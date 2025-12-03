## 🚀 SalesTools (Retail 11.2.7 Compatible)

**Author / Maintainer:** Updated for patch 11.2.7 by **Osiris the Kiwi 🥝** (Discord: `osirisnz`)
**Original Authors & Contributors:** Adalyia-Illidan, Volthemar-Dalaran, Honorax-Illidan

SalesTools is a World of Warcraft addon designed to streamline gold trading, sales tracking, and communication for collectors, traders, and boosters.
This repository is a **continuation and maintenance fork** of the original [SalesTools by Adalyia](https://github.com/Adalyia/SalesTools), updated for Retail patch 11.2 with fixes, quality-of-life improvements, and UI enhancements.

-----

## ✨ Features & Updates (v1.2.7)

### 📈 Balance List Updates (The Balance Module)

The Balance List module received a complete overhaul for gold tracking and usability.

  * **Warband Gold Tracking:**
      * Full **Warband Bank Gold** tracking is now implemented, correctly including it in the **Battle.net Account Balance** total.
      * The system now gracefully handles and displays **"No Warband Access"** if the game API does not return a value, correctly excluding it from the total.
  * **Enhanced Data & Sorting:**
      * A new **"Last Updated"** column was added, displaying the time as **relative time** (e.g., "5 min ago") instead of a raw timestamp.
      * The default sort order for the list is now set to **"Last Updated" (Newest First)**.
      * Critical fixes were implemented to prevent sorting errors (`attempt to compare number with nil`) caused by missing timestamps in old character data.
      * A fix was implemented to correctly retrieve and display a character's **Guild Name** even if the user is a standard member (fixing the permanent `&lt;No Guild&gt;` error).
  * **GUI and Formatting:**
      * Gold amounts (including the total balance) are now correctly displayed with **comma separators** (e.g., `6,471,312g`).
      * The dedicated "Warband Gold" column was **removed** from the main table as it was redundant per character.
      * Warband Gold and Total Account Balance are now displayed in a two-line, right-aligned block above the table.

### 💰 Gold/Copy Helper (The Info Plate)

The `/sales help` info plate received new functionality and a layout adjustment.

  * **Warband Gold Copy Button:** A new **"Warband"** button was added to the info plate to allow one-click copying of the total **Warband Bank Gold**.
      * The button's state is dynamically updated, being **disabled/greyed out** if the Warband Gold amount is zero.
  * **Information Display:**
      * The Realm name and Faction name are now displayed in **two separate lines**.
      * The Faction name uses the **official Faction colors** (Alliance Blue / Horde Red/Orange) and a smaller font for clarity.
      * The label for gold amounts on the buttons was simplified from the localized word **"Gold"** to the abbreviation **`"g"`** (e.g., `100,000g`).
  * **Copy Reliability:**
      * The core copy function was made more robust, attempting an automatic `SetClipboard()` copy first, then falling back to an aggressive text-highlighting method that requires the user to manually press **Ctrl+C**.
      * The button text in the copy dialog popup was changed from **"Okay"** to the localized **"Close"** for better user flow.

### 💻 Command/UI Panel Updates

Key changes to the look, feel, and functionality of all main addon windows.

  * **Default Window Dimensions:** The default and maximum dimensions for the **Balance List, Mail Log, and Trade Log** viewer windows have been standardized to **1400w x 720h**.
      * The **Trade Log** now defaults to a maximized, centered state on launch, and the redundant **Maximize Button was removed**.
      * The **Mail Log** maximum size was increased to **1400w x 800h**.
  * **Version Info Panel:**
      * The redundant large version number display (e.g., "1.2.7") was **removed** from the top of the panel.
      * The remaining author/contributor text was adjusted to be correctly positioned at the top of the panel.
  * **Collector Menu Buttons:** Button labels were corrected/renamed:
      * **"Mass Whisper"** is now **"Version Info"**.
      * **"Mass Invite"** is now **"Info Panel"** (which opens the `/sales help` view).
      * **"Request Inv"** is now **"Close Menu"**.
  * **Title/Header Clean-up:** The **Name Grabber window** now opens with an **empty title bar**, removing the display of the character name and realm from the header.

### 🛠 Core & Maintenance

Significant structural changes were made for stability, localization, and future-proofing.

  * **Dynamic Versioning (v1.2.7):**
      * All hardcoded references to the version number ("11.2.5") were **removed**.
      * The addon now dynamically retrieves the current **Version (`1.2.7`)** and **Interface (`110207`)** numbers directly from the `SalesTools.toc` file.
      * The startup banner now displays correctly **once** per login (duplicate printing was fixed).
  * **Localization (L10N) Overhaul:**
      * Added support for **Russian (`ruRU`)**, **Korean (`koKR`)**, **Traditional Chinese (`zhTW`)**, and **Simplified Chinese (`zhCN`)**.
      * The addon description, Gold Info title, and all dynamic copy pop-up titles are now **fully localized**.
      * **Critical fix:** Localization race conditions and "Missing entry" errors were resolved with new fallback logic and corrected key names across all modules.
  * **Crash & Error Fixes:**
      * Critical Lua syntax errors (missing `end` keywords) were fixed in `SalesTools.lua` to prevent addon crashes on loading.
      * Robust nil-checks were added when retrieving metadata and data (like Warband Gold) to prevent "bad argument" and "compare number with nil" errors.

-----

## 📦 Installation

1.  **Download** the latest release from [suspicious link removed].
2.  **Extract** the archive so that the folder structure is:
    ```
    World of Warcraft/_retail_/Interface/AddOns/SalesTools/
    ```
3.  **Restart** WoW or run `/reload` in-game.

-----

## 💻 Commands

| Command | Description |
| :--- | :--- |
| `/sales collect` | Toggle the Collector Menu |
| `/sales version` | Show version information panel |
| `/sales help` | Display the Info Plate |

-----

## 📜 Changelog

See [CHANGELOG.md](https://www.google.com/search?q=./CHANGELOG.md) for the complete update history.

-----

## 🛠 Development Notes

  * This is a **maintenance fork** of the original addon, updated for Retail 11.2.7.
  * All modifications are noted in file headers where applicable.
  * The addon remains licensed under **GNU General Public License v3.0**.

-----

## 📄 License

This project is licensed under the [GNU GPL v3.0](https://www.google.com/search?q=./LICENSE).
You are free to use, modify, and distribute it, provided that:

  * The same GPL-3.0 license applies to your changes.
  * Original author credits are preserved.
  * Modifications are clearly documented.

-----

## 🙏 Credits

  * **Original Authors:** Adalyia-Illidan, Volthemar-Dalaran, Honorax-Illidan
  * **Retail 11.2.7 Maintenance:** Osiris the Kiwi 🥝
  * Thanks to the WoW addon community for continued feedback and testing.
