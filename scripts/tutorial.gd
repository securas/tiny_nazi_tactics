extends Node2D

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

var state = 0
onready var timer = get_node( "../tutorialtimer" )
func run_tutorial():
	print( "tutorial state ", state )
	if state == 0:
		# show select tutorial
		state = 1
		print( "showing select tutorial. New state: ", state )
		get_node( "select_tutorial" ).show()
		timer.set_wait_time( 3 )
		timer.start()
	elif state == 1:
		get_node( "select_tutorial" ).hide()
		# show move tutorial
		get_node( "move_tutorial" ).show()
		timer.set_wait_time( 3 )
		timer.start()
		state = 2
	elif state == 2:
		get_node( "move_tutorial" ).hide()
		# show move tutorial
		get_node( "attack_tutorial" ).show()
		timer.set_wait_time( 3 )
		timer.start()
		state = 3
	elif state == 3:
		get_node( "attack_tutorial" ).hide()
		state = 0
	print( "Leaving with state: ", state )



func _on_tutorialtimer_timeout():
	print( "tutorial timeout ", state )
	run_tutorial()
