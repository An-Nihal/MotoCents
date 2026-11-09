# MotoCents 🏍️💰

A production-quality, cross-platform (Android, iOS & Web PWA) mobile app built with Flutter for tracking vehicle fuel fill-ups and mileage, maintenance servicing, vehicle expenses, and sensitive driver/vehicle documents with client-side encryption.

---

## 📱 Live Web App & Instant iPhone Install

Anyone can run MotoCents immediately without installing anything from an app store, or install it as a standalone progressive web app on iPhone / iPad with zero sideloading:

🌐 **Live Web App**: **[https://an-nihal.github.io/MotoCents](https://an-nihal.github.io/MotoCents)**

### 🍏 How to Install on iPhone / iPad:
1. Open **[https://an-nihal.github.io/MotoCents](https://an-nihal.github.io/MotoCents)** in **Safari**.
2. Tap the **Share** button (the square with an upward arrow at the bottom).
3. Scroll down and tap **Add to Home Screen** (হোম স্ক্রিনে যোগ করুন).
4. Tap **Add**. MotoCents installs directly to your home screen with its app icon and runs full screen with offline support!

---

## 🌟 Core Principles

- **Offline-First & Local-Only (v1):** No sign-in required, zero external backend dependencies, no cloud telemetry. All database records and encrypted vault files reside exclusively on the device.
- **Privacy & Authenticated Encryption:** Driver documents (driving license, smart card, tax token) and receipt photos are encrypted using **AES-256-GCM** with keys secured in `flutter_secure_storage`.
- **Fast Entry:** Logging a fuel fill-up takes under 10 seconds with smart auto-calculations (2-of-3 quantity/price/total reconciliation) and receipt/odometer OCR.
- **Sync-Ready Architecture:** Designed with repository patterns, UUID primary keys, and audit fields (`createdAt`, `updatedAt`, `deletedAt`) on every entity to support Phase 2 cloud sync (Firebase Auth + Firestore) without rewriting.
- **Bilingual & Locale-Aware:** Full English and Bangla (বাংলা) localization from day one, user-selectable currency (defaulting to BDT ৳), and locale-aware digit formatting (`০, ১, ২...`).

---

## 🏗 Architecture & Tech Stack

```
lib/
├── core/
│   ├── database/                  # Drift SQLite database, tables, DAOs, migrations & seeds
│   ├── localization/              # ARB files (en, bn), generated delegates, and LocaleFormatter
│   ├── notifications/             # Local notifications service & timezone scheduling
│   ├── providers/                 # Core global providers (database, settings, active vehicles)
│   ├── router/                    # GoRouter configuration with StatefulShellRoute
│   └── theme/                     # Material 3 styling, color schemes, light/dark themes
└── features/
    ├── garage/                    # Multi-vehicle management (cars, bikes, CNG, microbus, trucks)
    ├── fuel/                      # Fuel logs, full-to-full mileage calculation, units converter
    ├── service/                   # Maintenance entries, multi-item services, distance & date reminders
    ├── documents/                 # Encrypted document vault, local_auth biometric/PIN lock, Quick Show
    ├── expenses/                  # General running costs (tolls, parking, wash, fines, loan/EMI)
    ├── dashboard/                 # Home overview, KPI cards, recent alerts, and quick actions
    ├── statistics/                # Spend charts, mileage trends, donut breakdown, TCO calculations
    ├── smart/                     # Receipt/odometer OCR, mileage drop alerts, station insights, trip calculator
    ├── reports/                   # Buyer-ready PDF Vehicle History, multi-sheet Excel, CSV export & import
    ├── backup/                    # Encrypted .fslbackup archive creation, restore, and 30-day reminder
    ├── onboarding/                # 3-slide interactive walkthrough & initial vehicle onboarding
    ├── settings/                  # User preferences, currency selector, custom type management
    └── shell/                     # Bottom navigation bar with vehicle switcher app bar
```

### Technology Highlights
- **Framework:** Flutter (latest stable, null-safe Dart)
- **State Management:** Riverpod 3 (NotifierProvider, StreamProvider, AsyncValue)
- **Local Database:** Drift (SQLite) with fluent type-safe query generation
- **Cryptographic Engine:** `cryptography` (AES-256-GCM cipher with PBKDF2-HMAC-SHA256 key derivation)
- **Vault Security:** `flutter_secure_storage` + `local_auth` (Fingerprint / Face ID / PIN)
- **Document & Receipt Scanning:** `cunning_document_scanner` + `image_picker` + `file_picker`
- **On-Device OCR:** `google_mlkit_text_recognition`
- **Visual Analytics:** `fl_chart` (Line charts, stacked bar charts, donut charts)
- **Document Generation & Sharing:** `pdf` + `printing` + `excel` + `csv` + `share_plus`
- **Background Reminders:** `flutter_local_notifications` + `timezone`

---

## 🚀 Key Feature Sets

### 1. Garage & Vehicles
- Manage multiple vehicles: cars, motorcycles, CNG/auto-rickshaws, microbuses, trucks, and custom vehicles.
- Custom units per vehicle: Distance (`km`, `mi`), Volume (`L`, `gal`), Economy (`km/L`, `L/100km`, `MPG`).
- Fast vehicle switcher available right from the navigation app bar.

### 2. Fuel Log & Mileage Calculation (Full-to-Full Method)
- Live 2-of-3 calculation: enter any two of **Quantity**, **Price per unit**, or **Total cost**, and the third is instantly calculated.
- Option to enter **Trip meter distance** instead of raw odometer (automatically converted to odometer).
- **Exact Full-to-Full Algorithm**:
  $$\text{Distance} = \text{Odometer}(F_i) - \text{Odometer}(F_j)$$
  $$\text{Fuel Used} = \sum_{k=j+1}^{i} \text{Quantity}(F_k)$$
  $$\text{Mileage} = \frac{\text{Distance}}{\text{Fuel Used}}$$
- Partial fill-ups accumulated into the next full fill-up; missed fill-ups flag prevents distorted mileage spikes.

### 3. Service Log & Preventive Maintenance
- Pre-seeded service types (Engine oil, oil filter, air filter, fuel filter, spark plugs, brake pads, tyres, battery, wash, etc.) plus custom user-defined types.
- Multi-item service records with labor cost breakdown, mechanic/garage name, and encrypted receipt attachments.
- **Predictive Reminders**: Distance-based (every $X\text{ km}$), time-based (every $X\text{ months}$), or whichever comes first, with remaining distance/date progress bars.

### 4. Encrypted Document Vault
- Pre-configured document categories (Driving License, Blue Book / Registration, Tax Token, Smart Card, Fitness Certificate, Insurance, Route Permit, National ID) + custom types.
- Client-side encryption: Document photos and PDFs are encrypted using AES-256-GCM before saving to disk.
- **Vault Lock**: Biometric unlock with 4–6 digit fallback PIN and configurable auto-lock timeout.
- **Quick Show Mode**: Instant full-screen, swipeable carousel with max brightness and wake-lock for traffic inspections.
- Expiry alerts scheduled for 30, 15, 7, and 1 day before expiration.

### 5. Other Expenses, Dashboard & Statistics
- Track tolls, parking, washing, traffic fines, renewals, accessories, loan/EMI, and custom categories.
- Real-time Home Dashboard: current odometer, latest mileage, rolling average economy, monthly expenditure, upcoming service cards, and expiring documents.
- Analytics: Mileage trend line chart, monthly stacked spend bar chart, category donut breakdown, fuel price history, and Total Cost of Ownership (TCO).

### 6. Smart / Convenience Features
- **Receipt & Odometer OCR**: Machine learning powered text extraction for instant fill-up form population.
- **Mileage Drop Alert**: Contextual warnings if mileage dips $>15\%$ below rolling average ("Check tyre pressure, air filter, or fuel quality").
- **Station Insights**: Average fuel economy and average unit price per station to identify fuel quality.
- **Trip Cost Calculator**: Estimate required fuel volume, total fuel budget, and per-passenger split cost based on vehicle efficiency.

### 7. Reports, Data Export & Encrypted Backups
- **Vehicle History Dossier (PDF)**: Comprehensive buyer-ready PDF document including vehicle specs, TCO financial breakdown, service logs, and fuel summary.
- **Spreadsheet Exports**: RFC 4180 CSV logs and complete multi-sheet Excel (`.xlsx`) workbooks.
- **CSV Data Import**: Import past logs from other apps with automated column guessing, sample preview dialog, and missing-value reconciliation.
- **Encrypted Backup & Restore (`.fslbackup`)**: Single password-protected archive bundling SQLite database and vault attachments.
- Automated 30-day backup reminder.

### 8. Settings & Customization
- Theme (System / Light / Dark) and Language (English / বাংলা) switching.
- Multi-currency support (`BDT ৳`, `USD $`, `EUR €`, `GBP £`, `INR ₹`, etc.).
- Custom service types, expense categories, and document types management.
- 3-slide interactive Onboarding flow.

---

## 🔒 Security & Offline Guarantee

```
┌────────────────────────────────────────────────────────┐
│                   User's Device                        │
│                                                        │
│  ┌────────────────────┐      ┌──────────────────────┐  │
│  │   Drift Database   │      │ Document & Receipts  │  │
│  │ (SQLite encrypted  │      │ Vault Storage        │  │
│  │      metadata)     │      │ (AES-256-GCM files)  │  │
│  └─────────┬──────────┘      └──────────┬───────────┘  │
│            │                            │              │
│            └──────────────┬─────────────┘              │
│                           ▼                            │
│           ┌───────────────────────────────┐            │
│           │      Zip Archive Bundler      │            │
│           └───────────────┬───────────────┘            │
│                           ▼                            │
│           ┌───────────────────────────────┐            │
│           │ PBKDF2-HMAC-SHA256 Key Deriv  │            │
│           │ + AES-256-GCM Payload Cipher  │            │
│           └───────────────┬───────────────┘            │
│                           ▼                            │
│              Encrypted .fslbackup File                 │
└───────────────────────────┼────────────────────────────┘
                            │ (User manual export only)
                            ▼
           System Share Sheet (Drive / Email / Files)
```

- Keys are generated cryptographically (`Random.secure()`) and saved in device-secure hardware keystore / keychain via `flutter_secure_storage`.
- Backup archives include PBKDF2 key derivation with 20,000 rounds and a 16-byte random salt, making brute-force attacks infeasible.

---

## 🛠 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (version $\ge 3.24.0$)
- Android Studio / Xcode configured for Android and iOS builds

### Installation & Run

1. **Clone the repository and install dependencies:**
   ```bash
   flutter pub get
   ```

2. **Generate code (Drift & Localization):**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   flutter gen-l10n
   ```

3. **Run the application:**
   ```bash
   # Android
   flutter run -d android

   # iOS
   flutter run -d ios

   # Windows / macOS / Linux
   flutter run -d windows
   ```

---

## 🧪 Testing & Verification

The codebase includes comprehensive unit and widget tests covering calculation logic, unit conversions, reminders, encryption, PDF generation, CSV import/export, and UI screens:

```bash
# Run code analysis
flutter analyze

# Run all test suites
flutter test
```

---

## 🗺 Phase 2 Roadmap (Cloud Sync Ready)

The data layer is deliberately structured for effortless Phase 2 cloud sync integration:
- Every table includes UUID primary keys, `createdAt`, `updatedAt`, and `deletedAt` for two-way delta sync.
- **Planned Enhancements**:
  - Optional **Sign in with Google** and **Sign in with Apple** via Firebase Auth.
  - Multi-device cloud sync via Cloud Firestore with offline cache enabled.
  - End-to-end encrypted backup storage in Firebase Storage.
  - Multi-user vehicle sharing with family or fleet drivers.
  - Tyre and battery lifecycle degradation tracking.
