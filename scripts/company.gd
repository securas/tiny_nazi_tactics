extends Area2D

onready var global = get_node( "/root/global" )

# states
var cur_state = ""
var nxt_state = "idle"
var is_selected = false

# update rate
const UPDATEPERIOD = 0.25
var elapsedtime = 0

# areas
var area = [ Vector2( 10000, 10000 ), Vector2( -10000, -10000 ) ]
var attack_area = [ Vector2(), Vector2() ]
const ATTACKRANGE = Vector2( 50, 50 )

# germans or allies
var is_allied = true

# instancing men
var man_scn = preload( "res://scenes/man.tscn" )
var men = []
var formation_pos = []
export var size = Vector2( 10, 10 )
export var separation = Vector2( 10, 10 )
#var enemy_container = null
export var men_speed = 80
export( String, "allies", "nazis" ) var groupname = "allies"
var enemygroupname = ""
var group = ""
var enemygroup = ""

# motion
const REACH_RANGE2 = 2500
onready var nav = get_parent().get_parent().get_node( "navigation" )

# attack
var attack_on_sight = true
var attack_target = null

func _ready():
	# group
	group = groupname + "_company"
	if groupname == "allies":
		enemygroupname = "nazis"
	else:
		enemygroupname = "allies"
	enemygroup = enemygroupname + "_company"
	add_to_group( group )
	# instance men
	_instance_men()
	# level control
	get_parent().get_parent().connect( "start_game", self, "_start_game" )
	get_parent().get_parent().connect( "end_game", self, "_end_game" )

func _start_game():
	set_fixed_process( true )
func _end_game():
	set_fixed_process( false )

func set_men_speed(men_speed):
	for m in men:
		m.VELOCITY = men_speed

#-----------------------------
# fixed process
#-----------------------------
func _fixed_process( delta ):
	# update areas
	_update_areas()
	
	# debugging
	if global.Debug: update()
	
	elapsedtime += delta
	if elapsedtime > UPDATEPERIOD: elapsedtime -= UPDATEPERIOD
	else: return
	
	# attack on sight
	if attack_on_sight:
		# Used to move and attack anything on sight
		_attack_nearby_companies()
		pass
	elif attack_target != null:
		
		# check if target still exists
		if not weakref( attack_target ).get_ref():
			# the target is gone... go back to default state
			attack_target = null
			attack_on_sight = true
			return
		# used to attack a specific target and ignore everything else
		var aux = attack_target.get_pos() - get_pos()
		#print( "Distance to target: ", aux.length() )
		if not _attack_nearby_companies():
			#print( "moving" )
			
			#_move_men( [ attack_target._get_most_distant_man_pos( get_pos() ) ] )
			_move_men( [ attack_target.get_global_pos() ] )
		pass
	

#-----------------------------
# state functions
#-----------------------------
var ignore_attack = false
func move_to( pos_stack ):
	# clear any target
	attack_on_sight = false
	attack_target = null
	ignore_attack = true
	for m in men: m.stop_attack()
	# move men
	_move_men( pos_stack )

func attack_to( pos_stack ):
	ignore_attack = false
	attack_on_sight = true
	attack_target = null
	# move men
	_move_men( pos_stack )

func attack_company( c ):
	ignore_attack = true
	attack_on_sight = false
	attack_target = c
	_move_men( [ attack_target.get_global_pos() ] )

func _move_men( move_target_stack ):
	for m in men:
		var path = Vector2Array()
		# cicle move stack and compute all paths
		var t0 = m.get_pos()
		var aux
		for t in move_target_stack:
			aux = nav.get_simple_path( t0, t + m.formation_pos, true )
			aux.remove( 0 )
			path += aux
			t0 = t + m.formation_pos
		# send path to men
		m.move_to( path )




func _attack_nearby_companies():
	var nearby_companies = _get_enemy_area_in_range()
	if nearby_companies.size() == 0:
		for m in men:
			m.stop_attack()
		return false
	else:
		var area = null
		if attack_target != null:
			for a in nearby_companies:
				if a == attack_target:
					area = a
					break
			if area == null:
				for m in men: m.stop_attack()
				return false
			return _send_man_to_fight( area )
		else:
			var is_attacking = false
			for area in nearby_companies:
				var aux = _send_man_to_fight( area )
				if aux:
					is_attacking = true
			return is_attacking
func _send_man_to_fight( area ):
	var is_attacking = false
	for m in men:
		var dist
		var distlen2 = 0
		var mindist2 = 10000000
		var mindir = null
		for n in area.men:
			dist = n.get_pos() - m.get_pos()
			distlen2 = dist.length_squared()
			if  distlen2 < mindist2:
				mindist2 = distlen2
				mindir = dist
		if mindist2 <= 2 * REACH_RANGE2:
			m.start_attack( mindir.normalized(), area )
			is_attacking = true # at least one man is attacking
		else:
			m.stop_attack()
	if is_attacking: area._attack_alert( self )
	return is_attacking
#-----------------------
# respond to atack
#-----------------------
func _attack_alert( area ):
	#if not attack_on_sight and attack_target != null:
	#	return # ignore attack
	if ignore_attack: return
	self.attack_company( area )




