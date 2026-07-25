extends SceneTree

var failed_any := false


func _init() -> void:
	var state = load("res://scripts/game_state.gd").new()
	state.reset_to_defaults()

	_verify_market_stall(state)
	_verify_ancient_tree(state)
	_verify_arcane_forge(state)
	_verify_save_load(state)

	if failed_any:
		quit(1)
		return
	print("Building systems behavior check passed")
	quit(0)


func _verify_market_stall(state: Node) -> void:
	if state.get("market_reputation") != 1:
		fail("Market reputation should start at 1")
	if state.get("market_orders_completed") != 0:
		fail("Market completed orders should start at 0")
	if not state.has_method("fulfill_market_order"):
		fail("GameState should implement fulfill_market_order")
		return

	state.total_mana = 40
	var mana_order: Dictionary = state.fulfill_market_order("mana_bundle")
	if not bool(mana_order.get("Success", false)):
		fail("Mana bundle order should succeed with 40 mana")
	if state.total_mana != 15:
		fail("Mana bundle order should spend 25 mana")
	if state.total_coins != 35:
		fail("Mana bundle order should pay 35 coins")
	if state.market_orders_completed != 1:
		fail("Market order count should increase")
	if state.market_reputation != 2:
		fail("Market reputation should rise after first order")

	var failed_order: Dictionary = state.fulfill_market_order("potion_crate")
	if bool(failed_order.get("Success", false)):
		fail("Potion crate should fail without potions")
	if state.total_coins != 35:
		fail("Failed market order should not change coins")

	state.mana_potion_count = 2
	var potion_order: Dictionary = state.fulfill_market_order("potion_crate")
	if not bool(potion_order.get("Success", false)):
		fail("Potion crate should succeed with two potions")
	if state.mana_potion_count != 1:
		fail("Potion crate should spend one potion")
	if state.total_coins != 110:
		fail("Potion crate should pay 75 coins")


func _verify_ancient_tree(state: Node) -> void:
	if not state.has_method("restore_ancient_tree"):
		fail("GameState should implement restore_ancient_tree")
		return
	if not state.has_method("claim_ancient_tree_reward"):
		fail("GameState should implement claim_ancient_tree_reward")
		return
	if not state.has_method("get_next_ancient_tree_reward_text"):
		fail("GameState should implement get_next_ancient_tree_reward_text")
		return
	state.total_mana = 200
	var restored: Dictionary = state.restore_ancient_tree()
	if not bool(restored.get("Success", false)):
		fail("Ancient Tree watering should succeed while water uses remain")
	if state.ancient_tree_growth != 25:
		fail("Ancient Tree watering should add 10 growth")
	if state.ancient_tree_level != 2:
		fail("Ancient Tree level should update at 25 growth")
	if int(restored.get("RemainingWaters", -1)) != 2:
		fail("Ancient Tree watering should track remaining daily waters")
	if String(restored.get("RewardText", "")).is_empty():
		fail("Ancient Tree watering should award a nurture reward")
	if not state.is_quest_completed("awaken_roots"):
		fail("Awaken Roots quest should complete after restoring Ancient Tree")
	if state.get_next_ancient_tree_reward_text() != "Level 2 reward ready":
		fail("Next Ancient Tree reward text should show ready reward")

	var mana_before_claim: int = state.total_mana
	var claimed: Dictionary = state.claim_ancient_tree_reward(2)
	if not bool(claimed.get("Success", false)):
		fail("Ancient Tree level 2 reward should be claimable")
	if state.ancient_tree_claimed_rewards.size() != 1:
		fail("Ancient Tree claimed reward should persist in list")
	if state.total_mana != mana_before_claim + 25:
		fail("Ancient Tree level 2 reward should grant 25 mana")
	if bool(state.claim_ancient_tree_reward(2).get("Success", false)):
		fail("Ancient Tree reward should not be claimable twice")
	if state.get_next_ancient_tree_reward_text() != "Level 3 reward at 50% restoration":
		fail("Next Ancient Tree reward text should point at level 3 after claiming level 2")


func _verify_arcane_forge(state: Node) -> void:
	if not state.has_method("purchase_forge_upgrade"):
		fail("GameState should implement purchase_forge_upgrade")
		return
	state.total_mana = 250
	state.total_coins = 250
	state.sacred_pond_spirit_energy = 40

	var flower_rate_before: float = state.get_flower_base_production_rate()
	var flower_upgrade: Dictionary = state.purchase_forge_upgrade("flower_focus")
	if not bool(flower_upgrade.get("Success", false)):
		fail("Flower Focus forge upgrade should succeed with enough resources")
	if state.forge_flower_focus_level != 1:
		fail("Flower Focus forge upgrade level should increase")
	if state.get_flower_base_production_rate() <= flower_rate_before:
		fail("Flower Focus should increase flower production")

	var potion_value_before: int = state.get_potion_sell_value()
	var potion_upgrade: Dictionary = state.purchase_forge_upgrade("potion_gilding")
	if not bool(potion_upgrade.get("Success", false)):
		fail("Potion Gilding forge upgrade should succeed with enough resources")
	if state.forge_potion_gilding_level != 1:
		fail("Potion Gilding level should increase")
	if state.get_potion_sell_value() <= potion_value_before:
		fail("Potion Gilding should increase potion sell value")

	var pond_restore_before: int = state.get_sacred_pond_base_restore_amount()
	var pond_upgrade: Dictionary = state.purchase_forge_upgrade("pond_resonance")
	if not bool(pond_upgrade.get("Success", false)):
		fail("Pond Resonance forge upgrade should succeed with enough resources")
	if state.forge_pond_resonance_level != 1:
		fail("Pond Resonance level should increase")
	if state.get_sacred_pond_base_restore_amount() <= pond_restore_before:
		fail("Pond Resonance should increase pond restore amount")

	state.total_mana = 0
	if bool(state.purchase_forge_upgrade("flower_focus").get("Success", false)):
		fail("Forge upgrade should fail without resources")


func _verify_save_load(state: Node) -> void:
	var data: Dictionary = state.get_save_data()
	for key in [
		"market_reputation",
		"market_orders_completed",
		"ancient_tree_level",
		"ancient_tree_claimed_rewards",
		"forge_level",
		"forge_flower_focus_level",
		"forge_potion_gilding_level",
		"forge_pond_resonance_level"
	]:
		if not data.has(key):
			fail("Save data should include %s" % key)

	var loaded = load("res://scripts/game_state.gd").new()
	loaded.apply_save_data(data)
	if loaded.get("market_reputation") != state.get("market_reputation"):
		fail("Market reputation should load")
	if loaded.get("ancient_tree_level") != state.get("ancient_tree_level"):
		fail("Ancient Tree level should load")
	var loaded_rewards = loaded.get("ancient_tree_claimed_rewards")
	var state_rewards = state.get("ancient_tree_claimed_rewards")
	if not (loaded_rewards is Array) or not (state_rewards is Array) or loaded_rewards.size() != state_rewards.size():
		fail("Ancient Tree rewards should load")
	if loaded.get("forge_flower_focus_level") != state.get("forge_flower_focus_level"):
		fail("Forge flower focus level should load")
	if loaded.get("forge_potion_gilding_level") != state.get("forge_potion_gilding_level"):
		fail("Forge potion gilding level should load")
	if loaded.get("forge_pond_resonance_level") != state.get("forge_pond_resonance_level"):
		fail("Forge pond resonance level should load")


func fail(message: String) -> void:
	failed_any = true
	push_error(message)
