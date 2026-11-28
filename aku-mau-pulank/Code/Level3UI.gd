class_name Level3UI
extends CanvasLayer
# UI Level 3 lewat kode (pola StoryUI): panel LABEL karya, panel input KODE, panel CATATAN (tombol N),
# panel KERTAS CLUE (dibaca berulang, tidak diambil), penghitung progres, dan banner misi.
# Digabung dalam satu file karena semuanya berbagi aturan yang sama: hanya satu panel terbuka,
# get_tree().paused saat terbuka, ditutup dengan ui_cancel, dan satu signal `closed`.
# Logika clue (hitungan, kotak kertas, isi kertas clue) ada di Level3Clue.gd.

signal closed

const LEBAR_PANEL := 540
const TINGGI_GULIR := 380
const AKSI_CATATAN := "catatan"

var total_karya := 0   # diisi manager, untuk penghitung "label dibaca"

var _backdrop: ColorRect
var _aktif: Control
var _panel_label: PanelContainer
var _teks_label: RichTextLabel
var _tombol_kertas: Button
var _panel_kode: PanelContainer
var _isi_kode: Label
var _edit_kode: LineEdit
var _status_kode: Label
var _panel_catatan: PanelContainer
var _teks_catatan: RichTextLabel
var _tombol_clue: Button          # di panel label: baca kertas clue yang terselip di lukisan itu
var _panel_clue: PanelContainer
var _judul_clue: Label
var _teks_clue: RichTextLabel
var _tombol_kembali: Button
var _hud: Label
var _hud_pill: PanelContainer
var _banner: PanelContainer
var _karya_aktif: KaryaPameran
var _kode_aktif: PanelKode
var _catatan: Array[Level3Generator.Kertas] = []
var _dibaca := {}          # id karya -> {judul, jumlah (hasil hitung ulang warna di label itu)}
var _clue_dibaca := {}     # indeks kertas clue yang pernah dibaca (hanya untuk penghitung)

func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS   # tetap jalan saat game di-pause
	add_to_group("level3_ui")
	_daftarkan_aksi()
	_backdrop = UITheme.make_backdrop()
	add_child(_backdrop)
	_bangun_label()
	_bangun_kode()
	_bangun_catatan()
	_bangun_clue()
	_bangun_hud()
	_bangun_banner()
	_segarkan_hud()

# Tombol baru didaftarkan lewat kode supaya project.godot tidak perlu diubah.
func _daftarkan_aksi() -> void:
	if not InputMap.has_action(AKSI_CATATAN):
		InputMap.add_action(AKSI_CATATAN)
		var ev := InputEventKey.new()
		ev.physical_keycode = KEY_N
		InputMap.action_add_event(AKSI_CATATAN, ev)

# ---------------------------------------------------------------- pembangun panel

# Kotak teks Level 3 tetap PUTIH (bukan krem): kuning dan cyan di atas krem terlalu pudar,
# padahal warna kata adalah inti puzzle. Bingkai dan panel luar tetap mengikuti tema UITheme.
func _gaya_kartu_putih(kartu: PanelContainer) -> void:
	kartu.add_theme_stylebox_override("panel", UITheme.make_box(Color.WHITE, UITheme.BORDER_SOFT, 1, 10, 14, 14))

func _panel_putih() -> PanelContainer:
	var p := PanelContainer.new()
	p.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	p.visible = false
	UITheme.style_parchment_panel(p, 24, 20)
	add_child(p)
	return p

func _teks_hitam() -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.custom_minimum_size = Vector2(LEBAR_PANEL, 0)
	r.add_theme_color_override("default_color", UITheme.TEXT_DARK)
	return r

# Teks gelap yang bisa digulir (roda mouse) untuk panel yang isinya panjang.
func _teks_hitam_gulir() -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = false
	r.scroll_active = true
	r.custom_minimum_size = Vector2(LEBAR_PANEL, TINGGI_GULIR)
	r.add_theme_color_override("default_color", UITheme.TEXT_DARK)
	return r

func _label_hitam(teks: String, ukuran: int = 15) -> Label:
	var l := Label.new()
	l.text = teks
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = LEBAR_PANEL
	l.add_theme_font_size_override("font_size", ukuran)
	l.add_theme_color_override("font_color", UITheme.TEXT_DARK)
	return l

