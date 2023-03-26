//
//  VideoContext.h
//  SFFmpegIOSDecoder
//
//  Created by 罗谨 on 2023/1/9.
//  Copyright © 2023 Lei Xiaohua. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <GLKit/GLKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface VideoContext : NSObject

@property (nonatomic, assign) double audio_pts_second;

+ (instancetype)sharedInstance;

@end

static int My_TexImage2D( GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height,  GLenum format, GLenum type, const GLvoid *pixels, GLint pitch);

NS_ASSUME_NONNULL_END
