# Firebase Auth for Linux

This repository is a fork of the original FlutterFire platform for desktop packages, updated to ensure linux compatibility with the following versions:

- `firebase_auth`: ^5.3.4
- `firebase_core`: ^3.8.1
- `firebase_auth_desktop`: custom version from [flutterfire_desktop](https://github.com/Andrflor/flutterfire_desktop)
- `firebase_core_desktop`: custom version from [flutterfire_desktop](https://github.com/Andrflor/flutterfire_desktop)

## Modifications

This fork integrates changes to work seamlessly with the above versions, particularly addressing desktop platform support via the `firebase_auth_desktop` and `firebase_core_desktop` packages. It is specifically tailored to provide basic compatibility for `firebase_auth` on Linux systems.

## Installation

To use these specific versions in your Flutter project, add the following dependencies to your `pubspec.yaml` file:

```yaml
dependencies:
  firebase_auth: ^5.3.4
  firebase_core: ^3.8.1
  firebase_auth_desktop:
      git:
          url: https://github.com/Andrflor/flutterfire_desktop
          path: packages/firebase_auth/firebase_auth_desktop/
  firebase_core_desktop:
      git:
          url: https://github.com/Andrflor/flutterfire_desktop
          path: packages/firebase_core/firebase_core_desktop/
```

## Notes

- This fork is intended for developers who need to use `firebase_auth` and `firebase_core` with the specified versions, including desktop support.
- It is particularly useful for providing basic authentication functionality on Linux platforms.
- For more details about the original packages and features, refer to the official [FlutterFire documentation](https://firebase.flutter.dev/).

## Support

If you encounter any issues related to this fork, please create an issue in this repository, specifying the problem and the steps to reproduce it.

