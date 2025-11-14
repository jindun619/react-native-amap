import type { ViewProps } from 'react-native';
import type { DirectEventHandler } from 'react-native/Libraries/Types/CodegenTypes';
import { codegenNativeComponent } from 'react-native';

export type MapType = 'standard' | 'satellite';

//Overlay types
export interface Coordinate {
  latitude: number;
  longitude: number;
}

export interface PolylineOptions {
  id: string;
  coordinates: ReadonlyArray<Coordinate>;
  strokeColor?: string;
  strokeWidth?: number;
}

export interface PolygonOptions {
  id: string;
  coordinates: ReadonlyArray<Coordinate>;
  strokeColor?: string;
  strokeWidth?: number;
  fillColor?: string;
}

export interface CircleOptions {
  id: string;
  center: Coordinate;
  radius: number; // in meters
  strokeColor?: string;
  strokeWidth?: number;
  fillColor?: string;
}

// Event payload types
export interface MapPressEventData {
  coordinate: Readonly<{
    latitude: string;
    longitude: string;
  }>;
}

export interface MarkerPressEventData {
  id: string;
  coordinate: Readonly<{
    latitude: string;
    longitude: string;
  }>;
}

export interface RegionChangeEventData {
  latitude: string;
  longitude: string;
  latitudeDelta: string;
  longitudeDelta: string;
  zoom: string;
}

export interface ClusterPressEventData {
  coordinate: Readonly<{
    latitude: string;
    longitude: string;
  }>;
  markerCount: string;
}

export interface NativeProps extends ViewProps {
  // Map display configuration (default: 'standard')
  mapType?: string;
  // Show 3D buildings (default: true)
  showsBuildings?: boolean;
  // Show traffic layer (default: false)
  showsTraffic?: boolean;
  // Show text labels (default: true)
  showsLabels?: boolean;

  // Map interaction controls (all default: true)
  zoomEnabled?: boolean;
  scrollEnabled?: boolean;
  rotateEnabled?: boolean;
  tiltEnabled?: boolean;

  // User location (default: false)
  showsUserLocation?: boolean;

  // Marker clustering (default: false)
  clusteringEnabled?: boolean;

  // Event handlers
  onMapReady?: DirectEventHandler<{}>;
  onRegionChange?: DirectEventHandler<RegionChangeEventData>;
  onMapPress?: DirectEventHandler<MapPressEventData>;
  onMapLongPress?: DirectEventHandler<MapPressEventData>;
  onMarkerPress?: DirectEventHandler<MarkerPressEventData>;
  onClusterPress?: DirectEventHandler<ClusterPressEventData>;
}

export default codegenNativeComponent<NativeProps>('AmapView');
