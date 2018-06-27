//
//  BMIconManager.m
//  icons9
//
//  Created by 冯立海 on 2018/3/6.
//  Copyright © 2018年 冯立海. All rights reserved.
//

#import "BMIconManager.h"
#import <AppKit/AppKit.h>
#import "BMAPIRequest.h"
#import "BMAPIRequestURL.h"
#import <sqlite3.h>
#import "BMSQLProjectModel.h"
#import "BMSQLIconModel.h"
#include <CommonCrypto/CommonDigest.h>
#import "NSString+Networking.h"
#import <AFNetworking.h>
#import "BMIconsDownloader.h"
#import <MJExtension.h>


#define DATABASE @"icons9.db"
#define TABLE_PROJECTS @"projects"
#define TABLE_ICONS @"icons"

#define FileHashDefaultChunkSizeForReadingData 1024*8


#define isStrEmpty(_ref)    (((_ref) == nil) || ([(_ref) isEqual:[NSNull null]]) ||([(_ref)isEqualToString:@""]))

#define emptySafeStr(_ref)    (_ref?_ref:@"")

@interface NSDictionary (emptySafe)

- (NSString *)stringNotNilForKey:(NSString *)key;

@end;
@implementation NSDictionary (emptySafe)

- (NSString *)stringNotNilForKey:(NSString *)key {
    NSString *content = [self objectForKey:key];
    return content?content:@"";
}
@end;


@interface BMIconManager ()
{
    sqlite3 *database;
}
@property (nonatomic, strong) NSString *homePath;
@property (nonatomic, strong) NSString *sqliteFile;
@property (nonatomic, strong) NSString *baseUrl;

//@property (nonatomic, strong) NSMutableDictionary *iconsHashList; ///< 项目icon hash列表

@end
@implementation BMIconManager



+ (instancetype)sharedInstance {
    static BMIconManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[BMIconManager alloc] init];
    });
    return sharedInstance;
}


