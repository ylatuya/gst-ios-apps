/*
 * GStreamer Player demo app for IOS
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

#import "PlaybackViewController.h"
#include <gst/gst.h>
#include <gst/interfaces/xoverlay.h>

@implementation PlaybackViewController

@synthesize backButton;
@synthesize playButton;
@synthesize screenView;
@synthesize slider;
@synthesize positionLabel;

-(void) _poll_gst_bus
{
    GstBus *bus;
    GstMessage *msg;
        
    /* Wait until error or EOS */
    bus = gst_element_get_bus (self->pipeline);
    msg = gst_bus_timed_pop_filtered(bus, GST_CLOCK_TIME_NONE,
                                         (GstMessageType) (GST_MESSAGE_ERROR | GST_MESSAGE_EOS | GST_MESSAGE_DURATION| GST_MESSAGE_STATE_CHANGED));
    gst_object_unref(bus);
    
    switch (GST_MESSAGE_TYPE(msg)) {
        case GST_MESSAGE_EOS:
            [self stop];
            NSLog(@"EOS");
            break;
        case GST_MESSAGE_ERROR: {
            GError *gerr = NULL;
            gchar *debug;
            
            gst_message_parse_error(msg, &gerr, &debug);
            
            [self stop];
            NSLog(@"Error %s - %s", gerr->message, debug, nil);
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Playback error"
                                                            message:[NSString stringWithUTF8String:gerr->message]
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                [alert show];
            });
            
            //[alert release];
            
        }
            break;
        case GST_MESSAGE_DURATION: {
            GstFormat format;
            gint64 dur;
            
            gst_message_parse_duration(msg, &format, &dur);
            if (format == GST_FORMAT_TIME && GST_CLOCK_TIME_IS_VALID(dur)) {
                self->duration = (GstClockTime) dur;
                [self updatePositionUI];
            } else {
                [self queryDuration];
            }
        }
            break;
        case GST_MESSAGE_STATE_CHANGED: {
            GstState state;
            if (GST_MESSAGE_SRC(msg) == GST_OBJECT_CAST(self->pipeline)) {
                gst_message_parse_state_changed(msg, NULL, &state, NULL);
                if (state == GST_STATE_PLAYING) {
                    [self startPositionTimer];
                } else if (state == GST_STATE_READY) {
                    [self stopPositionTimer];
                }
            }
        }
            break;
        default:
            break;
    }
}

-(void)initialize
{
    if (self->pipeline == NULL) {
        self->pipeline = gst_element_factory_make("playbin2", NULL);
        self->videosink = gst_element_factory_make("eglglessink", "videosink");

        g_object_set(self->pipeline, "video-sink", self->videosink, NULL);
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            while (1) {
                GST_ERROR ("Starting loop!");
                [self _poll_gst_bus];
            }
        });
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [self initialize];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [self initialize];
    gst_x_overlay_set_window_handle(GST_X_OVERLAY(self->videosink), (guintptr) (id) self.screenView);
}

- (void)dealloc
{
    if (self->pipeline) {
        gst_element_set_state(self->pipeline, GST_STATE_NULL);
        gst_object_unref(self->pipeline);
    }
    //[super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)back:(id)sender {
    gst_element_set_state(self->pipeline, GST_STATE_NULL);
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)togglePlay:(id)sender
{
    GstState current = GST_STATE_PLAYING;
    GstState pending = GST_STATE_PLAYING;
    
    gst_element_get_state(self->pipeline, &current, &pending, 0);
    if (current == GST_STATE_PLAYING || pending == GST_STATE_PLAYING) {
        /* consider playing */
        [self pause];
    } else {
        [self play];
    }
}

-(void)pause
{
    gst_element_set_state(self->pipeline, GST_STATE_PAUSED);
    playButton.title = @"Play";
}

-(void)stop
{
    gst_element_set_state(self->pipeline, GST_STATE_READY);
    playButton.title = @"Play";
}

-(void)play
{
    gst_element_set_state(self->pipeline, GST_STATE_PLAYING);
    playButton.title = @"Pause";
}

-(void)setURI:(NSString*)uri
{
    g_object_set(self->pipeline, "uri", [uri UTF8String], NULL);
}

-(void)queryDuration
{
    gint64 dur;
    GstFormat format = GST_FORMAT_TIME;
    gst_element_query_duration(self->pipeline, &format, &dur);

    if (format == GST_FORMAT_TIME) {
        self->duration = (GstClockTime) dur;
        [self updatePositionUI];
    }
}

-(void)queryPosition:(NSTimer*) timer
{
    gint64 pos;
    GstFormat format = GST_FORMAT_TIME;
    gst_element_query_position(self->pipeline, &format, &pos);
    
    if (format == GST_FORMAT_TIME) {
        self->position = (GstClockTime) pos;
        if (!GST_CLOCK_TIME_IS_VALID(duration) || duration == 0) {
            [self queryDuration];
        } else {
            [self updatePositionUI];
        }
    }
}

-(void)updatePositionUI
{
    NSString *position_txt = @" -- ";
    NSString *duration_txt = @" -- ";
    
    if (GST_CLOCK_TIME_IS_VALID(self->duration)) {
        NSUInteger hours = (self->duration / GST_SECOND) / (60 * 60);
        NSUInteger minutes = ((self->duration / GST_SECOND) / 60) % 60;
        NSUInteger seconds = (self->duration / GST_SECOND) % 60;
        
        duration_txt = [NSString stringWithFormat:@"%02u:%02u:%02u", hours, minutes, seconds, nil];
    }
    if (GST_CLOCK_TIME_IS_VALID(self->position)) {
        NSUInteger hours = (self->position / GST_SECOND) / (60 * 60);
        NSUInteger minutes = ((self->position / GST_SECOND) / 60) % 60;
        NSUInteger seconds = (self->position / GST_SECOND) % 60;
        
        position_txt = [NSString stringWithFormat:@"%02u:%02u:%02u", hours, minutes, seconds, nil];
    }
    
    NSString *text = [NSString stringWithFormat:@"%@ / %@",
                      position_txt, duration_txt, nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.positionLabel.text = text;
        
        if (GST_CLOCK_TIME_IS_VALID(self->duration)) {
            [self.slider setMaximumValue:(self->duration/GST_SECOND)];
            if (GST_CLOCK_TIME_IS_VALID(self->position)) {
                [self.slider setValue:(self->position/GST_SECOND)];
            }
        } else {
            [self.slider setValue:0];
        }
    });
}

-(void)startPositionTimer
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self->positionTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(queryPosition:) userInfo:nil repeats:YES];
    });
}

-(void)stopPositionTimer
{
    [self->positionTimer invalidate];
}

-(IBAction)sliderChange:(id)sender {
    gint64 pos = ((gint64) [slider value]) * GST_SECOND;
    
    NSLog(@"Seeking to position: %llu", pos, nil);
    
    gst_element_seek_simple(self->pipeline, GST_FORMAT_TIME, GST_SEEK_FLAG_FLUSH, pos);
}

@end
