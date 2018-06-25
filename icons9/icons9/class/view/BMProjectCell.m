//
//  BMProjectCell.m
//  icons9
//
//  Created by fenglh on 2018/4/28.
//  Copyright © 2018年 冯立海. All rights reserved.
//

#import "BMProjectCell.h"
@interface BMProjectCell()
@property (weak) IBOutlet NSTextField *badgeLabel;
@property (weak) IBOutlet NSButton *updateBtn;
@end;
@implementation BMProjectCell

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
}



- (void)awakeFromNib {
    self.badgeLabel.wantsLayer = YES;
    self.badgeLabel.layer.cornerRadius  = 2.f;
    self.badgeLabel.layer.masksToBounds = YES;

}

- (IBAction)updateBtnOnClick:(id)sender {
    if (self.clickBlock) {
        self.clickBlock();
    }
}


- (void)setBadgeValue:(NSInteger)badgeValue {

    if (badgeValue > 0) {
        self.badgeLabel.hidden = NO;
        self.updateBtn.hidden = NO;
    }else{
        self.badgeLabel.hidden = YES;
        self.updateBtn.hidden = YES;
    }
    self.badgeLabel.integerValue = badgeValue;
}
@end
