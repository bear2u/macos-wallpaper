# Mac Live Wallpaper

MP4/MOV 동영상 및 고화질 이미지를 macOS 데스크톱 라이브 월페이퍼(동적 배경화면)로 사용할 수 있는 네이티브 Swift/SwiftUI 맥 앱입니다.

---

## 🌟 주요 기능 (Key Features)

### 1. 🎬 싱글 미디어 모드 (Single Mode)
- **다양한 포맷 지원**: MP4, MOV 비디오뿐만 아니라 PNG, JPG, HEIC, WEBP, GIF 등 고화질 이미지까지 지원
- **실시간 인라인 미리보기**: 재생/일시정지 버튼, 타임라인 시크바, 음소거 버튼이 포함된 인라인 플레이어 컨트롤 제공
- **미디어 메타데이터 표시**: 해상도, 재생 시간, 파일 용량 정보 자동 추출
- **스케일링 & 사운드 설정**: `Fill`(화면 채우기) / `Fit`(화면 맞춤) 선택 및 음소거(Mute) 온/오프 조절
- **정지 프레임 옵션 (Freeze Motion)**: 비디오를 정지된 1개 프레임 상태의 배경화면으로 사용 가능

### 2. 📑 멀티 플레이리스트 모드 (Multi/Playlist Mode)
- **다중 미디어 등록**: 여러 개의 동영상 및 이미지 파일들을 한 번에 등록하여 나만의 월페이퍼 플레이리스트 구성
- **재생 순서 선택 (Playback Order)**:
  - 🔄 **순차 재생 (`Sequential`)**: 1번 ➔ 2번 ➔ 3번 ➔ 1번... 순서대로 재생
  - 🔀 **랜덤 재생 (`Random / Shuffle`)**: 미디어를 무작위로 교체하며 재생
- **자동 전환 주기 설정 (Switch Interval)**:
  - 🎬 **영상이 끝나면 (`When Video Ends`)**: 영상 1회 완독 후 자동으로 다음 미디어로 전환
  - ⏱️ **시간 간격 지정 (`Every 1 min` / `5 min` / `15 min` / `30 min` / `1 hour`)**: 지정된 정기 시간 간격마다 배경화면 자동 전환
- **빠른 이전/다음 전환**: 메인 화면 및 상단 메뉴바(Status Bar)에서 **`Next Wallpaper` / `Previous Wallpaper`** 단축 조작 지원

### 3. ✨ 부드러운 전환 효과 (Smooth Cross-Dissolve Transition)
- **은은한 디졸브 페이드**: 월페이퍼가 교체될 때 뚝 끊기는 느낌 없이 0.7~1.0초간 은은하고 자연스럽게 스며드는 **하단 레이어 삽입형 Cross-Dissolve** 전환 효과 탑재
- **화면 검은색 방지 안전 구조**: AVPlayer 디코딩 시점과 관계없이 영상이 항상 100% 매끄럽고 부드럽게 전환

### 4. ⚙️ 메뉴바 상주 & 독(Dock) 숨기기 모드 (MenuBar Agent Mode)
- **Dock 아이콘 감추기 토글 (`Hide Dock Icon`)**: 설정 창에서 ON 설정 시 하단 독(Dock)에서 아이콘이 사라지고 상단 메뉴바에만 조용히 백그라운드로 상주
- **메인 창을 닫아도 배경 유지**: 메인 윈도우(X)를 닫아도 라이브 월페이퍼는 상단 메뉴바 백그라운드에서 끊김 없이 작동

### 5. 🖥️ 다중 모니터 & 전력 최적화 (Multi-Monitor & Power Saving)
- **다중 모니터 지원**: 연결된 모든 모니터(`NSScreen`)에 독립적인 데스크톱 라이브 월페이퍼 자동 배치
- **모니터 감지 오토 갱신**: 외장 모니터 연결/해제 시 자동 화면 구성
- **스마트 절전 모드 (Sleep/Wake)**: Mac 슬립, 디스플레이 화면 꺼짐, 잠금 화면 진입 시 비디오 자동 일시정지(`Pause`)로 CPU 및 배터리 전력 소모 최소화
- **로그인 시 자동 실행 (Launch at Login)**: Mac을 켤 때 백그라운드 자동 실행 및 마지막 월페이퍼 상태 자동 복구

---

## 📸 앱 작동 모드 요약

| 모드 종류 | 기능 설명 |
| :--- | :--- |
| **Single Mode** | 1개의 동영상 또는 이미지를 데스크톱 배경화면으로 지속 재생/표시합니다. |
| **Playlist (Multi) Mode** | 여러 개의 동영상/이미지를 순차 또는 랜덤으로 회전하며 자동으로 교체 재생합니다. |
| **Agent Mode** | 하단 Dock 아이콘 없이 상단 Status Menu Bar에만 조용히 상주하여 동작합니다. |
| **Static Mode** | 비디오의 특정 장면을 멈춘 상태의 정지 배경화면으로 활용합니다. |

---

## 🛠 프로젝트 구조 (Project Architecture)

```text
MacLiveWallpaper/
├── App/
│   ├── MacLiveWallpaperApp.swift        # SwiftUI App Entry Point
│   └── AppDelegate.swift                 # App Lifecycle & Status Bar Menu Controller
├── Models/
│   ├── Wallpaper.swift                   # Wallpaper, MediaKind, PlaybackOrder, SwitchInterval Data Model
│   └── AppSettings.swift                 # Application Preferences Model (Hide Dock Icon, Launch at Login)
├── Views/
│   ├── MainView.swift                    # Main UI (Single Preview, Playlist Tab, Controls)
│   ├── VideoPreviewView.swift            # Inline AVPlayerView Video/Image Preview
│   ├── EmptyStateView.swift              # Media Dropzone & File Selection View
│   ├── SettingsView.swift                # General & Media Playback Settings
│   └── MenuBarExtraView.swift            # Menu Bar Dropdown Controls & Next Wallpaper Trigger
├── Wallpaper/
│   ├── WallpaperManager.swift            # Wallpaper & Playlist Orchestrator Singleton
│   ├── WallpaperWindowController.swift   # Smooth Cross-Dissolve Desktop Window Controller per Screen
│   └── VideoPlaybackController.swift     # AVQueuePlayer & AVPlayerLooper Controller
├── Services/
│   ├── FileImportService.swift           # Single & Multiple Media File Selection Service
│   ├── ScreenManager.swift               # NSScreen Monitor Observer
│   ├── PowerStateObserver.swift         # System & Display Sleep/Wake Observer
│   ├── LoginItemManager.swift            # SMAppService Launch at Login Manager
│   └── PreferenceStore.swift             # UserDefaults & Security-Scoped Bookmark Store
├── Resources/
│   ├── Assets.xcassets                   # AppIcon macOS Asset Catalog
│   ├── AppIcon.icns                      # Compiled macOS App Icon
│   └── Info.plist                        # macOS Bundle Properties
├── Package.swift                         # Swift Package Manager Build Configuration
├── MacLiveWallpaper.xcodeproj            # Xcode Project
└── generate_xcodeproj.py                 # Xcode Project Generator Script
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
