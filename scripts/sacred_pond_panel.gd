extends PanelContainer

signal closed
signal decorate_requested

var stats_label: Label
var feedback_label: Label
var pond_preview: CanvasItem
var decoration_preview_layer: Control
var stat_value_labels: Dictionary = {}
var purity_progress: ProgressBar
var bonus_summary_label: Label

const PANEL_BUTTONS := {
	"Back": "res://assets/sprites/ui/panel_back.png",
	"Decorate": "res://assets/sprites/ui/panel_decorate.png",
	"Restore": "res://assets/sprites/ui/panel_restore.png",
}

func _ready() -> void:
	if has_node("Root"):
		_bind_scene_ui()
	else:
		_build_panel()
	_build_decoration_preview_layer()
	GameState.sacred_pond_changed.connect(_refresh)
	GameState.resources_changed.connect(_refresh)
	_refresh()


func _bind_scene_ui() -> void:
	self_modulate = Color.WHITE
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())

	stats_label = get_node("Root/StatsLabel") as Label
	feedback_label = get_node("Root/FeedbackLabel") as Label
	pond_preview = get_node_or_null("Root/PondBackground") as CanvasItem
	_polish_bound_scene_layout()

	var restore_button := get_node("Root/ActionRow/RestoreButton") as TextureButton
	var decorate_button := get_node("Root/ActionRow/DecorateButton") as TextureButton
	var back_button := get_node("Root/ActionRow/BackButton") as TextureButton
	restore_button.pressed.connect(_on_restore_pressed)
	decorate_button.pressed.connect(_on_decorate_pressed)
	back_button.pressed.connect(_on_back_pressed)


func _polish_bound_scene_layout() -> void:
	var root := get_node("Root") as Control
	var stats_background := root.get_node_or_null("StatsPanelBackground") as Control
	if stats_background:
		stats_background.position = Vector2(54, 1186)
		stats_background.size = Vector2(972, 326)
	if stats_label:
		stats_label.visible = false
	if feedback_label:
		feedback_label.position = Vector2(98, 1528)
		feedback_label.size = Vector2(884, 56)
		feedback_label.add_theme_font_size_override("font_size", 26)

	var action_background := root.get_node_or_null("ActionBarBackground") as Control
	if action_background:
		action_background.position = Vector2(54, 1610)
		action_background.size = Vector2(972, 164)
	var action_row := root.get_node_or_null("ActionRow") as HBoxContainer
	if action_row:
		action_row.position = Vector2(74, 1628)
		action_row.size = Vector2(932, 130)
		action_row.add_theme_constant_override("separation", 18)

	if root.get_node_or_null("PondStatusCards") == null:
		_build_status_cards(root)


func _build_status_cards(root: Control) -> void:
	stat_value_labels.clear()
	var cards_layer := Control.new()
	cards_layer.name = "PondStatusCards"
	cards_layer.position = Vector2(78, 1208)
	cards_layer.size = Vector2(924, 282)
	cards_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(cards_layer)

	var row := HBoxContainer.new()
	row.position = Vector2.ZERO
	row.size = Vector2(924, 118)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	cards_layer.add_child(row)
	row.add_child(_make_stat_card("Water Purity", "purity", Vector2(296, 118)))
	row.add_child(_make_stat_card("Spirit Energy", "spirit", Vector2(296, 118)))
	row.add_child(_make_stat_card("Pond Beauty", "beauty", Vector2(296, 118)))

	purity_progress = ProgressBar.new()
	purity_progress.name = "PurityProgress"
	purity_progress.position = Vector2(14, 134)
	purity_progress.size = Vector2(896, 24)
	purity_progress.max_value = 100
	purity_progress.show_percentage = false
	purity_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	purity_progress.add_theme_stylebox_override("background", _make_progress_style(Color(0.01, 0.03, 0.06, 0.85), Color("#23536a")))
	purity_progress.add_theme_stylebox_override("fill", _make_progress_style(Color("#5ad9ff"), Color("#d8fbff")))
	cards_layer.add_child(purity_progress)

	var summary_panel := PanelContainer.new()
	summary_panel.name = "PondSummaryPanel"
	summary_panel.position = Vector2(14, 170)
	summary_panel.size = Vector2(896, 104)
	summary_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	summary_panel.add_theme_stylebox_override("panel", _make_dark_panel_style(0.62))
	cards_layer.add_child(summary_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	summary_panel.add_child(margin)

	bonus_summary_label = Label.new()
	bonus_summary_label.name = "BonusSummary"
	bonus_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bonus_summary_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bonus_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bonus_summary_label.add_theme_font_size_override("font_size", 20)
	bonus_summary_label.add_theme_color_override("font_color", Color("#fff4cf"))
	bonus_summary_label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	bonus_summary_label.add_theme_constant_override("shadow_offset_x", 0)
	bonus_summary_label.add_theme_constant_override("shadow_offset_y", 0)
	margin.add_child(bonus_summary_label)


func _make_stat_card(title_text: String, key: String, card_size: Vector2) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = card_size
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", _make_dark_panel_style(0.72))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)

	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 19)
	title.add_theme_color_override("font_color", Color("#f5d779"))
	title.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 0)
	box.add_child(title)

	var value := Label.new()
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.add_theme_font_size_override("font_size", 36)
	value.add_theme_color_override("font_color", Color("#fff4cf"))
	value.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	value.add_theme_constant_override("shadow_offset_x", 0)
	value.add_theme_constant_override("shadow_offset_y", 0)
	box.add_child(value)
	stat_value_labels[key] = value
	return card


