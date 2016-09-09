//
//  PDMusicCube.m
//  PDTeapot3DAnimation
//
//  Created by 彭懂 on 16/9/8.
//  Copyright © 2016年 彭懂. All rights reserved.
//

#import "PDMusicCube.h"
#import <AVFoundation/AVAudioSession.h>

// 各种接口实现
#import <OpenAL/al.h>
#import <OpenAL/alc.h>
#import <AudioToolbox/AudioToolbox.h>


typedef ALvoid	AL_APIENTRY	(*alBufferDataStaticProcPtr) (const ALint bid, ALenum format, ALvoid* data, ALsizei size, ALsizei freq);
ALvoid  alBufferDataStaticProc(const ALint bid, ALenum format, ALvoid* data, ALsizei size, ALsizei freq)
{
    static	alBufferDataStaticProcPtr	proc = NULL;
    
    if (proc == NULL) {
        proc = (alBufferDataStaticProcPtr) alcGetProcAddress(NULL, (const ALCchar*) "alBufferDataStatic");
    }
    
    if (proc)
        proc(bid, format, data, size, freq);
    
    return;
}

void* MyGetOpenALAudioData(CFURLRef inFileURL, ALsizei *outDataSize, ALenum *outDataFormat, ALsizei*	outSampleRate)
{
    OSStatus						err = noErr;
    UInt64							fileDataSize = 0;
    AudioStreamBasicDescription		theFileFormat;
    UInt32							thePropertySize = sizeof(theFileFormat);
    AudioFileID						afid = 0;
    void*							theData = NULL;
    
    // Open a file with ExtAudioFileOpen()
    err = AudioFileOpenURL(inFileURL, kAudioFileReadPermission, 0, &afid);
    if(err) { printf("MyGetOpenALAudioData: AudioFileOpenURL FAILED, Error = %d\n", (int)err); goto Exit; }
    
    // Get the audio data format
    err = AudioFileGetProperty(afid, kAudioFilePropertyDataFormat, &thePropertySize, &theFileFormat);
    if(err) { printf("MyGetOpenALAudioData: AudioFileGetProperty(kAudioFileProperty_DataFormat) FAILED, Error = %d\n", (int)err); goto Exit; }
    
    if (theFileFormat.mChannelsPerFrame > 2)  {
        printf("MyGetOpenALAudioData - Unsupported Format, channel count is greater than stereo\n"); goto Exit;
    }
    
    if ((theFileFormat.mFormatID != kAudioFormatLinearPCM) || (!TestAudioFormatNativeEndian(theFileFormat))) {
        printf("MyGetOpenALAudioData - Unsupported Format, must be little-endian PCM\n"); goto Exit;
    }
    
    if ((theFileFormat.mBitsPerChannel != 8) && (theFileFormat.mBitsPerChannel != 16)) {
        printf("MyGetOpenALAudioData - Unsupported Format, must be 8 or 16 bit PCM\n"); goto Exit;
    }
    
    
    thePropertySize = sizeof(fileDataSize);
    err = AudioFileGetProperty(afid, kAudioFilePropertyAudioDataByteCount, &thePropertySize, &fileDataSize);
    if(err) { printf("MyGetOpenALAudioData: AudioFileGetProperty(kAudioFilePropertyAudioDataByteCount) FAILED, Error = %d\n", (int)err); goto Exit; }
    
    // Read all the data into memory
    UInt32		dataSize = (UInt32)fileDataSize;
    theData = malloc(dataSize);
    if (theData)
    {
        AudioFileReadBytes(afid, false, 0, &dataSize, theData);
        if(err == noErr)
        {
            // success
            *outDataSize = (ALsizei)dataSize;
            *outDataFormat = (theFileFormat.mChannelsPerFrame > 1) ? AL_FORMAT_STEREO16 : AL_FORMAT_MONO16;
            *outSampleRate = (ALsizei)theFileFormat.mSampleRate;
        }
        else
        {
            // failure
            free (theData);
            theData = NULL; // make sure to return NULL
            printf("MyGetOpenALAudioData: ExtAudioFileRead FAILED, Error = %d\n", (int)err); goto Exit;
        }
    }
    
Exit:
    // Dispose the ExtAudioFileRef, it is no longer needed
    if (afid) AudioFileClose(afid);
    return theData;
}

void TeardownOpenAL()
{
    ALCcontext	*context = NULL;
    ALCdevice	*device = NULL;
    ALuint		returnedName;
    
    alDeleteSources(1, &returnedName);
    alDeleteBuffers(1, &returnedName);
    
    context = alcGetCurrentContext();
    device = alcGetContextsDevice(context);
    alcDestroyContext(context);
    alcCloseDevice(device);
}


@implementation PDMusicCube

@synthesize isPlaying = _isPlaying;
@synthesize wasInterrupted = _wasInterrupted;
@synthesize listenerRotation = _listenerRotation;

#pragma mark Object Init / Maintenance


