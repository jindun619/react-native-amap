#import "AmapModule.h"
#import "AmapView.h"
#import "AmapMarkerAnnotation.h"
#import <React/RCTUIManager.h>
#import <React/RCTLog.h>
#import <MAMapKit/MAMapKit.h>
#import <AMapFoundationKit/AMapFoundationKit.h>

@implementation AmapModule {
    // Store marker and overlay references by ID
    NSMutableDictionary<NSString *, AmapMarkerAnnotation *> *_markers;
    NSMutableDictionary<NSString *, id<MAOverlay>> *_polylines;
    NSMutableDictionary<NSString *, id<MAOverlay>> *_polygons;
    NSMutableDictionary<NSString *, id<MAOverlay>> *_circles;
}

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE()

- (instancetype)init
{
    if (self = [super init]) {
        _markers = [NSMutableDictionary dictionary];
        _polylines = [NSMutableDictionary dictionary];
        _polygons = [NSMutableDictionary dictionary];
        _circles = [NSMutableDictionary dictionary];
    }
    return self;
}

- (dispatch_queue_t)methodQueue
{
  return dispatch_get_main_queue();
}

+ (BOOL)requiresMainQueueSetup
{
  return YES;
}

RCT_EXPORT_METHOD(animateToRegion:(nonnull NSNumber *)viewTag
                  latitude:(double)latitude
                  longitude:(double)longitude
                  zoom:(double)zoom
                  duration:(nullable NSNumber *)duration
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  [self.bridge.uiManager addUIBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *,UIView *> *viewRegistry) {
    AmapView *view = (AmapView *)viewRegistry[viewTag];
    if (!view || ![view isKindOfClass:[AmapView class]]) {
      reject(@"invalid_view", @"Invalid view tag", nil);
      return;
    }

    MAMapView *mapView = [view getMapView];
    if (!mapView) {
      reject(@"no_map", @"Map view not initialized", nil);
      return;
    }

    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);

    // Animate camera
    NSTimeInterval animationDuration = duration ? [duration doubleValue] / 1000.0 : 0.3;

    // Set zoom level first
    [mapView setZoomLevel:zoom animated:YES];

    // Then animate to center coordinate
    [mapView setCenterCoordinate:coordinate animated:YES];

    resolve(nil);
  }];
}

RCT_EXPORT_METHOD(setCamera:(nonnull NSNumber *)viewTag
                  latitude:(double)latitude
                  longitude:(double)longitude
                  zoom:(double)zoom
                  tilt:(nullable NSNumber *)tilt
                  rotation:(nullable NSNumber *)rotation
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  [self.bridge.uiManager addUIBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *,UIView *> *viewRegistry) {
    AmapView *view = (AmapView *)viewRegistry[viewTag];
    if (!view || ![view isKindOfClass:[AmapView class]]) {
      reject(@"invalid_view", @"Invalid view tag", nil);
      return;
    }

    MAMapView *mapView = [view getMapView];
    if (!mapView) {
      reject(@"no_map", @"Map view not initialized", nil);
      return;
    }

    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);

    [mapView setCenterCoordinate:coordinate];
    [mapView setZoomLevel:zoom];

    if (tilt) {
      [mapView setCameraDegree:[tilt doubleValue]];
    }

    if (rotation) {
      [mapView setRotationDegree:[rotation doubleValue]];
    }

    resolve(nil);
  }];
}

RCT_EXPORT_METHOD(addMarker:(nonnull NSNumber *)viewTag
                  markerId:(nonnull NSString *)markerId
                  latitude:(double)latitude
                  longitude:(double)longitude
                  title:(nullable NSString *)title
                  subtitle:(nullable NSString *)subtitle
                  showsCallout:(nullable NSNumber *)showsCallout
                  icon:(nullable id)icon
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  __weak __typeof__(self) weakSelf = self;
  [self.bridge.uiManager addUIBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *,UIView *> *viewRegistry) {
    __typeof__(self) strongSelf = weakSelf;
    if (!strongSelf) return;

    AmapView *view = (AmapView *)viewRegistry[viewTag];
    if (!view || ![view isKindOfClass:[AmapView class]]) {
      reject(@"invalid_view", @"Invalid view tag", nil);
      return;
    }

    MAMapView *mapView = [view getMapView];
    if (!mapView) {
      reject(@"no_map", @"Map view not initialized", nil);
      return;
    }

    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);

    AmapMarkerAnnotation *annotation = [[AmapMarkerAnnotation alloc] init];
    annotation.coordinate = coordinate;
    annotation.title = title;
    annotation.subtitle = subtitle;
    annotation.markerId = markerId;

    // Default to showing callout if title or subtitle is provided
    BOOL shouldShowCallout = showsCallout ? [showsCallout boolValue] : (title != nil || subtitle != nil);
    annotation.showsCallout = shouldShowCallout;

    // Handle custom icon
    if (icon) {
      [strongSelf loadImageFromSource:icon completion:^(UIImage *image) {
        annotation.iconImage = image;
        // Refresh annotation view if already added
        if ([mapView.annotations containsObject:annotation]) {
          MAAnnotationView *view = [mapView viewForAnnotation:annotation];
          if (view && image) {
            view.image = image;
          }
        }
      }];

      // Store icon source for later reference
      if ([icon isKindOfClass:[NSString class]]) {
        annotation.iconSource = (NSString *)icon;
      }
    }

    [mapView addAnnotation:annotation];
    strongSelf->_markers[markerId] = annotation;

    resolve(nil);
  }];
}

