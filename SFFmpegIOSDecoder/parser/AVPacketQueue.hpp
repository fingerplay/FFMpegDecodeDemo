//
//  AVPacketQueue.hpp
//  AudioTest
//
//  Created by 罗谨 on 2022/12/31.
//

#ifndef AVPacketQueue_hpp
#define AVPacketQueue_hpp
#include "Queue.hpp"
#ifdef __cplusplus
extern "C" {

#include <stdio.h>
#include <libavcodec/avcodec.h>
}
#endif


class AVPacketQueue {
public:
    AVPacketQueue();
    ~AVPacketQueue();
    void Abort();
    int Push(AVPacket* value);
    AVPacket* Pop(const int timeout);
//    AVPacket* Front();
    int Size();
    void release();
private:
    Queue<AVPacket*> queue_;
};


#endif /* AVPacketQueue_hpp */

