extends Control

const FlowerGrovePanelScene := preload("res://ui/FlowerGrovePanel.tscn")
const SacredPondPanelScene := preload("res://ui/SacredPondPanel.tscn")
const FairyHousePanelScene := preload("res://ui/FairyHousePanel.tscn")
const PotionShopPanelScene := preload("res://ui/PotionShopPanel.tscn")
const QuestPanelScene := preload("res://ui/QuestPanel.tscn")
const ExplorePanelScene := preload("res://ui/ExplorePanel.tscn")
const BuildingsPanelScene := preload("res://ui/BuildingsPanel.tscn")
const InventoryPanelScene := preload("res://ui/InventoryPanel.tscn")
const SettingsPanelScene := preload("res://ui/SettingsPanel.tscn")
const PondDecoratePanelScene := preload("res://ui/PondDecoratePanel.tscn")
const AncientTreePanelScene := preload("res://ui/AncientTreePanel.tscn")
const ArcaneForgePanelScene := preload("res://ui/ArcaneForgePanel.tscn")
const MarketStallPanelScene := preload("res://ui/MarketStallPanel.tscn")

const VILLAGE_BACKGROUND_PATH := "res://assets/sprites/backgrounds/restored_village_background.png"
const BACKGROUND_GLOW_SHADER_PATH := "res://assets/shaders/background_glow_pulse.gdshader"
const ANCIENT_TREE_HOME_PATH := "res://assets/sprites/buildings/ancient_tree_landmark.png"
const SACRED_POND_HOME_PATH := "res://assets/sprites/buildings/sacred_pond_home.png"
const FLOWER_GROVE_HOME_PATH := "res://assets/sprites/buildings/flower_grove_home.png"
const FAIRY_HOUSE_HOME_PATH := "res://assets/sprites/buildings/fairy_house_home.png"
const POTION_SHOP_HOME_PATH := "res://assets/sprites/buildings/potion_shop_home.png"
const MARKET_STALL_HOME_PATH := "res://assets/sprites/buildings/market_stall_home.png"
const NAV_BUTTON_TEXTURES := {
	"Map": "res://assets/sprites/ui/nav_map.png",
	"Explore": "res://assets/sprites/ui/nav_explore.png",
	"Buildings": "res://assets/sprites/ui/nav_buildings.png",
	"Quests": "res://assets/sprites/ui/nav_quests.png",
	"Settings": "res://assets/sprites/ui/nav_settings.png",
}
const RESTORATION_VISUAL_NAMES := ["Extra pond flowers", "Pond glow", "Fairy lights", "Sun Koi Guardian"]

var mana_label: Label
var coins_label: Label
var restoration_label: Label
var restoration_bar: ProgressBar
var feedback_label: Label
var tutorial_panel: PanelContainer
var tutorial_text: Label
var panel_layer: CanvasLayer
var tutorial_layer: CanvasLayer
var bottom_nav_layer: CanvasLayer
var building_hit_layer: CanvasLayer
var open_panel: Control
var attention_layer: Control
var restoration_visual_layer: Control
var pond_decoration_visual_layer: Control
var fairy_worker_visual_layer: Control
var quests_button: TextureButton
var quests_badge: Label
var fairy_visual_refresh_elapsed: float = 0.0

func _ready() -> void:
	_hide_editor_label_previews()
	_disable_editor_map_input_blocking()
	_build_screen()
	GameState.resources_changed.connect(_refresh_hud)
	GameState.resources_changed.connect(_refresh_attention_indicators)
	GameState.resources_changed.connect(_refresh_restoration_visuals)
	GameState.flower_grove_changed.connect(_refresh_attention_indicators)
	GameState.flower_grove_changed.connect(_refresh_fairy_worker_visuals)
	GameState.fairy_house_changed.connect(_refresh_attention_indicators)
	GameState.fairy_house_changed.connect(_refresh_fairy_worker_visuals)
	GameState.potion_shop_changed.connect(_refresh_attention_indicators)
	GameState.sacred_pond_changed.connect(_refresh_restoration_visuals)
	GameState.sacred_pond_changed.connect(_refresh_pond_decoration_visuals)
	GameState.sacred_pond_changed.connect(_refresh_attention_indicators)
	GameState.sacred_pond_changed.connect(_refresh_fairy_worker_visuals)
	GameState.quests_changed.connect(_refresh_quest_button)
	GameState.quests_changed.connect(_refresh_attention_indicators)
	GameState.save_status_changed.connect(_show_feedback)
	GameState.save_reset.connect(_on_save_reset)
	_refresh_hud()
	_refresh_quest_button()
	_refresh_attention_indicators()
	_refresh_restoration_visuals()
	SoundManager.play_music(SoundManager.TRACK_MAIN_VILLAGE)
	if not GameState.has_seen_tutorial:
		if GameState.has_completed_onboarding and not GameState.show_tutorial_after_reset:
			GameState.mark_tutorial_seen()
		else:
			_show_tutorial()


func _process(delta: float) -> void:
	if fairy_worker_visual_layer == null:
		return
	if open_panel != null:
		fairy_visual_refresh_elapsed = 0.0
		return
	fairy_visual_refresh_elapsed += delta
	if fairy_visual_refresh_elapsed >= 1.0:
		fairy_visual_refresh_elapsed = 0.0
		_refresh_fairy_worker_visuals()


func _build_screen() -> void:
	_build_village_background()
	_build_building_hit_layer()
	_build_restoration_focus()
	_add_landmark_hit_button("Ancient Tree", _get_placement_rect("AncientTreePlacement", Rect2(350, 140, 380, 418)), _open_ancient_tree)
	_build_restoration_visual_layer()

	_add_area_button("Sacred Koi Pond", _get_placement_rect("SacredKoiPondPlacement", Rect2(90, 484, 342, 276)), Color("#123e7a"), _open_sacred_pond, "Water Purity")
	_add_home_swimming_koi(_get_placement_rect("SacredKoiPondPlacement", Rect2(90, 484, 342, 276)))
	_add_area_button("Potion Shop", _get_placement_rect("PotionShopPlacement", Rect2(714, 502, 278, 254)), Color("#5c2e78"), _open_potion_shop, "Mana Potion")
	_add_area_button("Flower Grove", _get_placement_rect("FlowerGrovePlacement", Rect2(392, 807, 308, 238)), Color("#4b2670"), _open_flower_grove, "Mana Garden")
	_add_area_button("Fairy House", _get_placement_rect("FairyHousePlacement", Rect2(156, 1260, 288, 244)), Color("#6b4a24"), _open_fairy_house, "Luna Assigned")
	_add_area_button("Market Stall", _get_placement_rect("MarketStallPlacement", Rect2(673, 1258, 298, 224)), Color("#7a3f1f"), _open_market_stall, "Trade Orders")
	_add_area_button("Arcane Forge", _get_placement_rect("ArcaneForgePlacement", Rect2(760, 1030, 250, 235)), Color("#2c516f"), _open_arcane_forge, "Gear Upgrades")
	_build_fairy_worker_visual_layer()
	_build_attention_layer()
	_build_pond_decoration_visual_layer()
	_build_hud()
	_build_version_label()
	_build_bottom_bar()

	panel_layer = CanvasLayer.new()
	panel_layer.layer = 10
	add_child(panel_layer)

	tutorial_layer = CanvasLayer.new()
	tutorial_layer.name = "TutorialLayer"
	tutorial_layer.layer = 40
	add_child(tutorial_layer)


func _build_building_hit_layer() -> void:
	building_hit_layer = CanvasLayer.new()
	building_hit_layer.name = "BuildingHitLayer"
	building_hit_layer.layer = 5
	add_child(building_hit_layer)


