//
//  AVPacketQueue.swift
//  SFFmpegIOSDecoder
//
//  Created by 罗谨 on 2023/1/10.
//  Copyright © 2023 Lei Xiaohua. All rights reserved.
//

import Foundation

class PacketQueue: NSObject {
    
    var queue_: Queue<UnsafeMutablePointer<AVPacket>>;
    
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
                 var pkt = try queue_.pop(timeout: 1)
                 av_packet_free(withUnsafeMutablePointer(to: &pkt, { $0 }));
            }catch {
                break;
            }
        }
    }
    
    @objc public func push(_ value: UnsafeMutablePointer<AVPacket>) ->Int{
        let tmp_pkt = av_packet_alloc();
        av_packet_move_ref(tmp_pkt, value);
//        debugPrint("push packet address:%p",tmp_pkt);
        return queue_.push(val: tmp_pkt!)
    }
    
    @objc public func pop(_ timeout: Int) -> UnsafeMutablePointer<AVPacket>? {
        do {
            let tmp_pkt = try queue_.pop(timeout: timeout)
//            NSLog(@"pop packet address:%p",tmp_pkt);
            return tmp_pkt;
        }catch (let error){
            debugPrint("PacketQueue pop failed", error.localizedDescription);
        }
        return nil;
    }
    
    @objc func size()->Int {
        return queue_.size();
    }
}
