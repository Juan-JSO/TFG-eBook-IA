extends Control

class_name MainManager

static var mm: MainManager

@export var pc_kobold_cpp_settings: Node
@export var pc_comfy_ui_settings: Node
@export var pc_ebook_settings: Node

@export var container_text_generation: Node
@export var container_ebook_generation: Node

@export var image_display: Node

@export var panel_cover_paragraph: Node
@export var panel_paragraph: Node

@export var panel_styles: Node
	
var generated_text_id: int = 0
var generated_images_id: int = 0
var generated_videos_id: int = 0

var original_paragraph_container = preload("res://paragraph_container.tscn")

var paragraph_requests = []
	
var processing_request = false

var cover_paragraph_data = null
var cover_paragraph_container = null

var paragraph_data_list = []
var paragraph_container_list = []

var instruct_dict = {
	"user_message_prefix": "<|start_header_id|>user<|end_header_id|>",
	"user_message_suffix": "<|eot_id|>",
	"assistant_message_prefix": "<|start_header_id|>assistant<|end_header_id|>",
	"assistant_message_suffix": "<|eot_id|>",
	"system_message_prefix": "<|start_header_id|>system<|end_header_id|>",
	"system_message_suffix": "<|eot_id|>",
	"stop_sequence": "</s>",
}

func _process(delta):
	pass

func _ready():
	
	mm = get_node(".")
	
	load_data()
	
	get_kobold_cpp_settings()
	
	$VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/LabelKoboldCpp.text = "KoboldCpp: CONNECTING..."
	
	$Node/HTTPRequestKoboldCpp.request("http://127.0.0.1:5001/api/v1/model")
	
	$VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer2/LabelTFGApi.text = "TFGApi: CONNECTING..."
	
	$Node/HTTPRequestTFGApi.request("http://127.0.0.1:8000/")
	
	cover_paragraph_data = ParagraphData.new()
	
	reload_cover_paragraph()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_data()
		

func _on_http_request_kobold_cpp_request_completed(result, response_code, headers, body):
	
	if result == 0:
		var json = JSON.parse_string(body.get_string_from_utf8())
		$VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/LabelKoboldCpp.text = "KoboldCpp: CONNECTED (%s)" % [json["result"]]
	else:
		$VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/LabelKoboldCpp.text = "KoboldCpp: CONNECTION ERROR"


func _on_http_request_tfg_api_request_completed(result, response_code, headers, body):
	
	if result == 0:
		var json = JSON.parse_string(body.get_string_from_utf8())
		$VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer2/LabelTFGApi.text = "TFGApi: CONNECTED"
	else:
		$VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer2/LabelTFGApi.text = "TFGApi: CONNECTION ERROR"


func _on_button_kobold_cpp_button_down():
	
	$VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/LabelKoboldCpp.text = "KoboldCpp: CONNECTING..."
	
	$Node/HTTPRequestKoboldCpp.request("http://127.0.0.1:5001/api/v1/model")


func _on_button_tfg_api_button_down():
	
	$VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer2/LabelTFGApi.text = "TFGApi: CONNECTING..."
	
	$Node/HTTPRequestTFGApi.request("http://127.0.0.1:8000/")


func _on_http_request_story_request_completed(result, response_code, headers, body):
	
	if result == 0:
				
		var json = JSON.parse_string(body.get_string_from_utf8())
		var text_response = json["results"][0]["text"]
		
		if generating_story == true:
				
			if story_generation_step == 0:
				
				print("PRIMER PASO COMPLETADO")
				
				text_response = text_response.strip_edges(true, true)
				
				text_response_summary = text_response
				
				story_generation_step = 1
				
				text_response_story = instruct_dict["assistant_message_prefix"] + "\n\n" + assistant_name + ": ###chapter%s: " % story_generation_step
				
				story_generation_step_1()
				
			else:
				
				story_generation_step = story_generation_step + 1
					
				text_response_story = text_response_story + text_response
				
				if story_generation_step <= text_gen_chapters:
					
					print("SEGUNDO PASO COMPLETADO: %s" % story_generation_step)
					
					text_response_story = text_response_story + instruct_dict["assistant_message_suffix"] + instruct_dict["assistant_message_prefix"] + "\n\n" + assistant_name + ": ###chapter%s: " % story_generation_step
					
					story_generation_step_1()
					
				else:
					
					print("TERCER PASO COMPLETADO")
					
					text_response_story = text_response_story.replace("<|start_header_id|>assistant<|end_header_id|>\n\n", "")
					
					text_response_story = text_response_story.replace("<|eot_id|>", "")
					
					text_response_story = text_response_story.replace("Writing Machine: ", "\n\n")
					
					text_response_story = text_response_story.strip_edges(true, true)
					
					generating_story = false

					container_text_generation.get_node("TextEditStory").text = text_response_story
	
					container_text_generation.get_node("ButtonGenerateStory").text = "Generate Story"
					container_text_generation.get_node("ButtonGenerateStory").disabled = false
					
					container_text_generation.get_node("ButtonContinueStory").text = "Continue Story"
					container_text_generation.get_node("ButtonContinueStory").disabled = false
					
					container_ebook_generation.get_node("HBoxContainer/ButtonGenerateTitle").text = "Generate Title"
					container_ebook_generation.get_node("HBoxContainer/ButtonGenerateTitle").disabled = false
		else:
			container_text_generation.get_node("TextEditStory").text = container_text_generation.get_node("TextEditStory").text + text_response

			container_text_generation.get_node("ButtonGenerateStory").text = "Generate Story"
			container_text_generation.get_node("ButtonGenerateStory").disabled = false
			
			container_text_generation.get_node("ButtonContinueStory").text = "Continue Story"
			container_text_generation.get_node("ButtonContinueStory").disabled = false
			
			container_ebook_generation.get_node("HBoxContainer/ButtonGenerateTitle").text = "Generate Title"
			container_ebook_generation.get_node("HBoxContainer/ButtonGenerateTitle").disabled = false
			
	else:
		$AcceptDialog.dialog_text = "ERROR GENERATING STORY"
		$AcceptDialog.show()
	
		container_text_generation.get_node("ButtonGenerateStory").text = "Generate Story"
		container_text_generation.get_node("ButtonGenerateStory").disabled = false
		
		container_text_generation.get_node("ButtonContinueStory").text = "Continue Story"
		container_text_generation.get_node("ButtonContinueStory").disabled = false
		
		container_ebook_generation.get_node("HBoxContainer/ButtonGenerateTitle").text = "Generate Title"
		container_ebook_generation.get_node("HBoxContainer/ButtonGenerateTitle").disabled = false


