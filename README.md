# LogCam — Apple Log Video Recorder for iPhone 16 Pro Max

> Record professional Apple Log footage directly from your iPhone 16 Pro Max

---

## 📁 Project Files

```
LogCam/
├── LogCam/
│   ├── LogCamApp.swift              ← App entry point
│   ├── ContentView.swift            ← Root view + permission flow
│   ├── Info.plist                   ← Camera/mic permissions
│   ├── Camera/
│   │   ├── CameraManager.swift      ← AVCaptureSession + Apple Log detection
│   │   └── RecordingManager.swift   ← AVAssetWriter pipeline
│   ├── Models/
│   │   └── RecordingSession.swift   ← Data models
│   └── Views/
│       ├── CameraPreviewView.swift  ← Live viewfinder
│       ├── RecordingControlsView.swift ← Record button, HUD
│       └── GalleryView.swift        ← Saved clips + settings
└── .github/workflows/build.yml     ← Auto-build on GitHub
```

---

## 🚀 How to Build & Install (Windows Users)

### Option A: MacinCloud (Easiest — No Account Needed)

1. Go to **https://www.macincloud.com** → Start Free Trial
2. Upload this folder to the cloud Mac
3. Open `LogCam.xcodeproj` in Xcode
4. Connect your iPhone via USB (Remote Desktop)
5. Set your Apple ID in Signing → Build & Run

### Option B: GitHub Actions (Free, No Mac Needed)

1. Create a **free GitHub account** at github.com
2. Create a **new repository** (public)
3. Upload the `LogCam` folder
4. GitHub will auto-build it (macOS runner)
5. Download the build artifact

### Option C: AltStore (Install Without Developer Account)

1. Install **AltServer** on Windows: https://altstore.io
2. Install **AltStore** on your iPhone via AltServer
3. Build the IPA using MacinCloud
4. Sideload via AltStore (free, refreshes every 7 days)

---

## ✨ App Features

| Feature | Details |
|---------|---------|
| 🎬 Apple Log Recording | Full Apple Log color profile preserved |
| 📐 4K 24/30/60fps | Pro quality video |
| 🎙️ Audio | 48kHz AAC stereo |
| 🗂️ Gallery | View all recordings in-app |
| ⚙️ Settings | Resolution, FPS, LOG toggle |
| 📱 iOS 17+ | iPhone 15 Pro / 16 Pro / 16 Pro Max |

---

## 🎨 Post-Processing

Your `.mov` files will have Apple Log color baked in.  
Import into:
- **DaVinci Resolve** → Color Management → Apple Log
- **Final Cut Pro** → Built-in Apple Log support
- **Premiere Pro** → Apply LUT: AppleLog_to_Rec709

---

## ⚠️ Requirements

- iPhone 15 Pro / 16 Pro / 16 Pro Max (iOS 17+)
- Xcode 15+ (on any Mac or MacinCloud)
- Free Apple ID (for AltStore sideloading)
