extends MarginContainer


func _on_button_button_down():
	
	disable()
	
	$"../../..".request_image()


func disable():
	
	$Button.text = "..."