func _build_panel() -> void:
	self_modulate = Color.WHITE
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	pond_preview = _add_zoom_background("res://assets/sprites/panels/sacred_pond_zoom.png")

	var stats_margin := MarginContainer.new()
	stats_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	stats_margin.add_theme_constant_override("margin_left", 74)
	stats_margin.add_theme_constant_override("margin_right", 74)
	stats_margin.add_theme_constant_override("margin_top", 1324)
	stats_margin.add_theme_constant_override("margin_bottom", 340)
	add_child(stats_margin)

	var stats_panel := PanelContainer.new()
	stats_panel.add_theme_stylebox_override("panel", _make_dark_panel_style(0.72))
	stats_margin.add_child(stats_panel)

	stats_label = Label.new()
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats_label.add_theme_font_size_override("font_size", 21)
	stats_label.add_theme_color_override("font_color", Color("#fff4c6"))
	stats_label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	stats_label.add_theme_constant_override("shadow_offset_x", 0)
	stats_label.add_theme_constant_override("shadow_offset_y", 0)
	stats_panel.add_child(stats_label)

	var feedback_margin := MarginContainer.new()
	feedback_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	feedback_margin.add_theme_constant_override("margin_left", 96)
	feedback_margin.add_theme_constant_override("margin_right", 96)
	feedback_margin.add_theme_constant_override("margin_top", 1562)
	feedback_margin.add_theme_constant_override("margin_bottom", 266)
	add_child(feedback_margin)

	feedback_label = Label.new()
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	feedback_label.add_theme_font_size_override("font_size", 26)
	feedback_label.add_theme_color_override("font_color", Color("#f3d57a"))
	feedback_label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	feedback_label.add_theme_constant_override("shadow_offset_x", 0)
	feedback_label.add_theme_constant_override("shadow_offset_y", 0)
	feedback_margin.add_child(feedback_label)

	var button_margin := MarginContainer.new()
	button_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	button_margin.add_theme_constant_override("margin_left", 36)
	button_margin.add_theme_constant_override("margin_right", 36)
	button_margin.add_theme_constant_override("margin_top", 1608)
	button_margin.add_theme_constant_override("margin_bottom", 44)
	add_child(button_margin)

	var button_panel := PanelContainer.new()
	button_panel.add_theme_stylebox_override("panel", _make_button_bar_style())
	button_margin.add_child(button_panel)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 10)
	button_panel.add_child(buttons)
	buttons.add_child(_make_panel_nav_button("Restore", _on_restore_pressed))
	buttons.add_child(_make_panel_nav_button("Decorate", _on_decorate_pressed))
	buttons.add_child(_make_panel_nav_button("Back", _on_back_pressed))


func _make_panel_nav_button(button_name: String, callback: Callable) -> TextureButton:
	var button := TextureButton.new()
	button.name = "%sPanelButton" % button_name
	button.texture_normal = load(PANEL_BUTTONS[button_name])
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	button.custom_minimum_size = Vector2(238, 238)
	button.size = Vector2(238, 238)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.pressed.connect(callback)
	button.mouse_entered.connect(func(): button.modulate = Color(1.12, 1.08, 0.95, 1.0))
	button.mouse_exited.connect(func(): button.modulate = Color.WHITE)
	button.button_down.connect(func(): button.modulate = Color(0.86, 0.80, 0.68, 1.0))
	button.button_up.connect(func(): button.modulate = Color.WHITE)
	return button


