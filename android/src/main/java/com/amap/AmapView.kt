package com.amap

import android.content.Context
import android.util.AttributeSet
import com.amap.api.maps.TextureMapView
import com.amap.api.maps.AMap
import com.amap.api.maps.MapsInitializer
import com.amap.api.maps.model.Marker
import com.amap.api.maps.model.Polyline
import com.amap.api.maps.model.Polygon
import com.amap.api.maps.model.Circle
import com.amap.api.maps.model.MarkerOptions
import com.amap.api.maps.model.LatLng
import com.amap.api.maps.model.BitmapDescriptorFactory
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Color as AndroidColor
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.RCTEventEmitter
import android.graphics.Point

// Simple cluster data class
data class ClusterMarker(
  val marker: Marker,
  val latLng: LatLng
)

class AmapView : TextureMapView {
  private var aMap: AMap? = null
  private val markers = mutableMapOf<String, Marker>()
  private val polylines = mutableMapOf<String, Polyline>()
  private val polygons = mutableMapOf<String, Polygon>()
  private val circles = mutableMapOf<String, Circle>()
  private var eventEmitter: RCTEventEmitter? = null
  private var clusteringEnabled = false
  private val allMarkers = mutableListOf<ClusterMarker>()
  private val clusterMarkers = mutableMapOf<String, Marker>()

  constructor(context: Context?) : super(context) {
    initialize(context)
  }

  constructor(context: Context?, attrs: AttributeSet?) : super(context, attrs) {
    initialize(context)
  }

  constructor(context: Context?, attrs: AttributeSet?, defStyleAttr: Int) : super(
    context,
    attrs,
    defStyleAttr
  ) {
    initialize(context)
  }

  private fun initialize(context: Context?) {
    context?.let {
      // Get event emitter
      if (it is ReactContext) {
        eventEmitter = it.getJSModule(RCTEventEmitter::class.java)
      }

      // Initialize AMap SDK (API key is set in AndroidManifest.xml)
      try {
        MapsInitializer.updatePrivacyShow(it, true, true)
        MapsInitializer.updatePrivacyAgree(it, true)
      } catch (e: Exception) {
        e.printStackTrace()
      }

      // Get AMap instance
      aMap = map

      // Basic map configuration
      aMap?.let { map ->
        map.mapType = AMap.MAP_TYPE_NORMAL
        map.uiSettings?.isZoomControlsEnabled = false
        map.uiSettings?.isCompassEnabled = false
        map.uiSettings?.isMyLocationButtonEnabled = false
        map.isMyLocationEnabled = false

        // Set up event listeners
        setupEventListeners(map)
      }
    }
  }

  private fun setupEventListeners(aMap: AMap) {
    // Map loaded listener
    aMap.setOnMapLoadedListener {
      emitEvent("onMapReady", Arguments.createMap())
    }

    // Camera change listener
    aMap.setOnCameraChangeListener(object : AMap.OnCameraChangeListener {
      override fun onCameraChange(position: com.amap.api.maps.model.CameraPosition?) {
        // onCameraChangeBegin
      }

      override fun onCameraChangeFinish(position: com.amap.api.maps.model.CameraPosition?) {
        // Update clusters if clustering is enabled
        if (clusteringEnabled) {
          updateClusters()
        }

        position?.let {
          val event = Arguments.createMap().apply {
            putString("latitude", it.target.latitude.toString())
            putString("longitude", it.target.longitude.toString())
            putString("latitudeDelta", "0.1") // AMap doesn't provide delta
            putString("longitudeDelta", "0.1")
            putString("zoom", it.zoom.toString())
          }
          emitEvent("onRegionChange", event)
        }
      }
    })

    // Map click listener
    aMap.setOnMapClickListener { latLng ->
      val event = Arguments.createMap().apply {
        val coordinate = Arguments.createMap().apply {
          putString("latitude", latLng.latitude.toString())
          putString("longitude", latLng.longitude.toString())
        }
        putMap("coordinate", coordinate)
      }
      emitEvent("onMapPress", event)
    }

    // Map long click listener
    aMap.setOnMapLongClickListener { latLng ->
      val event = Arguments.createMap().apply {
        val coordinate = Arguments.createMap().apply {
          putString("latitude", latLng.latitude.toString())
          putString("longitude", latLng.longitude.toString())
        }
        putMap("coordinate", coordinate)
      }
      emitEvent("onMapLongPress", event)
    }

    // Marker click listener
    aMap.setOnMarkerClickListener { marker ->
      // Check if it's a cluster marker
      val clusterData = marker.`object` as? ClusterData
      if (clusterData != null) {
        // Emit onClusterPress event
        val event = Arguments.createMap().apply {
          val coordinate = Arguments.createMap().apply {
            putString("latitude", clusterData.position.latitude.toString())
            putString("longitude", clusterData.position.longitude.toString())
          }
          putMap("coordinate", coordinate)
          putString("markerCount", clusterData.count.toString())
        }
        emitEvent("onClusterPress", event)
      } else {
        // Emit onMarkerPress event for regular markers
        val event = Arguments.createMap().apply {
          putString("id", marker.title ?: "")
          val coordinate = Arguments.createMap().apply {
            putString("latitude", marker.position.latitude.toString())
            putString("longitude", marker.position.longitude.toString())
          }
          putMap("coordinate", coordinate)
        }
        emitEvent("onMarkerPress", event)
      }
      false // Return false to allow default behavior
    }
  }

