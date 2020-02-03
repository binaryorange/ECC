extends Spatial


# we use this script to keep track of whether or not the player is on a dynamic platform
# we do this by checking for an AREA that is on each dynamic platform, rather than the body

export (String) var Group = "dynamic_platform"

# store the player, which is the direct parent of this node
onready var player = get_parent()

# get the player's parent and store it in default_parent
# this is the parent that the player will be reparented to when not
# on a dynamic platform
onready var default_parent = player.get_parent()

# this variable will store the platform we are on
var platform = null

# these variables store what our last parent is, and what our new parent will be
# lots of adopting out going on here!
var prev_parent = null
var new_parent = null

# Called when the node enters the scene tree for the first time.
func _ready():
	# ensure we stored the player
	print("Stored the node " + str(player.name))
	# ensure we stored the player's parent
	print("Stored the player's default parent as " + str(default_parent.name))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	
	# store the player's current parent
	prev_parent = player.get_parent()
	
	# do these actions when platform is valid
	if platform:
		
		# when we are on a platform, subtract its rotation from our rotation when moving
		if platform.RotatePlatform:
			if player.stickInput.x != 0 or player.stickInput.y != 0:
				player.rotation = player.rotation - platform.rotation
	
	# check for dynamic platform
	_check_for_platform()
			
# this function checks for a platform through player's floor_test_array
func _check_for_platform():

	# check if they are on a dynamic platform
	for i in range(player.floor_test_array.size()):
		if player.floor_test_array[i].is_colliding():
			var collider = player.floor_test_array[i].get_collider()
			if collider.is_in_group(Group):
				# first we check if platform is already used, if it is, we
				# reassign it to a different platform
				if platform:
					if platform != collider.get_node("../../"):
						# ensure we tell the first platform we are OFF of it...
						platform.on_platform = false
						
						print("old platform: " + str(platform.name))
						platform = collider.get_node("../../")
						print("new platform: " + str(platform.name))
				else:
					platform = collider.get_node("../../")
					print("landing on " + str(platform.name))
				
				# now trigger the reparenting
				if !platform.on_platform:
					call_deferred("parent")
		else: 
			# we aren't colliding anymore, so reparent the player back to the world
			if platform:
				call_deferred("unparent")
				
				
func parent():
	# assign the new parent as the platform
	new_parent = platform
	
	# store the player's global transform
	var t = player.global_transform
	
	# remove the player from its previous parent
	prev_parent.remove_child(player)
	
	# now add the player to the new parent
	new_parent.add_child(player)
	
	# reapply the global transfrom back to the player
	player.global_transform = t
	
	# tell the platform we are on it
	platform.on_platform = true
	
	print("Reparented " + str(player.name) + " from " + str(prev_parent.name) + " to " + str(new_parent.name))
	
	
func unparent():
	new_parent = default_parent
	
	# store the player's global transform
	var t = player.global_transform
	# remove the player from its previous parent
	prev_parent.remove_child(player)
	
	# now add the player to the new parent
	new_parent.add_child(player)
	
	# reapply the global transfrom back to the player
	player.global_transform = t
	
	# tell the platform we are not on it anymore
	platform.on_platform = false
	
	# ensure platform is null
	platform = null
	print("Reparented " + str(player.name) + " from " + str(prev_parent.name) + " to " + str(new_parent.name))
	