func _bangun_label() -> void:
	_panel_label = _panel_putih()
	var kolom := VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 12)
	_panel_label.add_child(kolom)

	var kartu := PanelContainer.new()
	_gaya_kartu_putih(kartu)
	kolom.add_child(kartu)
	_teks_label = _teks_hitam()
	kartu.add_child(_teks_label)

	_tombol_kertas = Button.new()
	_tombol_kertas.text = "Ambil kertas terselip"
	UITheme.style_button(_tombol_kertas, "primary")
	_tombol_kertas.pressed.connect(_ambil_terselip)
	kolom.add_child(_tombol_kertas)

	_tombol_clue = Button.new()
	_tombol_clue.text = "Baca kertas terselip"
	UITheme.style_button(_tombol_clue, "primary")
	_tombol_clue.pressed.connect(_baca_clue_terselip)
	kolom.add_child(_tombol_clue)

	var tutup_btn := Button.new()
	tutup_btn.text = "Tutup"
	UITheme.style_button(tutup_btn, "secondary")
	tutup_btn.pressed.connect(tutup)
	kolom.add_child(tutup_btn)

func _bangun_kode() -> void:
	_panel_kode = _panel_putih()
	var kolom := VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 12)
	_panel_kode.add_child(kolom)

	kolom.add_child(UITheme.make_title("Panel Kode Pintu", 22, false))
	kolom.add_child(UITheme.make_divider(false))
	_isi_kode = _label_hitam("")
	kolom.add_child(_isi_kode)
	_edit_kode = LineEdit.new()
	_edit_kode.max_length = Level3Data.CODE_LENGTH
	_edit_kode.placeholder_text = "%d angka" % Level3Data.CODE_LENGTH
	_edit_kode.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_edit_kode.custom_minimum_size.y = 52
	_edit_kode.add_theme_font_size_override("font_size", 28)
	_edit_kode.text_changed.connect(_saring_angka)
	_edit_kode.text_submitted.connect(func(_t: String) -> void: _kirim_kode())
	kolom.add_child(_edit_kode)
	_status_kode = _label_hitam("")
	_status_kode.add_theme_color_override("font_color", UITheme.ACCENT_DANGER)
	kolom.add_child(_status_kode)

	var baris := HBoxContainer.new()
	baris.add_theme_constant_override("separation", 10)
	kolom.add_child(baris)
	var buka_btn := Button.new()
	buka_btn.text = "Buka"
	buka_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.style_button(buka_btn, "primary")
	buka_btn.pressed.connect(_kirim_kode)
	baris.add_child(buka_btn)
	var tutup_btn := Button.new()
	tutup_btn.text = "Tutup"
	UITheme.style_button(tutup_btn, "secondary")
	tutup_btn.pressed.connect(tutup)
	baris.add_child(tutup_btn)

func _bangun_catatan() -> void:
	_panel_catatan = _panel_putih()
	var kolom := VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 12)
	_panel_catatan.add_child(kolom)

	var header := HBoxContainer.new()
	kolom.add_child(header)
	var judul := UITheme.make_title("Catatan Petunjuk", 22, false)
	judul.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(judul)
	var hint := UITheme.make_body("N / Esc untuk menutup", 13, true, false)
	hint.autowrap_mode = TextServer.AUTOWRAP_OFF   # tanpa ini label menyempit jadi satu huruf per baris di dalam HBox
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(hint)
	kolom.add_child(UITheme.make_divider(false))

	var kartu := PanelContainer.new()
	_gaya_kartu_putih(kartu)
	kolom.add_child(kartu)
	_teks_catatan = _teks_hitam_gulir()
	kartu.add_child(_teks_catatan)

	var tutup_btn := Button.new()
	tutup_btn.text = "Tutup"
	UITheme.style_button(tutup_btn, "secondary")
	tutup_btn.pressed.connect(tutup)
	kolom.add_child(tutup_btn)
	_segarkan_catatan()

# Panel kertas clue: judul kertas + isi. Dibuka dari kertas di ruangan atau dari label lukisan.
func _bangun_clue() -> void:
	_panel_clue = _panel_putih()
	var kolom := VBoxContainer.new()
	kolom.add_theme_constant_override("separation", 12)
	_panel_clue.add_child(kolom)

	var header := HBoxContainer.new()
	kolom.add_child(header)
	_judul_clue = UITheme.make_title("Kertas Clue", 22, false)
	_judul_clue.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_judul_clue)
	var hint := UITheme.make_body("Esc untuk menutup", 13, true, false)
	hint.autowrap_mode = TextServer.AUTOWRAP_OFF   # tanpa ini label menyempit jadi satu huruf per baris di dalam HBox
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(hint)
	kolom.add_child(UITheme.make_divider(false))

	var kartu := PanelContainer.new()
	_gaya_kartu_putih(kartu)
	kolom.add_child(kartu)
	_teks_clue = _teks_hitam()
	kartu.add_child(_teks_clue)

	var baris := HBoxContainer.new()
	baris.add_theme_constant_override("separation", 10)
	kolom.add_child(baris)
	_tombol_kembali = Button.new()
	_tombol_kembali.text = "Kembali ke label"
	UITheme.style_button(_tombol_kembali, "primary")
	_tombol_kembali.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tombol_kembali.pressed.connect(_kembali_ke_label)
	baris.add_child(_tombol_kembali)
	var tutup_btn := Button.new()
	tutup_btn.text = "Tutup"
	UITheme.style_button(tutup_btn, "secondary")
	tutup_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tutup_btn.pressed.connect(tutup)
	baris.add_child(tutup_btn)

