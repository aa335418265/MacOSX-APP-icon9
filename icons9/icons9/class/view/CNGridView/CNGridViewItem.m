//
//  CNGridViewItem.m
//
//  Created by cocoa:naut on 06.10.12.
//  Copyright (c) 2012 cocoa:naut. All rights reserved.
//

/*
 The MIT License (MIT)
 Copyright © 2012 Frank Gregor, <phranck@cocoanaut.com>

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the “Software”), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#import "CNGridViewItem.h"
#import "NSColor+CNGridViewPalette.h"
#import "CNGridViewItemLayout.h"
#import "SKSVGObject.h"
#import <SVGKit/SVGKit.h>


#if !__has_feature(objc_arc)
#error "Please use ARC for compiling this file."
#endif

#define ItemImageInset      10
#define ItemTitleHeight     24
#define MiniSquareSize(size) (size.width < size.height ? CGSizeMake(size.width, size.width) : CGSizeMake(size.height, size.height))

NSString *const kCNDefaultItemIdentifier = @"CNGridViewItem";


/// Notifications
extern NSString *CNGridViewSelectAllItemsNotification;
extern NSString *CNGridViewDeSelectAllItemsNotification;


@implementation CNGridViewItemBase



+ (CGSize)defaultItemSize {
	return NSMakeSize(310, 225);
}

- (void)dealloc {
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self name:CNGridViewSelectAllItemsNotification object:nil];
	[nc removeObserver:self name:CNGridViewDeSelectAllItemsNotification object:nil];
}


- (id)init {
	self = [super init];
	if (self) {
		[self initProperties];
	}
	return self;
}

- (id)initWithFrame:(NSRect)frameRect {
	self = [super initWithFrame:frameRect];
	if (self) {
		[self initProperties];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
		[self initProperties];
	}
	return self;
}


- (void)initProperties {
	/// Reusing Grid View Items
	self.reuseIdentifier = kCNDefaultItemIdentifier;
	self.index = CNItemIndexUndefined;


	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(selectAll:) name:CNGridViewSelectAllItemsNotification object:nil];
	[nc addObserver:self selector:@selector(deSelectAll:) name:CNGridViewDeSelectAllItemsNotification object:nil];
    
}



- (void)prepareForReuse {
    
	self.index = CNItemIndexUndefined;
	self.selected = NO;
	self.selectable = YES;
	self.hovered = NO;
}

- (BOOL)isReuseable {
	return (self.selected ? NO : YES);
}

- (void)selectAll:(NSNotification *)notification {
	[self setSelected:YES];
}

- (void)deSelectAll:(NSNotification *)notification {
	[self setSelected:NO];
}

@end


@interface CNGridViewItem ()
@property (strong) CNGridViewItemLayout *currentLayout;

@end

@implementation CNGridViewItem

#pragma mark - Initialzation

- (id)initWithLayout:(CNGridViewItemLayout *)layout reuseIdentifier:(NSString *)reuseIdentifier {
	self = [self init];
	if (self) {
		_defaultLayout = layout;
		_hoverLayout = layout;
		_selectionLayout = layout;
		_currentLayout = _defaultLayout;
		self.reuseIdentifier = reuseIdentifier;
	}
	return self;
}

- (void)initProperties {
	[super initProperties];
	/// Grid View 布局
	_defaultLayout = [CNGridViewItemLayout defaultLayout];
	_hoverLayout = [CNGridViewItemLayout defaultLayout];
	_selectionLayout = [CNGridViewItemLayout defaultLayout];
	_currentLayout = _defaultLayout;
	_useLayout = YES;
}






- (BOOL)isFlipped {
	return YES;
}

#pragma mark - Reusing Grid View Items

- (void)prepareForReuse {
	[super prepareForReuse];
}

#pragma mark - ViewDrawing



- (void)drawRect:(NSRect)rect {
    NSLog(@"===================");
    
    CFAbsoluteTime startTime =CFAbsoluteTimeGetCurrent();
    NSBezierPath *contentRectPath = [NSBezierPath bezierPathWithRoundedRect:[self contentRect] xRadius:self.currentLayout.itemBorderRadius yRadius:self.currentLayout.itemBorderRadius];
    [self.currentLayout.backgroundColor setFill];
    [contentRectPath fill];
    /// draw selection ring
    if (self.selected) {
        [self.currentLayout.selectionRingColor setStroke];
        [contentRectPath setLineWidth:self.currentLayout.selectionRingLineWidth];
        [contentRectPath stroke];
    }

    //图片大小
    CGSize imageSize = [self imageContentSize];


    NSImage *image = [self resizeImage:self.imageModel.image targetSize:imageSize];//调整大小



    NSRect srcRect = NSZeroRect;
    NSSize imgSize = image.size;
    srcRect.size = imgSize;
    NSRect imageRect = NSZeroRect;
    NSRect textRect = NSZeroRect;
    CGFloat contentInset = self.currentLayout.contentInset;

    CGFloat imgW = imgSize.width;
    CGFloat imgH = imgSize.height;
    CGFloat W = NSWidth([self contentRect]);
    CGFloat H = NSHeight([self contentRect]);

    if ((self.currentLayout.visibleContentMask & (CNGridViewItemVisibleContentImage | CNGridViewItemVisibleContentTitle)) ==
        (CNGridViewItemVisibleContentImage | CNGridViewItemVisibleContentTitle)
        ) {
        imageRect = NSMakeRect(self.bounds.size.width /2 - imgW / 2 ,
                               self.currentLayout.contentInset + ItemImageInset ,
                               imgW,
                               imgH);
        [image drawInRect:imageRect fromRect:srcRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];

        CGFloat textInset = 16;
        CGSize textSize = [self getStringSize:self.imageModel.name maxWidth:W - textInset maxHeight:ItemTitleHeight attributes:self.currentLayout.itemTitleTextAttributes];

        textRect = NSMakeRect((self.bounds.size.width - textSize.width) / 2.0 + 2,
                              self.bounds.size.height - 2 * self.currentLayout.contentInset - textSize.height - 4,
                              textSize.width,
                              textSize.height);
        [self.imageModel.name drawInRect:textRect withAttributes:self.currentLayout.itemTitleTextAttributes];
    }

    else if (self.currentLayout.visibleContentMask & CNGridViewItemVisibleContentImage) {
        if (W >= imgW && H >= imgH) {
            imageRect = NSMakeRect(((W - imgW) / 2) + contentInset,
                                   ((H - imgH) / 2) + contentInset,
                                   imgW,
                                   imgH);
        }
        else if (0 < W && 0 < H && imgW > 0 && imgH > 0) {
            CGFloat kView = H / W;
            CGFloat kImg = imgH / imgW;

            if (kView > kImg) {
                // use W
                CGFloat newH = W * kImg;
                CGFloat y = floorf((H - newH) / 2);
                imageRect.size.width = W;
                imageRect.size.height = ceilf(newH);
                imageRect.origin.x = 0;
                imageRect.origin.y = y;
            }
            else {
                // use H

                CGFloat newW = H / kImg;
                CGFloat x = floorf((W - newW) / 2);
                imageRect.size.width = newW;
                imageRect.size.height = H;
                imageRect.origin.x = x;
                imageRect.origin.y = 0;
            }
        }

        [image drawInRect:imageRect fromRect:srcRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
    }
    CFAbsoluteTime linkTime = (CFAbsoluteTimeGetCurrent() - startTime);
//    NSLog(@"item 绘制代码执行时间 %f ms", linkTime *1000.0);

}

#pragma mark - 私有方法
//item(图片+标题)可显示的区域大小
- (CGRect)contentRect {
    
    return NSMakeRect(self.bounds.origin.x + self.currentLayout.contentInset,
                      self.bounds.origin.y + self.currentLayout.contentInset,
                      self.bounds.size.width - self.currentLayout.contentInset * 2,
                      self.bounds.size.height - self.currentLayout.contentInset * 2);
}

//图片可以显示的区域大小
- (CGSize)imageContentSize {
    NSRect contentRect = [self contentRect];
    CGSize imageSize = CGSizeMake(contentRect.size.width - 2 * ItemImageInset, contentRect.size.height - 2 * ItemImageInset - ItemTitleHeight);
    return imageSize;
}

//获取字符串尺寸大小
- (CGSize)getStringSize:(NSString *)string maxWidth:(CGFloat)maxWidth maxHeight:(CGFloat)maxHeight  attributes:(NSDictionary *)attributes {

    NSSize size = NSMakeSize(maxWidth, maxHeight);
    NSRect bounds;

    // 2获得该文字的高度和宽度
    bounds = [string
              boundingRectWithSize: size
              options: NSStringDrawingUsesFontLeading
              attributes: attributes];

    return bounds.size;
}
//图片缩放
- (NSImage*) resizeImage:(NSImage*)sourceImage targetSize:(CGSize)targetSize
{
 
    if (sourceImage == nil) {
        return nil;
    }
    CFAbsoluteTime startTime =CFAbsoluteTimeGetCurrent();
    
    CGSize imageSize = sourceImage.size;
//    NSImageRep *imageRep = [sourceImage.representations firstObject];
//    if (imageRep) {
//       imageSize = CGSizeMake(imageRep.pixelsWide, imageRep.pixelsHigh);
//    }


    CGFloat maxEdage = imageSize.width > imageSize.height ?  imageSize.width : imageSize.height;
    CGFloat scale = 1;
    scale = targetSize.height / maxEdage;

    NSRect targetFrame = NSMakeRect(0, 0, imageSize.width * scale, imageSize.height * scale);
    if (targetFrame.size.width <0 || targetFrame.size.height < 0) {
        return nil;
    }
    NSImage* targetImage = nil;
    NSImageRep *sourceImageRep =
    [sourceImage bestRepresentationForRect:targetFrame
                                   context:nil
                                     hints:nil];

    targetImage = [[NSImage alloc] initWithSize:targetFrame.size];

    [targetImage lockFocus];
    [sourceImageRep drawInRect: targetFrame];
    [targetImage unlockFocus];
    CFAbsoluteTime linkTime = (CFAbsoluteTimeGetCurrent() - startTime);
    
//    NSLog(@"图片缩放代码执行时间 %f ms", linkTime *1000.0);
    return targetImage;
}



#pragma mark - 通知

- (void)clearHovering {
	[self setHovered:NO];
}

- (void)clearSelection {
	[self setSelected:NO];
}

#pragma mark - Accessors

- (void)setHovered:(BOOL)hovered {
	[super setHovered:hovered];
	_currentLayout = (self.hovered ? _hoverLayout : (self.selected ? _selectionLayout : _defaultLayout));
	[self setNeedsDisplay:YES];
}

- (void)setSelected:(BOOL)selected {
	[super setSelected:selected];
	_currentLayout = (self.selected ? _selectionLayout : _defaultLayout);
	[self setNeedsDisplay:YES];
}

- (void)setDefaultLayout:(CNGridViewItemLayout *)defaultLayout {
	_defaultLayout = defaultLayout;
	self.currentLayout = _defaultLayout;
}


#pragma mark - NSPasteboardItemDataProvider


@end
