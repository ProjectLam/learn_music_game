extends MarginContainer
class_name CoursesItem

@export var image: ImageTexture = null
@export var title: String = ""
@export var description: String = ""

@onready var nCourses: Courses = find_parent("Courses")

@onready var nBox: PanelContainer = find_child("Box")

@onready var nCompletedLabel: Label = find_child("CompletedLabel")
@onready var nCourseImage: TextureRect = find_child("CourseImage")
@onready var nTitleLabel: Label = find_child("TitleLabel")
@onready var nDescLabel: Label = find_child("DescLabel")

var is_completed: bool = false: set = set_is_completed

func _ready():
	nCompletedLabel.hide()

func _process(delta):
	pass

func set_image(p_image: ImageTexture) -> void:
	image = p_image
	nCourseImage.texture = image

func set_title(p_title: String) -> void:
	title = p_title
	nTitleLabel.text = title

func set_description(p_description: String) -> void:
	description = p_description
	nDescLabel.text = description

func set_is_completed(p_is_completed: bool) -> void:
	is_completed = p_is_completed
	
	if is_completed:
		nBox.add_theme_stylebox_override("panel", nCourses.item_stylebox_completed)
		nCompletedLabel.show()
	else:
		nBox.add_theme_stylebox_override("panel", nCourses.item_stylebox_normal)
		nCompletedLabel.show()
