extends Resource


static func is_ImporterMeshInstance3D(node: Node) -> bool:
	#print("Node: ", node)
	if is_instance_of(node, ImporterMeshInstance3D):
		return true
	return false


static func is_MeshInstance3D(node: Node) -> bool:
	#print("Node: ", node)
	if is_instance_of(node, MeshInstance3D):
		return true
	return false
