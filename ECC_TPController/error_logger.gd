extends Node

# This is a custom error logger system for ECC.

var warn_level = ["ECC CRITICAL ERROR: ", "ECC WARNING: "]
enum WARN_LEVEL {ERROR = 0, WARN = 1}

var msg = ["No node assigned to %s, please assign a node and try again!"]


var node_names = ["ViewCamera", "ClipCamera", "Target"]
enum NODE_NAME {V_CAM = 0, C_CAM = 1, TARGET = 2}

func unassigned_node_error(level, node):
	
	var _msg = warn_level[level] + msg[0] % node_names[node]
	printerr(_msg)
	push_error(_msg)
