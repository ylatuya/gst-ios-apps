//
//  main.m
//  GstAudioTest
//
//  Created by FLUENDO on 06/03/13.
//  Copyright (c) 2013 FLUENDO. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AppDelegate.h"
#include "gst_backend.h"


int main(int argc, char *argv[])
{
    @autoreleasepool {
        gst_backend_initialize ();
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
