class_name GeneratedRouteGraph
extends RefCounted

var nodes: Array[GeneratedRouteNode]:
	get:
		return _nodes.duplicate()
var edges: Array[GeneratedRouteEdge]:
	get:
		return _edges.duplicate()

var _nodes: Array[GeneratedRouteNode] = []
var _edges: Array[GeneratedRouteEdge] = []
var _node_index_by_id: Dictionary = {}
var _edge_index_by_id: Dictionary = {}
var _has_unique_ids: bool = true


func _init(
		graph_nodes: Array[GeneratedRouteNode] = [],
		graph_edges: Array[GeneratedRouteEdge] = []
) -> void:
	for node in graph_nodes:
		_nodes.append(node)
	for edge in graph_edges:
		_edges.append(edge)
	_build_indices()


func is_valid() -> bool:
	if _nodes.is_empty() or _edges.is_empty() or not _has_unique_ids:
		return false
	for node in _nodes:
		if node == null or not node.is_valid():
			return false
	for edge in _edges:
		if edge == null or not edge.is_valid():
			return false
		if not _node_index_by_id.has(edge.from_node_id) \
				or not _node_index_by_id.has(edge.to_node_id):
			return false
	return true


func node_index(node_id: StringName) -> int:
	return int(_node_index_by_id.get(node_id, -1))


func edge_index(edge_id: StringName) -> int:
	return int(_edge_index_by_id.get(edge_id, -1))


func node_by_id(node_id: StringName) -> GeneratedRouteNode:
	var index := node_index(node_id)
	return _nodes[index] if index >= 0 else null


func edge_by_id(edge_id: StringName) -> GeneratedRouteEdge:
	var index := edge_index(edge_id)
	return _edges[index] if index >= 0 else null


func node_index_map() -> Dictionary:
	return _node_index_by_id.duplicate()


func edge_index_map() -> Dictionary:
	return _edge_index_by_id.duplicate()


func _build_indices() -> void:
	for index in range(_nodes.size()):
		var node := _nodes[index]
		if node == null or _node_index_by_id.has(node.id):
			_has_unique_ids = false
			continue
		_node_index_by_id[node.id] = index
	for index in range(_edges.size()):
		var edge := _edges[index]
		if edge == null or _edge_index_by_id.has(edge.id):
			_has_unique_ids = false
			continue
		_edge_index_by_id[edge.id] = index
