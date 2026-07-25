extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node_or_null("GameState")
	if game_state == null:
		fail("GameState autoload should be available")
		return
	game_state.reset_to_defaults()
	game_state.total_mana = 100
	game_state.total_coins = 50
	game_state.sacred_pond_spirit_energy = 0

	var panel: Node = load("res://ui/ArcaneForgePanel.tscn").instantiate()
	root.add_child(panel)
	await process_frame

	var flower_status := _find_label(panel, "ForgeUpgradeStatus_flower_focus")
	if flower_status == null or flower_status.text != "Ready to forge.":
		fail("Affordable Forge upgrade should explain it is ready")
		return

	var flower_pill := _find_label(panel, "ForgeUpgradePill_flower_focus")
	if flower_pill == null or flower_pill.text != "Ready":
		fail("Affordable Forge upgrade should show a Ready pill")
		return

	var flower_button := _find_button(panel, "ForgeButton_flower_focus")
	if flower_button == null or flower_button.disabled or flower_button.text != "Forge":
		fail("Affordable Forge upgrade should have an enabled Forge button")
		return

	panel._on_next_upgrade_pressed()
	await process_frame

	var potion_status := _find_label(panel, "ForgeUpgradeStatus_potion_gilding")
	if potion_status == null or potion_status.text != "Need 50 Coins.":
		fail("Blocked Forge upgrade should list missing Coins")
		return

	var potion_button := _find_button(panel, "ForgeButton_potion_gilding")
	if potion_button == null or not potion_button.disabled or potion_button.text != "Need More":
		fail("Blocked Forge upgrade should show disabled Need More button")
		return

	panel._on_previous_upgrade_pressed()
	await process_frame

	var flower_effect := _find_label(panel, "ForgeUpgradeEffect_flower_focus")
	if flower_effect == null or not flower_effect.text.contains("Flower Grove Mana/sec"):
		fail("Forge upgrade should describe the effect before purchase")
		return
	flower_button = _find_button(panel, "ForgeButton_flower_focus")
	if flower_button == null or flower_button.disabled:
		fail("Affordable Forge upgrade should still be available after paging")
		return

	flower_button.pressed.emit()
	await process_frame
	if game_state.forge_flower_focus_level != 1:
		fail("Forge purchase should increase upgrade level")
		return
	if game_state.total_mana != 0 or game_state.total_coins != 0:
		fail("Forge purchase should spend required resources")
		return

	var refreshed_status := _find_label(panel, "ForgeUpgradeStatus_flower_focus")
	if refreshed_status == null or refreshed_status.text != "Need 175 Mana + 100 Coins.":
		fail("Forge upgrade status should refresh with next-level cost")
		return

	panel.queue_free()
	print("Arcane Forge polish behavior check passed")
	quit(0)


func _find_label(node: Node, label_name: String) -> Label:
	if node is Label and String(node.name) == label_name:
		return node
	for child in node.get_children():
		var found := _find_label(child, label_name)
		if found:
			return found
	return null


func _find_button(node: Node, button_name: String) -> BaseButton:
	if node is BaseButton and String(node.name) == button_name:
		return node
	for child in node.get_children():
		var found := _find_button(child, button_name)
		if found:
			return found
	return null


func fail(message: String) -> void:
	push_error(message)
	quit(1)
