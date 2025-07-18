# Intervention/Blocking Screen

## Overview
Layar Intervensi adalah komponen kunci dari aplikasi todolist yang dirancang untuk memblokir akses ke aplikasi pengganggu dan mengarahkan pengguna kembali ke tugas-tugas produktif mereka.

## Features
- **Full-screen overlay** dengan background gelap yang elegan
- **Animasi masuk** yang smooth dengan scale dan fade effect
- **Quote motivasi random** dengan typography serif yang elegan
- **Reminder tugas urgent** yang dinamis berdasarkan data real
- **Icon adaptif** berdasarkan jenis aplikasi yang diblokir
- **Minimal button** untuk kembali bekerja

## Components

### 1. InterventionScreen
Widget utama yang menampilkan layar blocking.

```dart
InterventionScreen(
  blockedAppName: 'Instagram',
  currentHighPriorityTask: 'Selesaikan laporan bulanan',
)
```

### 2. InterventionDemoScreen  
Screen demo untuk testing dan preview layar intervensi.

### 3. InterventionIcons
Collection icon yang disesuaikan dengan jenis aplikasi.

### 4. AppBlockerService
Service untuk mengatur logika blocking aplikasi.

## Design Specifications

### Colors
- Background: `#1A1A1A` (dark grey)
- Gradient: `#2D2D2D` to `#1A1A1A`
- Text: White dengan berbagai opacity
- Accent: `#4A6FA5` (blue muted)

### Typography
- Quote: Georgia (serif) 22px untuk elegance
- Author: 16px dengan italic style
- Task reminder: 18px bold
- Button: 18px medium

### Layout
- Padding: 32px horizontal, 40px vertical
- Icon size: 120x120px dalam circle container
- Spacing: Flexible dengan Spacer widgets

### Animations
- Duration: 1500ms untuk scale animation
- Curve: `Curves.elasticOut` untuk bouncy effect
- Fade: `Curves.easeIn` untuk smooth appearance

## Usage

### Basic Usage
```dart
// Navigate to intervention screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => InterventionScreen(
      blockedAppName: 'TikTok',
    ),
  ),
);
```

### With Service
```dart
// Using AppBlockerService
AppBlockerService.showInterventionScreen(context, 'com.tiktok.app');
```

### Demo/Testing
```dart
// Navigate to demo screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => InterventionDemoScreen(),
  ),
);
```

## Customization

### Adding New Quotes
Edit the `_quotes` list in `InterventionScreen`:

```dart
final List<Map<String, String>> _quotes = [
  {
    'text': 'Your custom quote here.',
    'author': 'Author Name'
  },
  // ... more quotes
];
```

### Custom Icons
Add new icons in `InterventionIcons`:

```dart
static const IconData newIcon = Icons.your_icon_here;
```

### Custom App Mapping
Update `AppBlockerService` for new app support:

```dart
static const Map<String, String> _appNames = {
  'com.your.app': 'Your App Name',
  // ... more apps
};
```

## Integration Points

### 1. Settings Screen
Demo screen accessible from Settings > "Test Layar Intervensi"

### 2. Todo Repository
Mengambil task urgent untuk ditampilkan dalam reminder

### 3. App Blocker Settings
Terintegrasi dengan pengaturan aplikasi yang diblokir

## Performance Notes
- Animasi dioptimalkan dengan `SingleTickerProviderStateMixin`
- Lazy loading untuk urgent task data
- Efficient quote selection dengan modulo operation
- Haptic feedback untuk better UX

## Accessibility
- Semantic labels untuk screen readers
- High contrast colors
- Readable font sizes
- Touch target minimal 44px

## Future Enhancements
- [ ] Custom quote dari user
- [ ] Statistik blocking time
- [ ] Integration dengan usage statistics
- [ ] Breathing exercise mini-games
- [ ] Achievement system untuk focus streaks
