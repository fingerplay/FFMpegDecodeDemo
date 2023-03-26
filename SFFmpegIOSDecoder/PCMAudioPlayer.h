//
//  AudioPlayer.h
//  SFFmpegIOSDecoder
//
//  Created by 罗谨 on 2023/1/7.
//  Copyright © 2023 Lei Xiaohua. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
NS_ASSUME_NONNULL_BEGIN
#define QUEUE_BUFFER_SIZE 3//队列缓冲个数
#define MIN_SIZE_PER_FRAME 2048//每帧最小数据长度

@protocol AudioPlayerDelegate <NSObject>
@optional
- (void)didStartPlay;

@end

@interface PCMAudioPlayer : NSObject
{
    AudioStreamBasicDescription _audioDescription;///音频参数
    AudioQueueRef audioQueue;//音频播放队列
    AudioQueueBufferRef audioQueueBuffers[QUEUE_BUFFER_SIZE];//音频缓存
    BOOL audioQueueUsed[QUEUE_BUFFER_SIZE];
    NSLock* sysnLock;
}

@property (nonatomic, assign) AudioStreamBasicDescription audioDescription;
@property (nonatomic, weak) id<AudioPlayerDelegate> delegate;

- (void)reset;
- (void)stop;
- (void)play:(void*)pcmData length:(unsigned int)length;

@end

NS_ASSUME_NONNULL_END
