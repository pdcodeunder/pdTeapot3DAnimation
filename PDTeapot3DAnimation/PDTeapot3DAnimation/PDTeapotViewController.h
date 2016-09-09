//
//  ViewController.h
//  PDTeapot3DAnimation
//
//  Created by 彭懂 on 16/9/9.
//  Copyright © 2016年 彭懂. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "PDTeapotBaseEffect.h"
#import "PDMusicCube.h"

@interface PDTeapotViewController : GLKViewController
{
    EAGLContext *context;    // 实现和提供一个呈现环境
    GLuint mode;
    // 茶壶
    GLfloat rot;
    // 正方体
    GLfloat cubePos[3];
    GLfloat cubeRot;
    GLuint cubeTexture;
}

@property (nonatomic, strong) PDTeapotBaseEffect *innerCircle;
@property (nonatomic, strong) PDTeapotBaseEffect *outerCircle;
@property (nonatomic, strong) PDTeapotBaseEffect *teapot;
@property (nonatomic, strong) NSMutableArray *cubeEffectArr;
@property (nonatomic, strong) PDMusicCube *musicCube;

@end

