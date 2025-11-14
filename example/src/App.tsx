import {
  View,
  StyleSheet,
  Button,
  Text,
  ScrollView,
  TouchableOpacity,
} from 'react-native';
import {
  AmapView,
  type AmapViewHandle,
  type MapType,
} from '@jindun619/react-native-amap';
import { useState, useRef } from 'react';

export default function App() {
  const mapRef = useRef<AmapViewHandle>(null);
  const [mapType, setMapType] = useState<MapType>('standard');
  const [showsTraffic, setShowsTraffic] = useState(false);
  const [showsBuildings, _setShowsBuildings] = useState(true);
  const [showsUserLocation, setShowsUserLocation] = useState(false);
  const [markerCount, setMarkerCount] = useState(0);
  const [overlayCount, setOverlayCount] = useState({
    polyline: 0,
    polygon: 0,
    circle: 0,
  });
  const [eventLog, setEventLog] = useState<string[]>([]);
  const [controlsExpanded, setControlsExpanded] = useState(false);
  const [clusteringEnabled, setClusteringEnabled] = useState(false);

  // Beijing Tiananmen Square
  const handleGoToBeijing = () => {
    mapRef.current?.animateToRegion(39.9042, 116.4074, 15, 500);
  };

  // Shanghai
  const handleGoToShanghai = () => {
    mapRef.current?.animateToRegion(31.2304, 121.4737, 15, 500);
  };

  const handleAddMarker = () => {
    const id = `marker-${markerCount}`;
    // Add marker at current center (Beijing area)
    const lat = 39.9042 + (Math.random() - 0.5) * 0.1;
    const lng = 116.4074 + (Math.random() - 0.5) * 0.1;

    mapRef.current?.addMarker({
      id,
      coordinate: { latitude: lat, longitude: lng },
      title: `Marker ${markerCount + 1}`,
      subtitle: `ID: ${id}`,
    });

    setMarkerCount(markerCount + 1);
  };

  const handleClearMarkers = () => {
    mapRef.current?.clearMarkers();
    setMarkerCount(0);
  };

  const handleAddCustomIconMarker = () => {
    const id = `marker-${markerCount}`;
    const lat = 39.9042 + (Math.random() - 0.5) * 0.1;
    const lng = 116.4074 + (Math.random() - 0.5) * 0.1;

    // Add marker with custom icon from URL
    mapRef.current?.addMarker({
      id,
      coordinate: { latitude: lat, longitude: lng },
      title: `Custom Icon ${markerCount + 1}`,
      subtitle: `ID: ${id}`,
      icon: 'https://raw.githubusercontent.com/pointhi/leaflet-color-markers/master/img/marker-icon-2x-red.png',
    });

    setMarkerCount(markerCount + 1);
    addLog(
      `📍 Added custom icon marker at (${lat.toFixed(4)}, ${lng.toFixed(4)})`
    );
  };

  const handleAddManyMarkers = () => {
    // Add 20 markers around Beijing area for clustering demo
    for (let i = 0; i < 20; i++) {
      const id = `marker-${markerCount + i}`;
      const lat = 39.9042 + (Math.random() - 0.5) * 0.2;
      const lng = 116.4074 + (Math.random() - 0.5) * 0.2;

      mapRef.current?.addMarker({
        id,
        coordinate: { latitude: lat, longitude: lng },
        title: `Marker ${markerCount + i + 1}`,
        subtitle: `ID: ${id}`,
      });
    }

    setMarkerCount(markerCount + 20);
  };

  // Overlay handlers
  const handleAddPolyline = () => {
    const id = `polyline-${overlayCount.polyline}`;
    // Create a line path around Beijing
    const coordinates = [
      { latitude: 39.9042, longitude: 116.4074 },
      { latitude: 39.9142, longitude: 116.4174 },
      { latitude: 39.9242, longitude: 116.4074 },
    ];

    mapRef.current?.addPolyline({
      id,
      coordinates,
      strokeColor: '#FF0000',
      strokeWidth: 5,
    });

    setOverlayCount((prev) => ({ ...prev, polyline: prev.polyline + 1 }));
  };

  const handleAddPolygon = () => {
    const id = `polygon-${overlayCount.polygon}`;
    // Create a triangle around Beijing
    const coordinates = [
      { latitude: 39.8942, longitude: 116.3974 },
      { latitude: 39.8842, longitude: 116.4174 },
      { latitude: 39.8742, longitude: 116.3974 },
    ];

    mapRef.current?.addPolygon({
      id,
      coordinates,
      strokeColor: '#00FF00',
      strokeWidth: 3,
      fillColor: '#0000FF80',
    });

    setOverlayCount((prev) => ({ ...prev, polygon: prev.polygon + 1 }));
  };

  const handleAddCircle = () => {
    const id = `circle-${overlayCount.circle}`;
    // Add circle around Beijing
    const lat = 39.9042 + (Math.random() - 0.5) * 0.05;
    const lng = 116.4074 + (Math.random() - 0.5) * 0.05;

    mapRef.current?.addCircle({
      id,
      center: { latitude: lat, longitude: lng },
      radius: 1000, // 1km
      strokeColor: '#FF00FF',
      strokeWidth: 3,
      fillColor: '#FFFF0080',
    });

    setOverlayCount((prev) => ({ ...prev, circle: prev.circle + 1 }));
  };

  const handleClearOverlays = () => {
    mapRef.current?.clearPolylines();
    mapRef.current?.clearPolygons();
    mapRef.current?.clearCircles();
    setOverlayCount({ polyline: 0, polygon: 0, circle: 0 });
  };

  // Event handlers
  const addLog = (message: string) => {
    setEventLog((prev) => [message, ...prev].slice(0, 10)); // Keep last 10 events
  };

  const handleMapReady = () => {
    addLog('✅ Map Ready');
  };

  const handleRegionChange = (event: any) => {
    addLog(
      `📍 Region: ${event.latitude.toFixed(4)}, ${event.longitude.toFixed(
        4
      )} (Zoom: ${event.zoom.toFixed(1)})`
    );
  };

  const handleMapPress = (event: any) => {
    addLog(
      `👆 Tap: ${event.coordinate.latitude.toFixed(
        4
      )}, ${event.coordinate.longitude.toFixed(4)}`
    );
  };

  const handleMapLongPress = (event: any) => {
    addLog(
      `👆👆 Long Press: ${event.coordinate.latitude.toFixed(
        4
      )}, ${event.coordinate.longitude.toFixed(4)}`
    );
  };

  const handleMarkerPress = (event: any) => {
    addLog(`📌 Marker: ${event.id}`);
  };

  const handleClusterPress = (event: any) => {
    addLog(
      `🔢 Cluster: ${
        event.markerCount
      } markers at (${event.coordinate.latitude.toFixed(
        4
      )}, ${event.coordinate.longitude.toFixed(4)})`
    );
  };

  return (
    <View style={styles.container}>
      <AmapView
        ref={mapRef}
        style={styles.map}
        mapType={mapType}
        showsBuildings={showsBuildings}
        showsTraffic={showsTraffic}
        showsUserLocation={showsUserLocation}
        showsLabels={true}
        zoomEnabled={true}
        scrollEnabled={true}
        rotateEnabled={true}
        tiltEnabled={true}
        clusteringEnabled={clusteringEnabled}
        onMapReady={handleMapReady}
        onRegionChange={handleRegionChange}
        onMapPress={handleMapPress}
        onMapLongPress={handleMapLongPress}
        onMarkerPress={handleMarkerPress}
        onClusterPress={handleClusterPress}
      />

      <View style={styles.controlsContainer} pointerEvents="box-none">
        <TouchableOpacity
          style={styles.toggleButton}
          onPress={() => setControlsExpanded(!controlsExpanded)}
        >
          <Text style={styles.toggleButtonText}>
            {controlsExpanded ? '▼ Hide Controls' : '▲ Show Controls'}
          </Text>
        </TouchableOpacity>

        {controlsExpanded && (
          <ScrollView
            style={styles.controls}
            contentContainerStyle={styles.controlsContent}
          >
            <Button
              title={mapType === 'standard' ? 'Satellite' : 'Standard'}
              onPress={() =>
                setMapType(mapType === 'standard' ? 'satellite' : 'standard')
              }
            />
            <Button
              title={showsTraffic ? 'Hide Traffic' : 'Show Traffic'}
              onPress={() => setShowsTraffic(!showsTraffic)}
            />
            <Button
              title={showsUserLocation ? 'Hide Location' : 'Show Location'}
              onPress={() => setShowsUserLocation(!showsUserLocation)}
            />
            <Button title="Beijing" onPress={handleGoToBeijing} />
            <Button title="Shanghai" onPress={handleGoToShanghai} />
            <Button title="Add Marker" onPress={handleAddMarker} />
            <Button
              title="Add Custom Icon"
              onPress={handleAddCustomIconMarker}
            />
            <Button title="Add 20 Markers" onPress={handleAddManyMarkers} />
            <Button title="Clear Markers" onPress={handleClearMarkers} />
            <Button
              title={
                clusteringEnabled
                  ? '🔢 Disable Clustering'
                  : '🔢 Enable Clustering'
              }
              onPress={() => setClusteringEnabled(!clusteringEnabled)}
            />
            <Button title="Add Polyline" onPress={handleAddPolyline} />
            <Button title="Add Polygon" onPress={handleAddPolygon} />
            <Button title="Add Circle" onPress={handleAddCircle} />
            <Button title="Clear Overlays" onPress={handleClearOverlays} />
          </ScrollView>
        )}
      </View>

      {eventLog.length > 0 && (
        <View style={styles.eventLog}>
          <Text style={styles.eventLogTitle}>Event Log (Last 10):</Text>
          <ScrollView style={styles.eventLogScroll}>
            {eventLog.map((log, index) => (
              <Text key={index} style={styles.eventLogItem}>
                {log}
              </Text>
            ))}
          </ScrollView>
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  map: {
    flex: 1,
  },
  controlsContainer: {
    position: 'absolute',
    bottom: 20,
    left: 20,
    right: 20,
  },
  toggleButton: {
    backgroundColor: 'rgba(0, 122, 255, 0.9)',
    padding: 12,
    borderRadius: 10,
    alignItems: 'center',
    marginBottom: 10,
  },
  toggleButtonText: {
    color: 'white',
    fontSize: 14,
    fontWeight: 'bold',
  },
  controls: {
    maxHeight: 300,
    backgroundColor: 'rgba(255, 255, 255, 0.95)',
    borderRadius: 10,
  },
  controlsContent: {
    padding: 10,
    gap: 10,
  },
  eventLog: {
    position: 'absolute',
    top: 60,
    left: 20,
    right: 20,
    maxHeight: 200,
    backgroundColor: 'rgba(255, 255, 255, 0.95)',
    padding: 10,
    borderRadius: 10,
  },
  eventLogTitle: {
    fontSize: 14,
    fontWeight: 'bold',
    marginBottom: 5,
  },
  eventLogScroll: {
    maxHeight: 150,
  },
  eventLogItem: {
    fontSize: 12,
    marginVertical: 2,
    color: '#333',
  },
});
