extends Label


# Called when the node enters the scene tree for the first time.
func _process(delta):
	if owner.performance_instrument:
		text = "%2.2f" % owner.performance_instrument.get_time()
