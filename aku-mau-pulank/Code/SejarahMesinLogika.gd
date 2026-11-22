class_name SejarahMesinLogika
extends RefCounted
# Logika murni mesin Level 4 (tanpa node): tumpukan di tangan pemain, potongan yang sudah
# dimasukkan, pemeriksaan jawaban, dan pengeluaran ulang bila ada yang keliru.
# Tumpukan TIDAK memakai Inventory (3 slot).

var potongan: Array[SejarahGenerator.Potongan] = []
var tumpukan: Array[int] = []       # indeks potongan yang sedang dipegang pemain
var jawaban: Dictionary = {}        # indeks potongan -> kategori yang dipilih pemain
var kardus_diambil := false

var _rng := RandomNumberGenerator.new()

func _init(daftar: Array[SejarahGenerator.Potongan], nilai_seed: int = 0) -> void:
	potongan = daftar
	if nilai_seed != 0:
		_rng.seed = nilai_seed
	else:
		_rng.randomize()

# Interaksi pertama dengan kardus: semua potongan masuk ke tumpukan pemain.
func ambil_dari_kardus() -> bool:
	if kardus_diambil:
		return false
	kardus_diambil = true
	tumpukan.clear()
	for i in potongan.size():
		tumpukan.append(i)
	return true

func jumlah_total() -> int:
	return potongan.size()

func jumlah_dimasukkan() -> int:
	return jawaban.size()

func jumlah_tumpukan() -> int:
	return tumpukan.size()

func semua_masuk() -> bool:
	return kardus_diambil and jawaban.size() == potongan.size()

# Masukkan satu potongan ke mesin. Tidak bisa ditarik kembali sebelum semua masuk.
func masukkan(indeks: int, kategori: int) -> bool:
	if not tumpukan.has(indeks):
		return false
	if kategori < 0 or kategori > 2:
		return false
	tumpukan.erase(indeks)
	jawaban[indeks] = kategori
	return true

# Cek semua jawaban. {lolos: bool, salah: int}; salah = -1 bila belum semua masuk.
func periksa() -> Dictionary:
	if not semua_masuk():
		return {"lolos": false, "salah": -1}
	var salah := 0
	for i in potongan.size():
		if jawaban[i] != potongan[i].kategori:
			salah += 1
	return {"lolos": salah == 0, "salah": salah}

# Ada yang keliru: semua potongan kembali ke tumpukan (urutan diacak), mesin dikosongkan.
func keluarkan_semua() -> void:
	jawaban.clear()
	tumpukan.clear()
	for i in potongan.size():
		tumpukan.append(i)
	for i in range(tumpukan.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp := tumpukan[i]
		tumpukan[i] = tumpukan[j]
		tumpukan[j] = tmp
