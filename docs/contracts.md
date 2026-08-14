# Contracts

Contract 1.0.0. VersionSeal owns: Approval Request; Approval Decision; Approval Record; Approval Condition; Approval Scope; Revocation Record; Expiration Record; Verification Result. Records carry schema/tool versions, stable IDs, actor, timestamp, provenance, command, and payload. Consumers accept compatible 1.x, preserve safe unknown payload metadata, and reject incompatible majors. JSON uses `ok/data/error/tool_version/contract_version`. Offline upstream fixtures identify repository, tag, schema, and checksum.
