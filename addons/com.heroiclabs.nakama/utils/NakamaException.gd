extends RefCounted

# An exception generated during a request.
# Usually contains at least an error message.
class_name NakamaException


#This module provides a selection of GRPC status codes
#https://github.com/grpc/grpc/blob/master/doc/statuscodes.md
#are mapped to HTTP status codes in
#https://github.com/grpc-ecosystem/grpc-gateway/blob/aec6aa29864109e41408491319a859f190ec4040/runtime/errors.go#L36
#
#See https://forum.heroiclabs.com/t/custom-rpc-response-status-in-lua/619 for more info.

enum GRPC_STATUS_CODES {
	OK                  = 0,
	CANCELED            = 1,
	UNKNOWN             = 2,
	INVALID_ARGUMENT    = 3,
	DEADLINE_EXCEEDED   = 4,
	NOT_FOUND           = 5,
	ALREADY_EXISTS      = 6,
	PERMISSION_DENIED   = 7,
	RESOURCE_EXHAUSTED  = 8,
	FAILED_PRECONDITION = 9,
	ABORTED             = 10,
	OUT_OF_RANGE        = 11,
	UNIMPLEMENTED       = 12,
	INTERNAL            = 13,
	UNAVAILABLE         = 14,
	DATA_LOSS           = 15,
	UNAUTHENTICATED     = 16,
}


var _status_code : int = -1
var status_code : int:
	set(v):
		pass
	get:
		return _status_code

var _grpc_status_code : int = -1
var grpc_status_code : int:
	set(v):
		pass
	get:
		return _grpc_status_code

var _message : String = ""
var message : String:
	set(v):
		pass
	get:
		return _message

var _cancelled : bool = false
var cancelled : bool:
	set(v):
		pass
	get:
		return _cancelled

func _init(p_message : String = "", p_status_code : int = -1, p_grpc_status_code : int = -1, p_cancelled : bool = false):
	_status_code = p_status_code
	_grpc_status_code = p_grpc_status_code
	_message = p_message
	_cancelled = p_cancelled

func _to_string() -> String:
	return "NakamaException(StatusCode={%s}, Message='{%s}', GrpcStatusCode={%s})" % [_status_code, _message, _grpc_status_code]
