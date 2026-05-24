# 📦 Smart Ledger

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![SQLite](https://img.shields.io/badge/sqlite-%2307405e.svg?style=for-the-badge&logo=sqlite&logoColor=white)

**Smart Ledger** is a robust, offline-first Flutter application designed for wholesale and retail businesses. It streamlines inventory management, customer credit tracking, and supplier returns (RMA), all from a single, blazing-fast mobile interface.

## ✨ Key Features

- **🧠 Smart Text Parsing Engine**: Paste unstructured lists of inventory directly from WhatsApp messages. The custom parsing engine automatically extracts brands, models, quality grades, and prices to update your entire inventory database instantly!
- **📖 Advanced Customer Ledger (Khata)**: Track credit sales with a bulletproof ledger. Features include auto-refunds on Undone sales, precision floating-point protection, and safe customer archiving (blocks deletion if active debts exist).
- **💬 One-Click WhatsApp Billing**: Generate professional account statements and share them directly with customers via WhatsApp with a single tap.
- **🔄 Smart Defective Returns (RMA)**: Comprehensive returns queue with Support for **Partial Returns**. Supplier resolutions dynamically restore physical inventory counts flawlessly.
- **📊 Sales Analytics**: Built-in analytics dashboard visualizing top-selling items, stock velocity, and revenue generation.
- **⚡ Bulk Updaters**: Powerful tools to update prices or stock counts across massive inventories simultaneously without tedious manual data entry.
- **🔒 100% Offline & Private**: Built entirely on a local SQLite architecture. Your business data never touches the cloud and never leaves your device.

## 📱 Screenshots
*(Add screenshots of your Dashboard, Customer Ledger, and WhatsApp sharing here!)*

---

## 📥 How to Download & Install

There are two ways to get Smart Ledger on your Android device:

### Option 1: Direct Download (Easiest)
1. Go to the **[Releases](../../releases)** page on the right side of this repository.
2. Download the latest `app-release.apk` file.
3. Open the downloaded file on your Android phone to install it. *(Note: You may need to enable "Install from Unknown Sources" in your Android security settings).*

### Option 2: Build from Source
If you are a developer and want to compile the app yourself or make modifications:

1. **Clone the repository:**
   ```bash
   git clone https://github.com/YourUsername/smart-ledger.git
   cd smart-ledger
   ```
2. **Fetch dependencies:**
   ```bash
   flutter pub get
   ```
3. **Build the APK:**
   ```bash
   flutter build apk --release
   ```
4. Transfer the compiled APK from `build/app/outputs/flutter-apk/app-release.apk` to your phone.

## 🛠️ Tech Stack
- **Framework:** Flutter
- **Language:** Dart
- **Database:** `sqflite` (Native SQLite integration)
- **State Management:** `provider`
- **Integrations:** `url_launcher` (WhatsApp API integration)

## 🏗️ Application Architecture
The app follows a clean, provider-based architecture:
- **`lib/models/`**: Data classes (`InventoryItem`, `Customer`, `LedgerTransaction`, `Defect`).
- **`lib/providers/`**: Centralized state management (`InventoryProvider`) handling business logic and SQLite transactions.
- **`lib/database/`**: Singleton `DatabaseHelper` managing local SQLite storage and raw SQL migrations.
- **`lib/utils/`**: Core utilities including the powerful `PriceParser` Regex engine used for extracting phone models and pricing from raw WhatsApp text.

## 🗄️ Database Schema
The local SQLite database utilizes 4 core tables:
1. `inventory`: Tracks brand, model, quality grade, wholesale/retail prices, and current stock.
2. `customers`: Stores customer profiles and their total outstanding ledger due.
3. `ledger`: Logs all credit sales and cash payments, linked by `customer_id`.
4. `defects`: An RMA queue logging broken parts and return status.

## 🚀 Future Roadmap
- [ ] Implement PDF Invoice generation.
- [ ] Add CSV/Excel export functionality for inventory and ledgers.
- [ ] Integrate barcode/QR scanner for rapid stock checkouts.
- [ ] Add cloud backup functionality via Google Drive API.

## 🤝 Contributing
Contributions, issues, and feature requests are welcome! Feel free to check the issues page if you want to contribute.

## 📝 License
This project is open-source and available under the MIT License.
