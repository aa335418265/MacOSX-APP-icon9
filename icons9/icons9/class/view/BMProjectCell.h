//
//  BMProjectCell.h
//  icons9
//
//  Created by fenglh on 2018/4/28.
//  Copyright © 2018年 冯立海. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BMProjectCell : NSView
@property (weak) IBOutlet NSTextField *nameLabel;
@property (weak) IBOutlet NSImageView *folderImageView;
@property (weak) IBOutlet NSButton *updateBtn;
@property (weak) IBOutlet NSTextField *badgeLabel;

@end
