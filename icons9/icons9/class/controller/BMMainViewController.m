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

//#import "BMFileModel.h"

NSString *kPrivateDragUTI = @"com.itx.cocoadraganddrop";

static NSString *kItemSizeSliderPositionKey;

@interface BMMainViewController ()<CNGridViewDelegate, CNGridViewDataSource, NSTableViewDataSource,NSTableViewDelegate>

@property (weak) IBOutlet CNGridView *gridView;
@property (weak) IBOutlet NSSlider *itemSizeSlider;
@property (strong) NSMutableArray<BMIconModel *> *items;
@property (strong) NSMutableArray <BMIconGroupModel *>*groups;
@property (weak) IBOutlet NSTableView *tableView;

@property (assign) NSInteger currentSelectedRow;
@property (strong) CNGridViewItemLayout *defaultLayout; //默认样式
@property (strong) CNGridViewItemLayout *hoverLayout;   //鼠标悬停样式
@property (strong) CNGridViewItemLayout *selectionLayout;   //选中样式

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





- (void)initUI {
    

    self.defaultLayout = [CNGridViewItemLayout defaultLayout];
    self.defaultLayout.itemTitleTextAttributes = @{NSForegroundColorAttributeName : [NSColor colorWithRed:71/255.0 green:88/255.0 blue:96/255.0 alpha:1],NSFontAttributeName:[NSFont systemFontOfSize:12.0f]};
    self.hoverLayout = [CNGridViewItemLayout defaultLayout];
    self.selectionLayout = [CNGridViewItemLayout defaultLayout];
    self.hoverLayout.backgroundColor = [[NSColor grayColor] colorWithAlphaComponent:0.42];
    self.selectionLayout.backgroundColor = [NSColor colorWithCalibratedRed:0.542 green:0.699 blue:0.807 alpha:0.420];
    //初始化NSUserDefaults 数据
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults integerForKey:kItemSizeSliderPositionKey]) {
        self.itemSizeSlider.integerValue = [defaults integerForKey:kItemSizeSliderPositionKey];
    }
    self.gridView.dropInBlock = ^(NSArray<NSString *> *files) {
        BMIconGroupModel * group = [[[BMIconManager sharedInstance] allGroups] firstObject];
        NSArray *copyIcons = [group copyFilesFromPaths:files];
        [self.items addObjectsFromArray:copyIcons];
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(self.items.count, files.count)];
        [self.gridView insertItemsAtIndexes:indexSet animated:YES];
        
    };
    self.gridView.itemSize = NSMakeSize(self.itemSizeSlider.integerValue, self.itemSizeSlider.integerValue);
    self.gridView.backgroundColor = [NSColor colorWithPatternImage:[NSImage imageNamed:@"BackgroundDust"]];
    self.gridView.scrollElasticity = YES;//滚动弹性
    self.gridView.allowsMultipleSelection = YES;//允许多选
    self.gridView.allowsMultipleSelectionWithDrag = YES;//允许拖拽选
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
    self.currentSelectedRow = 0;    //默认当前选中row

    NSArray *groups = [[[BMIconManager sharedInstance] allGroups] copy];
    [self.groups addObjectsFromArray:groups];
    BMIconGroupModel * group = [self.groups firstObject];
    if (group && groups.count > 0) {
        [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:self.currentSelectedRow] byExtendingSelection:YES];
        self.items =[NSMutableArray arrayWithArray:[[group allObjects] copy]];
    }
}


#pragma mark - 按钮事件

- (IBAction)addFilesButtonAction:(id)sender {
    

    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanCreateDirectories:YES];
    [panel setCanChooseFiles:YES];//是否能选择文件file
    [panel setCanChooseDirectories:YES];//是否能打开文件夹
    [panel setAllowsMultipleSelection:YES];//是否允许多选file
    NSInteger finded = [panel runModal]; //获取panel的响应
    if (finded == NSFileHandlingPanelOKButton) {
        for (NSURL *url in [panel URLs]) {
            NSLog(@"文件：%@", url);
        }
    }
    

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

- (IBAction)selectAllItemsButtonAction:(id)sender {
    NSLog(@"全选");

}
     
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
    item.selectionLayout = self.selectionLayout;
    BMIconModel *iconModel = self.items[index];
    item.itemTitle = iconModel.name;
    item.itemImage = iconModel.image;
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
    NSInteger selectedRow = [self.tableView selectedRow];
    if (selectedRow >= 0 && selectedRow != self.currentSelectedRow) {
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

    }
    self.currentSelectedRow = selectedRow;



    
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.groups.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    //根据ID取视图
    NSTextField * label = [tableView makeViewWithIdentifier:@"cellId" owner:self];

    if (label==nil) {
        label = [[NSTextField alloc]initWithFrame:CGRectZero];
        label.textColor = [NSColor colorWithRed:71/255.0 green:88/255.0 blue:96/255.0 alpha:1];
        label.font = [NSFont fontWithName:@"Arial" size:22];
        label.backgroundColor = [NSColor clearColor];
        label.identifier = @"cellId";
        label.bordered = NO;
        label.editable = NO;
        label.alignment = NSTextAlignmentLeft;
        

    }
    label.stringValue = self.groups[row].groupName;
    
    
    return label;

}
#pragma mark - 私有方法

- (void)openColorPanel{
    
    NSColorPanel *colorpanel = [NSColorPanel sharedColorPanel];
    
    colorpanel.mode = NSColorPanelModeCrayon; //调出时，默认色盘
    
    [colorpanel setAction:@selector(changeColor:)];
    [colorpanel setTarget:self];
    [colorpanel orderFront:nil];
}

//颜色选择action事件
- (void)changeColor:(id)sender {
    NSColorPanel *colorPanel = sender ;
    NSColor *color = colorPanel.color;
    self.gridView.backgroundColor = color;
}

@end
