/*
 * GStreamer EAGL demo app for IOS
 * Copyright (C) 2013 Collabora Ltd.
 *   @author: Thiago Santos <thiago.sousa.santos@collabora.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 *
 * Alternatively, the contents of this file may be used under the
 * GNU Lesser General Public License Version 2.1 (the "LGPL"), in
 * which case the following provisions apply instead of the ones
 * mentioned above:
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

#include <stdio.h>
#include "gst_backend.h"
#include <dispatch/dispatch.h>

#include <gst/interfaces/xoverlay.h>

GST_PLUGIN_STATIC_DECLARE (coreelements);
GST_PLUGIN_STATIC_DECLARE (videotestsrc);
GST_PLUGIN_STATIC_DECLARE (eglglessink);


void gst_backend_initialize()
{
    setenv ("GST_DEBUG", "2", 1);
    gst_init(NULL, NULL);
    GST_PLUGIN_STATIC_REGISTER (coreelements);
    GST_PLUGIN_STATIC_REGISTER (videotestsrc);
    GST_PLUGIN_STATIC_REGISTER (eglglessink);
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
void gst_backend_video_playback_set_format (GstApp *app, const gchar *format)
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

GstApp* gst_backend_video_playback_start(UIView * view)
{
    GstApp *app;
    
    app = (GstApp*) malloc(sizeof (GstApp));
    
    /* Build the pipeline */
    app->pipeline = gst_parse_launch ("videotestsrc ! capsfilter name=filter caps=video/x-raw-yuv,framerate=15/1,width=512,height=512 ! eglglessink name=sink", NULL);
    app->capsfilter = gst_bin_get_by_name (GST_BIN (app->pipeline), "filter");
    app->sink = gst_bin_get_by_name(GST_BIN (app->pipeline), "sink");
    
    gst_x_overlay_set_window_handle(GST_X_OVERLAY(app->sink), (guintptr) view);
    
    app->running = TRUE;
    _start_run_loop(app);
    return app;
}

void gst_backend_video_playback_pause (GstApp *app)
{
    if (app == NULL)
        return;
    
    _set_state (app, GST_STATE_PAUSED);
}


void gst_backend_video_playback_play (GstApp *app)
{
    if (app == NULL)
        return;
    
    _set_state (app, GST_STATE_PLAYING);
}

void gst_backend_video_playback_toggle_play (GstApp *app)
{
    if (app == NULL)
        return;
    
    if (app->state == GST_STATE_PLAYING)
        _set_state (app, GST_STATE_PAUSED);
    else if (app->state == GST_STATE_PAUSED)
        _set_state (app, GST_STATE_PLAYING);
}

void gst_backend_video_playback_stop (GstApp *app)
{
    if (app == NULL)
        return;
    app->running = FALSE;
    _set_state (app, GST_STATE_NULL);
    gst_object_unref (app->pipeline);
    g_free (app);
    app = NULL;
}