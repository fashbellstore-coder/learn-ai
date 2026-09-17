# Legacy "Terminal Noir" theme — backup

These are unmodified copies of the app's theme files as they stood before the
Nebula redesign (deep navy / cyber-cyan cyberpunk-terminal look), kept here so
the previous visual identity is easy to find and restore.

**Not imported anywhere.** These files are inert reference copies, not part of
the build. To bring the old theme back:

1. Copy `app_colors.dart` and `app_typography.dart` from this folder back over
   `lib/core/theme/app_colors.dart` and `lib/core/theme/app_typography.dart`.
2. Remove the `google_fonts` text styles from the live `app_typography.dart`
   if you also want to drop that dependency.

Snapshot taken: 2026-09-17, on branch `feature/nebula-theme`, just before
implementing the "Nebula" design (see `design_inspire/` for the source
mockups: Home Dashboard, Lesson, Catalog Roadmap).
