# Mac Live Wallpaper

## MP4/MOV 기반 macOS 라이브 월페이퍼 앱 MVP 개발 기획서

### 1. 프로젝트 개요

**프로젝트명:** Mac Live Wallpaper
**플랫폼:** macOS
**개발언어:** Swift
**UI:** SwiftUI + AppKit
**최소 지원 버전:** macOS 13+
**1차 목표:** 사용자가 자신의 MP4/MOV 동영상을 선택하여 Mac 데스크톱 배경에서 무한 반복 재생할 수 있는 네이티브 앱 개발

서비스의 핵심 경험은 매우 단순하게 유지한다.

```text
앱 실행
  ↓
MP4/MOV 선택
  ↓
영상 미리보기
  ↓
Set as Wallpaper
  ↓
Mac 데스크톱에서 무한 반복 재생
```

AI 영상 생성 기능, 온라인 월페이퍼 스토어, 계정 시스템 등은 MVP에서 제외한다.

---

# 2. 핵심 목표

사용자가 AI 영상 생성 서비스 등에서 제작한 5~30초 MP4/MOV 동영상을 Mac으로 가져온 뒤 몇 번의 클릭만으로 라이브 월페이퍼로 적용할 수 있도록 한다.

핵심 원칙:

* 설치가 단순해야 한다.
* 별도 서버가 필요 없어야 한다.
* 회원가입이 없어야 한다.
* 외부 Shell Script를 실행하지 않는다.
* 영상은 로컬에서만 처리한다.
* macOS 공개 API를 우선 사용한다.
* Finder 아이콘과 일반 앱 사용을 방해하지 않아야 한다.
* 영상은 기본적으로 무음으로 재생한다.
* CPU/GPU 및 배터리 사용을 불필요하게 증가시키지 않는다.

---

# 3. MVP 사용자 시나리오

## 시나리오 A — 첫 실행

사용자가 앱을 실행한다.

화면 중앙에 다음 버튼을 표시한다.

```text
Mac Live Wallpaper

Turn your videos into live wallpapers.

[ Choose Video ]

Supported
MP4 / MOV
```

사용자가 `Choose Video`를 누른다.

macOS 파일 선택창을 열어 MP4 또는 MOV 파일을 선택한다.

선택된 영상의 첫 프레임 또는 썸네일을 표시한다.

```text
┌─────────────────────────────────┐
│                                 │
│          VIDEO PREVIEW          │
│                                 │
└─────────────────────────────────┘

my-wallpaper.mp4

Duration     15 sec
Resolution   3840 × 2400

Fill Mode
● Fill
○ Fit

[ Set as Wallpaper ]
```

`Set as Wallpaper`를 누르면 데스크톱 배경에서 영상 재생을 시작한다.

---

# 4. MVP 필수 기능

## 4.1 영상 불러오기

지원 포맷:

* MP4
* MOV

macOS의 `NSOpenPanel`을 사용한다.

Drag & Drop도 지원한다.

사용자가 선택한 동영상 URL을 애플리케이션 상태에 저장한다.

---

## 4.2 영상 Preview

영상 선택 후 앱 내부에서 미리볼 수 있어야 한다.

사용 기술:

```text
AVFoundation
AVPlayer
```

Preview에서는 다음 기능을 제공한다.

* Play
* Pause
* Mute
* Loop
* Fill / Fit

---

# 5. Wallpaper Engine

MVP의 핵심 모듈이다.

구조:

```text
WallpaperManager
       │
       ├── WallpaperWindow
       │
       ├── VideoPlayer
       │
       └── ScreenManager
```

각 모니터마다 하나의 Wallpaper Window를 생성한다.

```text
MacBook Display
      ↓
WallpaperWindow #1
      ↓
AVPlayerLayer


External Display
      ↓
WallpaperWindow #2
      ↓
AVPlayerLayer
```

Apple의 `NSScreen.screens`는 현재 시스템에서 사용할 수 있는 화면 목록을 제공한다.

