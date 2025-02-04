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

	// logic compute shader
	golLogicCode := rl.LoadFileText("shader/gol.glsl")
	defer rl.UnloadFileText(golLogicCode)

	golLogicShader := rlgl.CompileShader(cstring(golLogicCode), rlgl.COMPUTE_SHADER)
	golLogicProgram := rlgl.LoadComputeShaderProgram(golLogicShader)

	// render shader
	golRenderShader := rl.LoadShader(nil, "shader/gol_render.glsl")
	resUniformLoc := rl.GetShaderLocation(golRenderShader, "resolution")

	// gol transfert shader
	golTransfertCode := rl.LoadFileText("shader/gol_transfert.glsl")
	defer rl.UnloadFileText(golTransfertCode)

	golTransfertShader := rlgl.CompileShader(cstring(golTransfertCode), rlgl.COMPUTE_SHADER)
	golTransfertProgram := rlgl.LoadComputeShaderProgram(golTransfertShader)

	// storag buffer object
	ssboA := rlgl.LoadShaderBuffer(GOL_WIDTH * GOL_WIDTH * size_of(uint), nil, rlgl.DYNAMIC_COPY)
	ssboB := rlgl.LoadShaderBuffer(GOL_WIDTH * GOL_WIDTH * size_of(uint), nil, rlgl.DYNAMIC_COPY)
	ssboTransfert := rlgl.LoadShaderBuffer(size_of(GolUpdateSSBO), nil, rlgl.DYNAMIC_COPY)

	transfertBuffer: GolUpdateSSBO


	// draw texture
	whiteImage := rl.GenImageColor(GOL_WIDTH, GOL_WIDTH, rl.WHITE)
	whiteTex := rl.LoadTextureFromImage(whiteImage)
	defer rl.UnloadImage(whiteImage)

	for (!rl.WindowShouldClose()) {

		rl.BeginDrawing()
		rl.ClearBackground(rl.RED)


		rl.EndDrawing()
	}

	rlgl.UnloadShaderBuffer(ssboA)
	rlgl.UnloadShaderBuffer(ssboB)
	rlgl.UnloadShaderBuffer(ssboTransfert)

	rlgl.UnloadShaderProgram(golTransfertProgram)
	rlgl.UnloadShaderProgram(golLogicProgram)

	rl.UnloadTexture(whiteTex)
	rl.UnloadShader(golRenderShader)

}