  private fun emitEvent(eventName: String, params: WritableMap) {
    eventEmitter?.receiveEvent(id, eventName, params)
  }

  fun getAMap(): AMap? = aMap

  fun addMarkerWithId(id: String, marker: Marker) {
    markers[id] = marker
  }

  fun removeMarkerById(id: String) {
    markers[id]?.remove()
    markers.remove(id)
  }

  fun getMarkerById(id: String): Marker? {
    return markers[id]
  }

  fun clearMarkers() {
    markers.clear()
  }

  // Polyline methods
  fun addPolylineWithId(id: String, polyline: Polyline) {
    polylines[id] = polyline
  }

  fun removePolylineById(id: String) {
    polylines[id]?.remove()
    polylines.remove(id)
  }

  fun clearPolylines() {
    polylines.values.forEach { it.remove() }
    polylines.clear()
  }

  // Polygon methods
  fun addPolygonWithId(id: String, polygon: Polygon) {
    polygons[id] = polygon
  }

  fun removePolygonById(id: String) {
    polygons[id]?.remove()
    polygons.remove(id)
  }

  fun clearPolygons() {
    polygons.values.forEach { it.remove() }
    polygons.clear()
  }

  // Circle methods
  fun addCircleWithId(id: String, circle: Circle) {
    circles[id] = circle
  }

  fun removeCircleById(id: String) {
    circles[id]?.remove()
    circles.remove(id)
  }

  fun clearCircles() {
    circles.values.forEach { it.remove() }
    circles.clear()
  }

  // Clustering methods
  fun setClusteringEnabled(enabled: Boolean) {
    clusteringEnabled = enabled
    updateClusters()
  }

  private fun updateClusters() {
    aMap?.let { map ->
      if (!clusteringEnabled) {
        // Remove cluster markers
        clusterMarkers.values.forEach { it.remove() }
        clusterMarkers.clear()
        return
      }

      // Get all regular markers
      val markersList = mutableListOf<ClusterMarker>()
      markers.values.forEach { marker ->
        markersList.add(ClusterMarker(marker, marker.position))
      }
      allMarkers.clear()
      allMarkers.addAll(markersList)

      // Perform clustering
      val clusters = clusterMarkers(allMarkers)

      // Remove existing markers
      clusterMarkers.values.forEach { it.remove() }
      clusterMarkers.clear()
      markers.values.forEach { it.isVisible = false }

      // Add clustered markers
      clusters.forEach { cluster ->
        if (cluster.size > 1) {
          // Create cluster marker
          val centerLat = cluster.map { it.latLng.latitude }.average()
          val centerLng = cluster.map { it.latLng.longitude }.average()
          val clusterLatLng = LatLng(centerLat, centerLng)

          val clusterMarker = map.addMarker(
            MarkerOptions()
              .position(clusterLatLng)
              .title("${cluster.size} markers")
              .icon(BitmapDescriptorFactory.fromBitmap(createClusterBitmap(cluster.size)))
          )

          clusterMarker?.let {
            val clusterId = "cluster_${System.currentTimeMillis()}_${cluster.hashCode()}"
            clusterMarkers[clusterId] = it
            it.setObject(ClusterData(clusterLatLng, cluster.size))
          }
        } else {
          // Show single marker
          cluster[0].marker.isVisible = true
        }
      }
    }
  }

  private fun clusterMarkers(markers: List<ClusterMarker>): List<List<ClusterMarker>> {
    if (markers.isEmpty()) return emptyList()

    val result = mutableListOf<List<ClusterMarker>>()
    val remaining = markers.toMutableList()
    val clusterDistance = 60f // Distance in pixels

    while (remaining.isNotEmpty()) {
      val current = remaining.removeAt(0)
      val cluster = mutableListOf(current)
      val currentPoint = aMap?.projection?.toScreenLocation(current.latLng)

      if (currentPoint != null) {
        val toRemove = mutableListOf<ClusterMarker>()
        remaining.forEach { other ->
          val otherPoint = aMap?.projection?.toScreenLocation(other.latLng)
          if (otherPoint != null) {
            val distance = Math.sqrt(
              Math.pow((currentPoint.x - otherPoint.x).toDouble(), 2.0) +
                Math.pow((currentPoint.y - otherPoint.y).toDouble(), 2.0)
            ).toFloat()

            if (distance < clusterDistance) {
              cluster.add(other)
              toRemove.add(other)
            }
          }
        }
        remaining.removeAll(toRemove)
      }

      result.add(cluster)
    }

    return result
  }

  private fun createClusterBitmap(count: Int): Bitmap {
    val size = 80
    val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(bitmap)
    val paint = Paint().apply {
      isAntiAlias = true
      color = AndroidColor.parseColor("#9C27B0") // Purple
      style = Paint.Style.FILL
    }

    // Draw circle
    canvas.drawCircle(size / 2f, size / 2f, size / 2f, paint)

    // Draw count text
    paint.color = AndroidColor.WHITE
    paint.textSize = 32f
    paint.textAlign = Paint.Align.CENTER

    val text = count.toString()
    val textY = size / 2f - (paint.descent() + paint.ascent()) / 2f
    canvas.drawText(text, size / 2f, textY, paint)

    return bitmap
  }

  // Cluster data class
  data class ClusterData(val position: LatLng, val count: Int)
}
