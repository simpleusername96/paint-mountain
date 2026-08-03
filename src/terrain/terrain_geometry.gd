class_name TerrainGeometry
extends RefCounted

var render_mesh: ArrayMesh
var top_shape: HeightMapShape3D
var skirt_shape: ConcavePolygonShape3D
var local_bounds: Rect2
var cell_size: float = 2.5
var base_y: float = -12.0
var top_vertex_count: int = 0
var shell_vertex_count: int = 0
var top_triangle_count: int = 0
var skirt_triangle_count: int = 0
var bottom_triangle_count: int = 0


func total_triangle_count() -> int:
	return top_triangle_count + skirt_triangle_count + bottom_triangle_count


func is_valid() -> bool:
	return render_mesh != null \
			and top_shape != null \
			and skirt_shape != null \
			and local_bounds.has_area() \
			and cell_size > 0.0 \
			and top_triangle_count > 0 \
			and skirt_triangle_count > 0 \
			and bottom_triangle_count == 2
