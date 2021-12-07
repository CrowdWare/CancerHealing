extends Node2D

var drag_from = null
var drag_to = null
var lines = []
var energies = []
var started = false
var startTime = 0
var processedFrame = -1

const SPEED = 150

func _ready():
	print("Hello world")

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
			obj.position = line.from.position
			obj.target = line.to
			add_child_below_node(line.from, obj)
			energies.append(obj)

		print(elapsed)	
		processedFrame = elapsed
	
	#alle energien bewegen
	for energy in energies:
		var pos = energy.position.move_toward(energy.target.position, delta * SPEED)
		# ziel erreicht, dann energy wieder löschen
		if pos == energy.target.position:
			energy.target.count = energy.target.count + 1
			energies.erase(energy)
			energy.queue_free()
		else:
			energy.position = pos
		

class Line:
	var from
	var to
	var color

	func _init(f, t, c):
		from = f
		to = t
		color = c
