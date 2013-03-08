//
//  ViewController.m
//  GstAudioTest
//
//  Created by FLUENDO on 06/03/13.
//  Copyright (c) 2013 FLUENDO. All rights reserved.
//

#import "ViewController.h"
#import "gst_backend.h"

@interface ViewController ()

@end

@implementation ViewController

static GstApp *app = NULL;

- (void)viewDidLoad
{
    formatValues = [[NSArray alloc] initWithObjects:
                    @"audio/x-raw-int", @"audio/x-raw-float", nil];
    
    sampleRateValues = [[NSArray alloc] initWithObjects:
                        @"48000", @"44100", @"32000", @"24000",
                        @"22050", @"16000", @"12000", @"8000", nil];
    
    widthValues = [[NSArray alloc] initWithObjects:
                   @"32", @"24", @"16", @"8", nil];

    formatLabel.text = [self getCaps];
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString*)getCaps
{
    return [NSString stringWithFormat:@"%@,width=%@,rate=%@",
               [self->formatValues objectAtIndex:self->selectedFormat],
               [self->widthValues objectAtIndex:self->selectedWidth],
               [self->sampleRateValues objectAtIndex:self->selectedSampleRate]];

}

- (IBAction)ApplyFormat:(id)sender {
    formatLabel.text = [self getCaps];
}

- (IBAction)TogglePlay:(id)sender {
    if (app != NULL) {
        gst_backend_audio_playback_toggle_play (app);
    }
}

- (IBAction)StartPlayback:(id)sender {
    if (app == NULL) {
        NSString *caps_str = [self getCaps];
        
        app = gst_backend_audio_playback_start ();
        gst_backend_audio_playback_set_format (app, caps_str.UTF8String);
        gst_backend_audio_playback_play (app);
    } else {
        gst_backend_audio_playback_stop (app);
        app = NULL;
    }
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *) pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *) pickerView numberOfRowsInComponent:(NSInteger)component {
    
    if (pickerView == self->formatPickler)
        return [self->formatValues count];
    else if (pickerView == self->sampleRatePickler)
        return [self->sampleRateValues count];
    else if (pickerView == self->widthPickler)
        return [self->widthValues count];
    
    return 0;
}

- (NSString *)pickerView:(UIPickerView *) pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
 
    NSString *res;

    if (pickerView == self->formatPickler)
        res = [self->formatValues objectAtIndex:row];
    else if (pickerView == self->sampleRatePickler)
        res = [self->sampleRateValues objectAtIndex:row];
    else if (pickerView == self->widthPickler)
        res = [self->widthValues objectAtIndex:row];
    else
        res =  @"Unkown";
  
    return res;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    
    if (pickerView == self->formatPickler)
        self->selectedFormat = row;
    else if (pickerView == self->sampleRatePickler)
        self->selectedSampleRate = row;
    else if (pickerView == self->widthPickler)
        self->selectedWidth = row;
}

- (void)dealloc {
    [widthPickler release];
    [sampleRatePickler release];
    [formatPickler release];
    [formatLabel release];
    [super dealloc];
}
@end
