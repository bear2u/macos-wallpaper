# Mac Live Wallpaper

MP4/MOV 동영상을 macOS 데스크톱 라이브 월페이퍼(동적 배경화면)로 사용할 수 있는 네이티브 Swift/SwiftUI 맥 앱입니다.

---

## 🌟 주요 기능 (Key Features)

1. **비디오 선택 및 미리보기 (Video Import & Preview)**
   - MP4 및 MOV 파일 선택 지원 (`NSOpenPanel` 및 Drag & Drop 지원)
   - 앱 내부 비디오 미리보기 (해상도, 비디오 길이, 파일 용량 정보 표시)

2. **라이브 월페이퍼 엔진 (Wallpaper Engine)**
   - Apple 공식 `AVFoundation` (`AVQueuePlayer` + `AVPlayerLooper`) 기반 매끄러운 무한 반복 재생
   - `desktopWindow` 레벨의 borderless `NSWindow` 사용으로 Finder 데스크톱 아이콘 클릭 및 일반 앱 화면 동작 방해 없음
   - `Fill` (`.resizeAspectFill`) 및 `Fit` (`.resizeAspect`) 스케일링 모드 전환 지원
   - 음소거(Mute) 온/오프 조절 기능

3. **다중 모니터 및 화면 변경 대응 (Multi-Monitor Support)**
   - `NSScreen.screens` 탐색으로 모든 연동 모니터에 라이브 월페이퍼 적용
   - 외장 모니터 연결/해제 이벤트 감지 및 자동 재구성 (`ScreenManager`)

4. **전력 및 성능 최적화 (Sleep/Wake Optimization)**
   - Mac 슬립, 디스플레이 화면 꺼짐, 사용자 세션 비활성화 시 자동 Pause (`PowerStateObserver`)
   - 복구/Wake 시 자동으로 라이브 월페이퍼 재생 재개

5. **메뉴바 통합 및 자동 실행 (Menu Bar & Launch at Login)**
   - macOS 메뉴바(Status Bar) 아이콘을 통해 일시정지/재개, 설정 및 앱 제어
   - 로그인 시 자동 실행 지원 (`SMAppService.mainApp`)
   - 마지막 적용한 월페이퍼 기억 및 자동 복구 (`Security-scoped bookmark` 활용)

---

## 🛠 프로젝트 구조 (Project Architecture)

```text
MacLiveWallpaper/
├── App/
│   ├── MacLiveWallpaperApp.swift    # SwiftUI App Entry Point
│   └── AppDelegate.swift             # App Lifecycle & Status Bar Menu
├── Models/
│   ├── Wallpaper.swift               # Wallpaper Data Model & VideoMetadata
│   └── AppSettings.swift             # Application Preferences Model
├── Views/
│   ├── MainView.swift                # Main UI (Preview, Info, Controls)
│   ├── VideoPreviewView.swift        # NSViewRepresentable Video Player Preview
│   ├── EmptyStateView.swift          # Video Import Dropzone & Choose Button
│   ├── SettingsView.swift            # General & Video Settings View
│   └── MenuBarExtraView.swift        # Menu Bar Dropdown Controls
├── Wallpaper/
│   ├── WallpaperManager.swift        # Wallpaper Orchestrator Singleton
│   ├── WallpaperWindowController.swift # Desktop Window Management per Screen
│   └── VideoPlaybackController.swift # AVQueuePlayer & AVPlayerLooper Controller
├── Services/
│   ├── FileImportService.swift       # NSOpenPanel & Video Metadata Extractor
│   ├── ScreenManager.swift           # NSScreen Monitor Observer
│   ├── PowerStateObserver.swift     # System & Display Sleep/Wake Observer
│   ├── LoginItemManager.swift        # SMAppService Launch at Login Manager
│   └── PreferenceStore.swift         # UserDefaults & Security-Scoped Bookmark Store
├── Resources/
│   └── Info.plist
├── Package.swift                     # Swift Package Manager Build Configuration
├── MacLiveWallpaper.xcodeproj        # Xcode Project
└── generate_xcodeproj.py             # Xcode Project Generator Script
```

---

## 🚀 빌드 및 실행 방법 (Build & Run Instructions)

### Xcode로 열기 및 실행
1. Xcode에서 `MacLiveWallpaper.xcodeproj` 프로젝트를 엽니다.
2. Target을 `MacLiveWallpaper`로 선택 후 `Cmd + R`로 빌드 및 실행합니다.

### 터미널에서 빌드 (xcodebuild)
```bash
xcodebuild -project MacLiveWallpaper.xcodeproj -scheme MacLiveWallpaper build
```

### 터미널에서 Swift Package Manager로 빌드 및 실행
```bash
swift build
swift run MacLiveWallpaper
```
