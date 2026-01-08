

# 📘 SmallTalk — Project Documentation
**Local, Instant Voice → Text → Paste Assistant for macOS**

---

## 1. Project Overview

### 1.1 Objective

Build a **native macOS application** that allows users to **toggle voice recording**, perform **fully local speech-to-text** using Apple Silicon hardware acceleration, and **paste the transcribed text into the currently focused application** with minimal latency.

The application must:

- Run **fully on-device**
- Work **offline**
- Feel **instant** (target: ≤ 3 seconds from stop → paste)
- Use **open-source models hosted on Hugging Face**
- Be architected for future **AI prompt optimization**

---

### 1.2 Primary Use Case

> “I press a hotkey, speak my thoughts, press the hotkey again, and the text appears where my cursor is.”

Target environments include:
- Browser-based AI tools (ChatGPT, Claude, etc.)
- Slack, Notion, email clients
- IDEs and code editors
- Any macOS text input field

---

## 2. Scope

### 2.1 In Scope (MVP)

- macOS app (Apple Silicon only)
- Toggle-based recording (start / stop)
- Local speech-to-text
- Clipboard paste into focused app
- Global hotkey
- Menubar UI with status indicator
- Multilingual transcription (European languages)
- No cloud dependency after first launch

---

### 2.2 Out of Scope (MVP)

- Auto-submit (Enter key)
- Live streaming captions
- Cloud inference
- iOS support
- User accounts / sync
- Audio file import/export
- Prompt optimization (documented for later)

---

## 3. Key Technical Decisions (Frozen)

### 3.1 Speech Recognition Model

**Model**
```
FluidInference/parakeet-tdt-0.6b-v3-coreml
```

**Source**
- Hugging Face
- Open source
- CoreML-converted

**Capabilities**
- Multilingual transcription (25 European languages)
- Automatic punctuation and capitalization
- Word-level timestamps (future use)
- Optimized for low-latency, short utterances

**Rationale**
- Best perceived latency for interactive dictation
- Fully local on Apple Silicon
- No PyTorch runtime in production

**Trade-off**
- Slightly lower WER than Whisper-large
- Chosen because **UX latency > absolute accuracy**

---

### 3.2 Runtime & Inference Stack

- **CoreML** (Apple Neural Engine / CPU)
- **FluidAudio SDK** for:
  - Model download & caching
  - Audio preprocessing
  - Decoder logic

**Explicitly excluded**
- PyTorch runtime
- Cloud APIs

---

### 3.3 Audio Input Format

- `AVAudioEngine`
- Mono
- 16 kHz
- Float32 samples in range `[-1, 1]`
- Audio buffered in memory during recording

---

### 3.4 Interaction Model

- **Toggle-based**
  - First hotkey press → start recording
  - Second hotkey press → stop → transcribe → paste
- **Paste-only**
  - No automatic “Enter” / submit

**Reasoning**
- Toggle eliminates VAD tail latency
- Deterministic stop timing
- Maximum user control

---

## 4. Application Architecture

### 4.1 High-Level Flow

```
Hotkey Press
   ↓
Start Audio Capture
   ↓
User Speaks
   ↓
Hotkey Press
   ↓
Stop Capture
   ↓
Local ASR (CoreML)
   ↓
Clipboard Write
   ↓
Cmd + V into focused app
```

---

### 4.2 Core Components

| Component        | Responsibility |
|------------------|----------------|
| HotkeyService    | Global toggle hotkey |
| AudioCapture     | Mic input, resampling |
| AsrService       | Local ASR inference |
| PasteService     | Clipboard + paste |
| AppState         | Recording state machine |
| MenubarView      | UI & status |

---

### 4.3 State Machine

```
Idle
 └── hotkey → Recording
Recording
 └── hotkey → Processing
Processing
 └── success → Idle
 └── error → Idle (error shown)
```

---

## 5. Performance Requirements

### 5.1 Latency Targets

- **P50 stop → paste:** ≤ 1.5s
- **P95 stop → paste:** ≤ 3.0s
- Typical utterance length: 2–8 seconds

---

### 5.2 UX Requirements

- No blocking UI
- Clear recording indicator
- Immediate paste once transcription is ready
- Deterministic behavior (no silent failures)

---

## 6. Permissions & Security

### Required macOS Permissions

- Microphone access
- Accessibility access (for paste simulation)

---

### Privacy Guarantees

- No audio leaves the device
- No network calls after model download
- No telemetry by default

---

## 7. Model Lifecycle

### First Launch

- Download CoreML models via FluidAudio
- Cache in Application Support directory

### Subsequent Launches

- Load models from local cache
- Fully offline operation

---

## 8. Future Extensions (Not in MVP)

### 8.1 Prompt Optimization Layer

Second-stage text-only processing that:
- Takes raw transcript
- Extracts intent, constraints, output format
- Produces an optimized AI prompt

Decoupled from ASR and optional.

---

### 8.2 Model Fallback (Optional)

- Detect low-confidence or unsupported language
- Fallback to Whisper-based CoreML model
- Not part of MVP

---

## 9. Team Responsibilities

### macOS Developer (Swift)

- App lifecycle & architecture
- Hotkeys
- Audio capture & resampling
- Menubar UI
- Permissions handling
- Clipboard & paste logic
- Performance profiling

---

### AI Engineer

- ASR model validation
- Language coverage testing
- Latency benchmarking
- Audio preprocessing verification
- Design of future prompt-optimizer

---

## 10. Definition of Done (MVP)

The project is complete when:

- ✅ Global toggle hotkey works reliably
- ✅ Speech is transcribed fully locally
- ✅ Text is pasted into focused app
- ✅ P95 latency ≤ 3s on Apple Silicon
- ✅ No internet required after first launch
- ✅ Stable multilingual transcription
- ✅ Clean, documented codebase

---

## 11. Deliverables

- macOS application (Swift / SwiftUI)
- This `PROJECT.md`
- Minimal README
- Latency & language benchmark notes

---

## 12. Strategic Note

This project is **not just dictation**.

It is the **foundation layer** for:
- Thought → text
- Thought → structured prompts
- Human-speed AI interaction

Optimizing **local latency and reliability first** is a deliberate strategic choice.

---
