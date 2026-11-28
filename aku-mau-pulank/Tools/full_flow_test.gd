extends Node
# Uji end-to-end seluruh game:
# Main Menu (Normal / Hard / Setting), Pause (Esc), Timer Hard 10 menit,
# dan sambungan pintu Level 1 -> Level 2 -> Level 3 -> Level 4 -> Menang.

var _gagal := 0

func _cek(kondisi: bool, pesan: String) -> void:
	if kondisi:
		print("  [ok]   ", pesan)
	else:
		_gagal += 1
		print("  [GAGAL] ", pesan)

func _tunggu(n: int = 4) -> void:
	for _i in n:
		await get_tree().physics_frame
	await get_tree().process_frame

func _tekan_esc() -> void:
	var ev := InputEventAction.new()
	ev.action = "ui_cancel"
	ev.pressed = true
	Input.parse_input_event(ev)
	await _tunggu(2)
	var up := InputEventAction.new()
	up.action = "ui_cancel"
	up.pressed = false
	Input.parse_input_event(up)
	await _tunggu(2)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_jalankan.call_deferred()

func _jalankan() -> void:
	get_tree().current_scene = null   # agar runner tidak ikut dibebaskan saat change_scene
	await _uji_main_menu_dan_setting()
	await _uji_normal_run_dan_pause()
	await _uji_hard_mode_timer()
	print("\n=== SELESAI: %s ===" % ("SEMUA LULUS" if _gagal == 0 else "%d PEMERIKSAAN GAGAL" % _gagal))
	get_tree().quit(0 if _gagal == 0 else 1)

func _uji_main_menu_dan_setting() -> void:
	print("=== 1. Main Menu & Pengaturan ===")
	var menu_pkg: PackedScene = load("res://Scene/main_menu.tscn")
	var menu: Node = menu_pkg.instantiate()
	get_tree().root.add_child(menu)
	get_tree().current_scene = menu
	await _tunggu(4)
	_cek(menu != null and menu.name == "MainMenu", "MainMenu dimuat")
	_cek(menu.btn_normal != null and menu.btn_hard != null and menu.btn_settings != null, "Tombol Normal, Hard, dan Pengaturan tersedia")
	_cek(not GameManager._hud_root.visible, "HUD gameplay tersembunyi di Main Menu")
	_cek(not InventoryUI._hotbar_panel.visible, "Hotbar inventory tersembunyi di Main Menu")

	# Buka pengaturan & ubah ukuran layar + volume
	menu.btn_settings.pressed.emit()
	await _tunggu(2)
	_cek(menu.settings_panel.visible and not menu.menu_card.visible, "Panel Pengaturan terbuka dari Main Menu")
	GameManager.set_resolution(2)
	GameManager.set_volume(0.5)
	_cek(GameManager.resolution_index == 2, "Resolusi berubah ke indeks 2 (1600x900)")
	var bus := AudioServer.get_bus_index("Master")
	_cek(absf(db_to_linear(AudioServer.get_bus_volume_db(bus)) - 0.5) < 0.05, "Volume Master bus terupdate ke 50%")
	GameManager.set_volume(0.0)
	_cek(AudioServer.is_bus_mute(bus), "Volume 0% membisukan Master bus")
	GameManager.set_volume(0.8)
	_cek(not AudioServer.is_bus_mute(bus), "Volume 80% menyalakan kembali Master bus")

	# Esc menutup panel Pengaturan di Main Menu
	await _tekan_esc()
	_cek(not menu.settings_panel.visible and menu.menu_card.visible, "Esc di Pengaturan kembali ke Main Menu")

