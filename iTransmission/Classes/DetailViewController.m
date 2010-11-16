    //
//  DetailViewController.m
//  iTransmission
//
//  Created by Mike Chen on 10/4/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "DetailViewController.h"
#import "Torrent.h"
#import "Controller.h"
#import "NSStringAdditions.h"
#import "StatisticsView.h"
#import "Notifications.h"
#import "FlexibleLabelCell.h"


#define HEADER_SECTION 0
#define TITLE_ROW 0

#define STATE_SECTION 1
#define STATE_ROW 0
#define ERROR_MESSAGE_ROW (STATE_ROW+1)

#define SPEED_SECTION 2
#define DL_SPEED_ROW 0
#define UL_SPEED_ROW 1

#define GENERAL_INFO_SECTION 3
#define HASH_ROW 0
#define IS_PRIVATE_ROW 1
#define CREATOR_ROW 2
#define CREATED_ON_ROW 3
#define COMMENT_ROW 4

#define TRANSFER_SECTION 4
#define TOTAL_SIZE_ROW 0
#define SIZE_COMPLETED_ROW 1
#define PROGRESS_ROW 2
#define DOWNLOADED_ROW 3
#define UPLOADED_ROW 4
#define RATIO_ROW 5

#define MORE_SECTION 5
#define FILES_ROW 0
#define TRACKERS_ROW 1
#define PEERS_ROW 2

#define LOCATION_SECTION 6
#define DATA_LOCATION_ROW 0
#define TORRENT_LOCATION_ROW 1

#define REMOVE_COMFIRM_TAG 1003

@implementation DetailViewController
@synthesize tableView = fTableView;
@synthesize torrent = fTorrent;
@synthesize controller = fController;
@synthesize statisticsView = fStatisticsView;
@synthesize startButton = fStartButton;
@synthesize pauseButton = fPauseButton;
@synthesize removeButton = fRemoveButton;
@synthesize refreshButton = fRefreshButton;
@synthesize UIUpdateTimer = fUIUpdateTimer;

- (id)initWithTorrent:(Torrent*)t controller:(Controller*)c {
    if ((self = [super initWithNibName:@"DetailViewController" bundle:nil])) {
        self.title = @"Details";
		fTorrent = t;
		fController = c;
		
		self.startButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(startButtonClicked:)] autorelease];
		self.pauseButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause target:self action:@selector(pauseButtonClicked:)] autorelease];
		self.removeButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(removeButtonClicked:)] autorelease];
		self.refreshButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(updateUI)] autorelease];

		UIBarButtonItem *flexSpaceOne = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
		UIBarButtonItem *flexSpaceTwo = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
		UIBarButtonItem *flexSpaceThree = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease];
		
		self.toolbarItems = [NSArray arrayWithObjects:self.startButton, flexSpaceOne, self.pauseButton, flexSpaceTwo, self.refreshButton, flexSpaceThree, self.removeButton, nil];
		displayedError = NO;
	}
    return self;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 7;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == MORE_SECTION) {
		return indexPath;
	}
	return nil;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
	return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == MORE_SECTION) {
		[[[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"This is not implemented currently. " delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] autorelease] show];
		[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
	}
}

- (void)viewDidLoad {
    [super viewDidLoad];
	self.statisticsView = [StatisticsView createFromNib];
	self.statisticsView.controller = self.controller;
	[self.view addSubview:self.statisticsView];
	[self.tableView setAllowsSelection:YES];
	
	[fTitleLabel setText:[fTorrent name]];
	if ([fTorrent icon])
		[fIconView setImage:[fTorrent icon]];
	else 
		[fIconView setImage:[UIImage imageNamed:@"question-mark.png"]];
	[fHashLabel setText:[fTorrent hashString]];
	[fDataLocationLabel setText:[fTorrent dataLocation]];
	[fDataLocationCell resizeToFitText];
	[fTorrentLocationLabel setText:[fTorrent torrentLocation]];
	[fTorrentLocationCell resizeToFitText];
	[fIsPrivateSwitch setOn:[fTorrent privateTorrent]];
	[fCommentLabel setText:[fTorrent comment]];
	[fCommentCell resizeToFitText];
	[fCreatorLabel setText:[fTorrent creator]];
	
	fFilesCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
	fFilesCell.textLabel.text = @"Files";
	fFilesCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	fPeersCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
	fPeersCell.textLabel.text = @"Peers";
	fPeersCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	fTrackersCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
	fTrackersCell.textLabel.text = @"Trackers";
	fTrackersCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

- (void)viewWillAppear:(BOOL)animated
{
	[self updateUI];
	self.UIUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(updateUI) userInfo:nil repeats:YES];
	[self.statisticsView startUpdate];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionStatusChanged:) name:NotificationSessionStatusChanged object:self.controller];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[self.UIUpdateTimer invalidate];
	self.UIUpdateTimer = nil;
	[self.statisticsView startUpdate];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NotificationSessionStatusChanged object:self.controller];
}

