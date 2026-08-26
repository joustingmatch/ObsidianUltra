## 25.08.2026

```diff
[features]
+ New element: player cards - an avatar thumbnail with a title and description lines (both rich text)
+ Tab:AddPlayerInfo(Idx, Info) is the full card: a full-width banner across the top of the tab, above both columns and under the warning box
+ Groupbox:AddPlayerInfo(Idx, Info) is the compact card: an avatar box with no header of its own, so the groupbox around it carries the title and the collapse
+ Defaults to the local player; Player, UserId, Thumbnail and ThumbnailType ("HeadShot" | "Bust" | "Avatar") override it
+ Methods: SetTitle, SetDescription, SetPlayer, SetUserId, SetThumbnail, SetHeight, SetCollapsed, SetVisible, Destroy


+ Player card descriptions accept dividers between lines: "---" or { Divider = true } draws a thin rule (full card; the compact card shows the avatar alone)

[changes]
+ TabSwipeFrom now only applies to normal tabs; sub tab content always swipes in from the bottom
```

## 09.08.2026

```diff
[fixes]
+ Notification History no longer duplicates its "No notifications yet." placeholder on refresh
+ Fixed the history panel rendering off-screen
+ Corner radius now reliably re-applies to keybind pills and other corners after the radius passes through 0 (each corner remembers its square/half/full ratio instead of getting stuck)

[features]
+ Built-in Notification History: every Library:Notify call is logged automatically, no manual hooking needed
+ History panel drops down from under the notification bell with a smooth slide + fade, and retracts back into it on close
+ X button in the panel's title bar
+ Notify Type ("Error" | "Warning" | "Success" | "Info") colors the primary text and shows a colored tag in history; customizable via Library.NotificationTypeColors
+ Click a notification in the history to copy its text: clipboard icon swaps to a check and a "Copied!" tag flashes in as feedback
+ Clicking outside the history panel now closes it
+ New "Enabled Features" top-bar button: opens a smooth, organized panel listing every element changed from its default (only altered values appear), each with an inline control to tweak it
+ Enabled Features supports toggles (switch), sliders (draggable), inputs (text box) and dropdowns (single-select cycles), plus a reset-to-default button per row
+ Copy feedback now uses a copy/paste icon that pops in with a bounce and swaps to a checkmark, with a rising "Copied!" tag
+ Added themes: Linoria, Hollywood Novo, Rose Pine, V3rmillion, Sakura Drift
+ The Notification and Enabled Features buttons (with the unread badge) now also appear in the minimized window card, and their panels drop from whichever button is on screen
+ Toggle the history panel with the RightAlt keybind (Library.NotificationHistoryKeybind) or Library:ToggleNotificationHistory()
+ Draggable panel lists each notification's timestamp, title and description, newest first
+ Notification bell icon in the top bar (left of the minimize/move icons) with an unread count badge; click it to open the history
+ Opening the history clears the unread badge
+ Library.NotificationHistory, Library.NotificationHistoryLimit (default 100), Library.NotificationUnreadCount, Library:GetNotificationHistory(), Library:ClearNotificationHistory(), Library:RefreshNotificationHistory(), Library:SetNotificationHistoryVisible(bool), Library:UpdateNotificationBadge()
```

## 05.08.2026

```diff
[features]
+ Built in "Select All" / "Deselect All" row on multi dropdowns, in the inline list and the expanded panel
+ It skips disabled values and, while a search is typed, only touches the matching ones
+ Dropdown:SelectAll(Search?), Dropdown:DeselectAll(Search?), DropdownInfo.SelectAllButtons
```

## 04.08.2026

```diff
[features]
+ Search v2 with fuzzy subsequence matching, Dropdown/Input/KeyPicker value search, and groupbox/tabbox/sub-tab name matching
+ Ctrl+F now focuses the searchbar; Escape clears it and releases focus
+ Library.FuzzySearch, Library.SearchValues, WindowInfo.FuzzySearch, WindowInfo.SearchValues, WindowInfo.SearchKeybind, WindowInfo.DisableSearchKeybind
+ Minimize the window to a card with title, subtitle, labels and footer; button sits beside the move icon
+ The card is built into the window and needs no setup: its subtitle tracks the open tab and its footer mirrors the window footer
+ Sub tabs are now one feature with two views shown at once: the button row above the groupboxes and a collapsible list nested under the tab in the sidebar
+ Both are painted from the same SubTab:Show/Hide, so switching in either drives the other
+ Tab:SetExpanded/ToggleExpanded/IsExpanded, Animations.SidebarSubTabs
+ Window:SetMinimized/ToggleMinimized/IsMinimized, SetMinimizedSubtitle, AddMinimizedLabel, ClearMinimizedLabels
+ WindowInfo.Minimizable, MinimizeKeybind, MinimizedWidth, MinimizedSubtitle

[fixes]
+ Search queries are now matched as literal text instead of Lua patterns
+ Dropdown value filtering also treated its query as a Lua pattern
```

## 11.07.2026

```diff
[changes]
+ Loading configs now triggers element callbacks even if their value hasn't changed
```

