extends Control

var _img_cache: Dictionary = {}

func _has_point(point: Vector2) -> bool:
	if not Rect2(Vector2.ZERO, size).has_point(point):
		return false
	for child_name in ["ItemBorde", "ItemInterior"]:
		var tex_rect := get_node_or_null(child_name) as TextureRect
		if tex_rect and tex_rect.texture and _texture_rect_has_opaque_pixel(tex_rect, point - tex_rect.position):
			return true
	return false

func _texture_rect_has_opaque_pixel(tex_rect: TextureRect, local_pos: Vector2) -> bool:
	var tex := tex_rect.texture
	var img: Image = _img_cache.get(tex)
	if img == null:
		img = tex.get_image()
		if img == null or img.is_empty():
			return false
		_img_cache[tex] = img
	var tex_size := Vector2(img.get_size())
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return false
	var fit_scale := minf(tex_rect.size.x / tex_size.x, tex_rect.size.y / tex_size.y)
	if fit_scale <= 0.0:
		return false
	var draw_size := tex_size * fit_scale
	var draw_offset := (tex_rect.size - draw_size) * 0.5
	var rel := (local_pos - draw_offset) / fit_scale
	var px := Vector2i(floori(rel.x), floori(rel.y))
	if px.x < 0 or px.y < 0 or px.x >= img.get_width() or px.y >= img.get_height():
		return false
	return img.get_pixelv(px).a > 0.1

