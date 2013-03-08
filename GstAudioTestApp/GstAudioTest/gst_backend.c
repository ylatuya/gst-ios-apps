
#include <stdio.h>
#include "gst_backend.h"

GST_PLUGIN_STATIC_DECLARE (coreelements);
GST_PLUGIN_STATIC_DECLARE (audiotestsrc);
GST_PLUGIN_STATIC_DECLARE (audioconvert);
GST_PLUGIN_STATIC_DECLARE (osxaudio);


void gst_backend_initialize()
{
    setenv ("GST_DEBUG", "2", 1);
    setenv ("GST_PLUGIN_SYSTEM_PATH", "/bar/foo", 1);
    gst_init(NULL, NULL);
    GST_PLUGIN_STATIC_REGISTER (coreelements);
    GST_PLUGIN_STATIC_REGISTER (audiotestsrc);
    GST_PLUGIN_STATIC_REGISTER (audioconvert);
    GST_PLUGIN_STATIC_REGISTER (osxaudio);
}

static void
_set_state (GstApp *app, GstState state)
{
    app->state = state;
    gst_element_set_state (app->pipeline, app->state);
    GST_INFO ("State changed to %d", app->state);
}

void gst_backend_audio_playback_set_format (GstApp *app, const gchar *format)
{
    GstCaps *caps;
    
    if (app == NULL)
        return;
    
    caps = gst_caps_from_string(format);
    if (caps == NULL) {
        GST_ERROR ("Could not parse caps: %s", format);
        return;
    }
    
    g_object_set(app->capsfilter, "caps", caps, NULL);
    gst_caps_unref(caps);
}

GstApp* gst_backend_audio_playback_start()
{
    GstApp *app;
    
    app = malloc(sizeof (GstApp));
    
    /* Build the pipeline */
    app->pipeline = gst_parse_launch ("audiotestsrc ! capsfilter name=filter ! osxaudiosink", NULL);
    app->capsfilter = gst_bin_get_by_name (GST_BIN (app->pipeline), "filter");
    
    return app;
}

void gst_backend_audio_playback_pause (GstApp *app)
{
    if (app == NULL)
        return;
    
    _set_state (app, GST_STATE_PAUSED);
}

void gst_backend_audio_playback_play (GstApp *app)
{
    if (app == NULL)
        return;
    
    _set_state (app, GST_STATE_PLAYING);
}

void gst_backend_audio_playback_toggle_play (GstApp *app)
{
    if (app == NULL)
        return;
    
    if (app->state == GST_STATE_PLAYING)
        _set_state (app, GST_STATE_PAUSED);
    else if (app->state == GST_STATE_PAUSED)
        _set_state (app, GST_STATE_PLAYING);
}

void gst_backend_audio_playback_stop (GstApp *app)
{
    if (app == NULL)
        return;
    _set_state (app, GST_STATE_NULL);
    gst_object_unref (app->pipeline);
    g_free (app);
    app = NULL;
}