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
//Depth
uniform sampler2D depth1;
uniform sampler2D depth2;
uniform sampler2D depth3;
uniform sampler2D depth4;
uniform sampler2D depth5;

uniform sampler2D splatmap;

uniform float resolution = 16;
uniform float randomize_rotation = 0.0;
uniform float albedo = 1.0;
uniform float normal = 1.0;
uniform float depth_scale;
uniform int depth_min_layers: hint_range(0, 32);
uniform int depth_max_layers: hint_range(0, 64);
uniform vec2 depth_flip = vec2(1.0);

varying vec3 uv1_triplanar_pos;
uniform float uv1_blend_sharpness;
varying vec3 uv1_power_normal;
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;

uniform bool triplanar;



void vertex() {
	TANGENT = vec3(0.0,0.0,-1.0) * abs(NORMAL.x);
	TANGENT+= vec3(1.0,0.0,0.0) * abs(NORMAL.y);
	TANGENT+= vec3(1.0,0.0,0.0) * abs(NORMAL.z);
	TANGENT = normalize(TANGENT);
	BINORMAL = vec3(0.0,1.0,0.0) * abs(NORMAL.x);
	BINORMAL+= vec3(0.0,0.0,-1.0) * abs(NORMAL.y);
	BINORMAL+= vec3(0.0,1.0,0.0) * abs(NORMAL.z);
	BINORMAL = normalize(BINORMAL);
	uv1_power_normal=pow(abs(NORMAL),vec3(uv1_blend_sharpness));
	uv1_power_normal/=dot(uv1_power_normal,vec3(1.0));
	uv1_triplanar_pos = VERTEX * uv1_scale + uv1_offset;
	uv1_triplanar_pos *= vec3(1.0,-1.0, 1.0);
}

vec2 height(sampler2D texture_depth, vec3 view_dir, vec2 base_uv){
	float num_layers = mix(float(depth_max_layers),float(depth_min_layers), abs(dot(vec3(0.0, 0.0, 1.0), view_dir)));
	float layer_depth = 1.0 / num_layers;
	float current_layer_depth = 0.0;
	vec2 P = view_dir.xy * depth_scale;
	vec2 delta = P / num_layers;
	vec2 ofs = base_uv;
	float depth = textureLod(texture_depth, ofs, 0.0).r;
	float current_depth = 0.0;
	while(current_depth < depth) {
		ofs -= delta;
		depth = textureLod(texture_depth, ofs, 0.0).r;
		current_depth += layer_depth;
	}
	vec2 prev_ofs = ofs + delta;
	float after_depth  = depth - current_depth;
	float before_depth = textureLod(texture_depth, prev_ofs, 0.0).r - current_depth + layer_depth;
	float weight = after_depth / (after_depth - before_depth);
	ofs = mix(ofs,prev_ofs,weight);
	return ofs;
}

vec4 triplanar_texture(sampler2D p_sampler,vec3 p_weights,vec3 p_triplanar_pos) {
	vec4 samp=vec4(0.0);
	samp+= texture(p_sampler,p_triplanar_pos.xy) * p_weights.z;
	samp+= texture(p_sampler,p_triplanar_pos.xz) * p_weights.y;
	samp+= texture(p_sampler,p_triplanar_pos.zy * vec2(-1.0,1.0)) * p_weights.x;
	return samp;
}

float rand(vec2 input) {
	//return fract(sin(dot(input.xy, vec2(12.9898,78.233))) * 43758.5453123);
	return 0.0;
}

float mip_map_level(in vec2 texture_coordinate) {
    vec2  dx_vtc = dFdx(texture_coordinate);
    vec2  dy_vtc = dFdy(texture_coordinate);
    float delta_max_sqr = max(dot(dx_vtc, dx_vtc), dot(dy_vtc, dy_vtc));
    float mml = 0.5 * log2(delta_max_sqr);
    return max(0, mml);
}

