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

#import "ViewController.h"
#include <libavcodec/avcodec.h>
#include <libavformat/avformat.h>
#include <libavutil/imgutils.h>
#include <libswscale/swscale.h>
#import "DemuxThread.h"
#import "DecodeThread.h"
#import "Demuxer.h"
#import "PCMAudioPlayer.h"
#include "SDL.h"
#include "SDL_render.h"

@interface ViewController ()<DecodeDelegate,AudioPlayerDelegate,DecodeThreadDelegate>
@property(nonatomic,strong) EAGLContext *context;
@property(nonatomic,assign) CVPixelBufferPoolRef pixelBufferPool;
@property(nonatomic,strong) CADisplayLink *displayLink;
@property(nonatomic,strong) NSMutableArray *pixelBufferArray;
@property(nonatomic,strong) PCMAudioPlayer *audioPlayer;
@property(nonatomic,strong) DecodeThread *audio_decode_thread;
@property(nonatomic,strong) DecodeThread *video_decode_thread;
@property(nonatomic,strong) DemuxThread *demux_thread;

@end

@implementation ViewController
static SDL_Window *sdl_window;
static SDL_Renderer *sdl_renderer;
static SDL_RendererInfo renderer_info = {0};

static const struct TextureFormatEntry {
    enum AVPixelFormat format;
    int texture_fmt;
} sdl_texture_format_map[] = {
    { AV_PIX_FMT_RGB8,           SDL_PIXELFORMAT_RGB332 },
    { AV_PIX_FMT_RGB444,         SDL_PIXELFORMAT_RGB444 },
    { AV_PIX_FMT_RGB555,         SDL_PIXELFORMAT_RGB555 },
    { AV_PIX_FMT_BGR555,         SDL_PIXELFORMAT_BGR555 },
    { AV_PIX_FMT_RGB565,         SDL_PIXELFORMAT_RGB565 },
    { AV_PIX_FMT_BGR565,         SDL_PIXELFORMAT_BGR565 },
    { AV_PIX_FMT_RGB24,          SDL_PIXELFORMAT_RGB24 },
    { AV_PIX_FMT_BGR24,          SDL_PIXELFORMAT_BGR24 },
    { AV_PIX_FMT_0RGB32,         SDL_PIXELFORMAT_RGB888 },
    { AV_PIX_FMT_0BGR32,         SDL_PIXELFORMAT_BGR888 },
    { AV_PIX_FMT_NE(RGB0, 0BGR), SDL_PIXELFORMAT_RGBX8888 },
    { AV_PIX_FMT_NE(BGR0, 0RGB), SDL_PIXELFORMAT_BGRX8888 },
    { AV_PIX_FMT_RGB32,          SDL_PIXELFORMAT_ARGB8888 },
    { AV_PIX_FMT_RGB32_1,        SDL_PIXELFORMAT_RGBA8888 },
    { AV_PIX_FMT_BGR32,          SDL_PIXELFORMAT_ABGR8888 },
    { AV_PIX_FMT_BGR32_1,        SDL_PIXELFORMAT_BGRA8888 },
    { AV_PIX_FMT_YUV420P,        SDL_PIXELFORMAT_IYUV },
    { AV_PIX_FMT_YUYV422,        SDL_PIXELFORMAT_YUY2 },
    { AV_PIX_FMT_UYVY422,        SDL_PIXELFORMAT_UYVY },
    { AV_PIX_FMT_NONE,           SDL_PIXELFORMAT_UNKNOWN },
};

static unsigned sws_flags = SWS_BICUBIC;
BOOL isShowWindow = false;

- (void)viewDidLoad {
    [super viewDidLoad];
    SDL_SetMainReady();
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:self.context];
    // Do any additional setup after loading the view, typically from a nib.
    CGFloat width = self.view.bounds.size.width-40;
    CGFloat height = (self.view.bounds.size.width-40)/848*480;
//    self.glLayer = [[AAPLEAGLLayer alloc] initWithFrame:CGRectMake(20, 200, width, height)];
    self.glView = [[DDView alloc] initWithFrame:CGRectMake(20, 500, width, height)];


//    self.glView.backgroundColor=[UIColor grayColor];
    [self.view addSubview:self.glView];
