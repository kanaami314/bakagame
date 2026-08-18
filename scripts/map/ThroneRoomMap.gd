extends MapControllerBase
## プロローグ 場面2 ── ヴァレンティア王国 王城 謁見の広間。
##
## 入口から赤絨毯を歩いて王座へ進むと、オルヴァン王による勇者任命が始まる。
## 台詞は docs/プロローグ台詞ドラフト.md に対応する。

## 王都はまだ設計していないため、暫定的に仮組みの村へつないでいる。
const NEXT_SCENE := "res://scenes/maps/Town.tscn"

const KING := "オルヴァン王"
const SERENA := "セレナ"

const SERENA_START := Vector2i(14, 4)
const SERENA_END := Vector2i(11, 3)

const LAYOUT: PackedStringArray = [
	"CCCCCCCCCCCCCCCCCCCC",
	"CFFFFFFFFFTFFFFFFFFC",
	"CFFFFFFFFFcFFFFFFFFC",
	"CFFFFFFFFFcFFFFFFFFC",
	"CFFFFFFFFFcFFFFFFFFC",
	"CFFFFFFFFFcFFFFFFFFC",
	"CFFFFFFFFFcFFFFFFFFC",
	"CFFFFFFFFFcFFFFFFFFC",
	"CFFFFFFFFFcFFFFFFFFC",
	"CFFFFFFFFFcFFFFFFFFC",
	"CFFFFFFFFFcFFFFFFFFC",
	"CFFFFFFFFFcFFFFFFFFC",
	"CFFFFFFFFFcFFFFFFFFC",
	"CCCCCCCCCCCCCCCCCCCC",
]

const OBJECTS: Array = [
	{"type": "marker", "cell": Vector2i(10, 12), "id": "start"},
	{"type": "trigger", "cell": Vector2i(10, 3), "id": "throne_audience"},
	{
		"type": "npc", "cell": Vector2i(10, 2), "name": "オルヴァン王",
		"look": "king", "solid": true,
		"lines": ["……面を上げよ。近う寄れ。"],
	},
	{
		"type": "npc", "cell": Vector2i(8, 11), "name": "衛兵",
		"look": "guard", "solid": true,
		"lines": ["陛下がお待ちだ。まっすぐ、王座の前へ進まれよ。"],
	},
	{
		"type": "npc", "cell": Vector2i(12, 7), "name": "衛兵",
		"look": "guard", "solid": true,
		"lines": [
			"七神教会から神官どのが遣わされてきている。",
			"教国が本気だという証だな。……粗相のないようにな。",
		],
	},
	{
		"type": "npc", "cell": Vector2i(7, 5), "name": "文官",
		"look": "official", "solid": true,
		"lines": [
			"街道のマサがひどくてな。隊商がめっきり減った。",
			"商人が通らねば、国庫も痩せる。陛下も気が気ではあるまい。",
		],
	},
	{
		"type": "npc", "cell": Vector2i(13, 9), "name": "侍女",
		"look": "maid", "solid": true,
		"lines": [
			"北の村では、昨日まで何ともなかった橋が落ちたそうです。",
			"昔から危ない場所は決まっていたはずなのに……最近は、どこが危ないのか誰にも分かりません。",
		],
	},
]

var _serena_sprite: Sprite2D


func _get_layout() -> PackedStringArray:
	return LAYOUT


func _get_objects() -> Array:
	return OBJECTS


## セレナは任命の途中で歩み出るため、通常のNPCではなく専用に配置する。
func _on_ready_extra() -> void:
	var look: Dictionary = LOOKS["priest"]
	_serena_sprite = Sprite2D.new()
	_serena_sprite.texture = TileArt.character("left", look["tunic"], look["hair"])
	_serena_sprite.centered = true
	_serena_sprite.position = grid.cell_to_world(SERENA_START)
	add_child(_serena_sprite)
	grid.set_solid(SERENA_START, true)


func _run_trigger(id: String) -> void:
	if id != "throne_audience":
		return

	await Dialogue.say(KING, "よく来た。面を上げよ。")
	await Dialogue.say(KING, "そなたの名を、この場で今一度、聞かせてくれ。")

	var entered: String = await NameEntry.ask("そなたの名は?", PartyData.hero_name())
	PartyData.set_hero_name(entered)
	var hero := PartyData.hero_name()

	await Dialogue.say(KING, "――%s。しかと聞き届けた。" % hero)
	await Dialogue.say(KING, "事情はすでに耳にしていよう。")
	await Dialogue.say(KING, "世界各地でマサが凶悪化し、七神教会はこれを魔王復活の兆候と断じた。")
	await Dialogue.say(KING, "オルディナ教国は魔王討伐の勇者を立てるよう求め、我がヴァレンティアはその選定を委ねられた。")
	await Dialogue.say(KING, "そして選ばれたのが、そなただ。")
	await Dialogue.say(KING, "%sよ。魔王を討ち、この世界を救ってまいれ。" % hero)

	await _serena_steps_forward()

	await Dialogue.say(SERENA, "陛下、失礼いたします。")
	await Dialogue.say(SERENA, "オルディナ教国大聖堂より参りました、神官セレナ・アルヴェールと申します。")
	await Dialogue.say(SERENA, "教皇猊下の命により、勇者様の旅に同行いたします。")
	await Dialogue.say(SERENA, "……どうぞ、よろしくお願いいたします。")

	await Dialogue.say(KING, "教会からの支えだ。心強かろう。")
	await Dialogue.say(KING, "発つ前に、城下で支度を整えてゆくがよい。")

	PartyData.add_member("serena")
	GameState.travel_to(NEXT_SCENE, "start")


func _serena_steps_forward() -> void:
	var tw := create_tween()
	tw.tween_property(_serena_sprite, "position", grid.cell_to_world(SERENA_END), 0.7)
	await tw.finished
	var look: Dictionary = LOOKS["priest"]
	_serena_sprite.texture = TileArt.character("down", look["tunic"], look["hair"])
