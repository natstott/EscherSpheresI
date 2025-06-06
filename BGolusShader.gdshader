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



            struct appdata
            {
                vec4 vertex;
                uint UNITY_VERTEX_INPUT_INSTANCE_ID;
            };

// was struc v2f
        varying       vec4 pos;
        varying       vec3 rayDir;
        varying     vec3 rayOrigin;
        varying     uint UNITY_VERTEX_INPUT_INSTANCE_ID;



            // common vertex function for all passes
            void vertex ()
            {


                // check if the current projection is orthographic or not from the current projection matrix
                bool isOrtho = (PROJECTION_MATRIX[3].z == 1.0);

                // viewer position, equivalent to _WorldSpaceCAmeraPos.xyz, but for the current view
                mat4 MATRIX_IVIEW=inverse(VIEW_MATRIX);
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

                vec3 scale = vec3(scalex,scaley,scalez);
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
                float maxRadius = maxScale * 0.5;

                // find the radius of a cone that contains the sphere with the point at the camera and the base at the pivot of the sphere
                // this means the quad is always scaled to perfectly cover only the area the sphere is visible within
                float quadScale = maxScale;
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
                rayDir = (vec4(worldSpaceRayDir, 0.0)* unity_WorldToObject).xyz;
                rayOrigin = (unity_WorldToObject*vec4(worldSpaceRayOrigin, 1.0)).xyz;

                // offset towards the camera for use with conservative depth
            #if defined(USE_CONSERVATIVE_DEPTH)
                worldPos += worldSpaceRayDir / dot(normalize(worldSpacePivotToView), worldSpaceRayDir) * maxRadius;
            #endif

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

            #if defined(UNITY_PASS_FORWARDBASE) || defined(UNITY_PASS_FORWARDADD)
            // dummy struct to allow shadow macro to work
            struct shadowInput {
                SHADOW_COORDS(0)
            };

            half3 _LightColor0;

            half3 _Color;
            sampler2D _MainTex;
            samplerCUBE _CubeTex;

            // reuse the fragment shader for both forward base and forward add passes
            fixed4 frag_forward (v2f i
            #if defined(USE_CONSERVATIVE_DEPTH)
                , out float outDepth : SV_DepthLessEqual
            #else
            // the device probably can't use conservative depth
              , out float outDepth : SV_Depth
            #endif
                ) : SV_Target
            {
                // instancing
                // even though we're not using any instanced properties
                // we are using the MODELVIEW_MATRIX transform matrix
                // and in instanced shaders, that needs the instance id
                UNITY_SETUP_INSTANCE_ID(i);

                // ray origin
                vec3 rayOrigin = i.rayOrigin;

                // normalize ray vector
                vec3 rayDir = normalize(i.rayDir);

                // ray sphere intersection
                float rayHit = sphIntersect(rayOrigin, rayDir, vec4(0,0,0,0.5));

            #if !defined(_MSAABEHAVIOUR_ALPHATOCOVERAGE)
                // sphere intersection function returns -1 if there's no intersection
                clip(rayHit);
            #endif

                // cheap way to reduce mip map artifacts on edge
                // not 100% accurate, but close enough that it'd be hard to notice
                rayHit = rayHit < 0.0 ? dot(rayDir, -rayOrigin) : rayHit;

                // calculate object space position from ray, front hit ray length, and ray origin
                vec3 surfacePos = rayDir * rayHit + rayOrigin;

                // object space surface normal
                vec3 normal = normalize(surfacePos);

            #if defined(_MAPPING_CUBEMAP)
                // cubemap uvw
                vec3 uvw = surfacePos;

                // swizzle & invert cubemap UVW so it matches equirectangular UVs
                uvw.xz = -uvw.zx;

                // sample cube map
                fixed4 col = texCUBE(_CubeTex, uvw);
            #else
                // -0.5 to 0.5 range
                float phi = atan2(normal.z, normal.x) / (UNITY_PI * 2.0);

                // 0.0 to 1.0 range
                float phi_frac = frac(phi);

                // negate the y because acos(-1.0) = PI, acos(1.0) = 0.0
                float theta = acos(-normal.y) / UNITY_PI;

                // construct the uvs, selecting the phi to use based on the derivatives
                float2 uv = float2(
                    fwidth(phi) < fwidth(phi_frac) - 0.001 ? phi : phi_frac,
                    theta
                    );

            #if MSAA_SUPER_SAMPLE
                // sample the equirectangular texture with an lod bias
                half4 col = tex2Dbias (_MainTex, vec4(uv, 0, -1));
            #else
                // sample the equirectangular texture
                half4 col = tex2D (_MainTex, uv);
            #endif // MSAA_SUPER_SAMPLE
            #endif // _MAPPING_CUBEMAP

                // what shader is complete without a little color tinting?
                col.rgb *= _Color.rgb;

                // world space position and clip space position
                vec3 worldPos = mul(MODELVIEW_MATRIX, vec4(surfacePos, 1.0));
                vec4 clipPos = UnityWorldToClipPos(vec4(worldPos, 1.0));

                // stuff for directional shadow receiving
            #if defined (SHADOWS_SCREEN)
                // setup shadow struct for screen space shadows
                shadowInput shadowIN;
            #if defined(UNITY_NO_SCREENSPACE_SHADOWS)
                // mobile directional shadow
                shadowIN._ShadowCoord = mul(unity_WorldToShadow[0], vec4(worldPos, 1.0));
            #else
                // screen space directional shadow
                shadowIN._ShadowCoord = ComputeScreenPos(clipPos);
            #endif // UNITY_NO_SCREENSPACE_SHADOWS
            #else
                // no shadow, or no directional shadow
                float shadowIN = 0;
            #endif // SHADOWS_SCREEN

                // basic lighting
                half3 worldNormal = UnityObjectToWorldNormal(normal);
                half3 worldLightDir = UnityWorldSpaceLightDir(worldPos);
                half ndotl = saturate(dot(worldNormal, worldLightDir));

                // get shadow, attenuation, and cookie
                UNITY_LIGHT_ATTENUATION(atten, shadowIN, worldPos);

                // per pixel lighting
                half3 lighting = _LightColor0 * ndotl * atten;

            #if defined(UNITY_SHOULD_SAMPLE_SH)
                // ambient lighting
                half3 ambient = ShadeSH9(vec4(worldNormal, 1));
                lighting += ambient;

            #if defined(VERTEXLIGHT_ON)
                // "per vertex" non-important lights
                half3 vertexLighting = Shade4PointLights(
                unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
                unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
                unity_4LightAtten0, worldPos, worldNormal);

                lighting += vertexLighting;
            #endif // VERTEXLIGHT_ON
            #endif // UNITY_SHOULD_SAMPLE_SH

                // apply lighting
                col.rgb *= lighting;

                // output modified depth
                outDepth = clipPos.z / clipPos.w;

            #if !defined(UNITY_REVERSED_Z)
                // openGL platforms need the clip space to be rescaled
                outDepth = outDepth * 0.5 + 0.5;
            #endif

            #if defined(_MSAABEHAVIOUR_ALPHATOCOVERAGE)
                // ray to sphere origin distance
                float rayToPointDist = length(rayDir * dot(rayDir, -rayOrigin) + rayOrigin);

                // fwidth gets the sum of the ddx & ddy partial derivatives
                // float fDist = fwidth(rayToPointDist);

                // fwidth is a coarse approximation of this
                float fDist = length(float2(ddx(rayToPointDist), ddy(rayToPointDist)));

                // sharpen ray to point distance
                // centered on sphere radius, +/- half a pixel based on derivatives
                float alpha = (0.5 - rayToPointDist) / max(fDist, 0.0001) + 0.5;

                // clip based on sharpened alpha
                clip(alpha);

                // clamp alpha to a 0 to 1 range and apply to color
                col.a *= saturate(alpha);
            #endif

                // fog
                float fogCoord = clipPos.z;
            #if (SHADER_TARGET < 30) || defined(SHADER_API_MOBILE)
                // calculate fog falloff and creates a unityFogFactor variable to hold it
                UNITY_CALC_FOG_FACTOR(fogCoord);
                fogCoord = unityFogFactor;
            #endif
                UNITY_APPLY_FOG(fogCoord, col);

                return col;
            }
            #endif

            fixed4 frag_shadow (v2f i
            #if defined(USE_CONSERVATIVE_DEPTH)
                , out float outDepth : SV_DepthLessEqual
            #else
            // the device probably can't use conservative depth
              , out float outDepth : SV_Depth
            #endif
                ) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i);

                // ray origin
                vec3 rayOrigin = i.rayOrigin;

                // normalize ray vector
                vec3 rayDir = normalize(i.rayDir);

                // ray sphere intersection
                float rayHit = sphIntersect(rayOrigin, rayDir, vec4(0,0,0,0.5));

                // above function returns -1 if there's no intersection
                clip(rayHit);

                // calculate object space position from ray, front hit ray length, and ray origin
                vec3 surfacePos = rayDir * rayHit + rayOrigin;

                // output modified depth
                vec4 clipPos = UnityClipSpaceShadowCasterPos(surfacePos, surfacePos);
                clipPos = UnityApplyLinearShadowBias(clipPos);
                outDepth = clipPos.z / clipPos.w;

            #if !defined(UNITY_REVERSED_Z)
                // openGL platforms need the clip space to be rescaled
                outDepth = outDepth * 0.5 + 0.5;
            #endif

                return 0;
            }


}