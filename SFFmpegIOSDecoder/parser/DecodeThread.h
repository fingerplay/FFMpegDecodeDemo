//
//  DecodeThread.h
//  SFFmpegIOSDecoder
//
//  Created by 罗谨 on 2023/1/6.
//  Copyright © 2023 Lei Xiaohua. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AVPacketQueue.h"
#import "AVFrameQueue.h"
#import "SFFmpegIOSDecoder-Swift.h"

NS_ASSUME_NONNULL_BEGIN
@class DecodeThread;
@protocol DecodeThreadDelegate <NSObject>
@optional

-(void)decoderThread:(DecodeThread*)decoderThread didDecodeFrame:(AVFrame*)frame;

@end

@interface DecodeThread : NSObject {

    AVCodecContext *codec_ctxt;
    PacketQueue *_packet_queue;
    FrameQueue *_frame_queue;
    NSThread *thread_;
    int abort_;
}

@property(nonatomic, weak) id<DecodeThreadDelegate>delegate;
@property (nonatomic, assign) AVCodecParameters *params;

-(instancetype)initWithPacketQueue:(PacketQueue *)packet_queue frameQueue:(FrameQueue *)frame_queue delegate:(id<DecodeThreadDelegate>)delegate;
-(int)setupWithParam:(AVCodecParameters *)params;
-(int)start;
-(void)stop;
-(void)run;


@end

NS_ASSUME_NONNULL_END
