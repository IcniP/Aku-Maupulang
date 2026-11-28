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
const RADIUS_KERTAS := 46.0       # kertas (kode dan clue) dilarang dekat titik awal/pintu/panel, supaya tidak berebut tombol E dengan panel kode

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

# --- Kertas CLUE: kertas informasi yang tersebar di ruangan. Bisa dibaca berulang kali, TIDAK bisa diambil
# (berbeda dengan kertas KODE yang masuk ke Catatan). Lokasi acak tiap permainan, tidak di dinding bawah. ---
const JUMLAH_CLUE := 5
# Titik kertas clue di dinding kiri dan kanan (tepat di tepi lantai; x = +-186 masih di dalam AREA_RUANG).
const TITIK_DINDING_SAMPING: Array[Vector2] = [
	Vector2(-186, -30), Vector2(-186, 30), Vector2(186, -30), Vector2(186, 30),
]
const DURASI_BANNER := 7.0                # detik banner misi tampil saat level mulai
const TEKS_BANNER := "Hologram pameran ini error: beberapa kata di label berubah warna. Mungkin itu bukan kebetulan! Cari kertas petunjuk di lantai, di dinding atas, kiri, dan kanan, atau terselip di lukisan."

# Isi tiap kertas clue (BBCode). Penanda {CONTOH} dan {KAMUS} diganti oleh Level3Clue.isi_clue().
const CLUE_KERTAS := [
	{"judul": "Catatan Teknisi Budi",
	"isi": "Hologram expo error lagi! Kata-kata di label jadi warna-warni, dan kode pintu cadangan kucatat di kertas-kertas yang kusebar. Sayangnya aku lupa menaruhnya di mana. Tolong ya!\n\nKodenya 3 angka. Masukkan ke panel KODE di samping pintu.\n\n- Budi, teknisi shift malam"},
	{"judul": "Cara Membaca Kertas Kode",
	"isi": "Ada 3 kertas kode yang bisa diambil. Tiap kertas menyebut SATU WARNA untuk SATU DIGIT kode.\n\nContoh kertas:\n{CONTOH}\nArtinya: digit ke-1 kode = jumlah kata KUNING di SEMUA label karya."},
	{"judul": "Cara Menghitung",
	"isi": "1. Buka SEMUA 7 label karya (tekan E pada patung dan lukisan).\n2. Hitung hanya kata yang warnanya bukan hitam, sesuai warna di kertas kode.\n3. Jumlahkan dari semua label.\n\nTombol N membuka Catatan. Catatan mencatat hitungan tiap label yang sudah kamu buka, jadi kamu tidak perlu mengingatnya."},
	{"judul": "Kamus Warna",
	"isi": "Ada enam warna:\n{KAMUS}\n\nHati-hati: merah dan magenta mirip, biru dan cyan juga mirip. Satu kata hanya punya satu warna."},
	{"judul": "Di Mana Kertas Kode?",
	"isi": "Kertas kode bisa ada di sudut ruangan, tergeletak di lantai, atau terselip di label karya (buka labelnya, lalu tekan Ambil kertas terselip).\n\nKertas yang ini lain: tidak bisa diambil, tetapi boleh kamu baca lagi kapan saja."},
]