- (void)startButtonClicked:(id)sender
{
	[fTorrent startTransfer];
	[self updateUI];
}

- (void)pauseButtonClicked:(id)sender
{
	[fTorrent stopTransfer];
	[self updateUI];
}

- (void)removeButtonClicked:(id)sender
{
	NSString *msg = @"Are you sure to remove this torrent?";
	UIActionSheet *actionSheet = [[[UIActionSheet alloc] initWithTitle:msg delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Yes and remove data" otherButtonTitles:@"Yes but keep data", nil] autorelease];
	actionSheet.tag = REMOVE_COMFIRM_TAG;
	[actionSheet showFromToolbar:self.navigationController.toolbar];	
}

- (void)performRemove:(BOOL)trashData
{
	[self.UIUpdateTimer invalidate];
	self.UIUpdateTimer = nil;
	[self.navigationController popViewControllerAnimated:YES];	
	[self.controller removeTorrents:[NSArray arrayWithObject:self.torrent] trashData:trashData];
}

- (void)sessionStatusChanged:(NSNotification*)notif
{
	[self updateUI];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (actionSheet.tag) {
		case REMOVE_COMFIRM_TAG: {
			if (buttonIndex == actionSheet.cancelButtonIndex) {
			}
			else {
				[self performRemove:(buttonIndex == [actionSheet destructiveButtonIndex])];
			}
		}
    }
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section
{
	switch (section) {
		case HEADER_SECTION:
			return 1;
			break;
		case STATE_SECTION:
			return displayedError ? 2 : 1;
		case SPEED_SECTION:
			return 2;
			break;
		case GENERAL_INFO_SECTION:
			return 5;
			break;
		case TRANSFER_SECTION:
			return 6;
			break;
		case LOCATION_SECTION:
			return 2;
			break;
		case MORE_SECTION:
			return 3;
			break;
		default:
			break;
	}
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch (indexPath.section) {
		case HEADER_SECTION:
			switch (indexPath.row) {
				case TITLE_ROW:
					return fTitleCell;
					break;
				default:
					break;
			}
			break;
		case STATE_SECTION:
			switch (indexPath.row) {
				case STATE_ROW:
					return fStateCell;
					break;
				case ERROR_MESSAGE_ROW:
					return fErrorMessageCell;
					break;
				default:
					break;
			}
			break;
		case SPEED_SECTION:
			switch (indexPath.row) {
				case UL_SPEED_ROW:
					return fULSpeedCell;
					break;
				case DL_SPEED_ROW:
					return fDLSpeedCell;
					break;
				default:
					break;
			}
			break;
		case GENERAL_INFO_SECTION:
			switch (indexPath.row) {
				case HASH_ROW:
					return fHashCell;
					break;
				case CREATOR_ROW:
					return fCreatorCell;
					break;
				case CREATED_ON_ROW:
					return fCreatedOnCell;
					break;
				case COMMENT_ROW:
					return fCommentCell;
					break;
				case IS_PRIVATE_ROW:
					return fIsPrivateCell;
					break;
				default:
					break;
			}
			break;
		case TRANSFER_SECTION:
			switch (indexPath.row) {
				case TOTAL_SIZE_ROW:
					return fTotalSizeCell;
					break;
				case SIZE_COMPLETED_ROW:
					return fCompletedSizeCell;
					break;
				case PROGRESS_ROW:
					return fProgressCell;
					break;
				case UPLOADED_ROW:
					return fUploadedSizeCell;
					break;
				case DOWNLOADED_ROW:
					return fDownloadedSizeCell;
					break;
				case RATIO_ROW:
					return fRatioCell;
					break;
				default:
					break;
			}
			break;
		case LOCATION_SECTION:
			switch (indexPath.row) {
				case DATA_LOCATION_ROW:
					return fDataLocationCell;
					break;
				case TORRENT_LOCATION_ROW:
					return fTorrentLocationCell;
					break;
				default:
					break;
			}
			break;
		case MORE_SECTION:
			switch (indexPath.row) {
				case FILES_ROW:
					return fFilesCell;
					break;
				case PEERS_ROW:
					return fPeersCell;
					break;
				case TRACKERS_ROW:
					return fTrackersCell;
					break;
				default:
					break;
			}
			break;

		default:
			break;
	}
	return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
	CGFloat height = cell.bounds.size.height;
	return height;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	switch (section) {
		case TRANSFER_SECTION:
			return @"Transfer";
			break;
		case SPEED_SECTION:
			return @"Speed";
			break;
		case GENERAL_INFO_SECTION:
			return @"General Information";
			break;
		case LOCATION_SECTION:
			return @"Location";
			break;
		case MORE_SECTION:
			return @"More";
			break;
		default:
			break;
	}
	return nil;
}

- (void)updateUI
{	
	if ([self.controller isSessionActive]) {
		[self.startButton setEnabled:YES && (![self.torrent isActive])];
		[self.pauseButton setEnabled:YES && ([self.torrent isActive])];
	}
	else {
		[self.startButton setEnabled:NO];
		[self.pauseButton setEnabled:NO];
	}
	
	[fTorrent update];
	[fTotalSizeLabel setText:[NSString stringForFileSize:[fTorrent size]]];
	[fCompletedSizeLabel setText:[NSString stringForFileSize:[fTorrent haveVerified]]];
	[fProgressLabel setText:[NSString stringWithFormat:@"%.2f%%",[fTorrent progress] * 100.0f]];
	[fUploadedSizeLabel setText:[NSString stringForFileSize:[fTorrent uploadedTotal]]];
	[fDownloadedSizeLabel setText:[NSString stringForFileSize:[fTorrent downloadedTotal]]];

	BOOL hasError = [fTorrent isAnyErrorOrWarning];
	if (hasError) {
		if (!displayedError) {
			[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:ERROR_MESSAGE_ROW inSection:STATE_SECTION]] withRowAnimation:UITableViewRowAnimationTop];
			displayedError = YES;
		}
		
	}
	else {
		if (displayedError) {
			[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:ERROR_MESSAGE_ROW inSection:STATE_SECTION]] withRowAnimation:UITableViewRowAnimationTop];
			displayedError = NO;
		}
	}
	
	[fStateLabel setText:[fTorrent stateString]];
	[fRatioLabel setText:[NSString stringForRatio:[fTorrent ratio]]];
	
	[fULSpeedLabel setText:[NSString stringForSpeed:[fTorrent uploadRate]]];
	[fDLSpeedLabel setText:[NSString stringForSpeed:[fTorrent downloadRate]]];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
	self.statisticsView = nil;
}

