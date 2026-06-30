# Handoff Report: NxTopicsViewer Fixes

## 1. Observation
- `NxTopicsViewer.tsx` leaks state when `contactId` changes (mentionsCache, etc. are not reset).
- Missing `timestamp` in `Mention` causes "Invalid Date" due to `new Date(mention.timestamp)`.
- `toggleTopic` allows race conditions because it does not check `mentionsLoading[topic.id]` when clicked rapidly.
- Data extraction from `apiClient` responses stringently expects an object with a `data` array property, which breaks if the backend returns a direct array.

## 2. Logic Chain
1. By adding a `useEffect` on `contactId`, we can reset `expandedTopics`, `mentionsCache`, `mentionsLoading`, and `mentionsError` when switching between contacts.
2. By making `timestamp` optional in the `Mention` interface and conditionally checking its value in `renderMention`, we ensure a safe fallback ("Unknown Time").
3. By adding `|| mentionsLoading[topic.id]` to the cache check inside `toggleTopic`, we prevent concurrent API requests for the same topic's mentions.
4. By using a more resilient payload extraction logic (`Array.isArray(resData?.data) ? resData.data : (Array.isArray(resData) ? resData : [])`), we gracefully handle both wrapped and un-wrapped API responses.

## 3. Caveats
- The changes assume that the un-wrapped API response, if not in `.data`, is itself the array.
- We clear all expanded states and mentions caches upon changing `contactId`. This means users will have to re-fetch mentions if they return to the previous `contactId` (unless state is lifted, which is out of scope here).

## 4. Conclusion
The four bugs can be successfully addressed by targeted edits in `NxTopicsViewer.tsx`. Implement the changes as specified in the instructions below.

## 5. Verification Method
- **State Leak**: Verify that switching `contactId` closes all expanded topics and empties the mentions cache.
- **Timestamp Edge Case**: Provide a mock mention with a missing `timestamp` and ensure it renders "Unknown Time" instead of "Invalid Date".
- **Race Condition**: Simulate network delay and click a topic multiple times rapidly. Ensure only one network request is dispatched.
- **Payload Extraction**: Mock the API response to return a direct array instead of an object with a `data` key, and ensure topics still render.

## Implementation Instructions

Use the `multi_replace_file_content` tool on `c:\Users\hedra\Desktop\Sourcecode\NexusV2\Nexus-Frontend\components\NxTopicsViewer.tsx` with the following chunks:

### Chunk 1: Update Mention interface
**StartLine**: 19
**EndLine**: 26
**TargetContent**:
```tsx
interface Mention {
  id: number;
  message_excerpt?: string;
  message?: { body?: string; sender?: string };
  sender?: string;
  timestamp: string;
  analysis_run_id?: number;
}
```
**ReplacementContent**:
```tsx
interface Mention {
  id: number;
  message_excerpt?: string;
  message?: { body?: string; sender?: string };
  sender?: string;
  timestamp?: string;
  analysis_run_id?: number;
}
```

### Chunk 2: Add useEffect for contactId state reset
**StartLine**: 37
**EndLine**: 40
**TargetContent**:
```tsx
  const [expandedTopics, setExpandedTopics] = useState<Set<number>>(new Set());
  const [mentionsCache, setMentionsCache] = useState<Record<number, Mention[]>>({});
  const [mentionsLoading, setMentionsLoading] = useState<Record<number, boolean>>({});
  const [mentionsError, setMentionsError] = useState<Record<number, string>>({});
```
**ReplacementContent**:
```tsx
  const [expandedTopics, setExpandedTopics] = useState<Set<number>>(new Set());
  const [mentionsCache, setMentionsCache] = useState<Record<number, Mention[]>>({});
  const [mentionsLoading, setMentionsLoading] = useState<Record<number, boolean>>({});
  const [mentionsError, setMentionsError] = useState<Record<number, string>>({});

  useEffect(() => {
    setExpandedTopics(new Set());
    setMentionsCache({});
    setMentionsLoading({});
    setMentionsError({});
  }, [contactId]);
```

### Chunk 3: Update fetchTopics payload extraction
**StartLine**: 46
**EndLine**: 48
**TargetContent**:
```tsx
      const response = await apiClient.get(`/contacts/${contactId}/topics`);
      const data = (response.data as { data?: Topic[] }).data ?? [];
      setTopics(data);
```
**ReplacementContent**:
```tsx
      const response = await apiClient.get(`/contacts/${contactId}/topics`);
      const resData = response.data as any;
      const data = Array.isArray(resData?.data) ? resData.data : (Array.isArray(resData) ? resData : []);
      setTopics(data);
```

### Chunk 4: Update toggleTopic in-flight check and payload extraction
**StartLine**: 77
**EndLine**: 87
**TargetContent**:
```tsx
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
**ReplacementContent**:
```tsx
    if (mentionsCache[topic.id] !== undefined || mentionsLoading[topic.id]) {
      return;
    }

    setMentionsLoading((prev) => ({ ...prev, [topic.id]: true }));
    setMentionsError((prev) => ({ ...prev, [topic.id]: '' }));

    try {
      const response = await apiClient.get(`/contacts/${contactId}/topics/${topic.id}/mentions`);
      const resData = response.data as any;
      const data = Array.isArray(resData?.data) ? resData.data : (Array.isArray(resData) ? resData : []);
      setMentionsCache((prev) => ({ ...prev, [topic.id]: data }));
```

### Chunk 5: Update renderMention timestamp fallback
**StartLine**: 98
**EndLine**: 102
**TargetContent**:
```tsx
  const renderMention = (mention: Mention) => {
    const excerpt = mention.message_excerpt ?? mention.message?.body ?? 'No excerpt available';
    const sender = mention.sender ?? mention.message?.sender ?? 'Unknown Sender';
    const title = `${sender} - ${new Date(mention.timestamp).toLocaleString()}`;
    const url = mention.analysis_run_id ? `/analysis/${mention.analysis_run_id}` : undefined;
```
**ReplacementContent**:
```tsx
  const renderMention = (mention: Mention) => {
    const excerpt = mention.message_excerpt ?? mention.message?.body ?? 'No excerpt available';
    const sender = mention.sender ?? mention.message?.sender ?? 'Unknown Sender';
    const timeString = mention.timestamp ? new Date(mention.timestamp).toLocaleString() : 'Unknown Time';
    const title = `${sender} - ${timeString}`;
    const url = mention.analysis_run_id ? `/analysis/${mention.analysis_run_id}` : undefined;
```
