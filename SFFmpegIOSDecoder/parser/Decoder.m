//
//  Decoder.m
//  SFFmpegIOSDecoder
//
//  Created by 罗谨 on 2023/1/7.
//  Copyright © 2023 Lei Xiaohua. All rights reserved.
//

#import "Decoder.h"
#include <libavutil/imgutils.h>
#include <libswscale/swscale.h>
#include <libavutil/time.h>
#import "VideoContext.h"

#define DELAY_THRESHOLD 1
@implementation Decoder

- (instancetype)initWithStream:(AVStream *)stream {
    self = [super init];
    if (self) {
        _decode_queue = dispatch_queue_create("decodeQueue", DISPATCH_QUEUE_SERIAL);
        _stream = stream;
        _params = stream->codecpar;
        [self setupWithParam:_params];
    }
    return self;
}


-(BOOL)setupWithParam:(AVCodecParameters *)params {
    if (!params) {
        av_log(NULL, AV_LOG_ERROR, "decodeThread init params error\n");
        return false;
    }
    codec_ctxt = avcodec_alloc_context3(NULL);
    int ret = avcodec_parameters_to_context(codec_ctxt, params);
    if (ret != 0) {
        av_log(NULL, AV_LOG_ERROR, "avcodec_parameters_to_context failed,ret=%d\n",ret);
        return false;
    }
    
    const AVCodec *codec = avcodec_find_decoder(codec_ctxt->codec_id);
    if (!codec) {
        av_log(NULL, AV_LOG_ERROR, "avcodec_find_decoder failed\n");
        return false;
    }
    
    ret = avcodec_open2(codec_ctxt, codec, NULL);
    if (ret != 0) {
        av_log(NULL, AV_LOG_ERROR, "avcodec_open2 failed,ret=%d\n",ret);
        return false;
    }
    av_log(NULL, AV_LOG_INFO, "DecodeThread init finish\n");
    
    if (params->codec_type == AVMEDIA_TYPE_AUDIO) {
        BOOL result = [self setupAudioContext];
        if (!result) return false;
    }else if (params->codec_type == AVMEDIA_TYPE_VIDEO) {
        BOOL result = [self setupVideoContext];
        if (!result) return false;
    }
    
    return true;
}

- (BOOL)setupVideoContext {
    FILE *p_yuv;
    NSString *output_nsstr = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"test.yuv"];

    p_yuv=fopen([output_nsstr UTF8String],"wb+");
    if(p_yuv==NULL){
        printf("Cannot open output file.\n");
        return false;
    }
    fp_yuv = p_yuv;
    return true;
}

-(BOOL)setupAudioContext {
    pSwrContext = swr_alloc();
    swr_alloc_set_opts(
                       pSwrContext,
                       av_get_channel_layout_nb_channels(AV_SAMPLE_FMT_S16),
                       AV_SAMPLE_FMT_S16,
                       44100,
                       codec_ctxt->channel_layout,
                       codec_ctxt->sample_fmt,
                       codec_ctxt->sample_rate,
                       0, NULL
                       );
    int ret = swr_init(pSwrContext);
    if (ret != 0) {
        av_log(NULL, AV_LOG_ERROR,"%s swr_init failed, ret=%d\n", __FUNCTION__,ret);
        avcodec_free_context(&codec_ctxt);
        swr_free(&pSwrContext);
        return false;
    }
    
    
//    pPCM16OutBuf = (uint8_t *) malloc(
//                                      av_get_bytes_per_sample(AV_SAMPLE_FMT_S16) * 1024);
//
//    if (pPCM16OutBuf == NULL) {
//        av_log(NULL, AV_LOG_ERROR,"%s PCM16OutBufs malloc failed, ret=%d\n", __FUNCTION__,ret);
//        avcodec_free_context(&codec_ctxt);
//        swr_free(&pSwrContext);
//        return false;
//    }
    
    FILE *p_pcm;
    NSString *output_nsstr = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"test.pcm"];

    p_pcm=fopen([output_nsstr UTF8String],"wb+");
    if(p_pcm==NULL){
        printf("Cannot open output file.\n");
        return false;
    }
    fp_pcm = p_pcm;

    return true;
}

