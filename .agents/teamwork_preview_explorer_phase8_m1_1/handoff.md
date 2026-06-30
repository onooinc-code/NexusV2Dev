# Handoff Report: Task 11.1 (Topics Evidence & Citations)

## 1. Observation
- `NxTopicsViewer` is located at `Nexus-Frontend/components/NxTopicsViewer.tsx` and currently lists `Topic` objects. The `Topic` interface in this file lacks `analysis_run_id` and `confidence` properties. The mapped topic element is a static `div` (Line 92).
- `NxSourceCitation` is located at `Nexus-Frontend/components/NxSourceCitation.tsx`. It accepts `title`, `snippet`, `url`, and `relevanceScore`.
- The endpoint `GET /api/v1/contacts/{contactId}/topics/{topicId}/mentions` is defined in `Nexus-backend/routes/api.php` mapping to `ContactController@topicMentions`.
- In `ContactController.php` line 647, `topicMentions` currently returns a stubbed response: `return response()->json(['data' => []]);`.

## 2. Logic Chain
- To implement topic expansion, `NxTopicsViewer` needs state hooks to track `expandedTopicId` and the `mentions` cache (e.g. `Record<number, Mention[]>`).
- Because the backend currently returns an empty array, the frontend needs to define a `Mention` interface that anticipates the required data: `id`, `message_excerpt`, `sender`, `timestamp`, and optionally `analysis_run_id`.
- The `Topic` interface needs to be updated to include `analysis_run_id?: number` and `confidence?: number` to meet the header requirements.
- The `map` over `topics` needs to be refactored to wrap the current header UI in a clickable toggle `button` and conditionally render an expanded content `div` below it.
- To display a mention, `NxSourceCitation` should be used mapping `Mention` fields: `title` for sender/timestamp, `snippet` for `message_excerpt`, and `url` for the run link.
- Because there is no dedicated Next.js page route explicitly meant for viewing single analysis runs by ID, a placeholder link (like `#` or `?runId=...`) should be used for the run link if `analysis_run_id` is present.

## 3. Caveats
- The backend `topicMentions` endpoint is incomplete. During implementation and local testing, the UI will just display an empty list of citations (unless you manually return mock data from your network client or backend).
- There is no specified frontend route for `analysis_run_id` click behavior in the scope document. I recommend preventing default link behavior or using a placeholder if needed.

## 4. Conclusion
The implementation of Task 11.1 resides entirely within `Nexus-Frontend/components/NxTopicsViewer.tsx` (state, fetching logic, and layout update). The implementer must define the `Mention` schema, augment the `Topic` schema, implement the `expandTopic` API handler, and render `NxSourceCitation` for the list.

## 5. Verification Method
- Ensure the React UI correctly renders a topic's confidence and run ID if added to mocked `Topic` data.
- Run `npm run build` in `Nexus-Frontend` to verify there are no TypeScript errors.
- Ensure that clicking a topic row triggers a network request to `/api/v1/contacts/{contactId}/topics/{topicId}/mentions` (visible in devtools network tab) and sets the row into an expanded state.
