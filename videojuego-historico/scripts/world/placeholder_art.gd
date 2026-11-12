class_name PlaceholderArt
extends RefCounted
## Genera texturas placeholder en código (círculos/cuadrados de color) para
## objetos interactivos que todavía no tienen arte definitivo.

static func circle(radius: int, color: Color) -> ImageTexture:
	var size := radius * 2
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var r2 := radius * radius
	for y in size:
		for x in size:
			var dx := x - radius + 0.5
			var dy := y - radius + 0.5
			if dx * dx + dy * dy <= float(r2):
				img.set_pixel(x, y, color)
	return ImageTexture.create_from_image(img)

static func square(size: int, color: Color) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(color)
	return ImageTexture.create_from_image(img)
