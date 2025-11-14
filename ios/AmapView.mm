#import "AmapView.h"
#import "AmapMarkerAnnotation.h"

#import <react/renderer/components/AmapViewSpec/ComponentDescriptors.h>
#import <react/renderer/components/AmapViewSpec/EventEmitters.h>
#import <react/renderer/components/AmapViewSpec/Props.h>
#import <react/renderer/components/AmapViewSpec/RCTComponentViewHelpers.h>

#import "RCTFabricComponentsPlugins.h"
#import <AMapFoundationKit/AMapFoundationKit.h>
#import <MAMapKit/MAMapKit.h>

using namespace facebook::react;

// Cluster annotation to represent a group of markers
@interface AmapClusterAnnotation : MAPointAnnotation
@property (nonatomic, strong) NSArray<AmapMarkerAnnotation *> *markers;
@property (nonatomic, assign) NSInteger markerCount;
@end

@implementation AmapClusterAnnotation
@end

@interface AmapView () <RCTAmapViewViewProtocol>

@end

@implementation AmapView {
    MAMapView * _mapView;
    CLLocationManager * _locationManager;
    BOOL _clusteringEnabled;
    NSArray<AmapMarkerAnnotation *> *_allMarkers; // Store all markers for clustering
}

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
    return concreteComponentDescriptorProvider<AmapViewComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps = std::make_shared<const AmapViewProps>();
    _props = defaultProps;

    // Initialize AMap SDK with API key from Info.plist
    // Enable HTTPS (required for AMap SDK v4.5.0+)
    [AMapServices sharedServices].enableHTTPS = YES;
    NSString *apiKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"AMapApiKey"];
    if (apiKey) {
      [AMapServices sharedServices].apiKey = apiKey;
    }

    // Initialize location manager
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;

    // Create MAMapView
    _mapView = [[MAMapView alloc] initWithFrame:self.bounds];
    _mapView.delegate = self;
    _mapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    // Basic map configuration
    _mapView.showsUserLocation = NO;
    _mapView.zoomEnabled = YES;
    _mapView.scrollEnabled = YES;
    _mapView.rotateEnabled = YES;
    _mapView.rotateCameraEnabled = YES;

    // Initialize clustering
    _clusteringEnabled = NO;
    _allMarkers = @[];

    self.contentView = _mapView;
  }

  return self;
}

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps
{
    const auto &oldViewProps = *std::static_pointer_cast<AmapViewProps const>(_props);
    const auto &newViewProps = *std::static_pointer_cast<AmapViewProps const>(props);

    // Map type
    if (oldViewProps.mapType != newViewProps.mapType) {
        std::string mapTypeStr = newViewProps.mapType;
        if (mapTypeStr == "satellite") {
            _mapView.mapType = MAMapTypeSatellite;
        } else {
            _mapView.mapType = MAMapTypeStandard;
        }
    }

    // Buildings display
    if (oldViewProps.showsBuildings != newViewProps.showsBuildings) {
        _mapView.showsBuildings = newViewProps.showsBuildings;
    }

    // Traffic display
    if (oldViewProps.showsTraffic != newViewProps.showsTraffic) {
        _mapView.showTraffic = newViewProps.showsTraffic;
    }

    // Labels display
    if (oldViewProps.showsLabels != newViewProps.showsLabels) {
        _mapView.showsLabels = newViewProps.showsLabels;
    }

    // Zoom enabled
    if (oldViewProps.zoomEnabled != newViewProps.zoomEnabled) {
        _mapView.zoomEnabled = newViewProps.zoomEnabled;
    }

    // Scroll enabled
    if (oldViewProps.scrollEnabled != newViewProps.scrollEnabled) {
        _mapView.scrollEnabled = newViewProps.scrollEnabled;
    }

    // Rotate enabled
    if (oldViewProps.rotateEnabled != newViewProps.rotateEnabled) {
        _mapView.rotateEnabled = newViewProps.rotateEnabled;
    }

    // Tilt enabled (rotateCameraEnabled controls 3D tilt gestures)
    if (oldViewProps.tiltEnabled != newViewProps.tiltEnabled) {
        _mapView.rotateCameraEnabled = newViewProps.tiltEnabled;
    }

    // User location
    if (oldViewProps.showsUserLocation != newViewProps.showsUserLocation) {
        if (newViewProps.showsUserLocation) {
            // Request location permission if not already granted
            CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
            if (status == kCLAuthorizationStatusNotDetermined) {
                [_locationManager requestWhenInUseAuthorization];
            }
            _mapView.showsUserLocation = YES;
        } else {
            _mapView.showsUserLocation = NO;
        }
    }

    // Clustering enabled
    if (oldViewProps.clusteringEnabled != newViewProps.clusteringEnabled) {
        _clusteringEnabled = newViewProps.clusteringEnabled;
        [self updateClusters];
    }

    [super updateProps:props oldProps:oldProps];
}

