//
//  BMIconModel.h
//  icons9
//
//  Created by 冯立海 on 2018/3/6.
//  Copyright © 2018年 冯立海. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SVGKit/SVGKit.h>


@interface BMIconModel : NSObject
@property (nonatomic,readonly, strong) NSString     *name;          //文件名
@property (nonatomic,readonly, strong) NSString     *path;          //路径
@property (nonatomic,readonly, assign) BMImageType  type;           //图片类型
@property (nonatomic,readonly, strong) NSImage      *image;         //



+ (instancetype)modelWithPath:(NSString *)path;
+ (BMImageType)getImageType:(NSString *)path;
- (void)changeSVGFillColor:(NSColor *)color;

//当type = BMImageTypeSVG 时
- (SVGKImage *)svgImage;
@end
