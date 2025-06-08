//Shader "Complete Sphere Impostor"
shader_type spatial;

render_mode
	blend_mix,
	depth_draw_opaque,
	cull_back,
	diffuse_burley,
	specular_schlick_ggx,
	shadows_disabled,
	depth_prepass_alpha;



        uniform vec4 Color: source_color = vec4(1,1,1,1);
		uniform sampler2D _MainTex : source_color, filter_linear_mipmap, repeat_enable;




// was struc v2f
        varying       vec4 pos;
        varying       vec3 rayDir;
        varying     vec3 rayOrigin;
//        varying     uint UNITY_VERTEX_INPUT_INSTANCE_ID; //may need something later!
		varying mat4 modelviewmatrix;



            // common vertex function for all passes
            void vertex ()
            {
                // check if the current projection is orthographic or not from the current projection matrix
                bool isOrtho = (PROJECTION_MATRIX[3].z == 1.0);

                // viewer position, equivalent to _WorldSpaceCAmeraPos.xyz, but for the current view
                mat4 MATRIX_IVIEW=inverse(VIEW_MATRIX);
				modelviewmatrix=MODELVIEW_MATRIX;
				vec3 worldSpaceViewerPos = vec3(
					MATRIX_IVIEW[0].w,
					MATRIX_IVIEW[1].w,
					MATRIX_IVIEW[2].w); //MATRIX_IVIEW._m03_m13_m23
                // view forward
                vec3 worldSpaceViewForward =vec3(
					MATRIX_IVIEW[0].z,
					MATRIX_IVIEW[1].z,
					MATRIX_IVIEW[2].z); // -MATRIX-IVIEW._m02_m12_m22;

                // pivot position
                vec3 worldSpacePivotPos =vec3(
					MODELVIEW_MATRIX[0].w,
					MODELVIEW_MATRIX[1].w,
					MODELVIEW_MATRIX[2].w
						);// MODELVIEW_MATRIX._m03_m13_m23;

                // offset between pivot and camera
                vec3 worldSpacePivotToView = worldSpaceViewerPos - worldSpacePivotPos;

                // get the max object scale
				float scalex= length(vec3(
					MODELVIEW_MATRIX[0].x,
					MODELVIEW_MATRIX[1].x,
					MODELVIEW_MATRIX[2].x
				)); //MODELVIEW_MATRIX._m00_m10_m20

				float scaley= length(vec3(
					MODELVIEW_MATRIX[0].y,
					MODELVIEW_MATRIX[1].y,
					MODELVIEW_MATRIX[2].y
				)); //MODELVIEW_MATRIX._m01_m11_m21

				float scalez= length(vec3(
					MODELVIEW_MATRIX[0].z,
					MODELVIEW_MATRIX[1].z,
					MODELVIEW_MATRIX[2].z
				)); //MODELVIEW_MATRIX.m02_m12_m22

                vec3 scale = vec3(1.0);//vec3(scalex,scaley,scalez);

                float maxScale = max(abs(scale.x), max(abs(scale.y), abs(scale.z)));

                // calculate a camera facing rotation matrix
                vec3 up = vec3(
					MATRIX_IVIEW[0].y,
					MATRIX_IVIEW[1].y,
					MATRIX_IVIEW[2].y); //MATRIX_IVIEW._m01_m11_m21;
                vec3 forward = isOrtho ? -worldSpaceViewForward : normalize(worldSpacePivotToView);
                vec3 right = normalize(cross(forward, up));
                up = cross(right, forward);
                mat3 quadOrientationMatrix = mat3(right, up, forward);

                // use the max scale to figure out how big the quad needs to be to cover the entire sphere
                // we're using a hardcoded object space radius of 0.5 in the fragment shader
                float maxRadius = 1.0;//maxScale * 0.5;

                // find the radius of a cone that contains the sphere with the point at the camera and the base at the pivot of the sphere
                // this means the quad is always scaled to perfectly cover only the area the sphere is visible within
                float quadScale = 1.0;//maxScale;
                if (!isOrtho)
                {
                    // get the sine of the right triangle with the hyp of the sphere pivot distance and the opp of the sphere radius
                    float sinAngle = maxRadius / length(worldSpacePivotToView);
                    // convert to cosine
                    float cosAngle = sqrt(1.0 - sinAngle * sinAngle);
                    // convert to tangent
                    float tanAngle = sinAngle / cosAngle;

                    // basically this, but should be faster
                    //tanAngle = tan(asin(sinAngle));

                    // get the opp of the right triangle with the 90 degree at the sphere pivot * 2
                    quadScale = tanAngle * length(worldSpacePivotToView) * 2.0;
                }

                // flatten mesh, in case it's a cube or sloped quad mesh
               VERTEX.z = 0.0; //appdata v - is this really model space?

                // calculate world space position for the camera facing quad
                vec3 worldPos = (quadOrientationMatrix*VERTEX.xyz * quadScale) + worldSpacePivotPos;

                // calculate world space view ray direction and origin for perspective or orthographic
                vec3 worldSpaceRayOrigin = worldSpaceViewerPos;
                vec3 worldSpaceRayDir = worldPos - worldSpaceRayOrigin;
                if (isOrtho)
                {
                    worldSpaceRayDir = worldSpaceViewForward * -dot(worldSpacePivotToView, worldSpaceViewForward);
                    worldSpaceRayOrigin = worldPos - worldSpaceRayDir;
                }

                // output object space ray direction and origin
				mat4 unity_WorldToObject= inverse(MODEL_MATRIX);
                rayDir = (unity_WorldToObject*vec4(worldSpaceRayDir, 0.0) ).xyz;
                rayOrigin = (unity_WorldToObject*vec4(worldSpaceRayOrigin, 1.0)).xyz;

                // offset towards the camera for use with conservative depth

                //pos = (UnityWorldToClipPos*worldPos).xyz;
				pos = VIEW_MATRIX*PROJECTION_MATRIX*vec4(worldPos,1.0);

                //return o;
            }

            // https://www.iquilezles.org/www/articles/spherefunctions/spherefunctions.htm
            float sphIntersect( vec3 ro, vec3 rd, vec4 sph )
            {
                vec3 oc = ro - sph.xyz;
                float b = dot( oc, rd );
                float c = dot( oc, oc ) - sph.w*sph.w;
                float h = b*b - c;
                if( h<0.0 ) return -1.0;
                h = sqrt( h );
                return -b - h;
            }


            // reuse the fragment shader for both forward base and forward add passes
            void fragment ()
            {
                // instancing
                // even though we're not using any instanced properties
                // we are using the MODELVIEW_MATRIX transform matrix
                // and in instanced shaders, that needs the instance id
                // ray origin
                //vec3 rayOrigin = i.rayOrigin; not needed as no structure passed.

                // normalize ray vector
                vec3 NormrayDir = normalize(rayDir);

                // ray sphere intersection
                float rayHit = sphIntersect(rayOrigin, NormrayDir, vec4(0,0,0,1.0));

            if (rayHit<-0.0)
                // sphere intersection function returns -1 if there's no intersection
                discard;

                // cheap way to reduce mip map artifacts on edge
                // not 100% accurate, but close enough that it'd be hard to notice
                rayHit = rayHit < 0.0 ? dot(NormrayDir, -rayOrigin) : rayHit;

                // calculate object space position from ray, front hit ray length, and ray origin
                vec3 surfacePos = NormrayDir * rayHit + rayOrigin;

                // object space surface normal
                vec3 normal = normalize(surfacePos);

                // -0.5 to 0.5 range

                float phi = atan(normal.z, normal.x) / 6.28318;
                // 0.0 to 1.0 range
                float phi_frac = fract(phi);
                // negate the y because acos(-1.0) = PI, acos(1.0) = 0.0
                float theta = acos(-normal.y) / 3.14159265;
                // construct the uvs, selecting the phi to use based on the derivatives
                vec2 uv = vec2(
                    fwidth(phi) < fwidth(phi_frac) - 0.001 ? phi : phi_frac,
                    theta
                    );

                vec4 col = texture(_MainTex, uv);
                // what shader is complete without a little color tinting?
                //col.rgb *= Color.rgb;

                // world space position and clip space position
                vec3 worldPos = (modelviewmatrix*vec4(surfacePos, 1.0)).xyz;
                vec4 clipPos = VIEW_MATRIX*PROJECTION_MATRIX*(vec4(worldPos, 1.0));


                ALBEDO=  col.rgb;
            }
