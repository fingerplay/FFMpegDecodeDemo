//
//  Queue.swift
//  SFFmpegIOSDecoder
//
//  Created by 罗谨 on 2023/1/10.
//  Copyright © 2023 Lei Xiaohua. All rights reserved.
//

import Foundation

struct Queue<T> {
    var abort_:Int = 0 ;
    var cond_: NSConditionLock = NSConditionLock.init();
    var mutex_: NSLock = NSLock.init();
    var queue_: Array<T> = Array.init();
    let kErrorDomainQueue =  "queue"

    mutating func abort() {
        abort_ = 1;
        cond_.unlock(withCondition: 1);
    }
    
    mutating func push(val:T) ->Int {
        mutex_.lock();

        if (1 == abort_) {
            return -1;
        }
        
        queue_.append(val)
    //    cond_.notify_one();
        cond_.unlock(withCondition: 1)
        mutex_.unlock()
        return 0;
    }
    
    mutating func pop(timeout: Int) throws -> T? {
        mutex_.lock()
        if(queue_.count == 0) {
            // 等待push或超时唤醒
    //        cond_.wait_for(lock, std::chrono::microseconds(timeout),[this]{
    //            return !queue_.empty() || abort_;
    //        });
            cond_.lock(whenCondition: 1, before: Date.init(timeIntervalSinceNow: TimeInterval(timeout)))
        }
        if (abort_ != 0) {
            mutex_.unlock()
            throw NSError.init(domain: kErrorDomainQueue, code: -1)
        }
        if (queue_.count == 0){
            mutex_.unlock()
            throw NSError.init(domain: kErrorDomainQueue, code: -2)
        }
        let val = queue_[0]
        queue_.remove(at: 0)
        mutex_.unlock()
        return val;
    }
    
    func size()->Int {
        mutex_.lock()
        let count = queue_.count
        mutex_.unlock()
        return count;
    }
}
