# Cursor Project Rules
- Code in small, reviewable PRs.
- Keep PCI scope minimal; never handle raw PAN in our code.
- Every service must expose `/health` and structured JSON logs.
- Prefer idempotent POST endpoints with Idempotency-Key.
- Add unit tests before adding new endpoints.

## TODO List
- [TODO] Add Redis + 3DS2 integrator placeholders in issuer-gateway.
- [TODO] Move rewards accrual rate to config + MCC-based rules.
- [TODO] Add user/account tables + FK in postings to enforce referential integrity.
- [TODO] Create dispute/chargeback service skeleton.
- [TODO] Add OpenTelemetry middleware on all services.
