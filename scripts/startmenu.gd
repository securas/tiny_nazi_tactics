extends Node2D
onready var global = get_node( "/root/global" )

func _ready():
	global.total_score = 0
	get_node( "Label1/anim" ).play( "flash" )
	# music maestro
	global.main.change_song( global.main.menu_song )
	# wait for user
	set_process_input( true )

func _input( event ):
	if Input.is_action_pressed( "btn_click" ):
		global.score = 0
		global.main.change_map( "level 1" )
