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
        CIImage *ciImage = svgImage.CIImage ;
        NSImage *nsImage = [[NSImage alloc] initWithCGImage:ciImage.CGImage size:CGSizeMake(1024, 1024)];
        model.image = nsImage;
        
        
    }else{
        model.image = [[NSImage alloc] initWithContentsOfFile:path] ;
    }
    

    return model;
}


//+ (NSImage *)svgImagePath:(NSString *)path size:(CGSize)size tintColor:(NSColor *)tintColor {
//    SVGKImage *svgImage = [[SVGKImage alloc] initWithContentsOfFile:path];
//    
//    svgImage.size = size;
//    CGRect rect = CGRectMake(0, 0, svgImage.size.width, svgImage.size.height);
//    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(svgImage.CIImage.CGImage);
//    BOOL opaque = alphaInfo == kCGImageAlphaNoneSkipLast
//    || alphaInfo == kCGImageAlphaNoneSkipFirst
//    || alphaInfo == kCGImageAlphaNone;
//    
//    
//    
//    CGContextRef context = svgImage.newCGContextAutosizedToFit;
//    CGContextTranslateCTM(context, 0, svgImage.size.height);
//    CGContextScaleCTM(context, 1.0, -1.0);
//    CGContextSetBlendMode(context, kCGBlendModeNormal);
//    CGContextClipToMask(context, rect, svgImage.CIImage.CGImage);
//    CGContextSetFillColorWithColor(context, tintColor.CGColor);
//    CGContextFillRect(context, rect);
//    [svgImage renderInContext:context];
//    return svgImage.NSImage;
//}

@end
