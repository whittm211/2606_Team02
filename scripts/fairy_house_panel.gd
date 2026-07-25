extends PanelContainer

signal closed

var stats_label: Label
var feedback_label: Label
var fairy_cards_container: BoxContainer
var section_title: Label
var workers_button: BaseButton
var tasks_button: BaseButton
var upgrades_button: BaseButton
var active_view: String = "workers"
var task_refresh_elapsed: float = 0.0

const ASSIGN_FLOWER_TEXT := "Assign to Flower Grove"
const ASSIGN_POND_TEXT := "Assign to Sacred Pond"
const UNASSIGN_TEXT := "Unassign"
const FAIRY_PORTRAITS := {
	"Luna": "res://assets/sprites/fairy_house/fairy_luna_gatherer.png",
	"Pip": "res://assets/sprites/fairy_house/fairy_pip_pond_keeper.png",
	"Nim": "res://assets/sprites/fairy_house/fairy_nim_sleeping.png",
	"Sol": "res://assets/sprites/fairy_house/fairy_sol_gatherer.png",
	"Mira": "res://assets/sprites/fairy_house/fairy_mira_pond_keeper.png"
}

func _ready() -> void:
	if has_node("Root"):
		_bind_scene_ui()
	else:
		_build_panel()
	set_process(true)
	GameState.flower_grove_changed.connect(_refresh)
	GameState.sacred_pond_changed.connect(_refresh)
	GameState.fairy_house_changed.connect(_refresh)
	_refresh()


func _process(delta: float) -> void:
	if active_view != "tasks":
		task_refresh_elapsed = 0.0
		return
	task_refresh_elapsed += delta
	if task_refresh_elapsed >= 1.0:
		task_refresh_elapsed = 0.0
		_refresh()


func _bind_scene_ui() -> void:
	self_modulate = Color.WHITE
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())

	stats_label = get_node("Root/StatsLabel") as Label
	feedback_label = get_node("Root/FeedbackLabel") as Label
	section_title = get_node_or_null("Root/WorkersTitle") as Label
	fairy_cards_container = get_node("Root/FairyCardsScroll/FairyCardsContainer") as BoxContainer

	workers_button = get_node("Root/ActionRow/WorkersButton") as BaseButton
	tasks_button = get_node("Root/ActionRow/TasksButton") as BaseButton
	upgrades_button = get_node("Root/ActionRow/UpgradeHouseButton") as BaseButton
	var back_button := get_node("Root/ActionRow/BackButton") as BaseButton
	feedback_label.add_theme_font_size_override("font_size", 19)
	feedback_label.clip_text = true
	feedback_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	workers_button.pressed.connect(_show_workers_view)
	tasks_button.pressed.connect(_show_tasks_view)
	upgrades_button.pressed.connect(_show_upgrades_view)
	back_button.pressed.connect(_on_back_pressed)


func _build_panel() -> void:
	self_modulate = Color.WHITE
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_add_zoom_background("res://assets/sprites/fairy_house/fairy_house_interior.png")

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 58)
	margin.add_theme_constant_override("margin_right", 58)
	margin.add_theme_constant_override("margin_top", 930)
	margin.add_theme_constant_override("margin_bottom", 210)
	add_child(margin)

	var content_panel := PanelContainer.new()
	content_panel.self_modulate = Color(1, 1, 1, 0.92)
	content_panel.add_theme_stylebox_override("panel", _make_dark_panel_style())
	margin.add_child(content_panel)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	content_panel.add_child(layout)

	var title := Label.new()
	title.text = "Fairy House"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 46)
	title.add_theme_color_override("font_color", Color("#f3d57a"))
	title.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 0)
	title.visible = false
	layout.add_child(title)

	stats_label = Label.new()
	stats_label.add_theme_font_size_override("font_size", 22)
	stats_label.add_theme_color_override("font_color", Color.WHITE)
	stats_label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	stats_label.add_theme_constant_override("shadow_offset_x", 0)
	stats_label.add_theme_constant_override("shadow_offset_y", 0)
	layout.add_child(stats_label)

	var workers_title := Label.new()
	section_title = workers_title
	workers_title.text = "Fairy Workers"
	workers_title.add_theme_font_size_override("font_size", 24)
	workers_title.add_theme_color_override("font_color", Color("#f3d57a"))
	workers_title.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	workers_title.add_theme_constant_override("shadow_offset_x", 0)
	workers_title.add_theme_constant_override("shadow_offset_y", 0)
	layout.add_child(workers_title)

	var cards_scroll := ScrollContainer.new()
	cards_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	cards_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	cards_scroll.custom_minimum_size = Vector2(1, 356)
	layout.add_child(cards_scroll)

	fairy_cards_container = HBoxContainer.new()
	fairy_cards_container.add_theme_constant_override("separation", 14)
	fairy_cards_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards_scroll.add_child(fairy_cards_container)

	feedback_label = Label.new()
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.custom_minimum_size = Vector2(1, 32)
	feedback_label.add_theme_font_size_override("font_size", 19)
	feedback_label.add_theme_color_override("font_color", Color("#f3d57a"))
	feedback_label.clip_text = true
	feedback_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	layout.add_child(feedback_label)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 18)
	layout.add_child(buttons)
	workers_button = _make_button("Workers", _show_workers_view)
	tasks_button = _make_button("Tasks", _show_tasks_view)
	upgrades_button = _make_button("Upgrades", _show_upgrades_view)
	buttons.add_child(workers_button)
	buttons.add_child(tasks_button)
	buttons.add_child(upgrades_button)
	buttons.add_child(_make_button("Back", _on_back_pressed))


