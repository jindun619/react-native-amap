import type { ConfigPlugin } from 'expo/config-plugins';
import {
  withAndroidManifest,
  withProjectBuildGradle,
  AndroidConfig,
  WarningAggregator,
} from 'expo/config-plugins';
import type { AmapPluginProps } from './index';

/**
 * Android config plugin for react-native-amap
 *
 * Configures:
 * 1. AndroidManifest.xml - API key, required permissions
 * 2. build.gradle - AMap Maven repository
 */
export const withAmapAndroid: ConfigPlugin<AmapPluginProps> = (
  config,
  props
) => {
  config = withAmapManifest(config, props);
  config = withAmapGradle(config);
  return config;
};

/**
 * Adds required AndroidManifest.xml entries for AMap SDK
 */
const withAmapManifest: ConfigPlugin<AmapPluginProps> = (config, props) => {
  return withAndroidManifest(config, (config) => {
    const mainApplication =
      AndroidConfig.Manifest.getMainApplicationOrThrow(config.modResults);

    // 1. Add AMap API key as meta-data
    const apiKey =
      props.androidApiKey || process.env.EXPO_PUBLIC_AMAP_ANDROID_API_KEY || '';

    if (apiKey) {
      AndroidConfig.Manifest.addMetaDataItemToMainApplication(
        mainApplication,
        'com.amap.api.v2.apikey',
        apiKey
      );
    } else {
      WarningAggregator.addWarningAndroid(
        'react-native-amap',
        'AMap Android API key not provided. Set androidApiKey in plugin props or EXPO_PUBLIC_AMAP_ANDROID_API_KEY environment variable.'
      );
    }

    // 2. Add required permissions
    const permissions = [
      'android.permission.INTERNET',
      'android.permission.ACCESS_FINE_LOCATION',
      'android.permission.ACCESS_COARSE_LOCATION',
      'android.permission.ACCESS_NETWORK_STATE',
      'android.permission.ACCESS_WIFI_STATE',
      'android.permission.WRITE_EXTERNAL_STORAGE',
      'android.permission.READ_EXTERNAL_STORAGE',
    ];

    permissions.forEach((permission) => {
      AndroidConfig.Permissions.ensurePermission(config.modResults, permission);
    });

    return config;
  });
};

/**
 * Adds AMap Maven repository to project-level build.gradle
 */
const withAmapGradle: ConfigPlugin = (config) => {
  return withProjectBuildGradle(config, (config) => {
    const mavenRepo =
      'maven { url "https://maven.aliyun.com/repository/public" }';

    // Check if AMap Maven repository is already added
    if (!config.modResults.contents.includes('maven.aliyun.com')) {
      // Add to allprojects.repositories section
      // Pattern: allprojects { ... repositories { ... } }
      const allProjectsPattern =
        /allprojects\s*\{[\s\S]*?repositories\s*\{/;
      const match = config.modResults.contents.match(allProjectsPattern);

      if (match && match.index !== undefined) {
        const insertPosition = match.index + match[0].length;
        config.modResults.contents =
          config.modResults.contents.slice(0, insertPosition) +
          '\n        ' +
          mavenRepo +
          config.modResults.contents.slice(insertPosition);
      } else {
        WarningAggregator.addWarningAndroid(
          'react-native-amap',
          'Could not find allprojects.repositories in build.gradle. Please add AMap Maven repository manually: ' +
            mavenRepo
        );
      }
    }

    return config;
  });
};
