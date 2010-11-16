//
//  Controller.m
//  iTransmission
//
//  Created by Mike Chen on 10/3/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Controller.h"
#import "Torrent.h"
#import "Notifications.h"
#import "TorrentViewController.h"
#import "TorrentFetcher.h"
#import "Reachability.h"
#include <stdlib.h> // setenv()

#define APP_NAME "iTrans"

BOOL isStartingTransferAllowed(){
	Controller *c = (Controller*)[[UIApplication sharedApplication] delegate];
	return [c isStartingTransferAllowed];
}

static tr_rpc_callback_status rpcCallback(tr_session * handle UNUSED, tr_rpc_callback_type type, struct tr_torrent * torrentStruct, void * controller)
{
    [(Controller *)controller rpcCallback: type forTorrentStruct: torrentStruct];
    return TR_RPC_NOREMOVE; //we'll do the remove manually
}

@implementation Controller

@synthesize window;
@synthesize navController;
@synthesize torrentViewController;
@synthesize activityCounter;
@synthesize reachability;
@synthesize globalMessage;

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions { 
    [self fixDocumentsDirectory];
	[self transmissionInitialize];
    
    self.torrentViewController = [[[TorrentViewController alloc] initWithNibName:@"TorrentViewController" bundle:nil] autorelease];
    self.torrentViewController.controller = self;
    self.navController = [[[UINavigationController alloc] initWithRootViewController:self.torrentViewController] autorelease];
    self.navController.toolbarHidden = NO;
    
    [self.window addSubview:self.navController.view];
	
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)resetToDefaultPreferences
{
    [NSUserDefaults resetStandardUserDefaults];
    fDefaults = [NSUserDefaults standardUserDefaults];
    [fDefaults setBool:YES forKey:@"SpeedLimitAuto"];
    [fDefaults setBool:NO forKey:@"AutoStartDownload"];
    [fDefaults setBool:YES forKey:@"DHTGlobal"];
    [fDefaults setInteger:0 forKey:@"DownloadLimit"];
    [fDefaults setInteger:0 forKey:@"UploadLimit"];
    [fDefaults setBool:NO forKey:@"DownloadLimitEnabled"];
    [fDefaults setBool:NO forKey:@"UploadLimitEnabled"];
    [fDefaults setObject:[self defaultDownloadDir] forKey:@"DownloadFolder"];
    [fDefaults setObject:[self defaultDownloadDir] forKey:@"IncompleteDownloadFolder"];
    [fDefaults setBool:NO forKey:@"UseIncompleteDownloadFolder"];
    [fDefaults setBool:YES forKey:@"LocalPeerDiscoveryGlobal"];
    [fDefaults setInteger:30 forKey:@"PeersTotal"];
    [fDefaults setInteger:20 forKey:@"PeersTorrent"];
    [fDefaults setBool:NO forKey:@"RandomPort"];
    [fDefaults setInteger:30901 forKey:@"BindPort"];
    [fDefaults setInteger:0 forKey:@"PeerSocketTOS"];
    [fDefaults setBool:YES forKey:@"PEXGlobal"];
    [fDefaults setBool:YES forKey:@"NatTraversal"];
    [fDefaults setBool:NO forKey:@"Proxy"];
    [fDefaults setInteger:0 forKey:@"ProxyPort"];
    [fDefaults setFloat:0.0f forKey:@"RatioLimit"];
    [fDefaults setBool:NO forKey:@"RatioCheck"];
    [fDefaults setBool:YES forKey:@"RenamePartialFiles"];
    [fDefaults setBool:NO forKey:@"RPCAuthorize"];
    [fDefaults setBool:NO forKey:@"RPC"];
	[fDefaults setObject:@"" forKey:@"RPCUsername"];
    [fDefaults setObject:@"" forKey:@"RPCPassword"];
	[fDefaults setInteger:9091 forKey:@"RPCPort"];
    [fDefaults setBool:NO forKey:@"RPCUseWhitelist"];
	[fDefaults setBool:YES forKey:@"UseWiFi"];
	[fDefaults setBool:NO forKey:@"UseCellularNetwork"];
	[fDefaults synchronize];
}

