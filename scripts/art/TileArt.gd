class_name TileArt
extends RefCounted
## ドット絵をコード内の文字列パターンから生成する。外部アセットに依存しない。
##
## 各行の文字はパレットのキーに対応し、パレットに無い文字(空白など)は
## 「下地の色をそのまま残す」扱いになる。そのため行の長さが多少ずれても
## 絵が壊れず下地で埋まるだけで済む。

const SIZE := 16

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

static var _cache: Dictionary = {} # 名前 -> Image (テクスチャはここから作る)


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


static func get_image(art_name: String) -> Image:
	if not _cache.has(art_name):
		_cache[art_name] = _build(art_name)
	return _cache[art_name]


static func get_texture(art_name: String) -> ImageTexture:
	return ImageTexture.create_from_image(get_image(art_name))


## 人型スプライト。服と髪の色を差し替えて村人・神官などを作り分ける。
static func character_image(dir: String, tunic: Color, hair: Color = PALETTE["h"]) -> Image:
	var key := "char_%s_%s_%s" % [dir, tunic.to_html(false), hair.to_html(false)]
	if _cache.has(key):
		return _cache[key]
	var pal := PALETTE.duplicate()
	pal["b"] = tunic
	pal["h"] = hair
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
	var img := make(rows, pal, Color(0, 0, 0, 0))
	_cache[key] = img
	return img


static func character(dir: String, tunic: Color, hair: Color = PALETTE["h"]) -> ImageTexture:
	return ImageTexture.create_from_image(character_image(dir, tunic, hair))


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
