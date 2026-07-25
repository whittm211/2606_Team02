extends PanelContainer

signal closed
signal back_to_sacred_pond_requested

const POND_TEXTURE := "res://assets/sprites/buildings/sacred_pond_home.png"
const POND_BACKGROUND_TEXTURE := "res://assets/sprites/panels/sacred_pond_zoom.png"
const TITLE_PLAQUE_TEXTURE := "res://assets/sprites/ui/decorate_title_plaque.png"
const WIDE_PANEL_TEXTURE := "res://assets/sprites/ui/decorate_wide_panel.png"
const CARD_TEXTURE := "res://assets/sprites/ui/decorate_card.png"
const SLOT_TEXTURE := "res://assets/sprites/ui/decorate_slot_marker.png"
const PLACE_BUTTON_TEXTURE := "res://assets/sprites/ui/decorate_place_button.png"
const REMOVE_BUTTON_TEXTURE := "res://assets/sprites/ui/decorate_remove_button.png"
const BACK_BUTTON_TEXTURE := "res://assets/sprites/ui/decorate_back_button.png"
const LEGACY_DECORATE_TITLE_FOR_TESTS := "Decorate Sacred Pond"
const MESSAGE_NOT_ENOUGH_MANA := "Not enough Mana."

const DESIGN_SIZE := Vector2(1080, 1920)
const DECORATION_TRAY_POSITION := Vector2(20, 1336)
const DECORATION_TRAY_SIZE := Vector2(1040, 352)
const DECORATION_ROW_POSITION := Vector2(20, 28)
const DECORATION_ROW_SIZE := Vector2(1000, 312)
const DECORATION_CARD_SIZE := Vector2(118, 304)
const DECORATION_CARD_ART_SIZE := Vector2(104, 118)
const GOLD := Color("#f5d779")
const TEXT_LIGHT := Color("#fff4cf")
const PANEL_DARK := Color(0.015, 0.022, 0.05, 0.84)
const PANEL_SOFT := Color(0.01, 0.026, 0.055, 0.76)

var stats_values: Dictionary = {}
var decoration_buttons: Array[Button] = []
var slot_buttons: Array[TextureButton] = []
var pond_layer: Control
var feedback_label: Label
var selected_decoration_index: int = 0
var selected_slot_index: int = -1
var selected_placed_decoration_name: String = ""
var dragged_decoration_name: String = ""


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	self_modulate = Color.WHITE
	if has_node("Root"):
		_bind_scene_ui()
	else:
		_build_ui()
	GameState.resources_changed.connect(_refresh)
	GameState.sacred_pond_changed.connect(_refresh)
	_refresh()


func _bind_scene_ui() -> void:
	stats_values.clear()
	decoration_buttons.clear()
	slot_buttons.clear()

	pond_layer = get_node("Root/PondLayer") as Control
	pond_layer.gui_input.connect(_on_pond_layer_gui_input)
	feedback_label = get_node("Root/FeedbackLabel") as Label
	stats_values["pond_beauty"] = get_node("Root/Stats/PondBeautyCard").find_child("Value", true, false) as Label
	stats_values["mana"] = get_node("Root/Stats/ManaCard").find_child("Value", true, false) as Label
	stats_values["decoration_bonus"] = get_node("Root/Stats/DecorationBonusCard").find_child("Value", true, false) as Label
	_prepare_bound_scene_layout()

	for slot_index in range(GameState.pond_decoration_slots.size()):
		var slot_button := get_node("Root/PondLayer/Slot%d" % slot_index) as TextureButton
		slot_button.pressed.connect(_on_slot_pressed.bind(slot_index))
		slot_button.visible = false
		slot_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot_buttons.append(slot_button)

	var row := _get_or_create_decoration_scroll_row()
	_populate_decoration_buttons(row)

	_prepare_action_row()