- (void)dealloc {
	self.removeButton = nil;
	self.startButton = nil;
	self.pauseButton = nil;
	self.statisticsView = nil;
	self.refreshButton = nil;
	[self.UIUpdateTimer invalidate];
	self.UIUpdateTimer = nil;
	
	[fTitleCell release];
	[fTitleLabel release];
	[fIconView release];
	[fTotalSizeCell release];
	[fTotalSizeLabel release];
	[fCompletedSizeCell release];
	[fCompletedSizeLabel release];
	[fProgressCell release];
	[fProgressLabel release];
	[fDownloadedSizeCell release];
	[fDownloadedSizeLabel release];
	[fUploadedSizeCell release];
	[fUploadedSizeLabel release];	
	[fStateCell release];
	[fStateLabel release];
	[fErrorMessageCell release];
	[fErrorMessageLabel release];
	[fHashCell release];
	[fHashLabel release];
	[fRatioCell release];
	[fRatioLabel release];
	[fDataLocationCell release];
	[fDataLocationLabel release];
	[fTorrentLocationCell release];
	[fTorrentLocationLabel release];
	[fULSpeedCell release];
	[fULSpeedLabel release];
	[fDLSpeedCell release];
	[fDLSpeedLabel release];
	[fCreatorCell release];
	[fCreatorLabel release];
	[fCreatedOnCell release];
	[fCreatedOnLabel release];
	[fCommentCell release];
	[fCommentLabel release];
	[fIsPrivateSwitch release];
	[fIsPrivateCell release];
	[fPeersCell release];
	[fTrackersCell release];
	[fFilesCell release];
    [super dealloc];
}


@end
