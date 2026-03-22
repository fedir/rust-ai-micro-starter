---
name: rust-web-patterns
description: axum: router composition, extractors, AppState, Tower middleware, IntoResponse, graceful shutdown.
---

# Rust Web Patterns Skill

## When to Use
- Building axum web services or REST API handlers
- Adding middleware, authentication, or validation
- Structuring handlers, state, and router composition

---

## AppState

```rust
#[derive(Clone)]
pub struct AppState {
    pub pool: PgPool,       // Arc-based internally — cheap clone
    pub config: AppConfig,
}
// axum wraps in Arc via .with_state() — do NOT use Arc<AppState>
```

## Router Composition

```rust
pub fn create_router(state: AppState) -> Router {
    Router::new()
        .nest("/api/v1", api_routes())
        .layer(tower::ServiceBuilder::new()
            .layer(TraceLayer::new_for_http())
            .layer(CorsLayer::permissive())
            .layer(TimeoutLayer::new(Duration::from_secs(30)))
            .layer(CompressionLayer::new()))
        .with_state(state)
}
```

## Handler Pattern

```rust
// Thin handler — delegate to service
pub async fn create(
    State(state): State<AppState>,
    Json(req): Json<CreateUserRequest>,
) -> Result<(StatusCode, Json<UserResponse>), AppError> {
    req.validate()?;
    let user = services::user::create(&state.pool, req).await?;
    Ok((StatusCode::CREATED, Json(UserResponse::from(user))))
}
```

## JWT Custom Extractor

```rust
impl<S: Send + Sync> FromRequestParts<S> for AuthUser {
    type Rejection = AppError;
    async fn from_request_parts(parts: &mut Parts, _: &S) -> Result<Self, AppError> {
        let TypedHeader(Authorization(bearer)) =
            TypedHeader::<Authorization<Bearer>>::from_request_parts(parts, _)
                .await.map_err(|_| AppError::Unauthorized)?;
        let claims = verify_jwt(bearer.token()).map_err(|_| AppError::Unauthorized)?;
        Ok(AuthUser { user_id: claims.sub, roles: claims.roles })
    }
}
```

## Health Endpoints

```rust
pub async fn health() -> impl IntoResponse { Json(json!({ "status": "ok" })) }

pub async fn ready(State(state): State<AppState>) -> impl IntoResponse {
    match sqlx::query("SELECT 1").execute(&state.pool).await {
        Ok(_) => Json(json!({ "status": "ready" })).into_response(),
        Err(_) => (StatusCode::SERVICE_UNAVAILABLE, Json(json!({ "status": "not ready" }))).into_response(),
    }
}
```

## Key Rules

- Thin handlers; business logic in service layer
- `State<AppState>` — no double Arc-wrapping
- Never return internal errors to clients
- Validate at extractor boundary
- Canonical `AppError` → `rust-architect/references/rust-setup.md`
- Canonical `shutdown_signal()` → `rust-architect/references/rust-setup.md`
