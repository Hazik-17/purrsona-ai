
# 🐱 Purrsona AI

**Offline-First Cat Breed Classification & Care Companion**
*Developed for Bachelor of Computer Science (Hons.) - CSP650 Final Year Project*

## 📖 Abstract

**Purrsona AI** is a native mobile application designed to solve the challenge of accurately identifying visually similar cat breeds (e.g., Birman vs. Ragdoll) without relying on internet connectivity. Unlike standard cloud-based classifiers, Purrsona AI runs a **Hierarchical Deep Learning Pipeline** entirely on-device, ensuring privacy, speed, and accessibility in remote areas.

## 🚀 Key Features

* **⚡ True Offline AI:** Runs inference locally using **TensorFlow Lite (Int8 Quantized)** models. No API calls required for detection.
* **🛡️ The Gatekeeper:** A dedicated binary classifier that filters out non-cat images with **99.94% precision**, preventing false positive results.
* **🔍 Hierarchical Detection:**
* **Generalist:** Identifies 12 core breeds (e.g., Persian, Siamese, Bengal).
* **Expert:** Automatically activates for ambiguous pairs to resolve fine-grained differences.

* **🏥 Nearby Services:** Google Maps integration to find Vet Clinics & Pet Shops (requires internet).
* **📂 Smart Archive:** Automatically compresses and saves scan history to a local SQLite database to save storage.
* **🧠 Personality Profiler:** Estimates cat temperament based on breed traits and user-input behavior.

## 📊 Performance Metrics (Verified)

| Metric | Result | Description |
| --- | --- | --- |
| **Overall Accuracy** | **93.47%** | Tested on Oxford-IIIT Pet Dataset |
| **Gatekeeper Precision** | **99.94%** | Success rate in rejecting non-cat objects |
| **Inference Speed** | **< 2.0s** | End-to-end processing on POCO F7 Ultra |
| **Model Size** | **~12.5 MB** | Total footprint (Int8 Quantized) |
| **Peak RAM Usage** | **< 500 MB** | Optimized for mid-range Android devices |

## 🛠️ Tech Stack

* **Framework:** Flutter (Dart 3.x)
* **Architecture:** MVC (Model-View-Controller) with Service Layer
* **ML Engine:** TensorFlow Lite (`tflite_flutter`)
* **Model Architecture:** EfficientNetV2B0 (Transfer Learning)
* **Database:** SQLite (`sqflite`)
* **State Management:** Provider / Native State
* **Mapping:** Google Maps SDK

## 🧠 Hierarchical Model Architecture

The core innovation of Purrsona AI is its multi-stage inference pipeline:

1. **Stage 1: Gatekeeper (Binary)**
* *Input:* Raw Image (224x224)
* *Action:* Checks if the subject is a "Cat". If score < Threshold, aborts process.

2. **Stage 2: Generalist (Multi-class)**
* *Input:* Valid Cat Image
* *Action:* Classifies into one of 12 primary clusters.

3. **Stage 3: Expert (Refinement)**
* *Input:* Ambiguous Result (e.g., "Birman" or "Ragdoll")
* *Action:* Uses specialized feature extraction to determine the final label.

## 📦 Installation & Setup

1. **Clone the repository**
```bash
git clone https://github.com/Hazik-17/purrsona-ai.git

```

2. **Install Dependencies**
```bash
flutter pub get

```

3. **Asset Configuration**
* Ensure the `.tflite` models and `labels.txt` are present in `assets/models/`.

4. **Run the App**
* **Debug:** `flutter run`
* **Profile (for RAM testing):** `flutter run --profile`

## 📝 License

This project is developed exclusively for educational purposes as part of the academic curriculum at **Universiti Teknologi MARA (UiTM)**.

---

*Developed by **Hazik Razak***