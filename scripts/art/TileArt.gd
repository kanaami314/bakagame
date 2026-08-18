class_name TileArt
extends RefCounted
## 絵の供給元。**差し替え用のPNGがあればそれを使い、無ければ仮のドット絵を生成する。**
##
## 現在コード内に書かれているドット絵はすべて仮アセットである。
## 本番の絵を用意したら、決められた場所へPNGを置くだけで置き換わる。
## コードの修正は不要。
##
##   タイル・物体  res://assets/tiles/<名前>.png
##   人物          res://assets/sprites/<look_id>_<向き>.png
##
## 命名の詳細と一覧は docs/アセット差し替え.md を参照。
##
## 仮アセットの生成方法: 各行の文字がパレットのキーに対応し、パレットに無い文字
## (空白など)は「下地の色をそのまま残す」扱いになる。そのため行の長さが多少
## ずれても絵が壊れず下地で埋まるだけで済む。

const SIZE := 16

const TILE_ASSET_DIR := "res://assets/tiles/"
const CHARACTER_ASSET_DIR := "res://assets/sprites/"

## 人物の見た目。仮アセットではここの色で塗り分ける。
## 差し替え後はキーが <look_id> としてPNGのファイル名に対応する。
const LOOKS := {
	"hero": {"tunic": Color("3f6fc4"), "hair": Color("caa14a")},
	"priest": {"tunic": Color("e8e8f0"), "hair": Color("c9a24b")},
	"villager": {"tunic": Color("4aa87a"), "hair": Color("5a4030")},
	"elder": {"tunic": Color("8a5fb0"), "hair": Color("d8d8e0")},
	"merchant": {"tunic": Color("d98b3b"), "hair": Color("3a2a1e")},
	"innkeeper": {"tunic": Color("9a6a4a"), "hair": Color("4a3020")},
	"king": {"tunic": Color("7a2f8a"), "hair": Color("dcdce4")},
	"guard": {"tunic": Color("6f7d94"), "hair": Color("3a2f28")},
	"official": {"tunic": Color("46605a"), "hair": Color("bdbdc6")},
	"maid": {"tunic": Color("8fb0d4"), "hair": Color("5a4030")},
}

const PALETTE := {
	"k": Color("1a1420"), # 輪郭
	"g": Color("4e7a3a"), # 草
	"G": Color("3d6130"), # 濃い草
	"l": Color("6b9a4c"), # 明るい草
	"d": Color("a8865c"), # 土
	"D": Color("8a6c46"), # 濃い土
	"s": Color("6a6a78"), # 石
	"S": Color("41414e"), # 濃い石
	"e": Color("8f8f9e"), # 明るい石
	"t": Color("6b4a2f"), # 幹
	"T": Color("4d3520"), # 濃い幹
	"f": Color("3f7a3a"), # 葉
	"F": Color("2c5a2a"), # 濃い葉
	"w": Color("b08a5a"), # 木材
	"W": Color("7d5f3c"), # 濃い木材
	"c": Color("7ec8e3"), # 窓
	"r": Color("b04a3a"), # 屋根
	"R": Color("8a3529"), # 濃い屋根
	"y": Color("d9a53b"), # 金
	"Y": Color("a87c22"), # 濃い金
	"m": Color("9aa0ab"), # 金属
	"n": Color("e8c49a"), # 肌
	"h": Color("6b4a2f"), # 髪
	"b": Color("3f6fc4"), # 衣服(既定)
	"A": Color("c3c0cf"), # 大理石
	"B": Color("9a97a8"), # 大理石の影
}

static var _image_cache: Dictionary = {}
static var _texture_cache: Dictionary = {}


