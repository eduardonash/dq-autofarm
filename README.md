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

## Config panel

Press **Right Shift** for a panel with every setting laid out in sections, each
with its own on/off switch that greys out and disables the whole group.
Dropdowns for the picky ones (dungeon, difficulty, where to stand, which stat),
switches for the flags, boxes for the numbers.

Changes apply the moment you make them. **Save** writes them to
`dq_autofarm_config.json` in your executor's workspace folder, and they are
loaded back on the next run — including after auto replay teleports you into a
fresh server. Once that file exists it wins over the settings block above the
loadstring, so the block is really just the starting point on a fresh install.
Delete the file to go back to it.

The panel opens by itself the first time, then stays hidden.

## Status panel

A small draggable panel sits bottom-left showing what the script is doing right
now, plus enemies alive, kills, elapsed time and gold earned this session. It
replaces the original's per-frame console narration, which flooded F9.

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
- **Teleporting** hops in short steps and raycasts for floor before each landing.
  If you get kicked, lower `_G.teleport_step` first.
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
