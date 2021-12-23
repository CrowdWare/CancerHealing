extends Node2D

var drag_from = null
var drag_to = null
var lines = []
var energies = []
var started = false
var startTime = 0
var processedFrame = -1
var swipe_start = null
var level = 1
var enemy_delay = ENEMY_DELAY

const SPEED = 150
const MAX_LEVEL_COUNT = 7
const ENEMY_DELAY = 5


######
##
##  TODO: Goldhaufen, Wachtürme, 
##  zweifarbige Linen bei Gegenangriff
##
######

func _ready():
	loadLevel("Level" + str(level))
	var hand = $Level.get_node("Hand")
	if hand:
		hand.visible = true
	$StartButton.visible = true

func setDragTo(object):
	drag_to = object
	
func getDragTo():
	return drag_to

func setDragFrom(object):
	drag_from = object
	
func getDragFrom():
	return drag_from
	
func setEnemyDelay(delay):
	enemy_delay = delay

func drop(from, to):
	if not started:
		return
	addLine(from, to)

func addLine(from, to):
	# erst mal prüfen, ob line schon besteht
	if isAttacking(from, to) or isSupporting(from, to):
		return

	# line war schon da, allerdings in umgekehrter Reihenfolge
	var linesToDelete = []
	for line in lines:
		if line.from == to and line.to == from and line.from.typ == line.to.typ:
			line.from.channels = line.from.channels - 1
			linesToDelete.append(line)
			remove_child(line.obj)
			line.obj.queue_free()
			update()
	for line in linesToDelete:
		lines.erase(line)
			
	var line_obj = Line2D.new()
	line_obj.add_point(from.position)
	line_obj.add_point(to.position)
	var color = Gradient.new()
	var fc = from.getColor()
	color.set_color(0, fc)
	# make transparent
	fc.a = 0
	color.set_color(1, fc)
	line_obj.set_gradient(color)
	add_child(line_obj)
	var line = Line.new(line_obj, from, to)
	from.channels = from.channels + 1
	lines.append(line)
	update()
	
func _on_Button_pressed():
	# starten
	var hand = $Level.get_node("Hand")
	if hand:
		hand.visible = false

	$StartButton.visible = false
	$Undo.visible = true
	started = true
	startTime = OS.get_unix_time()

func _on_Weiter_pressed():
	# nächsten Level laden	
	$Weiter.visible = false
	$Sieg.visible = false
	processedFrame = -1
	if level < MAX_LEVEL_COUNT:
		level = level + 1
	# reset delay to default
	enemy_delay = ENEMY_DELAY
	loadLevel("Level" + str(level))
	var hand = $Level.get_node("Hand")
	if hand:
		hand.visible = true
	if level < MAX_LEVEL_COUNT:
		$StartButton.visible = true
	update()

func _on_NochMal_pressed():
	# level noch mal starten
	$NochMal.visible = false
	$Niederlage.visible = false
	$Undo.visible = true
	started = true
	startTime = OS.get_unix_time()
	processedFrame = -1
	loadLevel("Level" + str(level))
	update()
	

func _on_Undo_pressed():
	reset(false, false)

func loadLevel(lvl):
	var world = get_tree().get_root().get_node("World")
	var scene = load("res://" + lvl + ".tscn")
	var l = world.get_node("Level")
	world.remove_child(l)
	l.call_deferred("free")
	var levelInstance = scene.instance() 
	levelInstance.set_name("Level")
	world.add_child(levelInstance)

func _input(event):
	if not started:
		return

	if event is InputEventMouseButton:
		if event.pressed:
			swipe_start = event.position
		else:
			swipe_start = null
	if event is InputEventMouseMotion and swipe_start != null:
		for line in lines:
			if Geometry. segment_intersects_segment_2d(line.from.position, line.to.position, swipe_start, event.position):
				if line.from.typ == 1:
					line.from.channels = line.from.channels - 1
					lines.erase(line)
					remove_child(line.obj)
					line.obj.queue_free()
					update()

