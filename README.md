# react-native-amap

React Native bridge for AMap (高德地图) iOS/Android SDK with full New Architecture (Fabric + TurboModules) support.

## Features

- ✅ **New Architecture Ready** - Full support for React Native 0.81+ with Fabric and TurboModules
- 🗺️ **Map Display** - Standard and satellite map types with full gesture controls
- 📍 **Markers** - Add, remove, and customize markers with callouts
- 🎨 **Custom Icons** - Support for custom marker icons from URLs or local assets
- 🔢 **Marker Clustering** - Automatic marker clustering with customizable appearance
- 📐 **Overlays** - Polylines, polygons, and circles with customizable styles
- 📱 **User Location** - Show user's current location on the map
- 🎯 **Camera Control** - Programmatic camera positioning with smooth animations
- 📡 **Events** - Rich event system for map interactions

## Installation

```sh
npm install @jindun619/react-native-amap
# or
yarn add @jindun619/react-native-amap
```

### Getting Your API Keys

You need to obtain API keys from AMap:

1. Go to [AMap Developer Console](https://console.amap.com/)
2. Create an account or sign in
3. Create a new application
4. Get your iOS and Android API keys (they are different)

**Important**: iOS and Android require separate API keys from AMap.

### iOS Setup

1. Add your AMap API key to `Info.plist`:

```xml
<key>AMapApiKey</key>
<string>YOUR_AMAP_API_KEY</string>
```

2. Add location permissions to `Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show your position on the map</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>We need your location to show your position on the map</string>
```

3. Add App Transport Security exception for AMap domains in `Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSExceptionDomains</key>
  <dict>
    <key>amap.com</key>
    <dict>
      <key>NSIncludesSubdomains</key>
      <true/>
      <key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key>
      <true/>
    </dict>
  </dict>
</dict>
```

4. **CRITICAL**: Initialize AMap SDK in your `AppDelegate`. Add this code to `AppDelegate.mm` (or `AppDelegate.swift`):

**For Objective-C (AppDelegate.mm):**
```objc
#import <AMapFoundationKit/AMapFoundationKit.h>
#import <MAMapKit/MAMapKit.h>

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  // Configure AMap SDK privacy compliance (MUST be called before MAMapView instantiation)
  [MAMapView updatePrivacyShow:AMapPrivacyShowStatusDidShow privacyInfo:AMapPrivacyInfoStatusDidContain];
  [MAMapView updatePrivacyAgree:AMapPrivacyAgreeStatusDidAgree];

  // Enable HTTPS
  [AMapServices sharedServices].enableHTTPS = YES;

  // ... rest of your AppDelegate code
}
```

**For Swift (AppDelegate.swift):**
```swift
import AMapFoundationKit
import MAMapKit

func application(
  _ application: UIApplication,
  didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
) -> Bool {
  // Configure AMap SDK privacy compliance (MUST be called before MAMapView instantiation)
  MAMapView.updatePrivacyShow(.didShow, privacyInfo: .didContain)
  MAMapView.updatePrivacyAgree(.didAgree)

  // Enable HTTPS
  AMapServices.shared().enableHTTPS = true

  // ... rest of your AppDelegate code
  return true
}
```

5. Install pods:

```sh
cd ios && pod install
```

### Android Setup

1. Add AMap Maven repository to your project-level `android/build.gradle`:

```gradle
allprojects {
  repositories {
    // ... other repositories
    maven { url "https://maven.aliyun.com/repository/public" }
  }
}
```

2. Add required permissions to `AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

  <!-- Required permissions -->
  <uses-permission android:name="android.permission.INTERNET" />
  <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
  <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
  <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
  <uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
  <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
  <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />

  <application>
    <!-- AMap API Key -->
    <meta-data
      android:name="com.amap.api.v2.apikey"
      android:value="YOUR_AMAP_API_KEY" />

    <!-- ... rest of your application config -->
  </application>
</manifest>
```

## Basic Usage

```tsx
import React, { useRef } from 'react';
import { AmapView, type AmapViewHandle } from '@jindun619/react-native-amap';

export default function App() {
  const mapRef = useRef<AmapViewHandle>(null);

  return (
    <AmapView
      ref={mapRef}
      style={{ flex: 1 }}
      mapType="standard"
      showsUserLocation={true}
      onMapReady={() => console.log('Map is ready!')}
    />
  );
}
```

## API Reference

### Props

#### Map Configuration

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `mapType` | `'standard' \| 'satellite'` | `'standard'` | Map display type |
| `showsBuildings` | `boolean` | `true` | Show 3D buildings |
| `showsTraffic` | `boolean` | `false` | Show traffic layer |
| `showsLabels` | `boolean` | `true` | Show text labels |
| `showsUserLocation` | `boolean` | `false` | Show user's location |

#### Interaction Controls

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `zoomEnabled` | `boolean` | `true` | Enable pinch to zoom |
| `scrollEnabled` | `boolean` | `true` | Enable pan gestures |
| `rotateEnabled` | `boolean` | `true` | Enable rotation gestures |
| `tiltEnabled` | `boolean` | `true` | Enable 3D tilt gestures |

#### Marker Features

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `clusteringEnabled` | `boolean` | `false` | Enable automatic marker clustering |

#### Events

| Event | Payload | Description |
|-------|---------|-------------|
| `onMapReady` | `void` | Called when map is loaded |
| `onRegionChange` | `RegionChangeEvent` | Called when visible region changes |
| `onMapPress` | `MapPressEvent` | Called when map is tapped |
| `onMapLongPress` | `MapPressEvent` | Called when map is long pressed |
| `onMarkerPress` | `MarkerPressEvent` | Called when marker is tapped |
| `onClusterPress` | `ClusterPressEvent` | Called when marker cluster is tapped |

### Methods

Access these methods via ref:

```tsx
const mapRef = useRef<AmapViewHandle>(null);
```

#### Camera Control

```tsx
// Animate to a specific location
await mapRef.current?.animateToRegion(
  39.9042,    // latitude
  116.4074,   // longitude
  15,         // zoom level
  1000        // duration in ms (optional)
);

// Set camera position (no animation)
await mapRef.current?.setCamera({
  latitude: 39.9042,
  longitude: 116.4074,
  zoom: 15,
  tilt: 45,      // optional
  rotation: 90   // optional
});
```

#### Markers

```tsx
// Add a marker
await mapRef.current?.addMarker({
  id: 'marker-1',
  coordinate: { latitude: 39.9042, longitude: 116.4074 },
  title: 'Beijing',
  subtitle: 'Capital of China',
  showsCallout: true,
  icon: 'https://example.com/icon.png' // optional custom icon
});

// Remove a marker
await mapRef.current?.removeMarker('marker-1');

// Clear all markers
await mapRef.current?.clearMarkers();

// Show/hide marker callout
await mapRef.current?.showCallout('marker-1');
await mapRef.current?.hideCallout('marker-1');
```

#### Custom Marker Icons

Markers support custom icons from various sources:

```tsx
// From URL
await mapRef.current?.addMarker({
  id: 'marker-url',
  coordinate: { latitude: 39.9042, longitude: 116.4074 },
  icon: 'https://example.com/marker-icon.png'
});

// From local asset (iOS)
await mapRef.current?.addMarker({
  id: 'marker-asset',
  coordinate: { latitude: 39.9042, longitude: 116.4074 },
  icon: 'marker_icon' // Name of image in Assets.xcassets
});

// From drawable resource (Android)
await mapRef.current?.addMarker({
  id: 'marker-drawable',
  coordinate: { latitude: 39.9042, longitude: 116.4074 },
  icon: 'marker_icon' // Name of drawable resource
});
```

#### Marker Clustering

Enable clustering to group nearby markers:

```tsx
<AmapView
  ref={mapRef}
  clusteringEnabled={true}
  onClusterPress={(event) => {
    console.log(`Cluster with ${event.markerCount} markers`);
    console.log(`Location: ${event.coordinate.latitude}, ${event.coordinate.longitude}`);
  }}
/>
```

Clustering features:
- Automatic grouping of markers within 60 pixels
- Purple cluster markers with marker count
- Custom `onClusterPress` event
- Re-clusters automatically when map moves

#### Overlays

##### Polyline

```tsx
await mapRef.current?.addPolyline({
  id: 'polyline-1',
  coordinates: [
    { latitude: 39.9042, longitude: 116.4074 },
    { latitude: 39.9142, longitude: 116.4174 },
    { latitude: 39.9242, longitude: 116.4274 }
  ],
  strokeColor: '#FF0000',
  strokeWidth: 5
});

await mapRef.current?.removePolyline('polyline-1');
await mapRef.current?.clearPolylines();
```

##### Polygon

```tsx
await mapRef.current?.addPolygon({
  id: 'polygon-1',
  coordinates: [
    { latitude: 39.9042, longitude: 116.4074 },
    { latitude: 39.9142, longitude: 116.4174 },
    { latitude: 39.9242, longitude: 116.4074 }
  ],
  strokeColor: '#00FF00',
  strokeWidth: 3,
  fillColor: '#0000FF80'
});

await mapRef.current?.removePolygon('polygon-1');
await mapRef.current?.clearPolygons();
```

##### Circle

```tsx
await mapRef.current?.addCircle({
  id: 'circle-1',
  center: { latitude: 39.9042, longitude: 116.4074 },
  radius: 1000, // meters
  strokeColor: '#FF0000',
  strokeWidth: 2,
  fillColor: '#FF000040'
});

await mapRef.current?.removeCircle('circle-1');
await mapRef.current?.clearCircles();
```

## Type Definitions

```typescript
interface LatLng {
  latitude: number;
  longitude: number;
}

interface Marker {
  id: string;
  coordinate: LatLng;
  title?: string;
  subtitle?: string;
  showsCallout?: boolean;
  icon?: string | number; // URL, asset name, or require()
}

interface MapPressEvent {
  coordinate: LatLng;
}

interface MarkerPressEvent {
  id: string;
  coordinate: LatLng;
}

interface RegionChangeEvent {
  latitude: number;
  longitude: number;
  latitudeDelta: number;
  longitudeDelta: number;
  zoom: number;
}

interface ClusterPressEvent {
  coordinate: LatLng;
  markerCount: number;
}
```

## Complete Example

```tsx
import React, { useRef, useState } from 'react';
import { View, Button, StyleSheet } from 'react-native';
import { AmapView, type AmapViewHandle } from '@jindun619/react-native-amap';

export default function App() {
  const mapRef = useRef<AmapViewHandle>(null);
  const [clusteringEnabled, setClusteringEnabled] = useState(false);
  const [markerCount, setMarkerCount] = useState(0);

  const handleAddMarker = () => {
    const id = `marker-${markerCount}`;
    mapRef.current?.addMarker({
      id,
      coordinate: {
        latitude: 39.9042 + (Math.random() - 0.5) * 0.1,
        longitude: 116.4074 + (Math.random() - 0.5) * 0.1
      },
      title: `Marker ${markerCount + 1}`,
      subtitle: `ID: ${id}`,
      icon: 'https://example.com/custom-icon.png' // Optional
    });
    setMarkerCount(markerCount + 1);
  };

  const handleGoToBeijing = () => {
    mapRef.current?.animateToRegion(39.9042, 116.4074, 12, 1000);
  };

  return (
    <View style={styles.container}>
      <AmapView
        ref={mapRef}
        style={styles.map}
        mapType="standard"
        showsUserLocation={true}
        clusteringEnabled={clusteringEnabled}
        onMapReady={() => console.log('Map ready!')}
        onMarkerPress={(event) => console.log('Marker pressed:', event.id)}
        onClusterPress={(event) =>
          console.log(`Cluster: ${event.markerCount} markers`)
        }
      />
      <View style={styles.controls}>
        <Button title="Add Marker" onPress={handleAddMarker} />
        <Button title="Go to Beijing" onPress={handleGoToBeijing} />
        <Button
          title={clusteringEnabled ? 'Disable Clustering' : 'Enable Clustering'}
          onPress={() => setClusteringEnabled(!clusteringEnabled)}
        />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  map: { flex: 1 },
  controls: { position: 'absolute', bottom: 20, left: 20, right: 20 }
});
```

## Troubleshooting

### Map is not displaying

**Most common issue**: Missing AMap SDK initialization in AppDelegate (iOS)

Make sure you added the privacy compliance and HTTPS configuration in `AppDelegate.mm` or `AppDelegate.swift`:

```swift
MAMapView.updatePrivacyShow(.didShow, privacyInfo: .didContain)
MAMapView.updatePrivacyAgree(.didAgree)
AMapServices.shared().enableHTTPS = true
```

**Other common issues**:

1. **Invalid API Key**: Make sure you're using the correct API key for iOS/Android
2. **Missing permissions**: Ensure all required permissions are added to AndroidManifest.xml
3. **Missing Maven repository**: Android needs the AMap Maven repository in build.gradle
4. **Pod install**: iOS requires running `pod install` after installation
5. **Clean rebuild**: Try cleaning and rebuilding the project:
   ```sh
   # iOS
   cd ios && rm -rf Pods Podfile.lock && pod install

   # Android
   cd android && ./gradlew clean
   ```

### Map displays but crashes on interaction

This is usually due to missing privacy compliance setup on iOS. Make sure the privacy methods are called **before** any map view is created.

### Location not showing

1. Check that location permissions are granted
2. Verify `showsUserLocation={true}` prop is set
3. On iOS, ensure Info.plist has location usage descriptions

## Requirements

- React Native >= 0.81.0 (New Architecture)
- iOS >= 12.0
- Android >= API 21
- AMap API Keys (separate for iOS and Android)

## License

MIT

---

Made with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