- (instancetype)init {
    self = [super init];
    if (self) {
        NSFileManager *fileMgr = [NSFileManager defaultManager];
        NSArray * searchResult =  [fileMgr URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask];
        NSURL * appSupportPath = [searchResult firstObject];
        self.homePath = [appSupportPath.path stringByAppendingPathComponent:@"icon9"];
        if (![fileMgr fileExistsAtPath:self.homePath]) {
            [fileMgr createDirectoryAtPath:self.homePath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        self.sqliteFile = [NSString stringWithFormat:@"%@/%@",self.homePath,DATABASE];
        NSLog(@"素材根目录:%@", self.homePath);
        //创建数据库
        [self openDatabase];
        [self createProjectTable];
        [self createIconsTable];

    }
    return self;
}


- (void)openDatabase {
    int databaseResult = sqlite3_open([self.sqliteFile UTF8String], &database);
    if (databaseResult == SQLITE_OK) {
        NSLog(@"打开数据库成功");
    }else{
        NSLog(@"创建／打开数据库失败,%d",databaseResult);
    }
}


#pragma mark - project 数据库操作

- (void)createProjectTable {
    char *error;
    NSString *sqlString = [NSString stringWithFormat:@"create table if not exists %@(id integer primary key autoincrement,projectid char unique, name char unique ,hash char ,picUrl char, projectpath char)", TABLE_PROJECTS];
    const char *sql = [sqlString cStringUsingEncoding:NSUTF8StringEncoding];
    int tableResult = sqlite3_exec(database, sql, NULL, NULL, &error);
    if (tableResult == SQLITE_OK) {
        NSLog(@"创建%@表成功", TABLE_PROJECTS);
    }else{
         NSLog(@"创建%@表失败", TABLE_PROJECTS);
    }
}

- (void)insertProjects:(NSArray <NSDictionary *> *)list {
    if (list.count <= 0) {
        return;
    }
    for (NSDictionary *param in list) {
        NSString *projectId = [param stringNotNilForKey:@"id"];
        NSString *name = [param stringNotNilForKey:@"name"];
        NSString *hash = [param stringNotNilForKey:@"iconsHash"];
        NSString *picUrl = [param stringNotNilForKey:@"picUrl"];
        NSString *projectPath=[self.homePath stringByAppendingPathComponent:name];
        if (name == nil || hash == nil ) {
            continue;
        }
        NSString *sqlString = [NSString stringWithFormat:@"REPLACE INTO %@(projectid,name,hash, picUrl, projectpath) VALUES ('%@','%@','%@', '%@','%@');",TABLE_PROJECTS, projectId,name, hash,picUrl,projectPath];
        char *error;
        const char * sql = [sqlString cStringUsingEncoding:(NSUTF8StringEncoding)];
        int ret = sqlite3_exec(database, sql, NULL, NULL, &error);
        if (ret==SQLITE_OK) {
            NSLog(@"插入成功");
            //创建
            NSFileManager *fileMgr = [NSFileManager defaultManager];
            if (![fileMgr fileExistsAtPath:projectPath]) {
                [fileMgr createDirectoryAtPath:projectPath withIntermediateDirectories:YES attributes:nil error:nil];
            }
        }else{
            NSLog(@"插入失败:%s", error);
        }
    }
}


- (NSArray *)queryProjects
{
    sqlite3_stmt *statement = nil;
    NSString *sqlString = [NSString stringWithFormat:@"select * from %@;", TABLE_PROJECTS];
    int resutl = sqlite3_prepare_v2(database, sqlString.UTF8String, -1, &statement, NULL);
    NSMutableArray *results = [NSMutableArray array];
    if (resutl == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            BMSQLProjectModel *model = [[BMSQLProjectModel alloc] init];

            const char *projectId = (const char *)sqlite3_column_text(statement, 1);
            const char *name = (const char *)sqlite3_column_text(statement, 2);
            const char *hash = (const char *)sqlite3_column_text(statement, 3);
            const char *picUrl = (const char *)sqlite3_column_text(statement, 4);
            const char *path = (const char *)sqlite3_column_text(statement, 5);
            model.projectId = [NSString stringWithCString:projectId encoding:NSUTF8StringEncoding];;
            model.projectName = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
            model.projectHash = [NSString stringWithCString:hash encoding:NSUTF8StringEncoding];
            model.projectPicUrl = [NSString stringWithCString:picUrl encoding:NSUTF8StringEncoding];
            model.projectLocalPath = [NSString stringWithCString:path encoding:NSUTF8StringEncoding];
            [results addObject:model];

        }
    }else{
        NSLog(@"查询数据库失败");
    }
    return results;
}



- (void)updateProjects:(CompledBlock)complete {
    
    dispatch_queue_t queue = dispatch_queue_create(0, DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(queue, ^{
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        NSString *url = [NSString stringWithFormat:@"%@%@", self.baseUrl, URI_PROJECTS];
        
        [[BMAPIRequest sharedInstance] callGETWithParams:params headers:nil url:url queryString:nil apiName:NSStringFromSelector(_cmd)  progress:nil success:^(BMURLResponse *response) {
            id data = [response.content objectForKey:@"data"];
            if ([data isKindOfClass:[NSNull class]]) {
                complete?complete(NO,[self allGroups]):nil;
            }else{
                [self insertProjects:data];
                complete?complete(YES,[self allGroups]):nil;
            }

        } failure:^(BMURLResponse *response) {
            complete?complete(NO,[self allGroups]):nil;
            NSLog(@"请求失败");
        }];
    });
}

- (void)getIconsUpdateList:(NSString *)projectHash projectId:(NSString *)projectId success:(CheckSuccess )success failure:(CheckFailure)failure
{

    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setValue:projectHash forKey:@"iconsHash"];
    [params setValue:projectId forKey:@"projectId"];
    NSString *url = [NSString stringWithFormat:@"%@%@", self.baseUrl, URI_CHECK_UPDATE];
    [[BMAPIRequest sharedInstance] callGETWithParams:params headers:nil url:url queryString:nil apiName:NSStringFromSelector(_cmd)  progress:nil success:^(BMURLResponse *response) {
        
        id data = [response.content objectForKey:@"data"];
        NSLog(@"params=%@, data=%@", params,data);
        if ([data isKindOfClass:[NSNull class]]) {
            failure?failure(nil):nil;
        }
        success?success(data):nil;

    } failure:^(BMURLResponse *response) {
        failure?failure(nil):nil;
        NSLog(@"请求失败");
    }];
}

- (void)updateIcons:(NSArray *)iconHashList  projectName:(NSString *)projectName projectId:(NSString *)projectId
{
    NSString *str=@"";
    for (NSString *hash in iconHashList) {
        str = [str stringByAppendingString:[NSString stringWithFormat:@"%@,", hash]];
    }
    str = [str substringToIndex:str.length - 1];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params setValue:str forKey:@"iconHash"];
    NSString *url = [NSString stringWithFormat:@"%@%@", self.baseUrl, URI_ICONS];
    [[BMAPIRequest sharedInstance] callPOSTWithParams:params headers:nil url:url queryString:nil apiName:NSStringFromSelector(_cmd)  progress:nil success:^(BMURLResponse *response) {
        
        id data = [response.content objectForKey:@"data"];
        NSArray *models = [BMSQLIconModel mj_objectArrayWithKeyValuesArray:data];
        for (BMSQLIconModel *model in models) {
             model.projectName = projectName;
            model.projectId = projectId;
            if (!isStrEmpty(model.svgUrl)) {
                model.svgLocalPath = [self.homePath stringByAppendingString:[NSString stringWithFormat:@"/%@/%@.svg", model.projectName, model.iconName]];
                [[BMIconsDownloader sharedInstance] download:model.svgUrl savePath:model.svgLocalPath];
            }
            if (!isStrEmpty(model.pngExtraUrl)) {
                model.pngExtraLocalPath = [self.homePath stringByAppendingString:[NSString stringWithFormat:@"/%@/%@.png", model.projectName, model.iconName]];
                [[BMIconsDownloader sharedInstance] download:model.pngExtraUrl savePath:model.pngExtraLocalPath];
            }
            if (!isStrEmpty(model.pngDoubleUrl)) {
                model.pngDoubleLocalPath = [self.homePath stringByAppendingString:[NSString stringWithFormat:@"/%@/%@@2x.png", model.projectName, model.iconName]];
                [[BMIconsDownloader sharedInstance] download:model.pngDoubleUrl savePath:model.pngDoubleLocalPath];
            }
            if (!isStrEmpty(model.pngTripleUrl)) {
                model.pngTripleLocalPath = [self.homePath stringByAppendingString:[NSString stringWithFormat:@"/%@/%@@3x.png", model.projectName, model.iconName]];
                [[BMIconsDownloader sharedInstance] download:model.pngTripleUrl savePath:model.pngTripleLocalPath];
            }
        }
        [self insertIcons:models];

    } failure:^(BMURLResponse *response) {
        NSLog(@"请求失败");
    }];
}


