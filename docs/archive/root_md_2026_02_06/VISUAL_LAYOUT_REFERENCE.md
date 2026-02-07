# Visual Layout Reference - History Clinic Screen

## 1. Widget Tree Hierarchy

```
WorkspaceScaffold
│
└─ ClinicSummaryShell (Container wrapper)
   ├─ margin: EdgeInsets(16, 14, 16, 16)
   ├─ decoration: BoxDecoration(
   │  ├─ color: kCardColor.withValues(alpha: 0.20)
   │  ├─ borderRadius: 22
   │  └─ border: white@0.08
   │
   ├─ Column [
   │  ├─ [0] header: ClinicClientHeaderWithTabs (height: 150)
   │  │   └─ See detailed layout below
   │  │
   │  └─ [1] Expanded ──> TabBarView (5 tabs)
   │      ├─ padding: EdgeInsets(20, 18, 20, 20)
   │      ├─ PersonalDataTab
   │      ├─ BackgroundTab
   │      ├─ GeneralEvaluationTab
   │      ├─ TrainingEvaluationTab
   │      └─ GynecoTab
   │  ]
   ]
```

## 2. ClinicClientHeaderWithTabs Detailed Layout

```
┌─────────────────────────────────────────────────────────────┐
│ CONTAINER (height: 150, Stack)                              │
│                                                              │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ ROW (padding: 20t, 14t, 20b, 54b) - MAIN CONTENT       │ │
│ │                                                          │ │
│ │  ┌─────────┐  ┌──────────────────┐  ┌────┬─────────┐  │ │
│ │  │  Avatar │  │ Name             │  │Chip│ Chip    │  │ │
│ │  │ 88x88   │  │ (w700, 18sp)     │  │(×3)│ Row     │  │ │
│ │  │  Icon   │  │ Objective        │  │    │         │  │ │
│ │  │ person  │  │ (13sp, secondary)│  │    │         │  │ │
│ │  └─────────┘  └──────────────────┘  └────┴─────────┘  │ │
│ │    88x88           Expanded                 w: min      │ │
│ │                                                          │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                              │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ POSITIONED (bottom: 0, left: 124, right: 20, h: 54)    │ │
│ │ TABBAR (isScrollable: true)                             │ │
│ │                                                          │ │
│ │  [ Datos Personales │ Antecedentes │ Evaluación ... ]   │ │
│ │  ═════════════════════                                  │ │
│ │  (underline indicator, kPrimaryColor)                   │ │
│ │                                                          │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Layout Metrics
```
Avatar Position:
├─ left: 20px
├─ top: 14px
├─ width: 88px
├─ height: 88px

Name Column:
├─ left: 20 + 88 + 16 = 124px
├─ right: expand to chips
├─ top: 14px
└─ height: 88px (vertically centered)

Chips Row:
├─ right: 20px
├─ spacing: 8px
├─ colors: orange, blue, green/grey
└─ dynamic sizing

TabBar:
├─ left: 124px (after avatar)
├─ right: 20px
├─ bottom: 0px
├─ height: 54px
├─ scrollable: true (to wrap tabs if needed)
└─ indicator: 2.6px underline, kPrimaryColor
```

## 3. Metric Chips Format

```
┌─────────────────┐
│ Grasa 18.5 %    │  ← Orange, color@0.2 fill, color@0.4 border
└─────────────────┘

┌──────────────────┐
│ Músculo 42.3 %   │  ← Blue, color@0.2 fill, color@0.4 border
└──────────────────┘

┌───────────────┐
│ Plan Activo   │  ← Green (active) or Grey (inactive)
└───────────────┘
```

**Styling:**
```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  decoration: BoxDecoration(
    color: color.withValues(alpha: 0.2),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: color.withValues(alpha: 0.4)),
  ),
  child: Text(
    label,
    style: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: color,
    ),
  ),
)
```

## 4. Full Screen Layout (in context)

```
┌──────────────────────────────────────┐
│  MAIN SHELL (Workspace margin)       │
│                                      │
│  ┌────────────────────────────────┐  │
│  │ SUMMARY SHELL (margin: 16-16)  │  │
│  │ border: white@0.08, r: 22      │  │
│  │ bg: kCardColor@0.20            │  │
│  │                                │  │
│  │  ┌──────────────────────────┐  │  │
│  │  │ HEADER + TABS (h: 150)   │  │  │
│  │  │ [Avatar Name Chips]      │  │  │
│  │  │ [Tabs at bottom]         │  │  │
│  │  └──────────────────────────┘  │  │
│  │                                │  │
│  │  ┌──────────────────────────┐  │  │
│  │  │ CONTENT AREA             │  │  │
│  │  │ (padding: 20-18-20-20)   │  │  │
│  │  │                          │  │  │
│  │  │ PersonalDataTab          │  │  │
│  │  │ [Sections with inputs]   │  │  │
│  │  │                          │  │  │
│  │  └──────────────────────────┘  │  │
│  │                                │  │
│  └────────────────────────────────┘  │
│                                      │
└──────────────────────────────────────┘
```

## 5. Tab Content Integration

Each tab (PersonalDataTab, BackgroundTab, etc.) renders inside the Expanded area with:
- **Padding**: 20px (left/right), 18px (top), 20px (bottom)
- **Scrollable**: SingleChildScrollView for overflow content
- **Sections**: ClinicSectionSurface for grouped fields
- **Inputs**: depressed style (kBackgroundColor@0.35, white@0.06 border)

```
Tab Content:
├─ ClinicSectionSurface
│  ├─ Header band (icon + title)
│  ├─ Divider (1px white@0.08)
│  └─ Content (fields with depressed inputs)
│
├─ ClinicSectionSurface
│  └─ (multiple sections per tab)
│
└─ [Last section + bottom margin]
```

## 6. Color Reference

```
Theme Constants:
├─ kBackgroundColor = #FF232B45
│  └─ Used for: screen bg, input fills (@0.35 alpha)
│
├─ kCardColor = #FF010510
│  └─ Used for: shell bg (@0.20 alpha), avatar bg
│
├─ kPrimaryColor = #FF3F51B5
│  └─ Used for: avatar border, tab indicator, focus states
│
├─ kTextColor = #FFFFFFFF (white)
│  └─ Used for: primary text
│
└─ kTextColorSecondary = #FF9E9E9E
   └─ Used for: secondary text, unselected tabs
