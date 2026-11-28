class_name UITheme
extends RefCounted
# Tema UI terpadu bergaya Museum Nusantara (kayu jati, emas lembut, dan kertas perkamen hangat).

const BG_DARK := Color(0.11, 0.085, 0.065, 0.95)
const BG_MENU := Color(0.14, 0.105, 0.08, 0.96)
const BG_DIM := Color(0.04, 0.03, 0.02, 0.68)
const CARD_BG := Color(0.96, 0.93, 0.87, 0.99)
const CARD_INNER := Color(0.90, 0.85, 0.76, 1.0)
const CARD_HOVER := Color(0.94, 0.89, 0.80, 1.0)
const BORDER_GOLD := Color(0.78, 0.60, 0.30, 1.0)
const BORDER_WOOD := Color(0.45, 0.32, 0.20, 1.0)
const BORDER_SOFT := Color(0.75, 0.67, 0.55, 1.0)

const ACCENT_PRIMARY := Color(0.68, 0.43, 0.16, 1.0)
const ACCENT_PRIMARY_HOVER := Color(0.78, 0.52, 0.22, 1.0)
const ACCENT_PRIMARY_PRESSED := Color(0.55, 0.34, 0.12, 1.0)

const ACCENT_SECONDARY := Color(0.28, 0.22, 0.17, 1.0)
const ACCENT_SECONDARY_HOVER := Color(0.37, 0.29, 0.22, 1.0)
const ACCENT_SECONDARY_PRESSED := Color(0.22, 0.17, 0.13, 1.0)

const ACCENT_SUCCESS := Color(0.19, 0.48, 0.30, 1.0)
const ACCENT_SUCCESS_HOVER := Color(0.25, 0.58, 0.37, 1.0)
const ACCENT_SUCCESS_PRESSED := Color(0.14, 0.38, 0.23, 1.0)

const ACCENT_DANGER := Color(0.66, 0.21, 0.19, 1.0)
const ACCENT_DANGER_HOVER := Color(0.78, 0.27, 0.24, 1.0)
const ACCENT_DANGER_PRESSED := Color(0.52, 0.16, 0.14, 1.0)

const TEXT_DARK := Color(0.15, 0.11, 0.08, 1.0)
const TEXT_MUTED := Color(0.42, 0.35, 0.28, 1.0)
const TEXT_LIGHT := Color(0.97, 0.94, 0.88, 1.0)
const TEXT_LIGHT_MUTED := Color(0.78, 0.72, 0.63, 1.0)
const TEXT_GOLD := Color(0.95, 0.80, 0.46, 1.0)
const TEXT_WARN := Color(0.95, 0.68, 0.24, 1.0)
const TEXT_DANGER := Color(0.95, 0.36, 0.32, 1.0)

static var _cached_theme: Theme

static func make_box(
	bg: Color,
	border: Color = Color.TRANSPARENT,
	border_w: int = 0,
	radius: int = 10,
	pad_x: int = 16,
	pad_y: int = 12,
	shadow: int = 0
) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	if border_w > 0:
		s.set_border_width_all(border_w)
		s.border_color = border
	s.set_corner_radius_all(radius)
	s.content_margin_left = pad_x
	s.content_margin_right = pad_x
	s.content_margin_top = pad_y
	s.content_margin_bottom = pad_y
	if shadow > 0:
		s.shadow_size = shadow
		s.shadow_color = Color(0, 0, 0, 0.35)
		s.shadow_offset = Vector2(0, 4)
	return s

