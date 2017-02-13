extends Node2D

onready var global = get_node( "/root/global" )

func _ready():
	set_process_input( true )

func _input( event ):
	if Input.is_action_pressed( "btn_click" ):
		global.main.change_map( "startmenu" )

func _on_timer_timeout():
	global.main.change_map( "startmenu" )