#pragma mark - icons 数据库操作

- (void)createIconsTable {
    char *error;
    NSString *sqlString = [NSString stringWithFormat:@"create table if not exists %@(\
                           id integer primary key autoincrement,\
                           iconId char unique,\
                           iconName char ,\
                           projectId char ,\
                           svgUrl char ,\
                           pngExtraUrl char ,\
                           pngDoubleUrl char ,\
                           pngTripleUrl char ,\
                           svgLocalPath char,\
                           pngExtraLocalPath char,\
                           pngDoubleLocalPath char,\
                           pngTripleLocalPath char,\
                           pngExtraSize char,\
                           pngDoubleSize char,\
                           pngTripleSize char,\
                           svgFileMd5 char,\
                           pngExtraFileMd5 char,\
                           pngDoubleFileMd5 char,\
                           pngTripleFileMd5 char,\
                           totalMD5 char\
                           )"
                           ,TABLE_ICONS];
    const char *sql = [sqlString cStringUsingEncoding:NSUTF8StringEncoding];
    int tableResult = sqlite3_exec(database, sql, NULL, NULL, &error);
    if (tableResult == SQLITE_OK) {
        NSLog(@"创建%@表成功", TABLE_ICONS);
    }else{
        NSLog(@"创建%@表失败", TABLE_ICONS);
    }
}

