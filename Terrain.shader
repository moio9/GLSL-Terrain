shader_type spatial;   
uniform sampler2D texture1;
uniform sampler2D texture2;
uniform sampler2D texture3;
uniform sampler2D texture4;
uniform sampler2D texture5;
//Normal
uniform sampler2D normal1;
uniform sampler2D normal2;
uniform sampler2D normal3;
uniform sampler2D normal4;
uniform sampler2D normal5;

uniform sampler2D splatmap;

uniform float resolution = 16;
uniform float randomize_rotation = 0.0;
uniform float albedo = 1.0;
uniform float normal = 1.0;

float rand(vec2 input) {
	return fract(sin(dot(input.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

float mip_map_level(in vec2 texture_coordinate) {
    vec2  dx_vtc = dFdx(texture_coordinate);
    vec2  dy_vtc = dFdy(texture_coordinate);
    float delta_max_sqr = max(dot(dx_vtc, dx_vtc), dot(dy_vtc, dy_vtc));
    float mml = 0.5 * log2(delta_max_sqr);
    return max(0, mml);
}

void fragment () {
	vec2 tiled_UV_raw = UV * resolution;
	vec2 tiled_UV = fract(tiled_UV_raw) - 0.5;
	vec2 unique_val = floor(UV * resolution) / resolution;
	float rotation = (rand(unique_val) * 2.0 - 1.0) * randomize_rotation * 3.14;
	float cosine = cos(rotation);
	float sine = sin(rotation);
	mat2 rotation_mat = mat2(vec2(cosine, -sine), vec2(sine, cosine));
	vec2 new_uv = rotation_mat * tiled_UV + 0.5;
	float lod = mip_map_level(tiled_UV_raw * vec2(textureSize(texture2, 0)));
	lod = mip_map_level(tiled_UV_raw * vec2(textureSize(texture1, 0)));
	lod = mip_map_level(tiled_UV_raw * vec2(textureSize(texture3, 0)));
	lod = mip_map_level(tiled_UV_raw * vec2(textureSize(texture4, 0)));
	
    vec3 result;
	vec3 result2;
    float mix1 = texture(splatmap, UV).r;
    float mix2 = texture(splatmap, UV).g;
    float mix3 = texture(splatmap, UV).b;
    float mix4 = 1.0-texture(splatmap, UV).a;
	float mix5 = 1.0-(texture(splatmap, UV).r + texture(splatmap, UV).g + texture(splatmap, UV).b + (1.0-texture(splatmap, UV).a));
	
    vec3 color1 = texture(texture1, new_uv).rgb*mix1;
    vec3 color2 = texture(texture2, new_uv).rgb*mix2;
    vec3 color3 = texture(texture3, new_uv).rgb*mix3;
    vec3 color4 = texture(texture4, new_uv).rgb*mix4;
	vec3 color5 = texture(texture5, new_uv).rgb*mix5;
	
	vec3 map1 = texture(normal1, new_uv).rgb*mix1;
    vec3 map2 = texture(normal2, new_uv).rgb*mix2;
    vec3 map3 = texture(normal3, new_uv).rgb*mix3;
    vec3 map4 = texture(normal4, new_uv).rgb*mix4;
	vec3 map5 = texture(normal5, new_uv).rgb*mix5;
	
    result = color1 + color2 + color3 + color4 + color5;
	result2 = map1 + map2 + map3 + map4 + map5;
	
    ALBEDO = result * albedo;
	NORMALMAP = result2 * normal;
	
}
