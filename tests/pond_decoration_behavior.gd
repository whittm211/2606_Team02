extends SceneTree

func _init() -> void:
	var state = load("res://scripts/game_state.gd").new()
	state.reset_to_defaults()

	if state.pond_beauty != 0:
		fail("Pond beauty should start at 0")
	if state.get_pond_decoration_restore_bonus() != 0:
		fail("Decoration bonus should start at 0")
	if state.pond_decorations.size() != 15:
		fail("Expected fifteen starting pond decorations")
	if state.pond_decoration_slots.size() != 6:
		fail("Expected six preset decoration slots")

	state.total_mana = 25
	if not state.place_pond_decoration("Moon Lantern", 0):
		fail("Moon Lantern should place with enough mana")
	if state.total_mana != 0:
		fail("Moon Lantern should spend 25 mana")
	if state.pond_beauty != 5:
		fail("Moon Lantern should add 5 beauty")
	if state.get_pond_decoration_restore_bonus() != 0:
		fail("5 beauty should not add restore bonus yet")
	if not state.is_pond_slot_occupied(0):
		fail("Slot 0 should be occupied")
	var lantern_position: Vector2 = state.get_pond_decoration_position(state.pond_decorations[0])
	if lantern_position != state.get_default_pond_decoration_position(0):
		fail("Legacy slot placement should convert to default free position")

	state.total_mana = 40
	if not state.place_pond_decoration("Spirit Stone", 1):
		fail("Spirit Stone should place with enough mana")
	var free_position := Vector2(620, 780)
	if not state.move_pond_decoration("Spirit Stone", free_position):
		fail("Placed decoration should move to a free pond position")
	if state.get_pond_decoration_position(state.pond_decorations[1]) != free_position:
		fail("Moved decoration should keep exact free position")
	var normalized_position: Vector2 = state.get_pond_decoration_normalized_position(state.pond_decorations[1])
	if normalized_position.x < 0.0 or normalized_position.x > 1.0 or normalized_position.y < 0.0 or normalized_position.y > 1.0:
		fail("Moved decoration should save as a normalized pond position")
	var village_rect := Rect2(90, 484, 342, 276)
	var village_position: Vector2 = state.get_pond_decoration_screen_position(state.pond_decorations[1], village_rect)
	var expected_village_position := village_rect.position + village_rect.size * normalized_position
	if village_position != expected_village_position:
		fail("Village should map the same normalized pond position into its pond rectangle")
	if state.pond_beauty != 13:
		fail("Two decorations should total 13 beauty")
	if state.get_pond_decoration_restore_bonus() != 1:
		fail("13 beauty should add +1 restore bonus")
	if state.get_sacred_pond_total_restore_amount() != 7:
		fail("Default Pip total restore should include +1 decoration bonus")

	state.total_mana = 0
	if state.place_pond_decoration("Bloom Lilypad", 2):
		fail("Placement should fail without mana")
	if state.last_pond_decoration_message != "Not enough Mana.":
		fail("Expected not enough mana message")

	state.total_mana = 999
	state.place_pond_decoration("Bloom Lilypad", 2)
	state.place_pond_decoration("Sacred Bridge", 3)
	if state.place_pond_decoration("Moon Lantern", 4):
		fail("Already placed decoration should not place twice")

	if not state.remove_pond_decoration("Moon Lantern"):
		fail("Remove should clear placed decoration")
	if state.is_pond_slot_occupied(0):
		fail("Slot should be empty after removal")

	var data: Dictionary = state.get_save_data()
	if not data.has("pond_beauty"):
		fail("Save data should include pond beauty")
	var loaded_state = load("res://scripts/game_state.gd").new()
	loaded_state.apply_save_data(data)
	if loaded_state.pond_beauty != state.pond_beauty:
		fail("Loaded pond beauty should persist")
	if loaded_state.get_pond_decoration_restore_bonus() != state.get_pond_decoration_restore_bonus():
		fail("Loaded decoration bonus should persist")
	if loaded_state.get_pond_decoration_position(loaded_state.pond_decorations[1]) != free_position:
		fail("Loaded decoration free position should persist")

	var legacy_state = load("res://scripts/game_state.gd").new()
	legacy_state.apply_save_data({
		"pond_decorations": [
			{
				"DecorationName": "Moon Lantern",
				"CostMana": 25,
				"BeautyValue": 5,
				"IsUnlocked": true,
				"IsPlaced": true,
				"SlotIndex": 2
			}
		]
	})
	if legacy_state.get_pond_decoration_position(legacy_state.pond_decorations[0]) != legacy_state.get_default_pond_decoration_position(2):
		fail("Old slot-only saves should migrate to a free position")

	print("Pond decoration behavior check passed")
	quit(0)


func fail(message: String) -> void:
	push_error(message)
	quit(1)
