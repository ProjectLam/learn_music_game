extends Node

var arguments = {}

# this node parses the command line arguments into a singleton for use.
# example(to simplify testing with different users) :
# godot4 -- --email=testmail@testmail.com --password=password

func _init():
	for argument in OS.get_cmdline_user_args():
		if argument.find("=") > -1:
			var key_value = argument.split("=")
			arguments[key_value[0].lstrip("--")] = key_value[1]
		else:
		# Options without an argument will be present in the dictionary,
		# with the value set to an empty string.
			arguments[argument.lstrip("--")] = ""
	
	print("Game started with user command line arguemtns :", arguments)
