extends RefCounted

## Convex support mapping keeps sphere/cylinder/box attacks correct under their
## full world transform, including nonuniform scale, against the projectile hurt box.
static func overlaps_box(type: int, xform: Transform3D, params: Dictionary, center: Vector3, half: Vector3) -> bool:
	var direction := center - xform.origin
	if direction.is_zero_approx():
		direction = Vector3.RIGHT
	var simplex: Array[Vector3] = []
	for iteration in 64:
		var point := support(type, xform, params, direction) - box_support(center, half, -direction)
		if point.dot(direction) < -0.00001:
			return false
		simplex.push_front(point)
		var step := reduce_simplex(simplex)
		if step.hit:
			return true
		direction = step.direction
		if direction.length_squared() < 0.00000001:
			return true
	return false

static func support(type: int, xform: Transform3D, params: Dictionary, direction: Vector3) -> Vector3:
	var local := xform.basis.transposed() * direction
	var point := Vector3.ZERO
	match type:
		0: # Sphere becomes an ellipsoid under nonuniform scale.
			point = local.normalized() * float(params.radius)
		1:
			var radial := Vector2(local.x, local.z).normalized() * float(params.radius)
			point = Vector3(radial.x, float(params.half_height) if local.y >= 0.0 else -float(params.half_height), radial.y)
		2:
			point = box_support(Vector3.ZERO, params.half_extents, local)
	return xform * point

static func box_support(center: Vector3, half: Vector3, direction: Vector3) -> Vector3:
	return center + Vector3(half.x if direction.x >= 0.0 else -half.x, half.y if direction.y >= 0.0 else -half.y, half.z if direction.z >= 0.0 else -half.z)

static func reduce_simplex(points: Array[Vector3]) -> Dictionary:
	var a := points[0]
	var ao := -a
	if points.size() == 1:
		return {hit = false, direction = ao}
	var b := points[1]
	var ab := b - a
	if points.size() == 2:
		if ab.dot(ao) > 0.0:
			return {hit = false, direction = ab.cross(ao).cross(ab)}
		points.assign([a])
		return {hit = false, direction = ao}
	var c := points[2]
	var ac := c - a
	var normal := ab.cross(ac)
	if points.size() == 3:
		if normal.cross(ac).dot(ao) > 0.0:
			if ac.dot(ao) > 0.0:
				points.assign([a, c])
				return {hit = false, direction = ac.cross(ao).cross(ac)}
			points.assign([a, b])
			return reduce_simplex(points)
		if ab.cross(normal).dot(ao) > 0.0:
			points.assign([a, b])
			return reduce_simplex(points)
		if normal.dot(ao) >= 0.0:
			return {hit = false, direction = normal}
		points.assign([a, c, b])
		return {hit = false, direction = -normal}
	var d := points[3]
	# Check the three faces incident to the newest support point. Orient each
	# face away from the opposite vertex, independent of simplex winding.
	for face in [[b, c, d], [c, d, b], [d, b, c]]:
		var u: Vector3 = face[0]
		var v: Vector3 = face[1]
		var opposite: Vector3 = face[2]
		var outward := (u - a).cross(v - a)
		if outward.dot(opposite - a) > 0.0:
			outward = -outward
		if outward.dot(ao) > 0.0:
			points.assign([a, u, v])
			return reduce_simplex(points)
	return {hit = true, direction = Vector3.ZERO}
