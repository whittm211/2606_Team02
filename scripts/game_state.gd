extends Node

signal resources_changed
signal flower_grove_changed
signal sacred_pond_changed
signal fairy_house_changed
signal potion_shop_changed
signal market_stall_changed
signal ancient_tree_changed
signal arcane_forge_changed
signal inventory_changed
signal quests_changed
signal save_status_changed(message: String)
signal save_reset

const SAVE_PATH := "user://mystic_grove_save.json"
const FAIRY_AREA_FLOWER_GROVE := "Flower Grove"
const FAIRY_AREA_SACRED_POND := "Sacred Koi Pond"
const FAIRY_AREA_UNASSIGNED := "Unassigned"
const POND_BONUS_NONE := "None"
const POND_BONUS_BLOOMING_WATERS := "Blooming Waters"
const POND_BONUS_MOONLIT_REFLECTION := "Moonlit Reflection"
const POND_BONUS_FAIRY_BLESSING := "Fairy Blessing"
const POND_BONUS_SUN_KOI_GUARDIAN := "Sun Koi Guardian"
const QUEST_GOAL_COLLECT_MANA := "collect_mana"
const QUEST_GOAL_RESTORE_POND := "restore_pond"
const QUEST_GOAL_ASSIGN_FLOWER_FAIRY := "assign_flower_fairy"
const QUEST_GOAL_CRAFT_POTION := "craft_potion"
const QUEST_GOAL_UPGRADE_FLOWER := "upgrade_flower"
const QUEST_GOAL_MARKET_TRADE := "market_trade"
const QUEST_GOAL_RESTORE_TREE := "restore_tree"
const QUEST_GOAL_FORGE_UPGRADE := "forge_upgrade"
const QUEST_REWARD_MANA := "Mana"
const QUEST_REWARD_COINS := "Coins"
const SUN_KOI_GUARDIAN_SPIRIT_BONUS := 1
const POTION_RECIPE_MANA := "mana_potion"
const POTION_RECIPE_SPIRIT_TONIC := "spirit_tonic"
const POTION_INGREDIENT_MANA_CRYSTAL := "mana_crystal"
const POTION_INGREDIENT_DREAMBLOOM := "dreambloom"
const POTION_INGREDIENT_EMPTY_VIAL := "empty_vial"
const FLOWER_GRID_COLUMNS := 3
const FLOWER_GRID_ROWS := 4
const FLOWER_GRID_SLOT_COUNT := 12
const FLOWER_TIER_EMPTY := 0
const FLOWER_TIER_SEED := 1
const FLOWER_TIER_FLOWER := 2
const FLOWER_TIER_BLOOM := 3
const FLOWER_TIER_RARE_BLOSSOM := 4
const POND_DECORATION_EDITOR_RECT := Rect2(140, 320, 800, 830)
const FAIRY_TASK_FLOWER_GROVE := "flower_grove"
const FAIRY_TASK_FORAGE_INGREDIENTS := "forage_ingredients"
const FAIRY_TASK_SACRED_POND := "sacred_pond"
const FAIRY_TASK_IDS := [FAIRY_TASK_FLOWER_GROVE, FAIRY_TASK_FORAGE_INGREDIENTS, FAIRY_TASK_SACRED_POND]
const FAIRY_TASK_REQUIRED_PROGRESS := 60.0
const FAIRY_MAX_LEVEL := 5
const FAIRY_WORK_BONUS_PER_LEVEL := 0.5
const FAIRY_HOUSE_MAX_LEVEL := 5
const ANCIENT_TREE_WATER_LIMIT := 3
const ANCIENT_TREE_WATER_WINDOW_SECONDS := 3600
const FAIRY_HOUSE_UPGRADE_COSTS := {
	2: {"Mana": 80, "Coins": 25, "Spirit": 0},
	3: {"Mana": 140, "Coins": 50, "Spirit": 2},
	4: {"Mana": 220, "Coins": 90, "Spirit": 5},
	5: {"Mana": 320, "Coins": 150, "Spirit": 10}
}
const FAIRY_RECRUIT_COSTS := {
	"Sol": {"Mana": 120, "Coins": 40, "Spirit": 0, POTION_INGREDIENT_MANA_CRYSTAL: 1, POTION_INGREDIENT_DREAMBLOOM: 2, POTION_INGREDIENT_EMPTY_VIAL: 0},
	"Mira": {"Mana": 180, "Coins": 75, "Spirit": 4, POTION_INGREDIENT_MANA_CRYSTAL: 2, POTION_INGREDIENT_DREAMBLOOM: 2, POTION_INGREDIENT_EMPTY_VIAL: 1}
}

var total_mana: int = 0
var total_coins: int = 0
var grove_restoration: int = 15

var flower_grove_level: int = 1
var flower_grove_stored_mana: float = 0.0
var flower_grove_max_stored_mana: int = 100
var flower_grove_base_mana_production_rate: float = 5.0
var flower_grove_fairy_bonus_production: float = 0.0
var flower_grove_upgrade_cost: int = 25
var flower_grove_active_plots: int = 3
var flower_grove_max_plots: int = 6
var flower_grove_plot_unlock_states: Array[bool] = [true, true, true, false, false, false]
var flower_grove_grid_slots: Array[Dictionary] = []

var sacred_pond_water_purity: int = 15
var sacred_pond_spirit_energy: int = 0
var sacred_pond_level: int = 1
var sacred_pond_restore_cost: int = 25
var sacred_pond_base_restore_amount: int = 5
var sacred_pond_fairy_restore_bonus: int = 0
var active_pond_bonus: String = POND_BONUS_NONE
var unlocked_pond_rewards: Array[String] = []
var pond_beauty: int = 0
var pond_decorations: Array[Dictionary] = []
var pond_decoration_slots: Array[String] = []
var last_pond_decoration_message: String = ""

var fairy_house_level: int = 1
var fairy_residents: int = 3
var fairy_max_residents: int = 3
var fairy_workers_active: int = 2
var fairy_current_assignment: String = "Flower Grove"
var fairies: Array[Dictionary] = []
var fairy_task_progress: Dictionary = {}
var fairy_task_ready_counts: Dictionary = {}
var potion_shop_level: int = 1
var mana_potion_count: int = 0
var potion_mana_cost: int = 25
var potion_base_craft_time: int = 5
var potion_current_craft_time: float = 0.0
var potion_crafting_active: bool = false
var potion_crafting_recipe_id: String = POTION_RECIPE_MANA
var potion_inventory: Dictionary = {}
var potion_ingredients: Dictionary = {}
var potion_sell_value: int = 50
var potion_shop_upgrade_cost: int = 100
var market_reputation: int = 1
var market_orders_completed: int = 0
var inventory_notes: Array[String] = []
var ancient_tree_level: int = 1
var ancient_tree_growth: int = 15
var ancient_tree_restore_cost: int = 75
var ancient_tree_claimed_rewards: Array[int] = []
var ancient_tree_experience: int = 0
var ancient_tree_seed_count: int = 0
var ancient_tree_water_timestamps: Array[int] = []
var forge_level: int = 1
var forge_flower_focus_level: int = 0
var forge_potion_gilding_level: int = 0
var forge_pond_resonance_level: int = 0
var quests: Array[Dictionary] = []
var preserve_feedback_once: bool = false
var has_completed_onboarding: bool = false
var first_merge_complete: bool = false
var show_tutorial_after_reset: bool = false
var has_seen_tutorial: bool = false
var tutorial_step: int = 0
var music_volume: float = 0.75
var sfx_volume: float = 0.75

func _ready() -> void:
	if _is_test_save_disabled():
		reset_to_defaults()
		save_status_changed.emit("Test save disabled.")
		return
	load_game()


func _process(delta: float) -> void:
	generate_flower_mana(delta)
	update_fairy_tasks(delta)
	update_potion_crafting(delta)
	update_exploration(delta)


func generate_flower_mana(delta: float) -> void:
	if delta <= 0.0:
		return

	var old_mana := int(floor(flower_grove_stored_mana))
	flower_grove_stored_mana = min(
		flower_grove_stored_mana + get_flower_production_rate() * delta,
		float(flower_grove_max_stored_mana)
	)

	if int(floor(flower_grove_stored_mana)) != old_mana:
		flower_grove_changed.emit()


func collect_flower_mana() -> int:
	var collected := int(floor(flower_grove_stored_mana))
	if collected <= 0:
		return 0

	total_mana += collected
	flower_grove_stored_mana = 0.0
	add_quest_progress(QUEST_GOAL_COLLECT_MANA, collected)
	resources_changed.emit()
	flower_grove_changed.emit()
	save_game()
	return collected


func upgrade_flower_grove() -> bool:
	if total_mana < flower_grove_upgrade_cost:
		save_status_changed.emit("Not enough mana.")
		return false

	total_mana -= flower_grove_upgrade_cost
	flower_grove_level += 1
	flower_grove_base_mana_production_rate += 2.0
	if flower_grove_level % 2 == 0:
		flower_grove_max_stored_mana += 25
	flower_grove_upgrade_cost = int(ceil(float(flower_grove_upgrade_cost) * 1.5))
	add_quest_progress(QUEST_GOAL_UPGRADE_FLOWER, 1)

	resources_changed.emit()
	flower_grove_changed.emit()
	save_game()
	return true


func unlock_flower_plot() -> int:
	if flower_grove_active_plots >= flower_grove_max_plots:
		save_status_changed.emit("All plots unlocked.")
		return 0

	var unlock_cost := get_flower_unlock_cost()
	if total_mana < unlock_cost:
		save_status_changed.emit("Not enough mana.")
		return -1

	total_mana -= unlock_cost
	flower_grove_active_plots += 1
	flower_grove_base_mana_production_rate += 2.0
	_sync_plot_unlock_states()
	_sync_flower_grid_unlocks()

	resources_changed.emit()
	flower_grove_changed.emit()
	save_game()
	return 1


func get_flower_upgrade_cost() -> int:
	return flower_grove_upgrade_cost


func get_flower_unlock_cost() -> int:
	if flower_grove_active_plots >= flower_grove_max_plots:
		return 0
	var unlock_index := flower_grove_active_plots - 3
	return [50, 100, 200][unlock_index]


func get_flower_base_production_rate() -> float:
	return flower_grove_base_mana_production_rate


func get_flower_fairy_bonus_production() -> float:
	return flower_grove_fairy_bonus_production


func get_flower_production_rate() -> float:
	var total := flower_grove_base_mana_production_rate + flower_grove_fairy_bonus_production
	if is_pond_reward_unlocked(POND_BONUS_BLOOMING_WATERS):
		total *= 1.05
	return total


func get_flower_tier_data(tier: int) -> Dictionary:
	match tier:
		FLOWER_TIER_SEED:
			return {
				"Name": "Seed",
				"Sprite": "res://assets/sprites/environment/seed.png",
				"ManaValue": 2,
				"ManaProductionRate": 1,
				"MergeTier": 1
			}
		FLOWER_TIER_FLOWER:
			return {
				"Name": "Flower",
				"Sprite": "res://assets/sprites/environment/bloom_flower.png",
				"ManaValue": 5,
				"ManaProductionRate": 3,
				"MergeTier": 2
			}
		FLOWER_TIER_BLOOM:
			return {
				"Name": "Bloom",
				"Sprite": "res://assets/sprites/environment/bloom_stage3.png",
				"ManaValue": 12,
				"ManaProductionRate": 8,
				"MergeTier": 3
			}
		FLOWER_TIER_RARE_BLOSSOM:
			return {
				"Name": "Rare Blossom",
				"Sprite": "res://assets/sprites/environment/dreambloom.png",
				"ManaValue": 30,
				"ManaProductionRate": 20,
				"MergeTier": 4
			}
	return {
		"Name": "Empty",
		"Sprite": "",
		"ManaValue": 0,
		"ManaProductionRate": 0,
		"MergeTier": 0
	}


func get_flower_grid_production_rate() -> int:
	var production := 0
	for slot in flower_grove_grid_slots:
		production += int(get_flower_tier_data(int(slot.get("Tier", FLOWER_TIER_EMPTY))).get("ManaProductionRate", 0))
	return production


func get_flower_grid_slot(slot_index: int) -> Dictionary:
	if slot_index < 0 or slot_index >= flower_grove_grid_slots.size():
		return {"Tier": FLOWER_TIER_EMPTY, "Locked": true}
	return flower_grove_grid_slots[slot_index]


func is_flower_grid_full() -> bool:
	for slot in flower_grove_grid_slots:
		if not bool(slot.get("Locked", false)) and int(slot.get("Tier", FLOWER_TIER_EMPTY)) == FLOWER_TIER_EMPTY:
			return false
	return true


func plant_seed_in_flower_slot(slot_index: int) -> int:
	if slot_index < 0 or slot_index >= flower_grove_grid_slots.size():
		return -1
	if bool(flower_grove_grid_slots[slot_index].get("Locked", false)):
		return -1
	if int(flower_grove_grid_slots[slot_index].get("Tier", FLOWER_TIER_EMPTY)) != FLOWER_TIER_EMPTY:
		return -1
	flower_grove_grid_slots[slot_index]["Tier"] = FLOWER_TIER_SEED
	flower_grove_base_mana_production_rate += float(get_flower_tier_data(FLOWER_TIER_SEED).get("ManaProductionRate", 1))
	flower_grove_changed.emit()
	save_game()
	return 1


func merge_flower_grid_slots(from_slot: int, to_slot: int) -> Dictionary:
	var result := {
		"Success": false,
		"Message": "Flowers must match to merge.",
		"Reward": 0,
		"NewTier": FLOWER_TIER_EMPTY
	}
	if from_slot == to_slot:
		return result
	if from_slot < 0 or from_slot >= flower_grove_grid_slots.size() or to_slot < 0 or to_slot >= flower_grove_grid_slots.size():
		return result
	if bool(flower_grove_grid_slots[from_slot].get("Locked", false)) or bool(flower_grove_grid_slots[to_slot].get("Locked", false)):
		return result

	var from_tier := int(flower_grove_grid_slots[from_slot].get("Tier", FLOWER_TIER_EMPTY))
	var to_tier := int(flower_grove_grid_slots[to_slot].get("Tier", FLOWER_TIER_EMPTY))
	if from_tier <= FLOWER_TIER_EMPTY or to_tier <= FLOWER_TIER_EMPTY:
		result["Message"] = "Drag matching life together."
		return result
	if from_tier != to_tier:
		return result

	if from_tier >= FLOWER_TIER_RARE_BLOSSOM:
		var cashout_reward := int(get_flower_tier_data(from_tier).get("ManaValue", 0)) * 3 * 2
		var cashout_production := int(get_flower_tier_data(from_tier).get("ManaProductionRate", 0)) * 2

		flower_grove_grid_slots[from_slot]["Tier"] = FLOWER_TIER_EMPTY
		flower_grove_grid_slots[to_slot]["Tier"] = FLOWER_TIER_EMPTY
		flower_grove_base_mana_production_rate -= float(cashout_production)
		total_mana += cashout_reward

		resources_changed.emit()
		flower_grove_changed.emit()
		save_game()

		result["Success"] = true
		result["Message"] = "Rare Blossoms cashed out!"
		result["Reward"] = cashout_reward
		result["NewTier"] = FLOWER_TIER_EMPTY
		return result

	var old_production := int(get_flower_tier_data(from_tier).get("ManaProductionRate", 0)) * 2
	var new_tier := from_tier + 1
	var new_data := get_flower_tier_data(new_tier)
	var new_production := int(new_data.get("ManaProductionRate", 0))
	var reward := int(new_data.get("ManaValue", 0))

	flower_grove_grid_slots[from_slot]["Tier"] = FLOWER_TIER_EMPTY
	flower_grove_grid_slots[to_slot]["Tier"] = new_tier
	flower_grove_base_mana_production_rate += float(new_production - old_production)
	total_mana += reward

	resources_changed.emit()
	flower_grove_changed.emit()
	save_game()

	result["Success"] = true
	result["Message"] = "%s created!" % String(new_data.get("Name", "Bloom"))
	result["Reward"] = reward
	result["NewTier"] = new_tier
	return result


func _sync_plot_unlock_states() -> void:
	flower_grove_active_plots = clamp(flower_grove_active_plots, 0, flower_grove_max_plots)
	flower_grove_plot_unlock_states.clear()
	for index in range(flower_grove_max_plots):
		flower_grove_plot_unlock_states.append(index < flower_grove_active_plots)


