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
		preview.custom_minimum_size = Vector2(48, 48)
		set_drag_preview(preview)
		return item

class DropZone extends Button:
	var table
	func _can_drop_data(_at: Vector2, data: Variant) -> bool:
		return table != null and table.placed == null and data is ItemData
	func _drop_data(_at: Vector2, data: Variant) -> void:
		table.try_place(data)

var hud_slots: Array[Button] = []
var bag_slots: Array[Slot] = []
var panel: PanelContainer
var table_box: VBoxContainer
var hint_label: Label
var drop_zone: DropZone
var detail_image: TextureRect
var detail_name: Label
var detail_desc: Label
var toast_label: Label
var table   # meja yang sedang dibuka, null = ransel biasa

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # tetap jalan saat game di-pause

	var bar := HBoxContainer.new()
	bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bar.offset_bottom = -12
	add_child(bar)
	for i in Inventory.MAX_ITEMS:
		var b := Button.new()
		_style_slot(b, i, 64)
		bar.add_child(b)
		hud_slots.append(b)

	panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.visible = false
	add_child(panel)
	var root := VBoxContainer.new()
	panel.add_child(root)
	var title := Label.new()
	title.text = "Ransel  (I / Esc untuk menutup)"
	root.add_child(title)

	table_box = VBoxContainer.new()
	root.add_child(table_box)
	hint_label = Label.new()
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.custom_minimum_size.x = 520
	table_box.add_child(hint_label)
	drop_zone = DropZone.new()
	drop_zone.custom_minimum_size = Vector2(96, 96)
	drop_zone.expand_icon = true
	drop_zone.focus_mode = Control.FOCUS_NONE
	drop_zone.pressed.connect(func(): if table: table.take_back())
	table_box.add_child(drop_zone)

	var body := HBoxContainer.new()
	root.add_child(body)
	var slot_col := VBoxContainer.new()
	body.add_child(slot_col)
	for i in Inventory.MAX_ITEMS:
		var s := Slot.new()
		s.index = i
		_style_slot(s, i, 80)
		slot_col.add_child(s)
		bag_slots.append(s)
	var detail := VBoxContainer.new()
	body.add_child(detail)
	detail_image = TextureRect.new()
	detail_image.custom_minimum_size = Vector2(256, 256)
	detail_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	detail_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	detail.add_child(detail_image)
	detail_name = Label.new()
	detail_name.add_theme_font_size_override("font_size", 24)
	detail.add_child(detail_name)
	detail_desc = Label.new()
	detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_desc.custom_minimum_size.x = 256
	detail.add_child(detail_desc)

	var close_btn := Button.new()
	close_btn.text = "Tutup"
	close_btn.pressed.connect(close)
	root.add_child(close_btn)

	toast_label = Label.new()  # terakhir, supaya tampil di atas panel
	toast_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	toast_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	toast_label.offset_top = 24
	toast_label.modulate.a = 0.0
	add_child(toast_label)

	Inventory.changed.connect(_refresh)
	_refresh()

func _style_slot(b: Button, i: int, size: int) -> void:
	b.custom_minimum_size = Vector2(size, size)
	b.toggle_mode = true
	b.expand_icon = true
	b.text = str(i + 1)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(Inventory.select.bind(i))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and panel.visible:
		close()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_1: Inventory.select(0)   # 1-3 hanya memilih item
			KEY_2: Inventory.select(1)
			KEY_3: Inventory.select(2)
			KEY_I:
				if panel.visible: close()
				else: open_backpack()

func open_backpack(t = null) -> void:
	table = t
	table_box.visible = t != null
	if t:
		hint_label.text = "Petunjuk: " + t.hint_text()
	panel.visible = true
	get_tree().paused = true
	_refresh()

func close() -> void:
	if not panel.visible:
		return
	panel.visible = false
	table = null
	get_tree().paused = false
	closed.emit()

func show_message(text: String) -> void:
	toast_label.text = text
	toast_label.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(toast_label, "modulate:a", 0.0, 0.5)

func _refresh() -> void:
	for i in Inventory.MAX_ITEMS:
		var icon: Texture2D = Inventory.items[i].icon if Inventory.items[i] else null
		for b in [hud_slots[i], bag_slots[i]]:
			b.icon = icon
			b.set_pressed_no_signal(i == Inventory.selected)
	var item := Inventory.selected_item()
	detail_image.texture = item.large_image if item else null
	detail_name.text = item.display_name if item else "Pilih item"
	detail_desc.text = item.description if item else ""
	if table:
		drop_zone.table = table
		drop_zone.icon = table.placed.icon if table.placed else null
		drop_zone.text = "" if table.placed else "Seret item ke sini"
