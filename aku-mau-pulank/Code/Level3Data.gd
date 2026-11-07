class_name Level3Data
extends RefCounted
# Data & konstanta Level 3. Dipisah dari logika (Level3Generator.gd).
# Ubah angka di sini bila ingin menyetel kode, tata letak, atau warna.

# --- Kode & jumlah karya ---
const CODE_LENGTH := 3            # panjang kode (mode hardcore nanti: 4)
const JUMLAH_PATUNG := 4          # patung yang tampil tiap permainan
const JUMLAH_LUKISAN := 3         # lukisan yang tampil tiap permainan
const MAKS_PER_WARNA := 9         # jumlah kata berwarna per warna, 0..9
const MIN_PANJANG_KATA := 3       # hanya kata >= 3 huruf yang boleh diwarnai
const MAKS_PERCOBAAN := 20        # acak ulang bila validasi gagal

# --- Jarak (piksel) ---
const MIN_JARAK_KARYA := 40.0     # jarak minimal antar karya
const MIN_JARAK_KERTAS := 28.0    # jarak minimal kertas ke karya
const RADIUS_SLOT := 40.0         # slot dilarang dekat titik awal/pintu/panel
const RADIUS_KERTAS := 34.0       # kertas dilarang dekat titik awal/pintu/panel

# --- Warna kata (nama -> hex, HURUF BESAR). Terbaca di atas putih. ---
const WARNA := {
	"merah": "#E01B1B",
	"hijau": "#1A8A33",
	"biru": "#2447E6",
	"kuning": "#B88A00",
	"magenta": "#D61FA8",
	"cyan": "#008FA3",
}

# --- Tata letak default (koordinat dunia; ruangan = tile -12..11 x, -6..5 y, 16 px) ---
# Lantai dalam: x -192..192, y -96..80 (dinding bawah menutupi y 80..96).
const AREA_RUANG := Rect2(-188, -90, 376, 170)       # batas yang bisa dijangkau pemain
const GARIS_DINDING_Y := -110.0                      # tengah lukisan di dinding atas
const RENTANG_X_DINDING := Vector2(-150.0, 150.0)
const JUMLAH_SLOT_DINDING := 6
const AREA_LANTAI := Rect2(-128, -44, 256, 64)       # slot patung (grid)
const KOLOM_LANTAI := 4
const BARIS_LANTAI := 2
const AREA_KERTAS_LANTAI := Rect2(-90, -20, 180, 66) # titik kertas di lantai (grid)
const KOLOM_KERTAS_LANTAI := 3
const BARIS_KERTAS_LANTAI := 2
const TITIK_POJOK: Array[Vector2] = [
	Vector2(-176, -82), Vector2(176, -82), Vector2(-176, 66), Vector2(176, 66),
]
const POSISI_AWAL_PEMAIN := Vector2(0, 0)
const POSISI_PINTU := Vector2(150, 84)
const POSISI_PANEL := Vector2(104, 84)

static func nama_warna() -> Array[String]:
	var out: Array[String] = []
	for k in WARNA.keys():
		out.append(k)
	return out

# Kembalikan nama warna dari hex (tak peduli huruf besar/kecil); "" bila tidak dikenal.
static func warna_dari_hex(hex: String) -> String:
	for k in WARNA.keys():
		if String(WARNA[k]).to_upper() == hex.to_upper():
			return k
	return ""