- (void)transmissionInitialize
{
	fDefaults = [NSUserDefaults standardUserDefaults];

    if (![fDefaults boolForKey:@"NotFirstRun"]) {
        [self resetToDefaultPreferences];
        [fDefaults setBool:YES forKey:@"NotFirstRun"];
        [self performSelector:@selector(firstRunMessage) withObject:nil afterDelay:0.5f];
    }
    
	tr_bencInitDict(&settings, 37);
	const char * configDir = [[self configDir] cStringUsingEncoding:NSUTF8StringEncoding];
	tr_sessionGetDefaultSettings(configDir, &settings);
    tr_bencDictAddBool(&settings, TR_PREFS_KEY_ALT_SPEED_ENABLED, [fDefaults boolForKey: @"SpeedLimit"]);
    
	tr_bencDictAddBool(&settings, TR_PREFS_KEY_ALT_SPEED_TIME_ENABLED, NO);
	
	tr_bencDictAddBool(&settings, TR_PREFS_KEY_START, [fDefaults boolForKey: @"AutoStartDownload"]);
	
	tr_bencDictAddInt(&settings, TR_PREFS_KEY_DSPEED, [fDefaults integerForKey: @"DownloadLimit"]);
	tr_bencDictAddBool(&settings, TR_PREFS_KEY_DSPEED_ENABLED, [fDefaults boolForKey: @"DownloadLimitEnabled"]);
	tr_bencDictAddInt(&settings, TR_PREFS_KEY_USPEED, [fDefaults integerForKey: @"UploadLimit"]);
	tr_bencDictAddBool(&settings, TR_PREFS_KEY_USPEED_ENABLED, [fDefaults boolForKey: @"UploadLimitEnabled"]);
	
//	if ([fDefaults objectForKey: @"BindAddressIPv4"])
//		tr_bencDictAddStr(&settings, TR_PREFS_KEY_BIND_ADDRESS_IPV4, [[fDefaults stringForKey: @"BindAddressIPv4"] UTF8String]);
//	if ([fDefaults objectForKey: @"BindAddressIPv6"])
//		tr_bencDictAddStr(&settings, TR_PREFS_KEY_BIND_ADDRESS_IPV6, [[fDefaults stringForKey: @"BindAddressIPv6"] UTF8String]);

	tr_bencDictAddBool(&settings, TR_PREFS_KEY_BLOCKLIST_ENABLED, [fDefaults boolForKey: @"Blocklist"]);
	tr_bencDictAddBool(&settings, TR_PREFS_KEY_DHT_ENABLED, [fDefaults boolForKey: @"DHTGlobal"]);
	tr_bencDictAddStr(&settings, TR_PREFS_KEY_DOWNLOAD_DIR, [[self defaultDownloadDir] cStringUsingEncoding:NSASCIIStringEncoding]);
	tr_bencDictAddStr(&settings, TR_PREFS_KEY_DOWNLOAD_DIR, [[[fDefaults stringForKey: @"DownloadFolder"]
															  stringByExpandingTildeInPath] UTF8String]);
	tr_bencDictAddStr(&settings, TR_PREFS_KEY_INCOMPLETE_DIR, [[[fDefaults stringForKey: @"IncompleteDownloadFolder"]
																stringByExpandingTildeInPath] UTF8String]);
	tr_bencDictAddBool(&settings, TR_PREFS_KEY_INCOMPLETE_DIR_ENABLED, [fDefaults boolForKey: @"UseIncompleteDownloadFolder"]);
	tr_bencDictAddBool(&settings, TR_PREFS_KEY_LPD_ENABLED, [fDefaults boolForKey: @"LocalPeerDiscoveryGlobal"]);
	tr_bencDictAddInt(&settings, TR_PREFS_KEY_MSGLEVEL, TR_MSG_DBG);
	tr_bencDictAddInt(&settings, TR_PREFS_KEY_PEER_LIMIT_GLOBAL, [fDefaults integerForKey: @"PeersTotal"]);
	tr_bencDictAddInt(&settings, TR_PREFS_KEY_PEER_LIMIT_TORRENT, [fDefaults integerForKey: @"PeersTorrent"]);
	
	const BOOL randomPort = [fDefaults boolForKey: @"RandomPort"];
	tr_bencDictAddBool(&settings, TR_PREFS_KEY_PEER_PORT_RANDOM_ON_START, randomPort);
	if (!randomPort)
		tr_bencDictAddInt(&settings, TR_PREFS_KEY_PEER_PORT, [fDefaults integerForKey: @"BindPort"]);
	
	//hidden pref
	if ([fDefaults objectForKey: @"PeerSocketTOS"])
		tr_bencDictAddInt(&settings, TR_PREFS_KEY_PEER_SOCKET_TOS, [fDefaults integerForKey: @"PeerSocketTOS"]);
	
	tr_bencDictAddBool(&settings, TR_PREFS_KEY_PEX_ENABLED, [fDefaults boolForKey: @"PEXGlobal"]);
	tr_bencDictAddBool(&settings, TR_PREFS_KEY_PORT_FORWARDING, [fDefaults boolForKey: @"NatTraversal"]);
	tr_bencDictAddBool(&settings, TR_PREFS_KEY_PROXY_AUTH_ENABLED, [fDefaults boolForKey: @"ProxyAuthorize"]);
	tr_bencDictAddBool(&settings, TR_PREFS_KEY_PROXY_ENABLED, [fDefaults boolForKey: @"Proxy"]);
	tr_bencDictAddInt(&settings, TR_PREFS_KEY_PROXY_PORT, [fDefaults integerForKey: @"ProxyPort"]);
	tr_bencDictAddStr(&settings, TR_PREFS_KEY_PROXY, [[fDefaults stringForKey: @"ProxyAddress"] UTF8String]);
	tr_bencDictAddStr(&settings, TR_PREFS_KEY_PROXY_USERNAME,  [[fDefaults stringForKey: @"ProxyUsername"] UTF8String]);
	tr_bencDictAddReal(&settings, TR_PREFS_KEY_RATIO, [fDefaults floatForKey: @"RatioLimit"]);
	tr_bencDictAddBool(&settings, TR_PREFS_KEY_RATIO_ENABLED, [fDefaults boolForKey: @"RatioCheck"]);
	tr_bencDictAddBool(&settings, TR_PREFS_KEY_RENAME_PARTIAL_FILES, [fDefaults boolForKey: @"RenamePartialFiles"]);
	tr_bencDictAddBool(&settings, TR_PREFS_KEY_RPC_AUTH_REQUIRED,  [fDefaults boolForKey: @"RPCAuthorize"]);
	tr_bencDictAddBool(&settings, TR_PREFS_KEY_RPC_ENABLED,  [fDefaults boolForKey: @"RPC"]);
	tr_bencDictAddInt(&settings, TR_PREFS_KEY_RPC_PORT, [fDefaults integerForKey: @"RPCPort"]);
	tr_bencDictAddStr(&settings, TR_PREFS_KEY_RPC_USERNAME,  [[fDefaults stringForKey: @"RPCUsername"] UTF8String]);
	tr_bencDictAddBool(&settings, TR_PREFS_KEY_RPC_WHITELIST_ENABLED,  [fDefaults boolForKey: @"RPCUseWhitelist"]);
	
	fLib = tr_sessionInit("macosx", configDir, YES, &settings);
	tr_bencFree(&settings);
    
    NSString *webDir = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"web"];
    if (setenv("TRANSMISSION_WEB_HOME", [webDir cStringUsingEncoding:NSUTF8StringEncoding], 1)) {
        NSLog(@"Failed to set \"TRANSMISSION_WEB_HOME\" environmental variable. ");
    }
	
	fTorrents = [[NSMutableArray alloc] init];	
    fActivities = [[NSMutableArray alloc] init];
	tr_sessionSetRPCCallback(fLib, rpcCallback, self);
	
	fUpdateInProgress = NO;
	
	fPauseOnLaunch = YES;
    tr_sessionSaveSettings(fLib, [[self configDir] cStringUsingEncoding:NSUTF8StringEncoding], &settings);

    [self loadTorrentHistory];
	
	self.reachability = [Reachability reachabilityForInternetConnection];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkInterfaceChanged:) name:kReachabilityChangedNotification object:self.reachability];
	[self.reachability startNotifier];
	self.globalMessage = @"";
}

