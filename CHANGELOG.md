## 24.09.2026 (2)

```diff
[additions]
+ Groupbox:AddStatusLabel(Idx, Info) -- a scrolling list of rows, each with a live
  status on its right. A row with a Time counts down to that moment ("9 min", "2 hr");
  a row without one, or past it, shows the plain status word ("Up") in accent. Clicking
  any countdown flips the whole list between the countdown and the clock time it lands
  on -- two readings of the same instant, the way a date in a document can be shown
  either way. Rows live in a ScrollingFrame capped at MaxHeight (120 by default), so a
  long list scrolls instead of stretching the groupbox. Items are { Text, Status, Time,
  Suffix, StatusColor, TimeColor, TimeFormat, Tooltip }; the element exposes SetItems,
  AddItem, UpdateItem, Clear, SetMode, Toggle, SetMaxHeight and SetVisible, and is
  indexed into Library.Labels. One heartbeat per list, throttled to a tick a second.
```

## 24.09.2026

```diff
[changes]
* Merged upstream Obsidian (44 commits, through "feat: SetPopOutWidth"). Upstream won
  every API and behaviour conflict; the fork kept its own styling where upstream had
  only restyled the same region. What this changes for callers:
* Library:PlayTabAnimation(Tab, Showing, OnComplete, SwipeFrom) now takes the tab
  table rather than its canvas -- upstream animates Tab.Container and dropped the
  CanvasGroup wrapper around tab contents, which is their fix for blurry tab text. A
  bare container instance is still accepted, so sub tabs pass their own canvas as
  before, and a CanvasGroup container still fades as well as slides.
* Tab buttons gained upstream's ButtonHolder, TabIndicator and TabButtonsStyle. The
  chip skin (Library:SkinTabButton) still owns the corner, the chip and the active
  state, so upstream's own UICorner is not created and CornerRadius has no effect.
  TabButtonsStyle defaults to Gap = 4, Padding = 6 here, which is the spacing the
  skin was drawn against and what keeps MinSidebarWidth at 76.
* Search is upstream's scored implementation: every tab is searched and the window
  switches to the most prominent match. Sub tab recursion and GlobalSearch are kept on
  top -- GlobalSearch now only decides whether tabs other than the best match keep
  their filtered state.
* Tooltips take upstream's cursor-aware placement; the pop animation stays.
* Example.lua is upstream's, pointed back at this fork's raw URL. The fork's own
  element demos are no longer in it.
```

## 21.09.2026 (2)

```diff
[changes]
* Reverted the drag gate, the shared element states and the groupbox header
  badge. MakeDraggable is back to moving the window the moment the handle is
  pressed, checkboxes, toggles, buttons and dropdowns keep the state colours
  they each had, and Groupbox:SetBadge / the Badge and ShowActiveCount fields
  are gone again.
* Kept out of that revert: the constants that moved into tables so the main
  chunk clears Luau's 200 local register limit. The Discord card metrics, the
  player card insets and the notification history sizes each live in one table,
  which is what lets the file compile at -O0 the way an executor loads it.
  Anything added near the top level should go in a table for the same reason;
  `luau-compile -O0` is the check, since -O1 and above reuse registers and
  compile a file that is over the limit without complaint.
```

## 21.09.2026

```diff
[changes]
* Sliders read as a channel with light in it, and stay flat. The track is sunk to
  the background colour instead of the panel colour and grown 15 -> 18px, and the
  fill runs a gradient along the bar -- shaded at the root, full accent at the head
  -- rather than sitting as one solid block. Nothing rides on the bar: no ball, no
  handle, no rim. Hovering warms the track edge to the accent at 0.4 and that is
  all. Programmatic value changes now glide the fill into place; dragging stays
  glued to the cursor, frame for frame. Compact sliders share the new height, and
  the label gap went 2 -> 3px.
* A tabbox's tab strip is a segmented control. The row is a recessed rail inset 4px
  inside the card, and the open tab is a raised accent chip that slides between the
  segments, lit along its top edge by a white-to-grey gradient over the accent. The
  open tab's label and glyph flip to black or white -- whichever the accent can
  carry -- while the rest sit at 0.55 against the rail and climb to 0.25 under the
  pointer. The old centred underline is gone; the chip marks the open tab now, and
  the header divider still separates the strip from the content below.
* Nine more pink themes: Cotton Candy, Neon Bubblegum, Rosewater, Strawberry Milk,
  Peony, Magenta Dusk, Pink Lemonade, Hot Pink Void and Orchid Haze -- from a muted
  rosewater through milk-and-strawberry mids to a hot pink on near-black.
```

## 20.09.2026

