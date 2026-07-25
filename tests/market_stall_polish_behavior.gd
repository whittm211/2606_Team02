extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := root.get_node_or_null("GameState")
	if game_state == null:
		fail("GameState autoload should be available")
		return
	game_state.reset_to_defaults()
	game_state.total_mana = 25
	game_state.mana_potion_count = 0
	game_state.sacred_pond_spirit_energy = 0

	var panel: Node = load("res://ui/MarketStallPanel.tscn").instantiate()
	root.add_child(panel)
	await process_frame

	var mana_status := _find_label(panel, "MarketOrderStatus_mana_bundle")
	if mana_status == null or mana_status.text != "Ready to trade.":
		fail("Ready Market order should explain it can be traded")
		return

	var mana_pill := _find_label(panel, "MarketOrderPill_mana_bundle")
	if mana_pill == null or mana_pill.text != "Ready":
		fail("Ready Market order should show a Ready pill")
		return

	var mana_button := _find_button(panel, "TradeButton_mana_bundle")
	if mana_button == null or mana_button.disabled or mana_button.text != "Trade":
		fail("Ready Market order should have an enabled Trade button")
		return

	panel._on_next_order_pressed()
	await process_frame

	var potion_status := _find_label(panel, "MarketOrderStatus_potion_crate")
	if potion_status == null or potion_status.text != "Need 1 Mana Potion.":
		fail("Blocked potion order should list missing Mana Potions")
		return

	var potion_button := _find_button(panel, "TradeButton_potion_crate")
	if potion_button == null or not potion_button.disabled or potion_button.text != "Need More":
		fail("Blocked potion order should show disabled Need More button")
		return

	panel._on_previous_order_pressed()
	await process_frame
	mana_button = _find_button(panel, "TradeButton_mana_bundle")
	if mana_button == null:
		fail("Mana bundle order should be visible again after paging back")
		return
	mana_button.pressed.emit()
	await process_frame
	if game_state.total_coins != 35:
		fail("Ready Market trade should pay Coins")
		return
	if game_state.market_reputation != 2:
		fail("Ready Market trade should add reputation")
		return

	var refreshed_mana_status := _find_label(panel, "MarketOrderStatus_mana_bundle")
	if refreshed_mana_status == null or refreshed_mana_status.text != "Need 25 Mana.":
		fail("Market order status should refresh after spending resources")
		return

	panel.queue_free()
	print("Market Stall polish behavior check passed")
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