---

# 6. 동영상 반복 재생

영상 재생에는 다음 구조를 사용한다.

```text
AVPlayerItem
      ↓
AVQueuePlayer
      ↓
AVPlayerLooper
      ↓
AVPlayerLayer
```

`AVPlayerLooper`는 `AVQueuePlayer`와 `AVPlayerItem`을 기반으로 반복 재생을 관리하는 Apple 공식 API다.

기본 구조 예:

```swift
let item = AVPlayerItem(url: videoURL)

let player = AVQueuePlayer()

let looper = AVPlayerLooper(
    player: player,
    templateItem: item
)

let playerLayer = AVPlayerLayer(player: player)

player.isMuted = true
player.play()
```

중요:

`AVPlayerLooper` 객체가 해제되지 않도록 플레이어 컨트롤러에서 strong reference로 보관한다.

---

# 7. Desktop Window

AppKit `NSWindow`를 이용하여 일반 앱 창과 별개의 Wallpaper Window를 생성한다.

예상 구조:

```swift
final class WallpaperWindowController {
    
    let window: NSWindow
    let playerLayer: AVPlayerLayer
    
}
```

Window 기본 속성:

```text
borderless
no titlebar
no shadow
no user interaction
ignoresMouseEvents = true
desktop window level
all relevant Spaces
stationary
```

Core Graphics에는 표준 macOS window level로 `desktopWindow`와 `desktopIconWindow` 등이 정의되어 있다.

초기 구현 후보:

```swift
window.level = NSWindow.Level(
    rawValue: Int(
        CGWindowLevelForKey(.desktopWindow)
    )
)
```

그리고:

```swift
window.ignoresMouseEvents = true
window.hasShadow = false
window.isOpaque = true
```

### 중요 구현 검증 사항

`desktopWindow` 레벨의 실제 동작은 다음 환경에서 반드시 실기기로 확인한다.

* Finder desktop icons
* Mission Control
* Spaces
* Stage Manager
* Full Screen App
* 외장 모니터
* 디스플레이 연결/해제

Finder 아이콘보다 월페이퍼 영상이 위에 표시되는 문제가 생겨서는 안 된다.

**Private API나 Finder 프로세스 조작 방식은 사용하지 않는다.**

---

# 8. 화면 채우기

기본값은 `Aspect Fill`로 한다.

```swift
playerLayer.videoGravity = .resizeAspectFill
```

사용자는 두 옵션을 선택할 수 있다.

```text
Fill
화면 전체를 영상으로 채움
일부 영상 영역이 잘릴 수 있음

Fit
영상 전체가 보임
화면 비율에 따라 여백이 생길 수 있음
```

매핑:

```text
Fill
→ .resizeAspectFill

Fit
→ .resizeAspect
```

---

# 9. Multi Monitor

MVP에서 최소한 모든 모니터에 동일한 영상을 표시할 수 있도록 한다.

```text
NSScreen.screens
       ↓
for screen in screens
       ↓
WallpaperWindow 생성
```

예:

```text
MacBook
└── video01.mp4

LG Monitor
└── video01.mp4
```

MVP 이후에는 모니터별 다른 영상 선택 기능을 추가한다.

```text
MacBook
└── rain.mp4

LG Monitor
└── space.mp4
```

---

# 10. Display 변경 감지

외장 모니터가 연결되거나 제거되면 Wallpaper Window를 다시 구성한다.

ScreenManager 책임:

```text
현재 디스플레이 확인
       ↓
변경 감지
       ↓
기존 WallpaperWindow 정리
       ↓
현재 NSScreen 기준 재생성
```

---

# 11. Sleep / Wake 최적화

Mac이 Sleep 상태가 되거나 화면이 꺼졌을 때 영상을 계속 재생할 필요가 없다.

Apple의 `NSWorkspace`는 다음 환경 이벤트를 제공한다.