```diff
[changes]
* Sidebar tab hover is a well at both widths. Expanded rows used to answer a hover by
  lifting the label from 0.5 to 0.25 transparency and nothing else, which is a change
  you have to be looking for; they now raise the same light well the compact column
  does, shaped to the row (the full card, grown back out through the button's padding
  so it covers exactly what the open row's fill covers) and rounded at the bar radius
  rather than the chip's. The compact well was raised from 0.92 to 0.88 so it is
  actually visible, and it swells 24 -> 27px under the pointer the way the chip grows
  when it opens; the wide row sits at 0.94, since a card carries far more light than a
  24px square at the same alpha. Label and glyph now go to 0.1 on hover instead of
  0.25, so the well carries the state and the text only finishes the climb.
* The accent edge marker is drawn at both widths. An expanded open tab was a filled
  card with no accent anywhere on it; the 3x22 rail now lights for it too, which ties
  the expanded row back to the compact chip instead of leaving the two widths looking
  like different controls.
* Sliders are flat again: the label sits above a plain 15px track with the value
  centred inside it. The ball, its shadow, the inner ring and the grey track
  gradient are gone, the bar takes the panel colour rather than the font colour,
  and both bar and fill round at half the window radius instead of into a pill.
  The value now reads "6 studs / 10 studs", spaced either side of the slash.
* Compact sidebar tabs are now dock chips: while the sidebar is compact, the open
  tab's glyph sits on a 30px accent-filled rounded square (a white-to-grey gradient
  over the accent, plus a white top rim) and flips to black or white -- whichever
  reads against the accent. A 3x22 accent marker sits hard against the sidebar's
  left edge, level with the chip, tapering away at both tips. Switching tabs slides
  both: the incoming pair enters from the side the previous tab sits on while it
  fades in, and the outgoing pair leaves towards the new one as it fades out, so the
  mark reads as being carried down the column rather than blinking from place to
  place. Hovering an inactive glyph raises a plain light
  well rather than a faint accent chip, and switching tabs grows the chip from 24px. Expanding the sidebar brings
  the labels back and drops both: a row with a label is a row, not a chip, so the
  button returns to the plain full-width card.
* Compact glyphs sit at 18px (padding 6 -> 11) so they read inside the chip.
* Sidebar tab list gets a 6px gutter with 4px between buttons; minimum sidebar and
  compact widths were nudged up to keep the buttons the same size inside it.

[fixes]
* A chip that had slid away on a tab switch stayed offset, so it was drawn crooked in
  its own button the next time it was hovered. The pair is now put back once the
  slide has finished and it is out of sight.
* Compact chips no longer stay lit as a hover after being selected: Tab:Hover returns
  early while a tab is the open one, so a tab clicked with the pointer on it was never
  told the pointer left and lit back up the moment it was deselected. The chip now
  tracks hover on the button's own signals and drops it on selection.
```

## 02.09.2026

```diff
[changes]
* Groupboxes now slide open/shut when collapsed instead of snapping — the body is
  clipped behind the card edge while the height animates, and the chevron spins with
  it. Gated on Animations.GroupboxCollapse, which defaults to true (independent of
  the general Animations.Groupbox resize flag).

* Tabboxes redesigned: the folder-tab buttons are now a clean icon/text strip with
  a sliding accent underline and a smooth content-switch animation (underline slide
  gated on Animations.SubTabUnderline, content slide on Animations.TabSwitch). Tabbox:AddTab(Name, IconName) — pass a name, an icon, or both ("" name = icon-only).

[fixes]
* Tabbox underline no longer spans the whole strip until the first tab switch: adding
  a tab re-flexes the row, so the underline now re-measures against the active button.

[features]
+ Groupbox:AddDiscordBox(Idx, Info) — a Discord-style promo card: banner, circular avatar overlapping it, status dot, title/subtitle, and a row of action buttons (copy an invite link, run a callback). Nothing is hardcoded — images, colours, labels and actions are all passed in; the accent defaults to Scheme.BlueColor. Methods: SetTitle/SetSubtitle/SetBanner/SetAvatar/SetStatus/SetAccent/SetLink/SetButtons/SetButtonText/SetBannerHeight/SetAvatarSize/SetVisible/GetTotalHeight.
+ Window:SetGlow(Enabled, Options?) — opt-in soft glow behind the window. Off by default and never forced/hidden (games' anticheats can flag unusual rendering). Options: { Color: Color3? (defaults to & follows the accent color), Transparency: number?, Radius: number? }. Also settable at creation via Glow = true.
+ Window:GetSizePosition() / Window:SetSizePosition(Size?, Position?) — read/apply the window size & position (clamped to the viewport & min size, relayouts tabs).
+ SaveManager now saves & restores the UI size and position. Skip it with SaveManager:SetIgnoreIndexes({ "WindowLayout" }).
```

## 29.08.2026

```diff
[features]
+ Groupbox:AddPriorityDropdown(Idx, Info) — a searchable, drag-to-rank priority list (no selecting; drag rows above/below to order them). Grab a row anywhere, clamped + auto-scroll, mouse/touch. Has an expand panel (Expand/Collapse/ToggleExpanded/IsExpanded) for easier management. Saves/loads with SaveManager.
```

## 20.09.2026

