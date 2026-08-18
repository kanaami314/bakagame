extends MapControllerBase
## 第1章 ── ヴァレンティア王国 王都。
##
## 中央広場を中心に、北=王城側(入り直せない)、東=商業区、西=聖堂、
## 南=城門(閉ざされている)と宿屋。60×42マスでカメラが追従する。
##
## ※ 住民の台詞と店の品揃えは未承認のドラフトである。docs/王都ドラフト.md を参照。
## ※ マサ(初見殺し)は仕様どおり一切置いていない。噂話も置いていない。

const WIDTH := 60
const HEIGHT := 42

## 城門の外はまだ設計していないため、南門は閉ざしてある。
const CATHEDRAL_DOOR := Vector2i(13, 18)
const ITEM_SHOP_DOOR := Vector2i(44, 18)
const ARMS_SHOP_DOOR := Vector2i(54, 18)
const INN_DOOR := Vector2i(24, 36)

var _layout_cache: PackedStringArray


func _get_layout() -> PackedStringArray:
	if not _layout_cache.is_empty():
		return _layout_cache

	# 地面は草地を下地にし、石畳は大通りと広場だけに敷く。
	# 全面を石畳にすると区画の切れ目が消え、どこが道なのか分からなくなる。
	var b := MapBuilder.new(WIDTH, HEIGHT, ".")
	b.border("W") # 市壁

	# --- 北: 王城の外壁。任命は済んでおり、もう入れない ---
	# 金帯入りの城壁を積み重ねると縞模様に見えるため、帯は基部の一段だけにする。
	b.fill_rect(1, 1, WIDTH - 2, 5, "W")
	b.fill_rect(1, 6, WIDTH - 2, 1, "C")
	b.set_cell(29, 6, "+")
	b.set_cell(30, 6, "+")

	# --- 大通り(縦横)と中央広場 ---
	b.fill_rect(28, 7, 4, HEIGHT - 8, "p")
	b.fill_rect(1, 19, WIDTH - 2, 4, "p")
	b.fill_rect(24, 15, 13, 13, "p")
	b.set_cell(30, 21, "f")

	# --- 広場の四隅の植え込み ---
	for pos in [Vector2i(25, 16), Vector2i(34, 16), Vector2i(25, 26), Vector2i(34, 26)]:
		b.fill_rect(pos.x, pos.y, 2, 2, ".")
		b.set_cell(pos.x, pos.y, "#")
		b.set_cell(pos.x + 1, pos.y + 1, "#")

	# --- 西: 聖堂(オルディナ教国 王国支部)。青い石板屋根で民家と区別する ---
	b.fill_rect(6, 10, 14, 5, "A")
	b.fill_rect(6, 15, 14, 4, "H")
	b.set_cell(13, 18, "D")

	# --- 東: 商業区。大通りに面して2軒 ---
	b.building(40, 12, 8, 3, 4, 4) # 道具屋   扉(44,18)
	b.building(50, 12, 8, 3, 4, 4) # 武器防具屋 扉(54,18)

	# --- 南: 宿屋。大通りへ横道でつなぐ ---
	b.building(20, 30, 8, 3, 4, 4) # 扉(24,36)
	b.fill_rect(24, 37, 8, 1, "p")

	# --- 住宅街 ---
	b.building(6, 25, 7, 3, 3, 3)
	b.building(15, 25, 7, 3, 3, 3)
	b.building(6, 33, 7, 3, 3, 3)
	b.building(41, 27, 7, 3, 3, 3)
	b.building(50, 27, 7, 3, 3, 3)
	b.building(45, 34, 7, 3, 3, 3)
	for door_x in [9, 18]:
		b.vline(door_x, 31, 19, "p")
	for door_x in [44, 53]:
		b.vline(door_x, 23, 33, "p")
	b.vline(9, 39, 36, "p")
	b.hline(9, 28, 39, "p")
	b.vline(48, 40, 37, "p")
	b.hline(31, 48, 40, "p")

	# --- 街路樹 ---
	for pos in [
		Vector2i(3, 12), Vector2i(3, 16), Vector2i(22, 12), Vector2i(22, 16),
		Vector2i(37, 10), Vector2i(37, 30), Vector2i(23, 32), Vector2i(36, 34),
		Vector2i(14, 41 - 3), Vector2i(56, 12), Vector2i(56, 30), Vector2i(3, 30),
	]:
		b.set_cell(pos.x, pos.y, "#")

	# --- 南の城門(閉ざされている) ---
	b.set_cell(29, HEIGHT - 1, "+")
	b.set_cell(30, HEIGHT - 1, "+")

	_layout_cache = b.to_layout()
	return _layout_cache


