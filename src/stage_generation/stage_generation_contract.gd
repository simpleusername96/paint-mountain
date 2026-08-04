class_name StageGenerationContract
extends Resource

## Owns every generation-wide version-4 constant consumed by production.

const CONTRACT_VERSION := 4
const REQUIRED_CELL_COUNT := Vector2i(72, 48)
const REQUIRED_LOCAL_BOUNDS := Rect2(Vector2(-90.0, -60.0), Vector2(180.0, 120.0))
const REQUIRED_MAXIMUM_TOP_TRIANGLE_COUNT := 6912
const REQUIRED_MASK_SIZE := 512
const REQUIRED_ATTEMPT_COUNT := 32
const REQUIRED_ATTEMPT_SEED_STRIDE := 7919
const REQUIRED_ROUTE_STATION_Z := [-44.0, -32.0, -20.0, -8.0, 4.0, 16.0, 30.0, 44.0]

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
@export_range(1, 100000, 1) var maximum_top_triangle_count: int = REQUIRED_MAXIMUM_TOP_TRIANGLE_COUNT
@export var cell_diagonal: CellDiagonal = CellDiagonal.P01_TO_P10

@export_category("Generation")
@export_range(1, 2048, 1) var mask_size: int = REQUIRED_MASK_SIZE
@export_range(1, 256, 1) var attempt_count: int = REQUIRED_ATTEMPT_COUNT
@export var attempt_seed_stride: int = REQUIRED_ATTEMPT_SEED_STRIDE

@export_category("Route graph")
@export var route_station_z := PackedFloat32Array(REQUIRED_ROUTE_STATION_Z)
@export_range(1.0, 64.0, 0.5) var maximum_station_x_delta: float = 18.0

@export_category("Height synthesis")
@export_range(0.0, 32.0, 0.5) var outer_band_width: float = 12.0
@export_range(0.1, 16.0, 0.1) var terrace_step: float = 4.0
@export_range(0.0, 1.0, 0.01) var terrace_blend: float = 0.90
@export_range(0.0, 16.0, 0.5) var bank_height: float = 4.0
@export_range(0.1, 32.0, 0.5) var bank_blend_distance: float = 8.0
@export_range(0.1, 32.0, 0.5) var target_shoulder_distance: float = 12.0
@export_range(0.1, 64.0, 0.5) var support_distance: float = 24.0
@export_range(0.1, 16.0, 0.1) var smooth_max_k: float = 6.0
@export_range(0.1, 16.0, 0.1) var smooth_min_k: float = 3.0

@export_category("Noise")
@export_range(0.001, 1.0, 0.001) var noise_frequency: float = 0.035
@export_range(1, 8, 1) var noise_octaves: int = 2
@export_range(1.0, 8.0, 0.05) var noise_lacunarity: float = 2.0
@export_range(0.0, 1.0, 0.01) var noise_gain: float = 0.45
@export_range(0.0, 4.0, 0.05) var noise_amplitude: float = 0.5


func is_valid() -> bool:
	return generation_version == CONTRACT_VERSION \
			and profile_version == CONTRACT_VERSION \
			and layout_version == CONTRACT_VERSION \
			and cell_count == REQUIRED_CELL_COUNT \
			and local_bounds == REQUIRED_LOCAL_BOUNDS \
			and maximum_top_triangle_count == REQUIRED_MAXIMUM_TOP_TRIANGLE_COUNT \
			and maximum_top_triangle_count == cell_count.x * cell_count.y * 2 \
			and cell_diagonal == CellDiagonal.P01_TO_P10 \
			and mask_size == REQUIRED_MASK_SIZE \
			and attempt_count == REQUIRED_ATTEMPT_COUNT \
			and attempt_seed_stride == REQUIRED_ATTEMPT_SEED_STRIDE \
			and route_station_z == PackedFloat32Array(REQUIRED_ROUTE_STATION_Z) \
			and is_equal_approx(maximum_station_x_delta, 18.0) \
			and is_equal_approx(outer_band_width, 12.0) \
			and is_equal_approx(terrace_step, 4.0) \
			and is_equal_approx(terrace_blend, 0.90) \
			and is_equal_approx(bank_height, 4.0) \
			and is_equal_approx(bank_blend_distance, 8.0) \
			and is_equal_approx(target_shoulder_distance, 12.0) \
			and is_equal_approx(support_distance, 24.0) \
			and is_equal_approx(smooth_max_k, 6.0) \
			and is_equal_approx(smooth_min_k, 3.0) \
			and is_equal_approx(noise_frequency, 0.035) \
			and noise_octaves == 2 \
			and is_equal_approx(noise_lacunarity, 2.0) \
			and is_equal_approx(noise_gain, 0.45) \
			and is_equal_approx(noise_amplitude, 0.5)
