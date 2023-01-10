extends Node

var httprqn : HTTPRequest
var goomsdksg
var waiting_to_connect : bool = false
var request_dict := {}
var goom_containers := {
	# ID : GoomContainer
	}

func _ready():
	httprqn = HTTPRequest.new()
	add_child(httprqn)
	httprqn.connect("request_completed", http_request_completed)
	if Engine.has_singleton("GoomSDKVideoPlugin"):
		goomsdksg = Engine.get_singleton("GoomSDKVideoPlugin")
		goomsdksg.init()
		goom_container_resized()
		await get_tree().process_frame
		goom_container_resized()
	else:
		push_error("GOOMSDK SIGNLETON NOT FOUND")

func http_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if !waiting_to_connect:
		return
	waiting_to_connect = false
	if response_code != HTTPClient.RESPONSE_OK:
		notify_client("invalid http reponse code : %d" % response_code, true)
		return
	var parsed_body = JSON.parse_string(body.get_string_from_utf8())
	if !(parsed_body is Dictionary)|| !(parsed_body.has("signature")):
		notify_client("invalid http response body : %s" % parsed_body, true)
		return
	var signature = parsed_body.get("signature")
	if !(signature is String):
		notify_client("invalid signature %s" % signature, true)
		return
	print_debug("valid http response : ", parsed_body)
	goomsdk_connect_session(signature, request_dict["sessionName"], request_dict["userIdentity"],
		request_dict["pwd"])
	
func goomsdk_connect_session(jwt : String, session_name : String, user_name : String, session_password : String):
	if(!goomsdksg):
		notify_client("INVALID GOOMSDK SINGLETON", true)
		return
	goomsdksg.connect_session(jwt, session_name, user_name, session_password)
	

func connect_session(backend_url : String, session_name : String, username : String, session_password : String):
	request_dict = {
		"userIdentity" : username,
		"role" : 1,
		"sessionName" : session_name,
		"pwd" : session_password
	}
	waiting_to_connect = true
	httprqn.cancel_request()
	httprqn.request(backend_url, ["Content-Type: application/json"], false, HTTPClient.METHOD_POST, 
		JSON.stringify(request_dict))

func notify_client(message : String, error : bool = false):
	if goomsdksg:
		if(error):
			push_error(message)
		else:
			print_debug(message)
		goomsdksg.godotToast(message)

func set_goom_container(new_container : GoomContainer, id : String):
	var goom_container = goom_containers.get(id)
	
	if is_instance_valid(goom_container):
		if goom_container.is_connected("global_item_rect_changed", goom_container_resized):
			goom_container.disconnect("global_item_rect_changed", goom_container_resized)
	if is_instance_valid(new_container):
		goom_containers[id] = new_container
		if !new_container.is_connected("global_item_rect_changed", goom_container_resized):
			new_container.connect("global_item_rect_changed", goom_container_resized)
		goom_container_resized()
	else:
		goom_containers.erase(id)
		
func goom_container_resized():
	if !is_inside_tree():
		return
	var tree := get_tree()
	if !(tree.is_connected("process_frame", _goom_container_resized)):
		assert(tree.connect("process_frame", _goom_container_resized, CONNECT_ONE_SHOT) == OK)

func _goom_container_resized():
	if !is_instance_valid(goomsdksg):
		return
	var cdict := {}
	# this factor is meant for canvas stretch with expand aspect.
	var vpsize := Vector2(DisplayServer.screen_get_size())
	var pjsize := Vector2(get_viewport().get_visible_rect().size)
	var sratio = vpsize/pjsize
	for id in goom_containers:
		var goom_container : GoomContainer = goom_containers[id]
		if is_instance_valid(goom_container):
			cdict[goom_container.target_id] = {
					"left" : int(goom_container.global_position.x*sratio.x),
					"top" : int(goom_container.global_position.y*sratio.y),
					"width" : int(goom_container.size.x*sratio.x),
					"height" : int(goom_container.size.y*sratio.y),
					"type" : goom_container.get_type_string(),
					"parent_id" : goom_container.get_parent_container(),
				}
	goomsdksg.configureLayout(cdict)

func set_goom_visibility(visible : bool):
	pass

func add_dummy_student():
	if(is_instance_valid(goomsdksg)):
		goomsdksg.add_dummy_view()
