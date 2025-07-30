# RV-Emergency

AI Traffic Response for Emergency Vehicles (FiveM/QBCore)

## Features
- AI vehicles automatically pull over for emergency vehicles with sirens.
- Configurable detection radius, pull-over behavior, and debug options.
- Visual debug markers and notifications for testing.
- Simple NUI (UI) for toggling debug mode and viewing AI vehicle status.

## Usage
- Place this resource in your `[scripts]` folder and ensure it in your `server.cfg`.
- Use `/rvem_ui` in-game to open the debug UI.
- Use `/rvem_debug` to toggle debug mode via command.
- (Optional) Use `/testpullover` (when debug is enabled) to test siren behavior.

## Configuration
Edit `config.lua` to adjust:
- Detection radius
- Pull-over distance and aggressiveness
- Debug mode and honking

## UI
- The UI allows toggling debug mode and viewing a list of AI vehicles currently pulled over.
- Press `ESC` to close the UI.

## Credits
- Script by Raven
- Refactored and improved for clarity, maintainability, and user experience.

## Requirements
- QBCore Framework
- FiveM server

## Support
For issues or suggestions, contact Raven or open an issue on the repository.
