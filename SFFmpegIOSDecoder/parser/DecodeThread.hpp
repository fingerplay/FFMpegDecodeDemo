//
//  DecodeThread.hpp
//  VideoTest
//
//  Created by 罗谨 on 2023/1/2.
//

#ifndef DecodeThread_hpp
#define DecodeThread_hpp

#include <stdio.h>
#include "Thread.hpp"
#include "AVPacketQueue.hpp"
#include "AVFrameQueue.hpp"

class DecodeThread : public Thread {
public:
    DecodeThread(AVPacketQueue *packet_queue, AVFrameQueue *frame_queue);
    ~DecodeThread();
    int Init(AVCodecParameters* params);
    int Start();
    void Stop();
    void Run();
    
private:
    char err2Str[256]= {0};
    AVCodecContext *codec_ctxt = NULL;
    AVPacketQueue *packet_queue=NULL;
    AVFrameQueue *frame_queue=NULL;
};

#endif /* DecodeThread_hpp */
