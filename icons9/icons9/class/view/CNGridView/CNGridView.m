//
//  CNGridView.m
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

#import <QuartzCore/QuartzCore.h>
#import "NSColor+CNGridViewPalette.h"
#import "NSView+CNGridView.h"
#import "CNGridView.h"


#if !__has_feature(objc_arc)
#error "Please use ARC for compiling this file."
#endif



#pragma mark Notifications

const int CNSingleClick = 1;
const int CNDoubleClick = 2;
const int CNTrippleClick = 3;

NSString *const CNGridViewSelectAllItemsNotification = @"CNGridViewSelectAllItems";
NSString *const CNGridViewDeSelectAllItemsNotification = @"CNGridViewDeSelectAllItems";

NSString *const CNGridViewWillHoverItemNotification = @"CNGridViewWillHoverItem";
NSString *const CNGridViewWillUnhoverItemNotification = @"CNGridViewWillUnhoverItem";
NSString *const CNGridViewWillSelectItemNotification = @"CNGridViewWillSelectItem";
NSString *const CNGridViewDidSelectItemNotification = @"CNGridViewDidSelectItem";
NSString *const CNGridViewWillDeselectItemNotification = @"CNGridViewWillDeselectItem";
NSString *const CNGridViewDidDeselectItemNotification = @"CNGridViewDidDeselectItem";
NSString *const CNGridViewWillDeselectAllItemsNotification = @"CNGridViewWillDeselectAllItems";
NSString *const CNGridViewDidDeselectAllItemsNotification = @"CNGridViewDidDeselectAllItems";
NSString *const CNGridViewDidClickItemNotification = @"CNGridViewDidClickItem";
NSString *const CNGridViewDidDoubleClickItemNotification = @"CNGridViewDidDoubleClickItem";
NSString *const CNGridViewRightMouseButtonClickedOnItemNotification = @"CNGridViewRightMouseButtonClickedOnItem";

NSString *const CNGridViewItemKey = @"gridViewItem";
NSString *const CNGridViewItemIndexKey = @"gridViewItemIndex";
NSString *const CNGridViewSelectedItemsKey = @"CNGridViewSelectedItems";
NSString *const CNGridViewItemsIndexSetKey = @"CNGridViewItemsIndexSetKey";


CNItemPoint CNMakeItemPoint(NSUInteger aColumn, NSUInteger aRow) {
	CNItemPoint point;
	point.column = aColumn;
	point.row = aRow;
	return point;
}

#pragma mark CNSelectionFrameView

@interface CNSelectionFrameView : NSView
@end

#pragma mark CNGridView


@interface CNGridView () <NSDraggingSource, NSDraggingDestination, NSPasteboardItemDataProvider>
{
	
	NSMutableDictionary *selectedItems;
	
	CNSelectionFrameView *selectionFrameView;
	NSNotificationCenter *nc;
	NSMutableArray *clickEvents;
	NSTrackingArea *gridViewTrackingArea;
	NSTimer *clickTimer;
	NSInteger lastHoveredIndex;
	NSInteger lastSelectedItemIndex;
	NSInteger numberOfItems;
	CGPoint selectionFrameInitialPoint;


	CGFloat _contentInset;
}
@property (nonatomic, strong) NSMutableDictionary *reuseableItems; ///< <#注释#>
@property (nonatomic, strong) NSMutableDictionary *keyedVisibleItems; ///< <#注释#>
@property (nonatomic, assign)     BOOL isInitialCall; ///< <#注释#>
@property (nonatomic, strong) NSMutableDictionary *selectedItemsBySelectionFrame;  ///< <#注释#>
@property (nonatomic, assign) BOOL mouseHasDraged;  ///< 鼠标已经拖拽选中item
@property (nonatomic, assign) CGPoint mouseDownPoint; ///< 鼠标按下坐标
@end


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"

@implementation CNGridView

#pragma mark - Initialization

- (id)init {
	self = [super init];
	if (self) {
		[self setupDefaults];
		_delegate = nil;
		_dataSource = nil;
	}
	return self;
}

- (id)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];
	if (self) {
		[self setupDefaults];
		_delegate = nil;
		_dataSource = nil;
	}

	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	if (self) {
		[self setupDefaults];
        //注册拖放
        [self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, NSTIFFPboardType,nil]];
	}
	return self;
}

- (void)setupDefaults {
	self.keyedVisibleItems = [[NSMutableDictionary alloc] init];
	self.reuseableItems = [[NSMutableDictionary alloc] init];
	selectedItems = [[NSMutableDictionary alloc] init];
	self.selectedItemsBySelectionFrame = [[NSMutableDictionary alloc] init];
	clickEvents = [NSMutableArray array];
	nc = [NSNotificationCenter defaultCenter];
	lastHoveredIndex = NSNotFound;
	lastSelectedItemIndex = NSNotFound;
	selectionFrameInitialPoint = CGPointZero;
	clickTimer = nil;
	self.isInitialCall = YES;
	selectionFrameView = nil;


	// properties
	_backgroundColor = [NSColor controlColor];
	_itemSize = [CNGridViewItem defaultItemSize];
	_gridViewTitle = nil;
	_scrollElasticity = YES;
	_useSelectionRing = YES;


    



	[[self enclosingScrollView] setDrawsBackground:YES];

	NSClipView *clipView = [[self enclosingScrollView] contentView];
	[clipView setPostsBoundsChangedNotifications:YES];
	[[NSNotificationCenter defaultCenter] addObserver:self
	                                         selector:@selector(updateVisibleRect)
	                                             name:NSViewBoundsDidChangeNotification
	                                           object:clipView];
}









#pragma mark - Accessors

- (void)setItemSize:(NSSize)itemSize {
	if (!NSEqualSizes(_itemSize, itemSize)) {
		_itemSize = itemSize;
		[self refreshGridViewAnimated:YES initialCall:YES];
	}
}

- (void)setScrollElasticity:(BOOL)scrollElasticity {
	_scrollElasticity = scrollElasticity;
	NSScrollView *scrollView = [self enclosingScrollView];
	if (_scrollElasticity) {
//		[scrollView setHorizontalScrollElasticity:NSScrollElasticityAllowed];
		[scrollView setVerticalScrollElasticity:NSScrollElasticityAllowed];
	}
	else {
//		[scrollView setHorizontalScrollElasticity:NSScrollElasticityNone];
		[scrollView setVerticalScrollElasticity:NSScrollElasticityNone];
	}
}

- (void)setBackgroundColor:(NSColor *)backgroundColor {
	_backgroundColor = backgroundColor;
	[[self enclosingScrollView] setBackgroundColor:_backgroundColor];
}



#pragma mark - Private Helper

- (void)_refreshInset {
	if (self.useCenterAlignment) {
		NSRect clippedRect  = [self clippedRect];
		NSUInteger columns  = [self columnsInGridView];
		_contentInset = floorf((clippedRect.size.width - columns * self.itemSize.width) / 2);
	}
	else {
		_contentInset = 0;
	}
}

- (void)updateVisibleRect {
	[self updatereuseableItems];
	[self updateVisibleItems];
	[self arrangeGridViewItemsAnimated:NO];
}

