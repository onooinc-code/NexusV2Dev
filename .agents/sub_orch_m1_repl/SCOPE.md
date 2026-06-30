# Scope: M1_Extraction

## Architecture
- Code Organization & Extraction for `app/settings/page.tsx`

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | M1_Extraction | Code Organization & Extraction (Tasks 1-4) | none | IN_PROGRESS |

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
