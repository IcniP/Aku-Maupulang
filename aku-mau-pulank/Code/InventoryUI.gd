extends CanvasLayer
# Autoload "InventoryUI": HUD slot (tombol 1-3 = pilih), ransel (tombol I), mode meja (drag & drop).

signal closed

class Slot extends Button:
	var index := 0
	func _get_drag_data(_at: Vector2) -> Variant:
		var item := Inventory.items[index]
		if item == null:
			return null
		var preview := TextureRect.new()
		preview.texture = item.icon
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.custom_minimum_size = Vector2(52, 52)
		set_drag_preview(preview)
		return item

class DropZone extends Button:
	var table
	var slot_index := 0
	func _can_drop_data(_at: Vector2, data: Variant) -> bool:
		return table != null and table.can_place_at(slot_index) and data is ItemData
	func _drop_data(_at: Vector2, data: Variant) -> void:
		table.try_place(data, slot_index)

var hud_slots: Array[Button] = []
var bag_slots: Array[Slot] = []
var panel: PanelContainer
var table_box: VBoxContainer
var hint_label: Label
var table_status_label: Label
var drop_row: HBoxContainer
var drop_zones: Array[DropZone] = []
var detail_image: TextureRect
var detail_name: Label
var detail_region: Label
var detail_desc: Label
var toast_label: Label
var table   # meja yang sedang dibuka, null = ransel biasa

var _hotbar_panel: PanelContainer
var _backdrop: ColorRect
var _title_label: Label
var _toast_panel: PanelContainer
var _toast_tween: Tween

func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS  # tetap jalan saat game di-pause

	# --- Hotbar bawah (khusus gameplay Level 1) ---
	_hotbar_panel = PanelContainer.new()
	UITheme.style_hud_pill(_hotbar_panel)
	_hotbar_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_hotbar_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_hotbar_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_hotbar_panel.offset_bottom = -14
	add_child(_hotbar_panel)

	var hotbar_col := VBoxContainer.new()
	hotbar_col.add_theme_constant_override("separation", 4)
	_hotbar_panel.add_child(hotbar_col)

	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 8)
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	hotbar_col.add_child(bar)
	for i in Inventory.MAX_ITEMS:
		var b := Button.new()
		_style_slot(b, i, 62)
		bar.add_child(b)
		hud_slots.append(b)

	var hotbar_hint := UITheme.make_body("[1-3] Pilih Slot   •   [I] Buka Ransel", 11, true, true)
	hotbar_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hotbar_col.add_child(hotbar_hint)

	# --- Latar gelap modal ---
	_backdrop = UITheme.make_backdrop()
	add_child(_backdrop)

	# --- Panel Ransel & Submit Meja ---
	panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.visible = false
	UITheme.style_parchment_panel(panel, 24, 20)
	add_child(panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	root.custom_minimum_size.x = 580
	panel.add_child(root)

	var header := HBoxContainer.new()
	root.add_child(header)
	_title_label = UITheme.make_title("Ransel", 22, false)
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title_label)
	var shortcut_lbl := UITheme.make_body("I / Esc untuk menutup", 13, true, false)
	shortcut_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(shortcut_lbl)
	root.add_child(UITheme.make_divider(false))

	# --- Bagian Meja Submit (2 slot batik) ---
	table_box = VBoxContainer.new()
	table_box.add_theme_constant_override("separation", 10)
	root.add_child(table_box)

	var table_card := PanelContainer.new()
	UITheme.style_inner_box(table_card, 14, false)
	table_box.add_child(table_card)

	var table_inner := VBoxContainer.new()
	table_inner.add_theme_constant_override("separation", 10)
	table_card.add_child(table_inner)

	hint_label = UITheme.make_body("", 15, false, false)
	hint_label.custom_minimum_size.x = 520
	table_inner.add_child(hint_label)

	table_status_label = UITheme.make_body("", 13, true, false)
	table_inner.add_child(table_status_label)

	drop_row = HBoxContainer.new()
	drop_row.alignment = BoxContainer.ALIGNMENT_CENTER
	drop_row.add_theme_constant_override("separation", 16)
	table_inner.add_child(drop_row)
	_ensure_drop_zones(2)

	# --- Isi Ransel: Slot kiri + Detail kanan ---
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	root.add_child(body)

	var slot_col := VBoxContainer.new()
	slot_col.add_theme_constant_override("separation", 8)
	body.add_child(slot_col)
	var bag_cap := UITheme.make_body("Slot Ransel", 13, true, false)
	bag_cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot_col.add_child(bag_cap)
	for i in Inventory.MAX_ITEMS:
		var s := Slot.new()
		s.index = i
		_style_slot(s, i, 82)
		slot_col.add_child(s)
		bag_slots.append(s)

	var detail_card := PanelContainer.new()
	detail_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.style_inner_box(detail_card, 14, false)
	body.add_child(detail_card)

	var detail := VBoxContainer.new()
	detail.add_theme_constant_override("separation", 8)
	detail_card.add_child(detail)

	var img_frame := PanelContainer.new()
	img_frame.add_theme_stylebox_override("panel", UITheme.make_box(Color(0.99, 0.97, 0.93, 1.0), UITheme.BORDER_SOFT, 1, 8, 8, 8))
	detail.add_child(img_frame)
	detail_image = TextureRect.new()
	detail_image.custom_minimum_size = Vector2(260, 190)
	detail_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	detail_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img_frame.add_child(detail_image)

	detail_name = UITheme.make_title("Pilih item", 20, false)
	detail.add_child(detail_name)
	detail_region = UITheme.make_body("", 13, true, false)
	detail_region.add_theme_color_override("font_color", UITheme.ACCENT_PRIMARY)
	detail.add_child(detail_region)
	detail_desc = UITheme.make_body("", 14, false, false)
	detail_desc.custom_minimum_size.x = 320
	detail.add_child(detail_desc)

	var close_btn := Button.new()
	close_btn.text = "Tutup"
	UITheme.style_button(close_btn, "secondary")
	close_btn.pressed.connect(close)
	root.add_child(close_btn)

	# --- Toast banner di atas tengah ---
	_toast_panel = PanelContainer.new()
	UITheme.style_hud_pill(_toast_panel)
	_toast_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_toast_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast_panel.offset_top = 18
	_toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_panel.modulate.a = 0.0
	add_child(_toast_panel)

	toast_label = UITheme.make_body("", 15, false, true)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_toast_panel.add_child(toast_label)

	Inventory.changed.connect(_refresh)
	_refresh()

