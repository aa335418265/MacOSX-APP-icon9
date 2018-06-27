//
//  NSMainWinController.m
//  icons9
//
//  Created by fenglh on 2018/6/26.
//  Copyright © 2018年 冯立海. All rights reserved.
//

#import "NSMainWinController.h"
#import "BackgroundView.h"

#import "CNGridViewItemLayout.h"
#import "CNGridViewItem.h"
#import "CNGridView.h"
#import "BMIconManager.h"
#import "BMProjectCell.h"
#import <SVGKit/SVGKit.h>
#import <UIImageView+WebCache.h>

static NSString *kItemSizeSliderPositionKey = @"ItemSizeSliderPosition";

@interface NSMainWinController ()<NSSplitViewDelegate, CNGridViewDelegate, CNGridViewDataSource, NSTableViewDataSource,NSTableViewDelegate>
@property (nonatomic, retain) IBOutlet NSSplitView *container;
@property (nonatomic, retain) IBOutlet NSView *left;
@property (nonatomic, retain) IBOutlet NSView *middle;
@property (nonatomic, retain) IBOutlet NSView *right;
@property (nonatomic, retain) IBOutlet NSView *inspector;
@property (weak) IBOutlet NSSegmentedCell *segment;

@property (nonatomic, assign) BOOL inspectorExpanded; ///<
@property (nonatomic, assign) BOOL outlineExpanded; ///<
@property (nonatomic, assign) BOOL logExpanded; ///<


@property (weak) IBOutlet CNGridView *gridView;
@property (weak) IBOutlet NSSlider *itemSizeSlider;
@property (strong) NSMutableArray<BMIconModel *> *items;
@property (strong) NSMutableArray <BMSQLProjectModel *>*projects;
@property (weak) IBOutlet NSTableView *tableView;


@property (strong) CNGridViewItemLayout *defaultLayout; //默认样式
@property (strong) CNGridViewItemLayout *hoverLayout;   //鼠标悬停样式
@property (strong) CNGridViewItemLayout *selectedLayout;   //选中样式

@property (nonatomic, assign) BMImageType selectedFilteredImageType; ///< 选中已过滤的图片类型
@property (nonatomic, assign) NSInteger selectedGroupIndex; //选中的组别
@property (nonatomic, strong) NSMutableDictionary *iconsUpdateList; ///< 更新列表


@end

@implementation NSMainWinController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    [self initLocalData];
    [self initUI];
    [self addNotification];
    
    //更新项目组
    [[BMIconManager sharedInstance] updateProjects:^(BOOL success, NSArray<BMSQLProjectModel *> *projects) {
        if (success && projects.count >0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.projects removeAllObjects];
                self.projects = [projects mutableCopy];
                [self.tableView reloadData];
                //检查项目下的素材是否有更新
                for (BMSQLProjectModel *model in projects) {
                    
                    NSString *updateMD5 = [[BMIconManager sharedInstance] caculateLocalUpdateMD5InProject:model.projectId];
                    //1. 计算每个项目中的素材的总hash
                    [[BMIconManager sharedInstance] getIconsUpdateList:updateMD5 projectId:model.projectId success:^(NSArray *list) {
                        //本地与远程iconsMd5列表差异比较
                        NSArray *localIconsMd5List = [[BMIconManager sharedInstance] getLocalIconsMD5ListInProject:model.projectId];
                        
                        NSPredicate * filterPredicate1 = [NSPredicate predicateWithFormat:@"NOT (SELF IN %@)",localIconsMd5List];
                        NSArray * addList = [list filteredArrayUsingPredicate:filterPredicate1];
                        NSLog(@"有%lu个素材需要更新", (unsigned long)addList.count);
                        [self.iconsUpdateList setObject:addList forKey:model.projectId];
                        [self.tableView reloadData];
                        
                        
                        NSPredicate * filterPredicate2 = [NSPredicate predicateWithFormat:@"NOT (SELF IN %@)",list];
                        NSArray * delList = [localIconsMd5List filteredArrayUsingPredicate:filterPredicate2];
                        NSLog(@"有%lu个素材需要删除", (unsigned long)delList.count);
                        
                        if (list.count >0) {
                            //接口待完善
                            NSLog(@"projectHash:%@, projectId:%@,有更新",model.projectHash, model.projectId);
                        }
                    } failure:^(NSError *error) {
                        //
                        NSLog(@"检查更新接口失败");
                    }];
                }
            });
        }
    }];
    
}



