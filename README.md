# MenuStats

A small macOS menu bar app that shows system stats in a dropdown panel, in the spirit of iStat Menus' combined mode.

The menu bar shows a single icon. Clicking it opens a panel with:

- **CPU:** total usage with a 5-minute history graph
- **Memory:** used / total, matching Activity Monitor's "Memory Used"
- **Network:** download / upload speed with a history graph (Wi-Fi and Ethernet only, so VPN traffic isn't counted twice)
- **Battery:** charge, charging state, health, cycle count and temperature

Stats refresh every 5 seconds. The app has no third-party dependencies, makes no network calls and needs no special permissions.

## Requirements

- macOS 26 or later
- Xcode 26 or later (for Swift 6.2+)
- [just](https://github.com/casey/just) (optional, for the commands below)

## Usage

```sh
just test     # run the tests
just bundle   # build build/MenuStats.app
just run      # rebuild and (re)start the app
just clean    # remove build output
```

Without `just`, use `swift test` and `./scripts/bundle.sh`, then `open build/MenuStats.app`.

The app is ad-hoc signed for local use and isn't notarized.