//    [self.view.layer addSublayer:self.glLayer];
    
    

    
//    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkDidUpdate:)];
//    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
//    self.displayLink.preferredFramesPerSecond = 25;
//    [self.displayLink setPaused:YES];
    
//    self.pixelBufferArray = [[NSMutableArray alloc] init];
    
    self.audioPlayer = [[PCMAudioPlayer alloc] init];
    self.audioPlayer.delegate = self;
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [self postFinishLaunchWithWidth:width height:height];
//    });

}

- (void)postFinishLaunchWithWidth:(int)width height:(int)height {
    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        NSLog(@"Could not initialize SDL");
        return;
    }
    SDL_Window *window =
           SDL_CreateWindow("", 0, 0,
                            0, 0, SDL_WINDOW_FOREIGN);
//    SDL_SetWindowPosition(window, 20 , 300);
//    SDL_ShowWindow(window);
    sdl_window = window;
    if (window) {
        SDL_Renderer *renderer = SDL_CreateRenderer(sdl_window, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
        sdl_renderer = renderer;
        if (!sdl_renderer) {
            av_log(NULL, AV_LOG_WARNING, "Failed to initialize a hardware accelerated renderer: %s\n", SDL_GetError());
            sdl_renderer = SDL_CreateRenderer(window, -1, 0);
        }
        if (sdl_renderer) {
            if (!SDL_GetRendererInfo(renderer, &renderer_info))
                av_log(NULL, AV_LOG_VERBOSE, "Initialized %s renderer.\n", renderer_info.name);
        }
        if (!window || !renderer || !renderer_info.num_texture_formats) {
                   av_log(NULL, AV_LOG_FATAL, "Failed to create window or renderer: %s", SDL_GetError());
            return ;
        }
    }
 
//    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
//    SDL_GL_SetAttribute(SDL_GL_ACCELERATED_VISUAL, 1);
//    SDL_GL_SetAttribute(SDL_GL_RED_SIZE, 8);
//    SDL_GL_SetAttribute(SDL_GL_GREEN_SIZE, 8);
//    SDL_GL_SetAttribute(SDL_GL_BLUE_SIZE, 8);
//    SDL_GL_SetAttribute(SDL_GL_ALPHA_SIZE, 8);
//    SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);
//    SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, 8);
//
//    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
//    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 2);
//    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
 
//    SDL_GLContext gl_context = SDL_GL_CreateContext(window);
//    SDL_GL_MakeCurrent(window, gl_context);
//    SDL_GL_SetSwapInterval(1); // Enable vsync

//    self.sdlView = [[SDL_uikitview alloc] initWithFrame:CGRectMake(20, 200, width, height)];
//    [self.view addSubview:self.sdlView];
//    [self.sdlView setSDLWindow:window];
    
    [self clickDecodeButton:nil];
}

- (void)decoderThread:(DecodeThread *)decoderThread didDecodeFrame:(AVFrame *)frame {
    if (decoderThread.params->codec_type == AVMEDIA_TYPE_VIDEO) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self dispatchAVFrame:frame];
        });
    }
}

- (void)decoder:(Decoder *)decoder didDecodeFrame:(AVFrame *)frame {
    if (decoder.params->codec_type == AVMEDIA_TYPE_VIDEO) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self dispatchAVFrame:frame];
        });
    }
}

- (void)decoder:(Decoder *)decoder didDecodeFrame:(uint8_t *)data length:(int)len {
//    if (audioDescription.mReserved == 0) {
//        audioDescription.mSampleRate = frame->sample_rate;
//        audioDescription.mChannelsPerFrame = frame->channels;
//        audioDescription.mReserved = 1;
//        self.audioPlayer.audioDescription = audioDescription;
//    }
    
    [self.audioPlayer play:data length:len];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)clickDecodeButton:(id)sender {
    NSString *input_str= [NSString stringWithFormat:@"resource.bundle/%@",self.inputurl.text];
//    NSString *input_str = [NSString stringWithFormat:@"resource.bundle/%@",@"IMG_0283.MOV"];
    NSString *input_nsstr=[[[NSBundle mainBundle]resourcePath] stringByAppendingPathComponent:input_str];
    
    Demuxer *demuxer = [[Demuxer alloc] initWithUrl:input_nsstr decodeDelegate:self];
    [demuxer start];
}


