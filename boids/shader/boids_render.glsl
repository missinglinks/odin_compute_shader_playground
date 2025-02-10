#version 430

in vec2 fragTextCoord;

out vec4 finalColor;

layout(std430, binding=1) readonly buffer boidLayout {
    uint boidPositionBuffer[];
};

void main() {
    ivec2 coords = ivec2(fragTextCoord);

    if (boidPositionBuffer[coords.x + coords.y * 960] == 1) finalColor = vec4(1.0);
    else finalColor = vec4(1.0, 0.0, 0.0, 1.0);
}