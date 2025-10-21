# StressLessAI

StressLessAI is a macOS menu bar application that helps you monitor and manage stress by analyzing your facial landmarks in real time. Using your camera, the app provides continuous feedback on your stress levels, helping you stay mindful and take control of your well-being.

## Key Features

*   **Real-Time Stress Monitoring:** The app uses your camera to track key facial landmarks and calculates a real-time stress score.
*   **Menu Bar Integration:** StressLessAI lives in your menu bar, providing unobtrusive, at-a-glance feedback on your current stress level.
*   **Robust Data Persistence:** The app features a professional-grade SQLite data layer that securely stores your telemetry data in the proper `Application Support` directory.
*   **Automated Builds:** The application is built and packaged automatically using a GitHub Actions workflow, ensuring a consistent and reliable build process.
*   **Modern & Concurrent:** The app has been updated to use modern Swift concurrency features, ensuring a smooth and responsive user experience.

## Getting the Application

The `StressLessAI.app` bundle is automatically built by our GitHub Actions workflow. To get the latest version of the application:

1.  Navigate to the **Actions** tab in the GitHub repository.
2.  Select the latest successful workflow run for the `main` branch.
3.  Under **Artifacts**, click on **StressLessAI.app** to download the application bundle.

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

## Future Development

We have an exciting roadmap for StressLessAI, including:

*   **Predictive Interventions:** The app will soon be able to predict rising stress levels and offer timely interventions.
*   **Live Dashboard:** We are working on a live dashboard that will provide a more detailed view of your stress levels over time.
*   **Session-End Recommendations:** The app will provide personalized recommendations at the end of each session.

We welcome contributions from the community. If you are interested in contributing, please fork the repository and submit a pull request.
