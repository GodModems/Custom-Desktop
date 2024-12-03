extends Control

@export var DESKTOP_SHORTCUT : PackedScene 
@export var TASKBAR : PackedScene

@onready var DESKTOP_FOLDER : String = "D:/GodotDesktop"
@onready var ICONS: Control = $Icons


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_shortcuts()


func load_shortcuts():
	var shortcuts = []

	# Check if the desktop folder exists
	if not DirAccess.dir_exists_absolute(DESKTOP_FOLDER):
		print("Shortcut folder not found:", DESKTOP_FOLDER)
		return shortcuts
	
	# Open the desktop folder
	var dir = DirAccess.open(DESKTOP_FOLDER)
	if dir == null:
		print("Failed to open directory:", DESKTOP_FOLDER)
		return shortcuts

	# Start iterating through directory contents
	print(dir)
	dir.list_dir_begin()
	var entry = dir.get_next()
	while entry != "":
		var path = DESKTOP_FOLDER + "/" + entry

		# Check if the entry is a directory
		if DirAccess.dir_exists_absolute(path):
			var jsonFile = path + "/shortcut.json"
			var iconFile = path + "/icon.png"
			# Check for required files
			print(FileAccess.file_exists(jsonFile) and FileAccess.file_exists(iconFile))
			if FileAccess.file_exists(jsonFile) and FileAccess.file_exists(iconFile):
				var shortcutData = load_json(jsonFile)
				if shortcutData:
					shortcutData["icon"] = iconFile
					shortcutData["json"] = jsonFile
					shortcuts.append(shortcutData)
				else:
					print("Failed to parse JSON in:", jsonFile)
		else:
			print("Skipping non-directory entry:", entry)

		# Get the next directory entry
		entry = dir.get_next()
	for shortcut in shortcuts:
		load_shortcut(shortcut)
	return shortcuts



func load_json(filePath : String):
	var file = FileAccess.open(filePath, FileAccess.READ)
	if file.get_error() == OK:
		var content = file.get_as_text()
		file.close()
		return JSON.parse_string(content)
	print("Failed to load JSON:", filePath)
	return null


func load_shortcut(shortcutInfo) -> void:
		var currentShortcut = DESKTOP_SHORTCUT.instantiate()
		currentShortcut.setup_shortcut(shortcutInfo)
		ICONS.add_child(currentShortcut)


func save_shortcuts():
	for shortcut in ICONS.get_children():
		save_json(shortcut.JSON_FILE_PATH, shortcut.JSON_FILE_INFO)


func save_json(file_path: String, data: Dictionary) -> void:
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file.get_error() == OK:
		file.store_string(JSON.stringify(data))
		file.close()
		print("Saved shortcut data to:", file_path)
	else:
		print("Failed to save JSON:", file_path)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# Called when the application is quitting
func _notification(what: int) -> void:
	if what == MainLoop.NOTIFICATION_PREDELETE:  # Detect when the app is closing
		save_shortcuts()  # Save all shortcuts before quitting
