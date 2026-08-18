extends Node2D
## プロローグ 場面1 ── オルディナ教国 大聖堂。
##
## 背景なし、テキストのみのカットシーン。主人公は登場せず、
## アウレリウス教皇がセレナに勇者への同行を命じる。
## 台詞は docs/プロローグ台詞ドラフト.md に対応する。

const NEXT_SCENE := "res://scenes/maps/ThroneRoom.tscn"

const POPE := "アウレリウス教皇"
const SERENA := "セレナ"

const SCRIPT_LINES: Array = [
	["", "オルディナ教国、大聖堂。"],
	["", "七神の像が見下ろす広間に、ひとりの若い神官が呼ばれていた。"],

	[POPE, "セレナ・アルヴェールよ。面を上げなさい。"],
	[SERENA, "……はい、猊下。"],
	[POPE, "近ごろ、世界各地で「マサ」が凶悪さを増しているのは、そなたも知っていよう。"],
	[POPE, "かつて安全であった道に罠が生まれ、魔物が尋常ならざる力を得ている。"],
	[SERENA, "はい。わたくしのおりました地方の聖堂にも、運び込まれる者が日ごとに増えておりました。"],
	[POPE, "教会はこれを、魔王復活の兆候と断じた。"],
	[POPE, "ヴァレンティア王国にはすでに勇者を選ばせてある。討伐の支度は整いつつある。"],
	[SERENA, "では、わたくしは……"],
	[POPE, "そなたを、勇者を支える神官として遣わす。"],
	[POPE, "勇者と共に魔王を討ち、この世界に安寧をもたらしなさい。"],
	[SERENA, "……わたくしのような若輩に、そのような大役が務まりましょうか。"],
	[POPE, "務まるかを問うてはおらぬ。務めるのだ。"],

	# 過激派の目的(魔王が受け継ぐ大災厄の力の回収)につながる指示。
	# この時点では儀礼上の注意にしか見えないようにしてある。
	[POPE, "……セレナよ。ひとつだけ、固く命じておく。"],
	[POPE, "魔王を討ち取ったのち、その亡骸には決して触れてはならぬ。"],
	[POPE, "触れてよいのは、教会が遣わす者のみである。"],
	[SERENA, "……亡骸に、でございますか。"],
	[POPE, "魔王の穢れは、死してなお残る。"],
	[POPE, "若い神官の身が損なわれてはならぬ。それだけのことだ。"],
	[SERENA, "……承知いたしました。"],
	[POPE, "七神の加護が、そなたと勇者にあらんことを。"],
]


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.04)
	bg.size = Vector2(320, 224)
	add_child(bg)
	_play()


func _play() -> void:
	# 場面が始まる前に一拍置く
	await get_tree().create_timer(0.6).timeout
	for line in SCRIPT_LINES:
		await Dialogue.say(String(line[0]), String(line[1]))
	await get_tree().create_timer(0.4).timeout
	GameState.travel_to(NEXT_SCENE, "start")