func _make_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(220, 76)
	button.add_theme_font_size_override("font_size", 26)
	button.pressed.connect(callback)
	return button


func _make_cottage_preview() -> Control:
	var preview := Control.new()
	preview.custom_minimum_size = Vector2(920, 330)

	_add_sprite(preview, "res://assets/sprites/ui/panel_border_ornate.png", Vector2(92, 12), Vector2(736, 292))
	_add_sprite(preview, "res://assets/sprites/buildings/fairy_house_scene.png", Vector2(330, 38), Vector2(300, 254))
	_add_sprite(preview, "res://assets/sprites/characters/fairy_luna.png", Vector2(210, 104), Vector2(86, 140))
	_add_sprite(preview, "res://assets/sprites/characters/fairy_pond_keeper.png", Vector2(624, 96), Vector2(86, 136))
	_add_sprite(preview, "res://assets/sprites/effects/glow_orb.png", Vector2(632, 130), Vector2(54, 54))

	for offset in [Vector2(224, 235), Vector2(296, 246), Vector2(370, 257), Vector2(446, 268)]:
		_add_sprite(preview, "res://assets/sprites/environment/path_straight.png", offset, Vector2(58, 58))
	for offset in [Vector2(202, 142), Vector2(665, 160), Vector2(245, 238), Vector2(632, 238)]:
		_add_sprite(preview, "res://assets/sprites/environment/purple_mushroom_cluster.png", offset, Vector2(46, 46))
	for index in range(6):
		_add_sprite(preview, "res://assets/sprites/environment/fence_post.png", Vector2(235 + index * 82, 250), Vector2(24, 54))

	return preview


func _add_sprite(parent: Node, path: String, top_left: Vector2, size: Vector2) -> Sprite2D:
	var texture := load(path)
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = top_left + size * 0.5
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if texture:
		sprite.scale = Vector2(size.x / texture.get_width(), size.y / texture.get_height())
	parent.add_child(sprite)
	return sprite


func _add_zoom_background(path: String) -> void:
	var background := TextureRect.new()
	background.texture = load(path)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)


func _make_dark_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.018, 0.028, 0.78)
	style.border_color = Color("#b98c43")
	style.set_border_width_all(2)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.content_margin_left = 26
	style.content_margin_right = 26
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	return style


func _make_card_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.018, 0.028, 0.78)
	style.border_color = Color("#b98c43")
	style.set_border_width_all(2)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	return style


func _make_tinted_card_panel_style(border_color: Color, bg_color: Color = Color(0.015, 0.018, 0.028, 0.78)) -> StyleBoxFlat:
	var style := _make_card_panel_style()
	style.border_color = border_color
	style.bg_color = bg_color
	return style


func _refresh() -> void:
	stats_label.text = (
		"Residents  %d / %d        Workers Active  %d        Resting  %d        House Level  %d"
		% [
			GameState.fairy_residents,
			GameState.fairy_max_residents,
			GameState.fairy_workers_active,
			max(0, GameState.fairy_residents - GameState.fairy_workers_active),
			GameState.fairy_house_level
		]
	)
	match active_view:
		"tasks":
			_rebuild_task_cards()
		"upgrades":
			_rebuild_upgrade_cards()
		_:
			_rebuild_fairy_cards()


func _clear_cards() -> void:
	for child in fairy_cards_container.get_children():
		child.queue_free()


func _set_section_title(text: String) -> void:
	if section_title:
		section_title.text = text


func _set_active_view(view_name: String) -> void:
	active_view = view_name
	if workers_button:
		workers_button.modulate = Color("#fff2a8") if view_name == "workers" else Color.WHITE
	if tasks_button:
		tasks_button.modulate = Color("#fff2a8") if view_name == "tasks" else Color.WHITE
	if upgrades_button:
		upgrades_button.modulate = Color("#fff2a8") if view_name == "upgrades" else Color.WHITE
	_refresh()


func _rebuild_fairy_cards() -> void:
	_set_section_title("Fairy Workers")
	_clear_cards()

	for fairy in GameState.fairies:
		if bool(fairy.get("IsUnlocked", false)):
			fairy_cards_container.add_child(_make_fairy_card(fairy))
		else:
			fairy_cards_container.add_child(_make_recruit_card(fairy))