- (tr_session*)rawSession
{
    return fLib;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}


- (void)applicationWillTerminate:(UIApplication *)application {
	[self updateTorrentHistory];
    tr_sessionClose(fLib);
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}


- (void)dealloc {
    [fTorrents release];
    fTorrents = nil;
    [fActivities release];
    fActivities = nil;
	self.window = nil;
	self.reachability = nil;
	self.globalMessage = nil;
	[super dealloc];
}

- (NSString*)defaultDownloadDir
{
	return [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"Downloads"];
}

- (NSString*)transferPlist
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	return [documentsDirectory stringByAppendingPathComponent:@"Transfer.plist"];
}

- (NSString*)torrentsPath
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	return [documentsDirectory stringByAppendingPathComponent:@"torrents"];
}

- (NSString*)configDir
{
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:@"config"];
}

- (void)networkInterfaceChanged:(NSNotification*)notif
{
	NetworkStatus status = [self.reachability currentReachabilityStatus];
	[self setActiveForNetworkStatus:status];
}

- (void)updateNetworkStatus
{
	[self setActiveForNetworkStatus:[self.reachability currentReachabilityStatus]];
}

- (BOOL)isSessionActive
{
	return [self isStartingTransferAllowed];
}

- (BOOL)isStartingTransferAllowed
{
	NetworkStatus status = [self.reachability currentReachabilityStatus];
	if (status == ReachableViaWiFi && [fDefaults boolForKey:@"UseWiFi"] == NO) return NO;
	if (status == ReachableViaWWAN && [fDefaults boolForKey:@"UseCellularNetwork"] == NO) return NO;
	if (status == NotReachable) return NO;
	return YES;
}

