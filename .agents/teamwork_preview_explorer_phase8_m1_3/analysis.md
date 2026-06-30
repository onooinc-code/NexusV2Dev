# Analysis Report: NxTopicsViewer Mentions Expansion

## 1. Problem Boundary
The task requires updating `NxTopicsViewer` to allow users to click a topic row, expanding it to display an inline list of mentions. Mentions should be fetched from the backend API (`GET /api/v1/contacts/{contactId}/topics/{topicId}/mentions`) and rendered using the existing `NxSourceCitation` component. Furthermore, we must add an "analysis_run_id" link and confidence badge to the topic header if applicable.

## 2. Core Observations
- **Location**: Frontend component at `Nexus-Frontend/components/NxTopicsViewer.tsx`.
- **Existing Model (`Topic`)**: Currently only includes `id`, `topic`, `mention_count`, `mentions_count`, and `trend`. It lacks `analysis_run_id`.
- **API Client**: Existing fetches use `apiClient.get('/contacts/${contactId}/topics')`. The route `/contacts/{id}/topics/{topic}/mentions` exists on the backend but is currently returning a hardcoded `['data' => []]`. 
- **`NxSourceCitation` Props**: Defined in `Nexus-Frontend/components/NxSourceCitation.tsx`. It takes `title`, `url`, `snippet`, `relevanceScore`, and `className`.

## 3. Required Frontend Changes
### Interfaces & State
- **Add fields to `Topic`**: `analysis_run_id?: number | string;`, `confidence_score?: number;`
- **Create `Mention` interface**:
  ```tsx
  interface Mention {
    id: number;
    excerpt?: string;
    message?: { body?: string; sender_identifier?: string; source_timestamp?: string };
    sender?: string;
    timestamp?: string;
    created_at?: string;
    analysis_run_id?: number | string;
  }
  ```
- **Add State Variables**:
  ```tsx
  const [expandedTopicId, setExpandedTopicId] = useState<number | null>(null);
  const [mentionsData, setMentionsData] = useState<Record<number, Mention[]>>({});
  const [mentionsLoading, setMentionsLoading] = useState<Record<number, boolean>>({});
  const [mentionsError, setMentionsError] = useState<Record<number, string>>({});
  ```

### Handlers
- **`handleExpandTopic`**: Toggles the `expandedTopicId`. On expand, checks if `mentionsData[topicId]` exists. If not, fetches it via `apiClient.get('/contacts/${contactId}/topics/${topicId}/mentions')` and caches it.

### UI Rendering
- **Topic Header**: 
  - Add `onClick={() => handleExpandTopic(topic.id)}` to the topic row and change cursor to pointer.
  - If `topic.analysis_run_id` exists, append a small "High Confidence" badge (or similar) and an anchor tag linking to `/contacts/${contactId}/analysis-runs/${topic.analysis_run_id}` inside the topic details column.
- **Expanded Mentions Container**: 
  - Conditionally rendered beneath the topic header when `expandedTopicId === topic.id`.
  - Handles local loading (`Loader2`), error state text, and empty state ("No mentions found").
  - Maps `mentionsData[topic.id]` to `<NxSourceCitation>` instances:
    - `title`: Combination of `mention.sender` (fallback to `Unknown`) and formatted `mention.timestamp`.
    - `snippet`: `mention.excerpt` or `mention.message.body`.
    - `url`: Construct the run link if `mention.analysis_run_id` exists (`/contacts/${contactId}/analysis-runs/${mention.analysis_run_id}`).

## 4. Caveats
- The backend implementation for `topicMentions` in `ContactController.php` (line 647) currently returns a hardcoded empty array `return response()->json(['data' => []]);`. The frontend will successfully call the endpoint but will only display "No mentions found" until the backend logic is populated. This frontend update can be merged independently.
- The prompt implies mapping backend response fields `sender`, `timestamp`, `excerpt`, and `analysis_run_id` to `NxSourceCitation`. The exact structure from the backend API isn't finalized, so the frontend code must defensively check fallbacks (e.g. `mention.excerpt || mention.message?.body`).
