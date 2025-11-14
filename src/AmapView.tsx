import {
  forwardRef,
  useImperativeHandle,
  useRef,
  useCallback,
  type ComponentProps,
} from 'react';
import { findNodeHandle } from 'react-native';
import AmapViewNativeComponent, {
  type MapPressEventData,
  type MarkerPressEventData,
  type RegionChangeEventData,
  type ClusterPressEventData,
} from './AmapViewNativeComponent';
import AmapModule, {
  type CameraPosition,
  type Marker,
  type LatLng,
  type Polyline,
  type Polygon,
  type Circle,
} from './AmapModule';

// User-friendly event types with numbers
export interface MapPressEvent {
  coordinate: LatLng;
}

export interface MarkerPressEvent {
  id: string;
  coordinate: LatLng;
}

export interface RegionChangeEvent {
  latitude: number;
  longitude: number;
  latitudeDelta: number;
  longitudeDelta: number;
  zoom: number;
}

export interface ClusterPressEvent {
  coordinate: LatLng;
  markerCount: number;
}

// Props type that includes both native props and custom event handlers
export type AmapViewProps = Omit<
  ComponentProps<typeof AmapViewNativeComponent>,
  | 'onMapReady'
  | 'onRegionChange'
  | 'onMapPress'
  | 'onMapLongPress'
  | 'onMarkerPress'
  | 'onClusterPress'
> & {
  onMapReady?: () => void;
  onRegionChange?: (event: RegionChangeEvent) => void;
  onMapPress?: (event: MapPressEvent) => void;
  onMapLongPress?: (event: MapPressEvent) => void;
  onMarkerPress?: (event: MarkerPressEvent) => void;
  onClusterPress?: (event: ClusterPressEvent) => void;
};

export interface AmapViewHandle {
  /**
   * Animate camera to specific region
   */
  animateToRegion(
    latitude: number,
    longitude: number,
    zoom: number,
    duration?: number
  ): Promise<void>;

  /**
   * Set camera position (no animation)
   */
  setCamera(camera: CameraPosition): Promise<void>;

  /**
   * Add a marker to the map
   */
  addMarker(marker: Marker): Promise<void>;

  /**
   * Remove a marker by ID
   */
  removeMarker(id: string): Promise<void>;

  /**
   * Remove all markers
   */
  clearMarkers(): Promise<void>;

  /**
   * Show callout for a marker
   */
  showCallout(markerId: string): Promise<void>;

  /**
   * Hide callout for a marker
   */
  hideCallout(markerId: string): Promise<void>;

  /**
   * Add a polyline to the map
   */
  addPolyline(polyline: Polyline): Promise<void>;

  /**
   * Remove a polyline by ID
   */
  removePolyline(id: string): Promise<void>;

  /**
   * Remove all polylines
   */
  clearPolylines(): Promise<void>;

  /**
   * Add a polygon to the map
   */
  addPolygon(polygon: Polygon): Promise<void>;

  /**
   * Remove a polygon by ID
   */
  removePolygon(id: string): Promise<void>;

  /**
   * Remove all polygons
   */
  clearPolygons(): Promise<void>;

  /**
   * Add a circle to the map
   */
  addCircle(circle: Circle): Promise<void>;

  /**
   * Remove a circle by ID
   */
  removeCircle(id: string): Promise<void>;

  /**
   * Remove all circles
   */
  clearCircles(): Promise<void>;
}

