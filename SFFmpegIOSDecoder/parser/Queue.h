//
//  Queue.h
//  SFFmpegIOSDecoder
//
//  Created by 罗谨 on 2023/1/6.
//  Copyright © 2023 Lei Xiaohua. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <libavcodec/avcodec.h>
NS_ASSUME_NONNULL_BEGIN

@interface Queue : NSObject
{
    int abort_;
    NSLock* mutex_;
    NSConditionLock *cond_;
//    dispatch_queue_t taskqueue_;
    NSMutableArray* queue_;
}

-(void)abort;
-(int)push:(id)val;
-(id)popWithTimeout:(const int) timeout error:(NSError*)error;
-(id)frontWithError:(NSError*)error;
-(NSUInteger)size;

@end

NS_ASSUME_NONNULL_END
