
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;

uniform float background_dim : hint_range(0.0, 0.5) = 0.16;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float rgb_split : hint_range(0.0, 0.03) = 0.018;
uniform float distortion : hint_range(0.0, 0.1) = 0.055;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.4;

float random_noise(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;

	float t = floor(TIME * 24.0);
	float band = floor(uv.y * 45.0);

	float noise = random_noise(vec2(band, t));

	// Horizontal tearing in occasional scanline bands.
	float tear = step(0.79, noise);
	float horizontal_shift = (noise - 0.5) * distortion * intensity * tear;

	uv.x += horizontal_shift;
	uv = clamp(uv, vec2(0.001), vec2(0.999));

	// Offset RGB channels for chromatic aberration.
	float split_amount = rgb_split * intensity;

	vec3 col;
	col.r = texture(screen_texture, clamp(uv + vec2(split_amount, 0.0), vec2(0.0), vec2(1.0))).r;
	col.g = texture(screen_texture, uv).g;
	col.b = texture(screen_texture, clamp(uv - vec2(split_amount, 0.0), vec2(0.0), vec2(1.0))).b;

	// Subtle moving scanlines.
	float scanline = sin(SCREEN_UV.y * 700.0 + TIME * 18.0);
	col *= 1.0 - max(scanline, 0.0) * scanline_strength * intensity;

	// Brief interference flashes.
	float flash_noise = random_noise(vec2(t, 4.0));
	float flash = step(0.90, flash_noise) * intensity;

	col = mix(col, vec3(0.55, 0.9, 1.0), flash * 0.22);

	
	// Slightly cold electronic tint.
	col = mix(col, col * vec3(0.83, 1.08, 1.12), intensity * 0.3);

	// Darken the scene while the glitch is active.
	// Automatically clears as intensity fades to zero.
	float dim_amount = background_dim * smoothstep(0.0, 0.18, intensity);

	col *= 1.0 - dim_amount;

	COLOR = vec4(col, 1.0);
}