- (void)refreshGridViewAnimated:(BOOL)animated initialCall:(BOOL)initialCall {
	self.isInitialCall = initialCall;

	CGSize size = self.frame.size;
	CGFloat newHeight = [self allOverRowsInGridView] * self.itemSize.height + _contentInset * 2;
	if (ABS(newHeight - size.height) > 1) {
		size.height = newHeight;
        if (size.height<NSHeight(self.enclosingScrollView.frame)) {
            size.height=NSHeight(self.enclosingScrollView.frame);
        }
		[super setFrameSize:size];
	}

	[self _refreshInset];
	__weak typeof(self) wSelf = self;
	dispatch_async(dispatch_get_main_queue(), ^{
	    [wSelf _refreshInset];
	    [wSelf updatereuseableItems];
	    [wSelf updateVisibleItems];
	    [wSelf arrangeGridViewItemsAnimated:animated];
	});
}

- (void)updatereuseableItems {
	//Do not mark items as reusable unless there are no selected items in the grid as recycling items when doing range multiselect
	if (self.selectedIndexes.count == 0) {
		NSRange visibleItemRange = [self visibleItemRange];

		[[self.keyedVisibleItems allValues] enumerateObjectsUsingBlock: ^(CNGridViewItem *item, NSUInteger idx, BOOL *stop) {
		    if (!NSLocationInRange(item.index, visibleItemRange) && [item isReuseable]) {
		        [self.keyedVisibleItems removeObjectForKey:@(item.index)];
		        [item removeFromSuperview];
		        [item prepareForReuse];

		        NSMutableSet *reuseQueue = self.reuseableItems[item.reuseIdentifier];
		        if (reuseQueue == nil) {
					reuseQueue = [NSMutableSet set];
                }
		        [reuseQueue addObject:item];
		        self.reuseableItems[item.reuseIdentifier] = reuseQueue;
			}
		}];
	}
}

- (void)updateVisibleItems {
	NSRange visibleItemRange = [self visibleItemRange];
	NSMutableIndexSet *visibleItemIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:visibleItemRange];

	[visibleItemIndexes removeIndexes:[self indexesForVisibleItems]];

	// update all visible items
	[visibleItemIndexes enumerateIndexesUsingBlock: ^(NSUInteger idx, BOOL *stop) {
	    CNGridViewItem *item = [self gridView:self itemAtIndex:idx inSection:0];
	    if (item) {
	        item.index = idx;
	        if (self.isInitialCall) {
	            [item setAlphaValue:0.0];
	            [item setFrame:[self rectForItemAtIndex:idx]];
			}
	        [self.keyedVisibleItems setObject:item forKey:@(item.index)];
	        [self addSubview:item];
		}
	}];
}

- (NSIndexSet *)indexesForVisibleItems {
	__block NSMutableIndexSet *indexesForVisibleItems = [[NSMutableIndexSet alloc] init];
	[self.keyedVisibleItems enumerateKeysAndObjectsUsingBlock: ^(id key, CNGridViewItem *item, BOOL *stop) {
	    [indexesForVisibleItems addIndex:item.index];
	}];
	return indexesForVisibleItems;
}

- (void)arrangeGridViewItemsAnimated:(BOOL)animated {
	// on initial call (aka application startup) we will fade all items (after loading it) in
    if ([self.keyedVisibleItems count] > 0) {
        if (self.isInitialCall) {
            self.isInitialCall = NO;
            if (animated) {
                [[NSAnimationContext currentContext] setDuration:0.35];
                [NSAnimationContext runAnimationGroup: ^(NSAnimationContext *context) {
                    [self.keyedVisibleItems enumerateKeysAndObjectsUsingBlock: ^(id key, CNGridViewItem *item, BOOL *stop) {
                        [[item animator] setAlphaValue:1.0];
                        NSRect newRect = [self rectForItemAtIndex:item.index];
                        [[item animator] setFrame:newRect];
                    }];
                } completionHandler:nil];
            }
            else{
                [self.keyedVisibleItems enumerateKeysAndObjectsUsingBlock: ^(id key, CNGridViewItem *item, BOOL *stop) {
                    [item setAlphaValue:1.0];
                    NSRect newRect = [self rectForItemAtIndex:item.index];
                    [item setFrame:newRect];
                }];
            }
        }
        else{
            if (animated) {
                [[NSAnimationContext currentContext] setDuration:0.15];
                [NSAnimationContext runAnimationGroup: ^(NSAnimationContext *context) {
                    [self.keyedVisibleItems enumerateKeysAndObjectsUsingBlock: ^(id key, CNGridViewItem *item, BOOL *stop) {
                        NSRect newRect = [self rectForItemAtIndex:item.index];
                        [[item animator] setFrame:newRect];
                    }];
                } completionHandler:nil];
            }
            else{
                [self.keyedVisibleItems enumerateKeysAndObjectsUsingBlock: ^(id key, CNGridViewItem *item, BOOL *stop) {
                    NSRect newRect = [self rectForItemAtIndex:item.index];
                    [item setFrame:newRect];
                }];
            }
        }
    }
}

- (NSRange)visibleItemRange {
	NSRect clippedRect  = [self clippedRect];
	NSUInteger columns  = [self columnsInGridView];
	NSUInteger rows     = [self visibleRowsInGridView];

	NSUInteger rangeStart = 0;
	if (clippedRect.origin.y > self.itemSize.height) {
		rangeStart = (ceilf(clippedRect.origin.y / self.itemSize.height) * columns) - columns;
	}
	NSUInteger rangeLength = MIN(numberOfItems, (columns * rows) + columns);
	rangeLength = ((rangeStart + rangeLength) > numberOfItems ? numberOfItems - rangeStart : rangeLength);

	NSRange rangeForVisibleRect = NSMakeRange(rangeStart, rangeLength);
	return rangeForVisibleRect;
}

- (NSRect)rectForItemAtIndex:(NSUInteger)index {
	NSUInteger columns = [self columnsInGridView];
	NSRect itemRect = NSMakeRect((index % columns) * self.itemSize.width + _contentInset,
	                             ((index - (index % columns)) / columns) * self.itemSize.height + _contentInset,
	                             self.itemSize.width,
	                             self.itemSize.height);
    if(itemRect.size.width < 100){
        NSLog(@"---");
    }
	return itemRect;
}

- (NSUInteger)columnsInGridView {
	NSRect visibleRect  = [self clippedRect];
	NSUInteger columns = floorf((float)NSWidth(visibleRect) / self.itemSize.width);
	columns = (columns < 1 ? 1 : columns);
	return columns;
}

- (NSUInteger)allOverRowsInGridView {
	NSUInteger allOverRows = ceilf((float)numberOfItems / [self columnsInGridView]);
	return allOverRows;
}

- (NSUInteger)visibleRowsInGridView {
	NSRect visibleRect  = [self clippedRect];
	NSUInteger visibleRows = ceilf((float)NSHeight(visibleRect) / self.itemSize.height);
	return visibleRows;
}

- (NSRect)clippedRect {
	return [[[self enclosingScrollView] contentView] bounds];
}

