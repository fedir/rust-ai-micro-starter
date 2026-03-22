---
name: grpc-patterns
description: tonic gRPC server and client patterns for Rust — protobuf setup, unary and streaming RPCs, interceptors, health checks, and integration testing.
---

# gRPC Patterns Skill

## When to Use
- Building gRPC services with tonic
- Implementing streaming RPCs or interceptors
- Testing gRPC services

---

## Setup

```toml
[dependencies]
tonic = "0.12"
prost = "0.13"
prost-types = "0.13"
tokio = { version = "1", features = ["full"] }
tonic-health = "0.12"
tonic-reflection = "0.12"

[build-dependencies]
tonic-build = "0.12"
```

```rust
// build.rs
fn main() -> Result<(), Box<dyn std::error::Error>> {
    tonic_build::configure()
        .build_server(true).build_client(true)
        .compile_protos(&["proto/service.proto"], &["proto/"])?;
    Ok(())
}
```

## Proto Pattern

```protobuf
syntax = "proto3";
package user.v1;

service UserService {
    rpc GetUser(GetUserRequest) returns (GetUserResponse);
    rpc ListUsers(ListUsersRequest) returns (stream UserResponse);
    rpc CreateUser(stream CreateUserRequest) returns (CreateUserResponse);
}
```

## Server Implementation

```rust
#[tonic::async_trait]
impl UserService for UserServiceImpl {
    // Unary RPC
    async fn get_user(&self, req: Request<GetUserRequest>) -> Result<Response<GetUserResponse>, Status> {
        let id = req.into_inner().id;
        let user = self.db.find_user(id).await
            .map_err(|e| Status::internal(e.to_string()))?
            .ok_or_else(|| Status::not_found("user not found"))?;
        Ok(Response::new(GetUserResponse { user: Some(user.into()) }))
    }

    // Server streaming
    type ListUsersStream = ReceiverStream<Result<UserResponse, Status>>;
    async fn list_users(&self, _: Request<ListUsersRequest>) -> Result<Response<Self::ListUsersStream>, Status> {
        let (tx, rx) = tokio::sync::mpsc::channel(32);
        let db = self.db.clone();
        tokio::spawn(async move {
            let mut stream = db.stream_users();
            while let Some(user) = stream.next().await {
                if tx.send(user.map(Into::into).map_err(|e| Status::internal(e.to_string()))).await.is_err() { break; }
            }
        });
        Ok(Response::new(ReceiverStream::new(rx)))
    }
}
```

## Auth Interceptor

```rust
fn auth_interceptor(req: Request<()>) -> Result<Request<()>, Status> {
    match req.metadata().get("authorization") {
        Some(token) => {
            verify_token(token.to_str().unwrap_or_default())
                .map_err(|_| Status::unauthenticated("invalid token"))?;
            Ok(req)
        }
        None => Err(Status::unauthenticated("missing token")),
    }
}

// Apply: UserServiceServer::with_interceptor(svc, auth_interceptor)
```

## Server with Health Check

```rust
#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let (health_reporter, health_service) = tonic_health::server::health_reporter();
    health_reporter.set_serving::<UserServiceServer<_>>().await;

    let svc = UserServiceImpl::new(pool);
    Server::builder()
        .add_service(health_service)
        .add_service(tonic_reflection::server::Builder::configure()
            .register_encoded_file_descriptor_set(FILE_DESCRIPTOR_SET)
            .build_v1()?)
        .add_service(UserServiceServer::with_interceptor(svc, auth_interceptor))
        .serve("0.0.0.0:50051".parse()?)
        .await?;
    Ok(())
}
```

## Testing

```rust
#[tokio::test]
async fn test_get_user() {
    let svc = UserServiceImpl::new(test_pool().await);
    let req = Request::new(GetUserRequest { id: "test-id".into() });
    let response = svc.get_user(req).await.expect("RPC failed");
    assert_eq!(response.into_inner().user.unwrap().id, "test-id");
}
```

## Key Rules

- Use `Status::not_found`, `Status::invalid_argument`, `Status::internal` — not raw strings
- Interceptors for cross-cutting: auth, logging, rate limiting
- Always add health service (`tonic-health`) for K8s readiness
- Add reflection service (`tonic-reflection`) for grpcurl/Postman
- Streaming: use `ReceiverStream`; handle `tx.send` errors (client disconnect)
