extends Node

# In the future this autoload will be used to create a cache for all relevant users.
# It will also help avoid duplication and confusion of the User objects.

var old_users := {}

func get_from(p_from):
	return User.new(p_from)