- (NSUInteger)indexForItemAtLocation:(NSPoint)location {
	NSPoint point = [self convertPoint:location fromView:nil];
	NSUInteger indexForItemAtLocation;
	if (point.x > (self.itemSize.width * [self columnsInGridView] + _contentInset)) {
		indexForItemAtLocation = NSNotFound;
	}
	else {
		NSUInteger currentColumn = floor((point.x - _contentInset) / self.itemSize.width);
		NSUInteger currentRow = floor((point.y - _contentInset) / self.itemSize.height);
		indexForItemAtLocation = currentRow * [self columnsInGridView] + currentColumn;
		indexForItemAtLocation = (indexForItemAtLocation > (numberOfItems - 1) ? NSNotFound : indexForItemAtLocation);
	}
	return indexForItemAtLocation;
}

- (CNItemPoint)locationForItemAtIndex:(NSUInteger)itemIndex {
	NSUInteger columnsInGridView = [self columnsInGridView];
	NSUInteger row = floor(itemIndex / columnsInGridView) + 1;
	NSUInteger column = itemIndex - floor((row - 1) * columnsInGridView) + 1;
	CNItemPoint location = CNMakeItemPoint(column, row);
	return location;
}

#pragma mark - Creating GridView Items

- (id)dequeueReusableItemWithIdentifier:(NSString *)identifier {
	CNGridViewItem *reusableItem = nil;
	NSMutableSet *reuseQueue = self.reuseableItems[identifier];
	if (reuseQueue != nil && [reuseQueue count] > 0) {
		reusableItem = [reuseQueue anyObject];
		[reuseQueue removeObject:reusableItem];
		self.reuseableItems[identifier] = reuseQueue;
		reusableItem.representedObject = nil;
	}
	return reusableItem;
}

#pragma mark - Reloading GridView Data

- (void)reloadData {
	[self reloadDataAnimated:NO];
}

- (void)reloadDataAnimated:(BOOL)animated {
	numberOfItems = [self gridView:self numberOfItemsInSection:0];
	[self.keyedVisibleItems enumerateKeysAndObjectsUsingBlock: ^(id key, id obj, BOOL *stop) {
	    [(CNGridViewItemBase *)obj removeFromSuperview];
	}];
	[self.keyedVisibleItems removeAllObjects];
	[self.reuseableItems removeAllObjects];
	[self refreshGridViewAnimated:animated initialCall:YES];
}

#pragma mark - animating KVO changes

- (void)insertItemAtIndex:(NSInteger)index animated:(BOOL)animated {
	NSUInteger count = self.keyedVisibleItems.count;
	if (count) {
		NSMutableArray *affected = [NSMutableArray arrayWithCapacity:count];
		// adjust the index
		[[self.keyedVisibleItems allValues] enumerateObjectsUsingBlock: ^(id obj, NSUInteger idx, BOOL *stop) {
		    CNGridViewItemBase *item = (CNGridViewItemBase *)obj;
		    NSUInteger i = item.index;
		    if (i >= index) {
		        NSUInteger acount = affected.count;
		        NSUInteger insertPos = acount;
		        for (NSUInteger j = 0; j < acount; j++) {
		            CNGridViewItemBase *p = [affected objectAtIndex:j];
		            if (i > p.index) {
		                insertPos = j;
		                break;
					}
				}
		        [affected insertObject:item atIndex:insertPos];
			}
		}];

		if (affected.count) {
			for (CNGridViewItemBase *item in affected) {
				NSInteger index = item.index;
				NSInteger newIndex = index + 1;

				[self.keyedVisibleItems removeObjectForKey:@(index)];
				[self.keyedVisibleItems setObject:item forKey:@(newIndex)];
				item.index = newIndex;
			}
			if (animated) {
				[[NSAnimationContext currentContext] setDuration:(animated ? 0.15 : 0.0)];
				[NSAnimationContext runAnimationGroup: ^(NSAnimationContext *context) {
				    for (CNGridViewItemBase * item in affected) {
				        NSInteger index = item.index;
				        NSRect newRect = [self rectForItemAtIndex:index];
				        [[item animator] setFrame:newRect];
					}
				} completionHandler:nil];
			}
			else {
				for (CNGridViewItemBase *item in affected) {
					NSInteger index = item.index;
					NSRect newRect = [self rectForItemAtIndex:index];
					[item setFrame:newRect];
				}
			}
		}
	}
	numberOfItems++;
	[self refreshGridViewAnimated:animated initialCall:YES];
}

- (void)insertItemsAtIndexes:(NSIndexSet *)indexes animated:(BOOL)animated {
	NSUInteger first = indexes.firstIndex;
	if (NSNotFound == first) {
		return;
	}

	NSUInteger count = self.keyedVisibleItems.count;
	if (count) {
		NSMutableArray *affected = [NSMutableArray arrayWithCapacity:count];
		// adjust the index
		[[self.keyedVisibleItems allValues] enumerateObjectsUsingBlock: ^(id obj, NSUInteger idx, BOOL *stop) {
		    CNGridViewItemBase *item = (CNGridViewItemBase *)obj;
		    NSUInteger i = item.index;
		    if (i >= first) {
		        NSUInteger acount = affected.count;
		        NSUInteger insertPos = acount;
		        for (NSUInteger j = 0; j < acount; j++) {
		            CNGridViewItemBase *p = [affected objectAtIndex:j];
		            if (i > p.index) {
		                insertPos = j;
		                break;
					}
				}
		        [affected insertObject:item atIndex:insertPos];
			}
		}];

		if (affected.count) {
			for (CNGridViewItemBase *item in affected) {
				NSInteger index = item.index;

				// check the number of new index before the index;
				__block NSUInteger ncount = 0;
				[indexes enumerateRangesUsingBlock: ^(NSRange range, BOOL *stop) {
				    if (range.location < index) {
				        ncount += range.length;
					}
				}];

				NSInteger newIndex = index + ncount;
				[self.keyedVisibleItems removeObjectForKey:@(index)];
				[self.keyedVisibleItems setObject:item forKey:@(newIndex)];
				item.index = newIndex;
			}
			if (animated) {
				[[NSAnimationContext currentContext] setDuration:(animated ? 0.15 : 0.0)];
				[NSAnimationContext runAnimationGroup: ^(NSAnimationContext *context) {
				    for (CNGridViewItemBase * item in affected) {
				        NSInteger index = item.index;
				        NSRect newRect = [self rectForItemAtIndex:index];
				        [[item animator] setFrame:newRect];
					}
				} completionHandler:nil];
			}
			else {
				for (CNGridViewItemBase *item in affected) {
					NSInteger index = item.index;
					NSRect newRect = [self rectForItemAtIndex:index];
					[item setFrame:newRect];
				}
			}
		}
	}

	numberOfItems += indexes.count;
	[self refreshGridViewAnimated:animated initialCall:NO];
}

