extends MeshInstance3D


enum SlideType {
	NONE,
	PITCHED,
	UNPITCHED
}

const NUM_FACES_SLIDE: int = 10
const NUM_FACES_VIBRATO: int = 8 # The number of faces in a single period of sine wave
const VIBRATO_SCALE: float = 0.2
const VIBRATO_AMPLITUDE: float = 0.5

var width: float = 1:
	set(value):
		width = value
	get:
		return width


var length: float = 5:
	set(value):
		length = value
	get:
		return length


var tail_width: float = 1
var end_x_offset: float = -4
var slide_type: SlideType  = SlideType.NONE
var has_vibrato: bool = false


func _ready():
	match slide_type:
		SlideType.NONE:
			if has_vibrato:
				_draw_vibrato()
			else:
				_draw_straight_tail()
		SlideType.PITCHED:
			_draw_pitched_tail()
		SlideType.UNPITCHED:
			_draw_unpitched_tail()


func _draw_straight_tail():
	var max_x := width * 0.5
	var min_x := width * -0.5
	
	var vertices: PackedVector3Array
	vertices.append(Vector3(max_x, 0, 0))
	vertices.append(Vector3(min_x, 0, 0))
	vertices.append(Vector3(max_x, 0, -length))
	vertices.append(Vector3(min_x, 0, -length))
	_draw_quad_chain(vertices)


func _draw_vibrato():
	var vertices: PackedVector3Array
	var normals: PackedVector3Array
	
	var period: float = VIBRATO_SCALE * TAU
	var test: float = TAU
	var num_periods: int = round(length / period)
	num_periods = max(1, num_periods)
	period = length / num_periods # Adjust for rounding above
	var vibrato_scale = period / TAU # VIBRATO_SCALE after adjustment
	var amplitude: float = VIBRATO_AMPLITUDE * vibrato_scale
	
	var num_faces = NUM_FACES_VIBRATO * num_periods
	
	for i in num_faces + 1:
		var t = length * float(i) / num_faces
		var sine = sin(TAU * t / period)
		var cosine = cos(TAU * t / period)
		var center_point := Vector3(0, amplitude * sine, -t)
		var normal := Vector3(0, 1 / amplitude, cosine).normalized()
		
		vertices.append(center_point + Vector3.RIGHT * width * 0.5)
		vertices.append(center_point + Vector3.LEFT * width * 0.5)
		normals.append(normal)
		normals.append(normal)
	
	_draw_quad_chain(vertices, normals)


func _draw_pitched_tail():
	var vertices: PackedVector3Array
	
	var max_x := width * 0.5
	var min_x := width * -0.5
	
	var control_point_distance := 0.33
	
	var start_point := Vector3.ZERO
	var end_point := Vector3(end_x_offset, 0, -length)
	var start_control := Vector3(0, 0, control_point_distance * -length)
	var end_control := Vector3(end_x_offset, 0, (1 - control_point_distance) * -length)
	
	for i in NUM_FACES_SLIDE + 1:
		var t := float(i) / NUM_FACES_SLIDE
		var center_point = _get_point_cubic(start_point, start_control, end_control, end_point, t)
		var tangent = _get_tangent_cubic(start_point, start_control, end_control, end_point, t).normalized()
		var normal := Vector3(-tangent.z, 0, tangent.x)
		vertices.append(center_point + max_x * normal)
		vertices.append(center_point + min_x * normal)
	
	_draw_quad_chain(vertices)


func _draw_unpitched_tail():
	var vertices: PackedVector3Array
	var colors: PackedColorArray
	
	var max_x := width * 0.5
	var min_x := width * -0.5
	
	var start_point := Vector3.ZERO
	var end_point := Vector3(end_x_offset, 0, -length)
	var control_point := Vector3(0, 0, 0.5 * -length)
	
	for i in NUM_FACES_SLIDE + 1:
		var t := float(i) / NUM_FACES_SLIDE
		var center_point = _get_point_quadratic(start_point, control_point, end_point, t)
		var tangent = _get_tangent_quadratic(start_point, control_point, end_point, t).normalized()
		var spline_normal := Vector3(-tangent.z, 0, tangent.x)
		vertices.append(center_point + max_x * spline_normal)
		vertices.append(center_point + min_x * spline_normal)
		colors.append((1.0 - t) * Color.WHITE)
		colors.append((1.0 - t) * Color.WHITE)
	
	_draw_quad_chain(vertices, PackedVector3Array(), colors)


# This function expects a series of vertices ordered per cross-edge, with the righthand side vertex first for every edge.
func _draw_quad_chain(vertices: PackedVector3Array, normals: PackedVector3Array = PackedVector3Array(), colors: PackedColorArray = PackedColorArray()):
	var triangles: PackedInt32Array
	for i in range(0, vertices.size() - 2, 2):
		triangles.append(i)
		triangles.append(i + 1)
		triangles.append(i + 3)
		
		triangles.append(i)
		triangles.append(i + 3)
		triangles.append(i + 2)
	
	if normals.size() == 0:
		for i in vertices.size():
			normals.append(Vector3.UP)
	
	if colors.size() == 0:
		for i in vertices.size():
			colors.append(Color.WHITE)
	
	var arrays: Array
	arrays.resize(ArrayMesh.ARRAY_MAX)
	arrays[ArrayMesh.ARRAY_VERTEX] = vertices
	arrays[ArrayMesh.ARRAY_INDEX] = triangles
	arrays[ArrayMesh.ARRAY_NORMAL] = normals
	arrays[ArrayMesh.ARRAY_COLOR] = colors
	var array_mesh := ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	mesh = array_mesh


func _get_point_quadratic(p0, p1, p2, t):
	var t2: float = t * t
	return p0 * (t2 - 2 * t + 1) + p1 * (2 * t - 2 * t2) + p2 * t2


func _get_tangent_quadratic(p0, p1, p2, t):
	return p0 * (2 * t - 2) + p1 * (2 - 4 * t) + p2 * 2 * t


func _get_point_cubic(p0, p1, p2, p3, t):
	var t2: float = t * t
	var t3: float = t2 * t
	return p0 * (-t3 + 3 * t2 - 3 * t + 1) \
		+ p1 * (3 * t3 - 6 * t2 + 3 * t) \
		+ p2 * (-3 * t3 + 3 * t2) \
		+ p3 * t3


func _get_tangent_cubic(p0, p1, p2, p3, t):
	var t2: float = t * t
	return p0 * (-3 * t2 + 6 * t - 3) \
		+ p1 * (9 * t2 - 12 * t + 3) \
		+ p2 * (-9 * t2 + 6 * t) \
		+ p3 * 3 * t2