- (void)decodeVideoPacket:(AVPacket*)pkt {
    AVFrame *frame = av_frame_alloc();
    
    if (pkt) {
        int ret = avcodec_send_packet(codec_ctxt, pkt);
        av_packet_free(&pkt);
        if (ret < 0) {
            av_log(NULL, AV_LOG_ERROR, "avcodec_send_frame failed,ret=%d\n",ret);
            return;
        }
        
//        AVFrame *pFrameYUV = av_frame_alloc();
//        uint8_t *out_buffer=(unsigned char *)av_malloc(av_image_get_buffer_size(AV_PIX_FMT_YUV420P,  codec_ctxt->width, codec_ctxt->height,1));
//        av_image_fill_arrays(pFrameYUV->data, pFrameYUV->linesize,out_buffer,
//                             AV_PIX_FMT_YUV420P,codec_ctxt->width, codec_ctxt->height,1);
//        struct SwsContext *img_convert_ctx = sws_getContext(codec_ctxt->width, codec_ctxt->height, codec_ctxt->pix_fmt,
//                                                            codec_ctxt->width, codec_ctxt->height, AV_PIX_FMT_YUV420P, SWS_BICUBIC, NULL, NULL, NULL);
        int fps = av_q2d(_stream->avg_frame_rate);
        double frame_delay = 1.0 / fps;
        while (true) {
            ret = avcodec_receive_frame(codec_ctxt, frame);
            
            if (ret == 0) {
//                sws_scale(img_convert_ctx, (const uint8_t* const*)frame->data, frame->linesize, 0, codec_ctxt->height,
//                          pFrameYUV->data, pFrameYUV->linesize);
//                pFrameYUV->width = frame->width;
//                pFrameYUV->height = frame->height;
//                pFrameYUV->best_effort_timestamp = frame->best_effort_timestamp;
//                pFrameYUV->pts = frame->pts;
                if (!hasRecord) {
                    int y_size=codec_ctxt->width*codec_ctxt->height;
                    fwrite(frame->data[0],1,y_size,fp_yuv);    //Y
    ////                fwrite(pFrameYUV->data[1],1,y_size/2,fp_yuv);  //UV
                    fwrite(frame->data[1],1,y_size/4,fp_yuv);  //U
                    fwrite(frame->data[2],1,y_size/4,fp_yuv);  //V
                    hasRecord = YES;
                }

                //判断当前帧是否有效，如果isValidFrame为false，则需要跳帧
                BOOL isValidFrame = [self scheduleVideoFrame:frame fps:fps frame_delay:frame_delay];
//                BOOL isValidFrame = [self scheduleVideoFrame:pFrameYUV fps:fps frame_delay:frame_delay];
                if (!isValidFrame) {
                    continue;
                }
                //原始frame的数据(包括data、linesize和buffer)在切换线程后会被释放，所以这里需要增加引用计数来确保其不被释放
                //如果是传递转换后的frame则不需要，因为outBuffer没有释放
                AVFrame *tmpFrame = av_frame_alloc();
                av_frame_ref(tmpFrame, frame);
                
                if (self.delegate && [self.delegate respondsToSelector:@selector(decoder:didDecodeFrame:)]){
                    [self.delegate decoder:self didDecodeFrame:tmpFrame];
                }

                //Output info
//                char pictype_str[10]={0};
//                switch(frame->pict_type){
//                    case AV_PICTURE_TYPE_I:sprintf(pictype_str,"I");break;
//                    case AV_PICTURE_TYPE_P:sprintf(pictype_str,"P");break;
//                    case AV_PICTURE_TYPE_B:sprintf(pictype_str,"B");break;
//                    default:sprintf(pictype_str,"Other");break;
//                }
//                NSLog(@"Type:%s\n",pictype_str);
                continue;
            }else if (AVERROR(EAGAIN)) {
                break;
            }else{
                _abort = 1;
                av_log(NULL, AV_LOG_ERROR, "avcodec_receive_frame failed,ret=%d\n",ret);
                break;
            }
        }
//        sws_freeContext(img_convert_ctx);
        //延迟到渲染结束再释放
//        av_frame_free(&pFrameYUV);
    }else{
        av_log(NULL, AV_LOG_INFO, "decodeThread not got packet\n");
    }
    
    av_frame_free(&frame);
}