- (void)reloadItemsAtIndexes:(NSIndexSet *)indexes animated:(BOOL)animated {
	NSUInteger first = indexes.firstIndex;
	if (NSNotFound == first) {
		return;
	}

	NSUInteger count = self.keyedVisibleItems.count;
	if (count) {
		NSMutableArray *affected = [NSMutableArray arrayWithCapacity:count];
		// adjust the index
		[[self.keyedVisibleItems allValues] enumerateObjectsUsingBlock: ^(id obj, NSUInteger idx, BOOL *stop) {
		    CNGridViewItemBase *item = (CNGridViewItemBase *)obj;
		    NSUInteger i = item.index;
		    if ([indexes containsIndex:i]) {
		        NSUInteger acount = affected.count;
		        NSUInteger insertPos = acount;
		        for (NSUInteger j = 0; j < acount; j++) {
		            CNGridViewItemBase *p = [affected objectAtIndex:j];
		            if (i > p.index) {
		                insertPos = j;
		                break;
					}
				}
		        [affected insertObject:item atIndex:insertPos];
			}
		}];

		if (affected.count) {
			for (CNGridViewItemBase *item in affected) {
				NSInteger index = item.index;
				[self.keyedVisibleItems removeObjectForKey:@(index)];
			}
			if (animated) {
				[[NSAnimationContext currentContext] setDuration:(animated ? 0.15 : 0.0)];
				[NSAnimationContext runAnimationGroup: ^(NSAnimationContext *context) {
				    for (CNGridViewItemBase * item in affected) {
				        [item setAlphaValue:1.0];
					}
				} completionHandler: ^() {
				    for (CNGridViewItemBase * item in affected) {
				        [item removeFromSuperview];
					}
				}];
			}
			else {
				for (CNGridViewItemBase *item in affected) {
					NSInteger index = item.index;
					NSRect newRect = [self rectForItemAtIndex:index];
					[item setFrame:newRect];
				}
			}
		}
	}

	self.isInitialCall = YES;
	[self refreshGridViewAnimated:animated initialCall:NO];
}

- (void)removeItemsAtIndexes:(NSIndexSet *)indexes animated:(BOOL)animated {
	NSUInteger first = indexes.firstIndex;
	if (NSNotFound == first) {
		return;
	}

	NSUInteger count = self.keyedVisibleItems.count;
	if (count) {
		NSMutableArray *affected = [NSMutableArray arrayWithCapacity:count];
		// adjust the index
		[[self.keyedVisibleItems allValues] enumerateObjectsUsingBlock: ^(id obj, NSUInteger idx, BOOL *stop) {
		    CNGridViewItemBase *item = (CNGridViewItemBase *)obj;
		    NSUInteger i = item.index;
		    if (i >= first) {
		        NSUInteger acount = affected.count;
		        NSUInteger insertPos = acount;
		        for (NSUInteger j = 0; j < acount; j++) {
		            CNGridViewItemBase *p = [affected objectAtIndex:j];
		            if (i > p.index) {
		                insertPos = j;
		                break;
					}
				}
		        [affected insertObject:item atIndex:insertPos];
			}
		}];

		if (affected.count) {
			for (CNGridViewItemBase *item in affected) {
				NSInteger index = item.index;
				[self.keyedVisibleItems removeObjectForKey:@(index)];
			}
			if (animated) {
				[[NSAnimationContext currentContext] setDuration:(animated ? 0.15 : 0.0)];
				[NSAnimationContext runAnimationGroup: ^(NSAnimationContext *context) {
				    for (CNGridViewItemBase * item in affected) {
				        [item setAlphaValue:1.0];
					}

				} completionHandler: ^() {
				    for (CNGridViewItemBase * item in affected) {
				        [item removeFromSuperview];
					}
				}];
			}
			else {
				for (CNGridViewItemBase *item in affected) {
					[item removeFromSuperview];
					[item prepareForReuse];
					NSString *cellID = item.identifier;
					NSMutableSet *reuseQueue = self.reuseableItems[cellID];
					if (reuseQueue == nil)
						reuseQueue = [NSMutableSet set];
					[reuseQueue addObject:item];
                    self.reuseableItems[cellID] = reuseQueue;
				}
			}
		}
	}

	numberOfItems -= indexes.count;
	[self refreshGridViewAnimated:animated initialCall:NO];
}

- (void)beginUpdates {
	// no function at the moment
	// just to please the code ported from tableview
}

- (void)endUpdates {
	// no function at the moment
	// just to please the code ported from tableview
}

#pragma mark - Selection Handling

- (void)hoverItemAtIndex:(NSInteger)index {
	// inform the delegate
	[self gridView:self willHoverItemAtIndex:index inSection:0];

	lastHoveredIndex = index;
	CNGridViewItem *item = self.keyedVisibleItems[@(index)];
	item.hovered = YES;
}

- (void)unHoverItemAtIndex:(NSInteger)index {
	// inform the delegate
	[self gridView:self willUnhoverItemAtIndex:index inSection:0];

	CNGridViewItem *item = self.keyedVisibleItems[@(index)];
	item.hovered = NO;
}

- (void)selectItemAtIndex:(NSUInteger)selectedItemIndex usingModifierFlags:(NSUInteger)modifierFlags {
	if (selectedItemIndex == NSNotFound)
		return;

	CNGridViewItem *gridViewItem = nil;

	if (lastSelectedItemIndex != NSNotFound && lastSelectedItemIndex != selectedItemIndex) {
		gridViewItem = self.keyedVisibleItems[@(lastSelectedItemIndex)];
		[self deSelectItem:gridViewItem];
	}

	gridViewItem = self.keyedVisibleItems[@(selectedItemIndex)];
	if (gridViewItem) {
        if (!gridViewItem.selected && !(modifierFlags & NSShiftKeyMask) && !(modifierFlags & NSCommandKeyMask)) {
            //Select a single item and deselect all other items when the shift or command keys are NOT pressed.
            [self deselectAllItems];
            [self selectItem:gridViewItem];
        }
        
        else if (gridViewItem.selected && modifierFlags & NSCommandKeyMask) {
            //If the item clicked is already selected and the command key is down, remove it from the selection.
            [self deSelectItem:gridViewItem];
        }
        
        else if (!gridViewItem.selected && modifierFlags & NSCommandKeyMask) {
            //If the item clicked is NOT selected and the command key is down, add it to the selection
            [self selectItem:gridViewItem];
        }
        
        else if (modifierFlags & NSShiftKeyMask) {
            //Select a range of items between the current selection and the item that was clicked when the shift key is down.
            NSUInteger lastIndex = [[self selectedIndexes] lastIndex];
            
            //If there were no previous items selected then
            if (lastIndex == NSNotFound) {
                [self selectItem:gridViewItem];
            }
            else {
                //Find range to select
                NSUInteger high;
                NSUInteger low;
                
                if (((NSInteger)lastIndex - (NSInteger)selectedItemIndex) < 0) {
                    high = selectedItemIndex;
                    low = lastIndex;
                }
                else {
                    high = lastIndex;
                    low = selectedItemIndex;
                }
                high++; //Avoid off by one
                
                //Select all the items that are not already selected
                for (NSUInteger idx = low; idx < high; idx++) {
                    gridViewItem = self.keyedVisibleItems[@(idx)];
                    if (gridViewItem && !gridViewItem.selected) {
                        [self selectItem:gridViewItem];
                    }
                }
            }
        }
        
        else if (gridViewItem.selected) {
            //                [self deselectAllItems];
            [self selectItem:gridViewItem];
        }
		lastSelectedItemIndex = NSNotFound;
	}
}

