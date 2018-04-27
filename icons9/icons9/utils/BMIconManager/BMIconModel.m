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


@interface BMIconModel ()
@property (nonatomic,readwrite, strong) NSString *name;       //文件名
@property (nonatomic,readwrite, strong) NSImage *image;       //图片
@property (nonatomic,readwrite, strong) NSString *path;       //路径
@property (nonatomic,readwrite, assign) BMImageType type;     //图片类型
@end


@implementation BMIconModel
+ (instancetype)modelWithPath:(NSString *)path {
    


    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path];
    if (!exists) {
        return nil;
    }
    BMIconModel *model = [[BMIconModel alloc] init];
    model.path = path;
    model.name = [path lastPathComponent];
    model.type = [self getImageType:path];
    
    
    if (model.type == BMImageTypeSVG ) {
         SVGKImage *svgImage = [[SVGKImage alloc] initWithContentsOfFile:path];
        svgImage.size = CGSizeMake(1024, 1024);//svg 存在自身带有固定尺寸，如果不被自身固定尺寸限制，而要期望的尺寸那么设置size
        if (svgImage.hasSize) {
            NSLog(@"%@包含大小:width=%f, height=%f", model.name,svgImage.size.width, svgImage.size.height);
        }
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
