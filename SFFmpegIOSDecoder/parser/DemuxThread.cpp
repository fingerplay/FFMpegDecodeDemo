//
//  DemuxThread.cpp
//  VideoLib
//
//  Created by 罗谨 on 2023/1/1.
//

#include "DemuxThread.hpp"

DemuxThread:: DemuxThread(AVPacketQueue *videoQueue, AVPacketQueue *audioQueue)
: _video_packet_queue(videoQueue), _audio_packet_queue(audioQueue){
    
};

DemuxThread::~DemuxThread(){
    
};

int DemuxThread:: Init(const char *url) {
    url_ = url;
    
    int ret = 0;
    AVFormatContext *avFormatContext = avformat_alloc_context();
    m_avFormatContext = avFormatContext;

    ret = avformat_open_input(&avFormatContext, url, NULL, NULL);
    if (ret != 0) {
        av_log(NULL, AV_LOG_ERROR, "Couldn't open file");
        return -1;
    }
    ret = avformat_find_stream_info(avFormatContext, NULL);
    if (ret < 0) {
        av_log(NULL, AV_LOG_ERROR, "Couldn't find stream information");
    }
    
    av_dump_format(avFormatContext, 0,url, 0);
    audio_index = av_find_best_stream(avFormatContext, AVMEDIA_TYPE_AUDIO, -1, -1, NULL, 0);
    video_index = av_find_best_stream(avFormatContext, AVMEDIA_TYPE_VIDEO, -1, -1, NULL, 0);
    if (audio_index <0 || video_index <0) {
        av_log(NULL, AV_LOG_ERROR, "Couldn't find audio or video");
        return -1;
    }
    
    return ret;
    
};

int DemuxThread:: Start() {
    thread_ = new std::thread(&DemuxThread::Run,this);
    if (!thread_) {
        av_log(NULL, AV_LOG_ERROR, "create thread failed");
        return  -1;
    }
    return 0;
};

void DemuxThread:: Stop(){
    Thread::Stop();
    avformat_close_input(&m_avFormatContext);
};

void DemuxThread::Run(){
     int ret;
     AVPacket pkt;
     while(!abort_) {
         if (_audio_packet_queue->Size()>100 || _video_packet_queue->Size()>100) {
             std::this_thread::sleep_for(std::chrono::milliseconds(10));
             continue;
         }
         ret = av_read_frame(m_avFormatContext, &pkt);
         if (ret<0) {
             av_log(NULL, AV_LOG_ERROR, "DemuxThread read frame failed:%d\n",ret);
             break;
         }
         if (pkt.stream_index == audio_index) {
             _audio_packet_queue->Push(&pkt);
//             av_log(NULL, AV_LOG_INFO, "audio packet queue size:%d\n", _audio_packet_queue->Size());
         }else if (pkt.stream_index == video_index) {
             _video_packet_queue->Push(&pkt);
//             av_log(NULL, AV_LOG_INFO, "video packet queue size:%d\n", _video_packet_queue->Size());
         }
         av_packet_unref(&pkt);
     }
     av_log(NULL, AV_LOG_INFO, "DemuxThread run finished\n");
 };

AVCodecParameters *DemuxThread::AudioCodecParameters(){
    if (audio_index != -1) {
        return m_avFormatContext->streams[audio_index]->codecpar;
    }else{
        return NULL;
    }
};

AVCodecParameters *DemuxThread::VideoCodecParameters(){
    if (video_index != -1) {
        return m_avFormatContext->streams[video_index]->codecpar;
    }else{
        return NULL;
    }
};