func _process(delta):
	if not started:
		return
	var curTime = OS.get_unix_time()
	var elapsed = curTime - startTime
	$FPS.set_text(str(Engine.get_frames_per_second()) + " FPS")

	# nach 5 Sekunden werden die Gegner auch aktiv
	if elapsed > enemy_delay and elapsed > processedFrame:
		for child in $Level.get_children():
			if child is StaticBody2D:	
				if child.typ > 1 and child.openGates() > 0:
					# enemy hat noch min. einen gate frei, mit dem er andocken kann
					var target = findNextTarget(child)
					if target:
						addLine(child,  target)
	
	# alle cellen schicken pro Sekunde eine neue energy los
	if elapsed > processedFrame:
		for line in lines:
			sendEnergy(line)
			if line.from.isSun:
				# sende eine zweite Energy bei einer Sonne
				var energy = sendEnergy(line)
				# die position etwas nach vorne verlagern, damit man beide Energien sehen kann
				var pos = energy.position.move_toward(energy.target.position, 0.06 * SPEED)
				energy.position = pos
		processedFrame = elapsed
	
	#alle energien bewegen
	for energy in energies:
		var pos = energy.position.move_toward(energy.target.position, delta * SPEED)
		
		#check collision
		var test = checkCollision(energy)
		if test != null:
			energies.erase(energy)
			energy.queue_free()
			energies.erase(test)
			test.queue_free()
			return
		
		# ziel fast erreicht, dann energy wieder löschen
		if Geometry.is_point_in_circle(pos, energy.target.position, 50):
			if energy.source_typ == energy.target.typ:
				if energy.target.count > 63:
					# diese Energy senden wir gleich weiter an alle Channels
					for line in lines:
						if line.from == energy.target:
							sendEnergy(line)
				else:
					energy.target.count = energy.target.count + 1
			else:
				energy.target.count = energy.target.count - 1
				if energy.target.count < 0:
					# Übernahme
					energy.target.typ = energy.source_typ
					energy.target.count = 1
					deleteLines(energy.target)
					correctLineColor(energy.source)
			energies.erase(energy)
			energy.queue_free()
		else:
			energy.position = pos
			
	var enemyCount = 0
	var playerCount = 0
	for child in $Level.get_children():
		if child is StaticBody2D:
			if child.typ == 1:
				playerCount = playerCount + 1
			elif child.typ > -1:
				enemyCount = enemyCount + 1
					
	if enemyCount == 0 or playerCount == 0:
		reset(enemyCount == 0, playerCount == 0)
	update()

func reset(won, lost):
	started = false
	for line in lines:
		remove_child(line.obj)
		line.obj.queue_free()
	lines.clear()
	for energy in energies:
		energy.queue_free()
	energies.clear()
	if won:
		$Sieg.visible = true
		$Weiter.visible = true
	else:
		if lost:
			$Niederlage.visible = true
		$NochMal.visible = true
	$Undo.visible = false
	
func sendEnergy(line):
	var energy = load("res://Energy.tscn")
	var obj = energy.instance()
	obj.get_node("Sprite").frame = line.from.typ - 1
	obj.position = line.from.position
	obj.source = line.from
	obj.target = line.to
	obj.source_typ = line.from.typ
	add_child_below_node(line.from, obj)
	energies.append(obj)
	return obj

func correctLineColor(cell):
	for line in lines:
		if line.from == cell:
			var color = Gradient.new()
			color.set_color(0, line.from.getColor())
			var tc = line.to.getColor()
			# make transparent
			tc.a = 0
			color.set_color(1, tc)
			line.obj.set_gradient(color)
		
func deleteLines(cell):
	var linesToDelete = []
	for line in lines:
		if line.from == cell:
			line.from.channels = line.from.channels - 1
			linesToDelete.append(line)
			remove_child(line.obj)
			line.obj.queue_free()
	for line in linesToDelete:
		lines.erase(line)
	update()
	
func checkCollision(en):
	for energy in energies:
		if energy != en and energy.source.typ != en.source.typ:
			if en.target == energy.source and en.source == energy.target:
				if Geometry.is_point_in_circle(en.position, energy.position, 40):
					return energy
	return null
	
func findTargets(cell):
	var targets = []
	for child in $Level.get_children():
		if child != cell and child is StaticBody2D:
			if child.typ > -1:
				if not pathHitsWall(cell, child):
					targets.append(child)
	return targets
	
func findNextTarget(cell):
	var bestTarget = null
	var targets = findTargets(cell)
	for target in targets:
		if not isAttacking(cell, target) and not isSupporting(target, cell) and not isSupporting(cell, target):
			if bestTarget == null:
				bestTarget = target
			elif bestTarget and target.count < bestTarget.count:
				bestTarget = target
	return bestTarget
	
func isAttacking(f, t):
	for line in lines:
		if line.from == f and line.to == t and line.from.typ != line.to.typ:
			return true
	return false

func isSupporting(f, t):
	for line in lines:
		if line.from == f and line.to == t and line.from.typ == line.to.typ:
			return true
	return false

func pathHitsWall(from, to):
	for child in $Level.get_children():
		if child is TileMap:
			for tile in child.get_used_cells():
				var pos = child.map_to_world(tile)
				pos.x = pos.x + 16
				pos.y = pos.y + 16
				var hit = Geometry.segment_intersects_circle(from.position, to.position, pos, 16)
				if hit > 0:
					return true
	return false


class Line:
	var from
	var to
	var obj

	func _init(o, f, t):
		from = f
		to = t
		obj = o

