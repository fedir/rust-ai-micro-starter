---
name: rust-patterns
description: Builder, Newtype, Typestate, Strategy, Repository; Rust 2024: let-else, must_use, LazyLock.
---

# Rust Design Patterns Skill

## When to Use
- Implementing Builder, Typestate, Newtype, Strategy, Repository patterns
- Enforcing invariants at compile time
- Applying Rust 2024 idioms

---

## Builder Pattern

```rust
#[derive(Default)]
pub struct UserBuilder { name: Option<String>, email: Option<String>, age: Option<u32> }

impl UserBuilder {
    pub fn name(mut self, v: impl Into<String>) -> Self { self.name = Some(v.into()); self }
    pub fn email(mut self, v: impl Into<String>) -> Self { self.email = Some(v.into()); self }
    pub fn age(mut self, v: u32) -> Self { self.age = Some(v); self }
    pub fn build(self) -> Result<User, &'static str> {
        Ok(User {
            id: Uuid::new_v4(),
            name: self.name.ok_or("name required")?,
            email: Email(self.email.ok_or("email required")?),
            age: self.age,
        })
    }
}
// Usage: User::builder().name("Alice").email("a@b.com").build()?
```

## Newtype Pattern

```rust
#[derive(Debug, Clone, PartialEq, Eq, Hash, serde::Serialize, serde::Deserialize)]
pub struct UserId(Uuid);
impl UserId { pub fn new() -> Self { Self(Uuid::new_v4()) } }
impl std::fmt::Display for UserId { fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result { self.0.fmt(f) } }
// Prevents mixing UserId with OrderId at compile time
```

## Typestate Pattern

```rust
pub struct Connection<State> { inner: TcpStream, _state: std::marker::PhantomData<State> }
pub struct Disconnected; pub struct Connected; pub struct Authenticated;

impl Connection<Disconnected> {
    pub async fn connect(addr: &str) -> Result<Connection<Connected>, Error> { todo!() }
}
impl Connection<Connected> {
    pub async fn authenticate(self, token: &str) -> Result<Connection<Authenticated>, Error> { todo!() }
}
impl Connection<Authenticated> {
    pub async fn send(&self, msg: &[u8]) -> Result<(), Error> { todo!() }
}
// Compile-time guarantee: can't send before authenticate
```

## Repository Pattern

```rust
pub trait UserRepository: Send + Sync {
    async fn find_by_id(&self, id: UserId) -> Result<Option<User>, RepositoryError>;
    async fn save(&self, user: &User) -> Result<(), RepositoryError>;
    async fn delete(&self, id: UserId) -> Result<(), RepositoryError>;
}

pub struct PostgresUserRepository { pool: PgPool }
impl UserRepository for PostgresUserRepository {
    async fn find_by_id(&self, id: UserId) -> Result<Option<User>, RepositoryError> {
        sqlx::query_as!(User, "SELECT * FROM users WHERE id = $1", id.0)
            .fetch_optional(&self.pool).await.map_err(RepositoryError::from)
    }
    // ...
}
// Test with MockUserRepository via mockall
```

## Rust 2024 Idioms

```rust
// let-else for early returns (avoid nested if-let)
let Some(user) = db.find_user(id).await? else { return Err(AppError::NotFound) };

// LazyLock for statics (not once_cell or lazy_static)
static CONFIG: std::sync::LazyLock<AppConfig> = std::sync::LazyLock::new(|| AppConfig::load());

// must_use — warn if return value silently dropped
#[must_use]
pub fn validate_email(email: &str) -> Result<(), ValidationError> { todo!() }

// Native async fn in traits (Rust 1.75+ — no async-trait crate)
pub trait DataLoader: Send + Sync {
    async fn load(&self, id: Uuid) -> Result<Data, Error>;
}
```

## Strategy Pattern

```rust
pub trait PricingStrategy: Send + Sync {
    fn calculate(&self, base_price: f64) -> f64;
}
pub struct StandardPricing;
pub struct DiscountPricing { discount: f64 }
impl PricingStrategy for StandardPricing { fn calculate(&self, p: f64) -> f64 { p } }
impl PricingStrategy for DiscountPricing { fn calculate(&self, p: f64) -> f64 { p * (1.0 - self.discount) } }
// Inject via Arc<dyn PricingStrategy> in AppState
```