RCT_EXPORT_METHOD(removeMarker:(nonnull NSNumber *)viewTag
                  markerId:(nonnull NSString *)markerId
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  __weak __typeof__(self) weakSelf = self;
  [self.bridge.uiManager addUIBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *,UIView *> *viewRegistry) {
    __typeof__(self) strongSelf = weakSelf;
    if (!strongSelf) return;

    AmapView *view = (AmapView *)viewRegistry[viewTag];
    if (!view || ![view isKindOfClass:[AmapView class]]) {
      reject(@"invalid_view", @"Invalid view tag", nil);
      return;
    }

    MAMapView *mapView = [view getMapView];
    if (!mapView) {
      reject(@"no_map", @"Map view not initialized", nil);
      return;
    }

    // Find and remove annotation by ID
    AmapMarkerAnnotation *annotation = strongSelf->_markers[markerId];
    if (annotation) {
      [mapView removeAnnotation:annotation];
      [strongSelf->_markers removeObjectForKey:markerId];
    }

    resolve(nil);
  }];
}

RCT_EXPORT_METHOD(clearMarkers:(nonnull NSNumber *)viewTag
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  __weak __typeof__(self) weakSelf = self;
  [self.bridge.uiManager addUIBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *,UIView *> *viewRegistry) {
    __typeof__(self) strongSelf = weakSelf;
    if (!strongSelf) return;

    AmapView *view = (AmapView *)viewRegistry[viewTag];
    if (!view || ![view isKindOfClass:[AmapView class]]) {
      reject(@"invalid_view", @"Invalid view tag", nil);
      return;
    }

    MAMapView *mapView = [view getMapView];
    if (!mapView) {
      reject(@"no_map", @"Map view not initialized", nil);
      return;
    }

    // Remove all markers from map
    NSArray *markers = [strongSelf->_markers allValues];
    [mapView removeAnnotations:markers];
    [strongSelf->_markers removeAllObjects];

    resolve(nil);
  }];
}

RCT_EXPORT_METHOD(showCallout:(nonnull NSNumber *)viewTag
                  markerId:(nonnull NSString *)markerId
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  __weak __typeof__(self) weakSelf = self;
  [self.bridge.uiManager addUIBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *,UIView *> *viewRegistry) {
    __typeof__(self) strongSelf = weakSelf;
    if (!strongSelf) return;

    AmapView *view = (AmapView *)viewRegistry[viewTag];
    if (!view || ![view isKindOfClass:[AmapView class]]) {
      reject(@"invalid_view", @"Invalid view tag", nil);
      return;
    }

    MAMapView *mapView = [view getMapView];
    if (!mapView) {
      reject(@"no_map", @"Map view not initialized", nil);
      return;
    }

    AmapMarkerAnnotation *annotation = strongSelf->_markers[markerId];
    if (annotation) {
      [mapView selectAnnotation:annotation animated:YES];
    }

    resolve(nil);
  }];
}

RCT_EXPORT_METHOD(hideCallout:(nonnull NSNumber *)viewTag
                  markerId:(nonnull NSString *)markerId
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  __weak __typeof__(self) weakSelf = self;
  [self.bridge.uiManager addUIBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *,UIView *> *viewRegistry) {
    __typeof__(self) strongSelf = weakSelf;
    if (!strongSelf) return;

    AmapView *view = (AmapView *)viewRegistry[viewTag];
    if (!view || ![view isKindOfClass:[AmapView class]]) {
      reject(@"invalid_view", @"Invalid view tag", nil);
      return;
    }

    MAMapView *mapView = [view getMapView];
    if (!mapView) {
      reject(@"no_map", @"Map view not initialized", nil);
      return;
    }

    AmapMarkerAnnotation *annotation = strongSelf->_markers[markerId];
    if (annotation) {
      [mapView deselectAnnotation:annotation animated:YES];
    }

    resolve(nil);
  }];
}

