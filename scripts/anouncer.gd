extends Node2D

signal annoucement_done

func _ready():
	hide()

var state = 0
var curstr = ""
onready var anim = get_node( "anim" )
onready var timer = get_node( "animtimer" )
func set_anounce( labelstr ):
	if state == 0:
		curstr = labelstr
		# play out animation
		anim.play( "out" )
		# show
		show()
		# set label text
		get_node( "fader/label" ).set_text( labelstr )
		# fade in
		anim.play( "fade_in" )
		timer.set_wait_time( 0.3 )
		timer.start()
		state = 1
	elif state == 1:
		# wait for user
		set_process_input( true )
		state = 2
	elif state == 2:
		# fade out
		anim.play( "fade_out" )
		timer.set_wait_time( 0.3 )
		timer.start()
		state = 3
	elif state == 3:
		# hide verything
		hide()
		emit_signal( "annoucement_done" )
		state = 0
	
func _input( event ):
	if Input.is_action_pressed( "btn_click" ):
		set_process_input( false )
		set_anounce( curstr )
	

func _on_animtimer_timeout():
	set_anounce( curstr )
