# VersionSeal next-session worklist

- [x] Add pluggable signature verification and offline public-key fixtures.
- [x] Define policy adapters for quorum and separation-of-duties approval rules.
- [x] Add expiry evaluation with an injectable clock for deterministic automation.
- [x] Add cross-host replication only with conflict and revocation semantics specified.
- [x] Run multi-process contention benchmarks on Linux, macOS, and Windows.

Completed 2026-08-14. The hardening suite includes a committed RSA public-key/signature fixture, RSA and HMAC verifier adapters, quorum/role policies, injected-clock expiry, deterministic replication with conflict receipts and revocation precedence, plus a pinned three-OS contention matrix.
