extends Control

signal play
signal delete
signal statistics

@onready var nLayer = $CanvasLayer/Layer

var is_opened: bool = false

var song: TSong

func _ready() -> void:
	visible = false
	nLayer.visible = false

func open(p_song) -> void:
	$AnimationPlayer.play("Open")

func close() -> void:
	$AnimationPlayer.play("Close")
	await $AnimationPlayer.animation_finished

func _on_Layer_gui_input(event):
	if event is InputEventMouseButton and event.is_pressed():
		close()