func _build_village_background() -> void:
	var existing_background := get_node_or_null("EditableHomeMap/BackgroundPreview") as TextureRect
	if existing_background:
		existing_background.texture = _load_texture(VILLAGE_BACKGROUND_PATH)
		existing_background.material = _make_background_glow_material()
		return

	var backing := ColorRect.new()
	backing.color = Color("#061014")
	backing.set_anchors_preset(Control.PRESET_FULL_RECT)
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backing)
	move_child(backing, 0)

	var background := TextureRect.new()
	background.texture = _load_texture(VILLAGE_BACKGROUND_PATH)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.material = _make_background_glow_material()
	add_child(background)
	move_child(background, 1)


func _make_background_glow_material():
	var shader = load(BACKGROUND_GLOW_SHADER_PATH)
	if shader == null:
		return null

	var glow_material := ShaderMaterial.new()
	glow_material.shader = shader
	glow_material.set_shader_parameter("pulse_speed", 1.35)
	glow_material.set_shader_parameter("pulse_strength", 0.26)
	glow_material.set_shader_parameter("glow_threshold", 0.34)
	glow_material.set_shader_parameter("wind_strength", 0.006)
	glow_material.set_shader_parameter("wind_speed", 0.85)
	return glow_material


func _build_title() -> void:
	var title := Label.new()
	title.text = "Mystic Grove"
	title.position = Vector2(220, 170)
	title.size = Vector2(640, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color("#d9bb72"))
	title.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 0)
	add_child(title)


func _build_version_label() -> void:
	var version := Label.new()
	version.text = "Build: Demo Build 01"
	version.position = Vector2(744, 1688)
	version.size = Vector2(280, 42)
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	version.add_theme_font_size_override("font_size", 15)
	version.add_theme_color_override("font_color", Color("#fff2a8"))
	version.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	version.add_theme_constant_override("shadow_offset_x", 0)
	version.add_theme_constant_override("shadow_offset_y", 0)
	add_child(version)


func _build_hud() -> void:
	var hud := HBoxContainer.new()
	hud.position = Vector2(34, 28)
	hud.add_theme_constant_override("separation", 14)
	add_child(hud)

	mana_label = Label.new()
	coins_label = Label.new()
	restoration_label = Label.new()
	restoration_bar = ProgressBar.new()
	hud.add_child(_make_resource_panel("Mana", "M", Color("#59bfff"), mana_label))
	hud.add_child(_make_resource_panel("Coins", "C", Color("#f6c14a"), coins_label))
	hud.add_child(_make_restoration_panel())
	hud.add_child(_make_inventory_button())

	feedback_label = Label.new()
	feedback_label.position = Vector2(310, 104)
	feedback_label.size = Vector2(500, 64)
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.add_theme_font_size_override("font_size", 26)
	feedback_label.add_theme_color_override("font_color", Color("#f5d66f"))
	feedback_label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	feedback_label.add_theme_constant_override("shadow_offset_x", 0)
	feedback_label.add_theme_constant_override("shadow_offset_y", 0)
	add_child(feedback_label)


func _make_resource_panel(title: String, icon_text: String, icon_color: Color, value_label: Label) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(235, 66)
	panel.add_theme_stylebox_override("panel", _make_style(Color(0.01, 0.014, 0.02, 0.88), Color("#b99245"), 2, 10))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)

	var icon := _make_icon_badge(icon_text, icon_color, Vector2(38, 38), 20)
	row.add_child(icon)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", -4)
	row.add_child(stack)
	var name_label := _make_ui_text(title, 16, Color("#cbbf9a"))
	stack.add_child(name_label)
	value_label.add_theme_font_size_override("font_size", 24)
	value_label.add_theme_color_override("font_color", Color("#fff2a8"))
	value_label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	value_label.add_theme_constant_override("shadow_offset_x", 0)
	value_label.add_theme_constant_override("shadow_offset_y", 0)
	stack.add_child(value_label)
	return panel


func _make_restoration_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(370, 66)
	panel.add_theme_stylebox_override("panel", _make_style(Color(0.01, 0.014, 0.02, 0.88), Color("#b99245"), 2, 10))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)

	var leaf := _make_icon_badge("R", Color("#84e071"), Vector2(36, 36), 18)
	row.add_child(leaf)

	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 3)
	row.add_child(stack)

	restoration_label.add_theme_font_size_override("font_size", 20)
	restoration_label.add_theme_color_override("font_color", Color("#fff2a8"))
	restoration_label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	restoration_label.add_theme_constant_override("shadow_offset_x", 0)
	restoration_label.add_theme_constant_override("shadow_offset_y", 0)
	stack.add_child(restoration_label)

	restoration_bar.min_value = 0
	restoration_bar.max_value = 100
	restoration_bar.custom_minimum_size = Vector2(250, 16)
	restoration_bar.show_percentage = false
	stack.add_child(restoration_bar)
	return panel


func _make_inventory_button() -> Button:
	var button := _make_small_button("Inventory", _open_inventory)
	button.name = "InventoryButton"
	button.custom_minimum_size = Vector2(150, 66)
	button.add_theme_font_size_override("font_size", 18)
	return button


func _make_ui_text(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 0)
	return label


func _make_icon_badge(text: String, color: Color, badge_size: Vector2, font_size: int) -> Label:
	var badge := Label.new()
	badge.text = text
	badge.custom_minimum_size = badge_size
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", font_size)
	badge.add_theme_color_override("font_color", Color.WHITE)
	badge.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	badge.add_theme_constant_override("shadow_offset_x", 0)
	badge.add_theme_constant_override("shadow_offset_y", 0)
	badge.add_theme_stylebox_override("normal", _make_style(Color(color.r, color.g, color.b, 0.82), Color("#d0a34f"), 2, 18))
	return badge


func _make_small_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(120, 58)
	button.add_theme_font_size_override("font_size", 22)
	_apply_button_style(button)
	button.pressed.connect(callback)
	return button


func _build_paths() -> void:
	_add_path_curve([
		Vector2(286, 650), Vector2(392, 684), Vector2(540, 650), Vector2(684, 580)
	], 34)
	_add_path_curve([
		Vector2(706, 596), Vector2(748, 682), Vector2(746, 778), Vector2(714, 900)
	], 30)
	_add_path_curve([
		Vector2(704, 1010), Vector2(610, 1096), Vector2(462, 1210), Vector2(324, 1376)
	], 34)
	_add_path_curve([
		Vector2(368, 1370), Vector2(460, 1224), Vector2(584, 1080), Vector2(714, 930)
	], 24)
	_add_path_curve([
		Vector2(650, 658), Vector2(734, 598), Vector2(806, 558), Vector2(868, 570)
	], 24)
	_add_stepping_stones([
		Vector2(412, 668), Vector2(492, 646), Vector2(612, 722), Vector2(674, 810), Vector2(548, 1144), Vector2(470, 1225), Vector2(770, 582)
	])


func _add_path(from: Vector2, to: Vector2, width: float) -> void:
	var path := ColorRect.new()
	path.color = Color("#7b4d27")
	path.position = from
	path.size = Vector2(from.distance_to(to), width)
	path.rotation = (to - from).angle()
	path.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(path)


func _add_path_curve(points: Array, width: float) -> void:
	var shadow := Line2D.new()
	shadow.points = PackedVector2Array(points)
	shadow.width = width + 10
	shadow.default_color = Color(0.0, 0.0, 0.0, 0.18)
	shadow.joint_mode = Line2D.LINE_JOINT_ROUND
	shadow.begin_cap_mode = Line2D.LINE_CAP_ROUND
	shadow.end_cap_mode = Line2D.LINE_CAP_ROUND
	shadow.position = Vector2(5, 10)
	add_child(shadow)

	var path := Line2D.new()
	path.points = PackedVector2Array(points)
	path.width = width
	path.default_color = Color("#7b4d27")
	path.joint_mode = Line2D.LINE_JOINT_ROUND
	path.begin_cap_mode = Line2D.LINE_CAP_ROUND
	path.end_cap_mode = Line2D.LINE_CAP_ROUND
	add_child(path)


