class_name PaintDepositTuning
extends Resource

@export_range(0.0, 1.0, 0.001) var painted_threshold: float = 0.18
@export_range(0.01, 1000.0, 0.01) var paint_units_per_full_alpha: float = 22.0
@export_range(0.0, 4.0, 0.01) var trail_intensity: float = 1.0
@export_range(0.0, 4.0, 0.01) var impact_intensity: float = 1.15
@export_range(0.0, 4.0, 0.01) var final_puddle_intensity: float = 0.90
@export_range(0.0, 4.0, 0.01) var burst_intensity: float = 1.0
@export_range(0.0, 1.0, 0.01) var flow_amount_ratio: float = 0.36
@export_range(0.0, 1.0, 0.01) var flow_decay: float = 0.72
@export_range(0.0, 1.0, 0.01) var flow_radius_ratio: float = 0.42
@export_range(0.0, 1.0, 0.001) var minimum_flow_alpha: float = 0.02


func intensity_multiplier(source_kind: PaintDepositRequest.SourceKind) -> float:
	match source_kind:
		PaintDepositRequest.SourceKind.IMPACT:
			return impact_intensity
		PaintDepositRequest.SourceKind.FINAL_PUDDLE:
			return final_puddle_intensity
		PaintDepositRequest.SourceKind.BURST:
			return burst_intensity
		_:
			return trail_intensity
