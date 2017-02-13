extends Node2D


onready var global = get_node( "/root/global" )

func _ready():
	# calulate score
	var scorestr = global.calculate_score()
	var nazikills = global.score
	print( scorestr )
	print( nazikills )
	get_node( "GridContainer/L2" ).set_text( "%03d" % nazikills )
	get_node( "GridContainer/L4" ).set_text( "%05d" % scorestr )
	set_process_input( true )

func _input( event ):
	if Input.is_action_pressed( "btn_click" ):
		global.score = 0
		global.main.change_map( global.getLevelName() )
