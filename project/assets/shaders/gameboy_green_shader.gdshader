shader_type canvas_item;

uniform vec4 darkest : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 dark : source_color = vec4(0.33, 0.33, 0.33, 1.0);
uniform vec4 light : source_color = vec4(0.66, 0.66, 0.66, 1.0);
uniform vec4 lightest : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    float brightness = dot(tex_color.rgb, vec3(0.299, 0.587, 0.114));

    if (brightness < 0.25) {
        COLOR = darkest;
    } else if (brightness < 0.5) {
        COLOR = dark;
    } else if (brightness < 0.75) {
        COLOR = light;
    } else {
        COLOR = lightest;
    }
}