#pragma mark - UI初始化

#pragma mark - 设置UI

- (void)initLocalData {
    
    self.items = [NSMutableArray array];
    self.projects = [NSMutableArray array];
    self.selectedGroupIndex = 0;    //默认当前选中group
    self.selectedFilteredImageType = BMImageTypeSVG;//当前选中要已过滤的图片类型,即要显示的类型
    
    NSArray *groups = [[[BMIconManager sharedInstance] allGroups] copy];
    if (groups.count <=0) {
        return;
    }
    [self.projects addObjectsFromArray:groups];
    BMSQLProjectModel * group = [self.projects objectAtIndex:self.selectedGroupIndex];
    if (group && groups.count > 0) {
        //选中
        [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:self.selectedGroupIndex] byExtendingSelection:YES];
        self.items =[NSMutableArray arrayWithArray:[[group objectsWithType:self.selectedFilteredImageType] copy]];
    }
}


- (void)initUI {
    
    self.tableView.rowHeight = 44;
    
    [self.tableView registerNib:[[NSNib alloc] initWithNibNamed:@"BMProjectCell" bundle:nil] forIdentifier:@"BMProjectCell"];
    self.defaultLayout = [CNGridViewItemLayout defaultLayout];
    self.defaultLayout.itemTitleTextAttributes = @{NSForegroundColorAttributeName : [NSColor colorWithRed:71/255.0 green:88/255.0 blue:96/255.0 alpha:1],NSFontAttributeName:[NSFont systemFontOfSize:12.0f]};
    self.hoverLayout = [CNGridViewItemLayout defaultLayout];
    self.selectedLayout = [CNGridViewItemLayout defaultLayout];
    self.selectedLayout.backgroundColor =  [[NSColor lightGrayColor] colorWithAlphaComponent:0.42];
    self.hoverLayout.backgroundColor = [[NSColor lightGrayColor] colorWithAlphaComponent:0.42];
    
    //初始化NSUserDefaults 数据
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults integerForKey:kItemSizeSliderPositionKey]) {
        self.itemSizeSlider.integerValue = [defaults integerForKey:kItemSizeSliderPositionKey];
    }
    self.gridView.dropInBlock = ^(NSArray<NSString *> *files) {
        BMSQLProjectModel * group = [self.projects objectAtIndex:self.selectedGroupIndex];
        NSArray *copyIcons = [group copyFilesFromPaths:files];
        if (copyIcons.count > 0) {
            [self.items addObjectsFromArray:copyIcons];
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(self.items.count, files.count)];
            [self.gridView insertItemsAtIndexes:indexSet animated:YES];
        }
    };
    self.gridView.itemSize = NSMakeSize(self.itemSizeSlider.integerValue, self.itemSizeSlider.integerValue);
    self.gridView.backgroundColor = [NSColor whiteColor];
    self.gridView.gridViewTitle = @"素材管理";
    [self.gridView reloadData];
    NSLog(@"%@", self.gridView);
    
}

- (void)addNotification {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(detectedNotification:) name:CNGridViewWillHoverItemNotification object:nil];
    [nc addObserver:self selector:@selector(detectedNotification:) name:CNGridViewWillUnhoverItemNotification object:nil];
    [nc addObserver:self selector:@selector(detectedNotification:) name:CNGridViewWillSelectItemNotification object:nil];
    [nc addObserver:self selector:@selector(detectedNotification:) name:CNGridViewDidSelectItemNotification object:nil];
    [nc addObserver:self selector:@selector(detectedNotification:) name:CNGridViewWillDeselectItemNotification object:nil];
    [nc addObserver:self selector:@selector(detectedNotification:) name:CNGridViewDidDeselectItemNotification object:nil];
    [nc addObserver:self selector:@selector(detectedNotification:) name:CNGridViewDidClickItemNotification object:nil];
    [nc addObserver:self selector:@selector(detectedNotification:) name:CNGridViewDidDoubleClickItemNotification object:nil];
    [nc addObserver:self selector:@selector(detectedNotification:) name:CNGridViewRightMouseButtonClickedOnItemNotification object:nil];
}