func _rebuild_task_cards() -> void:
	_set_section_title("Fairy Tasks")
	_clear_cards()
	fairy_cards_container.add_child(_make_task_board_card())
	fairy_cards_container.add_child(_make_info_card(
		"Resting",
		"%s\n\nResting fairies keep their level and can be reassigned anytime." % _get_fairies_for_area(GameState.FAIRY_AREA_UNASSIGNED)
	))


func _rebuild_upgrade_cards() -> void:
	_set_section_title("House Upgrades")
	_clear_cards()
	fairy_cards_container.add_child(_make_info_card(
		"House Level %d" % GameState.fairy_house_level,
		"Capacity: %d fairies\nActive workers: %d\nTask Speed: %.0f%%\nRewards: %.0f%%\nXP per Task: %d" % [
			GameState.fairy_max_residents,
			GameState.fairy_workers_active,
			GameState.get_fairy_house_task_speed_multiplier() * 100.0,
			GameState.get_fairy_house_reward_multiplier() * 100.0,
			GameState.get_fairy_house_xp_gain()
		]
	))
	fairy_cards_container.add_child(_make_upgrade_card())
	fairy_cards_container.add_child(_make_info_card(
		"Training",
		"Level 5 unlocks role training. Gatherers, Pond Keepers, and Foragers get stronger at their specialty and earn extra XP."
	))


func _make_upgrade_card() -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(286, 338)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.self_modulate = Color(0.025, 0.022, 0.032, 0.98)
	card.add_theme_stylebox_override("panel", _make_tinted_card_panel_style(Color("#a8ff9b"), Color(0.025, 0.040, 0.032, 0.92)))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	card.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)

	var title := Label.new()
	title.text = "Next Upgrade"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("#a8ff9b"))
	title.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 0)
	layout.add_child(title)

	var body := Label.new()
	body.text = GameState.get_fairy_house_upgrade_summary()
	body.custom_minimum_size = Vector2(1, 190)
	body.add_theme_font_size_override("font_size", 18)
	body.add_theme_color_override("font_color", Color("#fff0c2"))
	body.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	body.add_theme_constant_override("shadow_offset_x", 0)
	body.add_theme_constant_override("shadow_offset_y", 0)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(body)

	var upgrade := Button.new()
	upgrade.text = "Upgrade"
	upgrade.custom_minimum_size = Vector2(1, 52)
	upgrade.add_theme_font_size_override("font_size", 20)
	upgrade.disabled = GameState.fairy_house_level >= GameState.FAIRY_HOUSE_MAX_LEVEL
	upgrade.pressed.connect(func() -> void:
		SoundManager.play_click()
		var result: Dictionary = GameState.upgrade_fairy_house()
		feedback_label.text = String(result.get("Message", ""))
		_show_floating_text(feedback_label.text, Vector2(260, 780), Color("#a8ff9b") if bool(result.get("Success", false)) else Color("#ff9f8a"))
		active_view = "upgrades"
		_refresh()
	)
	layout.add_child(upgrade)
	return card


func _make_info_card(title_text: String, body_text: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(286, 338)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.self_modulate = Color(0.025, 0.022, 0.032, 0.98)
	card.add_theme_stylebox_override("panel", _make_card_panel_style())

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	card.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)

	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("#f3d57a"))
	title.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 0)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(title)

	var body := Label.new()
	body.text = body_text
	body.custom_minimum_size = Vector2(1, 240)
	body.add_theme_font_size_override("font_size", 19)
	body.add_theme_color_override("font_color", Color("#fff0c2"))
	body.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	body.add_theme_constant_override("shadow_offset_x", 0)
	body.add_theme_constant_override("shadow_offset_y", 0)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(body)
	return card


func _make_task_board_card() -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(932, 338)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.self_modulate = Color(0.025, 0.022, 0.032, 0.98)
	card.add_theme_stylebox_override("panel", _make_tinted_card_panel_style(Color("#80d6ff"), Color(0.016, 0.026, 0.040, 0.94)))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	card.add_child(margin)

	var board := HBoxContainer.new()
	board.add_theme_constant_override("separation", 14)
	margin.add_child(board)

	board.add_child(_make_task_inbox_panel())

	var task_stack := VBoxContainer.new()
	task_stack.custom_minimum_size = Vector2(646, 1)
	task_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	task_stack.add_theme_constant_override("separation", 9)
	board.add_child(task_stack)

	for task in GameState.get_fairy_task_cards():
		task_stack.add_child(_make_task_summary_row(task))
	return card


