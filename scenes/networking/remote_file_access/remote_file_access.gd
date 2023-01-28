extends RefCounted

class_name RemoteFileAccess

const REQUEST_SCENE := preload("remote_file_request.tscn")

var parent_url: String = ""


func create_request(target_path: String):
	var final_url: String = ""
	
	if target_path.is_relative_path():
		final_url = parent_url.path_join(target_path)
	else:
		final_url = target_path
	var rqinstance = REQUEST_SCENE.instantiate()
	
	rqinstance.target_url = final_url
	return rqinstance
