extends Control

signal closed

const BG_PATH := "res://assets/sprites/arcane_forge/arcane_forge_background.png"
const UPGRADE_IDS := ["flower_focus", "potion_gilding", "pond_resonance"]
const TAB_CARDS := {
	"Craft": "res://assets/sprites/arcane_forge/forge_craft_card.png",
	"Gear": "res://assets/sprites/arcane_forge/forge_gear_card.png",
	"Upgrades": "res://assets/sprites/arcane_forge/forge_upgrades_card.png",
	"Enhance": "res://assets/sprites/arcane_forge/forge_enhance_card.png",
	"Back": "res://assets/sprites/arcane_forge/forge_back_card.png"
}

var active_tab := "Upgrades"
var stats_label: Label
var title_label: Label
var mode_label: Label
var feedback_label: Label
var content_stack: VBoxContainer
var card_buttons: Dictionary = {}
var current_upgrade_index := 0
var previous_upgrade_button: Button
var next_upgrade_button: Button


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_panel()
	GameState.resources_changed.connect(_refresh)
	GameState.arcane_forge_changed.connect(_refresh)
	GameState.flower_grove_changed.connect(_refresh)
	GameState.potion_shop_changed.connect(_refresh)
	GameState.sacred_pond_changed.connect(_refresh)
	_refresh()


func _build_panel() -> void:
	_add_background()
	_add_top_bar()
	_add_title_header()
	_add_mode_panel()
	_add_bottom_tabs()
	_add_upgrade_pager_buttons()


func _add_background() -> void:
	var background := TextureRect.new()
	background.texture = load(BG_PATH)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.14)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)


func _add_top_bar() -> void:
	var margin := _make_full_margin(72, 72, 24, 1785)
	add_child(margin)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.012, 0.014, 0.020, 0.78), Color("#bd8d43"), 2, 12))
	margin.add_child(panel)
	stats_label = _make_label("", 24, Color("#fff1bc"), HORIZONTAL_ALIGNMENT_CENTER)
	stats_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(stats_label)


func _add_title_header() -> void:
	var margin := _make_full_margin(126, 126, 112, 1558)
	add_child(margin)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.010, 0.012, 0.018, 0.64), Color("#bd8d43"), 2, 14))
	margin.add_child(panel)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 0)
	panel.add_child(stack)

	title_label = _make_label("Arcane Forge", 58, Color("#ffd77b"), HORIZONTAL_ALIGNMENT_CENTER)
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_color_override("font_outline_color", Color("#1a1008"))
	title_label.add_theme_constant_override("outline_size", 2)
	stack.add_child(title_label)

	mode_label = _make_label("", 25, Color("#d9f1ff"), HORIZONTAL_ALIGNMENT_CENTER)
	mode_label.name = "ForgeLevelLabel"
	mode_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stack.add_child(mode_label)


func _add_mode_panel() -> void:
	var margin := _make_full_margin(95, 95, 1125, 475)
	add_child(margin)
	var panel := PanelContainer.new()
	panel.clip_contents = true
	panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.016, 0.018, 0.026, 0.84), Color("#b98c43"), 2, 14))
	margin.add_child(panel)
	var pad := _make_margin(24, 24, 20, 20)
	panel.add_child(pad)
	content_stack = VBoxContainer.new()
	content_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_stack.add_theme_constant_override("separation", 12)
	pad.add_child(content_stack)


func _add_bottom_tabs() -> void:
	var margin := _make_full_margin(85, 85, 1638, 24)
	add_child(margin)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	margin.add_child(row)
	for tab_name in ["Craft", "Gear", "Upgrades", "Enhance", "Back"]:
		var card := _make_tab_card(tab_name)
		card_buttons[tab_name] = card
		row.add_child(card)


