package boids

import "core:fmt"
import "core:math/rand"
import rl "vendor:raylib"

Vector2i :: struct {
	x: i16,
	y: i16,
}

WINDOW_SIZE :: Vector2i{960, 540}
BOID_N :: 500

FRIEND_DIST :: 60.0
AVOID_DIST :: 10.0

COHESION_FACTOR :: 0.05
AVOIDANCE_FACTOR :: 1
ALIGNMENT_FACTOR :: 0.3

MAX_SPEED :: 2

BoidData :: struct {
	pos: [BOID_N]rl.Vector2,
	vel: [BOID_N]rl.Vector2,
}

boid_data: BoidData

main :: proc() {

	// initialize boids with random position and random velocity
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

	for !rl.WindowShouldClose() {

		// update boids
		for i in 0 ..< BOID_N {
			friend_n, void_n: int
			align_v, cohesion_v, avoid_v: rl.Vector2

			// check for neighbors
			for j in 0 ..< BOID_N {
				if i == j {continue}
				dist := rl.Vector2DistanceSqrt(boid_data.pos[i], boid_data.pos[j])
				if dist < FRIEND_DIST * FRIEND_DIST {
					vec := boid_data.pos[j] - boid_data.pos[i]
					friend_n += 1
					cohesion_v += boid_data.pos[j]
					align_v += boid_data.vel[j]
					if dist < AVOID_DIST * AVOID_DIST {
						avoid_v -= vec * AVOIDANCE_FACTOR * rl.GetFrameTime()
					}
				}
			}

			// if neighours found set new velocity based on boids rules
			if friend_n > 0 {
				cohesion_v = (cohesion_v / f32(friend_n))
				cohesion_v = (cohesion_v - boid_data.pos[i]) * COHESION_FACTOR * rl.GetFrameTime()
				align_v = (align_v / f32(friend_n)) * ALIGNMENT_FACTOR * rl.GetFrameTime()
				boid_data.vel[i] += cohesion_v + avoid_v + align_v
				if rl.Vector2LengthSqr(boid_data.vel[i]) > MAX_SPEED * MAX_SPEED {
					boid_data.vel[i] = rl.Vector2Normalize(boid_data.vel[i]) * MAX_SPEED
				}
			}

			// set new boid position
			boid_data.pos[i] += boid_data.vel[i] * rl.GetFrameTime() * 50

			// wrap boids around screen bordres
			if boid_data.pos[i].x < 0 {
				boid_data.pos[i].x = f32(WINDOW_SIZE.x - 2)
			} else if boid_data.pos[i].x > f32(WINDOW_SIZE.x) {
				boid_data.pos[i].x = 1
			} else if boid_data.pos[i].y < 0 {
				boid_data.pos[i].y = f32(WINDOW_SIZE.y - 2)
			} else if boid_data.pos[i].y > f32(WINDOW_SIZE.y) {
				boid_data.pos[i].y = 1
			}
		}

		// draw stuff
		rl.BeginDrawing()
		rl.ClearBackground(rl.WHITE)
		for i in 0 ..< BOID_N {
			pos := boid_data.pos[i]
			rl.DrawCircle(i32(pos.x), i32(pos.y), 3, rl.RED)
		}
		rl.DrawFPS(10, 10)
		rl.EndDrawing()
	}
}
