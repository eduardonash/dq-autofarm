# Dungeon Quest Autofarm

Autofarm for **Dungeon Quest Reborn** (Delta Quarters OG, universe `9931749389`).

This is a repaired and retargeted build of an older Dungeon Quest autofarm. The
original was decompiler output that would not compile at all, and it was written
for the pre-2025 game, which shipped one Roblox place per dungeon. This build
runs every dungeon inside a single `Level` place, so the whole per-place
dispatcher had to be rewritten to key off `workspace.dungeonName` instead.

## Usage

Put your settings **above** the loader. The script reads `_G` as it loads, so
anything you set first wins.

```lua
-- ==== settings ====
_G.auto_join_dungeon = true
_G.auto_choose_dungeon_and_difficulty = true
_G.hardcore = true
_G.auto_replay = true
_G.teleport_to_enemies = true
-- ...see config.example.lua for the full list

loadstring(game:HttpGet("https://raw.githubusercontent.com/eduardonash/dq-autofarm/main/dq.lua"))()
```

`config.example.lua` is a complete, ready-to-paste settings block with the
loader line already at the bottom.

## Menu

Press **Right Shift**. The interface is the Radiance library (vendored here as
`Library.lua`, from sametexe001/sametlibs, unmodified so it can be re-synced),
laid out as:

| Page | Sections |
| --- | --- |
| farm | dungeon, combat |
| movement | teleport, dodge |
| items | selling, gear |
| misc | performance, boss raid, webhook |
| settings | named configs, theming, unload, menu keybind (the library's own) |

Every control's flag is named after the `_G` key it drives and writes straight
into it, so a change takes effect on the next tick rather than needing a reload.

**Settings save themselves.** Any change is written to
`Radiance/Configs/dq_autofarm.json` a second later, and loaded back on the next
run — including after auto replay teleports you into a fresh server. That file
wins over the settings block above the loadstring, which is only the starting
point on a fresh install; delete it to go back to the block. The settings page
also has the library's named-config manager if you want more than one profile.

Status lives in the watermark: current action on top, `alive / killed / gold /
elapsed` underneath.

## Where to stand

`_G.attack_position` picks how the farm approaches a mob:

| Value | |
| --- | --- |
| `default` | walk/hop straight at it |
| `above` | sit `attack_height` studs over its head, on an invisible pad |
| `below` | same, underneath it |
| `behind` | come in `attack_distance` studs off its back |

Weapons reach about 13 studs, so a large `attack_height` will park you out of
range swinging at nothing.

## Notes

- **Auto replay** teleports you into a fresh reserved server, which kills the
  running script. Put the loader in your executor's autoexec so it comes back up
  on the other side.
- **Teleporting** is a mode, not a switch. `far` (the default) only teleports to
  cover distance — past `_G.teleport_min_distance`, which is room-to-room range —
  and walks anything closer, which is what the melee approach was tuned for.
  `always` teleports the whole way in, `off` walks everywhere. It hops in short
  steps and raycasts for floor before each landing; if you get kicked, lower
  `_G.teleport_step` first.
- **Instakill** relies on owning the enemy's assembly so a client-side `Health`
  write replicates, which the old build achieved through `SimulationRadius`.
  The script probes once per session and turns the option off by itself, with a
  notification, if the server rejects the write.
- Dungeons added after the original script was written (Enchanted Forest,
  Northern Lands, Gilded Skies, Oni Dungeon, Krampus) are selectable and
  farmable, but have no hand-recorded wall data, so they run without the
  per-map geometry fix.

## Place ids

From the game's own `ReplicatedStorage.Utility.PlaceManager`:

| Place | Id |
| --- | --- |
| Lobby | `77649408247578` |
| Level (every dungeon) | `85776757589518` |
| Lobby 100+ | `115445507767090` |
