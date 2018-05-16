//
//  CNGridViewItemLayout.m
//
//  Created by cocoa:naut on 12.10.12.
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


#import "CNGridViewItemLayout.h"


#if !__has_feature(objc_arc)
#error "Please use ARC for compiling this file."
#endif


static CGFloat kDefaultContentInset;
static CGFloat kDefaultSelectionRingLineWidth;
static CGFloat kDefaultItemBorderRadius;


@implementation CNGridViewItemLayout

+ (void)initialize {
	kDefaultSelectionRingLineWidth = 1.0f;
	kDefaultContentInset = 3.0f;
	kDefaultItemBorderRadius = 5.0f;
}

- (id)init {
	self = [super init];
	if (self) {

        _backgroundColor        = [NSColor colorWithRed:249/255.0 green:249/255.0 blue:249/255.0 alpha:1]; //item背景颜色
		_selectionRingColor     = [NSColor itemSelectionRingColor];//选中外环的颜色
		_selectionRingLineWidth = kDefaultSelectionRingLineWidth;//外环宽度
		_contentInset           = kDefaultContentInset;
		_itemBorderRadius       = kDefaultItemBorderRadius;
        //显示图片和标题
		_visibleContentMask     = (CNGridViewItemVisibleContentImage | CNGridViewItemVisibleContentTitle);

		/// title text font attributes
		NSColor *textColor      = [NSColor itemTitleColor];
		NSShadow *textShadow    = [NSShadow new];
		[textShadow setShadowColor:[NSColor itemTitleShadowColor]];
		[textShadow setShadowOffset:NSMakeSize(0, -1)];

		NSMutableParagraphStyle *textStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
		[textStyle setAlignment:NSCenterTextAlignment];

        _itemTitleTextAttributes = @{NSFontAttributeName: [NSFont fontWithName:@"Helvetica" size:11],
                                     NSShadowAttributeName: textShadow,
                                     NSForegroundColorAttributeName: textColor,
                                     NSParagraphStyleAttributeName: textStyle};
	}
	return self;
}

+ (CNGridViewItemLayout *)defaultLayout {
	CNGridViewItemLayout *defaultLayout = [[[self class] alloc] init];
	return defaultLayout;
}

@end
