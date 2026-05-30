# Changelog

All notable changes documented here. Format inspired by Keep a Changelog.

## [0.1.0], 2026-05-30

Initial release.

### Added
- Core script `bin/watchdocker`: pure-bash auto-updater for Docker Compose projects
- `--dry-run`, `--once`, `--verbose`, `--list`, `--version`, `--help` CLI flags
- YAML config loader supporting `projects`, `skip_projects`, `pre_hook`, `post_hook`, `prune.{enabled,age}` keys
- Auto-discovery of compose-files under `/opt`, `/data`, `/srv`, `/home` when `projects:` is unset
- Container-level opt-out via the label `watchdocker.skip=true`
- Pre-hook and post-hook execution with root-owned-script validation
- Atomic lockfile via `mkdir`, with stale-PID detection and break logic
- Smart-restart: only `docker compose up -d` if `pull` actually pulled new layers
- Optional image-prune after successful updates, with configurable age threshold (default 168h)
- systemd `watchdocker.service` and `watchdocker.timer` (weekly Sun 03:00 + 30min jitter)
- Hardened systemd unit: `ProtectSystem=strict`, `NoNewPrivileges`, `SystemCallFilter`, empty capability sets
- `install.sh` for idempotent root install, never clobbers existing config
- Smoke-test suite under `tests/smoke.sh` covering CLI flags and config loader

### Security
- Hook paths validated as absolute, regular file, executable, root-owned (when run as root)
- YAML parser is non-evaluating: no `eval`, no command substitution from config values
- Lockfile race-free via atomic `mkdir`
- Comment stripping aware of single- and double-quoted strings to preserve `#` inside values

### Tested on
- Ubuntu 26.04 LTS + Docker Engine 29.5.2 (Lenovo Legion Pro 7 Gen 10, AMD64)
- Ubuntu 25.10 + Docker Engine 29.2.1 (DGX Spark, ARM64)

### Documentation
- `README.md` with design constraints, market positioning, full install + config docs
- `AGENTS.md` multi-agent contract for AI-assisted contributions
- `TASKS.md` roadmap with explicit anti-roadmap (refused-by-design features)
- `SECURITY.md` threat model + scope boundaries
- This `CHANGELOG.md`