func _sync_flower_grid_unlocks() -> void:
	if flower_grove_grid_slots.size() != FLOWER_GRID_SLOT_COUNT:
		_reset_flower_grid_to_defaults()
	var unlocked_slots: int = clamp(flower_grove_active_plots * 2, 0, FLOWER_GRID_SLOT_COUNT)
	for index in range(FLOWER_GRID_SLOT_COUNT):
		flower_grove_grid_slots[index]["Locked"] = index >= unlocked_slots


func restore_sacred_pond() -> bool:
	if sacred_pond_water_purity >= 100:
		save_status_changed.emit("Sacred Pond is fully restored.")
		return false
	if total_mana < sacred_pond_restore_cost:
		save_status_changed.emit("Not enough mana.")
		return false

	total_mana -= sacred_pond_restore_cost
	sacred_pond_water_purity = min(sacred_pond_water_purity + get_sacred_pond_total_restore_amount(), 100)
	sacred_pond_spirit_energy += 10 + get_sun_koi_guardian_spirit_bonus()
	sacred_pond_restore_cost = int(ceil(float(sacred_pond_restore_cost) * 1.25))
	update_sacred_pond_level_and_rewards()
	add_quest_progress(QUEST_GOAL_RESTORE_POND, 1)

	resources_changed.emit()
	flower_grove_changed.emit()
	sacred_pond_changed.emit()
	fairy_house_changed.emit()
	save_game()
	return true


func get_sacred_pond_base_restore_amount() -> int:
	return sacred_pond_base_restore_amount


func get_sacred_pond_fairy_restore_bonus() -> int:
	return sacred_pond_fairy_restore_bonus


func get_sacred_pond_total_restore_amount() -> int:
	return sacred_pond_base_restore_amount + sacred_pond_fairy_restore_bonus + get_pond_decoration_restore_bonus()


func can_restore_sacred_pond() -> bool:
	return sacred_pond_water_purity < 100 and total_mana >= sacred_pond_restore_cost


func get_pond_decoration_restore_bonus() -> int:
	return int(floor(float(pond_beauty) / 10.0))


func get_sun_koi_guardian_spirit_bonus() -> int:
	if is_pond_reward_unlocked(POND_BONUS_SUN_KOI_GUARDIAN):
		return SUN_KOI_GUARDIAN_SPIRIT_BONUS
	return 0


func get_pond_decoration_slot_name(slot_index: int) -> String:
	if slot_index < 0 or slot_index >= pond_decoration_slots.size():
		return "Auto"
	return pond_decoration_slots[slot_index]


func is_pond_slot_occupied(slot_index: int) -> bool:
	for decoration in pond_decorations:
		if bool(decoration.get("IsPlaced", false)) and int(decoration.get("SlotIndex", -1)) == slot_index:
			return true
	return false


func get_first_empty_pond_decoration_slot() -> int:
	for index in range(pond_decoration_slots.size()):
		if not is_pond_slot_occupied(index):
			return index
	return -1


func place_pond_decoration(decoration_name: String, requested_slot_index: int = -1) -> bool:
	var slot_index := requested_slot_index
	if slot_index < 0:
		slot_index = get_first_empty_pond_decoration_slot()
	if slot_index < 0:
		last_pond_decoration_message = "No empty decoration slots."
		save_status_changed.emit(last_pond_decoration_message)
		return false
	return place_pond_decoration_at(decoration_name, get_default_pond_decoration_position(slot_index), slot_index)


func place_pond_decoration_at(decoration_name: String, pond_position: Vector2, requested_slot_index: int = -1) -> bool:
	for index in range(pond_decorations.size()):
		if String(pond_decorations[index].get("DecorationName", "")) != decoration_name:
			continue
		if not bool(pond_decorations[index].get("IsUnlocked", true)):
			last_pond_decoration_message = "Decoration locked."
			save_status_changed.emit(last_pond_decoration_message)
			return false
		if bool(pond_decorations[index].get("IsPlaced", false)):
			last_pond_decoration_message = "Decoration already placed."
			save_status_changed.emit(last_pond_decoration_message)
			return false

		if requested_slot_index >= 0 and is_pond_slot_occupied(requested_slot_index):
			last_pond_decoration_message = "No empty decoration slots."
			save_status_changed.emit(last_pond_decoration_message)
			return false

		var cost := int(pond_decorations[index].get("CostMana", 0))
		if total_mana < cost:
			last_pond_decoration_message = "Not enough Mana."
			save_status_changed.emit(last_pond_decoration_message)
			return false

		total_mana -= cost
		pond_decorations[index]["IsPlaced"] = true
		pond_decorations[index]["SlotIndex"] = requested_slot_index
		var normalized_position := get_pond_decoration_normalized_from_editor_position(pond_position)
		pond_decorations[index]["PositionX"] = normalized_position.x
		pond_decorations[index]["PositionY"] = normalized_position.y
		recalculate_pond_beauty()
		last_pond_decoration_message = "Decoration placed!"
		resources_changed.emit()
		sacred_pond_changed.emit()
		save_game()
		save_status_changed.emit(last_pond_decoration_message)
		return true

	last_pond_decoration_message = "Decoration not found."
	save_status_changed.emit(last_pond_decoration_message)
	return false


func remove_pond_decoration(decoration_name: String) -> bool:
	for index in range(pond_decorations.size()):
		if String(pond_decorations[index].get("DecorationName", "")) != decoration_name:
			continue
		if not bool(pond_decorations[index].get("IsPlaced", false)):
			last_pond_decoration_message = "Decoration is not placed."
			save_status_changed.emit(last_pond_decoration_message)
			return false
		pond_decorations[index]["IsPlaced"] = false
		pond_decorations[index]["SlotIndex"] = -1
		pond_decorations[index]["PositionX"] = -1.0
		pond_decorations[index]["PositionY"] = -1.0
		recalculate_pond_beauty()
		last_pond_decoration_message = "Decoration removed."
		sacred_pond_changed.emit()
		save_game()
		save_status_changed.emit(last_pond_decoration_message)
		return true
	return false


func move_pond_decoration(decoration_name: String, pond_position: Vector2, save_immediately: bool = true) -> bool:
	for index in range(pond_decorations.size()):
		if String(pond_decorations[index].get("DecorationName", "")) != decoration_name:
			continue
		if not bool(pond_decorations[index].get("IsPlaced", false)):
			last_pond_decoration_message = "Decoration is not placed."
			save_status_changed.emit(last_pond_decoration_message)
			return false
		var normalized_position := get_pond_decoration_normalized_from_editor_position(pond_position)
		pond_decorations[index]["PositionX"] = normalized_position.x
		pond_decorations[index]["PositionY"] = normalized_position.y
		pond_decorations[index]["SlotIndex"] = -1
		last_pond_decoration_message = "Decoration moved."
		sacred_pond_changed.emit()
		if save_immediately:
			save_game()
		return true
	last_pond_decoration_message = "Decoration not found."
	save_status_changed.emit(last_pond_decoration_message)
	return false


func get_pond_decoration_position(decoration: Dictionary) -> Vector2:
	return get_pond_decoration_screen_position(decoration, POND_DECORATION_EDITOR_RECT)


func get_pond_decoration_screen_position(decoration: Dictionary, target_rect: Rect2) -> Vector2:
	var normalized := get_pond_decoration_normalized_position(decoration)
	return target_rect.position + target_rect.size * normalized


func get_pond_decoration_normalized_position(decoration: Dictionary) -> Vector2:
	var x := float(decoration.get("PositionX", -1.0))
	var y := float(decoration.get("PositionY", -1.0))
	if x >= 0.0 and y >= 0.0:
		if x <= 1.0 and y <= 1.0:
			return Vector2(clamp(x, 0.0, 1.0), clamp(y, 0.0, 1.0))
		return get_pond_decoration_normalized_from_editor_position(Vector2(x, y))
	var slot_index := int(decoration.get("SlotIndex", -1))
	if slot_index >= 0:
		return get_pond_decoration_normalized_from_editor_position(get_default_pond_decoration_position(slot_index))
	return Vector2(0.5, 0.5)


func get_default_pond_decoration_position(slot_index: int) -> Vector2:
	var positions := [
		Vector2(300, 438),
		Vector2(810, 535),
		Vector2(218, 900),
		Vector2(742, 1005),
		Vector2(548, 394),
		Vector2(540, 1038)
	]
	return positions[clamp(slot_index, 0, positions.size() - 1)]


func clamp_pond_decoration_position(pond_position: Vector2) -> Vector2:
	return Vector2(
		clamp(pond_position.x, POND_DECORATION_EDITOR_RECT.position.x, POND_DECORATION_EDITOR_RECT.end.x),
		clamp(pond_position.y, POND_DECORATION_EDITOR_RECT.position.y, POND_DECORATION_EDITOR_RECT.end.y)
	)


func get_pond_decoration_normalized_from_editor_position(pond_position: Vector2) -> Vector2:
	var clamped_position := clamp_pond_decoration_position(pond_position)
	return Vector2(
		inverse_lerp(POND_DECORATION_EDITOR_RECT.position.x, POND_DECORATION_EDITOR_RECT.end.x, clamped_position.x),
		inverse_lerp(POND_DECORATION_EDITOR_RECT.position.y, POND_DECORATION_EDITOR_RECT.end.y, clamped_position.y)
	)


func recalculate_pond_beauty() -> void:
	pond_beauty = 0
	for decoration in pond_decorations:
		if bool(decoration.get("IsPlaced", false)):
			pond_beauty += int(decoration.get("BeautyValue", 0))


func get_potion_mana_cost() -> int:
	return int(get_potion_recipe_data(POTION_RECIPE_MANA).get("CostMana", potion_mana_cost))


func get_potion_craft_time(recipe_id: String = POTION_RECIPE_MANA) -> int:
	var recipe := get_potion_recipe_data(recipe_id)
	var base_time := int(recipe.get("BaseCraftTime", potion_base_craft_time))
	return max(2, base_time - (potion_shop_level - 1))


func get_potion_sell_value(recipe_id: String = POTION_RECIPE_MANA) -> int:
	var recipe := get_potion_recipe_data(recipe_id)
	return int(recipe.get("SellValue", potion_sell_value))


func get_potion_craft_progress() -> float:
	if not potion_crafting_active:
		return 0.0
	var craft_time := float(get_potion_craft_time(potion_crafting_recipe_id))
	return clamp((craft_time - potion_current_craft_time) / craft_time, 0.0, 1.0)


func get_potion_recipe_data(recipe_id: String) -> Dictionary:
	match recipe_id:
		POTION_RECIPE_MANA:
			return {
				"RecipeID": POTION_RECIPE_MANA,
				"Name": "Mana Potion",
				"CostMana": potion_mana_cost,
				"CostSpirit": 0,
				"Ingredients": {
					POTION_INGREDIENT_MANA_CRYSTAL: 1,
					POTION_INGREDIENT_EMPTY_VIAL: 1
				},
				"BaseCraftTime": potion_base_craft_time,
				"SellValue": potion_sell_value,
				"Description": "A reliable village staple brewed from gathered Mana."
			}
		POTION_RECIPE_SPIRIT_TONIC:
			return {
				"RecipeID": POTION_RECIPE_SPIRIT_TONIC,
				"Name": "Spirit Tonic",
				"CostMana": 20,
				"CostSpirit": 5,
				"Ingredients": {
					POTION_INGREDIENT_MANA_CRYSTAL: 1,
					POTION_INGREDIENT_DREAMBLOOM: 2,
					POTION_INGREDIENT_EMPTY_VIAL: 1
				},
				"BaseCraftTime": potion_base_craft_time + 2,
				"SellValue": potion_sell_value + 45,
				"Description": "A bright pond-infused tonic that sells for a premium."
			}
	return {}


func get_potion_recipes() -> Array[Dictionary]:
	return [
		get_potion_recipe_data(POTION_RECIPE_MANA),
		get_potion_recipe_data(POTION_RECIPE_SPIRIT_TONIC)
	]


func get_potion_ingredient_name(ingredient_id: String) -> String:
	match ingredient_id:
		POTION_INGREDIENT_MANA_CRYSTAL:
			return "Mana Crystal"
		POTION_INGREDIENT_DREAMBLOOM:
			return "Dreambloom"
		POTION_INGREDIENT_EMPTY_VIAL:
			return "Empty Vial"
	return "Ingredient"


func get_potion_ingredient_count(ingredient_id: String) -> int:
	_sync_potion_ingredients()
	return int(potion_ingredients.get(ingredient_id, 0))


func get_potion_ingredient_requirements(recipe_id: String) -> Dictionary:
	var recipe := get_potion_recipe_data(recipe_id)
	if recipe.is_empty():
		return {}
	var ingredients = recipe.get("Ingredients", {})
	return ingredients if ingredients is Dictionary else {}


func has_potion_ingredients(recipe_id: String) -> bool:
	var requirements := get_potion_ingredient_requirements(recipe_id)
	for ingredient_id in requirements.keys():
		if get_potion_ingredient_count(String(ingredient_id)) < int(requirements.get(ingredient_id, 0)):
			return false
	return true


func get_potion_ingredient_requirement_text(recipe_id: String) -> String:
	var lines: Array[String] = []
	var requirements := get_potion_ingredient_requirements(recipe_id)
	for ingredient_id in requirements.keys():
		var clean_id := String(ingredient_id)
		lines.append("%s %d / %d" % [
			get_potion_ingredient_name(clean_id),
			get_potion_ingredient_count(clean_id),
			int(requirements.get(ingredient_id, 0))
		])
	return "\n".join(lines)


func add_potion_ingredient(ingredient_id: String, amount: int) -> void:
	if amount <= 0:
		return
	_sync_potion_ingredients()
	potion_ingredients[ingredient_id] = get_potion_ingredient_count(ingredient_id) + amount
	inventory_changed.emit()
	potion_shop_changed.emit()


func _spend_potion_ingredients(recipe_id: String) -> void:
	var requirements := get_potion_ingredient_requirements(recipe_id)
	_sync_potion_ingredients()
	for ingredient_id in requirements.keys():
		var clean_id := String(ingredient_id)
		potion_ingredients[clean_id] = max(0, get_potion_ingredient_count(clean_id) - int(requirements.get(ingredient_id, 0)))


func buy_potion_ingredient_bundle() -> Dictionary:
	var cost := 30
	if total_coins < cost:
		save_status_changed.emit("Not enough Coins.")
		return {"Success": false, "Message": "Not enough Coins."}
	total_coins -= cost
	add_potion_ingredient(POTION_INGREDIENT_MANA_CRYSTAL, 2)
	add_potion_ingredient(POTION_INGREDIENT_DREAMBLOOM, 2)
	add_potion_ingredient(POTION_INGREDIENT_EMPTY_VIAL, 2)
	resources_changed.emit()
	save_game()
	var message := "Bought potion ingredients."
	save_status_changed.emit(message)
	return {"Success": true, "Message": message}


func get_potion_count(recipe_id: String) -> int:
	_sync_potion_inventory_from_legacy()
	return int(potion_inventory.get(recipe_id, 0))


func get_total_potion_count() -> int:
	_sync_potion_inventory_from_legacy()
	var count := 0
	for recipe_id in potion_inventory.keys():
		count += int(potion_inventory.get(recipe_id, 0))
	return count


func can_craft_potion(recipe_id: String) -> bool:
	var recipe := get_potion_recipe_data(recipe_id)
	if recipe.is_empty() or potion_crafting_active:
		return false
	return total_mana >= int(recipe.get("CostMana", 0)) and sacred_pond_spirit_energy >= int(recipe.get("CostSpirit", 0)) and has_potion_ingredients(recipe_id)


func start_potion_craft(recipe_id: String) -> bool:
	var recipe := get_potion_recipe_data(recipe_id)
	if recipe.is_empty():
		save_status_changed.emit("Unknown recipe.")
		return false
	if potion_crafting_active:
		save_status_changed.emit("Potion already crafting.")
		return false
	var cost_mana := int(recipe.get("CostMana", 0))
	var cost_spirit := int(recipe.get("CostSpirit", 0))
	if total_mana < cost_mana:
		save_status_changed.emit("Not enough Mana.")
		return false
	if sacred_pond_spirit_energy < cost_spirit:
		save_status_changed.emit("Not enough Spirit Energy.")
		return false
	if not has_potion_ingredients(recipe_id):
		save_status_changed.emit("Missing potion ingredients.")
		return false

	total_mana -= cost_mana
	sacred_pond_spirit_energy -= cost_spirit
	_spend_potion_ingredients(recipe_id)
	potion_current_craft_time = float(get_potion_craft_time(recipe_id))
	potion_crafting_recipe_id = recipe_id
	potion_crafting_active = true
	resources_changed.emit()
	potion_shop_changed.emit()
	inventory_changed.emit()
	save_game()
	return true


func start_mana_potion_craft() -> bool:
	return start_potion_craft(POTION_RECIPE_MANA)


