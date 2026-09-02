-- Dungeon Quest autofarm settings.
--
-- These are the values used the FIRST time you run the script. After that the
-- in-game menu (Right Shift) writes Radiance/Configs/dq_autofarm.json, and that
-- file wins over this block. Delete it to come back to these.
-- Movement speed. This is the "careful" speed (strafe, dodge, backing off);
-- chasing runs 25% faster. Roblox's default is 16. The script used to hardcode
-- 31, which is fast enough that running into geometry diverges the client from
-- the server and the correction shows up as rubberbanding.
_G.walk_speed = 24

-- Travel teleport: skips the long walk to the next room or a distant group.
-- It only ever runs past teleport_min_distance; inside that the original walk-in
-- and attack code runs untouched, which is what makes hits land.
_G.teleport_to_enemies = true
_G.teleport_min_distance = 30   -- under this it walks, exactly like the original
_G.teleport_step = 20           -- studs per hop (60 got rejected by the server)
_G.teleport_interval = 0.35     -- seconds between hops (~57 studs/s total)

-- The script's own dodge-teleport. This was NOT in the original settings block,
-- which left it nil and the hop code unreachable - and that was correct. With it
-- on, smallTeleportVal (100) flings you up to 100 studs mid-fight, so you never
-- settle next to a mob long enough to damage it. Off unless you want it.
_G.SemiTeleports = false
_G.teleportDuringBossOnly = true -- if true, only use smallTeleports when its time for a boss
-- Client-side kills do not replicate in this build: the server keeps ownership
-- of enemies. Leaving this on only desyncs the health the farm reads. The
-- script probes one enemy and turns it off by itself, but off is the honest
-- default here.
_G.doInstakill = false

-- AI Visual Settings
_G.showTarget = true -- this will highlight each target in a red box
_G.showPath = true

-- AI Performance
_G.extremelyFast = true -- makes the ai think exponentially faster, but might lag for people

-- Lobby Settings
_G.maxWaitTimeInLobby = 0 -- this is how long itll randomly walk around for before going into a dungeon
_G.collect_daily_reward = false

-- Dungeon Choosing Settings
_G.auto_join_dungeon = true
_G.dungeon = nil
_G.difficulty = nil
_G.hardcore = true -- hardcore mode
_G.auto_choose_dungeon_and_difficulty = true -- if true, then script auto choose dungeon and difficulty for your lvl
_G.autoexec_wait_time_secs = 3

-- Auto Replay
-- Replays the dungeon you just finished instead of returning to the lobby.
-- Only works if you own the dungeon, and the game teleports you into a fresh
-- server, so the script must be in your autoexec to come back up over there.
_G.auto_replay = true
_G.auto_replay_delay = 3 -- seconds to wait after the run ends before replaying

-- Boss Raid Settings
_G.boss_raid = false
_G.auto_choose_raid_boss_tier = true
_G.boss_raid_tier = 1

-- Wave Defense Settings
_G.wavedefense = false -- wave defense

-- Easter Event Settings
_G.easter_enable = false
_G.eggClass = "Mage"

-- Party Settings
-- Hosting Settings
_G.wait_for_friends = false
_G.friends = {"Friend 1", "Friend 2"}

-- Joining Settings
_G.wait_for_friends_to_host = false
_G.host_name = "Name of the host"

-- Multi-Instance Settings
_G.multi_roblox = false
_G.host_name_key = {"acc"} -- this account creates parties
_G.name_key_list = {
  {"acc"},
}

-- Autosell Settings
_G.autosell = false
_G.testSell = false -- prints out what items would've been sold instead of selling the items
_G.keep_items_level_requirement = 156  -- keeps items that level requirements are above this number
_G.keep2spells = false -- sell spells extra spells if you have 2 already
_G.keep_items_from_class = {
  ["physical"] = false,
  ["mage"] = false,
} --[[ only keeps items that fall within the given class ]]
_G.keeprarities = {
  ['legendary'] = true,
  ['epic'] = false,
  ['rare'] = false,
  ['uncommon'] = false,
  ['common'] = false,
}
_G.itemlist ={

  --Volcanic Chambers Armor
  ["Lava King's Warrior Helmet"] = {"rare","epic"},
  ["Lava King's Warrior Armor"] = {"rare","epic"},
  ["Lava King's Mage Helmet"] = {"rare","epic"},
  ["Lava King's Mage Armor"] = {"rare","epic"},
  -- Warrior Skills,
  ["Enhanced Inner Rage"] = {"legendary"},
  -- Others
  ["Enchanted Serpent Daggers"] = {"rare","epic"},
  ["Oceanic Greatsword"] = {"rare","epic"},
  ["Spear Strike"] = {"rare"},
  ["Water Orb"] = {"rare"},
  ["Ice Barrage"] = {"epic"},
  ["Ice Crash"] = {"epic"},
  ["Aquatic Smite"] = {"epic"},
  ["Ice Spikes"] = {"epic"},
  ["Triton Warrior Helmet"] = {"rare","epic","uncommon"},
  ["Triton Warrior Armor"] = {"rare","epic","uncommon"},
  ["Triton Mage Armor"] = {"rare","epic","uncommon"},
  ["Triton Mage Helmet"] = {"rare","epic","uncommon"},
  ["Triton Guardian Helmet"] = {"rare","epic"},
  ["Triton Guardian Armor"] = {"rare","epic"},

}

-- Auto Upgrade Settings
_G.auto_stat_upgrade = false -- auto upgrade stats
_G.stat = "physicalPower" -- selected stat
_G.auto_equip_gear = false
_G.equip_type = "spell" -- "physical", "spell"
_G.auto_upgrade_equip = false
_G.autoEquipSpell = false
_G.spellType = "spell" -- "physical", "spell"

-- The script's map-fix walls block physically, as in the original. Some of them
-- were recorded against the old map geometry and overlap walkable ground in this
-- build, which shoves the character ~31 studs when it ends up inside one. Turning
-- this off stops that, but then it can walk off the map entirely (measured Y -190).
_G.solid_walls = true

-- ANTI LAG SETTINGS
_G.wall_transparency = .5
_G.optimize_mobs = true
_G.destroy_map = true
_G.del_armor= true
_G.del_weapon = true
_G.hide_projectiles = true
_G.loadSlow = false
_G.fpsBoost = true

-- UI Settings
_G.edit_ui = false
_G.UI_portait_image = 'rbxassetid://3157197640'
_G.UI_health = "Peanut"
_G.UI_money = "Peanut"
_G.UI_name = "Peanut Quest"
_G.UI_xp = "66"
_G.UI_lvl = "33"

-- Discord Webhook
_G.webhookEnabled = false
_G.webhookLink = nil -- your webhook

loadstring(game:HttpGet("https://raw.githubusercontent.com/eduardonash/dq-autofarm/main/dq.lua"))()
