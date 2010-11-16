//
//  PrefViewController.h
//  iTransmission
//
//  Created by Mike Chen on 10/3/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GradientButton;
@class PortChecker;
@interface PrefViewController :UIViewController<UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate> {
    UITableView *fTableView;
    
    IBOutlet UITableViewCell *fEnableRPCCell;
    IBOutlet UITableViewCell *fRPCUsernameCell;
    IBOutlet UITableViewCell *fRPCPasswordCell;
    IBOutlet UITableViewCell *fRPCPortCell;
    IBOutlet UITableViewCell *fUseCellularNetworkCell;
    IBOutlet UITableViewCell *fUseWiFiCell;
    IBOutlet UITableViewCell *fAutoPortMapCell;
    IBOutlet UITableViewCell *fRPCRequireAuthCell;
    IBOutlet UITableViewCell *fBindPortCell;
    IBOutlet GradientButton *fCheckPortButton;
	
	IBOutlet UISwitch *fEnableRPCSwitch;
	IBOutlet UISwitch *fRPCRequireAuthSwitch;
	IBOutlet UISwitch *fUseWiFiSwitch;
	IBOutlet UISwitch *fUseCellularNetworkSwitch;
	IBOutlet UISwitch *fAutoPortMapSwitch;
	IBOutlet UITextField *fBindPortTextField;
	IBOutlet UITextField *fRPCUsernameTextField;
	IBOutlet UITextField *fRPCPasswordTextField;
	IBOutlet UITextField *fRPCPortTextField;
	IBOutlet UIActivityIndicatorView *fPortCheckActivityIndicator;
    
    UIColor *fTextFieldTextColor;
    
    BOOL keyboardIsShowing;
    CGRect keyboardBounds;
	
	NSDictionary *fOriginalPreferences;
	PortChecker *fPortChecker;

}
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) PortChecker *portChecker;
@property (nonatomic, retain) NSDictionary *originalPreferences;

- (void)closeButtonClicked;
- (void)saveButtonClicked;
- (void)portCheckButtonClicked;

- (void)keyboardWillHide:(NSNotification*)notif;
- (void)keyboardWillShow:(NSNotification*)notif;

- (void)loadPreferences;

- (IBAction)enableRPCSwitchChanged:(id)sender;
- (IBAction)RPCRequireAuthSwitchChanged:(id)sender;
- (IBAction)UseWiFiSwitchChanged:(id)sender;
- (IBAction)switchChanged:(id)sender;
- (IBAction)checkPortButtonClicked:(id)sender;

@end
