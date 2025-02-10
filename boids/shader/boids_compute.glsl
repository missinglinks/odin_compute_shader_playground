#version 430

layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;

layout(rgba8, binding=3) uniform image2D renderTex;

layout(std430, binding=0) restrict buffer Params {
    float boidsN;
    float deltaTime;
    float windowX;
    float windowY;
    float friendDist;
    float avoidDist;
    float cohesionFactor;
    float avoidFactor;
    float alignFactor;
} params;

layout(std430, binding=1) buffer posBuffer {
    vec2 data[];
} position;

layout(std430, binding=2) buffer velBuffer {
    vec2 data[];
} velocity;

void main() {

    int index = int(gl_GlobalInvocationID.x);

    vec2 pos = position.data[index];
    vec2 vel = velocity.data[index];

    int col = int(pos.x);
    int row = int(pos.y);

    imageStore(renderTex, ivec2(col, row), vec4(0,0,0,255));

    int friendsCount = 0;
    vec2 cohesionVec = vec2(0,0);
    vec2 alignVec = vec2(0,0);
    vec2 avoidVec = vec2(0,0);

    for (int i= 0; i < params.boidsN; i+=1) {
        
        if (i != index) {
            vec2 otherPos = position.data[i];
            vec2 otherVel = velocity.data[i];

            vec2 distVector = otherPos - pos;
            float distSqr = dot(distVector, distVector);

            if (distSqr < params.friendDist * params.friendDist) {
                friendsCount += 1;
                cohesionVec += otherPos;
                alignVec += otherVel;
                if (distSqr < params.avoidDist * params.avoidDist) {
                    avoidVec -= distVector * params.avoidFactor * params.deltaTime;
                }
            }
        }
    }

    if (friendsCount > 0) {
        cohesionVec = cohesionVec / float(friendsCount);
        cohesionVec = (cohesionVec - pos) * params.cohesionFactor * params.deltaTime;
        alignVec = (alignVec / float(friendsCount)) * params.alignFactor * params.deltaTime;

        vel += cohesionVec + avoidVec + alignVec;
        if (length(vel) > 10) 
            vel = normalize(vel) * 10;
      
    }
    if (length(vel) < 7.5) 
        vel = normalize(vel) * 7.5;      
    if (pos.x <= 0.0) vel.x += 10.0;
    if (pos.y <= 0.0) vel.y += 10.0;
    if (pos.x >= params.windowX) vel.x -= 10.0;
    if (pos.y >= params.windowY) vel.y -= 10.0;


    pos += vel * params.deltaTime * 3;

    // if (pos.x <= 0.0) pos.x += params.windowX;
    // if (pos.y <= 0.0) pos.y += params.windowY;
    // if (pos.x >= params.windowX) pos.x = 0.0;
    // if (pos.y >= params.windowY) pos.y = 0.0;

    vec2 final_pos = pos;

    position.data[index] = final_pos;
    velocity.data[index] = vel;

    col = int(final_pos.x);
    row = int(final_pos.y);

    if (col > 0.0 && col < params.windowX && row > 0.0 && row < params.windowY)
        imageStore(renderTex, ivec2(col, row), vec4(255,255,255,255));
}

