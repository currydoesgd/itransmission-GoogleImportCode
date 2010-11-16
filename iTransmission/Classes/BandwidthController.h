//
//  BandwidthController.h
//  iTransmission
//
//  Created by Mike Chen on 10/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Torrent;
@class Controller;
@interface BandwidthController : NSObject {
	UIView *fPanel;
	Torrent *fTorrent;
	Controller *fController;
	UIToolbar *fToolbar;
	
	BOOL _visible;
}
@property (nonatomic, retain) IBOutlet UIView *panel;
@property (nonatomic, assign) Torrent *torrent;
@property (nonatomic, assign) Controller *controller;
@property (nonatomic, readonly, getter=isVisible) BOOL visible;

- (id)initWithTorrent:(Torrent*)t;

- (void)showFromToolbar:(UIToolbar*)toolbar;
- (void)hide;

@end
