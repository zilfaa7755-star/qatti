# Qaati V2.1 Foundation Repair Package

This package is a **working repair baseline**, not a final production release.

## Important

- `backend/.env` from the original upload is intentionally excluded.
- `backend/package.json` now declares required direct dependencies (`@nestjs/throttler`, `helmet`, `express`). Regenerate `package-lock.json` with `npm install` in a networked development environment before using `npm ci`.
- Payment verification is fail-closed until real provider adapters are implemented.
- `DB_SYNCHRONIZE=false` is intentional; the schema still requires the planned migration reconciliation.

See:
- `docs/QAATI_V2_1_MASTER_PLAN.md`
- `docs/EXECUTION_LOG.md`
- `docs/SCHEMA_RECONCILIATION.md`
- `tools/static_audit.py`
