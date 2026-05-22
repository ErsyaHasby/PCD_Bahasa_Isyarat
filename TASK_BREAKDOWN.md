# 📋 Task Breakdown — Kelompok 2 (4 Orang)
## Sistem Intelijen Visual Penerjemah Bahasa Isyarat Real-Time

**Deadline**: TBA  
**Status**: Planning Phase

---

## 👥 Tim & Pembagian Fokus

| # | Nama | NIM | Fokus Utama | Track |
|---|------|-----|-------------|-------|
| 1 | **Alexandrio Vega Bonito** | 241511067 | ML/AI Integration + Backend | **ML & Backend** |
| 2 | **Ersya Hasby Satria** | 241511072 | Computer Vision (PCD) + Camera | **CV/Processing** |
| 3 | **Muhammad Brata Hadinata** | 241511082 | Frontend/UI + UX | **Frontend** |
| 4 | **Varian Abidarma Syuhada** | 241511081 | Testing + DevOps + Integration | **QA/DevOps** |

---

## 🎯 Epic 1: CORE INFRASTRUCTURE (Minggu 1-2)

### Task 1.1 | [ALEXANDRIO] TFLite Model Integration
**Status**: Not Started  
**Priority**: 🔴 CRITICAL

**Deskripsi**:
Mengintegrasikan TensorFlow Lite inference engine ke dalam aplikasi Flutter.

**Deliverables**:
- [ ] Setup `tflite_flutter` plugin dengan benar
- [ ] Create `InferenceService` class untuk wrapper TFLite interpreter
- [ ] Load model dari `assets/models/gesture_model.tflite`
- [ ] Implement real inference (bukan mock lagi)
- [ ] Handle output tensor → class label + confidence
- [ ] Write unit tests untuk inference logic

**Files to Create/Modify**:
```
app/lib/core/services/inference_service.dart  (NEW)
app/lib/core/models/gesture_model.dart        (NEW)
pubspec.yaml                                   (MODIFY - sudah ada)
```

**Dependencies**:
- tflite_flutter package
- Model file: `gesture_model.tflite` (dari dataset BISINDO)
- Label mapping: `assets/models/labels.txt`

**Notes**:
- Tunggu Ersya selesai PCD pipeline dulu, baru integrate dengan inference
- Siapkan mock model jika model real belum siap

---

### Task 1.2 | [ERSYA] Real Camera Integration + PCD Pipeline
**Status**: In Progress  
**Priority**: 🔴 CRITICAL

**Deskripsi**:
Mengganti mock camera stream dengan real camera dari CameraController, dan implementasi real PCD pipeline (bukan mock).

**Deliverables**:
- [ ] Implementasi `_startImageStream()` dengan CameraImage real
- [ ] Replace mock `_processFrame()` dengan real frame processing
- [ ] Konversi warna YUV420 (Android) / BGRA (iOS) → RGB
- [ ] Center crop dengan dynamic aspect ratio
- [ ] Resize image ke 224×224
- [ ] Normalisasi pixel value ke Float32
- [ ] Passing preprocessed data ke Alexandrio's InferenceService
- [ ] Benchmark: FPS & latency pada device nyata

**Files to Create/Modify**:
```
app/lib/core/services/pcd_pipeline.dart       (MODIFY - replace mock)
app/lib/features/camera/camera_screen.dart    (MODIFY - improve streaming)
experiments/preprocessing/                     (MAINTAIN - validasi)
```

**Dependencies**:
- camera package (sudah ada)
- dart:typed_data (Uint8List, Float32List)
- Komputasi di background isolate via `compute()`

**Notes**:
- Test di Android emulator/device dulu sebelum iOS
- Dokumentasi YUV color space conversion untuk team reference

---

### Task 1.3 | [MUHAMMAD] Finish Onboarding + Home Screen
**Status**: Not Started  
**Priority**: 🟡 HIGH

**Deskripsi**:
Menyelesaikan onboarding flow dan home screen yang currently masih skeleton.

**Deliverables**:
- [ ] Create `OnboardingScreen` dengan 3-4 halaman:
  - Welcome + project intro
  - How it works (alur aplikasi)
  - Permissions request (camera, storage, TTS)
  - Ready to translate screen
- [ ] Finish `HomeScreen` (dashboard):
  - Button ke Camera Screen
  - Button ke History (Jurnal Terjemahan)
  - Statistics: total gestures recognized, accuracy
  - Quick settings