func _build_pond_preview() -> void:
	_add_sprite(pond_preview, "res://assets/sprites/ui/panel_border_ornate.png", Vector2(72, 42), Vector2(776, 556))
	_add_sprite(pond_preview, "res://assets/sprites/buildings/sacred_pond_scene.png", Vector2(250, 58), Vector2(420, 380))
	_add_sprite(pond_preview, "res://assets/sprites/environment/waterfall_small.png", Vector2(545, 74), Vector2(150, 90))
	_add_sprite(pond_preview, "res://assets/sprites/environment/bloom_lilypad.png", Vector2(168, 350), Vector2(160, 110))

	_add_sprite(pond_preview, "res://assets/sprites/characters/koi_gold.png", Vector2(310, 190), Vector2(118, 96))
	_add_sprite(pond_preview, "res://assets/sprites/characters/koi_blue.png", Vector2(470, 238), Vector2(112, 88))
	_add_sprite(pond_preview, "res://assets/sprites/characters/koi_pink.png", Vector2(558, 326), Vector2(116, 88))

	for offset in [Vector2(120, 72), Vector2(760, 96), Vector2(110, 530), Vector2(744, 520)]:
		_add_sprite(pond_preview, "res://assets/sprites/environment/moon_lantern.png", offset, Vector2(52, 88))
	for offset in [Vector2(408, 76), Vector2(702, 318), Vector2(202, 390)]:
		_add_sprite(pond_preview, "res://assets/sprites/effects/glow_orb.png", offset, Vector2(54, 54))


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


func _add_zoom_background(path: String) -> TextureRect:
	var background := TextureRect.new()
	background.texture = load(path)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	return background


func _add_swimming_koi() -> void:
	var koi_specs := [
		{
			"path": "res://assets/sprites/characters/koi_gold.png",
			"start": Vector2(285, 690),
			"end": Vector2(640, 600),
			"size": Vector2(110, 78),
			"duration": 5.2
		},
		{
			"path": "res://assets/sprites/characters/koi_blue.png",
			"start": Vector2(710, 830),
			"end": Vector2(430, 755),
			"size": Vector2(102, 72),
			"duration": 6.0
		},
		{
			"path": "res://assets/sprites/characters/koi_pink.png",
			"start": Vector2(380, 1010),
			"end": Vector2(760, 1085),
			"size": Vector2(106, 74),
			"duration": 6.6
		}
	]

	for spec in koi_specs:
		var koi := _add_sprite(self, spec["path"], Vector2.ZERO, spec["size"])
		koi.z_index = 3
		koi.modulate = Color(1.0, 1.0, 1.0, 0.88)
		_animate_koi_loop(koi, spec["start"], spec["end"], float(spec["duration"]))


func _animate_koi_loop(koi: Sprite2D, start_position: Vector2, end_position: Vector2, duration: float) -> void:
	koi.position = start_position
	koi.rotation = (end_position - start_position).angle()
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(koi, "position", end_position, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(koi, "rotation", (end_position - start_position).angle() + 0.10, duration * 0.5)
	tween.tween_property(koi, "position", start_position, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(koi, "rotation", (start_position - end_position).angle() - 0.10, duration * 0.5)


func _make_dark_panel_style(alpha: float = 0.78) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.018, 0.028, alpha)
	style.border_color = Color("#b98c43")
	style.set_border_width_all(2)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	return style


func _make_button_bar_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.018, 0.025, 0.68)
	style.border_color = Color("#6f5327")
	style.set_border_width_all(1)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style


func _make_progress_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style


