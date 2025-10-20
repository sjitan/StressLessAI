# 🫨 StressLessAI

**StressLessAI** is a fully native macOS app that uses real-time facial telemetry to detect and visualize user stress levels — helping students, developers, and professionals recognize rising stress and recover before burnout.

---

## 💡 Overview

- Runs quietly in the macOS menu bar.  
- Uses **Apple Vision**, **AVFoundation**, and **CoreML** (no external dependencies).  
- Tracks facial landmarks (eyes, mouth, eyebrows, head motion).  
- Computes a live **stress score (0–100)** and learns your personal baseline over time.  
- Issues subtle notifications when stress stays high — encouraging you to take a break, stretch, or hydrate.  
- All data stays **on-device**; privacy-first architecture.

---

## ⚙️ Features

| Category | Details |
|-----------|----------|
| **AI / ML** | On-device CoreML model learns your baseline stress pattern (EMA). |
| **Telemetry** | Blink rate, mouth openness, head jitter, roll/pitch/yaw. |
| **Visualization** | Robinhood-style chart (green/yellow/red) with session markers. |
| **Notifications** | “Take a Break” alert after 90s sustained high stress. |
| **Storage** | CoreData local DB (sessions, samples, configs). |
| **Modes** | Study, Code, Call, or Open — each with tuned thresholds. |
| **Demo** | Synthetic data mode for systems without a camera. |
| **Accessibility** | VoiceOver labels, high contrast palette, and reduce-motion support. |

---

## 🧠 Tech Stack

- Swift + SwiftUI (macOS 13+)  
- Vision, AVFoundation, CoreML  
- CoreData for persistence  
- UserNotifications for alerts  
- Swift Charts for dashboard

---

## 🔒 Privacy

- All processing and data storage happen locally.  
- No cloud, no external APIs, no tracking.  
- Optional data export / purge (`Erase All Data` in settings).

---

## 🚀 Build & Run

```bash
git clone https://github.com/sjitan/StressLessAI.git
cd StressLessAI
swift build && swift run
