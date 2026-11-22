class_name SejarahGenerator
extends RefCounted
# Logika murni Level 4 (tanpa node): pilih karya per jenis, slot, titik kardus, bentuk
# 15 potongan kertas (BENAR / SALAH / TIDAK ADA), dan validasi. Pola mengikuti Level3Generator.
# Kategori dinilai HANYA dari isi label yang tampil, bukan dari kebenaran sejarah sebenarnya.

enum Jenis { BENAR, SALAH, TAK_TERBUKTI, FAKTA_TAK_TAMPIL }

# Masukan generator.
class Konfigurasi extends RefCounted:
	var pool: Array[SejarahKaryaData] = []
	var slot_dinding: PackedVector2Array = PackedVector2Array()
	var slot_lantai: PackedVector2Array = PackedVector2Array()
	var titik_kardus: PackedVector2Array = PackedVector2Array()
	var titik_terlarang: PackedVector2Array = PackedVector2Array()  # awal pemain, pintu, mesin, kertas kategori
	var radius_slot: float = SejarahData.RADIUS_SLOT
	var radius_kardus: float = SejarahData.RADIUS_KARDUS
	var area_ruang: Rect2 = SejarahData.AREA_RUANG
	var jumlah_potongan: int = SejarahData.JUMLAH_POTONGAN
	var min_per_kategori: int = SejarahData.MIN_PER_KATEGORI
	var maks_per_kategori: int = SejarahData.MAKS_PER_KATEGORI
	var seed_awal: int = 0   # 0 = acak

# Satu karya yang tampil.
class Karya extends RefCounted:
	var data: SejarahKaryaData
	var posisi: Vector2 = Vector2.ZERO

# Satu potongan kertas berisi satu pernyataan.
class Potongan extends RefCounted:
	var teks: String = ""
	var kategori: int = SejarahData.Kategori.BENAR   # jawaban yang benar
	var jenis: int = SejarahGenerator.Jenis.BENAR
	var karya_id: StringName = &""                   # karya sumber
	var fakta_id: StringName = &""                   # kosong untuk TAK_TERBUKTI
	var kata_kunci: String = ""
	var tahun: int = 0

# Hasil satu permainan.
class Hasil extends RefCounted:
	var seed_dipakai: int = 0
	var seed_dasar: int = 0
	var percobaan: int = 0
	var karya: Array[SejarahGenerator.Karya] = []
	var potongan: Array[SejarahGenerator.Potongan] = []
	var posisi_kardus: Vector2 = Vector2.ZERO
	var galat: PackedStringArray = PackedStringArray()

	func valid() -> bool:
		return galat.is_empty()

	# Jumlah potongan per kategori [BENAR, SALAH, TIDAK_ADA].
	func komposisi() -> Array[int]:
		var c: Array[int] = [0, 0, 0]
		for p in potongan:
			c[p.kategori] += 1
		return c

# ---------------------------------------------------------------- API utama

static func konfigurasi_standar(pool: Array[SejarahKaryaData], seed_awal: int = 0) -> Konfigurasi:
	var k := Konfigurasi.new()
	k.pool = pool
	k.seed_awal = seed_awal
	k.slot_dinding = slot_garis(SejarahData.GARIS_DINDING_Y, SejarahData.RENTANG_X_DINDING, SejarahData.JUMLAH_SLOT_DINDING)
	k.slot_lantai = slot_grid(SejarahData.AREA_LANTAI, SejarahData.KOLOM_LANTAI, SejarahData.BARIS_LANTAI)
	k.titik_kardus = slot_grid(SejarahData.AREA_KARDUS, SejarahData.KOLOM_KARDUS, SejarahData.BARIS_KARDUS)
	k.titik_kardus.append_array(PackedVector2Array(SejarahData.TITIK_POJOK))
	k.titik_terlarang = titik_terlarang_standar()
	return k

# Titik-titik sejajar pada satu garis horizontal (slot dinding). Pola sama dengan Level 3.
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