- (void)setActiveForNetworkStatus:(NetworkStatus)status
{
	if (status == ReachableViaWiFi) {
		if ([fDefaults boolForKey:@"UseWiFi"] == NO) {
			self.globalMessage = @"Paused for WiFi.";
			for (Torrent *t in fTorrents) {
				[t stopTransfer];
			}
		}
	}
	else if (status == NotReachable) {
		self.globalMessage = @"Network down!";
	}
	else if (status == ReachableViaWWAN) {
		if ([fDefaults boolForKey:@"UseCellularNetwork"] == NO) {
			self.globalMessage = @"Paused for cellular network.";
			for (Torrent *t in fTorrents) {
				[t stopTransfer];
			}
		}
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:NotificationSessionStatusChanged object:self userInfo:nil];
}

- (NSString*)globalMessage
{
	NSString *msg;
	if (globalMessage) {
		msg = [[globalMessage retain] autorelease];
		self.globalMessage = nil;
	}
	else msg = [NSString string];
	return msg;
}

- (CGFloat)globalDownloadSpeed
{
	return tr_sessionGetPieceSpeed(fLib, TR_DOWN);
}

- (CGFloat)globalUploadSpeed
{
	return tr_sessionGetPieceSpeed(fLib, TR_UP);
}

- (void)fixDocumentsDirectory
{
    BOOL isDir, exists;
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    
    NSArray *directories = [NSArray arrayWithObjects:[self configDir], [self torrentsPath], [self defaultDownloadDir], [[self configDir] stringByAppendingPathComponent:@"torrents"], nil];
    
    for (NSString *d in directories) {
        exists = [fileManager fileExistsAtPath:d isDirectory:&isDir];
        if (exists && !isDir) {
            [fileManager removeItemAtPath:d error:nil];
            [fileManager createDirectoryAtPath:d withIntermediateDirectories:YES attributes:nil error:nil];
            continue;
        }
        if (!exists) {
            [fileManager createDirectoryAtPath:d withIntermediateDirectories:YES attributes:nil error:nil];
            continue;
        }
    }
    [fileManager release];
}

