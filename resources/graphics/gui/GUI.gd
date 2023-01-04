extends ColorRect

func _process(_delta):
	$FPS_COUNTER.text = str(Engine.get_frames_per_second()) + " FPS"
