/// Runtime flags controlled by `--dart-define`.
const bool kScreenshotMode = bool.fromEnvironment(
  'SCREENSHOT_MODE',
  defaultValue: false,
);
