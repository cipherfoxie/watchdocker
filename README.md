# watchdocker

> Sovereign Docker Compose auto-updater. Pure bash. No container. No daemon. The bash-native successor to archived watchtower.

[![License: MIT](https://img.shields.io/badge/license-MIT-yellow.svg)](LICENSE)
[![Bash](https://img.shields.io/badge/bash-5.x-4EAA25.svg?logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![systemd](https://img.shields.io/badge/systemd-timer-FCC624.svg?logo=systemd&logoColor=black)](https://www.freedesktop.org/wiki/Software/systemd/)
[![Docker Engine](https://img.shields.io/badge/docker-29.x-2496ED.svg?logo=docker&logoColor=white)](https://docs.docker.com/engine/)
[![arch](https://img.shields.io/badge/arch-amd64%20%7C%20arm64-blue.svg)](#tested-on)
[![Zero Dependencies](https://img.shields.io/badge/runtime%20deps-zero-success.svg)](#design-constraints)
[![Security](https://img.shields.io/badge/security-SECURITY.md-red.svg)](SECURITY.md)
[![Write-up](https://img.shields.io/badge/write--up-sovgrid.org-76b900.svg)](https://sovgrid.org/blog/watchdocker/)

## What

`watchdocker` watches your Docker Compose projects, pulls new images when available, and restarts containers cleanly. It runs as a systemd timer, logs to journalctl, and gets out of the way.

```bash
sudo watchdocker --dry-run
# 16:14:22 [INFO]  watchdocker 0.1.0, 4 project(s)
# 16:14:22 [INFO]  ▸ openwebui (/opt/openwebui)
# 16:14:22 [INFO]    dry-run: would docker compose pull
# 16:14:22 [INFO]  ▸ gitea (/data/gitea)
# 16:14:22 [INFO]    dry-run: would docker compose pull
# ...
# 16:14:22 [INFO]  ═══ Summary ═══
# 16:14:22 [INFO]    updated:    0
# 16:14:22 [INFO]    unchanged:  0
# 16:14:22 [INFO]    skipped:    0
# 16:14:22 [INFO]    dry-run:    4
```

## Watchdocker vs Watchtower

| | watchdocker | containrrr/watchtower | nicholas-fedor/watchtower |
|---|---|---|---|
| **Project status (2026)** | Active, v0.1.0 | Archived Dec 2025 | Active fork |
| **Compatible with Docker Engine 29.x** | ✓ native | ✗ crashes (API 1.25 vs min 1.40) | ✓ patched |
| **Runtime** | bash + systemd | container | container |
| **Extra container running 24/7** | none | one | one |
| **Memory footprint when idle** | 0 bytes | ~20 MB | ~20 MB |
| **Polls Docker daemon between runs** | no | yes, every interval | yes, every interval |
| **Code language** | bash (350 LOC) | Go (~30k LOC) | Go (~30k LOC) |
| **Audit time for full source** | 15 min | hours | hours |
| **Pull triggers** | systemd timer (configurable) | internal scheduler | internal scheduler |
| **Smart-restart (only if pull pulled)** | ✓ | ✓ | ✓ |
| **Opt-out via container label** | `watchdocker.skip=true` | `com.centurylinklabs.watchtower.enable=false` | same |
| **Pre/post hooks** | ✓ via config | only via lifecycle commands | only via lifecycle commands |
| **Logs** | journalctl (structured) | container stdout | container stdout |
| **External dependencies** | zero | Go runtime baked into image | same |
| **Image registry telemetry** | none | none | none |
| **Cron-style scheduling** | systemd.timer (calendar + jitter) | interval seconds | interval seconds |
| **Multi-arch images to pull and pin** | none | one per arch | one per arch |
| **Install** | `sudo ./install.sh` (idempotent) | `docker run` or compose | `docker run` or compose |
| **Audit by your AI agent in one prompt** | ✓ fits in context | partial | partial |
| **Supply-chain attack surface** | bash interpreter + docker compose | Go binary + container base image + Go deps + image registry chain | same |

The asymmetry that drove this project: watchtower (in either form) is a process that runs continuously to do work that happens once a week. systemd has a scheduler. systemd already runs. watchdocker is the smaller path.

## Why

Containrrr/watchtower, the de-facto Docker auto-updater for the last seven years, was [archived on 2025-12-17](https://github.com/containrrr/watchtower). Its last release (1.7.1, November 2023) ships a Docker SDK that speaks API version 1.25. Docker Engine 29.x requires minimum API 1.40, so watchtower 1.7.1 on a fresh Docker install crashes with:

```
client version 1.25 is too old. Minimum supported API version is 1.40
```

There is a [community fork at nicholas-fedor/watchtower](https://github.com/nicholas-fedor/watchtower) that maintains compatibility with current Docker. Use it if you want a Go binary in a container. `watchdocker` is for the operator who looked at the situation and asked: "why is there a container running 24/7 for something that runs once a week, and why is the auto-updater a 30,000-line Go program when the actual work is two commands?"

`watchdocker` fills the gap with the smallest possible design that still does the job: one bash script, two systemd units, one YAML config, opt-out via container label. No web UI, no daemon, no API, no metrics endpoint, no container. The lack of those is the feature.

## Design constraints

These are non-negotiable and define the project scope:

1. **Pure bash + standard POSIX tools.** No Python runtime, no Node, no Rust, no Go. The script runs on any Linux with bash 4+, docker compose v2, and standard `find`/`grep`/`sed`. Already on every homelab host.

2. **No daemon, no port, no container.** A systemd timer is the entire scheduler. The script runs, does its work, exits. Zero attack surface between runs.

3. **Opt-out, not opt-in.** Container-level opt-out via label `watchdocker.skip=true`. Project-level opt-out via config. Default behavior: update everything you've defined in compose. This matches what 90% of homelab operators actually want, auto-update is the goal, exceptions are the tiny minority.

4. **Smart-restart.** Only restart if `docker compose pull` actually pulled a new image. No "restart everything every week just in case." If nothing changed, nothing moves.

5. **Idempotent install, no overwrite.** The install script never clobbers an existing `/etc/watchdocker/config.yaml`. The new example lands next to the old config as `.yaml.new` for manual diff.

6. **Hooks for the 10% who need them.** Pre-hook and post-hook script paths in the config. Pre-hook fires before any pull (use for backup). Post-hook fires only after successful updates (use for notification, dashboard refresh, smoke test).

7. **Sovereign-friendly.** No telemetry. No external API call ever. No phone-home. The only network the script touches is whatever `docker compose pull` decides to hit. The code is auditable in 15 minutes.

## Market positioning

For homelab and sovereign-stack operators choosing a 2026-current Docker auto-updater:

| Tool | Approach | Active | Trade-off |
|---|---|---|---|
| **watchdocker** | bash + systemd timer | ✓ 2026 | no web UI, zero extra runtime |
| **nicholas-fedor/watchtower** | Go binary in container, watchtower fork | ✓ 2026 | one extra container, but drop-in if you already used watchtower |
| **WUD** (What's Up Docker) | TypeScript container + web UI | ✓ 2026 | rich UI, more attack surface, one more container to maintain |
| **Diun** | Go notification-only binary | ✓ 2026 | does not auto-update, just tells you |
| **Renovate** | CI bot, PR-driven | ✓ 2026 | overkill unless you already use Renovate for code repos |
| **containrrr/watchtower** | the historical default | ✗ archived Dec 2025 | do not use on Docker 29.x, crashes |

`watchdocker` is the right pick when you want auto-updates with the smallest possible operational surface. Pick the watchtower fork if you want drop-in compatibility with prior labels and zero migration. Pick WUD if you want a web UI. Pick Diun if you want notification-only.

## Install

```bash
git clone https://github.com/cipherfoxie/watchdocker.git
cd watchdocker
sudo ./install.sh
```

Then:

```bash
sudo nano /etc/watchdocker/config.yaml      # edit project list
sudo watchdocker --dry-run --verbose         # test
sudo systemctl enable --now watchdocker.timer
systemctl list-timers watchdocker            # verify next run
```

## Config

Minimal:

```yaml
projects:
  - /opt/my-app
  - /data/services/grafana
```

Full:

```yaml
projects:
  - /opt/openwebui
  - /opt/ai-services
  - /data/ai/comfyui
  - /data/config/gitea

skip_projects:
  - /opt/experimental

pre_hook: /usr/local/bin/my-backup-script
post_hook: /usr/local/bin/my-notify-script

prune:
  enabled: true
  age: 168h
```

If `projects:` is empty, watchdocker auto-discovers compose-files under `/opt`, `/data`, `/srv`, `/home` (max depth 4).

## Container-level opt-out

In a compose.yml, label a container:

```yaml
services:
  postgres:
    image: postgres:16-alpine
    labels:
      - watchdocker.skip=true
```

That whole project is skipped on the next run. Useful for stateful services where you want to pin to an exact tag and bump it manually.

## Hooks

Pre-hook example (backup before update):

```bash
#!/bin/bash
# /usr/local/bin/watchdocker-pre
TS=$(date +%Y%m%d-%H%M%S)
sudo tar czf "/backups/docker-volumes-$TS.tgz" /data/webui /data/gitea
```

Post-hook example (Nostr notify):

```bash
#!/bin/bash
# /usr/local/bin/watchdocker-post
nostril -p "watchdocker updated containers at $(date)" | \
  websocat wss://relay.example.com
```

## Logs

```bash
journalctl -u watchdocker.service -e        # last run
journalctl -u watchdocker.service -f        # follow live
systemctl list-timers watchdocker           # when next?
```

## Tested on

- Ubuntu 26.04 LTS with Docker Engine 29.5.2 (Lenovo Legion Pro 7 Gen 10, AMD64)
- Ubuntu 25.10 with Docker Engine 29.2.1 (DGX Spark, ARM64)
- Debian 13 with Docker Engine 29.5.2 (VPS, AMD64)

Should work on anything with bash 4+ and docker compose v2.

## Roadmap

- Add `bats` test suite under `tests/`
- GitHub Actions CI: shellcheck, install-test on Ubuntu matrix
- Optional: per-project schedule override (some weekly, some daily)
- Optional: webhook output for monitoring integration
- Optional: image-tag pinning detection (warn if pulling `:latest` while compose pins to `:16-alpine`)

Pull requests welcome. Keep it sovereign, keep it small.

## Won't do (anti-roadmap)

These are refused by design because they break the constraints above. Filing them as feature requests will be politely closed:

- Web UI (use WUD)
- Built-in Prometheus metrics endpoint (use hooks)
- Multi-host orchestration (use ansible)
- Python/Go/Rust runtime (pure bash is the point)
- Container packaging (the whole point is no container)
- Telemetry / phone-home / update-checks for watchdocker itself

## License

MIT. See [LICENSE](LICENSE).

## Origin

Built 2026-05-30 as a watchtower replacement after the Docker Engine 29.5 incompatibility blocked auto-updates on a Lenovo Legion friend-laptop setup. The friend's box runs four compose-stacks and needs auto-updates that work without a web UI, without a container running 24/7, and without depending on a Go binary maintained by a stranger. watchdocker is what came out of that one afternoon.
