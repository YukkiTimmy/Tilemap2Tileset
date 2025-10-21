@tool
extends Control

var content_visible := true

@export var hide_content := false:
	set(value):
		if value:
			content_visible = !content_visible
			$VBoxContainer/Content.visible = content_visible
			_update_container_size()
			hide_content = false  

		
func _ready() -> void:
	_update_container_size()
	if Engine.is_editor_hint():
		$VBoxContainer/Content.child_entered_tree.connect(_on_child_added)
		$VBoxContainer/Content.child_exited_tree.connect(_on_child_removed)
		
	content_visible = $VBoxContainer/Content.visible

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_update_container_size()

func _update_container_size():
	if not is_inside_tree():
		return
	var content_size = $VBoxContainer.get_minimum_size().y
	custom_minimum_size.y = content_size

func _on_child_added(_child: Node) -> void:
	_update_container_size()

func _on_child_removed(_child: Node) -> void:
	_update_container_size()

func _on_container_title_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		content_visible = !content_visible
		$VBoxContainer/Content.visible = content_visible
		_update_container_size()
