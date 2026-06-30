# Analysis of Bugs in NxTopicsViewer.tsx

## 1. State Leak on Prop Change
**Observation:** In `NxTopicsViewer.tsx` lines 37-40, component state is defined for `expandedTopics`, `mentionsCache`, `mentionsLoading`, and `mentionsError`. The `useEffect` that triggers `fetchTopics` (line 56-59) does not clear these state variables. Since the component might remain mounted while the `contactId` prop changes, the cached mentions and expanded state from the previous contact will persist and be displayed for the new contact's topics if their IDs overlap.
**Logic Chain:** When `contactId` changes, `fetchTopics` is called because it's in the dependency array (via `useCallback`). Resetting the state inside `fetchTopics` or in the `useEffect` when `contactId` changes will ensure that the UI is clean for the new contact.
**Conclusion:** Reset `expandedTopics`, `mentionsCache`, `mentionsLoading`, and `mentionsError` at the start of `fetchTopics` or in the effect that watches `contactId`.

## 2. Missing `timestamp` Edge Case
**Observation:** In `renderMention` at line 101, the code uses `new Date(mention.timestamp).toLocaleString()`. If `timestamp` is undefined, null, or missing, `new Date(undefined)` returns an invalid date, which translates to the string "Invalid Date" in the UI.
**Logic Chain:** The `timestamp` is typed as a required string in the `Mention` interface (line 24), but runtime data might differ. Safe extraction using a fallback string "Unknown Date" prevents the bad UI.
**Conclusion:** Replace line 101 with a check: `const dateStr = mention.timestamp ? new Date(mention.timestamp).toLocaleString() : 'Unknown Date'; const title = \`\${sender} - \${dateStr}\`;`

## 3. Race condition on rapid clicking
**Observation:** In `toggleTopic` (lines 66-95), it checks if `mentionsCache[topic.id] !== undefined` to avoid refetching. However, it does not check if `mentionsLoading[topic.id]` is true. If a user double-clicks rapidly, `toggleTopic` can fire multiple times before `mentionsCache` is populated, leading to duplicate simultaneous API calls.
**Logic Chain:** A simple check `if (mentionsLoading[topic.id]) return;` prevents the redundant in-flight requests.
**Conclusion:** Add `if (mentionsLoading[topic.id]) return;` immediately before setting the loading state to true.

## 4. Brittle payload extraction
**Observation:** Lines 47 and 86 use `(response.data as { data?: any[] }).data ?? []`. This assumes `response.data` is an object with a `data` property (Laravel Resource format). If the API directly returns a JSON array, this extraction will fail, resulting in an empty array `[]` being set.
**Logic Chain:** Checking `Array.isArray(response.data)` allows handling both Laravel Resource formats and plain arrays.
**Conclusion:** Change the extraction logic to `const payload = response.data; const data = Array.isArray(payload) ? payload : (payload?.data ?? []);`