```

## 7. Responsive Behavior

### Desktop (1200px+)
- All content visible
- Tabs may wrap if many
- Full avatar + name + chips layout

### Tablet (800-1200px)
- Content stays within margin
- Chips may stack if needed
- TabBar may scroll

### Mobile (< 800px)
- Full-width minus margins
- Avatar + name may compress
- Chips definitely scroll
- TabBar scrollable

**Key principle**: ClinicClientHeaderWithTabs uses `Expanded` and `Wrap` to handle responsive layout automatically.

---

## 8. State & Lifecycle

```
HistoryClinicScreen (ConsumerStatefulWidget)
│
├─ initState()
│  ├─ Create: TabController(length: 5)
│  ├─ Setup: _tabListener (saves on tab change)
│  └─ Register: addListener to _tabController
│
├─ build()
│  ├─ Watch: clientsProvider (active client)
│  ├─ Watch: globalDateProvider (for ClientSummaryData)
│  ├─ Create: _buildChipsRight(summary)
│  ├─ Render: ClinicSummaryShell
│  │  └─ Pass: _tabController, tabViews
│  │
│  └─ TabBarView switches children (5 GlobalKey states)
│
├─ _tabListener()
│  └─ On tab change: _saveTabIfNeeded(previousIndex)
│
└─ dispose()
   ├─ removeListener(_tabListener)
   └─ _tabController.dispose()
```

## 9. Save-on-Switch Logic

```
User clicks Tab → TabController.index changes
                       ↓
_tabListener triggered with previous tab index
                       ↓
_saveTabIfNeeded(prevIndex) called
                       ↓
Switch on prevIndex → Get GlobalKey state → Call saveIfDirty()
                       ↓
If client updated → ref.read(clientsProvider.notifier).updateActiveClient()
                       ↓
Merge nutrition & training extra fields
                       ↓
Return to new tab with updated state
```

---

## 10. Integration Points

### From HistoryClinicScreen → ClinicClientHeaderWithTabs
```dart
ClinicClientHeaderWithTabs(
  avatar: Icon(Icons.person, ...),           // ← from context
  name: client.fullName,                     // ← from clientsProvider
  subtitle: client.profile.objective,        // ← from clientsProvider
  chipsRight: _buildChipsRight(summary),    // ← custom method
  tabController: _tabController,             // ← from initState
  tabs: const [Tab(text: '...'), ...],      // ← const list
)
```

### From ClinicClientHeaderWithTabs → TabBar
```dart
TabBar(
  controller: _tabController,        // ← same as TabBarView
  tabs: tabs,                        // ← passed from parent
  isScrollable: true,               // ← allows overflow
  labelColor: kPrimaryColor,        // ← active tab color
  unselectedLabelColor: kTextColorSecondary,  // ← inactive
  indicator: UnderlineTabIndicator,          // ← 2.6px underline
)
```

### From ClinicSummaryShell → TabBarView
```dart
TabBarView(
  controller: _tabController,   // ← same TabController
  children: tabViews,           // ← List<Widget> of 5 tabs
)
```

---

## Summary

✓ **Clean hierarchy**: WorkspaceScaffold → Shell → Header+Tabs → TabBarView  
✓ **Responsive**: Avatar + Name + Chips auto-layout with Expanded/Wrap  
✓ **Integrated tabs**: Stack/Positioned in header bottom (not separate)  
✓ **Flat aesthetic**: Depressed colors, subtle borders, no shadows  
✓ **Functional**: Full save-on-switch logic preserved  
✓ **Maintainable**: Clear separation of concerns (Shell, Header, Tabs)
