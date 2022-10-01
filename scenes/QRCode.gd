extends Node2D

@onready var text_label := $url_label
@onready var qr_code_image := $QrCode

# Called when the node enters the scene tree for the first time.
func _ready():
	var qr_code: QrCode = QrCode.new()
	var url1 = "http://localhost:8001/demo url"
	var texture: ImageTexture = qr_code.get_texture(url1)

	text_label.text = "Client url : " + url1
	qr_code_image.texture = texture


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_button_pressed():
	get_tree().change_scene_to_file("res://scenes/main.tscn")
