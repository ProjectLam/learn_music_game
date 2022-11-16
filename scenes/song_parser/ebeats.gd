class_name Ebeats


@export var count  = 0 
@export var beats:Array[Vector2] = []

var measures: Array


func add_beat(measure: int, time: float):
	if measure >= measures.size():
		if measures.size() > 0:
			measures[-1].end_time = time
		measures.append(Measure.new(time))
	
	measures[-1].add_beat(time)


class Measure:
	var start_time: float
	var end_time: float
	var beats: Array[Beat]
	
	
	func _init(_start_time: float):
		start_time = _start_time
	
	
	func add_beat(time: float):
		beats.append(Beat.new(time))
		
		# Only necessary so the last measure has a valid end time
		end_time = max(end_time, time)


class Beat:
	var time: float
	
	
	func _init(_time):
		time = _time
