# 🐱 Felis AI (Purrsona)

A smart, AI-powered mobile application for cat breed detection, care guidance, and veterinary services location. Built for the Final Year Project (FYP) 2025.

![App Screenshot](assets/images/app_showcase.png) ## 🚀 Features

* **🤖 AI Breed Detection:** Instant offline identification of 12+ cat breeds using a custom fine-tuned EfficientNetV2B0 model (TFLite).
* **🛡️ Gatekeeper Logic:** Automatically distinguishes between "Cats" and "Not Cats" to prevent false positives.
* **🧠 Personality Analysis:** Interactive quiz to determine a cat's personality type (e.g., "Social Butterfly", "Hunter").
* **🗺️ Nearby Services:** Integrated Google Maps locator for Vet Clinics and Pet Shops with real-time filtering.
* **📚 Breed Codex:** A comprehensive, searchable encyclopedia of cat breeds with care tips and health info.
* **📂 History & Archives:** Saves detection results locally using SQLite for future reference.
* **✨ Name Generator:** Suggests creative names based on the detected breed and personality.

## 🛠️ Tech Stack

* **Framework:** Flutter (Dart)
* **Machine Learning:** TensorFlow Lite (Python for training, tflite_flutter for inference)
* **Local Database:** SQLite (sqflite)
* **Maps & Location:** Google Maps SDK, Google Places API, Geolocator
* **Architecture:** MVC (Model-View-Controller) pattern with Service-based abstraction.

## 📦 Installation & Setup

1.  **Clone the repository**
    ```bash
    git clone [https://github.com/yourusername/felis-ai.git](https://github.com/yourusername/felis-ai.git)
    ```

2.  **Install Dependencies**
    ```bash
    flutter pub get
    ```

3.  **Setup API Keys**
    * Create a file `android/local.properties`.
    * Add your Google Maps API Key: `maps_api_key=YOUR_KEY_HERE`.

4.  **Run the App**
    * **Debug Mode:** `flutter run --no-enable-impeller` (Recommended for Emulators)
    * **Release Mode:** `flutter run --release` (Recommended for physical devices)

## 🧠 ML Model Details

The app uses a **Hierarchical Model Architecture**:
1.  **Gatekeeper:** Binary classifier (MobileNetV2) to filter non-cat images.
2.  **Generalist:** Multiclass classifier (EfficientNetV2B0) for 12 core breeds.
3.  **Expert:** Specialized classifier for visually similar breeds (e.g., Ragdoll vs. Birman).

## 📝 License
This project is developed for academic purposes.