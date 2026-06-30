# Analysis: NxTopicsViewer Bugs

## 1. State Leak on Prop Change
**Observation:**
In `Nexus-Frontend/components/NxTopicsViewer.tsx` (lines 37-40), the component maintains several state variables: `expandedTopics`, `mentionsCache`, `mentionsLoading`, and `mentionsError`. When `contactId` changes, the `useEffect` on line 56 triggers `fetchTopics`. However, `fetchTopics` only resets `isLoading` and `error`, leaving the expanded topics and their cached mentions from the previous contact intact.

**Solution:**
In `fetchTopics` (line 42), we need to clear these state variables:
```typescript
    setExpandedTopics(new Set());
    setMentionsCache({});
    setMentionsLoading({});
    setMentionsError({});
```

## 2. Missing `timestamp` Edge Case
**Observation:**
In `renderMention` (line 101), the title is constructed as:
```typescript
const title = `${sender} - ${new Date(mention.timestamp).toLocaleString()}`;
```
If `mention.timestamp` is undefined or null at runtime, `new Date(undefined)` evaluates to an Invalid Date, resulting in "Invalid Date" in the UI.

**Solution:**
Implement a graceful fallback:
```typescript
const dateStr = mention.timestamp ? new Date(mention.timestamp).toLocaleString() : 'Unknown Date';
const title = `${sender} - ${dateStr}`;
```

## 3. Race condition on rapid clicking
**Observation:**
In `toggleTopic` (line 66), the component checks if mentions are cached before fetching:
```typescript
    if (mentionsCache[topic.id] !== undefined) {
      return;
    }
```
If a user clicks rapidly, the first click initiates the fetch and sets `mentionsLoading[topic.id]` to true. The second click collapses the topic. The third click expands it again, but since `mentionsCache` is still empty (fetch in-flight), it bypasses the guard and triggers a duplicate API call.

**Solution:**
Check the loading state as well:
```typescript
    if (mentionsCache[topic.id] !== undefined || mentionsLoading[topic.id]) {
      return;
    }
```

## 4. Brittle payload extraction
**Observation:**
Both `fetchTopics` (line 47) and `toggleTopic` (line 86) use the following pattern:
```typescript
const data = (response.data as { data?: Topic[] }).data ?? [];
```
If the API returns a direct array instead of a wrapped Laravel Resource (`{ data: [...] }`), `response.data.data` will be undefined, causing the component to mistakenly use the empty array fallback `[]` instead of the actual data.

**Solution:**
Use `Array.isArray` to safely handle both formats:
```typescript
const rawData = response.data;
const data = Array.isArray(rawData) ? rawData : (rawData?.data ?? []);
```
