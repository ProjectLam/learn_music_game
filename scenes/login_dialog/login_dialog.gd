extends Control

@onready var nAnimationPlayer = $AnimationPlayer
@onready var nLayer = $CanvasLayer/Layer

var is_opened: bool = false

func _ready():
	nLayer.visible = false

func _process(delta):
	pass

func open() -> void:
	is_opened = true
	nAnimationPlayer.play("Open")

func close() -> void:
	is_opened = false
	nAnimationPlayer.play("Close")