#pragma mark - 通知事件



- (void)detectedNotification:(NSNotification *)notif {
    //    CNLog(@"notification: %@", notif);
}
#pragma mark - splitview

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview
{
    return YES;
}


- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex
{
    if (dividerIndex == 0) {
        return 200;
    }
    else if (dividerIndex == 1)
    {
        return self.window.frame.size.width - 320;
    }
    return 200;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex
{
    if (dividerIndex == 0) {
        return 400;
    }
    else if (dividerIndex == 1)
    {
        return self.window.frame.size.width - 320;
    }
    return 300;
}

- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)view
{
    if (view == self.left)
    {
        if (view.frame.size.width <= 200) {
            return NO;
        }
    }
    
    return YES;
}

#pragma mark - CNGridView DataSource

- (NSUInteger)gridView:(CNGridView *)gridView numberOfItemsInSection:(NSInteger)section {
    return self.items.count;
}

- (CNGridViewItem *)gridView:(CNGridView *)gridView itemAtIndex:(NSInteger)index inSection:(NSInteger)section  {
    static NSString *reuseIdentifier = @"CNGridViewItem";
    CNGridViewItem *item = [gridView dequeueReusableItemWithIdentifier:reuseIdentifier];
    if (item == nil) {
        item = [[CNGridViewItem alloc] initWithLayout:self.defaultLayout reuseIdentifier:reuseIdentifier];
    }
    item.hoverLayout = self.hoverLayout;
    item.selectionLayout = self.selectedLayout;
    item.imageModel = self.items[index];
    return item;
}

#pragma mark - CNGridView Delegate

- (void)gridView:(CNGridView *)gridView didClickItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section {
    NSLog(@"didClickItemAtIndex: %li", index);
}

- (void)gridView:(CNGridView *)gridView didDoubleClickItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section {
    NSLog(@"didDoubleClickItemAtIndex: %li", index);
}

- (void)gridView:(CNGridView *)gridView didActivateContextMenuWithIndexes:(NSIndexSet *)indexSet inSection:(NSUInteger)section {
    NSLog(@"rightMouseButtonClickedOnItemAtIndex: %@", indexSet);
}

- (void)gridView:(CNGridView *)gridView didSelectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section {
    NSLog(@"didSelectItemAtIndex: %li", index);
}

- (void)gridView:(CNGridView *)gridView didDeselectItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section {
    NSLog(@"didDeselectItemAtIndex: %li", index);
}


#pragma mark -  NSTableViewDelegate

//选中
- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    
    [self.gridView deselectAllItems];
    NSInteger selectedRow = [self.tableView selectedRow];
    if (selectedRow < 0 ||  selectedRow == self.selectedGroupIndex) {
        return;
    }
    
    //先删除
    [self.items removeAllObjects];
    [self.gridView reloadDataAnimated:YES];
    //后更新
    BMSQLProjectModel *group = self.projects[selectedRow];
    NSArray *objects = [[group objectsWithType:self.selectedFilteredImageType] copy];
    if (objects.count > 0) {
        [self.items addObjectsFromArray:objects];
        [self.gridView reloadDataAnimated:YES];
    }
    self.selectedGroupIndex = selectedRow;
    
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.projects.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    //根据ID取视图
    
    BMProjectCell *cell = [tableView makeViewWithIdentifier:@"BMProjectCell" owner:self];
    BMSQLProjectModel * group = [self.projects objectAtIndex:row];
    cell.nameLabel.stringValue = group.projectName;
    cell.clickBlock = ^{
        NSLog(@"项目%@点击了更新按钮", group.projectId);
        [[BMIconManager sharedInstance] updateIcons:self.iconsUpdateList[group.projectId] projectName:group.projectName];
    };
    NSArray *updateList = self.iconsUpdateList[group.projectId];
    cell.badgeValue = updateList.count;
    [cell.folderImageView sd_setImageWithURL:[NSURL URLWithString:group.projectPicUrl] placeholderImage:[NSImage imageNamed:@"sucai2"] completed:^(NSImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
        NSLog(@"完成");
    }];
    return cell;
}



