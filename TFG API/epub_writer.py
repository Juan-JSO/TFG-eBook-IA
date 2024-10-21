from ebooklib import epub

def write_epub(book_id, title, language, author, cover, paragraph, folder_destination_ebooks, folder_destination_images):

    book = epub.EpubBook()

    book.set_identifier(book_id)
    book.set_title(title)
    book.set_language(language)
    book.add_author(author)

    if cover != "":
        # create image from the local image
        image_cover = open(cover, "rb").read()
        img = epub.EpubImage(
            uid=f"img_cover",
            file_name="static/image_cover.png",
            media_type="image/png",
            content=image_cover,
        )
        # add image
        book.add_item(img)
        book.set_cover("image_cover", image_cover)

    chapters = []  # To store chapter objects
    toc_items = []  # To store TOC references
    chapter_content = ""  # Current chapter content
    chapter_number = 1  # Start with Chapter 1
    image_index = 0  # To track image numbering
    current_chapter_title = ""  # To store the title of the current chapter

    for p in paragraph:

        if p["type"] == 0:

            # Create a new chapter when a title is encountered (type 0)
            if chapter_content:
                # If there's existing chapter content, save the previous chapter first
                file_name = f"chap_{chapter_number:02}.xhtml"
                chapter = epub.EpubHtml(title=current_chapter_title, file_name=file_name, lang="en")
                chapter.content = chapter_content

                # Add chapter to the book
                book.add_item(chapter)
                chapters.append(chapter)

                # Add chapter to Table of Contents (TOC)
                toc_items.append(epub.Link(file_name, current_chapter_title, f"chap_{chapter_number}"))

                # Increment chapter number and reset content for the new chapter
                chapter_number += 1
                chapter_content = ""

            # Set new chapter title and start the content
            current_chapter_title = p["content"]
            chapter_content += f'<h1>{current_chapter_title}</h1>'
        elif p["type"] == 1:
            # Append paragraph text to the current chapter
            chapter_content += f'<p>{p["content"]}</p>'
        elif p["type"] == 2:

            from PIL import Image
            frames = [Image.open(image) for image in p["content"]]
            frame_one = frames[0]
            frame_one.save(f"{folder_destination_images}/image-{image_index}.gif", format="GIF", append_images=frames,
                    save_all=True, duration=166.66, loop=0)

            # Insert image into the current chapter
            chapter_content += f'<p><img src="static/image_{image_index}.gif"/><br/></p>'

            # Create image from the local file
            image_content = open(f"{folder_destination_images}/image-{image_index}.gif", "rb").read()
            img = epub.EpubImage(
                uid=f"img_{image_index}",
                file_name=f"static/image_{image_index}.gif",
                media_type="image/gif",
                content=image_content,
            )
            book.add_item(img)  # Add image to the book
            image_index += 1  # Increment image index

    # After the loop, make sure to add the last chapter if any content exists
    if chapter_content:
        file_name = f"chap_{chapter_number:02}.xhtml"
        chapter = epub.EpubHtml(title=current_chapter_title, file_name=file_name, lang="en")
        chapter.content = chapter_content

        book.add_item(chapter)
        chapters.append(chapter)
        toc_items.append(epub.Link(file_name, current_chapter_title, f"chap_{chapter_number}"))

    # Define Table Of Contents (TOC)
    book.toc = toc_items

    # Add default NCX and Nav file for navigation
    book.add_item(epub.EpubNcx())
    book.add_item(epub.EpubNav())

    # define CSS style
    style = "BODY {color: white;}"
    nav_css = epub.EpubItem(
        uid="style_nav",
        file_name="style/nav.css",
        media_type="text/css",
        content=style,
    )

    # add CSS file
    book.add_item(nav_css)

    # basic spine
    book.spine = ["nav"] + chapters

    # write to the file
    epub.write_epub(f"{folder_destination_ebooks}/{title}.epub", book, {})

    return f"{folder_destination_ebooks}/{title}.epub"