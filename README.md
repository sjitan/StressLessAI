# StressLessAI

StressLessAI is a sophisticated macOS menu bar application designed to provide real-time, intelligent feedback on your stress levels by analyzing facial landmarks via your camera. It acts as a proactive co-pilot for your well-being, helping you stay mindful and in control.

## Key Features

*   **Live Dashboard with Thresholds:** A clear, color-coded dashboard provides an at-a-glance view of your stress levels, with distinct zones for low, medium, and high stress.
*   **AI-Powered Predictive Interventions:** The application's intelligent core analyzes your stress trends in real-time. If it detects a rapidly rising stress level, it will proactively send you a notification, prompting you to take a moment to refocus.
*   **Personalized Session-End Recommendations:** At the end of each session, the `PredictionEngine` provides a personalized, insightful summary of your stress patterns, helping you identify triggers and improve your well-being over time.
*   **Robust & Secure Data Persistence:** The app features a professional-grade SQLite data layer that securely stores your telemetry data in the appropriate `Application Support` directory, respecting macOS conventions.
*   **Automated Builds:** The application is built and packaged automatically using a GitHub Actions workflow, ensuring a consistent and reliable build process.

## Technology Stack

StressLessAI is built on a modern, robust technology stack, chosen for performance and reliability:

*   **Language:** Swift 5.10
*   **UI Framework:** SwiftUI for a modern, declarative user interface.
*   **Core Frameworks:**
    *   **AVFoundation:** For capturing and processing the camera feed.
    *   **Vision:** For detecting facial landmarks.
*   **Database:** A native SQLite implementation for efficient, local data persistence.

## The AI Model: How It Works

The intelligence of StressLessAI is driven by a sophisticated trend-detection model based on **Exponential Moving Averages (EMA)**. Here’s a transparent, no-hype explanation:

1.  **Real-Time Data Stream:** The application processes a continuous stream of stress scores, calculated from your facial landmarks.
2.  **Short-Term vs. Long-Term Trends:** The `PredictionEngine` maintains two separate EMAs:
    *   A **short-term EMA** that reacts quickly to recent changes in your stress level.
    *   A **long-term EMA** that represents your baseline stress level over a longer period.
3.  **Predictive Intervention Trigger:** A predictive intervention is triggered when the short-term EMA crosses significantly above the long-term EMA. This indicates a rapid, anomalous increase in stress, prompting the application to send you a helpful notification.

This EMA-based approach provides a reliable and responsive model for detecting meaningful changes in your stress levels, without the need for a complex, heavyweight AI model.

## How to Run the Application

The `StressLessAI.app` bundle is automatically built by our GitHub Actions workflow. To run the latest version:

1.  Navigate to the **Actions** tab in the GitHub repository.
2.  Select the latest successful workflow run for the `main` branch.
3.  Under **Artifacts**, click on **StressLessAI.app** to download the application bundle.

**Important: Bypassing macOS Gatekeeper**

Because the application is not yet signed and notarized by Apple, you will need to manually approve it to run the first time.

1.  Unzip the downloaded `StressLessAI.app.zip` file.
2.  Move `StressLessAI.app` to your `Applications` folder.
3.  **Right-click** (or Control-click) the `StressLessAI.app` icon and select **Open**.
4.  You will see a warning dialog. Click the **Open** button to run the application.

You will only need to do this once. After you have approved it, you can launch the application normally.

## Building from Source

To build and run StressLessAI from source, you will need Xcode 14 or later and macOS Ventura or later.

1.  Clone the repository:
    ```
    git clone https://github.com/your-username/StressLessAI.git
    ```
2.  Run the build script:
    ```
    ./StressLessAI/build.sh
    ```
3.  The `StressLessAI.app` bundle will be located in the `build` directory.
