# Handoff Report: Task 11.1 - Expand Topics with Evidence Citations

## 1. Observation
- `NxTopicsViewer` component is located at `Nexus-Frontend/components/NxTopicsViewer.tsx`. It currently renders static topic cards and uses the `/contacts/${contactId}/topics` endpoint.
- The `Topic` interface in `NxTopicsViewer.tsx` lacks `analysis_run_id` and `confidence_score` fields.
- The backend API provides the mention data via `GET /api/v1/contacts/{contactId}/topics/{topicId}/mentions`, returning a paginated list inside the `data` array.
- The `NxSourceCitation` component (`Nexus-Frontend/components/NxSourceCitation.tsx`) is designed to display evidence citations and accepts `title`, `url`, `snippet`, and `relevanceScore` props.
- Contact models and design docs verify that mentions contain a `message` relation which provides the `body`, `sender`, and `created_at` timestamp. Mentions might also have an `analysis_run_id`.

## 2. Logic Chain
- To meet the requirement of expanding topics to show evidence, we need to track expansion state per topic (`expandedTopics`) in `NxTopicsViewer.tsx`.
- When a topic is expanded, we need to fetch its mentions from the API, tracking loading state (`mentionsLoading`) and errors (`mentionsError`), and storing the fetched mentions (`mentions`).
- The fetched mentions can be rendered within an expanded section of the topic card.
- Each mention can be mapped to an `NxSourceCitation` by constructing the `title` from the message's sender and timestamp, passing the message `body` to `snippet`, and passing the `analysis_run_id` to `url` (e.g. `/analysis-runs/${runId}`).
- To display the confidence badge and run ID link in the topic header, we add `analysis_run_id` and `confidence_score` to the `Topic` interface and conditionally render them in the topic header row.

## 3. Caveats
- The backend API might wrap the paginated mentions in another `data` object depending on Laravel's pagination configuration (e.g., `response.data.data`). The UI code should safely fallback to an empty array using `?? []` and optional chaining.
- The exact fields on the `Message` model payload (`body` vs `content`) were inferred as `body` based on standard project conventions and the backend design doc's reference to `body excerpts`. The UI should safely fallback if `body` is missing.
- There is no `/analysis-runs/[id]` page currently implemented in the Next.js router. The `url` link will either be a dead link or a 404 until that route is built, but it fulfills the task requirement to make it "clickable".

## 4. Conclusion
Task 11.1 can be fully completed by modifying a single file: `Nexus-Frontend/components/NxTopicsViewer.tsx`. 
The implementation requires adding new component state for expansion and mentions, an async `toggleTopic` fetch handler, and updating the JSX mapping to render `Chevron` icons, confidence/run ID badges in the header, and an expanded section containing `NxSourceCitation` components for each mention. The detailed blueprint and interface definitions are saved in `analysis.md`.

## 5. Verification Method
- Ensure the frontend builds by running `npm run build` in `Nexus-Frontend`.
- Verify the UI by opening the contact details page and navigating to the "Topics" tab.
- Click on a topic row: it should expand, show a loading spinner, and then render a list of mentions (or a fallback message if empty).
- The `NxSourceCitation` components should display the correct sender, date, and excerpt.
- Topics with an `analysis_run_id` should display a clickable "Run #ID" link and a confidence percentage badge in the row header.