## 09.07.2026

```diff
[changes]
+ Background Image now supports external URLs using getcustomasset
```

## 07.07.2026

```diff
[features]
+ Dropdown.DragSelect, Dropdown:SetDragSelect(Value: boolean) (only works on non-touch devices and Multi dropdowns)
+ Animations.Groupbox, Animations.KeyPicker

[changes]
+ Notification appear and disappear animations are now smooth

[fixes]
+ Fixed Library.ToggleKeybind
```

## 05.07.2026

```diff
[features]
+ Added Animations.ToggleWindow
+ Added Animations.TabSwitch, TabTransitionTime, TabSwipeOffset, TabSwipeFrom (left/right/top/bottom)
+ Added Animations.Dropdown
+ Window:SetAnimations(Animations, TabTransitionTime, TabSwipeOffset, TabSwipeFrom)
+ Added DisableCollapsing to AddLeftGroupbox, AddRightGroupbox

[changes]
+ KeyPickers now allow setting the bind to any modifier key if it was only pressed and not held down

[fixes]
+ Fixed Library.ToggleKeybind not working properly with modifier keys
+ Fixed KeyPickers firing while picking a bind for any KeyPicker
```

## 02.07.2026

```diff
[changes]
+ Save Manager and Theme Manager refactored
+ Save Manager now saves the keybind menu visibility and position
+ Save Manager and Theme Manager now show what theme is the default and what config is autoloaded inside the dropdowns

[fixes]
+ Fixed dialogs buttons breaking with Destructive buttons if ThemeManager:SetDefaultTheme was used
```

## 01.07.2026

```diff
[features]
+ Confirmation dialogs to destructive actions in Save Manager and Theme Manager
+ Groupbox collapsed state now saves in configuration files
```


## 28.06.2026

```diff
[features]
+ Groupbox:SetVisible(Visible: boolean), Groupbox:Show(), Groupbox:Hide()
+ Groupbox:AddTabbox()
+ Collapse Groupbox arrow (disable with DisableCollapsing option)
+ TitleColor, DescriptionColor options for Library:Notify({ ... })
+ Library.Scheme.BackgroundImage and "Background Image" option in Theme Manager
+ Library.Window

[changes]
+ Tabbox:AddTab() now returns Tab and TabStoringIndex
+ Window BackgroundImage can now be set even when it was previously not set during creation

[fixes]
+ Fixed searching restoring hidden elements each time
+ Fixed attempt to index nil with 'Destroy' errors in Dropdown:BuildDropdownList()
+ Fixed rounded corners with Tab buttons inside Tabbox
+ Fixed Tab button spacing when it doesn't have name
```

## 26.06.2026

```diff
[features]
+ :Destroy() function for every element
+ Volume option for Library:Notify()
+ KeyPicker for buttons (Only works with 'Press' mode, Callback to the button will have an passed value FromKeyPicker which will be true if it was activated by the key picker)
+ Icon and IconPosition parameters to Library:AddDraggableLabel() and Library:AddDraggableButton()
+ Slider.AllowRightClickInput (right click/double tap to open text input for specific value)
+ Library:AddDraggableImageButton()

[changes]
+ Implemented individual rounded corners for certain elements (dropdowns, right-click context menus)
+ Right-click context menus will now connect to the buttons visually
+ Dropdown:GetActiveValues() => Dropdown:GetActiveValues(ReturnCountForMulti: boolean) [true => returns value count]
+ The dropdown menu will now close if the button is not visible on the screen.
+ Other KeyPickers will no longer trigger when you are selecting the keybind
+ Mouse button KeyPickers will no longer trigger when you have the UI opened
+ Draggable labels, buttons, menus and image buttons will now find an position where they won't overlap other dragging elements

[fixes]
+ Fixed AllowNull not properly working with Multi dropdowns
+ Fixed dropdown context menu not matching button size on the X axis

[optimizations]
+ Obsidian Library table will now get properly garbage collected after calling Library:Unload()
```

## 21.04.2026

```diff
[features]
+ SaveManager:SetLoadingOrder(enabled: boolean, order: { })
```

## 05.04.2026

```diff
[features]
+ Library.Scheme.DestructiveColor
+ Library:CreateLoading(LoadingInfo)
~ Read documentation at http://docs.mspaint.cc/obsidian/core/library/loading
```

## 03.04.2026

```diff
[features]
+ Tab:SetVisible()
```

## 28.03.2026

```diff
[features]
+ Dropdown.FormatListValue(Value)
  - Randomized formatting will not be preserved as the function is called every time the context menu is rebuilt
```

## 24.03.2026

```diff
[features]
+ Input.VerifyValue(NewValue: string): boolean
+ Input.ClearTextOnBlur
+ KeyPicker.Blacklisted, KeyPicker.BlacklistedModifiers
+ KeyPicker.Whitelisted, KeyPicker.WhitelistedModifiers

[changes]
+ CornerRadius now applies to more elements
+ Height of the slider increased by 1px
```

## 17.03.2026

