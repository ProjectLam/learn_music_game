extends Node

signal request_completed(buffer)
signal request_completed_string(str)

@export var target_url: String = ""

@onready var http_request = %HTTPRequest
@onready var retry_timer = %retry_timer

@export var request_headers: PackedStringArray = []
@export_multiline var request_body: String = ""

# todo : add export enum for this.
var request_method := HTTPClient.METHOD_GET

@export var tls_validate := true

# retry interval in seconds.
@export_range(0.1, 5.0) var retry_interval := 1.0


func _ready():
	http_request.request_completed.connect(_on_http_request_completed)
	
	# TODO : create a better temporary file destination.a.
	http_request.download_file = TmpFiles.get_tmp_file_path()
	
	if target_url == "":
		push_error("empty url")
		return
	retry_timer.timeout.connect(try)
	# TODO : add url validation.
	try()


func retry():
	print("retrying http request...")
	try()


func try():
	var err = OK + 1
	while(err != OK):
		err = http_request.request(target_url, request_headers, tls_validate, request_method, request_body)
		if err != OK:
			push_error("HTTPClient Error encountered while trying to create http request : ", err)
			retry_timer.start(retry_interval)


func _on_http_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if response_code == HTTPClient.RESPONSE_NOT_FOUND:
		push_error("Requested file not found : ", target_url)
		request_completed.emit([])
		request_completed_string.emit("")
		queue_free()
	if result == HTTPRequest.RESULT_SUCCESS:
		print("file [%s] downloaded." % target_url)
		_on_request_completed()
		queue_free()
	else:
		push_error("Bad HTTPRequest result :", result)
		retry_timer.start(retry_interval)


func get_downloaded_bytes():
	return http_request.get_downloaded_bytes()


func get_remaining_bytes():
	return http_request.get_body_size()


func _on_request_completed():
	if not request_completed.get_connections().is_empty():
		request_completed.emit(FileAccess.get_file_as_bytes(http_request.download_file))
	if not request_completed_string.get_connections().is_empty():
		request_completed_string.emit(FileAccess.get_file_as_string(http_request.download_file))
