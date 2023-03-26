//
//  FrameQueue.swift
//  SFFmpegIOSDecoder
//
//  Created by 罗谨 on 2023/1/10.
//  Copyright © 2023 Lei Xiaohua. All rights reserved.
//

import Foundation

class FrameQueue: NSObject{
    var queue_: Queue<UnsafeMutablePointer<AVFrame>>;
    
    override init() {
        queue_ = Queue.init()
    }
    
    func abort() {
        queue_.abort();
        release();
    }
    
    func release() {
        while (true) {
             do  {
                 var frame = try queue_.pop(timeout: 1)
                 av_frame_free(withUnsafeMutablePointer(to: &frame, { $0 }));
            }catch {
                break;
            }
        }
    }
    
    @objc func push(_ value: UnsafeMutablePointer<AVFrame>) ->Int{
        let frame = av_frame_alloc();
        av_frame_move_ref(frame, value);
//        debugPrint("push packet address:%p",tmp_pkt);
        return queue_.push(val: frame!)
    }
    
    @objc func pop(_ timeout: Int) -> UnsafeMutablePointer<AVFrame>? {
        do {
            let frame = try queue_.pop(timeout: timeout)
//            NSLog(@"pop packet address:%p",tmp_pkt);
            return frame;
        }catch  (let error){
            debugPrint("FrameQueue pop failed,%s", error.localizedDescription);
        }
        return nil;
    }
    
    @objc func size()->Int {
        return queue_.size();
    }
}
