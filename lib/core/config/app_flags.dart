/// Runtime flags controlled by `--dart-define`.
const bool kScreenshotMode = bool.fromEnvironment(
  'SCREENSHOT_MODE',
  defaultValue: false,
);

/// Product analytics (PostHog). Default OFF — no network unless explicitly enabled.
const bool kAnalyticsEnabled = bool.fromEnvironment(
  'ANALYTICS_ENABLED',
  defaultValue: false,
);

const String kPostHogApiKey = String.fromEnvironment(
  'POSTHOG_API_KEY',
  defaultValue: '',
);

const String kPostHogHost = String.fromEnvironment(
  'POSTHOG_HOST',
  defaultValue: 'https://us.i.posthog.com',
);

const String kAnalyticsEnvironment = String.fromEnvironment(
  'ANALYTICS_ENVIRONMENT',
  defaultValue: 'prelaunch',
);
