extends Node3D

@export var chunk_size = 40

var chunks_data = []
var chunk_index := 0

var current_chunk : Node3D

var prefab_static = preload("res://platforms/static_platform.tscn")
var prefab_moving = preload("res://platforms/mobile_platform.tscn")
var prefab_stalactite = preload("res://objects/stalactite.tscn")
var prefab_coffee = preload("res://collectibles/coffee.tscn")


@onready var chunk_holder = $"."
var chunk_to_delete : Node3D = null

func _ready():
	load_chunks_config()
	load_next_chunk()

func load_chunks_config():
	var file = FileAccess.open("res://chuncks/chuncks.json", FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var result = json.parse(json_text)
	if result == OK:
		chunks_data = json.data
	else:
		push_error("❌ Error al parsear el JSON: " + json.get_error_message())

func load_next_chunk():
	if chunk_index >= chunks_data.size():
		print("🎉 Todos los chunks generados.")
		return

	var config = chunks_data[chunk_index]
	var chunk = Node3D.new()
	chunk.name = "Chunk_%d" % chunk_index
	chunk.position.x = chunk_index * chunk_size

	# Plataformas estáticas
	for entry in config.get("platform", []):
		var pos = Vector3(entry["x"], entry["y"], 0)
		var p = prefab_static.instantiate()
		p.position = pos
		chunk.add_child(p)

	# Plataformas móviles
	for entry in config.get("mobile_platform", []):
		var pos = Vector3(entry["x"], entry["y"], 0)
		var m = prefab_moving.instantiate()
		m.position = pos
		m.direction = entry["direction"]
		m.speed = entry["speed"]
		chunk.add_child(m)

	# Cafés
	for entry in config.get("coffee", []):
		var pos = Vector3(entry["x"], entry["y"], 0)
		var cafe = prefab_coffee.instantiate()
		cafe.position = pos
		chunk.add_child(cafe)

	# Estalactitas
	for entry in config.get("stalactite", []):
		var pos = Vector3(entry["x"], entry["y"], 0)
		var e = prefab_stalactite.instantiate()
		e.position = pos
		chunk.add_child(e)

	# EndTrigger
	var trigger = Area3D.new()
	var shape = CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	shape.shape.extents = Vector3(1, 5, 1)
	trigger.name = "EndTrigger"
	trigger.add_child(shape)
	trigger.position = Vector3((chunk_size-5), 0, 0)
	trigger.connect("body_entered", Callable(self, "_on_trigger_entered"))
	chunk.add_child(trigger)

	# VisibleOnScreenNotifier3D
	var visibility = VisibleOnScreenNotifier3D.new()
	visibility.name = "VisibleOnScreenNotifier3D"
	visibility.position = Vector3((chunk_size+0.5), 0, 0)
	chunk.add_child(visibility)

	chunk_holder.add_child(chunk)
	current_chunk = chunk
	chunk_index += 1

func _on_trigger_entered(body):
	print("Entró algo al trigger: ", body.name)
	if body is Player:
		print("Es el jugador, cargando nuevo chunk")

		# Guardamos el chunk actual para borrarlo luego
		chunk_to_delete = current_chunk

		# Cargamos el siguiente chunk
		load_next_chunk()

		# Conectamos señal para borrar cuando ya no esté en cámara
		if chunk_to_delete.has_node("VisibleOnScreenNotifier3D"):
			var checker = chunk_to_delete.get_node("VisibleOnScreenNotifier3D")
			checker.connect("screen_exited", Callable(self, "_on_chunk_screen_exited"))
		else:
			print("❌ No se encontró VisibilityChecker")

func _on_chunk_screen_exited():
	if chunk_to_delete:
		print("🧹 Chunk salió de cámara, se borra: ", chunk_to_delete.name)
		chunk_to_delete.queue_free()
		chunk_to_delete = null
