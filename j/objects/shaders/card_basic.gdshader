shader_type canvas_item;

uniform float SPEED = 0.5f;
uniform float AMPLITUDE = 5.f;

const float VERTEX_OFFSET = 0.2f;

void vertex() {
	float effectiveTime = TIME + (float(VERTEX_ID) * VERTEX_OFFSET);
	
	VERTEX += vec2(0.f, cos(effectiveTime * SPEED) * AMPLITUDE);
}

void fragment() {
	float brightness = (sin((UV.y * 20.f) - TIME + (UV.x * ((cos(TIME) * 50.f) - 50.f))) + 1.f) / 4.f + 0.5f;
	
	vec4 orig = texture(TEXTURE, UV);
	vec3 transformed = vec3(orig.r, orig.g, orig.b);
	transformed *= brightness;
	
	COLOR = vec4(transformed, orig.a);
}
