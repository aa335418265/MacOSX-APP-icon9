//
//  BMMainViewController.m
//  icons9
//
//  Created by 冯立海 on 2018/3/4.
//  Copyright © 2018年 冯立海. All rights reserved.
//

#import "BMMainViewController.h"

#import "CNGridViewItemLayout.h"
#import "CNGridViewItem.h"
#import "CNGridView.h"
#import "BMIconManager.h"
#import "BMProjectCell.h"

//#import "BMFileModel.h"


static NSString *kItemSizeSliderPositionKey;

@interface BMMainViewController ()<CNGridViewDelegate, CNGridViewDataSource, NSTableViewDataSource,NSTableViewDelegate>

@property (weak) IBOutlet CNGridView *gridView;
@property (weak) IBOutlet NSSlider *itemSizeSlider;
@property (strong) NSMutableArray<BMIconModel *> *items;
@property (strong) NSMutableArray <BMIconGroupModel *>*groups;
@property (weak) IBOutlet NSTableView *tableView;


@property (strong) CNGridViewItemLayout *defaultLayout; //默认样式
@property (strong) CNGridViewItemLayout *hoverLayout;   //鼠标悬停样式
@property (strong) CNGridViewItemLayout *selectedLayout;   //选中样式

@property (nonatomic, assign) BMImageType selectedFilteredImageType; ///< 选中已过滤的图片类型
@property (nonatomic, assign) NSInteger selectedGroupIndex; //选中的组别

@end

@implementation BMMainViewController


+ (void)initialize {
    kItemSizeSliderPositionKey = @"ItemSizeSliderPosition";
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"初始化了");
    [self initData];
    [self initUI];
    [self addNotification];

}


#pragma mark - 设置UI


- (void)initUI {
    
    self.tableView.rowHeight = 44;

    self.defaultLayout = [CNGridViewItemLayout defaultLayout];
    self.defaultLayout.itemTitleTextAttributes = @{NSForegroundColorAttributeName : [NSColor colorWithRed:71/255.0 green:88/255.0 blue:96/255.0 alpha:1],NSFontAttributeName:[NSFont systemFontOfSize:12.0f]};
    self.hoverLayout = [CNGridViewItemLayout defaultLayout];
    self.selectedLayout = [CNGridViewItemLayout defaultLayout];
    self.hoverLayout.backgroundColor = [[NSColor lightGrayColor] colorWithAlphaComponent:0.42];
    self.selectedLayout.backgroundColor = [NSColor whiteColor];//选中背景颜色
    //初始化NSUserDefaults 数据
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults integerForKey:kItemSizeSliderPositionKey]) {
        self.itemSizeSlider.integerValue = [defaults integerForKey:kItemSizeSliderPositionKey];
    }
    self.gridView.dropInBlock = ^(NSArray<NSString *> *files) {
        
        NSInteger selectedRow =  [self.tableView selectedRow];

        BMIconGroupModel * group = [[[BMIconManager sharedInstance] allGroups] objectAtIndex:selectedRow];
        NSArray *copyIcons = [group copyFilesFromPaths:files];
        if (copyIcons.count > 0) {
            [self.items addObjectsFromArray:copyIcons];
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(self.items.count, files.count)];
            [self.gridView insertItemsAtIndexes:indexSet animated:YES];
        }

        
    };
    self.gridView.itemSize = NSMakeSize(self.itemSizeSlider.integerValue, self.itemSizeSlider.integerValue);
    self.gridView.backgroundColor = [NSColor colorWithPatternImage:[NSImage imageNamed:@"BackgroundDust"]];
    self.gridView.scrollElasticity = YES;//滚动弹性
    self.gridView.backgroundColor = [NSColor whiteColor];
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


