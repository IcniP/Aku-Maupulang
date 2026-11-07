class_name Level3Generator
extends RefCounted
# Logika murni Level 3 (tanpa node): pilih karya, slot per jenis, pewarnaan kata,
# hitung ulang jumlah per warna, pilih kertas, kode, dan validasi.
# Dipanggil level3_manager.gd dan Tools/level3_test.gd.

enum TipeKertas { POJOK, LANTAI, TERSELIP }

# Masukan generator.
class Konfigurasi extends RefCounted:
	var pool: Array[ExhibitData] = []
	var slot_dinding: PackedVector2Array = PackedVector2Array()
	var slot_lantai: PackedVector2Array = PackedVector2Array()
	var titik_pojok: PackedVector2Array = PackedVector2Array()
	var titik_kertas_lantai: PackedVector2Array = PackedVector2Array()
	var titik_terlarang: PackedVector2Array = PackedVector2Array()  # awal pemain, pintu, panel
	var radius_slot: float = Level3Data.RADIUS_SLOT
	var radius_kertas: float = Level3Data.RADIUS_KERTAS
	var area_ruang: Rect2 = Level3Data.AREA_RUANG
	var allow_zero: bool = true
	var seed_awal: int = 0   # 0 = acak

# Satu karya yang tampil.
class Karya extends RefCounted:
	var data: ExhibitData
	var posisi: Vector2 = Vector2.ZERO
	var bbcode: String = ""                # deskripsi dengan kata berwarna
	var jumlah_warna: Dictionary = {}      # hasil HITUNG ULANG dari bbcode
	var indeks_kertas: int = -1            # kertas terselip di karya ini (-1 = tidak ada)

# Satu kertas petunjuk.
class Kertas extends RefCounted:
	var warna: String = ""
	var posisi_angka: int = 0              # 0 = angka pertama
	var tipe: int = TipeKertas.POJOK
	var posisi: Vector2 = Vector2.ZERO
	var indeks_karya: int = -1             # untuk TERSELIP
	var teks: String = ""                  # mis. "_biru_"

	# Teks kertas dengan kata warna diberi warnanya (untuk Catatan).
	func ke_bbcode() -> String:
		var hex: String = Level3Data.WARNA.get(warna, "#000000")
		var kiri := "_".repeat(posisi_angka)
		var kanan := "_".repeat(Level3Data.CODE_LENGTH - 1 - posisi_angka)
		return "%s[color=%s][b]%s[/b][/color]%s" % [kiri, hex, warna, kanan]

# Hasil satu permainan.
class Hasil extends RefCounted:
	var seed_dipakai: int = 0
	var seed_dasar: int = 0
	var percobaan: int = 0
	var karya: Array[Level3Generator.Karya] = []
	var kertas: Array[Level3Generator.Kertas] = []
	var jumlah_warna: Dictionary = {}      # total per warna di semua label (hitung ulang)
	var kode: Array[int] = []
	var galat: PackedStringArray = PackedStringArray()

	func valid() -> bool:
		return galat.is_empty()

	func kode_teks() -> String:
		var s := ""
		for d in kode:
			s += str(d)
		return s

# ---------------------------------------------------------------- API utama

# Buat konfigurasi standar dari konstanta Level3Data (dipakai skrip uji).
static func konfigurasi_standar(pool: Array[ExhibitData], allow_zero: bool = true, seed_awal: int = 0) -> Konfigurasi:
	var k := Konfigurasi.new()
	k.pool = pool
	k.allow_zero = allow_zero
	k.seed_awal = seed_awal
	k.slot_dinding = slot_garis(Level3Data.GARIS_DINDING_Y, Level3Data.RENTANG_X_DINDING, Level3Data.JUMLAH_SLOT_DINDING)
	k.slot_lantai = slot_grid(Level3Data.AREA_LANTAI, Level3Data.KOLOM_LANTAI, Level3Data.BARIS_LANTAI)
	k.titik_kertas_lantai = slot_grid(Level3Data.AREA_KERTAS_LANTAI, Level3Data.KOLOM_KERTAS_LANTAI, Level3Data.BARIS_KERTAS_LANTAI)
	k.titik_pojok = PackedVector2Array(Level3Data.TITIK_POJOK)
	k.titik_terlarang = PackedVector2Array([Level3Data.POSISI_AWAL_PEMAIN, Level3Data.POSISI_PINTU, Level3Data.POSISI_PANEL])
	return k

