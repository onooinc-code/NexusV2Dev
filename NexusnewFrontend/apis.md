# APIs & MCP Integration Hub (apis)

## Overview
Manage external APIs and Model Context Protocol (MCP) server connections. This hub acts as the control panel for defining and connecting tool servers for AI agents to use.

## Design Details
- **Header**: Icon (Network, blue), title, and two buttons ("Refresh" with a spin animation and "Add MCP Server").
- **Container**: `NxGlassCard` wrapping the main content area.
- **Empty State**: Shows a prominent `Network` icon if no servers are configured.

## Core Features

### 1. MCP Server List
- Fetches the list of MCP servers configured in the system.
- Displays each server as a bordered card (`bg-slate-800/50`).
- **Server Card Details**:
  - Name and connection status (CheckCircle2 for connected/online, XCircle for disconnected).
  - Config details displayed in a single line monospace format.
  - Status badge (e.g., `CONNECTED`).
  - Connect/Disconnect toggle button (`bg-emerald-500/10` vs `bg-red-500/10`).
  - Quick action buttons to Edit or Delete the server.

### 2. Connection Management
- Connecting and Disconnecting a server directly communicates with the global state (and underlying API).

## Missing Features / Enhancements needed for Laravel
- The "Add MCP Server" button in Next.js has an empty `onClick={() => {}}`. A real modal/drawer needs to be created to input the MCP server details (Name, Transport Type like STDIO/SSE, and the Command/URL).
- Connection status polling using AJAX or Echo since it's a monolith.
