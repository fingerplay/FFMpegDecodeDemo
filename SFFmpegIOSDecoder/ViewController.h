/**
 * 最简单的基于FFmpeg的视频解码器-IOS
 * Simplest FFmpeg IOS Decoder
 *
 * 雷霄骅 Lei Xiaohua
 * leixiaohua1020@126.com
 * 中国传媒大学/数字电视技术
 * Communication University of China / Digital TV Technology
 * http://blog.csdn.net/leixiaohua1020
 *
 * 本程序是IOS平台下最简单的基于FFmpeg的视频解码器。
 * 它可以将输入的视频数据解码成YUV像素数据。
 *
 * This software is the simplest decoder based on FFmpeg in IOS.
 * It can decode video stream to raw YUV data.
 *
 */

#import <UIKit/UIKit.h>
//#import "GLView.h"
#import "MovieView.h"
#import "SFFmpegIOSDecoder-Swift.h"
#import "AVPacketQueue.h"
#import "AVFrameQueue.h"
#import "AAPLEAGLLayer.h"
#include "SDL_uikitview.h"

@interface ViewController : UIViewController {
     AVFrameQueue *video_frame_queue;
     AudioStreamBasicDescription audioDescription;
    
}
@property (weak, nonatomic) IBOutlet UILabel *infomation;
@property (weak, nonatomic) IBOutlet UITextField *inputurl;
@property (weak, nonatomic) IBOutlet UITextField *outputurl;
@property (weak, nonatomic) IBOutlet UIImageView *outputImageView;
@property (strong, nonatomic) DDView *glView;
@property (strong, nonatomic) AAPLEAGLLayer *glLayer;
@property (strong, nonatomic) SDL_uikitview *sdlView;
//@property (strong, nonatomic) MovieView* glView;


- (IBAction)clickDecodeButton:(id)sender;


@end

