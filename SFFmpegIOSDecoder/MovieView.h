//
//  MovieView.h
//  SFFmpegIOSDecoder
//
//  Created by 罗谨 on 2023/1/4.
//  Copyright © 2023 Lei Xiaohua. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
NS_ASSUME_NONNULL_BEGIN

@interface MovieView : UIView{
    BOOL hasAddObserver;
}
@property(nonatomic,strong) AVSampleBufferDisplayLayer *sampleBufferDisplayLayer;
@property(nonatomic,assign) CVPixelBufferRef previousPixelBuffer;

- (void)dispatchPixelBuffer:(CVPixelBufferRef) pixelBuffer;

@end

NS_ASSUME_NONNULL_END
