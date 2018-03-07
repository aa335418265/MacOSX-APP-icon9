/**
 
 */
#import "SVGKSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface SVGKSourceLocalFile : SVGKSource <NSCopying>

@property (nonatomic, strong) NSString* filePath;
@property (nonatomic, readonly) BOOL wasRelative;

- (instancetype)initWithFilename:(NSString*)p;
+ (instancetype)sourceFromFilename:(NSString*)p;

+ (nullable instancetype) internalSourceAnywhereInBundleUsingName:(NSString*) name;
+ (nullable instancetype)internalSourceAnywhereInBundle:(NSBundle *)bundle usingName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END