func update_potion_crafting(delta: float) -> void:
	if not potion_crafting_active or delta <= 0.0:
		return

	potion_current_craft_time = max(0.0, potion_current_craft_time - delta)
	if potion_current_craft_time <= 0.0:
		potion_crafting_active = false
		_add_potion_to_inventory(potion_crafting_recipe_id, 1)
		add_quest_progress(QUEST_GOAL_CRAFT_POTION, 1)
		inventory_changed.emit()
		potion_shop_changed.emit()
		save_game()
	else:
		potion_shop_changed.emit()


func sell_mana_potion() -> bool:
	return sell_potion(POTION_RECIPE_MANA)


func sell_potion(recipe_id: String) -> bool:
	var recipe := get_potion_recipe_data(recipe_id)
	if recipe.is_empty():
		save_status_changed.emit("Unknown recipe.")
		return false
	_sync_potion_inventory_from_legacy()
	if get_potion_count(recipe_id) <= 0:
		save_status_changed.emit("No %s to sell." % String(recipe.get("Name", "potions")))
		return false

	potion_inventory[recipe_id] = get_potion_count(recipe_id) - 1
	_sync_legacy_mana_potion_count()
	total_coins += get_potion_sell_value(recipe_id)
	resources_changed.emit()
	inventory_changed.emit()
	potion_shop_changed.emit()
	save_game()
	return true


func _add_potion_to_inventory(recipe_id: String, amount: int) -> void:
	if amount <= 0:
		return
	_sync_potion_inventory_from_legacy()
	potion_inventory[recipe_id] = get_potion_count(recipe_id) + amount
	_sync_legacy_mana_potion_count()


func _sync_potion_inventory_from_legacy() -> void:
	if not potion_inventory.has(POTION_RECIPE_MANA):
		potion_inventory[POTION_RECIPE_MANA] = mana_potion_count
	elif mana_potion_count > int(potion_inventory.get(POTION_RECIPE_MANA, 0)):
		potion_inventory[POTION_RECIPE_MANA] = mana_potion_count


func _sync_legacy_mana_potion_count() -> void:
	mana_potion_count = int(potion_inventory.get(POTION_RECIPE_MANA, 0))


func _set_potion_inventory_from_save(saved_inventory) -> void:
	potion_inventory.clear()
	if saved_inventory is Dictionary:
		for recipe_id in saved_inventory.keys():
			var clean_recipe_id := String(recipe_id)
			if get_potion_recipe_data(clean_recipe_id).is_empty():
				continue
			potion_inventory[clean_recipe_id] = max(0, int(saved_inventory.get(recipe_id, 0)))
	_sync_potion_inventory_from_legacy()
	_sync_legacy_mana_potion_count()


func _sync_potion_ingredients() -> void:
	for ingredient_id in [POTION_INGREDIENT_MANA_CRYSTAL, POTION_INGREDIENT_DREAMBLOOM, POTION_INGREDIENT_EMPTY_VIAL]:
		if not potion_ingredients.has(ingredient_id):
			potion_ingredients[ingredient_id] = 0


func _set_potion_ingredients_from_save(saved_ingredients) -> void:
	potion_ingredients.clear()
	if saved_ingredients is Dictionary:
		for ingredient_id in saved_ingredients.keys():
			var clean_id := String(ingredient_id)
			if clean_id not in [POTION_INGREDIENT_MANA_CRYSTAL, POTION_INGREDIENT_DREAMBLOOM, POTION_INGREDIENT_EMPTY_VIAL]:
				continue
			potion_ingredients[clean_id] = max(0, int(saved_ingredients.get(ingredient_id, 0)))
	_sync_potion_ingredients()


func upgrade_potion_shop() -> bool:
	if total_coins < potion_shop_upgrade_cost:
		save_status_changed.emit("Not enough Coins.")
		return false

	total_coins -= potion_shop_upgrade_cost
	potion_shop_level += 1
	resources_changed.emit()
	potion_shop_changed.emit()
	save_game()
	return true


func get_market_order_data(order_id: String) -> Dictionary:
	match order_id:
		"mana_bundle":
			return {
				"OrderID": "mana_bundle",
				"Title": "Mana Bundle",
				"CostMana": 25,
				"CostPotions": 0,
				"CostSpirit": 0,
				"RewardCoins": 35,
				"ReputationReward": 1,
				"Description": "Trade gathered Mana for village Coins."
			}
		"potion_crate":
			return {
				"OrderID": "potion_crate",
				"Title": "Potion Crate",
				"CostMana": 0,
				"CostPotions": 1,
				"CostSpirit": 0,
				"RewardCoins": 75,
				"ReputationReward": 1,
				"Description": "Sell a finished Mana Potion to traveling sprites."
			}
		"spirit_contract":
			return {
				"OrderID": "spirit_contract",
				"Title": "Spirit Contract",
				"CostMana": 10,
				"CostPotions": 0,
				"CostSpirit": 10,
				"RewardCoins": 110,
				"ReputationReward": 2,
				"Description": "Bind pond Spirit Energy into a high-value contract."
			}
	return {}


func get_market_orders() -> Array[Dictionary]:
	return [
		get_market_order_data("mana_bundle"),
		get_market_order_data("potion_crate"),
		get_market_order_data("spirit_contract")
	]


func fulfill_market_order(order_id: String) -> Dictionary:
	var order := get_market_order_data(order_id)
	if order.is_empty():
		save_status_changed.emit("Unknown market order.")
		return {"Success": false, "Message": "Unknown market order."}

	var cost_mana := int(order.get("CostMana", 0))
	var cost_potions := int(order.get("CostPotions", 0))
	var cost_spirit := int(order.get("CostSpirit", 0))
	if total_mana < cost_mana:
		save_status_changed.emit("Not enough Mana.")
		return {"Success": false, "Message": "Not enough Mana."}
	if mana_potion_count < cost_potions:
		save_status_changed.emit("Not enough Mana Potions.")
		return {"Success": false, "Message": "Not enough Mana Potions."}
	if sacred_pond_spirit_energy < cost_spirit:
		save_status_changed.emit("Not enough Spirit Energy.")
		return {"Success": false, "Message": "Not enough Spirit Energy."}

	total_mana -= cost_mana
	mana_potion_count -= cost_potions
	sacred_pond_spirit_energy -= cost_spirit
	total_coins += int(order.get("RewardCoins", 0))
	market_orders_completed += 1
	market_reputation += int(order.get("ReputationReward", 1))
	add_quest_progress(QUEST_GOAL_MARKET_TRADE, 1)

	resources_changed.emit()
	inventory_changed.emit()
	market_stall_changed.emit()
	potion_shop_changed.emit()
	sacred_pond_changed.emit()
	save_game()
	var message := "%s fulfilled!" % String(order.get("Title", "Order"))
	save_status_changed.emit(message)
	return {"Success": true, "Message": message}


func update_ancient_tree_level() -> void:
	if ancient_tree_growth >= 100:
		ancient_tree_level = 5
	elif ancient_tree_growth >= 75:
		ancient_tree_level = 4
	elif ancient_tree_growth >= 50:
		ancient_tree_level = 3
	elif ancient_tree_growth >= 25:
		ancient_tree_level = 2
	else:
		ancient_tree_level = 1


func restore_ancient_tree() -> Dictionary:
	return water_ancient_tree()


func water_ancient_tree() -> Dictionary:
	_prune_ancient_tree_water_timestamps()
	if ancient_tree_water_timestamps.size() >= ANCIENT_TREE_WATER_LIMIT:
		var wait_text := get_ancient_tree_water_reset_text()
		var blocked_message := "The Ancient Tree is resting. Water again in %s." % wait_text
		save_status_changed.emit(blocked_message)
		return {"Success": false, "Message": blocked_message, "RewardText": ""}

	var previous_level := ancient_tree_level
	ancient_tree_water_timestamps.append(_get_now_unix())
	ancient_tree_growth = min(100, ancient_tree_growth + 10)
	update_ancient_tree_level()
	if previous_level < 2 and ancient_tree_level >= 2:
		add_quest_progress(QUEST_GOAL_RESTORE_TREE, 1)
	var watering_reward := _grant_ancient_tree_watering_reward()
	resources_changed.emit()
	inventory_changed.emit()
	ancient_tree_changed.emit()
	save_game()
	var reward_text := String(watering_reward.get("Text", ""))
	var remaining := get_ancient_tree_water_uses_remaining()
	var message := "The Ancient Tree shared %s. %d water%s left this hour." % [
		reward_text,
		remaining,
		"" if remaining == 1 else "s"
	]
	save_status_changed.emit(message)
	return {
		"Success": true,
		"Message": message,
		"RewardType": String(watering_reward.get("Type", "")),
		"RewardAmount": int(watering_reward.get("Amount", 0)),
		"RewardText": reward_text,
		"Growth": ancient_tree_growth,
		"RemainingWaters": remaining
	}


func can_water_ancient_tree() -> bool:
	return get_ancient_tree_water_uses_remaining() > 0


func get_ancient_tree_water_uses_remaining() -> int:
	_prune_ancient_tree_water_timestamps()
	return max(0, ANCIENT_TREE_WATER_LIMIT - ancient_tree_water_timestamps.size())


func get_ancient_tree_water_status_text() -> String:
	var remaining := get_ancient_tree_water_uses_remaining()
	if remaining > 0:
		return "Water uses available: %d / %d" % [remaining, ANCIENT_TREE_WATER_LIMIT]
	return "Water again in %s" % get_ancient_tree_water_reset_text()


func get_ancient_tree_water_reset_text() -> String:
	_prune_ancient_tree_water_timestamps()
	if ancient_tree_water_timestamps.is_empty():
		return "now"
	var oldest := int(ancient_tree_water_timestamps[0])
	var seconds_left: int = max(1, ANCIENT_TREE_WATER_WINDOW_SECONDS - (_get_now_unix() - oldest))
	var minutes_left := int(ceil(float(seconds_left) / 60.0))
	if minutes_left >= 60:
		return "1 hour"
	return "%d minute%s" % [minutes_left, "" if minutes_left == 1 else "s"]


func _prune_ancient_tree_water_timestamps() -> void:
	var now := _get_now_unix()
	var kept: Array[int] = []
	for timestamp in ancient_tree_water_timestamps:
		if now - int(timestamp) < ANCIENT_TREE_WATER_WINDOW_SECONDS:
			kept.append(int(timestamp))
	ancient_tree_water_timestamps = kept


func _get_now_unix() -> int:
	return int(Time.get_unix_time_from_system())


func _grant_ancient_tree_watering_reward() -> Dictionary:
	var amount := 0
	match randi() % 4:
		0:
			amount = randi_range(12, 26) + ancient_tree_level * 3
			total_mana += amount
			return {"Type": "Mana", "Amount": amount, "Text": "+%d Mana" % amount}
		1:
			amount = randi_range(8, 22) + ancient_tree_level * 4
			total_coins += amount
			return {"Type": "Coins", "Amount": amount, "Text": "+%d Coins" % amount}
		2:
			amount = randi_range(8, 18) + ancient_tree_level * 3
			ancient_tree_experience += amount
			return {"Type": "Tree XP", "Amount": amount, "Text": "+%d Tree XP" % amount}
		_:
			amount = 1
			if ancient_tree_level >= 3 and randi_range(0, 1) == 1:
				amount += 1
			ancient_tree_seed_count += amount
			return {"Type": "Ancient Seeds", "Amount": amount, "Text": "+%d Ancient Seed%s" % [amount, "" if amount == 1 else "s"]}


func get_ancient_tree_reward_data(level: int) -> Dictionary:
	match level:
		2:
			return {"Level": 2, "Title": "Root Memory", "RewardMana": 25, "RewardCoins": 0}
		3:
			return {"Level": 3, "Title": "Branch Blessing", "RewardMana": 50, "RewardCoins": 40}
		4:
			return {"Level": 4, "Title": "Canopy Promise", "RewardMana": 75, "RewardCoins": 80}
		5:
			return {"Level": 5, "Title": "Heartwood Awakening", "RewardMana": 100, "RewardCoins": 150}
	return {}


func claim_ancient_tree_reward(level: int) -> Dictionary:
	var reward := get_ancient_tree_reward_data(level)
	if reward.is_empty():
		save_status_changed.emit("No reward at that level.")
		return {"Success": false, "Message": "No reward at that level."}
	if ancient_tree_level < level:
		save_status_changed.emit("Restore the Ancient Tree further.")
		return {"Success": false, "Message": "Restore the Ancient Tree further."}
	if ancient_tree_claimed_rewards.has(level):
		save_status_changed.emit("Reward already claimed.")
		return {"Success": false, "Message": "Reward already claimed."}

	ancient_tree_claimed_rewards.append(level)
	total_mana += int(reward.get("RewardMana", 0))
	total_coins += int(reward.get("RewardCoins", 0))
	resources_changed.emit()
	ancient_tree_changed.emit()
	save_game()
	var message := "%s claimed!" % String(reward.get("Title", "Reward"))
	save_status_changed.emit(message)
	return {"Success": true, "Message": message}


func get_next_ancient_tree_reward_text() -> String:
	for level in [2, 3, 4, 5]:
		if ancient_tree_claimed_rewards.has(level):
			continue
		var reward_thresholds: Array[int] = [0, 0, 25, 50, 75, 100]
		var threshold: int = reward_thresholds[level]
		if ancient_tree_level >= level:
			return "Level %d reward ready" % level
		return "Level %d reward at %d%% restoration" % [level, threshold]
	return "All Ancient Tree rewards claimed"


func get_forge_upgrade_data(upgrade_id: String) -> Dictionary:
	match upgrade_id:
		"flower_focus":
			return {
				"UpgradeID": "flower_focus",
				"Title": "Flower Focus",
				"Level": forge_flower_focus_level,
				"MaxLevel": 3,
				"CostMana": 100 + forge_flower_focus_level * 75,
				"CostCoins": 50 + forge_flower_focus_level * 50,
				"CostSpirit": 0,
				"Description": "+2 Flower Grove Mana/sec per level."
			}
		"potion_gilding":
			return {
				"UpgradeID": "potion_gilding",
				"Title": "Potion Gilding",
				"Level": forge_potion_gilding_level,
				"MaxLevel": 3,
				"CostMana": 75 + forge_potion_gilding_level * 60,
				"CostCoins": 100 + forge_potion_gilding_level * 65,
				"CostSpirit": 0,
				"Description": "+15 Coins per Mana Potion sale per level."
			}
		"pond_resonance":
			return {
				"UpgradeID": "pond_resonance",
				"Title": "Pond Resonance",
				"Level": forge_pond_resonance_level,
				"MaxLevel": 3,
				"CostMana": 50 + forge_pond_resonance_level * 50,
				"CostCoins": 50 + forge_pond_resonance_level * 50,
				"CostSpirit": 20 + forge_pond_resonance_level * 10,
				"Description": "+2 Sacred Pond restore power per level."
			}
	return {}


func get_forge_upgrades() -> Array[Dictionary]:
	return [
		get_forge_upgrade_data("flower_focus"),
		get_forge_upgrade_data("potion_gilding"),
		get_forge_upgrade_data("pond_resonance")
	]


func purchase_forge_upgrade(upgrade_id: String) -> Dictionary:
	var upgrade := get_forge_upgrade_data(upgrade_id)
	if upgrade.is_empty():
		save_status_changed.emit("Unknown forge upgrade.")
		return {"Success": false, "Message": "Unknown forge upgrade."}

	var level := int(upgrade.get("Level", 0))
	var max_level := int(upgrade.get("MaxLevel", 3))
	if level >= max_level:
		save_status_changed.emit("Forge upgrade is maxed.")
		return {"Success": false, "Message": "Forge upgrade is maxed."}

	var cost_mana := int(upgrade.get("CostMana", 0))
	var cost_coins := int(upgrade.get("CostCoins", 0))
	var cost_spirit := int(upgrade.get("CostSpirit", 0))
	if total_mana < cost_mana:
		save_status_changed.emit("Not enough Mana.")
		return {"Success": false, "Message": "Not enough Mana."}
	if total_coins < cost_coins:
		save_status_changed.emit("Not enough Coins.")
		return {"Success": false, "Message": "Not enough Coins."}
	if sacred_pond_spirit_energy < cost_spirit:
		save_status_changed.emit("Not enough Spirit Energy.")
		return {"Success": false, "Message": "Not enough Spirit Energy."}

	total_mana -= cost_mana
	total_coins -= cost_coins
	sacred_pond_spirit_energy -= cost_spirit
	if upgrade_id == "flower_focus":
		forge_flower_focus_level += 1
		flower_grove_base_mana_production_rate += 2.0
	elif upgrade_id == "potion_gilding":
		forge_potion_gilding_level += 1
		potion_sell_value += 15
	elif upgrade_id == "pond_resonance":
		forge_pond_resonance_level += 1
		sacred_pond_base_restore_amount += 2
	forge_level = 1 + forge_flower_focus_level + forge_potion_gilding_level + forge_pond_resonance_level
	add_quest_progress(QUEST_GOAL_FORGE_UPGRADE, 1)

	resources_changed.emit()
	flower_grove_changed.emit()
	potion_shop_changed.emit()
	sacred_pond_changed.emit()
	arcane_forge_changed.emit()
	save_game()
	var message := "%s forged!" % String(upgrade.get("Title", "Upgrade"))
	save_status_changed.emit(message)
	return {"Success": true, "Message": message}


