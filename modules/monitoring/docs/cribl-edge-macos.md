# Cribl Edge on macOS (Native Installation)

Native Cribl Edge installation for collecting logs, metrics, and power data from macOS hosts.

## Installation

Cribl Edge is installed via the Cribl Cloud enrollment script:

```bash
sudo curl 'https://YOUR_ORG.cribl.cloud/init/install-edge.sh?group=default_fleet&token=YOUR_TOKEN&user=cribl&user_group=cribl' | sudo bash -
```

This installs to `/opt/cribl/` and creates a `cribl` user.

## Full Disk Access (FDA) Workaround

macOS requires Full Disk Access for reading files in protected directories
(like user home folders). However, macOS FDA only accepts application bundles (.app),
not raw binaries.

### Problem

- Cribl Edge is installed as `/opt/cribl/bin/cribl` (raw binary)
- macOS System Settings silently rejects raw binaries from FDA
- The launchd service runs the binary directly

### Solution: App Bundle Wrapper

Create a minimal .app bundle that wraps the Cribl binary:

```bash
# 1. Create app bundle structure
sudo mkdir -p /Applications/CriblEdge.app/Contents/MacOS

# 2. Create wrapper script
sudo tee /Applications/CriblEdge.app/Contents/MacOS/cribl > /dev/null << 'EOF'
#!/bin/bash
exec /opt/cribl/bin/cribl "$@"
EOF
sudo chmod 755 /Applications/CriblEdge.app/Contents/MacOS/cribl

# 3. Create Info.plist
sudo tee /Applications/CriblEdge.app/Contents/Info.plist > /dev/null << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>cribl</string>
    <key>CFBundleIdentifier</key>
    <string>io.cribl.edge</string>
    <key>CFBundleName</key>
    <string>Cribl Edge</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
</dict>
</plist>
EOF
```

### Grant FDA

1. Open **System Settings** → **Privacy & Security** → **Full Disk Access**
2. Click **+** button
3. Navigate to `/Applications/`
4. Select **CriblEdge.app** and click **Open**
5. Ensure the toggle is ON

### Update launchd to Use Wrapper

The launchd service must launch through the FDA-enabled wrapper:

```bash
# 1. Stop the service
sudo launchctl unload /Library/LaunchDaemons/io.cribl.plist

# 2. Backup original plist
sudo cp /Library/LaunchDaemons/io.cribl.plist /Library/LaunchDaemons/io.cribl.plist.backup

# 3. Update plist to use wrapper
sudo sed -i '' 's|/opt/cribl/bin/cribl|/Applications/CriblEdge.app/Contents/MacOS/cribl|' /Library/LaunchDaemons/io.cribl.plist

# 4. Restart the service
sudo launchctl load /Library/LaunchDaemons/io.cribl.plist
```

### Verify FDA is Working

```bash
# Check if Cribl can read protected files (replace $USER with your username)
sudo -u cribl cat /Users/$USER/.claude/logs/mcp.jsonl | head -1
```

If FDA is working, this will output JSON. If not, you'll get "Operation not permitted".

## Capabilities

As of Cribl Edge 4.16.0+, macOS Edge is **generally available** (no longer Preview) and supports:

- File monitoring (with FDA for protected directories)
- Log collection (with FDA for protected directories)
- Exec sources (run arbitrary commands on a schedule)
- System metrics collection

### Power Monitoring Pack

The [cc-edge-macos-power](https://github.com/JacobPEvans/cc-edge-macos-power) pack uses Exec sources to collect:

- **Power metrics** (5 min intervals): Per-process energy impact, CPU/GPU/ANE power draw, thermal pressure via `powermetrics`
- **Battery status** (1 min intervals): Charge %, power source, charging state, cycle count, capacity, health %, temperature via `pmset` + `ioreg`

Data flows through Cribl Stream to Splunk (`index=os`, `sourcetype=macos:power:*`).

Install the pack:

```bash
sudo curl -L -o /opt/cribl/state/packs/cc-edge-macos-power.crbl https://github.com/JacobPEvans/cc-edge-macos-power/releases/latest/download/cc-edge-macos-power.crbl
curl -X POST http://localhost:9000/api/v1/packs -H "Content-Type: application/json" -d '{"source":"cc-edge-macos-power.crbl"}'
curl -X POST http://localhost:9000/api/v1/version/commit
curl -X POST http://localhost:9000/api/v1/system/settings/restart
```

### Native Edge → Stream Connectivity

Native macOS Edge connects to Cribl Stream in OrbStack via NodePort:

| Target | URL |
|--------|-----|
| Stream HEC | `http://localhost:30088/services/collector` |
| Stream UI | `http://localhost:30900` |

Configure the Edge output to use the Stream HEC URL above with token `edge-internal`.

## Ports

| Port | Purpose |
|------|---------|
| 9420 | API / OTEL input |
| 9000 | Web UI |

## Service Management

```bash
# Start
sudo launchctl load /Library/LaunchDaemons/io.cribl.plist

# Stop
sudo launchctl unload /Library/LaunchDaemons/io.cribl.plist

# Check status
sudo launchctl list | grep cribl

# View logs
tail -f /opt/cribl/log/cribl.log
```

## Updating After Cribl Upgrades

If Cribl Edge auto-updates, the wrapper still points to the updated binary (via exec).
No changes needed unless the installation path changes.

If the launchd plist is overwritten during an upgrade, re-run the sed command above.
