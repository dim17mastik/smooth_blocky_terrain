/**
* MIT License
*
* Copyright (c) 2025 Dmitry Slabzheninov
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

shader_type spatial;

// Lambert looks simpler. Specular not needed.
render_mode diffuse_lambert, specular_disabled;

uniform sampler2D atlas: filter_nearest_mipmap;

varying vec3 position;

// A custom noise function. It looks quite random, but it's best not used for
// anything serious.
vec3 noise(ivec3 v) {
	uvec3 a = uvec3(v);

	// Magic numbers are random large prime numbers.
	uvec3 b = a.xyz * 840979147u ^ a.yzx * 794601763u ^ a.zxy * 561992897u;
	b *= 829432259u;

	// Only 24 bits are used because float cannot store integers larger than
	// 2^24 - 1 (16777215) without loss. Any larger than that and the noise
	// becomes distorted.
	return vec3(b & uvec3(0x00ffffffu)) * (1.0 / 16777215.0);
}

void vertex() {
	position = VERTEX.xyz;
}

void fragment() {
	vec3 color = texture(atlas, UV).rgb;

	// Ideally, the noise should be in the vertex function, but based only on
	// the vertex coordinate, it is impossible to determine which voxel the
	// vertex belongs to. This can be fixed with a custom attribute with a voxel
	// coordinate.
	vec3 noise_value = noise(ivec3(position));

	// Darkening with distance to make it more convenient in orthographic
	// projection.
	float depth_falloff = 200.0;
	float depth_power = 2.0;
	float depth = pow(1.0 + VERTEX.z / depth_falloff, depth_power);

	ALBEDO = color * (0.7 + noise_value * 0.3) * depth;
}