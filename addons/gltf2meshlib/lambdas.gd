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


static func StringSortMethod(str1: String, str2: String) -> bool:
	return str1 < str2


static func NodeNameSortMethod(node1: Node, node2: Node) -> bool:
	return StringSortMethod(node1.name, node2.name)
