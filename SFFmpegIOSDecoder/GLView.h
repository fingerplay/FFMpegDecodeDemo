//
//  GLView.h
//  SFFmpegIOSDecoder
//
//  Created by 罗谨 on 2023/1/3.
//  Copyright © 2023 Lei Xiaohua. All rights reserved.
//

#import <UIKit/UIKit.h>
#include <GLKit/GLKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface GLView : GLKView {
    EAGLContext *_context;
    CAEAGLLayer *_eaglLayer;
    GLuint _colorBufferRender;
    GLuint _frameBuffer;
//    uint32_t m_tex_y;
//    uint32_t m_tex_u;
//    uint32_t m_tex_v;
//    uint32_t m_vertex_array;
//    uint32_t m_vertex_buffer;
//    uint32_t m_index_buffer;
//    const  int m_wnd_width;
//    const  int m_wnd_height;
//
//    int         m_tex_width;
//    int         m_tex_height;
//    ShaderParse m_shader_parse;
}
//@property (nonatomic, strong) EAGLContext* eaglContext;
bool InitRender(int frame_w, int frame_h);
bool UpLoadFrame(uint8_t* y, uint8_t* u, uint8_t* v);
void RenderFrame();

@end

NS_ASSUME_NONNULL_END
