---
name: rust-architect
description: Rust system architecture workflows — Cargo workspace layout, crate boundaries, async design, dependency selection, error hierarchy, and production verification gates.
---

# Rust Architect Skill

## When to Use
- Designing Rust system architecture or Cargo workspace structure
- Choosing async runtime, libraries, crate boundaries
- Solving ownership/lifetime architectural issues

## Reference Files

| Reference | Contents |
|-----------|---------|
| `references/rust-setup.md` | Workspace layout, Cargo.toml, project structure, canonical AppError, main.rs |
| `references/async-patterns.md` | tokio patterns, channels, select!, backpressure, task management |
| `references/error-handling.md` | thiserror, anyhow, error hierarchy, IntoResponse |
| `references/security.md` | JWT, argon2, rustls, cargo-audit, input validation |
| `references/testing-patterns.md` | Unit, integration, proptest, criterion, testcontainers |
| `references/worker-patterns.md` | Background jobs, cron scheduling, task queues, graceful shutdown |

---

## Dependency Selection

| Need | Crate |
|------|-------|
| Async runtime | `tokio` (full features) |
| Web framework | `axum` + `tower-http` |
| gRPC | `tonic` + `prost` |
| Database | `sqlx` (PostgreSQL) |
| Serialization | `serde` + `serde_json` |
| Errors (lib) | `thiserror` |
| Errors (app) | `anyhow` |
| Tracing | `tracing` + `tracing-subscriber` |
| Config | `config` (files + env vars) |
| Auth/JWT | `jsonwebtoken` |
| Password | `argon2` |
| Validation | `validator` or `garde` |
| CLI | `clap` (derive) |

## Verification Gates

Before done: `cargo fmt --check` · `cargo clippy -- -D warnings` · `cargo deny check` · `cargo test` · `cargo audit` · Docker image builds · health endpoint responds · migrations run

## MUST NOT

- No `unwrap()`/`expect()` in production
- No `std::sync::Mutex` across `.await` points
- No blocking I/O in async functions
- No `Box<dyn Error>` from library functions
- No business logic in axum handlers
- No `async-trait` crate — native async fn since Rust 1.75
- No `once_cell`/`lazy_static` — use `std::sync::LazyLock`
- No `Arc<AppState>` — axum wraps `State<AppState>` in Arc internally