func _make_task_inbox_panel() -> PanelContainer:
	var ready_count := GameState.get_total_fairy_task_ready_count()
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(220, 310)
	var border_color := Color("#f3d57a") if ready_count > 0 else Color("#80d6ff")
	var bg_color := Color(0.050, 0.038, 0.018, 0.94) if ready_count > 0 else Color(0.018, 0.030, 0.046, 0.92)
	panel.add_theme_stylebox_override("panel", _make_tinted_card_panel_style(border_color, bg_color))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 9)
	margin.add_child(layout)

	var status := Label.new()
	status.text = "REWARD INBOX"
	status.add_theme_font_size_override("font_size", 14)
	status.add_theme_color_override("font_color", Color("#f3d57a"))
	status.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	status.add_theme_constant_override("shadow_offset_x", 0)
	status.add_theme_constant_override("shadow_offset_y", 0)
	layout.add_child(status)

	var title := Label.new()
	title.text = "%d Ready" % ready_count
	title.add_theme_font_size_override("font_size", 29)
	title.add_theme_color_override("font_color", Color("#fff0c2"))
	title.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 0)
	layout.add_child(title)

	var body := Label.new()
	body.text = GameState.get_fairy_task_inbox_text()
	body.custom_minimum_size = Vector2(1, 104)
	body.add_theme_font_size_override("font_size", 16)
	body.add_theme_color_override("font_color", Color("#fff0c2"))
	body.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	body.add_theme_constant_override("shadow_offset_x", 0)
	body.add_theme_constant_override("shadow_offset_y", 0)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(body)

	var note := Label.new()
	note.text = "Collect all ready task rewards at once."
	note.custom_minimum_size = Vector2(1, 44)
	note.add_theme_font_size_override("font_size", 14)
	note.add_theme_color_override("font_color", Color("#cbbf9a"))
	note.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	note.add_theme_constant_override("shadow_offset_x", 0)
	note.add_theme_constant_override("shadow_offset_y", 0)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(note)

	var collect_all := Button.new()
	collect_all.name = "ClaimAllFairyTasksButton"
	collect_all.text = "Claim All" if ready_count <= 1 else "Claim All x%d" % ready_count
	collect_all.custom_minimum_size = Vector2(1, 48)
	collect_all.add_theme_font_size_override("font_size", 18)
	collect_all.disabled = ready_count <= 0
	collect_all.pressed.connect(func() -> void:
		SoundManager.play_collect()
		var result: Dictionary = GameState.collect_all_fairy_task_rewards()
		var message := String(result.get("Message", ""))
		feedback_label.text = message
		var float_text := String(result.get("FloatingText", message))
		var level_up_names: Array = result.get("LevelUpNames", [])
		_show_floating_text(float_text, Vector2(340, 790), Color("#f3d57a"))
		if not level_up_names.is_empty():
			_show_floating_text("%s leveled up!" % ", ".join(level_up_names), Vector2(280, 720), Color("#a8ff9b"))
		active_view = "tasks"
		_refresh()
	)
	layout.add_child(collect_all)
	return panel


