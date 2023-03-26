//
//  AVPacketQueue.cpp
//  AudioTest
//
//  Created by 罗谨 on 2022/12/31.
//

#include "AVPacketQueue.hpp"

AVPacketQueue::AVPacketQueue(){
    
}

AVPacketQueue::~AVPacketQueue() {
 
}

void AVPacketQueue::Abort() {
    release();
    queue_.Abort();
}

int AVPacketQueue:: Push(AVPacket* value){
    AVPacket *tmp_pkt = av_packet_alloc();
    av_packet_move_ref(tmp_pkt, value);
    return queue_.Push(tmp_pkt);
}

AVPacket* AVPacketQueue::Pop(const int timeout){
    AVPacket* tmp_pkt = NULL;
    int ret = queue_.Pop(tmp_pkt, timeout);
    if (ret <0) {
        if (ret == -1) {
            av_log(NULL, AV_LOG_ERROR, "AVPacketQueue pop failed");
        }
    }
    return tmp_pkt;
}

void AVPacketQueue::release(){
    while (true) {
        AVPacket *pkt = NULL;
        int ret = queue_.Pop(pkt,1);
        if (ret <0){
            break;
        }else {
            av_packet_free(&pkt);
        }
    }
}

int AVPacketQueue::Size() {
    return queue_.Size();
}
