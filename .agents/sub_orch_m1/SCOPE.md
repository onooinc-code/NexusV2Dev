# Scope: M1_Extraction

## Architecture
- Code Organization & Extraction for settings hub.
- Extract interfaces into `app/settings/types.ts`.
- Extract `SettingControl` into `app/settings/components/SettingControl.tsx`.
- Extract Tab components into `app/settings/components/*.tsx`.
- Clean up `app/settings/page.tsx`.

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | Tasks_1_to_4 | Extract types, SettingControl, Tabs, and wire page.tsx | none | PLANNED |

## Interface Contracts
### `app/settings/page.tsx` ↔ Extracted Components
- `SettingControl`: `{ setting: SettingEntry; value: any; onChange: (key: string, value: any) => void }`
- `GeneralTab`: `{ groupedSettings: GroupedSettings; editedValues: Record<string, any>; loading: boolean; onValueChange: (key: string, value: any) => void }`
- `IntegrationsTab`: `{ groupedSettings: GroupedSettings; editedValues: Record<string, any>; loading: boolean; showMaskedCredentials: Record<string, boolean>; maskedValues: Record<string, string>; editingEncrypted: Record<string, boolean>; onValueChange: (key: string, value: any) => void; onToggleMasked: (key: string) => void; onToggleEdit: (key: string) => void }`
- `HealthTab`: `{ healthStatus: HealthStatus | null; isLoadingHealth: boolean; onRefresh: () => void }`
- `SeedsTab`: `{ seeds: Seed[]; isLoadingSeeds: boolean; saving: boolean; onRunSeed: (id: string) => void }`
- `AdvancedTab`: `{ agentPausedEnabled: boolean; saving: boolean; onToggleAgentPause: () => void; onFactoryReset: () => void }`

## Code Layout
- Extracted types: `app/settings/types.ts`
- Extracted components: `app/settings/components/*.tsx`
