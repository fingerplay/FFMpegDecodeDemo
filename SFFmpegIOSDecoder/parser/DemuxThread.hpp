//
//  DemuxThread.hpp
//  VideoLib
//
//  Created by 罗谨 on 2023/1/1.
//

#ifndef DemuxThread_hpp
#define DemuxThread_hpp

#include <stdio.h>
#include "Thread.hpp"
#include "AVPacketQueue.hpp"
#ifdef __cplusplus
extern "C" {

#include <libavformat/avformat.h>
}
#endif

class DemuxThread: public Thread {
public:
    DemuxThread(AVPacketQueue *videoQueue, AVPacketQueue *audioQueue);
    ~DemuxThread();
    int Init(const char *url);
    int Start();
    void Stop();
    void Run();
    AVCodecParameters *AudioCodecParameters();
    AVCodecParameters *VideoCodecParameters();
private:
    std::string url_;
    AVFormatContext *m_avFormatContext = NULL;
    int audio_index;
    int video_index;
    AVPacketQueue *_video_packet_queue;
    AVPacketQueue *_audio_packet_queue;
};
#endif /* DemuxThread_hpp */


