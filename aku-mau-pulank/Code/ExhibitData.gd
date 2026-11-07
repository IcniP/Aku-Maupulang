class_name ExhibitData
extends Resource
# Data satu karya pameran (patung/lukisan). Hanya teks; tidak ada logika.
# Tipe menentukan jenis slot: PATUNG = lantai, LUKISAN = dinding.

enum Tipe { PATUNG, LUKISAN }

@export var id: StringName
@export var tipe: Tipe = Tipe.PATUNG
@export var judul: String
@export var daerah: String
@export_multiline var deskripsi: String   # 40-60 kata, bahasa Indonesia
@export var texture: Texture2D            # opsional; kosong = placeholder
