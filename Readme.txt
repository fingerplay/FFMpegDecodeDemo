����ffmpeg ����h264�Ľ��룬 ��ͨ��opengles������Ⱦ

���벿�֣�
�ο�ffplay ,ͨ��demuxer��decoder ��������ʵ����Ƶ�Ľ��װ�ͽ��룬���������и��Ե��̣߳�ȷ�����ܲ���Ӱ��

����Ƶͬ����
��Ƶ����Ƶ���룬ͨ���Ա� pts ��ʵ�ַ���Ϊ
- (BOOL)scheduleVideoFrame:(AVFrame*)avFrame fps:(double)fps frame_delay:(double)frame_delay 

��Ⱦ���֣�
���ڲ��Ե���Ƶ����ʹ��yuv420���룬���ʹ����Y��UV˫ƽ�����ķ�ʽ�������������ݴ����CVPixelBufferRef�����У����ݸ�openglES������Ⱦ��Ҳ����ֱ�Ӵ������ݸ�openglES��������ʹ��CVOpenGLESTextureCacheCreateTextureFromImage������������Բο�ע�͵��Ĵ���ʹ��glTexImage2D�������������ݡ