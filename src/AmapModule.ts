import { NativeModules } from 'react-native';

export interface LatLng {
  latitude: number;
  longitude: number;
}

export interface CameraPosition {
  latitude: number;
  longitude: number;
  zoom: number;
  tilt?: number;
  rotation?: number;
}

export interface Marker {
  id: string;
  coordinate: LatLng;
  title?: string;
  subtitle?: string;
  showsCallout?: boolean; // Show callout/info window on marker (default: true if title/subtitle provided)
  icon?: string | number; // Custom icon: URL string, asset name string, or require() number
}

export interface Region {
  latitude: number;
  longitude: number;
  latitudeDelta: number;
  longitudeDelta: number;
}

export interface Polyline {
  id: string;
  coordinates: LatLng[];
  strokeColor?: string;
  strokeWidth?: number;
}

export interface Polygon {
  id: string;
  coordinates: LatLng[];
  strokeColor?: string;
  strokeWidth?: number;
  fillColor?: string;
}

export interface Circle {
  id: string;
  center: LatLng;
  radius: number; // in meters
  strokeColor?: string;
  strokeWidth?: number;
  fillColor?: string;
}

interface AmapModuleInterface {
  animateToRegion(
    viewTag: number,
    latitude: number,
    longitude: number,
    zoom: number,
    duration?: number
  ): Promise<void>;

  setCamera(
    viewTag: number,
    latitude: number,
    longitude: number,
    zoom: number,
    tilt?: number,
    rotation?: number
  ): Promise<void>;

  addMarker(
    viewTag: number,
    id: string,
    latitude: number,
    longitude: number,
    title?: string,
    subtitle?: string,
    showsCallout?: boolean,
    icon?: string | number
  ): Promise<void>;

  removeMarker(viewTag: number, id: string): Promise<void>;

  clearMarkers(viewTag: number): Promise<void>;

  // Callout methods
  showCallout(viewTag: number, markerId: string): Promise<void>;
  hideCallout(viewTag: number, markerId: string): Promise<void>;

  // Polyline methods
  addPolyline(
    viewTag: number,
    id: string,
    coordinates: LatLng[],
    strokeColor?: string,
    strokeWidth?: number
  ): Promise<void>;

  removePolyline(viewTag: number, id: string): Promise<void>;

  clearPolylines(viewTag: number): Promise<void>;

  // Polygon methods
  addPolygon(
    viewTag: number,
    id: string,
    coordinates: LatLng[],
    strokeColor?: string,
    strokeWidth?: number,
    fillColor?: string
  ): Promise<void>;

  removePolygon(viewTag: number, id: string): Promise<void>;

  clearPolygons(viewTag: number): Promise<void>;

  // Circle methods
  addCircle(
    viewTag: number,
    id: string,
    latitude: number,
    longitude: number,
    radius: number,
    strokeColor?: string,
    strokeWidth?: number,
    fillColor?: string
  ): Promise<void>;

  removeCircle(viewTag: number, id: string): Promise<void>;

  clearCircles(viewTag: number): Promise<void>;
}

const { AmapModule } = NativeModules;

export default AmapModule as AmapModuleInterface;
