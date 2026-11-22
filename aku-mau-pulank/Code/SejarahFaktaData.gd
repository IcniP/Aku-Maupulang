class_name SejarahFaktaData
extends Resource
# Satu fakta sejarah pada label sebuah karya (Level 4). Hanya data.

@export var id: StringName
@export var tahun: int                         # tahun yang tercetak di label (angka)
@export var kata_kunci: String                 # istilah unik yang HARUS ada di teks label
@export_multiline var kalimat_benar: String    # cocok dengan label (tahun sama)
@export var varian_salah: PackedStringArray = PackedStringArray()  # 2 kalimat yang bertentangan dengan label
