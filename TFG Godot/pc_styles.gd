extends PanelContainer

@export var button_style_list: Array[Node]

func uncheck_all_button_style():
	for b_s in button_style_list:
		b_s.uncheck()


func get_check_style():
	if button_style_list.size() > 0:
		for b_s in button_style_list:
			if b_s.is_checked():
				return {"positive_prompt": b_s.positive_prompt, "negative_prompt": b_s.negative_prompt}

	return null
