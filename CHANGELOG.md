# Changelog

## [1.2.7] - 2025-12-04
**Interface Update:** World of Warcraft Retail 11.2.7

### New Features & Major Changes

#### Warband Gold Tracking Overhaul
* **Added Warband Bank Gold** tracking and inclusion in the total **Battle.net Account Balance** calculation.
* The **Balance List** now defaults to sorting by **"Last Updated" (Newest First)**.
* Added a **Warband Gold Copy Button** to the `/sales help` info plate.
    * The button is dynamically disabled/greyed out if the Warband Gold amount is zero.

#### Balance List (Data & UI)
* Introduced a new **"Last Updated"** column, displaying time in **relative format** (e.g., "5 min ago") instead of raw date strings.
* Gold amounts across the UI (Balance List, Collector Menu) are now correctly displayed with **comma separators** (e.g., `1,234,567g`).
* Fixed a bug preventing the correct retrieval and display of a character's **Guild Name** for standard guild members.

#### User Interface & Consistency
* Standardized default and maximum dimensions for **Balance List, Mail Log, and Trade Log** viewer windows to **1400w x 720h**.
* The `/sales help` Info Plate now separates the **Realm Name** and **Faction Name** onto two lines, with the Faction using the official Alliance/Horde color.
* Simplified all gold display labels from the localized word **"Gold"** to the abbreviation **`"g"`** (e.g., `100,000g`).

#### Core & Localization (L10N)
* **Massive Localization Update:** Added support for **Russian (`ruRU`)**, **Korean (`koKR`)**, **Traditional Chinese (`zhTW`)**, and **Simplified Chinese (`zhCN`)**.
    * Fixed duplicate startup banner printing; it now displays only once.
* **Menu Button Renames:**
    * `"Mass Whisper"` is now `"Version Info"`.
    * `"Mass Invite"` is now `"Info Panel"` (opens `/sales help`).
    * `"Request Inv"` is now `"Close Menu"`.
* **Stability:** Implemented robust nil-checks and safety fallbacks (especially for missing data and localization keys) to prevent various Lua crashes and errors (`attempt to compare number with nil`, "Missing entry").

## [1.2.0] — 2025‑08‑10
**Maintainer:** Osiris the Kiwi (Discord: osirisnz)  
**Previous contributors:** Adalyia‑Illidan, Volthemar‑Dalaran, Honorax‑Illidan

### Added
- **Version Information** toggle button in Collector Menu (replaces “Mass Whisper”) to open/close `/sales version`.
- A reliable startup message:
  ```
  [SalesTools] Version 1.2.0 updated for patch 11.2 by Osiris the Kiwi
  ```
- Collector Menu reload tip when pressing “Close Collector Menu”:
  ```
  [SalesTools] to open Collector Menu type /sales collect
  ```
- `/sales version` panel formatting updated with maintainer & contributor credits.
- Updated button labels and repositioned functionality:
  - “Mass Invite” → **Toggle Info Plate** (`/sales help`)
  - “Request Inv” → **Close Collector Menu** (`/sales collect`)
- Full swapping of:
  - **Close Collector Menu** ↔ **Trade Log**
  - **Close Collector Menu** ↔ **Toggle Info Plate**
  - **Toggle Info Plate** ↔ **Trade Log**
  (Includes names, functions, and anchor preservation.)

### Changed
- Whisper behavior now only shows:
  ```
  Received Xg from <player> in a trade.
  ```
  Removed duplicate “I received Xg Ys Zc” messages.
- UI improvements:
  - Standardized copy popup with `StaticPopupDialogs["SalesToolsPopup"]`.
  - Button layout preserved with correct anchors for two-column alignment.
  - Consistent button naming and callback handlers.
- Startup message now fires reliably on login and reload.

### Fixed
- Various bug fixes and API updates:
  - Resolved `editBox` nil issues in Retail 11.x.
  - Fixed popup registration errors.
  - Removed deprecated trade event registrations.
  - Syntax cleanup in `SalesTools.lua`.
  - Made module loading safer with silent `GetModule()`.
- Corrected layout drift after swapping buttons by anchoring correctly.
- Legacy trade whisper code removed in favor of the clean, single confirmation from TradeLog.

### Removed
- Pre-trade whisper: “trading you X gold”.
- Duplicate “I received Xg Ys Zc” messages.

### Maintenance
- Centralized copy helper functions.
- UI refinements to `/sales version` panel.
- Consistent naming convention for Collector Menu buttons.

---

## [1.0.6] — 2024‑07‑28
- Updated for *The War Within* (Dragonflight 11.0).
- Dependency updates.
- Quick fix for minimap menu.

## [1.0.5] — 2024‑05‑25
- TOC/version bump for Dragonflight 10.1.
- Updated dependencies.

## [1.0.4] — 2023‑12‑13
- Added `/st gnames` to list Name‑Realm in your party or raid.
- Patched Dragonflight-era bug in LibGuildBankComm.

## [1.0.3] — 2023‑11‑28
- TOC bump for 10.0.2.
- Updated dependencies.

## [1.0.2] — 2023‑10‑28
- Dragonflight (WoW 10.0.0) compatibility.

## [1.0.1] — 2023‑06‑13
- Retail 9.2.5 version bump.

## [1.0.0] — 2023‑05‑06
**Initial release.** Continuation of Honorax’s GallywixAdTools with new modules:
- AutoInvite, BalanceList, CollectorMenu UI, HelperDisplay, MailGrabber, MailLog, MailSender, MassInvite, MassWhisper, TradeLog, Language support (enUS, ptBR, esMX, esES).