- (void)initData {
    
    self.items = [NSMutableArray array];
    self.groups = [NSMutableArray array];
    self.selectedGroupIndex = 0;    //默认当前选中group
    self.selectedFilteredImageType = BMImageTypeAll;//当前选中要已过滤的图片类型,即要显示的类型

    NSArray *groups = [[[BMIconManager sharedInstance] allGroups] copy];
    [self.groups addObjectsFromArray:groups];
    BMIconGroupModel * group = [self.groups objectAtIndex:self.selectedGroupIndex];
    if (group && groups.count > 0) {
        [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:self.selectedGroupIndex] byExtendingSelection:YES];
        self.items =[NSMutableArray arrayWithArray:[[group objectsWithType:self.selectedFilteredImageType] copy]];
    }
}


#pragma mark - 按钮事件


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
    BMIconGroupModel *group = self.groups[self.selectedGroupIndex];
    NSArray *objects = [[group objectsWithType:imageType] copy];
    if (objects.count > 0) {
        [self.items addObjectsFromArray:objects];
        [self.gridView reloadDataAnimated:YES];
    }

}

- (IBAction)addFilesButtonAction:(id)sender {
    
    NSAlert *alert = [[NSAlert alloc]init];
    //可以设置产品的icon
    alert.icon = [NSImage imageNamed:@"(Lion_Head)_SFont.CN.png"];
    //添加两个按钮吧
    [alert addButtonWithTitle:@"OK"];
    //正文
    alert.messageText = @"提示";
    //描述文字
    alert.informativeText = @"暂不允许新建分组";
    //弹窗类型 默认类型 NSAlertStyleWarning
    [alert setAlertStyle:NSAlertStyleWarning];
    //回调Block
    [alert beginSheetModalForWindow:[self.view window] completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSAlertFirstButtonReturn ) {
            NSLog(@"this is OK Button tap");
        }
    }];
    

}
//slider 滑动
- (IBAction)itemSizeSliderAction:(id)sender {
    self.gridView.itemSize = NSMakeSize(self.itemSizeSlider.integerValue, self.itemSizeSlider.integerValue);
    //缓存到本地
    [[NSUserDefaults standardUserDefaults] setInteger:self.itemSizeSlider.integerValue forKey:kItemSizeSliderPositionKey];
}
     
- (IBAction)colorPannelButtonAction:(id)sender {
    [self openColorPanel];
}
     

#pragma mark - 通知事件


     
 - (void)detectedNotification:(NSNotification *)notif {
     //    CNLog(@"notification: %@", notif);
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
    BMIconGroupModel *group = self.groups[selectedRow];
    NSArray *objects = [[group allObjects] copy];
    if (objects.count > 0) {
        [self.items addObjectsFromArray:objects];
        [self.gridView reloadDataAnimated:YES];
    }
    self.selectedGroupIndex = selectedRow;
    
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.groups.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    //根据ID取视图

    
    BMProjectCell *cell = [tableView makeViewWithIdentifier:@"BMProjectCell" owner:self];

    if (cell==nil) {
        

        
    }
//    label.stringValue = self.groups[row].groupName;
    return cell;
}



#pragma mark - 颜色面板回调事件
//颜色选择action事件
- (void)changeColor:(id)sender {
    NSColorPanel *colorPanel = sender ;
   
    self.gridView.backgroundColor = colorPanel.color;;
}


#pragma mark - 私有方法
- (void)openColorPanel{
    
    NSColorPanel *colorpanel = [NSColorPanel sharedColorPanel];
    colorpanel.mode = NSColorPanelModeRGB; //调出时，默认色盘
    [colorpanel setAction:@selector(changeColor:)];
    [colorpanel setTarget:self];
    [colorpanel orderFront:nil];
}

- (BMImageType)imageTypeWithIndexOfSelectedItem:(NSInteger)index {
    BMImageType imageType = BMImageTypeUnknown;
    switch (index) {
        case 0:
            imageType =  BMImageTypeAll;
            break;
        case 1:
            imageType =  BMImageTypeSVG;
            break;
        case 2:
            imageType =  BMImageTypePNG;
            break;
        case 3:
            imageType = BMImageTypeJPG;
            break;
        default:
            break;
    }
    return imageType;
}


@end