- [ ] Setup routing: Splash → Onboarding → Home
- [ ] Polish animations & transitions

**Files to Create/Modify**:
```
app/lib/features/onboarding/               (NEW - full screen)
app/lib/features/home/                     (NEW - dashboard)
app/lib/core/router/app_router.dart        (MODIFY - add routes)
```

**UI Components**:
- Reusable button components
- Page transition animations
- Icon/image assets (prepare design specs)

---

### Task 1.4 | [VARIAN] Database Layer Setup + MongoDB Config
**Status**: Not Started  
**Priority**: 🟡 HIGH

**Deskripsi**:
Setup local database (Hive) dan cloud database (MongoDB) integration.

**Deliverables**:
- [ ] Finish Hive setup untuk `TranslationEntry` model
- [ ] Create MongoDB Atlas account + project
- [ ] Setup `ApiClient` untuk MongoDB REST API calls
- [ ] Implement cloud sync logic:
  - Auto-sync when app opens & closes
  - Conflict resolution strategy
  - Offline-first approach
- [ ] Create migration utilities
- [ ] Write tests untuk sync logic

**Files to Create/Modify**:
```
app/lib/data/remote/                       (NEW - API layer)
app/lib/data/remote/api_client.dart        (NEW)
app/lib/data/remote/sync_service.dart      (NEW)
app/lib/data/local/models/translation_entry.dart (MODIFY)
```

**MongoDB Setup**:
- Cluster name: `isyarat-translator`
- Collections: `translations`, `users`, `settings`
- Indexes: timestamp, userId, confidence

---

## 🎯 Epic 2: CAMERA & INFERENCE PIPELINE (Minggu 2-3)

### Task 2.1 | [ERSYA] Skeleton Overlay Refinement
**Status**: In Progress  
**Priority**: 🟡 HIGH

**Deskripsi**:
Optimalkan custom painter untuk menggambar 21 landmark tangan dengan smooth animation.

**Deliverables**:
- [ ] Refactor `HandOverlayPainter` untuk performa
- [ ] Add smooth interpolation antar frame
- [ ] Highlight "confident" gestures dengan effect visual
- [ ] Test rendering pada berbagai ukuran layar
- [ ] Performance profiling: GPU usage, render time

**Files to Modify**:
```
app/lib/features/camera/hand_overlay_painter.dart
```

---

### Task 2.2 | [ALEXANDRIO] Gesture Classification Mapping
**Status**: Not Started  
**Priority**: 🟡 HIGH

**Deskripsi**:
Map output tensor dari TFLite ke label BISINDO + confidence scoring.

**Deliverables**:
- [ ] Create `GestureMapper` class:
  - Tensor → softmax probabilities
  - Top-1 prediction + top-3 candidates
  - Confidence threshold filtering (>0.75)
- [ ] Load labels dari `assets/models/labels.txt`
- [ ] Create mapping: gesture_id → BISINDO text
- [ ] Handle edge cases: low confidence, multi-hand, hand blur
- [ ] Logging & debugging untuk model accuracy

**Files to Create**:
```
app/lib/core/services/gesture_mapper.dart  (NEW)
```

---

### Task 2.3 | [MUHAMMAD] Real-time Result Display
**Status**: Not Started  
**Priority**: 🟡 HIGH

**Deskripsi**:
Tampilkan hasil terjemahan dengan UI yang smooth dan interaktif.

**Deliverables**:
- [ ] Refine translation panel UI
- [ ] Add "confidence meter" visual
- [ ] Gesture history ticker (last 5 gestures)
- [ ] Error state handling (no hand detected, low confidence)
- [ ] Copy-to-clipboard functionality
- [ ] Share translation result

**Files to Modify**:
```
app/lib/features/camera/camera_screen.dart (MODIFY)
```

---

## 🎯 Epic 3: SERVICES & FEATURES (Minggu 3-4)

### Task 3.1 | [ALEXANDRIA] TTS + Audio Processing
**Status**: Not Started  
**Priority**: 🟢 MEDIUM

**Deskripsi**:
Implementasi text-to-speech untuk hasil terjemahan.

**Deliverables**:
- [ ] Setup `flutter_tts` dengan multiple languages (Indonesian + English)
- [ ] Test TTS output quality & speed
- [ ] Add speech rate & pitch controls
- [ ] Handle concurrent TTS calls
- [ ] Add offline TTS support (if possible)
- [ ] Test pada Android & iOS