func _make_tab_card(tab_name: String) -> Control:
	var card := Control.new()
	card.custom_minimum_size = Vector2(158, 218)
	var texture := TextureRect.new()
	texture.texture = load(String(TAB_CARDS[tab_name]))
	texture.set_anchors_preset(Control.PRESET_FULL_RECT)
	texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(texture)
	var border := PanelContainer.new()
	border.name = "ActiveBorder"
	border.set_anchors_preset(Control.PRESET_FULL_RECT)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border.add_theme_stylebox_override("panel", _make_panel_style(Color.TRANSPARENT, Color("#49cfff"), 4, 12))
	card.add_child(border)
	var button := Button.new()
	button.text = ""
	button.tooltip_text = tab_name
	button.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func() -> void:
		if tab_name == "Back":
			_on_back_pressed()
		else:
			active_tab = tab_name
			_refresh()
	)
	card.add_child(button)
	return card


func _refresh() -> void:
	stats_label.text = "Forge Level %d     Mana %d     Coins %d     Spirit %d" % [
		GameState.forge_level,
		GameState.total_mana,
		GameState.total_coins,
		GameState.sacred_pond_spirit_energy
	]
	mode_label.text = "Forge Level %d" % GameState.forge_level
	_clear_content()

	match active_tab:
		"Craft":
			_add_description("Choose a forge path, then fund its permanent upgrade from the Upgrades tab.")
			_add_forge_route_card(
				"Production Craft",
				"Flower Focus",
				"Raises Flower Grove Mana/sec so fairy gatherers have a stronger base.",
				GameState.forge_flower_focus_level,
				"Open Upgrades to forge Flower Focus."
			)
		"Gear":
			_add_description("Current forged gear bonuses.")
			_add_forge_status_board()
		"Enhance":
			_add_description("Enhance village systems by finishing forge projects.")
			_add_forge_route_card(
				"Best Next Project",
				_get_next_forge_project_title(),
				_get_next_forge_project_hint(),
				_get_next_forge_project_level(),
				_get_next_forge_project_cost()
			)
		_:
			_add_description("Spend resources on permanent upgrades that improve existing buildings.")
			current_upgrade_index = clampi(current_upgrade_index, 0, UPGRADE_IDS.size() - 1)
			_add_page_indicator(current_upgrade_index + 1, UPGRADE_IDS.size(), Color("#82d9ff"))
			var upgrade_id := String(UPGRADE_IDS[current_upgrade_index])
			content_stack.add_child(_make_upgrade_card(GameState.get_forge_upgrade_data(upgrade_id)))

	feedback_label = _make_label("", 24, Color("#82d9ff"), HORIZONTAL_ALIGNMENT_CENTER)
	content_stack.add_child(feedback_label)

	for tab_name in card_buttons.keys():
		var border := (card_buttons[tab_name] as Control).get_node("ActiveBorder") as PanelContainer
		border.visible = tab_name == active_tab
	var show_pager := active_tab == "Upgrades" and UPGRADE_IDS.size() > 1
	previous_upgrade_button.visible = show_pager
	next_upgrade_button.visible = show_pager


func _add_description(text: String) -> void:
	var label := _make_label(text, 24, Color("#fff2c6"), HORIZONTAL_ALIGNMENT_CENTER)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_stack.add_child(label)


func _add_page_indicator(current_page: int, page_count: int, color: Color) -> void:
	var label := _make_label("%d / %d" % [current_page, page_count], 18, color, HORIZONTAL_ALIGNMENT_CENTER)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	content_stack.add_child(label)


func _add_forge_status_board() -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _make_panel_style(Color(0.016, 0.026, 0.036, 0.90), Color("#82d9ff"), 2, 10))
	var margin := _make_margin(16, 16, 12, 12)
	card.add_child(margin)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 8)
	margin.add_child(rows)
	rows.add_child(_make_forge_status_row("Flower Focus", "Flower Grove Mana/sec", GameState.forge_flower_focus_level, GameState.get_flower_base_production_rate()))
	rows.add_child(_make_forge_status_row("Potion Gilding", "Mana Potion value", GameState.forge_potion_gilding_level, GameState.get_potion_sell_value()))
	rows.add_child(_make_forge_status_row("Pond Resonance", "Pond restore cost", GameState.forge_pond_resonance_level, GameState.sacred_pond_restore_cost))
	content_stack.add_child(card)


