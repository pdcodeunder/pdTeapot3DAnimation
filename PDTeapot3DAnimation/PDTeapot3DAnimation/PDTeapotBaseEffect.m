//
//  PDTeapotBaseEffect.m
//  PDTeapot3DAnimation
//
//  Created by 彭懂 on 16/9/8.
//  Copyright © 2016年 彭懂. All rights reserved.
//

#import "PDTeapotBaseEffect.h"
#import "teapot.h"

const GLshort cubeVertices[6][20] = {
    { 1,-1, 1, 1, 0,   -1,-1, 1, 1, 1,   1, 1, 1, 0, 0,  -1, 1, 1, 0, 1 },
    { 1, 1, 1, 1, 0,    1,-1, 1, 1, 1,   1, 1,-1, 0, 0,   1,-1,-1, 0, 1 },
    {-1, 1,-1, 1, 0,   -1,-1,-1, 1, 1,  -1, 1, 1, 0, 0,  -1,-1, 1, 0, 1 },
    { 1, 1, 1, 1, 0,   -1, 1, 1, 1, 1,   1, 1,-1, 0, 0,  -1, 1,-1, 0, 1 },
    { 1,-1,-1, 1, 0,   -1,-1,-1, 1, 1,   1, 1,-1, 0, 0,  -1, 1,-1, 0, 1 },
    { 1,-1, 1, 1, 0,   -1,-1, 1, 1, 1,   1,-1,-1, 0, 0,  -1,-1,-1, 0, 1 },
};

const GLushort cubeColors[6][4] = {
    {1, 0, 0, 1}, {0, 1, 0, 1}, {0, 0, 1, 1}, {1, 1, 0, 1}, {0, 1, 1, 1}, {1, 0, 1, 1},
};

@implementation PDTeapotBaseEffect

+ (instancetype)makeCircleWithNumOfSegments:(GLuint)segments radius:(GLfloat)radius
{
    PDTeapotBaseEffect *pdeffect = [[PDTeapotBaseEffect alloc] init];
    GLfloat vertices[circleSegments * 3];
    GLint count = 0;
    for (GLfloat i = 0; i < 360.0f; i += 360.0f/segments)
    {
        vertices[count++] = 0;									//x
        vertices[count++] = (cos(DegreesToRadians(i))*radius);	//y
        vertices[count++] = (sin(DegreesToRadians(i))*radius);	//z
    }
    
    GLKBaseEffect *effect = [[GLKBaseEffect alloc] init];
    effect.useConstantColor = YES;
    effect.constantColor = GLKVector4Make(0.2f, 0.7f, 0.2f, 1.0f);
    
    GLuint vertexArray, vertexBuffer;
    
    glGenVertexArraysOES(1, &vertexArray);
    glBindVertexArrayOES(vertexArray);
    
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, BUFFER_OFFSET(0));
    
    glBindVertexArrayOES(0);
    
    pdeffect.effect = effect;
    pdeffect.vertexArray = vertexArray;
    pdeffect.vertexBuffer = vertexBuffer;
    pdeffect.normalBuffer = 0;
    
    return pdeffect;
}

+ (instancetype)makeTeapot
{
    PDTeapotBaseEffect *teapot = [[PDTeapotBaseEffect alloc] init];
    GLKBaseEffect *effect = [[GLKBaseEffect alloc] init];
    // 材料
    effect.material.ambientColor = GLKVector4Make(0.4, 0.8, 0.4, 1.0);
    effect.material.diffuseColor = GLKVector4Make(1.0, 1.0, 1.0, 1.0);
    effect.material.specularColor = GLKVector4Make(1.0, 1.0, 1.0, 1.0);
    effect.material.shininess = 100.0;
    // 光
    effect.light0.enabled = GL_TRUE;
    effect.light0.ambientColor = GLKVector4Make(0.2, 0.2, 0.2, 1.0);
    effect.light0.diffuseColor = GLKVector4Make(0.2, 0.7, 0.2, 1.0);
    effect.light0.position = GLKVector4Make(0.0, 0.0, 1.0, 0.0);
    
    GLuint vertexArray, vertexBuffer, normalBuffer;
    
    glGenVertexArraysOES(1, &vertexArray);
    glBindVertexArrayOES(vertexArray);
    
    // 位置
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(teapot_vertices), teapot_vertices, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, BUFFER_OFFSET(0));
    
    glGenBuffers(1, &normalBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, normalBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(teapot_normals), teapot_normals, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 0, BUFFER_OFFSET(0));
    
    glBindVertexArrayOES(0);
    
    teapot.effect = effect;
    teapot.vertexArray = vertexArray;
    teapot.vertexBuffer = vertexBuffer;
    teapot.normalBuffer = normalBuffer;
    return teapot;
}

+ (NSMutableArray *)makeCube
{
    NSMutableArray *cubeArr = [[NSMutableArray alloc] init];
    for (int f = 0; f < 6; f++)
    {
        PDTeapotBaseEffect *cube = [[PDTeapotBaseEffect alloc] init];
        GLKBaseEffect *effect = [[GLKBaseEffect alloc] init];
        effect.texture2d0.enabled = GL_TRUE;
        effect.useConstantColor = GL_TRUE;
        effect.constantColor = GLKVector4Make(cubeColors[f][0], cubeColors[f][1], cubeColors[f][2], cubeColors[f][3]);
        
        GLuint vertexArray, vertexBuffer;
        
        glGenVertexArraysOES(1, &vertexArray);
        glBindVertexArrayOES(vertexArray);
        
        glGenBuffers(1, &vertexBuffer);
        glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
        glBufferData(GL_ARRAY_BUFFER, sizeof(cubeVertices[f]), cubeVertices[f], GL_STATIC_DRAW);
        
        glEnableVertexAttribArray(GLKVertexAttribPosition);
        glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_SHORT, GL_FALSE, 10, BUFFER_OFFSET(0));

        glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
        glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_SHORT, GL_FALSE, 10, BUFFER_OFFSET(6));
        
        glBindVertexArrayOES(0);
        
        cube.effect = effect;
        cube.vertexArray = vertexArray;
        cube.vertexBuffer = vertexBuffer;
        cube.normalBuffer = 0;
        
        [cubeArr addObject:cube];
    }
    
    return cubeArr;
}


+ (void)musicBack
{
    int	start = 0, i = 0;
    while(i < num_teapot_indices) {
        if(teapot_indices[i] == -1) {
            glDrawElements(GL_TRIANGLE_STRIP, i - start, GL_UNSIGNED_SHORT, &teapot_indices[start]);
            start = i + 1;
        }
        i++;
    }
    if(start < num_teapot_indices)
        glDrawElements(GL_TRIANGLE_STRIP, i - start - 1, GL_UNSIGNED_SHORT, &teapot_indices[start]);
}


@end
