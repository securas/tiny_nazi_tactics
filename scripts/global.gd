extends Node

var main = null
var Debug = true
signal timer_expired
signal allies_win
signal nazis_win
var LevelNo = 0
var LevelNames = [ 'startmenu', 'level 1', "level 2", "level 3", "level 4", "level 5", "level 6", "ending" ]



func _ready():
	# random stuff
	randomize()
	
	# main scene
	var _root = get_tree().get_root()
	main = _root.get_child( _root.get_child_count() - 1 )
	
	# center screen
	var screen_size = OS.get_screen_size( 0 )
	var window_size = OS.get_window_size()
	OS.set_window_position( screen_size * 0.5 - window_size * 0.5 )
	
	# start process
	set_process( true )

var nnazis
var nallies
func _process( delta ):
	# hit Esc to quit
	if Input.is_key_pressed( KEY_ESCAPE ):
		get_tree().quit()
	# count time
	if timer_running:
		# count men
		var aux = main.get_tree().get_nodes_in_group( "nazis_man" )
		nnazis = aux.size()
		main.get_node( "HUD_Layer/hud/GridContainer/nazi_casualties" ).set_text( "%03d" % [ nnazis ] )
		aux = main.get_tree().get_nodes_in_group( "allies_man" )
		nallies = aux.size()
		main.get_node( "HUD_Layer/hud/GridContainer/allied_casualties" ).set_text( "%03d" % [ nallies ] )
		
		runtime -= delta
		if runtime <= 0:
			emit_signal( "timer_expired" )
			timer_running = false
		else:
			var minutes = floor( runtime / 60 )
			var seconds = floor( runtime - minutes * 60 )
			main.get_node( "HUD_Layer/hud/GridContainer/time" ).set_text( "%02d:%02d" % [ minutes, seconds ] )
		if nnazis <= 0:
			emit_signal( "allies_win" )
			timer_running = false
		elif nallies <= 0:
			emit_signal( "nazis_win" )
			timer_running = false

func man_down( p ):
	if p.is_in_group( "nazis_man" ):
		score += 1
	return

func man_up( p ):
	return
	

var timer_running = false
var runtime = 100
var initial_time = 100
func set_timer( max_time ):
	runtime = max_time
	initial_time = max_time
	var minutes = floor( runtime / 60 )
	var seconds = runtime % 60
	main.get_node( "HUD_Layer/hud/GridContainer/time" ).set_text( "%02d:%02d" % [ minutes, seconds ] )
func start_timer():
	timer_running = true


var score = 0
var total_score = 0
func calculate_score():
	total_score += round( score / ( initial_time - runtime ) * 1000 )
	return total_score




func resetLevel():
	LevelNo = 0
func setLevel( n ):
	LevelNo = n
func setNextLevel():
	LevelNo += 1
	if LevelNo >= LevelNames.size():
		LevelNo = 0
func getLevelName():
	return LevelNames[LevelNo]


