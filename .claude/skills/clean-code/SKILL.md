---
name: clean-code
description: Clean Code principles (DRY, KISS, YAGNI), naming conventions, function design, and refactoring for Rust. Use when user says "clean this code", "refactor", "improve readability", or when reviewing code quality.
---

# Clean Code Skill (Rust)

## When to Use
- User says "clean this code" / "refactor" / "improve readability"
- Reducing complexity, removing duplication, improving naming

---

## Core Principles

| Principle | Rule | Red Flag |
|-----------|------|----------|
| **DRY** | Extract repeated logic | Copy-pasted validation, mapping, error handling |
| **KISS** | Simplest solution that works | Generics/traits when a plain function suffices |
| **YAGNI** | Don't build unused features | Abstraction layers with no second implementation |

## Naming

```rust
// ❌ Vague names
fn process(d: &Data) -> Option<Res> { ... }
fn check(u: &User) -> bool { ... }

// ✅ Intention-revealing
fn calculate_discount(order: &Order) -> Money { ... }
fn is_email_verified(user: &User) -> bool { ... }
```

## Function Design

```rust
// ❌ Too many responsibilities + boolean flag argument
pub async fn handle_user(user_id: Uuid, send_email: bool) -> Result<User, Error> { ... }

// ✅ Single responsibility; separate functions for separate concerns
pub async fn activate_user(user_id: Uuid) -> Result<User, Error> { ... }
pub async fn send_welcome_email(user: &User) -> Result<(), Error> { ... }
```

## Extract Common Patterns

```rust
// ❌ Repeated error mapping
fn a() -> Result<(), Error> { risky()?.map_err(|e| Error::Database(e.to_string())) }
fn b() -> Result<(), Error> { risky()?.map_err(|e| Error::Database(e.to_string())) }

// ✅ From impl or shared helper
impl From<sqlx::Error> for AppError { fn from(e: sqlx::Error) -> Self { AppError::Database(e) } }
fn a() -> Result<(), AppError> { risky().await? }
```

## Reduce Complexity

```rust
// ❌ Deep nesting
if let Some(user) = find_user(id).await? {
    if user.is_active() {
        if let Some(plan) = user.plan() { return Ok(plan); }
    }
}
return Err(AppError::NotFound);

// ✅ Early returns with let-else
let Some(user) = find_user(id).await? else { return Err(AppError::NotFound) };
let Some(plan) = user.is_active().then(|| user.plan()).flatten() else { return Err(AppError::NotFound) };
Ok(plan)
```

## Refactoring Checklist

- [ ] Functions do ONE thing and are < 20 lines
- [ ] No boolean flag parameters — use enums or separate functions
- [ ] Duplicated code extracted into shared function or `From` impl
- [ ] Nested `if let` replaced with `let ... else` (Rust 2024)
- [ ] Magic numbers/strings replaced with named constants or enums
- [ ] Complex closures extracted into named functions
- [ ] `clippy -- -D warnings` clean after refactor