#pragma mark - Helper Methods

- (UIColor *)colorFromHexString:(NSString *)hexString
{
    if (!hexString || [hexString length] == 0) {
        return [UIColor blueColor]; // Default color
    }

    NSString *colorString = [[hexString stringByReplacingOccurrencesOfString:@"#" withString:@""] uppercaseString];

    CGFloat alpha = 1.0, red = 0.0, blue = 0.0, green = 0.0;

    switch ([colorString length]) {
        case 3: // #RGB
            alpha = 1.0;
            red = [self colorComponentFrom:colorString start:0 length:1];
            green = [self colorComponentFrom:colorString start:1 length:1];
            blue = [self colorComponentFrom:colorString start:2 length:1];
            break;
        case 6: // #RRGGBB
            alpha = 1.0;
            red = [self colorComponentFrom:colorString start:0 length:2];
            green = [self colorComponentFrom:colorString start:2 length:2];
            blue = [self colorComponentFrom:colorString start:4 length:2];
            break;
        case 8: // #RRGGBBAA
            red = [self colorComponentFrom:colorString start:0 length:2];
            green = [self colorComponentFrom:colorString start:2 length:2];
            blue = [self colorComponentFrom:colorString start:4 length:2];
            alpha = [self colorComponentFrom:colorString start:6 length:2];
            break;
        default:
            return [UIColor blueColor];
    }

    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

- (CGFloat)colorComponentFrom:(NSString *)string start:(NSUInteger)start length:(NSUInteger)length
{
    NSString *substring = [string substringWithRange:NSMakeRange(start, length)];
    NSString *fullHex = length == 2 ? substring : [NSString stringWithFormat:@"%@%@", substring, substring];
    unsigned hexComponent;
    [[NSScanner scannerWithString:fullHex] scanHexInt:&hexComponent];
    return hexComponent / 255.0;
}

- (void)loadImageFromSource:(id)source completion:(void (^)(UIImage *))completion
{
    if (!source) {
        completion(nil);
        return;
    }

    // Handle string sources (URLs or asset names)
    if ([source isKindOfClass:[NSString class]]) {
        NSString *sourceString = (NSString *)source;

        // Check if it's a URL
        if ([sourceString hasPrefix:@"http://"] || [sourceString hasPrefix:@"https://"]) {
            // Load from URL asynchronously
            NSURL *url = [NSURL URLWithString:sourceString];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSData *imageData = [NSData dataWithContentsOfURL:url];
                UIImage *image = imageData ? [UIImage imageWithData:imageData] : nil;
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(image);
                });
            });
        } else {
            // Try loading as a bundled asset name
            UIImage *image = [UIImage imageNamed:sourceString];
            completion(image);
        }
    }
    else {
        // For now, we only support string sources (URLs and asset names)
        // Number sources (require()) could be added in future with proper RCTImageLoader integration
        completion(nil);
    }
}

#pragma mark - Polyline Methods

RCT_EXPORT_METHOD(addPolyline:(nonnull NSNumber *)viewTag
                  polylineId:(nonnull NSString *)polylineId
                  coordinates:(nonnull NSArray *)coordinates
                  strokeColor:(nullable NSString *)strokeColor
                  strokeWidth:(nullable NSNumber *)strokeWidth
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  __weak __typeof__(self) weakSelf = self;
  [self.bridge.uiManager addUIBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *,UIView *> *viewRegistry) {
    __typeof__(self) strongSelf = weakSelf;
    if (!strongSelf) return;
    AmapView *view = (AmapView *)viewRegistry[viewTag];
    if (!view || ![view isKindOfClass:[AmapView class]]) {
      reject(@"invalid_view", @"Invalid view tag", nil);
      return;
    }

    MAMapView *mapView = [view getMapView];
    if (!mapView) {
      reject(@"no_map", @"Map view not initialized", nil);
      return;
    }

    // Convert coordinates array to CLLocationCoordinate2D array
    NSUInteger count = coordinates.count;
    CLLocationCoordinate2D *coords = (CLLocationCoordinate2D *)malloc(sizeof(CLLocationCoordinate2D) * count);

    for (NSUInteger i = 0; i < count; i++) {
      NSDictionary *coord = coordinates[i];
      coords[i] = CLLocationCoordinate2DMake(
        [coord[@"latitude"] doubleValue],
        [coord[@"longitude"] doubleValue]
      );
    }

    MAPolyline *polyline = [MAPolyline polylineWithCoordinates:coords count:count];
    free(coords);

    [mapView addOverlay:polyline];
    strongSelf->_polylines[polylineId] = polyline;

    resolve(nil);
  }];
}

