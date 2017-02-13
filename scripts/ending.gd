extends Node2D


func _ready():
	global.main.change_song( global.main.end_song, true )
	get_node( "anim" ).play( "scr" )
	get_node( "anim" ).connect( "finished", self, "_on_play_finished" )
	get_node( "Timer" ).set_wait_time( 5 )

func _input( event ):
	if Input.is_action_pressed( "btn_click" ):
		_on_play_finished()

func _on_play_finished():
	global.resetLevel()
	global.main.change_map( "startmenu" )


func _on_Timer_timeout():
	set_process_input( true )