static void calculate_display_rect(SDL_Rect *rect,
                                   int scr_xleft, int scr_ytop, int scr_width, int scr_height,
                                   int pic_width, int pic_height, AVRational pic_sar)
{
    AVRational aspect_ratio = pic_sar;
    int64_t width, height, x, y;

    if (av_cmp_q(aspect_ratio, av_make_q(0, 1)) <= 0)
        aspect_ratio = av_make_q(1, 1);

    aspect_ratio = av_mul_q(aspect_ratio, av_make_q(pic_width, pic_height));

    /* XXX: we suppose the screen has a 1.0 pixel ratio */
    height = scr_height;
    width = av_rescale(height, aspect_ratio.num, aspect_ratio.den) & ~1;
    if (width > scr_width) {
        width = scr_width;
        height = av_rescale(width, aspect_ratio.den, aspect_ratio.num) & ~1;
    }
    x = (scr_width - width) / 2;
    y = (scr_height - height) / 2;
    rect->x = scr_xleft + x;
    rect->y = scr_ytop  + y;
    rect->w = FFMAX((int)width,  1);
    rect->h = FFMAX((int)height, 1);
}

static void get_sdl_pix_fmt_and_blendmode(int format, Uint32 *sdl_pix_fmt, SDL_BlendMode *sdl_blendmode)
{
    int i;
    *sdl_blendmode = SDL_BLENDMODE_NONE;
    *sdl_pix_fmt = SDL_PIXELFORMAT_UNKNOWN;
    if (format == AV_PIX_FMT_RGB32   ||
        format == AV_PIX_FMT_RGB32_1 ||
        format == AV_PIX_FMT_BGR32   ||
        format == AV_PIX_FMT_BGR32_1)
        *sdl_blendmode = SDL_BLENDMODE_BLEND;
    for (i = 0; i < FF_ARRAY_ELEMS(sdl_texture_format_map) - 1; i++) {
        if (format == sdl_texture_format_map[i].format) {
            *sdl_pix_fmt = sdl_texture_format_map[i].texture_fmt;
            return;
        }
    }
}

static int realloc_texture(SDL_Texture **texture, Uint32 new_format, int new_width, int new_height, SDL_BlendMode blendmode, int init_texture)
{
    Uint32 format;
    int access, w, h;
    if (!*texture || SDL_QueryTexture(*texture, &format, &access, &w, &h) < 0 || new_width != w || new_height != h || new_format != format) {
        void *pixels;
        int pitch;
        if (*texture)
            SDL_DestroyTexture(*texture);
        if (!(*texture = SDL_CreateTexture(sdl_renderer, new_format, SDL_TEXTUREACCESS_STREAMING, new_width, new_height)))
            return -1;
        if (SDL_SetTextureBlendMode(*texture, blendmode) < 0)
            return -1;
        if (init_texture) {
            if (SDL_LockTexture(*texture, NULL, &pixels, &pitch) < 0)
                return -1;
            memset(pixels, 0, pitch * new_height);
            SDL_UnlockTexture(*texture);
        }
        av_log(NULL, AV_LOG_VERBOSE, "Created %dx%d texture with %s.\n", new_width, new_height, SDL_GetPixelFormatName(new_format));
    }
    return 0;
}