- (void)handleInterruption:(NSNotification *)notification
{
    AVAudioSessionInterruptionType interruptionType = [[[notification userInfo]
                                                        objectForKey:AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    
    if (AVAudioSessionInterruptionTypeBegan == interruptionType)
    {
        [self teardownOpenAL];
        if (_isPlaying) {
            _wasInterrupted = YES;
            _isPlaying = NO;
        }
    }
    else if (AVAudioSessionInterruptionTypeEnded == interruptionType)
    {
        NSError *error = nil;
        [[AVAudioSession sharedInstance] setActive:YES error:&error];
        if (nil != error) NSLog(@"Error setting audio session active! %@", error);
        
        [self initOpenAL];
        if (_wasInterrupted)
        {
            [self startSound];
            _wasInterrupted = NO;
        }
    }
}

- (id)init
{
    if (self = [super init]) {
        AVAudioSession *sessionInstance = [AVAudioSession sharedInstance];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleInterruption:)
                                                     name:AVAudioSessionInterruptionNotification
                                                   object:sessionInstance];
        
        NSError *error = nil;
        [sessionInstance setCategory:AVAudioSessionCategoryAmbient error:&error];
        if(nil != error) NSLog(@"Error setting audio session category! %@", error);
        else {
            [sessionInstance setActive:YES error:&error];
            if (nil != error) NSLog(@"Error setting audio session active! %@", error);
        }
        
        _wasInterrupted = NO;
        [self initOpenAL];
    }
    
    return self;
}

- (void)dealloc
{
    if (_data) free(_data);
    
    [self teardownOpenAL];
}

#pragma mark OpenAL

- (void) initBuffer
{
    ALenum  error = AL_NO_ERROR;
    ALenum  format = 0;
    ALsizei size = 0;
    ALsizei freq = 0;
    
    NSBundle*				bundle = [NSBundle mainBundle];
    
    CFURLRef fileURL = (__bridge CFURLRef)[NSURL fileURLWithPath:[bundle pathForResource:@"sound" ofType:@"wav"]];
    
    if (fileURL)
    {
        _data = MyGetOpenALAudioData(fileURL, &size, &format, &freq);
        CFRelease(fileURL);
        
        if((error = alGetError()) != AL_NO_ERROR) {
            printf("error loading sound: %x\n", error);
            exit(1);
        }
        alBufferDataStaticProc(_buffer, format, _data, size, freq);
        
        if((error = alGetError()) != AL_NO_ERROR) {
            printf("error attaching audio to buffer: %x\n", error);
        }
    }
    else
    {
        printf("Could not find file!\n");
        _data = NULL;
    }
}

- (void) initSource
{
    ALenum error = AL_NO_ERROR;
    alGetError();
    alSourcei(_source, AL_LOOPING, AL_TRUE);
    alSourcefv(_source, AL_POSITION, _sourcePos);
    alSourcef(_source, AL_REFERENCE_DISTANCE, 0.15f);
    alSourcei(_source, AL_BUFFER, _buffer);
    
    if((error = alGetError()) != AL_NO_ERROR) {
        printf("Error attaching buffer to source: %x\n", error);
        exit(1);
    }
}


- (void)initOpenAL
{
    ALenum			error;
    ALCcontext		*newContext = NULL;
    ALCdevice		*newDevice = NULL;
    newDevice = alcOpenDevice(NULL);
    if (newDevice != NULL)
    {
        newContext = alcCreateContext(newDevice, 0);
        if (newContext != NULL)
        {
            alcMakeContextCurrent(newContext);
            alGenBuffers(1, &_buffer);
            if((error = alGetError()) != AL_NO_ERROR) {
                printf("Error Generating Buffers: %x", error);
                exit(1);
            }
            alGenSources(1, &_source);
            if(alGetError() != AL_NO_ERROR)
            {
                printf("Error generating sources! %x\n", error);
                exit(1);
            }
            
        }
    }
    alGetError();
    
    [self initBuffer];
    [self initSource];
}

- (void)teardownOpenAL
{
    ALCcontext	*context = NULL;
    ALCdevice	*device = NULL;
    
    alDeleteSources(1, &_source);
    alDeleteBuffers(1, &_buffer);
    
    context = alcGetCurrentContext();
    device = alcGetContextsDevice(context);
    alcDestroyContext(context);
    alcCloseDevice(device);
}

#pragma mark Play / Pause

- (void)startSound
{
    ALenum error;
    
    printf("Start!\n");
    alSourcePlay(_source);
    if((error = alGetError()) != AL_NO_ERROR) {
        printf("error starting source: %x\n", error);
    } else {
        self.isPlaying = YES;
    }
}

- (void)stopSound
{
    ALenum error;
    alSourceStop(_source);
    if((error = alGetError()) != AL_NO_ERROR) {
        printf("error stopping source: %x\n", error);
    } else {
        self.isPlaying = NO;
    }
}

#pragma mark Setters / Getters

- (float*)sourcePos
{
    return _sourcePos;
}

- (void)setSourcePos:(float*)SOURCEPOS
{
    int i;
    for (i=0; i<3; i++)
        _sourcePos[i] = SOURCEPOS[i];
    
    alSourcefv(_source, AL_POSITION, _sourcePos);
}

- (float*)listenerPos
{
    return _listenerPos;
}

- (void)setListenerPos:(float*)LISTENERPOS
{
    int i;
    for (i=0; i<3; i++)
        _listenerPos[i] = LISTENERPOS[i];
    
    alListenerfv(AL_POSITION, _listenerPos);
}

- (float)listenerRotation
{
    return _listenerRotation;
}

- (void)setListenerRotation:(float)radians
{
    _listenerRotation = radians;
    float ori[] = {0., cos(radians), sin(radians), 1., 0., 0.};
    alListenerfv(AL_ORIENTATION, ori);
}

@end
