extends Node

const tmp_files_dir := "user://tmp"

var tmp_file_counter := 0

func _ready():
	var dir = DirAccess.open("user://")
	if not dir.dir_exists(tmp_files_dir):
		dir.make_dir_recursive(tmp_files_dir)
	
	var tmp_dir = DirAccess.open(tmp_files_dir)
	for file in tmp_dir.get_files():
		tmp_dir.remove(file)


func _exit_tree():
	var tmp_dir = DirAccess.open(tmp_files_dir)
	for file in tmp_dir.get_files():
		tmp_dir.remove(file)


func get_tmp_file_path() -> String:
	tmp_file_counter += 1
	return tmp_files_dir.path_join("tmp_file_%d" % tmp_file_counter)
