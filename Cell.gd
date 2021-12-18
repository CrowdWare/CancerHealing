extends StaticBody2D

var dragging = false
var dragHitsWallOrPlayer = false
var orig
var drag_pos
var channels = 0 setget setChannels

onready var focus = $Focus
onready var world = get_tree().get_root().get_node("World")

export var count = 0 setget setCount
export var typ = 0 setget setTyp
export var isSun = false setget setSun

func setSun(s):
	isSun = s
	$Sun.visible = s

func openGates():
	if count > 29:
		return 3 - channels
	elif count > 9:
		return 2 - channels
	elif count > 0:
		return 1 - channels
	else:
		return 0
	
func setTyp(t):
	typ = t
	if typ == 0:
		$Sprite.frame = 0 # gray
	elif typ == 1:
		$Sprite.frame = 1 # blue
	elif typ == 2:
		$Sprite.frame = 2 # green
	elif typ == 3:
		$Sprite.frame = 3 # red
	elif typ == 4:
		$Sprite.frame = 4 # yellow

func setCount(c):
	count = c
	if count > 63:
		$Count.text = "MAX"
	else:
		$Count.text = str(count)
	refreshGates()
	
func refreshGates():
	$Gate1_close.visible = false
	$Gate1_open.visible = false
	$Gate2_close.visible = false
	$Gate2_open.visible = false
	$Gate3_close.visible = false
	$Gate3_open.visible = false
	
	if count > 29:
		$Gate1_close.visible = true
		$Gate1_open.visible = true
		$Gate2_close.visible = true
		$Gate2_open.visible = true
		$Gate3_close.visible = true
		$Gate3_open.visible = true
		if channels > 0:
			$Gate3_open.visible = false
		if channels > 1:
			$Gate2_open.visible = false
		if channels > 2:
			$Gate1_open.visible = false

	elif count > 9:
		$Gate1_close.visible = true
		$Gate1_open.visible = true
		$Gate3_close.visible = true
		$Gate3_open.visible = true
		if channels > 0:
			$Gate3_open.visible = false
		if channels > 1:
			$Gate1_open.visible = false

	elif count > 0:
		$Gate2_close.visible = true
		$Gate2_open.visible = true
		if channels > 0:
			$Gate2_open.visible = false

func setChannels(c):
	channels = c
	refreshGates()

func getCount():
	return count
	
func hasOpenChannel():
	var m = 0
	if count > 0:
		m = m + 1
	if count > 9:
		m = m + 1
	if count > 29:
		m = m + 1
	return m - channels > 0

func _mouse_enter():
	var obj = world.getDragFrom()
	if obj and obj != self and not obj.dragHitsWallOrPlayer:
		focus.visible = true
		world.setDragTo(self)
	
func _mouse_exit():
	focus.visible = false
	world.setDragTo(null)

func _input_event(_viewport, event, _shape_idx):
	if not world.started or typ != 1:
		return

	if event is InputEventMouseButton:
		if event.pressed and hasOpenChannel():
			dragging = true
			orig = get_global_mouse_position()
			world.setDragFrom(self)
			world.swipe_start = null
		
func _input(event):
	if event is InputEventMouseButton and not event.pressed:
		focus.visible = false
		dragging = false
		var from = world.getDragFrom()
		var to = world.getDragTo()
		if to and to != self:
			world.setDragTo(null)
			world.setDragFrom(null)
			world.drop(from, to)

func _process(_delta):
	if Input.is_mouse_button_pressed(BUTTON_LEFT):
		drag_pos = get_global_mouse_position()
	update()

func _draw():
	if dragging:
		if dragHitsWall() or dragThroughPlayer():
			dragHitsWallOrPlayer = true
			Global.draw_dashed_line(self, Vector2(0,0), Vector2(drag_pos.x - orig.x, drag_pos.y - orig.y), Color(.5, .5, .5), 15, 15)
		else:
			dragHitsWallOrPlayer = false
			Global.draw_dashed_line(self, Vector2(0,0), Vector2(drag_pos.x - orig.x, drag_pos.y - orig.y), Color(0, 0, 1), 15, 15)

func dragHitsWall():
	for child in world.get_node("Level").get_children():
		if child is TileMap:
			for tile in child.get_used_cells():
				var pos = child.map_to_world(tile)
				pos.x = pos.x + 16
				pos.y = pos.y + 16
				var hit = Geometry.segment_intersects_circle(self.position, drag_pos, pos, 16)
				if hit > 0:
					return true
	return false
	
func dragThroughPlayer():
	for child in world.get_node("Level").get_children():
		if child is StaticBody2D:
			if child != self:
				var intersects = Geometry.segment_intersects_circle(self.position, drag_pos, child.position, 40)
				var hit = Geometry.is_point_in_circle(drag_pos, child.position, 40)
				if intersects > 0 and hit == false:
					return true
	return false
