//
//  DecodeThread.cpp
//  VideoTest
//
//  Created by 罗谨 on 2023/1/2.
//

#include "DecodeThread.hpp"
DecodeThread:: DecodeThread(AVPacketQueue *packet_queue, AVFrameQueue *frame_queue):packet_queue(packet_queue), frame_queue(frame_queue){
    
};

DecodeThread::~DecodeThread(){
    if (thread_) {
        Stop();
    }
    if(codec_ctxt){
        avcodec_close(codec_ctxt);
    }
};

int DecodeThread::Init(AVCodecParameters *params){
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
};

int DecodeThread:: Start() {
    thread_ = new std::thread(&DecodeThread::Run,this);
    if (!thread_) {
        av_log(NULL, AV_LOG_ERROR, "DecodeThread start failed\n");
        return  -1;
    }
    return 0;
};

void DecodeThread:: Stop(){
    Thread::Stop();
//    avformat_close_input(&m_avFormatContext);
};

void DecodeThread::Run(){

     AVFrame *frame = av_frame_alloc();
     while(abort_!=1) {
         if (frame_queue->Size()>10) {
             std::this_thread::sleep_for(std::chrono::milliseconds(10));
             continue;
         }
         AVPacket* pkt = packet_queue->Pop(10);
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
                 if (ret == 0) {
                     frame_queue->Push(frame);
                     av_log(NULL, AV_LOG_INFO, "%s frame queue size: %d\n",codec_ctxt->codec->name, frame_queue->Size());
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
             av_log(NULL, AV_LOG_INFO, "not got packet\n");
         }
     }
     av_log(NULL, AV_LOG_INFO, "DecodeThread run finished\n");
 };