RCT_EXPORT_METHOD(removePolyline:(nonnull NSNumber *)viewTag
                  polylineId:(nonnull NSString *)polylineId
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  __weak __typeof__(self) weakSelf = self;
  [self.bridge.uiManager addUIBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *,UIView *> *viewRegistry) {
    __typeof__(self) strongSelf = weakSelf;
    if (!strongSelf) return;
    AmapView *view = (AmapView *)viewRegistry[viewTag];
    if (!view || ![view isKindOfClass:[AmapView class]]) {
      reject(@"invalid_view", @"Invalid view tag", nil);
      return;
    }

    MAMapView *mapView = [view getMapView];
    if (!mapView) {
      reject(@"no_map", @"Map view not initialized", nil);
      return;
    }

    id<MAOverlay> polyline = strongSelf->_polylines[polylineId];
    if (polyline) {
      [mapView removeOverlay:polyline];
      [strongSelf->_polylines removeObjectForKey:polylineId];
    }

    resolve(nil);
  }];
}

RCT_EXPORT_METHOD(clearPolylines:(nonnull NSNumber *)viewTag
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  __weak __typeof__(self) weakSelf = self;
  [self.bridge.uiManager addUIBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *,UIView *> *viewRegistry) {
    __typeof__(self) strongSelf = weakSelf;
    if (!strongSelf) return;
    AmapView *view = (AmapView *)viewRegistry[viewTag];
    if (!view || ![view isKindOfClass:[AmapView class]]) {
      reject(@"invalid_view", @"Invalid view tag", nil);
      return;
    }

    MAMapView *mapView = [view getMapView];
    if (!mapView) {
      reject(@"no_map", @"Map view not initialized", nil);
      return;
    }

    [mapView removeOverlays:strongSelf->_polylines.allValues];
    [strongSelf->_polylines removeAllObjects];

    resolve(nil);
  }];
}

#pragma mark - Polygon Methods

RCT_EXPORT_METHOD(addPolygon:(nonnull NSNumber *)viewTag
                  polygonId:(nonnull NSString *)polygonId
                  coordinates:(nonnull NSArray *)coordinates
                  strokeColor:(nullable NSString *)strokeColor
                  strokeWidth:(nullable NSNumber *)strokeWidth
                  fillColor:(nullable NSString *)fillColor
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  __weak __typeof__(self) weakSelf = self;
  [self.bridge.uiManager addUIBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *,UIView *> *viewRegistry) {
    __typeof__(self) strongSelf = weakSelf;
    if (!strongSelf) return;
    AmapView *view = (AmapView *)viewRegistry[viewTag];
    if (!view || ![view isKindOfClass:[AmapView class]]) {
      reject(@"invalid_view", @"Invalid view tag", nil);
      return;
    }

    MAMapView *mapView = [view getMapView];
    if (!mapView) {
      reject(@"no_map", @"Map view not initialized", nil);
      return;
    }

    // Convert coordinates array to CLLocationCoordinate2D array
    NSUInteger count = coordinates.count;
    CLLocationCoordinate2D *coords = (CLLocationCoordinate2D *)malloc(sizeof(CLLocationCoordinate2D) * count);

    for (NSUInteger i = 0; i < count; i++) {
      NSDictionary *coord = coordinates[i];
      coords[i] = CLLocationCoordinate2DMake(
        [coord[@"latitude"] doubleValue],
        [coord[@"longitude"] doubleValue]
      );
    }

    MAPolygon *polygon = [MAPolygon polygonWithCoordinates:coords count:count];
    free(coords);

    [mapView addOverlay:polygon];
    strongSelf->_polygons[polygonId] = polygon;

    resolve(nil);
  }];
}