- (void)selectAllItems {
	NSUInteger number = [self gridView:self numberOfItemsInSection:0];
	for (NSUInteger idx = 0; idx < number; idx++) {
		CNGridViewItem *item = [self gridView:self itemAtIndex:idx inSection:0];
		item.selected = YES;
		item.index = idx;
		[selectedItems setObject:item forKey:@(item.index)];
	}
}

- (void)deselectAllItems {
	if (selectedItems.count > 0) {
		// inform the delegate
		[self gridView:self willDeselectAllItems:[self selectedItems]];

		[nc postNotificationName:CNGridViewDeSelectAllItemsNotification object:self];
		[selectedItems removeAllObjects];

		// inform the delegate
		[self gridViewDidDeselectAllItems:self];
	}
}

- (void)selectItem:(CNGridViewItem *)theItem {
	if (!selectedItems[@(theItem.index)]) {
		// inform the delegate
		[self gridView:self willSelectItemAtIndex:theItem.index inSection:0];

		theItem.selected = YES;
		selectedItems[@(theItem.index)] = theItem;

		// inform the delegate
		[self gridView:self didSelectItemAtIndex:theItem.index inSection:0];
	}
}

- (void)deSelectItem:(CNGridViewItem *)theItem {
	if (selectedItems[@(theItem.index)]) {
		// inform the delegate
		[self gridView:self willDeselectItemAtIndex:theItem.index inSection:0];

		theItem.selected = NO;
		[selectedItems removeObjectForKey:@(theItem.index)];

		// inform the delegate
		[self gridView:self didDeselectItemAtIndex:theItem.index inSection:0];
	}
}

- (NSArray *)selectedItems {
	return [selectedItems allValues];
}

- (NSIndexSet *)selectedIndexes {
	NSMutableIndexSet *mutableIndex = [NSMutableIndexSet indexSet];
	for (CNGridViewItem *gridItem in[self selectedItems]) {
		[mutableIndex addIndex:gridItem.index];
	}
	return mutableIndex;
}

- (NSIndexSet *)visibleIndexes {
	return [NSIndexSet indexSetWithIndexesInRange:[self visibleItemRange]];
}

- (void)handleClicks:(NSTimer *)theTimer {
	switch ([clickEvents count]) {
		case CNSingleClick: {
			NSEvent *theEvent = [clickEvents lastObject];
			NSUInteger index = [self indexForItemAtLocation:theEvent.locationInWindow];
			[self handleSingleClickForItemAtIndex:index];
			break;
		}

		case CNDoubleClick: {
			NSUInteger indexClick1 = [self indexForItemAtLocation:[[clickEvents objectAtIndex:0] locationInWindow]];
			NSUInteger indexClick2 = [self indexForItemAtLocation:[[clickEvents objectAtIndex:1] locationInWindow]];
			if (indexClick1 == indexClick2) {
				[self handleDoubleClickForItemAtIndex:indexClick1];
			}
			else {
				[self handleSingleClickForItemAtIndex:indexClick1];
				[self handleSingleClickForItemAtIndex:indexClick2];
			}
			break;
		}

		case CNTrippleClick: {
			NSUInteger indexClick1 = [self indexForItemAtLocation:[[clickEvents objectAtIndex:0] locationInWindow]];
			NSUInteger indexClick2 = [self indexForItemAtLocation:[[clickEvents objectAtIndex:1] locationInWindow]];
			NSUInteger indexClick3 = [self indexForItemAtLocation:[[clickEvents objectAtIndex:2] locationInWindow]];
			if (indexClick1 == indexClick2 == indexClick3) {
				[self handleDoubleClickForItemAtIndex:indexClick1];
			}

			else if ((indexClick1 == indexClick2) && (indexClick1 != indexClick3)) {
				[self handleDoubleClickForItemAtIndex:indexClick1];
				[self handleSingleClickForItemAtIndex:indexClick3];
			}

			else if ((indexClick1 != indexClick2) && (indexClick2 == indexClick3)) {
				[self handleSingleClickForItemAtIndex:indexClick1];
				[self handleDoubleClickForItemAtIndex:indexClick3];
			}

			else if (indexClick1 != indexClick2 != indexClick3) {
				[self handleSingleClickForItemAtIndex:indexClick1];
				[self handleSingleClickForItemAtIndex:indexClick2];
				[self handleSingleClickForItemAtIndex:indexClick3];
			}
			break;
		}
	}
	[clickEvents removeAllObjects];
}

- (void)handleSingleClickForItemAtIndex:(NSUInteger)selectedItemIndex {
	if (selectedItemIndex == NSNotFound)
		return;

	// inform the delegate
	[self gridView:self didClickItemAtIndex:selectedItemIndex inSection:0];
}

- (void)handleDoubleClickForItemAtIndex:(NSUInteger)selectedItemIndex {
	if (selectedItemIndex == NSNotFound)
		return;

	// inform the delegate
	[self gridView:self didDoubleClickItemAtIndex:selectedItemIndex inSection:0];
}

- (void)drawSelectionFrameForMousePointerAtLocation:(NSPoint)location {
	if (!selectionFrameView) {
		selectionFrameInitialPoint = location;
		selectionFrameView = [CNSelectionFrameView new];
		selectionFrameView.frame = NSMakeRect(location.x, location.y, 0, 0);
        [self addSubview:selectionFrameView];
		if (![self containsSubView:selectionFrameView])
			[self addSubview:selectionFrameView];
	}

	else {
		NSRect clippedRect = [self clippedRect];
		NSUInteger columnsInGridView = [self columnsInGridView];

		CGFloat posX = ceil((location.x > selectionFrameInitialPoint.x ? selectionFrameInitialPoint.x : location.x));
		posX = (posX < NSMinX(clippedRect) ? NSMinX(clippedRect) : posX);

		CGFloat posY = ceil((location.y > selectionFrameInitialPoint.y ? selectionFrameInitialPoint.y : location.y));
		posY = (posY < NSMinY(clippedRect) ? NSMinY(clippedRect) : posY);

		CGFloat width = (location.x > selectionFrameInitialPoint.x ? location.x - selectionFrameInitialPoint.x : selectionFrameInitialPoint.x - posX);
		width = (posX + width >= (columnsInGridView * self.itemSize.width) ? (columnsInGridView * self.itemSize.width) - posX - 1 : width);
       

		CGFloat height = (location.y > selectionFrameInitialPoint.y ? location.y - selectionFrameInitialPoint.y : selectionFrameInitialPoint.y - posY);
		height = (posY + height > NSMaxY(clippedRect) ? NSMaxY(clippedRect) - posY : height);

		NSRect selectionFrame = NSMakeRect(posX, posY, width, height);
		selectionFrameView.frame = selectionFrame;

         NSLog(@"x=%f,y=%f,width=%f,height=%f",selectionFrame.origin.x,selectionFrame.origin.y,selectionFrame.size.width,selectionFrame.size.height);
	}
}

