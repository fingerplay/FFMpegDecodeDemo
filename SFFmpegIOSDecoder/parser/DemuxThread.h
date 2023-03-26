//
//  DemuxThread.h
//  SFFmpegIOSDecoder
//
//  Created by 罗谨 on 2023/1/6.
//  Copyright © 2023 Lei Xiaohua. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <libavformat/avformat.h>
#import "AVPacketQueue.h"
#import "SFFmpegIOSDecoder-Swift.h"

NS_ASSUME_NONNULL_BEGIN

@interface DemuxThread : NSObject{
    NSString* url_;
    AVFormatContext *m_avFormatContext;
    int audio_index;
    int video_index;
    PacketQueue *_video_packet_queue;
    PacketQueue *_audio_packet_queue;
    NSThread *thread_;
    int abort_;
}

-(instancetype)initWithVideoQueue:(PacketQueue *)videoQueue audioQueue:(PacketQueue *)audioQueue;
- (int)setupWithUrl:(NSString*)url;
-(int)start;
-(void)stop;
-(void)run;
-(AVCodecParameters *)AudioCodecParameters;
-(AVCodecParameters *)VideoCodecParameters;

@end

NS_ASSUME_NONNULL_END
