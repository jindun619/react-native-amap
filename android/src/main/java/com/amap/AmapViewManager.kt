package com.amap

import android.graphics.Color
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
    return AmapView(context)
  }

  @ReactProp(name = "color")
  override fun setColor(view: AmapView?, color: String?) {
    view?.setBackgroundColor(Color.parseColor(color))
  }

  companion object {
    const val NAME = "AmapView"
  }
}
