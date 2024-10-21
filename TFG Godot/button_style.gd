@tool
extends Button

@export var texture: Texture:
	set(new_texture):
		texture = new_texture
		set_texture()

@export var check_box: CheckBox

@export var title: String:
	set(new_title):
		title = new_title
		set_title()

@export var positive_prompt: String
@export var negative_prompt: String


func _ready():
	set_title()
	set_texture()


func set_texture():
	if is_inside_tree():
		$VBoxContainer/TextureRect.texture = texture


func set_title():
	if is_inside_tree():
		$PanelContainer/MarginContainer/Label.text = title

		
func check_button():
	if check_box.button_pressed == true:
		check_box.button_pressed = false
		
		if $"../../../..".get_check_style() == null:
			$"../../../..".button_style_list[0].check_box.button_pressed = true
	else:
		$"../../../..".uncheck_all_button_style()
		check_box.button_pressed = true


func uncheck():
	check_box.button_pressed = false


func is_checked():
	return check_box.button_pressed


func _on_button_down():
	check_button()
