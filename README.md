# Odin Compute Shader Playground

In this repo, I am learning and experimenting with compute shaders using Raylib and the Odin programming language.

## `/gol`

Conway's Game of Life compute shader lifted from the raylib examples: https://github.com/raysan5/raylib/blob/master/examples/others/rlgl_compute_shader.c

![](imgs/gol.gif)

## `/boids`

Boids on the compute shader, inspired by Daniel Schoenmehls Godot compute shader project: https://gitlab.com/niceeffort/boids_compute_shader/-/tree/main

But i haven't implemented any optimizations (yet): on my 3060 mobile it can run ~40000 boids with 60 fps.

![](imgs/boids.gif)

Might add more stuff in the future :D