Class<RCTComponentViewProtocol> AmapViewCls(void)
{
    return AmapView.class;
}

#pragma mark - Clustering Methods

- (void)updateClusters
{
    if (!_clusteringEnabled) {
        // Remove all cluster annotations and show all markers
        NSArray *annotations = [_mapView.annotations copy];
        for (id<MAAnnotation> annotation in annotations) {
            if ([annotation isKindOfClass:[AmapClusterAnnotation class]]) {
                [_mapView removeAnnotation:annotation];
            }
        }
        return;
    }

    // Get all marker annotations
    NSMutableArray *markers = [NSMutableArray array];
    NSArray *annotations = [_mapView.annotations copy];
    for (id<MAAnnotation> annotation in annotations) {
        if ([annotation isKindOfClass:[AmapMarkerAnnotation class]]) {
            [markers addObject:annotation];
        }
    }
    _allMarkers = [markers copy];

    // Perform clustering
    NSArray *clusters = [self clusterAnnotations:_allMarkers];

    // Remove existing annotations
    [_mapView removeAnnotations:annotations];

    // Add clustered annotations
    [_mapView addAnnotations:clusters];
}

- (NSArray *)clusterAnnotations:(NSArray<AmapMarkerAnnotation *> *)markers
{
    if (markers.count == 0) {
        return @[];
    }

    NSMutableArray *result = [NSMutableArray array];
    NSMutableArray *remaining = [markers mutableCopy];

    // Clustering distance in screen points
    CGFloat clusterDistance = 60.0;

    while (remaining.count > 0) {
        AmapMarkerAnnotation *marker = remaining.firstObject;
        [remaining removeObjectAtIndex:0];

        CGPoint point = [_mapView convertCoordinate:marker.coordinate toPointToView:_mapView];
        NSMutableArray *cluster = [NSMutableArray arrayWithObject:marker];

        // Find nearby markers
        NSMutableArray *toRemove = [NSMutableArray array];
        for (AmapMarkerAnnotation *other in remaining) {
            CGPoint otherPoint = [_mapView convertCoordinate:other.coordinate toPointToView:_mapView];
            CGFloat distance = sqrt(pow(point.x - otherPoint.x, 2) + pow(point.y - otherPoint.y, 2));

            if (distance < clusterDistance) {
                [cluster addObject:other];
                [toRemove addObject:other];
            }
        }
        [remaining removeObjectsInArray:toRemove];

        // Create cluster or single marker
        if (cluster.count > 1) {
            // Calculate cluster center
            CLLocationDegrees lat = 0, lon = 0;
            for (AmapMarkerAnnotation *m in cluster) {
                lat += m.coordinate.latitude;
                lon += m.coordinate.longitude;
            }
            lat /= cluster.count;
            lon /= cluster.count;

            AmapClusterAnnotation *clusterAnnotation = [[AmapClusterAnnotation alloc] init];
            clusterAnnotation.coordinate = CLLocationCoordinate2DMake(lat, lon);
            clusterAnnotation.title = [NSString stringWithFormat:@"%ld markers", (long)cluster.count];
            clusterAnnotation.markers = cluster;
            clusterAnnotation.markerCount = cluster.count;

            [result addObject:clusterAnnotation];
        } else {
            [result addObject:marker];
        }
    }

    return result;
}

#pragma mark - MAMapViewDelegate