- (void)insertIcons:(NSArray <BMSQLIconModel *> *) list {
    if (list.count <= 0) {
        return;
    }
    @synchronized(self){
        NSLog(@"开始更新(插入)%lu条icon记录", (unsigned long)list.count);
        NSString *sqlString = @"";
        for (BMSQLIconModel *model in list) {
            NSString *str = [NSString stringWithFormat:@"REPLACE INTO %@(\
                             iconId,\
                             iconName,\
                             projectId,\
                             svgUrl,\
                             pngExtraUrl,\
                             pngDoubleUrl,\
                             pngTripleUrl,\
                             svgLocalPath,\
                             pngExtraLocalPath,\
                             pngDoubleLocalPath,\
                             pngTripleLocalPath,\
                             pngExtraSize,\
                             pngDoubleSize,\
                             pngTripleSize,\
                             svgFileMd5,\
                             pngExtraFileMd5,\
                             pngDoubleFileMd5,\
                             pngTripleFileMd5,\
                             totalMD5 \
                             ) VALUES ('%@','%@','%@', '%@','%@','%@','%@','%@', '%@','%@','%@','%@','%@', '%@','%@','%@','%@','%@','%@');"
                             ,TABLE_ICONS,
                             emptySafeStr(model.iconId),
                             emptySafeStr(model.iconName),
                             emptySafeStr(model.projectId),
                             emptySafeStr(model.svgUrl),
                             emptySafeStr(model.pngExtraUrl),
                             emptySafeStr(model.pngDoubleUrl),
                             emptySafeStr(model.pngTripleUrl),
                             emptySafeStr(model.svgLocalPath),
                             emptySafeStr(model.pngExtraLocalPath),
                             emptySafeStr(model.pngDoubleLocalPath),
                             emptySafeStr(model.pngTripleLocalPath),
                             emptySafeStr(model.pngExtraSize),
                             emptySafeStr(model.pngDoubleSize),
                             emptySafeStr(model.pngTripleSize),
                             emptySafeStr(model.svgFileMd5),
                             emptySafeStr(model.pngExtraFileMd5),
                             emptySafeStr(model.pngDoubleFileMd5),
                             emptySafeStr(model.pngTripleFileMd5),
                             emptySafeStr(model.totalMd5)
                             ];
            sqlString = [sqlString stringByAppendingString:str];
        }
        
        char *error;
        const char * sql = [sqlString cStringUsingEncoding:(NSUTF8StringEncoding)];
        int ret = sqlite3_exec(database, sql, NULL, NULL, &error);
        if (ret==SQLITE_OK) {
            NSLog(@"成功更新(插入)%lu条icon记录", list.count);
        }else{
            NSLog(@"插入或更新icon失败:%s", error);
        }
    }
    

}



//获取本地update MD5
- (NSString *)caculateLocalUpdateMD5InProject:(NSString *)projectId {
    
    if (projectId == nil) {
        return nil;
    }
    NSArray *iconsMD5List = [self getProjectHashList:projectId];
    //计算更新md5
    NSString *str =nil;
    for (NSString *md5 in iconsMD5List) {
        str = [str stringByAppendingString:md5];
    }
    return str.md5String;
}

//获取project 的iconMD5列表
- (NSArray *)getProjectHashList:(NSString *)projectId
{
    if (projectId == nil) {
        return nil;
    }
    
    NSArray *iconsList = [self queryIconsInProject:projectId];
    NSSortDescriptor *iconIDSortDesc = [NSSortDescriptor sortDescriptorWithKey:@"iconId" ascending:YES];
    NSArray *sortIconsList = [iconsList sortedArrayUsingDescriptors:@[iconIDSortDesc]];
        
    NSMutableArray *iconMD5List = [NSMutableArray array];
    for (BMSQLIconModel *iconModel in sortIconsList) {
        NSString *iconMD5 = [self calculateLocalIconMD5:iconModel];
        iconMD5 ? [iconMD5List addObject:iconMD5] :nil;
    }
    return iconMD5List;
}


//计算真正的icon的MD5(name+fileMD5)
- (NSString *)calculateLocalIconMD5:(BMSQLIconModel *)model {

    //计算iconMD5 = name+svgMD5 + pngDoubleMD5+pngTriplemd5 +pngExtralMD5
    NSString *content = @"";
    content = [content stringByAppendingString:model.iconName];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:model.svgLocalPath]) {
         NSString *fileMD5 = [self getFileMD5WithPath:model.svgLocalPath];
        content = [content stringByAppendingString:fileMD5];
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:model.pngDoubleLocalPath]) {
        NSString *fileMD5 = [self getFileMD5WithPath:model.pngDoubleLocalPath];
        content = [content stringByAppendingString:fileMD5];
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:model.pngTripleLocalPath]) {
        NSString *fileMD5 = [self getFileMD5WithPath:model.pngTripleLocalPath];
        content = [content stringByAppendingString:fileMD5];
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:model.pngExtraLocalPath]) {
        NSString *fileMD5 = [self getFileMD5WithPath:model.pngExtraLocalPath];
        content = [content stringByAppendingString:fileMD5];
    }
    
    return content.md5String;
}



