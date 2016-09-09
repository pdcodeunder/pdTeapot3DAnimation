//
//  PDMusicCube.h
//  PDTeapot3DAnimation
//
//  Created by 彭懂 on 16/9/8.
//  Copyright © 2016年 彭懂. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenAL/al.h>
#import <OpenAL/alc.h>

@interface PDMusicCube : NSObject
{
    ALuint			_source;
    ALuint			_buffer;
    void			*_data;
    float			_sourcePos[3];
    float			_listenerPos[3];
    float			_listenerRotation;
    ALfloat			_sourceVolume;
    BOOL			_isPlaying;
    BOOL			_wasInterrupted;
}

@property			BOOL isPlaying; // 设置暂停和播放
@property			BOOL wasInterrupted; // 播放是否被打断
@property			float *sourcePos; // 声音资源
@property			float *listenerPos;
@property			float listenerRotation;

- (void)initOpenAL;
- (void)teardownOpenAL;

- (void)startSound;
- (void)stopSound;

@end