func _add_stepping_stones(points: Array) -> void:
	for index in range(points.size()):
		var center: Vector2 = points[index]
		_add_shadow_ellipse(center + Vector2(3, 8), Vector2(34, 11), 0.16)
		_add_ellipse(center, Vector2(28, 10), Color("#b8a98d"), 0.92)


func _build_restoration_focus() -> void:
	var rect := _get_placement_rect("AncientTreePlacement", Rect2(350, 140, 380, 418))
	var base := rect.position + rect.size * 0.5
	_add_shadow_ellipse(rect.position + Vector2(rect.size.x * 0.5, rect.size.y * 0.96), Vector2(rect.size.x * 0.40, max(22.0, rect.size.y * 0.08)), 0.20)
	var glow_alpha := 0.12 + (float(GameState.grove_restoration) / 100.0) * 0.30
	_add_ellipse(base + Vector2(0, rect.size.y * 0.12), Vector2(rect.size.x * 0.23, rect.size.y * 0.09), Color("#37d6c6"), glow_alpha)
	_add_tree_restoration_badge(rect)


func _add_tree_restoration_badge(rect: Rect2) -> void:
	var badge := PanelContainer.new()
	badge.position = rect.position + Vector2(rect.size.x * 0.5 - 128, rect.size.y * 0.72)
	badge.size = Vector2(256, 82)
	badge.z_index = 24
	badge.add_theme_stylebox_override("panel", _make_style(Color(0.01, 0.014, 0.02, 0.82), Color("#d0a34f"), 2, 8))
	add_child(badge)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	badge.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 2)
	margin.add_child(layout)
	var title := _make_ui_text("Ancient Tree", 18, Color("#fff2a8"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(title)
	var percent := _make_ui_text("Restoration %d%%" % GameState.grove_restoration, 20, Color("#aeea84"))
	percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(percent)


func _build_restoration_visual_layer() -> void:
	restoration_visual_layer = Control.new()
	restoration_visual_layer.name = "Grove Restoration Visual State"
	restoration_visual_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	restoration_visual_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(restoration_visual_layer)


func _build_pond_decoration_visual_layer() -> void:
	pond_decoration_visual_layer = Control.new()
	pond_decoration_visual_layer.name = "Pond Decoration Visual State"
	pond_decoration_visual_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pond_decoration_visual_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(pond_decoration_visual_layer)
	_refresh_pond_decoration_visuals()


func _refresh_pond_decoration_visuals() -> void:
	if pond_decoration_visual_layer == null:
		return
	for child in pond_decoration_visual_layer.get_children():
		child.queue_free()

	for decoration in GameState.pond_decorations:
		if not bool(decoration.get("IsPlaced", false)):
			continue
		var decoration_name := String(decoration.get("DecorationName", ""))
		var marker_size := _pond_decoration_world_size(decoration_name)
		var pond_rect := _get_placement_rect("SacredKoiPondPlacement", Rect2(90, 484, 342, 276))
		var marker := _add_layer_sprite(
			pond_decoration_visual_layer,
			_pond_decoration_sprite_path(decoration_name),
			GameState.get_pond_decoration_screen_position(decoration, pond_rect) - marker_size * 0.5,
			marker_size
		)
		marker.z_index = 18
		marker.modulate.a = 0.9


func _pond_decoration_world_position(editor_position: Vector2) -> Vector2:
	var pond_rect := _get_placement_rect("SacredKoiPondPlacement", Rect2(90, 484, 342, 276))
	var decoration := {
		"PositionX": editor_position.x,
		"PositionY": editor_position.y
	}
	return GameState.get_pond_decoration_screen_position(decoration, pond_rect)


func _pond_decoration_world_slot(slot_index: int) -> Vector2:
	var pond_rect := _get_placement_rect("SacredKoiPondPlacement", Rect2(90, 484, 342, 276))
	var positions := [
		pond_rect.position + Vector2(pond_rect.size.x * 0.24, pond_rect.size.y * 0.20),
		pond_rect.position + Vector2(pond_rect.size.x * 0.74, pond_rect.size.y * 0.22),
		pond_rect.position + Vector2(pond_rect.size.x * 0.26, pond_rect.size.y * 0.76),
		pond_rect.position + Vector2(pond_rect.size.x * 0.72, pond_rect.size.y * 0.76),
		pond_rect.position + Vector2(pond_rect.size.x * 0.10, pond_rect.size.y * 0.50),
		pond_rect.position + Vector2(pond_rect.size.x * 0.88, pond_rect.size.y * 0.50)
	]
	return positions[clamp(slot_index, 0, positions.size() - 1)]


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
	return "res://assets/sprites/environment/bloom_lilypad.png"


func _pond_decoration_world_size(decoration_name: String) -> Vector2:
	if decoration_name == "Moon Lantern":
		return Vector2(34, 64)
	if decoration_name == "Spirit Stone":
		return Vector2(44, 54)
	if decoration_name == "Bloom Lilypad":
		return Vector2(58, 42)
	if decoration_name == "Sacred Bridge":
		return Vector2(76, 52)
	if decoration_name == "Crystal Lotus":
		return Vector2(62, 76)
	if decoration_name == "Stone Koi Statue":
		return Vector2(60, 78)
	if decoration_name == "Crystal Pillar":
		return Vector2(54, 76)
	if decoration_name == "Moonstone Steps":
		return Vector2(68, 52)
	if decoration_name == "Fern Spring":
		return Vector2(66, 62)
	if decoration_name == "Flame Basin":
		return Vector2(66, 58)
	if decoration_name == "Reed Cluster":
		return Vector2(54, 78)
	if decoration_name == "Willow Arch":
		return Vector2(68, 80)
	if decoration_name == "Gold Koi":
		return Vector2(58, 40)
	if decoration_name == "Blue Koi":
		return Vector2(54, 38)
	if decoration_name == "Pink Koi":
		return Vector2(56, 40)
	return Vector2(46, 46)


func _refresh_restoration_visuals() -> void:
	if restoration_visual_layer == null:
		return
	for child in restoration_visual_layer.get_children():
		child.queue_free()

	var restoration := GameState.grove_restoration
	if restoration >= 25:
		for offset in [Vector2(94, 560), Vector2(168, 526), Vector2(388, 616), Vector2(326, 748), Vector2(126, 730)]:
			_add_layer_sprite(restoration_visual_layer, "res://assets/sprites/environment/bush_flowers.png", offset, Vector2(46, 40))

	if restoration >= 50:
		_add_layer_ellipse(restoration_visual_layer, Vector2(260, 684), Vector2(185, 66), Color("#76f5ff"), 0.15)
		_add_layer_ellipse(restoration_visual_layer, Vector2(260, 684), Vector2(128, 42), Color("#d7fffd"), 0.08)

	if restoration >= 75:
		for pos in [Vector2(456, 746), Vector2(548, 818), Vector2(642, 904), Vector2(584, 1100), Vector2(438, 1262)]:
			_add_layer_sprite(restoration_visual_layer, "res://assets/sprites/environment/moon_lantern.png", pos, Vector2(24, 44), Color(1.0, 1.0, 1.0, 0.82))

	if restoration >= 100:
		_add_layer_ellipse(restoration_visual_layer, Vector2(260, 640), Vector2(136, 52), Color("#ffd762"), 0.22)
		_add_layer_sprite(restoration_visual_layer, "res://assets/sprites/characters/koi_gold.png", Vector2(214, 604), Vector2(96, 64), Color(1.0, 0.92, 0.62, 0.96))
		_add_layer_sprite(restoration_visual_layer, "res://assets/sprites/environment/spirit_stone.png", Vector2(510, 408), Vector2(58, 68), Color(1.0, 0.92, 0.62, 0.86))
		_add_restoration_label("Sun Koi Guardian", Vector2(184, 668))


func _add_restoration_label(text: String, position: Vector2) -> void:
	var label := Label.new()
	label.text = text
	label.position = position
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color("#fff2a8"))
	label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	restoration_visual_layer.add_child(label)


func _add_layer_sprite(parent: Node, path: String, top_left: Vector2, size: Vector2, tint: Color = Color.WHITE) -> Sprite2D:
	var texture := _load_texture(path)
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = top_left + size * 0.5
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.modulate = tint
	if texture:
		sprite.scale = Vector2(size.x / texture.get_width(), size.y / texture.get_height())
	parent.add_child(sprite)
	return sprite


func _add_layer_ellipse(parent: Node, center: Vector2, radius: Vector2, color: Color, alpha: float) -> Polygon2D:
	var points := PackedVector2Array()
	for index in range(28):
		var angle := TAU * float(index) / 28.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	var ellipse := Polygon2D.new()
	ellipse.polygon = points
	ellipse.color = Color(color.r, color.g, color.b, alpha)
	parent.add_child(ellipse)
	return ellipse


func _build_trees() -> void:
	for pos in [
		Vector2(64, 264), Vector2(900, 270), Vector2(58, 806), Vector2(925, 720),
		Vector2(72, 1268), Vector2(930, 1122), Vector2(88, 1578), Vector2(890, 1598),
		Vector2(442, 310), Vector2(732, 330), Vector2(814, 528), Vector2(182, 1428)
	]:
		_build_tree(pos)
	for pos in [
		Vector2(154, 786), Vector2(866, 854), Vector2(204, 1188), Vector2(806, 1182),
		Vector2(210, 1540), Vector2(842, 1510), Vector2(506, 1478), Vector2(608, 468)
	]:
		_build_bush(pos)


func _build_tree(pos: Vector2) -> void:
	_add_shadow_ellipse(pos + Vector2(60, 120), Vector2(76, 22), 0.22)
	var tree_size := Vector2(128, 148)
	var tint := Color(0.82, 0.96, 0.86, 0.96)
	_add_sprite("res://assets/sprites/environment/ancient_tree_large.png", pos + Vector2(-6, -16), tree_size, 0.0, tint)


func _build_bush(pos: Vector2) -> void:
	_add_shadow_ellipse(pos + Vector2(40, 48), Vector2(58, 15), 0.16)
	_add_sprite("res://assets/sprites/environment/bush_flowers.png", pos + Vector2(-4, -10), Vector2(86, 76))


func _build_filler_props() -> void:
	for pos in [
		Vector2(160, 760), Vector2(370, 720), Vector2(602, 746), Vector2(812, 720),
		Vector2(230, 1160), Vector2(820, 1130), Vector2(414, 1458), Vector2(702, 1512)
	]:
		_add_sprite("res://assets/sprites/environment/purple_mushroom_cluster.png", pos, Vector2(46, 46))

	for pos in [
		Vector2(208, 704), Vector2(534, 686), Vector2(884, 640), Vector2(646, 1148),
		Vector2(220, 1510), Vector2(902, 1438)
	]:
		_add_sprite("res://assets/sprites/environment/blue_mushroom.png", pos, Vector2(38, 38))

	for pos in [
		Vector2(286, 720), Vector2(556, 760), Vector2(770, 630), Vector2(602, 1110),
		Vector2(374, 1288), Vector2(830, 1340)
	]:
		_add_sprite("res://assets/sprites/environment/spirit_stone.png", pos, Vector2(46, 58))

	for pos in [
		Vector2(382, 616), Vector2(850, 750), Vector2(520, 1030), Vector2(252, 1348),
		Vector2(714, 1256)
	]:
		_add_sprite("res://assets/sprites/environment/moon_lantern.png", pos, Vector2(38, 70))

	for pos in [
		Vector2(332, 782), Vector2(650, 752), Vector2(760, 1032), Vector2(468, 1324),
		Vector2(604, 1390)
	]:
		_add_sprite("res://assets/sprites/environment/spirit_stone.png", pos, Vector2(30, 38), 0.0, Color(1.0, 1.0, 1.0, 0.72))

	for pos in [
		Vector2(522, 716), Vector2(824, 672), Vector2(586, 1158), Vector2(390, 1336)
	]:
		_add_sprite("res://assets/sprites/environment/bush_flowers.png", pos, Vector2(46, 40))


func _add_area_button(title: String, rect: Rect2, color: Color, callback: Callable, subtitle: String) -> void:
	_build_area_art(title, rect)
	_add_tappable_glow(rect)

	var hit_area := Button.new()
	hit_area.name = "%sHitButton" % title.replace(" ", "")
	hit_area.text = ""
	var click_rect := _get_click_rect(rect)
	hit_area.position = click_rect.position
	hit_area.size = click_rect.size
	hit_area.custom_minimum_size = Vector2(220, 76)
	hit_area.focus_mode = Control.FOCUS_NONE
	hit_area.mouse_filter = Control.MOUSE_FILTER_STOP
	hit_area.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	hit_area.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	hit_area.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	hit_area.pressed.connect(callback)
	hit_area.mouse_entered.connect(func(): _set_button_hover(hit_area, true))
	hit_area.mouse_exited.connect(func(): _set_button_hover(hit_area, false))
	building_hit_layer.add_child(hit_area)

	var label := Button.new()
	label.text = title
	label.position = _get_area_label_position(title, rect)
	label.size = _get_area_label_size(title)
	label.custom_minimum_size = label.size
	label.focus_mode = Control.FOCUS_NONE
	label.z_index = 25
	label.add_theme_color_override("font_color", Color("#fff2a8"))
	label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	label.add_theme_font_size_override("font_size", 17)
	_apply_sign_style(label)
	label.pressed.connect(callback)
	add_child(label)


func _get_area_label_position(title: String, rect: Rect2) -> Vector2:
	return _get_area_label_rect(title, rect).position


func _get_area_label_size(title: String) -> Vector2:
	var label_rect := _get_area_label_rect(title, Rect2())
	if label_rect.size != Vector2.ZERO:
		return label_rect.size
	if title == "Sacred Koi Pond":
		return Vector2(220, 46)
	return Vector2(190, 46)


func _get_area_label_rect(title: String, rect: Rect2) -> Rect2:
	var label_name := _get_label_placement_name(title)
	if label_name != "":
		var placement := get_node_or_null("EditableHomeMap/%s" % label_name) as Control
		if placement:
			return Rect2(placement.position, placement.size)
	if rect == Rect2():
		return Rect2(Vector2.ZERO, Vector2.ZERO)
	var label_size := Vector2(220, 46) if title == "Sacred Koi Pond" else Vector2(190, 46)
	var x := rect.position.x + rect.size.x * 0.5 - label_size.x * 0.5
	var y := rect.position.y + rect.size.y - label_size.y * 0.55
	return Rect2(Vector2(x, y), label_size)


func _get_label_placement_name(title: String) -> String:
	match title:
		"Sacred Koi Pond":
			return "SacredKoiPondLabelPlacement"
		"Potion Shop":
			return "PotionShopLabelPlacement"
		"Flower Grove":
			return "FlowerGroveLabelPlacement"
		"Fairy House":
			return "FairyHouseLabelPlacement"
		"Market Stall":
			return "MarketStallLabelPlacement"
		"Arcane Forge":
			return "ArcaneForgeLabelPlacement"
		"Ancient Tree":
			return "AncientTreeLabelPlacement"
	return ""


func _hide_editor_label_previews() -> void:
	var map := get_node_or_null("EditableHomeMap")
	if map == null:
		return
	for child in map.get_children():
		if child is Control and child.name.ends_with("LabelPlacement"):
			(child as Control).visible = false


func _disable_editor_map_input_blocking() -> void:
	var map := get_node_or_null("EditableHomeMap") as Control
	if map == null:
		return
	_set_control_tree_mouse_filter_ignore(map)


func _set_control_tree_mouse_filter_ignore(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_set_control_tree_mouse_filter_ignore(child)


func _build_area_art(title: String, rect: Rect2) -> void:
	if title == "Sacred Koi Pond":
		_add_water_details(rect)
	elif title == "Flower Grove":
		_add_flower_details(rect)
	elif title == "Fairy House":
		_add_cottage_details(rect)
	elif title == "Potion Shop":
		_add_potion_shop_details(rect)


func _get_placement_rect(placement_name: String, fallback: Rect2) -> Rect2:
	var placement := get_node_or_null("EditableHomeMap/%s" % placement_name) as Control
	if placement == null:
		return fallback
	return Rect2(placement.position, placement.size)


func _get_click_rect(visual_rect: Rect2) -> Rect2:
	var inset_x := visual_rect.size.x * 0.12
	var inset_y := visual_rect.size.y * 0.10
	return Rect2(
		visual_rect.position + Vector2(inset_x, inset_y),
		visual_rect.size - Vector2(inset_x * 2.0, inset_y * 2.0)
	)


func _add_water_details(rect: Rect2) -> void:
	var center := rect.position + Vector2(rect.size.x * 0.5, rect.size.y * 0.56)
	_add_shadow_ellipse(center + Vector2(0, rect.size.y * 0.27), Vector2(rect.size.x * 0.42, max(18.0, rect.size.y * 0.12)), 0.22)


func _add_flower_details(rect: Rect2) -> void:
	_add_shadow_ellipse(rect.position + Vector2(rect.size.x * 0.5, rect.size.y * 1.07), Vector2(rect.size.x * 0.44, max(18.0, rect.size.y * 0.11)), 0.17)


func _add_cottage_details(rect: Rect2) -> void:
	_add_shadow_ellipse(rect.position + Vector2(rect.size.x * 0.5, rect.size.y * 1.0), Vector2(rect.size.x * 0.46, max(18.0, rect.size.y * 0.13)), 0.20)


func _add_potion_shop_details(rect: Rect2) -> void:
	_add_shadow_ellipse(rect.position + Vector2(rect.size.x * 0.5, rect.size.y * 0.90), Vector2(rect.size.x * 0.44, max(18.0, rect.size.y * 0.11)), 0.20)


func _build_fairy_worker_visual_layer() -> void:
	fairy_worker_visual_layer = Control.new()
	fairy_worker_visual_layer.name = "Fairy Worker Visuals"
	fairy_worker_visual_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fairy_worker_visual_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	fairy_worker_visual_layer.z_index = 24
	add_child(fairy_worker_visual_layer)
	_refresh_fairy_worker_visuals()


func _refresh_fairy_worker_visuals() -> void:
	if fairy_worker_visual_layer == null:
		return
	for child in fairy_worker_visual_layer.get_children():
		child.queue_free()

	var flower_rect := _get_placement_rect("FlowerGrovePlacement", Rect2(392, 807, 308, 238))
	var pond_rect := _get_placement_rect("SacredKoiPondPlacement", Rect2(90, 484, 342, 276))
	var fairy_rect := _get_placement_rect("FairyHousePlacement", Rect2(156, 1260, 288, 244))
	var flower_index := 0
	var pond_index := 0
	var resting_index := 0

	for fairy in GameState.fairies:
		if not bool(fairy.get("IsUnlocked", false)):
			continue
		var assigned_area := String(fairy.get("AssignedArea", GameState.FAIRY_AREA_UNASSIGNED))
		var fairy_name := String(fairy.get("FairyName", "Fairy"))
		if assigned_area == GameState.FAIRY_AREA_FLOWER_GROVE:
			_add_fairy_worker_visual(fairy, _get_flower_fairy_position(flower_rect, flower_index), "Gathering", _get_area_ready_count(GameState.FAIRY_AREA_FLOWER_GROVE))
			flower_index += 1
		elif assigned_area == GameState.FAIRY_AREA_SACRED_POND:
			_add_fairy_worker_visual(fairy, _get_pond_fairy_position(pond_rect, pond_index), "Tending", _get_area_ready_count(GameState.FAIRY_AREA_SACRED_POND))
			pond_index += 1
		else:
			_add_fairy_worker_visual(fairy, _get_resting_fairy_position(fairy_rect, resting_index), "Resting", 0, true)
			resting_index += 1


func _get_flower_fairy_position(rect: Rect2, index: int) -> Vector2:
	var offsets := [
		Vector2(0.18, 0.18),
		Vector2(0.72, 0.24),
		Vector2(0.46, 0.66),
		Vector2(0.30, 0.52)
	]
	return rect.position + rect.size * offsets[index % offsets.size()]


func _get_pond_fairy_position(rect: Rect2, index: int) -> Vector2:
	var offsets := [
		Vector2(0.18, 0.30),
		Vector2(0.78, 0.34),
		Vector2(0.58, 0.72),
		Vector2(0.34, 0.66)
	]
	return rect.position + rect.size * offsets[index % offsets.size()]


func _get_resting_fairy_position(rect: Rect2, index: int) -> Vector2:
	var offsets := [
		Vector2(0.72, 0.18),
		Vector2(0.30, 0.76),
		Vector2(0.54, 0.88),
		Vector2(0.18, 0.38)
	]
	return rect.position + rect.size * offsets[index % offsets.size()]


func _get_area_ready_count(area: String) -> int:
	if area == GameState.FAIRY_AREA_SACRED_POND:
		return GameState.get_fairy_task_ready_count(GameState.FAIRY_TASK_SACRED_POND)
	if area == GameState.FAIRY_AREA_FLOWER_GROVE:
		return GameState.get_fairy_task_ready_count(GameState.FAIRY_TASK_FLOWER_GROVE) + GameState.get_fairy_task_ready_count(GameState.FAIRY_TASK_FORAGE_INGREDIENTS)
	return 0


func _add_fairy_worker_visual(fairy: Dictionary, center_position: Vector2, status_text: String, ready_count: int = 0, resting: bool = false) -> void:
	var fairy_name := String(fairy.get("FairyName", "Fairy"))
	var role_color := _get_fairy_role_color(fairy)
	var orb := _add_layer_sprite(
		fairy_worker_visual_layer,
		"res://assets/sprites/effects/glow_orb.png",
		center_position - Vector2(34, 25),
		Vector2(68, 68),
		Color(role_color.r, role_color.g, role_color.b, 0.52 if resting else 0.74)
	)
	orb.z_index = 1

	var sprite := _add_layer_sprite(
		fairy_worker_visual_layer,
		_get_home_fairy_sprite_path(fairy_name),
		center_position - Vector2(30, 54),
		Vector2(60, 94),
		Color(1.0, 1.0, 1.0, 0.72 if resting else 0.96)
	)
	sprite.z_index = 2

	var badge := _make_fairy_status_badge(fairy_name, status_text, role_color, center_position, ready_count, resting)
	fairy_worker_visual_layer.add_child(badge)

	if ready_count > 0:
		var ready_badge := _make_fairy_ready_badge(center_position, ready_count)
		fairy_worker_visual_layer.add_child(ready_badge)

	_animate_fairy_worker(sprite, orb, badge, resting)


func _make_fairy_status_badge(fairy_name: String, status_text: String, role_color: Color, center_position: Vector2, ready_count: int, resting: bool) -> PanelContainer:
	var badge := PanelContainer.new()
	badge.name = "FairyStatus_%s" % fairy_name
	badge.position = center_position + Vector2(-72, 28)
	badge.custom_minimum_size = Vector2(144, 48)
	badge.size = badge.custom_minimum_size
	badge.z_index = 4
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var border_color := Color("#f3d57a") if ready_count > 0 else role_color
	var bg_color := Color(0.040, 0.030, 0.014, 0.86) if ready_count > 0 else Color(0.012, 0.018, 0.028, 0.78)
	if resting:
		bg_color = Color(0.018, 0.018, 0.030, 0.72)
	badge.add_theme_stylebox_override("panel", _make_style(bg_color, border_color, 2, 10))

	var label := Label.new()
	label.text = "%s\n%s" % [fairy_name, "Ready x%d" % ready_count if ready_count > 0 else status_text]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color("#fff2a8") if ready_count > 0 else role_color)
	label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 0)
	badge.add_child(label)
	return badge


