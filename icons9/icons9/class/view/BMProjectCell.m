//
//  BMProjectCell.m
//  icons9
//
//  Created by fenglh on 2018/4/28.
//  Copyright © 2018年 冯立海. All rights reserved.
//

#import "BMProjectCell.h"
@interface BMProjectCell()

@end;
@implementation BMProjectCell

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
}

//+ (instancetype)view {
//    BMProjectCell *cell = [[BMProjectCell alloc] init];
//    NSImageView *imageView = [[NSImageView alloc] init];
//    [imageView setImage:[NSImage imageNamed:@@property (nonatomic, assign) <#类型#> <#变量#>; ///< <#注释#>]]
//}

- (void)awakeFromNib {
    self.badgeLabel.wantsLayer = YES;
    self.badgeLabel.layer.cornerRadius  = 2.f;
    self.badgeLabel.layer.masksToBounds = YES;

}


- (IBAction)label:(id)sender {
}
- (IBAction)nameLabel:(id)sender {
}
@end