- (void)decodeAudioPacket:(AVPacket*)pkt {
    AVFrame *frame = av_frame_alloc();
    if (pkt) {
        int ret = avcodec_send_packet(codec_ctxt, pkt);
        av_packet_free(&pkt);
        if (ret < 0) {
            av_log(NULL, AV_LOG_ERROR, "avcodec_send_frame failed,ret=%d\n",ret);
            return;
        }
        
        while (true) {
            ret = avcodec_receive_frame(codec_ctxt, frame);
            if (ret == 0) {
                //获取音频的相对时间
                [VideoContext sharedInstance].audio_pts_second = frame->pts * av_q2d(_stream->time_base);
                
                // 声道数
//                int inChs = av_get_channel_layout_nb_channels(codec_ctxt->channel_layout);
                // 每个样本的大小
//                int inBytesPerSample = inChs * av_get_bytes_per_sample(codec_ctxt->sample_fmt);
                // 输入缓冲区大小
                int inSamples = frame->nb_samples;
                
                // 输出缓冲区
                // 指向输出缓冲区的指针
                uint8_t **outData = NULL;
                // 缓冲区大小
                int outLineSize = 0;
                int outSampleRate = 44100;
                // 声道数
                int outChs = av_get_channel_layout_nb_channels(AV_SAMPLE_FMT_S16);
                // 每个样本的大小
                int outBytesPerSample = outChs * av_get_bytes_per_sample(AV_SAMPLE_FMT_S16);
                // 输出缓冲区大小
                int outSamples = (int)av_rescale_rnd(outSampleRate, inSamples, frame->sample_rate, AV_ROUND_UP);
                
                // 创建输出缓冲区
                ret = av_samples_alloc_array_and_samples(&outData, &outLineSize, outChs, outSamples,AV_SAMPLE_FMT_S16 , 0);
                if (ret < 0) {
                    av_log(NULL, AV_LOG_ERROR, "%s av_samples_alloc_array_and_samples ret=%d\n",__FUNCTION__,ret);
                    return;
                }

                //音频重采样
                int ret = swr_convert(
                                         pSwrContext,
                                         outData,
                                         outSamples,
                                         (const uint8_t **) frame->data,
                                         frame->nb_samples
                                         );
                if (ret< 0) {
                    av_log(NULL, AV_LOG_ERROR, "%s swr_convert appear problem ret=%d\n",__FUNCTION__,ret);
                } else {
                    
                    fwrite((const char *)outData[0],1, ret * outBytesPerSample, fp_pcm);
                    if (self.delegate && [self.delegate respondsToSelector:@selector(decoder:didDecodeFrame:length:)]){
                        [self.delegate decoder:self didDecodeFrame:*outData length:ret * outBytesPerSample];
                    }
                }
               
            
                if (outData) {
                    av_freep(&outData[0]);
                }
                av_freep(&outData);
                
                
//                //保存原始PCM
//                int data_size = av_get_bytes_per_sample(codec_ctxt->sample_fmt);
//                if (data_size < 0) {
//                    continue;
//                }
//                for (int i = 0; i < frame->nb_samples; i++)
//                {
//                    for (int ch = 0; ch < codec_ctxt->channels; ch++)
//                    {
//                        fwrite(frame->data[ch] + data_size * i, 1, data_size, fp_pcm);
//                    }
//                }
                
//                int frame_data_size = frame->nb_samples *data_size;
//                uint8_t *pOutBuf = (uint8_t *) malloc(frame_data_size);

//                if (self.delegate && [self.delegate respondsToSelector:@selector(decoder:didDecodeFrame:)]){
//                    [self.delegate decoder:self didDecodeFrame:frame];
//                }
            }else if (AVERROR(EAGAIN)) {
                break;
            }else{
                _abort = 1;
                av_log(NULL, AV_LOG_ERROR, "avcodec_receive_frame failed,ret=%d\n",ret);
                break;
            }
        }
    }else{
        av_log(NULL, AV_LOG_INFO, "decodeThread not got packet\n");
    }
    
    av_frame_free(&frame);
}

- (void)decodePacketOnQueue:(AVPacket *)pkt {
    
    if (self.params->codec_type == AVMEDIA_TYPE_VIDEO) {
        [self decodeVideoPacket:pkt];
    }else if (self.params->codec_type == AVMEDIA_TYPE_AUDIO) {
        [self decodeAudioPacket:pkt];
    }else{
        av_log(NULL, AV_LOG_ERROR, "decodePacketOnQueue failed ,error type ");
    }
}

- (void)decodePacket:(AVPacket*)pkt {
    AVPacket *tmp_pkt = av_packet_alloc();
    av_packet_move_ref(tmp_pkt, pkt);
    
    dispatch_async(_decode_queue, ^{
        [self decodePacketOnQueue:tmp_pkt];
    });
}