## 差し替え用アセットが置かれていればそれを返す。無ければ null。
static func _load_override(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	var res: Resource = load(path)
	return res as Texture2D


## スプライトへ人物の絵を設定する。
## 差し替え用アセットが16pxより背が高くても、足元がマスの底に揃うようにする。
static func apply_character_texture(spr: Sprite2D, look_id: String, dir: String) -> void:
	var tex := character(look_id, dir)
	spr.texture = tex
	spr.centered = true
	spr.offset = Vector2(0, (SIZE - tex.get_height()) * 0.5)


## 文字列パターンから画像を生成する。
## base で塗りつぶしてからパターンを重ねるので、パレットに無い文字は下地が残る。
static func make(rows: Array, palette: Dictionary, base: Color) -> Image:
	var img := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(base)
	for y in mini(rows.size(), SIZE):
		var row := String(rows[y])
		for x in mini(row.length(), SIZE):
			var ch := row[x]
			if palette.has(ch):
				img.set_pixel(x, y, palette[ch])
	return img


static func get_texture(art_name: String) -> Texture2D:
	var key := "tile:" + art_name
	if _texture_cache.has(key):
		return _texture_cache[key]
	var tex := _load_override(TILE_ASSET_DIR + art_name + ".png")
	if tex == null:
		tex = ImageTexture.create_from_image(get_image(art_name))
	_texture_cache[key] = tex
	return tex


## 画像そのものが必要な場合(書き出しツールなど)に使う。
static func get_image(art_name: String) -> Image:
	var key := "tile:" + art_name
	if _image_cache.has(key):
		return _image_cache[key]
	var override := _load_override(TILE_ASSET_DIR + art_name + ".png")
	var img: Image = override.get_image() if override != null else _build(art_name)
	_image_cache[key] = img
	return img


## 人物の絵。look_id は LOOKS のキー("hero" "priest" "guard" など)。
## dir は "down" "up" "left" "right"。
static func character(look_id: String, dir: String) -> Texture2D:
	var key := "char:%s:%s" % [look_id, dir]
	if _texture_cache.has(key):
		return _texture_cache[key]
	var tex := _load_override(CHARACTER_ASSET_DIR + look_id + "_" + dir + ".png")
	if tex == null:
		tex = ImageTexture.create_from_image(character_image(look_id, dir))
	_texture_cache[key] = tex
	return tex


static func character_image(look_id: String, dir: String) -> Image:
	var key := "char:%s:%s" % [look_id, dir]
	if _image_cache.has(key):
		return _image_cache[key]

	var override := _load_override(CHARACTER_ASSET_DIR + look_id + "_" + dir + ".png")
	var img: Image
	if override != null:
		img = override.get_image()
	else:
		var look: Dictionary = LOOKS.get(look_id, LOOKS["villager"])
		var pal := PALETTE.duplicate()
		pal["b"] = look["tunic"]
		pal["h"] = look["hair"]
		var rows: Array = CHAR_DOWN
		match dir:
			"up":
				rows = CHAR_UP
			"left":
				rows = CHAR_SIDE
			"right":
				rows = _mirror(CHAR_SIDE)
			_:
				rows = CHAR_DOWN
		img = make(rows, pal, Color(0, 0, 0, 0))

	_image_cache[key] = img
	return img


static func _mirror(rows: Array) -> Array:
	var out: Array = []
	for r in rows:
		var padded := String(r).rpad(SIZE, " ")
		out.append(padded.reverse())
	return out


static func _build(art_name: String) -> Image:
	match art_name:
		"grass":
			return make(GRASS, PALETTE, PALETTE["g"])
		"path":
			return make(PATH, PALETTE, PALETTE["d"])
		"floor":
			return make(FLOOR, PALETTE, PALETTE["S"])
		"wall_stone":
			return make(WALL_STONE, PALETTE, PALETTE["s"])
		"pillar":
			return make(PILLAR, PALETTE, PALETTE["S"])
		"tree":
			return make(TREE, PALETTE, PALETTE["g"])
		"house":
			return make(HOUSE, PALETTE, PALETTE["w"])
		"house_door":
			return make(HOUSE_DOOR, PALETTE, PALETTE["w"])
		"roof":
			return make(ROOF, PALETTE, PALETTE["r"])
		"castle_floor":
			return make(CASTLE_FLOOR, PALETTE, PALETTE["A"])
		"castle_wall":
			return make(CASTLE_WALL, PALETTE, PALETTE["s"])
		"carpet":
			return make(CARPET, PALETTE, PALETTE["r"])
		"throne":
			return make(THRONE, PALETTE, Color(0, 0, 0, 0))
		"chest":
			return make(CHEST, PALETTE, Color(0, 0, 0, 0))
		"sign":
			return make(SIGN, PALETTE, Color(0, 0, 0, 0))
		_:
			return make([], PALETTE, Color(1, 0, 1, 1)) # 未定義はマゼンタで目立たせる


# ---------------- 地面 ----------------

const GRASS := [
	"                ",
	"  l        l    ",
	"      G         ",
	" G          l   ",
	"        l       ",
	"   l         G  ",
	"                ",
	" G      G       ",
	"           l    ",
	"     G          ",
	"  l          G  ",
	"          l     ",
	"                ",
	"    G     G     ",
	"        l       ",
	"  G             ",
]

const PATH := [
	"                ",
	"   D        D   ",
	"        D       ",
	" D           D  ",
	"      D         ",
	"           D    ",
	"  D             ",
	"       D    D   ",
	"            D   ",
	"   D            ",
	"        D       ",
	" D          D   ",
	"     D          ",
	"           D    ",
	"  D      D      ",
	"                ",
]

## 8x8の敷石。継ぎ目が入ることで「床」だと分かるようにしている。
const FLOOR := [
	"ssssssssssssssss",
	"s       s       ",
	"s       s       ",
	"s       s       ",
	"s       s       ",
	"s       s       ",
	"s       s       ",
	"s       s       ",
	"ssssssssssssssss",
	"s       s       ",
	"s       s       ",
	"s       s       ",
	"s       s       ",
	"s       s       ",
	"s       s       ",
	"s       s       ",
]

## レンガ積みの壁。目地を暗く、上面を明るくして立体感を出す。
const WALL_STONE := [
	"SSSSSSSSSSSSSSSS",
	"eeeeeeeeeeeeeeee",
	"       S        ",
	"       S        ",
	"SSSSSSSSSSSSSSSS",
	"eeeeeeeeeeeeeeee",
	"   S        S   ",
	"   S        S   ",
	"SSSSSSSSSSSSSSSS",
	"eeeeeeeeeeeeeeee",
	"       S        ",
	"       S        ",
	"SSSSSSSSSSSSSSSS",
	"eeeeeeeeeeeeeeee",
	"   S        S   ",
	"   S        S   ",
]

const PILLAR := [
	"                ",
	"   eeeeeeeeee   ",
	"   eSSSSSSSSe   ",
	"    seeeeees    ",
	"    seeeeees    ",
	"    sSeeeeSs    ",
	"    seeeeees    ",
	"    seeeeees    ",
	"    sSeeeeSs    ",
	"    seeeeees    ",
	"    seeeeees    ",
	"    sSeeeeSs    ",
	"    seeeeees    ",
	"   eSSSSSSSSe   ",
	"   eeeeeeeeee   ",
	"                ",
]

# ---------------- 城 ----------------

## 磨かれた大理石の床。遺跡の石床より明るく整った印象にする。
const CASTLE_FLOOR := [
	"BBBBBBBBBBBBBBBB",
	"B       B       ",
	"B       B       ",
	"B       B       ",
	"B       B       ",
	"B       B       ",
	"B       B       ",
	"B       B       ",
	"BBBBBBBBBBBBBBBB",
	"B       B       ",
	"B       B       ",
	"B       B       ",
	"B       B       ",
	"B       B       ",
	"B       B       ",
	"B       B       ",
]

## 城壁。遺跡の壁と同じレンガ積みだが、金の帯を入れて格式を出す。
const CASTLE_WALL := [
	"SSSSSSSSSSSSSSSS",
	"AAAAAAAAAAAAAAAA",
	"       S        ",
	"       S        ",
	"SSSSSSSSSSSSSSSS",
	"yyyyyyyyyyyyyyyy",
	"YYYYYYYYYYYYYYYY",
	"   S        S   ",
	"SSSSSSSSSSSSSSSS",
	"AAAAAAAAAAAAAAAA",
	"       S        ",
	"       S        ",
	"SSSSSSSSSSSSSSSS",
	"AAAAAAAAAAAAAAAA",
	"   S        S   ",
	"   S        S   ",
]

## 赤絨毯。縦に敷き詰めると両脇に金の縁が続いて見える。
const CARPET := [
	"yY            Yy",
	"yY            Yy",
	"yY            Yy",
	"yY            Yy",
	"yY            Yy",
	"yY            Yy",
	"yY            Yy",
	"yY            Yy",
	"yY            Yy",
	"yY            Yy",
	"yY            Yy",
	"yY            Yy",
	"yY            Yy",
	"yY            Yy",
	"yY            Yy",
	"yY            Yy",
]

const THRONE := [
	"                ",
	"   kkkkkkkkkk   ",
	"   kyyyyyyyyk   ",
	"   kyYYYYYYyk   ",
	"   kyYrrrrYyk   ",
	"   kyYrrrrYyk   ",
	"   kyYrrrrYyk   ",
	"   kyYrrrrYyk   ",
	"   kyYYYYYYyk   ",
	"   kyyyyyyyyk   ",
	"  kkyrrrrrrykk  ",
	"  kyyrrrrrryyk  ",
	"  kyyyyyyyyyyk  ",
	"  kkkkkkkkkkkk  ",
	"   kk      kk   ",
	"   kk      kk   ",
]

# ---------------- 建物・自然物 ----------------

const TREE := [
	"                ",
	"     FFFFFF     ",
	"   FFffffffFF   ",
	"  FffffffffffF  ",
	"  FffflffffffF  ",
	" FfffllffffffFF ",
	" FffffffffffffF ",
	" FFffffffffffFF ",
	"  FFffffffffFF  ",
	"   FFFffffFFF   ",
	"     FTttTF     ",
	"      TttT      ",
	"      TttT      ",
	"     GTttTG     ",
	"    GGttttGG    ",
	"                ",
]

const HOUSE := [
	"WWWWWWWWWWWWWWWW",
	"W              W",
	"W  WWWWWWWWWW  W",
	"W  WccccccccW  W",
	"W  WccccccccW  W",
	"W  WccccccccW  W",
	"W  WWWWWWWWWW  W",
	"W              W",
	"WWWWWWWWWWWWWWWW",
	"W              W",
	"W              W",
	"W              W",
	"W              W",
	"W              W",
	"W              W",
	"WWWWWWWWWWWWWWWW",
]

const HOUSE_DOOR := [
	"WWWWWWWWWWWWWWWW",
	"W              W",
	"W   WWWWWWWW   W",
	"W   WkkkkkkW   W",
	"W   WkWWWWkW   W",
	"W   WkWWWWkW   W",
	"W   WkWWWWkW   W",
	"W   WkWWWWkW   W",
	"W   WkWmWWkW   W",
	"W   WkWWWWkW   W",
	"W   WkWWWWkW   W",
	"W   WkWWWWkW   W",
	"W   WkWWWWkW   W",
	"W   WkWWWWkW   W",
	"W   WkkkkkkW   W",
	"WWWWWWWWWWWWWWWW",
]

const ROOF := [
	"RRRRRRRRRRRRRRRR",
	"                ",
	"                ",
	"RRRRRRRRRRRRRRRR",
	"                ",
	"                ",
	"RRRRRRRRRRRRRRRR",
	"                ",
	"                ",
	"RRRRRRRRRRRRRRRR",
	"                ",
	"                ",
	"RRRRRRRRRRRRRRRR",
	"                ",
	"                ",
	"RRRRRRRRRRRRRRRR",
]

# ---------------- オブジェクト ----------------

const CHEST := [
	"                ",
	"                ",
	"   kkkkkkkkkk   ",
	"  kyyyyyyyyyyk  ",
	"  kyYYYYYYYYyk  ",
	"  kyyyyyyyyyyk  ",
	"  kkkkkkkkkkkk  ",
	"  kWwwwmmwwwWk  ",
	"  kWwwwmmwwwWk  ",
	"  kWwwwmmwwwWk  ",
	"  kWwwwwwwwwWk  ",
	"  kWwwwwwwwwWk  ",
	"  kkkkkkkkkkkk  ",
	"                ",
	"                ",
	"                ",
]

const SIGN := [
	"                ",
	"   kkkkkkkkkk   ",
	"   kwwwwwwwwk   ",
	"   kwWWWWWWwk   ",
	"   kwWWWWWWwk   ",
	"   kwWWWWWWwk   ",
	"   kwwwwwwwwk   ",
	"   kkkkkkkkkk   ",
	"      kWWk      ",
	"      kWWk      ",
	"      kWWk      ",
	"      kWWk      ",
	"      kWWk      ",
	"     kkWWkk     ",
	"                ",
	"                ",
]

# ---------------- 人物 ----------------

const CHAR_DOWN := [
	"                ",
	"     kkkkkk     ",
	"    khhhhhhk    ",
	"   khhhhhhhhk   ",
	"   khnnnnnnhk   ",
	"   khnknnknhk   ",
	"   kknnnnnnkk   ",
	"    knnnnnnk    ",
	"     kknnkk     ",
	"    kbbbbbbk    ",
	"   kbbbbbbbbk   ",
	"   knbbbbbbnk   ",
	"   kbbbbbbbbk   ",
	"    kbbbbbbk    ",
	"    kWWkkWWk    ",
	"    kkk  kkk    ",
]

const CHAR_UP := [
	"                ",
	"     kkkkkk     ",
	"    khhhhhhk    ",
	"   khhhhhhhhk   ",
	"   khhhhhhhhk   ",
	"   khhhhhhhhk   ",
	"   kkhhhhhhkk   ",
	"    khhhhhhk    ",
	"     kkhhkk     ",
	"    kbbbbbbk    ",
	"   kbbbbbbbbk   ",
	"   knbbbbbbnk   ",
	"   kbbbbbbbbk   ",
	"    kbbbbbbk    ",
	"    kWWkkWWk    ",
	"    kkk  kkk    ",
]

const CHAR_SIDE := [
	"                ",
	"     kkkkkk     ",
	"    khhhhhhk    ",
	"   khhhhhhhhk   ",
	"   khnnnnnhhk   ",
	"   khknnnnhhk   ",
	"   kknnnnnnkk   ",
	"    knnnnnnk    ",
	"     kknnkk     ",
	"    kbbbbbbk    ",
	"   nbbbbbbbk    ",
	"   kbbbbbbbk    ",
	"    kbbbbbbk    ",
	"    kbbbbbbk    ",
	"    kWWkkWWk    ",
	"    kkk  kkk    ",
]
