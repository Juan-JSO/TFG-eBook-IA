#This is an example that uses the websockets api to know when a prompt execution is done
#Once the prompt execution is done it downloads the images using the /history endpoint

import websocket #NOTE: websocket-client (https://github.com/websocket-client/websocket-client)
import uuid
import json
import urllib.request
import urllib.parse

server_address = "127.0.0.1:8188"
client_id = str(uuid.uuid4())

def queue_prompt(prompt):
    p = {"prompt": prompt, "client_id": client_id}
    data = json.dumps(p).encode('utf-8')
    req =  urllib.request.Request("http://{}/prompt".format(server_address), data=data)
    return json.loads(urllib.request.urlopen(req).read())

def get_image(filename, subfolder, folder_type):
    data = {"filename": filename, "subfolder": subfolder, "type": folder_type}
    url_values = urllib.parse.urlencode(data)
    with urllib.request.urlopen("http://{}/view?{}".format(server_address, url_values)) as response:
        return response.read()

def get_history(prompt_id):
    with urllib.request.urlopen("http://{}/history/{}".format(server_address, prompt_id)) as response:
        return json.loads(response.read())

def get_images(ws, prompt):
    prompt_id = queue_prompt(prompt)['prompt_id']
    output_images = {}
    while True:
        out = ws.recv()
        if isinstance(out, str):
            message = json.loads(out)
            if message['type'] == 'executing':
                data = message['data']
                if data['node'] is None and data['prompt_id'] == prompt_id:
                    break #Execution is done
        else:
            continue #previews are binary data

    history = get_history(prompt_id)[prompt_id]
    for o in history['outputs']:
        for node_id in history['outputs']:
            node_output = history['outputs'][node_id]
            if 'images' in node_output:
                images_output = []
                for image in node_output['images']:
                    image_data = get_image(image['filename'], image['subfolder'], image['type'])
                    images_output.append(image_data)
            output_images[node_id] = images_output

    return output_images


def generate_image_flux(request_id, request_type, model, seed, steps, cfg, sampler_name, positive_prompt, negative_prompt, width, height, folder_destination):

    filename = "workflow_image_flux_s_api.json"

    if model == True:
        filename = "workflow_image_flux_d_api.json"

    with open(filename, "r", encoding="utf-8") as f:
        workflow_json = f.read()

    prompt = json.loads(workflow_json)

    #seed
    prompt["31"]["inputs"]["seed"] = seed
    #steps
    prompt["31"]["inputs"]["steps"] = steps
    #sampler_name
    prompt["31"]["inputs"]["sampler_name"] = sampler_name
 
    #positive prompt
    prompt["6"]["inputs"]["text"] = positive_prompt

    #width
    prompt["27"]["inputs"]["width"] = width
    #height
    prompt["27"]["inputs"]["height"] = height

    ws = websocket.WebSocket()
    ws.connect("ws://{}/ws?clientId={}".format(server_address, client_id))
    images = get_images(ws, prompt)

    image_path_list = []

    i = 0
    for node_id in images:
        for image_data in images[node_id]:
            from PIL import Image
            import io
            image = Image.open(io.BytesIO(image_data))
            image.save(f"{folder_destination}/{request_id}-{request_type}-{seed}.png")

            image_path_list.append(f"{folder_destination}/{request_id}-{request_type}-{seed}.png")

            i += 1

    return image_path_list

def generate_video_sdv(request_id, request_type, seed, steps, cfg, sampler_name, positive_prompt, negative_prompt, width, height, folder_destination):

    with open("workflow_video_sdv_api.json", "r", encoding="utf-8") as f:
        workflow_json = f.read()

    prompt = json.loads(workflow_json)

    from PIL import Image
    with Image.open(positive_prompt) as image:
        width, height = image.size

    import base64
    # Convert the image to base64 format
    with open(positive_prompt, "rb") as f:
        encoded_image = base64.b64encode(f.read())
 
    #positive prompt
    prompt["25"]["inputs"]["image"] = encoded_image.decode("ascii")

    #width
    prompt["12"]["inputs"]["width"] = width
    #height
    prompt["12"]["inputs"]["height"] = height

    ws = websocket.WebSocket()
    ws.connect("ws://{}/ws?clientId={}".format(server_address, client_id))
    images = get_images(ws, prompt)

    image_path_list = []

    i = 0
    for node_id in images:
        for image_data in images[node_id]:
            from PIL import Image
            import io
            image = Image.open(io.BytesIO(image_data))
            image.save(f"{folder_destination}/{request_id}-{request_type}-{seed}-{i}.png")

            image_path_list.append(f"{folder_destination}/{request_id}-{request_type}-{seed}-{i}.png")

            i += 1

    return image_path_list