extends Resource
## Force/length safety limits for the single unilateral spring.
@export_range(0.0, 200.0) var stiffness := 35.0
@export_range(0.0, 100.0) var damping := 9.0
@export_range(1.0, 1000.0) var contraction_speed := 180.0
@export_range(1.0, 900.0) var minimum_length := 36.0
@export_range(1.0, 3000.0) var maximum_length := 900.0
@export_range(1.0, 10000.0) var maximum_tension := 2800.0
