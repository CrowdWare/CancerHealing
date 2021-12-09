extends Node2D

var drag_from = null
var drag_to = null
var lines = []
var energies = []
var started = false
var startTime = 0
var processedFrame = -1
var swipe_start = null

const SPEED = 150


func _ready():
	print("Hello world")
	loadLevel("Level2")

func setDragTo(object):
	drag_to = object
	
func getDragTo():
	return drag_to

func setDragFrom(object):
	drag_from = object
	
func getDragFrom():
	return drag_from
	
func drop(from, to):
	var line = Line.new(from, to, Color(0, 0, 255))
	from.channels = from.channels + 1
	lines.append(line)
	update()

func _draw():
	for line in lines:
		Global.draw_dashed_line(self, line.from.position, line.to.position, line.color, 15, 15)

func _on_Button_pressed():
	$StartButton.visible = false
	started = true
	startTime = OS.get_unix_time()

func _on_Weiter_pressed():
	$Weiter.visible = false
	$Sieg.visible = false
	# nächsten Level laden	
	started = true
	startTime = OS.get_unix_time()
	processedFrame = -1
	loadLevel("Level1")
	update()

func loadLevel(lvl):
	var world = get_tree().get_root().get_node("World")
	var scene = load("res://" + lvl + ".tscn")
	var level = world.get_node("Level")
	world.remove_child(level)
	level.call_deferred("free")
	var levelInstance = scene.instance() 
	levelInstance.set_name("Level")
	world.add_child(levelInstance)

func _input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			swipe_start = event.position
		else:
			swipe_start = null
	if event is InputEventMouseMotion and swipe_start != null:
		for line in lines:
			if Geometry. segment_intersects_segment_2d(line.from.position, line.to.position, swipe_start, event.position):
				line.from.channels = line.from.channels - 1
				lines.erase(line)
				update()

func _process(delta):
	if not started:
		return
	var curTime = OS.get_unix_time()
	var elapsed = curTime - startTime
	
	# alle cellen schicken pro Sekunde eine neue energy los
	if elapsed > processedFrame:
		for line in lines:
			var energy = load("res://Energy.tscn")
			var obj = energy.instance()
			if line.from.typ > 1:
				obj.get_node("Sprite").frame = 1
			obj.position = line.from.position
			obj.source = line.from
			obj.target = line.to
			add_child_below_node(line.from, obj)
			energies.append(obj)

		processedFrame = elapsed
	
	#alle energien bewegen
	for energy in energies:
		var pos = energy.position.move_toward(energy.target.position, delta * SPEED)
		# ziel erreicht, dann energy wieder löschen
		if pos == energy.target.position:
			if energy.source.typ == energy.target.typ:
				energy.target.count = energy.target.count + 1
			else:
				energy.target.count = energy.target.count - 1
				if energy.target.count < 0:
					energy.target.typ = energy.source.typ
					energy.target.count = 1
			energies.erase(energy)
			energy.queue_free()
		else:
			energy.position = pos
			
	var enemyCount = 0
	for child in $Level.get_children():
		if child is StaticBody2D:
			if child.typ != 1:
				enemyCount = enemyCount + 1
					
	if enemyCount == 0:
		started = false
		lines.clear()
		for energy in energies:
			energy.queue_free()
		energies.clear()
		$Sieg.visible = true
		$Weiter.visible = true
		

class Line:
	var from
	var to
	var color

	func _init(f, t, c):
		from = f
		to = t
		color = c