func _make_task_summary_row(task: Dictionary) -> PanelContainer:
	var is_ready := bool(task.get("IsReady", false))
	var is_active := bool(task.get("IsActive", false))
	var ready_count := int(task.get("ReadyCount", 0))
	var task_id := String(task.get("TaskID", ""))
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(1, 96)
	var border_color := Color("#a8ff9b") if is_ready else Color("#80d6ff") if is_active else Color("#7f7290")
	var bg_color := Color(0.028, 0.042, 0.030, 0.93) if is_ready else Color(0.018, 0.030, 0.046, 0.92) if is_active else Color(0.020, 0.018, 0.028, 0.92)
	row.add_theme_stylebox_override("panel", _make_tinted_card_panel_style(border_color, bg_color))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	row.add_child(margin)

	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)

	var text_stack := VBoxContainer.new()
	text_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_stack.add_theme_constant_override("separation", 3)
	content.add_child(text_stack)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	text_stack.add_child(header)

	var title := Label.new()
	title.text = String(task.get("Title", "Fairy Task"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("#f3d57a"))
	title.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 0)
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	header.add_child(title)

	var status := Label.new()
	status.text = String(task.get("StatusText", "Idle")).to_upper()
	status.custom_minimum_size = Vector2(126, 1)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status.add_theme_font_size_override("font_size", 14)
	status.add_theme_color_override("font_color", Color("#a8ff9b") if is_ready else Color("#80d6ff") if is_active else Color("#cbbf9a"))
	status.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	status.add_theme_constant_override("shadow_offset_x", 0)
	status.add_theme_constant_override("shadow_offset_y", 0)
	status.clip_text = true
	header.add_child(status)

	var details := Label.new()
	details.text = "%s  |  %s" % [
		String(task.get("WorkerText", "No fairies assigned")),
		String(task.get("RewardText", ""))
	]
	details.add_theme_font_size_override("font_size", 14)
	details.add_theme_color_override("font_color", Color("#fff0c2"))
	details.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	details.add_theme_constant_override("shadow_offset_x", 0)
	details.add_theme_constant_override("shadow_offset_y", 0)
	details.clip_text = true
	details.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	text_stack.add_child(details)

	var progress_row := HBoxContainer.new()
	progress_row.add_theme_constant_override("separation", 8)
	text_stack.add_child(progress_row)

	var progress := ProgressBar.new()
	progress.min_value = 0
	progress.max_value = 100
	progress.value = int(task.get("ProgressPercent", 0))
	progress.show_percentage = true
	progress.custom_minimum_size = Vector2(1, 24)
	progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_row.add_child(progress)

	var progress_text := Label.new()
	progress_text.text = String(task.get("ProgressText", "0 / 60"))
	progress_text.custom_minimum_size = Vector2(98, 1)
	progress_text.add_theme_font_size_override("font_size", 13)
	progress_text.add_theme_color_override("font_color", Color("#d7ecff") if is_active else Color("#cbbf9a"))
	progress_text.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	progress_text.add_theme_constant_override("shadow_offset_x", 0)
	progress_text.add_theme_constant_override("shadow_offset_y", 0)
	progress_row.add_child(progress_text)

	var time_text := Label.new()
	time_text.text = String(task.get("TimeRemainingText", "Assign a fairy to begin"))
	time_text.custom_minimum_size = Vector2(138, 1)
	time_text.add_theme_font_size_override("font_size", 13)
	time_text.add_theme_color_override("font_color", Color("#d7ecff") if is_active else Color("#cbbf9a"))
	time_text.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	time_text.add_theme_constant_override("shadow_offset_x", 0)
	time_text.add_theme_constant_override("shadow_offset_y", 0)
	time_text.clip_text = true
	time_text.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	progress_row.add_child(time_text)

	var collect := Button.new()
	collect.name = "CollectFairyTaskButton_%s" % task_id
	collect.text = "Collect" if ready_count <= 1 else "Collect x%d" % ready_count
	collect.custom_minimum_size = Vector2(128, 58)
	collect.add_theme_font_size_override("font_size", 17)
	collect.disabled = ready_count <= 0
	collect.pressed.connect(func() -> void:
		SoundManager.play_collect()
		var result: Dictionary = GameState.collect_fairy_task_reward(task_id)
		var message := String(result.get("Message", ""))
		feedback_label.text = message
		var float_text := String(result.get("FloatingText", message))
		var level_up_names: Array = result.get("LevelUpNames", [])
		_show_floating_text(float_text, Vector2(340, 790), Color("#f3d57a"))
		if not level_up_names.is_empty():
			_show_floating_text("%s leveled up!" % ", ".join(level_up_names), Vector2(280, 720), Color("#a8ff9b"))
		active_view = "tasks"
		_refresh()
	)
	content.add_child(collect)
	return row


func _make_task_inbox_card() -> PanelContainer:
	var ready_count := GameState.get_total_fairy_task_ready_count()
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(270, 338)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.self_modulate = Color(0.025, 0.022, 0.032, 0.98)
	var border_color := Color("#f3d57a") if ready_count > 0 else Color("#80d6ff")
	var bg_color := Color(0.050, 0.038, 0.018, 0.94) if ready_count > 0 else Color(0.018, 0.030, 0.046, 0.92)
	card.add_theme_stylebox_override("panel", _make_tinted_card_panel_style(border_color, bg_color))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	card.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)

	var status := Label.new()
	status.text = "REWARD INBOX"
	status.add_theme_font_size_override("font_size", 15)
	status.add_theme_color_override("font_color", Color("#f3d57a"))
	status.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	status.add_theme_constant_override("shadow_offset_x", 0)
	status.add_theme_constant_override("shadow_offset_y", 0)
	layout.add_child(status)

	var title := Label.new()
	title.text = "%d Ready" % ready_count
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("#fff0c2"))
	title.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 0)
	layout.add_child(title)

	var body := Label.new()
	body.text = "%s\n\nClaim all gathers every ready mana, ingredient, and pond reward while still granting fairy XP." % GameState.get_fairy_task_inbox_text()
	body.custom_minimum_size = Vector2(1, 170)
	body.add_theme_font_size_override("font_size", 16)
	body.add_theme_color_override("font_color", Color("#fff0c2"))
	body.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	body.add_theme_constant_override("shadow_offset_x", 0)
	body.add_theme_constant_override("shadow_offset_y", 0)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(body)

	var collect_all := Button.new()
	collect_all.name = "ClaimAllFairyTasksButton"
	collect_all.text = "Claim All" if ready_count <= 1 else "Claim All x%d" % ready_count
	collect_all.custom_minimum_size = Vector2(1, 52)
	collect_all.add_theme_font_size_override("font_size", 18)
	collect_all.disabled = ready_count <= 0
	collect_all.pressed.connect(func() -> void:
		SoundManager.play_collect()
		var result: Dictionary = GameState.collect_all_fairy_task_rewards()
		var message := String(result.get("Message", ""))
		feedback_label.text = message
		var float_text := String(result.get("FloatingText", message))
		var level_up_names: Array = result.get("LevelUpNames", [])
		_show_floating_text(float_text, Vector2(340, 790), Color("#f3d57a"))
		if not level_up_names.is_empty():
			_show_floating_text("%s leveled up!" % ", ".join(level_up_names), Vector2(280, 720), Color("#a8ff9b"))
		active_view = "tasks"
		_refresh()
	)
	layout.add_child(collect_all)
	return card