func _on_http_request_title_request_completed(result, response_code, headers, body):
	
	if result == 0:
		var json = JSON.parse_string(body.get_string_from_utf8())
		print(json["results"][0]["text"])
		var text_response = json["results"][0]["text"].strip_edges(true, true)
		
		text_response = text_response.replace('"', '')

		container_ebook_generation.get_node("HBoxContainer/LineEdit").text = text_response
	else:
		$AcceptDialog.dialog_text = "ERROR GENERATING TITLE"
		$AcceptDialog.show()
	
	
	container_text_generation.get_node("ButtonGenerateStory").text = "Generate Story"
	container_text_generation.get_node("ButtonGenerateStory").disabled = false
	
	container_text_generation.get_node("ButtonContinueStory").text = "Continue Story"
	container_text_generation.get_node("ButtonContinueStory").disabled = false
	
	container_ebook_generation.get_node("HBoxContainer/ButtonGenerateTitle").text = "Generate Title"
	container_ebook_generation.get_node("HBoxContainer/ButtonGenerateTitle").disabled = false


func _on_http_request_comfy_ui_request_completed(result, response_code, headers, body):
	
	var i = 0
	
	if result == 0:
		var json = JSON.parse_string(body.get_string_from_utf8())
		
		i = paragraph_requests[0]["request_id"]
		
		if i == -1:
			
			cover_paragraph_container.paragraph.image_path_list.append(json["image_path_list"])
			
		else:
		
			while i > -1:
				
				if i < paragraph_container_list.size():
				
					paragraph_container_list[i].paragraph.image_path_list.append(json["image_path_list"])
					
					break
				
				i = i - 1
		
	else:
		$AcceptDialog.dialog_text = "ERROR GENERATING IMAGES"
		$AcceptDialog.show()
		
	if i == -1:
		
		cover_paragraph_container.reload_buttons()
	
	if i > -1:
		
		paragraph_container_list[i].reload_buttons()
	
	paragraph_requests.remove_at(0)

	if paragraph_requests.size() > 0:
		process_request()
	else:
		processing_request = false
		

func _on_http_request_ebook_request_completed(result, response_code, headers, body):
	
	container_ebook_generation.get_node("ButtonGenerateEbook").text = "Generate Ebook"
	container_ebook_generation.get_node("ButtonGenerateEbook").disabled = false
	
	if result == 0:
		
		$AcceptDialog.dialog_text = "Ebook generated!"
		$AcceptDialog.show()
		
	else:
		
		$AcceptDialog.dialog_text = "ERROR GENERATING EBOOK"
		$AcceptDialog.show()


func _on_http_request_generate_prompt_request_completed(result, response_code, headers, body):
	
	if result == 0:
		var json = JSON.parse_string(body.get_string_from_utf8())
		print(json["results"][0]["text"])
		var text_response = json["results"][0]["text"].strip_edges(true, true).replace("[", "").replace("]", "")
		
		text_response.replace('"', '').replace("[", "").replace("]", "")
		
		paragraph_requests[0]["positive_prompt"] = text_response
		
		var new_responses = text_response.replace("Prompt Machine: ", "").strip_edges(true, true).split("###prompt")
		
		if new_responses.size() > 1:

			for i in new_responses.size():
				if i == 0:
					paragraph_requests[0]["positive_prompt"] = new_responses[i].strip_edges(true, true)
				else:
					if new_responses[i].rsplit(":", false, 1).size() > 1:
						new_responses[i] = new_responses[i].split(":", false, 1)[1].strip_edges(true, true)
					request_image(paragraph_requests[0]["request_id"], 0, new_responses[i].strip_edges(true, true), true, i)
	
	else:
		$AcceptDialog.dialog_text = "ERROR GENERATING PROMPT"
		$AcceptDialog.show()
		
	generate_image()
	
var type = 0
var image_path = ""
var paragraph_id = -1

