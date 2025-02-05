package game

import "core:fmt"
import glfw "vendor:glfw"
import rl "vendor:raylib"
import rlgl "vendor:raylib/rlgl"

GOL_WIDTH :: 768
MAX_BUFFERED_TRANSFERTS :: 48

GolUpdateCmd :: struct {
	x:       i32,
	y:       i32,
	w:       i32,
	enabled: bool,
}

GolUpdateSSBO :: struct {
	count:    i32,
	commands: [MAX_BUFFERED_TRANSFERTS]GolUpdateCmd,
}


main :: proc() {
	rl.InitWindow(GOL_WIDTH, GOL_WIDTH, "GOL")
	defer rl.CloseWindow()

	resolution := rl.Vector2{GOL_WIDTH, GOL_WIDTH}

	fmt.println(rlgl.GRAPHICS_API_OPENGL_43)
	fmt.println(rlgl.GetVersion())

	brushSize: i32 = 8

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

	rl.SetTargetFPS(60)

	for (!rl.WindowShouldClose()) {

		//update

		brushSize += i32(rl.GetMouseWheelMove())
		if (rl.IsMouseButtonDown(.LEFT) || rl.IsMouseButtonDown(.RIGHT)) &&
		   (transfertBuffer.count < MAX_BUFFERED_TRANSFERTS) {
			//Buffer command
			transfertBuffer.commands[transfertBuffer.count].x =
				rl.GetMouseX() - i32(f32(brushSize) / 2.0)
			transfertBuffer.commands[transfertBuffer.count].y =
				rl.GetMouseY() - i32(f32(brushSize) / 2.0)

			transfertBuffer.commands[transfertBuffer.count].w = brushSize
			transfertBuffer.commands[transfertBuffer.count].enabled = rl.IsMouseButtonDown(.LEFT)


			transfertBuffer.count += 1
		} else if transfertBuffer.count > 0 {
			// send ssbo buffer to gpu
			rlgl.UpdateShaderBuffer(ssboTransfert, &transfertBuffer, size_of(GolUpdateSSBO), 0)

			// process ssbo commands on gpu
			rlgl.EnableShader(golTransfertProgram)
			rlgl.BindShaderBuffer(ssboA, 1)
			rlgl.BindShaderBuffer(ssboTransfert, 3)
			rlgl.ComputeShaderDispatch(u32(transfertBuffer.count), 1, 1)
			rlgl.DisableShader()

			transfertBuffer.count = 0
		} else {
			rlgl.EnableShader(golLogicProgram)
			rlgl.BindShaderBuffer(ssboA, 1)
			rlgl.BindShaderBuffer(ssboB, 2)
			rlgl.ComputeShaderDispatch(GOL_WIDTH / 16, GOL_WIDTH / 16, 1)
			rlgl.DisableShader()

			tmp := ssboA
			ssboA = ssboB
			ssboB = tmp
		}


		rlgl.BindShaderBuffer(ssboA, 1)
		rl.SetShaderValue(golRenderShader, resUniformLoc, &resolution, .VEC2)

		//drw
		rl.BeginDrawing()
		rl.ClearBackground(rl.BLANK)

		rl.BeginShaderMode(golRenderShader)
		rl.DrawTexture(whiteTex, 0, 0, rl.WHITE)
		rl.EndShaderMode()

		rl.DrawRectangleLines(
			rl.GetMouseX() - i32(brushSize / 2),
			rl.GetMouseY() - i32(brushSize / 2),
			brushSize,
			brushSize,
			rl.RED,
		)

		rl.DrawFPS(rl.GetScreenWidth() - 100, 10)

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
