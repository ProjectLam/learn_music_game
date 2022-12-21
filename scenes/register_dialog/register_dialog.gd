extends Control

@onready var nAnimationPlayer = $AnimationPlayer
@onready var nLayer = $CanvasLayer/Layer
@onready var nBox = find_child("Box")

var is_opened: bool = false

func _ready():
	nLayer.visible = false

func _process(delta):
	nBox.pivot_offset.x = nBox.size.x / 2
	nBox.pivot_offset.y = nBox.size.y / 2

func open() -> void:
	is_opened = true
	nAnimationPlayer.play("Open")

func close() -> void:
	is_opened = false
	nAnimationPlayer.play("Close")

func _on_LoginBtn_pressed():
	pass

func _on_CloseBtn_pressed() -> void:
	close()
