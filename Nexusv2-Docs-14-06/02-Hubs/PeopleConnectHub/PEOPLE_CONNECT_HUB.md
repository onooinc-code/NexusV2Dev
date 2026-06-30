# PeopleConnectHub — Full Documentation

## Hub Overview

PeopleConnectHub is the live messaging layer of Nexus. It connects real-time WhatsApp conversations (via WAHA API) to Nexus contacts, enabling agents to read incoming messages, send replies, and automatically extract memories and insights from live conversations.

---

# Part 1: Backend Documentation

## 1.1 API Endpoints

| Method | Endpoint | Controller | Description |
|--------|----------|-----------|-------------|
| GET | `/api/people-connect/conversations` | `PeopleConnectController@index` | List active conversations |
| GET | `/api/people-connect/conversations/{id}` | `PeopleConnectController@show` | Conversation detail |
| POST | `/api/people-connect/conversations/{id}/reply` | `PeopleConnectController@reply` | Send reply |
| GET | `/api/people-connect/live-msgs` | `LiveMsgsController@index` | Live message feed |
| POST | `/api/webhooks/waha` | `WebhookController@handleWahaWebhook` | WAHA incoming webhook |

---

## 1.2 Architecture & Integrations

### WAHA API Integration
WAHA (WhatsApp HTTP API) is a self-hosted or cloud service that exposes WhatsApp functionality via REST:

```
Incoming WhatsApp message → WAHA → Webhook → Nexus
Nexus sends reply → WAHA API → WhatsApp contact
```

**Configuration:**
```env
WAHA_BASE_URL=http://localhost:3000
WAHA_SESSION=default
WAHA_API_KEY=your-api-key
```

### WahaWebhookIngestionService
Processes incoming WAHA webhook payloads:

```php
// Parses WhatsApp message payload
// Resolves contact by phone number / WhatsApp ID
// Creates/updates ContactMessage record
// Fires MessageReceived event
// Triggers real-time broadcast to frontend
$service->ingest($webhookPayload);
```

### WahaMessageDispatcher
Sends outbound messages via WAHA:

```php
// Sends text message to WhatsApp contact
$dispatcher->send([
  'chatId'   => '201234567890@c.us',
  'text'     => 'Hello from Nexus!',
  'session'  => 'default',
]);
```

### PeopleConnectContactResolver
Maps incoming WhatsApp numbers to Nexus contacts:

```php
// Lookup by whatsapp_id in ContactIdentifier
// If not found → create new contact with whatsapp_id
$contact = $resolver->resolve($wahaPayload);
```

### PeopleConnectContextAssembler
Builds AI context for reply generation:

```php
// Assembles: contact memory + recent messages + preferences
// Used to generate contextually-aware AI replies
$context = $assembler->assemble($contact, $conversation);
```

### PeopleConnectReplyModeService
Determines reply mode for a contact:

```php
// Reply modes: 'manual', 'agent_suggested', 'fully_automated'
// Determined by: ContactReplyRule, ContactPreference, system config
$mode = $service->getReplyMode($contact);
```

### LiveMsgsSyncService
Syncs live messages to the frontend in real-time:

```php
// On new message → broadcast via WebSocket
// Channel: nexus.people-connect.{userId}
// Event: NewWhatsAppMessage
```

---

## 1.3 Contact Message Flow

```
WhatsApp user sends message to configured number
  ↓
WAHA receives message → fires webhook → POST /api/webhooks/waha
  ↓
WahaWebhookIngestionService.ingest($payload)
  ↓
PeopleConnectContactResolver.resolve($payload)
  → Finds contact by whatsapp_id OR creates new contact
  ↓
ContactMessage record created
  ↓
PeopleConnectRealtimeBroadcaster.broadcastNewMessage($message)
  → WebSocket event: 'NewWhatsAppMessage'
  ↓
Frontend receives event → adds to conversation feed
  ↓
[Optional] PeopleConnectAnalysisService extracts memory from message
  → Memory stored: relevant facts, topics, sentiment
```

---

## 1.4 AI-Assisted Replies

When in `agent_suggested` mode:

```
User views incoming message in PeopleConnectHub
  → Clicks "Generate Reply"
  → POST /api/people-connect/conversations/{id}/generate-reply
  → PeopleConnectContextAssembler builds context
  → UniversalAiGatewayService generates reply
  → Suggested reply shown to user
  → User edits/approves → sends via WahaMessageDispatcher
```

---

# Part 2: Frontend Documentation

## 2.1 Hub Page (`app/people-connect/page.tsx`)

Features:
- Live conversation feed (left panel)
- Active conversation view (right panel) with message bubbles
- Contact info panel linked to ContactsHub
- Reply input with AI suggest button
- Contact status indicator (online/typing via WAHA)
- Auto-scroll to newest messages

## 2.2 Key Components

| Component | Purpose |
|-----------|---------|
| `NxMessageBubble` | Individual message bubble (in/out) |
| `NxChatInput` | Message input with emoji and attachment support |
| `NxMessageActions` | Per-message actions (reply, copy, save as memory) |
| `NxConnectionStatus` | WAHA connection health indicator |
| `NxConnectionDot` | Live status dot for conversation |

## 2.3 Real-Time Messaging

```typescript
// Subscribe to live messages
Echo.private(`nexus.people-connect.${userId}`)
  .listen('NewWhatsAppMessage', (msg) => {
    addMessage(msg);
    scrollToBottom();
    notifyIfMinimized(msg);
  })
  .listen('MessageDelivered', (e) => updateStatus(e))
  .listen('MessageRead', (e) => updateStatus(e));
```

## 2.4 TypeScript Types

```typescript
interface WhatsAppMessage {
  id: string;
  contact_id: string;
  direction: 'in' | 'out';
  body: string;
  type: 'text' | 'image' | 'document' | 'audio';
  whatsapp_id: string;
  status: 'pending' | 'sent' | 'delivered' | 'read' | 'failed';
  received_at: string;
  sent_at: string | null;
}

interface ActiveConversation {
  contact: Contact;
  messages: WhatsAppMessage[];
  reply_mode: 'manual' | 'agent_suggested' | 'fully_automated';
  unread_count: number;
}
```

---

*Last updated: 2026-06-14 | Nexus v2 Documentation*