static func get_theme() -> Theme:
	if _cached_theme != null:
		return _cached_theme
	var t := Theme.new()
	t.default_font_size = 15

	# Button default (warm wood)
	t.set_stylebox("normal", "Button", make_box(ACCENT_SECONDARY, BORDER_WOOD, 1, 8, 14, 9))
	t.set_stylebox("hover", "Button", make_box(ACCENT_SECONDARY_HOVER, BORDER_GOLD, 1, 8, 14, 9))
	t.set_stylebox("pressed", "Button", make_box(ACCENT_SECONDARY_PRESSED, BORDER_GOLD, 1, 8, 14, 9))
	t.set_stylebox("focus", "Button", make_box(ACCENT_SECONDARY_HOVER, BORDER_GOLD, 2, 8, 14, 9))
	t.set_stylebox("disabled", "Button", make_box(Color(0.35, 0.31, 0.27, 0.65), BORDER_SOFT, 1, 8, 14, 9))
	t.set_color("font_color", "Button", TEXT_LIGHT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", TEXT_GOLD)
	t.set_color("font_disabled_color", "Button", Color(0.80, 0.76, 0.70, 0.7))

	# LineEdit
	t.set_stylebox("normal", "LineEdit", make_box(Color(1.0, 0.985, 0.95, 1.0), BORDER_WOOD, 2, 8, 12, 8))
	t.set_stylebox("focus", "LineEdit", make_box(Color(1.0, 0.99, 0.97, 1.0), ACCENT_PRIMARY, 2, 8, 12, 8))
	t.set_color("font_color", "LineEdit", TEXT_DARK)
	t.set_color("font_placeholder_color", "LineEdit", TEXT_MUTED)
	t.set_color("caret_color", "LineEdit", ACCENT_PRIMARY)

	# PanelContainer default (parchment)
	t.set_stylebox("panel", "PanelContainer", make_box(CARD_BG, BORDER_WOOD, 2, 12, 20, 18, 12))

	# HSeparator
	var sep := StyleBoxLine.new()
	sep.color = Color(0.55, 0.44, 0.32, 0.4)
	sep.thickness = 1
	t.set_stylebox("separator", "HSeparator", sep)

	# HSlider
	t.set_stylebox("slider", "HSlider", make_box(Color(0.24, 0.19, 0.15, 1.0), BORDER_WOOD, 1, 6, 4, 4))
	t.set_stylebox("grabber_area", "HSlider", make_box(ACCENT_PRIMARY, BORDER_GOLD, 1, 6, 4, 4))
	t.set_stylebox("grabber_area_highlight", "HSlider", make_box(ACCENT_PRIMARY_HOVER, BORDER_GOLD, 1, 6, 4, 4))

	# ItemList
	t.set_stylebox("panel", "ItemList", make_box(Color(0.99, 0.97, 0.93, 1.0), BORDER_SOFT, 1, 8, 6, 6))
	t.set_stylebox("selected", "ItemList", make_box(ACCENT_PRIMARY, BORDER_GOLD, 1, 6, 8, 6))
	t.set_stylebox("selected_focus", "ItemList", make_box(ACCENT_PRIMARY, BORDER_GOLD, 1, 6, 8, 6))
	t.set_color("font_color", "ItemList", TEXT_DARK)
	t.set_color("font_selected_color", "ItemList", Color.WHITE)

	# OptionButton / PopupMenu
	t.set_stylebox("panel", "PopupMenu", make_box(BG_MENU, BORDER_GOLD, 1, 8, 8, 8, 8))
	t.set_stylebox("hover", "PopupMenu", make_box(ACCENT_PRIMARY, BORDER_GOLD, 0, 6, 8, 6))
	t.set_color("font_color", "PopupMenu", TEXT_LIGHT)
	t.set_color("font_hover_color", "PopupMenu", Color.WHITE)

	_cached_theme = t
	return t

static func style_parchment_panel(p: PanelContainer, pad_x: int = 22, pad_y: int = 18) -> void:
	p.theme = get_theme()
	p.add_theme_stylebox_override("panel", make_box(CARD_BG, BORDER_WOOD, 2, 14, pad_x, pad_y, 14))

static func style_dark_panel(p: PanelContainer, pad_x: int = 26, pad_y: int = 22) -> void:
	p.theme = get_theme()
	p.add_theme_stylebox_override("panel", make_box(BG_MENU, BORDER_GOLD, 2, 14, pad_x, pad_y, 16))

static func style_hud_pill(p: PanelContainer, border: Color = BORDER_GOLD) -> void:
	p.theme = get_theme()
	p.add_theme_stylebox_override("panel", make_box(BG_DARK, border, 2, 10, 14, 8, 6))

static func style_inner_box(p: PanelContainer, pad: int = 12, dark: bool = false) -> void:
	var bg := Color(0.19, 0.145, 0.11, 0.95) if dark else CARD_INNER
	var bd := Color(0.45, 0.35, 0.22, 0.8) if dark else BORDER_SOFT
	p.add_theme_stylebox_override("panel", make_box(bg, bd, 1, 10, pad, pad))

static func style_button(b: Button, variant: String = "secondary") -> void:
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var normal_bg := ACCENT_SECONDARY
	var hover_bg := ACCENT_SECONDARY_HOVER
	var pressed_bg := ACCENT_SECONDARY_PRESSED
	var border := BORDER_WOOD
	match variant:
		"primary":
			normal_bg = ACCENT_PRIMARY
			hover_bg = ACCENT_PRIMARY_HOVER
			pressed_bg = ACCENT_PRIMARY_PRESSED
			border = BORDER_GOLD
		"success":
			normal_bg = ACCENT_SUCCESS
			hover_bg = ACCENT_SUCCESS_HOVER
			pressed_bg = ACCENT_SUCCESS_PRESSED
			border = Color(0.45, 0.78, 0.56, 1.0)
		"danger":
			normal_bg = ACCENT_DANGER
			hover_bg = ACCENT_DANGER_HOVER
			pressed_bg = ACCENT_DANGER_PRESSED
			border = Color(0.92, 0.52, 0.48, 1.0)
		"slot":
			b.add_theme_stylebox_override("normal", make_box(Color(0.20, 0.15, 0.11, 0.92), BORDER_WOOD, 2, 10, 6, 6))
			b.add_theme_stylebox_override("hover", make_box(Color(0.28, 0.21, 0.15, 0.96), BORDER_GOLD, 2, 10, 6, 6))
			b.add_theme_stylebox_override("pressed", make_box(Color(0.35, 0.24, 0.14, 1.0), TEXT_GOLD, 3, 10, 6, 6))
			b.add_theme_stylebox_override("disabled", make_box(Color(0.22, 0.26, 0.20, 0.9), ACCENT_SUCCESS, 2, 10, 6, 6))
			b.add_theme_color_override("font_color", TEXT_LIGHT)
			b.add_theme_color_override("font_pressed_color", TEXT_GOLD)
			return
		"dropzone":
			b.add_theme_stylebox_override("normal", make_box(CARD_INNER, BORDER_WOOD, 2, 12, 8, 8))
			b.add_theme_stylebox_override("hover", make_box(CARD_HOVER, ACCENT_PRIMARY, 2, 12, 8, 8))
			b.add_theme_stylebox_override("pressed", make_box(CARD_INNER, BORDER_GOLD, 2, 12, 8, 8))
			b.add_theme_stylebox_override("disabled", make_box(Color(0.84, 0.92, 0.85, 1.0), ACCENT_SUCCESS, 2, 12, 8, 8))
			b.add_theme_color_override("font_color", TEXT_DARK)
			b.add_theme_color_override("font_hover_color", TEXT_DARK)
			b.add_theme_color_override("font_disabled_color", ACCENT_SUCCESS)
			return
	b.add_theme_stylebox_override("normal", make_box(normal_bg, border, 1, 8, 16, 10))
	b.add_theme_stylebox_override("hover", make_box(hover_bg, BORDER_GOLD, 1, 8, 16, 10))
	b.add_theme_stylebox_override("pressed", make_box(pressed_bg, BORDER_GOLD, 1, 8, 16, 10))
	b.add_theme_stylebox_override("disabled", make_box(Color(0.38, 0.34, 0.30, 0.55), BORDER_SOFT, 1, 8, 16, 10))
	b.add_theme_color_override("font_color", TEXT_LIGHT)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_pressed_color", TEXT_GOLD)

static func make_backdrop() -> ColorRect:
	var r := ColorRect.new()
	r.color = BG_DIM
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_STOP
	r.visible = false
	return r

static func make_title(text: String, size: int = 22, dark_bg: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", TEXT_GOLD if dark_bg else TEXT_DARK)
	return l

static func make_body(text: String, size: int = 15, muted: bool = false, dark_bg: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	if dark_bg:
		l.add_theme_color_override("font_color", TEXT_LIGHT_MUTED if muted else TEXT_LIGHT)
	else:
		l.add_theme_color_override("font_color", TEXT_MUTED if muted else TEXT_DARK)
	return l

static func make_divider(dark_bg: bool = false) -> HSeparator:
	var s := HSeparator.new()
	var line := StyleBoxLine.new()
	line.color = Color(0.78, 0.60, 0.30, 0.35) if dark_bg else Color(0.45, 0.32, 0.20, 0.28)
	line.thickness = 1
	s.add_theme_stylebox_override("separator", line)
	return s
