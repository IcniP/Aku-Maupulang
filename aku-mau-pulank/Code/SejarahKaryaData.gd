class_name SejarahKaryaData
extends Resource
# Satu karya pameran sejarah (miniatur/lukisan hologram) beserta fakta-faktanya (Level 4).
# MINIATUR = slot lantai, LUKISAN = slot dinding.

enum Tipe { MINIATUR, LUKISAN }

@export var id: StringName
@export var tipe: Tipe = Tipe.MINIATUR
@export var judul: String
@export var era: String                        # daerah / era
@export_multiline var teks_label: String       # 50-70 kata, BBCode: tahun dicetak tebal [b]
@export var fakta: Array[SejarahFaktaData] = []                # tepat 3 fakta
@export var tak_terbukti: Array[SejarahTakTerbuktiData] = []   # 2 pernyataan tak terbukti
@export var texture: Texture2D                 # opsional; kosong = placeholder
