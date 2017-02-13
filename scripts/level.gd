extends Node2D
onready var global = get_node( "/root/global" )
var input_states = preload( "res://scripts/input_states.gd" )
var btn_click = input_states.new( "btn_click" )
var right_click = input_states.new( "right_click" )
var selected_company = null
export(int) var available_time = 10
export(int) var levelno = 1
signal start_game
signal end_game

func _ready():
	polyanim.play( "stop" )
	# set level number
	global.setLevel( levelno )
	
	# set time
	global.set_timer( available_time )
	global.connect( "timer_expired", self, "_timer_expired" )
	# connect to global
	global.connect( "allies_win", self, "_allies_win" )
	global.connect( "nazis_win", self, "_nazis_win" )
	
	# wait for main
	yield( global.main, "level_start" )
	
	# start music
	global.main.change_song( global.main.main_song, true )
	
	# play level annoucer
	get_node( "anoucing_layer/anouncer" ).set_anounce( "Level %d" % levelno )
	yield( get_node( "anoucing_layer/anouncer" ), "annoucement_done" )
	
	# start timer
	global.start_timer()
	# start game
	emit_signal( "start_game" )
	set_fixed_process( true )
	
	# check if there is a tutorial
	var tut = get_node( "tutoriallayer" )
	if tut:
		get_node( "tutoriallayer/tutorial" ).run_tutorial()
	pass

func _timer_expired():
	print( "timer expired" )
	set_fixed_process( false )
	emit_signal( "end_game" )
	get_node( "anoucing_layer/anouncer" ).set_anounce( "Timer\nExpired" )
	yield( get_node( "anoucing_layer/anouncer" ), "annoucement_done" )
	global.resetLevel()
	global.main.change_map( "scores" )
	pass

func _allies_win():
	print( "allies win" )
	set_fixed_process( false )
	emit_signal( "end_game" )
	get_node( "anoucing_layer/anouncer" ).set_anounce( "Level\nPassed" )
	yield( get_node( "anoucing_layer/anouncer" ), "annoucement_done" )
	global.setNextLevel()
	global.main.change_map( "scores" )
	pass

func _nazis_win():
	print( "nazis win" )
	set_fixed_process( false )
	emit_signal( "end_game" )
	get_node( "anoucing_layer/anouncer" ).set_anounce( "Game\nOver!!!" )
	yield( get_node( "anoucing_layer/anouncer" ), "annoucement_done" )
	global.resetLevel()
	global.main.change_map( "scores" )
	pass

var highlight = false
var highlight_new = true
onready var poly = get_node( "highlightlayer/highlight" )
onready var polyanim = get_node( "highlightlayer/anim" )
func _fixed_process( delta ):
	#selected_company.nxt_state ="guard"
	if selected_company != null and not weakref( selected_company ).get_ref():
		selected_company = null
	# check player input
	if btn_click.check() == 1:
		# move or select company - currently only move
		var c = _find_company_under_mouse( get_global_mouse_pos(), "allies_company" )
		#print( "Selected Company: ", selected_company )
		#print( "Selection: ", c )
		if c.size() == 0 and selected_company == null:
			# click without selecting
			return
		elif c.size() == 0 and selected_company != null:
			# move selected to empty space
			selected_company.move_to( [ get_global_mouse_pos() ] )
			highlight = true
			highlight_new = true
		elif c.size() == 1 and selected_company == null:
			selected_company = c[0]
			selected_company.is_selected = true
			highlight = true
			highlight_new = true
		elif c.size() == 1 and selected_company != null:
			# clicked one company with another selected
			if c[0] == selected_company:
				# highligh company again
				highlight = true
				highlight_new = true
			else:
				# clicked another company
				selected_company.is_selected = false
				selected_company = c[0]
				selected_company.is_selected = true
				highlight = true
				highlight_new = true
		elif c.size() > 1 and selected_company == null:
			# select one of the companies
			selected_company = c[0]
			selected_company.is_selected = true
			highlight = true
			highlight_new = true
		elif c.size() > 1 and selected_company != null:
			# select the other company
			selected_company.is_selected = false
			for n in c: if n != selected_company: selected_company = n
			selected_company.is_selected = true
			highlight = true
			highlight_new = true
		#elif c.size() == 1 and selected_company == c[0]:
		#	selected_company.move_to( [ get_global_mouse_pos() ] )
		#	highlight = true
		#	highlight_new = true
		#elif c.size() != 0:
		#	if selected_company != null: 
		#		for n in c:
		#			if n != selected_company:
		#				selected_company.is_selected = false
		#				selected_company = n
		#				break
		#		get_node( "highlightlayer/highlight_timer" ).stop()
		#	else:
		#		selected_company = c[0]
		#	selected_company.is_selected = true
		#	highlight = true
	elif right_click.check() == 1:
		var c = _find_company_under_mouse( get_global_mouse_pos(), "nazis_company" )
		if c.size() == 0 and selected_company != null:
			selected_company.attack_to( [ get_global_mouse_pos() ] )
		elif c.size() != 0 and selected_company != null:
			selected_company.attack_company( c[0] )
	
	if highlight:
		var p1 = selected_company.area[0] - Vector2( 10, 27 )
		var p2 = selected_company.area[1] + Vector2( 10, 6 )
		var polyarea = Vector2Array()
		polyarea.append( p1 )
		polyarea.append( Vector2( p2.x, p1.y ) )
		polyarea.append( p2 )
		polyarea.append( Vector2( p1.x, p2.y ) )
		poly.set_polygon( polyarea )
		if highlight_new:
			highlight_new = false #only first time
			polyanim.play( "flash", -1, 4 )
			get_node( "highlightlayer/highlight_timer" ).set_wait_time( 1 )
			get_node( "highlightlayer/highlight_timer" ).start()
		
		

func _find_company_under_mouse( pos, groupname ):
	var companies = []
	var m = get_tree().get_nodes_in_group( groupname )
	for a in m:
		#if pos.x > a.attack_area[0].x and pos.x < a.attack_area[1].x and pos.y > a.attack_area[0].y and pos.y < a.attack_area[1].y:
		var areax = [ a.area[0] - Vector2( 10, 27 ), a.area[1] + Vector2( 10, 6 ) ]
		if pos.x > areax[0].x and pos.x < areax[1].x and pos.y > areax[0].y and pos.y < areax[1].y:
			companies.append( a )
	return companies
	
	pass





func _on_highlight_timer_timeout():
	polyanim.play( "stop" )
	highlight = false
	pass # replace with function body
