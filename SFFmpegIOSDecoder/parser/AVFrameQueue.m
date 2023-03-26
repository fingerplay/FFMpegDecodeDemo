//
//  AVFrameQueue.m
//  SFFmpegIOSDecoder
//
//  Created by 罗谨 on 2023/1/6.
//  Copyright © 2023 Lei Xiaohua. All rights reserved.
//

#import "AVFrameQueue.h"

@implementation AVFrameQueue

-(instancetype)init{
    self = [super init];
    if (self) {
        queue_ = [[Queue alloc] init];
    }
    return self;
}

-(void)abort {
    [self releaseRC];
    [queue_ abort];
}

-(int)push:(AVFrame* )value{
    AVFrame *frame = av_frame_alloc();
    av_frame_move_ref(frame, value);
    return [queue_ push:[NSValue valueWithPointer:frame]];
}

-(AVFrame*)pop:(const int )timeout{
    NSError *error = nil;
//    AVFrame* frame = (__bridge AVFrame *)([queue_ popWithTimeout:timeout error:error]);
    NSValue *value = [queue_ popWithTimeout:timeout error:error];
    AVFrame *frame = [value pointerValue];
    if (error) {
        av_log(NULL, AV_LOG_ERROR, "AVFrameQueue pop failed,%ld",(long)error.code);
    }
    return frame;
}

-(void)releaseRC {
    while (true) {
        NSError *error = nil;
//        AVFrame *frame = (__bridge AVFrame *)([queue_ popWithTimeout:1 error:error]);
        NSValue *value = [queue_ popWithTimeout:1 error:error];
        AVFrame *frame = [value pointerValue];
        if (error){
            break;
        }else {
            av_frame_free(&frame);
        }
    }
}

-(AVFrame*)front{
    NSError *error = nil;
//    AVFrame* frame = (__bridge AVFrame *)([queue_ frontWithError:error]);
    NSValue *value = [queue_ frontWithError:error];
    AVFrame *frame = [value pointerValue];
    if (error) {
        av_log(NULL, AV_LOG_ERROR, "AVFrameQueue Front failed,%ld",error.code);
    }
    return frame;
};

-(NSUInteger)size {
    return [queue_ size];
}
@end
