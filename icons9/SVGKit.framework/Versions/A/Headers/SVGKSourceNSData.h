/**
 
 */
#import "SVGKSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface SVGKSourceNSData : SVGKSource

@property (nonatomic, copy) NSData* rawData;
@property (nonatomic, strong) NSURL* effectiveURL;

- (instancetype)initWithData:(NSData*)data;
- (instancetype)initWithData:(NSData*)data URLForRelativeLinks:(nullable NSURL*)url;

+ (instancetype)sourceFromData:(NSData*)data URLForRelativeLinks:(nullable NSURL*) url;

@end

NS_ASSUME_NONNULL_END
