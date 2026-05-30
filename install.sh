#!/usr/bin/env bash
# watchdocker install script — idempotent
#
# Run as root or with sudo. Installs:
#   /usr/local/bin/watchdocker
#   /etc/systemd/system/watchdocker.service
#   /etc/systemd/system/watchdocker.timer
#   /etc/watchdocker/config.yaml (only if missing — does not overwrite)
#
# After install:
#   systemctl daemon-reload
#   systemctl enable --now watchdocker.timer
#
# Verify next scheduled run:
#   systemctl list-timers watchdocker

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "✗ run as root (or with sudo)" >&2
    exit 1
fi

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "▸ installing watchdocker binary"
install -m 0755 "$REPO_DIR/bin/watchdocker" /usr/local/bin/watchdocker

echo "▸ installing systemd units"
install -m 0644 "$REPO_DIR/systemd/watchdocker.service" /etc/systemd/system/
install -m 0644 "$REPO_DIR/systemd/watchdocker.timer"   /etc/systemd/system/

echo "▸ installing example config"
mkdir -p /etc/watchdocker
if [ ! -f /etc/watchdocker/config.yaml ]; then
    install -m 0644 "$REPO_DIR/config/watchdocker.yaml.example" /etc/watchdocker/config.yaml
    echo "  ✓ /etc/watchdocker/config.yaml created (review before enabling!)"
else
    echo "  ! /etc/watchdocker/config.yaml exists, NOT overwritten"
    install -m 0644 "$REPO_DIR/config/watchdocker.yaml.example" /etc/watchdocker/config.yaml.new
    echo "  → new example saved as /etc/watchdocker/config.yaml.new"
fi

echo "▸ creating runtime dir"
mkdir -p /run/watchdocker
chmod 755 /run/watchdocker

systemctl daemon-reload

echo ""
echo "✓ watchdocker installed."
echo ""
echo "Next steps:"
echo "  1. Review/edit /etc/watchdocker/config.yaml"
echo "  2. Test once:    sudo watchdocker --dry-run --verbose"
echo "  3. Enable timer: sudo systemctl enable --now watchdocker.timer"
echo "  4. Check timer:  systemctl list-timers watchdocker"
echo "  5. View logs:    journalctl -u watchdocker.service -e"
