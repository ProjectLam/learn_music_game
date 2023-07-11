extends VBoxContainer

const SCORE_VIEWER_SCENE := preload("res://scenes/performance/match_end_player_score_viewer.tscn")

func reload_users(_iusers: Dictionary):
	for c in get_children():
		c.queue_free()
#		remove_child(c)
#		c.free()
	
	for iuser in _iusers:
		var inode = SCORE_VIEWER_SCENE.instantiate()
		
		var iuser_data: IngameUser = _iusers[iuser]
		
		if iuser_data.user:
			inode.username = iuser_data.user.username
		else:
			inode.username = "Me"
		
		if iuser_data.ready_status == IngameUser.ReadyStatus.ENDED_PLAYING:
			inode.score = str(iuser_data.score)
		
		add_child(inode)
		
	
	