- (NSString*)randomTorrentPath
{
    return [[self torrentsPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%f.torrent", [[NSDate date] timeIntervalSince1970]]];
}

- (void)updateTorrentHistory
{    
    tr_sessionSaveSettings(fLib, [[self configDir] cStringUsingEncoding:NSUTF8StringEncoding], &settings);
    NSMutableArray * history = [NSMutableArray arrayWithCapacity: [fTorrents count]];
    
    for (Torrent * torrent in fTorrents)
        [history addObject: [torrent history]];
    
    [history writeToFile: [self transferPlist] atomically: YES];

}

- (void)loadTorrentHistory
{
    NSArray * history = [NSArray arrayWithContentsOfFile: [self transferPlist]];
    
    if (!history)
    {
        //old version saved transfer info in prefs file
        if ((history = [fDefaults arrayForKey: @"History"]))
            [fDefaults removeObjectForKey: @"History"];
    }
    
    if (history)
    {
        for (NSDictionary * historyItem in history)
        {
            Torrent * torrent;
            if ((torrent = [[Torrent alloc] initWithHistory: historyItem lib: fLib forcePause: fPauseOnLaunch]))
            {
                [fTorrents addObject: torrent];
                [torrent release];
            }
        }
    }
}

- (NSUInteger)torrentsCount
{
    return [fTorrents count];
}

- (Torrent*)torrentAtIndex:(NSInteger)index
{
    return [fTorrents objectAtIndex:index];
}

- (void)torrentFetcher:(TorrentFetcher *)fetcher fetchedTorrentContent:(NSData *)data fromURL:(NSString *)url
{
    NSError *error = nil;
    [self decreaseActivityCounter];
    NSString *path = [self randomTorrentPath];
    [data writeToFile:path options:0 error:&error];
    error = [self openFile:path addType:ADD_URL forcePath:nil];
    if (error) {
        [[[[UIAlertView alloc] initWithTitle:@"Add from URL" message:[NSString stringWithFormat:@"Adding from %@ failed. %@", url, [error localizedDescription]]  delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] autorelease] show];
    }
    [fActivities removeObject:fetcher];
}

- (void)torrentFetcher:(TorrentFetcher *)fetcher failedToFetchFromURL:(NSString *)url withError:(NSError *)error
{
    UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"Add torrent" message:[NSString stringWithFormat:@"Failed to fetch torrent URL: \"%@\". \nError: %@", url, [error localizedDescription]] delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] autorelease];
    [alertView show];
    [fActivities removeObject:fetcher];    
    [self decreaseActivityCounter];
}

- (void)removeTorrents:(NSArray*)torrents trashData:(BOOL)trashData
{
	for (Torrent *torrent in torrents) {
		[torrent stopTransfer];
		if (trashData)
			[torrent trashData];
		[torrent closeRemoveTorrent];
		[fTorrents removeObject:torrent];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:NotificationTorrentsRemoved object:self userInfo:nil];
}

