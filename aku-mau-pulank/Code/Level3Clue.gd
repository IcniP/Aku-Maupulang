class_name Level3Clue
extends RefCounted
# Logika murni clue Level 3 (tanpa node): ringkasan hitungan per label, kotak kertas, kamus warna,
# dan isi kertas CLUE (informasi yang tersebar di ruangan). Dipakai Level3UI.gd dan Tools/level3_test.gd.
# Teks tetap ada di Level3Data.

# Hitungan warna di satu label (nama warna -> jumlah), dihitung ulang dari BBCode akhir.
static func ringkas_label(bbcode: String) -> Dictionary:
	return Level3Generator.hitung_warna(bbcode)

# Nama warna dengan warnanya, huruf besar tebal. Contoh: KUNING (berwarna kuning).
static func nama_tebal(warna: String) -> String:
	var hex: String = Level3Data.WARNA.get(warna, "#000000")
	return "[color=%s][b]%s[/b][/color]" % [hex, warna.to_upper()]

# Kertas tampil sebagai kotak: digit yang ditanyakan berisi warna, sisanya "?".
# Contoh kertas ke-2: [ ? ] [ BIRU ] [ ? ]. Tanda kurung dipakai lewat [lb] dan [rb] agar bukan tag BBCode.
static func kotak_kertas(kertas: Level3Generator.Kertas) -> String:
	var bagian: PackedStringArray = PackedStringArray()
	for i in Level3Data.CODE_LENGTH:
		if i == kertas.posisi_angka:
			bagian.append("[lb] %s [rb]" % nama_tebal(kertas.warna))
		else:
			bagian.append("[lb] ? [rb]")
	return "  ".join(bagian)

# Kamus enam warna, tiap nama ditulis dengan warnanya sendiri.
static func kamus_warna() -> String:
	var bagian: PackedStringArray = PackedStringArray()
	for w in Level3Data.nama_warna():
		bagian.append(nama_tebal(w))
	return "   ".join(bagian)

# Satu baris catatan label: hanya warna yang jumlahnya > 0, tiap warna dengan warnanya.
static func baris_label(judul: String, jumlah: Dictionary) -> String:
	var bagian: PackedStringArray = PackedStringArray()
	var total := 0
	for w in Level3Data.nama_warna():
		var n: int = int(jumlah.get(w, 0))
		if n > 0:
			var hex: String = Level3Data.WARNA[w]
			bagian.append("[color=%s][b]%s %d[/b][/color]" % [hex, w, n])
			total += n
	var isi := ", ".join(bagian) if total > 0 else "tidak ada kata berwarna"
	return "%s: %s" % [judul.replace("[", "[lb]"), isi]

# Jumlah kata berwarna per warna dari label yang SUDAH dibaca (dibaca: id -> {judul, jumlah}).
static func total_sebagian(dibaca: Dictionary) -> Dictionary:
	var out := {}
	for w in Level3Data.nama_warna():
		out[w] = 0
	for id in dibaca:
		var jumlah: Dictionary = dibaca[id]["jumlah"]
		for w in Level3Data.nama_warna():
			out[w] += int(jumlah.get(w, 0))
	return out

# Contoh kertas kode untuk kertas clue "Cara Membaca Kertas Kode" (bukan kertas sungguhan).
static func contoh_kotak() -> String:
	var contoh := Level3Generator.Kertas.new()
	contoh.warna = "kuning"
	contoh.posisi_angka = 0
	return kotak_kertas(contoh)

static func judul_clue(indeks: int) -> String:
	return String(Level3Data.CLUE_KERTAS[indeks]["judul"])

# Isi kertas clue dengan penanda {CONTOH} dan {KAMUS} sudah diganti.
static func isi_clue(indeks: int) -> String:
	var isi := String(Level3Data.CLUE_KERTAS[indeks]["isi"])
	isi = isi.replace("{CONTOH}", contoh_kotak())
	isi = isi.replace("{KAMUS}", kamus_warna())
	return isi
