//
//  VideoContext.m
//  SFFmpegIOSDecoder
//
//  Created by 罗谨 on 2023/1/9.
//  Copyright © 2023 Lei Xiaohua. All rights reserved.
//

#import "VideoContext.h"


@implementation VideoContext

static  VideoContext* _instance = nil;

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[VideoContext alloc] init];
    });
    return _instance;
}

static int My_TexImage2D( GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLenum format, GLenum type, const GLvoid *pixels, GLint pitch)
{
    UInt8 *blob = NULL;
    UInt8 *src;
    int src_pitch;
    int y;

    /* Reformat the texture data into a tightly packed array */
    src_pitch = width ;
    src = (UInt8 *)pixels;
    if (pitch != src_pitch) {
        blob = (UInt8 *)malloc(src_pitch * height);
        if (!blob) {
            return -1;
        }
        src = blob;
        for (y = 0; y < height; ++y)
        {
            memcpy(src, pixels, src_pitch);
            src += src_pitch;
            pixels = (UInt8 *)pixels + pitch;
        }
        src = blob;
    }

//    glTexSubImage2D(target, 0, xoffset, yoffset, width, height, format, type, src);
    glTexImage2D(target, level, internalformat, width, height, 0, format, type, src);
    if (blob) {
        free(blob);
    }
    return 0;
}

@end
