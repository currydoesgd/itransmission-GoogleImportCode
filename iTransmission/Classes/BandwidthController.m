//
//  BandwidthController.m
//  iTransmission
//
//  Created by Mike Chen on 10/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "BandwidthController.h"
#import "Torrent.h"
#import "Controller.h"

@implementation BandwidthController
@synthesize panel = fPanel;
@synthesize torrent = fTorrent;
@synthesize controller = fController;
@synthesize visible = _visible;

- (id)initWithTorrent:(Torrent *)t
{
	if (self = [super init]) {
		self.torrent = t;
		[[NSBundle mainBundle] loadNibNamed:@"BandwidthController" owner:self options:nil];
	}
	return self;
}

- (void)showFromToolbar:(UIToolbar*)toolbar
{
	self.panel.frame = CGRectMake(0.0f, 0.0f, self.panel.bounds.size.width, self.panel.bounds.size.height);
	[toolbar addSubview:self.panel];
	[UIView beginAnimations:@"Show Bandwidth Controller" context:nil];
	self.panel.frame = CGRectMake(0.0f, -self.panel.bounds.size.height, self.panel.bounds.size.width, self.panel.bounds.size.height);
	[UIView setAnimationDuration:1.0f];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView commitAnimations];
	fToolbar = toolbar;
	
	_visible = YES;
}

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
	[self.panel removeFromSuperview];
	_visible = NO;
	fToolbar = nil;
}

- (void)hide
{
	if (_visible != NO && self.panel.superview) {
		[UIView beginAnimations:@"Hide Bandwidth Controller" context:nil];
		self.panel.frame = CGRectMake(0.0f, fToolbar.bounds.size.height, self.panel.bounds.size.width, self.panel.bounds.size.height);
		[UIView setAnimationDuration:1.0f];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
		[UIView setAnimationBeginsFromCurrentState:YES];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
		[UIView commitAnimations];
	}
}

- (void)dealloc
{
	self.panel = nil;
	self.torrent = nil;
	self.controller = nil;
	[super dealloc];
}

@end
