class_name StageGenerationContract
extends Resource

## Pins generation-wide version-4 values independently of legacy runtime profiles.

const CONTRACT_VERSION := 4
const REQUIRED_CELL_COUNT := Vector2i(72, 48)
const REQUIRED_LOCAL_BOUNDS := Rect2(Vector2(-90.0, -60.0), Vector2(180.0, 120.0))
const REQUIRED_TOP_TRIANGLE_COUNT := 6912
const REQUIRED_MASK_SIZE := 512
const REQUIRED_ATTEMPT_COUNT := 32
const REQUIRED_ATTEMPT_SEED_STRIDE := 7919

enum CellDiagonal {
	P01_TO_P10,
	P00_TO_P11,
}

@export_category("Versions")
@export_range(1, 99, 1) var generation_version: int = CONTRACT_VERSION
@export_range(1, 99, 1) var profile_version: int = CONTRACT_VERSION
@export_range(1, 99, 1) var layout_version: int = CONTRACT_VERSION

@export_category("Geometry")
@export var cell_count: Vector2i = REQUIRED_CELL_COUNT
@export var local_bounds: Rect2 = REQUIRED_LOCAL_BOUNDS
@export_range(1, 100000, 1) var top_triangle_count: int = REQUIRED_TOP_TRIANGLE_COUNT
@export var cell_diagonal: CellDiagonal = CellDiagonal.P01_TO_P10

@export_category("Generation")
@export_range(1, 2048, 1) var mask_size: int = REQUIRED_MASK_SIZE
@export_range(1, 256, 1) var attempt_count: int = REQUIRED_ATTEMPT_COUNT
@export var attempt_seed_stride: int = REQUIRED_ATTEMPT_SEED_STRIDE


func is_valid() -> bool:
	return generation_version == CONTRACT_VERSION \
			and profile_version == CONTRACT_VERSION \
			and layout_version == CONTRACT_VERSION \
			and cell_count == REQUIRED_CELL_COUNT \
			and local_bounds == REQUIRED_LOCAL_BOUNDS \
			and top_triangle_count == REQUIRED_TOP_TRIANGLE_COUNT \
			and top_triangle_count == cell_count.x * cell_count.y * 2 \
			and cell_diagonal == CellDiagonal.P01_TO_P10 \
			and mask_size == REQUIRED_MASK_SIZE \
			and attempt_count == REQUIRED_ATTEMPT_COUNT \
			and attempt_seed_stride == REQUIRED_ATTEMPT_SEED_STRIDE
