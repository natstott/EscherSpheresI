Various examples of sphere impostors. Work in Progress.
The aim is to develop an instanced shader for a sphere impostor that can 
provide textured spheres using quads for particles or other simulations
where visual appearance is not as important as proessing speed

Based on:

https://godotshaders.com/shader/ray-traced-sphere-for-particle-effects/
tranquilmarmot 
	
https://bgolus.medium.com/rendering-a-sphere-on-a-quad-13c92025570c
Ben Golus
	
https://github.com/danilw/Godot4-Sphere-as-particle-do-not-use-Sphere-mesh-as-particle
DanilW

General concept-
for each fragment of a quad, identify the ray direction from the camera that would hit it.
Calculate where on the surface of a sphere that would impact.
Shade the fragment s if it was that point on the surface.

Difficulties - DanilW and Tranquil marmot have a sphere with normals and lighting that works.
But having calculated the ray in view space, translating back to model space in the frag shader
to find the right texture UVs to use. Accounting for rotation.

All solved by Ben Golus shader in Unity, but mapping the right transforms in Godot is
proving difficult.
