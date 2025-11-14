#import <React/RCTViewComponentView.h>
#import <UIKit/UIKit.h>
#import <MAMapKit/MAMapKit.h>
#import <CoreLocation/CoreLocation.h>

#ifndef AmapViewNativeComponent_h
#define AmapViewNativeComponent_h

NS_ASSUME_NONNULL_BEGIN

@interface AmapView : RCTViewComponentView <MAMapViewDelegate, CLLocationManagerDelegate>

- (MAMapView * _Nullable)getMapView;

@end

NS_ASSUME_NONNULL_END

#endif /* AmapViewNativeComponent_h */
