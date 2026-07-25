extends Control

signal closed

const BG_PATH := "res://assets/sprites/market_stall/market_stall_background.png"
const ORDER_IDS := ["mana_bundle", "potion_crate", "spirit_contract"]
const TAB_CARDS := {
	"Trade": "res://assets/sprites/market_stall/market_trade_card.png",
	"Orders": "res://assets/sprites/market_stall/market_orders_card.png",
	"Upgrades": "res://assets/sprites/market_stall/market_upgrades_card.png",
	"Storage": "res://assets/sprites/market_stall/market_storage_card.png",
	"Back": "res://assets/sprites/market_stall/market_back_card.png"
}

var active_tab := "Trade"
var stats_label: Label
var level_label: Label
var content_stack: VBoxContainer
var feedback_label: Label
var card_buttons: Dictionary = {}
var current_order_index := 0
var previous_order_button: Button
var next_order_button: Button


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_panel()
	GameState.resources_changed.connect(_refresh)
	GameState.market_stall_changed.connect(_refresh)
	GameState.potion_shop_changed.connect(_refresh)
	GameState.sacred_pond_changed.connect(_refresh)
	_refresh()


func _build_panel() -> void:
	_add_background()
	_add_top_bar()
	_add_title_header()
	_add_mode_panel()
	_add_bottom_tabs()
	_add_order_pager_buttons()


func _add_background() -> void:
	var background := TextureRect.new()
	background.texture = load(BG_PATH)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.16)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)


func _add_top_bar() -> void:
	var margin := _make_full_margin(72, 72, 24, 1785)
	add_child(margin)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.030, 0.018, 0.014, 0.80), Color("#d8a35a"), 2, 12))
	margin.add_child(panel)
	stats_label = _make_label("", 24, Color("#fff1bf"), HORIZONTAL_ALIGNMENT_CENTER)
	stats_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(stats_label)


func _add_title_header() -> void:
	var margin := _make_full_margin(144, 144, 108, 1600)
	add_child(margin)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.030, 0.018, 0.014, 0.66), Color("#d8a35a"), 2, 14))
	margin.add_child(panel)

	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 0)
	panel.add_child(stack)

	var title := _make_label("Market Stall", 54, Color("#ffe2a0"), HORIZONTAL_ALIGNMENT_CENTER)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_outline_color", Color("#1a1008"))
	title.add_theme_constant_override("outline_size", 2)
	stack.add_child(title)

	level_label = _make_label("", 25, Color("#f8ffce"), HORIZONTAL_ALIGNMENT_CENTER)
	level_label.name = "MarketLevelLabel"
	level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stack.add_child(level_label)


func _add_mode_panel() -> void:
	var margin := _make_full_margin(122, 122, 1248, 360)
	add_child(margin)
	var panel := PanelContainer.new()
	panel.clip_contents = true
	panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.070, 0.038, 0.022, 0.68), Color("#c9954e"), 2, 14))
	margin.add_child(panel)
	var pad := _make_margin(22, 22, 16, 16)
	panel.add_child(pad)
	content_stack = VBoxContainer.new()
	content_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_stack.add_theme_constant_override("separation", 10)
	pad.add_child(content_stack)


