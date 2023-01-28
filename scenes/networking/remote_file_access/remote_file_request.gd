extends Node

signal request_completed(buffer)

var target_url: String = ""

@onready var http_request = %HTTPRequest
@onready var retry_timer = %retry_timer

var request_headers: PackedStringArray = []
var request_body: String

var request_method := HTTPClient.METHOD_GET

var tls_validate := true

# retry interval in seconds.
var retry_interval := 1.0


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
	if result == HTTPRequest.RESULT_SUCCESS:
		print("file downloaded.")
		request_completed.emit(FileAccess.get_file_as_bytes(http_request.download_file))
		queue_free()
	else:
		push_error("Bad HTTPRequest result :", result)
		retry_timer.start(retry_interval)


func get_downloaded_bytes():
	return http_request.get_downloaded_bytes()


func get_remaining_bytes():
	return http_request.get_body_size()