func update_sacred_pond_level_and_rewards() -> void:
	if sacred_pond_water_purity >= 100:
		sacred_pond_level = 5
	elif sacred_pond_water_purity >= 75:
		sacred_pond_level = 4
	elif sacred_pond_water_purity >= 50:
		sacred_pond_level = 3
	elif sacred_pond_water_purity >= 25:
		sacred_pond_level = 2
	else:
		sacred_pond_level = 1

	if sacred_pond_level >= 2:
		_unlock_pond_reward(POND_BONUS_BLOOMING_WATERS)
	if sacred_pond_level >= 3:
		_unlock_pond_reward(POND_BONUS_MOONLIT_REFLECTION)
	if sacred_pond_level >= 4:
		_unlock_pond_reward(POND_BONUS_FAIRY_BLESSING)
	if sacred_pond_level >= 5:
		_unlock_pond_reward(POND_BONUS_SUN_KOI_GUARDIAN)

	active_pond_bonus = _get_highest_active_pond_bonus()


func _unlock_pond_reward(reward_name: String) -> void:
	if is_pond_reward_unlocked(reward_name):
		return
	unlocked_pond_rewards.append(reward_name)
	if reward_name == POND_BONUS_MOONLIT_REFLECTION:
		flower_grove_max_stored_mana += 10
	elif reward_name == POND_BONUS_FAIRY_BLESSING:
		fairy_max_residents += 1


func _get_highest_active_pond_bonus() -> String:
	if is_pond_reward_unlocked(POND_BONUS_SUN_KOI_GUARDIAN):
		return POND_BONUS_SUN_KOI_GUARDIAN
	if is_pond_reward_unlocked(POND_BONUS_FAIRY_BLESSING):
		return POND_BONUS_FAIRY_BLESSING
	if is_pond_reward_unlocked(POND_BONUS_MOONLIT_REFLECTION):
		return POND_BONUS_MOONLIT_REFLECTION
	if is_pond_reward_unlocked(POND_BONUS_BLOOMING_WATERS):
		return POND_BONUS_BLOOMING_WATERS
	return POND_BONUS_NONE


func is_pond_reward_unlocked(reward_name: String) -> bool:
	return unlocked_pond_rewards.has(reward_name)


func get_active_pond_bonus_text() -> String:
	if active_pond_bonus == POND_BONUS_BLOOMING_WATERS:
		return "Blooming Waters +5% Flower Production"
	if active_pond_bonus == POND_BONUS_MOONLIT_REFLECTION:
		return "Moonlit Reflection +10 Max Stored Mana"
	if active_pond_bonus == POND_BONUS_FAIRY_BLESSING:
		return "Fairy Blessing +1 Fairy House Capacity"
	if active_pond_bonus == POND_BONUS_SUN_KOI_GUARDIAN:
		return "Sun Koi Guardian +1 Spirit Energy per Restore"
	return "None"


func get_next_pond_reward_text() -> String:
	if sacred_pond_water_purity < 25:
		return "Blooming Waters at 25%"
	if sacred_pond_water_purity < 50:
		return "Moonlit Reflection at 50%"
	if sacred_pond_water_purity < 75:
		return "Fairy Blessing at 75%"
	if sacred_pond_water_purity < 100:
		return "Sun Koi Guardian at 100%"
	return "All pond rewards unlocked"


func assign_fairy_to_area(fairy_name: String, area: String) -> String:
	var clean_area := area
	if clean_area == "Sacred Pond":
		clean_area = FAIRY_AREA_SACRED_POND
	if clean_area not in [FAIRY_AREA_FLOWER_GROVE, FAIRY_AREA_SACRED_POND, FAIRY_AREA_UNASSIGNED]:
		return "Unknown assignment."

	for index in range(fairies.size()):
		if fairies[index].get("FairyName", "") == fairy_name and bool(fairies[index].get("IsUnlocked", false)):
			fairies[index]["AssignedArea"] = clean_area
			recalculate_fairy_bonuses()
			resources_changed.emit()
			flower_grove_changed.emit()
			sacred_pond_changed.emit()
			fairy_house_changed.emit()
			if clean_area == FAIRY_AREA_FLOWER_GROVE:
				add_quest_progress(QUEST_GOAL_ASSIGN_FLOWER_FAIRY, 1)
			save_game()
			if clean_area == FAIRY_AREA_FLOWER_GROVE:
				return "%s assigned to Flower Grove" % fairy_name
			if clean_area == FAIRY_AREA_SACRED_POND:
				return "%s assigned to Sacred Pond" % fairy_name
			return "%s is resting" % fairy_name

	return "%s is not available." % fairy_name


func update_fairy_tasks(delta: float) -> void:
	if delta <= 0.0:
		return
	var changed := false
	var house_speed_multiplier := get_fairy_house_task_speed_multiplier()
	var flower_speed := _get_fairy_task_speed(FAIRY_TASK_FLOWER_GROVE)
	if flower_speed > 0.0:
		changed = _advance_fairy_task(FAIRY_TASK_FLOWER_GROVE, flower_speed * house_speed_multiplier * delta) or changed
	var forage_speed := _get_fairy_task_speed(FAIRY_TASK_FORAGE_INGREDIENTS)
	if forage_speed > 0.0:
		changed = _advance_fairy_task(FAIRY_TASK_FORAGE_INGREDIENTS, forage_speed * house_speed_multiplier * delta * 0.75) or changed
	var pond_speed := _get_fairy_task_speed(FAIRY_TASK_SACRED_POND)
	if pond_speed > 0.0:
		changed = _advance_fairy_task(FAIRY_TASK_SACRED_POND, pond_speed * house_speed_multiplier * delta) or changed
	if changed:
		fairy_house_changed.emit()


func _advance_fairy_task(task_id: String, amount: float) -> bool:
	var progress := float(fairy_task_progress.get(task_id, 0.0)) + amount
	var ready_count := int(fairy_task_ready_counts.get(task_id, 0))
	var changed := false
	while progress >= FAIRY_TASK_REQUIRED_PROGRESS:
		progress -= FAIRY_TASK_REQUIRED_PROGRESS
		ready_count += 1
		changed = true
	fairy_task_progress[task_id] = progress
	fairy_task_ready_counts[task_id] = ready_count
	return changed


func _get_fairy_task_speed(task_id: String) -> float:
	var speed := 0.0
	for fairy in fairies:
		if not bool(fairy.get("IsUnlocked", false)):
			continue
		if String(fairy.get("AssignedArea", FAIRY_AREA_UNASSIGNED)) != _get_fairy_task_area(task_id):
			continue
		speed += _get_fairy_task_contribution(fairy, task_id)
	return speed


func _get_fairy_task_area(task_id: String) -> String:
	if task_id == FAIRY_TASK_SACRED_POND:
		return FAIRY_AREA_SACRED_POND
	return FAIRY_AREA_FLOWER_GROVE


func _get_fairy_task_contribution(fairy: Dictionary, task_id: String) -> float:
	var work_bonus: float = max(0.5, float(fairy.get("WorkBonus", 1.0)))
	return work_bonus * _get_fairy_role_task_multiplier(fairy, task_id)


func _get_fairy_role_task_multiplier(fairy: Dictionary, task_id: String) -> float:
	var role := String(fairy.get("FairyRole", "Helper"))
	var training_bonus := get_fairy_house_role_training_bonus()
	if task_id == FAIRY_TASK_FLOWER_GROVE:
		if role == "Gatherer":
			return 1.0 + training_bonus
		if role == "Forager":
			return 0.9
		if role == "Pond Keeper":
			return 0.85
	if task_id == FAIRY_TASK_FORAGE_INGREDIENTS:
		if role == "Forager":
			return 1.6 + training_bonus
		if role == "Gatherer":
			return 0.75
		if role == "Pond Keeper":
			return 0.65
	if task_id == FAIRY_TASK_SACRED_POND:
		if role == "Pond Keeper":
			return 1.0 + training_bonus
		if role == "Gatherer":
			return 0.9
		if role == "Forager":
			return 0.8
	return 1.0


func get_fairy_task_progress_percent(task_id: String) -> int:
	return int(floor((float(fairy_task_progress.get(task_id, 0.0)) / FAIRY_TASK_REQUIRED_PROGRESS) * 100.0))


func get_fairy_task_progress_text(task_id: String) -> String:
	var progress := float(fairy_task_progress.get(task_id, 0.0))
	return "%d / %d progress" % [int(floor(progress)), int(FAIRY_TASK_REQUIRED_PROGRESS)]


func get_fairy_task_ready_count(task_id: String) -> int:
	return int(fairy_task_ready_counts.get(task_id, 0))


func get_total_fairy_task_ready_count() -> int:
	var total := 0
	for task_id in FAIRY_TASK_IDS:
		total += get_fairy_task_ready_count(task_id)
	return total


func get_fairy_task_inbox_text() -> String:
	var ready_count := get_total_fairy_task_ready_count()
	if ready_count > 0:
		return "%d fairy reward%s ready to collect." % [ready_count, "" if ready_count == 1 else "s"]
	var active_count := 0
	for task_id in FAIRY_TASK_IDS:
		if _get_fairy_task_speed(task_id) > 0.0:
			active_count += 1
	if active_count > 0:
		return "%d fairy task%s in progress." % [active_count, "" if active_count == 1 else "s"]
	return "Assign fairies to begin gathering rewards."


func get_fairy_task_status_text(task_id: String) -> String:
	var ready_count := get_fairy_task_ready_count(task_id)
	if ready_count > 0:
		return "Ready to collect"
	if _get_fairy_task_speed(task_id) > 0.0:
		return "Working"
	return "Idle"


func get_fairy_task_time_remaining_text(task_id: String) -> String:
	if get_fairy_task_ready_count(task_id) > 0:
		return "Reward waiting"
	var speed: float = _get_adjusted_fairy_task_speed(task_id)
	if speed <= 0.0:
		return "Assign a fairy to begin"
	var remaining: float = max(0.0, FAIRY_TASK_REQUIRED_PROGRESS - float(fairy_task_progress.get(task_id, 0.0)))
	return "Next reward in about %ds" % int(ceil(remaining / speed))


func get_fairy_task_cards() -> Array[Dictionary]:
	return [
		{
			"TaskID": FAIRY_TASK_FLOWER_GROVE,
			"Title": "Gather Mana",
			"Area": FAIRY_AREA_FLOWER_GROVE,
			"Workers": _get_fairies_for_assignment(FAIRY_AREA_FLOWER_GROVE),
			"WorkerText": get_fairy_task_worker_text(FAIRY_TASK_FLOWER_GROVE),
			"StatusText": get_fairy_task_status_text(FAIRY_TASK_FLOWER_GROVE),
			"TaskRateText": get_fairy_task_rate_text(FAIRY_TASK_FLOWER_GROVE),
			"TimeRemainingText": get_fairy_task_time_remaining_text(FAIRY_TASK_FLOWER_GROVE),
			"ProgressPercent": get_fairy_task_progress_percent(FAIRY_TASK_FLOWER_GROVE),
			"ProgressText": get_fairy_task_progress_text(FAIRY_TASK_FLOWER_GROVE),
			"ReadyCount": get_fairy_task_ready_count(FAIRY_TASK_FLOWER_GROVE),
			"RewardText": "+%d Mana" % get_fairy_task_reward_amount(FAIRY_TASK_FLOWER_GROVE),
			"IsReady": get_fairy_task_ready_count(FAIRY_TASK_FLOWER_GROVE) > 0,
			"IsActive": _get_fairy_task_speed(FAIRY_TASK_FLOWER_GROVE) > 0.0
		},
		{
			"TaskID": FAIRY_TASK_FORAGE_INGREDIENTS,
			"Title": "Forage Ingredients",
			"Area": FAIRY_AREA_FLOWER_GROVE,
			"Workers": _get_fairies_for_assignment(FAIRY_AREA_FLOWER_GROVE),
			"WorkerText": get_fairy_task_worker_text(FAIRY_TASK_FORAGE_INGREDIENTS),
			"StatusText": get_fairy_task_status_text(FAIRY_TASK_FORAGE_INGREDIENTS),
			"TaskRateText": get_fairy_task_rate_text(FAIRY_TASK_FORAGE_INGREDIENTS),
			"TimeRemainingText": get_fairy_task_time_remaining_text(FAIRY_TASK_FORAGE_INGREDIENTS),
			"ProgressPercent": get_fairy_task_progress_percent(FAIRY_TASK_FORAGE_INGREDIENTS),
			"ProgressText": get_fairy_task_progress_text(FAIRY_TASK_FORAGE_INGREDIENTS),
			"ReadyCount": get_fairy_task_ready_count(FAIRY_TASK_FORAGE_INGREDIENTS),
			"RewardText": "Mana Crystal, Dreambloom x2, Empty Vial",
			"IsReady": get_fairy_task_ready_count(FAIRY_TASK_FORAGE_INGREDIENTS) > 0,
			"IsActive": _get_fairy_task_speed(FAIRY_TASK_FORAGE_INGREDIENTS) > 0.0
		},
		{
			"TaskID": FAIRY_TASK_SACRED_POND,
			"Title": "Tend Waters",
			"Area": FAIRY_AREA_SACRED_POND,
			"Workers": _get_fairies_for_assignment(FAIRY_AREA_SACRED_POND),
			"WorkerText": get_fairy_task_worker_text(FAIRY_TASK_SACRED_POND),
			"StatusText": get_fairy_task_status_text(FAIRY_TASK_SACRED_POND),
			"TaskRateText": get_fairy_task_rate_text(FAIRY_TASK_SACRED_POND),
			"TimeRemainingText": get_fairy_task_time_remaining_text(FAIRY_TASK_SACRED_POND),
			"ProgressPercent": get_fairy_task_progress_percent(FAIRY_TASK_SACRED_POND),
			"ProgressText": get_fairy_task_progress_text(FAIRY_TASK_SACRED_POND),
			"ReadyCount": get_fairy_task_ready_count(FAIRY_TASK_SACRED_POND),
			"RewardText": "+%d Spirit Energy" % get_fairy_task_reward_amount(FAIRY_TASK_SACRED_POND),
			"IsReady": get_fairy_task_ready_count(FAIRY_TASK_SACRED_POND) > 0,
			"IsActive": _get_fairy_task_speed(FAIRY_TASK_SACRED_POND) > 0.0
		}
	]


func _get_fairies_for_assignment(area: String) -> Array[String]:
	var names: Array[String] = []
	for fairy in fairies:
		if not bool(fairy.get("IsUnlocked", false)):
			continue
		if String(fairy.get("AssignedArea", FAIRY_AREA_UNASSIGNED)) == area:
			names.append(String(fairy.get("FairyName", "Fairy")))
	return names


func get_fairy_task_worker_text(task_id: String) -> String:
	var area := _get_fairy_task_area(task_id)
	var parts: Array[String] = []
	for fairy in fairies:
		if not bool(fairy.get("IsUnlocked", false)):
			continue
		if String(fairy.get("AssignedArea", FAIRY_AREA_UNASSIGNED)) != area:
			continue
		parts.append("%s %.1fx" % [
			String(fairy.get("FairyName", "Fairy")),
			_get_fairy_task_contribution(fairy, task_id)
		])
	if parts.is_empty():
		return "No fairies assigned"
	return ", ".join(parts)


func _get_adjusted_fairy_task_speed(task_id: String) -> float:
	var speed := _get_fairy_task_speed(task_id) * get_fairy_house_task_speed_multiplier()
	return speed * (0.75 if task_id == FAIRY_TASK_FORAGE_INGREDIENTS else 1.0)


func get_fairy_task_rate_text(task_id: String) -> String:
	var adjusted_speed := _get_adjusted_fairy_task_speed(task_id)
	if adjusted_speed <= 0.0:
		return "Idle"
	var seconds := FAIRY_TASK_REQUIRED_PROGRESS / adjusted_speed
	return "%.1fx speed, about %ds" % [adjusted_speed, int(ceil(seconds))]


