extends Node2D

var drag_from = null
var drag_to = null


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
	var fc = from.getCount()
	var tc = to.getCount()
	from.setCount(fc - 1)
	to.setCount(tc + 1)
	print(from, to)
