package com.amap

import android.graphics.Color
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.viewmanagers.AmapViewManagerInterface
import com.facebook.react.viewmanagers.AmapViewManagerDelegate

@ReactModule(name = AmapViewManager.NAME)
class AmapViewManager : SimpleViewManager<AmapView>(),
  AmapViewManagerInterface<AmapView> {
  private val mDelegate: ViewManagerDelegate<AmapView>

  init {
    mDelegate = AmapViewManagerDelegate(this)
  }

  override fun getDelegate(): ViewManagerDelegate<AmapView>? {
    return mDelegate
  }

  override fun getName(): String {
    return NAME
  }

  public override fun createViewInstance(context: ThemedReactContext): AmapView {
    val mapView = AmapView(context)
    mapView.onCreate(null) // Initialize map lifecycle
    return mapView
  }

  override fun onDropViewInstance(view: AmapView) {
    super.onDropViewInstance(view)
    view.onDestroy()
  }

  @ReactProp(name = "color")
  override fun setColor(view: AmapView?, color: String?) {
    // Color prop is no longer used
  }

  @ReactProp(name = "mapType")
  fun setMapType(view: AmapView?, mapType: String?) {
    view?.getAMap()?.let { aMap ->
      when (mapType) {
        "satellite" -> aMap.mapType = com.amap.api.maps.AMap.MAP_TYPE_SATELLITE
        else -> aMap.mapType = com.amap.api.maps.AMap.MAP_TYPE_NORMAL
      }
    }
  }

  @ReactProp(name = "showsBuildings", defaultBoolean = true)
  fun setShowsBuildings(view: AmapView?, shows: Boolean) {
    view?.getAMap()?.showBuildings(shows)
  }

  @ReactProp(name = "showsTraffic", defaultBoolean = false)
  fun setShowsTraffic(view: AmapView?, shows: Boolean) {
    view?.getAMap()?.isTrafficEnabled = shows
  }

  @ReactProp(name = "showsLabels", defaultBoolean = true)
  fun setShowsLabels(view: AmapView?, shows: Boolean) {
    view?.getAMap()?.showMapText(shows)
  }

  @ReactProp(name = "zoomEnabled", defaultBoolean = true)
  fun setZoomEnabled(view: AmapView?, enabled: Boolean) {
    view?.getAMap()?.uiSettings?.isZoomGesturesEnabled = enabled
  }

  @ReactProp(name = "scrollEnabled", defaultBoolean = true)
  fun setScrollEnabled(view: AmapView?, enabled: Boolean) {
    view?.getAMap()?.uiSettings?.isScrollGesturesEnabled = enabled
  }

  @ReactProp(name = "rotateEnabled", defaultBoolean = true)
  fun setRotateEnabled(view: AmapView?, enabled: Boolean) {
    view?.getAMap()?.uiSettings?.isRotateGesturesEnabled = enabled
  }

  @ReactProp(name = "tiltEnabled", defaultBoolean = true)
  fun setTiltEnabled(view: AmapView?, enabled: Boolean) {
    view?.getAMap()?.uiSettings?.isTiltGesturesEnabled = enabled
  }

  @ReactProp(name = "showsUserLocation", defaultBoolean = false)
  fun setShowsUserLocation(view: AmapView?, shows: Boolean) {
    view?.getAMap()?.isMyLocationEnabled = shows
  }

  @ReactProp(name = "clusteringEnabled", defaultBoolean = false)
  fun setClusteringEnabled(view: AmapView?, enabled: Boolean) {
    view?.setClusteringEnabled(enabled)
  }

  override fun getExportedCustomDirectEventTypeConstants(): Map<String, Any> {
    return mapOf(
      "onMapReady" to mapOf("registrationName" to "onMapReady"),
      "onRegionChange" to mapOf("registrationName" to "onRegionChange"),
      "onMapPress" to mapOf("registrationName" to "onMapPress"),
      "onMapLongPress" to mapOf("registrationName" to "onMapLongPress"),
      "onMarkerPress" to mapOf("registrationName" to "onMarkerPress"),
      "onClusterPress" to mapOf("registrationName" to "onClusterPress")
    )
  }

  companion object {
    const val NAME = "AmapView"
  }
}
