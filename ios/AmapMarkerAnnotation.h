#import <MAMapKit/MAMapKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AmapMarkerAnnotation : MAPointAnnotation
@property (nonatomic, copy) NSString *markerId;
@property (nonatomic, assign) BOOL showsCallout;
@property (nonatomic, copy, nullable) NSString *iconSource; // URL string, asset name, or nil for default
@property (nonatomic, strong, nullable) UIImage *iconImage; // Resolved custom icon image
@end

NS_ASSUME_NONNULL_END