static int upload_texture(SDL_Texture **tex, AVFrame *frame, struct SwsContext **img_convert_ctx) {
    int ret = 0;
    Uint32 sdl_pix_fmt;
    SDL_BlendMode sdl_blendmode;
    get_sdl_pix_fmt_and_blendmode(frame->format, &sdl_pix_fmt, &sdl_blendmode);
    if (realloc_texture(tex, sdl_pix_fmt == SDL_PIXELFORMAT_UNKNOWN ? SDL_PIXELFORMAT_ARGB8888 : sdl_pix_fmt, frame->width, frame->height, sdl_blendmode, 0) < 0)
        return -1;
    switch (sdl_pix_fmt) {
        case SDL_PIXELFORMAT_UNKNOWN:
            /* This should only happen if we are not using avfilter... */
            *img_convert_ctx = sws_getCachedContext(*img_convert_ctx,
                frame->width, frame->height, frame->format, frame->width, frame->height,
                AV_PIX_FMT_BGRA, sws_flags, NULL, NULL, NULL);
            if (*img_convert_ctx != NULL) {
                uint8_t *pixels[4];
                int pitch[4];
                if (!SDL_LockTexture(*tex, NULL, (void **)pixels, pitch)) {
                    sws_scale(*img_convert_ctx, (const uint8_t * const *)frame->data, frame->linesize,
                              0, frame->height, pixels, pitch);
                    SDL_UnlockTexture(*tex);
                }
            } else {
                av_log(NULL, AV_LOG_FATAL, "Cannot initialize the conversion context\n");
                ret = -1;
            }
            break;
        case SDL_PIXELFORMAT_IYUV:
            if (frame->linesize[0] > 0 && frame->linesize[1] > 0 && frame->linesize[2] > 0) {
                ret = SDL_UpdateYUVTexture(*tex, NULL, frame->data[0], frame->linesize[0],
                                                       frame->data[1], frame->linesize[1],
                                                       frame->data[2], frame->linesize[2]);
            } else if (frame->linesize[0] < 0 && frame->linesize[1] < 0 && frame->linesize[2] < 0) {
                ret = SDL_UpdateYUVTexture(*tex, NULL, frame->data[0] + frame->linesize[0] * (frame->height                    - 1), -frame->linesize[0],
                                                       frame->data[1] + frame->linesize[1] * (AV_CEIL_RSHIFT(frame->height, 1) - 1), -frame->linesize[1],
                                                       frame->data[2] + frame->linesize[2] * (AV_CEIL_RSHIFT(frame->height, 1) - 1), -frame->linesize[2]);
            } else {
                av_log(NULL, AV_LOG_ERROR, "Mixed negative and positive linesizes are not supported.\n");
                return -1;
            }
            break;
        default:
            if (frame->linesize[0] < 0) {
                ret = SDL_UpdateTexture(*tex, NULL, frame->data[0] + frame->linesize[0] * (frame->height - 1), -frame->linesize[0]);
            } else {
                ret = SDL_UpdateTexture(*tex, NULL, frame->data[0], frame->linesize[0]);
            }
            break;
    }
    return ret;
}

- (void)dispatchAVFrame:(AVFrame*) frame{
//    SDL_SetRenderDrawColor(sdl_renderer, 0, 0, 0, 255);
//    SDL_RenderClear(sdl_renderer);
//    SDL_Rect rect;
//    calculate_display_rect(&rect, 0, 0, self.view.bounds.size.width, self.view.bounds.size.height, frame->width, frame->height, frame->sample_aspect_ratio);
//    SDL_Texture *texture = NULL;
//    if (upload_texture(&texture, frame, NULL) < 0) {
////        set_sdl_yuv_conversion_mode(NULL);
//        return;
//    }
//    SDL_RenderCopyEx(sdl_renderer, texture, NULL, &rect, 0, NULL,  0);
//    SDL_RenderPresent(sdl_renderer);
//
//    return;

    
    if(!frame || !frame->data[0]){
        return;
    }
 
    CVReturn theError;
    if (!self.pixelBufferPool){
        NSMutableDictionary* attributes = [NSMutableDictionary dictionary];
        [attributes setObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange] forKey:(NSString*)kCVPixelBufferPixelFormatTypeKey];
        [attributes setObject:[NSNumber numberWithInt:frame->width] forKey: (NSString*)kCVPixelBufferWidthKey];
        [attributes setObject:[NSNumber numberWithInt:frame->height] forKey: (NSString*)kCVPixelBufferHeightKey];
        [attributes setObject:@(frame->linesize[0]) forKey:(NSString*)kCVPixelBufferBytesPerRowAlignmentKey];
        [attributes setObject:[NSDictionary dictionary] forKey:(NSString*)kCVPixelBufferIOSurfacePropertiesKey];
        theError = CVPixelBufferPoolCreate(kCFAllocatorDefault, NULL, (__bridge CFDictionaryRef) attributes, &_pixelBufferPool);
        if (theError != kCVReturnSuccess){
            NSLog(@"CVPixelBufferPoolCreate Failed");
        }
    }

    CVPixelBufferRef pixelBuffer = nil;
    theError = CVPixelBufferPoolCreatePixelBuffer(NULL, self.pixelBufferPool, &pixelBuffer);
    if(theError != kCVReturnSuccess){
        NSLog(@"CVPixelBufferPoolCreatePixelBuffer Failed");
    }

    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