func _add_bottom_tabs() -> void:
	var margin := _make_full_margin(85, 85, 1638, 24)
	add_child(margin)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	margin.add_child(row)
	for tab_name in ["Trade", "Orders", "Upgrades", "Storage", "Back"]:
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
	border.add_theme_stylebox_override("panel", _make_panel_style(Color.TRANSPARENT, Color("#78e071"), 4, 12))
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
	stats_label.text = "Reputation %d     Orders %d     Coins %d     Mana %d     Potions %d" % [
		GameState.market_reputation,
		GameState.market_orders_completed,
		GameState.total_coins,
		GameState.total_mana,
		GameState.mana_potion_count
	]
	level_label.text = "Orders Completed %d" % GameState.market_orders_completed
	_clear_content()

	match active_tab:
		"Trade", "Orders":
			_add_banner("Fill village orders to earn Coins and reputation.")
			current_order_index = clampi(current_order_index, 0, ORDER_IDS.size() - 1)
			_add_page_indicator(current_order_index + 1, ORDER_IDS.size(), Color("#99e8ac"))
			var order_id := String(ORDER_IDS[current_order_index])
			content_stack.add_child(_make_order_card(GameState.get_market_order_data(order_id)))
		"Upgrades":
			_add_banner("Market reputation unlocks better routes and funds Forge work.")
			_add_market_progress_card()
		"Storage":
			_add_banner("Stored trade goods ready for village orders.")
			_add_market_storage_card()

	feedback_label = _make_label("", 24, Color("#99e8ac"), HORIZONTAL_ALIGNMENT_CENTER)
	content_stack.add_child(feedback_label)

	for tab_name in card_buttons.keys():
		var border := (card_buttons[tab_name] as Control).get_node("ActiveBorder") as PanelContainer
		border.visible = tab_name == active_tab
	var show_pager := active_tab in ["Trade", "Orders"] and ORDER_IDS.size() > 1
	previous_order_button.visible = show_pager
	next_order_button.visible = show_pager


func _add_banner(text: String) -> void:
	var label := _make_label(text, 21, Color("#ffe5aa"), HORIZONTAL_ALIGNMENT_CENTER)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_stack.add_child(label)


func _add_page_indicator(current_page: int, page_count: int, color: Color) -> void:
	var label := _make_label("%d / %d" % [current_page, page_count], 17, color, HORIZONTAL_ALIGNMENT_CENTER)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	content_stack.add_child(label)


func _add_market_progress_card() -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _make_panel_style(Color(0.060, 0.036, 0.022, 0.74), Color("#e9c46a"), 2, 10))
	var margin := _make_margin(16, 16, 12, 12)
	card.add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	margin.add_child(stack)
	stack.add_child(_make_market_row("Reputation", str(GameState.market_reputation), "Raises village trust."))
	stack.add_child(_make_market_row("Orders Completed", str(GameState.market_orders_completed), _get_market_rank_text()))
	stack.add_child(_make_market_row("Best Next Trade", _get_best_market_order_title(), _get_best_market_order_hint()))
	content_stack.add_child(card)


func _add_market_storage_card() -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _make_panel_style(Color(0.060, 0.036, 0.022, 0.74), Color("#c9954e"), 2, 10))
	var margin := _make_margin(16, 16, 12, 12)
	card.add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	margin.add_child(stack)
	stack.add_child(_make_market_row("Mana", str(GameState.total_mana), "Used for Mana Bundle trades."))
	stack.add_child(_make_market_row("Mana Potions", str(GameState.mana_potion_count), "Used for Potion Crate trades."))
	stack.add_child(_make_market_row("Spirit Energy", str(GameState.sacred_pond_spirit_energy), "Used for Spirit Contract trades."))
	content_stack.add_child(card)