////查询本地文件
//- (void)checkLocalIconInProject:(NSString *)projectId {
//
//    NSArray *list = [self queryIconsInProject:projectId];
//    for (BMSQLIconModel *model in list) {
//        NSString *fileMD5 = [self getFileMD5WithPath:model];
//        NSString *totalMD5 = [NSString stringWithFormat:@"%@%@", model.iconName, fileMD5].md5String;
//
//        //文件不存在或者文件发生变化
//        if (![[NSFileManager defaultManager] fileExistsAtPath:model.iconLocalPath] || ! [totalMD5 isEqualToString:model.totalMD5]) {
//            //加入下载队列
//            NSLog(@"本地文件%@不存在或者发生改变，加入下载队列", model.iconLocalPath);
//            NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
//                //下载文件
//                AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
//                NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:model.iconUrl]];
//                NSURLSessionDownloadTask *download = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
//                    NSLog(@"下载进度:%@", downloadProgress.localizedDescription);
//                } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
//                    NSURL *filePath = [NSURL fileURLWithPath:model.iconLocalPath];
//                    NSLog(@"设置下载保存路径：%@", filePath);
//                    return filePath;
//                } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
//                    NSString *savePath = [NSString stringWithFormat:@"%@",filePath];
//                    NSLog(@"下载完成，保存路径:%@", savePath);
//                }];
//                [download resume];
//            }];
//            [self.downQueue addOperation:op];
//        }
//    }
//}


- (NSArray <BMSQLIconModel *>*)queryIconsInProject:(NSString *)projectId {
    sqlite3_stmt *statement = nil;
    NSString *sqlString;
    if (projectId) {
        sqlString = [NSString stringWithFormat:@"select * from %@ where projectId='%@';", TABLE_ICONS,projectId];
    }else {
        sqlString = [NSString stringWithFormat:@"select * from %@;", TABLE_ICONS];
    }
    
    int resutl = sqlite3_prepare_v2(database, sqlString.UTF8String, -1, &statement, NULL);
    NSMutableArray *results = [NSMutableArray array];
    if (resutl == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            BMSQLIconModel *model = [[BMSQLIconModel alloc] init];
            
            const char *iconId = (const char *)sqlite3_column_text(statement, 1);
            const char *iconName = (const char *)sqlite3_column_text(statement, 2);
            const char *projectId = (const char *)sqlite3_column_text(statement, 3);
            
            const char *svgUrl = (const char *)sqlite3_column_text(statement, 4);
            const char *pngExtraUrl = (const char *)sqlite3_column_text(statement, 5);
            const char *pngDoubleUrl = (const char *)sqlite3_column_text(statement, 6);
            const char *pngTripleUrl = (const char *)sqlite3_column_text(statement, 7);
            const char *svgLocalPath = (const char *)sqlite3_column_text(statement, 8);
            const char *pngExtraLocalPath = (const char *)sqlite3_column_text(statement, 9);
            const char *pngDoubleLocalPath = (const char *)sqlite3_column_text(statement, 10);
            const char *pngTripleLocalPath = (const char *)sqlite3_column_text(statement, 11);
            const char *pngExtraSize = (const char *)sqlite3_column_text(statement, 12);
            const char *pngDoubleSize = (const char *)sqlite3_column_text(statement, 13);
            const char *pngTripleSize = (const char *)sqlite3_column_text(statement, 14);
            const char *svgFileMd5 = (const char *)sqlite3_column_text(statement, 15);
            const char *pngExtraFileMd5 = (const char *)sqlite3_column_text(statement, 16);
            const char *pngDoubleFileMd5 = (const char *)sqlite3_column_text(statement, 17);
            const char *pngTripleFileMd5 = (const char *)sqlite3_column_text(statement, 18);
            const char *totalMD5 = (const char *)sqlite3_column_text(statement, 19);
            
            
            model.iconId = [NSString stringWithCString:iconId encoding:NSUTF8StringEncoding];
            model.iconName = [NSString stringWithCString:iconName encoding:NSUTF8StringEncoding];
            model.projectId = [NSString stringWithCString:projectId encoding:NSUTF8StringEncoding];
            
            model.svgUrl = [NSString stringWithCString:svgUrl encoding:NSUTF8StringEncoding];
            model.pngExtraUrl = [NSString stringWithCString:pngExtraUrl encoding:NSUTF8StringEncoding];
            model.pngDoubleUrl = [NSString stringWithCString:pngDoubleUrl encoding:NSUTF8StringEncoding];
            model.pngTripleUrl = [NSString stringWithCString:pngTripleUrl encoding:NSUTF8StringEncoding];
            
            model.svgLocalPath = [NSString stringWithCString:svgLocalPath encoding:NSUTF8StringEncoding];
            model.pngExtraLocalPath = [NSString stringWithCString:pngExtraLocalPath encoding:NSUTF8StringEncoding];
            model.pngDoubleLocalPath = [NSString stringWithCString:pngDoubleLocalPath encoding:NSUTF8StringEncoding];
            model.pngTripleLocalPath = [NSString stringWithCString:pngTripleLocalPath encoding:NSUTF8StringEncoding];
            
            model.pngExtraSize = [NSString stringWithCString:pngExtraSize encoding:NSUTF8StringEncoding];
            model.pngDoubleSize = [NSString stringWithCString:pngDoubleSize encoding:NSUTF8StringEncoding];
            model.pngTripleSize = [NSString stringWithCString:pngTripleSize encoding:NSUTF8StringEncoding];
            
            model.svgFileMd5 = [NSString stringWithCString:svgFileMd5 encoding:NSUTF8StringEncoding];
            model.pngExtraFileMd5 = [NSString stringWithCString:pngExtraFileMd5 encoding:NSUTF8StringEncoding];
            model.pngDoubleFileMd5 = [NSString stringWithCString:pngDoubleFileMd5 encoding:NSUTF8StringEncoding];
            model.pngTripleFileMd5 = [NSString stringWithCString:pngTripleFileMd5 encoding:NSUTF8StringEncoding];
            model.totalMd5 = [NSString stringWithCString:totalMD5 encoding:NSUTF8StringEncoding];
            [results addObject:model];
        }
    }else{
        NSLog(@"查询数据库失败");
    }
    return results;
}


