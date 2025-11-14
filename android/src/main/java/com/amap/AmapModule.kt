package com.amap

import com.facebook.react.bridge.*
import com.facebook.react.uimanager.UIManagerHelper
import com.facebook.react.uimanager.common.UIManagerType
import com.amap.api.maps.CameraUpdateFactory
import com.amap.api.maps.model.LatLng
import com.amap.api.maps.model.CameraPosition as AMapCameraPosition
import com.amap.api.maps.model.MarkerOptions
import com.amap.api.maps.model.Marker
import com.amap.api.maps.model.PolylineOptions
import com.amap.api.maps.model.PolygonOptions
import com.amap.api.maps.model.CircleOptions
import com.amap.api.maps.model.BitmapDescriptorFactory
import android.graphics.Color
import android.graphics.BitmapFactory
import java.net.URL

class AmapModule(private val reactContext: ReactApplicationContext) :
  ReactContextBaseJavaModule(reactContext) {

  override fun getName(): String = "AmapModule"

  @ReactMethod
  fun animateToRegion(
    viewTag: Int,
    latitude: Double,
    longitude: Double,
    zoom: Double,
    duration: Double?,
    promise: Promise
  ) {
    UIManagerHelper.getUIManager(reactContext, UIManagerType.FABRIC)?.addUIBlock { uiManager ->
      try {
        val view = uiManager.resolveView(viewTag) as? AmapView
        if (view == null) {
          promise.reject("invalid_view", "Invalid view tag")
          return@addUIBlock
        }

        val aMap = view.getAMap()
        if (aMap == null) {
          promise.reject("no_map", "Map not initialized")
          return@addUIBlock
        }

        val latLng = LatLng(latitude, longitude)
        val cameraUpdate = CameraUpdateFactory.newLatLngZoom(latLng, zoom.toFloat())

        val durationMs = duration?.toLong() ?: 300L
        aMap.animateCamera(cameraUpdate, durationMs, null)

        promise.resolve(null)
      } catch (e: Exception) {
        promise.reject("error", e.message)
      }
    }
  }

  @ReactMethod
  fun setCamera(
    viewTag: Int,
    latitude: Double,
    longitude: Double,
    zoom: Double,
    tilt: Double?,
    rotation: Double?,
    promise: Promise
  ) {
    UIManagerHelper.getUIManager(reactContext, UIManagerType.FABRIC)?.addUIBlock { uiManager ->
      try {
        val view = uiManager.resolveView(viewTag) as? AmapView
        if (view == null) {
          promise.reject("invalid_view", "Invalid view tag")
          return@addUIBlock
        }

        val aMap = view.getAMap()
        if (aMap == null) {
          promise.reject("no_map", "Map not initialized")
          return@addUIBlock
        }

        val latLng = LatLng(latitude, longitude)
        val cameraBuilder = AMapCameraPosition.Builder()
          .target(latLng)
          .zoom(zoom.toFloat())

        tilt?.let { cameraBuilder.tilt(it.toFloat()) }
        rotation?.let { cameraBuilder.bearing(it.toFloat()) }

        aMap.moveCamera(CameraUpdateFactory.newCameraPosition(cameraBuilder.build()))

        promise.resolve(null)
      } catch (e: Exception) {
        promise.reject("error", e.message)
      }
    }
  }

  @ReactMethod
  fun addMarker(
    viewTag: Int,
    markerId: String,
    latitude: Double,
    longitude: Double,
    title: String?,
    subtitle: String?,
    showsCallout: Boolean?,
    icon: String?,
    promise: Promise
  ) {
    UIManagerHelper.getUIManager(reactContext, UIManagerType.FABRIC)?.addUIBlock { uiManager ->
      try {
        val view = uiManager.resolveView(viewTag) as? AmapView
        if (view == null) {
          promise.reject("invalid_view", "Invalid view tag")
          return@addUIBlock
        }

        val aMap = view.getAMap()
        if (aMap == null) {
          promise.reject("no_map", "Map not initialized")
          return@addUIBlock
        }

        val markerOptions = MarkerOptions()
          .position(LatLng(latitude, longitude))
          .title(title)
          .snippet(subtitle)

        // Handle custom icon
        icon?.let { iconSource ->
          try {
            when {
              iconSource.startsWith("http://") || iconSource.startsWith("https://") -> {
                // Load from URL asynchronously
                Thread {
                  try {
                    val url = URL(iconSource)
                    val bitmap = BitmapFactory.decodeStream(url.openStream())
                    if (bitmap != null) {
                      reactContext.runOnUiQueueThread {
                        markerOptions.icon(BitmapDescriptorFactory.fromBitmap(bitmap))
                        val marker = aMap.addMarker(markerOptions)
                        marker?.isInfoWindowEnable = showsCallout ?: (title != null || subtitle != null)
                        view.addMarkerWithId(markerId, marker)
                      }
                    }
                  } catch (e: Exception) {
                    // Fallback to default icon if loading fails
                    reactContext.runOnUiQueueThread {
                      val marker = aMap.addMarker(markerOptions)
                      marker?.isInfoWindowEnable = showsCallout ?: (title != null || subtitle != null)
                      view.addMarkerWithId(markerId, marker)
                    }
                  }
                }.start()
                promise.resolve(null)
                return@addUIBlock
              }
              else -> {
                // Try loading as drawable resource name
                val resourceId = reactContext.resources.getIdentifier(
                  iconSource,
                  "drawable",
                  reactContext.packageName
                )
                if (resourceId != 0) {
                  markerOptions.icon(BitmapDescriptorFactory.fromResource(resourceId))
                }
              }
            }
          } catch (e: Exception) {
            // Continue with default icon if loading fails
          }
        }

        val marker = aMap.addMarker(markerOptions)

        // Configure info window (callout) - default to true if title or subtitle provided
        val shouldShowCallout = showsCallout ?: (title != null || subtitle != null)
        marker?.isInfoWindowEnable = shouldShowCallout

        // Store marker ID for later removal
        view.addMarkerWithId(markerId, marker)

        promise.resolve(null)
      } catch (e: Exception) {
        promise.reject("error", e.message)
      }
    }
  }

  @ReactMethod
  fun removeMarker(
    viewTag: Int,
    markerId: String,
    promise: Promise
  ) {
    UIManagerHelper.getUIManager(reactContext, UIManagerType.FABRIC)?.addUIBlock { uiManager ->
      try {
        val view = uiManager.resolveView(viewTag) as? AmapView
        if (view == null) {
          promise.reject("invalid_view", "Invalid view tag")
          return@addUIBlock
        }

        view.removeMarkerById(markerId)
        promise.resolve(null)
      } catch (e: Exception) {
        promise.reject("error", e.message)
      }
    }
  }

  @ReactMethod
  fun clearMarkers(
    viewTag: Int,
    promise: Promise
  ) {
    UIManagerHelper.getUIManager(reactContext, UIManagerType.FABRIC)?.addUIBlock { uiManager ->
      try {
        val view = uiManager.resolveView(viewTag) as? AmapView
        if (view == null) {
          promise.reject("invalid_view", "Invalid view tag")
          return@addUIBlock
        }

        val aMap = view.getAMap()
        if (aMap == null) {
          promise.reject("no_map", "Map not initialized")
          return@addUIBlock
        }

        aMap.clear()
        view.clearMarkers()

        promise.resolve(null)
      } catch (e: Exception) {
        promise.reject("error", e.message)
      }
    }
  }

  @ReactMethod
  fun showCallout(
    viewTag: Int,
    markerId: String,
    promise: Promise
  ) {
    UIManagerHelper.getUIManager(reactContext, UIManagerType.FABRIC)?.addUIBlock { uiManager ->
      try {
        val view = uiManager.resolveView(viewTag) as? AmapView
        if (view == null) {
          promise.reject("invalid_view", "Invalid view tag")
          return@addUIBlock
        }

        val marker = view.getMarkerById(markerId)
        marker?.showInfoWindow()

        promise.resolve(null)
      } catch (e: Exception) {
        promise.reject("error", e.message)
      }
    }
  }

  @ReactMethod
  fun hideCallout(
    viewTag: Int,
    markerId: String,
    promise: Promise
  ) {
    UIManagerHelper.getUIManager(reactContext, UIManagerType.FABRIC)?.addUIBlock { uiManager ->
      try {
        val view = uiManager.resolveView(viewTag) as? AmapView
        if (view == null) {
          promise.reject("invalid_view", "Invalid view tag")
          return@addUIBlock
        }

        val marker = view.getMarkerById(markerId)
        marker?.hideInfoWindow()

        promise.resolve(null)
      } catch (e: Exception) {
        promise.reject("error", e.message)
      }
    }
  }

  // Helper method to parse color
  private fun parseColor(colorString: String?): Int {
    return try {
      colorString?.let { Color.parseColor(it) } ?: Color.BLUE
    } catch (e: Exception) {
      Color.BLUE
    }
  }

  // Polyline methods
  @ReactMethod
  fun addPolyline(
    viewTag: Int,
    polylineId: String,
    coordinates: ReadableArray,
    strokeColor: String?,
    strokeWidth: Double?,
    promise: Promise
  ) {
    UIManagerHelper.getUIManager(reactContext, UIManagerType.FABRIC)?.addUIBlock { uiManager ->
      try {
        val view = uiManager.resolveView(viewTag) as? AmapView
        if (view == null) {
          promise.reject("invalid_view", "Invalid view tag")
          return@addUIBlock
        }

        val aMap = view.getAMap()
        if (aMap == null) {
          promise.reject("no_map", "Map not initialized")
          return@addUIBlock
        }

        val points = mutableListOf<LatLng>()
        for (i in 0 until coordinates.size()) {
          val coord = coordinates.getMap(i)
          coord?.let {
            points.add(LatLng(it.getDouble("latitude"), it.getDouble("longitude")))
          }
        }

        val polylineOptions = PolylineOptions()
          .addAll(points)
          .color(parseColor(strokeColor))
          .width(strokeWidth?.toFloat() ?: 10f)

        val polyline = aMap.addPolyline(polylineOptions)
        view.addPolylineWithId(polylineId, polyline)

        promise.resolve(null)
      } catch (e: Exception) {
        promise.reject("error", e.message)
      }
    }
  }

  @ReactMethod
  fun removePolyline(
    viewTag: Int,
    polylineId: String,
    promise: Promise
  ) {
    UIManagerHelper.getUIManager(reactContext, UIManagerType.FABRIC)?.addUIBlock { uiManager ->
      try {
        val view = uiManager.resolveView(viewTag) as? AmapView
        if (view == null) {
          promise.reject("invalid_view", "Invalid view tag")
          return@addUIBlock
        }

        view.removePolylineById(polylineId)
        promise.resolve(null)
      } catch (e: Exception) {
        promise.reject("error", e.message)
      }
    }
  }

  @ReactMethod
  fun clearPolylines(
    viewTag: Int,
    promise: Promise
  ) {
    UIManagerHelper.getUIManager(reactContext, UIManagerType.FABRIC)?.addUIBlock { uiManager ->
      try {
        val view = uiManager.resolveView(viewTag) as? AmapView
        if (view == null) {
          promise.reject("invalid_view", "Invalid view tag")
          return@addUIBlock
        }

        view.clearPolylines()
        promise.resolve(null)
      } catch (e: Exception) {
        promise.reject("error", e.message)
      }
    }
  }

  // Polygon methods
  @ReactMethod
  fun addPolygon(
    viewTag: Int,
    polygonId: String,
    coordinates: ReadableArray,
    strokeColor: String?,
    strokeWidth: Double?,
    fillColor: String?,
    promise: Promise
  ) {
    UIManagerHelper.getUIManager(reactContext, UIManagerType.FABRIC)?.addUIBlock { uiManager ->
      try {
        val view = uiManager.resolveView(viewTag) as? AmapView
        if (view == null) {
          promise.reject("invalid_view", "Invalid view tag")
          return@addUIBlock
        }

        val aMap = view.getAMap()
        if (aMap == null) {
          promise.reject("no_map", "Map not initialized")
          return@addUIBlock
        }

        val points = mutableListOf<LatLng>()
        for (i in 0 until coordinates.size()) {
          val coord = coordinates.getMap(i)
          coord?.let {
            points.add(LatLng(it.getDouble("latitude"), it.getDouble("longitude")))
          }
        }

        val polygonOptions = PolygonOptions()
          .addAll(points)
          .strokeColor(parseColor(strokeColor))
          .strokeWidth(strokeWidth?.toFloat() ?: 10f)
          .fillColor(parseColor(fillColor))

        val polygon = aMap.addPolygon(polygonOptions)
        view.addPolygonWithId(polygonId, polygon)

        promise.resolve(null)
      } catch (e: Exception) {
        promise.reject("error", e.message)
      }
    }
  }

  @ReactMethod
  fun removePolygon(
    viewTag: Int,
    polygonId: String,
    promise: Promise
  ) {
    UIManagerHelper.getUIManager(reactContext, UIManagerType.FABRIC)?.addUIBlock { uiManager ->
      try {
        val view = uiManager.resolveView(viewTag) as? AmapView
        if (view == null) {
          promise.reject("invalid_view", "Invalid view tag")
          return@addUIBlock
        }

        view.removePolygonById(polygonId)
        promise.resolve(null)
      } catch (e: Exception) {
        promise.reject("error", e.message)
      }
    }
  }

  @ReactMethod
  fun clearPolygons(
    viewTag: Int,
    promise: Promise
  ) {
    UIManagerHelper.getUIManager(reactContext, UIManagerType.FABRIC)?.addUIBlock { uiManager ->
      try {
        val view = uiManager.resolveView(viewTag) as? AmapView
        if (view == null) {
          promise.reject("invalid_view", "Invalid view tag")
          return@addUIBlock
        }

        view.clearPolygons()
        promise.resolve(null)
      } catch (e: Exception) {
        promise.reject("error", e.message)
      }
    }
  }

  // Circle methods
  @ReactMethod
  fun addCircle(
    viewTag: Int,
    circleId: String,
    latitude: Double,
    longitude: Double,
    radius: Double,
    strokeColor: String?,
    strokeWidth: Double?,
    fillColor: String?,
    promise: Promise
  ) {
    UIManagerHelper.getUIManager(reactContext, UIManagerType.FABRIC)?.addUIBlock { uiManager ->
      try {
        val view = uiManager.resolveView(viewTag) as? AmapView
        if (view == null) {
          promise.reject("invalid_view", "Invalid view tag")
          return@addUIBlock
        }

        val aMap = view.getAMap()
        if (aMap == null) {
          promise.reject("no_map", "Map not initialized")
          return@addUIBlock
        }

        val circleOptions = CircleOptions()
          .center(LatLng(latitude, longitude))
          .radius(radius)
          .strokeColor(parseColor(strokeColor))
          .strokeWidth(strokeWidth?.toFloat() ?: 10f)
          .fillColor(parseColor(fillColor))

        val circle = aMap.addCircle(circleOptions)
        view.addCircleWithId(circleId, circle)

        promise.resolve(null)
      } catch (e: Exception) {
        promise.reject("error", e.message)
      }
    }
  }

  @ReactMethod
  fun removeCircle(
    viewTag: Int,
    circleId: String,
    promise: Promise
  ) {
    UIManagerHelper.getUIManager(reactContext, UIManagerType.FABRIC)?.addUIBlock { uiManager ->
      try {
        val view = uiManager.resolveView(viewTag) as? AmapView
        if (view == null) {
          promise.reject("invalid_view", "Invalid view tag")
          return@addUIBlock
        }

        view.removeCircleById(circleId)
        promise.resolve(null)
      } catch (e: Exception) {
        promise.reject("error", e.message)
      }
    }
  }

  @ReactMethod
  fun clearCircles(
    viewTag: Int,
    promise: Promise
  ) {
    UIManagerHelper.getUIManager(reactContext, UIManagerType.FABRIC)?.addUIBlock { uiManager ->
      try {
        val view = uiManager.resolveView(viewTag) as? AmapView
        if (view == null) {
          promise.reject("invalid_view", "Invalid view tag")
          return@addUIBlock
        }

        view.clearCircles()
        promise.resolve(null)
      } catch (e: Exception) {
        promise.reject("error", e.message)
      }
    }
  }
}
