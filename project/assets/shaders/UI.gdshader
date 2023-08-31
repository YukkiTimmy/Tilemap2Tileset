shader_type canvas_item;

uniform int imgW = 0;
uniform int imgH = 0;
uniform int checkerW = 8;
uniform int checkerH = 8;
uniform int lineWidth = 1;  // Line width
uniform int offsetX = 0;  // offset in x direction
uniform int offsetY = 0;  // offset in y direction

void fragment(){
	vec2 uv = clamp(UV, 0.0, 1.0);
	bool outside = UV.x != uv.x || UV.y != uv.y;
	
	vec4 tex_color = texture(TEXTURE, uv);
	vec4 grid_color = tex_color + vec4(0.0, 0.0, 0.0, 0.5);
	vec4 black_color = vec4(0.0, 0.0, 0.0, 1.0);
	
	vec2 imgUV = uv * vec2(float(imgW), float(imgH));
	
	int ux = int(round(imgUV.x));
	int uy = int(round(imgUV.y));
	
	bool offsetPermits = ux >= offsetX && uy >= offsetY;
	bool xBord = (ux - offsetX) % checkerW == 0;
	bool yBord = (uy - offsetY) % checkerH == 0;
	COLOR =  outside? black_color: (offsetPermits && (xBord || yBord) ? grid_color: tex_color);
}
