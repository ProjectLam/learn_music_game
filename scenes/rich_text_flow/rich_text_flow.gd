extends Control

@onready var scroll_container = %ScrollContainer
@onready var text_container = %TextContainer
@onready var fadeout_timer = %FadeoutTimer
@onready var animation_player = %AnimationPlayer


func _ready() -> void:
	scroll_container.get_v_scroll_bar().changed.connect(_on_scroll_changed)
	scroll_container.get_v_scroll_bar().value_changed.connect(_on_scroll_value_changed)
	fadeout_timer.timeout.connect(_on_fadeout_timer_timeout)


func _process(delta) -> void:
	pass


func _on_scroll_changed() -> void:
	fadeout_timer.stop()
	fadeout_timer.start()
	fadeout_timer.paused = false
	animation_player.play("RESET")


func _on_scroll_value_changed(value: float) -> void:
	_on_scroll_changed()


func _on_fadeout_timer_timeout() -> void:
	animation_player.play("Fadeout")


func refresh():
	_on_scroll_changed()