func show_image(new_texture, new_type, new_image_path, new_paragraph_id):
	
	image_display.get_node("MarginContainer/TextureRect").texture = new_texture
	
	type = new_type
	image_path = new_image_path
	paragraph_id = new_paragraph_id
	
	if type == 0 and paragraph_id != -1:
		$VBoxContainer/ContainerMain/Control/ImageDisplay/VBoxContainer/ButtonAnimate.text = ">"
		$VBoxContainer/ContainerMain/Control/ImageDisplay/VBoxContainer/ButtonAnimate.show()
	else:
		$VBoxContainer/ContainerMain/Control/ImageDisplay/VBoxContainer/ButtonAnimate.hide()
	
	image_display.show()
	

func reload_cover_paragraph():
	
	for n in panel_cover_paragraph.get_node("MarginContainer").get_children():
		n.queue_free()
		
	var p_c = original_paragraph_container.instantiate()
	p_c.position_on_list = -1
	p_c.paragraph = cover_paragraph_data
	p_c.unique_image_path = true
	
	p_c.load_paragraph_container()
	
	cover_paragraph_container = p_c

	panel_cover_paragraph.get_node("MarginContainer").add_child(p_c)

	
func reload_paragraphs():
	
	paragraph_container_list = []
	
	for n in panel_paragraph.get_node("ScrollContainer/MarginContainer/VBoxContainer").get_children():
		n.queue_free()
	
	if paragraph_data_list.size() > 0:

		var i = 0
		
		for p_d in paragraph_data_list:
		
			var p_c = original_paragraph_container.instantiate()
			p_c.position_on_list = i
			p_c.paragraph = p_d
			
			p_c.load_paragraph_container()
			
			paragraph_container_list.append(p_c)
		
			panel_paragraph.get_node("ScrollContainer/MarginContainer/VBoxContainer").add_child(p_c)

			i = i + 1
	
	
func add_paragraph(position):
	
	if position > 0:
		paragraph_data_list[position - 1].text = paragraph_data_list[position - 1].text + "\n\n" + paragraph_data_list[position].text
		paragraph_data_list[position - 1].image_path_list.append_array(paragraph_data_list[position].image_path_list)
		paragraph_data_list.remove_at(position)
		reload_paragraphs()


func split_paragraph(position):
	
	var aux_text_list = paragraph_data_list[position].text.rsplit("\n\n", false, 1)
	if aux_text_list.size() > 1:
		paragraph_data_list[position].text = aux_text_list[0]
		paragraph_data_list.insert(position + 1, ParagraphData.new(aux_text_list[1]))
		reload_paragraphs()


func save_data():
	
	var save_dict = {
		"generated_text_id": generated_text_id,
		"generated_images_id": generated_images_id,
		"generated_videos_id": generated_videos_id,
	}
	
	var save_file = FileAccess.open("user://data.save", FileAccess.WRITE)
	
	var json_string = JSON.stringify(save_dict)

	save_file.store_line(json_string)

func load_data():
	if not FileAccess.file_exists("user://data.save"):
		return
		
	var data = {}
		
	var save_file = FileAccess.open("user://data.save", FileAccess.READ)
	while save_file.get_position() < save_file.get_length():
		var json_string = save_file.get_line()

		var json = JSON.new()

		var parse_result = json.parse(json_string)
		if not parse_result == OK:
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
			continue

		data = json.get_data()
		
	generated_text_id = data["generated_text_id"]
	generated_images_id = data["generated_images_id"]
	generated_videos_id = data["generated_videos_id"]


func request_image(request_id, request_type, text, skip_generate_prompt, insert_at):
	
	var data_to_send = get_comfy_ui_settings()
	
	data_to_send["request_id"] = request_id
	data_to_send["request_type"] = request_type
	
	if request_type != 1 and data_to_send["positive_prompt"] != "":
	
		data_to_send["positive_prompt"] = text + ", " + data_to_send["positive_prompt"]
	
	else:
		
		data_to_send["positive_prompt"] = text
		
	data_to_send["skip_generate_prompt"] = skip_generate_prompt
	
	if data_to_send["request_id"] == -1:
		data_to_send["width"] = pc_ebook_settings.get_node("MarginContainer/VBoxContainer/HBoxContainer9/SpinBox4").value
		data_to_send["height"] = pc_ebook_settings.get_node("MarginContainer/VBoxContainer/HBoxContainer9/SpinBox5").value
		
	if insert_at == -1:

		paragraph_requests.append(data_to_send)
	
	else:

		paragraph_requests.insert(insert_at, data_to_send)
	
	if !processing_request:
		process_request()
		
		
func get_kobold_cpp_settings():
	
	user_name = pc_kobold_cpp_settings.get_node("MarginContainer/VBoxContainer/HBoxContainer5/LineEdit").text
	assistant_name = pc_kobold_cpp_settings.get_node("MarginContainer/VBoxContainer/HBoxContainer4/LineEdit").text
		
	var settings = {
		"prompt": "",
		"max_length": 1024,
		"max_context_length": 8192,
		"temperature": 0.7,
		"top_p": 0.9,
		"typical_p": 1,
		"typical": 1,
		"sampler_seed": -1,
		"min_p": 0,
		"repetition_penalty": 1.1,
		"frequency_penalty": 0,
		"presence_penalty": 0,
		"top_k": 0,
		"min_tokens": 0,
		"length_penalty": 1,
		"early_stopping": false,
		"add_bos_token": true,
		"smoothing_factor": 0,
		"smoothing_curve": 1,
		"max_tokens_second": 0,
		"stop_sequence": [user_name + ":", assistant_name + ":", instruct_dict["user_message_prefix"], instruct_dict["assistant_message_prefix"], instruct_dict["system_message_prefix"], instruct_dict["stop_sequence"]],
		"truncation_length": 8192,
		"ban_eos_token": false,
		"skip_special_tokens": true,
		"top_a": 0, "tfs": 1,
		"mirostat_mode": 0,
		"mirostat_tau": 5,
		"mirostat_eta": 0.1,
		"custom_token_bans": "",
		"banned_strings": [],
		"sampler_order": [6, 0, 1, 3, 4, 2, 5],
		"grammar": "", "rep_pen": 1.1,
		"rep_pen_range": 0,
		"repetition_penalty_range": 0,
		"seed": -1,
		"guidance_scale": 1,
		"negative_prompt": "",
		"grammar_string": "",
		"repeat_penalty": 1.1,
		"tfs_z": 1,
		"repeat_last_n": 0,
		"n_predict": 1024,
		"mirostat": 0,
		"ignore_eos": false,
	}
	
	return settings
	