- (void)addTorrentFromURL:(NSString*)url
{
    TorrentFetcher *fetcher = [[[TorrentFetcher alloc] initWithURLString:url delegate:self] autorelease];
    [fActivities addObject:fetcher];
    [self increaseActivityCounter];
}

- (void)firstRunMessage
{
     UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"Welcome!" message:[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"first_run_message" ofType:@""] encoding:NSASCIIStringEncoding error:nil] delegate:nil cancelButtonTitle:@"I got it!" otherButtonTitles:nil] autorelease];
    [alertView show];
}

- (NSError*)addTorrentFromManget:(NSString *)magnet
{
    NSError *err = nil;
    
    tr_torrent * duplicateTorrent;
    if ((duplicateTorrent = tr_torrentFindFromMagnetLink(fLib, [magnet UTF8String])))
    {
        const tr_info * info = tr_torrentInfo(duplicateTorrent);
        NSString * name = (info != NULL && info->name != NULL) ? [NSString stringWithUTF8String: info->name] : nil;
        err = [[[NSError alloc] initWithDomain:@"Controller" code:1 userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Torrent %@ already exists. ", name] forKey:NSLocalizedDescriptionKey]] autorelease];
        return err;
    }
    
    //determine download location
    NSString * location = nil;
    if ([fDefaults boolForKey: @"DownloadLocationConstant"])
        location = [[fDefaults stringForKey: @"DownloadFolder"] stringByExpandingTildeInPath];
    
    Torrent * torrent;
    if (!(torrent = [[Torrent alloc] initWithMagnetAddress: magnet location: location lib: fLib]))
    {
        err = [[[NSError alloc] initWithDomain:@"Controller" code:1 userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"The magnet supplied is invalid. ", magnet] forKey:NSLocalizedDescriptionKey]] autorelease];
        return err;
    }
    
    [torrent setWaitToStart: [fDefaults boolForKey: @"AutoStartDownload"]];
    [torrent update];
    [fTorrents addObject: torrent];
    [torrent release]; 
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNewTorrentAdded object:self userInfo:nil];
    [self updateTorrentHistory];
    return nil;
}

