//
//  AVFrameQueue.hpp
//  VideoTest
//
//  Created by 罗谨 on 2023/1/2.
//

#ifndef AVFrameQueue_hpp
#define AVFrameQueue_hpp
#include "Queue.hpp"
#ifdef __cplusplus
extern "C" {

#include <stdio.h>
#include <libavcodec/avcodec.h>
}

#endif
class AVFrameQueue {
public:
    AVFrameQueue();
    ~AVFrameQueue();
    void Abort();
    int Push(AVFrame* value);
    AVFrame* Pop(const int timeout);
    AVFrame* Front();
    int Size();
    void release();
private:
    Queue<AVFrame*> queue_;
};
#endif /* AVFrameQueue_hpp */
