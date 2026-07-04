# WearShield — Apple Watch

Apple Watch port of the Android wearshield app. Parameterized via `Config.xcconfig` for any Apple Watch model.

## Config Parameters

Edit `Config.xcconfig` to target your watch:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `WATCHOS_DEPLOYMENT_TARGET` | Minimum watchOS version | 10.0 |
| `GATEWAY_HOST` | LAN gateway IP | 10.0.0.25 |
| `GATEWAY_PORT` | ASS-OS blossom port | 5540 |
| `DEFAULT_WEARER` | Wearer ID | user1 |
| `HAS_SKIN_TEMP` | Skin temperature sensor | YES (Series 8+) |
| `HAS_BLOOD_OXYGEN` | SpO2 sensor | YES (Series 6+) |
| `HAS_ECG` | ECG capability | YES (Series 4+) |
| `HAS_DEPTH` | Depth gauge | NO (Ultra only) |
| `HAS_SLEEP_APNEA` | Sleep apnea detection | NO (Series 10+) |

## Apple Watch Model Matrix

| Watch | minOS | Skin Temp | SpO2 | ECG | Depth | Apnea |
|-------|-------|-----------|------|-----|-------|-------|
| Series 4-5 | 9.0 | NO | NO | YES | NO | NO |
| Series 6-7 | 9.0 | NO | YES | YES | NO | NO |
| SE (2nd) | 9.0 | NO | NO | NO | NO | NO |
| Series 8 | 9.0 | YES | YES | YES | NO | NO |
| Ultra | 9.0 | YES | YES | YES | YES | NO |
| Series 9 | 10.0 | YES | YES | YES | NO | NO |
| Ultra 2 | 10.0 | YES | YES | YES | YES | NO |
| Series 10 | 11.0 | YES | YES | YES | NO | YES |

## Architecture

```
WearShield/
├── WearShieldApp.swift      — entry point, boots sensors + gateway + bloom
├── Models/
│   ├── WatchConfig.swift    — parameterized config from xcconfig
│   └── BloomState.swift     — fold math, κ dynamics, shield state
├── Sensors/
│   └── SensorHub.swift      — HealthKit + CoreMotion collection
├── Network/
│   └── GatewayClient.swift  — HTTP blossom RPC to ASS-OS gateway
├── UI/
│   └── ShieldView.swift     — bloom ring Canvas + κ/φ HUD
└── Bloom/                   — (future: escure, ERPC gate, tag store)
```

## vs Android wearshield

| Feature | Android | Apple |
|---------|---------|-------|
| Sensors | Samsung SDK + Android | HealthKit + CoreMotion |
| Transport | HTTP + MQTT + BLE | HTTP (MQTT planned) |
| Watch Face | WallpaperService | (planned: ClockKit) |
| Foreground Service | FGS health | Background App Refresh |
| Bloom math | BigInteger escure | Same fold/phi/wound/kappa |
| κ dynamics | Server-side | On-device (§2 convergence) |