func _make_forge_status_row(title_text: String, detail: String, level: int, value) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var title := _make_label("%s  Lv %d / 3" % [title_text, level], 18, Color("#fff2c6"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	var detail_label := _make_label("%s: %s" % [detail, str(value)], 16, Color("#d9f1ff"), HORIZONTAL_ALIGNMENT_RIGHT)
	detail_label.custom_minimum_size = Vector2(260, 1)
	row.add_child(detail_label)
	return row


func _add_forge_route_card(kicker: String, title_text: String, body_text: String, level: int, footer_text: String) -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _make_panel_style(Color(0.018, 0.020, 0.030, 0.90), Color("#8d6a33"), 2, 10))
	var margin := _make_margin(16, 16, 12, 12)
	card.add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 6)
	margin.add_child(stack)
	stack.add_child(_make_label(kicker.to_upper(), 14, Color("#82d9ff"), HORIZONTAL_ALIGNMENT_CENTER))
	stack.add_child(_make_label("%s  Level %d / 3" % [title_text, level], 22, Color("#fff2c6"), HORIZONTAL_ALIGNMENT_CENTER))
	var body := _make_label(body_text, 17, Color("#e8dfca"), HORIZONTAL_ALIGNMENT_CENTER)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(body)
	stack.add_child(_make_label(footer_text, 16, Color("#f3d57a"), HORIZONTAL_ALIGNMENT_CENTER))
	content_stack.add_child(card)


func _get_next_forge_project_title() -> String:
	var best := _get_next_forge_upgrade()
	return String(best.get("Title", "All Projects Complete"))


func _get_next_forge_project_hint() -> String:
	var best := _get_next_forge_upgrade()
	if best.is_empty():
		return "Every forge path is maxed. Future systems can build on this mastered forge."
	return String(best.get("Description", "Finish another forge project to strengthen the grove."))


func _get_next_forge_project_level() -> int:
	return int(_get_next_forge_upgrade().get("Level", 3))


func _get_next_forge_project_cost() -> String:
	var best := _get_next_forge_upgrade()
	if best.is_empty():
		return "No active forge cost."
	return "Needs %s." % _format_upgrade_cost(best)


func _get_next_forge_upgrade() -> Dictionary:
	var best: Dictionary = {}
	var lowest_level := 999
	for upgrade in GameState.get_forge_upgrades():
		var level := int(upgrade.get("Level", 0))
		if level < int(upgrade.get("MaxLevel", 3)) and level < lowest_level:
			lowest_level = level
			best = upgrade
	return best


