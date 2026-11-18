# Learnstead UI

Flutter client for Learnstead: parents discover, save, review and message
learning providers and plan sessions; providers manage their listing,
schedule and inquiries.

## Running

The app reads its endpoints at build time:

```
flutter run --dart-define-from-file=config/dev.json
```

`config/dev.json` points at a local backend (`Learnstead-Backend`, port 8000)
and local Supabase (port 54321). Copy `config/prod.json.example` to
`config/prod.json` for a hosted environment.

## Tests

```
flutter test --dart-define=API_BASE_URL=http://api.test
```

The widget tests run against a mocked HTTP API (no backend needed).

## Sign-in notes

- **Sessions** are persisted by `supabase_flutter`; `AuthGate` restores them
  on launch and API calls always use the auto-refreshed access token.
- **Forgot password** emails a 6-digit code. The Supabase "Reset Password"
  email template must include `{{ .Token }}` (the local template lives in
  `Learnstead-Backend/supabase/templates/recovery.html`; for a hosted project
  set it under Authentication → Email Templates).
- **Google / Apple** use Supabase OAuth and return to the app through the
  `io.learnstead.app://login-callback` deep link (registered in
  `AndroidManifest.xml` and `Info.plist`). To turn them on: enable each
  provider with your client ID/secret in Supabase (Authentication →
  Providers, or `[auth.external.*]` in `supabase/config.toml`) and add the
  deep link to the allowed redirect URLs. Until then the buttons show
  Supabase's "provider is not enabled" error.

# Run simulation
```
usbipd list
usbipd attach --wsl --busid <id>
scrcpy
flutter run -d R58R52565MB
```