* `willSleepNotification`
* `didWakeNotification`
* `screensDidSleepNotification`
* `screensDidWakeNotification`
* `activeSpaceDidChangeNotification`

동작:

```text
Normal
→ PLAY

Screen Sleep
→ PAUSE

Mac Sleep
→ PAUSE

Wake
→ RESUME
```

Observer 모듈:

```text
PowerStateObserver
```

---

# 12. 자동 재생 최적화

가능하면 다음 상황에서는 영상을 Pause한다.

### 화면 Sleep

Pause

### Mac Sleep

Pause

### 사용자 Session 비활성화

Pause

### 다시 활성화

Resume

Apple은 user session 전환에 대해 `sessionDidResignActiveNotification`과 `sessionDidBecomeActiveNotification`도 제공한다.

전체화면 앱 실행 시 자동 Pause 기능은 MVP+ 단계로 둔다.

---

# 13. Menu Bar

앱을 항상 일반 Window 형태로 열어둘 필요는 없다.

월페이퍼가 적용되면 앱을 Menu Bar 중심으로 사용할 수 있게 한다.

예:

```text
☁ Live Wallpaper
─────────────────
● Playing

Current
rain-seoul.mp4

Pause Wallpaper
Change Wallpaper
Open Settings
Quit
```

SwiftUI의 MenuBar UI 또는 AppKit `NSStatusItem` 구조 중 구현 난도가 낮고 안정적인 방식을 선택한다.

---

# 14. Main UI

디자인은 최대한 심플하게 한다.

```text
┌─────────────────────────────────────┐
│ Mac Live Wallpaper              ⚙  │
├─────────────────────────────────────┤
│                                     │
│                                     │
│          VIDEO PREVIEW              │
│                                     │
│                                     │
├─────────────────────────────────────┤
│ rain-seoul.mp4                      │
│ 3840×2400 · 15 sec                  │
│                                     │
│ Display                             │
│ [ Fill ▼ ]                          │
│                                     │
│ ☑ Mute                              │
│ ☑ Loop                              │
│                                     │
│        [ Set as Wallpaper ]         │
│                                     │
└─────────────────────────────────────┘
```

---

# 15. Settings

설정 항목:

```text
General

☑ Launch at Login
☑ Resume last wallpaper on launch
☑ Pause when display sleeps

Video

Scaling
● Fill
○ Fit

Audio
● Mute
○ Original Audio
```

MVP 기본값:

```text
Mute = ON
Loop = ON
Fill = ON
Pause on Sleep = ON
```

---

# 16. Launch at Login

macOS 13 이상에서는 Apple의 `SMAppService`를 사용하여 main app 또는 Login Item 등록을 관리할 수 있다.

예상 구조:

```swift
import ServiceManagement

SMAppService.mainApp
```

Settings:

```text
Launch at Login
[ ON / OFF ]
```

Shell script나 직접 `launchctl` 명령을 실행하는 방식은 사용하지 않는다.

---

# 17. 마지막 Wallpaper 복원

사용자가 Mac을 재시작하거나 앱을 종료했다 다시 실행했을 때 마지막 월페이퍼를 기억한다.

저장 데이터 예:

```text
wallpaper URL/bookmark
fill mode
mute
loop
launch at login
resume wallpaper
```

Preferences:

```text
UserDefaults
```

파일 접근 권한을 App Sandbox 환경에서도 지속시켜야 한다면 security-scoped bookmark 사용 여부를 구현 단계에서 검토한다.

---

# 18. 프로젝트 구조

권장 구조:

```text
MacLiveWallpaper/
│
├── App/
│   ├── MacLiveWallpaperApp.swift
│   └── AppDelegate.swift
│
├── Models/
│   ├── Wallpaper.swift
│   └── AppSettings.swift
│
├── Views/
│   ├── MainView.swift
│   ├── VideoPreviewView.swift
│   ├── SettingsView.swift
│   └── EmptyStateView.swift
│
├── Wallpaper/
│   ├── WallpaperManager.swift
│   ├── WallpaperWindowController.swift
│   └── VideoPlaybackController.swift
│
├── Services/
│   ├── FileImportService.swift
│   ├── ScreenManager.swift
│   ├── PowerStateObserver.swift
│   ├── LoginItemManager.swift
│   └── PreferenceStore.swift
│
├── MenuBar/
│   └── MenuBarController.swift
│
└── Resources/
    └── Assets.xcassets
```

