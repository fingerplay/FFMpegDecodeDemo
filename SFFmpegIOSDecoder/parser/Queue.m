//
//  Queue.m
//  SFFmpegIOSDecoder
//
//  Created by 罗谨 on 2023/1/6.
//  Copyright © 2023 Lei Xiaohua. All rights reserved.
//

#import "Queue.h"

@implementation Queue
#define kErrorDomainQueue @"queue"
- (instancetype)init{
    self = [super init];
    if (self){
        cond_ = [[NSConditionLock alloc]init];
        queue_ = [[NSMutableArray alloc] init];
//        taskqueue_ = dispatch_queue_create("customQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

-(void)abort {
    abort_ = 1;
    [cond_ unlockWithCondition:1];
}

-(int)push:(id)val{
//    std::lock_guard<std::mutex> lock(mutex_);
    [mutex_ lock];
    if (1 == abort_) {
        return -1;
    }
    
    [queue_ addObject:val];
//    cond_.notify_one();
    [cond_ unlockWithCondition:1];
    [mutex_ unlock];
    return 0;
}

-(id)popWithTimeout:(const int) timeout error:(NSError*)error{
//    std::unique_lock<std::mutex> lock(mutex_);
    [mutex_ lock];
    if([queue_ count] == 0) {
        // 等待push或超时唤醒
//        cond_.wait_for(lock, std::chrono::microseconds(timeout),[this]{
//            return !queue_.empty() || abort_;
//        });
        [cond_ lockWhenCondition:1 beforeDate:[NSDate dateWithTimeIntervalSinceNow:timeout]];
    }
    if (abort_) {
        error = [NSError errorWithDomain:kErrorDomainQueue code:-1 userInfo:NULL];
        return NULL;
    }
    if ([queue_ count] == 0){
        error = [NSError errorWithDomain:kErrorDomainQueue code:-2 userInfo:NULL];
        return NULL;
    }
    id val = [queue_ objectAtIndex:0];
    [queue_ removeObject:val];
    [mutex_ unlock];
    return val;
}

-(id)frontWithError:(NSError*)error{
//   std::lock_guard<std::mutex> lock(mutex_);
    [mutex_ lock];
    if(1 == abort_) {
        error = [NSError errorWithDomain:kErrorDomainQueue code:-1 userInfo:NULL];
        return NULL;
    }
    if ([queue_ count]==0){
        error = [NSError errorWithDomain:kErrorDomainQueue code:-2 userInfo:NULL];
        return NULL;
    }
   id val = [queue_ objectAtIndex:0];
    [mutex_ unlock];
    return val;
}

-(NSUInteger)size {
//    std::lock_guard<std::mutex> lock(mutex_);
    [mutex_ lock];
    NSUInteger count =  [queue_ count];
    [mutex_ unlock];
    return count;
}
@end
