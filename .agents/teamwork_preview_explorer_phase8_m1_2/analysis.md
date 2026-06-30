# Analysis for Task 11.1: Expand Topics with Evidence Citations

## Overview

Task 11.1 requires updating `NxTopicsViewer` to expand topics with evidence citations by calling the `GET /api/v1/contacts/{contactId}/topics/{topicId}/mentions` endpoint when a topic row is expanded. 

Each mention needs to be rendered as an `NxSourceCitation` component, showing a message excerpt, sender, timestamp, and clickable analysis run ID. Additionally, if the topic has an `analysis_run_id`, a confidence badge and run ID link must be displayed in the topic header.

## Findings

### Component: `NxTopicsViewer.tsx`
Location: `Nexus-Frontend/components/NxTopicsViewer.tsx`

Currently, `NxTopicsViewer` fetches the topics but does not include any interactive logic for expanding rows or fetching mentions. The UI for each row is a simple static card. The `Topic` interface is also missing the `analysis_run_id` and `confidence_score` fields.

### Mention API Shape
Based on backend design documents (`.kiro/specs/contact-hub-complete/design.md`), the `GET /contacts/{id}/topics/{topicId}/mentions` endpoint returns a paginated list of `ContactTopicMention` records which eager-load the related `message`.

A mention payload roughly resembles:
```json
{
  "id": 1,
  "topic_id": 1,
  "message_id": 123,
  "analysis_run_id": 45,
  "message": {
    "id": 123,
    "body": "Excerpt text here...",
    "sender": "John Doe",
    "created_at": "2026-06-06T12:00:00Z"
  }
}
```

### Component: `NxSourceCitation.tsx`
Location: `Nexus-Frontend/components/NxSourceCitation.tsx`

This component takes the following props:
- `title` (used for sender + timestamp)
- `url` (used for analysis run ID link)
- `snippet` (used for message excerpt)
- `relevanceScore` (not strictly needed, but available)
- `className`

## Proposed Changes

We can implement these requirements purely within `Nexus-Frontend/components/NxTopicsViewer.tsx`.

1. **Update Interfaces**:
   Add `Message` and `Mention` interfaces, and update the `Topic` interface to include `analysis_run_id` and `confidence_score`.

2. **Add Component State**:
   ```typescript
   const [expandedTopics, setExpandedTopics] = useState<Record<number, boolean>>({});
   const [mentions, setMentions] = useState<Record<number, Mention[]>>({});
   const [mentionsLoading, setMentionsLoading] = useState<Record<number, boolean>>({});
   const [mentionsError, setMentionsError] = useState<Record<number, string>>({});
   ```

3. **Add `toggleTopic` Handler**:
   ```typescript
   const toggleTopic = async (topicId: number) => {
     setExpandedTopics((prev) => ({ ...prev, [topicId]: !prev[topicId] }));

     if (!mentions[topicId] && !mentionsLoading[topicId]) {
       setMentionsLoading((prev) => ({ ...prev, [topicId]: true }));
       setMentionsError((prev) => ({ ...prev, [topicId]: '' }));
       try {
         const response = await apiClient.get(`/contacts/${contactId}/topics/${topicId}/mentions`);
         const data = (response.data as { data?: Mention[] }).data ?? [];
         setMentions((prev) => ({ ...prev, [topicId]: data }));
       } catch (err: any) {
         setMentionsError((prev) => ({
           ...prev,
           [topicId]: err?.response?.data?.message || 'Failed to load mentions.',
         }));
       } finally {
         setMentionsLoading((prev) => ({ ...prev, [topicId]: false }));
       }
     }
   };
   ```

4. **Update Rendered Topic Card**:
   - Make the container a `flex-col` and add `cursor-pointer` to the header.
   - Display `Run #{topic.analysis_run_id}` link and `${topic.confidence_score * 100}% Conf` badge next to the topic name in the header.
   - Show a `ChevronDown` or `ChevronUp` icon indicating expanded state.
   - Below the header, if `isExpanded` is true, render a new section for mentions using `NxSourceCitation`.
   - Map each mention to a `NxSourceCitation` passing:
     - `title={sender on date}`
     - `snippet={mention.message?.body}`
     - `url={mention.analysis_run_id ? \`/analysis-runs/\${mention.analysis_run_id}\` : undefined}`

The changes are entirely local to `NxTopicsViewer.tsx` and satisfy all parts of Task 11.1.