#-----------------------------
# find enemy areas in range
#-----------------------------
func _get_enemy_area_in_range():
	# isolate enemy companies
	#var enemy_units = enemy_container.get_children()
	var enemy_units = get_tree().get_nodes_in_group( enemygroup )
	var enemy_companies_in_range = []
	for m in enemy_units:
		if m extends get_script():
			if _is_overlapping( self.attack_area, m.attack_area ):
			#if _is_overlapping( self.area, m.area ):
				enemy_companies_in_range.append( m )
	return enemy_companies_in_range
	pass
func _is_overlapping( a1, a2 ):
	if a1[0].x > a2[1].x or a2[0].x > a1[1].x:
		return false
	if a1[0].y > a2[1].y or a2[0].y > a1[1].y:
		return false
	return true

# To attack, get most distant man in area
func _get_most_distant_man_pos( p ):
	var maxdist = 0
	var farthestman = null
	for m in men:
		var dir = m.get_pos() - p
		var dist = dir.length_squared()
		if dist > maxdist:
			maxdist = dist
			farthestman = m
	return farthestman.get_pos()

#-----------------------------
# instance men
#-----------------------------
func _instance_men():
	var curpos = get_pos()
	for ny in range( size.y ):
		for nx in range( size.x ):
			var relpos = Vector2( ( nx - ( size.x - 1 ) / 2 ) * separation.x, ( ny - ( size.y - 1 ) / 2 ) * separation.y ) 
			var m = man_scn.instance()
			m.set_pos( relpos + curpos )
			m.formation_pos = relpos
			m.company = self
			if groupname != "allies": m.is_allied = false
			m.add_to_group( groupname + "_man" )
			#print( ( groupname + "_man" ) )
			#print( m.get_groups() )
			get_parent().call_deferred( "add_child", m )
			men.append( m )
	_update_areas()
#-----------------------------
# recalculate formation
#-----------------------------
func _reset_formation_pos():
	var nmen = men.size()
	formation_pos = []
	var size_y
	if nmen > ( 2 * size.y ):
		size_y = size.y
	else:
		size_y = ceil( sqrt( nmen ) )

	var nrows = ceil( nmen / size_y )
	#print( " new formation: ", nrows, "x", size_y )
	var idx = 0
	for ny in range( size_y ):
		for nx in range( nrows ):
			var relpos = Vector2( ( nx - ( nrows - 1 ) / 2 ) * separation.x, ( ny - ( size_y - 1 ) / 2 ) * separation.y )
			men[idx].formation_pos = relpos
			idx += 1
			if idx >= men.size(): return
#-----------------------------
# remove men
#-----------------------------
func rmvmen( m ):
	var idx = men.find( m )
	if idx != -1:
		men.remove( idx )
		_reset_formation_pos()
	if men.size() == 0:
		queue_free()

#-----------------------------
# update areas according to position of men
#-----------------------------
func _update_areas():
	var mpos
	var center = Vector2( 0, 0 )
	area = [ Vector2( 10000, 10000 ), Vector2( -10000, -10000 ) ]
	for m in men:
		mpos = m.get_pos()
		# update center
		center += mpos
		# update corners
		area[0].x = min( area[0].x, mpos.x )
		area[0].y = min( area[0].y, mpos.y )
		area[1].x = max( area[1].x, mpos.x )
		area[1].y = max( area[1].y, mpos.y )
	center /= float( men.size() )
	# move area
	set_pos( center )
	# set attack area
	attack_area = [ area[0] - ATTACKRANGE, area[1] + ATTACKRANGE ]
	
	pass


#-----------------------------
# draw areas for debugging
#-----------------------------
func _draw():
	return
	var cpos = get_pos()
	var p1 = area[0] - cpos
	var p2 = area[1] - cpos
	var ct = Color( 1, 1, 1, 0.3 )
	#draw_line( p1, Vector2( p2.x, p1.y ), ct, 2 )
	#draw_line( Vector2( p2.x, p1.y ), p2, ct, 2 )
	#draw_line( p2, Vector2( p1.x, p2.y ), ct, 2 )
	#draw_line( Vector2( p1.x, p2.y ), p1, ct, 2 ) 
	
	p1 = attack_area[0] - cpos
	p2 = attack_area[1] - cpos
	draw_line( p1, Vector2( p2.x, p1.y ), ct, 0.1 )
	draw_line( Vector2( p2.x, p1.y ), p2, ct, 0.1 )
	draw_line( p2, Vector2( p1.x, p2.y ), ct, 0.1 )
	draw_line( Vector2( p1.x, p2.y ), p1, ct, 0.1 )
	if not is_selected: return
	var polyarea = Vector2Array()
	polyarea.append( p1 )
	polyarea.append( Vector2( p2.x, p1.y ) )
	polyarea.append( p2 )
	polyarea.append( Vector2( p1.x, p2.y ) )
	
	draw_colored_polygon( polyarea, Color( 1, 1, 1, 0.2 ) )
	
	#draw_circle( Vector2( 0, 0 ), 5, Color( 1, 0, 0, 0.5 ) )
	#if attack_target != null:
	#	if weakref( attack_target ).get_ref():
	#		draw_circle( attack_target.get_pos() - cpos, 5, Color( 0, 1, 0, 0.5 ) )
	#		draw_line( Vector2( 0, 0 ), attack_target.get_pos() - cpos, Color( 1, 1, 0 ) )
	