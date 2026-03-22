---
name: rust-code-review
description: Rust code review: ownership, lifetimes, unsafe soundness, async, perf, security. PR audits.
---

# Rust Code Review Skill

## When to Use
- "Review code", "check this PR", "code review"
- Before merging Rust changes or auditing `unsafe` blocks

---

## Step 1: Quick Scan

```bash
cargo clippy -- -D warnings
cargo audit
grep -rn "unwrap()\|expect(" src/
grep -rn "unsafe" src/
```

## Step 2: Review by Category

| Category | Anti-pattern | Idiomatic |
|----------|-------------|-----------|
| **Ownership** | `fn f(s: String)` when not consumed | `fn f(s: &str)` |
| | `.clone()` in hot path | Pass reference or redesign |
| | `Arc<String>` everywhere | References first; Arc only for shared ownership |
| **Errors** | `result.unwrap()` in prod | `result?` or `.context("msg")?` |
| | `Box<dyn Error>` at lib boundary | `thiserror` typed enum |
| | `let _ = risky_call()` | Handle or explain the ignore |
| **Async** | `std::sync::Mutex` across `.await` | `tokio::sync::Mutex` |
| | Blocking call in async (`std::fs`) | `tokio::task::spawn_blocking` |
| | `tokio::spawn` without storing `JoinHandle` | Store handle or `abort_on_drop` |
| **Unsafe** | Raw `unsafe {}` without comment | Justify soundness in comment above block |
| | `std::mem::transmute` | Use proper conversion or `bytemuck` |
| **Performance** | `Vec` without `with_capacity` in known-size loops | `Vec::with_capacity(n)` |
| | Regex compiled in loop | `std::sync::LazyLock<Regex>` |
| | N+1 queries | Batch fetch with `WHERE id = ANY($1)` |

## Async Correctness Checklist

- [ ] No `std::sync::Mutex` held across `.await`
- [ ] No blocking I/O in async context
- [ ] `tokio::spawn` tasks stored or detached intentionally
- [ ] `select!` branches are cancel-safe
- [ ] Channel senders/receivers lifecycle managed

## Severity Scale

- **Critical**: Unsound unsafe, data races, panics in prod paths, secrets exposed
- **Major**: Blocking-in-async, unnecessary clones in hot paths, error swallowing
- **Minor**: Missing docs, suboptimal algorithm
- **Nit**: Naming, formatting (defer to rustfmt)

## Review Order

Cargo.toml → error types → domain types → db layer → services → handlers → tests → docs
