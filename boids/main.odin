package boids

import "core:c"
import "core:fmt"
import "core:math"
import "core:math/rand"
import rl "vendor:raylib"
import rlgl "vendor:raylib/rlgl"

Vector2i :: struct {
	x: i16,
	y: i16,
}

WINDOW_SIZE :: Vector2i{960, 540}
BOID_N :: 40000

FRIEND_DIST :: 10.0
AVOID_DIST :: 3.0

COHESION_FACTOR :: 0.125
AVOIDANCE_FACTOR :: 05.105
ALIGNMENT_FACTOR :: 1.5095

MAX_SPEED :: 2

BoidData :: struct {
	pos: [BOID_N]rl.Vector2,
	vel: [BOID_N]rl.Vector2,
}

Params :: struct {
	boids_n:         f32,
	delta_time:      f32,
	window_x:        f32,
	window_y:        f32,
	friend_dist:     f32,
	avoid_dist:      f32,
	cohesion_factor: f32,
	avoid_factor:    f32,
	align_factor:    f32,
}

boid_data: BoidData
params := Params {
	BOID_N,
	0,
	f32(WINDOW_SIZE.x),
	f32(WINDOW_SIZE.y),
	FRIEND_DIST,
	AVOID_DIST,
	COHESION_FACTOR,
	AVOIDANCE_FACTOR,
	ALIGNMENT_FACTOR,
}

load_compute_shader :: proc(file: cstring) -> c.uint {
	shader_code := rl.LoadFileText(file)
	defer rl.UnloadFileText(shader_code)
	return rlgl.CompileShader(cstring(shader_code), rlgl.COMPUTE_SHADER)
}


main :: proc() {

	// initialize boids with random position and random velocity
	rng := rand.create(123456)
	//context.random_generator = rng
	for i in 0 ..< BOID_N {
		boid_data.pos[i] = {
			rand.float32_range(1, f32(WINDOW_SIZE.x - 1)),
			rand.float32_range(1, f32(WINDOW_SIZE.y - 1)),
		}

		boid_data.vel[i] =
			rl.Vector2Normalize({rand.float32_range(-1, 1), rand.float32_range(-1, 1)}) * MAX_SPEED
	}


	rl.InitWindow(i32(WINDOW_SIZE.x), i32(WINDOW_SIZE.y), "Boids")
	defer rl.CloseWindow()

	// load compute shader
	boids_shader := load_compute_shader("shader/boids_compute.glsl")
	boids_shader_prog := rlgl.LoadComputeShaderProgram(boids_shader)

	// load render shader
	fmt.println("SHADER")
	boidsRenderShader := rl.LoadShader(nil, "shader/boids_render.glsl")

	// draw texture
	img := rl.GenImageColor(i32(WINDOW_SIZE.x), i32(WINDOW_SIZE.y), rl.BLACK)
	rl.ImageFormat(&img, .UNCOMPRESSED_R8G8B8A8)
	tex := rl.LoadTextureFromImage(img)
	defer rl.UnloadImage(img)

	tex_data := rlgl.ReadTexturePixels(
		tex.id,
		i32(WINDOW_SIZE.x),
		i32(WINDOW_SIZE.y),
		i32(rl.PixelFormat.UNCOMPRESSED_R8G8B8A8),
	)

	// bind image texture
	rlgl.BindImageTexture(tex.id, 3, i32(tex.format), false)

	// create ssbo
	ssbo_params := rlgl.LoadShaderBuffer(BOID_N * size_of(Params), nil, rlgl.DYNAMIC_COPY)
	ssbo_pos := rlgl.LoadShaderBuffer(BOID_N * size_of(rl.Vector2), nil, rlgl.DYNAMIC_COPY)
	ssbo_vel := rlgl.LoadShaderBuffer(BOID_N * size_of(rl.Vector2), nil, rlgl.DYNAMIC_COPY)

	rlgl.BindShaderBuffer(ssbo_params, 0)
	rlgl.BindShaderBuffer(ssbo_pos, 1)
	rlgl.BindShaderBuffer(ssbo_vel, 2)

	rlgl.UpdateShaderBuffer(ssbo_pos, &boid_data.pos, size_of(rl.Vector2) * BOID_N, 0)
	rlgl.UpdateShaderBuffer(ssbo_vel, &boid_data.vel, size_of(rl.Vector2) * BOID_N, 0)

	for !rl.WindowShouldClose() {
		rlgl.UpdateTexture(
			tex.id,
			0,
			0,
			i32(WINDOW_SIZE.x),
			i32(WINDOW_SIZE.y),
			i32(rl.PixelFormat.UNCOMPRESSED_R8G8B8A8),
			tex_data,
		)

		pixels := new([i32(WINDOW_SIZE.x) * i32(WINDOW_SIZE.y) + 1]rl.Color)
		defer free(pixels)

		params.delta_time = rl.GetFrameTime()
		rlgl.UpdateShaderBuffer(ssbo_params, &params, size_of(Params), 0)

		rlgl.EnableShader(boids_shader_prog)
		rlgl.ComputeShaderDispatch(u32(math.round_f32(f32(BOID_N) / f32(64.0))) + 1, 1, 1)
		rlgl.DisableShader()


		// draw stuff
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		rl.DrawTexture(tex, 0, 0, rl.WHITE)

		rl.DrawFPS(10, 10)
		rl.EndDrawing()
	}
}