RCT_EXPORT_METHOD(removePolygon:(nonnull NSNumber *)viewTag
                  polygonId:(nonnull NSString *)polygonId
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  __weak __typeof__(self) weakSelf = self;
  [self.bridge.uiManager addUIBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *,UIView *> *viewRegistry) {
    __typeof__(self) strongSelf = weakSelf;
    if (!strongSelf) return;
    AmapView *view = (AmapView *)viewRegistry[viewTag];
    if (!view || ![view isKindOfClass:[AmapView class]]) {
      reject(@"invalid_view", @"Invalid view tag", nil);
      return;
    }

    MAMapView *mapView = [view getMapView];
    if (!mapView) {
      reject(@"no_map", @"Map view not initialized", nil);
      return;
    }

    id<MAOverlay> polygon = strongSelf->_polygons[polygonId];
    if (polygon) {
      [mapView removeOverlay:polygon];
      [strongSelf->_polygons removeObjectForKey:polygonId];
    }

    resolve(nil);
  }];
}

RCT_EXPORT_METHOD(clearPolygons:(nonnull NSNumber *)viewTag
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  __weak __typeof__(self) weakSelf = self;
  [self.bridge.uiManager addUIBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *,UIView *> *viewRegistry) {
    __typeof__(self) strongSelf = weakSelf;
    if (!strongSelf) return;
    AmapView *view = (AmapView *)viewRegistry[viewTag];
    if (!view || ![view isKindOfClass:[AmapView class]]) {
      reject(@"invalid_view", @"Invalid view tag", nil);
      return;
    }

    MAMapView *mapView = [view getMapView];
    if (!mapView) {
      reject(@"no_map", @"Map view not initialized", nil);
      return;
    }

    [mapView removeOverlays:strongSelf->_polygons.allValues];
    [strongSelf->_polygons removeAllObjects];

    resolve(nil);
  }];
}

#pragma mark - Circle Methods

RCT_EXPORT_METHOD(addCircle:(nonnull NSNumber *)viewTag
                  circleId:(nonnull NSString *)circleId
                  latitude:(double)latitude
                  longitude:(double)longitude
                  radius:(double)radius
                  strokeColor:(nullable NSString *)strokeColor
                  strokeWidth:(nullable NSNumber *)strokeWidth
                  fillColor:(nullable NSString *)fillColor
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  __weak __typeof__(self) weakSelf = self;
  [self.bridge.uiManager addUIBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *,UIView *> *viewRegistry) {
    __typeof__(self) strongSelf = weakSelf;
    if (!strongSelf) return;
    AmapView *view = (AmapView *)viewRegistry[viewTag];
    if (!view || ![view isKindOfClass:[AmapView class]]) {
      reject(@"invalid_view", @"Invalid view tag", nil);
      return;
    }

    MAMapView *mapView = [view getMapView];
    if (!mapView) {
      reject(@"no_map", @"Map view not initialized", nil);
      return;
    }

    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);
    MACircle *circle = [MACircle circleWithCenterCoordinate:coordinate radius:radius];

    [mapView addOverlay:circle];
    strongSelf->_circles[circleId] = circle;

    resolve(nil);
  }];
}

RCT_EXPORT_METHOD(removeCircle:(nonnull NSNumber *)viewTag
                  circleId:(nonnull NSString *)circleId
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  __weak __typeof__(self) weakSelf = self;
  [self.bridge.uiManager addUIBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *,UIView *> *viewRegistry) {
    __typeof__(self) strongSelf = weakSelf;
    if (!strongSelf) return;
    AmapView *view = (AmapView *)viewRegistry[viewTag];
    if (!view || ![view isKindOfClass:[AmapView class]]) {
      reject(@"invalid_view", @"Invalid view tag", nil);
      return;
    }

    MAMapView *mapView = [view getMapView];
    if (!mapView) {
      reject(@"no_map", @"Map view not initialized", nil);
      return;
    }

    id<MAOverlay> circle = strongSelf->_circles[circleId];
    if (circle) {
      [mapView removeOverlay:circle];
      [strongSelf->_circles removeObjectForKey:circleId];
    }

    resolve(nil);
  }];
}

RCT_EXPORT_METHOD(clearCircles:(nonnull NSNumber *)viewTag
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{
  __weak __typeof__(self) weakSelf = self;
  [self.bridge.uiManager addUIBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *,UIView *> *viewRegistry) {
    __typeof__(self) strongSelf = weakSelf;
    if (!strongSelf) return;
    AmapView *view = (AmapView *)viewRegistry[viewTag];
    if (!view || ![view isKindOfClass:[AmapView class]]) {
      reject(@"invalid_view", @"Invalid view tag", nil);
      return;
    }

    MAMapView *mapView = [view getMapView];
    if (!mapView) {
      reject(@"no_map", @"Map view not initialized", nil);
      return;
    }

    [mapView removeOverlays:strongSelf->_circles.allValues];
    [strongSelf->_circles removeAllObjects];

    resolve(nil);
  }];
}

@end
