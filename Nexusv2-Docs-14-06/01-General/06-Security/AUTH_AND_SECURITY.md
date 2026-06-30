# Nexus v2 — Authentication & Security

## 1. Authentication System

### 1.1 Mechanism
Nexus uses **Laravel Sanctum** for API token-based authentication.

- **Token type**: Bearer token
- **Token storage**: `personal_access_tokens` table in database
- **Token transmission**: `Authorization: Bearer {token}` HTTP header

### 1.2 Auth Flow

```
POST /api/auth/login
  Body: { email, password }
  Response: { token, user }

→ Store token (frontend memory or secure cookie)
→ All subsequent requests include: Authorization: Bearer {token}
→ Sanctum middleware validates token on every protected route
→ Token revocation: POST /api/auth/logout (deletes token from DB)
```

### 1.3 Auth Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/auth/login` | POST | Login with email/password → returns token |
| `/api/auth/register` | POST | Create new user account |
| `/api/auth/logout` | POST | Revoke current token |
| `/api/auth/verify` | GET | Validate current token |
| `/api/auth/refresh` | POST | Rotate to new token |

### 1.4 Middleware Stack

```php
// Protected routes use:
'auth:sanctum'       // Validates Bearer token
'api'                // JSON response, CORS headers

// Admin routes additionally use:
'is_admin'           // Checks user.is_admin === true
```

---

## 2. Authorization (Role-Based)

### 2.1 User Roles

| Role | Flag | Access |
|------|------|--------|
| Regular User | — | Their own contacts, agents, workflows |
| Admin | `is_admin = true` | Admin dashboard, DLQ management, system logs |
| Super Admin | `is_super_admin = true` | Full system access |

### 2.2 Resource Authorization
- Controllers check ownership via `where('user_id', auth()->id())`
- Admin controllers protected by `IsAdmin` middleware class
- `SessionPolicy` handles granular session-level authorization

---

## 3. Data Encryption

### 3.1 API Key Encryption
All AI provider API keys are encrypted at rest using **AES-256-CBC** via `CredentialEncryptionService`.

```php
// EncryptedApiKeyStorage stores keys encrypted
// They are decrypted only at request time
$key = $storage->decrypt($encryptedKey);
```

### 3.2 Settings Encryption
Sensitive settings (API credentials, webhooks secrets) are flagged as `encrypted = true` in the settings table and are encrypted before storage.

### 3.3 Password Hashing
User passwords are hashed using **bcrypt** with 12 rounds (configurable).

---

## 4. CORS Configuration

- **Allowed origins**: Configured to match frontend URL (`FRONTEND_URL` env var)
- **Allowed methods**: `GET`, `POST`, `PUT`, `PATCH`, `DELETE`, `OPTIONS`
- **Allowed headers**: `Content-Type`, `Authorization`, `X-Idempotency-Key`, `X-Requested-With`
- **Exposed headers**: `X-RateLimit-Limit`, `X-RateLimit-Remaining`

---

## 5. Idempotency

Critical write operations support idempotency to prevent duplicate processing:

```
POST /api/contacts
Headers: X-Idempotency-Key: unique-client-key-123

→ First request: Creates contact, stores key hash in DB
→ Duplicate request with same key: Returns original response
→ Key hash expires after 24 hours
```

**Implemented in**: `IdempotencyService`, Contact creation.

---

## 6. Rate Limiting

Laravel's built-in rate limiting is applied to all API routes:
- **Default**: 60 requests per minute per user
- **AI endpoints**: Additional throttling to manage LLM costs
- **Webhook endpoints**: Separate limits for inbound webhooks

---

## 7. WebSocket Security (Reverb)

- **Channel authentication**: Private channels require server-side auth
- **Channel naming**: `nexus.{entity}.{id}` convention
- **Auth endpoint**: `/broadcasting/auth`
- **Token validation**: Sanctum token verified during channel subscription

---

## 8. Audit Trails

| Trail Type | Model | What is logged |
|-----------|-------|----------------|
| **AI Decisions** | `AiAuditTrail` | Every AI model call: model, tokens, cost, provider, latency |
| **Contact Events** | `ContactAuditEvent` | Create, update, delete, merge, enrich, erase |
| **Agent Actions** | `AgentRuntimeLog` | Agent execution start, steps, completion, failure |
| **HedraSoul Traces** | `SoulyActionTrace` | Every HedraSoul intent: parsed intent, action taken, tools used, cost |
| **System Logs** | `SystemLog` | Authentication events, admin actions |

---

*Last updated: 2026-06-14 | Nexus v2 Documentation*
