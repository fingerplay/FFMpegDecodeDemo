//
//  DemuxThread.m
//  SFFmpegIOSDecoder
//
//  Created by 罗谨 on 2023/1/6.
//  Copyright © 2023 Lei Xiaohua. All rights reserved.
//

#import "DemuxThread.h"

@implementation DemuxThread

-(void)dealloc {
    NSLog(@"DemuxThread dealloc");
}

-(instancetype)initWithVideoQueue:(PacketQueue *)videoQueue audioQueue:(PacketQueue *)audioQueue  {
    if (self = [super init]) {
        _video_packet_queue = videoQueue;
        _audio_packet_queue = audioQueue;
    }
    return self;
}

- (int)setupWithUrl:(NSString*)url {
    url_ = url;
    
    int ret = 0;
    AVFormatContext *avFormatContext = avformat_alloc_context();
    m_avFormatContext = avFormatContext;

    ret = avformat_open_input(&avFormatContext, [url UTF8String], NULL, NULL);
    if (ret != 0) {
        av_log(NULL, AV_LOG_ERROR, "Couldn't open file");
        return -1;
    }
    ret = avformat_find_stream_info(avFormatContext, NULL);
    if (ret < 0) {
        av_log(NULL, AV_LOG_ERROR, "Couldn't find stream information");
    }
    
    av_dump_format(avFormatContext, 0,[url UTF8String], 0);
    audio_index = av_find_best_stream(avFormatContext, AVMEDIA_TYPE_AUDIO, -1, -1, NULL, 0);
    video_index = av_find_best_stream(avFormatContext, AVMEDIA_TYPE_VIDEO, -1, -1, NULL, 0);
    if (audio_index <0 || video_index <0) {
        av_log(NULL, AV_LOG_ERROR, "Couldn't find audio or video");
        return -1;
    }
    return ret;
}

-(int)start {
//    thread_ = new std::thread(&DemuxThread::Run,this);
    thread_ = [[NSThread alloc] initWithTarget:self selector:@selector(run) object:nil];
    if (!thread_) {
        av_log(NULL, AV_LOG_ERROR, "create thread failed");
        return  -1;
    }
    [thread_ start];
    return 0;
}
-(void)stop {
    if(thread_) {
        abort_ = 1;
        thread_ = nil;
    }
    avformat_close_input(&m_avFormatContext);
}
-(void)run {
    int ret;
    AVPacket pkt;
    while(!abort_) {
        if ([_audio_packet_queue size]>100 || [_video_packet_queue size]>100) {
//            std::this_thread::sleep_for(std::chrono::milliseconds(10));
//            [NSThread sleepForTimeInterval:2];
            continue;
        }
        ret = av_read_frame(m_avFormatContext, &pkt);
        if (ret<0) {
            av_log(NULL, AV_LOG_ERROR, "DemuxThread read frame failed:%d\n",ret);
            break;
        }
        if (pkt.stream_index == audio_index) {
            [_audio_packet_queue push:&pkt];
            av_log(NULL, AV_LOG_INFO, "audio packet queue size:%lu\n", (unsigned long)[_audio_packet_queue size]);
        }else if (pkt.stream_index == video_index) {
            [_video_packet_queue push:&pkt];
            av_log(NULL, AV_LOG_INFO, "video packet queue size:%lu\n", (unsigned long)[_video_packet_queue size]);
        }
        av_packet_unref(&pkt);
    }
    av_log(NULL, AV_LOG_INFO, "DemuxThread run finished\n");
}

-(AVCodecParameters *)AudioCodecParameters {
    if (audio_index != -1) {
        return m_avFormatContext->streams[audio_index]->codecpar;
    }else{
        return NULL;
    }
}

-(AVCodecParameters *)VideoCodecParameters {
    if (video_index != -1) {
        return m_avFormatContext->streams[video_index]->codecpar;
    }else{
        return NULL;
    }
}
@end
