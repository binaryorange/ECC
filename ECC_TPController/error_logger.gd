extends Node

# This is a custom error logger system for ECC.

var warn_level = ["ECC CRITICAL ERROR: ", "ECC WARNING: "]
enum WARN {ERR = 0, WARN = 1}

var node_names = ["ViewCamera", "ClipCamera", "Player"]
enum NODE {V_CAM = 0, C_CAM = 1, CC_PLAYER = 1}

func log_error(level, message, node):
	var _message = warn_level[level] + message
	var _node = node_names[node]
	printerr(_message % [_node, _node])
	push_error(_message % [_node, _node])
