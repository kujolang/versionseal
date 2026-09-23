# Interrupted-write recovery

VersionSeal can finish a write interrupted after its durable intent was published. Recovery recreates only the exact original record and audit-event bytes. It does not issue a new approval, infer authority, rebind an actor, replace a conflicting file, or bypass artifact validation.

```sh
versionseal doctor --state .versionseal --json
versionseal recover --state .versionseal --id approve-EXISTING-ID --dry-run --json
versionseal recover --state .versionseal --id approve-EXISTING-ID --json
versionseal verify --state .versionseal --id approve-EXISTING-ID --json
```

Replace the placeholder with an actual lowercase record ID. `recover` requires `--id`; it does not take new decision input or require a new actor. `--force` never overrides a recovery conflict. Dry-run inspects both members without writing. Repeating recovery is safe, including concurrent recovery processes.

## Write protocol

1. Acquire the exclusive `locks/<id>.lock` claim containing `locked\n`.
2. Recheck immutable record/history conflicts while holding that claim.
3. Atomically replace the owned claim with a bounded JSON intent containing the exact serialized record and its SHA-256. Recovery cannot act before this replacement.
4. Publish the record with no replacement.
5. Publish the matching history event with no replacement.
6. The original writer removes its own lock after both members exist.

The intent has `schema_version: "1.0.0"`, `kind: "record.create"`, `record_text`, and `record_sha256`. File destinations are derived from a safe ID and the original timestamp, never accepted as arbitrary paths from the intent. Intents are limited to 4 MiB and embedded records to 1 MiB of UTF-8. Existing record and history formats are unchanged.

Once an intent is published, failure preserves it and any published members. Recovery first checks both destinations for exact agreement, then adds only missing members. This replaces the previous best-effort rollback, which could not handle abrupt process termination. There is one extra atomic write per successful creation; the intent's duplicate record bytes are temporary during ordinary operation.

| Interruption point | Result |
|---|---|
| Before claim acquisition | No owned state to recover |
| Claim acquired, intent not yet published | No record published; manual stale-claim review required |
| Intent only | Recovery restores the record and event |
| Intent plus record | Recovery adds the event |
| Intent plus complete pair | Recovery verifies equality and succeeds without replacement |
| Normal successful write | Original writer removes the intent |
| Corrupt intent or divergent destination | Recovery fails and preserves evidence |

## Ownership and visibility

Recovery **never deletes or steals a lock**. It cannot safely prove that the original process is dead. A recovered, completed intent may therefore remain on disk; reads and validation accept it only when both members exactly match. `doctor` reports completed retained intents separately from incomplete/conflicting ones. An original writer still running can complete the same bytes and release its own lock.

To reclaim a completed retained intent, stop all writers, back up state, run `recover --id ... --dry-run` and confirm `complete: true`, then remove only that ID's lock file. Resume writers afterward. Do not remove a claim just because it is old. Legacy lock directories or plain-text claims cannot be automatically recovered: no original intent exists to prove what should be written. Inspect them with the writers stopped; never invent audit history from an unexplained orphan record.

New incomplete records are withheld by VersionSeal reads while their intents remain. Whole-state `doctor` and `validate` inspect up to 1,000 lock candidates and fail closed on pending/conflicting intents or incomplete scans, including intent-only crashes with no record yet. Ordinary listing retains its existing pagination; use `doctor` for pending writes absent from the records directory.

The record and event are still two filesystem publications. External programs that read raw files directly must wait for successful completion or verify through VersionSeal; this protocol does not give raw filesystem readers a simultaneous two-file snapshot. Process-interruption recovery is covered by deterministic persisted-state tests and concurrent replay. Power-loss guarantees remain dependent on the filesystem and Kujo's atomic-write implementation; directory fsync and network-filesystem semantics are not claimed.

## Compatibility and operation

- Existing valid 0.1.0 and 0.2.0 records remain readable and verifiable without a journal.
- Upgrade all writers before using recovery; do not mix older rollback-capable writers with the new protocol.
- UTF-8 byte limits now match file sizes, including non-ASCII actor names and metadata. Previously accepted oversized Unicode records that could not be loaded are rejected before locking.
- Kujo 1.5.0 or newer is required. It includes the interpreter lexical-scope fix and bounded directory paging. The UTF-8 size helper remains compatible and unchanged.
- Queries retain at most 1,003 directory names in the runtime selection heap (1,002 returned); pending-write scans retain at most 1,002 (1,001 returned). Directory enumeration remains O(N), and pages are not a snapshot across concurrent changes. No state index or filesystem layout migration is needed.