func _get_objects() -> Array:
	return [
		{"type": "marker", "cell": Vector2i(30, 8), "id": "start"},

		# ================= 店 =================
		{
			"type": "shop", "cell": ITEM_SHOP_DOOR + Vector2i(-1, 1),
			"name": "道具屋", "look": "merchant", "solid": true,
			"greeting": "いらっしゃい! 旅の支度なら任せとくれ。",
			"wares": [
				{"name": "ポーション", "item": "potion", "price": 10},
				{"name": "エーテル", "item": "ether", "price": 30},
				{"name": "解毒草", "item": "antidote", "price": 8},
				{"name": "ポーション5個セット", "item": "potion", "price": 45, "amount": 5},
			],
		},
		{
			"type": "shop", "cell": ARMS_SHOP_DOOR + Vector2i(-1, 1),
			"name": "武具屋", "look": "guard", "solid": true,
			"greeting": "武器か? 防具か? 命を預ける物だ、よく選べ。",
			"wares": [
				{"name": "ブロンズソード", "item": "bronze_sword", "price": 90},
				{"name": "騎士の剣", "item": "knight_sword", "price": 260},
				{"name": "銀の杖", "item": "silver_staff", "price": 220},
				{"name": "革の鎧", "item": "leather_armor", "price": 80},
				{"name": "鎖かたびら", "item": "chain_mail", "price": 240},
				{"name": "革の腕輪", "item": "leather_band", "price": 60},
				{"name": "七神の護符", "item": "seven_charm", "price": 150},
			],
		},
		{
			"type": "inn", "cell": INN_DOOR + Vector2i(-1, 1),
			"name": "宿屋", "look": "innkeeper", "solid": true, "price": 8,
		},

		# ================= 北: 王城前 =================
		{
			"type": "npc", "cell": Vector2i(28, 7), "name": "王城の衛兵",
			"look": "guard", "solid": true,
			"lines": [
				"陛下の任はすでに下された。城へ戻る用はあるまい。",
				"……達者でな、勇者どの。",
			],
		},
		{
			"type": "npc", "cell": Vector2i(31, 7), "name": "王城の衛兵",
			"look": "guard", "solid": true,
			"lines": ["この門はもう開かぬ。発つのなら南の城門からだ。"],
		},
		{
			"type": "npc", "cell": Vector2i(33, 10), "name": "門番長",
			"look": "official", "solid": true,
			"lines": [
				"勇者どのか。城下は好きに見て回るがいい。",
				"支度が済んだら南の城門へ。開けさせよう。",
			],
		},

		# ================= 西: 聖堂 =================
		{
			"type": "npc", "cell": Vector2i(13, 20), "name": "聖堂の神官",
			"look": "priest", "solid": true,
			"lines": [
				"ようこそ、七神の御許へ。",
				"ここはオルディナ教国の王国支部です。本国の大聖堂とは比ぶべくもありませんが。",
				"あなたの旅路に、七柱の加護がありますように。",
			],
		},
		{
			"type": "npc", "cell": Vector2i(10, 21), "name": "老いた司祭",
			"look": "elder", "solid": true,
			"lines": [
				"七神は世界を創り、人を守り、そして役目を終えて去られた。",
				"……そう教わってきた。わしも、そう教えてきた。",
			],
		},
		{
			"type": "npc", "cell": Vector2i(16, 21), "name": "参拝者",
			"look": "villager", "solid": true,
			"lines": ["息子が兵に取られましてね。無事を祈りに来たんです。"],
		},
		{
			"type": "npc", "cell": Vector2i(11, 24), "name": "参拝帰りの女",
			"look": "maid", "solid": true,
			"lines": [
				"教会の炊き出しには、ずいぶん助けられました。",
				"偉い方々が何を考えていようと、あれだけは本物ですよ。",
			],
		},

		# ================= 東: 商業区 =================
		{
			"type": "npc", "cell": Vector2i(41, 21), "name": "買い物客",
			"look": "villager", "solid": true,
			"lines": ["武具屋の親父は口が悪いが、品は確かだよ。"],
		},
		{
			"type": "npc", "cell": Vector2i(47, 22), "name": "行商人",
			"look": "merchant", "solid": true,
			"lines": [
				"街道を行き来してるが、荷が思うように運べなくてね。",
				"おかげで王都の品はどれも値上がりだ。ふところが寒いよ。",
			],
		},
		{
			"type": "npc", "cell": Vector2i(52, 21), "name": "鍛冶の弟子",
			"look": "official", "solid": true,
			"lines": [
				"剣は重さで選ぶな、振れる速さで選べって親方が。",
				"……まあ俺はまだ、まともに振れないんですけどね。",
			],
		},
		{
			"type": "npc", "cell": Vector2i(44, 24), "name": "屋台の女", "look": "maid", "solid": true,
			"lines": ["勇者様! 一つどうぞ……って、あら、代金はいりませんよ。"],
		},

		# ================= 中央広場 =================
		{
			"type": "npc", "cell": Vector2i(27, 20), "name": "こども",
			"look": "villager", "solid": true,
			"lines": ["ねえ、ほんとに勇者なの? 剣、見せてよ!"],
		},
		{
			"type": "npc", "cell": Vector2i(33, 22), "name": "こども",
			"look": "villager", "solid": true,
			"lines": ["ぼく、大きくなったら騎士になるんだ!"],
		},
		{
			"type": "npc", "cell": Vector2i(31, 18), "name": "吟遊詩人",
			"look": "merchant", "solid": true,
			"lines": [
				"♪ 勇者は征く 剣を提げ 魔王の城へ ただ独り――",
				"新作でね。ああ、独りじゃないな。連れがいるんだった。書き直そう。",
			],
		},
		{
			"type": "npc", "cell": Vector2i(28, 24), "name": "噴水の老人",
			"look": "elder", "solid": true,
			"lines": [
				"わしが若い頃にも、勇者と名乗る者が幾人か発っていった。",
				"……戻ってきた者は、まだ一人もおらんがね。",
			],
		},
		{
			"type": "npc", "cell": Vector2i(35, 20), "name": "王都の女",
			"look": "maid", "solid": true,
			"lines": ["広場の噴水、王都の自慢なんですよ。水がずっと絶えないの。"],
		},

		# ================= 南: 宿屋・城門 =================
		{
			"type": "npc", "cell": Vector2i(26, 37), "name": "宿の客",
			"look": "villager", "solid": true,
			"lines": ["寝床があるってのは、それだけでありがたいもんさ。"],
		},
		{
			"type": "npc", "cell": Vector2i(21, 38), "name": "洗濯女",
			"look": "maid", "solid": true,
			"lines": ["旅に出るなら、着替えは多めにお持ちなさいな。"],
		},
		{
			"type": "npc", "cell": Vector2i(29, 39), "name": "城門の衛兵",
			"look": "guard", "solid": true,
			"lines": [
				"南の城門だ。ここを抜ければ、もう王都の外だぞ。",
				"……門を開ける許可は、まだ下りていない。もうしばらく待たれよ。",
			],
		},
		{
			"type": "npc", "cell": Vector2i(31, 39), "name": "城門の衛兵",
			"look": "guard", "solid": true,
			"lines": ["支度は済んだか? 物資は王都で揃えておくことだ。"],
		},

		# ================= 住宅街 =================
		{
			"type": "npc", "cell": Vector2i(9, 33), "name": "王都の主婦",
			"look": "maid", "solid": true,
			"lines": ["うちの人ったら、勇者様を一目見たいって朝から広場に行ったきりで。"],
		},
		{
			"type": "npc", "cell": Vector2i(18, 32), "name": "石工",
			"look": "official", "solid": true,
			"lines": [
				"この城壁を積んだのは、俺の祖父さんの祖父さんの代だとさ。",
				"よく持ってるもんだよ、まったく。",
			],
		},
		{
			"type": "npc", "cell": Vector2i(44, 33), "name": "犬を連れた男",
			"look": "villager", "solid": true,
			"lines": ["おい、勇者様の前だぞ。……こら、吠えるな!"],
		},
		{
			"type": "npc", "cell": Vector2i(53, 33), "name": "退役兵",
			"look": "guard", "solid": true,
			"lines": [
				"魔王軍の連中とやり合ったことがある。あれは人の道理が通じん。",
				"……無理はするな。生きて帰ることだ。",
			],
		},
	]