func get_fairy_task_reward_amount(task_id: String) -> int:
	if task_id == FAIRY_TASK_FLOWER_GROVE:
		return int(round((20 + _get_fairies_for_assignment(FAIRY_AREA_FLOWER_GROVE).size() * 5) * get_fairy_house_reward_multiplier()))
	if task_id == FAIRY_TASK_SACRED_POND:
		return max(1, int(round(max(1, _get_fairies_for_assignment(FAIRY_AREA_SACRED_POND).size()) * get_fairy_house_reward_multiplier())))
	return 0


func collect_fairy_task_reward(task_id: String) -> Dictionary:
	var ready_count := int(fairy_task_ready_counts.get(task_id, 0))
	if ready_count <= 0:
		return {"Success": false, "Message": "No fairy task reward ready."}

	var reward_amount := get_fairy_task_reward_amount(task_id)
	fairy_task_ready_counts[task_id] = ready_count - 1
	var level_up_names := _grant_fairy_task_xp(task_id)
	if task_id == FAIRY_TASK_FLOWER_GROVE:
		total_mana += reward_amount
		add_quest_progress(QUEST_GOAL_COLLECT_MANA, reward_amount)
		resources_changed.emit()
		fairy_house_changed.emit()
		save_game()
		var mana_message := _append_fairy_level_message("Fairies delivered %d Mana." % reward_amount, level_up_names)
		save_status_changed.emit(mana_message)
		return {"Success": true, "Message": mana_message, "LevelUpNames": level_up_names, "FloatingText": "+%d Mana" % reward_amount}
	if task_id == FAIRY_TASK_SACRED_POND:
		sacred_pond_spirit_energy += reward_amount
		resources_changed.emit()
		sacred_pond_changed.emit()
		fairy_house_changed.emit()
		save_game()
		var pond_message := _append_fairy_level_message("Fairies gathered %d Spirit Energy." % reward_amount, level_up_names)
		save_status_changed.emit(pond_message)
		return {"Success": true, "Message": pond_message, "LevelUpNames": level_up_names, "FloatingText": "+%d Spirit" % reward_amount}
	if task_id == FAIRY_TASK_FORAGE_INGREDIENTS:
		add_potion_ingredient(POTION_INGREDIENT_MANA_CRYSTAL, 1)
		add_potion_ingredient(POTION_INGREDIENT_DREAMBLOOM, 2)
		add_potion_ingredient(POTION_INGREDIENT_EMPTY_VIAL, 1)
		fairy_house_changed.emit()
		save_game()
		var ingredient_message := _append_fairy_level_message("Fairies delivered potion ingredients.", level_up_names)
		save_status_changed.emit(ingredient_message)
		return {"Success": true, "Message": ingredient_message, "LevelUpNames": level_up_names, "FloatingText": "+Ingredients"}
	return {"Success": false, "Message": "Unknown fairy task."}


func collect_all_fairy_task_rewards() -> Dictionary:
	var starting_ready_count := get_total_fairy_task_ready_count()
	if starting_ready_count <= 0:
		return {"Success": false, "Message": "No fairy task rewards ready.", "ClaimedCount": 0, "LevelUpNames": []}

	var claimed_count := 0
	var mana_gained := 0
	var spirit_gained := 0
	var ingredient_rewards := 0
	var level_up_names: Array[String] = []
	for task_id in FAIRY_TASK_IDS:
		while get_fairy_task_ready_count(task_id) > 0:
			var before_mana := total_mana
			var before_spirit := sacred_pond_spirit_energy
			var result: Dictionary = collect_fairy_task_reward(task_id)
			if not bool(result.get("Success", false)):
				break
			claimed_count += 1
			mana_gained += max(0, total_mana - before_mana)
			spirit_gained += max(0, sacred_pond_spirit_energy - before_spirit)
			if task_id == FAIRY_TASK_FORAGE_INGREDIENTS:
				ingredient_rewards += 1
			for fairy_name in result.get("LevelUpNames", []):
				var clean_name := String(fairy_name)
				if not level_up_names.has(clean_name):
					level_up_names.append(clean_name)

	var parts: Array[String] = []
	if mana_gained > 0:
		parts.append("%d Mana" % mana_gained)
	if spirit_gained > 0:
		parts.append("%d Spirit" % spirit_gained)
	if ingredient_rewards > 0:
		parts.append("%d ingredient bundle%s" % [ingredient_rewards, "" if ingredient_rewards == 1 else "s"])
	var reward_text := ", ".join(parts) if not parts.is_empty() else "fairy rewards"
	var message := _append_fairy_level_message("Collected %d fairy reward%s: %s." % [claimed_count, "" if claimed_count == 1 else "s", reward_text], level_up_names)
	save_status_changed.emit(message)
	return {
		"Success": claimed_count > 0,
		"Message": message,
		"ClaimedCount": claimed_count,
		"LevelUpNames": level_up_names,
		"FloatingText": "+%d Rewards" % claimed_count
	}


func _grant_fairy_task_xp(task_id: String) -> Array[String]:
	var level_up_names: Array[String] = []
	var task_area := _get_fairy_task_area(task_id)
	for index in range(fairies.size()):
		if not bool(fairies[index].get("IsUnlocked", false)):
			continue
		if String(fairies[index].get("AssignedArea", FAIRY_AREA_UNASSIGNED)) != task_area:
			continue
		if int(fairies[index].get("FairyLevel", 1)) >= FAIRY_MAX_LEVEL:
			fairies[index]["FairyXP"] = 0
			continue
		fairies[index]["FairyXP"] = int(fairies[index].get("FairyXP", 0)) + get_fairy_house_xp_gain()
		var xp_to_next := get_fairy_xp_to_next_level(fairies[index])
		if int(fairies[index].get("FairyXP", 0)) >= xp_to_next:
			fairies[index]["FairyXP"] = int(fairies[index].get("FairyXP", 0)) - xp_to_next
			fairies[index]["FairyLevel"] = min(FAIRY_MAX_LEVEL, int(fairies[index].get("FairyLevel", 1)) + 1)
			fairies[index]["WorkBonus"] = float(fairies[index].get("WorkBonus", 1.0)) + FAIRY_WORK_BONUS_PER_LEVEL
			level_up_names.append(String(fairies[index].get("FairyName", "Fairy")))
	recalculate_fairy_bonuses()
	if not level_up_names.is_empty():
		resources_changed.emit()
		flower_grove_changed.emit()
		sacred_pond_changed.emit()
	return level_up_names


func _append_fairy_level_message(base_message: String, level_up_names: Array[String]) -> String:
	if level_up_names.is_empty():
		return base_message
	return "%s %s leveled up!" % [base_message, ", ".join(level_up_names)]


func get_fairy_house_task_speed_multiplier() -> float:
	if fairy_house_level < 2:
		return 1.0
	return 1.0 + (float(fairy_house_level - 1) * 0.10)


func get_fairy_house_reward_multiplier() -> float:
	return 1.25 if fairy_house_level >= 4 else 1.0


func get_fairy_house_role_training_bonus() -> float:
	return 0.25 if fairy_house_level >= FAIRY_HOUSE_MAX_LEVEL else 0.0


func get_fairy_house_xp_gain() -> int:
	return 2 if fairy_house_level >= FAIRY_HOUSE_MAX_LEVEL else 1


func get_fairy_house_upgrade_cost(target_level: int = fairy_house_level + 1) -> Dictionary:
	if not FAIRY_HOUSE_UPGRADE_COSTS.has(target_level):
		return {}
	return (FAIRY_HOUSE_UPGRADE_COSTS[target_level] as Dictionary).duplicate(true)


func can_upgrade_fairy_house() -> bool:
	var cost := get_fairy_house_upgrade_cost()
	if cost.is_empty():
		return false
	return total_mana >= int(cost.get("Mana", 0)) and total_coins >= int(cost.get("Coins", 0)) and sacred_pond_spirit_energy >= int(cost.get("Spirit", 0))


func get_fairy_house_upgrade_summary() -> String:
	if fairy_house_level >= FAIRY_HOUSE_MAX_LEVEL:
		return "Max Level: +40% task speed, +25% rewards, role training, and +2 XP per task."
	var next_level := fairy_house_level + 1
	var cost := get_fairy_house_upgrade_cost(next_level)
	var benefit := ""
	match next_level:
		2:
			benefit = "+10% fairy task speed"
		3:
			benefit = "+20% task speed and +1 fairy capacity"
		4:
			benefit = "+30% task speed and +25% task rewards"
		5:
			benefit = "+40% task speed, +1 fairy capacity, role training, and +2 XP per task"
		_:
			benefit = "More fairy support"
	return "Next Level %d: %s\nCost: %d Mana, %d Coins, %d Spirit" % [
		next_level,
		benefit,
		int(cost.get("Mana", 0)),
		int(cost.get("Coins", 0)),
		int(cost.get("Spirit", 0))
	]


func upgrade_fairy_house() -> Dictionary:
	if fairy_house_level >= FAIRY_HOUSE_MAX_LEVEL:
		save_status_changed.emit("Fairy House is maxed.")
		return {"Success": false, "Message": "Fairy House is maxed."}
	var target_level := fairy_house_level + 1
	var cost := get_fairy_house_upgrade_cost(target_level)
	if cost.is_empty():
		save_status_changed.emit("No Fairy House upgrade available.")
		return {"Success": false, "Message": "No Fairy House upgrade available."}
	if total_mana < int(cost.get("Mana", 0)):
		save_status_changed.emit("Not enough Mana.")
		return {"Success": false, "Message": "Not enough Mana."}
	if total_coins < int(cost.get("Coins", 0)):
		save_status_changed.emit("Not enough Coins.")
		return {"Success": false, "Message": "Not enough Coins."}
	if sacred_pond_spirit_energy < int(cost.get("Spirit", 0)):
		save_status_changed.emit("Not enough Spirit Energy.")
		return {"Success": false, "Message": "Not enough Spirit Energy."}

	total_mana -= int(cost.get("Mana", 0))
	total_coins -= int(cost.get("Coins", 0))
	sacred_pond_spirit_energy -= int(cost.get("Spirit", 0))
	fairy_house_level = target_level
	if fairy_house_level == 3 or fairy_house_level == 5:
		fairy_max_residents += 1
	recalculate_fairy_bonuses()
	resources_changed.emit()
	flower_grove_changed.emit()
	sacred_pond_changed.emit()
	fairy_house_changed.emit()
	save_game()
	var message := "Fairy House upgraded to Level %d!" % fairy_house_level
	save_status_changed.emit(message)
	return {"Success": true, "Message": message}


func recalculate_fairy_bonuses() -> void:
	flower_grove_fairy_bonus_production = 0.0
	sacred_pond_fairy_restore_bonus = 0
	fairy_residents = 0
	fairy_workers_active = 0
	fairy_current_assignment = FAIRY_AREA_UNASSIGNED

	for fairy in fairies:
		if not bool(fairy.get("IsUnlocked", false)):
			continue
		fairy_residents += 1
		var assigned_area := String(fairy.get("AssignedArea", FAIRY_AREA_UNASSIGNED))
		var work_bonus := float(fairy.get("WorkBonus", 0.0))
		if assigned_area == FAIRY_AREA_FLOWER_GROVE:
			flower_grove_fairy_bonus_production += work_bonus
			fairy_workers_active += 1
			fairy_current_assignment = FAIRY_AREA_FLOWER_GROVE
		elif assigned_area == FAIRY_AREA_SACRED_POND:
			sacred_pond_fairy_restore_bonus += int(ceil(work_bonus))
			fairy_workers_active += 1
			fairy_current_assignment = FAIRY_AREA_SACRED_POND

	fairy_max_residents = max(fairy_max_residents, fairy_residents)


func get_fairy_assigned_area(fairy_name: String) -> String:
	for fairy in fairies:
		if fairy.get("FairyName", "") == fairy_name:
			return String(fairy.get("AssignedArea", FAIRY_AREA_UNASSIGNED))
	return FAIRY_AREA_UNASSIGNED


func get_fairy_data(fairy_name: String) -> Dictionary:
	for fairy in fairies:
		if fairy.get("FairyName", "") == fairy_name:
			return fairy.duplicate(true)
	return {}


func get_unlocked_fairy_count() -> int:
	var count := 0
	for fairy in fairies:
		if bool(fairy.get("IsUnlocked", false)):
			count += 1
	return count


func get_recruitable_fairy_cards() -> Array[Dictionary]:
	var cards: Array[Dictionary] = []
	for fairy in fairies:
		if bool(fairy.get("IsUnlocked", false)):
			continue
		var fairy_name := String(fairy.get("FairyName", "Fairy"))
		cards.append({
			"FairyName": fairy_name,
			"FairyRole": String(fairy.get("FairyRole", "Helper")),
			"WorkBonus": float(fairy.get("WorkBonus", 1.0)),
			"SpecialtyText": get_fairy_specialty_text(fairy),
			"CostText": get_fairy_recruit_cost_text(fairy_name),
			"CanRecruit": can_recruit_fairy(fairy_name)
		})
	return cards


func get_fairy_recruit_cost(fairy_name: String) -> Dictionary:
	if not FAIRY_RECRUIT_COSTS.has(fairy_name):
		return {}
	return (FAIRY_RECRUIT_COSTS[fairy_name] as Dictionary).duplicate(true)


func get_fairy_recruit_cost_text(fairy_name: String) -> String:
	var cost := get_fairy_recruit_cost(fairy_name)
	if cost.is_empty():
		return "Recruit cost unavailable"
	var parts: Array[String] = []
	for key in ["Mana", "Coins", "Spirit", POTION_INGREDIENT_MANA_CRYSTAL, POTION_INGREDIENT_DREAMBLOOM, POTION_INGREDIENT_EMPTY_VIAL]:
		var amount := int(cost.get(key, 0))
		if amount <= 0:
			continue
		if key == POTION_INGREDIENT_MANA_CRYSTAL or key == POTION_INGREDIENT_DREAMBLOOM or key == POTION_INGREDIENT_EMPTY_VIAL:
			parts.append("%d %s" % [amount, get_potion_ingredient_name(key)])
		else:
			parts.append("%d %s" % [amount, key])
	return ", ".join(parts)


func can_recruit_fairy(fairy_name: String) -> bool:
	var fairy := _get_fairy_index(fairy_name)
	if fairy < 0:
		return false
	if bool(fairies[fairy].get("IsUnlocked", false)):
		return false
	if get_unlocked_fairy_count() >= fairy_max_residents:
		return false
	var cost := get_fairy_recruit_cost(fairy_name)
	if cost.is_empty():
		return false
	return total_mana >= int(cost.get("Mana", 0)) and total_coins >= int(cost.get("Coins", 0)) and sacred_pond_spirit_energy >= int(cost.get("Spirit", 0)) and get_potion_ingredient_count(POTION_INGREDIENT_MANA_CRYSTAL) >= int(cost.get(POTION_INGREDIENT_MANA_CRYSTAL, 0)) and get_potion_ingredient_count(POTION_INGREDIENT_DREAMBLOOM) >= int(cost.get(POTION_INGREDIENT_DREAMBLOOM, 0)) and get_potion_ingredient_count(POTION_INGREDIENT_EMPTY_VIAL) >= int(cost.get(POTION_INGREDIENT_EMPTY_VIAL, 0))


func recruit_fairy(fairy_name: String) -> Dictionary:
	var fairy_index := _get_fairy_index(fairy_name)
	if fairy_index < 0:
		save_status_changed.emit("Fairy not found.")
		return {"Success": false, "Message": "Fairy not found."}
	if bool(fairies[fairy_index].get("IsUnlocked", false)):
		save_status_changed.emit("%s already lives here." % fairy_name)
		return {"Success": false, "Message": "%s already lives here." % fairy_name}
	if get_unlocked_fairy_count() >= fairy_max_residents:
		save_status_changed.emit("Upgrade the Fairy House for more room.")
		return {"Success": false, "Message": "Upgrade the Fairy House for more room."}
	var cost := get_fairy_recruit_cost(fairy_name)
	if cost.is_empty():
		save_status_changed.emit("Recruit cost unavailable.")
		return {"Success": false, "Message": "Recruit cost unavailable."}
	if not can_recruit_fairy(fairy_name):
		save_status_changed.emit("Not enough resources to recruit %s." % fairy_name)
		return {"Success": false, "Message": "Not enough resources to recruit %s." % fairy_name}

	total_mana -= int(cost.get("Mana", 0))
	total_coins -= int(cost.get("Coins", 0))
	sacred_pond_spirit_energy -= int(cost.get("Spirit", 0))
	potion_ingredients[POTION_INGREDIENT_MANA_CRYSTAL] = get_potion_ingredient_count(POTION_INGREDIENT_MANA_CRYSTAL) - int(cost.get(POTION_INGREDIENT_MANA_CRYSTAL, 0))
	potion_ingredients[POTION_INGREDIENT_DREAMBLOOM] = get_potion_ingredient_count(POTION_INGREDIENT_DREAMBLOOM) - int(cost.get(POTION_INGREDIENT_DREAMBLOOM, 0))
	potion_ingredients[POTION_INGREDIENT_EMPTY_VIAL] = get_potion_ingredient_count(POTION_INGREDIENT_EMPTY_VIAL) - int(cost.get(POTION_INGREDIENT_EMPTY_VIAL, 0))
	fairies[fairy_index]["IsUnlocked"] = true
	fairies[fairy_index]["AssignedArea"] = FAIRY_AREA_UNASSIGNED
	recalculate_fairy_bonuses()
	resources_changed.emit()
	fairy_house_changed.emit()
	save_game()
	var message := "%s joined the Fairy House!" % fairy_name
	save_status_changed.emit(message)
	return {"Success": true, "Message": message}


