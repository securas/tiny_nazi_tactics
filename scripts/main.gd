extends Node2D

onready var global = get_node( "/root/global" )
onready var loadtimer = get_node( "loadtimer" )
onready var mapobj = get_node( "map" )
var state = 0
var cur_map = ""
signal level_start

var stages = { \
	"credits" : "res://scenes/credits.tscn", \
	"startmenu" : "res://scenes/startmenu.tscn", \
	"scores" : "res://scenes/scores.tscn", \
	"level 1" : "res://scenes/level_1.tscn", \
	"level 2" : "res://scenes/level_2.tscn", \
	"level 3" : "res://scenes/level_3.tscn", \
	"level 4" : "res://scenes/level_4.tscn", \
	"level 5" : "res://scenes/level_5.tscn", \
	"level 6" : "res://scenes/level_6.tscn", \
	"ending" : "res://scenes/ending.tscn" }

var main_song
var menu_song
var win_song
var loose_song
var end_song
func _ready():
	# Load songs
	menu_song = load( "res://gameart/nene - OpenGameArt/boss_battle.ogg" )
	main_song = load( "res://gameart/nene - OpenGameArt/boss_battle_#2.ogg" )
	end_song = load( "res://gameart/nene - OpenGameArt/Boss Battle #3.ogg" )
	change_map( "credits" )
	#change_map( "startmenu" )
	#change_map( "test" )
	pass

onready var mplayer = get_node( "music" )
onready var mplayer_anim = get_node( "music/anim" )
func change_song( new_song, startagain = false ):
	# check if already playing this song
	if startagain == false and mplayer.get_stream() == new_song: return
	# fade out old song
	if mplayer.get_stream() != null:
		mplayer_anim.play( "fade_out")
		yield( mplayer_anim, "finished" )
	mplayer.stop()
	# fade in
	mplayer_anim.play( "on" )
	# set new song
	mplayer.set_stream( new_song )
	# play
	mplayer.play()
	pass


func change_map( map ):
	print( "Changing map: ", map, " - State ", state )
	if state == 0:
		#---------------------------
		# State 0: Hide user interfaces
		#---------------------------
		
		# Set new map
		cur_map = map
		
		# fade out
		get_node( "HUD_Layer/fader/anim" ).play( "fade_out" )
		
		# Hide everything
		get_node( "HUD_Layer/hud" ).hide()
		
		# Set new state
		state = 1
		
		# Set timer
		loadtimer.set_wait_time( 0.25 )
		loadtimer.start()
		
	elif state == 1:
		#---------------------------
		# State 1: Delete old map and instance new one
		#---------------------------
		
		# Delete whatever map we have now
		var aux = mapobj.get_children()
		for x in aux: x.queue_free()
		
		# Create new map
		var m = load( stages[cur_map] )
		
		# Instance the new map
		mapobj.hide()
		mapobj.add_child( m.instance() )
		
		
		
		
		# Set new state
		state = 2
		
		# Set timer
		loadtimer.set_wait_time( 0.5 )
		loadtimer.start()
	else:
		#---------------------------
		# State 2: Show everything
		#---------------------------
		# fade in
		mapobj.show()
		get_node( "HUD_Layer/fader/anim" ).play( "fade_in" )
		
		# show HUD if this is a level map
		if cur_map != "startmenu" and cur_map != "credits" and cur_map != "scores" and cur_map != "ending":
			get_node( "HUD_Layer/hud" ).show()
		
		# Set new state
		state = 0
		# emit start signal
		emit_signal( "level_start" )



func _on_loadtimer_timeout():
	change_map( cur_map )