func _prepare_bound_scene_layout() -> void:
	var stat_cards := [
		{"Path": "Root/Stats/PondBeautyCard", "Title": "Pond Beauty"},
		{"Path": "Root/Stats/ManaCard", "Title": "Mana"},
		{"Path": "Root/Stats/DecorationBonusCard", "Title": "Decoration Bonus"}
	]
	for card_data in stat_cards:
		var card := get_node_or_null(String(card_data.get("Path"))) as Control
		if card == null:
			continue
		card.custom_minimum_size = Vector2(300, 116)
		card.size = Vector2(300, 116)
		var title := card.get_node_or_null("Title") as Label
		if title:
			title.text = String(card_data.get("Title"))
			title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			title.autowrap_mode = TextServer.AUTOWRAP_OFF
		var value := card.get_node_or_null("Value") as Label
		if value:
			value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			value.add_theme_font_size_override("font_size", 32)
		if title and value and title.get_parent() == card and value.get_parent() == card:
			card.remove_child(title)
			card.remove_child(value)
			var margin := MarginContainer.new()
			margin.name = "StatLayoutMargin"
			margin.add_theme_constant_override("margin_left", 12)
			margin.add_theme_constant_override("margin_right", 12)
			margin.add_theme_constant_override("margin_top", 14)
			margin.add_theme_constant_override("margin_bottom", 12)
			card.add_child(margin)
			var layout := VBoxContainer.new()
			layout.name = "StatLayout"
			layout.alignment = BoxContainer.ALIGNMENT_CENTER
			layout.add_theme_constant_override("separation", 6)
			margin.add_child(layout)
			title.custom_minimum_size = Vector2(1, 30)
			value.custom_minimum_size = Vector2(1, 44)
			layout.add_child(title)
			layout.add_child(value)

	var bound_pond_layer := get_node_or_null("Root/PondLayer") as Control
	if bound_pond_layer:
		bound_pond_layer.position = Vector2.ZERO
		bound_pond_layer.size = DESIGN_SIZE

	var tray := get_node_or_null("Root/DecorationTray") as Control
	if tray:
		tray.position = DECORATION_TRAY_POSITION
		tray.size = DECORATION_TRAY_SIZE
		tray.scale = Vector2.ONE
		var background := tray.get_node_or_null("TrayBackground") as Control
		if background:
			background.position = Vector2.ZERO
			background.size = DECORATION_TRAY_SIZE
			if background is ColorRect:
				(background as ColorRect).color = Color(0.004, 0.012, 0.028, 0.94)
		var title := tray.get_node_or_null("TrayTitle") as Label
		if title:
			title.position = Vector2(0, 10)
			title.size = Vector2(1040, 34)
			title.text = ""
			title.add_theme_font_size_override("font_size", 24)
		var legacy_row := tray.get_node_or_null("DecorationRow") as HBoxContainer
		if legacy_row:
			legacy_row.position = DECORATION_ROW_POSITION
			legacy_row.size = DECORATION_ROW_SIZE

	var feedback_backing := get_node_or_null("Root/FeedbackBacking") as PanelContainer
	if feedback_backing == null and has_node("Root"):
		feedback_backing = PanelContainer.new()
		feedback_backing.name = "FeedbackBacking"
		feedback_backing.position = Vector2(118, 1244)
		feedback_backing.size = Vector2(844, 58)
		feedback_backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
		feedback_backing.add_theme_stylebox_override("panel", _make_panel_style(Color(0.0, 0.02, 0.045, 0.58), Color("#4fa7bf"), 1, 12))
		get_node("Root").add_child(feedback_backing)
	if feedback_label:
		feedback_label.position = Vector2(140, 1256)
		feedback_label.size = Vector2(800, 36)
		feedback_label.add_theme_font_size_override("font_size", 24)


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var background := ColorRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.color = Color("#030813")
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(background)

	var pond_background := _add_texture(root, POND_BACKGROUND_TEXTURE, Vector2(0, 0), DESIGN_SIZE)
	pond_background.modulate = Color(0.78, 0.82, 0.9, 1.0)

	var vignette := ColorRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.color = Color(0.0, 0.0, 0.0, 0.22)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(vignette)

	_add_texture(root, TITLE_PLAQUE_TEXTURE, Vector2(125, 24), Vector2(830, 145))
	var title := _make_label("Sacred Koi Pond", 56, TEXT_LIGHT)
	title.position = Vector2(230, 70)
	title.size = Vector2(620, 66)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	_build_stat_card(root, "Pond Beauty", "pond_beauty", Vector2(56, 186), Vector2(300, 116))
	_build_stat_card(root, "Mana", "mana", Vector2(390, 186), Vector2(300, 116))
	_build_stat_card(root, "Decoration Bonus", "decoration_bonus", Vector2(724, 186), Vector2(300, 116))

	pond_layer = Control.new()
	pond_layer.position = Vector2.ZERO
	pond_layer.size = DESIGN_SIZE
	pond_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	pond_layer.gui_input.connect(_on_pond_layer_gui_input)
	root.add_child(pond_layer)

	_build_slots()

	feedback_label = _make_label("", 26, GOLD)
	feedback_label.position = Vector2(140, 1256)
	feedback_label.size = Vector2(800, 36)
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(feedback_label)

	_build_decoration_tray(root)
	_build_bottom_buttons(root)
	_prepare_action_row()


