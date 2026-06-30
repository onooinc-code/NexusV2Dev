# Hedra Soul Hub (hedra-soul)

## Overview
The Hedra Soul Hub is the private communication and command center for the user to interact directly with "Souly". It acts as the core Chat Interface but highly specialized with control panels for modifying the agent's autonomy and permissions.

## Design Details
- **Background**: `bg-[#0d1117]`. Full screen, hidden overflow.
- **Layout**: 
  - Topbar full width.
  - 3-Column Split View:
    1. **Left (256px / w-64)**: Session List
    2. **Center (flex-1)**: Message Panel and Composer
    3. **Right (320px / w-80)**: Control Panel

## Core Features

### 1. Topbar (`NxHedraTopbar`)
- Displays Souly's real-time status (online [green], thinking [amber], offline [red]).
- Displays the Active Model instance and current Autonomy Mode.
- Shows badges for Notification Count and pending Approval Count.
- **Emergency Pause Button**: Instantly sets autonomy mode to `emergency_paused` to halt all autonomous actions.

### 2. Session List (`NxSessionList` - Left Column)
- Button to create a "New Session".
- Lists active sessions with their title, topic, and message count.
- Highlighting the currently selected session.

### 3. Message Area (`NxHedraSoulMessagePanel` & Composer - Center Column)
- **Message List**: Chat bubbles colored by sender (User: purple, Agent: blue, System: gray).
  - Shows streaming indicators (pulsing dots) for incoming messages.
  - Displays the detected "Intent" of the message if applicable.
- **Composer**: Textarea with Ctrl+Enter to send. Supports Markdown.

### 4. Control Panel (`NxSoulyControlPanel` - Right Column)
- **Autonomy Mode Toggles**:
  - `chat_only`, `copilot`, `operator`, `autopilot_limited`, `emergency_paused`.
  - Instantly updates the runtime profile of the AI.
- **Access Controls (Read-Only Checkboxes)**:
  - Memory Access, Contact Access, Task Execution, Workflow Execution, External Messaging.
- **System Status details**:
  - Quarantined status.
  - Active Instruction Version.
  - Active Model ID.
