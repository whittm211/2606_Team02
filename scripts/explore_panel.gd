extends PanelContainer

signal closed

var feedback_label: Label
var status_label: Label
var location_list: VBoxContainer
var selected_location_id: String = ""
var last_ready_state: bool = false
var last_active_state: bool = false

func _ready() -> void:
	self_modulate = Color(0.015, 0.02, 0.04, 0.94)
	_build_ui()
	GameState.resources_changed.connect(_refresh_locations)


func _process(_delta: float) -> void:
	_update_status_text()

	var ready_now := GameState.is_exploration_ready()
	var active_now := GameState.exploration_active
	if ready_now != last_ready_state or active_now != last_active_state:
		last_ready_state = ready_now
		last_active_state = active_now
		_refresh_locations()


func _update_status_text() -> void:
	if status_label == null:
		return
	if not GameState.exploration_active:
		status_label.text = "No fairies are out exploring."
		status_label.add_theme_color_override("font_color", Color("#c9b78a"))
		return
	if GameState.is_exploration_ready():
		status_label.text = "%s complete! Collect your reward." % GameState.get_active_exploration_name()
		status_label.add_theme_color_override("font_color", Color("#9fe0a0"))
		return
	var seconds := GameState.get_exploration_time_remaining()
	status_label.text = "Exploring %s - %02d:%02d remaining" % [GameState.get_active_exploration_name(), seconds / 60, seconds % 60]
	status_label.add_theme_color_override("font_color", Color("#f5d66f"))


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 52)
	margin.add_theme_constant_override("margin_right", 52)
	margin.add_theme_constant_override("margin_top", 170)
	margin.add_theme_constant_override("margin_bottom", 210)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 22)
	margin.add_child(layout)

	var title := _make_label("Explore", 48, Color("#f5d66f"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(title)

	var description := _make_label("Send fairies beyond the grove to discover resources and hidden magic.", 28, Color("#fff2d6"))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(description)

	status_label = _make_label("", 28, Color("#f5d66f"))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(status_label)

	location_list = VBoxContainer.new()
	location_list.add_theme_constant_override("separation", 16)
	layout.add_child(location_list)

	feedback_label = _make_label("", 26, Color("#f5d66f"))
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(feedback_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(1, 30)
	layout.add_child(spacer)

	var button_row := HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 22)
	layout.add_child(button_row)

	var begin_button := _make_button("Begin Exploration")
	begin_button.pressed.connect(_on_begin_pressed)
	button_row.add_child(begin_button)

	var back_button := _make_button("Back")
	back_button.pressed.connect(func(): SoundManager.play_click(); closed.emit())
	button_row.add_child(back_button)

	_update_status_text()
	_refresh_locations()


func _refresh_locations() -> void:
	if location_list == null:
		return
	for child in location_list.get_children():
		child.queue_free()

	if GameState.is_exploration_ready():
		location_list.add_child(_make_collect_card())
		return

	for data in GameState.get_exploration_locations():
		location_list.add_child(_make_location_card(data))


func _make_collect_card() -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _make_style(Color(0.03, 0.05, 0.04, 0.9), Color("#9fe0a0"), 3, 10))

	var card_margin := MarginContainer.new()
	card_margin.add_theme_constant_override("margin_left", 26)
	card_margin.add_theme_constant_override("margin_right", 26)
	card_margin.add_theme_constant_override("margin_top", 20)
	card_margin.add_theme_constant_override("margin_bottom", 20)
	card.add_child(card_margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	card_margin.add_child(col)

	col.add_child(_make_label("The fairies have returned!", 30, Color("#9fe0a0")))
	col.add_child(_make_label("Collect your reward to send them out again.", 24, Color("#e8dfca")))

	var collect_button := _make_small_button("Collect Reward")
	collect_button.custom_minimum_size = Vector2(260, 58)
	collect_button.pressed.connect(_on_collect_pressed)
	col.add_child(collect_button)

	return card


func _make_location_card(data: Dictionary) -> PanelContainer:
	var location_id := String(data.get("LocationID", ""))
	var unlocked := GameState.is_exploration_unlocked(location_id)
	var is_selected := location_id == selected_location_id and unlocked

	var border_color := Color("#b99245")
	if is_selected:
		border_color = Color("#ffe08a")

	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _make_style(Color(0.03, 0.035, 0.055, 0.88), border_color, 3 if is_selected else 2, 10))

	var card_margin := MarginContainer.new()
	card_margin.add_theme_constant_override("margin_left", 26)
	card_margin.add_theme_constant_override("margin_right", 26)
	card_margin.add_theme_constant_override("margin_top", 16)
	card_margin.add_theme_constant_override("margin_bottom", 16)
	card.add_child(card_margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	card_margin.add_child(col)

	var name_color := Color("#fff2a8")
	if not unlocked:
		name_color = Color("#8f8a7c")
	col.add_child(_make_label(String(data.get("Name", "Location")), 30, name_color))

	if unlocked:
		var minutes := int(data.get("DurationSeconds", 0)) / 60
		var reward_min := int(data.get("RewardCoinsMin", 0))
		var reward_max := int(data.get("RewardCoinsMax", 0))
		var reward_text := "%d Coins" % reward_min
		if reward_max != reward_min:
			reward_text = "%d-%d Coins" % [reward_min, reward_max]
		col.add_child(_make_label("Cost: %d Mana   Time: %d min   Reward: %s" % [int(data.get("CostMana", 0)), minutes, reward_text], 22, Color("#e8dfca")))

		if GameState.exploration_active:
			col.add_child(_make_label("Fairies are already out.", 22, Color("#c9b78a")))
		else:
			var tap_button := _make_small_button("Selected" if is_selected else "Select")
			tap_button.disabled = is_selected
			tap_button.pressed.connect(func() -> void:
				SoundManager.play_click()
				selected_location_id = location_id
				feedback_label.text = "%s selected." % String(data.get("Name", "Location"))
				_refresh_locations()
			)
			col.add_child(tap_button)
	else:
		col.add_child(_make_label("Locked - reach level %d in Flower Grove and Potion Shop." % int(data.get("UnlockLevel", 0)), 22, Color("#c9a86a")))

	return card


func _on_begin_pressed() -> void:
	SoundManager.play_click()
	if GameState.exploration_active:
		feedback_label.text = "An exploration is already underway."
		return
	if selected_location_id == "":
		feedback_label.text = "Select a location first."
		return
	var result := GameState.start_exploration(selected_location_id)
	feedback_label.text = String(result.get("Message", ""))
	_refresh_locations()


func _on_collect_pressed() -> void:
	SoundManager.play_collect()
	var result := GameState.claim_exploration_reward()
	feedback_label.text = String(result.get("Message", ""))
	selected_location_id = ""
	_refresh_locations()


func _make_label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 0)
	return label


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(300, 78)
	button.add_theme_font_size_override("font_size", 26)
	button.add_theme_stylebox_override("normal", _make_style(Color(0.02, 0.025, 0.04, 0.96), Color("#b99245"), 2, 8))
	button.add_theme_stylebox_override("hover", _make_style(Color(0.06, 0.07, 0.09, 0.96), Color("#f0cf76"), 3, 8))
	button.add_theme_stylebox_override("pressed", _make_style(Color(0.12, 0.10, 0.06, 0.98), Color("#ffe08a"), 3, 8))
	button.add_theme_color_override("font_color", Color("#fff2a8"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	return button


func _make_small_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(200, 52)
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_stylebox_override("normal", _make_style(Color(0.02, 0.025, 0.04, 0.96), Color("#b99245"), 2, 8))
	button.add_theme_stylebox_override("hover", _make_style(Color(0.06, 0.07, 0.09, 0.96), Color("#f0cf76"), 3, 8))
	button.add_theme_stylebox_override("pressed", _make_style(Color(0.12, 0.10, 0.06, 0.98), Color("#ffe08a"), 3, 8))
	button.add_theme_color_override("font_color", Color("#fff2a8"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	return button


func _make_style(bg: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_right = border_width
	style.border_width_top = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style
