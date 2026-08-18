extends Node
## グローバルイベントバス。
## マップ/戦闘/UIなど互いを直接参照しないシステム同士を疎結合につなぐ。

signal trap_triggered(trap_id: String)
signal player_died(cause_id: String, message: String)
signal player_retried()
signal checkpoint_set(checkpoint_id: String)
signal dialogue_started(speaker: String, text: String)
signal dialogue_ended()
signal battle_started(encounter_id: String)
signal battle_ended(result: String)
