# yeki

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Installation (une fois après le clonage)

```bash
bash tool/setup_hooks.sh
```

Active le hook pre-commit versionné (`tool/githooks/pre-commit`), qui lance
le pare-feu du design system (`tool/check_design_system.sh`) avant chaque
commit — voir CDC_DESIGN §9 et `tool/baseline.txt`.
