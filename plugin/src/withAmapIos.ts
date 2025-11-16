import type { ConfigPlugin } from 'expo/config-plugins';
import {
  withInfoPlist,
  withAppDelegate,
  WarningAggregator,
} from 'expo/config-plugins';
import type { AmapPluginProps } from './index';

/**
 * iOS config plugin for react-native-amap
 *
 * Configures:
 * 1. Info.plist - API key, location permissions, App Transport Security
 * 2. AppDelegate - AMap SDK initialization (privacy compliance)
 */
export const withAmapIos: ConfigPlugin<AmapPluginProps> = (config, props) => {
  config = withAmapInfoPlist(config, props);
  config = withAmapAppDelegate(config, props);
  return config;
};

/**
 * Adds required Info.plist entries for AMap SDK
 */
const withAmapInfoPlist: ConfigPlugin<AmapPluginProps> = (config, props) => {
  return withInfoPlist(config, (config) => {
    const infoPlist = config.modResults;

    // 1. Add AMap API key
    const apiKey =
      props.iosApiKey || process.env.EXPO_PUBLIC_AMAP_IOS_API_KEY || '';

    if (apiKey) {
      infoPlist.AMapApiKey = apiKey;
    } else {
      WarningAggregator.addWarningIOS(
        'react-native-amap',
        'AMap iOS API key not provided. Set iosApiKey in plugin props or EXPO_PUBLIC_AMAP_IOS_API_KEY environment variable.'
      );
    }

    // 2. Add location permissions
    infoPlist.NSLocationWhenInUseUsageDescription =
      props.iosLocationWhenInUseDescription ||
      infoPlist.NSLocationWhenInUseUsageDescription ||
      'Allow $(PRODUCT_NAME) to access your location to show your position on the map';

    infoPlist.NSLocationAlwaysAndWhenInUseUsageDescription =
      props.iosLocationAlwaysDescription ||
      infoPlist.NSLocationAlwaysAndWhenInUseUsageDescription ||
      'Allow $(PRODUCT_NAME) to access your location to show your position on the map';

    // 3. Add App Transport Security exception for AMap domains
    if (!infoPlist.NSAppTransportSecurity) {
      infoPlist.NSAppTransportSecurity = {};
    }
    const ats = infoPlist.NSAppTransportSecurity as Record<string, any>;
    if (!ats.NSExceptionDomains) {
      ats.NSExceptionDomains = {};
    }

    ats.NSExceptionDomains['amap.com'] = {
      NSIncludesSubdomains: true,
      NSTemporaryExceptionAllowsInsecureHTTPLoads: true,
    };

    return config;
  });
};

/**
 * Adds AMap SDK initialization code to AppDelegate
 * This is CRITICAL for iOS - without this, the map will not display
 */
const withAmapAppDelegate: ConfigPlugin<AmapPluginProps> = (config) => {
  return withAppDelegate(config, (config) => {
    if (
      config.modResults.language === 'objcpp' ||
      config.modResults.language === 'objc'
    ) {
      let contents = config.modResults.contents;

      // 1. Add required imports at the top of the file
      const imports = [
        '#import <AMapFoundationKit/AMapFoundationKit.h>',
        '#import <MAMapKit/MAMapKit.h>',
      ];

      for (const importStatement of imports) {
        if (!contents.includes(importStatement)) {
          // Add import after the last #import statement
          const lastImportIndex = contents.lastIndexOf('#import');
          if (lastImportIndex !== -1) {
            const endOfLine = contents.indexOf('\n', lastImportIndex);
            contents =
              contents.slice(0, endOfLine + 1) +
              importStatement +
              '\n' +
              contents.slice(endOfLine + 1);
          } else {
            // If no imports found, add at the beginning
            contents = importStatement + '\n' + contents;
          }
        }
      }

      // 2. Add AMap SDK initialization in didFinishLaunchingWithOptions
      const initCode = `  // AMap SDK initialization (required for privacy compliance)
  // MUST be called before any MAMapView instantiation
  [MAMapView updatePrivacyShow:AMapPrivacyShowStatusDidShow privacyInfo:AMapPrivacyInfoStatusDidContain];
  [MAMapView updatePrivacyAgree:AMapPrivacyAgreeStatusDidAgree];
  [[AMapServices sharedServices] setEnableHTTPS:YES];
`;

      if (!contents.includes('MAMapView updatePrivacyShow')) {
        // Find the didFinishLaunchingWithOptions method
        const methodPattern =
          /(-\s*\(BOOL\)\s*application:\s*\(UIApplication\s*\*\)\s*application\s+didFinishLaunchingWithOptions:\s*\(NSDictionary\s*\*\)\s*launchOptions\s*\{)/;
        const match = contents.match(methodPattern);

        if (match && match.index !== undefined) {
          const insertPosition = match.index + match[0].length;
          contents =
            contents.slice(0, insertPosition) +
            '\n' +
            initCode +
            '\n' +
            contents.slice(insertPosition);
        } else {
          WarningAggregator.addWarningIOS(
            'react-native-amap',
            'Could not find didFinishLaunchingWithOptions method in AppDelegate. Please add AMap initialization manually.'
          );
        }
      }

      config.modResults.contents = contents;
    }

    return config;
  });
};
