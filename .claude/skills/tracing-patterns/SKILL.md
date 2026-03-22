---
name: tracing-patterns
description: Structured logging and distributed tracing for Rust with the tracing ecosystem — subscriber setup, instrument macro, manual spans, axum TraceLayer, request IDs, JSON output, and OpenTelemetry integration.
---

# Tracing Patterns Skill

## When to Use
- Setting up structured logging or observability for a Rust service
- Integrating OpenTelemetry / OTLP
- Adding tracing spans to async functions

---

## Setup

```toml
[dependencies]
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["env-filter", "json"] }

# Optional: OpenTelemetry
opentelemetry = "0.27"
opentelemetry-otlp = { version = "0.27", features = ["tonic"] }
tracing-opentelemetry = "0.28"
```

## Subscriber Init

```rust
pub fn init_tracing() {
    let env_filter = EnvFilter::try_from_default_env()
        .unwrap_or_else(|_| EnvFilter::new("info"));

    tracing_subscriber::registry()
        .with(env_filter)
        .with(tracing_subscriber::fmt::layer().json())   // JSON in prod
        .init();
}
// LOG_FORMAT=json or RUST_LOG=myapp=debug,sqlx=warn
```

## instrument Macro

```rust
#[tracing::instrument(skip(pool, password), fields(user.email = %email))]
pub async fn create_user(pool: &PgPool, email: &str, password: &str) -> Result<User, AppError> {
    tracing::info!("creating user");
    let user = db::users::create(pool, email, &hash_password(password)?).await?;
    tracing::info!(user.id = %user.id, "user created");
    Ok(user)
}
// skip sensitive fields; add structured fields with fields()
```

## Manual Spans

```rust
let span = tracing::info_span!("process_payment", payment_id = %payment_id, amount = amount);
let _guard = span.enter();
// or for async:
async { process(id).await }.instrument(span).await?;
```

## axum TraceLayer

```rust
use tower_http::trace::TraceLayer;
use tracing::Level;

let app = Router::new()
    .layer(TraceLayer::new_for_http()
        .make_span_with(|req: &Request<_>| {
            info_span!("http_request",
                method = %req.method(),
                uri = %req.uri(),
                request_id = tracing::field::Empty,
            )
        })
        .on_response(|res: &Response<_>, latency: Duration, span: &Span| {
            span.record("status", res.status().as_u16());
            tracing::info!(latency = ?latency, "response sent");
        }));
```

## OpenTelemetry Integration

```rust
use opentelemetry_otlp::WithExportConfig;
use tracing_opentelemetry::OpenTelemetryLayer;

let tracer = opentelemetry_otlp::new_pipeline()
    .tracing()
    .with_exporter(opentelemetry_otlp::new_exporter().tonic()
        .with_endpoint("http://otel-collector:4317"))
    .install_batch(opentelemetry_sdk::runtime::Tokio)?;

tracing_subscriber::registry()
    .with(EnvFilter::from_default_env())
    .with(tracing_subscriber::fmt::layer().json())
    .with(OpenTelemetryLayer::new(tracer))
    .init();
```

## Key Rules

- `skip(password, token, secret)` — never trace sensitive values
- Use `%` (Display) for IDs, `?` (Debug) for structs
- `tracing::warn!` / `tracing::error!` for non-happy paths
- Flush traces on shutdown: `opentelemetry::global::shutdown_tracer_provider()`
- `RUST_LOG=myapp=debug,sqlx=warn,tower_http=info` for fine-grained control
