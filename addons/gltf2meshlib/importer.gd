@tool
class_name GLTF2MeshLibraryImporter
extends EditorImportPlugin

#region plugin_definitions

# In my case the plugin works fine by default.
# If you have any suggestions, please let me know in Github Issues.


func _get_importer_name():
	return "zincles.gltf2meshlib"


func _get_visible_name():
	return "GLTF To MeshLibrary"


func _get_recognized_extensions():
	return ["gltf", "glb"]


func _get_save_extension():
	return "meshlib"


func _get_resource_type():
	return "MeshLibrary"


func _get_preset_count():
	return 1


func _get_preset_name(preset_index):
	return "Default"


func _get_import_options(path, preset_index):
	return [{"name": "generate_collision_shape", "default_value": false}]


func _get_option_visibility(path, option_name, options):
	return true


func _get_import_order():
	return 9999


#endregion

#region importer_logics.


func _is_ImporterMeshInstance3D(node: Node) -> bool:
	#print("Node: ", node)
	if is_instance_of(node, ImporterMeshInstance3D):
		return true
	return false


# Found all nodes, Pack them into an Array.
# The matcher should accept one argument (Node),returns a bool.
func find_first_matched_nodes(root_node: Node, matcher: Callable) -> Array[Node]:
	var result: Array[Node] = []

	for node: Node in root_node.get_children():
		var matches: bool = matcher.call(node)
		if matches == true:
			result.append(node)
			continue
		else:
			var matched_nodes := find_first_matched_nodes(node, matcher)
			result.append_array(matched_nodes)
	return result


func _import(gltf_path: String, save_path, options, platform_variants, gen_files):
	# Init.
	#print("Source File: ", gltf_path)
	#print("Save Path: ", save_path)

	var root_node: Node
	var meshLib: MeshLibrary = MeshLibrary.new()
	var file = FileAccess.open(gltf_path, FileAccess.READ)
	if file == null:
		print("Error: File Not Found!")
		return ERR_PARSE_ERROR

	# load the GLTF file, init as Node.
	var gltf_document_load := GLTFDocument.new()
	var gltf_state_load := GLTFState.new()
	var error := gltf_document_load.append_from_file(gltf_path, gltf_state_load)
	if error == OK:
		root_node = gltf_document_load.generate_scene(gltf_state_load)
	else:
		print("Error: %s " % error_string(error))
		return error

	# Get all MeshInstance3D nodes.
	var mesh_nodes := find_first_matched_nodes(root_node, _is_ImporterMeshInstance3D)

	# Add all meshes into MeshLibrary.
	var i := 0
	for mesh_node: ImporterMeshInstance3D in mesh_nodes:
		var mesh: ArrayMesh = mesh_node.mesh.get_mesh()  # Gets the mesh

		meshLib.create_item(i)
		meshLib.set_item_mesh(i, mesh)
		meshLib.set_item_name(i, mesh_node.name)
		if options.has("generate_collision_shape") and options.generate_collision_shape:
			var shape = mesh.create_convex_shape(true,true)
			if shape != null:
				meshLib.set_item_shapes(i,[shape])
		var preview: Array[Texture2D] = EditorInterface.make_mesh_previews([mesh], 64)
		meshLib.set_item_preview(i, preview[0])

		i += 1

	# Save
	root_node.queue_free()
	var filename = save_path + "." + _get_save_extension()
	return ResourceSaver.save(meshLib, filename)

#endregion
