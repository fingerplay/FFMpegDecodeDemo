//
//  AVFrameQueue.h
//  SFFmpegIOSDecoder
//
//  Created by 罗谨 on 2023/1/6.
//  Copyright © 2023 Lei Xiaohua. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Queue.h"
#include <libavcodec/avcodec.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVFrameQueue : NSObject
{
    Queue *queue_;
}
-(void)abort;
-(int)push:(AVFrame* )value;
-(AVFrame*)pop:(const int )timeout;
-(NSUInteger)size;
-(AVFrame*)front;
-(void)releaseRC;
@end

NS_ASSUME_NONNULL_END