const AmapView = forwardRef<AmapViewHandle, AmapViewProps>((props, ref) => {
  const nativeRef = useRef(null);

  // Destructure props
  const {
    onMapReady,
    onRegionChange,
    onMapPress,
    onMapLongPress,
    onMarkerPress,
    onClusterPress,
    ...restProps
  } = props;

  // Event handler converters (string to number)
  const handleRegionChange = useCallback(
    (event: { nativeEvent: RegionChangeEventData }) => {
      if (onRegionChange) {
        onRegionChange({
          latitude: parseFloat(event.nativeEvent.latitude),
          longitude: parseFloat(event.nativeEvent.longitude),
          latitudeDelta: parseFloat(event.nativeEvent.latitudeDelta),
          longitudeDelta: parseFloat(event.nativeEvent.longitudeDelta),
          zoom: parseFloat(event.nativeEvent.zoom),
        });
      }
    },
    [onRegionChange]
  );

  const handleMapPress = useCallback(
    (event: { nativeEvent: MapPressEventData }) => {
      if (onMapPress) {
        onMapPress({
          coordinate: {
            latitude: parseFloat(event.nativeEvent.coordinate.latitude),
            longitude: parseFloat(event.nativeEvent.coordinate.longitude),
          },
        });
      }
    },
    [onMapPress]
  );

  const handleMapLongPress = useCallback(
    (event: { nativeEvent: MapPressEventData }) => {
      if (onMapLongPress) {
        onMapLongPress({
          coordinate: {
            latitude: parseFloat(event.nativeEvent.coordinate.latitude),
            longitude: parseFloat(event.nativeEvent.coordinate.longitude),
          },
        });
      }
    },
    [onMapLongPress]
  );

  const handleMarkerPress = useCallback(
    (event: { nativeEvent: MarkerPressEventData }) => {
      if (onMarkerPress) {
        onMarkerPress({
          id: event.nativeEvent.id,
          coordinate: {
            latitude: parseFloat(event.nativeEvent.coordinate.latitude),
            longitude: parseFloat(event.nativeEvent.coordinate.longitude),
          },
        });
      }
    },
    [onMarkerPress]
  );

  const handleClusterPress = useCallback(
    (event: { nativeEvent: ClusterPressEventData }) => {
      if (onClusterPress) {
        onClusterPress({
          coordinate: {
            latitude: parseFloat(event.nativeEvent.coordinate.latitude),
            longitude: parseFloat(event.nativeEvent.coordinate.longitude),
          },
          markerCount: parseInt(event.nativeEvent.markerCount, 10),
        });
      }
    },
    [onClusterPress]
  );

  useImperativeHandle(ref, () => ({
    async animateToRegion(
      latitude: number,
      longitude: number,
      zoom: number,
      duration?: number
    ) {
      const handle = findNodeHandle(nativeRef.current);
      if (handle) {
        await AmapModule.animateToRegion(
          handle,
          latitude,
          longitude,
          zoom,
          duration
        );
      }
    },

    async setCamera(camera: CameraPosition) {
      const handle = findNodeHandle(nativeRef.current);
      if (handle) {
        await AmapModule.setCamera(
          handle,
          camera.latitude,
          camera.longitude,
          camera.zoom,
          camera.tilt,
          camera.rotation
        );
      }
    },

    async addMarker(marker: Marker) {
      const handle = findNodeHandle(nativeRef.current);
      if (handle) {
        await AmapModule.addMarker(
          handle,
          marker.id,
          marker.coordinate.latitude,
          marker.coordinate.longitude,
          marker.title,
          marker.subtitle,
          marker.showsCallout,
          marker.icon
        );
      }
    },

    async removeMarker(id: string) {
      const handle = findNodeHandle(nativeRef.current);
      if (handle) {
        await AmapModule.removeMarker(handle, id);
      }
    },

    async clearMarkers() {
      const handle = findNodeHandle(nativeRef.current);
      if (handle) {
        await AmapModule.clearMarkers(handle);
      }
    },

    async showCallout(markerId: string) {
      const handle = findNodeHandle(nativeRef.current);
      if (handle) {
        await AmapModule.showCallout(handle, markerId);
      }
    },

    async hideCallout(markerId: string) {
      const handle = findNodeHandle(nativeRef.current);
      if (handle) {
        await AmapModule.hideCallout(handle, markerId);
      }
    },

    async addPolyline(polyline: Polyline) {
      const handle = findNodeHandle(nativeRef.current);
      if (handle) {
        await AmapModule.addPolyline(
          handle,
          polyline.id,
          polyline.coordinates,
          polyline.strokeColor,
          polyline.strokeWidth
        );
      }
    },

    async removePolyline(id: string) {
      const handle = findNodeHandle(nativeRef.current);
      if (handle) {
        await AmapModule.removePolyline(handle, id);
      }
    },

    async clearPolylines() {
      const handle = findNodeHandle(nativeRef.current);
      if (handle) {
        await AmapModule.clearPolylines(handle);
      }
    },

    async addPolygon(polygon: Polygon) {
      const handle = findNodeHandle(nativeRef.current);
      if (handle) {
        await AmapModule.addPolygon(
          handle,
          polygon.id,
          polygon.coordinates,
          polygon.strokeColor,
          polygon.strokeWidth,
          polygon.fillColor
        );
      }
    },

    async removePolygon(id: string) {
      const handle = findNodeHandle(nativeRef.current);
      if (handle) {
        await AmapModule.removePolygon(handle, id);
      }
    },

    async clearPolygons() {
      const handle = findNodeHandle(nativeRef.current);
      if (handle) {
        await AmapModule.clearPolygons(handle);
      }
    },

    async addCircle(circle: Circle) {
      const handle = findNodeHandle(nativeRef.current);
      if (handle) {
        await AmapModule.addCircle(
          handle,
          circle.id,
          circle.center.latitude,
          circle.center.longitude,
          circle.radius,
          circle.strokeColor,
          circle.strokeWidth,
          circle.fillColor
        );
      }
    },

    async removeCircle(id: string) {
      const handle = findNodeHandle(nativeRef.current);
      if (handle) {
        await AmapModule.removeCircle(handle, id);
      }
    },

    async clearCircles() {
      const handle = findNodeHandle(nativeRef.current);
      if (handle) {
        await AmapModule.clearCircles(handle);
      }
    },
  }));

  return (
    <AmapViewNativeComponent
      ref={nativeRef}
      {...restProps}
      onMapReady={onMapReady}
      onRegionChange={onRegionChange ? handleRegionChange : undefined}
      onMapPress={onMapPress ? handleMapPress : undefined}
      onMapLongPress={onMapLongPress ? handleMapLongPress : undefined}
      onMarkerPress={onMarkerPress ? handleMarkerPress : undefined}
      onClusterPress={onClusterPress ? handleClusterPress : undefined}
    />
  );
});

AmapView.displayName = 'AmapView';

export default AmapView;