#pragma mark - 按钮事件
-(IBAction)expandPanelActions:(id)sender
{
    BOOL left_segment = [self.segment isSelectedForSegment:0];
    BOOL middle_segment = [self.segment isSelectedForSegment:1];
    BOOL right_segment = [self.segment isSelectedForSegment:2];
    
    [self expandNavigatorAction:left_segment];
//    [self expandLogPannel:middle_segment];
    [self expandInspectorAction:right_segment];
}

//slider 滑动
- (IBAction)itemSizeSliderAction:(id)sender {
    self.gridView.itemSize = NSMakeSize(self.itemSizeSlider.integerValue, self.itemSizeSlider.integerValue);
    //缓存到本地
    [[NSUserDefaults standardUserDefaults] setInteger:self.itemSizeSlider.integerValue forKey:kItemSizeSliderPositionKey];
}

- (IBAction)didPopButtonAction:(id)sender {
    
    NSPopUpButton *popBtn = (NSPopUpButton *)sender;
    BMImageType imageType = [self imageTypeWithIndexOfSelectedItem:popBtn.indexOfSelectedItem];
    if (self.selectedFilteredImageType == imageType) {
        return;
    }
    
    self.selectedFilteredImageType = imageType;
    //先删除
    [self.items removeAllObjects];
    [self.gridView reloadDataAnimated:YES];
    //后更新
    BMSQLProjectModel *group = self.projects[self.selectedGroupIndex];
    NSArray *objects = [[group objectsWithType:imageType] copy];
    if (objects.count > 0) {
        [self.items addObjectsFromArray:objects];
        [self.gridView reloadDataAnimated:YES];
    }
    
}
#pragma mark - 私有方法

- (BMImageType)imageTypeWithIndexOfSelectedItem:(NSInteger)index {
    BMImageType imageType = BMImageTypeUnknown;
    switch (index) {
        case 0:
            imageType =  BMImageTypeSVG;
            break;
        case 1:
            imageType =  BMImageTypePNG;
            break;
        case 2:
            imageType =  BMImageTypeJPG;
            break;
        case 3:
            imageType =  BMImageTypeAll;
            break;
        default:
            break;
    }
    return imageType;
}

-(void)expandInspectorAction:(BOOL)selected
{
    if (selected == self.inspectorExpanded) {
        return ;
    }
    
    if (!selected) {
        self.middle.frame = self.right.bounds;
        CGRect r = self.inspector.frame;
        r.size.width = 0;
        r.origin.x = self.right.frame.size.width;
        self.inspector.frame = r;
    }
    else
    {
        CGRect r = self.inspector.frame;
        r.size.width = 320;
        r.origin.x = self.right.frame.size.width - 320;
        self.inspector.frame = r;
        
        r = self.middle.frame;
        r.size.width = self.right.frame.size.width - 320;
        self.middle.frame = r;
    }
    
    self.inspectorExpanded = selected;
}

-(void)expandNavigatorAction:(BOOL)selected
{
    if (self.outlineExpanded == selected) {
        return ;
    }
    
    if (selected) {
        [self.container setPosition:200 ofDividerAtIndex:0];
        NSRect r = self.container.frame;
        r.size.width = self.window.frame.size.width;
        self.container.frame = r;
    }
    else
    {
        [self.container setPosition:0 ofDividerAtIndex:0];
        NSRect r = self.container.frame;
        r.size.width = self.window.frame.size.width;
        self.container.frame = r;
    }
    
    self.outlineExpanded = selected;
}

//-(void)expandLogPannel:(BOOL)selected
//{
//    if (self.logExpanded == selected) {
//        return ;
//    }
//
//    NSSplitView *dsv = (NSSplitView*)self.dataMappingController.view;
//    if (selected) {
//        [dsv setPosition:dsv.frame.size.height - 200 ofDividerAtIndex:0];
//    }
//    else
//    {
//        [dsv setPosition:dsv.frame.size.height - 80 ofDividerAtIndex:0];
//    }
//
//    self.logExpanded = selected;
//}
#pragma mark - getters
- (NSMutableDictionary *)iconsUpdateList {
    if (_iconsUpdateList == nil) {
        _iconsUpdateList = [NSMutableDictionary dictionary];
    }
    return _iconsUpdateList;
}



@end
