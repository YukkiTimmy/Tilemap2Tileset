extends Control
class_name popup_message

@onready var warning_popup := $VBoxContainer/WarningTitleBackground_Panel
@onready var warning_popup_label := $VBoxContainer/WarningTitleBackground_Panel/HBoxContainer/Label

@onready var info_popup := $VBoxContainer/InfoTitleBackground_Panel
@onready var info_popup_label := $VBoxContainer/InfoTitleBackground_Panel/HBoxContainer/Label

@onready var text_label = $VBoxContainer/InfoText_Panel/MarginContainer/Label

func show_warning(header : String, text : String):
	warning_popup.visible = true
	info_popup.visible = false
	
	warning_popup_label.text = header
	text_label.text = text
	
func show_info(header : String, text : String):
	info_popup.visible = true
	warning_popup.visible = false
	
	info_popup_label.text = header
	text_label.text = text

func _on_timer_timeout() -> void:
	queue_free()


func _on_close_btn_pressed() -> void:
	queue_free()