func get_comfy_ui_settings():
	
	var settings = {
		"request_id": 0,
		"request_type": 0,
		"model": get_comfy_ui_settings_image_video(),
		"seed": randi() if pc_comfy_ui_settings.get_node("MarginContainer/VBoxContainer/HBoxContainer/SpinBox").value == -1 else pc_comfy_ui_settings.get_node("MarginContainer/VBoxContainer/HBoxContainer/SpinBox").value,
		"steps": pc_comfy_ui_settings.get_node("MarginContainer/VBoxContainer/HBoxContainer2/SpinBox2").value,
		"cfg": pc_comfy_ui_settings.get_node("MarginContainer/VBoxContainer/HBoxContainer3/SpinBox3").value,
		"sampler_name": pc_comfy_ui_settings.get_node("MarginContainer/VBoxContainer/HBoxContainer4/OptionButton").get_item_text(pc_comfy_ui_settings.get_node("MarginContainer/VBoxContainer/HBoxContainer4/OptionButton").selected),
		"positive_prompt":pc_comfy_ui_settings.get_node("MarginContainer/VBoxContainer/VBoxContainer/TextEdit2").text,
		"negative_prompt": pc_comfy_ui_settings.get_node("MarginContainer/VBoxContainer/VBoxContainer2/TextEdit3").text,
		"width": pc_comfy_ui_settings.get_node("MarginContainer/VBoxContainer/HBoxContainer7/SpinBox4").value,
		"height": pc_comfy_ui_settings.get_node("MarginContainer/VBoxContainer/HBoxContainer7/SpinBox5").value,
		"folder_destination" : "",
	}
	
	return settings


func get_ebook_settings():

	var settings = {
		"book_id": "id" + str(generated_text_id),
		"title": container_ebook_generation.get_node("HBoxContainer/LineEdit").text,
		"language": "en",
		"author": pc_ebook_settings.get_node("MarginContainer/VBoxContainer/HBoxContainer5/LineEdit").text,
		"cover": "",
		"paragraph": null,
		"folder_destination_ebooks" : "",
		"folder_destination_images" : "",
	}
		
	return settings
	

func process_request():
	
	processing_request = true
	
	if paragraph_requests[0]["skip_generate_prompt"] == false:
	
		generate_prompt()
	
	else:
		
		generate_image()
	