# Penghitung progres di kanan atas, tepat di bawah timer hard mode milik GameManager (y=16), selalu terlihat.
# Sengaja bukan di kiri atas agar tidak bertabrakan dengan pil level GameManager.
func _bangun_hud() -> void:
	_hud_pill = PanelContainer.new()
	UITheme.style_hud_pill(_hud_pill)
	_hud_pill.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_hud_pill.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_hud_pill.offset_right = -16
	_hud_pill.offset_top = 64
	_hud_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hud_pill)
	_hud = UITheme.make_body("", 14, false, true)
	_hud.autowrap_mode = TextServer.AUTOWRAP_OFF
	_hud_pill.add_child(_hud)

# Banner misi saat level mulai; memudar sendiri dan hilang saat panel dibuka.
func _bangun_banner() -> void:
	_banner = PanelContainer.new()
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UITheme.style_dark_panel(_banner, 18, 14)
	_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_banner.grow_vertical = Control.GROW_DIRECTION_END
	_banner.offset_top = 112
	_banner.offset_bottom = 112
	var isi := UITheme.make_body(Level3Data.TEKS_BANNER, 15, false, true)
	isi.custom_minimum_size.x = 540
	isi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.add_child(isi)
	add_child(_banner)
	var tween := create_tween()
	tween.tween_interval(Level3Data.DURASI_BANNER)
	tween.tween_property(_banner, "modulate:a", 0.0, 1.0)
	tween.tween_callback(_banner.hide)

# ---------------------------------------------------------------- API untuk objek

func buka_label(karya: KaryaPameran) -> void:
	_karya_aktif = karya
	var d := karya.data
	# hitungan warna di label ini dihitung ulang dari teks akhir, lalu dicatat otomatis di Catatan
	_dibaca[d.id] = {"judul": d.judul, "jumlah": Level3Clue.ringkas_label(karya.bbcode)}
	karya.tandai_dibaca()
	_segarkan_hud()
	_teks_label.text = "[font_size=22][b]%s[/b][/font_size]\nAsal daerah: %s\n\n%s" % [
		_esc(d.judul), _esc(d.daerah), karya.bbcode]
	_tombol_kertas.visible = karya.kertas != null and not karya.kertas_diambil
	_tombol_clue.visible = karya.clue != null
	_tampilkan(_panel_label)

func buka_kode(panel: PanelKode) -> void:
	_kode_aktif = panel
	_isi_kode.text = "Masukkan %d angka (0-9) lalu tekan Buka.  Kertas ditemukan: %d/%d" % [
		Level3Data.CODE_LENGTH, _catatan.size(), Level3Data.CODE_LENGTH]
	_status_kode.text = ""
	_edit_kode.clear()
	_tampilkan(_panel_kode)
	_edit_kode.grab_focus()

func buka_catatan() -> void:
	_segarkan_catatan()
	_tampilkan(_panel_catatan)

# Buka kertas clue ke-indeks. dari_label = true bila dibuka dari label lukisan (ada tombol kembali ke label).
func buka_clue(indeks: int, dari_label: bool = false) -> void:
	_clue_dibaca[indeks] = true
	_segarkan_hud()
	_judul_clue.text = Level3Clue.judul_clue(indeks)
	_teks_clue.text = Level3Clue.isi_clue(indeks)
	_tombol_kembali.visible = dari_label
	_tampilkan(_panel_clue)

func jumlah_clue_dibaca() -> int:
	return _clue_dibaca.size()

func tambah_catatan(kertas: Level3Generator.Kertas) -> void:
	if _catatan.has(kertas):
		return
	_catatan.append(kertas)
	_segarkan_catatan()
	_segarkan_hud()
	InventoryUI.show_message("Kertas kode diambil (tekan N untuk membaca)")

func jumlah_catatan() -> int:
	return _catatan.size()