# Titik-titik sejajar pada satu garis horizontal (slot dinding).
static func slot_garis(y: float, rentang_x: Vector2, jumlah: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	if jumlah <= 0:
		return out
	if jumlah == 1:
		out.append(Vector2((rentang_x.x + rentang_x.y) * 0.5, y))
		return out
	var langkah := (rentang_x.y - rentang_x.x) / float(jumlah - 1)
	for i in jumlah:
		out.append(Vector2(rentang_x.x + langkah * i, y))
	return out

# Titik-titik grid di dalam Rect2 (slot lantai / titik kertas lantai).
static func slot_grid(area: Rect2, kolom: int, baris: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for j in baris:
		for i in kolom:
			var fx := 0.5 if kolom <= 1 else float(i) / float(kolom - 1)
			var fy := 0.5 if baris <= 1 else float(j) / float(baris - 1)
			out.append(area.position + Vector2(area.size.x * fx, area.size.y * fy))
	return out

# Jalankan generator; acak ulang (maks MAKS_PERCOBAAN) bila validasi gagal.
static func buat(konf: Konfigurasi) -> Hasil:
	var cek := cek_konfigurasi(konf)
	if not cek.is_empty():
		for pesan in cek:
			push_warning("Level3Generator: " + pesan)
		var h := Hasil.new()
		h.galat = cek
		return h
	var dasar := konf.seed_awal
	if dasar == 0:
		dasar = int((randi() ^ Time.get_ticks_usec()) & 0x3FFFFFFF)
		if dasar == 0:
			dasar = 1
	var terakhir: Hasil = null
	for i in Level3Data.MAKS_PERCOBAAN:
		var hasil := _coba(konf, dasar + i)
		hasil.percobaan = i + 1
		hasil.seed_dasar = dasar
		if hasil.valid():
			return hasil
		terakhir = hasil
	push_warning("Level3Generator: validasi gagal setelah %d percobaan: %s" % [Level3Data.MAKS_PERCOBAAN, ", ".join(terakhir.galat)])
	return terakhir

# Cek konfigurasi sekali di awal (jumlah slot cukup, pool cukup).
static func cek_konfigurasi(konf: Konfigurasi) -> PackedStringArray:
	var g := PackedStringArray()
	var d := _saring(konf.slot_dinding, konf.titik_terlarang, konf.radius_slot)
	var l := _saring(konf.slot_lantai, konf.titik_terlarang, konf.radius_slot)
	if d.size() < Level3Data.JUMLAH_LUKISAN:
		g.append("slot dinding %d < %d" % [d.size(), Level3Data.JUMLAH_LUKISAN])
	if l.size() < Level3Data.JUMLAH_PATUNG:
		g.append("slot lantai %d < %d" % [l.size(), Level3Data.JUMLAH_PATUNG])
	var n_patung := 0
	var n_lukisan := 0
	for e in konf.pool:
		if e.tipe == ExhibitData.Tipe.PATUNG:
			n_patung += 1
		else:
			n_lukisan += 1
	if n_patung < Level3Data.JUMLAH_PATUNG:
		g.append("patung di pool %d < %d" % [n_patung, Level3Data.JUMLAH_PATUNG])
	if n_lukisan < Level3Data.JUMLAH_LUKISAN:
		g.append("lukisan di pool %d < %d" % [n_lukisan, Level3Data.JUMLAH_LUKISAN])
	if Level3Data.WARNA.size() < Level3Data.CODE_LENGTH:
		g.append("warna kurang dari panjang kode")
	return g

# Jumlah kata berwarna per warna dalam satu bbcode (dihitung dari teks akhir).
static func hitung_warna(bbcode: String) -> Dictionary:
	var out := {}
	for w in Level3Data.nama_warna():
		out[w] = 0
	var re := RegEx.new()
	re.compile("\\[color=(#[0-9A-Fa-f]{6})\\]")
	for m: RegExMatch in re.search_all(bbcode):
		var nama := Level3Data.warna_dari_hex(m.get_string(1))
		if nama == "":
			out["_asing"] = int(out.get("_asing", 0)) + 1
		else:
			out[nama] += 1
	return out

static func teks_petunjuk(warna: String, posisi: int) -> String:
	return "_".repeat(posisi) + warna + "_".repeat(Level3Data.CODE_LENGTH - 1 - posisi)

# ---------------------------------------------------------------- satu percobaan

static func _coba(konf: Konfigurasi, nilai_seed: int) -> Hasil:
	var rng := RandomNumberGenerator.new()
	rng.seed = nilai_seed
	var h := Hasil.new()
	h.seed_dipakai = nilai_seed

	# 1) pilih karya dari pool, per jenis
	var patung: Array[ExhibitData] = []
	var lukisan: Array[ExhibitData] = []
	for e in konf.pool:
		if e.tipe == ExhibitData.Tipe.PATUNG:
			patung.append(e)
		else:
			lukisan.append(e)
	_acak(patung, rng)
	_acak(lukisan, rng)

	# 2) pilih slot per jenis (patung = lantai, lukisan = dinding)
	var slot_d := _saring_ke_array(konf.slot_dinding, konf.titik_terlarang, konf.radius_slot)
	var slot_l := _saring_ke_array(konf.slot_lantai, konf.titik_terlarang, konf.radius_slot)
	_acak(slot_d, rng)
	_acak(slot_l, rng)
	for i in Level3Data.JUMLAH_PATUNG:
		var k := Karya.new()
		k.data = patung[i]
		k.posisi = slot_l[i]
		h.karya.append(k)
	for i in Level3Data.JUMLAH_LUKISAN:
		var k := Karya.new()
		k.data = lukisan[i]
		k.posisi = slot_d[i]
		h.karya.append(k)

	# 3) pewarnaan kata, lalu HITUNG ULANG dari label akhir
	var galat_warna := _warnai(h.karya, konf, rng)
	if galat_warna != "":
		h.galat.append(galat_warna)
		return h
	for w in Level3Data.nama_warna():
		h.jumlah_warna[w] = 0
	for k in h.karya:
		k.jumlah_warna = hitung_warna(k.bbcode)
		for w in Level3Data.nama_warna():
			h.jumlah_warna[w] += k.jumlah_warna[w]

	# 4) kertas petunjuk + kode
	var galat_kertas := _buat_kertas(h, konf, rng)
	if galat_kertas != "":
		h.galat.append(galat_kertas)
		return h
	h.kode.resize(Level3Data.CODE_LENGTH)
	for k in h.kertas:
		h.kode[k.posisi_angka] = int(h.jumlah_warna[k.warna])

	# 5) validasi
	h.galat.append_array(validasi(konf, h))
	return h

# Pewarnaan: tentukan target per warna, sebar ke kata acak, bangun BBCode.
# Mengembalikan "" bila sukses, atau pesan galat.
static func _warnai(daftar: Array[Karya], konf: Konfigurasi, rng: RandomNumberGenerator) -> String:
	var tokens: Array = []
	var kapasitas: Array[int] = []
	var total_kap := 0
	for k in daftar:
		var tk := _tokenisasi(k.data.deskripsi)
		tokens.append(tk)
		var c := 0
		for t in tk:
			if t["kata"]:
				c += 1
		kapasitas.append(c)
		total_kap += c
		if c < 1:
			return "label %s tidak punya kata yang boleh diwarnai" % k.data.id
	var nama := Level3Data.nama_warna()
	var batas_bawah := 0 if konf.allow_zero else 1

	# (a) target jumlah per warna (0-9); total harus cukup untuk 1 kata per label
	var target := {}
	var ketemu := false
	for _ulang in 200:
		var total := 0
		for w in nama:
			var v := rng.randi_range(batas_bawah, Level3Data.MAKS_PER_WARNA)
			target[w] = v
			total += v
		if total >= daftar.size() and total <= total_kap:
			ketemu = true
			break
	if not ketemu:
		return "target warna tidak ditemukan"

	# (b) sebar: tiap label dapat minimal 1, sisanya ke label acak yang masih muat
	var bank: Array[String] = []
	for w in nama:
		for _j in int(target[w]):
			bank.append(w)
	_acak(bank, rng)
	var per_label: Array = []
	var urutan: Array[int] = []
	for i in daftar.size():
		per_label.append([])
		urutan.append(i)
	_acak(urutan, rng)
	for i in urutan:
		per_label[i].append(bank.pop_back())
	while not bank.is_empty():
		var w: String = bank.pop_back()
		var kandidat: Array[int] = []
		for i in daftar.size():
			if per_label[i].size() < kapasitas[i]:
				kandidat.append(i)
		if kandidat.is_empty():
			return "kapasitas kata kurang"
		per_label[kandidat[rng.randi_range(0, kandidat.size() - 1)]].append(w)

	# (c) pilih kata acak di tiap label dan bangun BBCode
	for i in daftar.size():
		var indeks_kata: Array[int] = []
		for t in tokens[i].size():
			if tokens[i][t]["kata"]:
				indeks_kata.append(t)
		_acak(indeks_kata, rng)
		var warna_label: Array = per_label[i]
		_acak(warna_label, rng)
		var peta := {}
		for n in warna_label.size():
			peta[indeks_kata[n]] = warna_label[n]
		var bb := ""
		for t in tokens[i].size():
			var teks := _escape(tokens[i][t]["t"])
			if peta.has(t):
				bb += "[color=%s][b]%s[/b][/color]" % [Level3Data.WARNA[peta[t]], teks]
			else:
				bb += teks
		daftar[i].bbcode = bb
	return ""

# Pecah teks jadi token {t: teks, kata: boleh diwarnai?}. Tanda baca & spasi = bukan kata.
static func _tokenisasi(teks: String) -> Array[Dictionary]:
	var re := RegEx.new()
	re.compile("[A-Za-z]+(?:-[A-Za-z]+)*")
	var out: Array[Dictionary] = []
	var pos := 0
	for m: RegExMatch in re.search_all(teks):
		if m.get_start() > pos:
			out.append({"t": teks.substr(pos, m.get_start() - pos), "kata": false})
		var kata := m.get_string()
		out.append({"t": kata, "kata": kata.replace("-", "").length() >= Level3Data.MIN_PANJANG_KATA})
		pos = m.get_end()
	if pos < teks.length():
		out.append({"t": teks.substr(pos), "kata": false})
	return out

static func _escape(teks: String) -> String:
	return teks.replace("[", "[lb]")

# Kertas: tiap posisi angka satu kertas, warna berbeda, tipe & titik acak tanpa tumpuk.
static func _buat_kertas(h: Hasil, konf: Konfigurasi, rng: RandomNumberGenerator) -> String:
	var nama := Level3Data.nama_warna()
	_acak(nama, rng)   # 3 warna pertama = yang ditanyakan, sisanya pengecoh
	var posisi_karya: Array[Vector2] = []
	for k in h.karya:
		posisi_karya.append(k.posisi)
	var pojok := _titik_kertas_layak(konf.titik_pojok, posisi_karya, konf)
	var lantai := _titik_kertas_layak(konf.titik_kertas_lantai, posisi_karya, konf)
	_acak(pojok, rng)
	_acak(lantai, rng)
	var calon_karya: Array[int] = []
	for i in h.karya.size():
		calon_karya.append(i)
	_acak(calon_karya, rng)
	for i in Level3Data.CODE_LENGTH:
		var kr := Kertas.new()
		kr.warna = nama[i]
		kr.posisi_angka = i
		kr.teks = teks_petunjuk(kr.warna, i)
		var opsi: Array[int] = []
		if not pojok.is_empty():
			opsi.append(TipeKertas.POJOK)
		if not lantai.is_empty():
			opsi.append(TipeKertas.LANTAI)
		if not calon_karya.is_empty():
			opsi.append(TipeKertas.TERSELIP)
		if opsi.is_empty():
			return "titik kertas habis"
		kr.tipe = opsi[rng.randi_range(0, opsi.size() - 1)]
		match kr.tipe:
			TipeKertas.POJOK:
				kr.posisi = pojok.pop_back()
			TipeKertas.LANTAI:
				kr.posisi = lantai.pop_back()
			_:
				var ik: int = calon_karya.pop_back()
				kr.indeks_karya = ik
				kr.posisi = h.karya[ik].posisi
				h.karya[ik].indeks_kertas = i
		h.kertas.append(kr)
	return ""

# Titik kertas yang layak: di dalam ruangan, tidak dekat karya, tidak dekat titik terlarang.
static func _titik_kertas_layak(titik: PackedVector2Array, posisi_karya: Array[Vector2], konf: Konfigurasi) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for p in titik:
		if not konf.area_ruang.has_point(p):
			continue
		var ok := true
		for q in posisi_karya:
			if p.distance_to(q) < Level3Data.MIN_JARAK_KERTAS:
				ok = false
		for q in konf.titik_terlarang:
			if p.distance_to(q) < konf.radius_kertas:
				ok = false
		if ok:
			out.append(p)
	return out

# ---------------------------------------------------------------- validasi

# Setara AksaraPuzzle.is_solvable(): kembalikan daftar galat (kosong = lolos).
static func validasi(konf: Konfigurasi, h: Hasil) -> PackedStringArray:
	var g := PackedStringArray()
	var panjang := Level3Data.CODE_LENGTH
	var nama := Level3Data.nama_warna()

	# kode
	if h.kode.size() != panjang:
		g.append("panjang kode %d != %d" % [h.kode.size(), panjang])
	for d in h.kode:
		if d < 0 or d > 9:
			g.append("angka kode di luar 0-9: %d" % d)

	# jumlah karya per jenis
	var n_patung := 0
	var n_lukisan := 0
	for k in h.karya:
		if k.data.tipe == ExhibitData.Tipe.PATUNG:
			n_patung += 1
		else:
			n_lukisan += 1
	if n_patung != Level3Data.JUMLAH_PATUNG or n_lukisan != Level3Data.JUMLAH_LUKISAN:
		g.append("jumlah karya salah: %d patung, %d lukisan" % [n_patung, n_lukisan])

	# label: hitung ulang warna dari data akhir
	var total := {}
	for w in nama:
		total[w] = 0
	for k in h.karya:
		var c := hitung_warna(k.bbcode)
		if c.has("_asing"):
			g.append("warna tak dikenal di label %s" % k.data.id)
		var di_label := 0
		for w in nama:
			total[w] += c[w]
			di_label += c[w]
		if di_label < 1:
			g.append("label %s tanpa kata berwarna" % k.data.id)
		g.append_array(_cek_kata_berwarna(k))
	var batas_bawah := 0 if konf.allow_zero else 1
	for w in nama:
		if total[w] > Level3Data.MAKS_PER_WARNA or total[w] < batas_bawah:
			g.append("jumlah %s = %d di luar batas" % [w, total[w]])
		if h.jumlah_warna.get(w, -1) != total[w]:
			g.append("jumlah %s tidak cocok dengan hitung ulang" % w)

	# slot per jenis & jarak antar karya
	for k in h.karya:
		var daftar := konf.slot_lantai if k.data.tipe == ExhibitData.Tipe.PATUNG else konf.slot_dinding
		var ada := false
		for s in daftar:
			if s.is_equal_approx(k.posisi):
				ada = true
		if not ada:
			g.append("%s tidak berada di slot jenisnya" % k.data.id)
	for i in h.karya.size():
		for j in range(i + 1, h.karya.size()):
			if h.karya[i].posisi.distance_to(h.karya[j].posisi) < Level3Data.MIN_JARAK_KARYA:
				g.append("karya %s dan %s terlalu dekat" % [h.karya[i].data.id, h.karya[j].data.id])

	# kertas: jumlah, posisi angka tepat sekali, warna beda, titik spawn
	if h.kertas.size() != panjang:
		g.append("jumlah kertas %d != %d" % [h.kertas.size(), panjang])
	var hitung_posisi: Array[int] = []
	hitung_posisi.resize(panjang)
	var warna_dipakai := {}
	var karya_terselip := {}
	for i in h.kertas.size():
		var kr := h.kertas[i]
		if kr.posisi_angka < 0 or kr.posisi_angka >= panjang:
			g.append("posisi angka kertas %d tidak valid" % i)
			continue
		hitung_posisi[kr.posisi_angka] += 1
		if not Level3Data.WARNA.has(kr.warna):
			g.append("kertas %d warna tidak dikenal" % i)
		if warna_dipakai.has(kr.warna):
			g.append("warna kertas kembar: %s" % kr.warna)
		warna_dipakai[kr.warna] = true
		if kr.teks != teks_petunjuk(kr.warna, kr.posisi_angka):
			g.append("teks kertas %d salah" % i)
		if kr.posisi_angka < h.kode.size() and h.kode[kr.posisi_angka] != int(total.get(kr.warna, -1)):
			g.append("kode posisi %d tidak cocok dengan jumlah %s" % [kr.posisi_angka, kr.warna])
		if kr.tipe == TipeKertas.TERSELIP:
			if kr.indeks_karya < 0 or kr.indeks_karya >= h.karya.size():
				g.append("kertas %d terselip tanpa karya" % i)
			elif h.karya[kr.indeks_karya].indeks_kertas != i or karya_terselip.has(kr.indeks_karya):
				g.append("kertas %d: satu karya menyimpan lebih dari satu kertas" % i)
			else:
				karya_terselip[kr.indeks_karya] = true
		else:
			if not konf.area_ruang.has_point(kr.posisi):
				g.append("kertas %d di luar ruangan" % i)
			for k in h.karya:
				if kr.posisi.distance_to(k.posisi) < Level3Data.MIN_JARAK_KERTAS:
					g.append("kertas %d menimpa karya %s" % [i, k.data.id])
			for q in konf.titik_terlarang:
				if kr.posisi.distance_to(q) < konf.radius_kertas:
					g.append("kertas %d dekat titik terlarang" % i)
		for j in range(i + 1, h.kertas.size()):
			if kr.tipe != TipeKertas.TERSELIP and h.kertas[j].tipe != TipeKertas.TERSELIP \
					and kr.posisi.distance_to(h.kertas[j].posisi) < 1.0:
				g.append("kertas %d dan %d menumpuk" % [i, j])
	for p in panjang:
		if hitung_posisi[p] != 1:
			g.append("posisi angka %d punya %d kertas" % [p, hitung_posisi[p]])
	return g

# Pastikan semua kata berwarna di satu label valid: huruf saja, >= 3 huruf.
static func _cek_kata_berwarna(k: Karya) -> PackedStringArray:
	var g := PackedStringArray()
	var re := RegEx.new()
	re.compile("\\[color=#[0-9A-Fa-f]{6}\\]\\[b\\]([^\\[\\]]*)\\[/b\\]\\[/color\\]")
	var kata_re := RegEx.new()
	kata_re.compile("^[A-Za-z]+(?:-[A-Za-z]+)*$")
	var cocok := 0
	for m: RegExMatch in re.search_all(k.bbcode):
		cocok += 1
		var kata := m.get_string(1)
		if kata_re.search(kata) == null or kata.replace("-", "").length() < Level3Data.MIN_PANJANG_KATA:
			g.append("kata berwarna tidak valid di %s: '%s'" % [k.data.id, kata])
	var semua := k.bbcode.count("[color=")
	if semua != cocok:
		g.append("format kata berwarna rusak di %s" % k.data.id)
	return g

# ---------------------------------------------------------------- util

static func _saring(titik: PackedVector2Array, terlarang: PackedVector2Array, radius: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in titik:
		var ok := true
		for q in terlarang:
			if p.distance_to(q) < radius:
				ok = false
		if ok:
			out.append(p)
	return out

static func _saring_ke_array(titik: PackedVector2Array, terlarang: PackedVector2Array, radius: float) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for p in _saring(titik, terlarang, radius):
		out.append(p)
	return out

# Fisher-Yates dengan RNG ber-seed, supaya debug_seed menghasilkan permainan yang sama.
static func _acak(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp: Variant = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
