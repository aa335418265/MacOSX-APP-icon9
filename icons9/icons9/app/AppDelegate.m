//
//  AppDelegate.m
//  icons9
//
//  Created by 冯立海 on 2018/3/3.
//  Copyright © 2018年 冯立海. All rights reserved.
//

#import "AppDelegate.h"
#import "BMMainViewController.h"

@interface AppDelegate ()
@property (weak) IBOutlet NSWindow *window;
@property (nonatomic, strong) BMMainViewController *mainViewController;


@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {

    self.mainViewController = [[BMMainViewController alloc] initWithNibName:@"BMMainViewController" bundle:nil];
    [self.window.contentView addSubview:self.mainViewController.view];
    self.mainViewController.view.frame = self.window.contentView.bounds;
    

    
}



- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
