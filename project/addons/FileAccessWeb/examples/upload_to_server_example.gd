class_name UploadToServerExample
extends Control

@onready var upload_image_example: UploadImageExample = $"Upload Image Example" as UploadImageExample
@onready var http: HTTPRequest = $HTTPRequest as HTTPRequest

var url: String = "http://localhost:5072/images"

func _ready() -> void:
	upload_image_example.file_access_web.loaded.connect(_on_file_loaded)
	http.request_completed.connect(_on_request_completed)

func _on_file_loaded(file_name: String, type: String, base64_data: String) -> void:
	_send_to_server(file_name, type, base64_data)

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	print(body.get_string_from_ascii())

func _send_to_server(file_name: String, file_type: String, file_base64: String) -> void:
	const boundary: String = "GodotFileUploadBoundaryZ29kb3RmaWxl"
	var headers = [ "Content-Type: multipart/form-data; boundary=%s" % boundary]
	var body = _form_data_packet(boundary, "image", file_name, file_type, file_base64)
	http.request_raw(url, headers, HTTPClient.METHOD_PUT, body)

func _form_data_packet(boundary: String, endpoint_argument_name: String, file_name: String, file_type: String, file_base64: String) -> PackedByteArray:	
	var packet := PackedByteArray()
	var boundary_start = ("\r\n--%s" % boundary).to_utf8_buffer()
	var disposition = ("\r\nContent-Disposition: form-data; name=\"%s\"; filename=\"%s\"" % [endpoint_argument_name, file_name]).to_utf8_buffer()
	var content_type = ("\r\nContent-Type: %s\r\n\r\n" % file_type).to_utf8_buffer()
	var boundary_end = ("\r\n--%s--\r\n" % boundary).to_utf8_buffer()

	packet.append_array(boundary_start)
	packet.append_array(disposition)
	packet.append_array(content_type)
	packet.append_array(Marshalls.base64_to_raw(file_base64))
	packet.append_array(boundary_end)
	return packet
