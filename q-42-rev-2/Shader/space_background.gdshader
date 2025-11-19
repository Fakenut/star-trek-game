shader_type canvas_item;

void fragment() {
    vec2 uv = UV * 20.0;               // Grid-Größe
    vec2 grid = fract(uv);
    float lines = smoothstep(0.48, 0.5, max(grid.x, grid.y));
    vec3 grid_color = vec3(0.1, 0.15, 0.3);
    COLOR.rgb = mix(COLOR.rgb, grid_color, lines * 0.6);
    // Kleine Sterne
    if (fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453) > 0.999)
        COLOR.rgb = vec3(1.0);
}