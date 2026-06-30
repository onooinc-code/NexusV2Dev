# Task Scheduler (scheduler)

## Overview
The Task Scheduler allows users to manage recurring tasks, webhook triggers, and cron expressions. It acts as a UI for Laravel's task scheduling, or a custom database-driven job runner.

## Design Details
- **Header**: Icon (Clock, blue, pulsing), title, description, and "New Job" button.
- **Grid Layout**: Responsive grid of `NxGlassCard` components representing each job.
- **Card Design**:
  - Gradient top border (pulse animation) if `is_running` is true.
  - **Header**: Job Name, Job Type (monospace badge), Status (active/paused badge with colors).
  - **Details**: Cron expression with calendar icon. Next run time and Last run time.
  - **Action Bar** (visible on hover): Play/Pause, Edit, and Delete buttons.

## Core Features

### 1. Job List
- Fetches jobs from the backend API.
- Displays jobs grouped/ordered visually.
- Handles start/stop/pause actions.
- Handles job deletion.

### 2. Job Creation/Editing Modal
- **Trigger**: "New Job" or "Edit" button.
- **Form Fields**:
  - **Job Name**: Text input.
  - **Type**: Select dropdown (`command`, `job`, `webhook`, `script`).
  - **Cron Expression**: Text input (e.g. `* * * * *`).
  - **Payload (JSON)**: Textarea for JSON payload data.
- **Submission**: Validates JSON and saves via POST/PUT.

## Porting Considerations to Laravel
- Requires a backend `SchedulerJob` model to store these dynamic scheduled tasks.
- Requires a custom Laravel Console Kernel schedule that queries these dynamic database jobs and dispatches them if their cron expression matches the current time.
