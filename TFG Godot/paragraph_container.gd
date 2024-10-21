extends PanelContainer

class_name ParagraphContainer

var original_button_image_path = preload("res://button_image_path.tscn")
var original_button_generate_image = preload("res://button_generate_image.tscn")

var paragraph: ParagraphData

var position_on_list: int = 0

var button_image_path_list = []
var button_generate_image = null

var unique_image_path = false

func get_check_button_image_path():
	
	var list = []
	if button_image_path_list.size() > 0:
		for b_i_p in button_image_path_list:
			if b_i_p.is_checked():
				list.append(b_i_p.image_path_list)

	return list


func load_paragraph_container():
	
	if position_on_list == -1:
		$VBoxContainer/MarginContainer/Label.hide()
	else:
		if position_on_list > 0:
			$VBoxContainer/ButtonAdd.show()

		$VBoxContainer/MarginContainer/Label.text = paragraph.text
		if $VBoxContainer/MarginContainer/Label.text.rsplit("\n\n", false, 1).size() > 1:
			$VBoxContainer/ButtonSplit.show()
	
	reload_buttons()

	
func reload_buttons():
	
	button_image_path_list = []
	
	for n in $VBoxContainer/FlowContainer.get_children():
		n.queue_free()
	
	if paragraph.image_path_list.size() > 0:

		var i = 0
		
		for i_p in paragraph.image_path_list:
		
			var b_i_p = original_button_image_path.instantiate()
			b_i_p.position_on_list = i
			b_i_p.image_path_list.append_array(i_p)
			
			b_i_p.load_button_image_path()
			
			button_image_path_list.append(b_i_p)
		
			$VBoxContainer/FlowContainer.add_child(b_i_p)
			
			b_i_p.check_button()

			i = i + 1
	
	button_generate_image = original_button_generate_image.instantiate()
	
	$VBoxContainer/FlowContainer.add_child(button_generate_image)


func uncheck_all_button_images():
	for b_i_p in button_image_path_list:
		b_i_p.uncheck()


func _on_button_add_button_down():
	MainManager.mm.add_paragraph(position_on_list)


func _on_button_split_button_down():
	MainManager.mm.split_paragraph(position_on_list)
	

func request_image():
	
	button_generate_image.disable()
	
	MainManager.mm.request_image(position_on_list, 0, paragraph.text, false, -1)
