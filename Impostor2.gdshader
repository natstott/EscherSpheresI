// this is fast port of
// https://github.com/danilw/godot-utils-and-other/blob/master/particle_system_effects_Godot3/shaders/particle_cloud_base.shader
// Godot 3 to 4 shader

// look full example on https://danilw.itch.io/particle-effects-godot3

// read - ALPHA does not work in compatibility in Godot4.3 - use Godot3.5 or web
// https://github.com/godotengine/godot/issues/85370
// found at https://github.com/danilw/Godot4-Sphere-as-particle-do-not-use-Sphere-mesh-as-particle/blob/main/sphere-as-particle-do-not-use-sphere-mesh-as-particle/Sphere_Quad_shader.gdshader

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx, shadows_disabled;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
//varying vec3 spos;
varying float sp_size;
varying mat4 passmodelviewmatrix;


// fix black color
// t2=max(t2,0.001)



void vertex() {
    
		// Billboard Mode: Enabled
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
			MAIN_CAM_INV_VIEW_MATRIX[0],
			MAIN_CAM_INV_VIEW_MATRIX[1],
			MAIN_CAM_INV_VIEW_MATRIX[2],
			MODEL_MATRIX[3]);

	// Billboard Keep Scale: Enabled
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(
			vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
			vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
			vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
			vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
	passmodelviewmatrix= MODELVIEW_MATRIX;
	//mat4 mat_world = mat4(normalize(INV_VIEW_MATRIX[0])*length(MODEL_MATRIX[0]),normalize(INV_VIEW_MATRIX[1])*length(MODEL_MATRIX[1]),normalize(INV_VIEW_MATRIX[2])*length(MODEL_MATRIX[2]),MODEL_MATRIX[3]);

	//MODELVIEW_MATRIX = VIEW_MATRIX * mat_world;
	//spos=mat_world[3].xyz;
	//sp_size=2./max(length(MODEL_MATRIX[0].xyz),0.0001);
	//roc=INV_VIEW_MATRIX[3].xyz*sp_size;
}


void fragment() {
mat3 mat_world = mat3(passmodelviewmatrix[0].xyz/length(passmodelviewmatrix[0].xyz),
passmodelviewmatrix[1].xyz/length(passmodelviewmatrix[1].xyz),
passmodelviewmatrix[2].xyz/length(passmodelviewmatrix[2].xyz));

vec3 pos=NODE_POSITION_WORLD;
vec3 cameravector=CAMERA_POSITION_WORLD-pos;




	vec2 xy=UV*2.0-vec2(1.0);
	if (length(xy)>1.0) discard;
	float widthy=sqrt(1.0-xy.y*xy.y);
	float longitude=asin(xy.x/widthy);
	float latitude=asin(xy.y);
	vec3 pointonsurface=vec3(widthy*sin(longitude),xy.y,widthy*cos(longitude));
	vec3 pointonglobe=mat_world*pointonsurface;
	float newwidthy=sqrt(1.0-pointonglobe.y*pointonglobe.y);
	float newlongitude=asin(pointonglobe.x/newwidthy);
	float newlatitude=asin(pointonglobe.y);
	//vec2 base_uv = vec2(0.5+longitude/6.283, UV.y);
	vec2 base_uv = vec2(0.5+0.5*newlongitude/6.28318, pointonglobe.y+0.5);
	vec4 albedo_tex = texture(texture_albedo, base_uv);
	ALBEDO=albedo_tex.rgb;

}