- (NSUInteger)boundIndexForItemAtLocation:(NSPoint)location {
	NSPoint point = [self convertPoint:location fromView:nil];
	NSUInteger indexForItemAtLocation;
	CGFloat currentWidth = (self.itemSize.width * [self columnsInGridView]);

	if (point.x > currentWidth)
		point.x = currentWidth;

	NSUInteger currentColumn = floor(point.x / self.itemSize.width);
	NSUInteger currentRow = floor(point.y / self.itemSize.height);
	indexForItemAtLocation = currentRow * [self columnsInGridView] + currentColumn;

	return indexForItemAtLocation;
}

- (void)selectItemsCoveredBySelectionFrame:(NSRect)selectionFrame usingModifierFlags:(NSUInteger)modifierFlags {
	NSUInteger topLeftItemIndex = [self boundIndexForItemAtLocation:[self convertPoint:NSMakePoint(NSMinX(selectionFrame), NSMinY(selectionFrame)) toView:nil]];
	NSUInteger bottomRightItemIndex = [self boundIndexForItemAtLocation:[self convertPoint:NSMakePoint(NSMaxX(selectionFrame), NSMaxY(selectionFrame)) toView:nil]];

	CNItemPoint topLeftItemPoint = [self locationForItemAtIndex:topLeftItemIndex];
	CNItemPoint bottomRightItemPoint = [self locationForItemAtIndex:bottomRightItemIndex];

	// handle all "by selection frame" selected items beeing now outside
	// the selection frame
	[[self indexesForVisibleItems] enumerateIndexesUsingBlock: ^(NSUInteger idx, BOOL *stop) {
	    CNGridViewItem *selectedItem = selectedItems[@(idx)];
	    CNGridViewItem *selectionFrameItem = self.selectedItemsBySelectionFrame[@(idx)];
	    if (selectionFrameItem) {
	        CNItemPoint itemPoint = [self locationForItemAtIndex:selectionFrameItem.index];

	        // handle all 'out of selection frame range' items
	        if ((itemPoint.row < topLeftItemPoint.row)              ||  // top edge out of range
	            (itemPoint.column > bottomRightItemPoint.column)    ||  // right edge out of range
	            (itemPoint.row > bottomRightItemPoint.row)          ||  // bottom edge out of range
	            (itemPoint.column < topLeftItemPoint.column)) {         // left edge out of range
	                                                                    // ok. before we deselect this item, lets take a look into our `self.keyedVisibleItems`
	                                                                    // if it there is selected too. If it so, keep it untouched!

	            // so, the current item wasn't selected, we can restore its old state (to unselected)
	            if (![selectionFrameItem isEqual:selectedItem]) {
	                selectionFrameItem.selected = NO;
	                [self.selectedItemsBySelectionFrame removeObjectForKey:@(selectionFrameItem.index)];
				}

	            // the current item already was selected, so reselect it.
	            else {
	                selectionFrameItem.selected = YES;
	                self.selectedItemsBySelectionFrame[@(selectionFrameItem.index)] = selectionFrameItem;
				}
			}
		}
	}];

	// Verify selection frame was inside gridded area
	BOOL validSelectionFrame = (NSWidth(selectionFrame) > 0) && (NSHeight(selectionFrame) > 0);

	NSUInteger columnsInGridView = [self columnsInGridView];
	NSUInteger allOverRows = ceilf((float)numberOfItems / columnsInGridView);

	topLeftItemPoint.row = MIN(topLeftItemPoint.row, allOverRows);
	topLeftItemPoint.column = MIN(topLeftItemPoint.column, columnsInGridView);
	bottomRightItemPoint.row = MIN(bottomRightItemPoint.row, allOverRows);
	bottomRightItemPoint.column = MIN(bottomRightItemPoint.column, columnsInGridView);

	// update all items that needs to be selected
	for (NSUInteger row = topLeftItemPoint.row; row <= bottomRightItemPoint.row; row++) {
		for (NSUInteger col = topLeftItemPoint.column; col <= bottomRightItemPoint.column; col++) {
			NSUInteger itemIndex = ((row - 1) * columnsInGridView + col) - 1;
			CNGridViewItem *selectedItem = selectedItems[@(itemIndex)];
			CNGridViewItem *itemToSelect = self.keyedVisibleItems[@(itemIndex)];
			if (itemToSelect && validSelectionFrame) {
				self.selectedItemsBySelectionFrame[@(itemToSelect.index)] = itemToSelect;
				if (modifierFlags & NSCommandKeyMask) {
					itemToSelect.selected = ([itemToSelect isEqual:selectedItem] ? NO : YES);
				}
				else {
					itemToSelect.selected = YES;
				}
			}
		}
	}
}

#pragma mark - Managing the Content

- (NSUInteger)numberOfVisibleItems {
	return [self.keyedVisibleItems count];
}

#pragma mark - NSView

- (BOOL)isFlipped {
	return YES;
}

- (void)setFrame:(NSRect)frameRect {
	BOOL animated = (self.frame.size.width == frameRect.size.width ? NO : YES);
	[super setFrame:frameRect];
	[self refreshGridViewAnimated:animated initialCall:YES];
}

- (void)updateTrackingAreas {
	if (gridViewTrackingArea)
		[self removeTrackingArea:gridViewTrackingArea];

	gridViewTrackingArea = nil;
	gridViewTrackingArea = [[NSTrackingArea alloc] initWithRect:self.frame
	                                                    options:NSTrackingMouseMoved | NSTrackingActiveInKeyWindow
	                                                      owner:self
	                                                   userInfo:nil];
	[self addTrackingArea:gridViewTrackingArea];
}

#pragma mark - NSResponder

- (BOOL)canBecomeKeyView {
	return YES;
}

- (BOOL)acceptsFirstResponder {
	return YES;
}


#pragma mark - 鼠标 左键 按下

- (void)mouseDown:(NSEvent *)theEvent {

    NSPoint location = [theEvent locationInWindow];
    self.mouseDownPoint = location;
    NSUInteger index = [self indexForItemAtLocation:location];
    //已经选中的item 索引集合
    NSIndexSet *selectedIndexes =  [self selectedIndexes];
    //假设：已经选中的item 索引集合 包含了 现在按下区域所指向的item 索引，那么不做任何处理。
    if (![selectedIndexes containsIndex:index]) {
        //移除所有选中items
        [self deselectAllItems];
        if (index != NSNotFound) {
            //选中item
            [self selectItemAtIndex:index usingModifierFlags:theEvent.modifierFlags];
        }else{
            [self deselectAllItems];
        }
    }
    
}


- (void)mouseMoved:(NSEvent *)theEvent {

	NSUInteger hoverItemIndex = [self indexForItemAtLocation:theEvent.locationInWindow];
	if (hoverItemIndex != NSNotFound || hoverItemIndex != lastHoveredIndex) {
		// unhover the last hovered item
		if (lastHoveredIndex != NSNotFound && lastHoveredIndex != hoverItemIndex) {
			[self unHoverItemAtIndex:lastHoveredIndex];
		}

		// inform the delegate
		if (lastHoveredIndex != hoverItemIndex) {
			[self hoverItemAtIndex:hoverItemIndex];
		}
	}
}

