# Handoff: NxTopicsViewer Fix Strategy

## Observation
1. **Async State Leak:** In `NxTopicsViewer.tsx` (lines 42-64), `fetchTopics` is wrapped in `useCallback` and triggered via a `useEffect` whenever `contactId` changes. It does not utilize an `AbortController` or an `ignore` flag. If `contactId` changes rapidly, multiple network requests overlap, and out-of-order API responses will overwrite the state with stale data.
2. **Brittle Payload:** In both `fetchTopics` (line 52) and `toggleTopic` (line 92), the response payload is parsed as `const data = Array.isArray(payload) ? payload : (payload?.data ?? []);`. If the API returns an object where `.data` is also an object (instead of an array), `data` will be set to an object. This causes a crash when the component subsequently attempts to call `.map()` on `topics` (line 170) or `mentionsCache` (line 238).
3. **Refresh Race Condition:** The refresh button directly invokes `fetchTopics` without checking the current `isLoading` state or cancelling pending requests. Rapid clicks will fire overlapping requests, and the `finally` block of earlier resolving requests will incorrectly set `isLoading(false)` before the later requests have completed.

## Logic Chain
- **Fixing State Leak & Race Condition:** Implementing a shared `useRef<AbortController | null>(null)` solves both problems. Inside `fetchTopics`:
  1. If an active controller exists, call `.abort()` to cancel the previous request.
  2. Create a new `AbortController`, store it in the ref, and pass `signal: controller.signal` to `apiClient.get()`.
  3. In the `catch` block, silently ignore cancellation errors (e.g., `err?.name === 'CanceledError'`).
  4. In the `finally` block, only set `isLoading(false)` if the current request's controller is still the active one (`abortControllerRef.current === controller`), preventing aborted requests from resetting the loading state prematurely.
- **Fixing Brittle Payload:** We must enforce strict runtime type checks. Instead of falling back to whatever `payload.data` is, we explicitly check `Array.isArray(payload.data)`. 
  ```typescript
  let data = [];
  if (Array.isArray(payload)) {
    data = payload;
  } else if (payload && Array.isArray(payload.data)) {
    data = payload.data;
  }
  ```
  This guarantees that state is always an array, completely eliminating `.map()` crashes. This pattern must be applied to both `fetchTopics` and `toggleTopic`.

## Caveats
- This strategy assumes `apiClient` is an Axios instance (or standard Fetch) that accepts `{ signal }` in its config and throws a catchable `CanceledError` (or `AbortError` for fetch) on cancellation. Given the error handling pattern (`err?.response?.data`), it behaves like Axios.
- It is assumed that `apiClient` does not globally swallow `CanceledError`.

## Conclusion
Updating `NxTopicsViewer.tsx` to use an `AbortController` tracked via `useRef` for `fetchTopics`, coupled with strict `Array.isArray()` checks on all API responses, will thoroughly address the Async State Leak, Brittle Payload, and Refresh Race Condition issues. 

## Verification Method
1. **Async State / Race Condition Test:** Temporarily throttle network speed, rapidly toggle between different `contactId`s or spam the refresh button. Observe the Network tab to ensure previous requests are marked as `(canceled)`. Verify that `isLoading` remains `true` until the final request completes, and that the UI renders the data for the final `contactId` requested.
2. **Brittle Payload Test:** Temporarily mock the API response or use interceptors to return an unexpected structure (e.g., `{ data: { unexpected: "object" } }`). Verify that the component does not throw a `.map is not a function` error but gracefully renders the "No topics extracted yet" fallback state.
