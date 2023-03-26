//
//  AVFrameQueue.cpp
//  VideoTest
//
//  Created by 罗谨 on 2023/1/2.
//

#include "AVFrameQueue.hpp"
AVFrameQueue::AVFrameQueue(){};

AVFrameQueue::~AVFrameQueue(){};

void AVFrameQueue:: Abort() {
    AVFrameQueue::release();
    queue_.Abort();
};

void AVFrameQueue::release() {
    while (true) {
        AVFrame *frame = NULL;
        int ret = queue_.Pop(frame,1);
        if (ret <0){
            break;
        }else {
            av_frame_free(&frame);
        }
    }
};
int AVFrameQueue::Push(AVFrame* value) {
    AVFrame *frame = av_frame_alloc();
    av_frame_move_ref(frame, value);
    return queue_.Push(frame);
}
AVFrame* AVFrameQueue::Pop(const int timeout){
    AVFrame* frame = NULL;
    int ret = queue_.Pop(frame, timeout);
    if (ret <0) {
        if (ret == -1) {
            av_log(NULL, AV_LOG_ERROR, "AVFrameQueue pop failed");
        }
    }
    return frame;
};
AVFrame* AVFrameQueue::Front(){
    AVFrame* frame = NULL;
    int ret = queue_.Front(frame);
    if (ret <0) {
        if (ret == -1) {
            av_log(NULL, AV_LOG_ERROR, "AVFrameQueue Front failed");
        }
    }
    return frame;
};
int AVFrameQueue::Size(){
    return queue_.Size();
};