func generate_prompt():
	
	var prompt = ""
	
	var n_prompts = 1
	
	var stop = [user_name + ":", assistant_name + ":", instruct_dict["user_message_prefix"], instruct_dict["assistant_message_prefix"], instruct_dict["system_message_prefix"], instruct_dict["stop_sequence"]]
	
	if paragraph_requests[0]["request_id"] == -1:
		
		prompt = 'You are a prompt machine capable of writing any prompt to generate images with AI. A prompt is a visual description, not a story, it should not narrate events.\nWrite a prompt for an image that will serve as the cover for the next story. Do not use any proper names, use generic words. Do not include anything that could be a spoiler, in other words, referring to the end of the story. Just write the prompt directly, do not include the command like "Generate an image" or "Make an image". In the image appears the text "{{title}}". If a character or creature from the character list appears in the image, use its corresponding physical description to represent it. LIMIT YOURSELF TO A VISUAL DESCRIPTION, NEVER WRITE A STORY OR ANY NARRATIVE TEXT.\nRespond only with a prompt strictly following the format:'
		
		stop = [user_name + ":", assistant_name + ":", instruct_dict["user_message_prefix"], instruct_dict["assistant_message_prefix"], instruct_dict["system_message_prefix"], instruct_dict["stop_sequence"], "###"]
		
	else:
	
		prompt = 'You are a prompt machine capable of writing any prompt to generate images with AI. A prompt is a visual description, not a story, it should not narrate events.\nWrite {{n_prompts}} long and detailed prompts that will serve to illustrate this scene of the story, these should illustrate important moments in detail and be visually striking. Characters and creatures should have a detailed description of their visual appearance and be common across all prompts. Just write the prompt directly, do not include the command like "Generate an image" or "Make an image". If a character or creature from the character list appears in the image, use its corresponding physical description to represent it. Each prompt must be detailed individually, no matter if the information is repeated between them. LIMIT YOURSELF TO A VISUAL DESCRIPTION, NEVER WRITE A STORY OR ANY NARRATIVE TEXT.\nRespond only with {{n_prompts}} prompts strictly following the format:'
		
		n_prompts = pc_ebook_settings.get_node("MarginContainer/VBoxContainer/HBoxContainer3/SpinBox").value
		
		prompt = prompt.replace("{{n_prompts}}", str(n_prompts))
		
	var format = "\n"
	
	for n in n_prompts:
		format = format + "\n###prompt%s: [PROMPT_%s]" % [n + 1, n + 1]
		
	prompt = instruct_dict["system_message_prefix"] + "\n\n" + prompt + format + instruct_dict["system_message_suffix"] + instruct_dict["user_message_prefix"] + "\n\n" + user_name + ": [Title: {{title}}]\n\n[Story: {{story}}]\n\n[Genre:{{genre}}]\n\n" + text_response_characters + "\n\nLIMIT YOURSELF TO A VISUAL DESCRIPTION, NEVER WRITE A STORY OR ANY NARRATIVE TEXT" + instruct_dict["user_message_suffix"] + instruct_dict["assistant_message_prefix"] + "\n\n" + "Prompt Machine" + ": ###prompt1:"	
	
	prompt = prompt.replace("{{idea}}", container_text_generation.get_node("TextEditIdea").text)
	prompt = prompt.replace("{{genre}}", container_text_generation.get_node("TextEditGenre").text)
	
	if paragraph_requests[0]["request_id"] == -1:
		prompt = prompt.replace("{{story}}", container_text_generation.get_node("TextEditStory").text)
	else:
		prompt = prompt.replace("{{story}}", container_text_generation.get_node("TextEditStory").text + "]\n\n[Scene: " + paragraph_requests[0]["positive_prompt"])
		
	prompt = prompt.replace("{{title}}", container_ebook_generation.get_node("HBoxContainer/LineEdit").text)
	prompt = prompt.replace("###chapter", "Chapter ").replace("#CHARACTERS", "List of characters:").replace("###character", "Character ")
	
	var data_to_send_text = get_kobold_cpp_settings()
	
	data_to_send_text["prompt"] = prompt
	data_to_send_text["max_length"] = pc_kobold_cpp_settings.get_node("MarginContainer/VBoxContainer/HBoxContainer6/SpinBox").value
	data_to_send_text["stop_sequence"] = stop

	var url = "http://127.0.0.1:5001/api/v1/generate"
	var headers = ["Content-Type: application/json"]
	var json = JSON.stringify(data_to_send_text)
	
	$Node/HTTPRequestGeneratePrompt.request(url, headers, HTTPClient.METHOD_POST, json)

	
func generate_image():

	var base_dir = "res://" if OS.has_feature("editor") else OS.get_executable_path().get_base_dir()
	
	var dir = DirAccess.open(ProjectSettings.globalize_path(base_dir))
	if !dir.dir_exists("images"):
		dir.make_dir("images")
	
	var dir_images = DirAccess.open(ProjectSettings.globalize_path(base_dir).path_join("images"))
	if !dir_images.dir_exists("%s" % generated_text_id):
		dir_images.make_dir("%s" % generated_text_id)
		
	
	var data_to_send = paragraph_requests[0]
	
	var style = panel_styles.get_check_style()
	
	if style["positive_prompt"] != "" and data_to_send["request_type"] != 1:
		
		
	
		data_to_send["positive_prompt"] = data_to_send["positive_prompt"].strip_edges(true, true) + ", " + style["positive_prompt"]
		data_to_send["negative_prompt"] = data_to_send["negative_prompt"].strip_edges(true, true) + ", " + style["negative_prompt"]
	
	data_to_send["folder_destination"] = ProjectSettings.globalize_path(base_dir).path_join("images").path_join(str(generated_text_id))
	
	generated_images_id = generated_images_id + 1
	
	print("-------------------------")
	print(data_to_send["positive_prompt"])

	var url = "http://127.0.0.1:8000/comfy_ui/generate_image"
	var headers = ["Content-Type: application/json"]
	var json = JSON.stringify(data_to_send)
 
	$Node/HTTPRequestComfyUI.request(url, headers, HTTPClient.METHOD_POST, json)


func get_comfy_ui_settings_image_video():
	return pc_comfy_ui_settings.get_node("MarginContainer/VBoxContainer/HBoxContainer8/OptionButton").selected


func _on_button_kobold_cpp_settings_button_down():
	if pc_kobold_cpp_settings.visible:
		pc_kobold_cpp_settings.hide()
	else:
		pc_kobold_cpp_settings.show()
		

func _on_button_comfy_ui_settings_button_down():
	if pc_comfy_ui_settings.visible:
		pc_comfy_ui_settings.hide()
	else:
		pc_comfy_ui_settings.show()


func _on_button_ebook_settings_button_down():
	if pc_ebook_settings.visible:
		pc_ebook_settings.hide()
	else:
		pc_ebook_settings.show()


func _on_button_close_0_button_down():
	if image_display.visible:
		image_display.hide()
	else:
		image_display.show()


func _on_button_close_1_button_down():
	if pc_kobold_cpp_settings.visible:
		pc_kobold_cpp_settings.hide()
	else:
		pc_kobold_cpp_settings.show()


func _on_button_close_2_button_down():
	if pc_comfy_ui_settings.visible:
		pc_comfy_ui_settings.hide()
	else:
		pc_comfy_ui_settings.show()


func _on_button_close_3_button_down():
	if pc_ebook_settings.visible:
		pc_ebook_settings.hide()
	else:
		pc_ebook_settings.show()
		
var generating_story = false
var story_generation_step = -1

