//
//  PDTeapotViewController.m
//  PDTeapot3DAnimation
//
//  Created by 彭懂 on 16/9/9.
//  Copyright © 2016年 彭懂. All rights reserved.
//

#import "PDTeapotViewController.h"

@implementation PDTeapotViewController

- (PDMusicCube *)musicCube {
    if (!_musicCube) {
        _musicCube = [[PDMusicCube alloc] init];
    }
    return _musicCube;
}

- (NSMutableArray *)cubeEffectArr
{
    if (!_cubeEffectArr) {
        _cubeEffectArr = [[NSMutableArray alloc] init];
    }
    return _cubeEffectArr;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    // 创建环境失败，或者将当前线程环境设置失败
    if (!context || ![EAGLContext setCurrentContext:context]) {
        return;
    }
    GLKView *glView = (GLKView *)self.view;
    glView.context = context;
    glView.drawableDepthFormat = GLKViewDrawableDepthFormat16;
    
    mode = 1;
    glEnable(GL_DEPTH_TEST);
    
    // 创建效果路径
    self.innerCircle = [PDTeapotBaseEffect makeCircleWithNumOfSegments:circleSegments radius:pathCircleRadius];
    self.outerCircle = [PDTeapotBaseEffect makeCircleWithNumOfSegments:circleSegments radius:pathOutCircleRadius];
    
    // 创建茶壶
    self.teapot = [PDTeapotBaseEffect makeTeapot];
    
    // 创建正方体
    self.cubeEffectArr = [PDTeapotBaseEffect makeCube];
    
    [self setUpCubeEffect];
    
    [self setUpMusicCube];
}

// 设置正方体上的图片效果
- (void)setUpCubeEffect
{
    UIImage *image = [UIImage imageNamed:@"speaker"];
    GLKTextureLoader *textureloader = [[GLKTextureLoader alloc] initWithSharegroup:context.sharegroup];
    [textureloader textureWithCGImage:image.CGImage options:nil queue:nil completionHandler:^(GLKTextureInfo *textureInfo, NSError *error) {
        if(error) {
            NSLog(@"Error loading texture %@",error);
        }
        else {
            for (int f=0; f<6; f++)
                ((PDTeapotBaseEffect *)self.cubeEffectArr[f]).effect.texture2d0.name = textureInfo.name;
            
            cubeTexture = textureInfo.name;
        }
    }];
}

// 设置背景音乐
- (void)setUpMusicCube {
    // 初始化配置
    self.musicCube.sourcePos[0] = self.musicCube.sourcePos[1] = self.musicCube.sourcePos[2] = 0;
    self.musicCube.listenerPos[0] = 0;
    self.musicCube.listenerPos[1] = (pathCircleRadius + pathOutCircleRadius) / 2.0;
    self.musicCube.listenerPos[2] = 0;
    self.musicCube.listenerRotation = 0;
    [self.musicCube startSound];
}

#pragma mark - 重绘
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(0.0, 0, 0, 1.0);
    glClearDepthf(1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    GLfloat aspectRatio = (GLfloat)(view.drawableWidth) / (GLfloat)(view.drawableHeight);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(-1.0f, 1.0f, -1.0f/aspectRatio, 1.0f/aspectRatio, -10.0f, 10.0f);
    projectionMatrix = GLKMatrix4Rotate(projectionMatrix, DegreesToRadians(-30.0f), 0.0f, 1.0f, 0.0f);
    
    // set the projection matrix
    self.innerCircle.effect.transform.projectionMatrix = projectionMatrix;
    self.outerCircle.effect.transform.projectionMatrix = projectionMatrix;
    self.teapot.effect.transform.projectionMatrix = projectionMatrix;
    for (int f=0; f<6; f++)
        ((PDTeapotBaseEffect *)self.cubeEffectArr[f]).effect.transform.projectionMatrix = projectionMatrix;
    
    glBindVertexArrayOES(self.innerCircle.vertexArray);
    [self.innerCircle.effect prepareToDraw];
    glDrawArrays (GL_LINE_LOOP, 0, circleSegments);
    
    glBindVertexArrayOES(self.outerCircle.vertexArray);
    [self.outerCircle.effect prepareToDraw];
    glDrawArrays (GL_LINE_LOOP, 0, circleSegments);
    
    [self drawTeapotAndUpdatePlayback];
    
    [self drawCube];
}

- (void)drawTeapotAndUpdatePlayback
{
    rot -= 1.0f;
    GLfloat radius = (pathOutCircleRadius + pathCircleRadius) / 2.;
    GLfloat teapotPos[3] = {0.0f, cos(DegreesToRadians(rot))*radius, sin(DegreesToRadians(rot))*radius};
    
    // 沿着圆环做运动
    GLKMatrix4 modelView = GLKMatrix4MakeTranslation(teapotPos[0], teapotPos[1], teapotPos[2]);
    modelView = GLKMatrix4Scale(modelView, kTeapotScale, kTeapotScale, kTeapotScale);
    
    // 添加旋转效果
    GLfloat rotYInRadians;
    if (mode == 2 || mode == 4)
        rotYInRadians = 0.0f;
    else
        rotYInRadians = atan2(teapotPos[2]-cubePos[2], teapotPos[1]-cubePos[1]);
    
    modelView = GLKMatrix4Rotate(modelView, -M_PI_2, 0, 0, 1);
    modelView = GLKMatrix4Rotate(modelView, rotYInRadians, 0, 1, 0);
    
    self.teapot.effect.transform.modelviewMatrix = modelView;
    
    glBindVertexArrayOES(self.teapot.vertexArray);
    [self.teapot.effect prepareToDraw];
    
    [PDTeapotBaseEffect musicBack];
    
    self.musicCube.listenerPos = teapotPos;
    self.musicCube.listenerRotation = rotYInRadians - M_PI;
}

- (void)drawCube
{
    cubeRot += 3;
    
    GLKMatrix4 modelView = GLKMatrix4MakeTranslation(cubePos[0], cubePos[1], cubePos[2]);
    modelView = GLKMatrix4Scale(modelView, kCubeScale, kCubeScale, kCubeScale);
    
    if (mode <= 2)
        modelView = GLKMatrix4Translate(modelView, 1.0f, 0.0f, 0.0f);
    else
        modelView = GLKMatrix4Translate(modelView, 4.5f, 0.0f, 0.0f);
    
    modelView = GLKMatrix4Rotate(modelView, DegreesToRadians(cubeRot), 1, 0, 0);
    modelView = GLKMatrix4Rotate(modelView, DegreesToRadians(cubeRot), 0, 1, 1);
    
    for (int f=0; f<6; f++) {
        ((PDTeapotBaseEffect *)self.cubeEffectArr[f]).effect.transform.modelviewMatrix = modelView;
        
        glBindVertexArrayOES(((PDTeapotBaseEffect *)self.cubeEffectArr[f]).vertexArray);
        [((PDTeapotBaseEffect *)self.cubeEffectArr[f]).effect prepareToDraw];
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    }
}

@end
