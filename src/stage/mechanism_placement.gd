class_name MechanismPlacement
extends Resource

@export var mechanism_data: MechanismData
@export var local_xz: Vector2 = Vector2.ZERO
@export var local_transform: Transform3D = Transform3D.IDENTITY
@export var route_role: StageRouteProfile.Role = StageRouteProfile.Role.PRIMARY
@export var route_index: int = -1
@export var shelf_t: float = -1.0
@export var downstream_tangent: Vector3 = Vector3.ZERO
