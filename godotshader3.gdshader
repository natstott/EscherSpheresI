// Copied from:
// https://github.com/danilw/Godot4-Sphere-as-particle-do-not-use-Sphere-mesh-as-particle

// Full example at: https://danilw.itch.io/particle-effects-godot3

// WARNING - ALPHA does not work in compatibility in Godot 4.3 - use Godot 3.5 or web
// https://github.com/godotengine/godot/issues/85370

shader_type spatial;
render_mode
	blend_mix,
	depth_draw_opaque,
	cull_back,
	diffuse_burley,
	specular_schlick_ggx,
	shadows_disabled,
	depth_prepass_alpha;

/** Whether or not to use normal-based occlusion when shading. */
uniform bool use_occlusion = false;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
/** Try to correct perspective distortion. */
uniform bool fix_perspective = false;


/** test value */
uniform float testscaler: hint_range(0.0, 20.0, 0.001) = 1.0;

/** How large the sphere is. */
uniform float sphere_size: hint_range(0.01, 1.0, 0.001) = 0.2;

/** Sphere position in world space */
varying vec3 sphere_position;

/** Origin of ray from camera, used for raymarching sphere drawing */
varying vec3 camera_ray_origin;

/** Sphere size */
varying float sp_size;
varying mat4 mcivm; 

void vertex() {
	
	mcivm =MAIN_CAM_INV_VIEW_MATRIX;
		mat4 mat_world = mat4(
			MAIN_CAM_INV_VIEW_MATRIX[0],
			MAIN_CAM_INV_VIEW_MATRIX[1],
			MAIN_CAM_INV_VIEW_MATRIX[2],
			MODEL_MATRIX[3]);

	MODELVIEW_MATRIX = VIEW_MATRIX * mat_world;
	sphere_position = mat_world[3].xyz;

	sp_size = 2. / max(length(MODEL_MATRIX[0].xyz), 0.0001);

	camera_ray_origin = MAIN_CAM_INV_VIEW_MATRIX[3].xyz * sp_size;

	if (fix_perspective) {
		VERTEX *= clamp(
			length(sphere_position - MAIN_CAM_INV_VIEW_MATRIX[3].xyz) / (2. / sp_size),
			0.,
			1.
		);
	}
}


/**
 * Sphere intersection.
 *
 * The MIT License
 * Copyright © 2014 Inigo Quilez
 * https://iquilezles.org/www/articles/intersectors/intersectors.htm
 * @param ro Ray origin.
 * @param rd Ray direction.
 * @param sph Sphere position and radius.
 * @return Distance to intersection or -1.   */
float sphere_intersect(in vec3 ro, in vec3 rd, in vec4 sph)
{
	vec3 oc = ro - sph.xyz;
	float b = dot(oc, rd);
	float c = dot(oc, oc) - sph.w * sph.w;
	float h = b * b - c;

	if (h < 0.0) {
		return -1.0;
	}

	return -b - sqrt(h);
}

void fragment() {
	
	METALLIC = 0.001;
	SPECULAR = 0.5;
	ROUGHNESS = 0.9;

	// This is needed ONLY when you have/want particle-shadows
	// and to fix Compatibility render in Godot 4.
	// If you do not need shadows and compatibility - remove this
	{
		vec3 rd = normalize((mcivm * vec4(normalize(-VIEW), 0.0)).xyz);
		//vec3 lgt = vec3(0., 1., 0.);
		vec2 uv;

/*
			col = sphere_image(
				normalize(rd),
				camera_ray_origin,
				sphere_position * sp_size,
				sphere_size
				
			); */
    vec4 sph = vec4(sphere_position*sp_size, sphere_size);
    vec3 col = vec3(1.0);

    float tmin = 1e10;
    vec3 normal = vec3(0.);
    float occ = 1.0;
	float a = 0.;

    float t2 = sphere_intersect(camera_ray_origin, rd, sph);
	if (t2<-0.5) discard;
	// to fix black color
	//t2 = max(t2, 0.001);
        tmin = t2;
        vec3 pos = camera_ray_origin + t2 * rd;
		normal = normalize(pos - sphere_position*sp_size);
        occ = 0.5 + 0.5 * normal.y;
      
		a = 1.;
	 	// ray sphere intersection
		//float rayHit = sphere_intersect(camera_ray_origin, rd, vec4(0,0,0,1.10));
		// calculate object space position from ray, front hit ray length, and ray origin
		vec3 surfacePos = pos-sphere_position; //rd * rayHit + ro;
		// object space surface normal;
		float phi = atan(normal.x/normal.z ) / (2.0*PI);
		//float phi = asin(normal.x/sp_sz ) / (PI);
		float phi_frac = fract(phi);
		//frac is fractional part
		 float theta =acos(-normal.y)/(PI);
		 uv = vec2(
			 phi,
			theta
			)*testscaler+vec2(0.5,0.0);
	
		col = texture(texture_albedo, uv).rgb;

		
		
		
		ALBEDO=col.rgb;
		NORMAL=normal;
	}
}