---

# 19. 핵심 클래스 역할

## WallpaperManager

전체 월페이퍼 상태 관리.

```text
setWallpaper()
start()
pause()
resume()
stop()
refreshDisplays()
```

---

## WallpaperWindowController

모니터별 Wallpaper Window 관리.

```text
screen
window
playerLayer
```

---

## VideoPlaybackController

AVFoundation 관련 처리.

```text
AVPlayerItem
AVQueuePlayer
AVPlayerLooper
AVPlayerLayer
```

---

## ScreenManager

```text
NSScreen 탐색
Display 변경 감지
Display ID 관리
```

---

## FileImportService

```text
NSOpenPanel
Drag & Drop
Video validation
```

---

## PowerStateObserver

```text
Sleep
Wake
Screen Sleep
Screen Wake
Session State
```

---

## LoginItemManager

```text
SMAppService
```

---

# 20. 데이터 모델

```swift
struct Wallpaper: Identifiable, Codable {

    let id: UUID

    var name: String

    var fileURL: URL

    var scalingMode: ScalingMode

    var isMuted: Bool

}
```

Scaling:

```swift
enum ScalingMode: String, Codable {

    case fill
    case fit

}
```

---

# 21. MVP 제외 기능

1차 버전에서는 다음을 구현하지 않는다.

```text
AI Video 생성
AI API
회원가입
Cloud Sync
Wallpaper Store
Community
댓글
좋아요
다운로드 서버
결제
구독
광고
Creator 기능
온라인 Gallery
Playlist
Schedule
영상 편집
영상 Upscaling
Seamless Loop 변환
```

목표는 **Live Wallpaper Engine 자체가 안정적으로 동작하는지 검증하는 것**이다.

---

# 22. 1차 개발 단계

## Phase 1 — 기술 검증

가장 먼저 이것만 만든다.

```text
Test MP4
   ↓
AVPlayerLooper
   ↓
NSWindow
   ↓
Desktop Level
   ↓
Wallpaper 표시
```

성공 조건:

```text
Finder 아이콘 정상 표시
영상 반복 재생
마우스 클릭 방해 없음
일반 앱 Window 정상 표시
```

이 단계가 프로젝트의 가장 중요한 PoC다.

---

# 23. Phase 2 — 파일 선택

추가:

```text
Choose Video
Drag & Drop
Preview
Set Wallpaper
```

---

# 24. Phase 3 — 상태 관리

추가:

```text
Pause
Resume
Stop
Mute
Fill / Fit
```

---

# 25. Phase 4 — 시스템 연동

추가:

```text
Sleep → Pause
Wake → Resume

Display 연결
Display 제거

Launch at Login
```

---

# 26. Phase 5 — UI 완성

추가:

```text
Main UI
Settings
Menu Bar
최근 Wallpaper
```

---

# 27. MVP 완료 기준

다음 항목이 모두 동작하면 MVP 완료로 판단한다.

### 영상

* MP4 선택 가능
* MOV 선택 가능
* Preview 가능
* 무음 재생 가능
* 무한 Loop 가능
* Fill 가능
* Fit 가능

### Wallpaper

* 영상이 desktop 영역에서 재생됨
* Finder desktop icon을 가리지 않음
* 클릭을 가로채지 않음
* 일반 Application Window를 가리지 않음

### System

* Sleep 시 Pause
* Wake 시 재생 복구
* 화면 Sleep 대응
* 외장 Display 대응
* Launch at Login 선택 가능

### UX

