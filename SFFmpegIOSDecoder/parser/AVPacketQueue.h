//
//  AVPackeQueue.h
//  SFFmpegIOSDecoder
//
//  Created by 罗谨 on 2023/1/6.
//  Copyright © 2023 Lei Xiaohua. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <libavcodec/avcodec.h>
#import "Queue.h"

NS_ASSUME_NONNULL_BEGIN

@interface AVPacketQueue : NSObject
{
    Queue *queue_;
}

-(void)abort;
-(int)push:(AVPacket* )value;
-(AVPacket*)pop:(const int )timeout;
//    AVPacket* Front();
-(NSUInteger)size;
-(void)releaseRC;

@end

NS_ASSUME_NONNULL_END
