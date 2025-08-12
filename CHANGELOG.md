# AutoHotPie Fork - Changelog

## Version 0.1 (Fork)

This fork introduces several new features and improvements over the main branch, while maintaining compatibility with existing functionality.

### ✨ New Features

#### 1. Send Key with Held Modifiers Function
- **New function**: `pie_sendKeyWithHeldModifiers()` in `PieFunctions.ahk`
- **Purpose**: Allows sending keystrokes while holding down modifier keys (Ctrl, Shift, Alt, Win)
- **Parameters**:
  - `heldModifiers`: String containing modifier keys to hold (e.g., "^+" for Ctrl+Shift)
  - `keys`: Array of individual keys to send while modifiers are held
  - `keyDelay`: Delay between individual key presses (default: 30ms)
- `modifierHoldDelay`: Delay after pressing modifiers before sending keys and after last keystroke before releasing modifiers (default: 40ms)
- **Usage**: Available in the slice function selection as "Send Key with Held Modifiers"

#### 2. Enhanced UI for Held Modifiers
- **New UI elements**: Added to `editPieMenu.js` for configuring the new function
- **Features**:
  - Modifier key checkboxes (Ctrl, Shift, Alt, Win)
  - Keystroke input with add/remove functionality
  - Configurable delays for key timing
  - Visual feedback for active modifiers

### 🔧 Technical Improvements

#### 1. Robust Error Handling
- **Enhanced error handling** in `pie_sendKeyWithHeldModifiers()` with try-catch blocks
- **Parameter validation** with sensible defaults for missing values
- **Debug logging** using `OutputDebug` for troubleshooting

#### 2. Improved DOM Element Handling
- **Fixed jQuery/DOM compatibility issues** in `editPieMenu.js`
- **Unified event handling** using native DOM methods where appropriate
- **Robust element selection** that works with both jQuery objects and native DOM elements

#### 3. Enhanced Slice Duplication
- **Improved icon visibility** for the slice duplication button
- **Dynamic sizing** based on button dimensions
- **Better positioning** for overlapping rectangle elements

### 🐛 Bug Fixes

#### 1. TypeError Fixes
- **Fixed**: `TypeError: this.sliceFunction.sendKeyWithHeldModifiers.heldModifiersDiv.addEventListener is not a function`
- **Fixed**: `TypeError: sliderDivElement.children is not a function`
- **Fixed**: `TypeError: sliderDivElement.getElementsByClassName is not a function`

#### 2. Functionality Issues
- **Fixed**: "Send Key with Held Modifiers" keystrokes not displaying in UI
- **Fixed**: Add keystroke button not working for held modifiers function
- **Fixed**: Deletion of added keystrokes not working correctly
- **Fixed**: Subsequent keystroke inputs not appearing

#### 3. Settings UI Reopening
- **Fixed**: Issue reopening settings UI after "Save and Run" in installed version
- **Solution**: Simplified path resolution using proven method from main branch
- **Result**: Reliable settings reopening in both development and installed environments

### 📁 File Changes

#### Modified Files
- `src/editPieMenu.js` - Enhanced UI for held modifiers function
- `src/lib/PieFunctions.ahk` - Added new function and fixed settings reopening
- `src/lib/PieMenu.ahk` - Updated executable name references

#### New Functions
- `addHeldModifiersKeystrokeButtonGroup()` - UI management for held modifiers
- `pie_sendKeyWithHeldModifiers()` - Core functionality for held modifier keystrokes

### 🔄 Compatibility

#### Maintained Features
- **"Send Key" function**: All existing functionality preserved
- **Slice management**: No changes to core slice operations
- **Profile management**: Existing profiles remain compatible
- **Hotkey system**: All existing hotkeys continue to work

#### Backward Compatibility
- **Settings files**: Existing configurations remain valid
- **Profiles**: No migration required for existing profiles
- **Scripts**: All existing AutoHotkey scripts continue to function

### 🚀 Installation & Usage

#### Development Environment
- Run with `npm start` as usual
- New function appears in slice function selection
- All features available immediately

#### Installed Version
- Install normally using existing installer
- New function available in all pie menus
- Settings reopening works reliably

### 📝 Technical Notes

#### AutoHotkey Integration
- **New function**: `pie_sendKeyWithHeldModifiers()` integrates seamlessly with existing pie menu system
- **Debug output**: Uses `OutputDebug` for troubleshooting (viewable with DebugView)
- **Error handling**: Graceful fallbacks for malformed parameters

#### JavaScript Enhancements
- **Event handling**: Improved compatibility between jQuery and native DOM
- **UI responsiveness**: Better handling of dynamic content updates
- **Error prevention**: Robust element selection and validation

### 🔮 Future Considerations

#### Potential Enhancements
- **Additional modifier combinations**: Support for more complex modifier sequences
- **Custom timing profiles**: User-defined delay patterns
- **Visual feedback**: Enhanced UI indicators for active modifiers

#### Maintenance
- **Regular testing**: Ensure compatibility with future AutoHotkey updates
- **Performance monitoring**: Watch for any impact on pie menu responsiveness
- **User feedback**: Collect usage patterns for future improvements

---

**Note**: This fork maintains full compatibility with the main branch while adding significant new functionality. All existing features work exactly as before, with the addition of the new "Send Key with Held Modifiers" capability.
