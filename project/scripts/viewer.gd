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

extends Node3D


const _MOVEMENT_SPEED := 100.0
const _ROTATION_SPEED := 1.0

@onready var _camera := $Camera as Camera3D


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("fullscreen"):
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_FULLSCREEN
			if DisplayServer.window_get_mode() !=
			DisplayServer.WINDOW_MODE_FULLSCREEN
			else DisplayServer.WINDOW_MODE_WINDOWED
		)


func _process(delta: float) -> void:
	var movement := Input.get_vector(
		"move_left", "move_right", "move_forward", "move_back"
	) * _MOVEMENT_SPEED * delta

	position += _camera.global_basis.x * movement.x

	var front := _camera.global_basis.x.rotated(Vector3.UP, -PI * 0.5)
	position += front * movement.y

	rotation.y += (
		Input.get_axis("rotate_right", "rotate_left") * _ROTATION_SPEED * delta
	)