func set_hotbar_visible(show_bar: bool) -> void:
	if _hotbar_panel != null:
		_hotbar_panel.visible = show_bar

func _ensure_drop_zones(count: int) -> void:
	while drop_zones.size() < count:
		var idx := drop_zones.size()
		var dz := DropZone.new()
		dz.slot_index = idx
		dz.custom_minimum_size = Vector2(156, 100)
		dz.expand_icon = true
		dz.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UITheme.style_button(dz, "dropzone")
		dz.pressed.connect(func(): if table: table.take_back(idx))
		drop_row.add_child(dz)
		drop_zones.append(dz)
	for i in drop_zones.size():
		drop_zones[i].visible = i < count

func _style_slot(b: Button, i: int, size: int) -> void:
	b.custom_minimum_size = Vector2(size, size)
	b.toggle_mode = true
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.text = str(i + 1)
	UITheme.style_button(b, "slot")
	b.pressed.connect(Inventory.select.bind(i))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and panel.visible:
		close()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_1: Inventory.select(0)   # 1-3 hanya memilih item
			KEY_2: Inventory.select(1)
			KEY_3: Inventory.select(2)
			KEY_I:
				if panel.visible:
					close()
					get_viewport().set_input_as_handled()
				elif _hotbar_panel.visible and not get_tree().paused:
					open_backpack()
					get_viewport().set_input_as_handled()

func open_backpack(t = null) -> void:
	table = t
	table_box.visible = t != null
	_title_label.text = "Meja Penyerahan Batik" if t != null else "Ransel"
	if t:
		hint_label.text = "Petunjuk:\n" + t.hint_text()
		_ensure_drop_zones(t.slot_count())
	_backdrop.visible = true
	panel.visible = true
	get_tree().paused = true
	_refresh()

func close() -> void:
	if not panel.visible:
		return
	_backdrop.visible = false
	panel.visible = false
	table = null
	get_tree().paused = false
	closed.emit()

func show_message(text: String) -> void:
	toast_label.text = text
	_toast_panel.modulate.a = 1.0
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.8)
	_toast_tween.tween_property(_toast_panel, "modulate:a", 0.0, 0.5)

func _refresh() -> void:
	for i in Inventory.MAX_ITEMS:
		var has_item := Inventory.items[i] != null
		var icon: Texture2D = Inventory.items[i].icon if has_item else null
		for b in [hud_slots[i], bag_slots[i]]:
			b.icon = icon
			b.text = "" if has_item else str(i + 1)
			b.set_pressed_no_signal(i == Inventory.selected)
	var item := Inventory.selected_item()
	detail_image.texture = item.large_image if item else null
	detail_name.text = item.display_name if item else "Belum ada item dipilih"
	detail_region.visible = item != null and not item.region_name.is_empty()
	detail_region.text = ("Asal daerah: %s" % item.region_name) if detail_region.visible else ""
	detail_desc.text = item.description if item else "Ambil batik dari lemari lalu seret ke slot meja untuk menyerahkan."
	if table:
		var total: int = table.slot_count()
		_ensure_drop_zones(total)
		for i in total:
			var dz := drop_zones[i]
			dz.table = table
			var placed_item: ItemData = table.placed_at(i)
			dz.icon = placed_item.icon if placed_item else null
			dz.text = "" if placed_item else "Batik %d\nSeret ke sini" % (i + 1)
			dz.disabled = table.solved
			dz.tooltip_text = ("%s (klik untuk ambil kembali)" % placed_item.display_name) if (placed_item and not table.solved) else ""
		if table.solved:
			table_status_label.text = "Selesai! Kedua batik dari daerah yang tepat telah dimasukkan."
			table_status_label.add_theme_color_override("font_color", UITheme.ACCENT_SUCCESS)
		else:
			table_status_label.text = "Submission: %d / %d  (seret batik ke slot, klik slot terisi untuk ambil kembali)" % [table.placed_count(), total]
			table_status_label.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