```diff
[features]
+ Window:SetCornerRadius(Radius: number)

[fixes]
+ Fixed Window:SetFooter not changing the label text
+ Fixed footer background not properly resizing
+ Fixed Tab buttons not respecting corner radius
```

## 16.01.2026

```diff
[features]
+ Library:ResetCursorIcon()
+ Library:ChangeCursorIcon(ImageId: string)
+ Library:ChangeCursorIconSize(Size: UDim2)
```

## 30.12.2025

```diff
[breaking changes]
! Library.Scheme:
  .Red -> .RedColor
  .Dark -> .DarkColor
  .White -> .WhiteColor
! WindowInfo.Compact -> WindowInfo.SidebarCompacted
! WindowInfo.SidebarMinWidth -> WindowInfo.MinSidebarWidth
! WindowInfo.MinContentWidth -> WindowInfo.MinContainerWidth
- WindowInfo.SidebarCollapseThreshold
- WindowInfo.SidebarHighlightCallback function
- WindowInfo.InitialSidebarWidth
- WindowInfo.InitialSidebarScale

[fixes]
+ Fixed DPI Scaling

[features]
+ WindowInfo.DisableCompactingSnap
  -> WindowInfo.CompactWidthActivation

[changes]
+ WindowInfo.SidebarCompactWidth default value (54) to new value (48)
+ Library:SetWatermark is deprecated due to Library:AddDraggableLabel having the same functionality
```

## 18.12.2025

```diff
+ Patched static key bypass inside Key Box
    * The AddKeyBox function now only takes the callback function
    * The callback function only returns the provided key, you need to implement your own handler inside the callback
```

## 09.11.2025

```diff
+ Added Library.ImageManager (https://docs.mspaint.cc/obsidian/core/library/utility#custom-asset-icons)
```

## 02.11.2025

```diff
+ Warning Box now follows the UI style of Obsidian (rounded corners with outlines)
+ Watermark now correctly resizes itself with new line characters
```

## 01.11.2025

```diff
+ The ignored indexes (SaveManager.SetIgnoreIndexes) are no longer applied when you load a configuration that contains them
```

## 5.10.2025

```diff
+ Added support for modifier keys in KeyPicker (for example: LCtrl + E)
+ Fixed DoClick not calling the correct callbacks
```

## 17.09.2025

```diff
+ Added support for custom icons (rbxasset, rbxassetid, rbxthumb, getcustomasset) for Tabs and Groupboxes
```

## 14.09.2025

```diff
+ Added `Press` mode to `KeyPicker`
```

## 19.08.2025

```diff
+ Fixed `KeyPicker` in Toggle mode not working properly when Key is nil
```

### 12.08.2025

```diff
+ Fixed `Tab:UpdateWarningBox()` not resizing properly
```

### 10.08.2025

```diff
+ Added a LockSize option `Tab:UpdateWarningBox()` to set the maximum size of the warning box to 3.25 size of the Tab Container (optional)
+ Added support for mouse button 3 (middle click)
```

### 17.07.2025

```diff
+ Added Description parameter to `Window:AddTab()` method to set a description for the tab
+ Updated `Window:AddTab()` method to accept a table with Name, Icon, and Description or a table with Name, Icon (optional), and Description (optional)
+ Updated `Library:CreateWindow()`'s WindowInfo parameter to include a `DisableSearch` option to disable the search box in the window
```

### 15.07.2025

```diff
+ Added watermark support to the library
+ Added `Library:SetWatermarkVisibility()` method to toggle the visibility of the watermark
+ Added `Library:SetWatermark()` method to set the watermark text
```

### 14.07.2025

```diff
+ Added `AddImage` component
```

### 13.07.2025

```diff
+ Updated lucide icons to the latest version
+ Changed lucide icons to be using `getcustomasset` to bypass ContentProvider detections
+ Added `AddViewport` component
```

### 12.07.2025

```diff
+ Added `ThemeManager:SetDefaultTheme()` method to set the default theme for the library
+ Improved `Library:SafeCallback()` to handle errors correctly and return everything correctly (previously it would only return the first return value)
+ Added `BackgroundImage` parameter to `Window` constructor to set a background image for the window
```

### 02.07.2025

```diff
+ Added dropdown support for `AddDependencyBox` and `AddDependencyGroupBox`
```

### 15.06.2025

```diff
+ Fixed Obsidian's `Library:Validate()` function to ignore arrays (setting modes option on AddKeyPicker would fail previously)
```

### 04.06.2025

```diff
+ Added Notify.Persist and Notify:Destroy() methods to make persistent notifications easier to manage
+ Added Icon parameter to Groupbox constructor that matches the accent color.
```

### 17.05.2025

```diff
+ Added a new `AddDependencyBox` and `AddDependencyGroupBox` methods to the `Groupbox` class
```

### 18.01.2024

```diff
+ Added a Hover Animation to Buttons
+ Added Risky to Buttons
+ Changed Toggle's Checkbox to Switch (Checkbox is still possible with AddCheckbox)
+ Dropdown disabled values moved to the bottom
+ Fixed DPI Scale issues (Title Wrapping, Slider Fill Bar and Dropdown Menu Size)
```
