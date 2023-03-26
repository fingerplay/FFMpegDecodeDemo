//
//  DecodeThread.m
//  SFFmpegIOSDecoder
//
//  Created by 罗谨 on 2023/1/6.
//  Copyright © 2023 Lei Xiaohua. All rights reserved.
//

#import "DecodeThread.h"
#include <libavutil/imgutils.h>
#include <libswscale/swscale.h>
@implementation DecodeThread

- (void)dealloc {
    NSLog(@"DecodeThread dealloc");
}

-(instancetype)initWithPacketQueue:(PacketQueue *)packet_queue frameQueue:(FrameQueue *)frame_queue delegate:(id<DecodeThreadDelegate>)delegate {
    if (self = [super init]){
        _packet_queue = packet_queue;
        _frame_queue = frame_queue;
        _delegate = delegate;
    }

    return self;
}

-(int)setupWithParam:(AVCodecParameters *)params {
    self.params = params;
    if (!params) {
        av_log(NULL, AV_LOG_ERROR, "decodeThread init params error\n");
        return -1;
    }
    codec_ctxt = avcodec_alloc_context3(NULL);
    int ret = avcodec_parameters_to_context(codec_ctxt, params);
    if (ret != 0) {
        av_log(NULL, AV_LOG_ERROR, "avcodec_parameters_to_context failed,ret=%d\n",ret);
        return -1;
    }
    
    const AVCodec *codec = avcodec_find_decoder(codec_ctxt->codec_id);
    if (!codec) {
        av_log(NULL, AV_LOG_ERROR, "avcodec_find_decoder failed\n");
        return -1;
    }
    
    ret = avcodec_open2(codec_ctxt, codec, NULL);
    if (ret != 0) {
        av_log(NULL, AV_LOG_ERROR, "avcodec_open2 failed,ret=%d\n",ret);
        return -1;
    }
    av_log(NULL, AV_LOG_INFO, "DecodeThread init finish\n");
    return 0;
}

-(int)start {
    thread_ = [[NSThread alloc] initWithTarget:self selector:@selector(run) object:nil];
    if (!thread_) {
        av_log(NULL, AV_LOG_ERROR, "DecodeThread start failed\n");
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
}
-(void)run {
    [[NSRunLoop currentRunLoop] addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
    FILE *fp_yuv;
    int y_size;
    NSString *output_nsstr = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"test.yuv"];
    
    fp_yuv=fopen([output_nsstr UTF8String],"wb+");
    if(fp_yuv==NULL){
        printf("Cannot open output file.\n");
        return;
    }
    AVFrame *frame = av_frame_alloc();
//    AVFrame *pFrameYUV = av_frame_alloc();
//    uint8_t *out_buffer=(unsigned char *)av_malloc(av_image_get_buffer_size(AV_PIX_FMT_NV12,  codec_ctxt->width, codec_ctxt->height,1));
//    av_image_fill_arrays(pFrameYUV->data, pFrameYUV->linesize,out_buffer,
//                         AV_PIX_FMT_NV12,codec_ctxt->width, codec_ctxt->height,1);
//    struct SwsContext *img_convert_ctx = sws_getContext(codec_ctxt->width, codec_ctxt->height, codec_ctxt->pix_fmt,
//                                                        codec_ctxt->width, codec_ctxt->height, AV_PIX_FMT_NV12, SWS_BICUBIC, NULL, NULL, NULL);
    int frame_cnt = 0;
    while(abort_!=1) {
//        if ([_frame_queue size]>10) {
////            std::this_thread::sleep_for(std::chrono::milliseconds(10));
//            [NSThread sleepForTimeInterval:2];
//            continue;
//        }
        AVPacket* pkt = [_packet_queue pop:2];
        if (pkt) {
            int ret = avcodec_send_packet(codec_ctxt, pkt);
            av_packet_free(&pkt);
            if (ret < 0) {
//                 av_strerror(ret, err2Str, sizeof(err2Str));
                av_log(NULL, AV_LOG_ERROR, "avcodec_send_frame failed,ret=%d\n",ret);
                break;
            }
            while (true) {
                ret = avcodec_receive_frame(codec_ctxt, frame);
//                sws_scale(img_convert_ctx, (const uint8_t* const*)frame->data, frame->linesize, 0, codec_ctxt->height,
//                          pFrameYUV->data, pFrameYUV->linesize);
//                pFrameYUV->width = frame->width;
//                pFrameYUV->height = frame->height;
                if (ret == 0) {
                    AVFrame *tmpFrame = av_frame_alloc();
                    av_frame_ref(tmpFrame, frame);
                    
//                    [_frame_queue push:frame];
                    
                    if (self.delegate && [self.delegate respondsToSelector:@selector(decoderThread:didDecodeFrame:)]){
                        [self.delegate decoderThread:self didDecodeFrame:tmpFrame];
                    }
                    y_size=codec_ctxt->width*codec_ctxt->height;
                    fwrite(frame->data[0],1,y_size,fp_yuv);    //Y
                    fwrite(frame->data[1],1,y_size/4,fp_yuv);  //U
                    fwrite(frame->data[2],1,y_size/4,fp_yuv);  //V
                    
//                    av_log(NULL, AV_LOG_INFO, "%s frame queue size: %lu\n",codec_ctxt->codec->name, (unsigned long)[_frame_queue size]);
                    //Output info
                    char pictype_str[10]={0};
                    switch(frame->pict_type){
                        case AV_PICTURE_TYPE_I:sprintf(pictype_str,"I");break;
                        case AV_PICTURE_TYPE_P:sprintf(pictype_str,"P");break;
                        case AV_PICTURE_TYPE_B:sprintf(pictype_str,"B");break;
                        default:sprintf(pictype_str,"Other");break;
                    }
                    NSLog(@"Frame Index: %5d. Type:%s\n",frame_cnt,pictype_str);
                    frame_cnt++;
                    continue;
                }else if (AVERROR(EAGAIN)) {
                    break;
                }else{
                    abort_ = 1;
                    av_log(NULL, AV_LOG_ERROR, "avcodec_receive_frame failed,ret=%d\n",ret);
                    break;
                }
            }
        }else{
            av_log(NULL, AV_LOG_INFO, "decodeThread not got packet\n");
        }
    }
    av_log(NULL, AV_LOG_INFO, "DecodeThread run finished\n");
    fclose(fp_yuv);
    
//    av_frame_free(&pFrameYUV);
    av_frame_free(&frame);
}


@end
