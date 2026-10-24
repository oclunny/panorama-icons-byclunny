# Vesktop Icon Changer

Change **Vesktop's tray icon and menu (launcher) icon** on Linux with one script. The icons are already included in this repo, so you just run it and you're done.

Made for the Flatpak version of Vesktop (`dev.vencord.Vesktop`).

## Features

- Applies a ready-made tray icon and menu icon, no image to find or pick
- Apply both, or only the tray icon, or only the menu icon
- Backs up Vesktop's original tray archive before changing anything, and can restore it
- Re-apply option to bring the tray icon back after a Vesktop update
- Checks for required tools on first run and offers to install anything missing
- The menu icon lives in your home folder, so updates don't undo it

## Requirements

- Linux
- [Vesktop](https://flathub.org/apps/dev.vencord.Vesktop) installed as a Flatpak
- `nodejs` and `npm` (the script offers to install them for you)
- Optional: ImageMagick, only used if you swap in your own differently sized images

## Usage

Clone the repo and run the script:

```
git clone https://github.com/oclunny/panorama-icons-byclunny.git
cd panorama-icons-byclunny
chmod +x change-vesktop-icons-byclunny.sh
./change-vesktop-icons-byclunny.sh
```

Choose an option:

| Option | What it does |
| ------ | ------------ |
| `[1]` | Apply the tray icon and the menu icon (recommended) |
| `[2]` | Apply the tray icon only |
| `[3]` | Apply the menu icon only |
| `[4]` | Re-apply the saved tray icon after a Vesktop update |
| `[5]` | Restore Vesktop's original icons |

Afterwards, fully quit Vesktop (tray > Quit) and start it again.

## Using your own icons

Replace these two files in the repo folder before running the script:

- `panorama-tray.png`: tray icon (`64x64`, transparent background)
- `panorama-tray-unread.png`: tray icon shown when you have unread messages (`64x64`)
- `panorama-launcher.png`: menu icon (`256x256` recommended)

## How It Works

**Menu icon:** the script copies Vesktop's launcher file (`dev.vencord.Vesktop.desktop`) into `~/.local/share/applications/` and points its `Icon=` line at the bundled icon. Your copy overrides the system one, so Flatpak updates never touch it.

**Tray icon:** Vesktop's tray images are packed inside its `app.asar`, so the script:

1. Backs up the original `app.asar`
2. Unpacks it, swaps in the bundled tray icon, and repacks it
3. Installs the new archive over the old one (this is why it asks for `sudo`)

## After a Vesktop Update

Updating Vesktop replaces `app.asar`, which resets the **tray icon** to the default. Run the script again and choose `[4]` (or `[1]`) to put it back. The menu icon is not affected by updates.

## Notes

- Both the normal and the unread-message tray icons are replaced, so the tray never falls back to Vesktop's default.
- Restoring uses the backup made for your current Vesktop version. If Vesktop updated since then, the script suggests `flatpak repair` instead.
- The applied tray icon is also saved in `~/.local/share/vesktop-icon-changer/`, so option `[4]` works even if you delete the cloned repo.

## Credits

- Menu icon from the [Gruvbox Plus icon pack](https://github.com/SylEleuth/gruvbox-plus-icon-pack)
- Tray icons from [WebCord](https://github.com/SpacingBat3/WebCord)

---

Created with ❤️ by clunny
