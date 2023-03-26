基于ffmpeg 进行h264的解码， 并通过opengles进行渲染

解码部分：
参考ffplay ,通过demuxer和decoder 两个对象实现视频的解封装和解码，两个对象有各自的线程，确保性能不受影响

音视频同步：
视频向音频靠齐，通过对比 pts ，实现方法为
- (BOOL)scheduleVideoFrame:(AVFrame*)avFrame fps:(double)fps frame_delay:(double)frame_delay 

渲染部分：
由于测试的视频都是使用yuv420编码，因此使用了Y和UV双平面编码的方式，将解码后的数据打包到CVPixelBufferRef对象中，传递给openglES进行渲染。也可以直接传递数据给openglES，但不能使用CVOpenGLESTextureCacheCreateTextureFromImage这个方法，可以参考注释掉的代码使用glTexImage2D来载入纹理数据。