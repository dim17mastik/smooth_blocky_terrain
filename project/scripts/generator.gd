# MIT License
#
# Copyright (c) 2025 Dmitry Slabzheninov
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

extends VoxelGeneratorScript
class_name Generator


const _AIR := 0
const _GRASS := 1
const _STONE := 2

const _TERRAIN_AMIPLITUDE := 8.0
const _HILL_HEIGHT := 8.0
const _GRASS_HEIGHT := 2.5
const _HILL_CONDITION := 0.4

var _field_noise := FastNoiseLite.new()
var _hill_noise := FastNoiseLite.new()

# For each 8-bit mask there is a shape ID.
var _shapes := PackedInt32Array([
#   x0  x1  x2  x3  x4  x5  x6  x7  x8  x9  xA  xB  xC  xD  xE  xF
	00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, # 0x
	00, 00, 00, 00, 00, 00, 00, 01, 00, 00, 00, 00, 00, 00, 00, 01, # 1x
	00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 02, 00, 00, 00, 02, # 2x
	00, 00, 00, 00, 00, 00, 00, 01, 00, 00, 00, 02, 00, 00, 00, 03, # 3x
	00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 04, 00, 04, # 4x
	00, 00, 00, 00, 00, 00, 00, 01, 00, 00, 00, 00, 00, 04, 00, 05, # 5x
	00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 29, # 6x
	00, 06, 00, 06, 00, 06, 00, 07, 00, 00, 00, 29, 00, 29, 00, 08, # 7x
	00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 09, 09, # 8x
	00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 29, # 9x
	00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 02, 00, 00, 09, 10, # Ax
	00, 00, 11, 11, 00, 00, 00, 29, 00, 00, 11, 12, 00, 00, 29, 13, # Bx
	00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 00, 04, 09, 14, # Cx
	00, 00, 00, 00, 15, 15, 00, 29, 00, 00, 00, 00, 15, 16, 29, 17, # Dx
	00, 00, 00, 00, 00, 00, 00, 00, 18, 00, 18, 29, 18, 29, 19, 20, # Ex
	00, 06, 11, 21, 15, 22, 29, 23, 18, 29, 24, 25, 26, 27, 28, 29, # Fx
])


func _init() -> void:
	_field_noise.seed = 0
	_hill_noise.seed = 1

	# Disabling the fractal removes the sharp breaks in the hills.
	_hill_noise.fractal_type = FastNoiseLite.FRACTAL_NONE


func _generate(x: float, y: float, z: float) -> int:
	var height := _field_noise.get_noise_2d(x, z) * _TERRAIN_AMIPLITUDE
	if _hill_noise.get_noise_2d(x, z) > _HILL_CONDITION:
		height += _HILL_HEIGHT
	if y <= height - _GRASS_HEIGHT:
		return _STONE
	if y <= height:
		return _GRASS
	return _AIR


func _generate_block(buffer: VoxelBuffer, origin: Vector3i, _lod: int) -> void:
	var chunk := PackedInt32Array()
	chunk.resize(17 * 17 * 17)
	for z in 17:
		for y in 17:
			for x in 17:
				chunk[x + 17 * y + 17 * 17 * z] = _generate(
					origin.x + x, origin.y + y, origin.z + z
				)

	for z in 16:
		for y in 16:
			for x in 16:
				var v0 := chunk[x + 0 + 17 * (y + 0) + 17 * 17 * (z + 0)]
				var v1 := chunk[x + 1 + 17 * (y + 0) + 17 * 17 * (z + 0)]
				var v2 := chunk[x + 0 + 17 * (y + 1) + 17 * 17 * (z + 0)]
				var v3 := chunk[x + 1 + 17 * (y + 1) + 17 * 17 * (z + 0)]
				var v4 := chunk[x + 0 + 17 * (y + 0) + 17 * 17 * (z + 1)]
				var v5 := chunk[x + 1 + 17 * (y + 0) + 17 * 17 * (z + 1)]
				var v6 := chunk[x + 0 + 17 * (y + 1) + 17 * 17 * (z + 1)]
				var v7 := chunk[x + 1 + 17 * (y + 1) + 17 * 17 * (z + 1)]

				# It might seem more logical to determine a voxel's type by its
				# center. In this case, a voxel might sometimes be assigned the
				# AIR type but not an empty shape, leaving it unclear what to
				# do.
				#
				# Here it could be a nice C like "var type = v0 or v1 or ...".
				# Unfortunately in gdscript this only works with booleans.
				var type := 0
				if v0:
					type = v0
				elif v1:
					type = v1
				elif v2:
					type = v2
				elif v3:
					type = v3
				elif v4:
					type = v4
				elif v5:
					type = v5
				elif v6:
					type = v6
				elif v7:
					type = v7

				# Each bit of the 8-bit mask indicates whether a cube vertex is
				# used or not.
				var mask := (
					((1 if v0 != _AIR else 0) << 0) |
					((1 if v1 != _AIR else 0) << 1) |
					((1 if v2 != _AIR else 0) << 2) |
					((1 if v3 != _AIR else 0) << 3) |
					((1 if v4 != _AIR else 0) << 4) |
					((1 if v5 != _AIR else 0) << 5) |
					((1 if v6 != _AIR else 0) << 6) |
					((1 if v7 != _AIR else 0) << 7)
				)

				var shape := _shapes[mask]
				if shape == 0:
					continue

				buffer.set_voxel(
					29 * (type - 1) + shape, x, y, z, VoxelBuffer.CHANNEL_TYPE
				)


func _get_used_channels_mask() -> int:
	return VoxelBuffer.CHANNEL_TYPE_BIT
