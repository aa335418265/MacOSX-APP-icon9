//
//  BMProjectCell.h
//  icons9
//
//  Created by fenglh on 2018/4/28.
//  Copyright © 2018年 冯立海. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef void(^OnClickBlock)();
@interface BMProjectCell : NSView
@property (weak) IBOutlet NSTextField *nameLabel;
@property (weak) IBOutlet NSImageView *folderImageView;
@property (nonatomic, assign) NSInteger badgeValue; ///< 更新角标

@property (nonatomic, strong) OnClickBlock clickBlock; ///< 点击
@end
