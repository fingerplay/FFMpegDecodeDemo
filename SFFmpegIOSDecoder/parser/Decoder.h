//
//  Decoder.h
//  SFFmpegIOSDecoder
//
//  Created by 罗谨 on 2023/1/7.
//  Copyright © 2023 Lei Xiaohua. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <libavformat/avformat.h>
#include <libswresample/swresample.h>


NS_ASSUME_NONNULL_BEGIN
@class Decoder;
@protocol DecodeDelegate <NSObject>

-(void)decoder:(Decoder*)decoder didDecodeFrame:(AVFrame*)frame;

-(void)decoder:(Decoder*)decoder didDecodeFrame:(uint8_t*)data length:(int)len;

@end

@interface Decoder : NSObject {
    AVCodecContext *codec_ctxt;
    int _abort;
    FILE *fp_yuv;
    FILE *fp_pcm;
    SwrContext *pSwrContext;
    double audio_pts_second;
    BOOL hasRecord;
//    uint8_t *pPCM16OutBuf;

}
@property (nonatomic, assign) AVCodecParameters *params;
@property (nonatomic, assign) AVStream *stream;
@property (nonatomic, strong)  dispatch_queue_t decode_queue;
@property (nonatomic, weak) id<DecodeDelegate> delegate;


- (instancetype)initWithStream:(AVStream *)stream;
- (void)decodePacket:(AVPacket*)packet;
- (void)stop;


@end

NS_ASSUME_NONNULL_END
