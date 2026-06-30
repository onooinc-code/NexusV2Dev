# AIModelsHub — Full Documentation

## Hub Overview

AIModelsHub is the AI infrastructure management layer of Nexus. It provides a unified interface to configure, test, monitor, and route AI model requests across multiple LLM providers. No direct LLM calls are made anywhere in Nexus without passing through this hub's gateway.

---

# Part 1: Backend Documentation

## 1.1 API Endpoints

### Providers
| Method | Endpoint | Controller | Description |
|--------|----------|-----------|-------------|
| GET | `/api/ai-providers` | `AiProviderController@index` | List all providers |
| POST | `/api/ai-providers` | `AiProviderController@store` | Register new provider |
| GET | `/api/ai-providers/{id}` | `AiProviderController@show` | Provider details |
| PUT | `/api/ai-providers/{id}` | `AiProviderController@update` | Update provider |
| DELETE | `/api/ai-providers/{id}` | `AiProviderController@destroy` | Remove provider |
| POST | `/api/ai-providers/{id}/test` | `AiProviderController@test` | Test connectivity |
| POST | `/api/ai-providers/{id}/sync-models` | `AiProviderController@syncModels` | Sync available models |

### Models
| Method | Endpoint | Controller | Description |
|--------|----------|-----------|-------------|
| GET | `/api/ai-models` | `AiModelController@index` | List all models |
| POST | `/api/ai-models` | `AiModelController@store` | Register model |
| GET | `/api/ai-models/{id}` | `AiModelController@show` | Model details |
| PUT | `/api/ai-models/{id}` | `AiModelController@update` | Update model |
| POST | `/api/ai-models/{id}/execute` | `AiModelController@execute` | Execute with model |
| POST | `/api/ai-models/{id}/execute-with-fallback` | Execute with fallback chain |
| GET | `/api/ai-models/providers` | List available providers |
| GET | `/api/ai-models/key-pool-status` | API key pool health |
| GET | `/api/ai-models/rate-limit-status` | Current rate limits |
| GET | `/api/ai-models/budget-status` | Budget consumption |

### Routing & Analytics
| Method | Endpoint | Controller | Description |
|--------|----------|-----------|-------------|
| GET | `/api/ai-routing/matrix` | `AiRequestController@getRoutingMatrix` | Intent routing rules |
| PUT | `/api/ai-routing/intent/{intent}` | `AiRequestController@routeIntent` | Update routing |
| GET | `/api/ai-cost-analytics` | `AiCostAnalyticsController` | Cost reports |
| GET | `/api/ai-instances` | `AiInstanceController@index` | AI instance log |

---

## 1.2 Core Services

### UniversalAiGatewayService
**Single entry point for all LLM calls in Nexus:**

```php
// All AI calls go through this gateway
$response = $gateway->complete([
  'model'   => 'gpt-4o',
  'messages' => [...],
  'intent'  => 'analysis',
]);

// Internally:
// 1. IntentRoutingEngine selects provider
// 2. DynamicProviderRegistry resolves provider instance
// 3. DynamicRestProvider makes HTTP call
// 4. UsageTracker logs tokens + cost
// 5. AiAuditTrail records decision
// 6. Returns standardized response
```

### IntentRoutingEngine
Maps incoming intents to the best provider/model:

```php
// Intent types: 'analysis', 'code_generation', 'summarization',
//               'translation', 'embedding', 'chat', 'vision'
$routing = $engine->selectModel($intent, $options);
// Returns: { provider, model, api_key_id }
```

### DynamicProviderRegistry
Manages all registered provider instances:

```php
// Supports: openai, anthropic, google_gemini, groq, custom_rest
$provider = $registry->resolve($providerId);
// Returns: DynamicRestProvider instance configured for that provider
```

### DynamicRestProvider
Universal HTTP adapter supporting OpenAI-compatible APIs:

```php
// Works with any OpenAI-compatible endpoint
// Handles: request formatting, response parsing, streaming
// Adapts: different API schemas via PayloadAdapterFactory
```

