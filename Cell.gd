extends StaticBody2D

var dragging = false
var orig
var drag_pos
var channels = 0 setget setChannels

onready var focus = $Focus
onready var world = get_parent()

export var count = 0 setget setCount
export var typ = 0 setget setTyp
	
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
	
	if count > 0:
		$Gate1_close.visible = true
		$Gate1_open.visible = true
	if count > 9:
		$Gate2_close.visible = true
		$Gate2_open.visible = true
	if count > 29:
		$Gate3_close.visible = true
		$Gate3_open.visible = true
		
	if channels > 0:
		$Gate1_open.visible = false
		
	if channels > 1:
		$Gate2_open.visible = false
		
	if channels > 2:
		$Gate3_open.visible = false

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
	if obj and obj != self:
		focus.visible = true
		world.setDragTo(self)
	
func _mouse_exit():
	focus.visible = false
	world.setDragTo(null)

func _input_event(_viewport, event, _shape_idx):
	if not world.started:
		return

	if event is InputEventMouseButton:
		if event.pressed and hasOpenChannel():
			dragging = true
			orig = get_global_mouse_position()
			world.setDragFrom(self)
		
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
		Global.draw_dashed_line(self, Vector2(0,0), Vector2(drag_pos.x - orig.x, drag_pos.y - orig.y), Color(0, 0, 255), 15, 15)

