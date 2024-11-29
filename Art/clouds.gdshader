shader_type canvas_item;

uniform float zoom = 1;
uniform float timeScale = 1;
uniform sampler3D noiseImage;
uniform vec4 color_a : source_color = vec4(0.101961,0.619608,0.666667, 1);
uniform vec4 color_b : source_color = vec4(0.666667,0.666667,0.498039, 1);

float fbm3 (in vec2 st, in float z) {
	vec3 dummy;
	vec3 m = modf(vec3(st, z), dummy);
	float tul = texture(noiseImage, m).r;
	return tul;
}

float fbm2 (in vec2 st) {
	return fbm3(st, 0.5);
}

vec2 center(in vec2 p)
{
	return (p / 2.0) + vec2(0.5, 0.5);
}

float uncenter(in float p)
{
	return (p * 2.0) - 1.;
}

void fragment() {
    //vec2 st = vec2(0.5, 0.5) + (UV.xy - vec2(0.5, 0.5))/zoom;
	vec2 st = UV / zoom;

	float tm = 0.15 * timeScale * TIME;
	float radian = PI * 2.0 * fbm3(st, tm);
	vec2 circle = vec2(sin(radian), cos(radian));
	
	float cs_x = fbm3(st + circle, tm);
	float cs_y = fbm3(st - circle, tm);
	vec2 cs = vec2(cs_x, cs_y);
	
	vec2 inner_a = vec2(fbm3(st + cs, 0.1), fbm3(st + cs, 0.6));
	vec2 inner_b = vec2(fbm3(cs + st + inner_a * inner_a, 0.2), fbm3(cs + st + inner_a * inner_a, 0.7));
	float v = clamp(fbm2(cs + st + inner_b * inner_b), 0., 1.);
	v = pow(v, 2);
	COLOR = mix(color_a, color_b, v);
}