- (void)mouseDragged:(NSEvent *)theEvent {

	[NSCursor closedHandCursor];
    
    NSPoint location = [self convertPoint:[theEvent locationInWindow] fromView:nil];

    NSUInteger index = [self indexForItemAtLocation:self.mouseDownPoint];
    NSIndexSet *selectedIndexes = [self selectedIndexes];
    if ([selectedIndexes containsIndex:index]) {
        [self beginDragging:theEvent];
    }else{
        [self drawSelectionFrameForMousePointerAtLocation:location];
        [self selectItemsCoveredBySelectionFrame:selectionFrameView.frame usingModifierFlags:theEvent.modifierFlags];
    }



}

- (void)mouseUp:(NSEvent *)theEvent {
	[NSCursor arrowCursor];
    // remove selection frame
    [[selectionFrameView animator] setAlphaValue:0];
    [selectionFrameView removeFromSuperview];
    selectionFrameView = nil;
    
    // catch all newly selected items that was selected by selection frame
    [self.selectedItemsBySelectionFrame enumerateKeysAndObjectsUsingBlock: ^(id key, CNGridViewItem *item, BOOL *stop) {
        if ([item selected] == YES) {
            [self selectItem:item];
        }
        else {
            [self deSelectItem:item];
        }
    }];
    [self.selectedItemsBySelectionFrame removeAllObjects];
    
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event{
    return YES;
}

//拖出
- (void)pasteboard:(nullable NSPasteboard *)pasteboard item:(NSPasteboardItem *)item provideDataForType:(NSString *)type {
    [pasteboard clearContents];
    NSArray <CNGridViewItem *> *gridViewItems = [self selectedItems];
    NSMutableArray *writeObjects = [NSMutableArray arrayWithCapacity:gridViewItems.count];
    for (CNGridViewItem *gridViewItem  in gridViewItems) {
        [writeObjects addObject:[NSURL fileURLWithPath:gridViewItem.imageModel.path]];
        NSLog(@"provideDataForType:%@",type);
    }
     [pasteboard writeObjects:writeObjects];
    
    
}

//发送方：定义允许的拖放操作
- (NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context {
    switch (context) {
        case NSDraggingContextOutsideApplication:
            return NSDragOperationCopy;
        case NSDraggingContextWithinApplication:
        default:
            return NSDragOperationCopy;
            break;
    }
}



#pragma mark - 鼠标 右键按下


- (void)rightMouseDown:(NSEvent *)theEvent {
	NSPoint location = [theEvent locationInWindow];
	NSUInteger index = [self indexForItemAtLocation:location];

	if (index != NSNotFound) {
		NSIndexSet *indexSet = [self selectedIndexes];
		BOOL isClickInSelection = [indexSet containsIndex:index];

		if (!isClickInSelection) {
			indexSet = [NSIndexSet indexSetWithIndex:index];
			[self deselectAllItems];
			CNGridViewItem *item = self.keyedVisibleItems[@(index)];
			[self selectItem:item];
		}

		if (_itemContextMenu) {
			NSEvent *fakeMouseEvent = [NSEvent mouseEventWithType:NSRightMouseDown
			                                             location:location
			                                        modifierFlags:0
			                                            timestamp:0
			                                         windowNumber:[self.window windowNumber]
			                                              context:nil
			                                          eventNumber:0
			                                           clickCount:0
			                                             pressure:0];

			for (NSMenuItem *menuItem in _itemContextMenu.itemArray) {
				[menuItem setRepresentedObject:indexSet];
			}
			[NSMenu popUpContextMenu:_itemContextMenu withEvent:fakeMouseEvent forView:self];

			// inform the delegate
			[self gridView:self didActivateContextMenuWithIndexes:indexSet inSection:0];
		}
	}
	else {
		[self deselectAllItems];
	}
}

- (void)mouseExited:(NSEvent *)theEvent {
    lastHoveredIndex = NSNotFound;
}

- (void)keyDown:(NSEvent *)theEvent {
    NSLog(@"键盘事件code=%d",[theEvent keyCode]);
    [super keyDown:theEvent];
}

#pragma mark - 私有方法


- (void)beginDragging:(NSEvent *)theEvent {
    
    NSArray <CNGridViewItem *> *items = [self selectedItems];
    NSMutableArray *dragItems = [NSMutableArray arrayWithCapacity:items.count];
    for (CNGridViewItem *gridViewItem in items) {
        //准备拖拽
        NSPasteboardItem *pbItem = [NSPasteboardItem new];
        __weak typeof(self) weakSelf = self;
        [pbItem setDataProvider:weakSelf forTypes:[NSArray arrayWithObjects:@"public.file-url", nil]];
        
        NSDraggingItem *dragItem = [[NSDraggingItem alloc] initWithPasteboardWriter:pbItem];
        
        NSRect draggingRect = [self rectForItemAtIndex:gridViewItem.index];
        [dragItem setDraggingFrame:draggingRect contents:gridViewItem.imageModel.image];
        [dragItems addObject:dragItem];
    }
    NSDraggingSession *draggingSession = [self beginDraggingSessionWithItems:dragItems event:theEvent source:self];
    draggingSession.animatesToStartingPositionsOnCancelOrFail = YES;
    draggingSession.draggingFormation = NSDraggingFormationNone;
}

#pragma mark - NSDraggingDestination 接收方

//拖放进入目标区
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    NSLog(@"拖放进入目标区");
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSCursor dragCopyCursor] set];
    });
    
    [self setNeedsDisplay:YES];
    
    NSDragOperation sourceDragMask = [sender draggingSourceOperationMask];
    NSPasteboard *pboard = [sender draggingPasteboard];
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
        if (sourceDragMask & NSDragOperationLink) {
            return NSDragOperationCopy;//可被拷贝
        }
    }
    return NSDragOperationNone;
}


//拖放预处理,一般是根据拖放类型type，决定是否接受拖放。
- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
    
    if ( [sender draggingSource] != self ) {
        BOOL canInit = [NSImage canInitWithPasteboard: [sender draggingPasteboard]];
        //例如是否可以初始化为图片
        return canInit;
    }
    return NO;
    

}


//允许接收拖放，开始接收处理拖放数据
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    NSLog(@"执行拖放处理");
    NSPasteboard *pboard = [sender draggingPasteboard];
    //文件包含Pboard 类型
    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        NSInteger numberOfFiles = [files count];
        if(numberOfFiles>0)
        {
            if (self.dropInBlock) {
                self.dropInBlock(files);
            }
            return YES;
        }
        
    }
    return YES;
    
}

//拖放退出目标区,拖放的图像会弹回到拖放源
- (void)draggingExited:(nullable id <NSDraggingInfo>)sender {
    NSLog(@"拖放退出");
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSCursor arrowCursor] set];
    });
    
}


- (void)draggingEnded:(id <NSDraggingInfo>)sender {
    NSLog(@"拖放结束");
    NSPasteboard *pasteboard = [sender draggingPasteboard];
    [pasteboard clearContents];
}

#pragma mark - CNGridView Delegate Calls

