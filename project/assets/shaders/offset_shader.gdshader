shader_type canvas_item;

// ----- Kasten-Parameter -----
uniform vec4 box_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform vec2 rect_pos = vec2(0.0, 0.0);
uniform vec2 rect_size = vec2(0.0, 0.0);
uniform float border_thickness = 2.0;

// ----- Grid-Parameter -----
uniform bool draw_grid = false;
uniform vec2 grid_size = vec2(16.0, 16.0); // x = Breite, y = Höhe in Pixeln
uniform vec4 grid_color : source_color = vec4(0.0, 1.0, 0.0, 0.5);
uniform float grid_thickness = 1.0;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    vec2 tex_size = vec2(textureSize(TEXTURE, 0));
    vec2 pixel_coord = UV * tex_size;

    // --- Grundfarbe aus der Textur ---
    vec4 final_color = tex_color;

    // --- Kasten nur zeichnen, wenn Größe > 0 ---
    if (rect_size.x > 0.0 && rect_size.y > 0.0) {
        float left   = rect_pos.x;
        float right  = rect_pos.x + rect_size.x;
        float top    = rect_pos.y;
        float bottom = rect_pos.y + rect_size.y;

        bool in_horizontal_border =
            (pixel_coord.x >= left && pixel_coord.x <= right) &&
            (abs(pixel_coord.y - top) <= border_thickness ||
             abs(pixel_coord.y - bottom) <= border_thickness);

        bool in_vertical_border =
            (pixel_coord.y >= top && pixel_coord.y <= bottom) &&
            (abs(pixel_coord.x - left) <= border_thickness ||
             abs(pixel_coord.x - right) <= border_thickness);

        if (in_horizontal_border || in_vertical_border) {
            final_color = box_color;
        }
    }

    // --- Grid zeichnen ---
    if (draw_grid && grid_size.x > 0.0 && grid_size.y > 0.0) {
        float gx = mod(pixel_coord.x, grid_size.x);
        float gy = mod(pixel_coord.y, grid_size.y);

        if (gx <= grid_thickness || gy <= grid_thickness) {
            final_color = mix(final_color, grid_color, grid_color.a);
        }
    }

    COLOR = final_color;
}