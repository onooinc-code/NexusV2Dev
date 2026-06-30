# Agents Hub — Requirements

## Introduction

AgentsHub is the central interface for managing AI agents in the Nexus system. It allows administrators to register and monitor agents, define agent personas (system prompts and behavioral traits), manage MCP server connections, browse the tools library, and run agents in a live playground sandbox.

## Glossary

| Term | Definition |
|------|-----------|
| Agent | A configured AI entity with a name, type, status, assigned persona, and tool/skill set |
| Persona | A reusable behavioral profile containing a system prompt, temperature, max tokens, and reasoning effort |
| MCP Server | A Model Context Protocol server that grants agents access to external tools and resources |
| Tool | A discrete capability (API call, file operation, etc.) available for agents to invoke |
| Playground | An interactive sandbox for executing or simulating an agent against a custom task input |
| Quarantine | An emergency status that halts an agent and cuts off its tool access |
| Kill-Switch | A global or per-agent emergency pause mechanism |

---

## Requirement 1: Agent Registry

**User Story:** As an administrator, I want to see all registered agents with their current status and usage, so that I can monitor the agent fleet at a glance.

### Acceptance Criteria

1. WHEN the user opens AgentsHub, THE system SHALL call GET `/agents` and display agents in a responsive grid of `NxAgentCard` components.
2. WHILE agents are loading, THE system SHALL display a loading indicator.
3. WHEN no agents are registered, THE system SHALL display an empty state with a "Sync Registry" button that calls `hydrateAgents()`.
4. THE stats panel above the grid SHALL show: total active agents (online + busy / total), total token executions (sum of tokenUsage across all agents), and quarantined agents count (status === 'error').
5. EACH agent card SHALL display: agent name, role/type, status badge (online=green pulse, busy=amber pulse, offline=gray, error=red), and token usage count.
6. THE user SHALL be able to click an agent card to trigger the `onSelectAgent` callback for downstream actions (e.g., open detail drawer or switch to Playground with that agent pre-selected).
7. A "Refresh Data" button in the header SHALL call `hydrateAgents()` to reload the agent list.
8. THE agent grid SHALL support a detail drawer (`NxDrawer`) that opens when clicking an agent, allowing inline editing of: name, temperature, max tokens, custom guidelines/system prompt, and persona assignment.
9. THE drawer SHALL include a "Reset to Defaults" button that restores the agent's archetype defaults.
10. THE system SHALL support quarantining an agent (calling POST `/agents/{id}/quarantine`) which sets status to `error` and shows a visual quarantine indicator on the card.

---

## Requirement 2: Agent Personas

**User Story:** As an administrator, I want to create and manage agent personas with custom system prompts and parameters, so that agents can exhibit distinct behavioral traits.

### Acceptance Criteria

1. WHEN the user opens the Personas tab, THE system SHALL call `hydratePersonas()` (GET `/agent-personas`) and display all personas as cards.
2. WHILE personas are loading, THE system SHALL display a centered loading spinner.
3. WHEN no personas exist, THE system SHALL display an empty state with a prompt to create one.
4. THE user SHALL be able to create a new persona via an inline form with fields: Name (required), Description, Temperature (0–2, step 0.1), Max Tokens (positive integer), Reasoning Effort (low/medium/high), and System Prompt (required, multi-line textarea).
5. WHEN the "New Persona" button is clicked, THE creation form SHALL expand inline above the persona grid.
6. WHEN the "Cancel" button is clicked while creating, THE form SHALL collapse without saving.
7. WHEN a valid persona form is submitted, THE system SHALL call `createPersona()` (POST `/agent-personas`) and add the new persona card without a full page reload.
8. EACH persona card SHALL display: persona name, description (truncated), and a preview of the system prompt (truncated, monospace font).
9. THE user SHALL be able to delete a persona via a delete icon that appears on hover, calling `deletePersona()` (DELETE `/agent-personas/{id}`).
10. THE user SHALL be able to edit an existing persona via an edit icon, opening the form pre-filled with the persona's current values.

---

