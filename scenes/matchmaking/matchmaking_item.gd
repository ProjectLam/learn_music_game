extends PanelContainer

signal selected

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func _on_OverlayBtn_pressed() -> void:
	emit_signal("selected")