func _get_fairy_index(fairy_name: String) -> int:
	for index in range(fairies.size()):
		if String(fairies[index].get("FairyName", "")) == fairy_name:
			return index
	return -1


func get_fairy_xp_to_next_level(fairy: Dictionary) -> int:
	return max(3, int(fairy.get("FairyLevel", 1)) * 3)


func get_fairy_specialty_text(fairy: Dictionary) -> String:
	var role := String(fairy.get("FairyRole", "Helper"))
	if role == "Gatherer":
		return "Best at mana gathering"
	if role == "Pond Keeper":
		return "Best at tending waters"
	if role == "Forager":
		return "Best at ingredient foraging"
	return "Flexible helper"


func get_fairy_bonus_text(fairy: Dictionary) -> String:
	var assigned_area := String(fairy.get("AssignedArea", FAIRY_AREA_UNASSIGNED))
	var work_bonus := float(fairy.get("WorkBonus", 0.0))
	if assigned_area == FAIRY_AREA_FLOWER_GROVE:
		return "+%d Mana/sec" % int(work_bonus)
	if assigned_area == FAIRY_AREA_SACRED_POND:
		return "+%d Restore" % int(ceil(work_bonus))
	return "No active bonus"


func _reset_fairies_to_defaults() -> void:
	fairies.clear()
	fairies.append({
		"FairyName": "Luna",
		"FairyLevel": 1,
		"FairyRole": "Gatherer",
		"AssignedArea": FAIRY_AREA_FLOWER_GROVE,
		"WorkBonus": 2.0,
		"FairyXP": 0,
		"IsUnlocked": true
	})
	fairies.append({
		"FairyName": "Pip",
		"FairyLevel": 1,
		"FairyRole": "Pond Keeper",
		"AssignedArea": FAIRY_AREA_SACRED_POND,
		"WorkBonus": 1.0,
		"FairyXP": 0,
		"IsUnlocked": true
	})
	fairies.append({
		"FairyName": "Nim",
		"FairyLevel": 1,
		"FairyRole": "Forager",
		"AssignedArea": FAIRY_AREA_UNASSIGNED,
		"WorkBonus": 1.0,
		"FairyXP": 0,
		"IsUnlocked": true
	})
	_add_default_fairy_if_missing("Sol", "Gatherer", 1.5, false)
	_add_default_fairy_if_missing("Mira", "Pond Keeper", 1.5, false)
	_reset_fairy_tasks_to_defaults()


func _add_default_fairy_if_missing(fairy_name: String, role: String, work_bonus: float, is_unlocked: bool) -> void:
	if _get_fairy_index(fairy_name) >= 0:
		return
	fairies.append({
		"FairyName": fairy_name,
		"FairyLevel": 1,
		"FairyRole": role,
		"AssignedArea": FAIRY_AREA_UNASSIGNED,
		"WorkBonus": work_bonus,
		"FairyXP": 0,
		"IsUnlocked": is_unlocked
	})


func _sync_recruitable_fairies() -> void:
	_add_default_fairy_if_missing("Sol", "Gatherer", 1.5, false)
	_add_default_fairy_if_missing("Mira", "Pond Keeper", 1.5, false)


func _reset_fairy_tasks_to_defaults() -> void:
	fairy_task_progress.clear()
	fairy_task_progress[FAIRY_TASK_FLOWER_GROVE] = 0.0
	fairy_task_progress[FAIRY_TASK_FORAGE_INGREDIENTS] = 0.0
	fairy_task_progress[FAIRY_TASK_SACRED_POND] = 0.0
	fairy_task_ready_counts.clear()
	fairy_task_ready_counts[FAIRY_TASK_FLOWER_GROVE] = 0
	fairy_task_ready_counts[FAIRY_TASK_FORAGE_INGREDIENTS] = 0
	fairy_task_ready_counts[FAIRY_TASK_SACRED_POND] = 0


func _apply_saved_fairy_tasks(saved_progress, saved_ready_counts) -> void:
	_reset_fairy_tasks_to_defaults()
	if saved_progress is Dictionary:
		for task_id in [FAIRY_TASK_FLOWER_GROVE, FAIRY_TASK_FORAGE_INGREDIENTS, FAIRY_TASK_SACRED_POND]:
			fairy_task_progress[task_id] = clampf(float(saved_progress.get(task_id, 0.0)), 0.0, FAIRY_TASK_REQUIRED_PROGRESS - 0.01)
	if saved_ready_counts is Dictionary:
		for task_id in [FAIRY_TASK_FLOWER_GROVE, FAIRY_TASK_FORAGE_INGREDIENTS, FAIRY_TASK_SACRED_POND]:
			fairy_task_ready_counts[task_id] = max(0, int(saved_ready_counts.get(task_id, 0)))


func _reset_quests_to_defaults() -> void:
	quests.clear()
	# === Collect Mana chain ===
	quests.append(_make_quest(
		"first_harvest",
		"First Harvest",
		"Collect mana from the Flower Grove.",
		QUEST_GOAL_COLLECT_MANA,
		50,
		QUEST_REWARD_COINS,
		25,
		"collect_mana",
		1
	))
	quests.append(_make_quest(
		"mana_gatherer",
		"Mana Gatherer",
		"Collect 250 mana from the Flower Grove.",
		QUEST_GOAL_COLLECT_MANA,
		250,
		QUEST_REWARD_COINS,
		60,
		"collect_mana",
		2
	))
	quests.append(_make_quest(
		"mana_hoarder",
		"Mana Hoarder",
		"Collect 750 mana from the Flower Grove.",
		QUEST_GOAL_COLLECT_MANA,
		750,
		QUEST_REWARD_COINS,
		200,
		"collect_mana",
		3
	))
	# === Upgrade Flower Grove chain ===
	quests.append(_make_quest(
		"village_growth",
		"Village Growth",
		"Upgrade the Flower Grove.",
		QUEST_GOAL_UPGRADE_FLOWER,
		1,
		QUEST_REWARD_COINS,
		75,
		"upgrade_flower",
		1
	))
	quests.append(_make_quest(
		"grove_keeper",
		"Grove Keeper",
		"Upgrade the Flower Grove 3 times.",
		QUEST_GOAL_UPGRADE_FLOWER,
		3,
		QUEST_REWARD_COINS,
		100,
		"upgrade_flower",
		2
	))
	quests.append(_make_quest(
		"grove_master",
		"Grove Master",
		"Upgrade the Flower Grove 9 times.",
		QUEST_GOAL_UPGRADE_FLOWER,
		9,
		QUEST_REWARD_COINS,
		300,
		"upgrade_flower",
		3
	))
	# === Craft Potion chain ===
	quests.append(_make_quest(
		"beginner_brewer",
		"Beginner Brewer",
		"Craft your first Mana Potion.",
		QUEST_GOAL_CRAFT_POTION,
		1,
		QUEST_REWARD_COINS,
		50,
		"craft_potion",
		1
	))
	quests.append(_make_quest(
		"master_brewer",
		"Master Brewer",
		"Craft 5 Mana Potions.",
		QUEST_GOAL_CRAFT_POTION,
		5,
		QUEST_REWARD_COINS,
		120,
		"craft_potion",
		2
	))
	quests.append(_make_quest(
		"legendary_brewer",
		"Legendary Brewer",
		"Craft 15 Mana Potions.",
		QUEST_GOAL_CRAFT_POTION,
		15,
		QUEST_REWARD_COINS,
		350,
		"craft_potion",
		3
	))
	# === Market Trade chain ===
	quests.append(_make_quest(
		"first_trade",
		"First Trade",
		"Fulfill a Market Stall order.",
		QUEST_GOAL_MARKET_TRADE,
		1,
		QUEST_REWARD_COINS,
		60,
		"market_trade",
		1
	))
	quests.append(_make_quest(
		"seasoned_trader",
		"Seasoned Trader",
		"Fulfill 5 Market Stall orders.",
		QUEST_GOAL_MARKET_TRADE,
		5,
		QUEST_REWARD_COINS,
		150,
		"market_trade",
		2
	))
	quests.append(_make_quest(
		"master_merchant",
		"Master Merchant",
		"Fulfill 15 Market Stall orders.",
		QUEST_GOAL_MARKET_TRADE,
		15,
		QUEST_REWARD_COINS,
		450,
		"market_trade",
		3
	))
	# Assign Flower Fairy chain
	quests.append(_make_quest(
		"restore_waters",
		"Restore the Waters",
		"Use mana to restore the Sacred Koi Pond.",
		QUEST_GOAL_RESTORE_POND,
		1,
		QUEST_REWARD_MANA,
		25,
		"restore_waters",
		1
	))
	quests.append(_make_quest(
		"fairy_work",
		"A Fairy's Work",
		"Assign a fairy to the Flower Grove.",
		QUEST_GOAL_ASSIGN_FLOWER_FAIRY,
		1,
		QUEST_REWARD_COINS,
		50,
		"assign_flower_fairy",
		1
	))
	quests.append(_make_quest(
		"fairy_circle",
		"Fairy Circle",
		"Assign a fairy to the Flower Grove 3 times.",
		QUEST_GOAL_ASSIGN_FLOWER_FAIRY,
		3,
		QUEST_REWARD_MANA,
		80,
		"assign_flower_fairy",
		2
	))
	quests.append(_make_quest(
		"fairy_monarch",
		"Fairy Monarch",
		"Assign a fairy to the Flower Grove 9 times.",
		QUEST_GOAL_ASSIGN_FLOWER_FAIRY,
		9,
		QUEST_REWARD_MANA,
		240,
		"assign_flower_fairy",
		3
	))
	#  Forge Upgrade chain 
	quests.append(_make_quest(
		"first_forging",
		"First Forging",
		"Purchase an Arcane Forge upgrade.",
		QUEST_GOAL_FORGE_UPGRADE,
		1,
		QUEST_REWARD_COINS,
		100,
		"forge_upgrade",
		1
	))
	quests.append(_make_quest(
		"master_forger",
		"Master Forger",
		"Purchase 3 Arcane Forge upgrades.",
		QUEST_GOAL_FORGE_UPGRADE,
		3,
		QUEST_REWARD_COINS,
		200,
		"forge_upgrade",
		2
	))
	quests.append(_make_quest(
		"grand_forger",
		"Grand Forger",
		"Purchase 9 Arcane Forge upgrades.",
		QUEST_GOAL_FORGE_UPGRADE,
		9,
		QUEST_REWARD_COINS,
		600,
		"forge_upgrade",
		3
	))
	# One-off quests.
	quests.append(_make_quest(
		"awaken_roots",
		"Awaken the Roots",
		"Restore the Ancient Tree.",
		QUEST_GOAL_RESTORE_TREE,
		1,
		QUEST_REWARD_MANA,
		75,
		"awaken_roots",
		1
	))


func _make_quest(quest_id: String, title: String, description: String, goal_type: String, required_progress: int, reward_type: String, reward_amount: int, chain_id: String = "", tier: int = 1) -> Dictionary:
	var resolved_chain := chain_id
	if resolved_chain == "":
		resolved_chain = quest_id
	return {
		"QuestID": quest_id,
		"QuestTitle": title,
		"QuestDescription": description,
		"QuestGoalType": goal_type,
		"CurrentProgress": 0,
		"RequiredProgress": required_progress,
		"RewardType": reward_type,
		"RewardAmount": reward_amount,
		"IsCompleted": false,
		"IsClaimed": false,
		"ChainID": resolved_chain,
		"Tier": tier
	}


func _apply_saved_quests(saved_quests) -> void:
	_reset_quests_to_defaults()
	if not (saved_quests is Array) or saved_quests.is_empty():
		return

	var saved_by_id: Dictionary = {}
	var unknown_saved_quests: Array[Dictionary] = []
	var default_ids: Dictionary = {}
	for quest in quests:
		default_ids[String(quest.get("QuestID", ""))] = true

	for saved_quest in saved_quests:
		if not (saved_quest is Dictionary):
			continue
		var quest_id := String(saved_quest.get("QuestID", ""))
		if quest_id.is_empty():
			continue
		if default_ids.has(quest_id):
			saved_by_id[quest_id] = saved_quest
		else:
			unknown_saved_quests.append(_sanitize_saved_quest(saved_quest))

	for index in range(quests.size()):
		var quest_id := String(quests[index].get("QuestID", ""))
		if not saved_by_id.has(quest_id):
			continue
		var saved: Dictionary = saved_by_id[quest_id]
		var required: int = max(1, int(quests[index].get("RequiredProgress", 1)))
		var progress: int = min(max(0, int(saved.get("CurrentProgress", 0))), required)
		quests[index]["CurrentProgress"] = progress
		quests[index]["IsCompleted"] = bool(saved.get("IsCompleted", false)) or progress >= required
		quests[index]["IsClaimed"] = bool(saved.get("IsClaimed", false))

	for quest in unknown_saved_quests:
		quests.append(quest)


func _sanitize_saved_quest(saved_quest: Dictionary) -> Dictionary:
	var required: int = max(1, int(saved_quest.get("RequiredProgress", 1)))
	var progress: int = min(max(0, int(saved_quest.get("CurrentProgress", 0))), required)
	return {
		"QuestID": String(saved_quest.get("QuestID", "")),
		"QuestTitle": String(saved_quest.get("QuestTitle", "Legacy Quest")),
		"QuestDescription": String(saved_quest.get("QuestDescription", "")),
		"QuestGoalType": String(saved_quest.get("QuestGoalType", "")),
		"CurrentProgress": progress,
		"RequiredProgress": required,
		"RewardType": String(saved_quest.get("RewardType", QUEST_REWARD_COINS)),
		"RewardAmount": max(0, int(saved_quest.get("RewardAmount", 0))),
		"IsCompleted": bool(saved_quest.get("IsCompleted", false)) or progress >= required,
		"IsClaimed": bool(saved_quest.get("IsClaimed", false))
	}


func add_quest_progress(goal_type: String, amount: int) -> void:
	if amount <= 0:
		return
	var changed := false
	var completed_now := false
	for index in range(quests.size()):
		if String(quests[index].get("QuestGoalType", "")) != goal_type:
			continue
		if bool(quests[index].get("IsClaimed", false)):
			continue
		var required := int(quests[index].get("RequiredProgress", 1))
		var current := int(quests[index].get("CurrentProgress", 0))
		var was_completed := bool(quests[index].get("IsCompleted", false))
		current = min(current + amount, required)
		quests[index]["CurrentProgress"] = current
		quests[index]["IsCompleted"] = current >= required
		changed = true
		if not was_completed and bool(quests[index]["IsCompleted"]):
			completed_now = true
	if changed:
		quests_changed.emit()
		if completed_now:
			preserve_feedback_once = true
			save_status_changed.emit("Quest Complete!")

func get_quest_bucket(quest: Dictionary) -> String:
	if bool(quest.get("IsClaimed", false)):
		return "completed"
	var chain_id := String(quest.get("ChainID", ""))
	var tier := int(quest.get("Tier", 1))
	for other in quests:
		if String(other.get("ChainID", "")) != chain_id:
			continue
		if int(other.get("Tier", 1)) < tier and not bool(other.get("IsClaimed", false)):
			return "future"
	return "active"


