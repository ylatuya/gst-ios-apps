#ifndef GstAudioTest_gst_backend_h
#define GstAudioTest_gst_backend_h


#include <gst/gst.h>

typedef struct {
    GstElement *pipeline;
    GstElement *capsfilter;
    GstState state;
} GstApp;

void gst_backend_initialize(void);
GstApp* gst_backend_audio_playback_start (void);
void gst_backend_audio_playback_play (GstApp *app);
void gst_backend_audio_playback_pause (GstApp *app);
void gst_backend_audio_playback_toggle_play (GstApp *app);
void gst_backend_audio_playback_stop (GstApp *app);
void gst_backend_audio_playback_set_format (GstApp *app, const gchar *format);

#endif
