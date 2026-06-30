# Analysis Report

## Summary
The Task 11.1 requires updating the `NxTopicsViewer` component to allow each topic row to be expandable. Upon expansion, it should fetch and display evidence citations (mentions) associated with the topic using the `NxSourceCitation` component. Furthermore, the topic header should include a confidence badge and an analysis run ID link if those properties exist.

## Problem Boundary
- **Objective:** Enable topic expansion to show source citations (mentions) using `NxSourceCitation` and update the topic header to display confidence and analysis run ID.
- **In Scope:** `Nexus-Frontend/components/NxTopicsViewer.tsx` (modifying state and render methods), defining `Mention` types, and handling the API integration for `GET /api/v1/contacts/{contactId}/topics/{topicId}/mentions`.
- **Out of Scope:** Backend implementation of `topicMentions` (currently returns `[]`).

## Key Findings & Evidence
1. **Existing `NxTopicsViewer.tsx` Structure:**
   - Currently, it simply iterates over a list of `Topic` objects and renders static `div` containers.
   - The `Topic` interface lacks `analysis_run_id` and `confidence` fields, which need to be added to support the new header requirements.
   - There is no local state tracking expanded items or fetched mentions.

2. **Existing `NxSourceCitation.tsx` Props:**
   - It requires `title` (string), and optionally accepts `url`, `snippet`, and `relevanceScore`.
   - The task states: *"Render each mention as a `NxSourceCitation` showing: message excerpt, sender, timestamp, and analysis run ID (clickable)."*
   - We can map these fields effectively: `snippet` <- `message_excerpt`, `title` <- sender & timestamp, `url` <- run ID.

3. **Backend API Endpoint:**
   - The route `GET /api/v1/contacts/{contactId}/topics/{topicId}/mentions` exists in `Nexus-backend/routes/api.php` and maps to `ContactController@topicMentions`.
   - However, the `topicMentions` method currently returns a hardcoded empty array (`['data' => []]`). The frontend should therefore define a clear `Mention` interface that expects fields like `id`, `message_excerpt`, `sender`, `timestamp`, and `analysis_run_id`, anticipating the final backend implementation.

## Proposed Component Changes
1. **Extend Interfaces:**
   - Update `Topic`: Add `analysis_run_id?: number` and `confidence?: number`.
   - Create `Mention`: `{ id: number, message_excerpt: string, sender: string, timestamp: string, analysis_run_id?: number }`.
2. **Add State Hooks:**
   - `expandedTopicId` (number | null)
   - `mentions` (Record<number, Mention[]>)
   - `loadingMentions` (Record<number, boolean>)
   - `mentionsError` (Record<number, string>)
3. **Add `expandTopic` Handler:**
   - Function to toggle `expandedTopicId`.
   - If not already cached in `mentions`, set loading to true and fetch via `apiClient.get()`. Handle successes and errors.
4. **Modify Rendering:**
   - Convert the root `div` in the `.map(topic)` loop into a layout containing a clickable header (`button`) and an expandable section.
   - **Header:** Add the UI for a confidence badge and a clickable run ID link (using `topic.confidence` and `topic.analysis_run_id`).
   - **Body:** When `expandedTopicId === topic.id`, conditionally render loading spinners, errors, or the list of `NxSourceCitation` components.
