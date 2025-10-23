# 🪑 rex-interactions

**Enhanced interaction system for RedM** - Converted to ox_target with improved menu structure, smart icons, and better user experience.

## ✨ Features

- 🎯 **ox_target Integration** - Modern targeting system instead of native prompts
- 🎨 **Smart Icons** - Contextual icons for every interaction type (beds 🛏️, pianos 🎵, chairs 🪑, etc.)
- 📍 **Position Labels** - Clear indicators for multi-position objects (Left, Right, Middle, Upper)
- ⚡ **Instant Cancel** - Press [J] anytime to stop current interaction
- 🎭 **100+ Interactions** - Chairs, beds, pianos, baths, and more
- ⚙️ **Highly Configurable** - Extensive config options for customization

## 📦 Installation

### Requirements
- [ox_lib](https://github.com/Rexshack-RedM/ox_lib)
- [ox_target](https://github.com/Rexshack-RedM/ox_target)

### Steps

1. **Download the resource**
   - Clone or download this repository

2. **Install dependencies**
   ```lua
   ensure ox_lib
   ensure ox_target
   ```

3. **Add to resources folder**
   - Place `rex-interactions` in your server's resources folder

4. **Configure the resource**
   - Edit `shared/config.lua` for your preferences
   - Edit `shared/translation.lua` for language support
   - **Important**: Update `IsRanchStaff()` in `client/cl_client.lua` to match your framework

5. **Start the resource**
   ```lua
   ensure rex-interactions
   ```

6. **Restart server**

## 🎮 Usage

### Starting Interactions
1. Walk near any interactable object (chair, bed, piano, etc.)
2. Look at the object - ox_target eye icon appears
3. Press your targeting key (default: **Left Alt**)
4. Select the interaction from the menu with icons

### Stopping Interactions
- Press **[J]** at any time to stop the current interaction
- No need to target the object again
- Works instantly from anywhere

## ⚙️ Configuration

### Key Settings in `shared/config.lua`

```lua
-- General
Config.Key = 0xF3830D8E -- [J] key for stopping interactions
Config.DevMode = false -- Enable debug messages
Config.Locale = 'en' -- Language (en, de)

-- Notifications
Config.EnableNotifications = true
Config.InteractionCooldown = 1000 -- Milliseconds between interactions

-- ox_target Menu
Config.ShowAllInteractions = true -- Show all available interactions
Config.GroupSimilarInteractions = true -- Group by category
Config.ShowPositionInLabel = true -- Show (Left)/(Right) in labels
```

## 🎯 Supported Interactions

### Objects
- **Seating**: 150+ chair and bench models
- **Sleeping**: Beds, bedrolls, bunk beds
- **Music**: Pianos, organs (5 piano models)
- **Bathing**: Bathtubs and 8+ town bath locations
- **Dancing**: Pole props with dance animations
- **Custom**: Church benches, shoe stands, and more

### Activities
- 🪑 Sitting (multiple positions per object)
- 🛏️ Sleeping (various sleep styles)
- 🎹 Piano playing (5 styles)
- 🎸 Guitar/Banjo/Mandolin
- 🍷 Drinking
- 🚬 Smoking
- 📖 Reading
- 🧶 Knitting
- 🔪 Knife sharpening
- 🎣 Fishing pose
- 🛁 Bathing (with cleaning effect)
- 💃 Dancing

## 🔧 Troubleshooting

### No targeting options appear
- Ensure `ox_target` starts before `rex-interactions`
- Check object model matches config
- Verify you're within interaction radius

### Interactions don't work
- Check F8 console for errors
- Verify `ox_lib` is installed
- Check Config.Interactions has valid data

## 🎖️ Credits

### Original Script
- **[kibook](https://github.com/kibook)** - Original [redm-interactions](https://github.com/kibook/redm-interactions) creator

### Spooni Development
- **[Spooni Development](https://github.com/Spooni-Development)** - [spooni_interactions](https://github.com/Spooni-Development/spooni_interactions) overhaul

### Current Version
- **ox_target conversion** with enhanced menu system, smart icons, and improved UX
- Comprehensive documentation and configuration options

## 📝 Version History

### v2.1.0 (ox_target)
- ✅ Converted to ox_target from native prompts
- ✅ Added smart icon detection (15+ icon types)
- ✅ Added position-aware labels
- ✅ Added instant stop via [J] key
- ✅ Enhanced configuration options
- ✅ Comprehensive documentation

### v2.0.0 (Spooni)
- Updated from original 3-year-old script
- Modernized codebase

### v1.0.0 (Original)
- Initial release by kibook

## 📄 License

Please respect the licenses of the original creators and contributors.
