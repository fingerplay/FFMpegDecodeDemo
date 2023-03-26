//
//  Demuxer.m
//  SFFmpegIOSDecoder
//
//  Created by 罗谨 on 2023/1/7.
//  Copyright © 2023 Lei Xiaohua. All rights reserved.
//

#import "Demuxer.h"

@implementation Demuxer
- (instancetype)initWithUrl:(NSString *)url decodeDelegate:(nonnull id<DecodeDelegate>)delegate{
    self = [super init];
    if (self) {
        _url = url;
        _demux_queue = dispatch_queue_create("demuxQueue", DISPATCH_QUEUE_SERIAL);
        [self setup];
        _videoDecoder = [[Decoder alloc] initWithStream:[self VideoStream]];
        _videoDecoder.delegate = delegate;
        _audioDecoder = [[Decoder alloc] initWithStream:[self AudioStream]];
        _audioDecoder.delegate = delegate;
    }
    return self;
}

-(int)setup {
    int ret = 0;
    AVFormatContext *avFormatContext = avformat_alloc_context();
    m_avFormatContext = avFormatContext;

    ret = avformat_open_input(&avFormatContext, [_url UTF8String], NULL, NULL);
    if (ret != 0) {
        av_log(NULL, AV_LOG_ERROR, "Couldn't open file");
        return -1;
    }
    ret = avformat_find_stream_info(avFormatContext, NULL);
    if (ret < 0) {
        av_log(NULL, AV_LOG_ERROR, "Couldn't find stream information");
        return -1;
    }
    
    av_dump_format(avFormatContext, 0,[_url UTF8String], 0);
    audio_index = av_find_best_stream(avFormatContext, AVMEDIA_TYPE_AUDIO, -1, -1, NULL, 0);
    video_index = av_find_best_stream(avFormatContext, AVMEDIA_TYPE_VIDEO, -1, -1, NULL, 0);
    if (audio_index <0 || video_index <0) {
        av_log(NULL, AV_LOG_ERROR, "Couldn't find audio or video");
        return -1;
    }
    return 0;
}


-(void)start {
    dispatch_async(_demux_queue, ^{
        [self startDemux];
    });
}

- (void)startDemux {
    AVPacket pkt;
    int ret;
    int audio_pkt_cnt = 0, video_pkt_cnt = 0;
    while(!_abort) {
        ret = av_read_frame(m_avFormatContext, &pkt);
        if (ret<0) {
            av_log(NULL, AV_LOG_ERROR, "DemuxThread read frame failed:%d\n",ret);
            break;
        }
        if (pkt.stream_index == audio_index) {
            [self.audioDecoder decodePacket:&pkt];
//            [_audio_packet_queue push:&pkt];
             av_log(NULL, AV_LOG_INFO, "audio packet queue size:%d\n", audio_pkt_cnt++);
        }else if (pkt.stream_index == video_index) {
            [self.videoDecoder decodePacket:&pkt];
//            [_video_packet_queue push:&pkt];
             av_log(NULL, AV_LOG_INFO, "video packet queue size:%d\n", video_pkt_cnt++);
        }
        av_packet_unref(&pkt);
    }
    av_log(NULL, AV_LOG_INFO, "DemuxThread finished\n");
}


-(void)stop {
    
}

-(AVStream *)AudioStream {
    if (audio_index != -1) {
        return m_avFormatContext->streams[audio_index];
    }else{
        return NULL;
    }
}

-(AVStream *)VideoStream {
    if (video_index != -1) {
        return m_avFormatContext->streams[video_index];
    }else{
        return NULL;
    }
}


@end