**Files to Modify**:
```
app/lib/core/services/tts_service.dart  (MODIFY - improve)
```

---

### Task 3.2 | [MUHAMMAD] History/Journal Screen
**Status**: Not Started  
**Priority**: 🟢 MEDIUM

**Deskripsi**:
Membuat "Buku Jurnal Terjemahan" - halaman riwayat dengan filter & search.

**Deliverables**:
- [ ] Create `HistoryScreen` dengan:
  - List view of all translations
  - Timestamp + confidence score
  - Gesture thumbnail (optional)
- [ ] Add filtering: date range, confidence threshold
- [ ] Search by gesture label
- [ ] Export history (CSV/PDF)
- [ ] Statistics dashboard:
  - Most frequent gestures
  - Accuracy over time
  - Daily usage graph
- [ ] Delete/clear history

**Files to Create**:
```
app/lib/features/history/                 (NEW - full screen)
app/lib/features/history/history_screen.dart
app/lib/features/history/history_provider.dart (Riverpod)
```

---

### Task 3.3 | [VARIAN] Settings + Preferences
**Status**: Not Started  
**Priority**: 🟢 MEDIUM

**Deskripsi**:
User settings & preferences management.

**Deliverables**:
- [ ] Create `SettingsScreen`:
  - Language selection (ID/EN)
  - TTS speed control
  - Confidence threshold setting
  - Cloud sync toggle
  - About & version
- [ ] Persist settings ke Hive
- [ ] Sync settings ke MongoDB
- [ ] Dark mode support (optional)

**Files to Create**:
```
app/lib/features/settings/               (NEW)
app/lib/data/local/preferences.dart      (NEW)
```

---

## 🎯 Epic 4: TESTING & OPTIMIZATION (Minggu 4+)

### Task 4.1 | [VARIAN] Unit & Widget Tests
**Status**: Not Started  
**Priority**: 🟡 HIGH

**Deskripsi**:
Comprehensive testing untuk core logic.

**Deliverables**:
- [ ] Unit tests:
  - PCD pipeline correctness
  - Gesture mapper (tensor → label)
  - Sync logic (Hive ↔ MongoDB)
- [ ] Widget tests:
  - Camera screen rendering
  - History list display
  - Settings persistence
- [ ] Integration tests:
  - Full flow: camera → inference → storage
  - Cloud sync workflow
- [ ] Coverage: target >70%

**Files to Create**:
```
test/core/services/pcd_pipeline_test.dart
test/core/services/inference_service_test.dart
test/features/camera/camera_screen_test.dart
test/integration/full_flow_test.dart
```

---

### Task 4.2 | [ERSYA] Performance Profiling
**Status**: Not Started  
**Priority**: 🟡 HIGH

**Deskripsi**:
Optimasi performance untuk latency rendah.

**Deliverables**:
- [ ] Profile FPS & frame latency
- [ ] Memory profiling (especially during inference)
- [ ] CPU optimization: batch processing, caching
- [ ] Benchmark pada mid-range devices
- [ ] Performance report & recommendations

**Tools**:
- Flutter DevTools → Performance tab
- Dart VM profiler
- Device-specific profilers (Android Profiler, Xcode Instruments)

---

### Task 4.3 | [VARIAN] Build & Release
**Status**: Not Started  
**Priority**: 🟢 MEDIUM

**Deskripsi**:
Prepare aplikasi untuk release di Google Play Store.

**Deliverables**:
- [ ] Setup signing certificates
- [ ] Configure build variants (debug/release/staging)
- [ ] Create APK & AAB
- [ ] Test on multiple devices/OS versions
- [ ] Prepare store listing:
  - App description
  - Screenshots
  - Privacy policy
  - Terms of service
- [ ] Set up CI/CD pipeline (GitHub Actions)

---

## 📁 File Structure Guide

