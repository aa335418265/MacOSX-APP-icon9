//
//  AppDelegate.m
//  icons9
//
//  Created by 冯立海 on 2018/3/3.
//  Copyright © 2018年 冯立海. All rights reserved.
//

#import "AppDelegate.h"
#import "BMMainViewController.h"
#import "NSMainWinController.h"

@interface AppDelegate ()
{
        NSMainWinController *mainWindow;
}


@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

    if (!mainWindow) {
        mainWindow = [[NSMainWinController alloc] initWithWindowNibName:@"NSMainWinController"];
    }
    [mainWindow showWindow:self];
 
}



- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}



@end
