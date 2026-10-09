extends Interactable

@export var item: ItemData

@onready var sprite: AnimatedSprite2D = get_parent().get_node("AnimatedSprite2D")

func _ready() -> void:
	add_to_group("lemari")
	_update_state()

func set_item(new_item: ItemData) -> void:
	item = new_item
	_update_state()

func interact() -> void:
	if item:
		if not Inventory.add(item):
			InventoryUI.show_message("Inventory penuh (maks %d)" % Inventory.MAX_ITEMS)
			return
		InventoryUI.show_message("Mengambil %s" % item.display_name)
		set_item(null)
	else:
		var held := Inventory.selected_item()
		if held == null:
			InventoryUI.show_message("Pilih item dulu (tombol 1-3)")
			return
		Inventory.remove(held)
		set_item(held)
		InventoryUI.show_message("Menaruh %s" % held.display_name)

func _update_state() -> void:
	sprite.play("Isi" if item else "Kosong")
	interact_name = "Ambil isi lemari" if item else "Taruh item"