#pragma mark - 私有方法

- (NSString *)emptyDealWith:(NSString *)content{
    return content?content:@"";
}

#pragma mark - 公有方法

- (NSArray <BMSQLProjectModel *> *)allGroups {
    NSArray *projects = [self queryProjects];
    return projects;
}


-(NSString*)getFileMD5WithPath:(NSString*)path
{
    return (__bridge_transfer NSString *)FileMD5HashCreateWithPath((__bridge CFStringRef)path, FileHashDefaultChunkSizeForReadingData);
}

CFStringRef FileMD5HashCreateWithPath(CFStringRef filePath,size_t chunkSizeForReadingData) {
    // Declare needed variables
    CFStringRef result = NULL;
    CFReadStreamRef readStream = NULL;
    // Get the file URL
    CFURLRef fileURL =
    CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                                  (CFStringRef)filePath,
                                  kCFURLPOSIXPathStyle,
                                  (Boolean)false);
    if (!fileURL) goto done;
    // Create and open the read stream
    readStream = CFReadStreamCreateWithFile(kCFAllocatorDefault,
                                            (CFURLRef)fileURL);
    if (!readStream) goto done;
    bool didSucceed = (bool)CFReadStreamOpen(readStream);
    if (!didSucceed) goto done;
    // Initialize the hash object
    CC_MD5_CTX hashObject;
    CC_MD5_Init(&hashObject);
    // Make sure chunkSizeForReadingData is valid
    if (!chunkSizeForReadingData) {
        chunkSizeForReadingData = FileHashDefaultChunkSizeForReadingData;
    }
    // Feed the data to the hash object
    bool hasMoreData = true;
    while (hasMoreData) {
        uint8_t buffer[chunkSizeForReadingData];
        CFIndex readBytesCount = CFReadStreamRead(readStream,(UInt8 *)buffer,(CFIndex)sizeof(buffer));
        if (readBytesCount == -1) break;
        if (readBytesCount == 0) {
            hasMoreData = false;
            continue;
        }
        CC_MD5_Update(&hashObject,(const void *)buffer,(CC_LONG)readBytesCount);
    }
    // Check if the read operation succeeded
    didSucceed = !hasMoreData;
    // Compute the hash digest
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(digest, &hashObject);
    // Abort if the read operation failed
    if (!didSucceed) goto done;
    // Compute the string result
    char hash[2 * sizeof(digest) + 1];
    for (size_t i = 0; i < sizeof(digest); ++i) {
        snprintf(hash + (2 * i), 3, "%02x", (int)(digest[i]));
    }
    result = CFStringCreateWithCString(kCFAllocatorDefault,(const char *)hash,kCFStringEncodingUTF8);
    
done:
    if (readStream) {
        CFReadStreamClose(readStream);
        CFRelease(readStream);
    }
    if (fileURL) {
        CFRelease(fileURL);
    }
    return result;
}



#pragma mark - Getter and Setter




- (NSString *)baseUrl {
    return kBMIsTestEnvironment ? BASE_URL_TEST : BASE_URL;
}



@end