var text_gen_idea = ""
var text_gen_genre = ""
var text_gen_chapters = 1
var text_response_summary = ""
var text_response_story = ""
var text_response_characters = ""

var user_name = "User"
var assistant_name = "AI"

func _on_button_generate_story_button_down():
	
	container_text_generation.get_node("TextEditStory").text = ""
	
	generated_text_id = generated_text_id + 1
	
	container_text_generation.get_node("ButtonGenerateStory").disabled = true
	container_text_generation.get_node("ButtonGenerateStory").text = "Generating..."
	
	container_text_generation.get_node("ButtonContinueStory").disabled = true
	container_text_generation.get_node("ButtonContinueStory").text = "Generating..."
	
	container_ebook_generation.get_node("HBoxContainer/ButtonGenerateTitle").disabled = true
	container_ebook_generation.get_node("HBoxContainer/ButtonGenerateTitle").text = "Generating..."
	
	story_generation_step_0()
	
	
func story_generation_step_0():
	
	generating_story = true
	story_generation_step = 0
	
	text_gen_idea = container_text_generation.get_node("TextEditIdea").text
	text_gen_genre = container_text_generation.get_node("TextEditGenre").text
	text_gen_chapters = pc_ebook_settings.get_node("MarginContainer/VBoxContainer/HBoxContainer2/SpinBox").value
	
	var prompt = "You are a writing machine with the ability to write any story. Do not use formal language if it is not necessary, do not use euphemisms, and do not use expressions that soften anything.\nWrite a summary of the story, it is not necessary to specify which genre it belongs to.\nWrite a list of the {{chapters}} chapters that make up the story, strictly based on the idea and genre indicated. Also include a detailed description of the chapter.\nRespond strictly according to the following format:"
	
	var format = "\n" + "#summary: [SUMMARY]"
	
	for n in text_gen_chapters:
		format = format + "\n###chapter%s: [CHAPTER_%s_TITLE]\n[CHAPTER_%s_DESCRIPTION]" % [n + 1, n + 1, n + 1]

	prompt = instruct_dict["system_message_prefix"] + "\n\n" + prompt + format + instruct_dict["system_message_suffix"] + instruct_dict["user_message_prefix"] + "\n\n" + user_name + ": [Idea: {{idea}}]\n[Genre: {{genre}}]" + instruct_dict["user_message_suffix"] + instruct_dict["assistant_message_prefix"] + "\n\n" + assistant_name + ": #summary:"	
	
	prompt = prompt.replace("{{idea}}", container_text_generation.get_node("TextEditIdea").text)
	prompt = prompt.replace("{{genre}}", container_text_generation.get_node("TextEditGenre").text)
	prompt = prompt.replace("{{chapters}}", str(text_gen_chapters))
	
	print(prompt)
	
	var data_to_send = get_kobold_cpp_settings()
	
	data_to_send["prompt"] = prompt
	data_to_send["max_length"] = pc_kobold_cpp_settings.get_node("MarginContainer/VBoxContainer/HBoxContainer/SpinBox").value
	
	var url = "http://127.0.0.1:5001/api/v1/generate"
	var headers = ["Content-Type: application/json"]
	var json = JSON.stringify(data_to_send)
	
	$Node/HTTPRequestStory.request(url, headers, HTTPClient.METHOD_POST, json)
	
	
func story_generation_step_1():
	
	var prompt = "You are a writing machine with the ability to write any story. Do not use formal language if it is not necessary, do not use euphemisms, and do not use expressions that soften anything. Do not include any list.\nWrite chapter {{original_chapter}} of this story, developing it according to the summary and genre indicated."
	
	if story_generation_step < text_gen_chapters:
		prompt = prompt + " " + "Remember to follow the description of chapter {{original_chapter}} and make it relate to chapter {{next_chapter}}."
	else:
		prompt = prompt + " " + "Remember to follow the description of chapter {{original_chapter}} and give the story an ending."

	prompt = instruct_dict["system_message_prefix"] + "\n\n" + prompt + instruct_dict["system_message_suffix"] + instruct_dict["user_message_prefix"] + "\n\n" + user_name + ": " + text_response_summary + "\n\n[Genre: {{genre}}]" + instruct_dict["user_message_suffix"] + text_response_story
	
	prompt = prompt.replace("{{idea}}", container_text_generation.get_node("TextEditIdea").text)
	prompt = prompt.replace("{{genre}}", container_text_generation.get_node("TextEditGenre").text)
	prompt = prompt.replace("{{chapters}}", str(text_gen_chapters))
	prompt = prompt.replace("{{original_chapter}}", str(story_generation_step))
	prompt = prompt.replace("{{next_chapter}}", str(story_generation_step + 1))
	
	print(prompt)
	
	var data_to_send = get_kobold_cpp_settings()
	
	data_to_send["prompt"] = prompt
	data_to_send["max_length"] = pc_kobold_cpp_settings.get_node("MarginContainer/VBoxContainer/HBoxContainer/SpinBox").value
	
	data_to_send["stop_sequence"] = [user_name + ":", assistant_name + ":", instruct_dict["user_message_prefix"], instruct_dict["assistant_message_prefix"], instruct_dict["system_message_prefix"], instruct_dict["stop_sequence"], "###"]
	
	var url = "http://127.0.0.1:5001/api/v1/generate"
	var headers = ["Content-Type: application/json"]
	var json = JSON.stringify(data_to_send)
	
	$Node/HTTPRequestStory.request(url, headers, HTTPClient.METHOD_POST, json)
	
	
