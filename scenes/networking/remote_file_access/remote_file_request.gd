extends Node

signal request_completed(buffer)
signal request_completed_string(str)
signal failed(code, message)

@export var target_url: String = ""

@onready var http_request = %HTTPRequest
@onready var retry_timer = %retry_timer

@export var request_headers: PackedStringArray = []
@export_multiline var request_body: String = ""

# todo : add export enum for this.
var request_method := HTTPClient.METHOD_GET

@export var tls_validate := true

# negative number means infinite retry.
@export_range(-1,9999) var default_retry_count := 3
var retry_count := default_retry_count
# retry interval in seconds.
@export_range(0.1, 5.0) var retry_interval := 1.0

enum ERROR_CODES {
	NONE,
	COULD_NOT_CREATE_REQUEST,
	COULD_NOT_CONNECT,
	BAD_RESULT,
}

var ignore_network_status := false
var ask_offline := true
var remove_fetcher := false

func _ready():
	if not ignore_network_status:
		if GBackend.file_src_mode == GBackend.FILE_SRC_MODE.OFFLINE:
			print("File source is in offline mode. Ignoring fetch of ", target_url)
			return
		GBackend.add_fetcher()
		remove_fetcher = true
	
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
		err = http_request.request(target_url, request_headers, request_method, request_body)
		if err != OK:
			push_error("HTTPClient Error encountered while trying to create http request : ", err)
			await retry_if_allowed(ERROR_CODES.COULD_NOT_CREATE_REQUEST, "HTTPClient Error encountered while trying to create http request : %s" % err)


func _on_http_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	if response_code == HTTPClient.RESPONSE_NOT_FOUND:
		push_error("Requested file not found : ", target_url)
		request_completed.emit([])
		request_completed_string.emit("{}")
		queue_free()
	elif result == HTTPRequest.RESULT_SUCCESS:
		print("file [%s] downloaded." % target_url)
		_on_request_completed()
		queue_free()
	else:
		push_error("Bad HTTPRequest result :", result)
		await retry_if_allowed(ERROR_CODES.BAD_RESULT, "Bad HTTPRequest result : %s" % result)


func get_downloaded_bytes():
	return http_request.get_downloaded_bytes()


func get_total_bytes():
	return http_request.get_body_size()


func _on_request_completed():
	if not request_completed.get_connections().is_empty():
		request_completed.emit(FileAccess.get_file_as_bytes(http_request.download_file))
	if not request_completed_string.get_connections().is_empty():
		request_completed_string.emit(FileAccess.get_file_as_string(http_request.download_file))


var last_failure_code := ERROR_CODES.NONE 
func retry_if_allowed(code, message):
	if default_retry_count < 0:
		# infinite retry
		retry_timer.start(retry_interval)
	elif code != last_failure_code:
		last_failure_code = code
		retry_count = default_retry_count
		retry_timer.start(retry_interval)
	elif retry_count > 0:
		retry_count -= 1
		retry_timer.start(retry_interval)
	else:
		failed.emit(code, message)
		if ask_offline:
			await Dialogs.file_offline_dialog.open()
			await Dialogs.file_offline_dialog.closed
			if GBackend.file_src_mode == GBackend.FILE_SRC_MODE.OFFLINE:
				queue_free()
			else:
				retry_count = default_retry_count
				retry_timer.start(retry_interval)


func _exit_tree():
	if remove_fetcher:
		GBackend.remove_fetcher()
