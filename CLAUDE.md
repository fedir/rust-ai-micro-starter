## Workflow
- Plan before acting on any task with 3+ steps or architectural decisions
- Never mark done without proving it works (run tests, check logs)
- After any user correction: update `tasks/lessons.md` with the pattern
- Load skills from `.claude/skills/`; use subagents from `.claude/agents/`

## Rust Standards
- Edition 2024, MSRV 1.88+, latest stable crates
- No `unwrap()`/`expect()` in production — use `?` and typed errors
- Errors: `thiserror` (libraries), `anyhow` (application)
- Async: `tokio`; native `async fn` in traits — no `async-trait` crate
- Statics: `std::sync::LazyLock` — not `once_cell` or `lazy_static`
- State: `State<AppState>` — axum wraps in `Arc`; do NOT double-wrap
- Stack: `axum` (HTTP), `tonic` (gRPC), `sqlx` (DB), `config` (config), `tracing` (logs)

## Build Gates
- `cargo fmt --check` · `cargo clippy -- -D warnings` · `cargo deny check` · `cargo test`
- Package name = parent directory name (snake_case); bump PATCH on each new version

## Delivery
- Docker Compose for all components; update README.md on each version
- GitHub Actions CI in `.github/workflows/`; use `cargo-nextest` in CI
- Minimize code generated
