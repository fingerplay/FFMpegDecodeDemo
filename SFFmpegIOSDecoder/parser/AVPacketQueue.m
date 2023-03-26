//
//  AVPackeQueue.m
//  SFFmpegIOSDecoder
//
//  Created by 罗谨 on 2023/1/6.
//  Copyright © 2023 Lei Xiaohua. All rights reserved.
//

#import "AVPacketQueue.h"

@implementation AVPacketQueue
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

-(int)push:(AVPacket* )value{
    AVPacket *tmp_pkt = av_packet_alloc();
    av_packet_move_ref(tmp_pkt, value);
//    AVPacket *tmp_pkt = av_packet_clone(value);
    NSLog(@"push packet address:%p",tmp_pkt);
//    return [queue_ push: [NSValue value:tmp_pkt withObjCType:@encode(AVPacket)]];
    return [queue_ push:[NSValue valueWithPointer:tmp_pkt]];
}

-(AVPacket*)pop:(const int )timeout{
    NSError *error = nil;
    NSValue* value = [queue_ popWithTimeout:timeout error:error];
    AVPacket* tmp_pkt = [value pointerValue];

    NSLog(@"pop packet address:%p",tmp_pkt);
    if (error) {
        av_log(NULL, AV_LOG_ERROR, "AVPacketQueue pop failed,%ld",(long)error.code);
    }
    return tmp_pkt;
}

-(void)releaseRC {
    while (true) {
        NSError *error = nil;
        AVPacket *pkt = (__bridge AVPacket *)([queue_ popWithTimeout:1 error:error]);
        if (error){
            break;
        }else {
            av_packet_free(&pkt);
        }
    }
}

-(NSUInteger)size {
    return [queue_ size];
}
@end