func _make_task_card(task: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(270, 338)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.self_modulate = Color(0.025, 0.022, 0.032, 0.98)
	var is_ready := bool(task.get("IsReady", false))
	var is_active := bool(task.get("IsActive", false))
	var border_color := Color("#a8ff9b") if is_ready else Color("#80d6ff") if is_active else Color("#7f7290")
	var bg_color := Color(0.028, 0.042, 0.030, 0.93) if is_ready else Color(0.018, 0.030, 0.046, 0.92) if is_active else Color(0.020, 0.018, 0.028, 0.92)
	card.add_theme_stylebox_override("panel", _make_tinted_card_panel_style(border_color, bg_color))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	margin.add_child(layout)

	var status := Label.new()
	status.text = String(task.get("StatusText", "Idle")).to_upper()
	status.add_theme_font_size_override("font_size", 15)
	status.add_theme_color_override("font_color", Color("#a8ff9b") if is_ready else Color("#80d6ff") if is_active else Color("#cbbf9a"))
	status.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	status.add_theme_constant_override("shadow_offset_x", 0)
	status.add_theme_constant_override("shadow_offset_y", 0)
	layout.add_child(status)

	var title := Label.new()
	title.text = String(task.get("Title", "Fairy Task"))
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("#f3d57a"))
	title.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 0)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(title)

	var details := Label.new()
	details.text = "%s\nWorkers: %s\nReward: %s\n%s" % [
		String(task.get("Area", "")),
		String(task.get("WorkerText", "No fairies assigned")),
		String(task.get("RewardText", "")),
		String(task.get("TaskRateText", "Idle"))
	]
	details.custom_minimum_size = Vector2(1, 98)
	details.add_theme_font_size_override("font_size", 14)
	details.add_theme_color_override("font_color", Color("#fff0c2"))
	details.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	details.add_theme_constant_override("shadow_offset_x", 0)
	details.add_theme_constant_override("shadow_offset_y", 0)
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(details)

	var progress := ProgressBar.new()
	progress.min_value = 0
	progress.max_value = 100
	progress.value = int(task.get("ProgressPercent", 0))
	progress.show_percentage = true
	progress.custom_minimum_size = Vector2(1, 32)
	layout.add_child(progress)

	var progress_text := Label.new()
	progress_text.text = "%s   %s" % [
		String(task.get("ProgressText", "0 / 60 progress")),
		String(task.get("TimeRemainingText", "Assign a fairy to begin"))
	]
	progress_text.add_theme_font_size_override("font_size", 13)
	progress_text.add_theme_color_override("font_color", Color("#d7ecff") if is_active else Color("#cbbf9a"))
	progress_text.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	progress_text.add_theme_constant_override("shadow_offset_x", 0)
	progress_text.add_theme_constant_override("shadow_offset_y", 0)
	progress_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(progress_text)

	var ready_count := int(task.get("ReadyCount", 0))
	var ready := Label.new()
	ready.text = "Ready Rewards: %d" % ready_count
	ready.add_theme_font_size_override("font_size", 16)
	ready.add_theme_color_override("font_color", Color("#aeea84") if ready_count > 0 else Color("#cbbf9a"))
	ready.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	ready.add_theme_constant_override("shadow_offset_x", 0)
	ready.add_theme_constant_override("shadow_offset_y", 0)
	layout.add_child(ready)

	var collect := Button.new()
	collect.text = "Collect Reward"
	if ready_count > 1:
		collect.text = "Collect Reward x%d" % ready_count
	collect.custom_minimum_size = Vector2(1, 52)
	collect.add_theme_font_size_override("font_size", 18)
	collect.disabled = ready_count <= 0
	var task_id := String(task.get("TaskID", ""))
	collect.pressed.connect(func() -> void:
		SoundManager.play_collect()
		var result: Dictionary = GameState.collect_fairy_task_reward(task_id)
		var message := String(result.get("Message", ""))
		feedback_label.text = message
		var float_text := String(result.get("FloatingText", message))
		var level_up_names: Array = result.get("LevelUpNames", [])
		_show_floating_text(float_text, Vector2(340, 790), Color("#f3d57a"))
		if not level_up_names.is_empty():
			_show_floating_text("%s leveled up!" % ", ".join(level_up_names), Vector2(280, 720), Color("#a8ff9b"))
		active_view = "tasks"
		_refresh()
	)
	layout.add_child(collect)
	return card