func _make_market_row(label_text: String, value_text: String, detail_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	left.add_child(_make_label(label_text, 17, Color("#ffe7af")))
	var detail := _make_label(detail_text, 14, Color("#f0ddbd"))
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(detail)
	var value := _make_label(value_text, 22, Color("#99e8ac"), HORIZONTAL_ALIGNMENT_RIGHT)
	value.custom_minimum_size = Vector2(130, 1)
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(value)
	return row


func _get_market_rank_text() -> String:
	if GameState.market_orders_completed >= 15:
		return "Master trader tier reached."
	if GameState.market_orders_completed >= 5:
		return "Trusted route tier active. Push toward master contracts."
	return "Complete 5 orders to feel like a trusted village trader."


func _get_best_market_order_title() -> String:
	var best := _get_best_market_order()
	return String(best.get("Title", "Mana Bundle"))


func _get_best_market_order_hint() -> String:
	var best := _get_best_market_order()
	if _can_fulfill_order(best):
		return "Ready now. Trade it for %d Coins." % int(best.get("RewardCoins", 0))
	return _format_order_status(best)


func _get_best_market_order() -> Dictionary:
	var best: Dictionary = {}
	var best_reward := -1
	for order_id in ORDER_IDS:
		var order := GameState.get_market_order_data(String(order_id))
		var reward := int(order.get("RewardCoins", 0))
		if _can_fulfill_order(order) and reward > best_reward:
			best_reward = reward
			best = order
	if not best.is_empty():
		return best
	for order_id in ORDER_IDS:
		var order := GameState.get_market_order_data(String(order_id))
		var reward := int(order.get("RewardCoins", 0))
		if reward > best_reward:
			best_reward = reward
			best = order
	return best


func _make_order_card(order: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	var order_id := String(order.get("OrderID", ""))
	var can_trade := _can_fulfill_order(order)
	card.name = "MarketOrderCard_%s" % order_id
	card.add_theme_stylebox_override("panel", _make_order_card_style(can_trade))
	var margin := _make_margin(14, 14, 10, 10)
	card.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)
	_add_order_icon(row, order_id)
	var text_stack := VBoxContainer.new()
	text_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_stack)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	text_stack.add_child(header)
	var title := _make_label(String(order.get("Title", "Order")), 19, Color("#ffe7af"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(_make_status_pill("Ready" if can_trade else "Missing", can_trade, order_id))

	var desc := _make_label(String(order.get("Description", "")), 14, Color("#f0ddbd"))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_stack.add_child(desc)
	text_stack.add_child(_make_label("Needs: %s" % _format_order_cost(order), 14, Color("#eac46e")))
	text_stack.add_child(_make_label("Pays: %d Coins + %d Reputation" % [
		int(order.get("RewardCoins", 0)),
		int(order.get("ReputationReward", 0))
	], 14, Color("#eac46e")))

	var status_label := _make_label(_format_order_status(order), 14, Color("#d8f0b3") if can_trade else Color("#ffb6a0"))
	status_label.name = "MarketOrderStatus_%s" % order_id
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_stack.add_child(status_label)

	var button := _make_button("Trade" if can_trade else "Need More")
	button.name = "TradeButton_%s" % order_id
	button.custom_minimum_size = Vector2(118, 54)
	button.disabled = not can_trade
	button.pressed.connect(func() -> void: _on_order_pressed(order_id))
	row.add_child(button)
	return card


func _add_order_icon(parent: Node, order_id: String) -> void:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(52, 52)
	holder.clip_contents = true
	parent.add_child(holder)
	match order_id:
		"mana_bundle":
			_add_icon_texture(holder, "res://assets/sprites/potion_shop/mana_crystal.png")
		"potion_crate":
			_add_icon_texture(holder, "res://assets/sprites/potion_shop/mana_potion_bottle.png")
		"spirit_contract":
			_add_icon_texture(holder, "res://assets/sprites/effects/glow_orb.png")


func _format_order_cost(order: Dictionary) -> String:
	var parts: Array[String] = []
	if int(order.get("CostMana", 0)) > 0:
		parts.append("%d Mana" % int(order.get("CostMana", 0)))
	if int(order.get("CostPotions", 0)) > 0:
		parts.append("%d Potion" % int(order.get("CostPotions", 0)))
	if int(order.get("CostSpirit", 0)) > 0:
		parts.append("%d Spirit" % int(order.get("CostSpirit", 0)))
	return " + ".join(parts) if parts.size() > 0 else "Free"


func _format_order_status(order: Dictionary) -> String:
	var missing: Array[String] = []
	var missing_mana: int = max(0, int(order.get("CostMana", 0)) - GameState.total_mana)
	var missing_potions: int = max(0, int(order.get("CostPotions", 0)) - GameState.mana_potion_count)
	var missing_spirit: int = max(0, int(order.get("CostSpirit", 0)) - GameState.sacred_pond_spirit_energy)
	if missing_mana > 0:
		missing.append("%d Mana" % missing_mana)
	if missing_potions > 0:
		missing.append("%d Mana Potion" % missing_potions)
	if missing_spirit > 0:
		missing.append("%d Spirit" % missing_spirit)
	if missing.is_empty():
		return "Ready to trade."
	return "Need %s." % " + ".join(missing)


func _can_fulfill_order(order: Dictionary) -> bool:
	return GameState.total_mana >= int(order.get("CostMana", 0)) and GameState.mana_potion_count >= int(order.get("CostPotions", 0)) and GameState.sacred_pond_spirit_energy >= int(order.get("CostSpirit", 0))


func _make_status_pill(text: String, ready: bool, order_id: String) -> Label:
	var pill := _make_label(text, 13, Color("#2b1b0e") if ready else Color("#fff2d6"), HORIZONTAL_ALIGNMENT_CENTER)
	pill.name = "MarketOrderPill_%s" % order_id
	pill.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pill.custom_minimum_size = Vector2(96, 34)
	pill.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	pill.add_theme_constant_override("shadow_offset_x", 0)
	pill.add_theme_constant_override("shadow_offset_y", 0)
	pill.add_theme_stylebox_override(
		"normal",
		_make_panel_style(
			Color("#f4d36d", 0.94) if ready else Color("#4a2730", 0.90),
			Color("#fff0aa") if ready else Color("#ff9c7d"),
			2,
			8
		)
	)
	return pill


func _make_order_card_style(ready: bool) -> StyleBoxFlat:
	return _make_panel_style(
		Color(0.095, 0.058, 0.034, 0.72) if ready else Color(0.060, 0.036, 0.022, 0.64),
		Color("#e9c46a") if ready else Color("#9f7436"),
		3 if ready else 2,
		10
	)


func _on_order_pressed(order_id: String) -> void:
	SoundManager.play_click()
	var result: Dictionary = GameState.fulfill_market_order(order_id)
	if feedback_label:
		feedback_label.text = String(result.get("Message", ""))
		_refresh()


func _add_order_pager_buttons() -> void:
	previous_order_button = _make_pager_button("^")
	previous_order_button.position = Vector2(435, 1232)
	previous_order_button.pressed.connect(_on_previous_order_pressed)
	add_child(previous_order_button)

	next_order_button = _make_pager_button("v")
	next_order_button.position = Vector2(435, 1556)
	next_order_button.pressed.connect(_on_next_order_pressed)
	add_child(next_order_button)


func _make_pager_button(text: String) -> Button:
	var button := _make_button(text)
	button.size = Vector2(210, 50)
	button.custom_minimum_size = Vector2(210, 50)
	button.z_index = 80
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.focus_mode = Control.FOCUS_NONE
	return button


func _on_previous_order_pressed() -> void:
	_change_order_page(-1)


func _on_next_order_pressed() -> void:
	_change_order_page(1)


func _change_order_page(direction: int) -> void:
	SoundManager.play_click()
	if ORDER_IDS.is_empty():
		return
	current_order_index = (current_order_index + direction + ORDER_IDS.size()) % ORDER_IDS.size()
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
	button.add_theme_stylebox_override("normal", _make_panel_style(Color(0.095, 0.052, 0.032, 0.94), Color("#c9954e"), 2, 8))
	button.add_theme_stylebox_override("hover", _make_panel_style(Color(0.140, 0.082, 0.046, 0.98), Color("#ffe28f"), 3, 8))
	button.add_theme_stylebox_override("pressed", _make_panel_style(Color(0.18, 0.10, 0.06, 0.98), Color("#fff5bd"), 3, 8))
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