func _make_fairy_ready_badge(center_position: Vector2, ready_count: int) -> Label:
	var label := Label.new()
	label.name = "FairyReadyBadge"
	label.text = "!"
	if ready_count > 1:
		label.text = "%d" % ready_count
	label.position = center_position + Vector2(28, -56)
	label.size = Vector2(36, 36)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.z_index = 5
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color("#061014"))
	label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 0)
	label.add_theme_stylebox_override("normal", _make_style(Color("#f3d57a"), Color("#fff2a8"), 2, 18))
	return label


func _animate_fairy_worker(sprite: Sprite2D, orb: Sprite2D, badge: Control, resting: bool) -> void:
	var bob_distance := 5.0 if resting else 9.0
	var duration := 1.45 if resting else 1.05
	var sprite_start := sprite.position
	var orb_start := orb.position
	var badge_start := badge.position
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(sprite, "position", sprite_start + Vector2(0, -bob_distance), duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(orb, "position", orb_start + Vector2(0, -bob_distance * 0.55), duration)
	tween.parallel().tween_property(badge, "position", badge_start + Vector2(0, -bob_distance * 0.25), duration)
	tween.tween_property(sprite, "position", sprite_start, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(orb, "position", orb_start, duration)
	tween.parallel().tween_property(badge, "position", badge_start, duration)
	tween.tween_interval(0.02)


func _get_home_fairy_sprite_path(fairy_name: String) -> String:
	match fairy_name:
		"Luna":
			return "res://assets/sprites/characters/fairy_luna.png"
		"Pip":
			return "res://assets/sprites/characters/fairy_pond_keeper.png"
		"Nim":
			return "res://assets/sprites/characters/fairy_potion_maker.png"
	return "res://assets/sprites/characters/fairy_placeholder.png"


func _get_fairy_role_color(fairy: Dictionary) -> Color:
	var role := String(fairy.get("FairyRole", "Helper"))
	if role == "Gatherer":
		return Color("#f3d57a")
	if role == "Pond Keeper":
		return Color("#80d6ff")
	if role == "Forager":
		return Color("#c784ff")
	return Color("#b98c43")


func _build_attention_layer() -> void:
	attention_layer = Control.new()
	attention_layer.name = "Home Attention Indicators"
	attention_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	attention_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	attention_layer.z_index = 28
	add_child(attention_layer)
	_refresh_attention_indicators()


func _refresh_attention_indicators() -> void:
	if attention_layer == null:
		return
	for child in attention_layer.get_children():
		child.queue_free()

	var flower_rect := _get_placement_rect("FlowerGrovePlacement", Rect2(392, 807, 308, 238))
	if GameState.flower_grove_stored_mana >= min(25.0, float(GameState.flower_grove_max_stored_mana)):
		_add_attention_marker(flower_rect.position + Vector2(flower_rect.size.x * 0.82, flower_rect.size.y * 0.20), "!", Color("#f6d66d"))

	var potion_rect := _get_placement_rect("PotionShopPlacement", Rect2(714, 502, 278, 254))
	if GameState.mana_potion_count > 0:
		_add_attention_marker(potion_rect.position + Vector2(potion_rect.size.x * 0.82, potion_rect.size.y * 0.16), "!", Color("#f6d66d"))

	var fairy_rect := _get_placement_rect("FairyHousePlacement", Rect2(156, 1260, 288, 244))
	if GameState.fairy_workers_active < GameState.fairy_residents:
		_add_attention_marker(fairy_rect.position + Vector2(fairy_rect.size.x * 0.70, fairy_rect.size.y * 0.12), "Zzz", Color("#bcdcff"), Vector2(76, 36), 22)

	var pond_rect := _get_placement_rect("SacredKoiPondPlacement", Rect2(90, 484, 342, 276))
	if GameState.total_mana >= GameState.sacred_pond_restore_cost and GameState.sacred_pond_water_purity < 100:
		_add_attention_marker(pond_rect.position + Vector2(pond_rect.size.x * 0.78, pond_rect.size.y * 0.22), "!", Color("#8fe6ff"))

	var quest_count := _get_claimable_quest_count()
	if quest_count > 0 and quests_badge:
		_refresh_quest_button()


func _get_claimable_quest_count() -> int:
	var count := 0
	for quest in GameState.quests:
		if bool(quest.get("IsCompleted", false)) and not bool(quest.get("IsClaimed", false)):
			count += 1
	return count


func _add_attention_marker(top_left: Vector2, text: String, color: Color, marker_size: Vector2 = Vector2(42, 42), font_size: int = 25) -> void:
	var marker := Button.new()
	marker.text = text
	marker.position = top_left
	marker.size = marker_size
	marker.custom_minimum_size = marker_size
	marker.focus_mode = Control.FOCUS_NONE
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.add_theme_font_size_override("font_size", font_size)
	marker.add_theme_color_override("font_color", Color.WHITE)
	marker.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	marker.add_theme_constant_override("shadow_offset_x", 0)
	marker.add_theme_constant_override("shadow_offset_y", 0)
	marker.add_theme_stylebox_override("normal", _make_style(Color(color.r, color.g, color.b, 0.82), Color("#fff2a8"), 2, 18))
	attention_layer.add_child(marker)


func _add_home_swimming_koi(pond_rect: Rect2) -> void:
	var koi_specs := [
		{
			"path": "res://assets/sprites/characters/koi_gold.png",
			"start": pond_rect.position + pond_rect.size * Vector2(0.34, 0.58),
			"end": pond_rect.position + pond_rect.size * Vector2(0.62, 0.48),
			"size": Vector2(52, 36),
			"duration": 3.8
		},
		{
			"path": "res://assets/sprites/characters/koi_blue.png",
			"start": pond_rect.position + pond_rect.size * Vector2(0.62, 0.68),
			"end": pond_rect.position + pond_rect.size * Vector2(0.42, 0.46),
			"size": Vector2(48, 34),
			"duration": 4.5
		},
		{
			"path": "res://assets/sprites/characters/koi_pink.png",
			"start": pond_rect.position + pond_rect.size * Vector2(0.48, 0.40),
			"end": pond_rect.position + pond_rect.size * Vector2(0.72, 0.62),
			"size": Vector2(50, 34),
			"duration": 5.1
		}
	]

	for spec in koi_specs:
		var koi := _add_sprite(spec["path"], Vector2.ZERO, spec["size"])
		koi.z_index = 12
		koi.modulate = Color(1.0, 1.0, 1.0, 0.86)
		_animate_koi_loop(koi, spec["start"], spec["end"], float(spec["duration"]))


func _animate_koi_loop(koi: Sprite2D, start_position: Vector2, end_position: Vector2, duration: float) -> void:
	koi.position = start_position
	koi.rotation = (end_position - start_position).angle()
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(koi, "position", end_position, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(koi, "rotation", (end_position - start_position).angle() + 0.12, duration * 0.5)
	tween.tween_property(koi, "position", start_position, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(koi, "rotation", (start_position - end_position).angle() - 0.12, duration * 0.5)


func _add_landmark_hit_button(title: String, rect: Rect2, callback: Callable) -> void:
	_add_shadow_ellipse(rect.position + Vector2(rect.size.x * 0.5, rect.size.y * 0.93), Vector2(rect.size.x * 0.42, max(18.0, rect.size.y * 0.12)), 0.16)
	_add_tappable_glow(rect)

	var hit_area := Button.new()
	hit_area.name = "%sHitButton" % title.replace(" ", "")
	hit_area.text = ""
	var click_rect := _get_click_rect(rect)
	hit_area.position = click_rect.position
	hit_area.size = click_rect.size
	hit_area.focus_mode = Control.FOCUS_NONE
	hit_area.mouse_filter = Control.MOUSE_FILTER_STOP
	hit_area.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	hit_area.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	hit_area.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	hit_area.pressed.connect(callback)
	building_hit_layer.add_child(hit_area)


func _add_home_label(text: String, position: Vector2, size: Vector2) -> Button:
	var label := Button.new()
	label.text = text
	label.position = position
	label.size = size
	label.custom_minimum_size = size
	label.focus_mode = Control.FOCUS_NONE
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", Color("#fff2a8"))
	label.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	label.add_theme_font_size_override("font_size", 20)
	_apply_sign_style(label)
	add_child(label)
	return label


func _add_sparkles(origin: Vector2, width: float) -> void:
	for index in range(5):
		var sparkle := ColorRect.new()
		sparkle.color = Color("#f5d66f") if index % 2 == 0 else Color("#8fe6ff")
		sparkle.position = origin + Vector2(24 + index * width / 5.0, 34 + (index % 3) * 42)
		sparkle.size = Vector2(14, 14)
		sparkle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(sparkle)


func _build_bottom_bar() -> void:
	var editable_layer := get_node_or_null("EditableBottomNavigation") as CanvasLayer
	if editable_layer:
		bottom_nav_layer = editable_layer
		_wire_editable_bottom_bar()
		return

	bottom_nav_layer = CanvasLayer.new()
	bottom_nav_layer.name = "BottomNavigation"
	bottom_nav_layer.layer = 30
	add_child(bottom_nav_layer)

	var bar := ColorRect.new()
	bar.color = Color(0.01, 0.014, 0.02, 0.9)
	bar.position = Vector2(40, 1730)
	bar.size = Vector2(1000, 150)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_nav_layer.add_child(bar)

	var row := HBoxContainer.new()
	row.position = Vector2(62, 1746)
	row.add_theme_constant_override("separation", 10)
	bottom_nav_layer.add_child(row)
	row.add_child(_make_nav_button("Map", NAV_BUTTON_TEXTURES["Map"], func(): open_nav_panel("Map")))
	row.add_child(_make_nav_button("Explore", NAV_BUTTON_TEXTURES["Explore"], func(): open_nav_panel("Explore")))
	row.add_child(_make_nav_button("Buildings", NAV_BUTTON_TEXTURES["Buildings"], func(): open_nav_panel("Buildings")))
	quests_button = _make_nav_button("Quests", NAV_BUTTON_TEXTURES["Quests"], func(): open_nav_panel("Quests"))
	row.add_child(quests_button)
	row.add_child(_make_nav_button("Settings", NAV_BUTTON_TEXTURES["Settings"], func(): open_nav_panel("Settings")))


func _wire_editable_bottom_bar() -> void:
	_wire_existing_nav_button("MapNavButton", func(): open_nav_panel("Map"))
	_wire_existing_nav_button("ExploreNavButton", func(): open_nav_panel("Explore"))
	_wire_existing_nav_button("BuildingsNavButton", func(): open_nav_panel("Buildings"))
	quests_button = _wire_existing_nav_button("QuestsNavButton", func(): open_nav_panel("Quests"))
	_wire_existing_nav_button("SettingsNavButton", func(): open_nav_panel("Settings"))
	quests_badge = bottom_nav_layer.get_node_or_null("QuestReadyBadge") as Label
	if quests_badge:
		_style_quest_badge(quests_badge)
	_refresh_quest_button()


func _wire_existing_nav_button(button_name: String, callback: Callable) -> TextureButton:
	var button := bottom_nav_layer.get_node_or_null("NavButtons/%s" % button_name) as TextureButton
	if button == null:
		return null
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(callback)
	button.mouse_entered.connect(func(): _set_texture_button_hover(button, true))
	button.mouse_exited.connect(func(): _set_texture_button_hover(button, false))
	button.button_down.connect(func(): button.modulate = Color(0.86, 0.80, 0.68, 1.0))
	button.button_up.connect(func(): button.modulate = Color.WHITE)
	return button


func _make_nav_button(text: String, texture_path: String, callback: Callable) -> TextureButton:
	var button := TextureButton.new()
	button.name = "%sNavButton" % text.replace(" ", "")
	button.custom_minimum_size = Vector2(184, 106)
	button.size = Vector2(184, 106)
	button.texture_normal = _load_texture(texture_path)
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(callback)
	button.mouse_entered.connect(func(): _set_texture_button_hover(button, true))
	button.mouse_exited.connect(func(): _set_texture_button_hover(button, false))
	button.button_down.connect(func(): button.modulate = Color(0.86, 0.80, 0.68, 1.0))
	button.button_up.connect(func(): button.modulate = Color.WHITE)
	if text == "Quests":
		quests_badge = _make_quest_badge()
		button.add_child(quests_badge)
	return button


func _set_button_hover(button: Button, hovered: bool) -> void:
	button.scale = Vector2(1.025, 1.025) if hovered else Vector2.ONE


func _set_texture_button_hover(button: TextureButton, hovered: bool) -> void:
	button.modulate = Color(1.12, 1.08, 0.95, 1.0) if hovered else Color.WHITE


func _make_quest_badge() -> Label:
	var badge := Label.new()
	badge.name = "QuestReadyBadge"
	badge.position = Vector2(142, -7)
	badge.size = Vector2(34, 34)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 18)
	badge.add_theme_color_override("font_color", Color.WHITE)
	badge.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	badge.add_theme_constant_override("shadow_offset_x", 0)
	badge.add_theme_constant_override("shadow_offset_y", 0)
	_style_quest_badge(badge)
	badge.visible = false
	return badge


func _style_quest_badge(badge: Label) -> void:
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color("#9b2f2d")
	badge_style.border_color = Color("#f8d879")
	badge_style.set_border_width_all(2)
	badge_style.corner_radius_top_left = 17
	badge_style.corner_radius_top_right = 17
	badge_style.corner_radius_bottom_left = 17
	badge_style.corner_radius_bottom_right = 17
	badge.add_theme_stylebox_override("normal", badge_style)


func _add_sprite(path: String, top_left: Vector2, size: Vector2, rotation: float = 0.0, tint: Color = Color.WHITE) -> Sprite2D:
	var texture := _load_texture(path)
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = top_left + size * 0.5
	sprite.rotation = rotation
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.modulate = tint
	if texture:
		sprite.scale = Vector2(size.x / texture.get_width(), size.y / texture.get_height())
	add_child(sprite)
	return sprite


func _load_texture(path: String) -> Texture2D:
	var resource: Resource = load(path)
	if resource is Texture2D:
		return resource as Texture2D

	var image := Image.new()
	if image.load(path) == OK:
		return ImageTexture.create_from_image(image)

	push_warning("Texture failed to load: %s" % path)
	return null


func _add_poly(points: PackedVector2Array, color: Color) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.polygon = points
	poly.color = color
	add_child(poly)
	return poly


func _add_ellipse(center: Vector2, radius: Vector2, color: Color, alpha: float = 1.0) -> Polygon2D:
	var points := PackedVector2Array()
	for index in range(28):
		var angle := TAU * float(index) / 28.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	var ellipse := Polygon2D.new()
	ellipse.polygon = points
	ellipse.color = Color(color.r, color.g, color.b, alpha)
	add_child(ellipse)
	return ellipse


func _add_shadow_ellipse(center: Vector2, radius: Vector2, alpha: float) -> Polygon2D:
	return _add_ellipse(center, radius, Color(0.0, 0.0, 0.0), alpha)


func _add_tappable_glow(rect: Rect2) -> void:
	var glow := _add_ellipse(
		rect.position + Vector2(rect.size.x * 0.5, rect.size.y * 0.74),
		Vector2(rect.size.x * 0.42, max(20.0, rect.size.y * 0.16)),
		Color("#ffe08a"),
		0.055
	)
	glow.z_index = 5


func _apply_button_style(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _make_style(Color(0.02, 0.025, 0.04, 0.92), Color("#9e7a34"), 2, 8))
	button.add_theme_stylebox_override("hover", _make_style(Color(0.06, 0.07, 0.09, 0.96), Color("#f0cf76"), 3, 8))
	button.add_theme_stylebox_override("pressed", _make_style(Color(0.12, 0.10, 0.06, 0.96), Color("#ffe08a"), 3, 8))
	button.add_theme_color_override("font_color", Color("#fff2a8"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)


func _apply_area_button_style(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _make_style(Color(0.02, 0.025, 0.04, 0.42), Color("#b99245"), 2, 8))
	button.add_theme_stylebox_override("hover", _make_style(Color(0.02, 0.025, 0.04, 0.58), Color("#f0cf76"), 3, 8))
	button.add_theme_stylebox_override("pressed", _make_style(Color(0.08, 0.06, 0.03, 0.72), Color("#ffe08a"), 3, 8))


func _apply_sign_style(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _make_style(Color("#4b3320", 0.86), Color("#c59a4b"), 2, 6))
	button.add_theme_stylebox_override("hover", _make_style(Color("#5d4027", 0.94), Color("#f0cf76"), 3, 6))
	button.add_theme_stylebox_override("pressed", _make_style(Color("#6a482a", 0.98), Color("#ffe08a"), 3, 6))


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


func _refresh_hud() -> void:
	mana_label.text = "%d" % GameState.total_mana
	coins_label.text = "%d" % GameState.total_coins
	restoration_label.text = "Grove Restoration: %d%%" % GameState.grove_restoration
	if restoration_bar:
		restoration_bar.value = GameState.grove_restoration


func _refresh_quest_button() -> void:
	if quests_badge == null:
		return
	var quest_count := _get_claimable_quest_count()
	quests_badge.visible = quest_count > 0
	quests_badge.text = str(quest_count)


func _show_feedback(message: String) -> void:
	feedback_label.text = message
	if message != "":
		_show_floating_text(message, Vector2(540, 300), Color("#f5d66f"))


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
	tween.tween_property(label, "position", start_position + Vector2(0, -80), 0.8)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(label.queue_free)


func _show_tutorial() -> void:
	if tutorial_panel:
		return
	tutorial_panel = PanelContainer.new()
	tutorial_panel.name = "Tutorial"
	tutorial_panel.position = Vector2(70, 520)
	tutorial_panel.size = Vector2(940, 560)
	tutorial_panel.self_modulate = Color(0.02, 0.025, 0.05, 0.94)
	tutorial_layer.add_child(tutorial_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_bottom", 32)
	tutorial_panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 22)
	margin.add_child(layout)

	tutorial_text = Label.new()
	tutorial_text.text = "The grove has lost its magic. Grow flowers to collect Mana, assign fairies to help, craft potions for Coins, and restore the Sacred Pond.\n\n1. Tap Flower Grove\n2. Collect Mana\n3. Upgrade Flower Grove\n4. Assign a Fairy\n5. Restore the Sacred Pond\n6. Craft and sell a potion\n7. Claim a quest reward"
	tutorial_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_text.add_theme_font_size_override("font_size", 34)
	tutorial_text.add_theme_color_override("font_color", Color("#fff2a8"))
	layout.add_child(tutorial_text)

	var close_button := Button.new()
	close_button.text = "Start Restoring"
	close_button.custom_minimum_size = Vector2(360, 78)
	close_button.add_theme_font_size_override("font_size", 28)
	close_button.pressed.connect(_close_tutorial)
	layout.add_child(close_button)


func _close_tutorial() -> void:
	SoundManager.play_click()
	if tutorial_panel:
		tutorial_panel.queue_free()
		tutorial_panel = null
	GameState.mark_tutorial_seen()


func _on_save_reset() -> void:
	close_all_panels()
	_set_home_nav_visible(true)
	_refresh_hud()
	_refresh_quest_button()
	_refresh_attention_indicators()
	_refresh_restoration_visuals()
	_show_tutorial()


func _open_flower_grove() -> void:
	SoundManager.play_click()
	GameState.tutorial_step = max(GameState.tutorial_step, 1)
	_show_panel(FlowerGrovePanelScene.instantiate())


func _open_sacred_pond() -> void:
	SoundManager.play_click()
	GameState.tutorial_step = max(GameState.tutorial_step, 3)
	_show_panel(SacredPondPanelScene.instantiate())


func _open_pond_decorate() -> void:
	SoundManager.play_click()
	_show_panel(PondDecoratePanelScene.instantiate())


func _open_fairy_house() -> void:
	SoundManager.play_click()
	_show_panel(FairyHousePanelScene.instantiate())


func _open_potion_shop() -> void:
	SoundManager.play_click()
	_show_panel(PotionShopPanelScene.instantiate())


func _open_ancient_tree() -> void:
	SoundManager.play_click()
	_show_panel(AncientTreePanelScene.instantiate())


func _open_arcane_forge() -> void:
	SoundManager.play_click()
	_show_panel(ArcaneForgePanelScene.instantiate())


func _open_market_stall() -> void:
	SoundManager.play_click()
	_show_panel(MarketStallPanelScene.instantiate())


func _open_inventory() -> void:
	SoundManager.play_click()
	_show_panel(InventoryPanelScene.instantiate())


func open_nav_panel(panel_name: String) -> void:
	SoundManager.play_click()
	close_all_panels()
	match panel_name:
		"Map":
			_open_map()
		"Explore":
			_open_explore()
		"Buildings":
			_open_buildings()
		"Quests":
			_open_quests()
		"Settings":
			_open_settings()


func close_all_panels() -> void:
	if open_panel:
		open_panel.queue_free()
		open_panel = null


func _open_map() -> void:
	_set_home_nav_visible(true)
	_refresh_hud()
	_refresh_quest_button()
	_refresh_attention_indicators()
	_refresh_restoration_visuals()


func _open_explore() -> void:
	SoundManager.play_click()
	_show_panel(ExplorePanelScene.instantiate())


func _open_buildings() -> void:
	SoundManager.play_click()
	var panel := BuildingsPanelScene.instantiate()
	_show_panel(panel)
	if panel.has_signal("open_building_requested"):
		panel.open_building_requested.connect(_open_building_from_buildings_panel)


func _open_quests() -> void:
	SoundManager.play_click()
	_show_panel(QuestPanelScene.instantiate())


func _open_settings() -> void:
	SoundManager.play_click()
	_show_panel(SettingsPanelScene.instantiate())


func _open_building_from_buildings_panel(building_name: String) -> void:
	match building_name:
		"Flower Grove":
			_open_flower_grove()
		"Sacred Koi Pond":
			_open_sacred_pond()
		"Fairy House":
			_open_fairy_house()
		"Potion Shop":
			_open_potion_shop()
		"Ancient Tree":
			_open_ancient_tree()
		"Market Stall":
			_open_market_stall()
		"Arcane Forge":
			_open_arcane_forge()


func _show_panel(panel: Control) -> void:
	close_all_panels()
	_set_home_nav_visible(false)
	open_panel = panel
	panel_layer.add_child(open_panel)
	if open_panel.has_signal("closed"):
		open_panel.closed.connect(_close_panel)
	if open_panel.has_signal("decorate_requested"):
		open_panel.decorate_requested.connect(_open_pond_decorate)
	if open_panel.has_signal("back_to_sacred_pond_requested"):
		open_panel.back_to_sacred_pond_requested.connect(_open_sacred_pond)


func _close_panel() -> void:
	if open_panel:
		open_panel.queue_free()
		open_panel = null
	_set_home_nav_visible(true)


func _set_home_nav_visible(is_visible: bool) -> void:
	if bottom_nav_layer:
		bottom_nav_layer.visible = is_visible
