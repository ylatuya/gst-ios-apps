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

#import "ViewController.h"
#import "MovieEntryCell.h"
#import "PlaybackViewController.h"

#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

@implementation ViewController

@synthesize collectionView;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [self refreshMediaItems];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)refreshMediaItems {
    NSArray *ftypes = [NSArray arrayWithObjects:@"mov", @"m4v", @"m4a", @"mp4", @"ogv",
                       @"mp3", @"avi", @"wmv", @"mkv", @"ts", nil];
    
    NSMutableArray *entries = [[NSMutableArray alloc] init];
    
    for (NSString *t in ftypes) {
        [entries addObjectsFromArray:[[NSBundle mainBundle] pathsForResourcesOfType:t inDirectory:@"."]];
    }
    self->mediaEntries = entries;
    self->onlineEntries = [NSArray arrayWithObjects:@"http://docs.gstreamer.com/media/sintel_trailer-368p.ogv",
                           @"http://download.blender.org/peach/bigbuckbunny_movies/BigBuckBunny_640x360.m4v", nil];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return [self->mediaEntries count];
        case 1:
            return [self->onlineEntries count];
        default:
            return 0;
    }
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 2;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MovieEntryCell* newCell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"cell"
                                                                           forIndexPath:indexPath];
    
    if(indexPath.section == 0) {
        newCell.label.text = [NSString stringWithFormat:@"file://%@",
                              [self->mediaEntries objectAtIndex:indexPath.item], nil];
    } else if (indexPath.section == 1) {
        newCell.label.text = [self->onlineEntries objectAtIndex:indexPath.item];
    }

    return newCell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"doPlay"]) {
        MovieEntryCell *cell = sender;
        PlaybackViewController *vc = [segue destinationViewController];
        NSString *uri = cell.label.text;
        
        [vc initialize];
        [vc setURI:uri];
    }
}

@end
