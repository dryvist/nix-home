# Cribl Edge macOS FDA Workaround Attempts

**Date**: 2024-12-20
**Outcome**: FDA workarounds failed - running as root is the working solution

## Problem

Cribl Edge runs as the `cribl` user (non-root) but needs Full Disk Access (FDA) to read files in protected directories like `~/.claude/logs/`.

macOS FDA only accepts application bundles (.app), not raw binaries. The Cribl Edge installer creates `/opt/cribl/bin/cribl` as a raw binary.

## Attempts

### Attempt 1: Add raw binary to FDA directly

**Action**: System Settings → Privacy & Security → Full Disk Access → + → `/opt/cribl/bin/cribl`

**Result**: macOS silently rejects it. The dialog accepts the selection but nothing appears in the FDA list.

**Why it failed**: macOS FDA is designed for .app bundles, not raw binaries.

---

### Attempt 2: Create .app wrapper in /Applications

**Action**:

```bash
sudo mkdir -p /Applications/CriblEdge.app/Contents/MacOS
# Created wrapper script:
cat > /Applications/CriblEdge.app/Contents/MacOS/cribl << 'EOF'
#!/bin/bash
exec /opt/cribl/bin/cribl "$@"
EOF
chmod 755 /Applications/CriblEdge.app/Contents/MacOS/cribl
# Created Info.plist with CFBundleIdentifier=io.cribl.edge
```

**Result**: .app was accepted into FDA, but Cribl still got EACCES errors.

**Why it failed**: FDA is checked against the actual binary making file access calls.
When the wrapper script does `exec /opt/cribl/bin/cribl`, the process image is replaced
with the original binary, which doesn't have FDA.

---

### Attempt 3: Copy actual binary into .app in /Applications

**Action**:

```bash
sudo cp /opt/cribl/bin/cribl /Applications/CriblEdge.app/Contents/MacOS/cribl
sudo chmod 755 /Applications/CriblEdge.app/Contents/MacOS/cribl
# Updated launchd plist to use /Applications/CriblEdge.app/Contents/MacOS/cribl
```

**Result**: Service crashed with "Cannot find module 'aws-sdk/global.bundle'"

**Why it failed**: The cribl binary expects supporting files
(*.bundle.js, @aws-sdk/, etc.) in the same directory. It also tries to
write logs relative to its location.

---

### Attempt 4: Symlink supporting files into .app in /Applications

**Action**:

```bash
cd /Applications/CriblEdge.app/Contents/MacOS
sudo ln -sf /opt/cribl/bin/*.bundle.js .
sudo ln -sf /opt/cribl/bin/@* .
# etc.
```

**Result**: Failed with "Operation not permitted" on some symlinks.

**Why it failed**: /Applications may have additional SIP or quarantine protections.

---

### Attempt 5: Create .app in /opt/cribl (outside /Applications)

**Action**:

```bash
sudo mkdir -p /opt/cribl/CriblEdge.app/Contents/MacOS
sudo cp /opt/cribl/bin/cribl /opt/cribl/CriblEdge.app/Contents/MacOS/
# Symlink supporting files
cd /opt/cribl/CriblEdge.app/Contents/MacOS
sudo ln -sf /opt/cribl/bin/*.bundle.js .
sudo ln -sf /opt/cribl/bin/@* .
# Symlink data directories
cd /opt/cribl/CriblEdge.app/Contents
sudo ln -sf /opt/cribl/data .
sudo ln -sf /opt/cribl/state .
sudo ln -sf /opt/cribl/log .
# etc.
# Updated launchd to use /opt/cribl/CriblEdge.app/Contents/MacOS/cribl
```

**Result**: .app was accepted into FDA. Service started but then crashed (SIGKILL, exit -9).

**Why it failed**: Unknown. Possibly:

- The symlinked structure confused the binary
- macOS code signing validation failed
- Some other internal check in the cribl binary

---

## What Works

1. **Run as root** ✅: Confirmed working. Root bypasses TCC/FDA entirely.
   Edit `/Library/LaunchDaemons/io.cribl.plist` and change `<key>UserName</key>` from
   `cribl` to `root`, then reload the service.

## What Might Work (Not Tested)

1. **MDM/PPPC Profile**: Enterprise deployment can push a Privacy Preferences Policy Control
   profile that grants FDA to specific binaries by code signature or bundle ID.
   Requires MDM infrastructure.

2. **Signing the .app**: If the .app bundle were properly code-signed with an Apple Developer
   certificate, FDA might work better. The unsigned .app may have been rejected by Gatekeeper.

3. **Using `open -a CriblEdge.app`**: Launching via the `open` command sometimes helps
   with FDA inheritance, but doesn't work for launchd daemons.

4. **Terminal.app FDA**: Granting FDA to Terminal.app would allow commands run from Terminal
   to access protected files, but this doesn't help launchd services.

---

## Files Created During Attempts

- `/Applications/CriblEdge.app/` - wrapper .app bundle
- `/opt/cribl/CriblEdge.app/` - second .app bundle attempt
- `/Library/LaunchDaemons/io.cribl.plist.backup` - backup of original plist

## Launchd Plist Modifications

Original path: `/opt/cribl/bin/cribl`
Modified to: `/opt/cribl/CriblEdge.app/Contents/MacOS/cribl`

---

## Conclusion

macOS FDA for command-line daemons is poorly documented and difficult to configure without:

- A properly signed .app bundle from the vendor
- MDM/PPPC profile deployment
- Running as root

For a local development/monitoring setup, running as root is the pragmatic choice.
