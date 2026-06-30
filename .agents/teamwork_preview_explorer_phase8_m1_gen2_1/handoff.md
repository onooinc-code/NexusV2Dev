# Handoff Report: NxTopicsViewer Bugs

## Observation
Reviewers identified four bugs in `Nexus-Frontend/components/NxTopicsViewer.tsx`. 
1. **State Leak on Prop Change:** Component states `expandedTopics`, `mentionsCache`, `mentionsLoading`, and `mentionsError` are not cleared when `contactId` changes. The fetch logic is triggered via a `useCallback` on `fetchTopics` but the internal state relies on the old `contactId`.
2. **Missing `timestamp` Edge Case:** `renderMention` directly executes `new Date(mention.timestamp).toLocaleString()` (line 101). A missing or invalid timestamp returns an "Invalid Date" string in the UI.
3. **Race Condition on Rapid Clicking:** `toggleTopic` (line 66) initiates a network request after expanding the topic, checking `if (mentionsCache[topic.id] !== undefined)` but failing to check if the request is already in-flight (`mentionsLoading`).
4. **Brittle Payload Extraction:** In `fetchTopics` (line 47) and `toggleTopic` (line 86), the response is parsed via `(response.data as { data?: Topic[] }).data ?? []`. If the API returns a flat array instead of a paginated resource, this evaluates to an empty array.

## Logic Chain
1. To fix the state leak, we must reset the view states whenever `contactId` changes. The best place is inside `fetchTopics`, right before or after setting `setIsLoading(true)`, because `fetchTopics` is recreated when `contactId` changes and is called in a `useEffect`.
2. To gracefully handle timestamps, we should check `mention.timestamp` truthiness and validity, falling back to `'Unknown Date'`.
3. To resolve the race condition, adding an early return `if (mentionsLoading[topic.id]) return;` in `toggleTopic` will guard against duplicate API calls.
4. To robustly extract payloads, we must verify if `response.data` is an array: `const payload = response.data; const data = Array.isArray(payload) ? payload : (payload?.data ?? []);`

## Caveats
No major caveats. We assume the missing `timestamp` might just be an undefined or null value in the JSON payload, but if it's an invalid date string like `"null"`, we might need a more robust `isNaN(new Date().getTime())` check, but simple truthiness check combined with standard fallback is usually sufficient and directly addresses the review comment. I will provide a slightly more robust check.

## Conclusion
The bugs can be fixed with targeted replacements in `Nexus-Frontend/components/NxTopicsViewer.tsx`:
1. Reset `expandedTopics`, `mentionsCache`, `mentionsLoading`, and `mentionsError` in `fetchTopics`.
2. Update the timestamp formatting logic in `renderMention` to fallback to `'Unknown Date'`.
3. Add `if (mentionsLoading[topic.id]) return;` in `toggleTopic`.
4. Update extraction logic in `fetchTopics` and `toggleTopic` to handle both array and object responses.

## Implementation Instructions (for Implementer)
Use `multi_replace_file_content` to make these changes in `Nexus-Frontend/components/NxTopicsViewer.tsx`.

### 1. Fix State Leak & Brittle Payload in `fetchTopics`
Replace:
```typescript
  const fetchTopics = useCallback(async () => {
    setIsLoading(true);
    setError('');
    try {
      const response = await apiClient.get(`/contacts/${contactId}/topics`);
      const data = (response.data as { data?: Topic[] }).data ?? [];
      setTopics(data);
```
With:
```typescript
  const fetchTopics = useCallback(async () => {
    setIsLoading(true);
    setError('');
    setExpandedTopics(new Set());
    setMentionsCache({});
    setMentionsLoading({});
    setMentionsError({});
    try {
      const response = await apiClient.get(`/contacts/${contactId}/topics`);
      const payload = response.data;
      const data = Array.isArray(payload) ? payload : (payload?.data ?? []);
      setTopics(data);
```

### 2. Fix Race Condition & Brittle Payload in `toggleTopic`
Replace:
```typescript
    if (mentionsCache[topic.id] !== undefined) {
      return;
    }

    setMentionsLoading((prev) => ({ ...prev, [topic.id]: true }));
    setMentionsError((prev) => ({ ...prev, [topic.id]: '' }));

    try {
      const response = await apiClient.get(`/contacts/${contactId}/topics/${topic.id}/mentions`);
      const data = (response.data as { data?: Mention[] }).data ?? [];
      setMentionsCache((prev) => ({ ...prev, [topic.id]: data }));
```
With:
```typescript
    if (mentionsCache[topic.id] !== undefined || mentionsLoading[topic.id]) {
      return;
    }

    setMentionsLoading((prev) => ({ ...prev, [topic.id]: true }));
    setMentionsError((prev) => ({ ...prev, [topic.id]: '' }));

    try {
      const response = await apiClient.get(`/contacts/${contactId}/topics/${topic.id}/mentions`);
      const payload = response.data;
      const data = Array.isArray(payload) ? payload : (payload?.data ?? []);
      setMentionsCache((prev) => ({ ...prev, [topic.id]: data }));
```

### 3. Fix Missing `timestamp` in `renderMention`
Replace:
```typescript
  const renderMention = (mention: Mention) => {
    const excerpt = mention.message_excerpt ?? mention.message?.body ?? 'No excerpt available';
    const sender = mention.sender ?? mention.message?.sender ?? 'Unknown Sender';
    const title = `${sender} - ${new Date(mention.timestamp).toLocaleString()}`;
```
With:
```typescript
  const renderMention = (mention: Mention) => {
    const excerpt = mention.message_excerpt ?? mention.message?.body ?? 'No excerpt available';
    const sender = mention.sender ?? mention.message?.sender ?? 'Unknown Sender';
    
    let dateStr = 'Unknown Date';
    if (mention.timestamp) {
      const d = new Date(mention.timestamp);
      if (!isNaN(d.getTime())) {
        dateStr = d.toLocaleString();
      }
    }
    
    const title = `${sender} - ${dateStr}`;
```

## Verification Method
1. Build the frontend: `npm run build` or `npm run typecheck` in the frontend directory to ensure TypeScript is satisfied.
2. Verify `contactId` changes reset the state.
3. Verify topics render without error when the response is a direct array.
4. Verify rapid clicking on topics does not cause duplicate network requests for the same topic.
5. Verify mentions with missing timestamps display "Unknown Date" rather than "Invalid Date".
