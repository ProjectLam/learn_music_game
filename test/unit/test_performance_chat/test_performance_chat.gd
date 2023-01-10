extends Control

@export var session_name : String = "test_performance"
@export var session_pwd : String = "pwd"
# use your own ip address.
# TODO : add an external configuration with gitignore exclusion for test backend url.
@export var jwt_backend_url : String = "http://192.168.0.10:4000"

func join_student():
	var sssn : String = session_name
	var usrn : String = "student"
	var pwd : String = session_pwd
	var burl : String = jwt_backend_url
	GoomSdk.connect_session(burl, sssn, usrn, pwd)
	
func join_teacher():
	var sssn : String = session_name
	var usrn : String = "teacher"
	var pwd : String = session_pwd
	var burl : String = jwt_backend_url
	GoomSdk.connect_session(burl, sssn, usrn, pwd)

func _on_join_student_pressed():
	join_student()


func _on_join_teacher_pressed():
	join_teacher()

func _ready():
	GoomSdk.call_deferred("add_dummy_student")
	GoomSdk.call_deferred("add_dummy_student")