func jumlah_dibaca() -> int:
	return _dibaca.size()

func tutup() -> void:
	if _aktif == null:
		return
	_backdrop.visible = false
	_aktif.visible = false
	_aktif = null
	_karya_aktif = null
	_kode_aktif = null
	get_tree().paused = false
	closed.emit()

func sedang_terbuka() -> bool:
	return _aktif != null

# ---------------------------------------------------------------- internal

func _tampilkan(panel: Control) -> void:
	_banner.hide()   # banner misi tidak boleh menimpa panel
	if _aktif != null:
		_aktif.visible = false
	_aktif = panel
	_backdrop.visible = true
	panel.visible = true
	get_tree().paused = true

func _ambil_terselip() -> void:
	if _karya_aktif == null:
		return
	_karya_aktif.ambil_kertas()
	_tombol_kertas.visible = false

func _kirim_kode() -> void:
	if _kode_aktif == null:
		return
	var teks := _edit_kode.text
	if teks.length() != Level3Data.CODE_LENGTH:
		_status_kode.text = "Masukkan tepat %d angka." % Level3Data.CODE_LENGTH
		return
	if _kode_aktif.coba_kode(teks):
		tutup()
	else:
		_status_kode.text = "Kode salah."
		InventoryUI.show_message("Kode salah")
		_edit_kode.clear()
		_edit_kode.grab_focus()

func _saring_angka(teks: String) -> void:
	var bersih := ""
	for c in teks:
		if "0123456789".contains(c):
			bersih += c
	if bersih != teks:
		var kolom := _edit_kode.caret_column
		_edit_kode.text = bersih
		_edit_kode.caret_column = mini(kolom, bersih.length())

func _segarkan_hud() -> void:
	_hud.text = "Label dibaca: %d/%d   Kertas kode: %d/%d   Clue dibaca: %d/%d" % [
		_dibaca.size(), total_karya, _catatan.size(), Level3Data.CODE_LENGTH, _clue_dibaca.size(), Level3Data.JUMLAH_CLUE]

# Catatan: kertas dalam bentuk kotak + hitungan otomatis per label yang sudah dibaca.
# Total TIDAK dijumlahkan otomatis: pemain tetap menjumlahkan sendiri, hanya tidak perlu mengingat.
func _segarkan_catatan() -> void:
	var s := "[b]KERTAS KODE[/b]  (yang sudah kamu ambil)\n"
	if _catatan.is_empty():
		s += "Belum ada kertas kode. Cari di sudut ruangan, di lantai, atau terselip di label karya.\n"
	else:
		for i in _catatan.size():
			s += "Kertas %d:  %s\n      Digit %d = jumlah kata %s di SEMUA label\n" % [
				i + 1, Level3Clue.kotak_kertas(_catatan[i]), _catatan[i].posisi_angka + 1, Level3Clue.nama_tebal(_catatan[i].warna)]
		if _catatan.size() < Level3Data.CODE_LENGTH:
			s += "Kertas yang belum ketemu: %d\n" % (Level3Data.CODE_LENGTH - _catatan.size())
	s += "\n[b]HITUNGAN PER LABEL[/b]  (dicatat otomatis saat label dibaca)\n"
	if _dibaca.is_empty():
		s += "Belum ada label yang dibaca.\n"
	else:
		for id in _dibaca:
			s += "- %s\n" % Level3Clue.baris_label(_dibaca[id]["judul"], _dibaca[id]["jumlah"])
	s += "Label dibaca: %d/%d" % [_dibaca.size(), total_karya]
	if _dibaca.size() < total_karya:
		s += "  (hitungan belum lengkap)"
	s += "\n\n[b]KAMUS WARNA[/b]\n%s" % Level3Clue.kamus_warna()
	_teks_catatan.text = s

# Tombol di panel label: baca kertas clue yang terselip di lukisan ini (kertas tidak diambil, bisa dibaca lagi).
func _baca_clue_terselip() -> void:
	if _karya_aktif == null or _karya_aktif.clue == null:
		return
	buka_clue(_karya_aktif.clue.indeks_teks, true)

func _kembali_ke_label() -> void:
	if _karya_aktif != null:
		_tampilkan(_panel_label)
	else:
		tutup()

func _esc(teks: String) -> String:
	return teks.replace("[", "[lb]")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _aktif != null:
		tutup()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(AKSI_CATATAN):
		if _aktif == _panel_catatan:
			tutup()
		elif _aktif == null and not get_tree().paused:   # jangan buka saat panel lain terbuka
			buka_catatan()