- (void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation
{
    // Will implement user location updates in Phase 6
}

- (void)mapView:(MAMapView *)mapView mapDidLoad:(BOOL)success
{
    if (success) {
        NSLog(@"AMap loaded successfully");
        // Emit onMapReady event
        if (_eventEmitter) {
            std::dynamic_pointer_cast<const facebook::react::AmapViewEventEmitter>(_eventEmitter)
                ->onMapReady(facebook::react::AmapViewEventEmitter::OnMapReady{});
        }
    }
}

- (void)mapView:(MAMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    // Update clusters if clustering is enabled
    if (_clusteringEnabled) {
        [self updateClusters];
    }

    // Emit onRegionChange event
    if (_eventEmitter) {
        MACoordinateRegion region = mapView.region;

        facebook::react::AmapViewEventEmitter::OnRegionChange event = {
            .latitude = @(region.center.latitude).stringValue.UTF8String,
            .longitude = @(region.center.longitude).stringValue.UTF8String,
            .latitudeDelta = @(region.span.latitudeDelta).stringValue.UTF8String,
            .longitudeDelta = @(region.span.longitudeDelta).stringValue.UTF8String,
            .zoom = @(mapView.zoomLevel).stringValue.UTF8String,
        };

        std::dynamic_pointer_cast<const facebook::react::AmapViewEventEmitter>(_eventEmitter)
            ->onRegionChange(event);
    }
}

- (void)mapView:(MAMapView *)mapView didSingleTappedAtCoordinate:(CLLocationCoordinate2D)coordinate
{
    // Emit onMapPress event
    if (_eventEmitter) {
        facebook::react::AmapViewEventEmitter::OnMapPress event = {
            .coordinate = {
                .latitude = @(coordinate.latitude).stringValue.UTF8String,
                .longitude = @(coordinate.longitude).stringValue.UTF8String,
            }
        };

        std::dynamic_pointer_cast<const facebook::react::AmapViewEventEmitter>(_eventEmitter)
            ->onMapPress(event);
    }
}

- (void)mapView:(MAMapView *)mapView didLongPressedAtCoordinate:(CLLocationCoordinate2D)coordinate
{
    // Emit onMapLongPress event
    if (_eventEmitter) {
        facebook::react::AmapViewEventEmitter::OnMapLongPress event = {
            .coordinate = {
                .latitude = @(coordinate.latitude).stringValue.UTF8String,
                .longitude = @(coordinate.longitude).stringValue.UTF8String,
            }
        };

        std::dynamic_pointer_cast<const facebook::react::AmapViewEventEmitter>(_eventEmitter)
            ->onMapLongPress(event);
    }
}

- (void)mapView:(MAMapView *)mapView didSelectAnnotationView:(MAAnnotationView *)view
{
    if (!_eventEmitter || !view.annotation) {
        return;
    }

    CLLocationCoordinate2D coordinate = view.annotation.coordinate;

    // Check if it's a cluster annotation
    if ([view.annotation isKindOfClass:[AmapClusterAnnotation class]]) {
        AmapClusterAnnotation *cluster = (AmapClusterAnnotation *)view.annotation;

        // Emit onClusterPress event
        facebook::react::AmapViewEventEmitter::OnClusterPress event = {
            .coordinate = {
                .latitude = @(coordinate.latitude).stringValue.UTF8String,
                .longitude = @(coordinate.longitude).stringValue.UTF8String,
            },
            .markerCount = @(cluster.markerCount).stringValue.UTF8String
        };

        std::dynamic_pointer_cast<const facebook::react::AmapViewEventEmitter>(_eventEmitter)
            ->onClusterPress(event);
    } else if ([view.annotation isKindOfClass:[AmapMarkerAnnotation class]]) {
        // Emit onMarkerPress event for regular markers
        NSString *annotationId = view.annotation.title ?: @"";

        facebook::react::AmapViewEventEmitter::OnMarkerPress event = {
            .id = annotationId.UTF8String,
            .coordinate = {
                .latitude = @(coordinate.latitude).stringValue.UTF8String,
                .longitude = @(coordinate.longitude).stringValue.UTF8String,
            }
        };

        std::dynamic_pointer_cast<const facebook::react::AmapViewEventEmitter>(_eventEmitter)
            ->onMarkerPress(event);
    }
}

- (MAMapView *)getMapView
{
    return _mapView;
}

- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MAUserLocation class]]) {
        return nil; // Use default user location view
    }

    // Check if it's a cluster annotation
    if ([annotation isKindOfClass:[AmapClusterAnnotation class]]) {
        static NSString *clusterIdentifier = @"AmapClusterAnnotation";
        MAPinAnnotationView *clusterView = (MAPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:clusterIdentifier];

        if (clusterView == nil) {
            clusterView = [[MAPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:clusterIdentifier];
        } else {
            clusterView.annotation = annotation;
        }

        AmapClusterAnnotation *cluster = (AmapClusterAnnotation *)annotation;
        clusterView.pinColor = MAPinAnnotationColorPurple;
        clusterView.canShowCallout = YES;

        // Add cluster count label
        UILabel *countLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 40, 20)];
        countLabel.text = [NSString stringWithFormat:@"%ld", (long)cluster.markerCount];
        countLabel.textAlignment = NSTextAlignmentCenter;
        countLabel.textColor = [UIColor whiteColor];
        countLabel.font = [UIFont boldSystemFontOfSize:12];
        countLabel.backgroundColor = [[UIColor purpleColor] colorWithAlphaComponent:0.8];
        countLabel.layer.cornerRadius = 10;
        countLabel.clipsToBounds = YES;

        // Position label above the pin
        countLabel.center = CGPointMake(16, -10);
        [clusterView addSubview:countLabel];

        return clusterView;
    }

    // Check if it's our custom AmapMarkerAnnotation
    if ([annotation isKindOfClass:[AmapMarkerAnnotation class]]) {
        AmapMarkerAnnotation *markerAnnotation = (AmapMarkerAnnotation *)annotation;

        // Check if marker has a custom icon
        if (markerAnnotation.iconImage) {
            // Use MAAnnotationView for custom icon
            static NSString *customIdentifier = @"AmapMarkerCustom";
            MAAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:customIdentifier];

            if (annotationView == nil) {
                annotationView = [[MAAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:customIdentifier];
            } else {
                annotationView.annotation = annotation;
            }

            annotationView.image = markerAnnotation.iconImage;
            annotationView.canShowCallout = markerAnnotation.showsCallout;
            annotationView.centerOffset = CGPointMake(0, -markerAnnotation.iconImage.size.height / 2);

            return annotationView;
        } else {
            // Use default pin annotation view
            static NSString *reuseIdentifier = @"AmapMarkerPin";
            MAPinAnnotationView *annotationView = (MAPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:reuseIdentifier];

            if (annotationView == nil) {
                annotationView = [[MAPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
            } else {
                annotationView.annotation = annotation;
            }

            annotationView.canShowCallout = markerAnnotation.showsCallout;
            annotationView.animatesDrop = YES;

            return annotationView;
        }
    }

    return nil;
}

- (MAOverlayRenderer *)mapView:(MAMapView *)mapView rendererForOverlay:(id<MAOverlay>)overlay
{
    if ([overlay isKindOfClass:[MAPolyline class]]) {
        MAPolylineRenderer *renderer = [[MAPolylineRenderer alloc] initWithPolyline:overlay];
        renderer.strokeColor = [UIColor blueColor];
        renderer.lineWidth = 3.0;
        return renderer;
    }
    else if ([overlay isKindOfClass:[MAPolygon class]]) {
        MAPolygonRenderer *renderer = [[MAPolygonRenderer alloc] initWithPolygon:overlay];
        renderer.strokeColor = [UIColor blueColor];
        renderer.fillColor = [[UIColor blueColor] colorWithAlphaComponent:0.3];
        renderer.lineWidth = 3.0;
        return renderer;
    }
    else if ([overlay isKindOfClass:[MACircle class]]) {
        MACircleRenderer *renderer = [[MACircleRenderer alloc] initWithCircle:overlay];
        renderer.strokeColor = [UIColor blueColor];
        renderer.fillColor = [[UIColor blueColor] colorWithAlphaComponent:0.3];
        renderer.lineWidth = 3.0;
        return renderer;
    }

    return nil;
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManagerDidChangeAuthorization:(CLLocationManager *)manager
{
    CLAuthorizationStatus status = [manager authorizationStatus];

    if (status == kCLAuthorizationStatusAuthorizedWhenInUse ||
        status == kCLAuthorizationStatusAuthorizedAlways) {
        // Permission granted, enable user location if it was requested
        if (_mapView.showsUserLocation) {
            NSLog(@"Location permission granted, showing user location");
        }
    } else if (status == kCLAuthorizationStatusDenied ||
               status == kCLAuthorizationStatusRestricted) {
        NSLog(@"Location permission denied or restricted");
        _mapView.showsUserLocation = NO;
    }
}

@end
