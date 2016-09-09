//
//  PDTeapotBaseEffect.h
//  PDTeapot3DAnimation
//
//  Created by 彭懂 on 16/9/8.
//  Copyright © 2016年 彭懂. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>
#import <OpenGLES/ES2/glext.h>
#import <GLKit/GLKit.h>

#define kTeapotScale		1.8
#define kCubeScale			0.12
#define kButtonScale		0.1

#define kButtonLeftSpace	1.1

#define	DegreesToRadians(x) ((x) * M_PI / 180.0)

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

static const CGFloat pathCircleRadius = 1.0;  // 运动路径内环
static const CGFloat pathOutCircleRadius = 1.1;  // 运动路径外环
static const GLuint circleSegments = 36;

// 效果类
@interface PDTeapotBaseEffect : NSObject

@property (nonatomic, strong) GLKBaseEffect *effect; // 效果类，灯光和材料模式效果
@property (nonatomic, assign) GLuint vertexArray;    // GLuint基础类型
@property (nonatomic, assign) GLuint vertexBuffer;
@property (nonatomic, assign) GLuint normalBuffer;


/**
 *  创建运动轨迹
 */
+ (instancetype)makeCircleWithNumOfSegments:(GLuint)segments radius:(GLfloat)radius;

/**
 *  创建茶壶
 */
+ (instancetype)makeTeapot;

/**
 *  创建正方体
 */
+ (NSMutableArray *)makeCube;

/**
 *  背景音乐的播放
 */
+ (void)musicBack;

@end
