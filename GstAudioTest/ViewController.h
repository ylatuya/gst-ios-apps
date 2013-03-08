//
//  ViewController.h
//  GstAudioTest
//
//  Created by FLUENDO on 06/03/13.
//  Copyright (c) 2013 FLUENDO. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UIPickerViewDataSource>
{
    NSArray            *formatValues;
    NSArray            *sampleRateValues;
    NSArray            *widthValues;
    
    int selectedFormat;
    int selectedSampleRate;
    int selectedWidth;
    
    IBOutlet UILabel *formatLabel;
    IBOutlet UIPickerView *formatPickler;
    IBOutlet UIPickerView *sampleRatePickler;
    IBOutlet UIPickerView *widthPickler;
}


@end
