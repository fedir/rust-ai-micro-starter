---
name: api-contract-review
description: REST API review: HTTP semantics, versioning, backward compat, response consistency, axum routing.
---

# API Contract Review Skill

## When to Use
- "Review this API" / "check REST endpoints" / before releasing API changes
- Reviewing PR with handler/router changes, checking backward compatibility

---

## Common Issues (Quick Reference)

| Issue | Symptom | Fix |
|-------|---------|-----|
| Wrong HTTP verb | POST for idempotent op | Use GET/PUT/DELETE correctly |
| Missing versioning | `/users` not `/v1/users` | Prefix all routes with `/v1/` |
| DB model leak | Raw row struct in response | Separate DTO/response type |
| 200 with error body | `{"status":200,"error":"..."}` | Use HTTP status codes, not envelope status |
| Inconsistent naming | `/getUsers` vs `/users` | Resource nouns, plural, kebab-case |
| Missing pagination | Returns all rows | Add `page`/`per_page` query params |

## HTTP Verb Semantics

| Verb | Use | Idempotent | Body |
|------|-----|------------|------|
| GET | Retrieve | Yes | No |
| POST | Create | No | Yes |
| PUT | Replace whole resource | Yes | Yes |
| PATCH | Partial update | No* | Yes |
| DELETE | Remove | Yes | Optional |

## Status Code Mapping (axum)

```rust
// 200 OK — GET success
// 201 Created — POST success
Ok((StatusCode::CREATED, Json(response)))
// 204 No Content — DELETE success (no body)
StatusCode::NO_CONTENT
// 400 Bad Request — validation failure
// 401 Unauthorized — missing/invalid auth
// 403 Forbidden — authenticated but not allowed
// 404 Not Found — resource doesn't exist
// 409 Conflict — duplicate (unique constraint)
// 422 Unprocessable Entity — semantic validation error
// 500 Internal Server Error — unexpected failure
```

## Route Structure Checklist

```
✅ /api/v1/users              GET (list), POST (create)
✅ /api/v1/users/:id          GET, PUT, PATCH, DELETE
✅ /api/v1/users/:id/orders   nested resource
❌ /api/v1/getUsers           verb in URL
❌ /api/v1/user               singular resource name
❌ /api/v1/users/delete/:id   verb in URL
```

## Backward Compatibility Rules

- Adding optional fields to response → safe
- Removing fields from response → **breaking**
- Adding required request fields → **breaking**
- Adding optional request fields → safe
- Changing field type → **breaking**
- Changing status code (e.g. 200 → 201) → **breaking**

## Response Consistency Checklist

- [ ] All error responses: `{"error": "message"}` (never raw status field)
- [ ] Timestamps: ISO 8601 (`"2024-01-15T10:30:00Z"`)
- [ ] IDs: UUIDs as strings (`"id": "uuid-string"`)
- [ ] Pagination: `{"data": [...], "total": N, "page": 1, "per_page": 20}`
- [ ] No internal details (stack traces, DB errors, file paths) in error responses
- [ ] `Content-Type: application/json` on all JSON responses
