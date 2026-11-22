class_name SejarahData
extends RefCounted
# Konstanta & tata letak Level 4 (dipisah dari logika). Ruangan Level 4 = ruangan Level 3,
# jadi nilai slot/area di bawah disalin dari Level3Data yang sudah terbukti pas.

# --- Potongan kertas ---
const JUMLAH_POTONGAN := 15       # hardcore nanti: 20 (pool data sudah cukup, lihat catatan)
const MIN_PER_KATEGORI := 4       # tiap kategori 4..7 potongan
const MAKS_PER_KATEGORI := 7
const MAKS_PERCOBAAN := 20        # acak ulang bila validasi gagal

# --- Karya per permainan ---
const JUMLAH_MINIATUR := 4
const JUMLAH_LUKISAN := 3
const FAKTA_PER_KARYA := 3
const TAK_TERBUKTI_PER_KARYA := 2
const VARIAN_SALAH_PER_FAKTA := 2
const MIN_KATA_LABEL := 50
const MAKS_KATA_LABEL := 70

# --- Kategori jawaban ---
enum Kategori { BENAR, SALAH, TIDAK_ADA }
const NAMA_KATEGORI := ["BENAR", "SALAH", "TIDAK ADA"]

# --- Jarak (piksel) ---
const MIN_JARAK_KARYA := 40.0
const MIN_JARAK_KARDUS := 28.0    # kardus ke karya
const RADIUS_SLOT := 40.0         # slot dilarang dekat titik awal/pintu/mesin
const RADIUS_KARDUS := 34.0       # kardus dilarang dekat titik awal/pintu/mesin/kertas kategori

# --- Tata letak (koordinat dunia; salinan nilai Level 3) ---
const AREA_RUANG := Rect2(-188, -90, 376, 170)
const GARIS_DINDING_Y := -110.0
const RENTANG_X_DINDING := Vector2(-150.0, 150.0)
const JUMLAH_SLOT_DINDING := 6
const AREA_LANTAI := Rect2(-128, -44, 256, 64)
const KOLOM_LANTAI := 4
const BARIS_LANTAI := 2
const AREA_KARDUS := Rect2(-90, -20, 180, 66)   # grid titik kardus di lantai
const KOLOM_KARDUS := 3
const BARIS_KARDUS := 2
const TITIK_POJOK: Array[Vector2] = [
	Vector2(-176, -82), Vector2(176, -82), Vector2(-176, 66), Vector2(176, 66),
]
const POSISI_AWAL_PEMAIN := Vector2(0, 0)
const POSISI_PINTU := Vector2(150, 84)
const POSISI_MESIN := Vector2(100, 84)
const POSISI_KERTAS_KATEGORI := Vector2(58, 84)
# Titik tambahan yang dijauhi kardus (tulisan di atas pintu/mesin)
const ZONA_TULISAN: Array[Vector2] = [Vector2(100, 52), Vector2(150, 52)]

# --- Teks catatan kategori (kertas di sebelah mesin) ---
const TEKS_KATEGORI := "[b]BENAR[/b]\nPeristiwa dan tahun pada potongan sama dengan yang tertulis di salah satu label di ruangan ini.\n\n[b]SALAH[/b]\nPeristiwanya disebut di label ruangan ini, tetapi tahun, pelaku, atau hasilnya berbeda dari yang tertulis di label.\n\n[b]TIDAK ADA[/b]\nPeristiwa atau detailnya tidak tertulis di label mana pun di ruangan ini. Nilailah HANYA dari label, bukan dari pengetahuan lain."

static func nama_kategori(k: int) -> String:
	return NAMA_KATEGORI[k]
