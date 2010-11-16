//
//  DetailViewController.h
//  iTransmission
//
//  Created by Mike Chen on 10/4/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Torrent;
@class Controller;
@class StatisticsView;
@class FlexibleLabelCell;

@interface DetailViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate> {
	StatisticsView *fStatisticsView;
	UITableView *fTableView;
	UIBarButtonItem *fStartButton;
	UIBarButtonItem *fPauseButton;
	UIBarButtonItem *fRemoveButton;
	UIBarButtonItem *fRefreshButton;
	Torrent *fTorrent;
	Controller *fController;
	
	IBOutlet UITableViewCell *fTitleCell;
	IBOutlet UILabel *fTitleLabel;
	IBOutlet UIImageView *fIconView;
	
	IBOutlet UITableViewCell *fTotalSizeCell;
	IBOutlet UILabel *fTotalSizeLabel;
	
	IBOutlet UITableViewCell *fCompletedSizeCell;
	IBOutlet UILabel *fCompletedSizeLabel;
	
	IBOutlet UITableViewCell *fProgressCell;
	IBOutlet UILabel *fProgressLabel;
	
	IBOutlet UITableViewCell *fDownloadedSizeCell;
	IBOutlet UILabel *fDownloadedSizeLabel;
	
	IBOutlet UITableViewCell *fUploadedSizeCell;
	IBOutlet UILabel *fUploadedSizeLabel;
	
	IBOutlet UITableViewCell *fStateCell;
	IBOutlet UILabel *fStateLabel;
	
	IBOutlet UITableViewCell *fErrorMessageCell;
	IBOutlet UILabel *fErrorMessageLabel;
	
	IBOutlet UITableViewCell *fHashCell;
	IBOutlet UILabel *fHashLabel;
	
	IBOutlet UITableViewCell *fRatioCell;
	IBOutlet UILabel *fRatioLabel;
	
	IBOutlet FlexibleLabelCell *fDataLocationCell;
	IBOutlet UILabel *fDataLocationLabel;
	
	IBOutlet FlexibleLabelCell *fTorrentLocationCell;
	IBOutlet UILabel *fTorrentLocationLabel;
	
	IBOutlet UITableViewCell *fULSpeedCell;
	IBOutlet UILabel *fULSpeedLabel;
	
	IBOutlet UITableViewCell *fDLSpeedCell;
	IBOutlet UILabel *fDLSpeedLabel;
	
	IBOutlet UITableViewCell *fCreatorCell;
	IBOutlet UILabel *fCreatorLabel;
	
	IBOutlet UITableViewCell *fCreatedOnCell;
	IBOutlet UILabel *fCreatedOnLabel;
	
	IBOutlet FlexibleLabelCell *fCommentCell;
	IBOutlet UILabel *fCommentLabel;
	
	IBOutlet UITableViewCell *fIsPrivateCell;
	IBOutlet UISwitch *fIsPrivateSwitch;
	
	UITableViewCell *fPeersCell;
	UITableViewCell *fTrackersCell;
	UITableViewCell *fFilesCell;
	
	NSTimer *fUIUpdateTimer;
	BOOL displayedError;
}
@property (nonatomic, retain) NSTimer *UIUpdateTimer;
@property (nonatomic, retain) StatisticsView *statisticsView;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, assign) Torrent *torrent;
@property (nonatomic, assign) Controller *controller;
@property (nonatomic, retain) UIBarButtonItem *startButton;
@property (nonatomic, retain) UIBarButtonItem *pauseButton;
@property (nonatomic, retain) UIBarButtonItem *removeButton;
@property (nonatomic, retain) UIBarButtonItem *refreshButton;

- (id)initWithTorrent:(Torrent*)t controller:(Controller*)c;
- (void)updateUI;

- (void)startButtonClicked:(id)sender;
- (void)pauseButtonClicked:(id)sender;
- (void)removeButtonClicked:(id)sender;
- (void)sessionStatusChanged:(NSNotification*)notif;

- (void)performRemove:(BOOL)trashData;

@end
