# react-native-amap

[![npm version](https://img.shields.io/npm/v/@jindun619/react-native-amap.svg)](https://www.npmjs.com/package/@jindun619/react-native-amap)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

React Native bridge for AMap (高德地图) iOS/Android SDK with full **New Architecture (Fabric)** support and **built-in Expo config plugin**.

<div align="center">
  <img src="https://user-images.githubusercontent.com/placeholder/demo.gif" alt="Demo" width="300"/>
</div>

---

## Table of Contents

- [Features](#features)
- [Installation](#installation)
  - [Expo Managed Workflow](#expo-managed-workflow-recommended)
  - [Bare React Native](#bare-react-native)
- [Getting Your API Keys](#getting-your-api-keys)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [API Reference](#api-reference)
  - [Props](#props)
  - [Methods](#methods)
  - [Events](#events)
  - [Types](#types)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)
- [Requirements](#requirements)
- [Contributing](#contributing)
- [License](#license)

---

## Features

- ✅ **New Architecture Ready** - Full support for React Native 0.81+ with Fabric and TurboModules
- 🎯 **Expo Config Plugin** - Zero-config setup for Expo managed workflow
- 🗺️ **Map Display** - Standard and satellite map types with full gesture controls
- 📍 **Markers** - Add, remove, and customize markers with callouts
- 🎨 **Custom Icons** - Support for custom marker icons from URLs or local assets
- 🔢 **Marker Clustering** - Automatic marker clustering with customizable appearance
- 📐 **Overlays** - Polylines, polygons, and circles with customizable styles
- 📱 **User Location** - Show user's current location on the map
- 🎯 **Camera Control** - Programmatic camera positioning with smooth animations
- 📡 **Events** - Rich event system for map interactions

---

## Installation

### Expo Managed Workflow (Recommended)

The easiest way to use this library in Expo projects - **just 2 steps**!

#### Step 1: Install the package

```sh
npx expo install @jindun619/react-native-amap
```

The config plugin will be **automatically detected** by Expo CLI!

#### Step 2: Add your API keys

**Option A: Using environment variables (Recommended)**

Create a `.env` file in your project root:

```bash
# .env (add this file to .gitignore!)
EXPO_PUBLIC_AMAP_IOS_API_KEY=your_ios_api_key_here
EXPO_PUBLIC_AMAP_ANDROID_API_KEY=your_android_api_key_here
```

**Option B: Using app.config.js**

```javascript
// app.config.js
export default {
  expo: {
    // ... other config
    plugins: [
      [
        '@jindun619/react-native-amap',
        {
          iosApiKey: 'your_ios_api_key',
          androidApiKey: 'your_android_api_key',
          // Optional: custom permission descriptions
          iosLocationWhenInUseDescription: 'We need your location to show your position on the map',
          iosLocationAlwaysDescription: 'We need your location to show your position on the map'
        }
      ]
    ]
  }
};
```

#### Step 3: Rebuild your app

```sh
# Prebuild to apply native changes
npx expo prebuild

# Run on your device/simulator
npx expo run:ios
# or
npx expo run:android
```

**That's it!** 🎉 The config plugin automatically handles:
- ✅ iOS Info.plist configuration (API key, location permissions, App Transport Security)
- ✅ iOS AppDelegate initialization (AMap SDK privacy compliance)
- ✅ Android AndroidManifest.xml setup (API key, permissions)
- ✅ Android build.gradle Maven repository configuration

---

### Bare React Native

#### Step 1: Install the package

```sh
npm install @jindun619/react-native-amap
# or
yarn add @jindun619/react-native-amap
```

#### Step 2: iOS Setup

1. **Install pods:**

```sh
cd ios && pod install
```

2. **Add AMap API key to `Info.plist`:**

```xml
<key>AMapApiKey</key>
<string>YOUR_AMAP_IOS_API_KEY</string>
```

3. **Add location permissions to `Info.plist`:**

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show your position on the map</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>We need your location to show your position on the map</string>
```

4. **Add App Transport Security exception to `Info.plist`:**

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

5. **⚠️ CRITICAL: Initialize AMap SDK in AppDelegate**

Without this step, the map will not display!

**For Objective-C (`AppDelegate.mm`):**

```objc
#import <AMapFoundationKit/AMapFoundationKit.h>
#import <MAMapKit/MAMapKit.h>

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  // Configure AMap SDK privacy compliance (MUST be called before MAMapView instantiation)
  [MAMapView updatePrivacyShow:AMapPrivacyShowStatusDidShow privacyInfo:AMapPrivacyInfoStatusDidContain];
  [MAMapView updatePrivacyAgree:AMapPrivacyAgreeStatusDidAgree];
  [[AMapServices sharedServices] setEnableHTTPS:YES];

  // ... rest of your AppDelegate code
  return YES;
}
```

**For Swift (`AppDelegate.swift`):**

```swift
import AMapFoundationKit
import MAMapKit

func application(
  _ application: UIApplication,
  didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
) -> Bool {
  // Configure AMap SDK privacy compliance
  MAMapView.updatePrivacyShow(.didShow, privacyInfo: .didContain)
  MAMapView.updatePrivacyAgree(.didAgree)
  AMapServices.shared().enableHTTPS = true

  // ... rest of your AppDelegate code
  return true
}
```

#### Step 3: Android Setup

1. **Add AMap Maven repository to `android/build.gradle`:**

```gradle
allprojects {
  repositories {
    // ... other repositories
    maven { url "https://maven.aliyun.com/repository/public" }
  }
}
```

2. **Add permissions and API key to `AndroidManifest.xml`:**

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
      android:value="YOUR_AMAP_ANDROID_API_KEY" />

    <!-- ... rest of your application config -->
  </application>
</manifest>
```

---

## Getting Your API Keys

You need separate API keys for iOS and Android from AMap:

1. Go to [AMap Developer Console](https://console.amap.com/)
2. Create an account or sign in
3. Create a new application
4. Get your **iOS** and **Android** API keys (they are different!)

**Important**:
- iOS and Android require **separate API keys**
- Keep your API keys secure (use `.env` file and add it to `.gitignore`)

---

## Quick Start

### Basic Example

```tsx
import React, { useRef } from 'react';
import { StyleSheet, View } from 'react-native';
import { AmapView, type AmapViewHandle } from '@jindun619/react-native-amap';

export default function App() {
  const mapRef = useRef<AmapViewHandle>(null);

  return (
    <View style={styles.container}>
      <AmapView
        ref={mapRef}
        style={styles.map}
        mapType="standard"
        showsUserLocation={true}
        onMapReady={() => console.log('Map is ready!')}
        onMapPress={(event) => console.log('Map pressed:', event.coordinate)}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  map: { flex: 1 },
});
```

### Adding Markers

```tsx
import { useEffect, useRef } from 'react';
import { AmapView, type AmapViewHandle } from '@jindun619/react-native-amap';

export default function MapWithMarkers() {
  const mapRef = useRef<AmapViewHandle>(null);

  useEffect(() => {
    // Add marker when map is ready
    const addMarker = async () => {
      await mapRef.current?.addMarker({
        id: 'beijing',
        coordinate: { latitude: 39.9042, longitude: 116.4074 },
        title: 'Beijing',
        subtitle: 'Capital of China',
        showsCallout: true,
      });

      // Animate camera to marker
      await mapRef.current?.animateToRegion(39.9042, 116.4074, 15, 1000);
    };

    addMarker();
  }, []);

  return (
    <AmapView
      ref={mapRef}
      style={{ flex: 1 }}
      showsUserLocation={true}
      onMarkerPress={(event) => console.log('Marker pressed:', event.id)}
    />
  );
}
```

---

## Configuration

### Expo Config Plugin Options

When using Expo, you can configure the plugin in `app.config.js`:

```javascript
export default {
  expo: {
    plugins: [
      [
        '@jindun619/react-native-amap',
        {
          // Required: API keys
          iosApiKey: 'your_ios_key',           // or use EXPO_PUBLIC_AMAP_IOS_API_KEY env var
          androidApiKey: 'your_android_key',   // or use EXPO_PUBLIC_AMAP_ANDROID_API_KEY env var

          // Optional: Custom permission descriptions
          iosLocationWhenInUseDescription: 'Custom description for location permission',
          iosLocationAlwaysDescription: 'Custom description for always location permission',
        }
      ]
    ]
  }
};
```

### Environment Variables

For better security, use environment variables:

```bash
# .env
EXPO_PUBLIC_AMAP_IOS_API_KEY=your_ios_key
EXPO_PUBLIC_AMAP_ANDROID_API_KEY=your_android_key
```

The plugin will automatically read these variables if API keys are not provided in the config.

---

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

---

### Methods

Access these methods via ref:

```tsx
const mapRef = useRef<AmapViewHandle>(null);
```

#### Camera Control

```tsx
// Animate to a specific location
await mapRef.current?.animateToRegion(
  latitude: number,
  longitude: number,
  zoom: number,
  duration?: number  // milliseconds (optional)
);

// Set camera position (no animation)
await mapRef.current?.setCamera({
  latitude: number,
  longitude: number,
  zoom: number,
  tilt?: number,      // 0-60 degrees (optional)
  rotation?: number   // 0-360 degrees (optional)
});
```

#### Marker Management

```tsx
// Add a marker
await mapRef.current?.addMarker({
  id: string,
  coordinate: { latitude: number, longitude: number },
  title?: string,
  subtitle?: string,
  showsCallout?: boolean,
  icon?: string  // URL, asset name, or require()
});

// Remove a marker
await mapRef.current?.removeMarker(id: string);

// Clear all markers
await mapRef.current?.clearMarkers();

// Show/hide marker callout
await mapRef.current?.showCallout(id: string);
await mapRef.current?.hideCallout(id: string);
```

#### Overlays

**Polyline:**
```tsx
await mapRef.current?.addPolyline({
  id: string,
  coordinates: Array<{ latitude: number, longitude: number }>,
  strokeColor?: string,  // hex color (e.g., '#FF0000')
  strokeWidth?: number   // in pixels
});

await mapRef.current?.removePolyline(id: string);
await mapRef.current?.clearPolylines();
```

**Polygon:**
```tsx
await mapRef.current?.addPolygon({
  id: string,
  coordinates: Array<{ latitude: number, longitude: number }>,
  strokeColor?: string,
  strokeWidth?: number,
  fillColor?: string  // hex color with alpha (e.g., '#FF000080')
});

await mapRef.current?.removePolygon(id: string);
await mapRef.current?.clearPolygons();
```

**Circle:**
```tsx
await mapRef.current?.addCircle({
  id: string,
  center: { latitude: number, longitude: number },
  radius: number,  // in meters
  strokeColor?: string,
  strokeWidth?: number,
  fillColor?: string
});

await mapRef.current?.removeCircle(id: string);
await mapRef.current?.clearCircles();
```

---

### Events

| Event | Payload | Description |
|-------|---------|-------------|
| `onMapReady` | `void` | Called when map is loaded and ready |
| `onRegionChange` | `RegionChangeEvent` | Called when visible region changes |
| `onMapPress` | `MapPressEvent` | Called when map is tapped |
| `onMapLongPress` | `MapPressEvent` | Called when map is long pressed |
| `onMarkerPress` | `MarkerPressEvent` | Called when marker is tapped |
| `onClusterPress` | `ClusterPressEvent` | Called when marker cluster is tapped |

---

### Types

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
  icon?: string | number;
}

interface CameraPosition {
  latitude: number;
  longitude: number;
  zoom: number;
  tilt?: number;      // 0-60 degrees
  rotation?: number;  // 0-360 degrees
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

interface Polyline {
  id: string;
  coordinates: LatLng[];
  strokeColor?: string;
  strokeWidth?: number;
}

interface Polygon {
  id: string;
  coordinates: LatLng[];
  strokeColor?: string;
  strokeWidth?: number;
  fillColor?: string;
}

interface Circle {
  id: string;
  center: LatLng;
  radius: number;  // in meters
  strokeColor?: string;
  strokeWidth?: number;
  fillColor?: string;
}
```

---

## Examples

### Complete Example with All Features

```tsx
import React, { useRef, useState } from 'react';
import { View, Button, StyleSheet } from 'react-native';
import { AmapView, type AmapViewHandle } from '@jindun619/react-native-amap';

export default function App() {
  const mapRef = useRef<AmapViewHandle>(null);
  const [clusteringEnabled, setClusteringEnabled] = useState(false);
  const [markerCount, setMarkerCount] = useState(0);

  const handleAddMarker = async () => {
    const id = `marker-${markerCount}`;
    await mapRef.current?.addMarker({
      id,
      coordinate: {
        latitude: 39.9042 + (Math.random() - 0.5) * 0.1,
        longitude: 116.4074 + (Math.random() - 0.5) * 0.1
      },
      title: `Marker ${markerCount + 1}`,
      subtitle: `ID: ${id}`,
      showsCallout: true,
    });
    setMarkerCount(markerCount + 1);
  };

  const handleAddPolyline = async () => {
    await mapRef.current?.addPolyline({
      id: 'route-1',
      coordinates: [
        { latitude: 39.9042, longitude: 116.4074 },
        { latitude: 39.9142, longitude: 116.4174 },
        { latitude: 39.9242, longitude: 116.4274 }
      ],
      strokeColor: '#FF0000',
      strokeWidth: 5
    });
  };

  const handleAddCircle = async () => {
    await mapRef.current?.addCircle({
      id: 'area-1',
      center: { latitude: 39.9042, longitude: 116.4074 },
      radius: 1000,
      strokeColor: '#0000FF',
      strokeWidth: 2,
      fillColor: '#0000FF40'
    });
  };

  const handleGoToBeijing = async () => {
    await mapRef.current?.animateToRegion(39.9042, 116.4074, 12, 1000);
  };

  return (
    <View style={styles.container}>
      <AmapView
        ref={mapRef}
        style={styles.map}
        mapType="standard"
        showsUserLocation={true}
        showsTraffic={false}
        clusteringEnabled={clusteringEnabled}
        onMapReady={() => console.log('Map ready!')}
        onMapPress={(event) => console.log('Map pressed:', event.coordinate)}
        onMarkerPress={(event) => console.log('Marker pressed:', event.id)}
        onClusterPress={(event) =>
          console.log(`Cluster: ${event.markerCount} markers`)
        }
        onRegionChange={(event) => console.log('Region changed:', event)}
      />

      <View style={styles.controls}>
        <Button title="Add Marker" onPress={handleAddMarker} />
        <Button title="Add Polyline" onPress={handleAddPolyline} />
        <Button title="Add Circle" onPress={handleAddCircle} />
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
  controls: {
    position: 'absolute',
    bottom: 20,
    left: 20,
    right: 20,
    gap: 10,
  },
});
```

### Custom Marker Icons

```tsx
// From URL
await mapRef.current?.addMarker({
  id: 'marker-url',
  coordinate: { latitude: 39.9042, longitude: 116.4074 },
  icon: 'https://example.com/marker-icon.png'
});

// From local asset (iOS: Assets.xcassets, Android: drawable)
await mapRef.current?.addMarker({
  id: 'marker-asset',
  coordinate: { latitude: 39.9042, longitude: 116.4074 },
  icon: 'marker_icon'  // asset name without extension
});
```

### Marker Clustering

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

---

## Troubleshooting

### Map is not displaying

**Most common issue**: Missing AMap SDK initialization in AppDelegate (iOS)

Make sure you added the privacy compliance and HTTPS configuration in `AppDelegate.mm` or `AppDelegate.swift`:

```swift
MAMapView.updatePrivacyShow(.didShow, privacyInfo: .didContain)
MAMapView.updatePrivacyAgree(.didAgree)
AMapServices.shared().enableHTTPS = true
```

**For Expo users**: The config plugin should handle this automatically. If the map still doesn't display:
1. Run `npx expo prebuild --clean` to regenerate native code
2. Rebuild your development build
3. Check that your API keys are correctly set in `.env` or `app.config.js`

### Other common issues

**1. Invalid API Key**
- Make sure you're using the correct API key for iOS/Android
- iOS and Android keys are different - don't mix them up!
- Verify keys at [AMap Developer Console](https://console.amap.com/)

**2. Missing permissions (Android)**
- Ensure all required permissions are added to `AndroidManifest.xml`
- For Expo: plugin adds permissions automatically

**3. Missing Maven repository (Android)**
- Android needs the AMap Maven repository in `build.gradle`
- For Expo: plugin adds repository automatically

**4. Pod install fails (iOS)**
```sh
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
```

**5. Clean rebuild**
```sh
# iOS
cd ios && rm -rf Pods Podfile.lock && pod install && cd ..

# Android
cd android && ./gradlew clean && cd ..

# Expo
npx expo prebuild --clean
```

### Map displays but crashes on interaction

This is usually due to missing privacy compliance setup on iOS. Make sure the privacy methods are called **before** any map view is created.

### Location not showing

1. Check that location permissions are granted
2. Verify `showsUserLocation={true}` prop is set
3. On iOS, ensure `Info.plist` has location usage descriptions
4. Test on a real device (simulators may not have location)

### Expo: "Module not found" error

```sh
# Clear cache and restart
npx expo start --clear

# Or reinstall
rm -rf node_modules
npm install
npx expo prebuild --clean
```

### Build errors after upgrading

```sh
# Clean everything and rebuild
yarn clean
rm -rf node_modules yarn.lock
yarn install
npx expo prebuild --clean
```

---

## Requirements

- React Native >= 0.81.0 (New Architecture)
- iOS >= 12.0
- Android >= API 21
- AMap API Keys (separate for iOS and Android)

**For Expo:**
- Expo >= 54.0.0
- Development Build or Standalone Build (not Expo Go)

---

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please follow the [Conventional Commits](https://www.conventionalcommits.org/) specification for commit messages.

---

## License

MIT

---

## Acknowledgments

- Built with [create-react-native-library](https://github.com/callstack/react-native-builder-bob)
- Uses [AMap iOS SDK](https://lbs.amap.com/api/ios-sdk/summary)
- Uses [AMap Android SDK](https://lbs.amap.com/api/android-sdk/summary)

---

**Made with ❤️ by [jindun619](https://github.com/jindun619)**
