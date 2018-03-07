/**
 
 */
#import "SVGKSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface SVGKSourceURL : SVGKSource <NSCopying>

@property (readonly, nonatomic, strong) NSURL* URL;

- (instancetype)initWithURL:(NSURL*)u;
+ (instancetype)sourceFromURL:(NSURL*)u;

@end

NS_ASSUME_NONNULL_END