### ApiKeyPool + EncryptedApiKeyStorage
```php
// Manages multiple API keys per provider
// Rotates keys on rate limits or errors
// Tracks key health and expiry
// All keys stored AES-256 encrypted
$key = $keyPool->selectBestKey($providerId);
```

### CircuitBreaker (per provider)
```php
// Opens circuit after N consecutive failures
// Returns 503 for open circuits (fail-fast)
// Resets after recovery timeout
$breaker->checkState($providerId); // 'closed' | 'open' | 'half_open'
```

### UsageTracker + UsageCalculator
```php
// Logs every LLM call to usage_logs table
// Calculates: prompt_tokens × input_cost + completion_tokens × output_cost
// Aggregates by provider/model/user/day
```

---

## 1.3 Routing Decision Flow

```
AI Request arrives (with intent: 'code_generation')
  ↓
IntentRoutingEngine checks IntentRouting table
  ↓
Finds routing profile: { preferred: 'claude-3-5-sonnet', fallbacks: ['gpt-4o'] }
  ↓
DynamicProviderRegistry checks:
  → Is circuit closed for Anthropic? YES
  → Is API key available? YES (select best key)
  → Is budget available? YES
  ↓
DynamicRestProvider sends request to Anthropic API
  ↓
On failure → try next model in fallback chain
  ↓
UsageTracker logs response metrics
  ↓
AiAuditTrail records full decision trace
```

---

# Part 2: Frontend Documentation

## 2.1 Hub Page (`app/ai-models/page.tsx`)

The AIModelsHub frontend displays:
- **Provider cards**: Each registered provider with health status
- **Model table**: All available models with capabilities, cost, speed tier
- **API Key management**: Add, rotate, check health of API keys
- **Routing configuration**: Map intents to preferred models
- **Cost analytics**: Charts of token usage and spending
- **Rate limit status**: Current usage vs limits per provider

## 2.2 Key Components

| Component | Purpose |
|-----------|---------|
| `NxProviderDots` | Visual health indicators for AI providers |
| `NxModelSelector` | Dropdown for selecting AI models |
| `NxTokenBudget` | Token/cost budget display and configuration |
| `NxIntentGrid` | Configure intent-to-model routing rules |

## 2.3 Frontend API Client (`lib/api/ai-models.ts`)

```typescript
fetchProviders(): Promise<AIProvider[]>
createProvider(data: CreateProviderData): Promise<AIProvider>
testProvider(id: string): Promise<TestResult>
syncModels(providerId: string): Promise<AIModel[]>

fetchModels(providerId?: string): Promise<AIModel[]>
executeModel(id: string, prompt: string): Promise<AIResponse>

fetchRoutingMatrix(): Promise<IntentRoutingRule[]>
updateIntentRouting(intent: string, modelId: string): Promise<void>

fetchCostAnalytics(period: string): Promise<CostReport>
fetchKeyPoolStatus(): Promise<KeyPoolStatus>
fetchBudgetStatus(): Promise<BudgetStatus>
```

---

# Part 3: Integration Notes

## 3.1 Provider Registration Flow
```
User clicks "Add Provider"
  → Fills: name, type, base_url, api_key
  → POST /api/ai-providers
  → Key encrypted and stored
  → POST /api/ai-providers/{id}/test → validates connectivity
  → POST /api/ai-providers/{id}/sync-models → fetches available models
  → Models appear in model table
```

## 3.2 Supported Provider Types

| Provider | Type Key | Base URL |
|----------|---------|---------|
| OpenAI | `openai` | `https://api.openai.com` |
| Anthropic | `anthropic` | `https://api.anthropic.com` |
| Google Gemini | `google_gemini` | `https://generativelanguage.googleapis.com` |
| Groq | `groq` | `https://api.groq.com` |
| Custom REST | `custom_rest` | User-defined |
| OpenAI-compatible | `openai_compatible` | User-defined (e.g., LM Studio, Ollama) |

---

*Last updated: 2026-06-14 | Nexus v2 Documentation*
