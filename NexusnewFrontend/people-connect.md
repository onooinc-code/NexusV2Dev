# People Connect Hub (people-connect)

## Overview
The People Connect Hub is a private communication and relationship management center. It acts as an inbox for external communications (e.g., WAHA WhatsApp Sync) and allows the user to interact with contacts and monitor AI (Souly) interactions with those contacts.

## Design Details
- **Background**: `bg-surface-dark` (Dark theme, `#0d1117`).
- **Layout**: Full-screen flex container (`h-screen flex-col overflow-hidden`).
- **Structure**:
  1. **Topbar** (`NxPeopleConnectTopbar`): Shows synchronization status, stats, and a "Sync All" button.
  2. **Main Area**: A split-pane view (flex row).
     - **Sidebar** (`NxConversationSidebar`): List of conversations and search functionality.
     - **Center Panel**: If a conversation is selected, shows Header, Message Panel, and Composer. If empty, shows a placeholder state with an icon.

## Core Features
1. **Real-time Stats**: Loads total conversations, unread counts, etc.
2. **Search & Filter**: Allows searching conversations by contact name or details.
3. **WAHA Synchronization**: A button to trigger `peopleConnectApi.triggerSync('all')` with a spinner state (`isSyncing`).
4. **Conversation List**: 
   - Displays contacts/conversations.
   - Shows unread counts, last message preview, and timestamps.
   - Highlighting the currently selected conversation.
5. **Message Panel** (`NxMessagePanel`):
   - Shows chronological stream of messages between the system/user and the contact.
   - Supports real-time updates when new messages arrive.
6. **Composer** (`NxComposer`):
   - Textarea to reply to the contact.
   - Awareness of the `reply_mode_effective` (e.g., whether the AI is on auto-reply or if manual intervention is needed).

## Missing Features to Port to Laravel
- Realtime WebSocket listeners (using Laravel Echo / Reverb) to update the `unread_count` and insert new messages instantly.
- The `isSyncing` state for WhatsApp/WAHA integration.
