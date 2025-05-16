# HealthKit Generator
<img src="Screenshots/healthKitGenerator.png" width="120" alt="App Icon" />

🚀 **My first Vibe Coded project!**  
A HealthKit companion app for generating high-volume synthetic health data — ideal for testing apps that rely on Apple's HealthKit.

---

## 🩺 What is this?

**HealthKit Generator** is a minimalistic, SwiftUI-based iOS app designed to write large amounts of fake HealthKit data into the Health app (on simulator or device). It’s perfect for:

- Debugging HealthKit-based apps
- Simulating various metrics from multiple sources
- Reproducing bugs or performance bottlenecks
- Testing UI/UX on real data patterns

---

## 🧠 Features

- ✅ HealthKit permission request with one tap
- 🎛 Metric toggles (Steps, Heart Rate, HRV, Body Temp, etc.)
- 📅 Generates synthetic data for the past 30 days
- 🧹 Auto-deletes old synthetic data before writing
- 📝 Scrollable log with real-time feedback
- 💡 Minimal SwiftUI UI focused on dev productivity

<p float="left">
  <img src="Screenshots/mock1.jpg" width="200" style="margin-right: 10px;" />
  <img src="Screenshots/mock2.jpg" width="200" style="margin-right: 10px;" />
  <img src="Screenshots/mock3.jpg" width="200" />
</p>
  
---

## 📲 Metrics supported

You can toggle any of these on/off before generating:

- 👣 Step Count  
- ❤️ Heart Rate  
- 💤 Resting Heart Rate  
- 📈 Heart Rate Variability (SDNN)  
- 🌬 Respiratory Rate  
- 🌡 Body Temperature  
- 🔥 Active Energy Burned  
- 🔋 Basal Energy Burned  
- 🛌 Sleep (fixed 11PM–7AM block)

> 🔐 The app respects HealthKit’s permissions — only metrics with write access are written.

---

## 🚀 How to Use

1. **Clone this repo**:
    ```bash
    git clone https://github.com/lukassmetana/healthkit-generator.git
    cd healthkit-generator
    ```

2. **Open in Xcode**:
    Open `HealthKitGenerator.xcodeproj` in Xcode 15 or newer.

3. **Run on a simulator** (recommended):
    - Preferably **not your personal Apple ID**.
    - HealthKit will simulate data even without a real Apple Watch/iPhone.

4. **In the app**:
    - Tap **Give Permission** to enable HealthKit write access.
    - Toggle desired metrics.
    - Tap **Generate Data** → This creates data for the past 30 days.
    - Tap **Delete Data** to remove previously written synthetic entries.
    - Use **Clear Log** to reset the log view.

---

## 🧪 Why it exists

I built this to stress-test and validate my main app that uses real-world HealthKit data. I needed thousands of realistic entries from various sources and intervals (e.g. Oura vs iPhone vs Apple Watch). Rather than hack my main app, I created this open-source companion.

---

## 📦 Tech Stack

- SwiftUI
- HealthKit
- ObservableObject architecture
- Xcode project templates only (no external dependencies)

---

## 🧊 Disclaimer

This project is for development and testing only. It writes synthetic data to HealthKit which may affect real apps if used outside a simulator.

---

## ❤️ Shoutout

This is my first project coded with intention and clarity — and the first in my growing collection of **Vibe Coded** tools. Built with care for devs who test deeply.

---

## 📄 License

[MIT License](LICENSE)

---