```diff
[features]
+ KeepDisabledValuePosition for Dropdown (keeps DisabledValues in their Values order instead of moving them to the end)
+ SetMaxPopOutHeight(MaxHeight: number) for popout groupboxes and tabboxes
+ SetPopOutWidth(Width: number) for popout groupboxes and tabboxes
+ KeyPicker:SetMenuVisibility(Visible: boolean)

[fixed]
+ Fixed text and UI elements sizing incorrectly at different DPI scales or screen resolutions
+ Fixed dropdown arrows overlapping the footer when scrolling
```

## 04.09.2026

```diff
[features]
+ TabButtonsStyle for CreateWindow (Gap, Padding, CornerRadius, Indicator, IndicatorWidth, IndicatorHeight)
+ Library.Cursor:ChangeCrossColor(Color)
+ Library.Cursor:ResetCross()
+ Library.Cursor:ChangeIcon(ImageId)
+ Library.Cursor:ChangeIconColor(Color)
+ Library.Cursor:ChangeIconSize(Size)
+ Library.Cursor:ResetIcon()
+ Library.Cursor:ResetCursor()

[changes]
+ Library:ChangeCursorCrossColor, ResetCursorCross, ChangeCursorIcon, ChangeCursorIconColor, ChangeCursorIconSize and ResetCursorIcon are deprecated; use Library.Cursor instead

[fixed]
+ Fixed KeyPickers not updating visually when toggled from the keybind menu
```

## 31.08.2026

```diff
[features]
+ Tooltip support for tab buttons

[changes]
+ ColorPickers use the smallest possible size on Mobile now
+ SetValue will now set the Value but will not run the Callbacks when the element is disabled
+ Search now switches to the tab with the most prominent match

[fixed]
+ Fixed notifications resizing incorrectly
+ Fixed Toggle and Lock buttons on mobile impossible to click
+ Fixed KeyPickers and ColorPickers still able to be changed while disabled in the UI
+ Fixed KeyPickers and ColorPickers not updating visually if they are disabled or not
```

## 25.08.2026

```diff
[features]
+ Library:ApplyLucideIcon(ImageGui: ImageLabel | ImageButton, Icon: LucideIcon, Rotation: number?)
+ Groupbox/Tabbox pop-out into draggable element (enabled by default)
+ Tabbox and Groupbox :SetPoppedOut, :TogglePoppedOut
+ Fuzzy matching for sidebar and dropdown search
+ Window snapping to screen edges/center (Snapping, SnapAvoidCoreGui, SnapDistance, SnapMargin)
+ Window:SetSnapping(Enabled, Distance?, Margin?)
+ Automatic WCAG contrast checking for themes

[changes]
+ Dropdown search results are sorted by best match
+ Matching a Tab/Groupbox name in search reveals all of its contents
+ ZIndex changed to Siblings mode
+ Increased the maximum width for Button KeyPickers
+ Escape dismisses open menus/dialogs and releases text input focus (without toggling the window)
+ AccentColor focus-border tween applied to all text inputs
+ Hover feedback on KeyBox Execute and KeyPicker key display buttons

[fixes]
+ Fixed Tab:SetOrder()
+ Fixed Dropdown:SetValueImages()
+ Fixed KeyPicker sliding animation sometimes causing errors
+ Fixed Button KeyPickers not resizing properly to fit the text
+ Fixed mouse icon state not reverting properly
+ Fixed corner radiuses not properly changing with Dropdowns, KeyPickers, ColorPickers and certain Context Menus
```

## 23.08.2026

```diff
[features]
+ Import/Export Theme and Configuration JSON through the UI
```

## 20.08.2026

```diff
[features]
+ Groupbox Descriptions, Groupbox:SetDescription()

[changes]
+ :AddLeftGroupbox(...) and :AddRightGroupbox(...) are now deprecated; use :AddGroupbox({ ... }) instead
```

## 17.08.2026

```diff
[features]
+ ColorPicker.Resizable
+ Window.AlwaysOnTop, Window:SetAlwaysOnTop, Loading.AlwaysOnTop

[changes]
+ TextBox focus now tweens the border between OutlineColor and AccentColor
+ Added Hover highlights on Dropdown items, KeyPicker mode-select buttons, and ColorPicker context menu items

[fixes]
+ Implemented MinContainerWidth properly
```

## 12.08.2026

```diff
[features]
+ Large dropdown lists are now virtualized for faster opens and lower instance count
+ Dropdowns no longer crash the game with over 10,000 values
+ Dictionary Values support: key = selection identity, value = display label
+ Dropdown:SetValues now prunes stale selections that are no longer in Values

[changes]
+ Dropdown.DisabledValues and Dropdown.ValueImages now accept dictionary keys or labels
+ Dropdown:AddValues on dictionary Values merges maps (or key=label for arrays)
+ Sparse numeric tables are treated as arrays (value identity), not dictionaries

[fixes]
+ Multi-dropdown dictionary keys no longer stripped to display labels (Issue #109)
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