- (void)gridView:(CNGridView *)gridView willHoverItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section {
	[nc postNotificationName:CNGridViewWillHoverItemNotification
	                  object:gridView
	                userInfo:[NSDictionary dictionaryWithObject:@(index) forKey:CNGridViewItemIndexKey]];
	if ([self.delegate respondsToSelector:_cmd]) {
		[self.delegate gridView:gridView willHoverItemAtIndex:index inSection:section];
	}
}

- (void)gridView:(CNGridView *)gridView willUnhoverItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section {
	[nc postNotificationName:CNGridViewWillUnhoverItemNotification
	                  object:gridView
	                userInfo:[NSDictionary dictionaryWithObject:@(index) forKey:CNGridViewItemIndexKey]];
	if ([self.delegate respondsToSelector:_cmd]) {
		[self.delegate gridView:gridView willUnhoverItemAtIndex:index inSection:section];
	}
}

- (void)gridView:(CNGridView *)gridView willSelectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section {
	[nc postNotificationName:CNGridViewWillSelectItemNotification
	                  object:gridView
	                userInfo:[NSDictionary dictionaryWithObject:@(index) forKey:CNGridViewItemIndexKey]];
	if ([self.delegate respondsToSelector:_cmd]) {
		[self.delegate gridView:gridView willSelectItemAtIndex:index inSection:section];
	}
}

- (void)gridView:(CNGridView *)gridView didSelectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section {
	[nc postNotificationName:CNGridViewDidSelectItemNotification
	                  object:gridView
	                userInfo:[NSDictionary dictionaryWithObject:@(index) forKey:CNGridViewItemIndexKey]];
	if ([self.delegate respondsToSelector:_cmd]) {
		[self.delegate gridView:gridView didSelectItemAtIndex:index inSection:section];
	}
}

- (void)gridView:(CNGridView *)gridView willDeselectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section {
	[nc postNotificationName:CNGridViewWillDeselectItemNotification
	                  object:gridView
	                userInfo:[NSDictionary dictionaryWithObject:@(index) forKey:CNGridViewItemIndexKey]];
	if ([self.delegate respondsToSelector:_cmd]) {
		[self.delegate gridView:gridView willDeselectItemAtIndex:index inSection:section];
	}
}

- (void)gridView:(CNGridView *)gridView didDeselectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section {
	[nc postNotificationName:CNGridViewDidDeselectItemNotification
	                  object:gridView
	                userInfo:[NSDictionary dictionaryWithObject:@(index) forKey:CNGridViewItemIndexKey]];
	if ([self.delegate respondsToSelector:_cmd]) {
		[self.delegate gridView:gridView didDeselectItemAtIndex:index inSection:section];
	}
}

- (void)gridView:(CNGridView *)gridView willDeselectAllItems:(NSArray *)theSelectedItems {
	[nc postNotificationName:CNGridViewWillDeselectAllItemsNotification
	                  object:gridView
	                userInfo:[NSDictionary dictionaryWithObject:theSelectedItems forKey:CNGridViewSelectedItemsKey]];
	if ([self.delegate respondsToSelector:_cmd]) {
		[self.delegate gridView:gridView willDeselectAllItems:theSelectedItems];
	}
}

- (void)gridViewDidDeselectAllItems:(CNGridView *)gridView {
	[nc postNotificationName:CNGridViewDidDeselectAllItemsNotification object:gridView userInfo:nil];
	if ([self.delegate respondsToSelector:_cmd]) {
		[self.delegate gridViewDidDeselectAllItems:gridView];
	}
}

- (void)gridView:(CNGridView *)gridView didClickItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section {
	[nc postNotificationName:CNGridViewDidClickItemNotification
	                  object:gridView
	                userInfo:[NSDictionary dictionaryWithObject:@(index) forKey:CNGridViewItemIndexKey]];
	if ([self.delegate respondsToSelector:_cmd]) {
		[self.delegate gridView:gridView didClickItemAtIndex:index inSection:section];
	}
}

- (void)gridView:(CNGridView *)gridView didDoubleClickItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section {
	[nc postNotificationName:CNGridViewDidDoubleClickItemNotification
	                  object:gridView
	                userInfo:[NSDictionary dictionaryWithObject:@(index) forKey:CNGridViewItemIndexKey]];
	if ([self.delegate respondsToSelector:_cmd]) {
		[self.delegate gridView:gridView didDoubleClickItemAtIndex:index inSection:section];
	}
}

- (void)gridView:(CNGridView *)gridView didActivateContextMenuWithIndexes:(NSIndexSet *)indexSet inSection:(NSUInteger)section {
	[nc postNotificationName:CNGridViewRightMouseButtonClickedOnItemNotification
	                  object:gridView
	                userInfo:[NSDictionary dictionaryWithObject:indexSet forKey:CNGridViewItemsIndexSetKey]];
	if ([self.delegate respondsToSelector:_cmd]) {
		[self.delegate gridView:gridView didActivateContextMenuWithIndexes:indexSet inSection:section];
	}
}

#pragma mark - CNGridView DataSource Calls

- (NSUInteger)gridView:(CNGridView *)gridView numberOfItemsInSection:(NSInteger)section {
	if ([self.dataSource respondsToSelector:_cmd]) {
		return [self.dataSource gridView:gridView numberOfItemsInSection:section];
	}
	return NSNotFound;
}


- (CNGridViewItem *)gridView:(CNGridView *)gridView itemAtIndex:(NSInteger)index inSection:(NSInteger)section {
	if ([self.dataSource respondsToSelector:_cmd]) {
		return [self.dataSource gridView:gridView itemAtIndex:index inSection:section];
	}
	return nil;
}

- (NSUInteger)numberOfSectionsInGridView:(CNGridView *)gridView {
	if ([self.dataSource respondsToSelector:_cmd]) {
		return [self.dataSource numberOfSectionsInGridView:gridView];
	}
	return NSNotFound;
}

- (NSString *)gridView:(CNGridView *)gridView titleForHeaderInSection:(NSInteger)section {
	if ([self.dataSource respondsToSelector:_cmd]) {
		return [self.dataSource gridView:gridView titleForHeaderInSection:section];
	}
	return nil;
}

- (NSArray *)sectionIndexTitlesForGridView:(CNGridView *)gridView {
	if ([self.dataSource respondsToSelector:_cmd]) {
		return [self.dataSource sectionIndexTitlesForGridView:gridView];
	}
	return nil;
}

@end




#pragma mark - CNSelectionFrameView

@implementation CNSelectionFrameView

- (void)drawRect:(NSRect)rect {
	NSRect dirtyRect = NSMakeRect(0.5, 0.5, floorf(NSWidth(self.bounds)) - 1, floorf(NSHeight(self.bounds)) - 1);
	NSBezierPath *selectionFrame = [NSBezierPath bezierPathWithRoundedRect:dirtyRect xRadius:0 yRadius:0];
    [[[NSColor blackColor] colorWithAlphaComponent:0.1] setFill];
	[selectionFrame fill];
	[[NSColor whiteColor] set];
	[selectionFrame setLineWidth:1];
	[selectionFrame stroke];
}

- (BOOL)isFlipped {
	return YES;
}

@end
#pragma clang diagnostic pop