func _make_upgrade_card(upgrade: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	var upgrade_id := String(upgrade.get("UpgradeID", ""))
	var level := int(upgrade.get("Level", 0))
	var max_level := int(upgrade.get("MaxLevel", 3))
	var is_maxed := level >= max_level
	var can_forge := _can_purchase_upgrade(upgrade)
	card.name = "ForgeUpgradeCard_%s" % upgrade_id
	card.add_theme_stylebox_override("panel", _make_upgrade_card_style(can_forge, is_maxed))
	var margin := _make_margin(16, 16, 12, 12)
	card.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	margin.add_child(row)
	_add_upgrade_icon(row, upgrade_id)
	var text_stack := VBoxContainer.new()
	text_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_stack)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	text_stack.add_child(header)
	var title := _make_label("%s  Level %d / %d" % [String(upgrade.get("Title", "Upgrade")), level, max_level], 19, Color("#fff2c6"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(_make_status_pill(_get_upgrade_state_text(can_forge, is_maxed), can_forge, is_maxed, upgrade_id))

	var effect := _make_label("Effect: %s" % String(upgrade.get("Description", "")), 15, Color("#e8dfca"))
	effect.name = "ForgeUpgradeEffect_%s" % upgrade_id
	effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_stack.add_child(effect)
	text_stack.add_child(_make_label("Needs: %s" % _format_upgrade_cost(upgrade), 15, Color("#f3d57a")))

	var status_label := _make_label(_format_upgrade_status(upgrade), 15, _get_status_color(can_forge, is_maxed))
	status_label.name = "ForgeUpgradeStatus_%s" % upgrade_id
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_stack.add_child(status_label)

	var button := _make_button(_get_upgrade_button_text(can_forge, is_maxed))
	button.name = "ForgeButton_%s" % upgrade_id
	button.custom_minimum_size = Vector2(118, 54)
	button.disabled = not can_forge
	button.pressed.connect(func() -> void: _on_upgrade_pressed(upgrade_id))
	row.add_child(button)
	return card


func _add_upgrade_icon(parent: Node, upgrade_id: String) -> void:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(52, 52)
	holder.clip_contents = true
	parent.add_child(holder)
	match upgrade_id:
		"flower_focus":
			_add_icon_texture(holder, "res://assets/sprites/environment/golden_bloom.png")
		"potion_gilding":
			_add_icon_texture(holder, "res://assets/sprites/potion_shop/mana_potion_bottle.png")
		"pond_resonance":
			_add_icon_texture(holder, "res://assets/sprites/environment/spirit_stone.png")


func _format_upgrade_cost(upgrade: Dictionary) -> String:
	var parts: Array[String] = []
	if int(upgrade.get("CostMana", 0)) > 0:
		parts.append("%d Mana" % int(upgrade.get("CostMana", 0)))
	if int(upgrade.get("CostCoins", 0)) > 0:
		parts.append("%d Coins" % int(upgrade.get("CostCoins", 0)))
	if int(upgrade.get("CostSpirit", 0)) > 0:
		parts.append("%d Spirit" % int(upgrade.get("CostSpirit", 0)))
	return " + ".join(parts)


func _format_upgrade_status(upgrade: Dictionary) -> String:
	var level := int(upgrade.get("Level", 0))
	var max_level := int(upgrade.get("MaxLevel", 3))
	if level >= max_level:
		return "Max level reached."
	var missing: Array[String] = []
	var missing_mana: int = max(0, int(upgrade.get("CostMana", 0)) - GameState.total_mana)
	var missing_coins: int = max(0, int(upgrade.get("CostCoins", 0)) - GameState.total_coins)
	var missing_spirit: int = max(0, int(upgrade.get("CostSpirit", 0)) - GameState.sacred_pond_spirit_energy)
	if missing_mana > 0:
		missing.append("%d Mana" % missing_mana)
	if missing_coins > 0:
		missing.append("%d Coins" % missing_coins)
	if missing_spirit > 0:
		missing.append("%d Spirit" % missing_spirit)
	if missing.is_empty():
		return "Ready to forge."
	return "Need %s." % " + ".join(missing)


func _can_purchase_upgrade(upgrade: Dictionary) -> bool:
	if int(upgrade.get("Level", 0)) >= int(upgrade.get("MaxLevel", 3)):
		return false
	return GameState.total_mana >= int(upgrade.get("CostMana", 0)) and GameState.total_coins >= int(upgrade.get("CostCoins", 0)) and GameState.sacred_pond_spirit_energy >= int(upgrade.get("CostSpirit", 0))


func _get_upgrade_state_text(can_forge: bool, is_maxed: bool) -> String:
	if is_maxed:
		return "Maxed"
	return "Ready" if can_forge else "Missing"


func _get_upgrade_button_text(can_forge: bool, is_maxed: bool) -> String:
	if is_maxed:
		return "Maxed"
	return "Forge" if can_forge else "Need More"


func _get_status_color(can_forge: bool, is_maxed: bool) -> Color:
	if is_maxed:
		return Color("#d9f1ff")
	return Color("#82d9ff") if can_forge else Color("#ffb6a0")


func _make_status_pill(text: String, ready: bool, maxed: bool, upgrade_id: String) -> Label:
	var pill := _make_label(text, 14, Color("#102018") if ready else Color("#fff2d6"), HORIZONTAL_ALIGNMENT_CENTER)
	pill.name = "ForgeUpgradePill_%s" % upgrade_id
	pill.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pill.custom_minimum_size = Vector2(96, 34)
	pill.add_theme_stylebox_override(
		"normal",
		_make_panel_style(
			_get_pill_background(ready, maxed),
			_get_pill_border(ready, maxed),
			2,
			8
		)
	)
	return pill


func _get_pill_background(ready: bool, maxed: bool) -> Color:
	if maxed:
		return Color("#243447", 0.94)
	return Color("#82d9ff", 0.94) if ready else Color("#4a2730", 0.94)


func _get_pill_border(ready: bool, maxed: bool) -> Color:
	if maxed:
		return Color("#d9f1ff")
	return Color("#f5d66f") if ready else Color("#ff9c7d")


func _make_upgrade_card_style(ready: bool, maxed: bool) -> StyleBoxFlat:
	if maxed:
		return _make_panel_style(Color(0.026, 0.030, 0.038, 0.90), Color("#7ea6c7"), 2, 10)
	return _make_panel_style(
		Color(0.026, 0.046, 0.058, 0.92) if ready else Color(0.018, 0.020, 0.030, 0.88),
		Color("#82d9ff") if ready else Color("#8d6a33"),
		3 if ready else 2,
		10
	)


func _on_upgrade_pressed(upgrade_id: String) -> void:
	SoundManager.play_click()
	var result: Dictionary = GameState.purchase_forge_upgrade(upgrade_id)
	if feedback_label:
		feedback_label.text = String(result.get("Message", ""))
		_refresh()


func _add_upgrade_pager_buttons() -> void:
	previous_upgrade_button = _make_pager_button("^")
	previous_upgrade_button.position = Vector2(435, 1110)
	previous_upgrade_button.pressed.connect(_on_previous_upgrade_pressed)
	add_child(previous_upgrade_button)

	next_upgrade_button = _make_pager_button("v")
	next_upgrade_button.position = Vector2(435, 1436)
	next_upgrade_button.pressed.connect(_on_next_upgrade_pressed)
	add_child(next_upgrade_button)


func _make_pager_button(text: String) -> Button:
	var button := _make_button(text)
	button.size = Vector2(210, 52)
	button.custom_minimum_size = Vector2(210, 52)
	button.z_index = 80
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.focus_mode = Control.FOCUS_NONE
	return button


func _on_previous_upgrade_pressed() -> void:
	_change_upgrade_page(-1)


func _on_next_upgrade_pressed() -> void:
	_change_upgrade_page(1)


func _change_upgrade_page(direction: int) -> void:
	SoundManager.play_click()
	if UPGRADE_IDS.is_empty():
		return
	current_upgrade_index = (current_upgrade_index + direction + UPGRADE_IDS.size()) % UPGRADE_IDS.size()
	_refresh()


func _on_back_pressed() -> void:
	SoundManager.play_click()
	GameState.save_game()
	closed.emit()


func _clear_content() -> void:
	for child in content_stack.get_children():
		content_stack.remove_child(child)
		child.queue_free()


func _add_texture(parent: Node, path: String, top_left: Vector2, texture_size: Vector2) -> TextureRect:
	var texture_rect := TextureRect.new()
	texture_rect.texture = load(path)
	texture_rect.position = top_left
	texture_rect.size = texture_size
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(texture_rect)
	return texture_rect


func _add_icon_texture(parent: Node, path: String) -> TextureRect:
	var texture_rect := TextureRect.new()
	texture_rect.texture = load(path)
	texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(texture_rect)
	return texture_rect


func _make_full_margin(left: int, right: int, top: int, bottom: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_bottom", bottom)
	return margin


func _make_margin(left: int, right: int, top: int, bottom: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_bottom", bottom)
	return margin


func _make_label(text: String, font_size: int, color: Color, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = alignment
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 0)
	return label


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", Color("#fff2c6"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _make_panel_style(Color(0.025, 0.028, 0.035, 0.94), Color("#9e7332"), 2, 8))
	button.add_theme_stylebox_override("hover", _make_panel_style(Color(0.060, 0.080, 0.105, 0.98), Color("#59c7ff"), 3, 8))
	button.add_theme_stylebox_override("pressed", _make_panel_style(Color(0.10, 0.13, 0.16, 0.98), Color("#d9f1ff"), 3, 8))
	return button


func _make_panel_style(bg: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style
