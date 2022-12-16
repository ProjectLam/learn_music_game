extends Control

var AUTH_URL = "https://accounts.google.com/o/oauth2/v2/auth"
var TOKEN_URL = "https://oauth2.googleapis.com/token"

var client_secret = "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"
var client_id = "1001908266518-a1bct6prbqi12q8khvk6bqori7tle98g.apps.googleusercontent.com"

var callback_url = "http://127.0.0.1"

func login() -> void:
	var body_parts = [
		"client_id=%s" % client_id,
		"redirect_uri=%s" % callback_url,
		"response_type=code",
		"scope=https://www.googleapis.com/auth/youtube.readonly",
	]
	var url = AUTH_URL + "?" + body_parts.join("&")
	
	OS.shell_open(url)
