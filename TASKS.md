# Tasks, watchdocker

Pick one, ship it, append the next. No process tax.

## Done

- [x] **CW-001** repo bootstrap (README, AGENTS, LICENSE, structure)
- [x] **CW-002** core script: pull + smart-restart + skip-label + lockfile
- [x] **CW-003** YAML config loader (top-level keys + lists, no parser dep)
- [x] **CW-004** systemd service + timer (weekly Sun 03:00 with jitter)
- [x] **CW-005** install.sh (idempotent, no config overwrite)
- [x] **CW-006** dry-run + verbose + list modes
- [x] **CW-007** pre-hook + post-hook (post fires only if updates happened)
- [x] **CW-008** image prune after successful updates (configurable age)

## Next (small things)

- [ ] **CW-009** `tests/smoke.sh`: install on tmpdir, run --list against fixture, assert exit 0
- [ ] **CW-010** shellcheck-clean as commit gate (.github/workflows/shellcheck.yml)
- [ ] **CW-011** Add Ubuntu 24.04 + Debian 12 test matrix
- [ ] **CW-012** Add AMD64 + ARM64 hardware test results to CI
- [ ] **CW-013** Document hook examples: backup-via-restic, Nostr-notify, Healthchecks.io ping

## Medium

- [ ] **CW-020** Per-project schedule override (some projects weekly, some daily)
- [ ] **CW-021** Webhook output: POST summary JSON to a configured URL
- [ ] **CW-022** Image-tag pinning detector: warn if pulling `:latest` while compose uses `:16-alpine`
- [ ] **CW-023** Compose-v1 fallback for hosts still on legacy `docker-compose` binary

## Stretch

- [ ] **CW-030** Optional remote-config mode: pull config from a git repo (sovereign single source of truth)
- [ ] **CW-031** Plugin system: drop a script in `/etc/watchdocker/plugins.d/`, gets sourced

## Don't-do (anti-roadmap)

These will be refused in PRs because they break design constraints:

- ❌ Web UI (use WUD if you want a UI)
- ❌ Built-in metrics endpoint (Prometheus etc, use hooks instead)
- ❌ Multi-host orchestration (use ansible if you want to manage many hosts)
- ❌ Python/Node/Go runtime (pure bash is the point)
- ❌ Container packaging (the whole point is "not a container")
- ❌ Telemetry / phone-home / update-checks for watchdocker itself
