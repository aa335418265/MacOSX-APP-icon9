/**
 
 */
#import "SVGKSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface SVGKSourceString : SVGKSource <NSCopying>

@property (nonatomic, strong, readonly) NSString* rawString;

- (instancetype)initWithContentsOfString:(NSString*)theStr;
+ (instancetype)sourceFromContentsOfString:(NSString*)rawString;

@end

NS_ASSUME_NONNULL_END
