# Handoff Report: Task 11.1 (NxTopicsViewer Mentions Expansion)

## 1. Observation
- `NxTopicsViewer` is located at `Nexus-Frontend/components/NxTopicsViewer.tsx`.
- The current `Topic` interface in `NxTopicsViewer.tsx` has `id`, `topic`, `mention_count`, `mentions_count`, and `trend`, but lacks `analysis_run_id` and `confidence_score`.
- `NxSourceCitation` is located at `Nexus-Frontend/components/NxSourceCitation.tsx` and accepts props: `title`, `url`, `snippet`, `relevanceScore`, and `className`.
- The backend API endpoint `/api/v1/contacts/{id}/topics/{topic}/mentions` exists in `routes/api.php` and maps to `ContactController@topicMentions`.
- In `ContactController.php`, `topicMentions` currently returns an empty array: `return response()->json(['data' => []]);`.
- API calls in the frontend omit the `/api/v1` prefix because `apiClient` inherently targets the API base URL (e.g. `apiClient.get('/contacts/${contactId}/topics')`).

## 2. Logic Chain
1. To display citations, we must update the `NxTopicsViewer` component to manage state for `expandedTopicId` and cache fetched `mentionsData`.
2. When a topic row is clicked, a handler must trigger a fetch to `apiClient.get('/contacts/${contactId}/topics/${topicId}/mentions')`.
3. While expanding, the row needs to render a container below the topic details. This container handles loading and error states for the specific fetch.
4. When mentions load successfully, we map the list of objects (typed via a new `Mention` interface) into `NxSourceCitation` components. We map `mention.sender` + `mention.timestamp` into the `title` prop, `mention.excerpt` into `snippet`, and use `mention.analysis_run_id` to generate a `url` (`/contacts/${contactId}/analysis-runs/${mention.analysis_run_id}`).
5. To fulfill the topic header requirements, we conditionally check if `topic.analysis_run_id` exists. If true, we render a confidence badge and an anchor linking to the specific run, ensuring `e.stopPropagation()` so clicking the link doesn't toggle the row expansion.

## 3. Caveats
- The backend `topicMentions` endpoint returns a hardcoded `[]`. During local testing, the frontend will accurately fire the request but always render the "No mentions found" empty state. This is expected until the backend developer wires up `ContactTopicMention` retrieval.
- We assume `NxSourceCitation` should link to the specific analysis run via `/contacts/[contactId]/analysis-runs/[runId]` as there isn't a universally standardized link format documented for analysis runs.
- The `Mention` interface is constructed based on assumptions from the task description (`message excerpt, sender, timestamp, and analysis run ID`). Fallbacks (like checking `mention.message?.body`) should be implemented defensively.

## 4. Conclusion
The frontend UI updates can be fully implemented without waiting for the backend to complete its data retrieval logic. The Implementer should update `Nexus-Frontend/components/NxTopicsViewer.tsx` to include expansion state management, the API fetch call for mentions, rendering of `NxSourceCitation` components in an expanded sub-panel, and the topic header modifications (confidence badge and clickable run ID link).

## 5. Verification Method
- **Static Check**: Confirm `Nexus-Frontend/components/NxTopicsViewer.tsx` contains the `handleExpandTopic` logic and maps `mentionsData` to `NxSourceCitation`.
- **Run project**: Start the frontend and open a contact page that has topics. Click on a topic row.
- **Network Check**: Verify an XHR/fetch request is fired to `/api/contacts/{contactId}/topics/{topicId}/mentions` (or similar, per API client base configuration).
- **UI Check**: Confirm that a loading spinner appears, followed by an empty state or the rendered `NxSourceCitation` components. If a topic has `analysis_run_id`, ensure the badge and link appear in the topic header.