- (NSError*)openFile:(NSString*)file addType:(AddType)type forcePath:(NSString *)path
{
    NSError *error = nil;
    tr_ctor * ctor = tr_ctorNew(fLib);
    tr_ctorSetMetainfoFromFile(ctor, [file UTF8String]);
        
    tr_info info;
    const tr_parse_result result = tr_torrentParse(ctor, &info);
    tr_ctorFree(ctor);
    
    // TODO: instead of alert view, print errors in activities view. 
    if (result != TR_PARSE_OK)
    {
        if (result == TR_PARSE_DUPLICATE) {
            error = [[[NSError alloc] initWithDomain:@"Controller" code:1 userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Torrent %s already exists. ", info.name] forKey:NSLocalizedDescriptionKey]] autorelease];
        }
        else if (result == TR_PARSE_ERR)
        {
            error = [[[NSError alloc] initWithDomain:@"Controller" code:1 userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Invalid torrent file. "] forKey:NSLocalizedDescriptionKey]] autorelease];
        }
        tr_metainfoFree(&info);
        return error;
    }
            
    
    Torrent * torrent;
    if (!(torrent = [[Torrent alloc] initWithPath:file location: [path stringByExpandingTildeInPath] deleteTorrentFile: NO lib: fLib])) {
        error = [[[NSError alloc] initWithDomain:@"Controller" code:1 userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Unknown error. "] forKey:NSLocalizedDescriptionKey]] autorelease];
        return error;
    }
    
    //verify the data right away if it was newly created
    if (type == ADD_CREATED)
        [torrent resetCache];
    
    [torrent setWaitToStart: [fDefaults boolForKey: @"AutoStartDownload"]];
    [torrent update];
    [fTorrents addObject: torrent];
    [torrent release];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NotificationNewTorrentAdded object:self userInfo:nil];
    [self updateTorrentHistory];
    return nil;
}

- (void)increaseActivityCounter
{
    activityCounter += 1;
    [[NSNotificationCenter defaultCenter] postNotificationName:NotificationActivityCounterChanged object:self userInfo:nil];
}

- (void)decreaseActivityCounter
{
    if (activityCounter == 0) return;
    activityCounter -= 1;
    [[NSNotificationCenter defaultCenter] postNotificationName:NotificationActivityCounterChanged object:self userInfo:nil];
}

- (void) rpcCallback: (tr_rpc_callback_type) type forTorrentStruct: (struct tr_torrent *) torrentStruct
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    //get the torrent
    Torrent * torrent = nil;
    if (torrentStruct != NULL && (type != TR_RPC_TORRENT_ADDED && type != TR_RPC_SESSION_CHANGED))
    {
        for (torrent in fTorrents)
            if (torrentStruct == [torrent torrentStruct])
            {
                [torrent retain];
                break;
            }
        
        if (!torrent)
        {
            [pool drain];
            
            NSLog(@"No torrent found matching the given torrent struct from the RPC callback!");
            return;
        }
    }
    
    switch (type)
    {
        case TR_RPC_TORRENT_ADDED:
            [self performSelectorOnMainThread: @selector(rpcAddTorrentStruct:) withObject:
			 [[NSValue valueWithPointer: torrentStruct] retain] waitUntilDone: NO];
            break;
			
        case TR_RPC_TORRENT_STARTED:
        case TR_RPC_TORRENT_STOPPED:
            [self performSelectorOnMainThread: @selector(rpcStartedStoppedTorrent:) withObject: torrent waitUntilDone: NO];
            break;
			
        case TR_RPC_TORRENT_REMOVING:
            [self performSelectorOnMainThread: @selector(rpcRemoveTorrent:) withObject: torrent waitUntilDone: NO];
            break;
			
        case TR_RPC_TORRENT_CHANGED:
            [self performSelectorOnMainThread: @selector(rpcChangedTorrent:) withObject: torrent waitUntilDone: NO];
            break;
			
        case TR_RPC_TORRENT_MOVED:
            [self performSelectorOnMainThread: @selector(rpcMovedTorrent:) withObject: torrent waitUntilDone: NO];
            break;
			
        case TR_RPC_SESSION_CHANGED:
//TODO: Post notification to update preferences. 
            break;
			
        default:
            NSAssert1(NO, @"Unknown RPC command received: %d", type);
            [torrent release];
    }
    
    [pool drain];
}

- (void) rpcAddTorrentStruct: (NSValue *) torrentStructPtr
{
    tr_torrent * torrentStruct = (tr_torrent *)[torrentStructPtr pointerValue];
    [torrentStructPtr release];
    
    NSString * location = nil;
    if (tr_torrentGetDownloadDir(torrentStruct) != NULL)
        location = [NSString stringWithUTF8String: tr_torrentGetDownloadDir(torrentStruct)];
    
    Torrent * torrent = [[Torrent alloc] initWithTorrentStruct: torrentStruct location: location lib: fLib];
    
    [torrent update];
    [fTorrents addObject: torrent];
    [torrent release];
}

- (void) rpcRemoveTorrent: (Torrent *) torrent
{
    [self removeTorrents:[NSArray arrayWithObject: torrent] trashData:NO];
    [torrent release];
}

- (void) rpcStartedStoppedTorrent: (Torrent *) torrent
{
    [torrent update];
    [torrent release];
    
	//TODO: Post notification to update this torrent's info in UI. 
	
    [self updateTorrentHistory];
}

- (void) rpcChangedTorrent: (Torrent *) torrent
{
    [torrent update];
    
	//TODO: Post notification to update this torrent's info in UI. 
	
    [torrent release];
}

- (void) rpcMovedTorrent: (Torrent *) torrent
{
    [torrent update];
        
    [torrent release];
}


@end
