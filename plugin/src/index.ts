import type { ConfigPlugin } from 'expo/config-plugins';
import { createRunOncePlugin } from 'expo/config-plugins';
import { withAmapAndroid } from './withAmapAndroid';
import { withAmapIos } from './withAmapIos';

/**
 * Props for the Amap Expo config plugin
 */
export interface AmapPluginProps {
  /**
   * iOS API key for AMap SDK
   * Falls back to EXPO_PUBLIC_AMAP_IOS_API_KEY environment variable
   */
  iosApiKey?: string;
  /**
   * Android API key for AMap SDK
   * Falls back to EXPO_PUBLIC_AMAP_ANDROID_API_KEY environment variable
   */
  androidApiKey?: string;
  /**
   * Custom iOS location permission description
   */
  iosLocationWhenInUseDescription?: string;
  /**
   * Custom iOS location permission description (always)
   */
  iosLocationAlwaysDescription?: string;
}

/**
 * Expo config plugin for @jindun619/react-native-amap
 *
 * Automatically configures:
 * - iOS: Info.plist (API key, permissions, ATS), AppDelegate initialization
 * - Android: AndroidManifest.xml (API key, permissions), build.gradle (Maven repo)
 *
 * @example
 * // app.config.js
 * export default {
 *   plugins: [
 *     [
 *       '@jindun619/react-native-amap',
 *       {
 *         iosApiKey: 'your-ios-key',
 *         androidApiKey: 'your-android-key'
 *       }
 *     ]
 *   ]
 * }
 *
 * @example
 * // Using environment variables (.env file)
 * EXPO_PUBLIC_AMAP_IOS_API_KEY=your-ios-key
 * EXPO_PUBLIC_AMAP_ANDROID_API_KEY=your-android-key
 */
const withAmap: ConfigPlugin<AmapPluginProps> = (config, props = {}) => {
  config = withAmapIos(config, props);
  config = withAmapAndroid(config, props);
  return config;
};

const pkg = require('../../package.json');

export default createRunOncePlugin(withAmap, pkg.name, pkg.version);