```
app/
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── models/
│   │   │   ├── inference_result.dart       ✅ DONE
│   │   │   └── gesture_model.dart          ⏳ TODO (ALEXANDRIO)
│   │   ├── services/
│   │   │   ├── pcd_pipeline.dart           🔄 IN PROGRESS (ERSYA)
│   │   │   ├── inference_service.dart      ⏳ TODO (ALEXANDRIO)
│   │   │   ├── gesture_mapper.dart         ⏳ TODO (ALEXANDRIO)
│   │   │   ├── tts_service.dart            🔄 IN PROGRESS
│   │   │   └── sync_service.dart           ⏳ TODO (VARIAN)
│   │   ├── router/
│   │   │   └── app_router.dart             🔄 IN PROGRESS (MUHAMMAD)
│   │   └── theme/
│   │       └── app_theme.dart              ✅ DONE
│   ├── features/
│   │   ├── camera/
│   │   │   ├── camera_screen.dart          🔄 IN PROGRESS (ERSYA)
│   │   │   └── hand_overlay_painter.dart   🔄 IN PROGRESS (ERSYA)
│   │   ├── onboarding/                     ⏳ TODO (MUHAMMAD)
│   │   ├── home/                           ⏳ TODO (MUHAMMAD)
│   │   ├── history/                        ⏳ TODO (MUHAMMAD)
│   │   └── settings/                       ⏳ TODO (VARIAN)
│   └── data/
│       ├── local/
│       │   ├── models/
│       │   │   └── translation_entry.dart  ✅ DONE
│       │   ├── journal_repository.dart     ✅ DONE
│       │   └── preferences.dart            ⏳ TODO (VARIAN)
│       └── remote/                         ⏳ TODO (VARIAN)
│           ├── api_client.dart
│           └── sync_service.dart
├── test/                                    ⏳ TODO (VARIAN)
└── assets/
    └── models/
        ├── gesture_model.tflite            ⏳ TODO (ALEXANDRIO - setup)
        └── labels.txt                      ⏳ TODO (ALEXANDRIO)
```

---

## 🔄 Dependencies & Integration Points

```
ALEXANDRIO              ERSYA                  MUHAMMAD               VARIAN
(ML/Backend)            (CV/Processing)        (Frontend)             (QA/DevOps)
    │                       │                      │                      │
    ├──────────────────────►├──────────────────────┤                      │
    │   TFLite Model       │ PCD Pipeline         │ UI Update            │
    │                       │                      │                      │
    │                       ├──────────────────────►├──────────────────────┤
    │                       │   Result             │ Display/Store       │
    │                       │                      │                      │
    ├──────────────────────────────────────────────►├──────────────────────┤
    │   TFLite Inference     Gesture Mapper         │ TTS/Haptic           │
    │                                               │                      │
    ├──────────────────────────────────────────────────────────────────────┤
    │                     Database & Cloud Sync (Hive + MongoDB)           │
    └─────────────────────────────────────────────────────────────────────┘
```

---

## ✅ Checklist & Milestone

### Milestone 1: Core Infrastructure (Week 1-2)
- [ ] Task 1.1 (ALEXANDRIO) - TFLite Integration
- [ ] Task 1.2 (ERSYA) - Real Camera + PCD
- [ ] Task 1.3 (MUHAMMAD) - Onboarding + Home
- [ ] Task 1.4 (VARIAN) - Database Setup

### Milestone 2: Inference Pipeline (Week 2-3)
- [ ] Task 2.1-2.3 completed
- [ ] End-to-end testing: camera → inference → display

### Milestone 3: Features & Services (Week 3-4)
- [ ] Task 3.1-3.3 completed
- [ ] TTS, History, Settings fully functional

### Milestone 4: Quality & Release (Week 4+)
- [ ] Task 4.1-4.3 completed
- [ ] All tests passing (>70% coverage)
- [ ] Performance optimized
- [ ] Ready for store submission

---

## 📞 Communication Protocol

**Standup Meeting**: Every Monday & Thursday 10:00 AM  
**Emergency Sync**: Discord/WhatsApp group (real-time issues)  
**Progress Tracking**: Update this file weekly

**Git Commit Convention**:
```
[TASK-X.X] [Name] Brief description

Example:
[TASK-1.1] [Alexandrio] Setup TFLite interpreter wrapper
[TASK-2.2] [Ersya] Implement YUV to RGB color conversion
[TASK-3.1] [Muhammad] Create onboarding flow
[TASK-4.2] [Varian] Add sync conflict resolution
```

---

## 📚 Reference Documents

- PROPOSAL.md - Project overview & methodology
- README.md - Architecture & pipeline details
- app/assets/models/README.txt - Model integration guide

---

**Last Updated**: May 22, 2026  
**Status**: Planning Phase ✓
