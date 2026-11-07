extends RefCounted

static func rectangles(cells: Dictionary) -> Array[Rect2i]:
	var remaining := cells.duplicate()
	var ordered := remaining.keys()
	ordered.sort()
	var result: Array[Rect2i] = []
	for origin: Vector2i in ordered:
		if not remaining.has(origin):
			continue
		var width := 1
		while remaining.has(origin + Vector2i(width, 0)):
			width += 1
		var height := 1
		while row_exists(remaining, origin + Vector2i(0, height), width):
			height += 1
		result.append(Rect2i(origin, Vector2i(width, height)))
		for y in height:
			for x in width:
				remaining.erase(origin + Vector2i(x, y))
	return result

static func row_exists(cells: Dictionary, origin: Vector2i, width: int) -> bool:
	for x in width:
		if not cells.has(origin + Vector2i(x, 0)):
			return false
	return true

