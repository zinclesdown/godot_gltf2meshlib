extends Resource

const FlagsDetect := preload("./flagsdetect.gd")


# Gets all child nodes in any depth, pick the nodes that matches the matcher.
static func find_all_matched_nodes(root_node: Node, matcher: Callable) -> Array[Node]:
	var result: Array[Node] = []

	for node: Node in root_node.get_children():
		var matches: bool = matcher.call(node)
		if matches == true:
			result.append(node)
		else:
			var matched_nodes := find_all_matched_nodes(node, matcher)
			result.append_array(matched_nodes)
	return result


## Merge Mesh-related nodes under a single node into one Mesh.
static func merge_meshs_together_recursively(base_node: Node3D) -> ArrayMesh:
	# Get the Mesh of the current node:
	var new_mesh: ArrayMesh = null

	if base_node is MeshInstance3D and not FlagsDetect.import_as_collision(base_node.name):
		new_mesh = base_node.mesh as ArrayMesh
	elif (
		base_node is ImporterMeshInstance3D and not FlagsDetect.import_as_collision(base_node.name)
	):
		new_mesh = base_node.mesh.get_mesh() as ArrayMesh
	else:
		new_mesh = ArrayMesh.new()

	for child in base_node.get_children():
		new_mesh = combine_multisurface(
			new_mesh, merge_meshs_together_recursively(child), child.transform
		)

	return new_mesh


## same as above, but only merges nodes with '-col' flags.
static func merge_collisions_together_recursively(base_node: Node3D) -> ArrayMesh:
	# Get the Mesh of the current node:
	var new_mesh: ArrayMesh

	if base_node is MeshInstance3D and FlagsDetect.import_as_collision(base_node.name):
		new_mesh = base_node.mesh as ArrayMesh
	elif base_node is ImporterMeshInstance3D and FlagsDetect.import_as_collision(base_node.name):
		new_mesh = base_node.mesh.get_mesh() as ArrayMesh
	else:
		new_mesh = ArrayMesh.new()

	for child in base_node.get_children():
		new_mesh = combine_multisurface(
			new_mesh, merge_collisions_together_recursively(child), child.transform
		)

	return new_mesh


## Merging two ArrayMeshes into one. This would keep their Transform.
## you need your transform from one mesh to another.
static func combine_multisurface(
	mesh_base: ArrayMesh, mesh_remote: ArrayMesh, transform_toward_base: Transform3D
) -> ArrayMesh:
	var new_mesh := ArrayMesh.new()

	# Make sure the mesh is not null.
	if mesh_base == null:
		mesh_base = ArrayMesh.new()
	if mesh_remote == null:
		mesh_remote = ArrayMesh.new()

	for i in range(mesh_base.get_surface_count()):
		# First, merge all base's surface.
		var surface1 := mesh_base.surface_get_arrays(i)
		new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface1)
		new_mesh.surface_set_material(i, mesh_base.surface_get_material(i))

	for i in range(mesh_remote.get_surface_count()):
		# Then we merge all remote's surface, considering the transform.
		# Note: the parameter of surface_set_material needs to consider the number of surfaces of the base, that is, an offset is made.

		var surface2 := mesh_remote.surface_get_arrays(i)

		var vertices2: PackedVector3Array = surface2[ArrayMesh.ARRAY_VERTEX]
		var normals2: PackedVector3Array = surface2[ArrayMesh.ARRAY_NORMAL]
		var uvs2: PackedVector2Array = surface2[ArrayMesh.ARRAY_TEX_UV]

		var new_vertices: PackedVector3Array = []
		var new_normals: PackedVector3Array = []
		var new_uvs: PackedVector2Array = []

		for j in range(vertices2.size()):
			var vertex: Vector3 = vertices2[j]
			var normal: Vector3 = normals2[j]
			var uv: Vector2 = uvs2[j]

			vertex = transform_toward_base * vertex
			normal = transform_toward_base.basis * (normal)

			new_vertices.append(vertex)
			new_normals.append(normal)
			new_uvs.append(uv)

		surface2[ArrayMesh.ARRAY_VERTEX] = new_vertices
		surface2[ArrayMesh.ARRAY_NORMAL] = new_normals
		surface2[ArrayMesh.ARRAY_TEX_UV] = new_uvs

		new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface2)
		new_mesh.surface_set_material(
			i + mesh_base.get_surface_count(), mesh_remote.surface_get_material(i)
		)

	return new_mesh


## Applys a transform3D to an ArrayMesh. returns a new ArrayMesh. It always returns a valid mesh, even if it might be empty.
static func apply_transform_to_arraymesh(
	array_mesh: ArrayMesh, transform: Transform3D
) -> ArrayMesh:
	var new_mesh := ArrayMesh.new()

	if not is_instance_valid(array_mesh):
		push_warning(
			"apply_transform_to_arraymesh(): array_mesh {} is not valid.".format([array_mesh])
		)
		# return null
	elif array_mesh.get_surface_count() <= 0:
		push_warning(
			"apply_transform_to_arraymesh(): array_mesh {} has no surface.".format([array_mesh])
		)
		# return null

	# loop through all surfaces, apply the transform.
	for i_surf in range(array_mesh.get_surface_count()):
		var surface := array_mesh.surface_get_arrays(i_surf)

		var vertices: PackedVector3Array = surface[ArrayMesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = surface[ArrayMesh.ARRAY_NORMAL]
		var uvs: PackedVector2Array = surface[ArrayMesh.ARRAY_TEX_UV]

		# in each surface, we loop through all vertices, apply the transform.
		for j in range(vertices.size()):
			var vertex: Vector3 = vertices[j]
			var normal: Vector3 = normals[j]

			vertex = transform * vertex
			normal = transform.basis * (normal)

			vertices[j] = vertex
			normals[j] = normal

		surface[ArrayMesh.ARRAY_VERTEX] = vertices
		surface[ArrayMesh.ARRAY_NORMAL] = normals

		# build a new ArrayMesh
		new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface)
		new_mesh.surface_set_material(i_surf, array_mesh.surface_get_material(i_surf))

	return new_mesh