- (BOOL)scheduleVideoFrame:(AVFrame*)avFrame fps:(double)fps frame_delay:(double)frame_delay{
    //获取当前画面的相对播放时间 , 相对 : 即从播放开始到现在的时间
    //  该值大多数情况下 , 与 pts 值是相同的
    //  该值比 pts 更加精准 , 参考了更多的信息
    //  转换成秒 : 这里要注意 pts 需要转成 秒 , 需要乘以 time_base 时间单位
    //  其中 av_q2d 是将 AVRational 转为 double 类型
    double video_best_effort_timestamp_second = avFrame->best_effort_timestamp * av_q2d(_stream->time_base);
    
    //解码时 , 该值表示画面需要延迟多长时间在显示
    //  extra_delay = repeat_pict / (2*fps)
    //  需要使用该值 , 计算一个额外的延迟时间
    //  这里按照文档中的注释 , 计算一个额外延迟时间
    double extra_delay = avFrame->repeat_pict / ( fps * 2 );
    
    //计算总的帧间隔时间 , 这是真实的间隔时间
    double total_frame_delay = frame_delay + extra_delay;
    
    //将 total_frame_delay ( 单位 : 秒 ) , 转换成 微秒值 , 乘以 100 万
    unsigned microseconds_total_frame_delay = total_frame_delay * 1000 * 1000;
    
    if(video_best_effort_timestamp_second == 0 ){
        //如果播放的是第一帧 , 或者当前音频没有播放 , 就要正常播放
        //休眠 , 单位微秒 , 控制 FPS 帧率
        av_usleep(microseconds_total_frame_delay);
    }else{
        //如果不是第一帧 , 要开始考虑音视频同步问题了
        //音频的相对播放时间 , 这个是相对于播放开始的相对播放时间
        if ([VideoContext sharedInstance].audio_pts_second) {
            double audio_pts_second =  [VideoContext sharedInstance].audio_pts_second;
            
            //使用视频相对时间 - 音频相对时间
            double second_delta = video_best_effort_timestamp_second - audio_pts_second;
            
            //将相对时间转为 微秒单位
            unsigned microseconds_delta = second_delta * 1000 * 1000;
            
            //如果 second_delta 大于 0 , 说明视频播放时间比较长 , 视频比音频快
            //如果 second_delta 小于 0 , 说明视频播放时间比较短 , 视频比音频慢
            if(second_delta > 0){
                //视频快处理方案 : 增加休眠时间
                //休眠 , 单位微秒 , 控制 FPS 帧率
                av_usleep(microseconds_total_frame_delay + microseconds_delta);
            }else if(second_delta < 0){
                //视频慢处理方案 :
                //  ① 方案 1 : 减小休眠时间 , 甚至不休眠
                //  ② 方案 2 : 视频帧积压太多了 , 这里需要将视频帧丢弃 ( 比方案 1 极端 )
                if(fabs(second_delta) >= 0.05){
                    
                    //丢弃解码后的视频帧
                    //终止本次循环 , 继续下一次视频帧绘制
                    return false;

                }else{
                    //如果音视频之间差距低于 0.05 秒 , 不操作 ( 50ms )
                }
            }
        }
    }
    return true;
}

/*
-(void)updateTimeStamp:(AVFrame*)frame {
    if(frame->pkt_dts != AV_NOPTS_VALUE) {
        m_CurTimeStamp = frame->pkt_dts;
    } else if (frame->pts != AV_NOPTS_VALUE) {
        m_CurTimeStamp = frame->pts;
    } else {
        m_CurTimeStamp = 0;
    }
    
    m_CurTimeStamp = (int64_t)((m_CurTimeStamp * av_q2d(_stream->time_base)) * 1000);
    
    if(m_SeekPosition > 0 && m_SeekSuccess)
    {
        m_StartTimeStamp = [[NSDate date] timeIntervalSince1970] - m_CurTimeStamp;
        m_SeekPosition = 0;
        m_SeekSuccess = false;
    }
}

- (long)AVSync {
    long curSysTime = [[NSDate date] timeIntervalSince1970];
    //基于系统时钟计算从开始播放流逝的时间
    long elapsedTime = curSysTime - m_StartTimeStamp;
    long delay = 0;
    //向系统时钟同步
    if(m_CurTimeStamp > elapsedTime) {
        //休眠时间
        int sleepTime = (int)(m_CurTimeStamp - elapsedTime);//ms
        //限制休眠时间不能过长
//        sleepTime = sleepTime > DELAY_THRESHOLD ? DELAY_THRESHOLD :  sleepTime;
        av_usleep(sleepTime * 1000);
    }
    delay = elapsedTime - m_CurTimeStamp;
    return delay;
}
*/
-(void)stop {
    if(fp_yuv) {
        fclose(fp_yuv);
    }
    if(fp_pcm) {
        fclose(fp_pcm);
    }
}


@end