## Requirement 3: MCP Servers

**User Story:** As an administrator, I want to register and manage MCP server connections, so that agents can access external tools and resources.

### Acceptance Criteria

1. WHEN the user opens the MCP Servers tab, THE system SHALL call `hydrateMCPServers()` and display all registered servers.
2. WHILE servers are loading, THE system SHALL display a centered loading spinner.
3. WHEN no servers are registered, THE system SHALL display an empty state.
4. THE user SHALL be able to register a new MCP server via an inline form with fields: Server Identifier (required), Server Type (local/remote), and Connection Configuration (JSON textarea, required).
5. FOR local servers, THE configuration hint SHALL indicate "command" and "args" are required. FOR remote servers, THE hint SHALL indicate "url" is required.
6. WHEN the connection config JSON is invalid, THE system SHALL alert the user with "Invalid JSON format in connection config."
7. WHEN a server is saved, THE system SHALL call `createMCPServer()` and add the new server card.
8. EACH server card SHALL display: server identifier, type badge, online/offline status with color-coded indicator, and the raw connection config in a scrollable JSON preview.
9. THE user SHALL be able to connect an offline server via a "Connect" button calling `connectMCPServer(name)`.
10. THE user SHALL be able to disconnect an online server via a "Disconnect" button calling `disconnectMCPServer(name)`.
11. THE user SHALL be able to delete a server via a trash icon button calling `deleteMCPServer(id)`.

---

## Requirement 4: Tools Library

**User Story:** As an administrator, I want to browse all tools available to agents, so that I can understand what capabilities are accessible.

### Acceptance Criteria

1. WHEN the user opens the Tools tab, THE system SHALL fetch tools from GET `/api/v1/agent-tools` and display them as cards.
2. WHILE tools are loading, THE system SHALL display a centered loading spinner.
3. WHEN no tools are found, THE system SHALL display an empty state.
4. EACH tool card SHALL display: tool name, category badge, description (truncated to 3 lines), and optional configuration schema (if `config` is non-empty).
5. THE tools grid SHALL be responsive: 1 column on mobile, 2 on tablet, 3 on desktop.

---

## Requirement 5: Agent Playground

**User Story:** As an administrator, I want to execute or simulate an agent against a custom task prompt, so that I can test agent behavior before deploying it in production workflows.

### Acceptance Criteria

1. THE Playground tab SHALL display a two-panel layout: a settings panel (left/top) and an execution output panel (right/bottom).
2. THE settings panel SHALL include: a Target Agent selector (dropdown populated from the loaded agents list), and a Task Prompt textarea.
3. THE settings panel SHALL provide two action buttons: "Simulate Execution" (calls `simulateAgent(id, payload)`) and "Run Real Execution" (calls `runAgent(id, payload)`).
4. BOTH buttons SHALL be disabled when no agent is selected or the task prompt is empty.
5. WHILE execution is in progress, THE active button SHALL show a loading spinner and the other button SHALL be disabled.
6. EACH execution result SHALL appear as a log entry in the output panel with: entry type label (SIMULATE / RUN / ERROR), timestamp, and the full JSON response or error string in a code block.
7. THE output panel SHALL display "Waiting for execution..." when no logs exist.
8. EACH error log entry SHALL have a red background; successful entries SHALL have a blue tinted background.
9. AFTER execution completes, THE system SHALL call `fetchAgentStatus(id)` to refresh the agent's current status.

---

## Requirement 6: Navigation & Layout

**User Story:** As an administrator, I want a clearly structured tabbed interface for AgentsHub, so that I can efficiently navigate between different management areas.

### Acceptance Criteria

1. THE page SHALL render within `AppLayout` with the title "AI Agent Hub."
2. THE page SHALL provide five tabs: Agents, Personas, Tools, MCP Servers, and Playground.
3. THE tabs SHALL use underline-style navigation.
4. THE header SHALL include a "Refresh Data" button visible on all tabs.
5. THE page SHALL support responsive layout on mobile screens.
6. EACH tab content area SHALL have a minimum height of 500px to prevent layout collapse.