func _get_fairies_for_area(area: String) -> String:
	var names: Array[String] = []
	for fairy in GameState.fairies:
		if not bool(fairy.get("IsUnlocked", false)):
			continue
		if String(fairy.get("AssignedArea", GameState.FAIRY_AREA_UNASSIGNED)) == area:
			names.append(String(fairy.get("FairyName", "Fairy")))
	if names.is_empty():
		return "No fairies assigned."
	return ", ".join(names)


func _make_fairy_card(fairy: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(286, 338)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.self_modulate = Color(0.025, 0.022, 0.032, 0.98)
	var role_color := _get_fairy_role_color(fairy)
	card.add_theme_stylebox_override("panel", _make_tinted_card_panel_style(role_color, _get_fairy_role_bg_color(fairy)))

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)

	var layout := VBoxContainer.new()
	layout.name = "Layout"
	layout.add_theme_constant_override("separation", 8)
	margin.add_child(layout)

	var assigned_area := String(fairy.get("AssignedArea", GameState.FAIRY_AREA_UNASSIGNED))
	var fairy_name := String(fairy.get("FairyName", "Fairy"))
	var content_row := HBoxContainer.new()
	content_row.name = "ContentRow"
	content_row.custom_minimum_size = Vector2(258, 238)
	content_row.add_theme_constant_override("separation", 12)
	layout.add_child(content_row)

	var portrait := Control.new()
	portrait.name = "PortraitFrame"
	portrait.custom_minimum_size = Vector2(96, 220)
	portrait.clip_contents = true
	var portrait_texture := load(_get_fairy_portrait(fairy_name)) as Texture2D
	var portrait_sprite := Sprite2D.new()
	portrait_sprite.name = "Portrait"
	portrait_sprite.texture = portrait_texture
	portrait_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	portrait_sprite.position = _get_portrait_position(fairy_name)
	if portrait_texture:
		var scale_factor: float = _get_portrait_scale(fairy_name, portrait_texture)
		portrait_sprite.scale = Vector2.ONE * scale_factor
	portrait.add_child(portrait_sprite)
	content_row.add_child(portrait)

	var details := Label.new()
	var fairy_level := int(fairy.get("FairyLevel", 1))
	var fairy_xp := int(fairy.get("FairyXP", 0))
	var xp_text := "MAX" if fairy_level >= GameState.FAIRY_MAX_LEVEL else "%d/%d" % [fairy_xp, GameState.get_fairy_xp_to_next_level(fairy)]
	details.name = "Details"
	details.text = (
		"%s\n%s\nLevel %d\nXP %s\n\n%s\n\nWorking:\n%s\n%s"
		% [
			fairy_name,
			String(fairy.get("FairyRole", "Helper")),
			fairy_level,
			xp_text,
			GameState.get_fairy_specialty_text(fairy),
			assigned_area,
			GameState.get_fairy_bonus_text(fairy)
		]
	)
	details.custom_minimum_size = Vector2(148, 220)
	details.add_theme_font_size_override("font_size", 16)
	details.add_theme_color_override("font_color", Color("#fff0c2"))
	details.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	details.add_theme_constant_override("shadow_offset_x", 0)
	details.add_theme_constant_override("shadow_offset_y", 0)
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	content_row.add_child(details)

	var buttons := HBoxContainer.new()
	buttons.name = "AssignmentButtons"
	buttons.add_theme_constant_override("separation", 6)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_child(buttons)
	buttons.add_child(_make_assignment_button("Flower", ASSIGN_FLOWER_TEXT, fairy_name, GameState.FAIRY_AREA_FLOWER_GROVE, assigned_area))
	buttons.add_child(_make_assignment_button("Pond", ASSIGN_POND_TEXT, fairy_name, GameState.FAIRY_AREA_SACRED_POND, assigned_area))
	buttons.add_child(_make_assignment_button("Rest", UNASSIGN_TEXT, fairy_name, GameState.FAIRY_AREA_UNASSIGNED, assigned_area))

	return card


