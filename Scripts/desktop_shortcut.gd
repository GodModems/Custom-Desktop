extends Control

# Icon Components
@onready var ICON: TextureRect 
@onready var APPNAME: Label 
@onready var HIGHLIGHT: Panel = $Highlight
@onready var doubleClickTimer = Timer.new()


@export var JSON_FILE_PATH : String
@export var JSON_FILE_INFO = {
	"name" : "",
	"path" : "",
	"position" : {"x" : "", "y" : ""}
}

# Icon dimensions
const ICON_WIDTH : int = 86
const ICON_HEIGHT : int = 128

# Grid area dimensions
const GRID_WIDTH : int = 1920
const GRID_HEIGHT : int = 1030
const PADDING : int = 5
const DOUBLE_CLICK_TIME : float = 0.3  # Maximum time (in seconds) between clicks for a double-click

var isDragging :bool = false
var dragOffset : Vector2 = Vector2()
var clickCount : int = 0
var applicationPath : String
var tempIcon
var tempPos
var shadow : bool = false
func _ready():
	add_child(doubleClickTimer)
	doubleClickTimer.one_shot = true
	doubleClickTimer.wait_time = DOUBLE_CLICK_TIME
	doubleClickTimer.connect("timeout", _on_double_click_timeout)

func setup_shortcut(shortcutInfo : Dictionary) -> void:
	ICON = find_child("Icon")
	APPNAME = find_child("Application Name")
	
	
	self.position.x = int(shortcutInfo["position"]["x"])
	self.position.y = int(shortcutInfo["position"]["y"])
	var image = Image.load_from_file(shortcutInfo["icon"])
	ICON.texture = ImageTexture.create_from_image(image)
	
	APPNAME.text = shortcutInfo["name"]
	applicationPath = shortcutInfo["path"]
	
	JSON_FILE_PATH = shortcutInfo["json"]
	JSON_FILE_INFO["name"] = shortcutInfo["name"]
	JSON_FILE_INFO["path"] = shortcutInfo["path"]
	JSON_FILE_INFO["position"] = shortcutInfo["position"]






func _gui_input(event) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				clickCount += 1
				if clickCount == 1:
					HIGHLIGHT.show()
					doubleClickTimer.start()
				elif clickCount == 2:
					on_double_click()
					return
				# Start dragging
				isDragging = true
				dragOffset = event.position
				tempIcon = self.duplicate(8)
				tempIcon.modulate = Color(1, 1, 1, 0.318)
				tempPos = global_position
				
			else:
				HIGHLIGHT.hide()
				# Stop dragging and snap to grid
				isDragging = false
				position = snap_to_grid(global_position)
				update_json_position(position)
				if shadow:
					tempIcon.queue_free()
					tempPos = Vector2(0,0)
				shadow = false
	elif event is InputEventMouseMotion and isDragging:
		# Move the icon with the mouse
		if not shadow:
			add_child(tempIcon)
			shadow = true
		global_position = get_global_mouse_position() - dragOffset
		tempIcon.global_position = tempPos + ICON.position


func snap_to_grid(global_pos: Vector2) -> Vector2:
	var usableWidth = GRID_WIDTH - (2 * PADDING)
	var usableHeight = GRID_HEIGHT - (2 * PADDING)
	# Clamp position within the grid area
	var clamped_x = clamp(global_pos.x, PADDING, PADDING + usableWidth - ICON_WIDTH)
	var clamped_y = clamp(global_pos.y, PADDING, PADDING + usableHeight - ICON_HEIGHT)

	# Snap to nearest grid point, considering padding
	var snapped_x = floor((clamped_x - PADDING) / ICON_WIDTH) * ICON_WIDTH + PADDING
	var snapped_y = floor((clamped_y - PADDING) / ICON_HEIGHT) * ICON_HEIGHT + PADDING
	return Vector2(snapped_x, snapped_y)

func update_json_position(pos : Vector2) -> void:
	JSON_FILE_INFO["position"]["x"] = str(pos.x)
	JSON_FILE_INFO["position"]["y"] = str(pos.y)


func _on_double_click_timeout() -> void:
	clickCount = 0


func on_double_click() -> void:
	# Placeholder command for double-click
	doubleClickTimer.stop()
	clickCount = 0
	print("Double-click detected on:", name)
	run_application()


func run_application() -> void:
	var args = []  # Arguments for the executable (if any)
	var output = ""
	var error = ""
	
	# Check if the file exists before trying to execute it
	if FileAccess.file_exists(applicationPath):
		var result = OS.execute(applicationPath, args)
		
		if result == OK:
			print("Executable launched successfully.")
		else:
			print("Error launching executable:", error)
	else:
		print("Executable not found at path:", applicationPath)
