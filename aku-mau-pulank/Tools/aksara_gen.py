#!/usr/bin/env python3
"""Membuat Puzzles/*.tres dari ejaan Latin. Jalankan dari root proyek: python3 Tools/aksara_gen.py

Ejaan per kata: suku kata dipisah '-'. Vokal: a i u e (taling/é) o E (pepet/schwa).
Suku kata tanpa konsonan ("a", "i") = huruf vokal mandiri. Akhiran '_' = konsonan penutup
("ng_", "r_", "h_" pakai tanda khusus, selain itu pakai pangkon/pamaeh).
Belum didukung: gugus konsonan (pasangan). Pilih kosakata tanpa gugus, atau ketik aksara manual.
Menambah aksara baru (Bali, Batak, Bugis...): tambahkan entri di SCRIPTS dan PUZZLES.
"""
import re, unicodedata as ud

def ch(name):
    return ud.lookup(name)  # gagal keras bila nama salah, jadi kodepoin pasti benar

def _std(prefix, vowels, finals, virama, indep):
    return dict(prefix=prefix, vowels=vowels, finals=finals, virama=virama, indep=indep)

SCRIPTS = {
    "jawa": _std("JAVANESE",
        {"i": ["WULU"], "u": ["SUKU"], "e": ["TALING"], "o": ["TALING", "TARUNG"], "E": ["PEPET"]},
        {"ng": "CECAK", "r": "LAYAR", "h": "WIGNYAN"}, "PANGKON",
        {"a": "A", "i": "I", "u": "U", "e": "E", "o": "O"}),
    "sunda": _std("SUNDANESE",
        {"i": ["PANGHULU"], "u": ["PANYUKU"], "e": ["PANAELAENG"], "o": ["PANOLONG"], "E": ["PAMEPET"]},
        {"ng": "PANYECEK", "r": "PANGLAYAR", "h": "PANGWISAD"}, "SIGN PAMAAEH",
        {"a": "A", "i": "I", "u": "U", "e": "E", "o": "O"}),
}
SYL = re.compile(r"^(ng|ny|dh|th|[bcdfghjklmnpqrstvwxyz])?([aiueoE])?(_)?$")

def syllable(sc, tok):
    s = SCRIPTS[sc]
    m = SYL.match(tok)
    assert m and (m[1] or m[2]), f"ejaan salah: {tok}"
    cons, vow, final = m.groups()
    P = s["prefix"]
    if not cons:
        return ch(f"{P} LETTER {s['indep'][vow]}")
    if final:
        if cons in s["finals"]:
            return ch(f"{P} SIGN {s['finals'][cons]}")
        return ch(f"{P} LETTER {cons.upper()}A") + ch(f"{P} {s['virama']}")
    out = ch(f"{P} LETTER {cons.upper()}A")
    if vow and vow != "a":
        out += "".join(ch(f"{P} VOWEL SIGN {n}") for n in s["vowels"][vow])
    return out

def word(sc, spec):
    return "".join(syllable(sc, t) for t in spec.split("-"))

def psa(items):
    return "PackedStringArray(" + ", ".join('"%s"' % i for i in items) + ")"

def write_puzzle(sc, data):
    subs, refs = [], []
    for n, (title, words, translation) in enumerate(data["boards"], 1):
        subs.append(
            f'[sub_resource type="Resource" id="board{n}"]\nscript = ExtResource("2")\n'
            f'title = "{title}"\nwords = {psa([word(sc, w) for w, _ in words])}\n'
            f'meanings = {psa([m for _, m in words])}\ntranslation = "{translation}"\n')
        refs.append(f'SubResource("board{n}")')
    text = (
        '[gd_resource type="Resource" script_class="AksaraPuzzle" format=3]\n\n'
        '[ext_resource type="Script" path="res://Code/AksaraPuzzle.gd" id="1"]\n'
        '[ext_resource type="Script" path="res://Code/StoryBoard.gd" id="2"]\n\n'
        + "\n".join(subs) +
        '\n[resource]\nscript = ExtResource("1")\n'
        f'script_name = "{data["name"]}"\nfont_path = "{data["font"]}"\n'
        f'boards = [{", ".join(refs)}]\n'
        f'question_words = {psa([word(sc, w) for w in data["question"]])}\n'
        f'answers = {psa(data["answers"])}\n')
    open(f"Puzzles/aksara_{sc}.tres", "w", encoding="utf-8").write(text)

PUZZLES = {
    "jawa": dict(name="Aksara Jawa", font="res://Assets/Fonts/NotoSansJavanese.ttf",
        boards=[
            ("Kisah Kebo", [("kE-bo", "kerbau"), ("a-na", "ada"), ("i-ng_", "di"), ("sa-wa-h_", "sawah")], "Kerbau ada di sawah."),
            ("Kisah Sapi", [("sa-pi", "sapi"), ("ma-nga-n_", "makan"), ("su-kE-t_", "rumput")], "Sapi makan rumput."),
            ("Kisah Bapak", [("ba-pa-k_", "bapak"), ("mE-nya-ng_", "pergi ke"), ("pa-sa-r_", "pasar")], "Bapak pergi ke pasar."),
            ("Kisah Rumah", [("sa-pa", "siapa"), ("a-na", "ada"), ("i-ng_", "di"), ("o-ma-h_", "rumah")], "Siapa ada di rumah?"),
        ],
        question=["sa-pa", "ma-nga-n_", "su-kE-t_"], answers=["sapi"]),
    "sunda": dict(name="Aksara Sunda", font="res://Assets/Fonts/NotoSansSundanese.ttf",
        boards=[
            ("Kisah Kuda", [("ku-da", "kuda"), ("a-ya", "ada"), ("di", "di"), ("sa-wa-h_", "sawah")], "Kuda ada di sawah."),
            ("Kisah Sapi", [("sa-pi", "sapi"), ("da-ha-r_", "makan"), ("ju-ku-t_", "rumput")], "Sapi makan rumput."),
            ("Kisah Bapa", [("ba-pa", "bapak"), ("ka", "ke"), ("pa-sa-r_", "pasar")], "Bapak ke pasar."),
            ("Kisah Imah", [("sa-ha", "siapa"), ("a-ya", "ada"), ("di", "di"), ("i-ma-h_", "rumah")], "Siapa ada di rumah?"),
        ],
        question=["sa-ha", "da-ha-r_", "ju-ku-t_"], answers=["sapi"]),
}

if __name__ == "__main__":
    for sc, data in PUZZLES.items():
        write_puzzle(sc, data)
        print(sc, "->", " ".join(word(sc, w) for w in data["question"]))
