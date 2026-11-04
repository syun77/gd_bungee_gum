extends RefCounted
## Stable scene paths keep checkpoint restoration scoped to the selected course.
const STAGES := [
	{"title": "レストラン", "description": "全6エリアのロングコース", "food": "milano_doria", "scene": "res://scenes/game.tscn"},
	{"title": "リングテラス", "description": "足場とリングのショートコース", "food": "margherita_pizza", "scene": "res://scenes/game_stage_2.tscn"},
	{"title": "はこび屋キッチン", "description": "箱と滑車のアクションコース", "food": "italian_pudding", "scene": "res://scenes/game_stage_3.tscn"},
]