func _uji_normal_run_dan_pause() -> void:
	print("\n=== 2. Alur Normal: Level 1 -> Level 2 -> Level 3 -> Level 4 -> Menang + Pause Esc ===")
	GameManager.start_game(GameManager.Mode.NORMAL)
	await _tunggu(8)

	# --- LEVEL 1 ---
	var l1 := get_tree().current_scene
	_cek(l1 != null and l1.name == "Game", "Mode Normal memulai di Level 1 (Game)")
	_cek(GameManager._hud_root.visible and not GameManager._timer_panel.visible, "HUD level tampil dan timer tersembunyi di Mode Normal")
	_cek(InventoryUI._hotbar_panel.visible, "Hotbar inventory tampil di Level 1")

	# Uji Pause dengan Esc
	await _tekan_esc()
	_cek(GameManager.is_paused_menu and get_tree().paused, "Menekan Esc membuka Pause Menu dan menjeda game")
	GameManager._open_pause_settings()
	await _tunggu(2)
	_cek(GameManager._settings_panel.visible, "Pengaturan bisa dibuka dari Pause Menu")
	await _tekan_esc()
	_cek(not GameManager._settings_panel.visible and GameManager._pause_panel.visible, "Esc dari Pengaturan Pause kembali ke Pause Menu")
	await _tekan_esc()
	_cek(not GameManager.is_paused_menu and not get_tree().paused, "Esc lagi menutup Pause Menu dan melanjutkan game")

	# Uji prioritas Esc: buka Meja -> Esc menutup Meja, TIDAK membuka Pause
	var meja = get_tree().get_nodes_in_group("meja")[0]
	InventoryUI.open_backpack(meja)
	await _tunggu(2)
	await _tekan_esc()
	_cek(not InventoryUI.panel.visible and not GameManager.is_paused_menu and not get_tree().paused, "Esc menutup panel Meja tanpa membuka Pause Menu")

	# Selesaikan Level 1 (2 batik dari daerah sama) -> pintu terbuka -> masuk hitbox pintu ke Level 2
	var req0: ItemData = meja.required[0]
	var req1: ItemData = meja.required[1]
	Inventory.add(req0)
	Inventory.add(req1)
	_cek(meja.try_place(req0, 0) and meja.try_place(req1, 1) and meja.solved, "Level 1: 2 batik daerah sama membuka pintu")
	await _tunggu(3)
	_cek(l1.get_node_or_null("PemicuKeluar") != null, "Level 1: PemicuKeluar dibuat di pintu")
	var p1: Player = l1.get_node("Y-Sort/Player")
	p1.global_position = l1.posisi_pintu + Vector2(0, 32)
	await _tunggu(2)
	p1.global_position = l1.posisi_pintu
	await _tunggu(10)

	# --- LEVEL 2 ---
	var l2 := get_tree().current_scene
	_cek(l2 != null and l2.name == "Level2", "Hitbox pintu Level 1 memindahkan pemain ke Level 2 (aktif: %s)" % (l2.name if l2 else "null"))
	_cek(not InventoryUI._hotbar_panel.visible, "Hotbar inventory disembunyikan di Level 2")
	var papan := get_tree().get_nodes_in_group("papan")
	var pintu_soal_list := get_tree().get_nodes_in_group("pintu_soal")
	_cek(papan.size() == 4, "Level 2 memiliki 4 papan cerita (%d)" % papan.size())
	_cek(pintu_soal_list.size() == 1, "Level 2 memiliki 1 pintu soal")
	# Uji baca papan + tutup dengan Esc (tidak buka Pause)
	StoryUI.open_board(papan[0].board, l2.active_puzzle.get_font())
	await _tunggu(2)
	await _tekan_esc()
	_cek(not StoryUI.panel.visible and not GameManager.is_paused_menu, "Esc menutup papan cerita Level 2 tanpa membuka Pause")
	# Jawab pintu soal -> hitbox pintu ke Level 3
	var ps = pintu_soal_list[0]
	_cek(ps.try_answer(l2.active_puzzle.answers[0]), "Level 2: jawaban aksara benar membuka pintu")
	await _tunggu(3)
	_cek(l2.get_node_or_null("PemicuKeluar") != null, "Level 2: PemicuKeluar dibuat di pintu")
	var p2: Player = l2.get_node("Y-Sort/Player")
	p2.global_position = l2.posisi_pintu + Vector2(0, 32)
	await _tunggu(2)
	p2.global_position = l2.posisi_pintu
	await _tunggu(10)

	# --- LEVEL 3 ---
	var l3 := get_tree().current_scene
	_cek(l3 != null and l3.name == "Level3", "Hitbox pintu Level 2 memindahkan pemain ke Level 3 (aktif: %s)" % (l3.name if l3 else "null"))
	_cek(l3.panel_kode.coba_kode(l3.hasil.kode_teks()), "Level 3: kode benar membuka pintu")
	await _tunggu(3)
	var p3: Player = l3.get_node("Y-Sort/Player")
	p3.global_position = l3.posisi_pintu + Vector2(0, -30)
	await _tunggu(2)
	p3.global_position = l3.posisi_pintu
	await _tunggu(10)

	# --- LEVEL 4 ---
	var l4 := get_tree().current_scene
	_cek(l4 != null and l4.name == "Level4", "Hitbox pintu Level 3 memindahkan pemain ke Level 4 (aktif: %s)" % (l4.name if l4 else "null"))
	l4.logika.ambil_dari_kardus()
	for i in l4.logika.potongan.size():
		l4.logika.masukkan(i, l4.logika.potongan[i].kategori)
	_cek(l4.mesin.selesai_memasukkan(), "Level 4: klasifikasi benar membuka pintu")
	await _tunggu(3)
	var p4: Player = l4.get_node("Y-Sort/Player")
	p4.global_position = l4.posisi_pintu + Vector2(0, -30)
	await _tunggu(2)
	p4.global_position = l4.posisi_pintu
	await _tunggu(8)

	# --- VICTORY ---
	_cek(GameManager.is_victory and GameManager._end_panel.visible and get_tree().paused, "Keluar pintu Level 4 memicu layar Menang!")

func _uji_hard_mode_timer() -> void:
	print("\n=== 3. Mode Hard: Timer 10 Menit & Game Over ===")
	GameManager.start_game(GameManager.Mode.HARD)
	await _tunggu(8)
	_cek(GameManager.mode == GameManager.Mode.HARD and GameManager.is_run_active, "Mode Hard aktif")
	_cek(GameManager._timer_panel.visible, "HUD timer tampil di Mode Hard")
	_cek(GameManager.time_remaining > 590.0 and GameManager.time_remaining <= 600.0, "Timer dimulai dari 10:00 (%.1fs)" % GameManager.time_remaining)

	# Timer berhenti saat pause
	GameManager.open_pause()
	var t_paused := GameManager.time_remaining
	await _tunggu(6)
	_cek(is_equal_approx(GameManager.time_remaining, t_paused), "Timer berhenti saat permainan dijeda")
	GameManager.close_pause()

	# Simulasi waktu hampir habis -> lewat 0 -> kalah
	GameManager.time_remaining = 0.05
	await _tunggu(8)
	_cek(GameManager.is_game_over and not GameManager.is_victory, "Waktu habis memicu Game Over di Mode Hard")
	_cek(GameManager._end_panel.visible and GameManager._end_title.text == "Waktu Habis!", "Layar 'Waktu Habis!' ditampilkan")
	_cek(get_tree().paused, "Game terjeda saat Game Over")
	GameManager.return_to_main_menu()
	await _tunggu(6)
	_cek(get_tree().current_scene != null and get_tree().current_scene.name == "MainMenu", "Tombol kembali ke Main Menu berfungsi")