* 앱 실행 후 3단계 이내 Wallpaper 적용

```text
Choose Video
→ Preview
→ Set Wallpaper
```

---

# 28. 테스트 환경

최소 다음 환경을 테스트한다.

```text
MacBook 단독

MacBook + 외장 Monitor

Spaces 2개 이상

Mission Control

Full Screen App

Stage Manager ON/OFF

Display Sleep

System Sleep

Restart

Logout/Login
```

---

# 29. 안전성 원칙

아래 기능은 사용하지 않는다.

```text
curl | bash
curl | zsh
sudo installer
임의 LaunchDaemon 생성
Finder 강제 종료
System 파일 수정
Private API
Gatekeeper 우회
SIP 변경
```

앱이 필요한 것은 기본적으로:

```text
사용자가 직접 선택한 Video 접근
Video Playback
Desktop Window
App Preferences
Launch at Login
```

수준으로 제한한다.

---

# 30. 향후 2차 버전

MVP가 안정화되면 다음 기능을 추가한다.

```text
Wallpaper Library

최근 사용한 Wallpaper

Favorite

Playlist

시간대별 자동 변경

모니터별 Wallpaper

Video Trim

Seamless Loop

4K Optimization

HEVC Conversion
```

---

# 31. 향후 AI 버전

그다음 AI 기능을 별도 단계로 추가한다.

```text
Prompt

"비 오는 서울 야경"

        ↓

AI Video API

        ↓

15 sec Video

        ↓

Loop Optimization

        ↓

Mac Resolution Optimization

        ↓

Preview

        ↓

Set as Wallpaper
```

최종적인 제품 방향:

```text
AI Wallpaper Studio
       +
Live Wallpaper Engine
```

---

# 32. AI Coding Agent 개발 지시사항

이 프로젝트를 구현할 때 처음부터 전체 기능을 동시에 만들지 말 것.

가장 먼저 다음 PoC를 구현한다.

```text
1. Xcode macOS Swift 프로젝트 생성

2. Test MP4 하나를 Bundle 또는 로컬 파일에서 불러오기

3. AVQueuePlayer + AVPlayerLooper 구현

4. borderless NSWindow 생성

5. 해당 Window를 desktop window level에 배치

6. Finder icon이 영상 위에 정상적으로 표시되는지 확인

7. ignoresMouseEvents 활성화

8. 영상 Loop 확인

9. Spaces / Mission Control 확인

10. 성공한 뒤 SwiftUI UI 개발 시작
```

Apple 공식 API에서 `desktopWindow`와 `desktopIconWindow`라는 별개의 window level을 제공하지만, 실제 Finder/Spaces/Stage Manager 동작은 구현 환경에서 반드시 검증할 것.

Private API를 이용하여 강제로 Wallpaper를 변경하지 말 것.

가능한 한 다음 Framework만 사용한다.

```text
SwiftUI
AppKit
AVFoundation
CoreGraphics
ServiceManagement
Foundation
```

외부 Package는 MVP에서 사용하지 않는다.

---

# 33. 가장 먼저 구현해야 할 성공 화면

앱의 첫 기술 목표는 단 하나다.

```text
┌─────────────────────────────────────────┐
│ Finder                                  │
│                                         │
│  📁 Project                             │
│                                         │
│           AI VIDEO PLAYING              │
│           IN BACKGROUND                 │
│                                         │
│                            📁 Images     │
│                                         │
└─────────────────────────────────────────┘
```

배경에서는 MP4가 무한 반복되고,

Finder 아이콘은 정상적으로 보이며,

사용자가 Finder 아이콘을 클릭할 수 있고,

다른 앱도 평소처럼 사용할 수 있어야 한다.

이 PoC가 정상 동작한 뒤 나머지 기능을 구현한다.

---

# 34. MVP 한 줄 정의

**“내 MP4/MOV 영상을 선택하면 Mac 데스크톱에서 조용히 무한 반복되는 라이브 월페이퍼 앱.”**

