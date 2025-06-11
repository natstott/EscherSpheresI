extends MeshInstance3D

func _ready() -> void:
	var imagesize = Vector2(1024,1024)
	var image=Image.create_empty(imagesize.x,imagesize.y,true,Image.FORMAT_RGB8)
	image.fill(Color.BLACK)
	var number_rows=64 #columns the same?
	var rowheight=imagesize.y/number_rows
	for i in range(number_rows):
		image.fill_rect(Rect2i(0,i*rowheight,imagesize.x,4),Color.WHITE)
		for j in range(number_rows):
			var linewidth=16-12*sin((PI*float(i))/float(number_rows))
			image.fill_rect(Rect2i(j*rowheight-linewidth/2,i*rowheight,linewidth,rowheight),Color.WHITE)
	var filename="res://newimage.png"
	image.generate_mipmaps(true)
	print("mipmaps:" ,image.get_mipmap_count())
	image.save_png(filename)
	var texture = ImageTexture.create_from_image(image)
	print("tex: ", texture)
	self.get_active_material(0).set_shader_parameter("texture_albedo", texture)
