# Kinsu Health

A basic iOS health app with a **Home** tab that shows:

1. **BP & pulse widget** – Blood pressure (systolic/diastolic) and heart rate with last updated time  
2. **Recent opened prescriptions** – List of recently opened prescriptions with medication name, doctor, and time ago  
3. **Next doses** – Upcoming and overdue doses with medication, dosage, and time  

## Setup

1. Install [Flutter](https://docs.flutter.dev/get-started/install) and ensure it’s on your PATH.
2. Generate the iOS (and optionally Android) runner:

   ```bash
   cd kinsu-health-ui
   flutter create . --project-name kinsu_health
   ```

   If the project already has `ios/`, you can skip this or run it anyway to refresh platform files.

3. Install dependencies:

   ```bash
   flutter pub get
   ```

4. Run on iOS simulator or device:

   ```bash
   flutter run
   ```

   Or open `ios/Runner.xcworkspace` in Xcode and run from there.

## Project structure

- `lib/main.dart` – App entry and theme  
- `lib/screens/home_screen.dart` – Home tab with the three sections in order  
- `lib/widgets/bp_pulse_widget.dart` – Blood pressure and pulse card  
- `lib/widgets/recent_prescriptions.dart` – Recent prescriptions list  
- `lib/widgets/next_doses.dart` – Next doses list  
- `lib/models/` – Prescription and NextDose models  
- `lib/data/mock_data.dart` – Mock data for development  

Data is currently mock; you can later connect to HealthKit or your backend.
