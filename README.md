# 🪑 Rex Interactions

A feature-rich RedM interaction script that allows players to interact with various objects in the world. Enhanced with ox_lib for a modern, organized menu system and improved user experience.

## ✨ Features

### 🎯 Interaction System
- **100+ Interactive Objects** - Chairs, benches, beds, pianos, baths, and more
- **Smart Detection** - Automatic detection of nearby interactive objects
- **Position Variants** - Multiple sitting/sleeping positions for benches and beds (left, right, middle, up)
- **Gender-Specific Animations** - Different scenarios for male and female characters
- **Custom Objects Support** - Church benches, organs, shoe stands, and custom props

### 🎨 Enhanced Menu System (ox_lib)
- **📂 Organized Categories** - Interactions grouped into logical categories:
  - 🪑 Seating (Chairs & Benches)
  - 🛏️ Resting (Beds & Sleep)
  - 🎵 Music (Pianos & Instruments)
  - 🛁 Bathing (Bath Interactions)
  - 💃 Dancing (Performance Animations)
  - ⭕ Other
- **🎯 Icons & Visual Feedback** - Each interaction has a relevant icon
- **📏 Distance Display** - Shows how far each object is from you
- **🎨 Customizable Colors** - Configure icon colors to match your server theme
- **🔔 Notifications** - Visual feedback when starting/stopping interactions

### 🛠️ Configuration Options
- **Keybind Customization** - Default: Q key
- **Toggle Notifications** - Enable/disable interaction feedback
- **Custom Icon Colors** - Personalize menu appearance
- **Banned Areas** - Prevent interactions in specific zones
- **Effect System** - Add special effects (e.g., cleaning in baths)
- **Multi-language Support** - English and German included

### 🎭 Interaction Types

#### Seating (25+ Scenarios)
- Basic sitting positions
- Drinking animations
- Smoking (cigar, cigarette, rolling)
- Musical instruments (banjo, guitar, harmonica, mandolin, concertina, jaw harp)
- Activities (reading, knitting, whittling, fishing rod)
- Grooming animations
- And many more!

#### Resting (7 Scenarios)
- Multiple sleeping positions
- Side and back sleeping
- Ground sleeping variants
- Bedroll positions

#### Music (5 Scenarios)
- Various piano playing styles
- Normal, upperclass, riverboat, sketchy
- Gender-specific animations

#### Bathing (5 Animations)
- Relaxing bath idle
- Scrubbing animations (arms and legs)
- Automatic dirt/blood cleaning effect

#### Dancing (4 Animations)
- Sword dance
- Cancan dance
- Fire dance
- Snake dance

## 📦 Installation

### Requirements
- [ox_lib](https://github.com/overextended/ox_lib) - Required for menu system

### Steps

1. **Download the resource**
   - Clone or download this repository

2. **Install dependencies**
   - Ensure [ox_lib](https://github.com/Rexshack-RedM/ox_lib) is installed and started before this resource

3. **Add to resources folder**
   - Rename the folder to `rex-interactions`
   - Place in your server's resources directory

4. **Update server.cfg**
   ```cfg
   ensure ox_lib
   ensure rex-interactions
   ```

5. **Configure the script** *(Optional)*
   - Edit `shared/config.lua` for general settings
   - Edit `shared/translation.lua` for language customization

6. **Restart your server**

## 🎮 Usage

1. **Approach any interactive object** (chair, bed, piano, etc.)
2. **Press Q** to open the interactions menu
3. **Select your desired interaction** from the categorized menu
4. **Press Q again** or select another interaction to stop

### Controls
- **Q** - Open interactions menu / Stop current interaction

## ⚙️ Configuration

### Key Settings (`shared/config.lua`)

```lua
Config.Key = 0xDE794E3E -- [Q] - Change interaction keybind
Config.Locale = 'en' -- 'en' or 'de' - Language
Config.UseNotifications = true -- Show start/stop notifications
Config.MenuIconColor = '#E8C547' -- Menu icon color (hex)
Config.DevMode = false -- Enable debug messages
```

### Banned Areas
Prevent interactions in specific zones:

```lua
Config.BannedAreas = {
    {x = -306.482, y = 809.1139, z = 118.98, r = 5}, -- r = radius
}
```

### Custom Effects
Add special effects to interactions:

```lua
Config.Effects = {
    ['clean'] = function()
        local ped = PlayerPedId()
        ClearPedEnvDirt(ped)
        ClearPedDamageDecalByZone(ped, 10, 'ALL')
        ClearPedBloodDamage(ped)
    end
}
```

## 🌍 Supported Languages
- 🇬🇧 English
- 🇩🇪 German

Add your own language in `shared/translation.lua`!

## 🔧 Troubleshooting

**Menu not showing?**
- Ensure ox_lib is installed and started before rex-interactions
- Check server console for errors

**Interactions not working?**
- Verify you're close enough to the object (within radius)
- Check if the area is in the banned zones list
- Make sure your character is not in combat or dead

**Performance issues?**
- Reduce the number of custom objects in config
- Disable DevMode in production

## 📝 Credits

- **Original Script**: [kibook](https://github.com/kibook) - [redm-interactions](https://github.com/kibook/redm-interactions)
- **Improved Script**: [Spooni Development](https://github.com/Spooni-Development) - [spooni_interactions](https://github.com/Spooni-Development/spooni_interactions)
- **Enhanced RSG Version**: Rex Development
- **Original Menu System**: [ox_lib](https://github.com/overextended/ox_lib) by Overextended

## 📄 License

This project is a derivative work based on the original redm-interactions script. Please respect the original author's work and any applicable licenses.

---

**Enjoy enhanced interactions in your RSG RedM server! 🎮**
