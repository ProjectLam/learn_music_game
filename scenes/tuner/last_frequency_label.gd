extends Label


func _process(delta):
	var last_raw_peaks: PackedVector2Array = InstrumentInput.microphone_input.last_raw_peaks
	
	if last_raw_peaks.size() > 0:
		var vl = last_raw_peaks[0].y
		if vl > InstrumentInput.microphone_input.volume_start_threshold:
			text = "%d Hz" % (last_raw_peaks[0].x*0.5)
#		print_debug(last_raw_peaks)
#			print_debug(AudioM
#	if InstrumentInput.microphone_input.last_adjusted_peaks.size() > 0:
#		print_debug(InstrumentInput.microphone_input.last_adjusted_peaks)
#	else:
#		text = "0 Hz"
