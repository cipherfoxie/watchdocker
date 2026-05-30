# Security model

## Threat model

`watchdocker` is a root-level cron-style tool that talks to the Docker daemon, reads compose-files, and optionally invokes user-defined hook scripts. The risks to design against:

| Risk | Mitigation in v0.1 |
|---|---|
| **Compromised config file** points `pre_hook` / `post_hook` at a malicious script | Hook paths are validated: must be absolute, no `..`, regular file, executable, root-owned. Refused otherwise (exit 2 before any docker action). |
| **Path-traversal in project list** to read or restart arbitrary containers | Project paths are passed verbatim to `docker compose` via `cd`. `docker compose` itself rejects non-compose-file directories. No filesystem traversal performed by watchdocker itself. |
| **Race condition** between two concurrent watchdocker runs (e.g. timer + manual) corrupting state | Atomic lock via `mkdir /run/watchdocker/lock`. Stale-PID detection breaks abandoned locks. Use `--once` to override deliberately. |
| **YAML injection** through a tampered config | The parser does not `eval` or expand values. Variable substitution is disabled by the absence of any `eval` or unquoted indirect expansion in the code. Quoted-string handling preserves `#` inside quotes but does not interpret backslash escapes. |
| **Malicious image pulled by `docker compose pull`** | Out of scope. Use Docker Content Trust or signed images if your threat model includes upstream supply-chain. watchdocker is a scheduler, not a verifier. |
| **`docker.sock` access from inside the systemd unit** is effectively root | Acknowledged. This is unavoidable: any Docker auto-updater must talk to the daemon, and the daemon socket is the privileged interface. The systemd unit hardens the surrounding environment (`ProtectSystem=strict`, `SystemCallFilter`, no capabilities) so the only privileged path is the socket itself. |
| **Compromised hook script gets executed as root** | Hook owner-check (root-only) prevents a non-root user from staging a hook. A root attacker can already do anything, so this is the relevant boundary. |
| **Lockfile in a writable dir** could be hijacked | `/run/watchdocker` is created via the systemd `RuntimeDirectory=` mechanism, mode 0750, root-owned. Non-root users cannot create or modify the lockdir. |

## What watchdocker does NOT defend against

The following are intentionally out of scope:

1. **A compromised Docker daemon**. If your `dockerd` is rooted, watchdocker cannot help. Use `systemd-cred` or HSM-backed Docker Content Trust if that's the threat.
2. **A compromised image registry returning a backdoored `:latest` tag**. Pin to specific tags or digests in your compose-files, or run a trust verifier in `pre_hook`.
3. **Compose-files themselves being modified between runs**. The `watchdocker.skip` label is honored, but if an attacker can rewrite compose-files, they can also unset the label.
4. **Resource exhaustion attacks** (huge images filling disk during pull). Set Docker's `data-root` on a separate filesystem if this matters. The image-prune step partially mitigates by clearing old layers older than configured age.

## Inputs and their trust level

| Input | Trust level | Notes |
|---|---|---|
| Command-line args | High | Limited to a fixed enum, no shell expansion |
| `/etc/watchdocker/config.yaml` | Medium | Validated, value-typed, no eval |
| Hook scripts | Medium | Validated as root-owned before execution |
| Compose-files | Treated as authoritative | watchdocker does not parse them; it delegates to `docker compose` |
| Docker daemon | Trusted | Same trust as the rest of the host |
| Container labels | Authoritative for opt-out | Anyone who can write a compose-file can set them; that's already root-equivalent on the host |

## Reporting

Found something? Open an issue on the repo. If sensitive, encrypt to the maintainer's public key (in repo `keys/` once published).

## Audit notes

- v0.1.0 (2026-05-30): initial release. No external dependencies, no eval, atomic mkdir lock, root-owned hook check, systemd unit hardened to the extent compatible with docker-socket access. Manual code review only, no formal audit. SBOM is trivial: bash, `docker compose`, standard POSIX tools.
