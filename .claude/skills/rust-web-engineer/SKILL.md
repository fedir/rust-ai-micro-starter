---
name: rust-web-engineer
description: axum service implementation: domain→errors→db→service→handlers→tests. Refs: web, data, auth, testing, cloud.
---

# Rust Web Engineer Skill

## When to Use
- Building axum REST services from scratch
- Implementing auth, database, or cloud features
- Need reference implementations for common patterns

## Reference Files

| Reference | Contents |
|-----------|---------|
| `references/web.md` | axum router, handlers, extractors, error responses, validation, CORS |
| `references/data.md` | sqlx entities, queries, transactions, migrations, pagination |
| `references/auth.md` | JWT middleware, argon2 password hashing, OAuth2, RBAC |
| `references/testing.md` | axum-test unit tests, integration tests, wiremock, testcontainers |
| `references/cloud.md` | Dockerfile, GitHub Actions, health checks, Kubernetes manifests |

---

## Implementation Order

1. **Domain model** — types first, make invalid states unrepresentable
2. **Error types** — canonical `AppError` in `rust-architect/references/rust-setup.md`
3. **Data layer** — `sqlx::query_as!` compile-time checked queries
4. **Service layer** — business logic, pure Rust, no HTTP concerns
5. **Handlers** — thin: extract → delegate to service → return response
6. **Router** — compose with middleware stack
7. **Tests** — `#[tokio::test]` with `axum-test` or `reqwest`

## MUST

- `State<AppState>` — axum wraps in Arc; do NOT double-wrap
- Validate at extractor level with `validator`/`garde`
- Map `sqlx::Error` to domain errors, never expose raw DB errors
- Graceful shutdown with `with_graceful_shutdown()`
- `/health` and `/ready` endpoints for Kubernetes

## MUST NOT

- No `unwrap()`/`expect()` in handlers or services
- No business logic in handlers
- No `std::sync::Mutex` in AppState — use `tokio::sync::RwLock`
- Never return internal errors to API clients
- No DB queries directly in handlers
