# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a React Native library bridging the Amap (AliMap/高德地图) iOS/Android SDK. It uses React Native's **Fabric (New Architecture)** with **Codegen** for type-safe native component generation.

## Architecture

### React Native Fabric Architecture

This library implements a **Fabric View Component** (`AmapView`), using React Native's new architecture:

1. **JavaScript Layer** (`src/`)
   - `AmapViewNativeComponent.ts`: Codegen specification defining the native component interface using `codegenNativeComponent`
   - Props are type-safe and automatically generate native interfaces
   - Currently supports: `color` prop (example implementation)

2. **Native Android** (`android/src/main/java/com/amap/`)
   - `AmapViewManager.kt`: Fabric ViewManager implementing `AmapViewManagerInterface` (codegen-generated)
   - Uses `ViewManagerDelegate` pattern for Fabric compatibility
   - Package: `com.amap`

3. **Native iOS** (`ios/`)
   - `AmapView.mm`: Fabric ComponentView written in Objective-C++
   - Implements `RCTAmapViewViewProtocol` (codegen-generated)
   - Uses C++ Fabric ComponentDescriptor and Props from `AmapViewSpec`

4. **Codegen Configuration** (`package.json`)
   - `codegenConfig.name`: "AmapViewSpec"
   - Generates native interfaces in both iOS and Android during build
   - Generated files are in `ios/build` and `android/build` (gitignored)

### Monorepo Structure

- **Root**: Library package (published to npm)
- **example/**: Example app for testing library changes
  - Configured to use local library version via Yarn workspaces
  - JS changes reflect immediately; native changes require rebuild

## Development Commands

### Setup
```sh
yarn                      # Install all dependencies (required)
```

### Building the Library
```sh
yarn prepare              # Build library with react-native-builder-bob
```

The build outputs to `lib/` directory:
- `lib/module/`: ESM JavaScript
- `lib/typescript/`: TypeScript declarations

### Type Checking and Linting
```sh
yarn typecheck            # Run TypeScript compiler
yarn lint                 # Run ESLint
yarn lint --fix           # Auto-fix linting issues
```

### Testing
```sh
yarn test                 # Run Jest unit tests
```

### Running the Example App
```sh
yarn example start        # Start Metro bundler
yarn example android      # Run on Android
yarn example ios          # Run on iOS
```

**Verify Fabric is enabled** by checking Metro logs for:
```
Running "AmapExample" with {"fabric":true,"initialProps":{"concurrentRoot":true},"rootTag":1}
```

### Cleaning Build Artifacts
```sh
yarn clean                # Remove all build directories (android/build, ios/build, lib/)
```

### Publishing
```sh
yarn release              # Use release-it for versioning and publishing
```

## Native Development

### Android
- Open `example/android` in Android Studio
- Find library source at: **Android** → **react-native-amap** (under project view)
- Native changes require rebuilding the example app

### iOS
- Open `example/ios/AmapExample.xcworkspace` in Xcode (NOT .xcodeproj)
- Find library source at: **Pods** → **Development Pods** → **react-native-amap**
- Native changes require rebuilding the example app

## Important Patterns

### Adding New Props
1. Add prop to `NativeProps` interface in `src/AmapViewNativeComponent.ts`
2. Codegen will auto-generate native interfaces on next build
3. Implement prop handling in:
   - Android: `AmapViewManager.kt` with `@ReactProp` annotation
   - iOS: `AmapView.mm` in `updateProps:oldProps:` method

### Codegen Types
- Android generates: `AmapViewManagerInterface` and `AmapViewManagerDelegate`
- iOS generates: Component descriptors, Props, EventEmitters in `AmapViewSpec/`
- These are auto-generated; never edit directly

## Commit Conventions

Follow [Conventional Commits](https://www.conventionalcommits.org/):
- `feat:` - New features
- `fix:` - Bug fixes
- `refactor:` - Code refactoring
- `docs:` - Documentation changes
- `test:` - Test changes
- `chore:` - Tooling/build changes

Pre-commit hooks (via lefthook) enforce this format.

## Key Configuration Files

- `package.json`: Contains `codegenConfig`, `react-native-builder-bob` config, scripts
- `Amap.podspec`: iOS CocoaPods specification
- `android/build.gradle`: Android build configuration
- `tsconfig.json`: Strict TypeScript settings with React Native paths
- `tsconfig.build.json`: Build-specific config (excludes example/ and lib/)
