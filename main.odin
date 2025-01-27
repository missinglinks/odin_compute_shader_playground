package game

import "core:fmt"
import glfw "vendor:glfw"
import rl "vendor:raylib"
import rlgl "vendor:raylib/rlgl"

GOL_WIDTH :: 768
MAX_BUFFERED_TRANSFERTS :: 48

GolUpdateCmd :: struct {
	x:       int,
	y:       int,
	w:       int,
	enabled: int,
}

GolUpdateSSBO :: struct {
	count:    int,
	commands: [MAX_BUFFERED_TRANSFERTS]GolUpdateCmd,
}

main :: proc() {
	rl.InitWindow(GOL_WIDTH, GOL_WIDTH, "GOL")
	defer rl.CloseWindow()

	fmt.println(rlgl.GRAPHICS_API_OPENGL_43)
	fmt.println(rlgl.GetVersion())

	brushSize: int = 8
	golLogicCode := rl.LoadFileText("shader/gol.glsl")
	defer rl.UnloadFileText(golLogicCode)

	golLogicShader := rlgl.CompileShader(cstring(golLogicCode), rlgl.COMPUTE_SHADER)
	golLogicProgram := rlgl.LoadComputeShaderProgram(golLogicShader)

	for (!rl.WindowShouldClose()) {

		rl.BeginDrawing()
		rl.ClearBackground(rl.RED)

		rl.EndDrawing()
	}
}
