//
//  GLView.m
//  SFFmpegIOSDecoder
//
//  Created by 罗谨 on 2023/1/3.
//  Copyright © 2023 Lei Xiaohua. All rights reserved.
//

#import "GLView.h"
#import <OpenGLES/ES3/gl.h>
#import <OpenGLES/ES3/glext.h>
@implementation GLView

- (instancetype)initWithFrame:(CGRect)frame context:(nonnull EAGLContext *)context{
    self = [super initWithFrame:frame context:context];
    if (self) {
        _eaglLayer = (CAEAGLLayer*)self.layer;
        _eaglLayer.frame = self.frame;
        _eaglLayer.opaque = YES;
        _eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],kEAGLDrawablePropertyRetainedBacking,kEAGLColorFormatRGBA8,kEAGLDrawablePropertyColorFormat, nil];
    }
    return self;
}

- (void)didMoveToSuperview{
    
    glGenRenderbuffers(1, &_colorBufferRender);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorBufferRender);
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
        
    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
        
    glFramebufferRenderbuffer(GL_FRAMEBUFFER,
                                  GL_COLOR_ATTACHMENT0,
                                  GL_RENDERBUFFER,
                                  _colorBufferRender);
    
    glClearColor(0.5f, 0.5f, 0.5f, 1.0f);

    glClear(GL_COLOR_BUFFER_BIT);

    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}


@end
