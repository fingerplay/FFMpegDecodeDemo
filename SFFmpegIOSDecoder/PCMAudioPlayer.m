//
//  AudioPlayer.m
//  SFFmpegIOSDecoder
//
//  Created by 罗谨 on 2023/1/7.
//  Copyright © 2023 Lei Xiaohua. All rights reserved.
//

#import "PCMAudioPlayer.h"
@interface PCMAudioPlayer()

@property (nonatomic,assign)BOOL isFirstPlay;
@property (nonatomic,assign)BOOL isStarted;
@end
@implementation PCMAudioPlayer

- (instancetype)init{
    self = [super init];
    if (self) {
        _isFirstPlay = YES;
        ///设置音频参数
        _audioDescription.mSampleRate =44100;//采样率
        _audioDescription.mFormatID =kAudioFormatLinearPCM;
        _audioDescription.mFormatFlags =kLinearPCMFormatFlagIsSignedInteger |kAudioFormatFlagIsPacked;
        _audioDescription.mChannelsPerFrame =1;
        _audioDescription.mFramesPerPacket =1;//每一个packet一侦数据
        _audioDescription.mBitsPerChannel =16;//每个采样点16bit量化
        _audioDescription.mBytesPerFrame = (_audioDescription.mBitsPerChannel / 8) * _audioDescription.mChannelsPerFrame;
        _audioDescription.mBytesPerPacket =_audioDescription.mBytesPerFrame;
        [self reset];
    }
    return self;
}

- (void)dealloc
{
    if (audioQueue !=nil) {
        AudioQueueStop(audioQueue,true);
    }

    audioQueue =nil;
    sysnLock =nil;
    NSLog(@"PCMAudioPlayer dealloc...");
}

static void AudioPlayerAQInputCallback(void* inUserData,AudioQueueRef outQ, AudioQueueBufferRef outQB)
{
    PCMAudioPlayer* player = (__bridge PCMAudioPlayer*)inUserData;
    [player playerCallback:outQB];
}

- (void)setAudioDescription:(AudioStreamBasicDescription)audioDescription {
    _audioDescription = audioDescription;
    [self reset];
}

- (void)reset
{
    [self stop];
    sysnLock = [[NSLock alloc] init];
    AudioQueueNewOutput(&_audioDescription,AudioPlayerAQInputCallback, (__bridge void*)self,nil,nil,0, &audioQueue);//使用player的内部线程播放

    //初始化音频缓冲区
    for (int i =0; i <QUEUE_BUFFER_SIZE; i++) {
        int result =AudioQueueAllocateBuffer(audioQueue,MIN_SIZE_PER_FRAME, &audioQueueBuffers[i]);///创建buffer区，MIN_SIZE_PER_FRAME为每一侦所需要的最小的大小，该大小应该比每次往buffer里写的最大的一次还大
        NSLog(@"AudioQueueAllocateBuffer i = %d,result = %d", i, result);
    }

    NSLog(@"PCMAudioPlayer reset");

}

- (void)stop
{
    if (audioQueue !=nil) {
        AudioQueueStop(audioQueue,true);
        AudioQueueReset(audioQueue);
    }

    audioQueue =nil;
}

- (void)play:(void*)pcmData length:(unsigned int)length
{
    if (audioQueue ==nil || ![self checkBufferHasUsed]) {
        if (_isFirstPlay) {
             AudioQueueStart(audioQueue,NULL);
            _isFirstPlay =NO;
        }
    }

//    [sysnLock lock];
    AudioQueueBufferRef audioQueueBuffer =NULL;

    while (true) {
        audioQueueBuffer = [self getNotUsedBuffer];
        if (audioQueueBuffer !=NULL) {
            break;
        }
    }

    audioQueueBuffer->mAudioDataByteSize = length;
    Byte* audiodata = (Byte*)audioQueueBuffer->mAudioData;

    for (int i =0; i < length; i++) {
        audiodata[i] = ((Byte*)pcmData)[i];
    }
    
    AudioQueueEnqueueBuffer(audioQueue, audioQueueBuffer,0,NULL);

//    AudioQueueEnqueueBufferWithParameters(audioQueue, audioQueueBuffer, 0, NULL, 0, 0, 0, NULL, <#const AudioTimeStamp * _Nullable inStartTime#>, <#AudioTimeStamp * _Nullable outActualStartTime#>);
    NSLog(@"PCMAudioPlayer play dataSize:%d", length);
//    [sysnLock unlock];
}

- (BOOL)checkBufferHasUsed
{
    for (int i =0; i <QUEUE_BUFFER_SIZE; i++) {
        if (YES ==audioQueueUsed[i]) {
            return YES;
        }
    }

    NSLog(@"PCMAudioPlayer播放中断............");
    return NO;
}

- (AudioQueueBufferRef)getNotUsedBuffer
{
    for (int i =0; i <QUEUE_BUFFER_SIZE; i++) {
        if (NO ==audioQueueUsed[i]) {
            audioQueueUsed[i] =YES;
//            NSLog(@"PCMAudioPlayer play buffer index:%d", i);
            return audioQueueBuffers[i];
        }
    }

    return NULL;
}

- (void)playerCallback:(AudioQueueBufferRef)outQB
{
    for (int i =0; i <QUEUE_BUFFER_SIZE; i++) {
        if (outQB ==audioQueueBuffers[i]) {
            audioQueueUsed[i] =NO;
        }
    }
    NSLog(@"PCMAudioPlayer播放中...");
    if(!self.isStarted) {
        if(self.delegate && [self.delegate respondsToSelector:@selector(didStartPlay)]){
            [self.delegate didStartPlay];
        }
        self.isStarted = YES;
    }

}

@end
