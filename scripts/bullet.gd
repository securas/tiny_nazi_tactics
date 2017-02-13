extends KinematicBody2D

var velocity = Vector2( 0, 0 )
const MAX_VELOCITY = 80
const LIFETIME = 1.5
const DAMAGE = 30
var is_allied = true

func _ready():
	set_fixed_process( true )
var elapsedtime = 0
func _fixed_process( delta ):
	var motion = velocity * delta * MAX_VELOCITY
	move( motion )
	elapsedtime += delta
	if is_colliding() or elapsedtime >= LIFETIME:
		queue_free()

func get_damage():
	return DAMAGE


func _on_Area2D_area_enter( area ):
	
	if ( not area.get_parent() extends preload( "res://scripts/man.gd" ) ) and ( not area.get_parent() extends get_script() ):
		queue_free()
	pass # replace with function body
