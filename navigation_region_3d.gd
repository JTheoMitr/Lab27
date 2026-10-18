extends NavigationRegion3D

func _ready() -> void:
	if navigation_mesh == null:
		print("No NavigationMesh assigned!")
		return

	print("Navigation polygons: ", navigation_mesh.get_polygon_count())
