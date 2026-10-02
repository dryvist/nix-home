"""Exercise supported setup with stubbed OpenBao and macOS commands."""

import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile


with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    script = Path(sys.argv[1]).read_text()
    for command in ("curl", "open", "pbcopy"):
        script = script.replace(f"/usr/bin/{command}", str(root / command))
    (root / "setup").write_text(script)
    commands = {
        "openbao-run": """#!/usr/bin/env bash
set -eu
[ "$PROXMAN_VAULT_ROLE_ID" = test-role ]
[ "$PROXMAN_VAULT_SECRET_ID" = test-bootstrap ]
[ -z "${OPENBAO_APPROLE_PROXMAN_ROLE_ID:-}${OPENBAO_APPROLE_PROXMAN_SECRET_ID:-}" ]
if [ "$3" = --secrets ]; then
  for name in url type auth_method credential_mount credential_path; do
    value=$(printf '%s' "$PROFILE" | jq -r --arg name "$name" '.[$name] // empty')
    export "$name=$value"
  done
else
  case "$4" in
    *USERNAME*) export PROXMAN_USERNAME='operator@test' ;;
    *PASSWORD*) export PROXMAN_PASSWORD='test-password-never-print'; printf password >> "$CALLS" ;;
  esac
fi
shift 4
[ "$1" = -- ]; shift
exec "$@"
""",
        "curl": "#!/usr/bin/env bash\nprintf '%s' \"${STATUS:-200}\"\n",
        "open": "#!/usr/bin/env bash\nprintf open >> \"$CALLS\"\n",
        "pbcopy": "#!/usr/bin/env bash\ncat > \"$CLIPBOARD\"\n",
    }
    for name, text in commands.items():
        target = root / name
        target.write_text(text)
        target.chmod(0o700)
    environment = dict(os.environ, PATH=f"{root}:{os.environ['PATH']}",
                       OPENBAO_APPROLE_PROXMAN_ROLE_ID="test-role",
                       OPENBAO_APPROLE_PROXMAN_SECRET_ID="test-bootstrap",
                       CALLS=str(root / "calls"), CLIPBOARD=str(root / "clipboard"))
    profile = dict(url="https://cluster.example.test", type="pve", auth_method="traditional",
                   credential_mount="secret", credential_path="proxmox/main/proxman")

    def run(value, *arguments, status="200"):
        (root / "calls").write_text("")
        result = subprocess.run(["bash", str(root / "setup"), *arguments],
                                env=dict(environment, PROFILE=json.dumps(value), STATUS=status),
                                capture_output=True, text=True, check=False)
        assert "test-password-never-print" not in result.stdout + result.stderr
        return result, (root / "calls").read_text()

    for invalid in ({}, dict(profile, url="http://cluster.example.test"),
                    dict(profile, auth_method="token"), dict(profile, credential_path="../secret")):
        result, calls = run(invalid)
        assert result.returncode != 0 and not calls
    result, calls = run(profile)
    assert result.returncode == 0 and calls == "open" and "operator@test" in result.stdout
    result, calls = run(profile, "--copy-password", status="401")
    assert result.returncode == 0 and calls == "passwordopen"
    assert (root / "clipboard").read_text() == "test-password-never-print"
    result, calls = run(profile, status="503")
    assert result.returncode != 0 and not calls
    print("ProxMan setup: 7 scenarios passed; password only reached clipboard on explicit request")
