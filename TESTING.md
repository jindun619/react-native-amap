# iOS Simulator Testing Guide

## Phase 1 완료 - 기본 지도 표시 테스트

### 🚀 빠른 테스트 방법

프로젝트 루트에서 실행:

```bash
yarn test:ios
```

이 명령은 다음을 자동으로 수행합니다:
1. CocoaPods 의존성 설치 (`pod install`)
2. React Native 빌드
3. iPhone 16 시뮬레이터에서 앱 실행

### 📱 예상 결과

- ✅ iPhone 16 시뮬레이터가 자동으로 실행됩니다
- ✅ 앱이 설치되고 실행됩니다
- ✅ **전체 화면에 AMap 지도가 표시됩니다**
- ✅ 지도를 터치/드래그하여 이동 가능
- ✅ 핀치 제스처로 줌 인/아웃 가능
- ✅ 두 손가락으로 회전 가능

### 🔧 수동 테스트 (Xcode 사용)

문제가 발생하면 Xcode에서 직접 실행:

```bash
# 1. Xcode 열기
open example/ios/AmapExample.xcworkspace

# 2. Xcode에서:
#    - 상단 Scheme: AmapExample
#    - 상단 Device: iPhone 16 (iOS 18.1)
#    - Run 버튼 클릭 (⌘R)
```

### 🐛 문제 해결

#### AMap SDK Privacy Error (개인정보 정책 오류)

Xcode 로그에 다음 오류가 표시되는 경우:
```
Error Domain=AMapFoundationErrorPrivacyShowUnknow Code=555570
使用MAMapKit3D SDK 功能前请设置隐私权政策是否弹窗告知用户
```

**해결 방법**: `example/ios/AmapExample/AppDelegate.swift`에서 개인정보 설정이 올바르게 되어있는지 확인:

```swift
import MAMapKit

func application(...) -> Bool {
    // MUST be called BEFORE any MAMapView instantiation
    MAMapView.updatePrivacyShow(.didShow, privacyInfo: .didContain)
    MAMapView.updatePrivacyAgree(.didAgree)

    AMapServices.shared().enableHTTPS = true
    // ... rest of initialization
}
```

**중요**:
- `MAMapView.updatePrivacy*` 호출은 **반드시 MAMapView 인스턴스 생성 전**에 호출되어야 합니다
- 프로덕션 환경에서는 실제 개인정보 보호 정책 다이얼로그를 사용자에게 표시해야 합니다

#### Metro Bundler가 실행되지 않는 경우

터미널을 하나 더 열어서:

```bash
yarn example start
```

그리고 다른 터미널에서:

```bash
yarn test:ios
```

#### Pod install 실패

```bash
cd example/ios
pod install --repo-update
cd ../..
yarn test:ios
```

#### 시뮬레이터가 부팅되지 않는 경우

```bash
# 시뮬레이터 목록 확인
xcrun simctl list devices | grep "iPhone 16"

# 다른 시뮬레이터 사용 (예: iPhone 15)
yarn example ios --simulator="iPhone 15"
```

### 📝 다음 Phase 테스트 시

각 Phase 완료 후 동일한 명령으로 테스트:

```bash
yarn test:ios
```

코드 변경 후 빠른 재빌드:
- JS 코드만 변경: Metro가 자동으로 핫 리로드 (⌘R로 수동 리로드)
- Native 코드 변경 (`ios/*.mm`, `ios/*.h`): Xcode에서 재빌드 필요 (⌘B → ⌘R)

### ✅ Phase 1 체크리스트

현재 Phase 1에서 확인할 사항:

- [ ] 앱이 정상적으로 빌드되고 실행됨
- [ ] 지도가 전체 화면에 표시됨
- [ ] 지도 이동(드래그) 가능
- [ ] 지도 줌 인/아웃 가능
- [ ] 지도 회전 가능
- [ ] 콘솔에 "AMap loaded successfully" 로그 출력

모두 확인되면 Phase 2로 진행 가능합니다!

---

## 로그 확인

Xcode Console에서 AMap 관련 로그 확인:

```
AMap loaded successfully
```

Metro Bundler 터미널에서 JS 로그 확인 가능.