func _make_button_style(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(2)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


func _refresh() -> void:
	var completion_text := "Fully Restored" if GameState.sacred_pond_water_purity >= 100 else "Restoring"
	if stat_value_labels.has("purity"):
		(stat_value_labels["purity"] as Label).text = "%d%%" % GameState.sacred_pond_water_purity
	if stat_value_labels.has("spirit"):
		(stat_value_labels["spirit"] as Label).text = str(GameState.sacred_pond_spirit_energy)
	if stat_value_labels.has("beauty"):
		(stat_value_labels["beauty"] as Label).text = str(GameState.pond_beauty)
	if purity_progress:
		purity_progress.value = GameState.sacred_pond_water_purity
	if bonus_summary_label:
		bonus_summary_label.text = "Status: %s    Decoration Bonus +%d%%    Restore +%d%% for %d Mana\n%s    Next: %s" % [
			completion_text,
			GameState.get_pond_decoration_restore_bonus(),
			GameState.get_sacred_pond_total_restore_amount(),
			GameState.sacred_pond_restore_cost,
			GameState.get_active_pond_bonus_text(),
			GameState.get_next_pond_reward_text()
		]
	stats_label.text = (
		"Water Purity: %d%%    Status: %s    Spirit Energy: %d\nPond Beauty: %d    Restore Cost: %d Mana    Total Restore Amount: +%d%%\nBase: +%d%%    Fairy: +%d%%    Decor: +%d%%\nActive Pond Bonus: %s\nNext Reward: %s"
		% [
			GameState.sacred_pond_water_purity,
			completion_text,
			GameState.sacred_pond_spirit_energy,
			GameState.pond_beauty,
			GameState.sacred_pond_restore_cost,
			GameState.get_sacred_pond_total_restore_amount(),
			GameState.get_sacred_pond_base_restore_amount(),
			GameState.get_sacred_pond_fairy_restore_bonus(),
			GameState.get_pond_decoration_restore_bonus(),
			GameState.get_active_pond_bonus_text(),
			GameState.get_next_pond_reward_text()
		]
	)
	_refresh_decoration_preview()


func _build_decoration_preview_layer() -> void:
	decoration_preview_layer = Control.new()
	decoration_preview_layer.name = "Pond Decoration Preview"
	decoration_preview_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	decoration_preview_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if has_node("Root"):
		get_node("Root").add_child(decoration_preview_layer)
	else:
		add_child(decoration_preview_layer)


func _refresh_decoration_preview() -> void:
	if decoration_preview_layer == null:
		return
	for child in decoration_preview_layer.get_children():
		child.queue_free()
	for decoration in GameState.pond_decorations:
		if not bool(decoration.get("IsPlaced", false)):
			continue
		var decoration_name := String(decoration.get("DecorationName", ""))
		var marker_size := _pond_decoration_preview_size(decoration_name)
		var marker := _add_sprite(
			decoration_preview_layer,
			_pond_decoration_sprite_path(decoration_name),
			GameState.get_pond_decoration_position(decoration) - marker_size * 0.5,
			marker_size
		)
		marker.z_index = 4
		marker.modulate.a = 0.94


func _pond_decoration_sprite_path(decoration_name: String) -> String:
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


func _pond_decoration_preview_size(decoration_name: String) -> Vector2:
	if decoration_name == "Moon Lantern":
		return Vector2(110, 136)
	if decoration_name == "Spirit Stone":
		return Vector2(120, 120)
	if decoration_name == "Bloom Lilypad":
		return Vector2(128, 94)
	if decoration_name == "Sacred Bridge":
		return Vector2(154, 100)
	if decoration_name == "Crystal Lotus":
		return Vector2(132, 164)
	if decoration_name == "Stone Koi Statue":
		return Vector2(132, 166)
	if decoration_name == "Crystal Pillar":
		return Vector2(118, 166)
	if decoration_name == "Moonstone Steps":
		return Vector2(150, 116)
	if decoration_name == "Fern Spring":
		return Vector2(146, 136)
	if decoration_name == "Flame Basin":
		return Vector2(148, 126)
	if decoration_name == "Reed Cluster":
		return Vector2(118, 170)
	if decoration_name == "Willow Arch":
		return Vector2(154, 180)
	if decoration_name == "Gold Koi":
		return Vector2(132, 94)
	if decoration_name == "Blue Koi":
		return Vector2(124, 88)
	if decoration_name == "Pink Koi":
		return Vector2(128, 90)
	return Vector2(108, 108)


func _on_restore_pressed() -> void:
	SoundManager.play_click()
	var restore_amount := GameState.get_sacred_pond_total_restore_amount()
	if GameState.restore_sacred_pond():
		feedback_label.text = "Water Purity +%d%%" % restore_amount
		_show_floating_text("Water Purity +%d%%" % restore_amount, Vector2(330, 830), Color("#80d6ff"))
		_flash_panel()
	elif GameState.sacred_pond_water_purity >= 100:
		feedback_label.text = "Sacred Pond is fully restored."
		_show_floating_text("Fully Restored", Vector2(330, 830), Color("#9ef0c0"))
	else:
		feedback_label.text = "Not enough Mana"
		_show_floating_text("Not enough Mana", Vector2(330, 830), Color("#ff9f8a"))


func _on_decorate_pressed() -> void:
	SoundManager.play_click()
	decorate_requested.emit()


func _on_remove_pressed() -> void:
	SoundManager.play_click()
	feedback_label.text = "Open Decorate to remove pond decorations."
	decorate_requested.emit()


func _on_back_pressed() -> void:
	SoundManager.play_click()
	GameState.save_game()
	closed.emit()


func _show_floating_text(text: String, start_position: Vector2, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.position = start_position
	label.add_theme_font_size_override("font_size", 34)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 0)
	add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "position", start_position + Vector2(0, -90), 0.75)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.75)
	tween.tween_callback(label.queue_free)


func _flash_panel() -> void:
	if pond_preview == null:
		return
	var original := pond_preview.modulate
	var tween := create_tween()
	tween.tween_property(pond_preview, "modulate", Color("#9ee8ff"), 0.12)
	tween.tween_property(pond_preview, "modulate", original, 0.28)
