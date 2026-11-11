class_name TransitionLayer
extends CanvasLayer
## Capa de transición: "colapso/barrido oscuro" mediante un iris (círculo que se
## cierra/abre) usando un shader. Se construye en código (placeholder visual).

const SHADER_CODE := """
shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 1.0;
uniform vec2 center = vec2(0.5, 0.5);

void fragment() {
	vec2 p = UV - center;
	float d = length(p);
	float hole = mix(-0.1, 1.5, progress);
	float a = smoothstep(hole - 0.03, hole + 0.03, d);
	COLOR = vec4(0.0, 0.0, 0.0, a);
}
"""

var _rect: ColorRect
var _mat: ShaderMaterial
var _progress: float = 1.0

func _ready() -> void:
	layer = 100
	_build()

func _build() -> void:
	_rect = ColorRect.new()
	_rect.anchor_left = 0.0
	_rect.anchor_top = 0.0
	_rect.anchor_right = 1.0
	_rect.anchor_bottom = 1.0
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.visible = false
	var shader := Shader.new()
	shader.code = SHADER_CODE
	_mat = ShaderMaterial.new()
	_mat.shader = shader
	_mat.set_shader_parameter("progress", 1.0)
	_rect.material = _mat
	add_child(_rect)

## Cierra el iris hasta cubrir la pantalla de negro.
func collapse() -> void:
	_rect.visible = true
	await _tween_progress(0.0)

## Abre el iris hasta dejar la pantalla visible.
func expand() -> void:
	await _tween_progress(1.0)
	_rect.visible = false

func _tween_progress(target: float) -> void:
	var tween := create_tween()
	tween.tween_method(_set_progress, _progress, target, 0.4)
	await tween.finished

func _set_progress(v: float) -> void:
	_progress = v
	_mat.set_shader_parameter("progress", v)
