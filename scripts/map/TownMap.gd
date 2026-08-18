extends MapControllerBase
## 第1章: 旅立ちの村。セレナが仲間になり、北の道から遺跡(ダンジョン)へ向かう。

const LAYOUT: PackedStringArray = [
	"##########,#########",
	"#.........,........#",
	"#.RRRR....,..RRRR..#",
	"#.HDHH....,..HDHH..#",
	"#.........,........#",
	"#....#....,...#....#",
	"#.........,........#",
	"#.........,........#",
	"#.RRRR....,..RRRR..#",
	"#.HDHH....,..HDHH..#",
	"#.........,........#",
	"#.........,........#",
	"#....#....,...#....#",
	"####################",
]

const OBJECTS: Array = [
	{"type": "marker", "cell": Vector2i(10, 11), "id": "start"},
	{"type": "marker", "cell": Vector2i(10, 2), "id": "from_dungeon"},
	{"type": "door", "cell": Vector2i(10, 0), "target_scene": "res://scenes/maps/Dungeon.tscn", "target_spawn": "start"},
	{
		"type": "npc", "cell": Vector2i(5, 6), "name": "村長", "look": "elder", "solid": true,
		"lines": [
			"勇者よ、ついに旅立ちの日じゃな。",
			"七神教会よりの神託どおり、魔王の復活を止めるのじゃ。",
			"このところ各地で「マサ」――古くからの理不尽な仕掛けが、輪をかけて凶悪になっておる。",
			"北の道を進めば、じきに試練の遺跡がある。油断せず行くのじゃぞ。",
			"……なに、死んでも死にきれんとも聞くが、まあ気にするでない。",
		],
	},
	{
		"type": "npc", "cell": Vector2i(14, 4), "name": "セレナ", "look": "priest",
		"join_member": "serena", "solid": true,
		"lines": [
			"勇者様、お待たせいたしました。",
			"七神教会より、あなたさまの旅への同行を仰せつかりました、セレナ・アルヴェールと申します。",
			"回復と支援ならお任せください。さあ、まいりましょう。",
		],
		"lines_after": [
			"準備はよろしいですか? 北の道から、遺跡へ向かえます。",
			"……ときどき妙な胸騒ぎがするのですが、気のせいですよね?",
		],
	},
	{
		"type": "npc", "cell": Vector2i(14, 11), "name": "旅の老婆", "look": "villager", "solid": true,
		"lines": [
			"坊や、旅に出るのかい。",
			"この世界にはね、昔からある妙な仕掛け――「マサ」ってやつがあってね。",
			"初めて通る道じゃ、絶対に気を抜くんじゃないよ。",
			"……まあ忠告したって、若いもんは一度は痛い目を見るのが常だけどねぇ。",
		],
	},
	{
		"type": "shop", "cell": Vector2i(3, 4), "name": "道具屋", "look": "merchant", "solid": true,
		"greeting": "いらっしゃい。何か買っていくかい?",
		"wares": [
			{"name": "ポーション", "item": "potion", "price": 10, "amount": 1},
			{"name": "ポーション5個セット", "item": "potion", "price": 45, "amount": 5},
		],
	},
	{
		"type": "inn", "cell": Vector2i(3, 10), "name": "宿屋", "look": "innkeeper",
		"solid": true, "price": 5,
	},
]


func _get_layout() -> PackedStringArray:
	return LAYOUT


func _get_objects() -> Array:
	return OBJECTS
