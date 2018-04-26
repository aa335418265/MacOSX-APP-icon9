//
//  BMIconModel.m
//  icons9
//
//  Created by 冯立海 on 2018/3/6.
//  Copyright © 2018年 冯立海. All rights reserved.
//

#import "BMIconModel.h"
#import <AppKit/AppKit.h>
#import "SKSVGObject.h"
#import <SVGKit/SVGKit.h>
@implementation BMIconModel
+ (instancetype)modelWithPath:(NSString *)path {
    


    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path];
    if (!exists) {
        return nil;
    }
    BMIconModel *model = [[BMIconModel alloc] init];
    model.path = path;
    
    model.exension = [path pathExtension];
    model.name = [path lastPathComponent];
    if ([model.exension isEqualToString:@"svg"]) {
         SVGKImage *svgImage = [[SVGKImage alloc] initWithContentsOfFile:path];
        //改变颜色
        [BMIconModel changeFillColorRecursively:[svgImage CALayerTree] color:[NSColor redColor]];
        CIImage *ciImage = svgImage.CIImage ;
        NSImage *nsImage = [[NSImage alloc] initWithCGImage:ciImage.CGImage size:CGSizeMake(1024, 1024)];
        
        model.image = nsImage;
    }else{
        model.image = [[NSImage alloc] initWithContentsOfFile:path] ;
    }
    

    return model;
}

+ (void)changeFillColorRecursively:(CALayer *)targetLayer color:(NSColor *)color {
    

    for (CALayer *layer in targetLayer.sublayers) {
        if ([layer isKindOfClass:[CAShapeLayer class]]) {
            CAShapeLayer *shapeLayer = (CAShapeLayer *)layer;
            shapeLayer.strokeColor = color.CGColor;
            shapeLayer.fillColor = color.CGColor;
        }
        if ([layer isKindOfClass:[CALayer class]]) {
            [self changeFillColorRecursively:layer color:color];
        }
    }
}



@end
