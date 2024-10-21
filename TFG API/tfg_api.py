from fastapi import FastAPI
import comfy_ui_api
import epub_writer

from pydantic import BaseModel

class ComfyUISettings(BaseModel):
    request_id: int | None = 0
    request_type: int | None = 0
    model: int | None = False
    seed: int | None = 0
    steps: int | None = 30
    cfg: float | None = 7
    sampler_name: str | None = 'euler_ancestral'
    positive_prompt: str | None = 'masterpiece, best quality, city'
    negative_prompt: str | None = ''
    width: int | None = 512
    height: int | None = 512
    folder_destination: str | None = './'

class Epub(BaseModel):
    book_id: str | None = 'id0000'
    title: str | None = 'Test Book'
    language: str | None = 'en'
    author: str | None = 'AI'
    cover: str | None = ''
    paragraph: list | None = []
    folder_destination_ebooks: str | None = './'
    folder_destination_images: str | None = './'

# http://127.0.0.1:8000
app = FastAPI()


@app.get("/")
async def root():
    return {"message": "TFG API Working"}

@app.post("/comfy_ui/generate_image")
async def generate_image(comfy_ui_settings: ComfyUISettings):

    if comfy_ui_settings.request_type == 1:

        image_path_list = comfy_ui_api.generate_video_sdv(comfy_ui_settings.request_id, comfy_ui_settings.request_type, comfy_ui_settings.seed, comfy_ui_settings.steps, comfy_ui_settings.cfg, comfy_ui_settings.sampler_name, comfy_ui_settings.positive_prompt, comfy_ui_settings.negative_prompt, comfy_ui_settings.width, comfy_ui_settings.height, comfy_ui_settings.folder_destination)

    else:

        image_path_list = comfy_ui_api.generate_image_flux(comfy_ui_settings.request_id, comfy_ui_settings.request_type, comfy_ui_settings.model, comfy_ui_settings.seed, comfy_ui_settings.steps, comfy_ui_settings.cfg, comfy_ui_settings.sampler_name, comfy_ui_settings.positive_prompt, comfy_ui_settings.negative_prompt, comfy_ui_settings.width, comfy_ui_settings.height, comfy_ui_settings.folder_destination)

    return {"request_id": comfy_ui_settings.request_id, "request_type": comfy_ui_settings.request_type, "image_path_list": image_path_list}

@app.post("/ebooklib/write_epub")
async def generate_epub(epub: Epub):

    epub_path = epub_writer.write_epub(epub.book_id, epub.title, epub.language, epub.author, epub.cover, epub.paragraph, epub.folder_destination_ebooks, epub.folder_destination_images)

    return {"epub_path": epub_path}
