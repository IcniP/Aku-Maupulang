class_name Level3UI
extends CanvasLayer
# UI Level 3 lewat kode (pola StoryUI): panel LABEL karya, panel input KODE, panel CATATAN (tombol N).
# Digabung dalam satu file karena ketiganya berbagi aturan yang sama: hanya satu panel terbuka,
# get_tree().paused saat terbuka, ditutup dengan ui_cancel, dan satu signal `closed`.

signal closed

const LEBAR_PANEL := 520
const AKSI_CATATAN := "catatan"

var total_karya := 0   # diisi manager, untuk penghitung "karya diperiksa"

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
var _karya_aktif: KaryaPameran
var _kode_aktif: PanelKode
var _catatan: Array[Level3Generator.Kertas] = []
var _dibaca := {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # tetap jalan saat game di-pause
	add_to_group("level3_ui")
	_daftarkan_aksi()
	_bangun_label()
	_bangun_kode()
	_bangun_catatan()

# Tombol baru didaftarkan lewat kode supaya project.godot tidak perlu diubah.
func _daftarkan_aksi() -> void:
	if not InputMap.has_action(AKSI_CATATAN):
		InputMap.add_action(AKSI_CATATAN)
		var ev := InputEventKey.new()
		ev.physical_keycode = KEY_N
		InputMap.action_add_event(AKSI_CATATAN, ev)

# ---------------------------------------------------------------- pembangun panel

func _panel_putih() -> PanelContainer:
	var p := PanelContainer.new()
	p.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	p.grow_horizontal = Control.GROW_DIRECTION_BOTH
	p.grow_vertical = Control.GROW_DIRECTION_BOTH
	p.visible = false
	var gaya := StyleBoxFlat.new()
	gaya.bg_color = Color.WHITE
	gaya.set_border_width_all(2)
	gaya.border_color = Color.BLACK
	gaya.set_content_margin_all(16)
	p.add_theme_stylebox_override("panel", gaya)
	add_child(p)
	return p

func _teks_hitam() -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.custom_minimum_size = Vector2(LEBAR_PANEL, 0)
	r.add_theme_color_override("default_color", Color.BLACK)
	return r

func _label_hitam(teks: String, ukuran: int = 16) -> Label:
	var l := Label.new()
	l.text = teks
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = LEBAR_PANEL
	l.add_theme_font_size_override("font_size", ukuran)
	l.add_theme_color_override("font_color", Color.BLACK)
	return l

func _bangun_label() -> void:
	_panel_label = _panel_putih()
	var kolom := VBoxContainer.new()
	_panel_label.add_child(kolom)
	_teks_label = _teks_hitam()
	kolom.add_child(_teks_label)
	_tombol_kertas = Button.new()
	_tombol_kertas.text = "Ambil kertas terselip"
	_tombol_kertas.focus_mode = Control.FOCUS_NONE
	_tombol_kertas.pressed.connect(_ambil_terselip)
	kolom.add_child(_tombol_kertas)
	var tutup_btn := Button.new()
	tutup_btn.text = "Tutup"
	tutup_btn.focus_mode = Control.FOCUS_NONE
	tutup_btn.pressed.connect(tutup)
	kolom.add_child(tutup_btn)

func _bangun_kode() -> void:
	_panel_kode = _panel_putih()
	var kolom := VBoxContainer.new()
	_panel_kode.add_child(kolom)
	kolom.add_child(_label_hitam("Panel Kode Pintu", 22))
	_isi_kode = _label_hitam("")
	kolom.add_child(_isi_kode)
	_edit_kode = LineEdit.new()
	_edit_kode.max_length = Level3Data.CODE_LENGTH
	_edit_kode.placeholder_text = "%d angka" % Level3Data.CODE_LENGTH
	_edit_kode.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_edit_kode.add_theme_font_size_override("font_size", 28)
	_edit_kode.text_changed.connect(_saring_angka)
	_edit_kode.text_submitted.connect(func(_t: String) -> void: _kirim_kode())
	kolom.add_child(_edit_kode)
	_status_kode = _label_hitam("")
	kolom.add_child(_status_kode)
	var baris := HBoxContainer.new()
	kolom.add_child(baris)
	var buka_btn := Button.new()
	buka_btn.text = "Buka"
	buka_btn.focus_mode = Control.FOCUS_NONE
	buka_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buka_btn.pressed.connect(_kirim_kode)
	baris.add_child(buka_btn)
	var tutup_btn := Button.new()
	tutup_btn.text = "Tutup"
	tutup_btn.focus_mode = Control.FOCUS_NONE
	tutup_btn.pressed.connect(tutup)
	baris.add_child(tutup_btn)

func _bangun_catatan() -> void:
	_panel_catatan = _panel_putih()
	var kolom := VBoxContainer.new()
	_panel_catatan.add_child(kolom)
	kolom.add_child(_label_hitam("Catatan  (N / Esc untuk menutup)", 22))
	_teks_catatan = _teks_hitam()
	kolom.add_child(_teks_catatan)
	var tutup_btn := Button.new()
	tutup_btn.text = "Tutup"
	tutup_btn.focus_mode = Control.FOCUS_NONE
	tutup_btn.pressed.connect(tutup)
	kolom.add_child(tutup_btn)
	_segarkan_catatan()

# ---------------------------------------------------------------- API untuk objek

func buka_label(karya: KaryaPameran) -> void:
	_karya_aktif = karya
	var d := karya.data
	_dibaca[d.id] = true
	karya.tandai_dibaca()
	_teks_label.text = "[font_size=22][b]%s[/b][/font_size]\nAsal daerah: %s\n\n%s" % [
		_esc(d.judul), _esc(d.daerah), karya.bbcode]
	_tombol_kertas.visible = karya.kertas != null and not karya.kertas_diambil
	_tampilkan(_panel_label)

func buka_kode(panel: PanelKode) -> void:
	_kode_aktif = panel
	_isi_kode.text = "Masukkan %d angka (0-9) lalu tekan Buka." % Level3Data.CODE_LENGTH
	_status_kode.text = ""
	_edit_kode.clear()
	_tampilkan(_panel_kode)
	_edit_kode.grab_focus()

func buka_catatan() -> void:
	_segarkan_catatan()
	_tampilkan(_panel_catatan)

func tambah_catatan(kertas: Level3Generator.Kertas) -> void:
	if _catatan.has(kertas):
		return
	_catatan.append(kertas)
	_segarkan_catatan()
	InventoryUI.show_message("Kertas petunjuk diambil (tekan N untuk membaca)")

func jumlah_catatan() -> int:
	return _catatan.size()

func tutup() -> void:
	if _aktif == null:
		return
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
	if _aktif != null:
		_aktif.visible = false
	_aktif = panel
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

func _segarkan_catatan() -> void:
	var s := "Tiap garis bawah (_) = satu angka lain. Angka ke-N = jumlah kata berwarna "
	s += "(warna yang tertulis di kertas) di SEMUA label karya.\n\n"
	if _catatan.is_empty():
		s += "Belum ada kertas petunjuk. Cari di sudut ruangan, di lantai, atau terselip di label karya."
	else:
		for i in _catatan.size():
			s += "Kertas %d:  %s\n" % [i + 1, _catatan[i].ke_bbcode()]
	s += "\n\nKarya diperiksa: %d/%d    Kertas: %d/%d" % [
		_dibaca.size(), total_karya, _catatan.size(), Level3Data.CODE_LENGTH]
	_teks_catatan.text = s

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
