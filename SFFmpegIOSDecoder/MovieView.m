//
//  MovieView.m
//  SFFmpegIOSDecoder
//
//  Created by 罗谨 on 2023/1/4.
//  Copyright © 2023 Lei Xiaohua. All rights reserved.
//

#import "MovieView.h"

@implementation MovieView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.sampleBufferDisplayLayer = [[AVSampleBufferDisplayLayer alloc] init];
        self.sampleBufferDisplayLayer.frame = self.bounds;
        self.sampleBufferDisplayLayer.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
        self.sampleBufferDisplayLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        self.sampleBufferDisplayLayer.opaque = YES;
        [self.layer addSublayer:self.sampleBufferDisplayLayer];
    }
    return self;
}


//把pixelBuffer包装成samplebuffer送给displayLayer
- (void)dispatchPixelBuffer:(CVPixelBufferRef) pixelBuffer
{
    if (!pixelBuffer){
        return;
    }
    @synchronized(self) {
        if (self.previousPixelBuffer){
            CFRelease(self.previousPixelBuffer);
            self.previousPixelBuffer = nil;
        }
        self.previousPixelBuffer = CFRetain(pixelBuffer);
    }
    
    //不设置具体时间信息
    CMSampleTimingInfo timing = {kCMTimeInvalid, kCMTimeInvalid, kCMTimeInvalid};
    //获取视频信息
    CMVideoFormatDescriptionRef videoInfo = NULL;
    OSStatus result = CMVideoFormatDescriptionCreateForImageBuffer(NULL, pixelBuffer, &videoInfo);
    NSParameterAssert(result == 0 && videoInfo != NULL);
    
    CMSampleBufferRef sampleBuffer = NULL;
    result = CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault,pixelBuffer, true, NULL, NULL, videoInfo, &timing, &sampleBuffer);
    NSParameterAssert(result == 0 && sampleBuffer != NULL);
    CFRelease(pixelBuffer);
    CFRelease(videoInfo);
    
    CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, YES);
    CFMutableDictionaryRef dict = (CFMutableDictionaryRef)CFArrayGetValueAtIndex(attachments, 0);
    CFDictionarySetValue(dict, kCMSampleAttachmentKey_DisplayImmediately, kCFBooleanTrue);
    [self enqueueSampleBuffer:sampleBuffer toLayer:self.sampleBufferDisplayLayer];
    CFRelease(sampleBuffer);
}

- (void)enqueueSampleBuffer:(CMSampleBufferRef) sampleBuffer toLayer:(AVSampleBufferDisplayLayer*) layer
{
    if (sampleBuffer){
        CFRetain(sampleBuffer);
        [layer enqueueSampleBuffer:sampleBuffer];
        CFRelease(sampleBuffer);
        if (layer.status == AVQueuedSampleBufferRenderingStatusFailed){
            NSLog(@"ERROR: %@", layer.error);
            if (-11847 == layer.error.code){
                [self rebuildSampleBufferDisplayLayer];
            }
        }else{
//            NSLog(@"STATUS: %i", (int)layer.status);
        }
    }else{
        NSLog(@"ignore null samplebuffer");
    }
}

- (void)rebuildSampleBufferDisplayLayer{
    @synchronized(self) {
        [self teardownSampleBufferDisplayLayer];
        [self setupSampleBufferDisplayLayer];
    }
}
 
- (void)teardownSampleBufferDisplayLayer
{
    if (self.sampleBufferDisplayLayer){
        [self.sampleBufferDisplayLayer stopRequestingMediaData];
        [self.sampleBufferDisplayLayer removeFromSuperlayer];
        self.sampleBufferDisplayLayer = nil;
    }
}
 
- (void)setupSampleBufferDisplayLayer{
    if (!self.sampleBufferDisplayLayer){
        self.sampleBufferDisplayLayer = [[AVSampleBufferDisplayLayer alloc] init];
        self.sampleBufferDisplayLayer.frame = self.bounds;
        self.sampleBufferDisplayLayer.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
        self.sampleBufferDisplayLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        self.sampleBufferDisplayLayer.opaque = YES;
        [self.layer addSublayer:self.sampleBufferDisplayLayer];
    }else{
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        self.sampleBufferDisplayLayer.frame = self.bounds;
        self.sampleBufferDisplayLayer.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
        [CATransaction commit];
    }
//    [self addObserver];
}

//- (void)addObserver{
//    if (!hasAddObserver){
//        NSNotificationCenter * notificationCenter = [NSNotificationCenter defaultCenter];
//        [notificationCenter addObserver: self selector:@selector(didResignActive) name:UIApplicationWillResignActiveNotification object:nil];
//        [notificationCenter addObserver: self selector:@selector(didBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
//        hasAddObserver = YES;
//    }
//}
//
//- (void)didResignActive{
//    NSLog(@"resign active");
//    [self setupPlayerBackgroundImage];
//}
// 
//- (void) setupPlayerBackgroundImage{
//    if (self.isVideoHWDecoderEnable){
//        @synchronized(self) {
//            if (self.previousPixelBuffer){
//                self.image = [self getUIImageFromPixelBuffer:self.previousPixelBuffer];
//                CFRelease(self.previousPixelBuffer);
//                self.previousPixelBuffer = nil;
//            }
//        }
//    }
//}
//
//- (UIImage*)getUIImageFromPixelBuffer:(CVPixelBufferRef)pixelBuffer
//{
//    UIImage *uiImage = nil;
//    if (pixelBuffer){
//        CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
//        uiImage = [UIImage imageWithCIImage:ciImage];
//        UIGraphicsBeginImageContext(self.bounds.size);
//        [uiImage drawInRect:self.bounds];
//        uiImage = UIGraphicsGetImageFromCurrentImageContext();
//        UIGraphicsEndImageContext();
//    }
//    return uiImage;
//}
@end
