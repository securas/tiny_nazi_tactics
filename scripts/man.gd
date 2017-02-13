extends KinematicBody2D
onready var global = get_node( "/root/global" )
# company
var formation_pos = Vector2( 0, 0 )
var velocity = Vector2( 0, 0 )
var company = null

# motion states
var motion_state_nxt = "idle"
var motion_state = ""

# move
var VELOCITY = 80
var motion_target_stack = []

# attack
var attack = false
var attack_dir = Vector2()
#var attack_on_sight = true
var bullet_scn = preload( "res://scenes/bullet.tscn" )
var attack_target = null
var attacktime = 0
const ATTACKPERIOD = 1
var area_under_attack = null

# health and fear
var health = 100
var fear = 0

# is allied
var is_allied = true

# animations
var cur_anim = ""
var nxt_anim = "idle"

func _ready():
	if not is_allied: 
		get_node( "sprite" ).set_texture( load( "res://gameart/german_version.png" ) )
		get_node( "sprite" ).set_flip_h( true )
	set_fixed_process( true )
	global.man_up( self )

func _fixed_process( delta ):
	# update states
	motion_state = motion_state_nxt
	
	# check attack
	if attack:
		# attack period
		attacktime += delta
		if attacktime < ( ATTACKPERIOD + rand_range( -ATTACKPERIOD, 0 ) ): return
		attacktime -= ATTACKPERIOD
		# fire bullet
		_fire_bullet()
		nxt_anim = "idle"
	else:
		if motion_state == "idle":
			nxt_anim = "idle"
			pass
		elif motion_state == "move":
			nxt_anim = "walk_right"
			_state_move( delta )
	
	# manage animation
	if nxt_anim != cur_anim:
		cur_anim = nxt_anim
		get_node( "anim" ).play( cur_anim )
		if is_allied:
			get_node( "anim" ).seek( rand_range( 0, 0.3 ) )




func move_to( motion_target_stack ):
	self.motion_target_stack = motion_target_stack
	motion_state_nxt = "move"

var direction = Vector2( 0, 0 )
var motion = Vector2( 0, 0 )
var prev_motion
func _state_move( delta ):
	direction = motion_target_stack[0] - get_global_pos() #get_pos()
	velocity = direction.normalized() * VELOCITY
	prev_motion = motion.x
	motion = velocity * delta
	var x = move( motion )
	if is_colliding():
		var n = get_collision_normal()
		motion = n.slide( motion )
		x = move( motion )
	#if get_name() == "man": print( velocity )
	if prev_motion < 0 and motion.x > 0:
		get_node( "sprite" ).set_flip_h( false )
	elif prev_motion > 0 and motion.x < 0:
		get_node( "sprite" ).set_flip_h( true )
	var distance_to_target = motion_target_stack[0] - get_pos()
	if distance_to_target.length_squared() < 10:
		if motion_target_stack.size() == 1:
			# reached final target
			motion_target_stack = []
			velocity = Vector2( 0, 0 )
			motion_state_nxt = "idle"
		else:
			# reached intermetiate target
			motion_target_stack.remove(0) # remove current target from stack

var target_direction
func start_attack( target_direction, area ):
	self.target_direction = target_direction
	attack = true
	area_under_attack = area
	pass
func stop_attack():
	attack = false
	area_under_attack = null
	pass

func _fire_bullet():
	var b = bullet_scn.instance()
	b.set_pos( get_pos() )
	b.velocity = target_direction
	b.is_allied = is_allied
	get_parent().call_deferred( "add_child", b )
	pass






var is_dying = false
func _die():
	if is_dying: return
	is_dying = true
	company.rmvmen( self )
	global.man_down( self )
	queue_free()
	
onready var spr = get_node( "sprite" )
func _on_area_area_enter( area ):
	var p = area.get_parent()
	if not p.has_method( "get_damage" ): return
	if p.is_allied == is_allied: return
	health -= p.get_damage()
	#print( "getting damage: ", health )
	if health <= 0:
		_die()
	elif health <= 30:
		spr.set_modulate( Color( 1, 0, 0 ) )
	elif health <= 50:
		spr.set_modulate( Color( 1, 1, 0 ) )
	p.queue_free()
	pass # replace with function body