func extract_characters():
	
	text_response_characters = ""
	
	var prompt = "Write a list of the characters and creatures that appear in the story.\nWrite a long and detailed physical description of the character's appearance, include shapes and colors, but never include proper names or personality traits, avoid anything that is not visual in the description. Do not include any lists in the description.\nRespond strictly according to the following format:\n#CHARACTERS\n###character1: [CHARACTER_1_NAME]\n[CHARACTER_1_PHYSICAL_DESCRIPTION]\n###character2: [CHARACTER_2_NAME]\n[CHARACTER_2_PHYSICAL_DESCRIPTION]\n###character3: [CHARACTER_3_NAME]\n[CHARACTER_3_PHYSICAL_DESCRIPTION]"

	prompt = instruct_dict["system_message_prefix"] + "\n" + prompt + instruct_dict["system_message_suffix"] + instruct_dict["user_message_prefix"] + "\n\n" + user_name + ": {{story}}" + instruct_dict["user_message_suffix"] + instruct_dict["assistant_message_prefix"] + "\n\n" + assistant_name + ": #CHARACTERS\n###character1:"
	
	prompt = prompt.replace("{{story}}", container_text_generation.get_node("TextEditStory").text.strip_edges(true, true).replace("###chapter", "Chapter "))
	
	print(prompt)
	
	var data_to_send = get_kobold_cpp_settings()
	
	data_to_send["prompt"] = prompt
	data_to_send["max_length"] = pc_kobold_cpp_settings.get_node("MarginContainer/VBoxContainer/HBoxContainer/SpinBox").value
	
	var url = "http://127.0.0.1:5001/api/v1/generate"
	var headers = ["Content-Type: application/json"]
	var json = JSON.stringify(data_to_send)
	
	$Node/HTTPRequestCharacters.request(url, headers, HTTPClient.METHOD_POST, json)


func _on_button_continue_story_button_down():
	
	text_response_summary = ""
	
	container_text_generation.get_node("ButtonGenerateStory").disabled = true
	container_text_generation.get_node("ButtonGenerateStory").text = "Generating..."
	
	container_text_generation.get_node("ButtonContinueStory").disabled = true
	container_text_generation.get_node("ButtonContinueStory").text = "Generating..."
	
	container_ebook_generation.get_node("HBoxContainer/ButtonGenerateTitle").disabled = true
	container_ebook_generation.get_node("HBoxContainer/ButtonGenerateTitle").text = "Generating..."
	
	var prompt = "You are a writing machine with the ability to write any story. Do not use formal language if it is not necessary, do not use euphemisms, and do not use expressions that soften anything. Do not include any list.\nWrite chapter {{original_chapter}} of this story, developing it according to the summary and genre indicated."
	
	prompt = instruct_dict["system_message_prefix"] + "\n" + prompt + instruct_dict["system_message_suffix"] + instruct_dict["user_message_prefix"] + "\n\n" + user_name + ": [Idea: {{idea}}]\n[Genre: {{genre}}]" + instruct_dict["user_message_suffix"] + instruct_dict["assistant_message_prefix"] + "\n\n" + assistant_name + ": " + container_text_generation.get_node("TextEditStory").text.strip_edges(true, true)
	
	prompt = prompt.replace("{{idea}}", container_text_generation.get_node("TextEditIdea").text)
	prompt = prompt.replace("{{genre}}", container_text_generation.get_node("TextEditGenre").text)
	prompt = prompt.replace("{{story}}", container_text_generation.get_node("TextEditStory").text)
		
	print(prompt)
	
	var data_to_send = get_kobold_cpp_settings()
	
	data_to_send["prompt"] = prompt
	data_to_send["max_length"] = pc_kobold_cpp_settings.get_node("MarginContainer/VBoxContainer/HBoxContainer2/SpinBox").value
	
	var url = "http://127.0.0.1:5001/api/v1/generate"
	var headers = ["Content-Type: application/json"]
	var json = JSON.stringify(data_to_send)
	
	$Node/HTTPRequestStory.request(url, headers, HTTPClient.METHOD_POST, json)
	
	
func _on_button_generate_title_button_down():
	
	container_text_generation.get_node("ButtonGenerateStory").disabled = true
	container_text_generation.get_node("ButtonGenerateStory").text = "Generating..."
	
	container_text_generation.get_node("ButtonContinueStory").disabled = true
	container_text_generation.get_node("ButtonContinueStory").text = "Generating..."
	
	container_ebook_generation.get_node("HBoxContainer/ButtonGenerateTitle").disabled = true
	container_ebook_generation.get_node("HBoxContainer/ButtonGenerateTitle").text = "Generating..."
	
	var prompt = "You are a writing machine with the ability to write anything. Write a title for the indicated story. Respond only with a single title in plain text.\n[Genre: {{genre}}]\n[Story: {{story}}]"
	
	prompt = prompt.replace("{{idea}}", container_text_generation.get_node("TextEditIdea").text)
	prompt = prompt.replace("{{genre}}", container_text_generation.get_node("TextEditGenre").text)
	prompt = prompt.replace("{{story}}", container_text_generation.get_node("TextEditStory").text)

	prompt = instruct_dict["system_message_prefix"] + "\n" + prompt + instruct_dict["system_message_suffix"] + instruct_dict["assistant_message_prefix"] + "\n" + assistant_name + ": Title: "
		
	print(prompt)
	
	var data_to_send = get_kobold_cpp_settings()
	
	data_to_send["prompt"] = prompt
	data_to_send["max_length"] = pc_kobold_cpp_settings.get_node("MarginContainer/VBoxContainer/HBoxContainer3/SpinBox").value
	
	var url = "http://127.0.0.1:5001/api/v1/generate"
	var headers = ["Content-Type: application/json"]
	var json = JSON.stringify(data_to_send)
	
	$Node/HTTPRequestTitle.request(url, headers, HTTPClient.METHOD_POST, json)