# Titik-titik grid di dalam Rect2 (slot lantai / titik kardus). Pola sama dengan Level 3.
static func slot_grid(area: Rect2, kolom: int, baris: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for j in baris:
		for i in kolom:
			var fx := 0.5 if kolom <= 1 else float(i) / float(kolom - 1)
			var fy := 0.5 if baris <= 1 else float(j) / float(baris - 1)
			out.append(area.position + Vector2(area.size.x * fx, area.size.y * fy))
	return out

static func titik_terlarang_standar() -> PackedVector2Array:
	var t := PackedVector2Array([
		SejarahData.POSISI_AWAL_PEMAIN, SejarahData.POSISI_PINTU,
		SejarahData.POSISI_MESIN, SejarahData.POSISI_KERTAS_KATEGORI])
	t.append_array(PackedVector2Array(SejarahData.ZONA_TULISAN))
	return t

# Jalankan generator; acak ulang (maks MAKS_PERCOBAAN) bila validasi gagal.
static func buat(konf: Konfigurasi) -> Hasil:
	var cek := cek_konfigurasi(konf)
	if not cek.is_empty():
		for pesan in cek:
			push_warning("SejarahGenerator: " + pesan)
		var h := Hasil.new()
		h.galat = cek
		return h
	var dasar := konf.seed_awal
	if dasar == 0:
		dasar = int((randi() ^ Time.get_ticks_usec()) & 0x3FFFFFFF)
		if dasar == 0:
			dasar = 1
	var terakhir: Hasil = null
	for i in SejarahData.MAKS_PERCOBAAN:
		var hasil := _coba(konf, dasar + i)
		hasil.percobaan = i + 1
		hasil.seed_dasar = dasar
		if hasil.valid():
			return hasil
		terakhir = hasil
	push_warning("SejarahGenerator: validasi gagal setelah %d percobaan: %s" % [SejarahData.MAKS_PERCOBAAN, ", ".join(terakhir.galat)])
	return terakhir

# Cek konfigurasi sekali di awal (slot & pool cukup, data valid).
static func cek_konfigurasi(konf: Konfigurasi) -> PackedStringArray:
	var g := PackedStringArray()
	var d := _saring(konf.slot_dinding, konf.titik_terlarang, konf.radius_slot)
	var l := _saring(konf.slot_lantai, konf.titik_terlarang, konf.radius_slot)
	if d.size() < SejarahData.JUMLAH_LUKISAN:
		g.append("slot dinding %d < %d" % [d.size(), SejarahData.JUMLAH_LUKISAN])
	if l.size() < SejarahData.JUMLAH_MINIATUR:
		g.append("slot lantai %d < %d" % [l.size(), SejarahData.JUMLAH_MINIATUR])
	var n_min := 0
	var n_luk := 0
	for e in konf.pool:
		if e.tipe == SejarahKaryaData.Tipe.MINIATUR:
			n_min += 1
		else:
			n_luk += 1
	if n_min < SejarahData.JUMLAH_MINIATUR:
		g.append("miniatur di pool %d < %d" % [n_min, SejarahData.JUMLAH_MINIATUR])
	if n_luk < SejarahData.JUMLAH_LUKISAN:
		g.append("lukisan di pool %d < %d" % [n_luk, SejarahData.JUMLAH_LUKISAN])
	if konf.jumlah_potongan < konf.min_per_kategori * 3 or konf.jumlah_potongan > konf.maks_per_kategori * 3:
		g.append("jumlah potongan %d tidak bisa dibagi ke 3 kategori" % konf.jumlah_potongan)
	return g

# Buang karya yang datanya rusak dari pool (dengan peringatan).
static func bersihkan_pool(pool: Array[SejarahKaryaData]) -> Array[SejarahKaryaData]:
	var out: Array[SejarahKaryaData] = []
	for k in pool:
		var g := validasi_data(k)
		if g.is_empty():
			out.append(k)
		else:
			push_warning("Karya '%s' dibuang dari pool: %s" % [k.id, ", ".join(g)])
	return out

# Kapasitas pool: potongan BENAR+SALAH (fakta tampil, maks) dan TIDAK ADA (minimum). Untuk cek hardcore 20.
static func kapasitas(pool: Array[SejarahKaryaData]) -> Dictionary:
	var fakta_tampil := (SejarahData.JUMLAH_MINIATUR + SejarahData.JUMLAH_LUKISAN) * SejarahData.FAKTA_PER_KARYA
	var tak_terbukti := (SejarahData.JUMLAH_MINIATUR + SejarahData.JUMLAH_LUKISAN) * SejarahData.TAK_TERBUKTI_PER_KARYA
	var sisa := maxi(pool.size() - SejarahData.JUMLAH_MINIATUR - SejarahData.JUMLAH_LUKISAN, 0)
	return {"benar_salah": fakta_tampil, "tidak_ada_min": tak_terbukti + sisa * SejarahData.FAKTA_PER_KARYA}

# ---------------------------------------------------------------- validasi data

# Teks tanpa tag BBCode.
static func teks_polos(bbcode: String) -> String:
	var re := RegEx.new()
	re.compile("\\[[^\\]]*\\]")
	return re.sub(bbcode, "", true)

static func memuat(bbcode: String, kata: String) -> bool:
	return teks_polos(bbcode).to_lower().contains(kata.to_lower())

static func _tahun_di_teks(teks: String) -> Array[int]:
	var re := RegEx.new()
	re.compile("\\b\\d{4}\\b")
	var out: Array[int] = []
	for m: RegExMatch in re.search_all(teks):
		out.append(int(m.get_string()))
	return out

# Validasi satu karya: jumlah kata, tepat 3 tahun, 3 fakta, varian salah, tak terbukti.
static func validasi_data(k: SejarahKaryaData) -> PackedStringArray:
	var g := PackedStringArray()
	var nama := String(k.id)
	if nama == "" or k.judul == "" or k.era == "":
		g.append("id/judul/era kosong")
	var polos := teks_polos(k.teks_label).strip_edges()
	var n_kata := polos.split(" ", false).size()
	if n_kata < SejarahData.MIN_KATA_LABEL or n_kata > SejarahData.MAKS_KATA_LABEL:
		g.append("label %d kata (harus %d-%d)" % [n_kata, SejarahData.MIN_KATA_LABEL, SejarahData.MAKS_KATA_LABEL])
	var tahun_label := _tahun_di_teks(polos)
	if tahun_label.size() != SejarahData.FAKTA_PER_KARYA:
		g.append("label memuat %d tahun (harus %d)" % [tahun_label.size(), SejarahData.FAKTA_PER_KARYA])
	if k.fakta.size() != SejarahData.FAKTA_PER_KARYA:
		g.append("fakta %d (harus %d)" % [k.fakta.size(), SejarahData.FAKTA_PER_KARYA])
	if k.tak_terbukti.size() != SejarahData.TAK_TERBUKTI_PER_KARYA:
		g.append("tak terbukti %d (harus %d)" % [k.tak_terbukti.size(), SejarahData.TAK_TERBUKTI_PER_KARYA])
	var id_fakta := {}
	var tahun_fakta: Array[int] = []
	for f in k.fakta:
		if f == null:
			g.append("fakta kosong")
			continue
		if id_fakta.has(f.id) or String(f.id) == "":
			g.append("id fakta kosong/kembar: %s" % f.id)
		id_fakta[f.id] = true
		tahun_fakta.append(f.tahun)
		if f.kata_kunci == "" or not memuat(polos, f.kata_kunci):
			g.append("fakta %s: kata kunci tidak ada di label" % f.id)
		if not tahun_label.has(f.tahun):
			g.append("fakta %s: tahun %d tidak ada di label" % [f.id, f.tahun])
		if not f.kalimat_benar.to_lower().contains(f.kata_kunci.to_lower()) or not f.kalimat_benar.contains(str(f.tahun)):
			g.append("fakta %s: kalimat_benar harus memuat kata kunci dan tahun" % f.id)
		if f.varian_salah.size() != SejarahData.VARIAN_SALAH_PER_FAKTA:
			g.append("fakta %s: varian salah %d (harus %d)" % [f.id, f.varian_salah.size(), SejarahData.VARIAN_SALAH_PER_FAKTA])
		for v in f.varian_salah:
			if v.strip_edges() == "" or v == f.kalimat_benar:
				g.append("fakta %s: varian salah kosong/sama dengan yang benar" % f.id)
		if f.varian_salah.size() == 2 and f.varian_salah[0] == f.varian_salah[1]:
			g.append("fakta %s: dua varian salah kembar" % f.id)
	tahun_fakta.sort()
	var tahun_sorted := tahun_label.duplicate()
	tahun_sorted.sort()
	if tahun_fakta != tahun_sorted:
		g.append("tahun fakta tidak sama dengan tahun di label")
	for t in k.tak_terbukti:
		if t == null or t.kalimat.strip_edges() == "" or t.kata_kunci == "":
			g.append("tak terbukti kosong")
			continue
		if not t.kalimat.to_lower().contains(t.kata_kunci.to_lower()):
			g.append("tak terbukti: kalimat tidak memuat kata kuncinya '%s'" % t.kata_kunci)
		if memuat(polos, t.kata_kunci):
			g.append("tak terbukti: kata kunci '%s' ternyata ada di label sendiri" % t.kata_kunci)
	return g

# Validasi lintas pool: kata kunci fakta hanya di label sendiri; kata kunci tak terbukti di label mana pun.
static func validasi_pool(pool: Array[SejarahKaryaData]) -> PackedStringArray:
	var g := PackedStringArray()
	var id_karya := {}
	for k in pool:
		if id_karya.has(k.id):
			g.append("id karya kembar: %s" % k.id)
		id_karya[k.id] = true
	for k in pool:
		for f in k.fakta:
			for o in pool:
				if o != k and memuat(o.teks_label, f.kata_kunci):
					g.append("kata kunci '%s' (%s) juga ada di label %s" % [f.kata_kunci, k.id, o.id])
		for t in k.tak_terbukti:
			for o in pool:
				if memuat(o.teks_label, t.kata_kunci):
					g.append("kata kunci tak terbukti '%s' (%s) ada di label %s" % [t.kata_kunci, k.id, o.id])
	return g

# ---------------------------------------------------------------- satu percobaan

static func _coba(konf: Konfigurasi, nilai_seed: int) -> Hasil:
	var rng := RandomNumberGenerator.new()
	rng.seed = nilai_seed
	var h := Hasil.new()
	h.seed_dipakai = nilai_seed

	# 1) pilih karya per jenis (miniatur = lantai, lukisan = dinding)
	var miniatur: Array[SejarahKaryaData] = []
	var lukisan: Array[SejarahKaryaData] = []
	for e in konf.pool:
		if e.tipe == SejarahKaryaData.Tipe.MINIATUR:
			miniatur.append(e)
		else:
			lukisan.append(e)
	_acak(miniatur, rng)
	_acak(lukisan, rng)
	var slot_d := _saring_ke_array(konf.slot_dinding, konf.titik_terlarang, konf.radius_slot)
	var slot_l := _saring_ke_array(konf.slot_lantai, konf.titik_terlarang, konf.radius_slot)
	_acak(slot_d, rng)
	_acak(slot_l, rng)
	for i in SejarahData.JUMLAH_MINIATUR:
		var k := Karya.new()
		k.data = miniatur[i]
		k.posisi = slot_l[i]
		h.karya.append(k)
	for i in SejarahData.JUMLAH_LUKISAN:
		var k := Karya.new()
		k.data = lukisan[i]
		k.posisi = slot_d[i]
		h.karya.append(k)

	# 2) titik kardus (bukan di slot karya, bukan dekat titik terlarang)
	var layak := _titik_kardus_layak(konf, h)
	if layak.is_empty():
		h.galat.append("titik kardus habis")
		return h
	h.posisi_kardus = layak[rng.randi_range(0, layak.size() - 1)]

	# 3) potongan kertas
	var galat_potongan := _buat_potongan(h, konf, rng)
	if galat_potongan != "":
		h.galat.append(galat_potongan)
		return h

	# 4) validasi
	h.galat.append_array(validasi(konf, h))
	return h

# Bentuk potongan: komposisi acak (tiap kategori 4..7), BENAR/SALAH dari fakta tampil (maks sekali per fakta),
# TIDAK ADA dari fakta karya yang tidak tampil atau pernyataan tak terbukti karya yang tampil.
static func _buat_potongan(h: Hasil, konf: Konfigurasi, rng: RandomNumberGenerator) -> String:
	var label_tampil: Array[String] = []
	var id_tampil := {}
	var fakta_tampil: Array[Dictionary] = []
	for k in h.karya:
		label_tampil.append(teks_polos(k.data.teks_label).to_lower())
		id_tampil[k.data.id] = true
		for f in k.data.fakta:
			fakta_tampil.append({"f": f, "karya": k.data.id})
	var tak_ada: Array[Dictionary] = []
	for d in konf.pool:
		if id_tampil.has(d.id):
			for t in d.tak_terbukti:
				if not _ada_di_label(t.kata_kunci, label_tampil):
					tak_ada.append({"teks": t.kalimat, "kw": t.kata_kunci, "karya": d.id, "fakta": &"", "jenis": Jenis.TAK_TERBUKTI, "tahun": 0})
		else:
			for f in d.fakta:
				if not _ada_di_label(f.kata_kunci, label_tampil):
					tak_ada.append({"teks": f.kalimat_benar, "kw": f.kata_kunci, "karya": d.id, "fakta": f.id, "jenis": Jenis.FAKTA_TAK_TAMPIL, "tahun": f.tahun})

	# komposisi: semua tripel (benar, salah, tidak ada) yang sah, pilih satu acak
	var pilihan: Array[Vector3i] = []
	for b in range(konf.min_per_kategori, konf.maks_per_kategori + 1):
		for s in range(konf.min_per_kategori, konf.maks_per_kategori + 1):
			var t := konf.jumlah_potongan - b - s
			if t < konf.min_per_kategori or t > konf.maks_per_kategori:
				continue
			if b + s > fakta_tampil.size() or t > tak_ada.size():
				continue
			pilihan.append(Vector3i(b, s, t))
	if pilihan.is_empty():
		return "komposisi potongan tidak mungkin dibuat (fakta %d, tidak ada %d)" % [fakta_tampil.size(), tak_ada.size()]
	var komp := pilihan[rng.randi_range(0, pilihan.size() - 1)]

	_acak(fakta_tampil, rng)
	for i in komp.x:
		var f: SejarahFaktaData = fakta_tampil[i]["f"]
		h.potongan.append(_potongan(f.kalimat_benar, SejarahData.Kategori.BENAR, Jenis.BENAR, fakta_tampil[i]["karya"], f.id, f.kata_kunci, f.tahun))
	for i in range(komp.x, komp.x + komp.y):
		var f: SejarahFaktaData = fakta_tampil[i]["f"]
		var varian := f.varian_salah[rng.randi_range(0, f.varian_salah.size() - 1)]
		h.potongan.append(_potongan(varian, SejarahData.Kategori.SALAH, Jenis.SALAH, fakta_tampil[i]["karya"], f.id, f.kata_kunci, f.tahun))
	_acak(tak_ada, rng)
	for i in komp.z:
		var e := tak_ada[i]
		h.potongan.append(_potongan(e["teks"], SejarahData.Kategori.TIDAK_ADA, e["jenis"], e["karya"], e["fakta"], e["kw"], e["tahun"]))
	_acak(h.potongan, rng)   # urutan potongan diacak
	return ""

static func _potongan(teks: String, kategori: int, jenis: int, karya: StringName, fakta: StringName, kw: String, tahun: int) -> Potongan:
	var p := Potongan.new()
	p.teks = teks
	p.kategori = kategori
	p.jenis = jenis
	p.karya_id = karya
	p.fakta_id = fakta
	p.kata_kunci = kw
	p.tahun = tahun
	return p

static func _ada_di_label(kata: String, label_lower: Array[String]) -> bool:
	for l in label_lower:
		if l.contains(kata.to_lower()):
			return true
	return false

static func _titik_kardus_layak(konf: Konfigurasi, h: Hasil) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for p in konf.titik_kardus:
		if not konf.area_ruang.has_point(p):
			continue
		var ok := true
		for k in h.karya:
			if p.distance_to(k.posisi) < SejarahData.MIN_JARAK_KARDUS:
				ok = false
		for q in konf.titik_terlarang:
			if p.distance_to(q) < konf.radius_kardus:
				ok = false
		if ok:
			out.append(p)
	return out

# ---------------------------------------------------------------- validasi hasil

# Setara AksaraPuzzle.is_solvable(): kembalikan daftar galat (kosong = lolos).
static func validasi(konf: Konfigurasi, h: Hasil) -> PackedStringArray:
	var g := PackedStringArray()

	# komposisi
	if h.potongan.size() != konf.jumlah_potongan:
		g.append("jumlah potongan %d != %d" % [h.potongan.size(), konf.jumlah_potongan])
	var komp := h.komposisi()
	for i in 3:
		if komp[i] < konf.min_per_kategori or komp[i] > konf.maks_per_kategori:
			g.append("kategori %s berisi %d potongan (harus %d-%d)" % [SejarahData.nama_kategori(i), komp[i], konf.min_per_kategori, konf.maks_per_kategori])

	# karya: jumlah per jenis, slot per jenis, jarak
	var n_min := 0
	var n_luk := 0
	var id_tampil := {}
	var label_tampil: Array[String] = []
	for k in h.karya:
		id_tampil[k.data.id] = k.data
		label_tampil.append(teks_polos(k.data.teks_label).to_lower())
		var daftar := konf.slot_lantai if k.data.tipe == SejarahKaryaData.Tipe.MINIATUR else konf.slot_dinding
		var ada := false
		for s in daftar:
			if s.is_equal_approx(k.posisi):
				ada = true
		if not ada:
			g.append("%s tidak berada di slot jenisnya" % k.data.id)
		if k.data.tipe == SejarahKaryaData.Tipe.MINIATUR:
			n_min += 1
		else:
			n_luk += 1
	if n_min != SejarahData.JUMLAH_MINIATUR or n_luk != SejarahData.JUMLAH_LUKISAN:
		g.append("jumlah karya salah: %d miniatur, %d lukisan" % [n_min, n_luk])
	for i in h.karya.size():
		for j in range(i + 1, h.karya.size()):
			if h.karya[i].posisi.distance_to(h.karya[j].posisi) < SejarahData.MIN_JARAK_KARYA:
				g.append("karya %s dan %s terlalu dekat" % [h.karya[i].data.id, h.karya[j].data.id])

	# kardus
	if not konf.area_ruang.has_point(h.posisi_kardus):
		g.append("kardus di luar ruangan")
	for k in h.karya:
		if h.posisi_kardus.distance_to(k.posisi) < SejarahData.MIN_JARAK_KARDUS:
			g.append("kardus menimpa karya %s" % k.data.id)
	for q in konf.titik_terlarang:
		if h.posisi_kardus.distance_to(q) < konf.radius_kardus:
			g.append("kardus dekat titik awal/mesin/pintu")

	# potongan satu per satu
	var teks_dipakai := {}
	var fakta_dipakai := {}
	for i in h.potongan.size():
		var p := h.potongan[i]
		var nama := "potongan %d" % (i + 1)
		if teks_dipakai.has(p.teks):
			g.append("%s: teks ganda" % nama)
		teks_dipakai[p.teks] = true
		match p.kategori:
			SejarahData.Kategori.BENAR, SejarahData.Kategori.SALAH:
				if p.jenis != (Jenis.BENAR if p.kategori == SejarahData.Kategori.BENAR else Jenis.SALAH):
					g.append("%s: jenis tidak cocok dengan kategori" % nama)
				if not id_tampil.has(p.karya_id):
					g.append("%s: karya sumber %s tidak tampil" % [nama, p.karya_id])
					continue
				var data: SejarahKaryaData = id_tampil[p.karya_id]
				var fakta: SejarahFaktaData = null
				for f in data.fakta:
					if f.id == p.fakta_id:
						fakta = f
				if fakta == null:
					g.append("%s: fakta %s tidak ada" % [nama, p.fakta_id])
					continue
				if not memuat(data.teks_label, fakta.kata_kunci) or not teks_polos(data.teks_label).contains(str(fakta.tahun)):
					g.append("%s: label %s tidak memuat kata kunci dan tahun fakta" % [nama, data.id])
				var jumlah_label := 0
				for l in label_tampil:
					if l.contains(fakta.kata_kunci.to_lower()):
						jumlah_label += 1
				if jumlah_label != 1:
					g.append("%s: kata kunci '%s' ada di %d label (harus 1)" % [nama, fakta.kata_kunci, jumlah_label])
				if fakta_dipakai.has(p.fakta_id):
					g.append("%s: fakta %s dipakai lebih dari sekali" % [nama, p.fakta_id])
				fakta_dipakai[p.fakta_id] = true
				if p.kategori == SejarahData.Kategori.BENAR:
					if p.teks != fakta.kalimat_benar:
						g.append("%s: bukan kalimat_benar fakta" % nama)
				else:
					if not fakta.varian_salah.has(p.teks):
						g.append("%s: bukan varian_salah fakta" % nama)
			SejarahData.Kategori.TIDAK_ADA:
				if p.kata_kunci == "" or _ada_di_label(p.kata_kunci, label_tampil):
					g.append("%s: kata kunci '%s' ditemukan di label yang tampil" % [nama, p.kata_kunci])
				if p.jenis == Jenis.TAK_TERBUKTI:
					if not id_tampil.has(p.karya_id):
						g.append("%s: pernyataan tak terbukti dari karya yang tidak tampil" % nama)
					else:
						var ok := false
						for t in (id_tampil[p.karya_id] as SejarahKaryaData).tak_terbukti:
							if t.kalimat == p.teks:
								ok = true
						if not ok:
							g.append("%s: bukan pernyataan tak terbukti karya sumber" % nama)
				elif p.jenis == Jenis.FAKTA_TAK_TAMPIL:
					if id_tampil.has(p.karya_id):
						g.append("%s: fakta dari karya yang justru tampil" % nama)
				else:
					g.append("%s: jenis tidak cocok dengan TIDAK ADA" % nama)
			_:
				g.append("%s: kategori tidak dikenal" % nama)
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
