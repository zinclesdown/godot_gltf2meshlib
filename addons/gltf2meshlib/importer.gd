@tool
class_name GLTF2MeshLibraryImporter
extends EditorImportPlugin

# "Imports".
const Lambdas := preload("./lambdas.gd")
const Helpers := preload("./helpers.gd")
const FlagsDetect := preload("./flagsdetect.gd")


#region plugin_definitions
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
	return [
		# Whether to gen collisionshape simply by mesh. This would ignore "--collision" flags.
		{"name": "generate_collision_shape_by_mesh", "default_value": false},
		{"name": "generate_preview", "default_value": true},  # Whether to gen preview.
		{"name": "model_offset", "default_value": Vector3(0, 0, 0)},  # Default model offset
		{"name": "sort_by_name", "default_value": true}  # Sort by name. preventing unexpected order.
	]


func _get_option_visibility(path, option_name, options):
	return true


func _get_priority():
	return 0.9


func _get_import_order():
	return 99


#endregion


#region importer_logics.
func _import(gltf_path: String, save_path, options, platform_variants, gen_files):
	print("Importing: ", gltf_path)

	var root_node: Node
	var meshLib: MeshLibrary = MeshLibrary.new()
	var file = FileAccess.open(gltf_path, FileAccess.READ)
	if file == null:
		print("Error: File Not Found!")
		return ERR_FILE_NOT_FOUND

	# Load the GLTF file and initialize as Node.
	var gltf_document_load := GLTFDocument.new()
	var gltf_state_load := GLTFState.new()
	var error := gltf_document_load.append_from_file(gltf_path, gltf_state_load)
	if error == OK:
		root_node = gltf_document_load.generate_scene(gltf_state_load)
	else:
		print("Error: %s " % error_string(error))
		return error

	# Find the root node of the items to be imported.
	# This is necessary because some programs add an empty node as a parent of the mesh.
	# We need to step deeper until we find multiple nodes.
	var items_root = root_node
	while items_root.get_child_count() == 1:
		items_root = items_root.get_child(0)

	# Loop through each item, merge their meshes and apply transformations.
	var i := 0

	# Sort?
	var items_arr: Array[Node] = items_root.get_children()
	if options["sort_by_name"]:
		items_arr.sort_custom(Lambdas.NodeNameSortMethod)

	for item: Node3D in items_arr:
		# Detect flags, see if we should import this item.
		if FlagsDetect.do_not_import(item.name):
			continue

		var model_mesh: ArrayMesh = Helpers.merge_meshs_together_recursively(item)

		model_mesh = Helpers.apply_transform_to_arraymesh(
			model_mesh, Transform3D(Basis.IDENTITY, options["model_offset"])
		)  # implement offset.

		# print("Setting up model for ", item.name)
		meshLib.create_item(i)
		meshLib.set_item_mesh(i, model_mesh)
		meshLib.set_item_name(i, item.name)

		# print("Setting up collision for ", item.name)
		# Generate collision by mesh, or by models with '-col' flags.
		if options.generate_collision_shape_by_mesh:
			# Generate Collision simply by it's Mesh.
			var shape_mesh := model_mesh.create_trimesh_shape()
			if shape_mesh != null:
				meshLib.set_item_shapes(i, [shape_mesh])
				print("> Generated collision simply by mesh. --collision flags are ignored.")
		else:
			# Generate Collision with flag tagged Mesh, ignore model mesh. This is the recommended way.
			var shape_mesh := Helpers.merge_collisions_together_recursively(item)

			if shape_mesh.get_surface_count() != 0:
				# convexshape = shape_mesh.create_convex_shape()
				# print("> Creating convex shape.")
				shape_mesh = Helpers.apply_transform_to_arraymesh(
					shape_mesh, Transform3D(Basis.IDENTITY, options["model_offset"])
				)  # implement offset.
				var convexshape = shape_mesh.create_trimesh_shape()
				if convexshape != null:
					meshLib.set_item_shapes(i, [convexshape])
					print("> Genrated collision by flag -col tagged mesh.")

		if options["generate_preview"] == true:
			if model_mesh.get_surface_count() > 0:
				# Seems this would raise Error.. with editor with gridmap scene opened. why?
				var preview: Array[Texture2D] = EditorInterface.make_mesh_previews([model_mesh], 64)
				meshLib.set_item_preview(i, preview[0])
			print("> Generated Preview.")

		i += 1

	print("Done processing meshes. Saving...")
	root_node.queue_free()

	# Save the mesh library.
	var filename = save_path + "." + _get_save_extension()
	return ResourceSaver.save(meshLib, filename)
#endregion
