
#include <stdio.h>
#include "gst_backend.h"
#include <dispatch/dispatch.h>

GST_PLUGIN_STATIC_DECLARE (coreelements);
GST_PLUGIN_STATIC_DECLARE (audiotestsrc);
GST_PLUGIN_STATIC_DECLARE (audioconvert);
GST_PLUGIN_STATIC_DECLARE (osxaudio);


void gst_backend_initialize()
{
    setenv ("GST_DEBUG", "2", 1);
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

static void
_post_error (GstApp *app, NSString *errorMessage)
{   
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *userInfo;
        
        userInfo = [NSDictionary dictionaryWithObject:errorMessage
                                               forKey:@"Message"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"GstErrorEvent"
                                                            object:nil
                                                          userInfo:userInfo];
    });
}

static void
_poll_bus (GstApp *app)
{
    GstBus *bus;
    GstMessage *msg;
    
    /* Wait until error or EOS */
    bus = gst_element_get_bus (app->pipeline);
    msg = gst_bus_timed_pop_filtered(bus, GST_CLOCK_TIME_NONE,
                                     (GstMessageType) (GST_MESSAGE_ERROR | GST_MESSAGE_EOS));
    GST_ERROR ("New message!");
       
    /* Parse message */
    if (msg != NULL) {
        GError *err;
        gchar *debug_info;
        
        switch (GST_MESSAGE_TYPE (msg)) {
            case GST_MESSAGE_ERROR: {
                NSString *error_msg;
                
                gst_message_parse_error (msg, &err, &debug_info);
                
                error_msg = [NSString stringWithFormat:@"Error received from element %s: %s\n"
                             "Debugging information: %s\n", GST_OBJECT_NAME (msg->src), err->message,
                             debug_info ? debug_info : "none"];
                g_clear_error (&err);
                g_free (debug_info);
                _post_error(app, error_msg);
                break;
            }
            case GST_MESSAGE_EOS:
                g_print ("End-Of-Stream reached.\n");
                break;
            default:
                /* We should not reach here because we only asked for ERRORs and EOS */
                g_printerr ("Unexpected message received.\n");
                break;
        }
        gst_message_unref (msg);
    }
}

static void
_start_run_loop (GstApp *app)
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (app->running) {
            GST_ERROR ("Starting loop!");
            _poll_bus(app);
        }
    });
    
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
    
    app = (GstApp*) malloc(sizeof (GstApp));
    
    /* Build the pipeline */
    app->pipeline = gst_parse_launch ("audiotestsrc ! capsfilter name=filter ! osxaudiosink", NULL);
    app->capsfilter = gst_bin_get_by_name (GST_BIN (app->pipeline), "filter");
    app->running = TRUE;
    _start_run_loop(app);
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
    app->running = FALSE;
    _set_state (app, GST_STATE_NULL);
    gst_object_unref (app->pipeline);
    g_free (app);
    app = NULL;
}