func get_quests_in_bucket(bucket: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for quest in quests:
		if get_quest_bucket(quest) == bucket:
			result.append(quest)
	return result

func claim_quest_reward(quest_id: String) -> bool:
	for index in range(quests.size()):
		if String(quests[index].get("QuestID", "")) != quest_id:
			continue
		if not bool(quests[index].get("IsCompleted", false)) or bool(quests[index].get("IsClaimed", false)):
			return false
		var reward_type := String(quests[index].get("RewardType", ""))
		var reward_amount := int(quests[index].get("RewardAmount", 0))
		if reward_type == QUEST_REWARD_MANA:
			total_mana += reward_amount
		elif reward_type == QUEST_REWARD_COINS:
			total_coins += reward_amount
		quests[index]["IsClaimed"] = true
		resources_changed.emit()
		inventory_changed.emit()
		quests_changed.emit()
		save_game()
		return true
	return false


func get_inventory_items() -> Array[Dictionary]:
	var items: Array[Dictionary] = [
		{
			"Name": "Mana",
			"Quantity": total_mana,
			"Category": "Resources",
			"Description": "Gathered from the Flower Grove and spent on restoration, crafting, and upgrades."
		},
		{
			"Name": "Coins",
			"Quantity": total_coins,
			"Category": "Resources",
			"Description": "Earned from potions, market trades, and quest rewards."
		},
		{
			"Name": "Spirit Energy",
			"Quantity": sacred_pond_spirit_energy,
			"Category": "Pond Relics",
			"Description": "Generated by Sacred Koi Pond restoration and used for higher-value trades."
		},
		{
			"Name": "Sun Koi Guardian Bonus",
			"Quantity": get_sun_koi_guardian_spirit_bonus(),
			"Category": "Pond Relics",
			"Description": "Extra Spirit Energy earned on each pond restore after the pond reaches 100% purity."
		}
	]
	for recipe in get_potion_recipes():
		items.append({
			"Name": String(recipe.get("Name", "Potion")),
			"Quantity": get_potion_count(String(recipe.get("RecipeID", ""))),
			"Category": "Crafted Goods",
			"Description": String(recipe.get("Description", "Crafted in the Potion Shop."))
		})
	for ingredient_id in [POTION_INGREDIENT_MANA_CRYSTAL, POTION_INGREDIENT_DREAMBLOOM, POTION_INGREDIENT_EMPTY_VIAL]:
		items.append({
			"Name": get_potion_ingredient_name(ingredient_id),
			"Quantity": get_potion_ingredient_count(ingredient_id),
			"Category": "Potion Ingredients",
			"Description": "Gathered by fairies and consumed by Potion Shop recipes."
		})
	var active_fairies := 0
	for fairy in fairies:
		if bool(fairy.get("IsUnlocked", false)):
			active_fairies += 1
	items.append({
		"Name": "Fairy Residents",
		"Quantity": active_fairies,
		"Category": "Companions",
		"Description": "Unlocked fairy helpers available for village assignments."
	})
	items.append({
		"Name": "Pond Decorations",
		"Quantity": _get_placed_pond_decoration_count(),
		"Category": "Decor",
		"Description": "Placed pond ornaments that increase Beauty and restoration bonuses."
	})
	items.append({
		"Name": "Tree XP",
		"Quantity": ancient_tree_experience,
		"Category": "Ancient Tree",
		"Description": "Mystic experience gathered while watering the Ancient Tree."
	})
	items.append({
		"Name": "Ancient Seeds",
		"Quantity": ancient_tree_seed_count,
		"Category": "Ancient Tree",
		"Description": "Rare seeds shaken loose by the Ancient Tree during restoration."
	})
	return items


func get_inventory_summary() -> Dictionary:
	return {
		"ItemCount": get_inventory_items().size(),
		"CraftedGoods": get_total_potion_count(),
		"PlacedDecorations": _get_placed_pond_decoration_count(),
		"UnlockedRewards": unlocked_pond_rewards.size(),
		"Notes": inventory_notes
	}


func _get_placed_pond_decoration_count() -> int:
	var count := 0
	for decoration in pond_decorations:
		if bool(decoration.get("IsPlaced", false)):
			count += 1
	return count


func has_claimable_quest_rewards() -> bool:
	for quest in quests:
		if bool(quest.get("IsCompleted", false)) and not bool(quest.get("IsClaimed", false)):
			return true
	return false


func is_quest_completed(quest_id: String) -> bool:
	for quest in quests:
		if String(quest.get("QuestID", "")) == quest_id:
			return bool(quest.get("IsCompleted", false))
	return false


func is_quest_claimed(quest_id: String) -> bool:
	for quest in quests:
		if String(quest.get("QuestID", "")) == quest_id:
			return bool(quest.get("IsClaimed", false))
	return false


func get_save_data() -> Dictionary:
	return {
		"total_mana": total_mana,
		"total_coins": total_coins,
		"flower_grove_level": flower_grove_level,
		"flower_grove_stored_mana": flower_grove_stored_mana,
		"flower_grove_production_rate": flower_grove_base_mana_production_rate,
		"flower_grove_base_mana_production_rate": flower_grove_base_mana_production_rate,
		"flower_grove_fairy_bonus_production": flower_grove_fairy_bonus_production,
		"flower_grove_max_stored_mana": flower_grove_max_stored_mana,
		"flower_grove_upgrade_cost": flower_grove_upgrade_cost,
		"flower_grove_active_plots": flower_grove_active_plots,
		"flower_grove_max_plots": flower_grove_max_plots,
		"flower_grove_plot_unlock_states": flower_grove_plot_unlock_states,
		"flower_grove_grid_slots": flower_grove_grid_slots,
		"flower_grove_grid_production_rate": get_flower_grid_production_rate(),
		"sacred_pond_water_purity": sacred_pond_water_purity,
		"sacred_pond_spirit_energy": sacred_pond_spirit_energy,
		"sacred_pond_level": sacred_pond_level,
		"sacred_pond_restore_cost": sacred_pond_restore_cost,
		"sacred_pond_base_restore_amount": sacred_pond_base_restore_amount,
		"sacred_pond_fairy_restore_bonus": sacred_pond_fairy_restore_bonus,
		"active_pond_bonus": active_pond_bonus,
		"unlocked_pond_rewards": unlocked_pond_rewards,
		"pond_beauty": pond_beauty,
		"pond_decorations": pond_decorations,
		"pond_decoration_slots": pond_decoration_slots,
		"grove_restoration": grove_restoration,
		"fairy_house_level": fairy_house_level,
		"fairy_residents": fairy_residents,
		"fairy_max_residents": fairy_max_residents,
		"fairy_workers_active": fairy_workers_active,
		"fairies": fairies,
		"fairy_task_progress": fairy_task_progress,
		"fairy_task_ready_counts": fairy_task_ready_counts,
		"potion_shop_level": potion_shop_level,
		"mana_potion_count": mana_potion_count,
		"potion_mana_cost": potion_mana_cost,
		"potion_base_craft_time": potion_base_craft_time,
		"potion_current_craft_time": potion_current_craft_time,
		"potion_crafting_active": potion_crafting_active,
		"potion_crafting_recipe_id": potion_crafting_recipe_id,
		"potion_inventory": potion_inventory,
		"potion_ingredients": potion_ingredients,
		"potion_sell_value": potion_sell_value,
		"potion_shop_upgrade_cost": potion_shop_upgrade_cost,
		"market_reputation": market_reputation,
		"market_orders_completed": market_orders_completed,
		"inventory_notes": inventory_notes,
		"ancient_tree_level": ancient_tree_level,
		"ancient_tree_growth": ancient_tree_growth,
		"ancient_tree_restore_cost": ancient_tree_restore_cost,
		"ancient_tree_claimed_rewards": ancient_tree_claimed_rewards,
		"ancient_tree_experience": ancient_tree_experience,
		"ancient_tree_seed_count": ancient_tree_seed_count,
		"ancient_tree_water_timestamps": ancient_tree_water_timestamps,
		"forge_level": forge_level,
		"forge_flower_focus_level": forge_flower_focus_level,
		"forge_potion_gilding_level": forge_potion_gilding_level,
		"forge_pond_resonance_level": forge_pond_resonance_level,
		"quests": quests,
		"has_completed_onboarding": has_completed_onboarding,
		"first_merge_complete": first_merge_complete,
		"show_tutorial_after_reset": show_tutorial_after_reset,
		"has_seen_tutorial": has_seen_tutorial,
		"tutorial_step": tutorial_step,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"exploration_active": exploration_active,
		"exploration_location_id": exploration_location_id,
		"exploration_end_unix": exploration_end_unix
	}
	


func apply_save_data(data: Dictionary) -> void:
	total_mana = int(data.get("total_mana", 0))
	total_coins = int(data.get("total_coins", 0))
	flower_grove_level = int(data.get("flower_grove_level", 1))
	flower_grove_stored_mana = float(data.get("flower_grove_stored_mana", 0.0))
	flower_grove_base_mana_production_rate = float(data.get("flower_grove_base_mana_production_rate", data.get("flower_grove_production_rate", 5.0)))
	flower_grove_fairy_bonus_production = float(data.get("flower_grove_fairy_bonus_production", 0.0))
	flower_grove_max_stored_mana = int(data.get("flower_grove_max_stored_mana", 100))
	flower_grove_upgrade_cost = int(data.get("flower_grove_upgrade_cost", 25))
	flower_grove_active_plots = int(data.get("flower_grove_active_plots", 3))
	flower_grove_max_plots = int(data.get("flower_grove_max_plots", 6))
	var saved_plot_states = data.get("flower_grove_plot_unlock_states", [])
	if saved_plot_states is Array and saved_plot_states.size() == flower_grove_max_plots:
		flower_grove_plot_unlock_states.clear()
		for value in saved_plot_states:
			flower_grove_plot_unlock_states.append(bool(value))
		flower_grove_active_plots = flower_grove_plot_unlock_states.count(true)
	else:
		_sync_plot_unlock_states()
	var saved_grid_slots = data.get("flower_grove_grid_slots", [])
	if saved_grid_slots is Array and saved_grid_slots.size() == FLOWER_GRID_SLOT_COUNT:
		flower_grove_grid_slots.clear()
		for saved_slot in saved_grid_slots:
			if saved_slot is Dictionary:
				flower_grove_grid_slots.append({
					"Tier": int(saved_slot.get("Tier", FLOWER_TIER_EMPTY)),
					"Locked": bool(saved_slot.get("Locked", false))
				})
			else:
				flower_grove_grid_slots.append({"Tier": FLOWER_TIER_EMPTY, "Locked": false})
		_sync_flower_grid_unlocks()
	else:
		_reset_flower_grid_to_defaults()
	sacred_pond_water_purity = int(data.get("sacred_pond_water_purity", 15))
	sacred_pond_spirit_energy = int(data.get("sacred_pond_spirit_energy", 0))
	sacred_pond_level = int(data.get("sacred_pond_level", 1))
	sacred_pond_restore_cost = int(data.get("sacred_pond_restore_cost", 25))
	sacred_pond_base_restore_amount = int(data.get("sacred_pond_base_restore_amount", 5))
	active_pond_bonus = String(data.get("active_pond_bonus", POND_BONUS_NONE))
	var saved_pond_rewards = data.get("unlocked_pond_rewards", [])
	unlocked_pond_rewards.clear()
	if saved_pond_rewards is Array:
		for reward in saved_pond_rewards:
			unlocked_pond_rewards.append(String(reward))
	_reset_pond_decorations_to_defaults()
	var saved_decorations = data.get("pond_decorations", [])
	if saved_decorations is Array and saved_decorations.size() > 0:
		pond_decorations.clear()
		for saved_decoration in saved_decorations:
			if saved_decoration is Dictionary:
				pond_decorations.append({
					"DecorationName": String(saved_decoration.get("DecorationName", "")),
					"CostMana": int(saved_decoration.get("CostMana", 0)),
					"BeautyValue": int(saved_decoration.get("BeautyValue", 0)),
					"IsUnlocked": bool(saved_decoration.get("IsUnlocked", true)),
					"IsPlaced": bool(saved_decoration.get("IsPlaced", false)),
					"SlotIndex": int(saved_decoration.get("SlotIndex", -1)),
					"PositionX": float(saved_decoration.get("PositionX", -1.0)),
					"PositionY": float(saved_decoration.get("PositionY", -1.0))
				})
				var imported_index := pond_decorations.size() - 1
				if bool(pond_decorations[imported_index].get("IsPlaced", false)):
					var imported_position := get_pond_decoration_normalized_position(pond_decorations[imported_index])
					pond_decorations[imported_index]["PositionX"] = imported_position.x
					pond_decorations[imported_index]["PositionY"] = imported_position.y
		_add_missing_default_pond_decorations()
	var saved_slots = data.get("pond_decoration_slots", [])
	if saved_slots is Array and saved_slots.size() > 0:
		pond_decoration_slots.clear()
		for slot_name in saved_slots:
			pond_decoration_slots.append(String(slot_name))
	recalculate_pond_beauty()
	grove_restoration = int(data.get("grove_restoration", sacred_pond_water_purity))
	fairy_house_level = int(data.get("fairy_house_level", 1))
	fairy_residents = int(data.get("fairy_residents", 3))
	fairy_max_residents = int(data.get("fairy_max_residents", 3))
	fairy_workers_active = int(data.get("fairy_workers_active", 2))
	var saved_fairies = data.get("fairies", [])
	if saved_fairies is Array and saved_fairies.size() > 0:
		fairies.clear()
		for saved_fairy in saved_fairies:
			if saved_fairy is Dictionary:
				fairies.append({
					"FairyName": String(saved_fairy.get("FairyName", "")),
					"FairyLevel": int(saved_fairy.get("FairyLevel", 1)),
					"FairyRole": String(saved_fairy.get("FairyRole", "Helper")),
					"AssignedArea": String(saved_fairy.get("AssignedArea", FAIRY_AREA_UNASSIGNED)),
					"WorkBonus": float(saved_fairy.get("WorkBonus", 1.0)),
					"FairyXP": int(saved_fairy.get("FairyXP", 0)),
					"IsUnlocked": bool(saved_fairy.get("IsUnlocked", true))
				})
	else:
		_reset_fairies_to_defaults()
	_sync_recruitable_fairies()
	_apply_saved_fairy_tasks(data.get("fairy_task_progress", {}), data.get("fairy_task_ready_counts", {}))
	recalculate_fairy_bonuses()
	update_sacred_pond_level_and_rewards()
	potion_shop_level = int(data.get("potion_shop_level", 1))
	mana_potion_count = int(data.get("mana_potion_count", 0))
	potion_mana_cost = int(data.get("potion_mana_cost", 25))
	potion_base_craft_time = int(data.get("potion_base_craft_time", 5))
	potion_current_craft_time = float(data.get("potion_current_craft_time", 0.0))
	potion_crafting_active = bool(data.get("potion_crafting_active", false))
	potion_crafting_recipe_id = String(data.get("potion_crafting_recipe_id", POTION_RECIPE_MANA))
	if get_potion_recipe_data(potion_crafting_recipe_id).is_empty():
		potion_crafting_recipe_id = POTION_RECIPE_MANA
		potion_crafting_active = false
		potion_current_craft_time = 0.0
	potion_sell_value = int(data.get("potion_sell_value", 50))
	_set_potion_inventory_from_save(data.get("potion_inventory", {}))
	_set_potion_ingredients_from_save(data.get("potion_ingredients", {}))
	potion_shop_upgrade_cost = int(data.get("potion_shop_upgrade_cost", 100))
	market_reputation = int(data.get("market_reputation", 1))
	market_orders_completed = int(data.get("market_orders_completed", 0))
	inventory_notes.clear()
	var saved_inventory_notes = data.get("inventory_notes", [])
	if saved_inventory_notes is Array:
		for note in saved_inventory_notes:
			inventory_notes.append(String(note))
	if inventory_notes.is_empty():
		inventory_notes.append("Inventory unlocked")
	ancient_tree_level = int(data.get("ancient_tree_level", 1))
	ancient_tree_growth = int(data.get("ancient_tree_growth", data.get("grove_restoration", 15)))
	update_ancient_tree_level()
	ancient_tree_restore_cost = int(data.get("ancient_tree_restore_cost", 75))
	ancient_tree_claimed_rewards.clear()
	ancient_tree_experience = int(data.get("ancient_tree_experience", 0))
	ancient_tree_seed_count = int(data.get("ancient_tree_seed_count", 0))
	ancient_tree_water_timestamps.clear()
	var saved_water_timestamps = data.get("ancient_tree_water_timestamps", [])
	if saved_water_timestamps is Array:
		for timestamp in saved_water_timestamps:
			ancient_tree_water_timestamps.append(int(timestamp))
	_prune_ancient_tree_water_timestamps()
	var saved_tree_rewards = data.get("ancient_tree_claimed_rewards", [])
	if saved_tree_rewards is Array:
		for reward_level in saved_tree_rewards:
			ancient_tree_claimed_rewards.append(int(reward_level))
	forge_level = int(data.get("forge_level", 1))
	forge_flower_focus_level = int(data.get("forge_flower_focus_level", 0))
	forge_potion_gilding_level = int(data.get("forge_potion_gilding_level", 0))
	forge_pond_resonance_level = int(data.get("forge_pond_resonance_level", 0))
	var saved_quests = data.get("quests", [])
	if saved_quests is Array and saved_quests.size() > 0:
		quests.clear()
		for saved_quest in saved_quests:
			if saved_quest is Dictionary:
				quests.append({
					"QuestID": String(saved_quest.get("QuestID", "")),
					"QuestTitle": String(saved_quest.get("QuestTitle", "")),
					"QuestDescription": String(saved_quest.get("QuestDescription", "")),
					"QuestGoalType": String(saved_quest.get("QuestGoalType", "")),
					"CurrentProgress": int(saved_quest.get("CurrentProgress", 0)),
					"RequiredProgress": int(saved_quest.get("RequiredProgress", 1)),
					"RewardType": String(saved_quest.get("RewardType", QUEST_REWARD_COINS)),
					"RewardAmount": int(saved_quest.get("RewardAmount", 0)),
					"IsCompleted": bool(saved_quest.get("IsCompleted", false)),
					"IsClaimed": bool(saved_quest.get("IsClaimed", false)),
					"ChainID": String(saved_quest.get("ChainID", String(saved_quest.get("QuestID", "")))),
					"Tier": int(saved_quest.get("Tier", 1))
				})
	else:
		_reset_quests_to_defaults()

	forge_flower_focus_level = min(max(0, int(data.get("forge_flower_focus_level", 0))), 3)
	forge_potion_gilding_level = min(max(0, int(data.get("forge_potion_gilding_level", 0))), 3)
	forge_pond_resonance_level = min(max(0, int(data.get("forge_pond_resonance_level", 0))), 3)
	forge_level = 1 + forge_flower_focus_level + forge_potion_gilding_level + forge_pond_resonance_level
	_apply_saved_quests(data.get("quests", []))
	has_completed_onboarding = bool(data.get("has_completed_onboarding", true))
	first_merge_complete = bool(data.get("first_merge_complete", has_completed_onboarding))
	show_tutorial_after_reset = bool(data.get("show_tutorial_after_reset", false))
	has_seen_tutorial = bool(data.get("has_seen_tutorial", has_completed_onboarding))
	tutorial_step = int(data.get("tutorial_step", 0))
	music_volume = clamp(float(data.get("music_volume", 0.75)), 0.0, 1.0)
	sfx_volume = clamp(float(data.get("sfx_volume", 0.75)), 0.0, 1.0)
	
	exploration_active = bool(data.get("exploration_active", false))
	exploration_location_id = String(data.get("exploration_location_id", ""))
	exploration_end_unix = int(data.get("exploration_end_unix", 0))

	resources_changed.emit()
	flower_grove_changed.emit()
	sacred_pond_changed.emit()
	fairy_house_changed.emit()
	potion_shop_changed.emit()
	market_stall_changed.emit()
	ancient_tree_changed.emit()
	arcane_forge_changed.emit()
	quests_changed.emit()


func save_game() -> void:
	if _is_test_save_disabled():
		if preserve_feedback_once:
			preserve_feedback_once = false
			return
		save_status_changed.emit("Test save skipped.")
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		save_status_changed.emit("Save failed.")
		return

	file.store_string(JSON.stringify(get_save_data()))
	if preserve_feedback_once:
		preserve_feedback_once = false
		return
	save_status_changed.emit("Game saved.")


func save_exists() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func reset_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	reset_to_defaults()
	show_tutorial_after_reset = true
	save_reset.emit()
	save_status_changed.emit("Save reset.")


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		reset_to_defaults()
		save_status_changed.emit("New game started.")
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		reset_to_defaults()
		save_status_changed.emit("Load failed.")
		return

	var save_text := file.get_as_text()
	if save_text.strip_edges().is_empty():
		reset_to_defaults()
		save_status_changed.emit("Save data reset.")
		return
	var parser := JSON.new()
	if parser.parse(save_text) != OK or typeof(parser.data) != TYPE_DICTIONARY:
		reset_to_defaults()
		save_status_changed.emit("Save data reset.")
		return

	apply_save_data(parser.data)
	save_status_changed.emit("Game loaded.")


func _is_test_save_disabled() -> bool:
	return OS.get_cmdline_user_args().has("--no-save")


func reset_to_defaults() -> void:
	total_mana = 0
	total_coins = 0
	grove_restoration = 15
	flower_grove_level = 1
	flower_grove_stored_mana = 0.0
	flower_grove_max_stored_mana = 100
	flower_grove_base_mana_production_rate = 5.0
	flower_grove_fairy_bonus_production = 0.0
	flower_grove_upgrade_cost = 25
	flower_grove_active_plots = 3
	flower_grove_max_plots = 6
	_sync_plot_unlock_states()
	_reset_flower_grid_to_defaults()
	sacred_pond_water_purity = 15
	sacred_pond_spirit_energy = 0
	sacred_pond_level = 1
	sacred_pond_restore_cost = 25
	sacred_pond_base_restore_amount = 5
	sacred_pond_fairy_restore_bonus = 0
	active_pond_bonus = POND_BONUS_NONE
	unlocked_pond_rewards.clear()
	_reset_pond_decorations_to_defaults()
	fairy_house_level = 1
	fairy_residents = 3
	fairy_max_residents = 3
	fairy_workers_active = 2
	fairy_current_assignment = FAIRY_AREA_FLOWER_GROVE
	_reset_fairies_to_defaults()
	recalculate_fairy_bonuses()
	potion_shop_level = 1
	mana_potion_count = 0
	potion_mana_cost = 25
	potion_base_craft_time = 5
	potion_current_craft_time = 0.0
	potion_crafting_active = false
	potion_crafting_recipe_id = POTION_RECIPE_MANA
	potion_inventory.clear()
	potion_inventory[POTION_RECIPE_MANA] = 0
	potion_inventory[POTION_RECIPE_SPIRIT_TONIC] = 0
	potion_ingredients.clear()
	potion_ingredients[POTION_INGREDIENT_MANA_CRYSTAL] = 0
	potion_ingredients[POTION_INGREDIENT_DREAMBLOOM] = 0
	potion_ingredients[POTION_INGREDIENT_EMPTY_VIAL] = 0
	potion_sell_value = 50
	potion_shop_upgrade_cost = 100
	market_reputation = 1
	market_orders_completed = 0
	inventory_notes.clear()
	inventory_notes.append("Inventory unlocked")
	ancient_tree_level = 1
	ancient_tree_growth = 15
	ancient_tree_restore_cost = 75
	ancient_tree_claimed_rewards.clear()
	ancient_tree_experience = 0
	ancient_tree_seed_count = 0
	ancient_tree_water_timestamps.clear()
	forge_level = 1
	forge_flower_focus_level = 0
	forge_potion_gilding_level = 0
	forge_pond_resonance_level = 0
	_reset_quests_to_defaults()
	has_completed_onboarding = false
	first_merge_complete = false
	show_tutorial_after_reset = false
	has_seen_tutorial = false
	tutorial_step = 0
	music_volume = 0.75
	sfx_volume = 0.75
	exploration_active = false
	exploration_location_id = ""
	exploration_end_unix = 0
	resources_changed.emit()
	flower_grove_changed.emit()
	sacred_pond_changed.emit()
	fairy_house_changed.emit()
	potion_shop_changed.emit()
	market_stall_changed.emit()
	ancient_tree_changed.emit()
	arcane_forge_changed.emit()
	inventory_changed.emit()
	quests_changed.emit()


func mark_tutorial_seen(step: int = 4) -> void:
	show_tutorial_after_reset = false
	has_seen_tutorial = true
	tutorial_step = step
	save_game()


func complete_onboarding_merge() -> void:
	if first_merge_complete:
		return
	first_merge_complete = true
	has_completed_onboarding = true
	if show_tutorial_after_reset:
		has_seen_tutorial = false
		tutorial_step = 0
	else:
		has_seen_tutorial = true
		tutorial_step = 4
	total_mana += 10
	grove_restoration = max(grove_restoration, 5)
	resources_changed.emit()
	save_game()


func _reset_pond_decorations_to_defaults() -> void:
	pond_decoration_slots = [
		"Top Left",
		"Top Right",
		"Bottom Left",
		"Bottom Right",
		"Center Left",
		"Center Right"
	]
	pond_decorations.clear()
	pond_decorations.append(_make_pond_decoration("Moon Lantern", 25, 5))
	pond_decorations.append(_make_pond_decoration("Spirit Stone", 40, 8))
	pond_decorations.append(_make_pond_decoration("Bloom Lilypad", 30, 6))
	pond_decorations.append(_make_pond_decoration("Sacred Bridge", 75, 12))
	pond_decorations.append(_make_pond_decoration("Crystal Lotus", 90, 16))
	pond_decorations.append(_make_pond_decoration("Stone Koi Statue", 60, 10))
	pond_decorations.append(_make_pond_decoration("Crystal Pillar", 80, 14))
	pond_decorations.append(_make_pond_decoration("Moonstone Steps", 45, 7))
	pond_decorations.append(_make_pond_decoration("Fern Spring", 55, 9))
	pond_decorations.append(_make_pond_decoration("Flame Basin", 70, 11))
	pond_decorations.append(_make_pond_decoration("Reed Cluster", 35, 6))
	pond_decorations.append(_make_pond_decoration("Willow Arch", 100, 18))
	pond_decorations.append(_make_pond_decoration("Gold Koi", 85, 14))
	pond_decorations.append(_make_pond_decoration("Blue Koi", 85, 14))
	pond_decorations.append(_make_pond_decoration("Pink Koi", 95, 16))
	recalculate_pond_beauty()


func _add_missing_default_pond_decorations() -> void:
	var current_names := {}
	for decoration in pond_decorations:
		current_names[String(decoration.get("DecorationName", ""))] = true
	var defaults := [
		_make_pond_decoration("Moon Lantern", 25, 5),
		_make_pond_decoration("Spirit Stone", 40, 8),
		_make_pond_decoration("Bloom Lilypad", 30, 6),
		_make_pond_decoration("Sacred Bridge", 75, 12),
		_make_pond_decoration("Crystal Lotus", 90, 16),
		_make_pond_decoration("Stone Koi Statue", 60, 10),
		_make_pond_decoration("Crystal Pillar", 80, 14),
		_make_pond_decoration("Moonstone Steps", 45, 7),
		_make_pond_decoration("Fern Spring", 55, 9),
		_make_pond_decoration("Flame Basin", 70, 11),
		_make_pond_decoration("Reed Cluster", 35, 6),
		_make_pond_decoration("Willow Arch", 100, 18),
		_make_pond_decoration("Gold Koi", 85, 14),
		_make_pond_decoration("Blue Koi", 85, 14),
		_make_pond_decoration("Pink Koi", 95, 16)
	]
	for decoration in defaults:
		var decoration_name := String(decoration.get("DecorationName", ""))
		if not current_names.has(decoration_name):
			pond_decorations.append(decoration)


func _reset_flower_grid_to_defaults() -> void:
	flower_grove_grid_slots.clear()
	for index in range(FLOWER_GRID_SLOT_COUNT):
		var tier := FLOWER_TIER_EMPTY
		if index == 0 or index == 1:
			tier = FLOWER_TIER_SEED
		elif index == 2:
			tier = FLOWER_TIER_FLOWER
		flower_grove_grid_slots.append({
			"Tier": tier,
			"Locked": index >= flower_grove_active_plots * 2
		})


func _make_pond_decoration(decoration_name: String, cost_mana: int, beauty_value: int) -> Dictionary:
	return {
		"DecorationName": decoration_name,
		"CostMana": cost_mana,
		"BeautyValue": beauty_value,
		"IsUnlocked": true,
		"IsPlaced": false,
		"SlotIndex": -1,
		"PositionX": -1.0,
		"PositionY": -1.0
	}


func set_music_volume(value: float) -> void:
	music_volume = clamp(value, 0.0, 1.0)
	var sound_manager := _get_sound_manager()
	if sound_manager:
		sound_manager.set_music_volume(music_volume)
	save_game()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clamp(value, 0.0, 1.0)
	var sound_manager := _get_sound_manager()
	if sound_manager:
		sound_manager.set_sfx_volume(sfx_volume)
	save_game()

func get_exploration_data(location_id: String) -> Dictionary:
	match location_id:
		"forest_trail":
			return {
				"LocationID": "forest_trail",
				"Name": "Forest Trail",
				"UnlockLevel": 3,
				"CostMana": 30,
				"DurationSeconds": 300,
				"RewardCoinsMin": 100,
				"RewardCoinsMax": 100
			}
		"moonlit_clearing":
			return {
				"LocationID": "moonlit_clearing",
				"Name": "Moonlit Clearing",
				"UnlockLevel": 6,
				"CostMana": 300,
				"DurationSeconds": 180,
				"RewardCoinsMin": 500,
				"RewardCoinsMax": 1000
			}
		"crystal_hollow":
			return {
				"LocationID": "crystal_hollow",
				"Name": "Crystal Hollow",
				"UnlockLevel": 9,
				"CostMana": 1000,
				"DurationSeconds": 3600,
				"RewardCoinsMin": 1000,
				"RewardCoinsMax": 3000
			}
	return {}


func get_exploration_locations() -> Array[Dictionary]:
	return [
		get_exploration_data("forest_trail"),
		get_exploration_data("moonlit_clearing"),
		get_exploration_data("crystal_hollow")
	]


func get_exploration_gate_level() -> int:
	
	return min(flower_grove_level, potion_shop_level)


func is_exploration_unlocked(location_id: String) -> bool:
	var data := get_exploration_data(location_id)
	if data.is_empty():
		return false
	return get_exploration_gate_level() >= int(data.get("UnlockLevel", 999))

var exploration_active: bool = false
var exploration_location_id: String = ""
var exploration_end_unix: int = 0


func start_exploration(location_id: String) -> Dictionary:
	var data := get_exploration_data(location_id)
	if data.is_empty():
		return {"Success": false, "Message": "Unknown location."}
	if exploration_active:
		return {"Success": false, "Message": "An exploration is already underway."}
	if not is_exploration_unlocked(location_id):
		var needed := int(data.get("UnlockLevel", 0))
		return {"Success": false, "Message": "Locked. Needs Flower Grove and Potion Shop at level %d." % needed}
	var cost := int(data.get("CostMana", 0))
	if total_mana < cost:
		return {"Success": false, "Message": "Not enough Mana."}

	total_mana -= cost
	exploration_active = true
	exploration_location_id = location_id
	exploration_end_unix = int(Time.get_unix_time_from_system()) + int(data.get("DurationSeconds", 60))
	resources_changed.emit()
	save_game()
	return {"Success": true, "Message": "Exploring %s..." % String(data.get("Name", "location"))}


func update_exploration(_delta: float) -> void:
	# Time remaining is worked out from the system clock, so there is nothing to
	# count down here. This is kept so the _process hook above stays valid.
	pass


func get_exploration_time_remaining() -> int:
	if not exploration_active:
		return 0
	return max(0, exploration_end_unix - int(Time.get_unix_time_from_system()))


func is_exploration_ready() -> bool:
	return exploration_active and get_exploration_time_remaining() <= 0


func get_active_exploration_name() -> String:
	if not exploration_active:
		return ""
	return String(get_exploration_data(exploration_location_id).get("Name", "the wilds"))


func clear_exploration() -> void:
	exploration_active = false
	exploration_location_id = ""
	exploration_end_unix = 0


func claim_exploration_reward() -> Dictionary:
	if not exploration_active:
		return {"Success": false, "Message": "No exploration underway."}
	if get_exploration_time_remaining() > 0:
		return {"Success": false, "Message": "The fairies are still exploring."}

	var data := get_exploration_data(exploration_location_id)
	if data.is_empty():
		clear_exploration()
		save_game()
		return {"Success": false, "Message": "That exploration is no longer available."}

	var reward_min := int(data.get("RewardCoinsMin", 0))
	var reward_max := int(data.get("RewardCoinsMax", reward_min))
	var reward := reward_min
	if reward_max > reward_min:
		reward = randi_range(reward_min, reward_max)

	total_coins += reward
	var location_name := String(data.get("Name", "the grove"))
	clear_exploration()

	resources_changed.emit()
	save_game()
	return {"Success": true, "Message": "The fairies returned from %s with %d Coins!" % [location_name, reward], "Reward": reward}


func _get_sound_manager() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("SoundManager")
