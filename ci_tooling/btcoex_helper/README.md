# OpenCore Legacy Patcher Bluetooth Coexistence Helper

`oclp-btcoex` restores Wi-Fi/Bluetooth coexistence on Modern Wireless cards in macOS 15 and newer.

Since macOS 15, `airportd` no longer loads coexistence profiles for these cards, causing Bluetooth audio to stutter while Wi-Fi is on 2.4 GHz. When root patching, OpenCore Legacy Patcher installs this tool to `/usr/libexec` along with a LaunchDaemon holding the profiles for the machine (`datasets/bluetooth_coex_data.py`). As the driver drops the profiles on reset, sleep and while joining a network, the LaunchDaemon keeps the tool running, which checks every 10 seconds and only reloads them when needed.

To check the current state, run the tool with the LaunchDaemon's arguments, replacing `--daemon` with `--status`.


## Building

```
make
```

This builds `payloads/Tools/BTCoex/usr/libexec/oclp-btcoex`.