//    size_t bytePerRowY = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
//    size_t bytesPerRowUV = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);
    void* base = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    memcpy(base, frame->data[0], frame->linesize[0] * frame->height);
//    uint8_t* yData = fixData(frame->width, frame->height, frame->data[0], frame->linesize[0]);
//    memcpy(base, yData, frame->width * frame->height);
    base = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
//    memcpy(base, frame->data[1], frame->linesize[1] * frame->height/2);
    uint32_t size = frame->width/2 * frame->height/2;
    uint8_t* dstData = (uint8_t*) malloc(2 * size);
//    uint8_t* uData = fixData(frame->width/2, frame->height/2, frame->data[1], frame->linesize[1]);
//    uint8_t* vData = fixData(frame->width/2, frame->height/2, frame->data[2], frame->linesize[2]);
    for (int i = 0; i < 2 * size; i++){
        if (i % 2 == 0){
            dstData[i] = frame->data[1][i/2];
//            dstData[i] = uData[i/2];
        }else {
            dstData[i] = frame->data[2][i/2];
//            dstData[i] = vData[i/2];
        }
    }
    memcpy(base, dstData, 2* size);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);

    [self dispatchPixelBuffer:pixelBuffer];
    free(dstData);
    CVPixelBufferRelease(pixelBuffer);
//    uint8_t *frameData0, *frameData1, *frameData2;
//    frameData0 = fixData(frame->width, frame->height, frame->data[0], frame->linesize[0]);
//    frameData1 = fixData(frame->width/2, frame->height/2, frame->data[1], frame->linesize[1]);
//    frameData2 = fixData(frame->width/2, frame->height/2, frame->data[2], frame->linesize[2]);
//
//    [self.glView renderBufferWithYData:frameData0 uData:frameData1 vData:frameData2 frameWidth:frame->width frameHeight:frame->height];
//
//    if (frameData0) {
//        free(frameData0);
//    }
//    if (frameData1) {
//        free(frameData1);
//    }
//    if (frameData2) {
//        free(frameData2);
//    }
    //本来应该在decoder里面释放的，但是因为渲染线程跟解码线程不一样，所以延迟到渲染结束后再释放
    av_frame_free(&frame);
}

static uint8_t* fixData(GLsizei width, GLsizei height,  const GLvoid *pixels, GLint pitch)
{
    uint8_t *blob = NULL;
    Uint8 *src;
    int src_pitch;
    int y;

    /* Reformat the texture data into a tightly packed array */
    src_pitch = width ;
    src = (uint8_t *)pixels;
    if (pitch != src_pitch) {
        blob = (uint8_t *)malloc(src_pitch * height);
        if (!blob) {
            return nil;
        }
        src = blob;
        for (y = 0; y < height; ++y)
        {
            memcpy(src, pixels, src_pitch);
            src += src_pitch;
            pixels = (Uint8 *)pixels + pitch;
        }
        src = blob;
    }

//    glTexSubImage2D(target, 0, xoffset, yoffset, width, height, format, type, src);
//    if (blob) {
//        SDL_free(blob);
//    }
    return src;
}

- (void)dispatchPixelBuffer:(CVPixelBufferRef)pixelBuffer {
//    [self.pixelBufferArray addObject:(__bridge id _Nonnull)(pixelBuffer)];

//    self.glLayer.pixelBuffer = pixelBuffer;
//    [self.glView dispatchPixelBuffer:pixelBuffer];
    
    [self.glView renderBufferWithPixelBuffer:pixelBuffer];
   
}


- (UIImage *)imageFromAVPicture:(AVFrame)pict width:(int)width height:(int)height {
 
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CFDataRef data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault, pict.data[0], pict.linesize[0] * height,kCFAllocatorNull);
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageRef cgImage = CGImageCreate(width,
                                       height,
                                       8,
                                       24,
                                       pict.linesize[0],
                                       colorSpace,
                                       bitmapInfo,
                                       provider,
                                       NULL,
                                       YES,
                                       kCGRenderingIntentDefault);
    CGColorSpaceRelease(colorSpace);
    UIImage *image = [[UIImage alloc]initWithCGImage:cgImage];
    
    CGImageRelease(cgImage);
    CGDataProviderRelease(provider);
    CFRelease(data);
    
    return image;
}

@end
