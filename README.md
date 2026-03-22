# Rust AI Micro Starter

A production-grade [Claude Code](https://claude.ai/code) / [OpenCode](https://opencode.ai) template for Rust microservices. Optimized for **maximum token efficiency** — agents and skills load only what the AI needs, when it needs it.

Clone it, open your AI coding assistant, and describe what to build. Expert-level Rust guidance is already wired in.

## Quick Start

```bash
git clone https://github.com/your-username/rust-ai-micro-starter my-project
cd my-project
rm -rf .git && git init
sed -i '' 's/placeholder/my-project/g' Cargo.toml
cp .env.example .env
claude   # or: opencode
```

Then describe your service:

```
Build a REST API for a task management app with PostgreSQL, JWT auth, and pagination.
```

## What's Included

### Agents — specialized sub-processes for complex tasks

| Agent | Role |
|-------|------|
| `rust-architect` | Workspace design, crate boundaries, async patterns |
| `rust-web-engineer` | axum REST APIs, sqlx integration, middleware, auth |
| `code-reviewer` | Ownership, unsafe audits, async correctness (opus) |
| `test-automator` | Unit, integration, proptest, criterion, cargo-nextest |
| `devops-engineer` | CI/CD, cross-compilation, release automation |
| `docker-expert` | cargo-chef, multi-stage builds, distroless, <20MB images |
| `kubernetes-specialist` | K8s manifests tuned for Rust: tiny images, instant probes |
| `security-engineer` | cargo-audit/deny, unsafe review, argon2, rustls (opus) |

### Skills — loaded on demand, not on every prompt

| Skill | Contents |
|-------|---------|
| `rust-architect` | Workspace layout, dep selection, error hierarchy, verification gates + 6 reference files |
| `rust-web-engineer` | Full axum service guide + 5 reference files (web, data, auth, testing, cloud) |
| `rust-web-patterns` | Router composition, handlers, extractors, DTOs, graceful shutdown |
| `rust-patterns` | Builder, Newtype, Typestate, Strategy, Repository + Rust 2024 idioms |
| `grpc-patterns` | tonic server/client, streaming RPCs, interceptors, health checks |
| `sqlx-patterns` | Compile-time queries, transactions, FOR UPDATE SKIP LOCKED, migrations |
| `tracing-patterns` | Structured logging, spans, `#[instrument]`, JSON, OpenTelemetry |
| `rust-code-review` | Ownership, errors, unsafe, async, performance — review tables |
| `clean-code` | DRY/KISS/YAGNI, naming, function design, refactoring for Rust |
| `api-contract-review` | HTTP semantics, versioning, DTO separation, error responses |

## Token Efficiency Design

Agents and skills follow a **router + constraints** model, not a documentation dump:

- **Agents**: ~30–55 lines each. Identity, constraints, stack, delegation rules only.
- **Skills**: Loaded only when triggered. Deep knowledge lives in `references/` files — pulled only when that specific topic arises.
- **CLAUDE.md**: 23 lines. Hard rules the model won't assume on its own.

Result: ~200–400 tokens per invocation vs. 2,000–4,000 in naive setups.

## Enforced Standards

Pre-configured to enforce modern Rust defaults:

- **Edition 2024**, MSRV 1.88+
- No `async-trait` crate — native `async fn` in traits (Rust 1.75+)
- No `once_cell`/`lazy_static` — `std::sync::LazyLock` from std
- No `Arc<AppState>` in axum — `State<AppState>` (axum wraps internally)
- No `unwrap()`/`expect()` in production — `?` with `thiserror`/`anyhow`
- `cargo deny` bans: `openssl-sys`, `lazy_static`, `async-trait`
- Distroless/nonroot final Docker images
- `cargo-nextest` as test runner in CI

## Project Structure

```
.
├── .claude/
│   ├── agents/               # 8 specialized sub-agents
│   └── skills/               # 10 on-demand skills + reference libraries
├── .github/workflows/ci.yml  # fmt → clippy → deny → audit → nextest → coverage → docker
├── Cargo.toml                # Edition 2024, optimized release profile, clippy pedantic
├── CLAUDE.md                 # Minimal project rules (23 lines)
├── deny.toml                 # License policy + dependency bans
├── docker-compose.yml        # Postgres 17 + Redis 7 + app
├── Dockerfile                # cargo-chef + distroless, <20MB
└── rustfmt.toml
```

## CI Pipeline

```
fmt      → cargo fmt --check
clippy   → cargo clippy --all-targets -- -D warnings
deny     → cargo deny check
audit    → cargo audit
test     → cargo nextest run --all-features
coverage → cargo llvm-cov → Codecov
docker   → multi-stage build with GHA cache
```

## Local Development

```bash
docker compose up -d db redis
sqlx migrate run
cargo nextest run
cargo run
```

## License

MIT
