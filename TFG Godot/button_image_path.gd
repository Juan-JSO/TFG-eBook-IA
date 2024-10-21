extends Button

class_name ButtonImagePath

@export var texture_rect: TextureRect
@export var check_box: CheckBox

var position_on_list: int = 0

var type: int = 0
var image_path_list: Array[String] = []

		
func check_button():
	if check_box.button_pressed == true:
		check_box.button_pressed = false
	else:
		if $"../../..".unique_image_path == true:
			$"../../..".uncheck_all_button_images()
		check_box.button_pressed = true


func uncheck():
	check_box.button_pressed = false


func is_checked():
	return check_box.button_pressed


func load_button_image_path():
	
	#generar lista de personas al hacer split
	
	if image_path_list.size() == 1:
		
		type = 0
	
		var image = Image.new()
		image.load(image_path_list[0])
	
		var image_texture = ImageTexture.new()
		image_texture.set_image(image)
		
		texture_rect.texture = image_texture

	else:
		
		type = 1
		
		var animated_texture = AnimatedTexture.new()
		
		animated_texture.set_frames(image_path_list.size())
		
		var i = 0
		for image_path in image_path_list:
	
			var image = Image.new()
			image.load(image_path)
	
			var image_texture = ImageTexture.new()
			image_texture.set_image(image)
			
			animated_texture.set_frame_texture(i, image_texture)
			animated_texture.set_frame_duration(i, 0.16666)
			
			i = i + 1
		
		texture_rect.texture = animated_texture

func _on_button_image_path_down():
	
	if MainManager.mm.image_display.get_node("MarginContainer/TextureRect").texture == texture_rect.texture:
	
		check_button()
	
	MainManager.mm.show_image(texture_rect.texture, type, image_path_list[0], $"../../..".position_on_list)


func _on_button_close_button_down():
	pass # Replace with function body.