func _make_recruit_card(fairy: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(286, 338)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.self_modulate = Color(0.025, 0.022, 0.032, 0.98)
	card.add_theme_stylebox_override("panel", _make_tinted_card_panel_style(Color("#7f7290"), Color(0.020, 0.018, 0.028, 0.94)))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	margin.add_child(layout)

	var fairy_name := String(fairy.get("FairyName", "Fairy"))

	var content_row := HBoxContainer.new()
	content_row.name = "ContentRow"
	content_row.custom_minimum_size = Vector2(258, 220)
	content_row.add_theme_constant_override("separation", 12)
	layout.add_child(content_row)

	var portrait := Control.new()
	portrait.name = "PortraitFrame"
	portrait.custom_minimum_size = Vector2(96, 220)
	portrait.clip_contents = true
	var portrait_texture := load(_get_fairy_portrait(fairy_name)) as Texture2D
	var portrait_sprite := Sprite2D.new()
	portrait_sprite.name = "Portrait"
	portrait_sprite.texture = portrait_texture
	portrait_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	portrait_sprite.position = _get_portrait_position(fairy_name)
	if portrait_texture:
		var scale_factor: float = _get_portrait_scale(fairy_name, portrait_texture)
		portrait_sprite.scale = Vector2.ONE * scale_factor
	portrait.add_child(portrait_sprite)
	content_row.add_child(portrait)

	var details := Label.new()
	details.name = "Details"
	details.text = "%s\nRecruit\n\n%s\nLevel 1\n\n%s\n\nCost:\n%s" % [
		fairy_name,
		String(fairy.get("FairyRole", "Helper")),
		GameState.get_fairy_specialty_text(fairy),
		GameState.get_fairy_recruit_cost_text(fairy_name)
	]
	details.custom_minimum_size = Vector2(148, 220)
	details.add_theme_font_size_override("font_size", 16)
	details.add_theme_color_override("font_color", Color("#fff0c2"))
	details.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	details.add_theme_constant_override("shadow_offset_x", 0)
	details.add_theme_constant_override("shadow_offset_y", 0)
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	content_row.add_child(details)

	var recruit := Button.new()
	recruit.text = "Recruit"
	recruit.custom_minimum_size = Vector2(1, 48)
	recruit.add_theme_font_size_override("font_size", 18)
	recruit.disabled = not GameState.can_recruit_fairy(fairy_name)
	recruit.pressed.connect(func() -> void:
		SoundManager.play_click()
		var result: Dictionary = GameState.recruit_fairy(fairy_name)
		feedback_label.text = String(result.get("Message", ""))
		_show_floating_text(feedback_label.text, Vector2(260, 780), Color("#a8ff9b") if bool(result.get("Success", false)) else Color("#ff9f8a"))
		active_view = "workers"
		_refresh()
	)
	layout.add_child(recruit)
	return card


func _get_portrait_position(fairy_name: String) -> Vector2:
	match fairy_name:
		"Luna":
			return Vector2(48, 112)
		"Pip":
			return Vector2(48, 114)
		"Nim":
			return Vector2(48, 108)
	return Vector2(48, 110)


func _get_portrait_scale(fairy_name: String, texture: Texture2D) -> float:
	var frame_size := Vector2(96, 220)
	var base_scale: float = min(frame_size.x / texture.get_width(), frame_size.y / texture.get_height())
	match fairy_name:
		"Nim":
			return base_scale * 1.65
		_:
			return base_scale * 1.18


func _make_assignment_button(text: String, tooltip: String, fairy_name: String, area: String, assigned_area: String) -> Button:
	var button := Button.new()
	button.text = text
	button.tooltip_text = tooltip
	button.custom_minimum_size = Vector2(72, 38)
	button.add_theme_font_size_override("font_size", 14)
	button.disabled = area == assigned_area
	button.pressed.connect(func() -> void:
		SoundManager.play_click()
		feedback_label.text = GameState.assign_fairy_to_area(fairy_name, area)
		_show_floating_text(feedback_label.text, Vector2(290, 790), Color("#a8ff9b"))
		active_view = "workers"
		_refresh()
	)
	return button


func _get_fairy_portrait(fairy_name: String) -> String:
	return String(FAIRY_PORTRAITS.get(fairy_name, "res://assets/sprites/characters/fairy_placeholder.png"))


func _show_workers_view() -> void:
	SoundManager.play_click()
	feedback_label.text = ""
	_set_active_view("workers")


func _show_tasks_view() -> void:
	SoundManager.play_click()
	feedback_label.text = "Task summary updated."
	_set_active_view("tasks")


func _show_upgrades_view() -> void:
	SoundManager.play_click()
	feedback_label.text = "House upgrade plan shown."
	_set_active_view("upgrades")


func _get_fairy_role_color(fairy: Dictionary) -> Color:
	var role := String(fairy.get("FairyRole", "Helper"))
	if role == "Gatherer":
		return Color("#f3d57a")
	if role == "Pond Keeper":
		return Color("#80d6ff")
	if role == "Forager":
		return Color("#c784ff")
	return Color("#b98c43")


func _get_fairy_role_bg_color(fairy: Dictionary) -> Color:
	var role := String(fairy.get("FairyRole", "Helper"))
	if role == "Gatherer":
		return Color(0.070, 0.050, 0.020, 0.90)
	if role == "Pond Keeper":
		return Color(0.020, 0.045, 0.070, 0.90)
	if role == "Forager":
		return Color(0.055, 0.030, 0.075, 0.90)
	return Color(0.015, 0.018, 0.028, 0.90)


func _show_floating_text(text: String, start_position: Vector2, color: Color) -> void:
	if text == "":
		return
	var label := Label.new()
	label.text = text
	label.position = start_position
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 0)
	add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "position", start_position + Vector2(0, -86), 0.78)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.78)
	tween.tween_callback(label.queue_free)


func _on_back_pressed() -> void:
	SoundManager.play_click()
	GameState.save_game()
	closed.emit()