func _on_button_split_story_button_down():
	
	container_text_generation.get_node("ButtonSplitStory").disabled = true
	container_text_generation.get_node("ButtonSplitStory").text = "Generating..."
	
	extract_characters()


func _on_button_cover_button_down():
	if panel_cover_paragraph.visible:
		panel_cover_paragraph.hide()
	else:
		panel_cover_paragraph.show()


func _on_button_generate_images_button_down():
	
	generated_images_id = generated_images_id + 1
	
	cover_paragraph_container.request_image()
	
	for p_c in paragraph_container_list:
		p_c.request_image()
		
		
func _on_button_generate_ebook_button_down():
	
	if paragraph_data_list.size() > 0:
	
		container_ebook_generation.get_node("ButtonGenerateEbook").disabled = true
		container_ebook_generation.get_node("ButtonGenerateEbook").text = "Generating..."
			
		var data_to_send = get_ebook_settings()
		
		var cover_img_path = ""
		if cover_paragraph_container.get_check_button_image_path().size() > 0:
			cover_img_path = cover_paragraph_container.get_check_button_image_path()[0][0]
		
		var paragraph = []
		
		if text_response_summary != "":
			paragraph.append({"type": 0, "content": "Introduction"})
			paragraph.append({"type": 1, "content": text_response_summary.strip_edges(true, true).split("###")[0].strip_edges(true, true)})
		
		for p in paragraph_container_list:
			
			var content = p.paragraph.text
			
			if content.split("\n", false, 1).size() > 1:
				paragraph.append({"type": 0, "content": content.split("\n", true, 1)[0].replace("###chapter", "Chapter ")})
				content = content.split("\n", true, 1)[1].strip_edges(true, true)
			
			for c in content.split("\n\n", false):
				paragraph.append({"type": 1, "content": c})
			
			var image_path_list = p.get_check_button_image_path()
			
			if image_path_list.size() > 0:
				
				var final_list = []
				
				for img in image_path_list:
					if img.size() == 1:
						for i in 14:
							final_list.append(img[0])
					else:
						final_list.append_array(img)
						
					print(final_list)
					
				paragraph.append({"type": 2, "content": final_list})

		var base_dir = "res://" if OS.has_feature("editor") else OS.get_executable_path().get_base_dir()
		
		var dir = DirAccess.open(ProjectSettings.globalize_path(base_dir))
		if !dir.dir_exists("ebooks"):
			dir.make_dir("ebooks")
		
		data_to_send["cover"] = cover_img_path
		data_to_send["paragraph"] = paragraph
		data_to_send["folder_destination_ebooks"] = ProjectSettings.globalize_path(base_dir).path_join("ebooks")
		data_to_send["folder_destination_images"] = ProjectSettings.globalize_path(base_dir).path_join("images").path_join(str(generated_text_id))

		print(paragraph)

		var url = "http://127.0.0.1:8000/ebooklib/write_epub"
		var headers = ["Content-Type: application/json"]
		var json = JSON.stringify(data_to_send)
	 
		print("---------------------------------------------aaa")
		print(data_to_send)
	
		$Node/HTTPRequestEbook.request(url, headers, HTTPClient.METHOD_POST, json)


func _on_button_styles_button_down():
	if panel_styles.visible:
		panel_styles.hide()
	else:
		panel_styles.show()


func _on_button_animate_button_down():
	$VBoxContainer/ContainerMain/Control/ImageDisplay/VBoxContainer/ButtonAnimate.text = "..."
	print(image_path)
	#request_image(paragraph_id, 1, image_path.replace("/", "\\"), true, -1)
	request_image(paragraph_id, 1, image_path, true, -1)


func _on_http_request_characters_request_completed(result, response_code, headers, body):
	
	if result == 0:
		var json = JSON.parse_string(body.get_string_from_utf8())
		print(json["results"][0]["text"])
		var text_response = json["results"][0]["text"].strip_edges(true, true)
		
		text_response_characters = "#CHARACTERS\n###character1: " + text_response.replace('"', '').replace("[", "").replace("]", "")
	else:
		$AcceptDialog.dialog_text = "ERROR EXTRACTING CHARACTERS"
		$AcceptDialog.show()
	
	for n in panel_paragraph.get_node("ScrollContainer/MarginContainer/VBoxContainer").get_children():
		n.queue_free()
		
	paragraph_data_list = []
	
	var paragraph_list = container_text_generation.get_node("TextEditStory").text.strip_edges(true, true).split("###chapter", false)
	
	if paragraph_list.size() > 0:
		
		for p in paragraph_list:
			p = p.strip_edges(true, true)
			p = "###chapter" + p
		
			paragraph_data_list.append(ParagraphData.new(p))
	
	reload_paragraphs()
	
	container_text_generation.get_node("ButtonSplitStory").text = "Split Story"
	container_text_generation.get_node("ButtonSplitStory").disabled = false
