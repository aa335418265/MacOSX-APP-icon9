//
//  BMIconModel.m
//  icons9
//
//  Created by 冯立海 on 2018/3/6.
//  Copyright © 2018年 冯立海. All rights reserved.
//

#import "BMIconModel.h"
#import <AppKit/AppKit.h>
#import <QuartzCore/QuartzCore.h>


@interface BMIconModel ()
@property (nonatomic,readwrite, strong) NSString *name;       //文件名
@property (nonatomic,readwrite, strong) NSString *path;       //路径
@property (nonatomic,readwrite, assign) BMImageType type;     //图片类型
@property (nonatomic,readwrite, strong) SVGKImage *svgImge;  //当type = BMImageTypeSVG 时
@property (nonatomic,readwrite, strong) NSImage *image;

@end


@implementation BMIconModel
+ (instancetype)modelWithPath:(NSString *)path {
    


    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path];
    if (!exists) {
        return nil;
    }
    BMImageType type = [self getImageType:path];
    
    BMIconModel *model = [[BMIconModel alloc] init];
    model.path = path;
    model.name = [path lastPathComponent];
    model.type = type;
    if (type == BMImageTypeSVG) {
        SVGKImage *svgImage = [[SVGKImage alloc] initWithContentsOfFile:path];
        model.svgImge = svgImage;
        svgImage.size = CGSizeMake(1024, 1024);
    }else{
        model.image = [[NSImage alloc] initWithContentsOfFile:path] ;
    }
    return model;
}

+ (BMImageType)getImageType:(NSString *)path {

        if ([[path pathExtension] isEqualToString:@"svg"]) {
            return BMImageTypeSVG;
        }
        if ([[path pathExtension] isEqualToString:@"png"]) {
            return BMImageTypePNG;
        }
        if ([[path pathExtension] isEqualToString:@"jpg"]) {
            return BMImageTypeJPG;
        }
    return BMImageTypeUnknown;
}



- (void)changeSVGFillColor:(NSColor *)color {
    if (self.svgImge == nil || [self.svgImge hasCALayerTree] == NO || color == nil) {
        return;
    }

    [self changeFillColorRecursively:[self.svgImge CALayerTree] color:color];
}

- (void) changeFillColorRecursively:(CALayer *)targetLayer color:(NSColor *)color {
    if (targetLayer == nil || color == nil) {
        return;
    }
    for (CALayer *layer in targetLayer.sublayers) {
        if ([layer isKindOfClass:[CAShapeLayer class]]) {
            CAShapeLayer *shapeLayer = (CAShapeLayer *)layer;
            shapeLayer.strokeColor = color.CGColor;
            shapeLayer.fillColor = color.CGColor;
            return;
        }
        if ([layer isKindOfClass:[CALayer class]]) {
            [self changeFillColorRecursively:layer color:color];
        }
    }
}

- (NSImage *)image {
    if (_type == BMImageTypeSVG) {
        return self.svgImge.NSImage;
    }else{
        return _image;
    }
}



@end