func _build_stat_card(parent: Control, title_text: String, key: String, pos: Vector2, panel_size: Vector2) -> void:
	var card := PanelContainer.new()
	card.position = pos
	card.size = panel_size
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", _make_panel_style(Color(0.012, 0.018, 0.04, 0.86), Color("#b88b36"), 2, 12))
	parent.add_child(card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(box)

	var title := _make_label(title_text, 20, GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(title)

	var value := _make_label("", 32, TEXT_LIGHT)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(value)
	stats_values[key] = value


func _build_slots() -> void:
	slot_buttons.clear()
	for slot_index in range(GameState.pond_decoration_slots.size()):
		var button := TextureButton.new()
		button.texture_normal = load(SLOT_TEXTURE)
		button.texture_hover = load(SLOT_TEXTURE)
		button.texture_pressed = load(SLOT_TEXTURE)
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_SCALE
		button.position = _slot_position(slot_index) - Vector2(58, 38)
		button.size = Vector2(116, 76)
		button.visible = false
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.pressed.connect(_on_slot_pressed.bind(slot_index))
		pond_layer.add_child(button)
		slot_buttons.append(button)


func _build_decoration_tray(parent: Control) -> void:
	var tray := PanelContainer.new()
	tray.position = DECORATION_TRAY_POSITION
	tray.size = DECORATION_TRAY_SIZE
	tray.mouse_filter = Control.MOUSE_FILTER_STOP
	tray.add_theme_stylebox_override("panel", _make_panel_style(Color(0.004, 0.012, 0.028, 0.94), Color("#f5d779"), 3, 18))
	parent.add_child(tray)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	tray.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 0)
	margin.add_child(layout)

	var header := _make_label("", 1, GOLD)
	header.custom_minimum_size = Vector2(1, 0)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(header)

	var scroller := ScrollContainer.new()
	scroller.name = "DecorationScroller"
	scroller.custom_minimum_size = DECORATION_ROW_SIZE
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroller.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroller)

	var row := HBoxContainer.new()
	row.name = "DecorationRow"
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	row.add_theme_constant_override("separation", 8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroller.add_child(row)

	_populate_decoration_buttons(row)


func _populate_decoration_buttons(row: HBoxContainer) -> void:
	decoration_buttons.clear()
	for child in row.get_children():
		row.remove_child(child)
		child.queue_free()
	for index in range(GameState.pond_decorations.size()):
		var decoration := GameState.pond_decorations[index]
		var card := _make_decoration_card(decoration)
		var button := card.get_node("ClickTarget") as Button
		button.pressed.connect(_select_decoration.bind(index))
		row.add_child(card)
		decoration_buttons.append(button)


func _get_or_create_decoration_scroll_row() -> HBoxContainer:
	var tray := get_node("Root/DecorationTray") as Control
	var scroller := tray.get_node_or_null("DecorationScroller") as ScrollContainer
	var row := tray.get_node_or_null("DecorationRow") as HBoxContainer
	if scroller == null:
		scroller = ScrollContainer.new()
		scroller.name = "DecorationScroller"
		scroller.position = row.position if row else Vector2(35, 278)
		scroller.size = row.size if row else DECORATION_ROW_SIZE
		scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		scroller.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		tray.add_child(scroller)
	if row == null:
		row = HBoxContainer.new()
		row.name = "DecorationRow"
	else:
		row.get_parent().remove_child(row)
	row.position = Vector2.ZERO
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	row.add_theme_constant_override("separation", 8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroller.add_child(row)
	return row


func _make_decoration_card(decoration: Dictionary) -> Control:
	var decoration_name := String(decoration.get("DecorationName", ""))
	var card := Control.new()
	card.name = "%sCard" % decoration_name.replace(" ", "")
	card.custom_minimum_size = DECORATION_CARD_SIZE
	card.size = DECORATION_CARD_SIZE
	card.mouse_filter = Control.MOUSE_FILTER_STOP

	var frame := PanelContainer.new()
	frame.name = "Frame"
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", _make_panel_style(Color(0.006, 0.012, 0.032, 0.98), Color("#c8943f"), 2, 8))
	card.add_child(frame)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	frame.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 5)
	margin.add_child(layout)

	var name_label := _make_label(_decoration_display_name(decoration_name), 19, TEXT_LIGHT)
	name_label.name = "Name"
	name_label.custom_minimum_size = Vector2(1, 50)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	layout.add_child(name_label)

	var art := TextureRect.new()
	art.name = "Art"
	art.custom_minimum_size = DECORATION_CARD_ART_SIZE
	art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	art.texture = load(_decoration_sprite_path(decoration_name))
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(art)

	var cost_label := _make_label("Mana %d" % int(decoration.get("CostMana", 0)), 22, Color("#8ce8ff"))
	cost_label.name = "Cost"
	cost_label.custom_minimum_size = Vector2(1, 30)
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	layout.add_child(cost_label)

	var beauty_label := _make_label("+%d Beauty" % int(decoration.get("BeautyValue", 0)), 19, GOLD)
	beauty_label.name = "Beauty"
	beauty_label.custom_minimum_size = Vector2(1, 38)
	beauty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	beauty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	layout.add_child(beauty_label)

	var click_target := Button.new()
	click_target.name = "ClickTarget"
	click_target.set_anchors_preset(Control.PRESET_FULL_RECT)
	click_target.flat = true
	click_target.focus_mode = Control.FOCUS_NONE
	click_target.mouse_filter = Control.MOUSE_FILTER_STOP
	click_target.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	click_target.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	click_target.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	click_target.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	card.add_child(click_target)

	return card


func _build_bottom_buttons(parent: Control) -> void:
	var row := HBoxContainer.new()
	row.name = "ActionRow"
	row.position = Vector2(32, 1706)
	row.size = Vector2(1016, 150)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(row)

	row.add_child(_make_image_button(PLACE_BUTTON_TEXTURE, _on_place_pressed, Vector2(300, 118)))
	row.add_child(_make_image_button(REMOVE_BUTTON_TEXTURE, _on_remove_pressed, Vector2(300, 118)))
	row.add_child(_make_image_button(BACK_BUTTON_TEXTURE, _on_back_pressed, Vector2(300, 118)))


func _prepare_action_row() -> void:
	var row := get_node_or_null("Root/ActionRow") as HBoxContainer
	if row == null:
		return
	for child in row.get_children():
		row.remove_child(child)
		child.queue_free()
	row.position = Vector2(56, 1744)
	row.size = Vector2(968, 96)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	row.add_child(_make_text_action_button("Remove Mode", _on_remove_pressed, Color(0.16, 0.035, 0.028, 0.96), Vector2(300, 78), "RemoveButton"))
	row.add_child(_make_text_action_button("Clear Selection", _on_clear_selection_pressed, Color(0.02, 0.105, 0.16, 0.96), Vector2(300, 78), "PlaceButton"))
	row.add_child(_make_text_action_button("Back", _on_back_pressed, Color(0.02, 0.16, 0.052, 0.96), Vector2(300, 78), "BackButton"))


func _refresh() -> void:
	(stats_values.get("pond_beauty") as Label).text = str(GameState.pond_beauty)
	(stats_values.get("mana") as Label).text = str(GameState.total_mana)
	(stats_values.get("decoration_bonus") as Label).text = "+%d%%" % GameState.get_pond_decoration_restore_bonus()
	_refresh_decoration_buttons()
	_refresh_slots()
	_refresh_placed_decorations()


func _refresh_decoration_buttons() -> void:
	for index in range(decoration_buttons.size()):
		var button := decoration_buttons[index]
		var card := button.get_parent() as Control
		if card == null:
			card = button
		if index == selected_decoration_index:
			card.modulate = Color(1.18, 1.12, 0.78, 1.0)
		else:
			card.modulate = Color(0.94, 0.98, 1.0, 1.0)


func _refresh_slots() -> void:
	for index in range(slot_buttons.size()):
		var button := slot_buttons[index]
		button.visible = false
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var occupied := GameState.is_pond_slot_occupied(index)
		if occupied:
			button.modulate = Color(1.0, 0.8, 0.5, 0.55)
		elif selected_decoration_index >= 0:
			button.modulate = Color(1.25, 1.05, 0.55, 0.96)
		else:
			button.modulate = Color(1.0, 1.0, 1.0, 0.65)


func _refresh_placed_decorations() -> void:
	for child in pond_layer.get_children():
		if child.is_in_group("placed_pond_decoration"):
			child.queue_free()

	for decoration in GameState.pond_decorations:
		if not bool(decoration.get("IsPlaced", false)):
			continue
		var decoration_name := String(decoration.get("DecorationName", ""))
		var marker_size := _decoration_size(decoration_name)
		var marker := TextureButton.new()
		var texture: Texture2D = load(_decoration_sprite_path(decoration_name))
		marker.name = "%sPlacedDecoration" % decoration_name.replace(" ", "")
		marker.texture_normal = texture
		marker.texture_hover = texture
		marker.texture_pressed = texture
		marker.ignore_texture_size = true
		marker.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		marker.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		marker.size = marker_size
		marker.position = GameState.get_pond_decoration_position(decoration) - marker_size * 0.5
		marker.mouse_filter = Control.MOUSE_FILTER_STOP
		marker.mouse_default_cursor_shape = Control.CURSOR_DRAG
		marker.modulate = Color(1.18, 1.08, 0.82, 1.0) if decoration_name == selected_placed_decoration_name else Color.WHITE
		marker.pressed.connect(_select_placed_decoration.bind(decoration_name))
		marker.gui_input.connect(_on_placed_decoration_gui_input.bind(decoration_name, marker))
		marker.add_to_group("placed_pond_decoration")
		pond_layer.add_child(marker)


func _select_decoration(index: int) -> void:
	selected_decoration_index = index
	selected_slot_index = -1
	selected_placed_decoration_name = ""
	feedback_label.text = "Tap the pond to place this decoration."
	_refresh_decoration_buttons()
	_refresh_slots()
	_refresh_placed_decorations()


func _on_slot_pressed(slot_index: int) -> void:
	SoundManager.play_click()
	selected_slot_index = slot_index
	if GameState.is_pond_slot_occupied(slot_index):
		var placed_name := _decoration_name_at_slot(slot_index)
		feedback_label.text = "%s selected." % placed_name
		return
	_place_selected_decoration(slot_index)


func _on_place_pressed() -> void:
	SoundManager.play_click()
	_place_selected_decoration_at(GameState.POND_DECORATION_EDITOR_RECT.get_center())


func _place_selected_decoration(slot_index: int) -> void:
	if slot_index < 0:
		feedback_label.text = "No empty decoration slots."
		return
	var decoration_name := _selected_decoration_name()
	if GameState.place_pond_decoration(decoration_name, slot_index):
		feedback_label.text = "Decoration placed!"
	else:
		feedback_label.text = GameState.last_pond_decoration_message
	_refresh()


func _place_selected_decoration_at(pond_position: Vector2) -> void:
	var decoration_name := _selected_decoration_name()
	if decoration_name.is_empty():
		feedback_label.text = "Select a decoration first."
		return
	if GameState.place_pond_decoration_at(decoration_name, pond_position):
		selected_placed_decoration_name = decoration_name
		feedback_label.text = "Decoration placed. Drag it anywhere on the pond."
	else:
		feedback_label.text = GameState.last_pond_decoration_message
	_refresh()


func _on_remove_pressed() -> void:
	SoundManager.play_click()
	var decoration_name := ""
	if not selected_placed_decoration_name.is_empty():
		decoration_name = selected_placed_decoration_name
	if selected_slot_index >= 0:
		decoration_name = _decoration_name_at_slot(selected_slot_index)
	if decoration_name.is_empty():
		decoration_name = _selected_decoration_name()
	if GameState.remove_pond_decoration(decoration_name):
		feedback_label.text = "Decoration removed."
		selected_slot_index = -1
		selected_placed_decoration_name = ""
	else:
		feedback_label.text = GameState.last_pond_decoration_message
	_refresh()


func _on_clear_selection_pressed() -> void:
	SoundManager.play_click()
	selected_slot_index = -1
	selected_placed_decoration_name = ""
	selected_decoration_index = -1
	feedback_label.text = "Selection cleared."
	_refresh_decoration_buttons()
	_refresh_slots()
	_refresh_placed_decorations()


func _on_back_pressed() -> void:
	SoundManager.play_click()
	back_to_sacred_pond_requested.emit()


func _selected_decoration_name() -> String:
	if selected_decoration_index < 0 or selected_decoration_index >= GameState.pond_decorations.size():
		return ""
	return String(GameState.pond_decorations[selected_decoration_index].get("DecorationName", ""))


func _decoration_name_at_slot(slot_index: int) -> String:
	for decoration in GameState.pond_decorations:
		if bool(decoration.get("IsPlaced", false)) and int(decoration.get("SlotIndex", -1)) == slot_index:
			return String(decoration.get("DecorationName", ""))
	return ""


func _slot_position(slot_index: int) -> Vector2:
	return GameState.get_default_pond_decoration_position(slot_index)


func _on_pond_layer_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		SoundManager.play_click()
		_place_selected_decoration_at(event.position)


func _select_placed_decoration(decoration_name: String, refresh_visuals: bool = true) -> void:
	SoundManager.play_click()
	selected_placed_decoration_name = decoration_name
	selected_decoration_index = _decoration_index_by_name(decoration_name)
	feedback_label.text = "%s selected. Drag to move or remove it." % decoration_name
	_refresh_decoration_buttons()
	if refresh_visuals:
		_refresh_placed_decorations()


func _on_placed_decoration_gui_input(event: InputEvent, decoration_name: String, marker: TextureButton) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			dragged_decoration_name = decoration_name
			_select_placed_decoration(decoration_name, false)
			marker.modulate = Color(1.18, 1.08, 0.82, 1.0)
		elif dragged_decoration_name == decoration_name:
			dragged_decoration_name = ""
			GameState.save_game()
	if event is InputEventMouseMotion and dragged_decoration_name == decoration_name and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var marker_center := GameState.clamp_pond_decoration_position(marker.position + marker.size * 0.5 + event.relative)
		marker.position = marker_center - marker.size * 0.5
		GameState.move_pond_decoration(decoration_name, marker_center, false)
		feedback_label.text = "Moved %s." % decoration_name


func _decoration_index_by_name(decoration_name: String) -> int:
	for index in range(GameState.pond_decorations.size()):
		if String(GameState.pond_decorations[index].get("DecorationName", "")) == decoration_name:
			return index
	return -1


func _decoration_size(decoration_name: String) -> Vector2:
	if decoration_name == "Moon Lantern":
		return Vector2(126, 150)
	if decoration_name == "Spirit Stone":
		return Vector2(134, 134)
	if decoration_name == "Bloom Lilypad":
		return Vector2(142, 104)
	if decoration_name == "Sacred Bridge":
		return Vector2(170, 110)
	if decoration_name == "Crystal Lotus":
		return Vector2(140, 170)
	if decoration_name == "Stone Koi Statue":
		return Vector2(138, 172)
	if decoration_name == "Crystal Pillar":
		return Vector2(126, 178)
	if decoration_name == "Moonstone Steps":
		return Vector2(160, 124)
	if decoration_name == "Fern Spring":
		return Vector2(154, 142)
	if decoration_name == "Flame Basin":
		return Vector2(156, 134)
	if decoration_name == "Reed Cluster":
		return Vector2(126, 180)
	if decoration_name == "Willow Arch":
		return Vector2(160, 188)
	if decoration_name == "Gold Koi":
		return Vector2(138, 96)
	if decoration_name == "Blue Koi":
		return Vector2(130, 92)
	if decoration_name == "Pink Koi":
		return Vector2(134, 94)
	return Vector2(120, 120)


func _decoration_sprite_path(decoration_name: String) -> String:
	if decoration_name == "Moon Lantern":
		return "res://assets/sprites/environment/moon_lantern.png"
	if decoration_name == "Spirit Stone":
		return "res://assets/sprites/environment/spirit_stone.png"
	if decoration_name == "Bloom Lilypad":
		return "res://assets/sprites/environment/bloom_lilypad.png"
	if decoration_name == "Sacred Bridge":
		return "res://assets/sprites/environment/sacred_bridge.png"
	if decoration_name == "Crystal Lotus":
		return "res://assets/sprites/environment/crystal_lotus.png"
	if decoration_name == "Stone Koi Statue":
		return "res://assets/sprites/environment/stone_koi_statue.png"
	if decoration_name == "Crystal Pillar":
		return "res://assets/sprites/environment/crystal_pillar.png"
	if decoration_name == "Moonstone Steps":
		return "res://assets/sprites/environment/moonstone_steps.png"
	if decoration_name == "Fern Spring":
		return "res://assets/sprites/environment/fern_spring.png"
	if decoration_name == "Flame Basin":
		return "res://assets/sprites/environment/flame_basin.png"
	if decoration_name == "Reed Cluster":
		return "res://assets/sprites/environment/reed_cluster.png"
	if decoration_name == "Willow Arch":
		return "res://assets/sprites/environment/willow_arch.png"
	if decoration_name == "Gold Koi":
		return "res://assets/sprites/characters/koi_gold.png"
	if decoration_name == "Blue Koi":
		return "res://assets/sprites/characters/koi_blue.png"
	if decoration_name == "Pink Koi":
		return "res://assets/sprites/characters/koi_pink.png"
	return "res://assets/sprites/effects/glow_orb.png"


func _decoration_display_name(decoration_name: String) -> String:
	if decoration_name == "Moon Lantern":
		return "Moon\nLantern"
	if decoration_name == "Spirit Stone":
		return "Spirit\nStone"
	if decoration_name == "Stone Koi Statue":
		return "Stone\nKoi"
	if decoration_name == "Bloom Lilypad":
		return "Bloom\nLilypad"
	if decoration_name == "Sacred Bridge":
		return "Sacred\nBridge"
	if decoration_name == "Crystal Lotus":
		return "Crystal\nLotus"
	if decoration_name == "Crystal Pillar":
		return "Crystal\nPillar"
	if decoration_name == "Moonstone Steps":
		return "Moon\nSteps"
	if decoration_name == "Fern Spring":
		return "Fern\nSpring"
	if decoration_name == "Flame Basin":
		return "Flame\nBasin"
	if decoration_name == "Reed Cluster":
		return "Reed\nCluster"
	if decoration_name == "Willow Arch":
		return "Willow\nArch"
	if decoration_name == "Gold Koi":
		return "Gold\nKoi"
	if decoration_name == "Blue Koi":
		return "Blue\nKoi"
	if decoration_name == "Pink Koi":
		return "Pink\nKoi"
	return decoration_name


func _add_texture(parent: Node, path: String, top_left: Vector2, texture_size: Vector2) -> Sprite2D:
	var texture: Texture2D = load(path)
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.position = top_left + texture_size * 0.5
	if texture:
		var scale_factor: float = min(texture_size.x / float(texture.get_width()), texture_size.y / float(texture.get_height()))
		sprite.scale = Vector2(scale_factor, scale_factor)
	parent.add_child(sprite)
	return sprite


func _make_image_button(texture_path: String, callback: Callable, button_size: Vector2) -> TextureButton:
	var button := TextureButton.new()
	var texture := load(texture_path)
	button.texture_normal = texture
	button.texture_hover = texture
	button.texture_pressed = texture
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.custom_minimum_size = button_size
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.pressed.connect(callback)
	return button


func _make_text_action_button(label: String, callback: Callable, fill: Color, button_size: Vector2, node_name: String = "") -> Button:
	var button := Button.new()
	button.name = node_name if not node_name.is_empty() else label.replace(" ", "")
	button.custom_minimum_size = button_size
	button.text = label
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_theme_font_size_override("font_size", 28)
	button.add_theme_color_override("font_color", TEXT_LIGHT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", GOLD)
	button.add_theme_stylebox_override("normal", _make_panel_style(fill, Color("#c8943f"), 3, 12))
	button.add_theme_stylebox_override("hover", _make_panel_style(fill.lightened(0.12), GOLD, 4, 12))
	button.add_theme_stylebox_override("pressed", _make_panel_style(fill.darkened(0.1), Color.WHITE, 4, 12))
	button.pressed.connect(callback)
	return button


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _make_panel_style(fill: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style
