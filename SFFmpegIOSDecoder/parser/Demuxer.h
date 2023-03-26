//
//  Demuxer.h
//  SFFmpegIOSDecoder
//
//  Created by 罗谨 on 2023/1/7.
//  Copyright © 2023 Lei Xiaohua. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <libavformat/avformat.h>
#import "Decoder.h"
NS_ASSUME_NONNULL_BEGIN

@interface Demuxer : NSObject {
    AVFormatContext *m_avFormatContext;
    AVCodecContext *codec_ctxt;
    int audio_index;
    int video_index;
    NSString* _url;
    int _abort;
}
@property (nonatomic, strong)  dispatch_queue_t demux_queue;
@property (nonatomic, strong) Decoder *videoDecoder;
@property (nonatomic, strong) Decoder *audioDecoder;

- (instancetype)initWithUrl:(NSString*)url decodeDelegate:(id<DecodeDelegate>)delegate;
-(void)start;
-(void)stop;

@end

NS_ASSUME_NONNULL_END
