@tool
class_name GLTF2MeshLibraryImporter
extends EditorImportPlugin

## mode import_hierarchy: import the hierarchy of the GLTF file.
## mode import_mesh_only: import the mesh of the GLTF file. No hierarchy, all meshes are treated as single items.

## Basically, you can "import a GLTF file into a MeshLibrary" like what Godot does.
## but, there's another mode that treats every direct node of root as an Item in the MeshLibrary.
## the second mode treats mesh and its "Child mesh" together as an Item, which is useful in some cases.
## The second mode also supports "flags".
## In the second mode, you can use "--collision" or "-col" to convert the mesh into a collision shape.
## mesh convented into collisionshape would be invisible in editor, no texture, only collision box.

## Use the option "import_hierarchy" to switch between the two modes.

# "Imports".
const Lambdas := preload("./lambdas.gd")
const Helpers := preload("./helpers.gd")
const FlagsDetect := preload("./flagsdetect.gd")
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
	return [
		{"name": "import_hierarchy", "default_value": true},
		{"name": "generate_collision_shape", "default_value": false},  # Whether to gen collisionshape.
	]


func _get_option_visibility(path, option_name, options):
	return true


func _get_priority():
	return 1.0


func _get_import_order():
	return 9999


#endregion


#region importer_logics.
func _import(gltf_path: String, save_path, options, platform_variants, gen_files):
	print("Importing: ", gltf_path)
	if options.import_hierarchy:
		_import_hierarchy(gltf_path, save_path, options, platform_variants, gen_files)
	else:
		_import_mesh_only(gltf_path, save_path, options, platform_variants, gen_files)


func _import_mesh_only(gltf_path: String, save_path, options, platform_variants, gen_files):
	# Init.
	#print("Source File: ", gltf_path)
	#print("Save Path: ", save_path)

	var root_node: Node
	var meshLib: MeshLibrary = MeshLibrary.new()
	var file = FileAccess.open(gltf_path, FileAccess.READ)
	if file == null:
		print("Error: File Not Found!")
		return ERR_FILE_NOT_FOUND

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
	# FIXME: what the hell did I do here? I need to re-write this mode.
	var mesh_nodes := Helpers.find_first_matched_nodes(root_node, Lambdas.is_ImporterMeshInstance3D)

	# Add all meshes into MeshLibrary.
	var i := 0
	for mesh_node: ImporterMeshInstance3D in mesh_nodes:
		var mesh: ArrayMesh = mesh_node.mesh.get_mesh()  # Gets the mesh

		meshLib.create_item(i)
		meshLib.set_item_mesh(i, mesh)
		meshLib.set_item_name(i, mesh_node.name)
		if options.has("generate_collision_shape") and options.generate_collision_shape:
			var shape = mesh.create_convex_shape(true, true)
			if shape != null:
				meshLib.set_item_shapes(i, [shape])
		var preview: Array[Texture2D] = EditorInterface.make_mesh_previews([mesh], 64)
		meshLib.set_item_preview(i, preview[0])

		i += 1

	# Save
	root_node.queue_free()
	var filename = save_path + "." + _get_save_extension()
	return ResourceSaver.save(meshLib, filename)


func _import_hierarchy(gltf_path: String, save_path, options, platform_variants, gen_files):
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
	for item: Node3D in items_root.get_children():
		# Detect flags, see if we should import this item.
		if FlagsDetect.do_not_import(item.name):
			continue

		var mesh: ArrayMesh = Helpers.merge_meshs_together_recursively(item)
		# var mesh := Helpers.merge_collisions_together_recursively(item)
		# print(mesh)

		meshLib.create_item(i)
		meshLib.set_item_mesh(i, mesh)
		meshLib.set_item_name(i, item.name)

		var shape_mesh := Helpers.merge_collisions_together_recursively(item)
		var convexshape
		if shape_mesh:
			# convexshape = shape_mesh.create_convex_shape()
			convexshape = shape_mesh.create_trimesh_shape()
		if convexshape != null:
			meshLib.set_item_shapes(i, [convexshape])

		# if options.has("generate_collision_shape") and options.generate_collision_shape:
		# 	var shape := mesh.create_convex_shape(true, true)
		# 	if shape != null:
		# 		meshLib.set_item_shapes(i, [shape])

		var preview: Array[Texture2D] = EditorInterface.make_mesh_previews([mesh], 64)
		meshLib.set_item_preview(i, preview[0])

		i += 1

	# Save the mesh library.
	var filename = save_path + "." + _get_save_extension()
	return ResourceSaver.save(meshLib, filename)
#endregion