void fragment () {
	vec3 view_dir = normalize(normalize(-VERTEX)*mat3(TANGENT*depth_flip.x,-BINORMAL*depth_flip.y,NORMAL));
	
	vec2 tiled_UV_raw = UV * resolution;
	vec2 tiled_UV = fract(tiled_UV_raw) - 0.5;
	vec2 unique_val = floor(UV * resolution) / resolution;
	float rotation = (rand(unique_val) * 2.0 - 1.0) * randomize_rotation * 3.14;
	float cosine = cos(rotation);
	float sine = sin(rotation);
	mat2 rotation_mat = mat2(vec2(cosine, -sine), vec2(sine, cosine));
	vec2 new_uv1 = rotation_mat * tiled_UV + 0.5;
	vec2 new_uv2 = rotation_mat * tiled_UV + 0.5;
	vec2 new_uv3 = rotation_mat * tiled_UV + 0.5;
	vec2 new_uv4 = rotation_mat * tiled_UV + 0.5;
	vec2 new_uv5 = rotation_mat * tiled_UV + 0.5;
	float lod = mip_map_level(tiled_UV_raw * vec2(textureSize(texture2, 0)));
	lod = mip_map_level(tiled_UV_raw * vec2(textureSize(texture1, 0)));
	lod = mip_map_level(tiled_UV_raw * vec2(textureSize(texture3, 0)));
	lod = mip_map_level(tiled_UV_raw * vec2(textureSize(texture4, 0)));
	
	
    vec3 result;
	vec3 result2;
	
	vec4 splat_tris = vec4(0.0, 0.0, 0.0, 0.0); 
	vec4 albedo_tex1 = vec4(1.0, 1.0, 1.0, 1.0); 
	vec4 albedo_tex2 = vec4(1.0, 1.0, 1.0, 1.0); 
	vec4 albedo_tex3 = vec4(1.0, 1.0, 1.0, 1.0);
	vec4 albedo_tex4 = vec4(1.0, 1.0, 1.0, 1.0);
	vec4 albedo_tex5 = vec4(1.0, 1.0, 1.0, 1.0);
	
	if (triplanar){
		splat_tris = triplanar_texture(splatmap,uv1_power_normal,uv1_triplanar_pos);
		albedo_tex1 = triplanar_texture(texture1,uv1_power_normal,uv1_triplanar_pos);
		albedo_tex2 = triplanar_texture(texture2,uv1_power_normal,uv1_triplanar_pos);
		albedo_tex3 = triplanar_texture(texture3,uv1_power_normal,uv1_triplanar_pos);
		albedo_tex4 = triplanar_texture(texture4,uv1_power_normal,uv1_triplanar_pos);
		albedo_tex5 = triplanar_texture(texture5,uv1_power_normal,uv1_triplanar_pos);
	}
	
    float mix1 = texture(splatmap, UV).r;
    float mix2 = texture(splatmap, UV).g;
    float mix3 = texture(splatmap, UV).b;
    float mix4 = 1.0-texture(splatmap, UV).a;
	float mix5 = 1.0-(texture(splatmap, UV).r + texture(splatmap, UV).g + texture(splatmap, UV).b + (1.0-texture(splatmap, UV).a));
	
	if (triplanar){
		splat_tris = triplanar_texture(splatmap,uv1_power_normal,uv1_triplanar_pos);
		albedo_tex1 = triplanar_texture(texture1,uv1_power_normal,uv1_triplanar_pos);
		albedo_tex2 = triplanar_texture(texture2,uv1_power_normal,uv1_triplanar_pos);
		albedo_tex3 = triplanar_texture(texture3,uv1_power_normal,uv1_triplanar_pos);
		albedo_tex4 = triplanar_texture(texture4,uv1_power_normal,uv1_triplanar_pos);
		albedo_tex5 = triplanar_texture(texture5,uv1_power_normal,uv1_triplanar_pos);
		
		mix1 += splat_tris.r; 
		mix2 += splat_tris.g;
		mix3 += splat_tris.b;
		mix4 += 1.0-splat_tris.a;
		mix5 += 1.0-(splat_tris.r + splat_tris.g + splat_tris.b + 1.0 - splat_tris.a);
	}
	
	if (depth_scale != 0.0){
		new_uv1 = height(depth1, view_dir, new_uv1);
		new_uv2 = height(depth2, view_dir, new_uv2);
		new_uv3 = height(depth3, view_dir, new_uv3);
		new_uv4 = height(depth4, view_dir, new_uv4);
		new_uv5 = height(depth5, view_dir, new_uv5);
	}
	
    vec3 color1 = texture(texture1, new_uv1).rgb*mix1*albedo_tex1.rgb;
    vec3 color2 = texture(texture2, new_uv2).rgb*mix2*albedo_tex2.rgb;
    vec3 color3 = texture(texture3, new_uv3).rgb*mix3*albedo_tex3.rgb;
    vec3 color4 = texture(texture4, new_uv4).rgb*mix4*albedo_tex4.rgb;
	vec3 color5 = texture(texture5, new_uv5).rgb*mix5*albedo_tex5.rgb;
	
	vec3 map1 = texture(normal1, new_uv1).rgb*mix1;
    vec3 map2 = texture(normal2, new_uv2).rgb*mix2;
    vec3 map3 = texture(normal3, new_uv3).rgb*mix3;
    vec3 map4 = texture(normal4, new_uv4).rgb*mix4;
	vec3 map5 = texture(normal5, new_uv5).rgb*mix5;
	
	
    result = color1 + color2 + color3 + color4 + color5;
	result2 = map1 + map2 + map3 + map4 + map5;
	
	
    ALBEDO = result * albedo;
	NORMAL_MAP = result2 * normal;
	
}
