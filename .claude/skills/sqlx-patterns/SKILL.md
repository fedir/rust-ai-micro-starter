---
name: sqlx-patterns
description: sqlx patterns for Rust — compile-time checked queries, connection pools, transactions with FOR UPDATE SKIP LOCKED, dynamic QueryBuilder, offline mode, migrations, and error mapping to HTTP.
---

# sqlx Patterns Skill

## When to Use
- Database access layer design for Rust
- Compile-time query checking, transactions, migrations
- Mapping sqlx errors to HTTP responses

---

## Setup

```toml
[dependencies]
sqlx = { version = "0.8", features = ["runtime-tokio", "postgres", "uuid", "chrono", "migrate", "json"] }
```

```bash
cargo install sqlx-cli --no-default-features --features postgres
sqlx migrate add create_users_table
sqlx migrate run
```

## Connection Pool

```rust
let pool = sqlx::postgres::PgPoolOptions::new()
    .max_connections(20).min_connections(2)
    .acquire_timeout(std::time::Duration::from_secs(3))
    .connect(&database_url).await?;
sqlx::migrate!("./migrations").run(&pool).await?;
```

## Compile-Time Checked Queries

```rust
// Fetch one (errors if 0 rows)
let user = sqlx::query_as!(User, "SELECT * FROM users WHERE id = $1", id)
    .fetch_one(&pool).await?;

// Fetch optional
let user = sqlx::query_as!(User, "SELECT * FROM users WHERE email = $1", email)
    .fetch_optional(&pool).await?;

// Insert returning
let user = sqlx::query_as!(User,
    "INSERT INTO users (id, email, name) VALUES ($1, $2, $3) RETURNING *",
    Uuid::new_v4(), email, name)
    .fetch_one(&pool).await?;
```

## Transactions

```rust
let mut tx = pool.begin().await?;
let user = sqlx::query_as!(User, "INSERT INTO users ... RETURNING *", ...)
    .fetch_one(&mut *tx).await?;
sqlx::query!("INSERT INTO audit_log (user_id) VALUES ($1)", user.id)
    .execute(&mut *tx).await?;
tx.commit().await?;
```

## FOR UPDATE SKIP LOCKED (job queue)

```rust
let job = sqlx::query_as!(Job,
    "SELECT * FROM jobs WHERE status = 'pending' ORDER BY created_at LIMIT 1 FOR UPDATE SKIP LOCKED")
    .fetch_optional(&mut *tx).await?;
```

## Dynamic Queries (QueryBuilder)

```rust
let mut qb = sqlx::QueryBuilder::new("SELECT * FROM users WHERE 1=1");
if let Some(email) = filter.email { qb.push(" AND email = ").push_bind(email); }
if let Some(status) = filter.status { qb.push(" AND status = ").push_bind(status); }
qb.push(" ORDER BY created_at DESC LIMIT ").push_bind(limit);
let users = qb.build_query_as::<User>().fetch_all(&pool).await?;
```

## Error Mapping

```rust
impl From<sqlx::Error> for AppError {
    fn from(e: sqlx::Error) -> Self {
        match e {
            sqlx::Error::RowNotFound => AppError::NotFound,
            sqlx::Error::Database(ref db) if db.constraint() == Some("users_email_key") => AppError::Conflict("email taken".into()),
            _ => AppError::Database(e),
        }
    }
}
```

## Offline Mode (CI without DB)

```bash
cargo sqlx prepare          # saves .sqlx/ query metadata
SQLX_OFFLINE=true cargo build   # compiles without live DB
```

## Key Rules

- Always use `query_as!` / `query!` macros — compile-time checked
- Use `PgPool` in `AppState` — already Arc-based, clone is cheap
- Transactions: pass `&mut *tx` (deref to executor)
- Map `sqlx::Error` to domain errors in the db layer, not in handlers
- Commit `.sqlx/` directory to git for CI offline builds
