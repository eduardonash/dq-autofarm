-- Dungeon Quest autofarm - repaired decompile, retargeted at the current build.
--
-- Source was unluac output that would not compile: Luau has no goto, one
-- function blew the 200-local limit, and several table SETLISTs were dropped.
-- Those are fixed, and the per-dungeon place ids from the old build are
-- replaced with dungeon-name dispatch (see the compat block below).
-- Diffed against the live game via its own remotes and client scripts.
local game6, value118
while true do
    if game:IsLoaded() then
        break
    end
    wait(0.1)
end
while not game.Players do
    wait(0.1)
end
-- The decompiler dropped this table's SETLIST, leaving tbl3 empty. Its four
-- slots are read back further down as:
--   tbl3[1] -> item4  (CollectionService: AddTag / GetTags / GetTagged)
--   tbl3[2] -> item3  (PathfindingService: CreatePath)
--   tbl3[3] -> item   (table.insert)
--   tbl3[4] -> item2  (table.remove)
local CollectionService = game:GetService("CollectionService")
local game2 = game
local tbl3 = {
    CollectionService,
    game2:GetService("PathfindingService"),
    table.insert,
    table.remove,
}
local humanoid2 = false
while true do
    if game.Players.LocalPlayer then
        break
    end
    wait(0.1)
end
repeat
    wait()
    game6 = game
until game6:IsLoaded()

local function fn(a)
    local ReplicatedStorage = game.ReplicatedStorage
    return ReplicatedStorage.remotes.reloadInvy:InvokeServer()
end

local function fn2()
    local tbl = {
        "q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "a", "s", "d", "f", "g", "h", "j", "k",
        "l", "z", "x", "c", "v", "b", "n", "m", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0",
        "X", "A", "B", "V", "R", "I", "O", "P", "L"
    }
    local ok = ""
    for i = 1, 16 do
        local value = ok
        local item = math.random(1, #tbl)
        item = tbl[item]
        ok = value .. item
    end
    return ok
end

local result3 = fn2()

local function fn3(a, b, c)
    -- Was an unbounded wait. Objects that no longer exist in this build
    -- (workspace.borders, workspace.Map) parked the calling thread forever, so
    -- the no-timeout form now caps out and returns nil for callers to handle.
    if c == nil then
        c = 20
    end
    local ok = 0
    while true do
        if a:FindFirstChild(b) or not (ok < c) then
            break
        end
        wait(0.1)
        ok = ok + 0.1
    end
    return a:FindFirstChild(b)
end

local function _(a, b)
    for k, v in pairs(b) do
        if a == v then
            return true
        end
    end
    return false
end

while true do
    if game.ReplicatedStorage:FindFirstChild("remotes") then
        break
    end
    wait(0.1)
end
while true do
    if game:FindFirstChild("Lighting") then
        break
    end
    wait(0.1)
end
while true do
    if game.Players.LocalPlayer:FindFirstChild("PlayerScripts") then
        break
    end
    wait(0.1)
end

function ScriptDebug(a)
    warn(a)
end

-- ============================================================================
-- 2025 re-release compatibility layer.
-- The old build shipped one Roblox place per dungeon; this build runs every
-- dungeon inside a single "Level" place and keys the map off workspace.dungeonName.
-- Ids come from ReplicatedStorage.Utility.PlaceManager (u1.Live).
-- ============================================================================
LOBBY_PLACE_ID = 77649408247578
LOBBY_100_PLACE_ID = 115445507767090
LEVEL_PLACE_ID = 85776757589518

local PlaceManager
do
    local ok = pcall(function()
        local Utility = game:GetService("ReplicatedStorage"):WaitForChild("Utility", 10)
        if Utility then
            PlaceManager = require(Utility:WaitForChild("PlaceManager", 10))
        end
    end)
    if not ok then
        PlaceManager = nil
    end
end

-- Defaults for the handful of _G values the script reads unconditionally.
-- Feature flags are deliberately left alone so nothing switches itself on.
if type(_G.wall_transparency) ~= "number" then
    _G.wall_transparency = 1
end
if type(_G.maxWaitTimeInLobby) ~= "number" then
    _G.maxWaitTimeInLobby = 15
end
-- Where to stand while attacking. "default" walks straight at the mob; "above"
-- and "below" park you off its hitbox on a hover pad; "behind" comes in from
-- its back. Anything past ~13 studs is out of weapon reach, so keep the offsets
-- small or you will hover there swinging at nothing.
if _G.attack_position == nil then
    _G.attack_position = "default"
end
if type(_G.attack_height) ~= "number" then
    -- Measured on a live weapon: the hit volume sits (0, 2.24, 1.24) from the
    -- root and is 7.14 long, so aimed at the target it reaches about 6 studs.
    -- The old default of 10 parked you past that - swinging, connecting with
    -- nothing.
    _G.attack_height = 4
end
if type(_G.attack_distance) ~= "number" then
    _G.attack_distance = 8
end
if _G.teleport_mode == nil then
    _G.teleport_mode = (_G.teleport_to_enemies == false) and "off" or "far"
end
if type(_G.teleport_min_distance) ~= "number" then
    -- 35 meant walking the last 35 studs of every approach, which is most of a
    -- room and much slower than the old behaviour of teleporting straight in.
    _G.teleport_min_distance = 20
end

function isLobbyPlace()
    return game.PlaceId == LOBBY_PLACE_ID or game.PlaceId == LOBBY_100_PLACE_ID
end

-- `notify` and `report` came from https://pastebin.com/raw/Ts8TSAZN, loaded at
-- the very end via HttpGetAsync + loadstring. That paste now 404s, so the load
-- threw (killing the tail) and every `report(...)` call from the anti-skid
-- handlers raised "attempt to call a nil value". Local implementations, defined
-- up front so the handlers connected further down resolve them.
function notify(a, b)
    local title, text = "Dungeon Quest", tostring(a)
    if b ~= nil then
        title, text = tostring(a), tostring(b)
    end
    warn("[" .. title .. "] " .. text)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 8,
        })
    end)
end

function report(a, b)
    warn("[" .. tostring(a) .. "] " .. tostring(b))
end

-- ============================================================================
-- Status panel.
-- The original narrated itself into the developer console every frame
-- ("Waiting for enemies...", "Thought: chase", bare prints of distances), which
-- floods F9. All of that now feeds this panel instead: callers just set a
-- string, and a 5 Hz heartbeat redraws only when something actually changed.
-- ============================================================================
farmStatus = {
    action = "starting up",
    target = "",
    dungeon = "",
    kills = 0,
    startedAt = tick(),
    startGold = nil,
}

-- Auto replay teleports you into a fresh server, which tears the script down and
-- takes the counters with it - and since the game only credits gold when a run
-- ends, the payout always landed after the panel was already gone. Keep the
-- session totals in a file so they carry across replays; a gap longer than half
-- an hour counts as a new session.
SESSION_FILE = "dq_autofarm_session.json"
local SESSION_GAP = 1800

function loadSession()
    if not (readfile and isfile) then
        return
    end
    local ok, data = pcall(function()
        if not isfile(SESSION_FILE) then
            return nil
        end
        return game:GetService("HttpService"):JSONDecode(readfile(SESSION_FILE))
    end)
    if not ok or type(data) ~= "table" then
        return
    end
    if type(data.stamp) ~= "number" or os.time() - data.stamp > SESSION_GAP then
        return
    end
    farmStatus.startGold = tonumber(data.startGold)
    farmStatus.kills = tonumber(data.kills) or 0
    farmStatus.sessionStart = tonumber(data.sessionStart)
end

function saveSession()
    if not writefile then
        return
    end
    pcall(function()
        writefile(SESSION_FILE, game:GetService("HttpService"):JSONEncode({
            startGold = farmStatus.startGold,
            kills = farmStatus.kills,
            sessionStart = farmStatus.sessionStart,
            stamp = os.time(),
        }))
    end)
end

loadSession()
if not farmStatus.sessionStart then
    farmStatus.sessionStart = os.time()
end

-- Gold is only credited at the end of a run, so this is the session total, not
-- a live counter. Baseline is taken once leaderstats exists.
function currentGold()
    local player = game:GetService("Players").LocalPlayer
    local leaderstats = player:FindFirstChild("leaderstats")
    local gold = leaderstats and leaderstats:FindFirstChild("Gold")
    return gold and gold.Value or nil
end

function goldEarned()
    local now = currentGold()
    if not now then
        return 0
    end
    if not farmStatus.startGold then
        farmStatus.startGold = now
        saveSession()
    end
    return now - farmStatus.startGold
end

function formatNumber(n)
    local text = tostring(math.floor(math.abs(n)))
    local grouped = text:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    return (n < 0 and "-" or "") .. grouped
end

-- Readable names for the AI's internal decisions.
farmActionNames = {
    chase = "chasing",
    chase_objective = "going to objective",
    chase_fobjective = "going to objective",
    strafe = "strafing",
    run = "backing off",
    dodge = "dodging",
    nothing = "idle",
}

function setAction(action, target)
    farmStatus.action = action or ""
    farmStatus.target = target or ""
end

-- ============================================================================
-- Interface (Radiance, vendored at dq-autofarm/Library.lua).
--
-- Every control's Flag is named after the _G key it drives, and its callback
-- writes straight back into _G - so the farm keeps reading _G exactly as it
-- always has, and a control moved in the menu takes effect on the next tick.
--
-- Load order matters: the settings block above the loadstring fills _G, the
-- controls are built with those values as their defaults, and then the saved
-- config is applied on top. That has to happen here, near the top, because the
-- rest of the script reads _G as it loads.
--
-- Menu key is Right Shift (rebindable on the settings page the library adds).
-- ============================================================================
LIBRARY_URL = "https://raw.githubusercontent.com/eduardonash/dq-autofarm/main/Library.lua"
UI_CONFIG_PATH = "Radiance/Configs/dq_autofarm.json"

local Library
do
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(LIBRARY_URL))()
    end)
    if ok then
        Library = result
    else
        -- The farm is the point; the menu is not. Carry on headless.
        warn("[DQ] UI library unavailable, running without a menu: " .. tostring(result))
    end
end

-- Applied by every control. Debounced so dragging a slider writes once, not
-- once per pixel.
local savePending = false
local function scheduleSave()
    if not (Library and writefile) or savePending then
        return
    end
    savePending = true
    spawn(function()
        wait(1)
        savePending = false
        pcall(function()
            if makefolder then
                if isfolder and not isfolder("Radiance") then
                    makefolder("Radiance")
                end
                if isfolder and not isfolder("Radiance/Configs") then
                    makefolder("Radiance/Configs")
                end
            end
            writefile(UI_CONFIG_PATH, Library:GetConfig())
        end)
    end)
end

-- Controls bind to _G by name. `transform` exists for the settings the script
-- wants as something other than the raw widget value.
local function bind(key, transform)
    return function(value)
        _G[key] = transform and transform(value) or value
        scheduleSave()
    end
end

if Library then
    local Window = Library:Window({
        Name = 'dungeon quest <font color="rgb(126, 192, 255)">autofarm</font>',
        Rank = "farm",
    })

    farmWatermark = Window:Watermark({
        Name = "dungeon quest autofarm",
        SubName = "loading",
    })

    local FarmPage = Window:Page({ Name = "farm" })
    local MovementPage = Window:Page({ Name = "movement" })
    local ItemsPage = Window:Page({ Name = "items" })
    local MiscPage = Window:Page({ Name = "misc" })

    do -- farm
        local dungeon = FarmPage:Section({ Name = "dungeon", Side = 1 })

        dungeon:Toggle({ Name = "auto join", Flag = "auto_join_dungeon",
            Default = _G.auto_join_dungeon or false, Callback = bind("auto_join_dungeon") })
        dungeon:Toggle({ Name = "pick for my level", Flag = "auto_choose_dungeon_and_difficulty",
            Default = _G.auto_choose_dungeon_and_difficulty or false,
            Callback = bind("auto_choose_dungeon_and_difficulty") })
        dungeon:Dropdown({ Name = "dungeon", Flag = "dungeon",
            Items = {
                "Desert Temple", "Winter Outpost", "Pirate Island", "King's Castle",
                "The Underworld", "Samurai Palace", "The Canals", "Ghastly Harbor",
                "Steampunk Sewers", "Orbital Outpost", "Volcanic Chambers", "Aquatic Temple",
                "Enchanted Forest", "Northern Lands", "Gilded Skies", "Oni Dungeon",
            },
            Multi = false, Default = _G.dungeon or "Desert Temple",
            Callback = bind("dungeon") })
        dungeon:Dropdown({ Name = "difficulty", Flag = "difficulty",
            Items = { "Easy", "Medium", "Hard", "Insane", "Nightmare" },
            Multi = false, Default = _G.difficulty or "Nightmare",
            Callback = bind("difficulty") })
        dungeon:Toggle({ Name = "hardcore", Flag = "hardcore",
            Default = _G.hardcore or false, Callback = bind("hardcore") })
        dungeon:Toggle({ Name = "wave defence", Flag = "wavedefense",
            Default = _G.wavedefense or false, Callback = bind("wavedefense") })
        dungeon:Toggle({ Name = "auto replay", Flag = "auto_replay",
            Default = _G.auto_replay or false, Callback = bind("auto_replay") })
        dungeon:Slider({ Name = "replay delay", Flag = "auto_replay_delay",
            Min = 0, Max = 15, Default = _G.auto_replay_delay or 3, Decimals = 1, Suffix = "s",
            Callback = bind("auto_replay_delay") })

        local combat = FarmPage:Section({ Name = "combat", Side = 2 })

        combat:Toggle({ Name = "auto attack", Flag = "auto_attack",
            Default = _G.auto_attack ~= false, Callback = bind("auto_attack") })
        combat:Dropdown({ Name = "stand", Flag = "attack_position",
            Items = { "default", "above", "below", "behind" }, Multi = false,
            Default = _G.attack_position or "default", Callback = bind("attack_position") })
        combat:Slider({ Name = "height offset", Flag = "attack_height",
            Min = 1, Max = 6, Default = _G.attack_height or 4, Decimals = 0.5, Suffix = "st",
            Callback = bind("attack_height") })
        combat:Slider({ Name = "attack distance", Flag = "attack_distance",
            Min = 1, Max = 13, Default = _G.attack_distance or 8, Decimals = 1, Suffix = "st",
            Callback = bind("attack_distance") })
        combat:Toggle({ Name = "instakill", Flag = "doInstakill",
            Default = _G.doInstakill or false, Callback = bind("doInstakill") })
        combat:Toggle({ Name = "ignore ability range", Flag = "ignoreAbilityRange",
            Default = _G.ignoreAbilityRange or false, Callback = bind("ignoreAbilityRange") })
        combat:Toggle({ Name = "optimize mobs", Flag = "optimize_mobs",
            Default = _G.optimize_mobs or false, Callback = bind("optimize_mobs") })
    end

    do -- movement
        local teleport = MovementPage:Section({ Name = "teleport", Side = 1 })

        teleport:Dropdown({ Name = "mode", Flag = "teleport_mode",
            Items = { "off", "far", "always" }, Multi = false,
            Default = _G.teleport_mode or "far", Callback = bind("teleport_mode") })
        teleport:Slider({ Name = "teleport past", Flag = "teleport_min_distance",
            Min = 10, Max = 200, Default = _G.teleport_min_distance or 20, Decimals = 1, Suffix = "st",
            Callback = bind("teleport_min_distance") })
        teleport:Slider({ Name = "studs per hop", Flag = "teleport_step",
            Min = 5, Max = 100, Default = _G.teleport_step or 40, Decimals = 1, Suffix = "st",
            Callback = bind("teleport_step") })
        teleport:Slider({ Name = "seconds per hop", Flag = "teleport_interval",
            Min = 0.05, Max = 1, Default = _G.teleport_interval or 0.15, Decimals = 0.01, Suffix = "s",
            Callback = bind("teleport_interval") })

        local dodge = MovementPage:Section({ Name = "dodge", Side = 2 })

        dodge:Toggle({ Name = "short dodge hops", Flag = "SemiTeleports",
            Default = _G.SemiTeleports or false, Callback = bind("SemiTeleports") })
        dodge:Toggle({ Name = "hops on boss only", Flag = "teleportDuringBossOnly",
            Default = _G.teleportDuringBossOnly or false, Callback = bind("teleportDuringBossOnly") })
    end

    do -- items
        local selling = ItemsPage:Section({ Name = "selling", Side = 1 })

        selling:Toggle({ Name = "autosell", Flag = "autosell",
            Default = _G.autosell or false, Callback = bind("autosell") })
        selling:Toggle({ Name = "dry run", Flag = "testSell",
            Default = _G.testSell or false, Callback = bind("testSell") })
        selling:Slider({ Name = "keep above level", Flag = "keep_items_level_requirement",
            Min = 0, Max = 200, Default = _G.keep_items_level_requirement or 156, Decimals = 1,
            Callback = bind("keep_items_level_requirement") })
        selling:Toggle({ Name = "keep 2 spells", Flag = "keep2spells",
            Default = _G.keep2spells or false, Callback = bind("keep2spells") })

        local gear = ItemsPage:Section({ Name = "gear", Side = 2 })

        gear:Toggle({ Name = "auto equip gear", Flag = "auto_equip_gear",
            Default = _G.auto_equip_gear or false, Callback = bind("auto_equip_gear") })
        gear:Dropdown({ Name = "equip type", Flag = "equip_type",
            Items = { "physical", "spell" }, Multi = false,
            Default = _G.equip_type or "physical", Callback = bind("equip_type") })
        gear:Toggle({ Name = "auto upgrade", Flag = "auto_upgrade_equip",
            Default = _G.auto_upgrade_equip or false, Callback = bind("auto_upgrade_equip") })
        gear:Toggle({ Name = "auto equip spell", Flag = "autoEquipSpell",
            Default = _G.autoEquipSpell or false, Callback = bind("autoEquipSpell") })
        gear:Dropdown({ Name = "spell type", Flag = "spellType",
            Items = { "physical", "spell" }, Multi = false,
            Default = _G.spellType or "spell", Callback = bind("spellType") })
        gear:Toggle({ Name = "auto spend points", Flag = "auto_stat_upgrade",
            Default = _G.auto_stat_upgrade or false, Callback = bind("auto_stat_upgrade") })
        gear:Dropdown({ Name = "stat", Flag = "stat",
            Items = { "physicalPower", "spellPower", "stamina" }, Multi = false,
            Default = _G.stat or "physicalPower", Callback = bind("stat") })
    end

    do -- misc
        local performance = MiscPage:Section({ Name = "performance", Side = 1 })

        performance:Toggle({ Name = "fps boost", Flag = "fpsBoost",
            Default = _G.fpsBoost or false, Callback = function(value)
                _G.fpsBoost = value
                scheduleSave()
                -- One-shot by nature: switching it on has to re-run the pass.
                if value and fpsBoost then
                    spawn(fpsBoost)
                end
            end })
        performance:Toggle({ Name = "strip map decoration", Flag = "destroy_map",
            Default = _G.destroy_map or false, Callback = bind("destroy_map") })
        performance:Toggle({ Name = "hide projectiles", Flag = "hide_projectiles",
            Default = _G.hide_projectiles or false, Callback = bind("hide_projectiles") })
        performance:Toggle({ Name = "delete armor models", Flag = "del_armor",
            Default = _G.del_armor or false, Callback = bind("del_armor") })
        performance:Toggle({ Name = "delete weapon models", Flag = "del_weapon",
            Default = _G.del_weapon or false, Callback = bind("del_weapon") })
        performance:Slider({ Name = "wall transparency", Flag = "wall_transparency",
            Min = 0, Max = 1, Default = _G.wall_transparency or 1, Decimals = 0.05,
            Callback = function(value)
                _G.wall_transparency = value
                scheduleSave()
                -- Retint the walls already standing, not just future ones.
                pcall(function()
                    for _, part in ipairs(workspace:GetChildren()) do
                        if part:IsA("BasePart") and part.Name == result3 then
                            part.Transparency = value
                        end
                    end
                end)
            end })
        performance:Toggle({ Name = "build walls slowly", Flag = "loadSlow",
            Default = _G.loadSlow or false, Callback = bind("loadSlow") })
        performance:Toggle({ Name = "think every frame", Flag = "extremelyFast",
            Default = _G.extremelyFast or false, Callback = bind("extremelyFast") })

        local raid = MiscPage:Section({ Name = "boss raid", Side = 2 })

        raid:Toggle({ Name = "boss raid", Flag = "boss_raid",
            Default = _G.boss_raid or false, Callback = bind("boss_raid") })
        raid:Toggle({ Name = "pick highest tier", Flag = "auto_choose_raid_boss_tier",
            Default = _G.auto_choose_raid_boss_tier or false,
            Callback = bind("auto_choose_raid_boss_tier") })
        raid:Slider({ Name = "tier", Flag = "boss_raid_tier",
            Min = 1, Max = 12, Default = _G.boss_raid_tier or 1, Decimals = 1,
            Callback = bind("boss_raid_tier") })

        local webhook = MiscPage:Section({ Name = "webhook", Side = 2 })

        webhook:Toggle({ Name = "enabled", Flag = "webhookEnabled",
            Default = _G.webhookEnabled or false, Callback = bind("webhookEnabled") })
        webhook:Textbox({ Name = "url", Flag = "webhookLink",
            Numeric = false, Finished = true, Placeholder = "discord webhook",
            Default = _G.webhookLink or "",
            Callback = bind("webhookLink", function(value)
                return value ~= "" and value or nil
            end) })
    end

    Window:InitWindow()

    -- Saved settings win over the block above the loadstring. LoadConfig drives
    -- the library's own SetFlags, which fire the callbacks above, so this also
    -- writes every value back into _G.
    if isfile and readfile and isfile(UI_CONFIG_PATH) then
        local ok, err = pcall(function()
            Library:LoadConfig(readfile(UI_CONFIG_PATH))
        end)
        if not ok then
            warn("[DQ] could not load saved config: " .. tostring(err))
        end
    end
end

-- Status: current action on the watermark, running totals underneath.
spawn(function()
    local CollectionService = game:GetService("CollectionService")
    local lastText, lastSub, saveTick = nil, nil, 0
    while true do
        local elapsed = os.time() - (farmStatus.sessionStart or os.time())
        local earned = goldEarned()
        local text = farmStatus.action
        if farmStatus.target ~= "" then
            text = text .. " " .. farmStatus.target
        end
        if farmStatus.dungeon ~= "" then
            text = farmStatus.dungeon .. "  |  " .. text
        end
        local sub = string.format(
            "%d alive  |  %d killed  |  %s%s gold  |  %02d:%02d",
            #CollectionService:GetTagged("Enemy"),
            farmStatus.kills,
            earned >= 0 and "+" or "",
            formatNumber(earned),
            math.floor(elapsed / 60),
            elapsed % 60
        )
        if farmWatermark then
            if text ~= lastText then
                pcall(function() farmWatermark:SetText(text) end)
                lastText = text
            end
            if sub ~= lastSub then
                pcall(function() farmWatermark:SetSubText(sub) end)
                lastSub = sub
            end
        end
        saveTick = saveTick + 1
        if saveTick % 25 == 0 then
            saveSession()
        end
        wait(0.2)
    end
end)

-- ============================================================================
-- Auto replay.
-- Mirrors the game's own "Replay Dungeon?" YES button: build the same payload
-- its collectDungeonData() builds, then fire remotes.replayDungeon. Only the
-- dungeon owner may replay - the server ignores the request from anyone else.
-- The server answers by teleporting the party into a fresh reserved server, so
-- the script has to run again there: put the loadstring in your autoexec.
-- ============================================================================
function collectDungeonData()
    local data = {}
    local function copyValue(name, key)
        local object = workspace:FindFirstChild(name)
        if object and object:IsA("ValueBase") then
            data[key or name] = object.Value
        end
    end
    copyValue("dungeonName")
    copyValue("dungeonProgress")
    copyValue("dungeonStarted")
    copyValue("hardcore")
    copyValue("hardcore", "isHardcore")

    local dungeon = workspace:FindFirstChild("dungeon")
    if dungeon then
        for _, child in ipairs(dungeon:GetChildren()) do
            if child:IsA("ValueBase") then
                data[child.Name] = child.Value
            end
        end
        local bossRoom = dungeon:FindFirstChild("bossRoom")
        if bossRoom then
            for _, child in ipairs(bossRoom:GetChildren()) do
                if child:IsA("ValueBase") then
                    data[child.Name] = child.Value
                end
            end
        end
    end
    return data
end

function autoReplay()
    if not _G.auto_replay then
        return
    end
    local data = collectDungeonData()
    if not data.dungeonName then
        ScriptDebug("[replay] no dungeonName to replay with")
        return
    end
    setAction("replaying " .. tostring(data.dungeonName), "")
    wait(_G.auto_replay_delay or 3)
    local ok = pcall(function()
        game:GetService("ReplicatedStorage").remotes.replayDungeon:FireServer(data)
    end)
    if not ok then
        ScriptDebug("[replay] replayDungeon call failed")
    end
end

-- ============================================================================
-- Teleporting.
-- Hops toward a destination in short steps instead of one long jump, and only
-- lands where there is actually floor - a straight-line jump across a dungeon
-- drops you through the map. Falls back to walking (returns false) whenever it
-- cannot find ground, so movement degrades instead of breaking.
-- ============================================================================
local lastTeleportAt = 0
local hoverPad = nil

-- Standing above or below a mob means there is no floor to land on, so the
-- teleporter carries its own: one invisible anchored pad kept under your feet.
local function ensureHoverPad(position)
    if not hoverPad or not hoverPad.Parent then
        hoverPad = Instance.new("Part")
        hoverPad.Name = "dqHoverPad"
        hoverPad.Size = Vector3.new(8, 1, 8)
        hoverPad.Anchored = true
        hoverPad.CanCollide = true
        hoverPad.Transparency = 1
        hoverPad.Parent = workspace
        pcall(function()
            game:GetService("CollectionService"):AddTag(hoverPad, "RayIgnore")
        end)
    end
    hoverPad.Position = position - Vector3.new(0, 3.5, 0)
end

function clearHoverPad()
    if hoverPad then
        hoverPad:Destroy()
        hoverPad = nil
    end
end

-- Where to stand relative to the enemy, per _G.attack_position.
-- Returns the position plus whether it needs a hover pad to stand on.
function attackAnchor(model)
    local root = enemyRoot(model)
    if not root then
        return nil, false
    end
    local position = root.Position
    local mode = _G.attack_position or "default"
    local height = tonumber(_G.attack_height) or 10
    if mode == "above" then
        return position + Vector3.new(0, height, 0), true
    elseif mode == "below" then
        return position - Vector3.new(0, height, 0), true
    elseif mode == "behind" then
        local distance = tonumber(_G.attack_distance) or 8
        return position - root.CFrame.LookVector * distance, false
    end
    return position, false
end

-- above/below put you off the mob's own level, which you cannot walk to and
-- cannot hit without tipping the rig towards it.
function attackModeIsOffset()
    local mode = _G.attack_position
    return mode == "above" or mode == "below"
end

-- Held every tick while hovering: the Humanoid keeps trying to right itself, so
-- the pitch has to be re-applied rather than set once.
function holdAimAt(model)
    local character = game:GetService("Players").LocalPlayer.Character
    local root = enemyRoot(model)
    if not (character and root) then
        return
    end
    charLookAt(character, root, true)
end

-- Teleport is a mode, not a switch:
--   "off"    never teleport, walk everything
--   "far"    only close distance with it - past teleport_min_distance, which is
--            room-to-room range. Inside that you walk, which looks far better
--            and is what the melee approach was tuned for.
--   "always" teleport the whole way in
function shouldTeleportTo(model)
    local mode = _G.teleport_mode
    if mode == nil then
        -- Back-compat with the old boolean.
        mode = (_G.teleport_to_enemies == false) and "off" or "far"
    end
    if mode == "off" then
        return false
    end
    local root = enemyRoot(model)
    local character = game:GetService("Players").LocalPlayer.Character
    local here = character and character:FindFirstChild("HumanoidRootPart")
    if not (root and here) then
        return false
    end
    if mode == "always" then
        return true
    end
    return (root.Position - here.Position).Magnitude > (tonumber(_G.teleport_min_distance) or 35)
end

function teleportToward(destination, stopDistance, hover)
    if not destination then
        return false
    end
    local character = game:GetService("Players").LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        return false
    end
    stopDistance = stopDistance or 10
    local from = root.Position
    local delta = destination - from
    local distance = delta.Magnitude
    if distance <= stopDistance then
        if hover then
            -- Already in position. Hold the pad and report the move as handled -
            -- returning false here handed the frame to the walker, which walked
            -- straight off the pad and back down to the floor.
            ensureHoverPad(root.Position)
            return true
        end
        return false
    end
    local now = tick()
    if now - lastTeleportAt < (_G.teleport_interval or 0.15) then
        -- Rate limited, but still the teleporter's turn: hold position rather
        -- than handing the frame back to the walker and fighting over it.
        return true
    end

    local step = math.min(_G.teleport_step or 40, distance - stopDistance)
    local goal = from + delta.Unit * step
    local landing

    if hover then
        landing = goal
        ensureHoverPad(landing)
    else
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = { character, hoverPad }
        local ground = workspace:Raycast(goal + Vector3.new(0, 12, 0), Vector3.new(0, -60, 0), params)
        if not ground then
            return false
        end
        landing = ground.Position + Vector3.new(0, 3, 0)
    end

    lastTeleportAt = now
    local velocity = root.AssemblyLinearVelocity
    root.CFrame = CFrame.new(landing, Vector3.new(destination.X, landing.Y, destination.Z))
    root.AssemblyLinearVelocity = velocity
    return true
end

-- The old build let its own server scripts CollectionService-tag every enemy,
-- and this script blocked until those tags appeared before adding its "Enemy"
-- tag. This build tags nothing (GetTags on a live Sand Peasant returns {}), so
-- the wait never ended and no enemy was ever registered - the farm loop just
-- printed "Waiting for enemies..." forever. Now it is a bounded wait: give the
-- game a moment to finish setting the model up, then proceed regardless.
-- Client-side Health writes only reach the server while this client owns the
-- enemy's assembly. The old one-shot write also raced the enemy's own initial
-- health replication, so even when ownership held it could be overwritten a
-- frame later. Retry briefly, then confirm the enemy actually died: if the model
-- is still sitting there afterwards the kill never replicated, and we say so
-- once instead of silently desyncing the farm's view of what is alive.
local instakillConfirmed = nil
local instakillProbeClaimed = false

-- Instakill only works if this client owns the enemy's assembly, so that a
-- client-side Health write replicates. It does not in this build.
--
-- The previous probe asked the wrong question. It only concluded "did not
-- replicate" when it saw Health climb back above zero - but the server never
-- sends a correction, because from its side nothing happened. The local value
-- just stayed at the zero we wrote, so the probe fell through, released its
-- claim, and re-probed on the next enemy forever, zeroing the whole room's
-- health client-side while never reaching a verdict. The farm was then swinging
-- at mobs it believed were already dead.
--
-- The model still existing afterwards is the real signal: an enemy that dies
-- gets removed. So exactly one enemy is ever touched until that is settled.
function tryInstakill(model)
    if instakillConfirmed == false then
        return
    end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return
    end

    if instakillConfirmed == nil then
        if instakillProbeClaimed then
            -- Untested: leave every other enemy's health alone.
            return
        end
        instakillProbeClaimed = true
        spawn(function()
            humanoid.Health = 0
            wait(2.5)
            if model.Parent == nil then
                instakillConfirmed = true
                ScriptDebug("[instakill] replicates - enabled")
            else
                instakillConfirmed = false
                _G.doInstakill = false
                notify("Instakill unavailable",
                    "The server keeps ownership of enemies here, so client-side kills do not replicate. Turned off - leaving it on desyncs the health the farm reads.")
            end
        end)
        return
    end

    -- Only reached once the probe proved it works.
    humanoid.Health = 0
end

function waitForEnemyTags(model, minTags, timeout)
    local CollectionService = game:GetService("CollectionService")
    local waited = 0
    timeout = timeout or 1.5
    while #CollectionService:GetTags(model) < minTags and waited < timeout do
        wait(0.1)
        waited = waited + 0.1
    end
    return waited < timeout
end

-- Enemy models stream in piece by piece and are torn down the moment they die,
-- so their root can be missing at either end of their life. Everything that
-- aims at an enemy goes through this instead of indexing .HumanoidRootPart.
function enemyRoot(model)
    if not model or not model.Parent then
        return nil
    end
    return model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
end

-- Injecting before the character exists used to abort the whole chunk on the
-- first `LocalPlayer.Character.Humanoid` access.
function waitForCharacter()
    local player = game:GetService("Players").LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    character:WaitForChild("Humanoid", 30)
    character:WaitForChild("HumanoidRootPart", 30)
    return character
end

-- Name of the dungeon this server is running, or nil in the lobby.
function currentDungeonName()
    local value = workspace:FindFirstChild("dungeonName")
    if value and value:IsA("StringValue") and value.Value ~= "" then
        return value.Value
    end
    if PlaceManager and PlaceManager.GetDungeonName then
        local ok, name = pcall(PlaceManager.GetDungeonName)
        if ok and name and name ~= "" then
            return name
        end
    end
    return nil
end

-- workspace.currentWave now exists in every dungeon server (0 when unused), so
-- wave defence is detected through the game's own teleport data.
function isWaveDefensePlace()
    if PlaceManager and PlaceManager.IsWaveDefense then
        local ok, isWave = pcall(PlaceManager.IsWaveDefense)
        if ok and isWave then
            return true
        end
    end
    local wave = workspace:FindFirstChild("currentWave")
    return wave ~= nil and wave:IsA("IntValue") and wave.Value > 0
end

function isBossRaidPlace()
    if PlaceManager and PlaceManager.IsBossKey then
        local ok, isKey = pcall(PlaceManager.IsBossKey)
        if ok and isKey then
            return true
        end
    end
    local tier = workspace:FindFirstChild("tier")
    return tier ~= nil and tier:IsA("IntValue") and tier.Value > 0
end

local Players3 = game:GetService("Players")
-- `extremelyFast` used to be captured here, so the menu could never change it.
-- It is a live _G read at each use site now.
local _, value13, value14, value15, value16, value17, item, item2, ok8, humanoid, ok10, ok = Players3.LocalPlayer, 1, 15, 2, 5, 31, tbl3[3], tbl3[4], false, true, false, false
local ok11 = humanoid2 and 0.5 or value13
local ok2, ok3 = false, false
-- These were unconditional assignments, which silently overrode whatever the
-- config block above the loadstring had set. Defaults only now.
if _G.auto_attack == nil then
    _G.auto_attack = true
end
if type(_G.smallTeleportVal) ~= "number" then
    _G.smallTeleportVal = 100
end
local tbl4 = {
    ["Sand Peasant"] = true, ["Sand Giant"] = true, ["Frost Minion"] = true, ["Frost Wizard"] = true,
    ["Pirate Rifleman"] = true, ["Pirate Savage"] = true, Elementalist = true,
    ["King's Guard"] = true, ["Dark Mage"] = true, ["Demon Warrior"] = true,
    ["Samurai Swordsman"] = true, Bodyguard = true, ["Burly Enforcer"] = true, Raider = true,
    ["Harpoon Gunner"] = true, ["Cannon Crab"] = true, ["Spinner Bot"] = true,
    ["Fighter Bot"] = true, ["Cog Shooter"] = true, ["Hammer Bot"] = true,
    ["Hologram Assassin"] = true, ["Hologram Warrior"] = true, ["Chicken Mage"] = true,
    ["Chicken Brawler"] = true
}
local part = game:service("VirtualUser")
local LocalPlayer = game:service("Players")
LocalPlayer = LocalPlayer.LocalPlayer
LocalPlayer.Idled:connect(function()
    part:CaptureController()
    part:ClickButton2(Vector2.new())
end)
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer2 = game:GetService("Players")
LocalPlayer2 = LocalPlayer2.LocalPlayer
LocalPlayer2.Idled:connect(function()
    local value = VirtualUser
    local Button2Down = value.Button2Down
    local Vector22 = Vector2.new(0, 0)
    local CurrentCamera = workspace.CurrentCamera
    Button2Down(value, Vector22, CurrentCamera.CFrame)
    wait(1)
    local value2 = VirtualUser
    local Button2Up = value2.Button2Up
    Vector22 = Vector2
    Button2Up(value2, Vector22.new(0, 0), workspace.CurrentCamera.CFrame)
end)

function AIMovementInLobby()
    local ok2, ok = 0, false
    _G.ai_done = false
    -- A nil value here threw inside the wait loop below, so ai_done never
    -- flipped and the "JOINING DUNGEON" wait never returned.
    if type(_G.maxWaitTimeInLobby) ~= "number" then
        _G.maxWaitTimeInLobby = 15
    end
    local Character = waitForCharacter()
    local Humanoid = Character.Humanoid
    spawn(function()
        local PathfindingService = game:GetService("PathfindingService")
        -- The decompiler dropped every SETLIST in this function, leaving `tbl`
        -- and each route empty; `math.random(1, #tbl)` then threw "interval is
        -- empty" and _G.ai_done was never set, hanging the join loop.
        -- Routes rebuilt from the Vector3 literals the decompiler did keep.
        -- NOTE: these are lobby coordinates from the pre-2025 lobby place.
        -- Set _G.lobby_ai_waypoints to your own {{Vector3, ...}, ...} to override.
        local V = Vector3.new
        local tbl = _G.lobby_ai_waypoints or {
            { V(29.4448986, 10.6809521, 1005.28198) },
            { V(120.158272, 5.05413818, 1005.26672) },
            { V(145.121567, 4.79999876, 1028.203) },
            { V(138.910416, 4.85120726, 1080.46936) },
            { V(50.0033913, 5.40119982, 1025.59448) },
            { V(56.9857826, 5.10824966, 1066.79846) },
            { V(8.27422428, 4.80000019, 1034.32092), V(-36.9196014, 4.80000019, 1022.45972), V(-93.4016876, 5.84888077, 1107.07776) },
            { V(8.27422428, 4.80000019, 1034.32092), V(-36.9196014, 4.80000019, 1022.45972) },
            { V(104.851845, 4.80013657, 1029.08655), V(66.5649185, 11.1366758, 981.947205) },
            { V(106.917046, 5.1029253, 1033.20129), V(126.421371, 4.80742407, 1017.41754) },
            { V(37.6123543, 5.1142168, 1041.55664), V(8.08811092, 11.3835154, 1087.04956) },
            { V(74.2765732, 4.79785824, 1034.74109), V(59.2142448, 5, 1081.58557) },
            { V(75.4334259, 5.07404947, 1048.54626), V(59.5415268, 9.24949932, 1002.75214) },
            { V(86.8510361, 4.95114946, 1012.60217), V(78.8645248, 5.21786928, 1063.84338) },
            { V(85.5781631, 5.19999838, 1044.32336), V(7.32494354, 4.79999876, 1031.84668) },
            { V(116.443657, 5.34364605, 1031.54187), V(136.55043, 4.80000019, 1068.89758) },
            { V(136.55043, 4.80000019, 1068.89758), V(96.5291367, 5.04907751, 1055.71301) },
            { V(84.3650131, 4.95895767, 1011.05023), V(28.3323727, 5.77999735, 1021.42993) },
        }
        if #tbl == 0 then
            ok = true
            return
        end
        local pairs2 = pairs
        local item2 = math.random(1, #tbl)
        item2 = tbl[item2]
        for k3, v3 in pairs2(item2) do
            local result3 = PathfindingService:CreatePath()
            result3:ComputeAsync(Character.HumanoidRootPart.Position, v3)
            local Players3 = result3:GetWaypoints()
            local tbl24 = {}
            local ok2 = 0
            for k, v in pairs(Players3) do
                if _G.ai_done then
                    break
                end
                ok2 = ok2 + 0.5
                local part = Instance.new("Part")
                part.Shape = "Ball"
                part.Material = "Neon"
                local math2 = Color3.new(1, 120, 1)
                part.Color = math2
                math2 = math
                local ok3 = math2.sin(ok2) + 1.5
                local ok4 = ok3 / 2
                local Position = Vector3.new(ok4, ok4, ok4)
                part.Size = Position
                Position = v.Position
                part.Position = Position
                part.Anchored = true
                part.CanCollide = false
                part.Parent = game.Workspace
                item(tbl24, part)
            end
            for k2, v2 in pairs(Players3) do
                if _G.ai_done then
                    break
                end
                local item3 = tbl24[k2]
                local VirtualUser = BrickColor.new("Bright blue")
                item3.BrickColor = VirtualUser
                VirtualUser = Humanoid
                VirtualUser:MoveTo(v2.Position)
                Humanoid.MoveToFinished:Wait()
                local item4 = tbl24[k2]
                local LocalPlayer4 = BrickColor.new("Fire Yellow")
                item4.BrickColor = LocalPlayer4
            end
        end
        ok = true
    end)
    while not ok and not (_G.maxWaitTimeInLobby < ok2) do
        ok2 = ok2 + 0.1
        wait(0.1)
    end
    _G.ai_done = true
    Humanoid:MoveTo(Character.HumanoidRootPart.Position)
end

function autoupgrade()
    if _G.auto_stat_upgrade and game.Players.LocalPlayer.skillPoints.Value > 0 then
        -- spendSkillPoint now takes (statName, amount); the old one-argument
        -- call left amount nil. Valid stats: physicalPower, spellPower, stamina.
        local stat = _G.stat
        if stat ~= "physicalPower" and stat ~= "spellPower" and stat ~= "stamina" then
            ScriptDebug("[compat] _G.stat is " .. tostring(stat) .. "; expected physicalPower, spellPower or stamina")
            return
        end
        while true do
            if not (game.Players.LocalPlayer.skillPoints.Value > 0) then
                break
            end
            local remotes = game:GetService("ReplicatedStorage")
            remotes = remotes.remotes
            remotes.spendSkillPoint:FireServer(stat, 1)
            wait()
        end
    end
end

function getItemType(a, b)
    if a.health == nil then
        if a.spellPower < a.physicalDamage then
            return "physical"
        end
        return "mage"
    end
    local spellPower = a.spellPower
    if a.physicalPower < spellPower then
        if b then
            local spellPower2 = a.spellPower
            if a.health < spellPower2 then
                return "mage"
            end
            return "guardian"
        end
        return "mage"
    end
    if b then
        local physicalPower = a.physicalPower
        if a.health < physicalPower then
            return "physical"
        end
        return "guardian"
    end
    return "physical"
end

function lobbyStrCheck(a, b)
    local PathfindingService = string.lower(a)
    local result2 = string.lower(b)
    PathfindingService = string.gsub(PathfindingService, "'", "")
    result2 = string.gsub(result2, "'", "")
    return string.gsub(PathfindingService, "s", "") == string.gsub(result2, "s", "")
end

function checkSell(a, b)
    for k2, v2 in pairs(_G.itemlist) do
        if lobbyStrCheck(k2, b) then
            for k, v in pairs(v2) do
                if a == v then
                    return false
                end
            end
        end
    end
    return not _G.keeprarities[a]
end

local function fn4()
    if _G.autosell then
        local tbl = {}
        local _, _ = nil, nil
        local LocalPlayer4 = fn(game.Players.LocalPlayer)
        for k3, v3 in pairs(LocalPlayer4) do
            local PathfindingService = fn(game.Players.LocalPlayer)
            if k3 == "weapons" or k3 == "chests" or k3 == "helmets" then
                for k, v in pairs(v3) do
                    local result2 = getItemType(v, false)
                    local keep_items_from_clas = _G.keep_items_from_class[result2]
                    local ok = not keep_items_from_clas
                    if not v.equipped
                        and checkSell(v.rarity, v.name)
                        and v.levelReq < _G.keep_items_level_requirement
                        and ok then
                        if k3 == "weapons" then
                            if _G.testSell then
                                print("MROBSWAG Selling: ", v.name)
                            else
                                local remotes3 = game:GetService("ReplicatedStorage")
                                remotes3 = remotes3.remotes
                                local sellItemEvent3 = remotes3.sellItemEvent
                                local FireServer3 = sellItemEvent3.FireServer
                                local tbl6 = {}
                                tbl6.ability = {}
                                tbl6.helmet = {}
                                tbl6.chest = {}
                                local tbl7 = {}
                                local part = tonumber(string.sub(k, 8))
                                tbl7[1] = part
                                tbl6.weapon = tbl7
                                FireServer3(sellItemEvent3, tbl6)
                            end
                        elseif k3 == "chests" then
                            if _G.testSell then
                                print("MROBSWAG Selling: ", v.name)
                            else
                                local remotes2 = game:GetService("ReplicatedStorage")
                                remotes2 = remotes2.remotes
                                local sellItemEvent2 = remotes2.sellItemEvent
                                local FireServer2 = sellItemEvent2.FireServer
                                local tbl4 = {}
                                tbl4.ability = {}
                                tbl4.helmet = {}
                                local tbl5 = {}
                                local Players3 = tonumber(string.sub(k, 7))
                                tbl5[1] = Players3
                                tbl4.chest = tbl5
                                tbl4.weapon = {}
                                FireServer2(sellItemEvent2, tbl4)
                            end
                        elseif k3 == "helmets" then
                            if _G.testSell then
                                print("MROBSWAG Selling: ", v.name)
                            else
                                local remotes = game:GetService("ReplicatedStorage")
                                remotes = remotes.remotes
                                local sellItemEvent = remotes.sellItemEvent
                                local FireServer = sellItemEvent.FireServer
                                local tbl2 = {}
                                tbl2.ability = {}
                                local tbl3 = {}
                                local result3 = tonumber(string.sub(k, 8))
                                tbl3[1] = result3
                                tbl2.helmet = tbl3
                                tbl2.chest = {}
                                tbl2.weapon = {}
                                FireServer(sellItemEvent, tbl2)
                            end
                        end
                    end
                end
            end
            if k3 == "abilities" then
                for k2, v2 in pairs(PathfindingService.abilities) do
                    if tbl[v2.name] then
                        tbl[v2.name] = tbl[v2.name] + 1
                    else
                        tbl[v2.name] = 1
                    end
                    if not v2.equipped.q and not v2.equipped.e then
                        if (not checkSell(v2.rarity, v2.name)
                            or not (v2.levelReq < _G.keep_items_level_requirement))
                            and tbl[v2.name] > 2
                            and _G.keep2spells then

                        end
                        if _G.testSell then
                            print("MROBSWAG Selling: ", v2.name)
                        else
                            local remotes4 = game:GetService("ReplicatedStorage")
                            remotes4 = remotes4.remotes
                            local sellItemEvent4 = remotes4.sellItemEvent
                            local FireServer4 = sellItemEvent4.FireServer
                            local tbl8 = {}
                            local LocalPlayer8 = {}
                            local VirtualUser = tonumber(string.sub(k2, 9))
                            LocalPlayer8[1] = VirtualUser
                            tbl8.ability = LocalPlayer8
                            tbl8.helmet = {}
                            tbl8.chest = {}
                            tbl8.weapon = {}
                            FireServer4(sellItemEvent4, tbl8)
                        end
                    end
                end
            end
        end
    end
end

local function fn5(a, b)
    local value2, ok = b, a
    for i = 1, value2 do
        local ok2 = ok * 0.05
        local ok3 = ok2 > 10 and 10 or ok2
        ok = ok + ok3
    end
    return math.floor(ok)
end

local function fn6(a, b)
    local ok, value = 0, 100
    for i = 1, a do
        local ok2
        if i > 1 then
            if 1.06 * value + 50 - value > 220 then
                ok2 = value + 220
            else
                ok2 = 1.06 * value + 50
            end
        else
            ok2 = value
        end
        if b < i then
            if i <= 466 then
                ok = ok + ok2
            else
                ok = ok + 100000
                ok2 = 100000
            end
        end
        value = ok2
    end
    return ok
end

function autoUpgradeEquip(a)
    if _G.auto_upgrade_equip then
        local PathfindingService = fn(game.Players.LocalPlayer)
        if a == "chests" then
            for k, v in pairs(PathfindingService.chests) do
                local ok3 = v.maxUpgrades - v.currentUpgrade
                if v.equipped and ok3 ~= 0 then
                    local spellPower = v.spellPower
                    if v.physicalPower < spellPower then
                        local remotes6 = game:GetService("ReplicatedStorage")
                        remotes6 = remotes6.remotes
                        local upgradeItem6 = remotes6.upgradeItem
                        upgradeItem6.FireServer(upgradeItem6, "chest", tonumber(string.sub(k, 7)), "spell", ok3)
                    else
                        local remotes5 = game:GetService("ReplicatedStorage")
                        remotes5 = remotes5.remotes
                        local upgradeItem5 = remotes5.upgradeItem
                        upgradeItem5.FireServer(upgradeItem5, "chest", tonumber(string.sub(k, 7)), "physical", ok3)
                    end
                end
            end
        elseif a == "helmets" then
            for k2, v2 in pairs(PathfindingService.helmets) do
                local ok2 = v2.maxUpgrades - v2.currentUpgrade
                if v2.equipped and ok2 ~= 0 then
                    local spellPower2 = v2.spellPower
                    if v2.physicalPower < spellPower2 then
                        local remotes4 = game:GetService("ReplicatedStorage")
                        remotes4 = remotes4.remotes
                        local upgradeItem4 = remotes4.upgradeItem
                        upgradeItem4.FireServer(upgradeItem4, "helmet", tonumber(string.sub(k2, 8)), "spell", ok2)
                    else
                        local remotes3 = game:GetService("ReplicatedStorage")
                        remotes3 = remotes3.remotes
                        local upgradeItem3 = remotes3.upgradeItem
                        upgradeItem3.FireServer(upgradeItem3, "helmet", tonumber(string.sub(k2, 8)), "physical", ok2)
                    end
                end
            end
        elseif a == "weapons" then
            for k3, v3 in pairs(PathfindingService.weapons) do
                local ok = v3.maxUpgrades - v3.currentUpgrade
                if v3.equipped and ok ~= 0 then
                    local spellPower3 = v3.spellPower
                    if v3.physicalDamage < spellPower3 then
                        local remotes2 = game:GetService("ReplicatedStorage")
                        remotes2 = remotes2.remotes
                        local upgradeItem2 = remotes2.upgradeItem
                        upgradeItem2.FireServer(upgradeItem2, "weapon", tonumber(string.sub(k3, 8)), "spell", ok)
                    else
                        local remotes = game:GetService("ReplicatedStorage")
                        remotes = remotes.remotes
                        local upgradeItem = remotes.upgradeItem
                        upgradeItem.FireServer(upgradeItem, "weapon", tonumber(string.sub(k3, 8)), "physical", ok)
                    end
                end
            end
        end
    end
end

local function fn7(a, b)
    local value = 0
    local value4, value5 = nil, nil
    for k, v in pairs(a) do
        if v.name ~= "skip" then
            local PathfindingService = v.description:lower()
            if PathfindingService:find("spell") and b == "spell" then
                if v.levelReq > value then
                    local levelReq2 = v.levelReq
                    value, value4, value5 = levelReq2, k, v.name
                end
            elseif PathfindingService:find("physical") and b == "physical" and v.levelReq > value then
                local levelReq = v.levelReq
                value, value4, value5 = levelReq, k, v.name
            end
        end
    end
    return value4, value5
end

local function fn8()
    if _G.autoEquipSpell then
        local PathfindingService = fn(game.Players.LocalPlayer)
        local abilities = PathfindingService.abilities
        local value3, value4, spellType = fn7, abilities, _G.spellType
        local result2, value16 = value3(value4, spellType.lower(spellType))
        for k, v in pairs(PathfindingService.abilities) do
            if v.name == value16 then
                v.name = "skip"
                break
            end
        end
        local value6, value7, spellType2 = fn7, abilities, _G.spellType
        local result3, _ = value6(value7, spellType2.lower(spellType2))
        if result2 ~= nil and result3 ~= nil then
            print(result3, result2)
            local remotes = game:GetService("ReplicatedStorage")
            remotes = remotes.remotes
            local equipItem = remotes.equipItem
            local InvokeServer = equipItem.InvokeServer
            local tonumber2 = tonumber(string.sub(result2, 9))
            InvokeServer(equipItem, "ability", tonumber2, "q")
            wait(1)
            local remotes2 = game:GetService("ReplicatedStorage")
            remotes2 = remotes2.remotes
            local equipItem2 = remotes2.equipItem
            local InvokeServer2 = equipItem2.InvokeServer
            tonumber2 = tonumber
            InvokeServer2(equipItem2, "ability", tonumber2(string.sub(result3, 9)), "e")
        end
    end
end

local function fn9()
    if _G.auto_equip_gear then
        setAction("equipping gear", "")
        local leaderstats = game.Players.LocalPlayer.leaderstats
        local Value = leaderstats.Level.Value
        local Players3 = fn(game.Players.LocalPlayer)
        local value28 = 0
        local value29 = nil
        if Players3.chests ~= nil then
            local Value2 = game.Players.LocalPlayer.leaderstats.Gold.Value
            local part, value30, value31 = pairs(Players3.chests)
            local value41, value42 = value28, value29
            for k, v in part, value30, value31 do
                local ok = v.maxUpgrades - v.currentUpgrade
                local value40 = value41
                if _G.equip_type == "spell"
                    and v.levelReq <= Value
                    and v.physicalPower < v.spellPower then
                    local upgradedPower = fn5(v.spellPower, ok)
                    local affordable = fn6(v.maxUpgrades, v.currentUpgrade) < Value2
                    if (value41 < upgradedPower and affordable) or v.spellPower > value41 then
                        value40, value42 = upgradedPower, k
                    end
                end
                if _G.equip_type == "physical"
                    and v.levelReq <= Value
                    and v.spellPower < v.physicalPower then
                    local PathfindingService = fn5(v.physicalPower, ok)
                    local ok6 = fn6(v.maxUpgrades, v.currentUpgrade) < Value2
                    if value40 < PathfindingService and ok6 or v.physicalPower > value40 then
                        value41, value42 = PathfindingService, k
                    else
                        value41 = value40
                    end
                else
                    value41 = value40
                end
            end
            if value42 ~= nil then
                local remotes = game:GetService("ReplicatedStorage")
                remotes = remotes.remotes
                local equipItem = remotes.equipItem
                equipItem.InvokeServer(equipItem, "chest", (tonumber(string.sub(value42, 7))))
            end
        end
        wait(1)
        autoUpgradeEquip("helmets")
        wait(1)
        local value32 = 0
        local value33 = nil
        if Players3.helmets ~= nil then
            local Value3 = game.Players.LocalPlayer.leaderstats.Gold.Value
            local result8, value34, value35 = pairs(Players3.helmets)
            local value44, value45 = value32, value33
            for k2, v2 in result8, value34, value35 do
                local ok3 = v2.maxUpgrades - v2.currentUpgrade
                local value43 = value44
                if _G.equip_type == "spell"
                    and v2.levelReq <= Value
                    and v2.physicalPower < v2.spellPower then
                    local upgradedPower = fn5(v2.spellPower, ok3)
                    local affordable = fn6(v2.maxUpgrades, v2.currentUpgrade) < Value3
                    if (value44 < upgradedPower and affordable) or v2.spellPower > value44 then
                        value43, value45 = upgradedPower, k2
                    end
                end
                if _G.equip_type == "physical"
                    and v2.levelReq <= Value
                    and v2.spellPower < v2.physicalPower then
                    local result2 = fn5(v2.physicalPower, ok3)
                    local ok8 = fn6(v2.maxUpgrades, v2.currentUpgrade) < Value3
                    if value43 < result2 and ok8 or v2.physicalPower > value43 then
                        value44, value45 = result2, k2
                    else
                        value44 = value43
                    end
                else
                    value44 = value43
                end
            end
            if value45 ~= nil then
                local remotes2 = game:GetService("ReplicatedStorage")
                remotes2 = remotes2.remotes
                local equipItem2 = remotes2.equipItem
                equipItem2.InvokeServer(equipItem2, "helmet", (tonumber(string.sub(value45, 8))))
            end
        end
        wait(1)
        autoUpgradeEquip("chests")
        wait(1)
        local value36 = 0
        local value37 = nil
        if Players3.weapons ~= nil then
            local Value4 = game.Players.LocalPlayer.leaderstats.Gold.Value
            local result11, value38, value39 = pairs(Players3.weapons)
            local value47, value48 = value36, value37
            for k3, v3 in result11, value38, value39 do
                local ok4 = v3.maxUpgrades - v3.currentUpgrade
                local value46 = value47
                if _G.equip_type == "spell"
                    and v3.levelReq <= Value
                    and v3.physicalDamage < v3.spellPower then
                    local upgradedPower = fn5(v3.spellPower, ok4)
                    local affordable = fn6(v3.maxUpgrades, v3.currentUpgrade) < Value4
                    if (value47 < upgradedPower and affordable) or v3.spellPower > value47 then
                        value46, value48 = upgradedPower, k3
                    end
                end
                if _G.equip_type == "physical"
                    and v3.levelReq <= Value
                    and v3.spellPower < v3.physicalDamage then
                    local result3 = fn5(v3.physicalDamage, ok4)
                    local ok10 = fn6(v3.maxUpgrades, v3.currentUpgrade) < Value4
                    if value46 < result3 and ok10 or v3.physicalDamage > value46 then
                        value47, value48 = result3, k3
                    else
                        value47 = value46
                    end
                else
                    value47 = value46
                end
            end
            if value48 ~= nil then
                local remotes3 = game:GetService("ReplicatedStorage")
                remotes3 = remotes3.remotes
                local equipItem3 = remotes3.equipItem
                equipItem3.InvokeServer(equipItem3, "weapon", (tonumber(string.sub(value48, 8))))
            end
        end
        wait(1)
        autoUpgradeEquip("weapons")
        wait(1)
    end
end

local function fn10()
    if _G.auto_choose_dungeon_and_difficulty then
        game.Players.LocalPlayer:WaitForChild("leaderstats")
        game.Players.LocalPlayer.leaderstats:WaitForChild("Level")
        lvl = game.Players.LocalPlayer.leaderstats.Level.Value
        print(lvl)
        if lvl <= 5 then
            _G.dungeon = "Desert Temple"
            _G.difficulty = "Easy"
        elseif lvl <= 11 then
            _G.dungeon = "Desert Temple"
            _G.difficulty = "Medium"
        elseif lvl <= 19 then
            _G.dungeon = "Desert Temple"
            _G.difficulty = "Hard"
        elseif lvl <= 26 then
            _G.dungeon = "Desert Temple"
            _G.difficulty = "Insane"
        elseif lvl <= 32 then
            _G.dungeon = "Desert Temple"
            _G.difficulty = "Nightmare"
        elseif lvl <= 39 then
            _G.dungeon = "Winter Outpost"
            _G.difficulty = "Easy"
        elseif lvl <= 44 then
            _G.dungeon = "Winter Outpost"
            _G.difficulty = "Medium"
        elseif lvl <= 49 then
            _G.dungeon = "Winter Outpost"
            _G.difficulty = "Hard"
        elseif lvl <= 54 then
            _G.dungeon = "Winter Outpost"
            _G.difficulty = "Insane"
        elseif lvl <= 59 then
            _G.dungeon = "Winter Outpost"
            _G.difficulty = "Nightmare"
        elseif lvl <= 64 then
            _G.dungeon = "Pirate Island"
            _G.difficulty = "Insane"
        elseif lvl <= 69 then
            _G.dungeon = "Pirate Island"
            _G.difficulty = "Nightmare"
        elseif lvl <= 74 then
            _G.dungeon = "King's Castle"
            _G.difficulty = "Insane"
        elseif lvl <= 79 then
            _G.dungeon = "King's Castle"
            _G.difficulty = "Nightmare"
        elseif lvl <= 84 then
            _G.dungeon = "The Underworld"
            _G.difficulty = "Insane"
        elseif lvl <= 89 then
            _G.dungeon = "The Underworld"
            _G.difficulty = "Nightmare"
        elseif lvl <= 94 then
            _G.dungeon = "Samurai Palace"
            _G.difficulty = "Insane"
        elseif lvl <= 99 then
            _G.dungeon = "Samurai Palace"
            _G.difficulty = "Nightmare"
        elseif lvl <= 104 then
            _G.dungeon = "The Canals"
            _G.difficulty = "Insane"
        elseif lvl <= 109 then
            _G.dungeon = "The Canals"
            _G.difficulty = "Nightmare"
        elseif lvl <= 114 then
            _G.dungeon = "Ghastly Harbor"
            _G.difficulty = "Insane"
        elseif lvl <= 119 then
            _G.dungeon = "Ghastly Harbor"
            _G.difficulty = "Nightmare"
        elseif lvl <= 124 then
            _G.dungeon = "Steampunk Sewers"
            _G.difficulty = "Insane"
        elseif lvl <= 139 then
            _G.dungeon = "Steampunk Sewers"
            _G.difficulty = "Nightmare"
        elseif lvl <= 145 then
            _G.dungeon = "Orbital Outpost"
            _G.difficulty = "Insane"
        elseif lvl <= 149 then
            _G.dungeon = "Orbital Outpost"
            _G.difficulty = "Nightmare"
        elseif lvl <= 154 then
            _G.dungeon = "Volcanic Chambers"
            _G.difficulty = "Insane"
        elseif lvl <= 159 then
            _G.dungeon = "Volcanic Chambers"
            _G.difficulty = "Nightmare"
        -- Dungeons added after the build this script was written for. Level
        -- requirements confirmed against remotes.getDungeonStats on the live server.
        elseif lvl <= 164 then
            _G.dungeon = "Aquatic Temple"
            _G.difficulty = "Insane"
        elseif lvl <= 169 then
            _G.dungeon = "Aquatic Temple"
            _G.difficulty = "Nightmare"
        elseif lvl <= 174 then
            _G.dungeon = "Enchanted Forest"
            _G.difficulty = "Insane"
        elseif lvl <= 179 then
            _G.dungeon = "Enchanted Forest"
            _G.difficulty = "Nightmare"
        elseif lvl <= 184 then
            _G.dungeon = "Northern Lands"
            _G.difficulty = "Insane"
        elseif lvl <= 189 then
            _G.dungeon = "Northern Lands"
            _G.difficulty = "Nightmare"
        elseif lvl <= 194 then
            _G.dungeon = "Gilded Skies"
            _G.difficulty = "Insane"
        elseif lvl <= 199 then
            -- 195 unlocks both Gilded Skies Nightmare and Oni Dungeon Insane;
            -- the later dungeon drops better gear.
            _G.dungeon = "Oni Dungeon"
            _G.difficulty = "Insane"
        else
            _G.dungeon = "Oni Dungeon"
            _G.difficulty = "Nightmare"
        end
    end
end

function autoChooseBossRaidTier()
    if _G.auto_choose_raid_boss_tier then
        local PathfindingService = fn(game.Players.LocalPlayer)
        local value3 = 0
        if PathfindingService.keys ~= nil and PathfindingService.keys then
            local Players3, value5, value6 = pairs(PathfindingService.keys)
            local value4 = value3
            for k, v in Players3, value5, value6 do
                if tonumber(k) > value4 and v then
                    local result2 = tonumber(k)
                    local _G2 = _G
                    local result3 = tonumber(k)
                    _G2.boss_raid_tier = result3
                    value4 = result2
                end
            end
        end
    end
end

local function fn11()
    spawn(function()
        local Players = game.Players
        pgui = Players.LocalPlayer.PlayerGui
        if game.CoreGui.RobloxGui:FindFirstChild("TopBarContainer") then
            game.CoreGui.RobloxGui.TopBarContainer:WaitForChild("NameHealthContainer")
            if game.CoreGui.RobloxGui.TopBarContainer.NameHealthContainer:FindFirstChild("Username") then
                game.CoreGui.RobloxGui.TopBarContainer.NameHealthContainer.Username:Destroy()
            end
        end
        while true do
            if game.Players.LocalPlayer.PlayerGui:FindFirstChild("playerStatus") then
                break
            end
            wait(0.1)
        end
        pstat = pgui.playerStatus.Frame
        if _G.edit_ui then
            while true do
                if game.Players.LocalPlayer.PlayerGui:FindFirstChild("playerStatus") then
                    break
                end
                wait(0.1)
            end
            pstat = pgui.playerStatus.Frame
            while true do
                if pstat.portraitBorder:FindFirstChild("portrait") then
                    break
                end
                wait(0.1)
            end
            local portraitBorder = pstat.portraitBorder
            portraitBorder.portrait.Image = _G.UI_portait_image
            if pstat.moneyMain:FindFirstChild("updateMoney") then
                pstat.moneyMain.updateMoney:Destroy()
            end
            local moneyMain = pstat.moneyMain
            moneyMain.TextLabel.Text = _G.UI_money
            local healthFrame = pstat.healthFrame
            healthFrame.health.Text = _G.UI_health
            if pstat.healthFrame.health:FindFirstChild("label") then
                pstat.healthFrame.health.label:Destroy()
                pstat.healthFrame.healthUpdater:Destroy()
            end
            pstat.playerName.Text = _G.UI_name
            local xpFrame = pstat.xpFrame
            xpFrame.xp.Text = _G.UI_xp
            if pstat.xpFrame:FindFirstChild("xpUpdater") then
                pstat.xpFrame.xp.label:Destroy()
                pstat.xpFrame.xpUpdater:Destroy()
            end
            local levelBorder = pstat.levelBorder
            levelBorder.level.Text = _G.UI_lvl
            game.Players.LocalPlayer.PlayerGui:WaitForChild("abilities")
        end
    end)
    game.Players.LocalPlayer.Character:WaitForChild("playerNameplate", 5)
    if game.Players.LocalPlayer.Character:FindFirstChild("playerNameplate") then
        game.Players.LocalPlayer.Character.playerNameplate:Destroy()
    end
    while true do
        if game.Players.LocalPlayer.Character then
            break
        end
        wait()
    end
    while true do
        if game.Players.LocalPlayer.Character:FindFirstChildOfClass("Accessory") then
            break
        end
        wait()
    end
    wait()
    local Players = game.Players
    pchar = Players.LocalPlayer.Character
    local next2 = next
    local PathfindingService, value11 = game.Players.LocalPlayer.Character:GetChildren()
    for k2, v2 in next2, PathfindingService, value11 do
        if v2.ClassName == "Accessory" then

        end
        local pairs2, pchar2 = pairs, pchar
        for k, v in pairs2(pchar2.GetChildren(pchar2)) do
            if v.ClassName == "Accessory" then
                if v:FindFirstChild("swing") then
                    if _G.del_armor and v:FindFirstChildOfClass("Model") then
                        v:FindFirstChildOfClass("Model"):Destroy()
                    end
                elseif _G.del_weapon then
                    v:Destroy()
                end
            end
        end
    end
end

setAction("checking place", "")
if isLobbyPlace() then
    setAction("in lobby", "")
    while true do
        if workspace:FindFirstChild(game.Players.LocalPlayer.Name) then
            break
        end
        wait(0.1)
        local remotes = game:GetService("ReplicatedStorage")
        remotes = remotes.remotes
        remotes.loadPlayerCharacter:FireServer()
    end
    setAction("loading character", "")
    spawn(function()
        while true do
            if workspace:FindFirstChild(game.Players.LocalPlayer.Name):FindFirstChild("Humanoid") then
                break
            end
            wait(0.1)
        end
        spawn(function()
            while true do
                if game.Lighting:FindFirstChild("Blur") then
                    break
                end
                wait(0.1)
            end
            while true do
                if game.Players.LocalPlayer.PlayerGui:FindFirstChild("introGui") then
                    break
                end
                wait(0.1)
            end
            local workspace2 = game.Players.LocalPlayer.PlayerGui:FindFirstChild("introGui")
            workspace2:Destroy()
            workspace2 = workspace
            local CurrentCamera = workspace2.CurrentCamera
            CurrentCamera.CameraType = Enum.CameraType.Track
            local LocalPlayer = game.Players.LocalPlayer
            CurrentCamera.CameraSubject = LocalPlayer.Character.Humanoid
            game.Lighting.Blur:Destroy()
        end)
        spawn(function()
            AIMovementInLobby()
        end)
    end)
    setAction("character ready", "")
    if _G.collect_daily_reward then
        while true do
            if workspace:FindFirstChild(game.Players.LocalPlayer.Name):FindFirstChild("HumanoidRootPart") then
                break
            end
            wait(0.1)
        end
        workspace.dailyRewardTouchPart.CFrame = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame
        wait(0.1)
        local dailyRewardTouchPart = workspace.dailyRewardTouchPart
        local game5 = Vector3.new(10, 10, 10)
        dailyRewardTouchPart.Size = game5
        local dailyRewardTouchPart2 = workspace.dailyRewardTouchPart
        game5 = game
        local Players = game5.Players
        local Character = Players.LocalPlayer.Character
        local CFrame2 = Character.HumanoidRootPart.CFrame
        local result13 = CFrame.new(0, 1, 0)
        dailyRewardTouchPart2.CFrame = CFrame2 * result13
        wait(0.1)
        spawn(function()
            game.CoreGui:WaitForChild("PurchasePromptApp"):Destroy()
        end)
    end
    setAction("daily reward", "")
    if _G.boss_raid and _G.auto_choose_raid_boss_tier then
        local LocalPlayer5 = fn(game.Players.LocalPlayer)
        if LocalPlayer5.keys == nil then
            _G.auto_choose_dungeon_and_difficulty = true
            _G.boss_raid = false
            _G.wavedefense = false
        end
        if LocalPlayer5.keys["1"] ~= nil and LocalPlayer5.keys["1"] == false then
            _G.auto_choose_dungeon_and_difficulty = true
            _G.boss_raid = false
            _G.wavedefense = false
        end
    end
    setAction("checking boss keys", "")
    fn10()
    setAction("choosing dungeon", "")
    autoChooseBossRaidTier()
    setAction("choosing raid tier", "")
    fn8()
    setAction("swapping spells", "")
    fn9()
    setAction("equipping gear", "")
    fn4()
    setAction("selling items", "")
    autoupgrade()
    setAction("upgrading gear", "")
    if _G.easter_enable then
        _G.dungeon = "Egg Island"
        _G.difficulty = "Nightmare"
        _G.hardcore = false
    end
    setAction("joining dungeon", "")
    while not _G.ai_done do
        wait(0.1)
    end
    if _G.auto_join_dungeon then
        if _G.wait_for_friends_to_host then
            if _G.boss_raid then
                while true do
                    if workspace.bossLobbies:FindFirstChild(_G.host_name) then
                        break
                    end
                    wait()
                end
                while wait(0.1) do
                    local remotes3 = game:GetService("ReplicatedStorage")
                    remotes3 = remotes3.remotes
                    local playerJoinBossLobby = remotes3.playerJoinBossLobby
                    local InvokeServer, bossLobbies = playerJoinBossLobby.InvokeServer, workspace.bossLobbies
                    InvokeServer(playerJoinBossLobby, bossLobbies.FindFirstChild(bossLobbies, _G.host_name))
                end
            else
                while true do
                    if workspace.games.inLobby:FindFirstChild(_G.host_name) then
                        break
                    end
                    wait()
                end
                while wait(0.1) do
                    local remotes2 = game:GetService("ReplicatedStorage")
                    remotes2 = remotes2.remotes
                    remotes2.joinDungeon:InvokeServer(_G.host_name)
                end
            end
        end
        if _G.multi_roblox then
            if game.Players.LocalPlayer.Name == _G.host_name_key[1] then
                if _G.boss_raid then
                    local remotes7 = game:GetService("ReplicatedStorage")
                    remotes7 = remotes7.remotes
                    remotes7.createBossLobby:InvokeServer(_G.boss_raid_tier, true, 0)
                else
                    local remotes6 = game:GetService("ReplicatedStorage")
                    remotes6 = remotes6.remotes
                    remotes6.createLobby:InvokeServer(_G.dungeon, _G.difficulty, 0, _G.hardcore, true, _G.wavedefense)
                end
                wait(0.1)
                if _G.boss_raid then
                    for k, v in pairs(_G.name_key_list) do
                        local remotes9 = game:GetService("ReplicatedStorage")
                        remotes9 = remotes9.remotes
                        remotes9.addPlayerToBossWhitelist:FireServer(v[1])
                    end
                else
                    for k2, v2 in pairs(_G.name_key_list) do
                        local remotes8 = game:GetService("ReplicatedStorage")
                        remotes8 = remotes8.remotes
                        remotes8.addPlayerToWhitelist:FireServer(v2[1])
                    end
                end
                if _G.boss_raid then
                    while true do
                        local players = workspace.bossLobbies:FindFirstChild(game.Players.LocalPlayer.Name)
                        players = players.players
                        local ok13 = players:GetChildren()
                        ok13 = #ok13
                        if ok13 == #_G.name_key_list + 1 then
                            break
                        end
                        wait()
                    end
                else
                    while true do
                        local LocalPlayer6 = workspace.games.inLobby:FindFirstChild(game.Players.LocalPlayer.Name):GetChildren()
                        LocalPlayer6 = #LocalPlayer6
                        if LocalPlayer6 - 1 == #_G.name_key_list + 1 then
                            break
                        end
                        wait()
                    end
                end
                if _G.boss_raid then
                    local remotes11 = game:GetService("ReplicatedStorage")
                    remotes11 = remotes11.remotes
                    remotes11.startBossRaid:FireServer()
                else
                    local remotes10 = game:GetService("ReplicatedStorage")
                    remotes10 = remotes10.remotes
                    remotes10.startDungeon:FireServer()
                end
            elseif _G.boss_raid then
                while true do
                    if workspace.bossLobbies:FindFirstChild(_G.host_name_key[1]) then
                        break
                    end
                    wait()
                end
                while wait(0.1) do
                    local remotes5 = game:GetService("ReplicatedStorage")
                    remotes5 = remotes5.remotes
                    local playerJoinBossLobby2 = remotes5.playerJoinBossLobby
                    local InvokeServer2, bossLobbies2 = playerJoinBossLobby2.InvokeServer, workspace.bossLobbies
                    InvokeServer2(playerJoinBossLobby2, bossLobbies2.FindFirstChild(bossLobbies2, _G.host_name_key[1]))
                end
            else
                while true do
                    if workspace.games.inLobby:FindFirstChild(_G.host_name_key[1]) then
                        break
                    end
                    wait()
                end
                while wait(0.1) do
                    local remotes4 = game:GetService("ReplicatedStorage")
                    remotes4 = remotes4.remotes
                    local joinDungeon = remotes4.joinDungeon
                    joinDungeon.InvokeServer(joinDungeon, _G.host_name_key[1])
                end
            end
        end
        if _G.wait_for_friends then
            if _G.boss_raid then
                local remotes13 = game:GetService("ReplicatedStorage")
                remotes13 = remotes13.remotes
                remotes13.createBossLobby:InvokeServer(_G.boss_raid_tier, true, 0)
            else
                local remotes12 = game:GetService("ReplicatedStorage")
                remotes12 = remotes12.remotes
                remotes12.createLobby:InvokeServer(_G.dungeon, _G.difficulty, 0, _G.hardcore, true, _G.wavedefense)
            end
            wait(0.1)
            if _G.boss_raid then
                for k3, v3 in pairs(_G.friends) do
                    local remotes15 = game:GetService("ReplicatedStorage")
                    remotes15 = remotes15.remotes
                    remotes15.addPlayerToBossWhitelist:FireServer(v3)
                end
            else
                for k4, v4 in pairs(_G.friends) do
                    local remotes14 = game:GetService("ReplicatedStorage")
                    remotes14 = remotes14.remotes
                    remotes14.addPlayerToWhitelist:FireServer(v4)
                end
            end
            wait(0.1)
            if _G.boss_raid then
                while true do
                    local players2 = workspace.bossLobbies:FindFirstChild(game.Players.LocalPlayer.Name)
                    players2 = players2.players
                    local ok15 = players2:GetChildren()
                    ok15 = #ok15
                    if ok15 == #_G.friends + 1 then
                        break
                    end
                    wait()
                end
            else
                while true do
                    local LocalPlayer7 = workspace.games.inLobby:FindFirstChild(game.Players.LocalPlayer.Name):GetChildren()
                    LocalPlayer7 = #LocalPlayer7
                    if LocalPlayer7 - 1 == #_G.friends + 1 then
                        break
                    end
                    wait()
                end
            end
            if _G.boss_raid then
                local remotes17 = game:GetService("ReplicatedStorage")
                remotes17 = remotes17.remotes
                remotes17.startBossRaid:FireServer()
            else
                local remotes16 = game:GetService("ReplicatedStorage")
                remotes16 = remotes16.remotes
                remotes16.startDungeon:FireServer()
            end
            wait(20)
        end
        if _G.boss_raid then
            print("make boss lobby")
            local remotes20 = game:GetService("ReplicatedStorage")
            remotes20 = remotes20.remotes
            remotes20.createBossLobby:InvokeServer(_G.boss_raid_tier, true, 0)
            wait(1)
            local remotes21 = game:GetService("ReplicatedStorage")
            remotes21 = remotes21.remotes
            remotes21.startBossRaid:FireServer()
            wait(20)
        elseif not _G.boss_raid then
            local remotes18 = game:GetService("ReplicatedStorage")
            remotes18 = remotes18.remotes
            remotes18.createLobby:InvokeServer(_G.dungeon, _G.difficulty, 0, _G.hardcore, true, _G.wavedefense)
            wait(1)
            local remotes19 = game:GetService("ReplicatedStorage")
            remotes19 = remotes19.remotes
            remotes19.startDungeon:FireServer()
            wait(20)
        end
    else
        while wait(0.1) do

        end
    end
    while wait(0.1) do

    end
end
while true do
    if game.Players.LocalPlayer then
        break
    end
    wait(0.1)
end
while true do
    if game.Players.LocalPlayer.Character then
        break
    end
    wait(0.1)
end
while true do
    if game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        break
    end
    wait(0.1)
end
while true do
    if game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
        break
    end
    wait(0.1)
end
while true do
    if workspace:FindFirstChild(game.Players.LocalPlayer.Name) then
        break
    end
    wait(0.1)
end
while true do
    if workspace:FindFirstChild("dungeon")
        or workspace:FindFirstChild("tier")
        or workspace:FindFirstChild("currentWave") then
        break
    end
    wait(1)
end
while true do
    if game:GetService("Workspace"):FindFirstChild("dungeonProgress")
        or game:GetService("Workspace"):FindFirstChild("raidProgress") then
        break
    end
    wait()
end
wait(0.5)
local tbl5 = { AgentHeight = 5, AgentRadius = 3, AgentCanJump = true }
local item3, item4 = tbl3[2], tbl3[1]
local _ = game.Players.LocalPlayer.Character
local LocalPlayer4 = item3:CreatePath(tbl5)
local tbl2 = {}
local value, value7 = 0, nil
local tbl = {}

function stringInTable(a, b)
    if b[a] == nil then
        return false
    end
    return true
end

local function fn12(a, b)
    if _G.loadSlow then
        local RenderStepped = game:GetService("RunService")
        RenderStepped = RenderStepped.RenderStepped
        RenderStepped:wait()
    end
    local PathfindingService = Instance.new("Part")
    item4:AddTag(PathfindingService, "RayWhitelist")
    PathfindingService.Size = b
    PathfindingService.CFrame = a
    PathfindingService.Name = result3
    PathfindingService.Anchored = true
    PathfindingService.Transparency = _G.wall_transparency
    PathfindingService.CanCollide = true
    PathfindingService.Parent = workspace
    return PathfindingService
end

local function fn13(a)
    report("ANTI SKID, TransChange", a)
end

local function fn14(a)
    if a.ClassName ~= "TouchTransmitter" then
        report("ANTI SKID, ChildChange", a)
    end
end

local function fn15(a, b, c, d)
    local PathfindingService = Instance.new("Part")
    PathfindingService.Shape = d
    item4:AddTag(PathfindingService, "RayIgnore")
    PathfindingService.Material = "Neon"
    if _G.showPath then
        PathfindingService.Transparency = 0.5
    else
        PathfindingService.Transparency = ok11
    end
    PathfindingService.Size = b
    PathfindingService.CFrame = a
    PathfindingService.Name = c
    PathfindingService.Anchored = true
    PathfindingService.CanCollide = false
    PathfindingService.Parent = workspace
    local ChildAdded = PathfindingService:GetPropertyChangedSignal("Transparency")
    ChildAdded:Connect(fn13)
    ChildAdded = PathfindingService.ChildAdded
    ChildAdded:Connect(fn14)
    return PathfindingService
end

local function fn16(a, b, c)
    local PathfindingService = Instance.new("Part")
    item4:AddTag(PathfindingService, "RayIgnore")
    PathfindingService.Size = a
    PathfindingService.CFrame = b
    PathfindingService.Parent = c
    PathfindingService.Name = "enemyRadius"
    PathfindingService.Anchored = false
    PathfindingService.CanCollide = false
    PathfindingService.Material = "SmoothPlastic"
    PathfindingService.Transparency = ok11
    local ChildAdded = PathfindingService:GetPropertyChangedSignal("Transparency")
    ChildAdded:Connect(fn13)
    ChildAdded = PathfindingService.ChildAdded
    ChildAdded:Connect(fn14)
    local Instance2 = PhysicalProperties.new(0, 0, 0, 0, 0)
    PathfindingService.CustomPhysicalProperties = Instance2
    Instance2 = Instance
    local result2 = Instance2.new("WeldConstraint")
    if c.ClassName == "Model" then
        result2.Part1 = c.PrimaryPart
    else
        result2.Part1 = c
    end
    result2.Part0 = PathfindingService
    result2.Parent = c
    return PathfindingService
end

local function fn17(a, b, c)
    -- Enemy models stream in a piece at a time and are torn down the moment they
    -- die, so PrimaryPart can be nil either side of this call: reading
    -- a.PrimaryPart.CFrame here was throwing "attempt to index nil with CFrame".
    if not a or not a.Parent or not a.PrimaryPart then
        return
    end
    if c == nil then
        -- Dropped SETLIST again: `tbl` came out empty, so the ring of hit
        -- volumes around the enemy was never built and fn17 did nothing.
        -- The offsets the decompiler kept ({b,b}, {0,b}, {b,0}, {0,-b}) are the
        -- 1st, 2nd, 4th and 7th cells of a row-major 3x3 ring, so the four it
        -- lost are the remaining cells.
        local tbl = {
            { b, b }, { 0, b }, { -b, b },
            { b, 0 }, { -b, 0 },
            { b, -b }, { 0, -b }, { -b, -b },
        }
        for k, v in pairs(tbl) do
            -- Building the ring yields, and the enemy can die partway through it.
            if not a.Parent or not a.PrimaryPart then
                break
            end
            local result8 = Vector3.new(1, 1, b)
            local CFrame17 = a.PrimaryPart.CFrame
            local CFrame18 = CFrame.new(v[1], 0, v[2])
            local ok8 = CFrame17 * CFrame18
            local Position = ok8.Position
            CFrame18 = CFrame
            local humanoid = CFrame18.new(Position, a.PrimaryPart.Position)
            local result9 = CFrame.new(0, 0, -b / 2 + 2)
            humanoid = humanoid * result9
            result9 = fn16
            result9(result8, humanoid, a)
        end
    elseif c == "square" then
        local LocalPlayer4 = Vector3.new(b, b, b)
        CFrame.new(0, 0, 0)
        local CFrame16
        if a.ClassName == "Model" then
            a:WaitForChild("PrimaryPart", 0.5)
            CFrame16 = a.PrimaryPart.CFrame
        else
            CFrame16 = a.CFrame
        end
        fn16(LocalPlayer4, CFrame16, a)
    elseif c == "rectangle" then
        local VirtualUser = Vector3.new(b, b, b)
        CFrame.new(0, 0, 0)
        local CFrame13
        if a.ClassName == "Model" then
            a:WaitForChild("PrimaryPart", 0.5)
            CFrame13 = a.PrimaryPart.CFrame
        else
            CFrame13 = a.CFrame
        end
        fn16(VirtualUser, CFrame13, a)
        VirtualUser = Vector3.new(1, b, b * 2)
        CFrame.new(0, 0, 0)
        local humanoid2
        if a.ClassName == "Model" then
            a:WaitForChild("PrimaryPart", 0.5)
            local CFrame15 = a.PrimaryPart.CFrame
            humanoid2 = CFrame15 * CFrame.new(0, 0, (b - 5) * -1)
        else
            local CFrame14 = a.CFrame
            humanoid2 = CFrame14 * CFrame.new(0, 0, (b - 5) * -1)
        end
        fn16(VirtualUser, humanoid2, a)
    elseif c == "rectanglev2" then
        local result3 = Vector3.new(b, b, b)
        CFrame.new(0, 0, 0)
        local CFrame8
        if a.ClassName == "Model" then
            a:WaitForChild("PrimaryPart", 0.5)
            CFrame8 = a.PrimaryPart.CFrame
        else
            CFrame8 = a.CFrame
        end
        fn16(result3, CFrame8, a)
        result3 = Vector3.new(b, b, b)
        CFrame.new(0, 0, 0)
        local ok4
        if a.ClassName == "Model" then
            a:WaitForChild("PrimaryPart", 0.5)
            local CFrame11 = a.PrimaryPart.CFrame
            local CFrame12 = CFrame.new(0, 0, (b - 10) * -1)
            local ok6 = CFrame11 * CFrame12
            CFrame12 = CFrame
            local part = CFrame12.Angles(math.rad(45), 0, math.rad(90))
            ok4 = ok6 * part
        else
            local CFrame9 = a.CFrame
            local CFrame10 = CFrame.new(0, 0, (b - 10) * -1)
            local ok5 = CFrame9 * CFrame10
            CFrame10 = CFrame
            local Players3 = CFrame10.Angles(math.rad(45), 0, math.rad(90))
            ok4 = ok5 * Players3
        end
        fn16(result3, ok4, a)
    elseif c == "rectanglev3" then
        local result2 = Vector3.new(b, b, b)
        CFrame.new(0, 0, 0)
        local CFrame3
        if a.ClassName == "Model" then
            a:WaitForChild("PrimaryPart", 0.5)
            CFrame3 = a.PrimaryPart.CFrame
        else
            CFrame3 = a.CFrame
        end
        fn16(result2, CFrame3, a)
        result2 = Vector3.new(b - 5, b - 5, b - 5)
        CFrame.new(0, 0, 0)
        local ok
        if a.ClassName == "Model" then
            a:WaitForChild("PrimaryPart", 0.5)
            local CFrame6 = a.PrimaryPart.CFrame
            local CFrame7 = CFrame.new(0, 0, (b - 5) * -1)
            local ok3 = CFrame6 * CFrame7
            CFrame7 = CFrame
            ok = ok3 * CFrame7.Angles(0, math.rad(45), 0)
        else
            local CFrame4 = a.CFrame
            local CFrame5 = CFrame.new(0, 0, (b - 5) * -1)
            local ok2 = CFrame4 * CFrame5
            CFrame5 = CFrame
            ok = ok2 * CFrame5.Angles(0, math.rad(45), 0)
        end
        fn16(result2, ok, a)
    elseif c == "rectangle-2" then
        local PathfindingService = Vector3.new(b, b, b)
        CFrame.new(0, 0, 0)
        local CFrame2
        if a.ClassName == "Model" then
            a:WaitForChild("PrimaryPart", 0.5)
            CFrame2 = a.PrimaryPart.CFrame
            CFrame2 = CFrame2 * CFrame.Angles(0, math.rad(45), 0)
        else
            CFrame2 = a.CFrame
            CFrame2 = CFrame2 * CFrame.Angles(0, math.rad(45), 0)
        end
        fn16(PathfindingService, CFrame2, a)
    end
end

local function fn18(a)
    if _G.optimize_mobs then
        local pairs2, value = pairs, a
        for k, v in pairs2(value.GetChildren(value)) do
            if v.ClassName == "Model" then
                v:Destroy()
            end
        end
        if a:FindFirstChild("HumanoidRootPart") then
            a.HumanoidRootPart.Transparency = 0
        end
        if a:FindFirstChild("Head") then
            a.Head.Transparency = 0
        end
    end
end

local function fn19(a)
    if a.ClassName == "Model" then
        -- Every wait here used to be unbounded. An enemy killed while this was
        -- still setting it up leaves PrimaryPart nil for good, so the first loop
        -- span forever - and because fn20 walks the room's enemies one at a
        -- time, that one dead mob froze the whole pass before it could register
        -- any ChildAdded handlers. Nothing got tagged from then on.
        local waited = 0
        while a.PrimaryPart == nil and waited < 5 do
            wait(0.05)
            waited = waited + 0.05
        end
        if not a.Parent or a.PrimaryPart == nil then
            return
        end
        waited = 0
        while not a:FindFirstChild(a.PrimaryPart.Name) and waited < 5 do
            wait(0.05)
            waited = waited + 0.05
        end
        if not a.Parent then
            return
        end
        a:WaitForChild("HumanoidRootPart", 5)
        a:WaitForChild("enemyStyle", 1.5)
        local styleValue = a.Parent and a:FindFirstChild("enemyStyle")
        if not styleValue then
            return
        end
        local Value = styleValue.Value
        if Value == "mob" or Value == "ranged" or Value == "melee" or Value == "burly" then
            waitForEnemyTags(a, ok and 1 or 2)
            item4:AddTag(a, "Enemy")
            local trackedHumanoid = a:FindFirstChildOfClass("Humanoid")
            if trackedHumanoid then
                trackedHumanoid.Died:Connect(function()
                    farmStatus.kills = farmStatus.kills + 1
                end)
            end
            -- The name whitelist only covers the pre-2020 dungeons; anything the
            -- game itself flags as a regular enemy style counts too, so mobs from
            -- Aquatic Temple onward are handled without hardcoding their names.
            if _G.doInstakill and (tbl4[a.Name] or Value == "mob" or Value == "ranged" or Value == "melee" or Value == "burly") then
                tryInstakill(a)
            end
            if Value ~= "ranged" then
                -- Every dungeon now shares one place id, so the per-enemy
                -- overrides key off the model name instead of game.PlaceId.
                if a.Name == "Explosive Lava Walker" or a.Name == "Aggressive Lava Walker" then
                    fn17(a, 8.5)
                elseif a.Name == "Temple Guard" then
                    fn17(a, 3)
                else
                    fn17(a, 7)
                end
            end
        else
            waitForEnemyTags(a, 1)
            if _G.doInstakill and tbl4[a.Name] then
                tryInstakill(a)
            end
            item4:AddTag(a, "Enemy")
        end
    end
end

local function fn20()
    -- Same stale check as fn34: tier/currentWave now exist in every dungeon, so
    -- normal runs hooked workspace.enemies (which stays empty here) instead of
    -- the per-room enemyFolders, and nothing was ever tagged as an Enemy.
    if isBossRaidPlace() or isWaveDefensePlace() then
        workspace.enemies.ChildAdded:Connect(function(a)
            if a.Name == "Stone Warrior" then
                a:WaitForChild("Humanoid")
                fn17(a, 5)
                wait(1)
                a.Humanoid.Health = 0
            else
                fn19(a)
                fn18(a)
            end
        end)
    else
        local pairs2, dungeon = pairs, workspace.dungeon
        for k2, v2 in pairs2(dungeon.GetChildren(dungeon)) do
            local enemyFolder = v2:FindFirstChild("enemyFolder")
            if enemyFolder then
                -- Connect first. This used to come after the pass over the
                -- enemies already in the room, so a single stuck enemy meant
                -- the room never got a handler and every later spawn was missed.
                enemyFolder.ChildAdded:Connect(function(a)
                    fn19(a)
                    fn18(a)
                end)
                -- And give each existing enemy its own thread, so one that dies
                -- mid-setup cannot hold up the rest of the room.
                for _, existing in pairs2(enemyFolder:GetChildren()) do
                    spawn(function()
                        fn19(existing)
                        fn18(existing)
                    end)
                end
            end
        end
    end
end

local tbl6 = {}
local tbl7 = {}
do
    local function fn50()
        if game.ReplicatedStorage:FindFirstChild("projectiles") then
            local projectiles = game:GetService("ReplicatedStorage")
            projectiles = projectiles.projectiles
            local PathfindingService = projectiles:GetChildren()
            local enemyProjectiles = game:GetService("ReplicatedStorage")
            enemyProjectiles = enemyProjectiles.enemyProjectiles
            local result2 = enemyProjectiles:GetChildren()
            for k, v in pairs(PathfindingService) do
                tbl6[v.Name] = true
            end
            for k2, v2 in pairs(result2) do
                tbl7[v2.Name] = true
            end
            tbl7.secondBossSlamHitbox = true
        end
    end

    fn50()
end

local function fn21(a)
    local PathfindingService = Instance.new("Part")
    item4:AddTag(PathfindingService, "RayIgnore")
    PathfindingService.Shape = "Ball"
    PathfindingService.Material = "Neon"
    local result2 = Vector3.new(0.6, 0.6, 0.6)
    PathfindingService.Size = result2
    PathfindingService.Position = a
    PathfindingService.Anchored = true
    PathfindingService.CanCollide = false
    result2 = result3
    PathfindingService.Name = result2
    PathfindingService.Parent = game.Workspace
    tbl[#tbl + 1] = PathfindingService
end

local value23 = fn15
local Instance2 = CFrame.new(0, 0, 0)
local result8 = Vector3.new(3, 3, 3)
local result9 = value23(Instance2, result8, result3, "Ball")
Instance2 = Instance
local new = Instance2.new
result8 = "SelectionBox"
local result10 = new(result8)

local function fn22(a, b)
    Vector3.new(b.X, a.Y, b.Z)
    return (a - b).magnitude
end

local function fn23()
    while true do
        if game.Players.LocalPlayer then
            break
        end
        wait()
    end
    local Players2 = game.Players
    local value, value2, value3, value4
    if Players2.LocalPlayer then
        local LocalPlayer = game.Players.LocalPlayer
        while true do
            if game.Players.LocalPlayer.Character then
                break
            end
            wait()
        end
        if game.Players.LocalPlayer.Character then
            local Players = game.Players
            local character = Players.LocalPlayer.character
            while true do
                if game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
                    break
                end
                wait()
            end
            local Character = game.Players.LocalPlayer.Character
            local FindFirstChild = Character.FindFirstChild
            local Humanoid
            if FindFirstChild(Character, "Humanoid") then
                local LocalPlayer2 = game.Players.LocalPlayer
                Humanoid = LocalPlayer2.Character.Humanoid
            else
                Humanoid = nil
            end
            while true do
                if game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    break
                end
                wait()
            end
            if game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local LocalPlayer3 = game.Players.LocalPlayer
                value, value2, value3, value4 = LocalPlayer, character, Humanoid, LocalPlayer3.Character.HumanoidRootPart
            else
                value, value2, value3, value4 = LocalPlayer, character, Humanoid, nil
            end
        else
            value, value2, value3, value4 = LocalPlayer, nil, nil, nil
        end
    else
        value, value2, value3, value4 = nil, nil, nil, nil
    end
    return value, value2, value3, value4
end

local tbl8 = {}
tbl8.itemsEarned = {}
local LocalPlayer8 = fn(game.Players.LocalPlayer)
tbl8.startingInventory = LocalPlayer8
tbl8.dungeonName = nil
tbl8.timeLeft = nil
tbl8.endingInventory = nil
LocalPlayer8 = {
    legendary = "16426522", epic = "14031610", rare = "39423", uncommon = "2096896",
    common = "15859184"
}
tbl8.colorTable = LocalPlayer8

function Format(a)
    return string.format("%02i", a)
end

local function fn24(a)
    local ok = (a - a % 60) / 60
    local ok2 = a - ok * 60
    local ok3 = Format(ok)
    ok3 = ok3 .. ":" .. Format(ok2)
    return ok3
end

local function fn25()
    -- syn/http_request are Synapse-era names; current executors expose `request`.
    local ok = (syn and syn.request) or http_request or request
        or (http and http.request) or (fluxus and fluxus.request)
    if not ok then
        ScriptDebug("[compat] no HTTP request function available - webhook skipped")
        return
    end
    local tbl = {}
    tbl.Url = _G.webhookLink
    tbl.Method = "POST"
    tbl.Headers = { ["Content-Type"] = "application/json" }
    local PathfindingService = game:GetService("HttpService")
    local JSONEncode = PathfindingService.JSONEncode
    local tbl2 = {}
    tbl2.embeds = tbl8.itemsEarned
    local result2 = JSONEncode(PathfindingService, tbl2)
    tbl.Body = result2
    ok(tbl)
end

local function fn26(a)
    local PathfindingService = a:sub(1, 1)
    local result2 = a:sub(2)
    local ok = PathfindingService:upper()
    ok = ok .. result2
    return ok
end

local function fn27(a, b)
    for k, v in pairs(b) do
        if not a[k] then
            local tbl = {}
            local rarity = fn26(v.name)
            tbl.description = [[```
]] .. rarity .. "```"
            local colorTable = tbl8.colorTable
            rarity = v.rarity
            tbl.color = colorTable[rarity]
            table.insert(tbl8.itemsEarned, tbl)
        end
    end
end

local function fn28()
    if _G.webhookEnabled then
        local value = tbl8
        local tbl = fn24(workspace.timeLeft.Value)
        value.timeLeft = tbl
        local value4 = tbl8
        local tbl2 = { color = "0" }
        tbl2.author = { name = "MRobSwag Item Notifier" }
        local tbl4 = { name = "Dungeon: ", value = tostring(tbl8.dungeonName) }
        local tbl5 = { name = "Clear Time: ", value = tbl8.timeLeft }
        -- Both dropped SETLISTs: the field list and the embed list. Without them
        -- the webhook posted an empty embeds array.
        local tbl3 = { tbl4, tbl5 }
        tbl2.fields = tbl3
        tbl = { tbl2 }
        value4.itemsEarned = tbl
        wait(2)
        print("doing webhook")
        local value5 = tbl8
        local PathfindingService = fn(game.Players.LocalPlayer)
        value5.endingInventory = PathfindingService
        local value8 = fn27
        PathfindingService = tbl8
        value8(PathfindingService.startingInventory.weapons, tbl8.endingInventory.weapons)
        fn27(tbl8.startingInventory.abilities, tbl8.endingInventory.abilities)
        fn27(tbl8.startingInventory.chests, tbl8.endingInventory.chests)
        fn27(tbl8.startingInventory.helmets, tbl8.endingInventory.helmets)
        fn25()
        print("done webhook")
    end
end

local workspace2 = workspace
local FindFirstChild = workspace2.FindFirstChild
if FindFirstChild(workspace2, "dungeonProgress") then
    local Changed2 = game:GetService("Workspace"):FindFirstChild("dungeonProgress")
    Changed2 = Changed2.Changed
    Changed2:Connect(function(a)
        if a ~= "" and a ~= "inProgress" and a ~= "playersNotReady" then
            ok2 = true
            if regionTable ~= nil then
                for k2, v2 in pairs(regionTable) do
                    for k, v in pairs(v2) do
                        local regionTable2 = regionTable[k2]
                        local item = regionTable2[k]
                        item.obj:Destroy()
                    end
                end
            end
            if readyPartTable ~= nil then
                for k3, v3 in pairs(readyPartTable) do
                    v3:Destroy()
                end
            end
            spawn(fn28)
            setAction("dungeon finished", "")
            -- The payout lands as the run ends; bank it before replay teleports
            -- us out and the panel is rebuilt in the next server.
            wait(1)
            saveSession()
            autoReplay()
            wait(0.5)
            game:GetService("ScriptContext"):SetTimeout(0)
        end
    end)
elseif workspace:FindFirstChild("raidPorgress") then
    local Changed = game:GetService("Workspace"):FindFirstChild("raidProgress")
    Changed = Changed.Changed
    Changed:Connect(function(a)
        if a ~= "" and a ~= "inProgress" and a ~= "playersNotReady" then
            ok2 = true
            if regionTable ~= nil then
                for k2, v2 in pairs(regionTable) do
                    for k, v in pairs(v2) do
                        local regionTable2 = regionTable[k2]
                        local item = regionTable2[k]
                        item.obj:Destroy()
                    end
                end
            end
            if readyPartTable ~= nil then
                for k3, v3 in pairs(readyPartTable) do
                    v3:Destroy()
                end
            end
            spawn(fn28)
            setAction("dungeon finished", "")
            -- The payout lands as the run ends; bank it before replay teleports
            -- us out and the panel is rebuilt in the next server.
            wait(1)
            saveSession()
            autoReplay()
            wait(0.5)
            game:GetService("ScriptContext"):SetTimeout(0)
        end
    end)
end

function SelectBoxChange(a)
    result10.Adornee = a
    local value = result10
    local PathfindingService = Color3.new(1, 0, 0)
    value.Color3 = PathfindingService
    result10.Parent = a
end

local function fn29()
    local huge = math.huge
    local ok = item4:GetTagged("Prio-Enemy")
    ok = #ok
    if ok > 0 then
        local item = item4:GetTagged("Prio-Enemy")
        item = item[1]
        return item
    end
    local value10, value11, value14
    while true do
        local ok2 = item4:GetTagged("Enemy")
        ok2 = #ok2
        if not (ok2 < 1) then
            value10, value11 = nil, huge
            break
        end
        setAction("waiting for enemies", "")
        if _G.extremelyFast then
            local RenderStepped = game:GetService("RunService")
            RenderStepped = RenderStepped.RenderStepped
            RenderStepped:wait()
        else
            wait()
        end
    end
    while true do
        if value10 ~= nil then
            value14 = value10
            break
        end
        local PathfindingService = item4:GetTagged("Enemy")
        local _, _, _, value7 = fn23()
        local result3, value8, value9 = pairs(PathfindingService)
        local value12, value13 = value10, value11
        for k, v in result3, value8, value9 do
            if v:FindFirstChild("HumanoidRootPart") and value7 ~= nil then
                local result2 = fn22(value7.Position, v.HumanoidRootPart.Position)
                if result2 < value13 then
                    value12, value13 = v, result2
                end
            end
        end
        if value12 ~= nil then
            value14 = value12
            break
        end
        if _G.extremelyFast then
            local RenderStepped2 = game:GetService("RunService")
            RenderStepped2 = RenderStepped2.RenderStepped
            RenderStepped2:wait()
            value10, value11 = value12, value13
        else
            wait()
            value10, value11 = value12, value13
        end
    end
    if _G.showTarget then
        SelectBoxChange(value14.HumanoidRootPart)
    end
    return value14
end

-- This used Model:SetPrimaryPartCFrame every frame while chasing. That re-seats
-- the whole rig and zeroes the assembly's velocity, so the humanoid restarted
-- from a standstill on every frame: measured 4.2 studs/s chasing versus 19.9
-- studs/s with the same MoveTo loop and no re-seating - the "tapping forward"
-- crawl. Now it turns the root part only, restores the velocity it was carrying,
-- and skips corrections too small to see.
-- `pitch` aims in full 3D instead of flattening to the character's own height.
-- The weapon's hit volume is welded to the rig, so it only ever covers what the
-- character faces: aiming flat while standing over a mob points the weapon out
-- across its head and every swing misses. Pitching tips the whole rig - head
-- down - and brings the hit volume onto the target.
function charLookAt(a, b, pitch)
    if not (a and b and b.Position) then
        return
    end
    local root = a.PrimaryPart or a:FindFirstChild("HumanoidRootPart")
    if not root then
        return
    end
    local position = root.Position
    local flat = pitch and b.Position
        or Vector3.new(b.Position.X, position.Y, b.Position.Z)
    local delta = flat - position
    if delta.Magnitude < 0.05 then
        return
    end
    if root.CFrame.LookVector:Dot(delta.Unit) > 0.9995 then
        return
    end
    local velocity = root.AssemblyLinearVelocity
    root.CFrame = CFrame.new(position, flat)
    root.AssemblyLinearVelocity = velocity
end

local function fn30()
    for k, v in pairs(tbl) do
        v:Destroy()
    end
    tbl = {}
end

local function fn31(a)
    local LocalPlayer = game.Players.LocalPlayer
    local HumanoidRootPart = LocalPlayer.Character.HumanoidRootPart
    local LocalPlayer2 = game.Players.LocalPlayer
    local Humanoid = LocalPlayer2.Character.Humanoid
    LocalPlayer4:ComputeAsync(HumanoidRootPart.Position, a)
    tbl2 = {}
    if LocalPlayer4.Status == Enum.PathStatus.Success then
        local PathfindingService = LocalPlayer4:GetWaypoints()
        tbl2 = PathfindingService
        PathfindingService = humanoid2
        if PathfindingService then
            fn30()
            for k, v in pairs(tbl2) do
                fn21(v.Position)
            end
        end
        value = 2
        local item = tbl2[value]
        if item == Enum.PathWaypointAction.Jump then
            Humanoid.Jump = true
        end
        Humanoid:MoveTo(tbl2[value].Position)
    else
        setAction("pathfinding failed", "")
        local root = value7 and (value7.PrimaryPart or (value7.Parent and value7:FindFirstChild("HumanoidRootPart")))
        if root then
            Humanoid:MoveTo(root.Position)
        else
            Humanoid:MoveTo(HumanoidRootPart.Position)
        end
    end
end

-- The enemy this is aiming at may already be gone by the time MoveToFinished
-- fires ("HumanoidRootPart is not a valid member of Model"), so look its root
-- up rather than indexing it. The second branch below always guarded; the
-- first, which is the one that fires while walking a path, did not.
-- (`value3 ~= ni` in the original was a decompiler typo for `nil`; `ni` is an
-- undefined global, so it happened to compare against nil anyway.)
local function fn32(a)
    local _, value2, value3, _ = fn23()
    local root = enemyRoot(value7)
    if value2 ~= nil and value3 ~= nil and a and #tbl2 > value then
        value = value + 1
        if root then
            charLookAt(value2, root)
        end
        value3:MoveTo(tbl2[value].Position)
    elseif value2 ~= nil and value3 ~= nil and root then
        charLookAt(value2, root)
    end
end

local function fn33(a)
    setAction("path blocked", "")
    local _, value2, _, _ = fn23()
    local root = enemyRoot(value7)
    if value2 ~= nil and root then
        charLookAt(value2, root)
    end
    if value < a then
        fn31(destination)
    end
end

local function fn34()
    local _, value7, _, _ = fn23()
    if value7 == nil then
        return
    end
    item4:AddTag(value7, "RayIgnore")
    item4:AddTag(workspace.Terrain, "RayWhitelist")
    -- workspace.tier used to exist only in the boss raid place; this build puts
    -- it in every dungeon server (0 when unused), which sent normal runs down
    -- the raid branch and threw on the missing workspace.mapModel.
    if isBossRaidPlace() and workspace:FindFirstChild("mapModel") then
        local pairs2 = pairs
        local mapModel = game:GetService("Workspace")
        mapModel = mapModel.mapModel
        local value6 = mapModel
        for k, v in pairs2(value6.GetChildren(value6)) do
            if v.ClassName == "Part"
                or v.ClassName == "UnionOperation"
                or v.ClassName == "WedgePart" then
                if v ~= value7
                    and v.Name ~= result3
                    and v.Transparency < 1
                    and v.Name ~= "enemyRadius" then
                    item4:AddTag(v, "RayWhitelist")
                end
            elseif v.ClassName == "Model" and v ~= value7 then
                item4:AddTag(v, "RayWhitelist")
            end
        end
    elseif isWaveDefensePlace() then
        local pairs3, workspace3 = pairs, workspace
        for k2, v2 in pairs3(workspace3.GetChildren(workspace3)) do
            if string.find(v2.Name, "Arena") then
                item4:AddTag(v2, "RayWhitelist")
            end
        end
    else
        local PathfindingService = fn3(workspace, "dungeon")
        local pairs4, value3 = pairs, PathfindingService
        for k4, v4 in pairs4(value3.GetChildren(value3)) do
            local pairs5, value4 = pairs, v4
            for k3, v3 in pairs5(value4.GetChildren(value4)) do
                if v3.ClassName == "Part"
                    or v3.ClassName == "UnionOperation"
                    or v3.ClassName == "WedgePart" then
                    if v3.Transparency < 1 then
                        item4:AddTag(v3, "RayWhitelist")
                    end
                elseif v3.ClassName == "Model" then
                    item4:AddTag(v3, "RayWhitelist")
                end
            end
        end
        local pairs6, workspace2 = pairs, workspace
        for k5, v5 in pairs6(workspace2.GetChildren(workspace2)) do
            if v5.ClassName == "Part"
                or v5.ClassName == "UnionOperation"
                or v5.ClassName == "WedgePart" then
                if v5 ~= value7
                    and v5.Name ~= result3
                    and v5.Transparency < 1
                    and v5.Name ~= "enemyRadius" then
                    item4:AddTag(v5, "RayWhitelist")
                end
            elseif v5.ClassName == "Model" and v5 ~= value7 then
                item4:AddTag(v5, "RayWhitelist")
            end
        end
    end
end

local function _(a, b)
    local ok = a - b
    local Unit = ok.Unit
    local PathfindingService = Vector3.new(0, 1, 0)
    local result2 = Unit:Cross(PathfindingService)
    local result3 = result2:Cross(Unit)
    return CFrame.fromMatrix(b, result2, result3)
end

function round(a)
    return math.floor(a + 0.5)
end

function roundVector(a)
    return Vector3.new(round(a.X), round(a.Y), round(a.Z))
end

local result2 = Vector3.new(0, 0, 0)
local PathfindingService = Vector3.new(1, 0, 0)

local function fn35(a, b)
    local ok = b ~= nil and b
    local _, value3, value4, value5 = fn23()
    if a.ClassName == "Model" then
        -- Same race as fn17/fn32: the destination model can lose its root the
        -- instant it dies, so there is nothing to walk to.
        local root = enemyRoot(a) or a.PrimaryPart
        if not root then
            return
        end
        PathfindingService = roundVector(root.Position)
    else
        PathfindingService = roundVector(a.Position)
    end
    if value4 ~= nil and value5 ~= nil then
        result2 = PathfindingService
        destination = PathfindingService
        if ok then
            local targetRoot = enemyRoot(value7)
            if targetRoot then
                charLookAt(value3, targetRoot)
            end
            spawn(fn30)
            value4:MoveTo(PathfindingService)
        else
            fn31(PathfindingService)
        end
    end
end

function visualRay(a)
    local PathfindingService = Instance.new("Part")
    item4:AddTag(PathfindingService, "RayIgnore")
    local workspace2 = Vector3.new(2, 2, 2)
    PathfindingService.Size = workspace2
    PathfindingService.Name = "Ray"
    PathfindingService.Anchored = true
    PathfindingService.Material = "Neon"
    PathfindingService.CanCollide = false
    workspace2 = workspace
    PathfindingService.Parent = workspace2
    game:GetService("Debris"):AddItem(PathfindingService, a)
    return PathfindingService
end

function rayCast(a, b, c, d)
    local p, p2 = b.p, a.p
    local PathfindingService = Ray.new(p2, p - p2)
    local result2 = item4:GetTagged(c)
    local _, _ = nil, nil
    local value, value2
    if d then
        local workspace3 = workspace
        local result3, value3 = workspace3:FindPartOnRayWithWhitelist(PathfindingService, result2)
        value, value2 = result3, value3
    else
        local workspace2 = workspace
        local Players3, value4 = workspace2:FindPartOnRayWithIgnoreList(PathfindingService, result2)
        value, value2 = Players3, value4
    end
    return value2, value
end

local tbl10 = {
    laserBeam = true, bossRiflePreCast = true, bossRifleShot = true, hitIndicatorIceAOE = true,
    iceBeamIndicator = true, projectile = true, mageProjectileBall = true, thirdBossSafeSpots = true,
    secondBossOrb = true, thirdBossOrbShot = true, spikePrecast = true, kolvumarTrail = true,
    ["Kraken Tentacle"] = true, secondBossRandomSquare = true, initialMageBossEntry = false,
    initialKingBossEntry = false, initialHunterBossEntry = false, thirdBossSafeSpot = false,
    forceField = false, safeSpotCircle = false, secondBossSafeSpots = false
}
local tbl11 = {
    glowPart = true, outerPrecast = true, beam = true, Beam = true, precast = true, preCast = true,
    HumanoidRootPart = true
}
local value3, value5, value6, value2, value4 = nil, nil, nil, nil, nil

local function fn36(a)
    value2 = a.Name
    if value2 == "enemyRadius" then
        return true
    end
    if a.Transparency == 1 then
        return false
    end
    value3 = tbl10[value2]
    if value3 ~= nil and value3 then
        return value3
    end
    value4 = a.Parent
    value5 = tbl10[a.Parent.Name]
    if value5 == nil then
        if stringInTable(value2, tbl6) then
            return false
        end
        value6 = tbl11[value2]
        if value6 ~= nil
            and a.ClassName == "Part"
            and value4 ~= game.Players.LocalPlayer.Character
            and value6 then
            return true
        end
        return false
    end
    return value5
end

local value26, value27 = 4, 5
local value28 = 1.4
local tbl12 = {}
local result11 = math.random(0, 4)

local function fn37()
    if _G.loadSlow then
        local RenderStepped = game:GetService("RunService")
        RenderStepped = RenderStepped.RenderStepped
        RenderStepped:wait()
    end
    local PathfindingService = Instance.new("Part")
    item4:AddTag(PathfindingService, "RayIgnore")
    local CFrame2 = Vector3.new(value26, 50, value26)
    PathfindingService.Size = CFrame2
    CFrame2 = CFrame
    local result2 = CFrame2.new(0, 100, 0)
    PathfindingService.CFrame = result2
    result2 = result3
    PathfindingService.Name = result2
    PathfindingService.Anchored = true
    PathfindingService.CanCollide = false
    PathfindingService.Material = "SmoothPlastic"
    PathfindingService.Transparency = ok11
    local ChildAdded = PathfindingService:GetPropertyChangedSignal("Transparency")
    ChildAdded:Connect(fn13)
    ChildAdded = PathfindingService.ChildAdded
    ChildAdded:Connect(fn14)
    local Players3 = BrickColor.new("Black")
    PathfindingService.BrickColor = Players3
    Players3 = result11
    if Players3 == 0 then
        if workspace:FindFirstChild("hardcore") then
            PathfindingService.Parent = workspace.hardcore
        else
            PathfindingService.Parent = workspace.raidProgress
        end
    elseif result11 == 1 then
        PathfindingService.Parent = workspace.timeLeft
    elseif result11 == 2 then
        PathfindingService.Parent = workspace.stats
    elseif result11 == 3 then
        if workspace:FindFirstChild("start") then
            PathfindingService.Parent = workspace.start
        else
            PathfindingService.Parent = workspace.dungeonStarted
        end
    elseif result11 == 4 then
        PathfindingService.Parent = workspace.Camera
    end
    PathfindingService.Touched:Connect(function()

    end)
    item(tbl12, PathfindingService)
    return PathfindingService
end

local function fn38(a)
    local tbl = {}
    for i = 1, a do
        for j = 1, a do
            if tbl[i] == nil then
                tbl[i] = {}
            end
            local item2 = tbl[i]
            if item2[j] == nil then
                local item = tbl[i]
                local tbl2 = {}
                tbl2.obj = nil
                tbl2.safe = nil
                item[j] = tbl2
            end
        end
    end
    return tbl
end

local function fn39(a)
    for i = 1, 441 do
        fn37()
    end
    local LocalPlayer = game.Players.LocalPlayer
    local _ = LocalPlayer.Character.HumanoidRootPart
    local PathfindingService = fn38(a)
    local ok = a / 2 + 0.5
    for i2 = 1, a do
        for j = 1, a do
            local result2 = item2(tbl12)
            local item = PathfindingService[i2]
            item[j].obj = result2
            local item3 = PathfindingService[i2]
            item3[j].safe = true
            if i2 ~= ok or j ~= ok then
                item4:AddTag(PathfindingService[i2][j].obj, "directionWL")
            end
        end
    end
    return PathfindingService
end

local result12 = fn39(value27)

local function _(a)
    local ok = #result12
    local _, _, _, value2 = fn23()
    if value2 ~= nil then
        local ok2, ok3, ok4, value = 0, 0, 0, 0
        local _, _, _ = nil, nil, nil
        for i = 1, ok - 1 do
            local ok6 = ok - 1 > i and 2 or 3
            for j = 0, ok6 do
                for k = 0, value do
                    local Position = value2.Position
                    local Instance2 = Vector3.new(ok2, 0, ok3)
                    local ok5 = Position + Instance2
                    Instance2 = Instance
                    local PathfindingService = Instance2.new("Part")
                    PathfindingService.Anchored = true
                    PathfindingService.CanCollide = false
                    PathfindingService.Position = ok5
                    local workspace2 = Vector3.new(2, 2, 2)
                    PathfindingService.Size = workspace2
                    workspace2 = workspace
                    PathfindingService.Parent = workspace2
                    if ok4 == 0 then
                        ok3 = ok3 + 5
                    elseif ok4 == 1 then
                        ok2 = ok2 + 5
                    elseif ok4 == 2 then
                        ok3 = ok3 - 5
                    elseif ok4 == 3 then
                        ok2 = ok2 - 5
                    end
                end
                local value3, value4 = ok2, ok3
                ok4 = (ok4 + 1) % 4
                ok2, ok3 = value3, value4
            end
            ok2, ok3, ok4, value = ok2, ok3, ok4, value + 1
        end
    end
end

local function fn40()
    local _, _, _, value2 = fn23()
    if value2 ~= nil then
        local ok = #result12
        local ok2 = (ok - 1) * value26 / 2 * -1 / value28
        local ok3 = (ok - 1) * value26 / 2 * -1 / value28
        local _, _, _ = nil, nil, nil
        for k3, v3 in pairs(result12) do
            for k2, v2 in pairs(v3) do
                local value = v2
                local obj = value.obj
                if value2 ~= nil and obj ~= nil then
                    local CFrame2 = value2.CFrame
                    local PathfindingService = CFrame.new(ok2, 0, ok3)
                    obj.CFrame = CFrame2 * PathfindingService
                    PathfindingService = obj
                    local result3 = PathfindingService:GetTouchingParts()
                    local pairs2 = BrickColor.new("Black")
                    obj.BrickColor = pairs2
                    value.safe = true
                    pairs2 = pairs
                    for k, v in pairs2(result3) do
                        if fn36(v) then
                            local result2 = BrickColor.new("Bright red")
                            obj.BrickColor = result2
                            value.safe = false
                            break
                        end
                    end
                end
                ok3 = ok3 + value26 / value28
            end
            ok3 = (ok - 1) * value26 / 2 * -1 / value28
            ok2 = ok2 + value26 / value28
        end
    end
end

local function fn41()
    for k, v in pairs(result12) do
        if #tbl12 == 0 then
            fn37()
        end
        local PathfindingService = item2(tbl12)
        local tbl3 = { obj = PathfindingService }
        item(result12[k], 1, tbl3)
        if #tbl12 == 0 then
            fn37()
        end
        PathfindingService = item2(tbl12)
        local tbl4 = { obj = PathfindingService }
        item(result12[k], tbl4)
    end
    local tbl = {}
    for k2, v2 in pairs(result12[1]) do
        if #tbl12 == 0 then
            fn37()
        end
        local result2 = item2(tbl12)
        local tbl5 = { obj = result2 }
        item(tbl, tbl5)
    end
    local tbl2 = {}
    for k3, v3 in pairs(result12[1]) do
        if #tbl12 == 0 then
            fn37()
        end
        local tbl6 = item2(tbl12)
        tbl6 = { obj = tbl6 }
        item(tbl2, tbl6)
    end
    item(result12, 1, tbl)
    item(result12, tbl2)
end

local function fn42()
    for k, v in pairs(result12) do
        local PathfindingService = item2(result12[k], #result12[k])
        if PathfindingService ~= nil then
            local obj = PathfindingService.obj
            local result2 = CFrame.new(0, 0, 0)
            obj.CFrame = result2
            local value4 = item
            result2 = tbl12
            value4(result2, PathfindingService.obj)
            local result3 = item2(result12[k], 1)
            local obj2 = result3.obj
            local Players3 = CFrame.new(0, 0, 0)
            obj2.CFrame = Players3
            local value5 = item
            Players3 = tbl12
            value5(Players3, result3.obj)
        end
    end
    local LocalPlayer4 = item2(result12, #result12)
    for k2, v2 in pairs(LocalPlayer4) do
        if v2 ~= nil then
            local obj3 = v2.obj
            local part = CFrame.new(0, 0, 0)
            obj3.CFrame = part
            local value6 = item
            part = tbl12
            value6(part, v2.obj)
        end
    end
    local result8 = item2(result12, 1)
    for k3, v3 in pairs(result8) do
        if v3 ~= nil then
            local obj4 = v3.obj
            local VirtualUser = CFrame.new(0, 0, 0)
            obj4.CFrame = VirtualUser
            local value7 = item
            VirtualUser = tbl12
            value7(VirtualUser, v3.obj)
        end
    end
end

local ok5, value10, ok6 = false, nil, false

function checkAroundPlayer(a, b)
    local ok = b / 2 + 0.5
    for i = #a - ok, value27 do
        local item = a[i]
        local item2 = item[i]
        if not item2.safe then
            return false
        end
    end
    return true
end

local function _(a, b)
    local ok = b / 2 + 0.5
    local item = a[ok]
    local item2 = item[ok]
    return item2.safe
end

local function fn43()
    local PathfindingService = fn29()
    value7 = PathfindingService
    PathfindingService = value15
    local value
    if value7 ~= nil and value7.Name ~= "Azrallik's Heart" and value7.Name ~= "Dragon Orb" then
        value7:WaitForChild("enemyStyle")
        local Value = value7.enemyStyle.Value
        if Value == "mob" or Value == "ranged" or Value == "melee" or Value == "burly" then
            if ok3 then
                local pairs2, workspace2 = pairs, workspace
                for k, v in pairs2(workspace2.GetChildren(workspace2)) do
                    if tbl7[v.Name] then
                        v:Destroy()
                    end
                end
            end
            ok3 = false
            value = PathfindingService
        else
            value = value16
            ok3 = true
        end
    else
        value = PathfindingService
    end
    local _, _, _, value26 = fn23()
    if value26 ~= nil and value7 ~= nil then
        local Position = value7.PrimaryPart.Position
        local result2 = Vector3.new(Position.X, value26.Position.Y, Position.z)
        local ok = fn22(result2, value26.Position)
        ok = ok - value7.PrimaryPart.Size.Z / 2
        fn40()
        -- The grid probe doubles as the strafe marker; park it on the character
        -- so it is not left sitting at the world origin (the stray ball) and so
        -- chase_fobjective cannot walk you there.
        if result9 and value26 then
            result9.CFrame = value26.CFrame
        end
        if ok6 then
            return "chase_fobjective", nil
        end
        if checkAroundPlayer(result12, #result12) then
            if ok5 and value10 ~= nil then
                game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 24
                return "chase_objective", nil
            end
            if value - 5 > ok then
                game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 24
                return "run", nil
            end
            if ok < value then
                game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 24
                return "strafe", nil
            end
            if ok3 then
                game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 24
            else
                game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 30
            end
            return "chase", nil
        end
        if not ok3 and _G.teleportDuringBossOnly then
            game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 30
        else
            game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 24
        end
        return "dodge", nil
    end
    return "nothing"
end

-- Instakill works by owning the enemy's assembly so a client-side Health write
-- replicates. The old build claimed that ownership by pushing SimulationRadius
-- to infinity; keep doing that (plus the executor's own setter, which some
-- builds honour) but no longer assume it took - tryInstakill probes the result.
do
    local RenderStepped = game:GetService("RunService")
    RenderStepped = RenderStepped.RenderStepped
    RenderStepped:connect(function()
        if not _G.doInstakill then
            return
        end
        local LocalPlayer = game:GetService("Players").LocalPlayer
        if setsimulationradius then
            pcall(setsimulationradius, math.huge, math.huge)
        end
        if sethiddenproperty then
            pcall(sethiddenproperty, LocalPlayer, "SimulationRadius", math.huge)
        end
    end)
end
local value8, value9
value118, value8, value9 = nil, nil, nil
local ok4 = true;
(function()
    spawn(function()
        local _, _, _, _ = fn23()
        while not ok2 do
            -- One error used to kill this thread outright: the marker ball froze
            -- on the spot ("disconnected"), nothing was chased again, and the
            -- farm looked dead while every other thread carried on. A target
            -- dying at the wrong moment is routine, so absorb it and take the
            -- next iteration instead of losing the loop.
            local iterationOk, iterationErr = pcall(function()
            local _, _, value54, value55 = fn23()
            local value, value2 = value55, value54
            if value ~= nil and value2 ~= nil and value2.Health > 0 then
                spawn(function()
                    game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = value17
                end)
                local result21, _ = fn43()
                setAction(farmActionNames[result21] or result21, value7 and value7.Name or "")
                if result21 == "chase" then
                    local reached = false
                    local anchor, needsPad = attackAnchor(value7)
                    -- An above/below anchor is in mid-air, so it always has to be
                    -- placed - there is no walking to it. Gating this behind
                    -- shouldTeleportTo meant that in "far" mode the anchor was
                    -- thrown away the moment you got within fighting range, and
                    -- the mode quietly collapsed back to standing on the floor.
                    if anchor and (needsPad or shouldTeleportTo(value7)) then
                        reached = teleportToward(
                            anchor,
                            tonumber(_G.attack_distance) or 10,
                            needsPad
                        )
                        if reached then
                            setAction(needsPad and (_G.attack_position .. " target") or "teleporting to", value7.Name)
                        end
                    else
                        clearHoverPad()
                    end
                    if needsPad then
                        holdAimAt(value7)
                    end
                    if not reached then
                        local _, value56 = rayCast(value.CFrame, value7.PrimaryPart.CFrame, "RayWhitelist", true)
                        value8 = value56
                        if value8 == nil then
                            fn35(value7, true)
                        else
                            fn35(value7)
                        end
                    end
                elseif result21 == "chase_objective" then
                    if value10 ~= nil and value10.ClassName == "Model" then
                        local rayCast8 = rayCast
                        local CFrame18 = value.CFrame
                        local precast8 = CFrame.new(0, 0, 0)
                        local ok19 = CFrame18 * precast8
                        precast8 = value10
                        local CFrame19 = precast8.PrimaryPart.CFrame
                        local result18 = CFrame.new(0, 4, 0)
                        local ok20 = CFrame19 * result18
                        result18 = "RayWhitelist"
                        local _, value57 = rayCast8(ok19, ok20, result18, true)
                        value8 = value57
                    elseif value10 ~= nil then
                        local rayCast9 = rayCast
                        local CFrame20 = value.CFrame
                        local result19 = CFrame.new(0, 0, 0)
                        local ok21 = CFrame20 * result19
                        result19 = value10
                        local CFrame21 = result19.CFrame
                        local result20 = CFrame.new(0, 4, 0)
                        local ok22 = CFrame21 * result20
                        result20 = "RayWhitelist"
                        local _, value58 = rayCast9(ok21, ok22, result20, true)
                        value8 = value58
                    end
                    if value8 == nil then
                        fn35(value10, true)
                    else
                        fn35(value10)
                    end
                elseif result21 == "chase_fobjective" then
                    local _, value59 = rayCast(value.CFrame, result9.CFrame, "RayWhitelist", true)
                    value8 = value59
                    if value8 == nil then
                        fn35(result9, true)
                    else
                        fn35(result9)
                    end
                elseif result21 == "strafe" then
                    local rayCast6 = rayCast
                    local CFrame12 = value.CFrame
                    local CFrame13 = value.CFrame
                    local result8 = CFrame.new(1000, 0, 0)
                    local ok17 = CFrame13 * result8
                    result8 = "RayWhitelist"
                    local result22, _ = rayCast6(CFrame12, ok17, result8, true)
                    local rayCast7 = rayCast
                    local CFrame14 = value.CFrame
                    local CFrame15 = value.CFrame
                    local result10 = CFrame.new(-1000, 0, 0)
                    local ok18 = CFrame15 * result10
                    result10 = "RayWhitelist"
                    local result11 = rayCast7(CFrame14, ok18, result10, true)
                    local result13 = fn22(value.Position, result22)
                    local LocalPlayer5 = fn22(value.Position, result11)
                    if math.abs(result13 - LocalPlayer5) < 5 then
                        result9.CFrame = value.CFrame
                    elseif LocalPlayer5 < result13 then
                        local value49 = result9
                        local CFrame17 = value.CFrame
                        local result16 = CFrame.new(5, 0, 0)
                        value49.CFrame = CFrame17 * result16
                    else
                        local value48 = result9
                        local CFrame16 = value.CFrame
                        local result15 = CFrame.new(-5, 0, 0)
                        value48.CFrame = CFrame16 * result15
                    end
                    fn35(result9, true)
                elseif result21 == "run" then
                    local rayCast4 = rayCast
                    local CFrame6 = value.CFrame
                    local CFrame7 = CFrame.new(0, 0, 0)
                    local ok10 = CFrame6 * CFrame7
                    CFrame7 = value.CFrame
                    local part = CFrame.new(0, 0, 25)
                    local ok11 = CFrame7 * part
                    part = "RayWhitelist"
                    local _, value60 = rayCast4(ok10, ok11, part, true)
                    value8 = value60
                    if value8 == nil then
                        local value45 = result9
                        local CFrame11 = value.CFrame
                        local ok16 = CFrame.new(0, 0, 25)
                        value45.CFrame = CFrame11 * ok16
                        local value46 = fn35
                        local value47 = result9
                        ok16 = true
                        value46(value47, ok16)
                    else
                        local LocalPlayer6 = false
                        for i = 1, 20 do
                            if LocalPlayer6 then
                                break
                            end
                            local ok13 = LocalPlayer6
                            for j = 1, 2 do
                                local LocalPlayer7 = i * 9
                                if j == 1 then
                                    LocalPlayer7 = LocalPlayer7 * -1
                                end
                                local rayCast5 = rayCast
                                local CFrame8 = value.CFrame
                                local CFrame9 = value.CFrame
                                local VirtualUser = CFrame.new(LocalPlayer7, -2, 25 - i)
                                local ok15 = CFrame9 * VirtualUser
                                VirtualUser = "RayWhitelist"
                                local _, value61 = rayCast5(CFrame8, ok15, VirtualUser, true)
                                value8 = value61
                                if value8 == nil then
                                    ok13 = true
                                    local value44 = result9
                                    local CFrame10 = value.CFrame
                                    local LocalPlayer4 = CFrame.new(LocalPlayer7, -2, 25 - i)
                                    value44.CFrame = CFrame10 * LocalPlayer4
                                    break
                                end
                            end
                            LocalPlayer6 = ok13
                        end
                        fn35(result9, true)
                    end
                elseif result21 == "dodge" then
                    local value3, huge = nil, math.huge
                    local _, _ = nil, nil
                    local ok = false
                    local ok6 = #result12 / 2 + 0.5
                    while value3 == nil do
                        if value == nil then
                            break
                        end
                        if value2 == nil then
                            break
                        end
                        if not (value2.Health > 0) then
                            break
                        end
                        local item4 = result12[ok6][ok6]
                        if item4.safe then
                            local item = result12[ok6]
                            value3, huge, ok = item[ok6].obj, huge, true
                            break
                        end
                        for k2, v2 in pairs(result12) do
                            for k, v in pairs(v2) do
                                local item2 = result12[k2]
                                local item3 = item2[k]
                                local PathfindingService = math.floor(fn22(value.Position, item3.obj.Position) + 0.5)
                                if item3.safe and PathfindingService < huge then
                                    local rayCast2 = rayCast
                                    local CFrame2 = value.CFrame
                                    local CFrame3 = CFrame.new(0, 0, 0)
                                    local humanoid2 = CFrame2 * CFrame3
                                    CFrame3 = CFrame
                                    local ok8 = CFrame3.new(item3.obj.Position, value.Position)
                                    local result2 = CFrame.new(0, 0, value26 / 2)
                                    ok8 = ok8 * result2
                                    result2 = "RayWhitelist"
                                    local _, value62 = rayCast2(humanoid2, ok8, result2, true)
                                    value8 = value62
                                    if value8 == nil then
                                        local obj2 = item3.obj
                                        value3, huge = obj2, PathfindingService
                                    else
                                        local obj = item3.obj
                                        local result3 = BrickColor.new("Bright yellow")
                                        obj.BrickColor = result3
                                    end
                                end
                            end
                        end
                        if value3 ~= nil then
                            break
                        end
                        fn41()
                        fn40()
                        if _G.extremelyFast then
                            local RenderStepped = game:GetService("RunService")
                            RenderStepped = RenderStepped.RenderStepped
                            RenderStepped:wait()
                        else
                            wait()
                        end
                    end
                    local _, _, value63, value64 = fn23()
                    local value4 = value64
                    if value3 ~= nil and value4 ~= nil and value63 ~= nil then
                        repeat
                            if not ok then
                                result9.CFrame = value3.CFrame
                                break
                            end
                            do
                                if ok5 then
                                    if value10 == nil or value10.ClassName ~= "Model" then
                                        if value10 ~= nil then
                                            local new = Vector3.new
                                            local X = value10.Position.X
                                            local Y = value4.Position.Y
                                            local Position = value10.Position
                                            value9 = new(X, Y, Position.Z)
                                        end
                                    else
                                        value9 = Vector3.new(value10.PrimaryPart.Position.X, value4.Position.Y, value10.PrimaryPart.Position.Z)
                                    end
                                else
                                    value9 = Vector3.new(value7.PrimaryPart.Position.X, value4.Position.Y, value7.PrimaryPart.Position.Z)
                                end
                                local rayCast3 = rayCast
                                local CFrame4 = value4.CFrame
                                local CFrame5 = CFrame.new(0, 0, 0)
                                local humanoid = CFrame4 * CFrame5
                                CFrame5 = CFrame
                                local _, value65 = rayCast3(humanoid, CFrame5.new(value9), "directionWL", true)
                                value8 = value65
                                if not (value8 == nil
                                    or value8.BrickColor ~= BrickColor.new("Black")) then
                                    if ok5 then
                                        result9.CFrame = value8.CFrame
                                        break
                                    end
                                    local result23 = fn22(value7.PrimaryPart.Position, value4.Position)
                                    if value16 < result23 then
                                        result9.CFrame = value8.CFrame
                                        break
                                    end
                                    result9.CFrame = value4.CFrame
                                    break
                                end
                            end
                            result9.CFrame = value3.CFrame
                        until true
                        local Players3 = BrickColor.new("Lime green")
                        value3.BrickColor = Players3
                        if ok then
                            game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = value3.CFrame
                            fn35(result9, true)
                        elseif _G.smallTeleportVal > huge and _G.SemiTeleports and ok4 then
                            if not _G.teleportDuringBossOnly or ok3 then
                                ok4 = false
                                game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = result9.CFrame
                                fn35(result9, true)
                                spawn(function()
                                    wait(0.1)
                                    ok4 = true
                                end)
                            else
                                fn35(result9, true)
                            end
                        else
                            fn35(result9, true)
                        end
                    end
                    while true do
                        local ok23 = #result12
                        if not (value27 < ok23) then
                            break
                        end
                        fn42()
                        if _G.extremelyFast then
                            local RenderStepped2 = game:GetService("RunService")
                            RenderStepped2 = RenderStepped2.RenderStepped
                            RenderStepped2:wait()
                        else
                            wait()
                        end
                    end
                end
            end
            end)
            if not iterationOk then
                ScriptDebug("[farm] recovered: " .. tostring(iterationErr))
            end
            if _G.extremelyFast then
                local RenderStepped3 = game:GetService("RunService")
                RenderStepped3 = RenderStepped3.RenderStepped
                RenderStepped3:wait()
            else
                wait()
            end
        end
    end)
end)()

local function fn44()
    while true do
        if game.Players.LocalPlayer:FindFirstChild("Backpack") then
            break
        end
        wait()
    end
    while not ok2 do
        if not _G.auto_attack then
            wait(0.2)
            continue
        end
        if _G.ignoreAbilityRange then
            local RenderStepped = game:GetService("RunService")
            RenderStepped = RenderStepped.RenderStepped
            RenderStepped:wait()
        else
            wait()
        end
        local Players = game.Players
        char = Players.LocalPlayer.Character
        if value7 ~= nil
            and value7.PrimaryPart ~= nil
            and char ~= nil
            and char.PrimaryPart ~= nil
            and (fn22(value7.PrimaryPart.Position, char.PrimaryPart.Position) - value7.PrimaryPart.Size.Z / 2 < value14
                or _G.ignoreAbilityRange) then
            local pairs2, Backpack = pairs, game.Players.LocalPlayer.Backpack
            for k, v in pairs2(Backpack.GetChildren(Backpack)) do
                if v:FindFirstChildOfClass("RemoteEvent") and v.cooldown.Value <= 0 then
                    v:FindFirstChildOfClass("RemoteEvent"):FireServer()
                end
            end
        end
    end
end

local function fn45()
    local pairs2 = game.Players.LocalPlayer.Character:GetChildren()
    player = pairs2
    pairs2 = pairs
    for k, v in pairs2(player) do
        if v.ClassName == "Accessory"
            and v:FindFirstChild("swing")
            and v:FindFirstChild("attackSpeed") then
            local swing = v.swing
            return swing, v.attackSpeed.Value
        end
    end
end

-- These loops used to be spawned only if auto_attack was on at load, so the
-- menu toggle did nothing either way. They always run now and check per tick.
spawn(fn44)
do
    spawn(function()
        while not ok2 do
            if not _G.auto_attack then
                wait(0.2)
                continue
            end
            local PathfindingService, value = fn45()
            cooldown = value
            sword = PathfindingService
            local Players = game.Players
            player = Players.LocalPlayer.Character
            if value7 ~= nil
                and value7.PrimaryPart ~= nil
                and player ~= nil
                and player.PrimaryPart ~= nil
                and cooldown ~= nil
                and fn22(value7.PrimaryPart.Position, player.PrimaryPart.Position) - value7.PrimaryPart.Size.Z / 2 < 13 then
                wait(cooldown / 10)
                local sword2 = sword
                sword2:FireServer()
            end
            wait()
        end
    end)
end

local function fn46(a)
    a:WaitForChild("precast")
    local tbl = {}
    tbl.bestVal = math.huge
    tbl.bestObj = nil
    tbl.dist = nil
    tbl.newPoint = nil
    local _, _, _, _ = fn23()
    local pairs2, value = pairs, a
    for k, v in pairs2(value.GetChildren(value)) do
        if v.Name == "hitBox" then
            local dist = fn22(game.Players.LocalPlayer.Character.HumanoidRootPart.Position, v.Position)
            tbl.dist = dist
            v.Transparency = 0.9
            dist = tbl.dist
            if tbl.bestVal > dist then
                tbl.bestVal = tbl.dist
                tbl.bestObj = v
            end
        elseif v.Name == "cog" then
            v:Destroy()
        end
    end
    local bestObj = tbl.bestObj
    local CFrame2 = BrickColor.new("Lime Green")
    bestObj.BrickColor = CFrame2
    local CFrame3 = tbl.bestObj.CFrame
    CFrame2 = CFrame
    local bestObj2 = CFrame2.new(0, 0, tbl.bestObj.Size.Z / -2 + 5)
    local ok = CFrame3 * bestObj2
    local Position = ok.Position
    bestObj2 = tbl.bestObj
    local CFrame4 = bestObj2.CFrame
    local PathfindingService = CFrame.new(0, 0, tbl.bestObj.Size.Z / 2 - 5)
    local ok2 = CFrame4 * PathfindingService
    local Position2 = ok2.Position
    PathfindingService = fn22
    if PathfindingService(value7.PrimaryPart.Position, Position) < fn22(value7.PrimaryPart.Position, Position2) then
        return Position
    end
    return Position2
end

local function fn47(a)
    local Union, Union2 = workspace.secondBossRockPile2.Union, workspace.secondBossRockPile1.Union
    if (Union.Position - a.PrimaryPart.Position).Magnitude < (Union2.Position - a.PrimaryPart.Position).Magnitude then
        return Union
    end
    return Union2
end

local tbl13 = { forceFieldCounter = 0, gotRock = false }
tbl13.gyzerTable = {}
tbl13.gyzerLoopRunning = false

local function fn48(a)
    local LocalPlayer = game.Players.LocalPlayer
    local HumanoidRootPart = LocalPlayer.Character.HumanoidRootPart
    local PrimaryPart = a.PrimaryPart
    local PathfindingService = Instance.new("Part")
    local CFrame2 = CFrame.new(PathfindingService.Position, HumanoidRootPart.Position)
    PathfindingService.CFrame = CFrame2
    CFrame2 = PrimaryPart.CFrame
    local result2 = CFrame.new(0, 10, -60)
    PathfindingService.CFrame = CFrame2 * result2
    local new = Vector3.new
    result2 = 14
    local workspace2 = new(result2, 5, 128)
    PathfindingService.Size = workspace2
    workspace2 = workspace
    PathfindingService.Parent = workspace2
    PathfindingService.CanCollide = false
    PathfindingService.Transparency = 1
    PathfindingService.Anchored = true
    PathfindingService.Name = "enemyRadius"
    wait(3)
    PathfindingService:Destroy()
end

workspace.ChildAdded:Connect(function(a)
    if a.Name == result3 then
        return
    end
    if a.Name == "firstBossMoveOrb" then
        fn17(a, 27, "rectanglev3")
    elseif a.Name == "secondBossSlamHitbox" then
        local hitBox2 = a:WaitForChild("hitBox")
        if hitBox2.Size.Z == 10
            and hitBox2.Size.Y == 150
            and hitBox2.Size.X % 10 == 0
            and hitBox2.Size.X >= 10
            and hitBox2.Size.X <= 150 then
            local part2 = Instance.new("Part")
            part2.Anchored = true
            part2.CanCollide = false
            part2.Transparency = 0.5
            part2.CFrame = hitBox2.CFrame
            local workspace2 = Vector3.new(hitBox2.Size.X + 7, 5, 800)
            part2.Size = workspace2
            part2.Name = "enemyRadius"
            workspace2 = workspace
            part2.Parent = workspace2
            local result28
            repeat
                wait()
                if a == nil then
                    break
                end
                result28 = a:IsDescendantOf(workspace)
            until not result28
            part2:Destroy()
        end
    elseif a.Name == "thirdBossOrbCircle" or a.Name == "finalBossOrbShot" then
        fn17(a, 30, "rectangle-2")
    elseif a.Name == "firstBossFollowOrb" then
        fn17(a, 25, "rectangle-2")
    elseif a.Name == "mageProjectileBall" then
        fn17(a, 10, "rectangle")
    elseif a.Name == "secondBossCrescent" then
        fn17(a, 12, "square")
    elseif a.Name == "secondBossOrb" then
        fn17(a, 12, "rectanglev3")
    elseif a.Name == "secondBossStabProjectile" then
        fn17(a, 15, "rectangle-2")
    elseif a.Name == "gasBall" then
        fn17(a, 10, "rectangle")
    elseif a.Name == "tornado" then
        fn17(a, 20, "square")
    elseif a.Name == "thirdBossOrbShot" then
        fn17(a, 26, "rectanglev2")
    elseif a.Name == "Kraken Tentacle" then
        local ok8 = true
        a:WaitForChild("Humanoid")
        while a.Parent ~= nil do
            if not a:FindFirstChild("Humanoid") then
                break
            end
            if not (a.Humanoid.Health > 0) then
                break
            end
            local humanoid = a.Humanoid:GetPlayingAnimationTracks()
            humanoid = #humanoid
            if humanoid == 2 and ok8 then
                fn48(a)
                wait(3)
                ok8 = true
            end
            wait()
        end
    elseif a.Name == "Kraken Tentacle" then
        local ok4 = true
        a:WaitForChild("Humanoid")
        while a.Parent ~= nil do
            if not a:FindFirstChild("Humanoid") then
                break
            end
            if not (a.Humanoid.Health > 0) then
                break
            end
            local humanoid2 = a.Humanoid:GetPlayingAnimationTracks()
            humanoid2 = #humanoid2
            if humanoid2 == 2 and ok4 then
                fn48(a)
                wait(3)
                ok4 = true
            end
            wait()
        end
    elseif a.Name == "overheadCannon" then
        print("got cannon")
        ok5 = true
        local playerFireCannon = game:GetService("Workspace")
        playerFireCannon = playerFireCannon.playerFireCannon
        value10 = playerFireCannon.ring
        spawn(function()
            while a ~= nil and a.Parent ~= nil do
                wait()
            end
            if workspace.playerFireCannonHitMark.Transparency == 1 then
                print("obj done")
                value10 = nil
                ok5 = false
            else
                print("chara prob died, get new cannon")
                value10 = workspace.playerPickupCannonballRing
                ok5 = true
            end
        end)
    elseif a.Name == "secondBossGeyser" then
        a:WaitForChild("PrimaryPart")
        spawn(function()
            local ok = #tbl13.gyzerTable + 1
            item(tbl13.gyzerTable, a)
            while a ~= nil and a.Parent ~= nil do
                wait()
            end
            print("remove gyzzer instance")
            item2(tbl13.gyzerTable, ok)
        end)
        spawn(function()
            if tbl13.gyzerLoopRunning then
                return
            end
            ok5 = true
            tbl13.gyzerLoopRunning = true
            while true do
                if workspace.secondBossRockPile2.Union.Transparency == 1 then
                    break
                end
                if #tbl13.gyzerTable == 0 then
                    break
                end
                if tbl13.gotRock then
                    value10 = tbl13.gyzerTable[#tbl13.gyzerTable]
                else
                    value10 = fn47(tbl13.gyzerTable[#tbl13.gyzerTable])
                end
                wait()
            end
            tbl13.gyzerLoopRunning = false
            if #tbl13.gyzerTable ~= 0 and workspace.secondBossRockPile2.Union.Transparency ~= 1 then
                return
            end
            value10 = nil
            ok5 = false
        end)
    elseif a.Name == "secondBossOverheadRock" then
        tbl13.gotRock = true
        while true do
            if not workspace:FindFirstChild("secondBossOverheadRock")
                or workspace.secondBossRockPile2.Union.Transparency == 1 then
                break
            end
            wait()
        end
        tbl13.gotRock = false
    elseif a.Name == "thirdBossSafeSpots" then
        ok6 = true
        local result22 = fn46(a)
        local value19 = result9
        local result23 = CFrame.new(result22)
        value19.CFrame = result23
        while true do
            if not workspace:FindFirstChild(a.Name)
                or not workspace[a.Name]:FindFirstChild("precast")
                or not (workspace[a.Name]:FindFirstChild("precast").Transparency < 1) then
                break
            end
            local result24 = fn46(a)
            local value21 = result9
            local result25 = CFrame.new(result24)
            value21.CFrame = result25
            wait()
        end
        ok6 = false
    elseif a.Name == "thirdBossSpreadLine" then
        a:WaitForChild("precast")
        local result20 = a.precast:Clone()
        result20.Parent = workspace
        result20.Transparency = 1
        local Size12 = a.precast.Size
        local result21 = Vector3.new(2, 0, 0)
        result20.Size = Size12 + result21
        result20.Name = "enemyRadius"
        local wait5 = wait
        result21 = 1.4
        wait5(result21)
        result20:Destroy()
        a.precast.Name = "precast"
    elseif a.Name == "firstBossLaserPrecast" then
        a:WaitForChild("precast")
        wait(0.5)
        if a:FindFirstChild("precast") then
            local result19 = a.precast:Clone()
            result19.Parent = workspace
            result19.Transparency = 1
            result19.Size = a.precast.Size
            result19.Name = "enemyRadius"
            wait(1)
            result19:Destroy()
        end
    elseif a.Name == "secondBossSlamHitbox" then
        local precast8 = a:WaitForChild("precast")
        local ok3 = 0 + precast8.Size.X + precast8.Size.Z + precast8.Size.Y
        warn(ok3)
        if ok3 == 46.431163787842 then
            ok6 = true
            local value17 = result9
            local result18 = CFrame.new(-2653.086, 196.526, 2325.825)
            value17.CFrame = result18
            local wait4 = wait
            result18 = 5
            wait4(result18)
            ok6 = false
        end
    elseif a.Name == "preCast" then
        a:WaitForChild("preCast")
        local preCast = a.preCast
        local Size11 = a.preCast.Size
        local result16 = Vector3.new(0, 0, 3)
        preCast.Size = Size11 + result16
    elseif a.Name == "riflemanShot" then
        a:WaitForChild("hitBox")
        local hitBox = a.hitBox
        local Size10 = a.hitBox.Size
        local result15 = Vector3.new(0, 0, 3)
        hitBox.Size = Size10 + result15
    elseif a.Name == "firstBossGatlingGunShot" then
        a:WaitForChild("precast")
        local precast7 = a.precast
        local Size9 = a.precast.Size
        local LocalPlayer5 = Vector3.new(1, 0, 0)
        precast7.Size = Size9 + LocalPlayer5
    elseif a.Name == "firstBossFlameShot" then
        a:WaitForChild("precast")
        local precast6 = a.precast
        local Size8 = a.precast.Size
        local result13 = Vector3.new(1, 0, 0)
        precast6.Size = Size8 + result13
    elseif a.Name == "chickenMage" then
        a:WaitForChild("precast")
        local precast5 = a.precast
        local Size7 = a.precast.Size
        local result12 = Vector3.new(0, 0, 3)
        precast5.Size = Size7 + result12
    elseif a.Name == "droneShot" then
        a:WaitForChild("shot")
        wait()
        local pairs3, value9 = pairs, a
        for k, v in pairs3(value9.GetChildren(value9)) do
            if v.Name == "shot" then
                local precast4 = v.precast
                local Size6 = v.precast.Size
                local result11 = Vector3.new(1.2, 0, 0)
                precast4.Size = Size6 + result11
            end
        end
    elseif a.Name == "poisonBomb" then
        a:WaitForChild("eggPart")
        a:WaitForChild("fuse")
        a:WaitForChild("PrimaryPart")
        a:WaitForChild("Union")
        a.eggPart.Name = "enemyRadius"
        a.fuse.Name = "enemyRadius"
        a.PrimaryPart.Name = "enemyRadius"
        a.Union.Name = "enemyRadius"
    elseif a.Name == "rangeMobShot" then
        a:WaitForChild("precast")
        local precast3 = a.precast
        local Size5 = a.precast.Size
        local result10 = Vector3.new(1.5, 0, 3)
        precast3.Size = Size5 + result10
    elseif a.Name == "chickenMage" then
        a:WaitForChild("precast")
        local precast2 = a.precast
        local Size4 = a.precast.Size
        local result8 = Vector3.new(0, 0, 3)
        precast2.Size = Size4 + result8
    elseif a.Name == "npcMageShot" then
        a:WaitForChild("precast")
        local precast = a.precast
        local Size3 = a.precast.Size
        local LocalPlayer4 = Vector3.new(0, 0, 3)
        precast.Size = Size3 + LocalPlayer4
    elseif a.Name == "iceBeamIndicator" then
        a:WaitForChild("Part")
        local Part = a.Part
        local Size2 = a.Part.Size
        local VirtualUser = Vector3.new(0, 3, 3)
        Part.Size = Size2 + VirtualUser
    elseif a.Name == "hitIndicatorIceAOE" then
        a:WaitForChild("Part")
        a.Part.Transparency = 0
    elseif a.Name == "thirdBossLifeStealBeams" then
        local value8 = fn15
        local CFrame2 = value7.PrimaryPart.CFrame
        local Vector32 = CFrame.new(0, 0, -75)
        local ok2 = CFrame2 * Vector32
        Vector32 = Vector3
        local Players3 = Vector32.new(40, 40, 150)
        local part = value8(ok2, Players3, "enemyRadius", "Block")
        local wait3 = wait
        Players3 = 1.5
        wait3(Players3)
        part:Destroy()
    elseif a.Name == "silkBlast" then
        local PathfindingService = a:WaitForChild("precast"):Clone()
        local Size = a.precast.Size
        local result2 = Vector3.new(3, 5, 3)
        PathfindingService.Size = Size + result2
        PathfindingService.Name = "enemyRadius"
        PathfindingService.Transparency = 0
        PathfindingService.Parent = workspace
        local wait2 = wait
        result2 = 5.5
        wait2(result2)
        PathfindingService:Destroy()
    elseif a.Name == "thirdBossSafeSpot" then
        ok5 = true
        while true do
            if a:FindFirstChild("precast") then
                break
            end
            wait()
        end
        value10 = a
        while true do
            if not workspace:FindFirstChild(value10.Name)
                or not workspace:FindFirstChild(value10.Name):FindFirstChild("precast")
                or not (workspace:FindFirstChild(value10.Name).precast.Transparency > 0) then
                break
            end
            wait()
        end
        value10 = nil
        ok5 = false
    elseif a.Name == "safeSpotCircle" then
        ok5 = true
        value10 = a
        while a ~= nil
            and workspace:FindFirstChild(a.Name)
            and workspace:FindFirstChild(a.Name).Transparency > 0 do
            wait()
        end
        value10 = nil
        ok5 = false
    elseif a.Name == "forceField" then
        tbl13.forceFieldCounter = tbl13.forceFieldCounter + 1
        ok5 = true
        value10 = a
        if tbl13.forceFieldCounter == 2 then
            tbl13.forceFieldCounter = 0
            ok5 = false
            value10 = nil
        end
    elseif a.ClassName == "Model" then
        if a.Name == "Kraken Tentacle" then
            return
        end
        a:WaitForChild("HumanoidRootPart", 10)
        if a ~= nil and a:FindFirstChild("HumanoidRootPart") then
            local Players = game.Players
            local Character = Players.LocalPlayer.Character
            if a ~= Character then
                if a.Name == "Azrallik's Heart" or a.Name == "Dragon Orb" then
                    item4:AddTag(a, "Prio-Enemy")
                elseif a.Name == "Blood Minion"
                    or a.Name == "Infected Pirate"
                    or a.Name == "Ice Minion"
                    or a.Name == "Tracking Minion"
                    or a.Name == "Stone Minion"
                    or a.Name == "Flame Minion" then
                    a:WaitForChild("Humanoid")
                    fn17(a, 5, "square")
                    a.Humanoid.Health = 0
                    wait(3)
                    a:Destroy()
                else
                    local ok, pairs2, Players2 = false, pairs, game.Players
                    for k2, v2 in pairs2(Players2.GetChildren(Players2)) do
                        if a.name == v2.Name then
                            ok = true
                        end
                    end
                    if not ok then
                        item4:AddTag(a, "Enemy")
                        fn17(a, 7)
                    end
                end
            end
        end
    end
end)
local MessageOut = Game:GetService("LogService")
MessageOut = MessageOut.MessageOut
MessageOut:Connect(function(a)
    if string.find(a, "Server Kick Message:") then
        game:GetService("TeleportService"):Teleport(LOBBY_PLACE_ID)
    end
end)
spawn(fn11)
LocalPlayer4.Blocked:Connect(fn33)
local game3 = game
game3:GetService("Players")
waitForCharacter().Humanoid.MoveToFinished:Connect(fn32)

local function fn49(a)
    local _, _, value, _ = fn23()
    value.MoveToFinished:Connect(fn32)
    value.WalkSpeed = value17
    value.AutoRotate = false
    spawn(fn11)
end

game.Players.LocalPlayer.CharacterAdded:Connect(fn49)

function oceanFix()
    local value13
    local PathfindingService = fn12
    local new = Vector3.new
    PathfindingService(CFrame.new(-2530.18213, 217.300583, 2292.73022, 0.978144467, 0, 0.207926437, 0, 1, 0, -0.207926437, 0, 0.978144467), new(19.569891, 131.600006, 27.9050236))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-783.23999, 69.9086685, 2350.23462, -1, 0, 0, 0, 1, 0, 0, 0, -1), new(372.139984, 128.209991, 15.29))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-2038.21997, 198.318665, 2348.7041, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(50.9199371, 138.75, 9.52999496))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-2032.505, 198.318665, 2303.51416, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(39.4899368, 138.75, 9.52999496))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1876.875, 54.728653, 2323.83374, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(3.30993915, 161.48999, 138.289993))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1944.46509, 54.728653, 2256.06372, 0, 0, -1, 0, 1, 0, 1, 0, 0), new(3.30993915, 161.48999, 138.289993))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-2013.51514, 54.728653, 2323.55371, -1, 0, 0, 0, 1, 0, 0, 0, -1), new(3.30993915, 161.48999, 138.289993))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1940.46277, 186.948654, 2392.69385, 0, 0, 1, 0, 1, 0, -1, 0, 0), new(3.30993915, 161.48999, 149.454834))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-2018.40503, 198.318665, 2369.28418, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(11.2899389, 138.75, 50.3699913))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-2018.40503, 198.318665, 2276.61914, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(11.2899389, 138.75, 63.3199921))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1936.995, 162.913666, 2251.38916, 0, 0, -1, 0, 1, 0, 1, 0, 0), new(11.2899389, 67.9399948, 155.979996))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1855.01501, 162.913666, 2254.21924, 0, 0, -1, 0, 1, 0, 1, 0, 0), new(11.2899389, 67.9399948, 44.0399971))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1835.495, 162.913666, 2321.28931, -1, 0, 0, 0, 1, 0, 0, 0, -1), new(11.2899389, 67.9399948, 129.720001))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1270.09351, 52.6868362, 2227.28467, -0.998307824, 0, 0.058156427, 0, 1, 0, -0.058156427, 0, -0.998307824), new(2.08999944, 162.653656, 36.7399902))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1277.76965, 52.6868362, 2242.85889, 0.0161704421, 0, 0.999869287, 0, 1, 0, -0.999869287, 0, 0.0161704421), new(9.21999931, 162.653656, 26.4699898))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1238.92224, 52.6868362, 2468.63843, -0.999989033, 0, 0.00474769808, 0, 1, 0, -0.00474769808, 0, -0.999989033), new(9.21999931, 162.653656, 107.419983))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1241.41284, 52.6868362, 2419.99854, 0.0148379207, 0, 0.999890029, 0, 1, 0, -0.999890029, 0, 0.0148379207), new(10.3999996, 162.653656, 28.6099815))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1261.41321, 52.6868362, 2393.58862, 0.891518176, 0, 0.452984959, 0, 1, 0, -0.452984959, 0, 0.891518176), new(9.21999931, 162.653656, 65.5099792))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1284.52197, 52.6868362, 2302.46655, 0.990956247, 0, 0.134185284, 0, 1, 0, -0.134185284, 0, 0.990956247), new(9.21999931, 162.653656, 129.029984))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1263.70508, 69.9086685, 2329.61914, 0, 0, -1, 0, 1, 0, 1, 0, 0), new(46.2999954, 128.209991, 13.9499998))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1265.06799, 52.6868362, 2238.36621, 0.993771136, 0, 0.111440428, 0, 1, 0, -0.111440428, 0, 0.993771136), new(1.61999965, 162.653656, 139.828094))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1227.82751, 52.6868362, 2201.66064, 0.993771136, 0, 0.111440428, 0, 1, 0, -0.111440428, 0, 0.993771136), new(9.21999931, 162.653656, 212.23999))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1292.28625, 52.6868362, 2105.9895, 0, 0, -1, 0, 1, 0, 1, 0, 0), new(9.21999931, 162.653656, 141.559982))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1364.03931, 52.6868362, 2176.00854, -1, 0, 0, 0, 1, 0, 0, 0, -1), new(9.21999931, 162.653656, 141.559982))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1348.71521, 52.6868362, 2243.71948, 0, 0, 1, 0, 1, 0, -1, 0, 0), new(9.21999931, 162.653656, 29.5399895))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1332.10864, 52.6868362, 2284.60376, 0.990956247, 0, 0.134185284, 0, 1, 0, -0.134185284, 0, 0.990956247), new(9.21999931, 162.653656, 90.7599869))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1331.63562, 52.6868362, 2374.04199, 0.991267025, 0, -0.131870151, 0, 1, 0, 0.131870151, 0, 0.991267025), new(9.21999931, 162.653656, 92.5399857))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1337.19312, 52.6868362, 2448.06567, 0.999832571, 0, 0.0182995033, 0, 1, 0, -0.0182995033, 0, 0.999832571), new(9.21999931, 162.653656, 64.6399918))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1397.48499, 65.1518402, 2454.98486, 0, 0, -1, 0, 1, 0, 1, 0, 0), new(60.1099968, 137.723663, 7.00999975))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1413.17004, 65.1518402, 2428.40991, 0, 0, -1, 0, 1, 0, 1, 0, 0), new(6.95999908, 137.723663, 38.3799973))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1482.84009, 65.1518402, 2428.40991, 0, 0, -1, 0, 1, 0, 1, 0, 0), new(6.95999908, 137.723663, 21.1599998))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1491.44507, 65.1518402, 2475.6748, 0, 0, -1, 0, 1, 0, 1, 0, 0), new(101.489998, 137.723663, 3.94999886))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1443.73999, 65.1518402, 2525.38989, 0, 0, -1, 0, 1, 0, 1, 0, 0), new(9.71999931, 137.723663, 99.5199966))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1831.43005, 101.343674, 2414.46924, -1, 0, 0, 0, 1, 0, 0, 0, -1), new(10.3799305, 191.080002, 57.9199944))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1360.9574, 52.6868362, 2520.39917, 0.0592788458, 0, -0.998241484, 0, 1, 0, 0.998241484, 0, 0.0592788458), new(9.71999931, 162.653656, 86.7799988))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1364.93335, 52.6868362, 2477.90015, 0.0592788458, 0, -0.998241484, 0, 1, 0, 0.998241484, 0, 0.0592788458), new(9.21999931, 162.653656, 64.6399918))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1280.71997, 52.6868362, 2518.2002, 0, 0, -1, 0, 1, 0, 1, 0, 0), new(9.71999931, 162.653656, 86.7799988))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1835.495, 101.343674, 2365.10938, -1, 0, 0, 0, 1, 0, 0, 0, -1), new(11.2899389, 191.080002, 42.0799942))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1853.7251, 101.343674, 2437.48438, -1, 0, 0, 0, 1, 0, 0, 0, -1), new(54.9699287, 191.080002, 11.8899946))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1467.53931, 65.1518402, 2402.24146, 0.979213893, 0, -0.202830359, 0, 1, 0, 0.202830359, 0, 0.979213893), new(6.95999908, 137.723663, 60.1899948))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1858.97498, 62.0486679, 2350.79932, -1, 0, 0, 0, 1, 0, 0, 0, -1), new(38.1499329, 112.48999, 13.4599934))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1853.11987, 101.343674, 2213.18994, 0, 0, -1, 0, 1, 0, 1, 0, 0), new(10.3799305, 191.080002, 57.9199944))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-2055.80542, 101.343674, 2279.81958, 0, 0, 1, 0, 1, 0, -1, 0, 0), new(35.4999313, 191.080002, 11.8899946))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-2058.75537, 101.343674, 2238.39453, 0, 0, 1, 0, 1, 0, -1, 0, 0), new(54.9699287, 191.080002, 11.8899946))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-2031.19507, 101.343674, 2212.02441, -1, 0, 0, 0, 1, 0, 0, 0, -1), new(48.0899277, 191.080002, 11.8899946))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1830.10474, 101.343674, 2253.21997, 0, 0, -1, 0, 1, 0, 1, 0, 0), new(90.4399261, 191.080002, 11.8899946))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1944.03992, 101.343674, 2216.88501, -1, 0, 0, 0, 1, 0, 0, 0, -1), new(126.819931, 191.080002, 11.8899946))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-2034.54504, 101.343674, 2439.59448, -1, 0, 0, 0, 1, 0, 0, 0, -1), new(54.9699287, 191.080002, 11.8899946))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-2056.00513, 101.343674, 2367.26953, 0, 0, -1, 0, 1, 0, 1, 0, 0), new(42.0799294, 191.080002, 11.8899946))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-2060.91504, 101.343674, 2409.96436, 0, 0, -1, 0, 1, 0, 1, 0, 0), new(48.0899277, 191.080002, 11.8899946))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-2530.13501, 217.300583, 2359.55347, -0.978144407, 0, 0.207926437, 0, 1, 0, -0.207926437, 0, -0.978144407), new(19.569891, 131.600006, 28.2675056))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-2814.97021, 217.300583, 2295.89038, -0.978144407, 0, 0.207926437, 0, 1, 0, -0.207926437, 0, -0.978144407), new(19.569891, 131.600006, 34.3708916))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-2538.92798, 217.300583, 2385.58179, -0.913549781, 0, 0.406727046, 0, 1, 0, -0.406727046, 0, -0.913549781), new(19.569891, 131.600006, 34.3708916))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-2805.54321, 217.300583, 2266.87744, -0.913549781, 0, 0.406727046, 0, 1, 0, -0.406727046, 0, -0.913549781), new(19.569891, 131.600006, 34.3708916))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-2554.1814, 217.300583, 2412.00098, -0.808997631, 0, 0.587812185, 0, 1, 0, -0.587812185, 0, -0.808997631), new(19.569891, 131.600006, 34.3708916))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-2790.29028, 217.300583, 2240.4585, -0.808997631, 0, 0.587812185, 0, 1, 0, -0.587812185, 0, -0.808997631), new(19.569891, 131.600006, 34.3708916))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-2574.59448, 217.300583, 2434.67188, -0.66911006, 0, 0.743163466, 0, 1, 0, -0.743163466, 0, -0.66911006), new(19.569891, 131.600006, 34.3708916))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-2769.87793, 217.300583, 2217.78784, -0.66911006, 0, 0.743163466, 0, 1, 0, -0.743163466, 0, -0.66911006), new(19.569891, 131.600006, 34.3708916))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-2599.27612, 217.300583, 2452.60132, -0.499959469, 0, 0.866048813, 0, 1, 0, -0.866048813, 0, -0.499959469), new(19.569891, 131.600006, 34.3708916))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-2745.19702, 217.300583, 2199.85962, -0.499959469, 0, 0.866048813, 0, 1, 0, -0.866048813, 0, -0.499959469), new(19.569891, 131.600006, 34.3708916))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-2717.32861, 217.300583, 2187.45264, -0.309060812, 0, 0.951042235, 0, 1, 0, -0.951042235, 0, -0.309060812), new(19.569891, 131.600006, 34.3708916))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-2627.14502, 217.300583, 2465.00854, -0.309060812, 0, 0.951042235, 0, 1, 0, -0.951042235, 0, -0.309060812), new(19.569891, 131.600006, 34.3708916))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-2687.49023, 217.300583, 2181.1106, -0.104543328, 0, 0.994520426, 0, 1, 0, -0.994520426, 0, -0.104543328), new(19.569891, 131.600006, 34.3708916))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-2656.98462, 217.300583, 2471.35083, -0.104543328, 0, 0.994520426, 0, 1, 0, -0.994520426, 0, -0.104543328), new(19.569891, 131.600006, 34.3708916))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-2687.48999, 217.300583, 2471.35059, 0.10454309, 0, 0.994520426, 0, 1, 0, -0.994520426, 0, 0.10454309), new(19.569891, 131.600006, 34.3708916))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-2656.98462, 217.300583, 2181.11084, 0.10454309, 0, 0.994520426, 0, 1, 0, -0.994520426, 0, 0.10454309), new(19.569891, 131.600006, 34.3708916))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-2717.32886, 217.300583, 2465.00806, 0.309060872, 0, 0.951042235, 0, 1, 0, -0.951042235, 0, 0.309060872), new(19.569891, 131.600006, 34.3708916))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-2627.146, 217.300583, 2187.45313, 0.309060872, 0, 0.951042235, 0, 1, 0, -0.951042235, 0, 0.309060872), new(19.569891, 131.600006, 34.3708916))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-2745.19629, 217.300583, 2452.59839, 0.499959469, 0, 0.866048813, 0, 1, 0, -0.866048813, 0, 0.499959469), new(19.569891, 131.600006, 34.3708916))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-2599.27905, 217.300583, 2199.8623, 0.499959469, 0, 0.866048813, 0, 1, 0, -0.866048813, 0, 0.499959469), new(19.569891, 131.600006, 34.3708916))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-2769.875, 217.300583, 2434.66724, 0.669109941, 0, 0.743163466, 0, 1, 0, -0.743163466, 0, 0.669109941), new(19.569891, 131.600006, 34.3708916))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-2574.60059, 217.300583, 2217.79272, 0.669109941, 0, 0.743163466, 0, 1, 0, -0.743163466, 0, 0.669109941), new(19.569891, 131.600006, 34.3708916))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-2554.18921, 217.300583, 2240.4624, 0.808997452, 0, 0.587812185, 0, 1, 0, -0.587812185, 0, 0.808997452), new(19.569891, 131.600006, 34.3708916))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-2790.28687, 217.300583, 2411.99756, 0.808997452, 0, 0.587812185, 0, 1, 0, -0.587812185, 0, 0.808997452), new(19.569891, 131.600006, 34.3708916))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-2538.93652, 217.300583, 2266.88037, 0.913549721, 0, 0.406727046, 0, 1, 0, -0.406727046, 0, 0.913549721), new(19.569891, 131.600006, 34.3708916))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-2805.53906, 217.300583, 2385.57935, 0.913549721, 0, 0.406727046, 0, 1, 0, -0.406727046, 0, 0.913549721), new(19.569891, 131.600006, 34.3708916))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-2814.96558, 217.300583, 2356.56763, 0.978144467, 0, 0.207926437, 0, 1, 0, -0.207926437, 0, 0.978144467), new(19.569891, 131.600006, 34.3708916))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1465.67212, 65.1518402, 2326.36108, 0.418038607, 0, 0.908429265, 0, 1, 0, -0.908429265, 0, 0.418038607), new(6.95999908, 137.723663, 119.360001))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1945.50989, 101.343674, 2432.42505, -1, 0, 0, 0, 1, 0, 0, 0, -1), new(128.319931, 191.080002, 11.8899946))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-2297.98022, 144.288208, 2350.95459, -1, 0, 0, 0, 1, 0, 0, 0, -1), new(476.47998, 282.413544, 13.9443436))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-2818.1543, 217.300583, 2326.22998, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(19.569891, 131.600006, 34.3708916))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1131.17993, 69.9086685, 2381.5293, -1, 0, 0, 0, 1, 0, 0, 0, -1), new(20.5199738, 128.209991, 74.9199982))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1420.72083, 65.1518402, 2388.11353, 0.979213893, 0, -0.202830359, 0, 1, 0, 0.202830359, 0, 0.979213893), new(6.95999908, 137.723663, 81.0299988))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-961.265015, 69.9086685, 2380.78955, -1, 0, 0, 0, 1, 0, 0, 0, -1), new(16.0899849, 128.209991, 76.3999939))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1189.79504, 69.9086685, 2350.74414, -1, 0, 0, 0, 1, 0, 0, 0, -1), new(137.75, 128.209991, 13.9499998))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1169.94495, 69.9086685, 2300.8855, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(98.0499878, 128.209991, 13.9499998))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1680.02002, 101.343666, 2350.79932, -1, 0, 0, 0, 1, 0, 0, 0, -1), new(322.239929, 191.079987, 13.4599934))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1676.88501, 101.343666, 2301.47925, -1, 0, 0, 0, 1, 0, 0, 0, -1), new(328.509979, 191.079987, 13.4599934))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-783.23999, 69.9086685, 2301.69507, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(372.139984, 128.209991, 15.29))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-961.265015, 69.9086685, 2271.14014, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(16.0899849, 128.209991, 76.3999939))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1489.99719, 65.1518402, 2361.78638, 0.418038607, 0, 0.908429265, 0, 1, 0, -0.908429265, 0, 0.418038607), new(6.95999908, 137.723663, 67.8799973))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1131.17993, 69.9086685, 2270.40039, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(20.5199738, 128.209991, 74.9199982))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1047.32996, 69.9086685, 2241.58521, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(188.219971, 128.209991, 17.2899971))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-2294.77515, 144.288223, 2300.9751, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(489.929993, 282.413544, 13.9443436))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1047.32996, 69.9086685, 2410.34448, -1, 0, 0, 0, 1, 0, 0, 0, -1), new(188.219971, 128.209991, 17.2899971))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-2055.80542, 63.3636742, 2325.40967, 0, 0, 1, 0, 1, 0, -1, 0, 0), new(126.679932, 115.119995, 11.8899946))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-605.989746, 69.9086685, 2325.82007, -1, 0, 0, 0, 1, 0, 0, 0, -1), new(17.639555, 128.209991, 64.1190643))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-908.832153, 19.1552086, 2328.98291, -1, 0, 0, 0, 1, 0, 0, 0, -1), new(623.32428, 26.7030716, 180.023346))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1240.33691, 19.1552086, 2326.72632, -1, 0, 0, 0, 1, 0, 0, 0, -1), new(44.9513016, 26.7030716, 38.2773705))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1246.12073, 2.28969336, 2217.56665, -0.994147718, -0.0294061154, -0.103950247, 0.00436780788, 0.950511336, -0.310659111, 0.107941173, -0.309295058, -0.944820225), new(43.4626274, 0.818213403, 196.637329))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1283.27283, -26.5007706, 2155.53857, -0.785861552, -0.612678826, -0.0839429274, -0.561007082, 0.763435185, -0.320059299, 0.260178566, -0.204429671, -0.943671346), new(22.6772556, 2.00851345, 39.9963722))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1277.3429, -23.8319092, 2181.02539, -0.785853446, -0.528600097, 0.320961922, -0.561008096, 0.390993059, -0.729653716, 0.260201216, -0.75346303, -0.603811979), new(24.3937035, 18.8500004, 1.07342899))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1279.44299, -28.572773, 2173.7793, -1.00000024, 0, 0, 0, 1, -0.0000000596046448, 0, 0.0000000596046448, -1), new(171.743622, 4.61810207, 136.415924))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1312.07739, -23.9459343, 2329.72607, -0.99006927, 0.0131960101, -0.13996321, 0.0200383328, 0.998665988, -0.0475906916, 0.139148533, -0.0499224477, -0.98901242), new(93.4838867, 4.94735384, 208.818771))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1286.50586, -19.7647514, 2468.22461, -1.00000107, -0.00000000279396772, 0, 0.00000000279396772, 1.00000012, -0.000000238418579, 0, 0.000000238418579, -1.00000012), new(93.4838867, 7.73166227, 87.2299957))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1286.50586, -20.5263233, 2466.67285, -1.00000107, -0.00000000279396772, 0, 0.00000000279396772, 1.00000012, -0.000000238418579, 0, 0.000000238418579, -1.00000012), new(93.4838867, 8.40604877, 90.3334351))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1286.50586, -20.8730373, 2463.3562, -1.00000107, -0.00000000279396772, 0, 0.00000000279396772, 1.00000012, -0.000000238418579, 0, 0.000000238418579, -1.00000012), new(93.4838867, 7.71262121, 96.9668121))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1286.50586, -21.1191273, 2460.82324, -1.00000107, -0.00000000279396772, 0, 0.00000000279396772, 1.00000012, -0.000000238418579, 0, 0.000000238418579, -1.00000012), new(93.4838867, 7.21999979, 102.032936))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1357.41565, -10.7322168, 2529.74609, -0.974118412, 0.215022326, -0.0697357282, 0.21412079, 0.976597607, 0.0202486329, 0.0724577755, 0.00479363743, -0.99736017), new(87.857872, 5.51671267, 107.359512))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1349.19824, 38.4995384, 2479.56812, -0.974118412, 0.215022326, -0.0697357282, 0.21412079, 0.976597607, 0.0202486329, 0.0724577755, 0.00479363743, -0.99736017), new(85.6598358, 104.72879, 6.42000008))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1453.97693, 1.46386302, 2476.76196, -1.00000453, 0.0000000097497832, -0.0000000149011612, -0.0000000097497832, 1.00000048, -0.0000009550713, -0.0000000149011612, 0.0000009550713, -1.00000036), new(109.169998, 0.424085021, 108.226189))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1454.32715, 1.63537717, 2476.76196, -1.00000453, 0.0000000097497832, -0.0000000149011612, -0.0000000097497832, 1.00000048, -0.0000009550713, -0.0000000149011612, 0.0000009550713, -1.00000036), new(108.46965, 0.767113209, 108.226189))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1454.69763, 1.91353273, 2476.76196, -1.00000453, 0.0000000097497832, -0.0000000149011612, -0.0000000097497832, 1.00000048, -0.0000009550713, -0.0000000149011612, 0.0000009550713, -1.00000036), new(107.728615, 1.32342398, 108.226189))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1443.73267, 10.8826275, 2394.87671, -0.977953851, -0.0425007194, 0.204492941, 0.00425821915, 0.974818051, 0.222961426, -0.208821028, 0.218918473, -0.953138232), new(36.4249535, 6.1712513, 130.547668))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1427.18213, 70.4603043, 2405.68164, -0.977953851, -0.0425007194, 0.204492941, 0.00425821915, 0.974818051, 0.222961426, -0.208821028, 0.218918473, -0.953138232), new(0.0500000007, 125.649826, 117.808311))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1487.76672, 20.8402691, 2338.7666, -0.893995583, 0.14297086, 0.424654365, 0.145493388, 0.988999486, -0.0266750585, -0.423796773, 0.0379370227, -0.90496242), new(88.661377, 9.92626381, 41.2240219))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1700.78955, 29.0303326, 2325.34424, -1.00000012, 0.0000000297213205, 0.0000000188447302, -0.0000000297213205, 0.999999821, -0.00000000186264515, 0.0000000188447302, 0.00000000186264515, -0.999999881), new(371.852844, 5.56997252, 53.5832138))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1529.57568, 28.8269882, 2325.34424, -1.00000012, 0.0000000297213205, 0.0000000188447302, -0.0000000297213205, 0.999999821, -0.00000000186264515, 0.0000000188447302, 0.00000000186264515, -0.999999881), new(31.7297535, 5.16327238, 53.5832138))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1528.28796, 28.558382, 2325.34424, -1.00000012, 0.0000000297213205, 0.0000000188447302, -0.0000000297213205, 0.999999821, -0.00000000186264515, 0.0000000188447302, 0.00000000186264515, -0.999999881), new(31.3896217, 4.62606096, 53.5832138))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1527.79773, 28.3058643, 2325.34424, -1.00000012, 0.0000000297213205, 0.0000000188447302, -0.0000000297213205, 0.999999821, -0.00000000186264515, 0.0000000188447302, 0.00000000186264515, -0.999999881), new(32.3699989, 4.12102604, 53.5832138))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1527.37683, 28.102354, 2325.34424, -1.00000012, 0.0000000297213205, 0.0000000188447302, -0.0000000297213205, 0.999999821, -0.00000000186264515, 0.0000000188447302, 0.00000000186264515, -0.999999881), new(33.211895, 3.71400523, 53.5832138))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1526.84424, 27.9374313, 2325.34424, -1.00000012, 0.0000000297213205, 0.0000000188447302, -0.0000000297213205, 0.999999821, -0.00000000186264515, 0.0000000188447302, 0.00000000186264515, -0.999999881), new(34.2771111, 3.38415861, 53.5832138))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1855.52856, 37.2675323, 2286.03491, -1.00000024, -0.00000824050039, 0.0000351449016, 0.00000488978958, 0.932308853, 0.36166212, -0.0000357189347, 0.36166209, -0.932308912), new(44.2060127, 6.02838516, 49.6322327))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1858.3186, 46.4191093, 2232.7439, -1.00000048, 0.000000118888238, 0.0000000753789209, -0.000000118888238, 0.999999285, 0, 0.0000000753789209, 0, -0.999999404), new(56.2976837, 5.61337185, 63.1329041))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1938.64209, 59.3698273, 2253.55371, -0.975066185, 0.221918508, 0.00000014699873, 0.221918583, 0.975063741, -0.0000000334559616, 0.000000150757813, -0.00000000000000896166618, -0.999998748), new(141.891571, 6.28999996, 63.1329041))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-2031.08984, 76.6613846, 2259.55518, -1.00000191, 0.000000461935997, 0.000000301515627, -0.000000461935997, 0.999997079, 0.0000000000000515942202, 0.000000301515627, -0.0000000000000515942202, -0.999997497), new(48.2068825, 3.13832617, 97.6713715))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-2037.69958, 90.5315781, 2323.69995, -1.00000381, -0.00000473108639, -0.0000501252653, 0.00000497483006, 0.975067258, -0.221883357, 0.0000515119791, -0.221883178, -0.975068092), new(48.2068825, 4.05999994, 133.019562))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-2035.52686, 103.249794, 2413.302, -1, 0.0000000000000179664345, 0.000000000000113686838, -0.0000000000000179664345, 1, -0.00000000000000088817842, 0.000000000000113686838, 0.00000000000000088817842, -1), new(48.8988571, 8.13232899, 50.8320503))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1952.27319, 116.819923, 2413.41699, -0.97507298, -0.221884459, 0.0000584738664, -0.221884459, 0.97507298, 0.00000750656818, -0.0000586818787, -0.00000565499067, -1), new(144.940002, 7.03901482, 40.3282356))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1857.91382, 134.10907, 2348.59229, -0.99999994, 0.0000000000000359328656, 0.000000000000227373662, -0.000000000000035932869, 1, -0.00000000000000177635684, 0.000000000000227373675, 0.00000000000000177635684, -1), new(56.4390755, 4.47680473, 177.607712))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1873.65051, 136.331314, 2318.76172, -0.855346203, 0.518056273, 0.000000000000774251973, 0.518056035, 0.85534656, -0.000000000000477246931, 0.000000000000909494539, 0.00000000000000710542736, -1), new(6.69999218, 0.0500000007, 150.532593))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1946.55249, 137.231415, 2319.61206, -0.999999166, 0.0000000298023224, 0.00000000000181898875, -0.0000000298023224, 1, -0.0000000000000142108547, 0.00000000000181898875, 0.0000000000000142108547, -1), new(137.636246, 3.40450764, 150.532593))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-1945.93896, 137.022552, 2319.61206, -0.999999166, 0.0000000298023224, 0.00000000000181898875, -0.0000000298023224, 1, -0.0000000000000142108547, 0.00000000000181898875, 0.0000000000000142108547, -1), new(138.863373, 2.98677969, 150.532593))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-2190.23413, 136.711761, 2325.40161, -0.999999166, 0.0000000298023224, 0.00000000000181898875, -0.0000000298023224, 1, -0.0000000000000142108547, 0.00000000000181898875, 0.0000000000000142108547, -1), new(366.358093, 2.36521196, 39.7483025))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-2674.35205, 192.732971, 2320.76904, -1, 0, 0, 0, 1, 0, 0, 0, -1), new(279.199799, 6.58692169, 290.013947))
    PathfindingService = fn12
    new = Vector3.new
    PathfindingService(CFrame.new(-2672.68774, 192.732971, 2320.76904, -1, 0, 0, 0, 1, 0, 0, 0, -1), new(282.528381, 6.58692169, 290.013947))
    PathfindingService = fn12
    CFrame137 = CFrame
    local workspace2 = CFrame137.new(-2398.11328, 162.203232, 2325.17139, 0.970287263, 0.241955817, 0, -0.241955817, 0.970287263, 0, 0, 0, 1.00000012)
    new = Vector3.new
    PathfindingService(workspace2, new(274.739532, 0.558954656, 51.0499992))
    PathfindingService = fn3
    workspace2 = workspace
    PathfindingService = PathfindingService(workspace2, "borders")
    local result2 = "Destroy"
    new = PathfindingService
    new[result2](new)
    if _G.destroy_map then
        local Terrain, value = workspace.Terrain, "Clear"
        local workspace3 = Terrain
        workspace3[value](workspace3)
        local pairs2 = pairs
        workspace3 = workspace
        value = workspace3
        for k, v in pairs2(value.GetChildren(value)) do
            if v.Name ~= "lastBossSafeZones"
                and v.Name ~= "Terrain"
                and (v.ClassName == "Model" or v:IsA("BasePart"))
                and v ~= game.Players.LocalPlayer.Character
                and v.Name ~= result3 then
                local value3, value4 = "Destroy", v
                value4[value3](value4)
            end
        end
    end
    while true do
        local game2, value5 = game, "GetService"
        local ok = game2
        game2 = ok[value5](ok, "Workspace")
        game2 = game2.dungeon
        local room3 = game2.room3
        room3 = room3.enemyFolder
        value5 = room3
        ok = value5.GetChildren(value5)
        ok = #ok
        if ok == 41 then
            break
        end
        wait(1)
    end
    ok6 = true
    new = result9
    result2 = CFrame.new(-1240.337, 7.648, 2246.159)
    new.CFrame = result2
    while wait() do
        local _, _, _, value9 = fn23()
        if value9 and value9.Position.Y < 21 then
            break
        end
    end
    ok6 = false
    while true do
        local game3, value7 = game, "GetService"
        local ok2 = game3
        game3 = ok2[value7](ok2, "Workspace")
        game3 = game3.dungeon
        local room5 = game3.room5
        room5 = room5.enemyFolder
        value7 = room5
        ok2 = value7.GetChildren(value7)
        ok2 = #ok2
        if ok2 == 16 then
            break
        end
        wait(1)
    end
    ok6 = true
    new = result9
    result2 = CFrame.new(-1858.319, 46.419, 2232.744)
    new.CFrame = result2
    repeat
        if not wait() then
            break
        end
        local value10, value11, value12
        value10, value11, value12, value13 = fn23()
    until value13 and value13.Position.Y < 38
    ok6 = false
end

function volcanicFix()
    local wait2 = fn12
    local new = Vector3.new
    wait2(CFrame.new(-1233.02295, 2.79844761, 705.183167, -0.999982297, -0.0000000614493274, -0.00593414903, -0.000000061298465, 1, -0.0000000256039989, 0.00593414903, -0.0000000252398049, -0.999982297), new(148.029877, 17.849968, 161.050003))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1127.02625, -2.89132118, 699.554077, -0.981609523, 0.190805554, -0.00593414763, 0.190808892, 0.981627166, -0.0000000257277861, 0.0058251163, -0.00113231386, -0.999982119), new(69.5298767, 18.849968, 35.0500031))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-793.540466, -8.58208942, 699.325134, -0.999981225, -0.000000048950298, -0.00593414297, -0.0000000541017471, 0.999999881, -0.0000000259606168, 0.00593414484, -0.0000000253785402, -0.999981582), new(606.529907, 18.849968, 38.5500031))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-417.026733, -7.0820694, 700.590942, -0.999981225, -0.000000048950298, -0.00593414297, -0.0000000541017471, 0.999999881, -0.0000000259606168, 0.00593414484, -0.0000000253785402, -0.999981582), new(157.529907, 18.849968, 158.550003))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-498.050507, 0.667925298, 696.821716, -0.999981225, -0.000000048950298, -0.00593414297, -0.0000000541017471, 0.999999881, -0.0000000259606168, 0.00593414484, -0.0000000253785402, -0.999981582), new(5.52990723, 2.34996796, 37.0500031))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-498.800507, 0.417925298, 696.826172, -0.999981225, -0.000000048950298, -0.00593414297, -0.0000000541017471, 0.999999881, -0.0000000259606168, 0.00593414484, -0.0000000253785402, -0.999981582), new(7.02990723, 1.84996796, 37.0500031))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(135.459915, -8.58203983, 696.812256, -0.999981225, -0.000000048950298, -0.00593414297, -0.0000000541017471, 0.999999881, -0.0000000259606168, 0.00593414484, -0.0000000253785402, -0.999981582), new(280.529907, 18.849968, 44.5500031))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(273.457336, -8.0820322, 695.993347, -0.999981225, -0.000000048950298, -0.00593414297, -0.0000000541017471, 0.999999881, -0.0000000259606168, 0.00593414484, -0.0000000253785402, -0.999981582), new(4.52990723, 19.849968, 44.5500031))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(276.957275, -7.5820322, 695.972595, -0.999981225, -0.000000048950298, -0.00593414297, -0.0000000541017471, 0.999999881, -0.0000000259606168, 0.00593414484, -0.0000000253785402, -0.999981582), new(9.52990723, 20.849968, 44.5500031))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(289.707031, -6.58203173, 695.896912, -0.999981225, -0.000000048950298, -0.00593414297, -0.0000000541017471, 0.999999881, -0.0000000259606168, 0.00593414484, -0.0000000253785402, -0.999981582), new(21.0299072, 22.849968, 44.5500031))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-12.0373135, -8.08204746, 697.687561, -0.999981225, -0.000000048950298, -0.00593414297, -0.0000000541017471, 0.999999881, -0.0000000259606168, 0.00593414484, -0.0000000253785402, -0.999981582), new(44.5299072, 19.849968, 44.5500031))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-14.5372658, -7.58204746, 697.702393, -0.999981225, -0.000000048950298, -0.00593414297, -0.0000000541017471, 0.999999881, -0.0000000259606168, 0.00593414484, -0.0000000253785402, -0.999981582), new(39.5299072, 20.849968, 44.5500031))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-16.5372276, -7.08204746, 697.714233, -0.999981225, -0.000000048950298, -0.00593414297, -0.0000000541017471, 0.999999881, -0.0000000259606168, 0.00593414484, -0.0000000253785402, -0.999981582), new(35.5299072, 21.849968, 44.5500031))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-19.0371799, -6.58204746, 697.729065, -0.999981225, -0.000000048950298, -0.00593414297, -0.0000000541017471, 0.999999881, -0.0000000259606168, 0.00593414484, -0.0000000253785402, -0.999981582), new(30.5299072, 22.849968, 44.5500031))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-24.2870808, -6.08204794, 697.760193, -0.999981225, -0.000000048950298, -0.00593414297, -0.0000000541017471, 0.999999881, -0.0000000259606168, 0.00593414484, -0.0000000253785402, -0.999981582), new(20.0299072, 23.849968, 44.5500031))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-40.2867775, -5.83204842, 697.855164, -0.999981225, -0.000000048950298, -0.00593414297, -0.0000000541017471, 0.999999881, -0.0000000259606168, 0.00593414484, -0.0000000253785402, -0.999981582), new(39.0299072, 24.349968, 44.5500031))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-44.036705, -6.58204842, 697.877441, -0.999981225, -0.000000048950298, -0.00593414297, -0.0000000541017471, 0.999999881, -0.0000000259606168, 0.00593414484, -0.0000000253785402, -0.999981582), new(46.5299072, 22.849968, 44.5500031))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-48.0366287, -7.08204889, 697.901123, -0.999981225, -0.000000048950298, -0.00593414297, -0.0000000541017471, 0.999999881, -0.0000000259606168, 0.00593414484, -0.0000000253785402, -0.999981582), new(54.5299072, 21.849968, 44.5500031))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-65.2863083, -7.33204985, 698.003479, -0.999981225, -0.000000048950298, -0.00593414297, -0.0000000541017471, 0.999999881, -0.0000000259606168, 0.00593414484, -0.0000000253785402, -0.999981582), new(89.0299072, 21.349968, 44.5500031))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-80.536026, -7.58205032, 698.093994, -0.999981225, -0.000000048950298, -0.00593414297, -0.0000000541017471, 0.999999881, -0.0000000259606168, 0.00593414484, -0.0000000253785402, -0.999981582), new(119.529907, 20.849968, 44.5500031))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-88.5358734, -8.08205032, 698.141479, -0.999981225, -0.000000048950298, -0.00593414297, -0.0000000541017471, 0.999999881, -0.0000000259606168, 0.00593414484, -0.0000000253785402, -0.999981582), new(135.529907, 19.849968, 44.5500031))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-113.535408, -8.58205223, 698.289856, -0.999981225, -0.000000048950298, -0.00593414297, -0.0000000541017471, 0.999999881, -0.0000000259606168, 0.00593414484, -0.0000000253785402, -0.999981582), new(185.529907, 18.849968, 44.5500031))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-215.033478, -8.08205795, 698.89209, -0.999981225, -0.000000048950298, -0.00593414297, -0.0000000541017471, 0.999999881, -0.0000000259606168, 0.00593414484, -0.0000000253785402, -0.999981582), new(26.5299072, 19.849968, 44.5500031))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-243.282944, -7.83205986, 699.059753, -0.999981225, -0.000000048950298, -0.00593414297, -0.0000000541017471, 0.999999881, -0.0000000259606168, 0.00593414484, -0.0000000253785402, -0.999981582), new(32.0299072, 20.349968, 44.5500031))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-270.78241, -7.33206129, 699.222961, -0.999981225, -0.000000048950298, -0.00593414297, -0.0000000541017471, 0.999999881, -0.0000000259606168, 0.00593414484, -0.0000000253785402, -0.999981582), new(49.0299072, 21.349968, 44.5500031))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-309.781677, -7.0820632, 699.454407, -0.999981225, -0.000000048950298, -0.00593414297, -0.0000000541017471, 0.999999881, -0.0000000259606168, 0.00593414484, -0.0000000253785402, -0.999981582), new(53.0299072, 21.849968, 44.5500031))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-313.281616, -6.5820632, 699.475159, -0.999981225, -0.000000048950298, -0.00593414297, -0.0000000541017471, 0.999999881, -0.0000000259606168, 0.00593414484, -0.0000000253785402, -0.999981582), new(46.0299072, 22.849968, 44.5500031))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-314.781586, -6.3320632, 699.48407, -0.999981225, -0.000000048950298, -0.00593414297, -0.0000000541017471, 0.999999881, -0.0000000259606168, 0.00593414484, -0.0000000253785402, -0.999981582), new(43.0299072, 23.349968, 44.5500031))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-317.031555, -5.8320632, 699.497437, -0.999981225, -0.000000048950298, -0.00593414297, -0.0000000541017471, 0.999999881, -0.0000000259606168, 0.00593414484, -0.0000000253785402, -0.999981582), new(38.5299072, 24.349968, 44.5500031))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-319.531494, -5.5820632, 699.512268, -0.999981225, -0.000000048950298, -0.00593414297, -0.0000000541017471, 0.999999881, -0.0000000259606168, 0.00593414484, -0.0000000253785402, -0.999981582), new(33.5299072, 24.849968, 44.5500031))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-320.531464, -6.0820632, 699.518188, -0.999981225, -0.000000048950298, -0.00593414297, -0.0000000541017471, 0.999999881, -0.0000000259606168, 0.00593414484, -0.0000000253785402, -0.999981582), new(35.5299072, 23.849968, 44.5500031))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-323.031403, -6.5820632, 699.53302, -0.999981225, -0.000000048950298, -0.00593414297, -0.0000000541017471, 0.999999881, -0.0000000259606168, 0.00593414484, -0.0000000253785402, -0.999981582), new(40.5299072, 22.849968, 44.5500031))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-326.776886, -6.5820632, 700.305298, -0.999981225, -0.000000048950298, -0.00593414297, -0.0000000541017471, 0.999999881, -0.0000000259606168, 0.00593414484, -0.0000000253785402, -0.999981582), new(48.0299072, 22.849968, 76.0500031))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-330.281281, -7.0820632, 699.57605, -0.999981225, -0.000000048950298, -0.00593414297, -0.0000000541017471, 0.999999881, -0.0000000259606168, 0.00593414484, -0.0000000253785402, -0.999981582), new(55.0299072, 21.849968, 90.5500031))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-2341.5, 9.19974613, 695.25, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(197, 3, 194.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-2244.75, 10.1997461, 695.25, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(10.5, 1, 194.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-46.5366592, -6.33204842, 697.892273, -0.999981225, -0.000000048950298, -0.00593414297, -0.0000000541017471, 0.999999881, -0.0000000259606168, 0.00593414484, -0.0000000253785402, -0.999981582), new(34.5299072, 23.349968, 44.5500031))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(278.207245, -7.0820322, 695.965149, -0.999981225, -0.000000048950298, -0.00593414297, -0.0000000541017471, 0.999999881, -0.0000000259606168, 0.00593414484, -0.0000000253785402, -0.999981582), new(7.02990723, 21.849968, 44.5500031))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-2093.75, 9.94974613, 696.75, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(692.5, 0.5, 37.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1725.44324, 10.6997461, 694.778015, 0.694658399, 0, 0.719339788, 0, 1, 0, -0.719339788, 0, 0.694658399), new(48, 2, 45))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1339.51733, 4.49533796, 698.180054, 0.99026829, -0.13917312, 0, 0.13917312, 0.99026829, 0, 0, 0, 1), new(67.5, 4, 37))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1363.59412, 1.11156046, 708.326904, 0.820969999, -0.13917318, 0.553750992, 0.115379818, 0.990268767, 0.0778246224, -0.559193194, 0, 0.829037607), new(34, 4, 49))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1371.4259, -0.998918772, 723.160156, 0.930549145, -0.139173374, -0.338692099, 0.13078016, 0.990270197, -0.047600057, 0.34202072, -0.0000000074505806, 0.939693034), new(38.5, 4, 48))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1393.78589, -4.70867538, 741.874329, 0.525701582, -0.11796616, -0.842453718, 0.0624936409, 0.993020117, -0.100052938, 0.848372996, -0.0000499562702, 0.529402494), new(57, 4, 48))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1426.87244, -9.64694118, 727.73645, -0.0525785685, -0.117965765, -0.991624653, -0.00619550375, 0.993017733, -0.117802992, 0.998597682, -0.0000502976873, -0.0529423133), new(43, 4, 49))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1542.79834, -24.1414528, 693.151733, 0.151433259, -0.117894612, -0.981410801, 0.0179410838, 0.993028104, -0.116522513, 0.988308668, 0.0000375595118, 0.152491033), new(16.5, 4, 24.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1525.43823, -22.3317413, 680.852295, 0.711567044, -0.117893316, -0.692656934, 0.0844521746, 0.993026376, -0.0822597519, 0.697524667, 0.0000369343543, 0.716561079), new(16.5, 3.5, 31))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1512.83789, -21.387928, 669.898132, 0.0859401673, -0.117966108, -0.989292026, 0.010259347, 0.993018389, -0.117519177, 0.996249139, -0.0000499039452, 0.086550802), new(16.5, 3.5, 26))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1502.39136, -20.650486, 668.989319, 0.0859401673, -0.117966108, -0.989292026, 0.010259347, 0.993018389, -0.117519177, 0.996249139, -0.0000499039452, 0.086550802), new(16.5, 3.5, 26))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1481.26001, -18.1399117, 673.785461, -0.526738107, -0.117966197, -0.841804624, -0.0625315532, 0.993019879, -0.100029439, 0.847729981, -0.0000499358321, -0.530434847), new(16.5, 3.5, 26))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1468.12195, -15.5714817, 686.85675, -0.526738107, -0.117966197, -0.841804624, -0.0625315532, 0.993019879, -0.100029439, 0.847729981, -0.0000499358321, -0.530434847), new(24.5, 3.5, 34.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1726.15015, 10.4497461, 694.790344, 0.694658399, 0, 0.719339788, 0, 1, 0, -0.719339788, 0, 0.694658399), new(49, 1.5, 46))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1727.22302, 10.1997461, 694.101868, 0.694658399, 0, 0.719339788, 0, 1, 0, -0.719339788, 0, 0.694658399), new(49.5, 1, 48.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1594.52539, -24.3682365, 695.275208, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(88.5, 2.5, 96))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1677.15637, -15.417098, 623.046021, 0.984657705, 0.0171872638, -0.173648149, -0.0174524058, 0.99984771, 0, 0.173621729, 0.00303057837, 0.98480767), new(80.5, 8, 85.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1450.97681, -13.2820768, 704.461609, -0.526738107, -0.117966197, -0.841804624, -0.0625315532, 0.993019879, -0.100029439, 0.847729981, -0.0000499358321, -0.530434847), new(36, 4, 32.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1635.84265, -139.839996, 622.938721, 0.178292945, 0, 0.98397553, 0, 1, 0, -0.983975589, 0, 0.178293034), new(14, 255, 4.35629797))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1631.328, -140.839996, 623.947815, 0.2464917, 0, 0.969143093, 0, 1, 0, -0.969143093, 0, 0.24649176), new(14, 255, 5.8792901))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1608.31348, -147.839996, 639.822876, 0.866703033, 0, 0.498820961, 0, 1, 0, -0.498820961, 0, 0.866703033), new(14, 255, 5.13447332))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1606.00684, -148.839996, 644.197998, 0.899387717, 0, 0.437147677, 0, 1, 0, -0.437147677, 0, 0.899387717), new(14, 255, 5.74125433))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1626.75098, -141.839996, 625.260925, 0.313491344, 0, 0.949589133, 0, 1, 0, -0.949589133, 0, 0.313491404), new(14, 255, 4.62769413))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1623.35046, -142.839996, 626.612061, 0.426887631, 0, 0.904302716, 0, 1, 0, -0.904302716, 0, 0.426887691), new(14, 255, 4.41635466))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1610.32239, -146.839996, 636.802979, 0.78356123, 0, 0.621311903, 0, 1, 0, -0.621311784, 0, 0.783561289), new(14, 255, 4.21742392))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1619.98938, -143.839996, 628.473572, 0.532674611, 0, 0.846318007, 0, 1, 0, -0.846318007, 0, 0.53267467), new(14, 255, 4.97442102))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1616.38782, -144.839996, 630.914368, 0.590408921, 0, 0.807102084, 0, 1, 0, -0.807102084, 0, 0.59040904), new(14, 255, 4.71004725))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1613.16479, -145.839996, 633.713562, 0.701997042, 0, 0.712177455, 0, 1, 0, -0.712177455, 0, 0.701997101), new(14, 255, 5.9066267))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1604.04761, -149.839996, 648.575867, 0.927696943, 0, 0.373347104, 0, 1, 0, -0.373347104, 0, 0.927697003), new(14, 255, 4.8348875))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1712.18823, -137.559921, 611.531189, -0.0305747688, -0.000000038556589, 0.999530673, -0.00000016698479, 1, 0.0000000334666268, -0.999530613, -0.00000016588379, -0.030574739), new(14, 255, 5.74125433))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1717.12427, -136.559921, 611.844177, -0.100224018, -0.000000038556589, 0.994963169, -0.00000016891255, 1, 0.0000000217368452, -0.994963109, -0.00000016588379, -0.100223958), new(14, 255, 5.13447332))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1720.7019, -135.559921, 612.44043, -0.246018708, -0.000000038556589, 0.969263375, -0.00000017027071, 1, -0.00000000343903395, -0.969263315, -0.00000016588379, -0.246018708), new(14, 255, 4.21742392))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1724.68433, -134.559921, 613.768799, -0.362314641, -0.000000038556589, 0.932054043, -0.000000168582289, 1, -0.0000000241653098, -0.932054043, -0.00000016588379, -0.362314641), new(14, 255, 5.9066267))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1728.55774, -133.559921, 615.56311, -0.494606912, -0.000000038556589, 0.869114876, -0.000000163242419, 1, -0.0000000485371636, -0.869114757, -0.00000016588379, -0.494606853), new(14, 255, 4.71004725))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1732.25928, -132.559921, 617.849548, -0.554024041, -0.000000038556589, 0.83249861, -0.00000015945929, 1, -0.000000059805302, -0.83249855, -0.00000016588379, -0.554023981), new(14, 255, 4.97442102))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1735.33374, -131.559921, 620.153809, -0.650239468, -0.000000038556589, 0.759727001, -0.00000015109741, 1, -0.000000078571702, -0.759726942, -0.00000016588379, -0.650239348), new(14, 255, 4.41635466))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1737.95874, -130.559921, 622.703003, -0.737985492, -0.000000038556589, 0.674813986, -0.000000140394903, 1, -0.0000000964013083, -0.674813926, -0.00000016588379, -0.737985432), new(14, 255, 4.62769413))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1741.03076, -129.559921, 626.341125, -0.783257902, -0.000000038556589, 0.621694207, -0.000000133328726, 1, -0.00000010595938, -0.621694148, -0.00000016588379, -0.783257842), new(14, 255, 5.8792901))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1743.79993, -128.559921, 630.046875, -0.824713767, -0.000000038556589, 0.565547168, -0.000000125613255, 1, -0.000000115001065, -0.565547168, -0.00000016588379, -0.824713647), new(14, 255, 4.35629797))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1745.77539, -127.560036, 633.337646, -0.879498184, -0.0000000867711378, 0.475898564, -0.000000112849136, 1, -0.0000000262235904, -0.475898594, -0.0000000767686217, -0.879498243), new(14, 255, 4.99258232))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1747.48596, -126.560036, 637.008545, -0.930946112, -0.0000000867711378, 0.365169674, -0.000000108812841, 1, -0.0000000397812556, -0.365169674, -0.0000000767686217, -0.930946112), new(14, 255, 4.8348875))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1749.06567, -125.560036, 641.53717, -0.954145014, -0.0000000867711378, 0.299338609, -0.000000105772067, 1, -0.0000000472744333, -0.299338609, -0.0000000767686217, -0.954145014), new(14, 255, 5.74125433))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1750.39087, -124.560036, 646.302246, -0.972701669, -0.0000000867711378, 0.2320517, -0.000000102216717, 1, -0.0000000545375691, -0.2320517, -0.0000000767686217, -0.972701669), new(14, 255, 5.13447332))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1751.00244, -123.560036, 649.877319, -0.99630177, -0.0000000867711378, 0.0859023929, -0.0000000930448607, 1, -0.0000000690308681, -0.0859024227, -0.0000000767686217, -0.996301889), new(14, 255, 4.21742392))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1751.05554, -122.560036, 654.075134, -0.99934417, -0.0000000867711378, -0.0361632407, -0.0000000839380334, 1, -0.0000000798561928, 0.0361632407, -0.0000000767686217, -0.99934417), new(14, 255, 5.9066267))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1750.63257, -121.560036, 658.322998, -0.983336091, -0.0000000867711378, -0.181787133, -0.0000000713696551, 1, -0.0000000912632245, 0.181787133, -0.0000000767686217, -0.983336091), new(14, 255, 4.71004725))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1749.68848, -120.560036, 662.570007, -0.968261242, -0.0000000867711378, -0.249933213, -0.000000064830104, 1, -0.0000000960190647, 0.249933243, -0.0000000767686217, -0.968261242), new(14, 255, 4.97442102))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1741.95715, -116.560036, 677.476013, -0.80499965, -0.0000000867711378, -0.59327215, -0.0000000243060558, 1, -0.000000113277608, 0.59327215, -0.0000000767686217, -0.80499959), new(14, 255, 4.35629797))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1744.5481, -117.560036, 673.643494, -0.844420195, -0.0000000867711378, -0.535677969, -0.0000000321480513, 1, -0.000000111306363, 0.535678029, -0.0000000767686217, -0.844420195), new(14, 255, 5.8792901))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1746.97571, -118.560036, 669.54718, -0.879728258, -0.0000000867711378, -0.475472927, -0.0000000398336297, 1, -0.000000108792854, 0.475472957, -0.0000000767686217, -0.879728317), new(14, 255, 4.62769413))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1748.52148, -119.560036, 666.230652, -0.931119382, -0.0000000867711378, -0.364709496, -0.0000000527960502, 1, -0.000000103127007, 0.364709556, -0.0000000767686217, -0.931119382), new(14, 255, 4.41635466))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1740.73279, 50.4497452, 720.327759, 0.694658399, 0, 0.719339788, 0, 1, 0, -0.719339788, 0, 0.694658399), new(8, 81.5, 31.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-1994.25, 10.4497461, 709.5, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(492.5, 0.5, 5))
    wait2 = fn12
    CFrame92 = CFrame
    local PathfindingService = CFrame92.new(-1994.25, 10.4497461, 681.5, 1, 0, 0, 0, 1, 0, 0, 0, 1)
    new = Vector3.new
    wait2(PathfindingService, new(492.5, 0.5, 4))
    wait2 = wait
    PathfindingService = 0.1
    wait2(PathfindingService)
    wait2 = fn3(workspace, "borders")
    if wait2 then
        local pairs2, value, value2 = pairs, "GetChildren", wait2
        local item = value2[value]
        for k, v in pairs2(item(value2)) do
            local value3 = item4
            local value4, value5 = "AddTag", value3
            value5[value4](value5, v, "RayWhitelist")
            v.Transparency = _G.wall_transparency
        end
    end
    if not workspace:FindFirstChild("map") then
        -- This build keeps dungeon geometry under workspace.dungeon, so the old
        -- workspace.map object may be gone; skip rather than error.
        ScriptDebug("[compat] workspace.map missing - skipping orbital map pass")
    elseif _G.destroy_map then
        local map2 = workspace.map
        local value12, value13 = "Destroy", map2
        value13[value12](value13)
    else
        local pairs3 = pairs
        local map = workspace.map
        local value6, value7 = "GetChildren", map
        local item2 = value7[value6]
        for k2, v2 in pairs3(item2(value7)) do
            local value8, value9 = "FindFirstChild", v2
            local item3 = value9[value8]
            if item3(value9, "Meshes/Forgers Mark2_Circle.001") then
                local value10, value11 = "Destroy", v2
                value11[value10](value11)
            end
        end
    end
end

function fixOrbital()
    local wait2 = fn12
    local new = Vector3.new
    wait2(CFrame.new(2.05055237, 6.13212585, 144.456467, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(184, 1.5, 81))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-27.9494476, 18.8821259, 183.206467, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(130, 27, 3.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(65.8005524, 18.8821259, 182.206467, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(60.5, 27, 5.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(80.5505524, 18.8821259, 176.206467, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(31, 27, 17.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(91.5505524, 18.8821259, 162.206467, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(9, 27, 45.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(71.8005524, 20.3821259, 101.206467, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(72.5, 30, 3.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(86.5673981, 5.77369833, 120.956467, 0.98480767, -0.173648179, 0, 0.173648179, 0.98480767, 0, 0, 0, 1), new(40, 7, 38))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(122.800552, 8.88212585, 116.456467, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(35.5, 7, 35))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(136.300552, 16.8821259, 132.706467, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(60.5, 23, 10.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(123.300552, 16.8821259, 103.206467, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(34.5, 23, 0.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(130.692398, 10.4759054, 116.456467, 0.98480773, -0.173648179, 0, 0.173648179, 0.98480773, 0, 0, 0, 1), new(24, 7, 35))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(225.300552, 10.8821259, 83.7064667, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(172.5, 11, 149.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(139.050552, 16.6321259, 84.4564667, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(11, 22.5, 47))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(151.469864, 16.6321259, 61.0406761, 0.91354543, 0, -0.406736642, 0, 1, 0, 0.406736642, 0, 0.91354543), new(3, 22.5, 94))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(169.348312, 16.6321259, 42.4514313, 0.694658279, 0, -0.719339728, 0, 1, 0, 0.719339728, 0, 0.694658279), new(4, 22.5, 94))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(207.741302, 16.6321259, 22.175375, 0.358367801, 0, -0.93358016, 0, 1, 0, 0.93358016, 0, 0.358367801), new(3.5, 22.5, 94))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(200.99971, 16.6321259, 23.0883999, 0.0174523592, 0, -0.999846816, 0, 1, 0, 0.999846816, 0, 0.0174523592), new(2, 22.5, 94))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(251.564911, 16.6321259, 18.5538025, 0.766042292, 0, -0.642785966, 0, 1, 0, 0.642785966, 0, 0.766042292), new(2, 22.5, 13.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(255.064896, 16.6321259, 9.05387974, 0.999991894, 0, -0.000000178813934, 0, 1, 0, 0.000000178813934, 0, 0.999991894), new(5, 22.5, 13.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(170.300552, 16.8821259, 128.706467, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(9.5, 23, 18.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(174.550552, 16.8821259, 109.206467, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(1, 23, 21.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(178.440842, 16.8821259, 87.8495941, 0.906307757, 0, -0.42261827, 0, 1, 0, 0.42261827, 0, 0.906307757), new(3, 23, 26.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(192.023926, 16.8821259, 70.1889038, 0.629320323, 0, -0.777145863, 0, 1, 0, 0.777145863, 0, 0.629320323), new(4, 23, 21))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(207.625092, 16.8821259, 62.0181961, 0.258818924, 0, -0.965925455, 0, 1, 0, 0.965925455, 0, 0.258818924), new(5.5, 23, 21.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(235.841599, 16.8821259, 62.0727882, -0.0174523555, 0, -0.999844193, 0, 1, 0, 0.999844193, 0, -0.0174523555), new(9, 23, 42))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(268.73175, 16.8821259, 68.6477737, -0.0174523555, 0, -0.999844193, 0, 1, 0, 0.999844193, 0, -0.0174523555), new(6, 23, 49))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(295.005676, 16.8821259, 38.8518867, -0.0174523555, 0, -0.999844193, 0, 1, 0, 0.999844193, 0, -0.0174523555), new(66.5, 23, 5.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(290.775604, 16.8821259, 9.02362251, -0.0174523555, 0, -0.999844193, 0, 1, 0, 0.999844193, 0, -0.0174523555), new(13, 23, 15))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(237.565033, 20.8821259, -8.44598103, 0.999991894, 0, -0.000000178813934, 0, 1, 0, 0.000000178813934, 0, 0.999991894), new(31, 31, 48.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(216.315201, 20.8821259, -32.4457855, 0.999991894, 0, -0.000000178813934, 0, 1, 0, 0.000000178813934, 0, 0.999991894), new(21.5, 31, 96.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(335.789215, 20.8821259, -32.4457664, 0.999991894, 0, -0.000000178813934, 0, 1, 0, 0.000000178813934, 0, 0.999991894), new(44.5500183, 31, 96.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(306.28949, 20.8821259, -8.19596863, 0.999991894, 0, -0.000000178813934, 0, 1, 0, 0.000000178813934, 0, 0.999991894), new(19.5500164, 31, 48))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(274.800537, 11.3821259, -97.7935333, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(146.5, 12, 225.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(204.550537, 22.3821259, -144.543533, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(6, 34, 132))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(346.550537, 22.3821259, -144.543533, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(3, 34, 132))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(253.300537, 22.3821259, -206.043533, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(103.5, 34, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(334.550537, 22.3821259, -206.043533, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(19, 34, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(339.300537, 22.3821259, -242.043533, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(9.5, 34, 77))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(260.300537, 22.3821259, -219.293533, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(54.5, 34, 31.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(312.050537, 11.3821259, -110.543533, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(72, 12, 251))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(314.800537, 22.3821259, -277.293518, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(58.5, 34, 9.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(221.550537, 23.8821259, -421.543518, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(14, 42, 8))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(221.300537, 23.8821259, -497.293518, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(14.5, 42, 32.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(319.965942, 16.5022373, -230.817398, 0.950360954, 0.0000000437113883, -0.311149508, -0.0000000279408212, 1, 0.0000000551423724, 0.311149508, -0.0000000437113883, 0.950360954), new(69, 1.5, 85))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(289.800537, 9.63212585, -304.293518, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(116.5, 8.5, 138.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(233.300537, 21.6321259, -252.543518, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(3.5, 34.5, 35))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(234.925537, 22.1321259, -319.043518, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(21.25, 33.5, 100))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(313.300537, 22.1321259, -304.043518, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(37.5, 33.5, 57))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(352.550537, 22.1321259, -322.793518, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(55, 33.5, 94.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(268.550537, 22.1321259, -366.043518, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(66, 33.5, 6))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(302.300537, 9.63212585, -375.543518, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(154.5, 8.5, 281))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(377.550537, 25.1321259, -440.043518, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(4, 39.5, 147))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(302.800537, 25.1321259, -512.293518, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(153.5, 39.5, 2.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(227.050537, 25.1321259, -492.793518, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(10, 39.5, 41.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(227.300537, 25.1321259, -400.043518, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(10.5, 39.5, 68))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(149.300537, 23.8821259, -501.293518, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(158.5, 42, 24.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(72.3005371, 23.8821259, -414.543518, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(4.5, 42, 16))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(165.300537, 23.3821259, -412.793518, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(123.5, 41, 14.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(143.550537, 10.1321259, -427.793518, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(178, 9.5, 176.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(170.300537, 23.8821259, -387.293518, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(4.5, 42, 60.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(159.175537, 23.8821259, -335.043518, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(25.25, 42, 59))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(92.8005371, 23.8821259, -360.793518, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(47.5, 42, 7.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(69.8005371, 23.8821259, -424.543518, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(1.5, 42, 135))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(84.3005371, 22.6321259, -303.543518, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(133.5, 44.5, 6))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(67.0505371, 22.6321259, -351.293518, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(54, 44.5, 26.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(89.0505371, 22.6321259, -344.543518, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(17, 44.5, 25))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(122.300537, 10.8821259, -333.793518, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(51.5, 11, 54.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(64.4733582, -4.418859, -333.793518, 0.906307757, -0.42261827, 0, 0.42261827, 0.906307757, 0, 0, 0, 1), new(75.5, 11, 54.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(20.3005371, -3.61787415, -356.293518, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(95.5, 11, 99.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(39.9685135, 6.63212585, -380.228729, 0.913545489, 0, 0.406736732, 0, 1, 0, -0.406736732, 0, 0.913545489), new(14.5, 31.5, 46.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(18.114563, 6.63212585, -403.113617, 0.0174522102, 0, 0.999847889, 0, 1, 0, -0.999847889, 0, 0.0174522102), new(14.5, 31.5, 91))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-26.2788792, 6.63212585, -366.632813, 0.0174522102, 0, 0.999847889, 0, 1, 0, -0.999847889, 0, 0.0174522102), new(89, 31.5, 3.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-36.5266075, 17.3821259, -309.552948, 0.0174522102, 0, 0.999847889, 0, 1, 0, -0.999847889, 0, 0.0174522102), new(26.5, 53, 57))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(5.80053711, 4.07662964, -309.267822, 1, 0, 0, 0, -0.656059086, 0.754709542, 0, -0.754709542, -0.656059086), new(31.5, 24, 15.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(19.5505371, 19.3427505, -291.517181, 1, 0, 0, 0, 0.0174524486, 0.99984777, 0, -0.99984777, 0.0174524486), new(5, 62, 50.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-102.175552, 17.3821259, -272.943085, 0.0174522102, 0, 0.999847889, 0, 1, 0, -0.999847889, 0, 0.0174522102), new(102, 53, 90))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(4.05209827, 17.3821259, -242.084457, 0.0174522102, 0, 0.999847889, 0, 1, 0, -0.999847889, 0, 0.0174522102), new(40, 53, 74.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(38.5662766, 17.3821259, -170.971268, 0.0174522102, 0, 0.999847889, 0, 1, 0, -0.999847889, 0, 0.0174522102), new(181, 53, 3))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-47.4959297, 17.3821259, -82.2097092, 0.0174522102, 0, 0.999847889, 0, 1, 0, -0.999847889, 0, 0.0174522102), new(0.499998093, 53, 172))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-130.682892, 17.3821259, -158.17308, 0.0174522102, 0, 0.999847889, 0, 1, 0, -0.999847889, 0, 0.0174522102), new(149.5, 53, 3))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-40.7920074, 4.38212585, -194.109756, 0.0174522102, 0, 0.999847889, 0, 1, 0, -0.999847889, 0, 0.0174522102), new(224.5, 27, 181.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-25.6994476, 18.8821259, 117.706467, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(125.5, 27, 36.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-89.1994476, 18.8821259, 154.206467, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(7.5, 27, 61.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(282.050537, 22.1321259, -316.793518, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(28, 33.5, 5.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(226.777496, 14.4964676, -453.289978, 0.99999994, -0.0000000874227766, -0.000000000000000284238873, 0.0000000874227695, 1, 0.0000000874227766, -0.00000000000000735850217, -0.0000000874227766, 1), new(8, 1, 45.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(226.277496, 14.9964676, -453.289978, 0.99999994, -0.0000000874227766, -0.000000000000000284238873, 0.0000000874227695, 1, 0.0000000874227766, -0.00000000000000735850217, -0.0000000874227766, 1), new(7, 2, 43.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(225.777496, 15.4964676, -453.289978, 0.99999994, -0.0000000874227766, -0.000000000000000284238873, 0.0000000874227695, 1, 0.0000000874227766, -0.00000000000000735850217, -0.0000000874227766, 1), new(6, 3, 41.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(210.777496, 15.9964666, -456.539978, 0.99999994, -0.0000000874227766, -0.000000000000000284238873, 0.0000000874227695, 1, 0.0000000874227766, -0.00000000000000735850217, -0.0000000874227766, 1), new(31, 4, 77))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(210.027496, 14.9964666, -456.539978, 0.99999994, -0.0000000874227766, -0.000000000000000284238873, 0.0000000874227695, 1, 0.0000000874227766, -0.00000000000000735850217, -0.0000000874227766, 1), new(32.5, 4, 77))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(209.527496, 14.4964666, -456.539978, 0.99999994, -0.0000000874227766, -0.000000000000000284238873, 0.0000000874227695, 1, 0.0000000874227766, -0.00000000000000735850217, -0.0000000874227766, 1), new(33.5, 3, 77))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-3.77072525, 17.3821259, -202.161972, -0.731354296, 0, 0.681998551, 0, 1, 0, -0.681998551, 0, -0.731354296), new(29.5, 53, 29.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(21.5335732, 17.3821259, -189.938141, -0.99026978, 0, 0.13917309, 0, 1, 0, -0.13917309, 0, -0.99026978), new(45, 53, 24.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-11.1203985, 17.3821259, -219.985062, -0.190809608, 0, 0.981628776, 0, 1, 0, -0.981628776, 0, -0.190809608), new(29.5, 53, 29.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(21.5335732, 17.3821259, -189.938141, -0.99026978, 0, 0.13917309, 0, 1, 0, -0.13917309, 0, -0.99026978), new(45, 53, 24.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(201.004074, 16.6321259, 23.3383617, 0.0174523592, 0, -0.999846816, 0, 1, 0, 0.999846816, 0, 0.0174523592), new(2.5, 22.5, 94))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(291.03064, 16.8821259, 66.0365601, -0.0174523555, 0, -0.999844193, 0, 1, 0, 0.999844193, 0, -0.0174523555), new(12, 23, 12.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(292.446808, 16.8821259, 13.5534649, -0.0174523555, 0, -0.999844193, 0, 1, 0, 0.999844193, 0, -0.0174523555), new(16, 23, 11.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(241.550537, 22.1321259, -316.793518, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(12, 33.5, 5.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(198.585739, 15.9964609, -495.978149, 0.69465822, -0.0000000874227766, 0.719339728, -0.00000000215772644, 1, 0.000000123615649, -0.719339669, -0.0000000874227837, 0.694658399), new(31, 4, 24.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(197.891083, 14.9964609, -495.25882, 0.69465822, -0.0000000874227766, 0.719339728, -0.00000000215772644, 1, 0.000000123615649, -0.719339669, -0.0000000874227837, 0.694658399), new(31, 4, 24.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(196.849091, 13.9964609, -494.17981, 0.69465822, -0.0000000874227766, 0.719339728, -0.00000000215772644, 1, 0.000000123615649, -0.719339669, -0.0000000874227837, 0.694658399), new(31, 4, 24.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(200.608017, 15.9964695, -413.158813, 0.707106352, -0.0000000874227979, -0.70710659, 0.000000123634393, 1, 0.0000000000000244249065, 0.707106471, -0.0000000874227837, 0.707106888), new(31, 4, 21))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(199.900909, 14.9964695, -413.865906, 0.707106352, -0.0000000874227979, -0.70710659, 0.000000123634393, 1, 0.0000000000000244249065, 0.707106471, -0.0000000874227837, 0.707106888), new(31, 4, 21))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(199.193802, 13.9964695, -414.572998, 0.707106352, -0.0000000874227979, -0.70710659, 0.000000123634393, 1, 0.0000000000000244249065, 0.707106471, -0.0000000874227837, 0.707106888), new(31, 4, 21))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(82.0505371, 23.8821259, -496.543518, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(24, 42, 34))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(319.015594, 15.5022373, -231.12854, 0.950360954, 0.0000000437113883, -0.311149508, -0.0000000279408212, 1, 0.0000000551423724, 0.311149508, -0.0000000437113883, 0.950360954), new(69, 1.5, 85))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(318.065247, 14.5022373, -231.439682, 0.950360954, 0.0000000437113883, -0.311149508, -0.0000000279408212, 1, 0.0000000551423724, 0.311149508, -0.0000000437113883, 0.950360954), new(69, 1.5, 85))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(317.114899, 13.5022373, -231.750824, 0.950360954, 0.0000000437113883, -0.311149508, -0.0000000279408212, 1, 0.0000000551423724, 0.311149508, -0.0000000437113883, 0.950360954), new(69, 1.5, 85))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(241.800537, 22.1321259, -317.043518, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(12.5, 33.5, 6))
    wait2 = fn12
    CFrame110 = CFrame
    local PathfindingService = CFrame110.new(122.300537, 9.88212585, -334.293518, 1, 0, 0, 0, 1, 0, 0, 0, 1)
    new = Vector3.new
    wait2(PathfindingService, new(51.5, 11.5, 55.5))
    wait2 = wait
    PathfindingService = 0.1
    wait2(PathfindingService)
    if _G.destroy_map then
        local Terrain, value = workspace.Terrain, "Clear"
        local value2 = Terrain
        value2[value](value2)
        Terrain = workspace:FindFirstChild("Map")
        if Terrain then
            value = "Destroy"
            value2 = Terrain
            value2[value](value2)
        end
    end
end

function canalsFix()
    local value = fn12
    local new = Vector3.new
    value(CFrame.new(155.957275, 32.8910141, -46.5320663, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(11.7300148, 87.4399948, 105.580002))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-138.143799, 32.8910141, 163.496231, -0.0000000437113883, 0, 1, 0, 1, 0, -1, 0, -0.0000000437113883), new(97.5299759, 87.4399948, 22.3999958))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-34.8195114, 32.8910141, -67.9616165, -1, -0.0000000874227766, 0, -0.0000000874227766, 1, -0.0000000874227766, 0.00000000000000764274186, -0.0000000874227766, -1), new(83.9499435, 87.4399948, 46.5899925))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-103.979477, 32.8910141, -224.424011, -0.0000000437113883, 0, -1, 0, 1, 0, 1, 0, -0.0000000437113883), new(6.84993505, 87.4399948, 235.629959))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-186.825027, 62.1460152, 73.4007111, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(84.4299774, 145.949997, 5.42000008))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-241.964264, 32.8910141, -94.9756775, -0.766044438, -0.0000000669697329, -0.642787576, -0.0000000312285025, 1, -0.0000000669697329, 0.642787576, -0.0000000312285025, -0.766044438), new(66.1999207, 87.4399948, 5.42000008))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-55.4694901, 32.8910141, -157.089325, -1, -0.0000000874227766, 0, -0.0000000874227766, 1, -0.0000000874227766, 0.00000000000000764274186, -0.0000000874227766, -1), new(6.84993505, 87.4399948, 138.609985))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-145.703644, 32.8910141, 28.710371, -1, -0.0000000874227766, 0, -0.0000000874227766, 1, -0.0000000874227766, 0.00000000000000764274186, -0.0000000874227766, -1), new(84.4299774, 87.4399948, 5.42000008))
    value = fn12
    new = Vector3.new
    value(CFrame.new(71.0828094, 32.8910141, 50.8468018, -0.0000000437113883, 0, -1, 0, 1, 0, 1, 0, -0.0000000437113883), new(49.6700058, 87.4399948, 93.9099808))
    value = fn12
    new = Vector3.new
    value(CFrame.new(135.878815, 32.8910141, 15.5871773, 0.719339788, 0, -0.694658399, 0, 1, 0, 0.694658399, 0, 0.719339788), new(11.7300148, 87.4399948, 58.2199783))
    value = fn12
    new = Vector3.new
    value(CFrame.new(225.497131, 36.9860115, -59.8648605, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(150.809937, 95.6299896, 52.0899887))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-242.781433, 32.8910141, -16.9685707, -0.121869326, -0.0000000106541549, 0.992546141, -0.000000174193914, 1, -0.0000000106541549, -0.992546141, -0.000000174193914, -0.121869326), new(80.8499374, 87.4399948, 5.42000008))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-224.062851, 32.8910141, -75.7806473, -0.766044438, -0.0000000669697329, -0.642787576, -0.0000000312285025, 1, -0.0000000669697329, 0.642787576, -0.0000000312285025, -0.766044438), new(63.4499245, 87.4399948, 5.92000008))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-145.703644, 62.2310066, 113.641754, -0.0000000437113883, 0, 1, 0, 1, 0, -1, 0, -0.0000000437113883), new(84.4299774, 146.11998, 5.42000008))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-294.795288, 32.8910141, -76.0985794, -0.99862951, -0.0000000873029649, -0.0523359589, -0.0000000828474214, 1, -0.0000000873029649, 0.0523359589, -0.0000000828474214, -0.99862951), new(63.6999283, 87.4399948, 5.42000008))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-123.277046, 32.8910141, 120.19175, -0.0000000437113883, 0, 1, 0, 1, 0, -1, 0, -0.0000000437113883), new(97.5299759, 87.4399948, 15.5299997))
    value = fn12
    new = Vector3.new
    value(CFrame.new(397.023865, 36.9860115, -58.8248749, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(150.809937, 95.6299896, 54.1699905))
    value = fn12
    new = Vector3.new
    value(CFrame.new(416.749054, 36.9860115, -96.7398682, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(111.359848, 95.6299896, 117.999992))
    value = fn12
    new = Vector3.new
    value(CFrame.new(425.636475, 36.9860115, 1.16940498, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(106.859848, 95.6299896, 82.909996))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-121.666016, 32.8910141, 279.982574, -0.0000000437113883, 0, 1, 0, 1, 0, -1, 0, -0.0000000437113883), new(97.5299759, 87.4399948, 11.550005))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-98.9495239, 59.7010269, -44.2266006, -1, -0.0000000874227766, 0, -0.0000000874227766, 1, -0.0000000874227766, 0.00000000000000764274186, -0.0000000874227766, -1), new(58.7299576, 33.8199959, 24.7199955))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-98.8532333, 32.8910141, 51.1067657, -0.0000000437113883, 0, -1, 0, 1, 0, 1, 0, -0.0000000437113883), new(50.0699921, 87.4399948, 41.260006))
    value = fn12
    new = Vector3.new
    value(CFrame.new(371.486694, 36.9860115, 44.0894165, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(215.159775, 95.6299896, 16.9300041))
    value = fn12
    new = Vector3.new
    value(CFrame.new(189.412186, 36.9860115, 17.0006351, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(16.339817, 95.6299896, 52.0800133))
    value = fn12
    new = Vector3.new
    value(CFrame.new(196.772171, 36.9860115, -85.2920761, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(93.3599701, 95.6299896, 28.0600014))
    value = fn12
    new = Vector3.new
    value(CFrame.new(155.065796, 36.9860115, 67.287796, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(20.3698311, 95.6299896, 17.1600227))
    value = fn12
    new = Vector3.new
    value(CFrame.new(124.959198, 36.9860115, 134.113754, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(41.2598, 95.6299896, 74.7600098))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-162.458191, 32.8910141, -68.6916199, -1, -0.0000000874227766, 0, -0.0000000874227766, 1, -0.0000000874227766, 0.00000000000000764274186, -0.0000000874227766, -1), new(83.9499435, 87.4399948, 45.1299858))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-111.588234, 32.8910141, 50.9817734, -0.0000000437113883, 0, -1, 0, 1, 0, 1, 0, -0.0000000437113883), new(49.939991, 87.4399948, 15.7900009))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-25.9021072, 32.8910141, 50.9817734, -0.0000000437113883, 0, -1, 0, 1, 0, 1, 0, -0.0000000437113883), new(49.939991, 87.4399948, 114.280014))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-223.311798, 32.8910141, -168.529022, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(6.84993505, 87.4399948, 116.899963))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-136.288849, 32.8910141, 301.444031, -0.0000000437113883, 0, 1, 0, 1, 0, -1, 0, -0.0000000437113883), new(32.1999626, 87.4399948, 18.6900043))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-232.190765, 32.8910141, 48.9222374, -0.224951044, -0.0000000196658441, 0.974370062, -0.000000172604913, 1, -0.0000000196658441, -0.974370062, -0.000000172604913, -0.224951044), new(54.5299835, 87.4399948, 5.42000008))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-170.796127, 32.8910141, 24.3202763, -0.0000000437113883, 0, -1, 0, 1, 0, 1, 0, -0.0000000437113883), new(84.4299774, 87.4399948, 5.42000008))
    value = fn12
    new = Vector3.new
    value(CFrame.new(186.772171, 36.9860115, -167.385376, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(113.35997, 95.6299896, 15.4500008))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-132.073868, 32.8910141, 268.779114, -0.0000000437113883, 0, 1, 0, 1, 0, -1, 0, -0.0000000437113883), new(97.5299759, 87.4399948, 10.260006))
    value = fn12
    new = Vector3.new
    value(CFrame.new(175.484131, 36.9860115, 53.6146545, -0.707106769, -0.0000000618172393, 0.707106769, -0.000000149240009, 1, -0.0000000618172393, -0.707106769, -0.000000149240009, -0.707106769), new(16.339817, 95.6299896, 46.5600052))
    value = fn12
    new = Vector3.new
    value(CFrame.new(124.959198, 36.9860115, 71.5675964, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(41.2598, 95.6299896, 17.1600227))
    value = fn12
    new = Vector3.new
    value(CFrame.new(117.913742, 77.9372025, 156.825684, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(167.879807, 17.2299976, 14.8899794))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-207.538849, 32.8910141, 296.944031, -0.0000000437113883, 0, 1, 0, 1, 0, -1, 0, -0.0000000437113883), new(41.1999626, 87.4399948, 2.19000244))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-187.778656, 27.8627968, 362.189514, -0.0000000437113883, 0, 1, 0, 1, 0, -1, 0, -0.0000000437113883), new(125.759773, 117.039948, 42.3200684))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-47.6979599, 48.4710083, 120.507584, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(68.4998016, 72.6599579, 42.0500107))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-330.275391, 43.1127968, 387.889862, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(245.559784, 86.5399475, 41.8200684))
    value = fn12
    new = Vector3.new
    value(CFrame.new(267.329956, 44.1549873, 47.4600601, 1, 0, -0.0000000437113883, 0, 1, 0, 0.0000000437113883, 0, 1), new(83.4698105, 65.7099991, 33.4500122))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-281.293365, 65.0105286, 53.0568275, -0.241921902, -0.0000000211494839, 0.970295727, -0.000000172248718, 1, -0.0000000211494839, -0.970295727, -0.000000172248718, -0.241921902), new(145.519989, 89.8999939, 14.3299999))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-463.079102, 43.6127968, 295.492493, -0.0000000437113883, 0, 1, 0, 1, 0, -1, 0, -0.0000000437113883), new(245.559784, 85.5399475, 41.8200684))
    value = fn12
    new = Vector3.new
    value(CFrame.new(46.2713356, 50.5749092, -60.2988358, -0.0000000437113883, 0, -1, 0, 1, 0, 1, 0, -0.0000000437113883), new(102.98999, 76.6199799, 150.919952))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-51.3865967, 44.7459869, 279.715424, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(140.999802, 54.1599617, 44.3200684))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-304.962646, 44.8627968, 155.790512, -1, -0.0000000874227766, 0, -0.0000000874227766, 1, -0.0000000874227766, 0.00000000000000764274186, -0.0000000874227766, -1), new(245.559784, 83.0399475, 41.8200684))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-33.8865967, 44.7459869, 164.972504, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(101.999802, 54.1599617, 52.3200684))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-303.172791, 48.7665901, -37.5034637, -0.10452842, -0.00000000913816489, 0.994521916, -0.000000174366647, 1, -0.00000000913816489, -0.994521916, -0.000000174366647, -0.10452842), new(48.9499397, 19.0299969, 20.3599987))
    value = fn12
    new = Vector3.new
    value(CFrame.new(13.9149284, 36.9860115, 136.112579, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(57.2598, 95.6299896, 76.2600098))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-219.415039, 70.8955231, 110.323151, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(83.8099518, 122.169983, 13.8299999))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-165.575058, 61.5059929, 108.555695, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(41.9299812, 144.669952, 23.8700027))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-198.054108, 47.3627968, 299.961273, -0.809017003, -0.0000000707265144, 0.587785244, -0.000000138808588, 1, -0.0000000707265144, -0.587785244, -0.000000138808588, -0.809017003), new(21.0899963, 78.0399475, 6.30006504))
    value = fn12
    new = Vector3.new
    value(CFrame.new(17.4978638, 32.8910141, 45.4267883, -0.0000000437113883, 0, -1, 0, 1, 0, 1, 0, -0.0000000437113883), new(38.8299904, 87.4399948, 201.079956))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-304.545441, 64.4899902, 21.4497986, -0.104528427, 0.00000000000000177635684, 0.994521916, 0, 1, 0, -0.994521916, 0.0000000000000142108547, -0.104528427), new(190.769989, 98.3999939, 10.8299999))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-112.038849, 4.6410141, 169.694031, -0.0000000437113883, 0, 1, 0, 1, 0, -1, 0, -0.0000000437113883), new(17.6999512, 30.9399948, 41.1900024))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-249.993698, 65.0105209, 98.5818253, -0.681998253, -0.000000021149468, 0.731353581, -0.00000014039864, 1, -0.000000102005565, -0.731353581, -0.000000172248718, -0.681998253), new(214.269989, 89.8999939, 3.57999992))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-248.899078, 32.8910065, -55.5102959, -0.121869326, -0.0000000106541549, 0.992546141, -0.000000174193914, 1, -0.0000000106541549, -0.992546141, -0.000000174193914, -0.121869326), new(4.34993744, 87.4399948, 8.17000008))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-273.835968, 17.4611702, 40.0727425, 0, -0.0000000874227695, 1, -0.0000000874227837, 1, 0.0000000874227837, -1, -0.0000000874227837, 0), new(230.769989, 4.8999939, 88.3300018))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-251.195892, 7.01116419, 91.0399628, -1, -0.0000000874227766, 0, -0.0000000874227766, 1, -0.0000000874227766, 0.00000000000000764274186, -0.0000000874227766, -1), new(47.0499802, 24, 33.1999054))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-249.195892, 6.01116419, 91.5399628, -1, -0.0000000874227766, 0, -0.0000000874227766, 1, -0.0000000874227766, 0.00000000000000764274186, -0.0000000874227766, -1), new(47.0499802, 24, 41.1999054))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-247.195892, 5.01116419, 93.2899628, -1, -0.0000000874227766, 0, -0.0000000874227766, 1, -0.0000000874227766, 0.00000000000000764274186, -0.0000000874227766, -1), new(47.0499802, 24, 45.6999054))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-245.195892, 4.01116419, 89.2899628, -1, -0.0000000874227766, 0, -0.0000000874227766, 1, -0.0000000874227766, 0.00000000000000764274186, -0.0000000874227766, -1), new(47.0499802, 24, 50.6999054))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-243.195892, 3.01116443, 92.0399628, -1, -0.0000000874227766, 0, -0.0000000874227766, 1, -0.0000000874227766, 0.00000000000000764274186, -0.0000000874227766, -1), new(47.0499802, 24, 46.1999054))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-241.195892, 2.01116443, 92.2899628, -1, -0.0000000874227766, 0, -0.0000000874227766, 1, -0.0000000874227766, 0.00000000000000764274186, -0.0000000874227766, -1), new(47.0499802, 24, 47.6999054))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-239.195892, 1.01116467, 95.2899628, -1, -0.0000000874227766, 0, -0.0000000874227766, 1, -0.0000000874227766, 0.00000000000000764274186, -0.0000000874227766, -1), new(47.0499802, 24, 45.6999054))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-181.175049, 11.859992, 89.4149475, -0.000000000000000280912309, -0.0000000874227624, 1, -0.0000000874227766, 1, 0.0000000874227908, -1, -0.0000000874227766, 0.00000000000000736183101), new(33.769989, 0.899993896, 68.8300018))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-38.9890747, 11.6300173, -100.624664, -1, -0.0000000874227766, 0.00000000000000770258813, -0.0000000874227766, 1, -0.0000000874227766, -0.0000000000000000598462659, -0.0000000874227766, -1), new(388.849945, 2.43999481, 252.609985))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-79.9495239, 44.2010269, -44.2266006, -1, -0.0000000874227766, 0, -0.0000000874227766, 1, -0.0000000874227766, 0.00000000000000764274186, -0.0000000874227766, -1), new(20.7299576, 64.8199921, 24.7199955))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-114.449524, 44.2010269, -44.2266006, -1, -0.0000000874227766, 0, -0.0000000874227766, 1, -0.0000000874227766, 0.00000000000000764274186, -0.0000000874227766, -1), new(21.7299576, 64.8199921, 24.7199955))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-146.699524, 44.2010269, -23.4766006, -1, -0.0000000874227766, 0, -0.0000000874227766, 1, -0.0000000874227766, 0.00000000000000764274186, -0.0000000874227766, -1), new(56.2299576, 64.8199921, 66.2199936))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-47.6995239, 44.2010345, -30.7266006, -1, -0.0000000874227766, 0, -0.0000000874227766, 1, -0.0000000874227766, 0.00000000000000764274186, -0.0000000874227766, -1), new(41.22995, 64.8199921, 51.7199936))
    value = fn12
    new = Vector3.new
    value(CFrame.new(121.772171, 36.9860115, -141.885376, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(21.3599701, 95.6299896, 66.4499969))
    value = fn12
    new = Vector3.new
    value(CFrame.new(305.272156, 36.9860115, -162.635376, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(125.35997, 95.6299896, 24.9500008))
    value = fn12
    new = Vector3.new
    value(CFrame.new(207.30394, 36.9860153, 63.8677101, -0.707106769, -0.0000000618172393, 0.707106769, -0.000000149240009, 1, -0.0000000618172393, -0.707106769, -0.000000149240009, -0.707106769), new(6.83981705, 95.6299896, 61.0600052))
    value = fn12
    new = Vector3.new
    value(CFrame.new(182.976639, 30.7049866, 90.3965759, -0.887010872, -0.00000000000000355271368, 0.46174866, 0, 1, -0.00000000000000710542736, -0.46174866, 0, -0.887010872), new(5.33981705, 95.6299896, 14.0600052))
    value = fn12
    new = Vector3.new
    value(CFrame.new(178.860107, 32.4249954, 129.819794, -1.00000012, -0.00000000000000315129545, -0.0000000298023224, 0.00000000000000315129566, 1, -0.00000000000000874588793, 0.0000000298023224, 0.00000000000000874588793, -1.00000012), new(4.33981705, 95.6299896, 69.0600052))
    value = fn12
    new = Vector3.new
    value(CFrame.new(160.610107, 32.4249954, 163.569794, -1.00000012, -0.00000000000000315129545, -0.0000000298023224, 0.00000000000000315129566, 1, -0.00000000000000874588793, 0.0000000298023224, 0.00000000000000874588793, -1.00000012), new(40.839817, 95.6299896, 1.56000519))
    value = fn12
    new = Vector3.new
    value(CFrame.new(88.459198, 36.9860115, 166.613754, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(114.259796, 95.6299896, 9.76000977))
    value = fn12
    new = Vector3.new
    value(CFrame.new(311.260925, 24.7869816, -58.2802277, -1, -0.0000000874098589, -0.00000000152582125, -0.0000000874224142, 0.99984777, 0.0174522698, 0.0000000000000352690052, 0.0174522698, -0.99984777), new(23.3499451, 39.9399948, 24.6099854))
    value = fn12
    new = Vector3.new
    value(CFrame.new(17.1134033, 44.7459869, 243.465424, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(3.99980164, 54.1599617, 116.820068))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-166.538849, 32.8910141, 307.694031, -0.0000000437113883, 0, 1, 0, 1, 0, -1, 0, -0.0000000437113883), new(19.6999626, 87.4399948, 79.1900024))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-207.538849, 32.8910141, 217.694031, -0.0000000437113883, 0, 1, 0, 1, 0, -1, 0, -0.0000000437113883), new(82.6999664, 87.4399948, 2.19000244))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-427.212646, 47.3627853, 175.540512, -1, -0.0000000874227766, 0, -0.0000000874227766, 1, -0.0000000874227766, 0.00000000000000764274186, -0.0000000874227766, -1), new(31.0597839, 78.0399475, 81.3200684))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-176.288849, 32.8910141, 211.694031, -0.0000000437113883, 0, 1, 0, 1, 0, -1, 0, -0.0000000437113883), new(42.6999664, 87.4399948, 59.6900024))
    value = fn12
    new = Vector3.new
    value(CFrame.new(75.8479004, 0.891014099, -2.7682178, -0.0000000437113883, 0, -1, 0, 1, 0, 1, 0, -0.0000000437113883), new(391.440002, 23.4399948, 462.780029))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-49.6365967, 18.9959869, 200.222504, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(133.499802, 2.6599617, 121.820068))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-290.788849, 0.641014099, 262.194031, -0.0000000437113883, 0, 1, 0, 1, 0, -1, 0, -0.0000000437113883), new(241.699966, 22.9399948, 369.690002))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-109.038849, 1.3910141, 264.194031, -0.0000000437113883, 0, 1, 0, 1, 0, -1, 0, -0.0000000437113883), new(237.699951, 24.4399948, 35.1900024))
    value = fn12
    new = Vector3.new
    value(CFrame.new(239.912186, 36.9860115, -22.4993649, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(117.339813, 95.6299896, 48.0800133))
    value = fn12
    new = Vector3.new
    value(CFrame.new(178.260925, 23.3800297, -162.874664, -1, -0.0000000874227766, 0.00000000000000770258813, -0.0000000874227766, 1, -0.0000000874227766, -0.0000000000000000598462659, -0.0000000874227766, -1), new(121.349945, 25.9399948, 128.109985))
    value = fn12
    new = Vector3.new
    value(CFrame.new(307.760925, 23.380043, -136.374664, -1, -0.0000000874227766, 0.00000000000000770258813, -0.0000000874227766, 1, -0.0000000874227766, -0.0000000000000000598462659, -0.0000000874227766, -1), new(137.349945, 25.9399948, 181.109985))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-99.9021072, -12.9436626, 113.714745, -0.0000000353632537, 0.0000000256929074, -1, 0.587785184, 0.809016943, -0.00000000000000044408921, 0.809016943, -0.587785184, -0.0000000437113918), new(79.9400024, 23.4399948, 56.2800293))
    value = fn12
    new = Vector3.new
    value(CFrame.new(42.959198, 36.9860115, 134.363754, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(23.2597961, 95.6299896, 74.2600098))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-121.288857, 0.756968558, 202.870163, -0.0000000420180761, 0.0000000120484973, 1, 0.275637388, 0.961261809, 0.00000000000000333066907, -0.961261809, 0.275637388, -0.0000000437113918), new(59.1999512, 23.9399948, 10.6900024))
    value = fn12
    new = Vector3.new
    value(CFrame.new(310.510925, 23.1539402, -49.8755417, -1, -0.0000000733189793, -0.0000000476138418, -0.000000087422741, 0.838670671, 0.544638932, -0.0000000000000130358269, 0.544638932, -0.838670671), new(24.8499451, 39.9399948, 16.6099854))
    value = fn12
    new = Vector3.new
    value(CFrame.new(310.510925, 21.0615959, -71.9470215, -1, -0.0000000778942706, 0.0000000396891195, -0.0000000874227766, 0.89100647, -0.453990608, -0.000000000000000053323414, -0.453990608, -0.89100647), new(24.8499451, 39.9399948, 24.6099854))
    value = fn12
    new = Vector3.new
    value(CFrame.new(137.010925, 20.868412, -68.4826736, -1, -0.0000000804731002, -0.0000000341587914, -0.0000000874227695, 0.920504868, 0.390731037, -0.0000000000000000514420645, 0.390731037, -0.920504868), new(38.8499451, 4.43999481, 68.1099854))
    value = fn12
    new = Vector3.new
    value(CFrame.new(256.935089, 9.34212494, 30.1253357, -0.920504808, -0.390731215, 0.00000000000000355271368, -0.390731215, 0.920504808, -0.0000000874227837, 0.0000000341587985, -0.0000000804730931, -1), new(66.8499451, 24.4399948, 66.1099854))
    value = fn12
    new = Vector3.new
    value(CFrame.new(337.760925, 22.6300564, 12.8753357, -1, -0.0000000874227766, 0.00000000000000770258813, -0.0000000874227766, 1, -0.0000000874227766, -0.0000000000000000598462659, -0.0000000874227766, -1), new(77.3499451, 24.4399948, 100.609985))
    value = fn12
    new = Vector3.new
    value(CFrame.new(337.010925, 22.1300583, 30.1253357, -1, -0.0000000874227766, 0.00000000000000770258813, -0.0000000874227766, 1, -0.0000000874227766, -0.0000000000000000598462659, -0.0000000874227766, -1), new(78.8499451, 23.4399948, 66.1099854))
    value = fn12
    new = Vector3.new
    value(CFrame.new(329.510925, 21.1300583, 30.1253357, -1, -0.0000000874227766, 0.00000000000000770258813, -0.0000000874227766, 1, -0.0000000874227766, -0.0000000000000000598462659, -0.0000000874227766, -1), new(93.8499451, 24.4399948, 66.1099854))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-110.288849, 1.1410141, 231.444031, -0.0000000437113883, 0, 1, 0, 1, 0, -1, 0, -0.0000000437113883), new(51.1999512, 23.9399948, 37.6900024))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-112.038849, 0.891014099, 231.444031, -0.0000000437113883, 0, 1, 0, 1, 0, -1, 0, -0.0000000437113883), new(51.1999512, 23.4399948, 41.1900024))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-245.053238, 24.6439991, -76.1922913, 0.131052777, 0.743242264, 0.656061411, -0.984807491, 0.173650265, -0.00000370293856, -0.113928005, -0.646093667, 0.754707873), new(4.34993744, 13.9399948, 22.9200001))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-219.118988, 16.1449757, -98.7366257, -0.342632473, 0.672451258, 0.656058371, -0.891007841, -0.453988045, -0.00000527128577, 0.297839075, -0.58455497, 0.754710317), new(4.34993744, 33.9399948, 22.9200001))
    value = fn12
    new = Vector3.new
    value(CFrame.new(-235.20369, 24.6545467, -84.7544098, -0.118063509, 0.745420098, 0.656065226, -0.987691581, -0.156433806, -0.00000313296914, 0.102626264, -0.647989988, 0.754713774), new(4.59993744, 13.9399948, 22.9200001))
    value = fn12
    CFrame110 = CFrame
    local PathfindingService = CFrame110.new(-254.772614, 20.8520355, -67.7679214, 0.335811794, 0.688516259, 0.642787576, -0.898794055, 0.438371211, -0.00000000186264515, -0.281779528, -0.577733696, 0.766044378)
    new = Vector3.new
    value(PathfindingService, new(3.09993744, 14.6899948, 22.9200001))
    local _G2 = _G
    PathfindingService = "destroy_map"
    if _G2[PathfindingService] then
        local Terrain, value2 = workspace.Terrain, "Clear"
        local workspace2 = Terrain
        workspace2[value2](workspace2)
        local pairs2 = pairs
        workspace2 = workspace
        value2 = workspace2
        for k, v in pairs2(value2.GetChildren(value2)) do
            if (v.ClassName == "Model"
                or v.ClassName == "Part"
                or v.ClassName == "UnionOperation"
                or v.ClassName == "WedgePart"
                or v.Name == "MeshPart")
                and v ~= game.Players.LocalPlayer.Character
                and v.Name ~= result3
                and v.Name ~= "secondBossSafeSpots"
                and v.Name ~= "finalBossObjectSpawns" then
                local value4, value5 = "Destroy", v
                value5[value4](value5)
            end
        end
    end
end

function steamFix()
    local wait2 = fn12
    local new = Vector3.new
    wait2(CFrame.new(1598.42798, -10.4780731, -429.198364, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(2.5, 59, 146.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(1487.67798, -10.4780731, -502.198364, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(224, 59, 0.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(1488.92798, -10.4780731, -357.448364, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(221.5, 59, 7))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(1388.92798, -40.2280731, -429.448364, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(44.5, 29.5, 151))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(1431.1106, -53.0152588, -431.698364, 0.882947683, 0.469471514, 0, -0.469471514, 0.882947683, 0, 0, 0, 1), new(62.5, 29.5, 31.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(1326.0979, -27.7056007, -431.698364, 0.965927362, 0.258819342, 0, -0.258819342, 0.965927362, 0, 0, 0, 1), new(155, 29.5, 31.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(1316.12097, -7.95021439, -416.198364, 0.965927362, 0.258819342, 0, -0.258819342, 0.965927362, 0, 0, 0, 1), new(125.5, 62.5, 0.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(1316.84546, -8.14432907, -447.948364, 0.965927362, 0.258819342, 0, -0.258819342, 0.965927362, 0, 0, 0, 1), new(127, 62.5, 3))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(1171.92798, -8.22807312, -429.448364, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(165.5, 29.5, 151))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(1171.92798, 9.52192688, -481.448364, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(165.5, 65, 47))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(1171.92798, 9.52192688, -397.198364, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(165.5, 65, 10.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(1088.17798, 9.52192688, -408.698364, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(5, 65, 33.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(1088.92798, 9.52192688, -447.698364, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(3.5, 65, 22.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(1059.92798, -3.47807312, -429.698364, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(61.5, 39, 58.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(1034.92798, -7.47807312, -429.698364, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(111.5, 31, 94.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(1019.40039, -7.82135487, -430.448364, 0.866025388, -0.5, 0, 0.5, 0.866025388, 0, 0, 0, 1), new(40.5, 31.5, 28))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(978.677979, 0.27192688, -429.698364, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(2, 14.5, 94.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(977.927979, 0.0219268799, -429.698364, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(2.5, 14, 94.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(977.427979, -0.22807312, -429.698364, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(3.5, 13.5, 94.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(960.427979, -13.4780731, -437.698364, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(37.5, 39, 161.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(937.427979, -13.4780731, -481.198364, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(83.5, 39, 74.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(937.427979, 8.27192688, -510.698364, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(83.5, 82.5, 15.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(976.177979, 8.27192688, -489.198364, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(9, 82.5, 56.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(975.927979, 8.27192688, -379.448364, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(8.5, 82.5, 39))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(811.927979, -33.4780731, -435.948364, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(334.5, 2, 165))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(947.677979, -27.1234665, -424.020416, 1, 0, 0, 0, 0.777145922, -0.629320383, 0, 0.629320383, 0.777145922), new(63, 27, 72.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(680.177979, -8.72807312, -364.198364, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(71, 51.5, 32.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(679.927979, -9.72807312, -493.948364, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(70.5, 49.5, 31))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(644.177979, -16.4780731, -461.448364, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(4, 36, 35))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(644.177979, -16.4780731, -395.948364, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(4, 36, 38))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(597.093445, -20.3076077, -428.198364, 0.965925813, 0.258819044, 0, -0.258819044, 0.965925813, 0, 0, 0, 1), new(129, 2, 35.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(398.177979, -18.7280731, -428.198364, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(277, 31.5, 103.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(496.177979, 1.77192688, -377.948364, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(81, 72.5, 3))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(496.177979, 1.77192688, -480.698364, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(81, 72.5, 3.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(467.177979, 1.77192688, -459.948364, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(5, 72.5, 45))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(467.177979, 1.77192688, -399.948364, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(5, 72.5, 39))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(589.427979, 1.77192688, -397.448364, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(111.5, 72.5, 34))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(589.427979, 1.77192688, -466.948364, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(111.5, 72.5, 46))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(351.927979, -3.47807312, -464.948364, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(221.5, 62, 30))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(260.677979, -18.4780731, -428.198364, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(2, 32, 103.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(249.677979, -17.9780731, -428.198364, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(21, 33, 103.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(249.677979, -7.97807312, -428.198364, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(19, 15, 103.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(249.677979, -7.47807312, -438.698364, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(16, 16, 82.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(234.190384, -24.4961605, -428.198364, 0.848048091, -0.529919267, 0, 0.529919267, 0.848048091, 0, 0, 0, 1), new(33, 33, 103.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(115.927979, -27.2280731, -296.698364, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(292.5, 38.5, 396.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(41.9279785, -22.7280731, -25.4483643, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(56.5, 47.5, 147))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(69.1779785, 11.0219269, 10.3016357, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(2, 54, 75.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(18.4279785, 11.0219269, 10.0516357, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(0.5, 54, 76))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(44.1779785, 11.0219269, 43.3016357, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(52, 54, 9.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(43.1779785, -8.81507015, -108.920464, 1, 0, 0, 0, 0.906307936, 0.4226183, 0, -0.4226183, 0.906307936), new(33, 9, 29))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(915.927979, -13.4780731, -419.948364, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(1.5, 39, 50))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(1105.50012, 1.51558495, -430.948364, 0.838670552, 0.544639051, 0, -0.544639051, 0.838670552, 0, 0, 0, 1), new(40.5, 8.5, 12))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(1258.92798, 9.52192688, -475.698364, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(13.5, 65, 58.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(1259.17798, 9.52192688, -409.448364, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(14, 65, 14))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(1421.67798, -37.7280731, -416.198364, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(31, 34.5, 0.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(1421.67798, -38.4780731, -447.698364, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(31, 33, 0.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(942.427979, 25.0219269, -440.073364, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(1.5, 39, 10.75))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(1370.17798, -24.7280731, -383.448364, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(7, 60.5, 59))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(1371.92798, -24.7280731, -475.948364, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(10.5, 60.5, 60))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(1059.42798, 3.02192688, -401.698364, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(99.5, 52, 47.5))
    wait2 = fn12
    CFrame61 = CFrame
    local PathfindingService = CFrame61.new(1059.17798, 3.02192688, -449.948364, 1, 0, 0, 0, 1, 0, 0, 0, 1)
    new = Vector3.new
    wait2(PathfindingService, new(99, 52, 26))
    wait2 = wait
    PathfindingService = 0.1
    wait2(PathfindingService)
    if _G.destroy_map then
        local result2 = fn3(workspace, "borders")
        if result2 then
            local pairs2 = pairs
            local value, value2 = "GetChildren", result2
            local item = value2[value]
            for k, v in pairs2(item(value2)) do
                local value3 = item4
                local value4, value5 = "AddTag", value3
                value5[value4](value5, v, "RayWhitelist")
            end
        end
        local Terrain = workspace.Terrain
        value2 = "Clear"
        local workspace2 = Terrain
        workspace2[value2](workspace2)
        local pairs3 = pairs
        workspace2 = workspace
        value = "GetChildren"
        value2 = workspace2
        local item2 = value2[value]
        for k2, v2 in pairs3(item2(value2)) do
            if (v2.ClassName == "Model"
                or v2.ClassName == "Part"
                or v2.ClassName == "UnionOperation"
                or v2.ClassName == "WedgePart"
                or v2.Name == "MeshPart")
                and v2 ~= game.Players.LocalPlayer.Character
                and v2.Name ~= result3 then
                local value6, value7 = "Destroy", v2
                value7[value6](value7)
            end
        end
    end
end

function ghastlyFix()
    _G.smallTeleportVal = 100
    _G.SemiTeleports = true
    _G.teleportDuringBossOnly = false
    local spawn2 = fn12
    local new = Vector3.new
    spawn2(CFrame.new(314.997986, 164.955307, 141.573303, 0.969875216, 0, 0.243605107, 0, 1.00000072, 0, -0.243605226, 0, 0.96987462), new(47.75, 1.75, 32.25))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(330.773529, 164.955322, 178.724518, 0.847127557, 0, 0.531389952, 0, 1.00000024, 0, -0.531390011, 0, 0.847127378), new(35.25, 1.75, 66.5))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(291.867157, 164.455322, 192.210632, 0.847127557, 0, 0.531389952, 0, 1.00000024, 0, -0.531390011, 0, 0.847127378), new(45.5, 0.75, 28.5))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(314.526306, 166.267242, 122.420898, 0.999228716, 0.0203912593, 0.0335599519, 0.0000898155777, 0.853422642, -0.521219611, -0.0392691493, 0.520820618, 0.852762461), new(31.25, 5.75, 11))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(309.891113, 205.179276, -100.146835, 0.995393157, 0.00000000186264515, 0.0958794728, 0, 1.00000012, -0.0000000298023224, -0.0958794951, 0, 0.995392919), new(44, 6, 43.25))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(310.046906, 204.929276, -98.5293198, 0.995393157, 0.00000000186264515, 0.0958794728, 0, 1.00000012, -0.0000000298023224, -0.0958794951, 0, 0.995392919), new(44, 5.5, 46.5))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(312.679291, 209.306335, -100.399132, 0.95375818, 0.156644791, 0.256531715, 0.0000263154507, 0.853422999, -0.521219373, -0.300576419, 0.497123897, 0.813954473), new(60.25, 2, 15))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(288.865051, 212.591721, -123.438225, 0.948331475, 0.000000000931322575, 0.317283809, -0.0000000149011612, 1.00000048, -0.0000000298023224, -0.317284107, 0, 0.948330641), new(71.25, 2.75, 46.5))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(271.416656, 208.042877, -149.974716, 0.963662565, -0.133397385, 0.231429577, -0.0000228088975, 0.866338432, 0.499457479, -0.267122626, -0.481313825, 0.834854841), new(44.25, 2.5, 18.75))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(317.858276, 226.091736, -141.969772, 0.902594805, -0.000000111274026, 0.430492133, -0.0000000626038599, 1.00000179, -0.000000156817535, -0.430491447, -0.000000111401803, 0.902596354), new(14.5, 26.75, 20.25))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(327.610962, 226.091751, -128.030334, 0.713265777, -0.000000346563553, 0.700896978, -0.000000228876587, 1.00000536, -0.000000453092753, -0.700894475, -0.000000337397211, 0.713270009), new(14.5, 26.75, 20.25))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(299.221466, 219.653625, -171.897232, 0.999782085, -0.000000121432961, 0.0208872557, -0.000000115081804, 1.00000358, -0.000000305271271, -0.0208872557, -0.000000302800913, 0.999785483), new(22.25, 41.75, 50.249836))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(302.612976, 218.403732, -206.136353, 0.914973915, 0.0000000357694532, -0.403517187, -0.000000230164034, 1.00000715, -0.000000610544703, 0.403514266, -0.000000651506639, 0.914980114), new(18, 41, 29.249836))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(326.326263, 224.250214, -238.250687, 0.697180986, 0.00000119631932, -0.716895223, -0.000000460329346, 1, 0.00000122108031, 0.716895163, -0.000000521306106, 0.697180986), new(15.5, 41, 52.499836))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(273.453644, 206.549149, -171.125031, 0.999962032, 0, 0.00871858001, -0.0000000149011612, 1.00000012, -0.0000000894069672, -0.00871856511, -0.0000000298023224, 0.999962091), new(43.5, 1.5, 45.25))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(276.836884, 203.299271, -199.41629, 0.999660194, -0.0130174877, 0.0225868188, -0.00000366615131, 0.866337717, 0.499459028, -0.026069466, -0.499289542, 0.866043389), new(48.75, 0.75, 14))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(278.942017, 199.432602, -215.061096, 0.917066813, 0.000000074505806, -0.398734063, -0.0000000279396772, 1.00000048, -0.000000238418579, 0.398733914, -0.000000238418579, 0.917067349), new(39, 2.75, 44.25))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(289.955353, 198.776428, -221.000946, 0.771579385, -0.317793787, -0.551065564, 0.000133678317, 0.866355062, -0.499431521, 0.636133432, 0.385276377, 0.668504), new(52, 0.749944925, 32.75))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(310.594818, 206.462585, -252.894989, 0.675608575, 0.000000666826963, -0.737262726, -0.000000134110451, 1.00000179, -0.00000101327896, 0.737261295, -0.000000804662704, 0.675610304), new(52, 1.24994493, 49))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(69.4087906, 144.00502, -171.119354, 0.99996233, -0.0000000589203459, 0.00871866941, -0.0000000546784662, 1.00000095, -0.000000486772592, -0.0087184906, -0.000000486277315, 0.999963284), new(43.75, 3.75, 49))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(52.5376968, 153.755035, -170.597244, 0.99996233, -0.0000000589203459, 0.00871866941, -0.0000000546784662, 1.00000095, -0.000000486772592, -0.0087184906, -0.000000486277315, 0.999963284), new(10, 23.25, 48.25))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(64.1473999, 141.698074, -201.493713, 0.999660909, -0.0130176228, 0.022584945, -0.00000262307003, 0.86633873, 0.499459445, -0.0260674842, -0.499291092, 0.866045833), new(29.5, 1.24981689, 14.25))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(62.3234749, 137.645157, -210.031967, 0.837708116, -0.00000123679638, 0.546123624, -0.000000217929482, 1.00000381, -0.00000190734863, -0.546121001, -0.0000014603138, 0.837710857), new(38.25, 3.49981689, 32.5))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-166.044968, 37.7829933, 287.729126, 0.0175017715, -0.0000000000000000000000239997362, 0.999847293, 0.0000000000000000000000216954798, 1, -0.0000000000000000000000243831762, -0.999847054, -0.0000000000000000000000221189041, 0.0175016522), new(119.25, 16.2497978, 131.25))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(26.7727909, 131.330139, -229.596436, 0.498491108, -0.0000000149011612, 0.866894901, 0, 1, -0.0000000298023224, -0.86689496, -0.0000000298023224, 0.498491049), new(49.75, 3.74981594, 60.25))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(52.0516853, 155.705139, -223.206177, 0.828062892, -0.000000211616907, 0.560636103, 0.0000000475783892, 1, -0.000000257120234, -0.560636997, -0.000000133975519, 0.828062534), new(38.25, 44.9998169, 3.75))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(104.046776, 139.162552, -171.938599, 0.986322045, -0.164742291, 0.00536258006, 0.164738536, 0.986336589, 0.00113770308, -0.00547673693, -0.000238718087, 0.99998498), new(32.0000076, 16.1000004, 19.6999855))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(181.243668, 158.680099, -172.372742, 0.942704737, -0.333585948, 0.0053159981, 0.333584517, 0.94271946, 0.00117557438, -0.00540364953, 0.00066511496, 0.999985158), new(27.6000061, 18.1999969, 19.6999855))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(131.853058, 145.830246, -172.094543, 0.976343989, -0.216156989, 0.0053403331, 0.216153711, 0.976358593, 0.00119193445, -0.00547172502, -0.00000940531027, 0.999985039), new(25.4000072, 14.2999983, 19.6999855))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(318.447052, 163.461685, 37.7652664, 0.999982238, 0.000530938152, 0.0059381309, 0.0000135496957, 0.995821595, -0.0913198441, -0.00596180419, 0.0913182944, 0.995803893), new(16.2999992, 19.3199978, 41.7999878))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(318.052277, 174.400818, -28.883812, 0.999982417, 0.00173310237, 0.00567422993, 0.0000261646928, 0.955086589, -0.296326905, -0.00593294576, 0.296321839, 0.955069721), new(16.2999992, 26.0899982, 41.7999878))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(226.274368, 183.300385, -172.641464, 0.870467842, -0.492196739, 0.00530316494, 0.492197692, 0.870482564, 0.00121696084, -0.00521529652, 0.00155088026, 0.999985218), new(25.4000072, 11.5999985, 19.6999855))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(152.616531, 158.295456, -172.219894, 0.958893836, -0.283715218, 0.005320244, 0.283712894, 0.958908498, 0.00120666309, -0.0054439758, 0.000352359959, 0.999985099), new(170.769989, 20.6599998, 19.6999855))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(318.252289, 167.785767, 4.91963005, 0.999982595, 0.00117594865, 0.00578253064, -0.0000267500873, 0.980835259, -0.194838986, -0.00590083003, 0.194835439, 0.980818212), new(16.2999992, 21.3699989, 41.7999878))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(244.598236, 195.088745, -172.753021, 0.824243903, -0.566209912, 0.00532178301, 0.566212296, 0.824258626, 0.00119986106, -0.00506589841, 0.00202428014, 0.999985099), new(25.4000072, 11.2999992, 19.6999855))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(203.613464, 171.606827, -172.507065, 0.917157352, -0.398489952, 0.00530689815, 0.398489475, 0.917172134, 0.00119122909, -0.00534203229, 0.00102219847, 0.999985218), new(25.4000072, 11.8999987, 19.6999855))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(317.851074, 185.098953, -62.7725983, 0.999982536, 0.00234849169, 0.00542167015, -0.0000189922284, 0.918884039, -0.394527793, -0.00590843149, 0.394520819, 0.918868005), new(16.2999992, 29.8699989, 41.7999878))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(313.591675, 164.848785, 87.4919815, 0.999982238, 0.0000123396703, 0.00595618133, 0.0000123396703, 0.999991417, -0.00414342992, -0.00595618133, 0.00414342992, 0.999973655), new(26.6000271, 12.3999996, 63.6499863))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(313.780762, 164.967224, 119.242188, 0.999982238, 0.0000123396703, 0.00595618133, 0.0000123396703, 0.999991417, -0.00414342992, -0.00595618133, 0.00414342992, 0.999973655), new(26.6000271, 12.8999996, 1.64998627))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(360.600037, 217.278778, 183.034668, -0.66911006, 0, 0.743163466, 0, 1, 0, -0.743163466, 0, -0.66911006), new(77.5999832, 140.259995, 5.57999849))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(329.736298, 201.704147, 121.851646, 0.990270376, 0, 0.13915664, 0, 1, 0, -0.13915664, 0, 0.990270376), new(8.30997372, 92.3699722, 7.27999878))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(336.563782, 201.704147, 98.0409088, 0.961273968, 0, -0.275594592, 0, 1, 0, 0.275594592, 0, 0.961273968), new(8.30997372, 92.3699722, 49.2699966))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(336.604401, 225.51413, 1.04374969, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(22.5599785, 139.98996, 158.379974))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(291.936859, 201.704147, 117.422958, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(22.5599785, 92.3699722, 85.6899643))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(325.460632, 217.398804, 205.506134, 0.601813793, 0, -0.798636556, 0, 1, 0, 0.798636556, 0, 0.601813793), new(31.1900005, 140.5, 5.57999849))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(356.861755, 217.278778, 201.473495, 0.79861635, 0, 0.601840496, 0, 1, 0, -0.601840496, 0, 0.79861635), new(52.8799973, 140.259995, 5.57999849))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(332.964478, 201.704147, 137.253326, 0.139203906, 0, -0.99026376, 0, 1, 0, 0.99026376, 0, 0.139203906), new(37.4799767, 92.3699722, 5.57999849))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(299.712402, 225.474121, 0.448717952, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(22.5599785, 139.909927, 154.210022))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(268.070129, 201.704147, 200.553894, 0.829036474, 0, 0.559194624, 0, 1, 0, -0.559194624, 0, 0.829036474), new(4.10997677, 92.3699722, 43.399971))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-3.77216744, 81.1528473, -397.064117, 0.987685978, 0, 0.156449571, 0, 1, 0, -0.156449571, 0, 0.987685978), new(26.0000801, 131.969925, 144.389969))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-417.882141, 71.6578674, -111.429916, 0.956294656, 0, 0.292404652, 0, 1, 0, -0.292404652, 0, 0.956294656), new(12.0600824, 112.979919, 155.639954))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(89.2471313, 201.152954, -201.564957, 0, 0, -1, 0, 1, 0, 1, 0, 0), new(12.8600912, 155.529922, 27.2199631))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-322.662384, 71.6578674, -175.193466, 0.970287263, 0, 0.241955817, 0, 1, 0, -0.241955817, 0, 0.970287263), new(52.1000938, 112.979919, 26.0899544))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-125.327179, 150.609619, 448.347321, 0, 1, 0, 1, 0, 0, 0, 0, -1), new(110.670059, 16.2098866, 21.2899628))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(278.299347, 240.282928, -82.8367004, -0.965929747, 0, -0.258804798, 0, 1, 0, 0.258804798, 0, -0.965929747), new(26.6800213, 77.2699661, 29.6099987))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(268.070129, 201.704147, 200.553894, 0.829036474, 0, 0.559194624, 0, 1, 0, -0.559194624, 0, 0.829036474), new(4.10997677, 92.3699722, 43.399971))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(321.441681, 258.039154, -126.414459, -0.406715393, 0, 0.913554907, 0, 1, 0, -0.913554907, 0, -0.406715393), new(129.209961, 9.13999081, 34.7499962))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(136.824524, 71.6578674, -210.560226, 0.788016856, 0, -0.615653694, 0, 1, 0, 0.615653694, 0, 0.788016856), new(23.9600925, 112.979919, 112.829971))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(280.31485, 201.704147, 174.340118, 0.829036474, 0, 0.559194624, 0, 1, 0, -0.559194624, 0, 0.829036474), new(53.7299843, 92.3699722, 13.6299658))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-42.6308556, 83.3778839, -423.266296, 0.987685978, 0, 0.156449571, 0, 1, 0, -0.156449571, 0, 0.987685978), new(55.3900757, 136.419937, 3.29997849))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(253.593842, 201.152954, -198.05365, -0.999848366, 0, 0.017436387, 0, 1, 0, -0.017436387, 0, -0.999848366), new(7.96000004, 155.529922, 9.87997532))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(80.389328, 130.517944, -178.993362, 0.587748766, 0, -0.809043527, 0, 1, 0, 0.809043527, 0, 0.587748766), new(84.3001022, 14.2599249, 27.2500114))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-56.7383423, 82.0228577, -388.675171, 0.987685978, 0, 0.156449571, 0, 1, 0, -0.156449571, 0, 0.987685978), new(16.700079, 133.709915, 144.389969))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-90.3630447, 71.6578674, -322.139832, 0.999847949, 0, -0.017436387, 0, 1, 0, 0.017436387, 0, 0.999847949), new(76.3400879, 112.979919, 10.0999537))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-269.883667, 71.6578674, -211.016266, 0.933587551, 0, 0.358349502, 0, 1, 0, -0.358349502, 0, 0.933587551), new(28.4701061, 112.979919, 26.0899544))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(66.7276688, 201.152954, -145.322754, -1, 0, 0, 0, 1, 0, 0, 0, -1), new(65.3700638, 155.529922, 7.01998234))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(147.480667, 71.6578674, -481.844696, 0.981621504, 0, -0.190838262, 0, 1, 0, 0.190838262, 0, 0.981621504), new(84.450058, 112.979919, 15.2799673))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(171.137604, 201.152954, -190.154861, -1, 0, 0, 0, 1, 0, 0, 0, -1), new(161.15007, 155.529922, 20.5299816))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(289.106201, 199.204453, -237.240112, -0.681973696, 0, 0.731376648, 0, 1, 0, -0.731376648, 0, -0.681973696), new(46.5600014, 1.63998556, 20.0499992))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(46.1648331, 170.712921, -244.133514, 0.933587551, 0, -0.358349502, 0, 1, 0, 0.358349502, 0, 0.933587551), new(48.9500923, 94.6499176, 9.41996288))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(32.8624992, 71.6578674, -504.092804, 0.981621504, 0, -0.190838262, 0, 1, 0, 0.190838262, 0, 0.981621504), new(84.450058, 112.979919, 15.2799673))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(171.137604, 201.152954, -154.059052, -1, 0, 0, 0, 1, 0, 0, 0, -1), new(161.15007, 155.529922, 20.5299816))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(56.9643517, 128.217972, -214.544128, 0.587748766, 0, -0.809043527, 0, 1, 0, 0.809043527, 0, 0.587748766), new(21.7401257, 9.65992451, 31.1400127))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(78.888588, 201.152954, -216.94101, 0.544665456, 0, -0.838653445, 0, 1, 0, 0.838653445, 0, 0.544665456), new(23.9600925, 155.529922, 9.41996288))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(201.904037, 81.967865, -316.362091, 0.788016856, 0, -0.615653694, 0, 1, 0, 0.615653694, 0, 0.788016856), new(51.6700859, 133.59993, 141.20993))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-151.983612, 71.6578674, -307.082306, 0.829036474, 0, 0.559194624, 0, 1, 0, -0.559194624, 0, 0.829036474), new(100.530083, 112.979919, 10.0999537))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-211.735306, 71.6578674, -241.287537, 0.469467044, 0, 0.882950008, 0, 1, 0, -0.882950008, 0, 0.469467044), new(89.0900803, 112.979919, 10.0999537))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(10.404254, 71.6578674, -235.046997, 0.984812498, 0, 0.173621148, 0, 1, 0, -0.173621148, 0, 0.984812498), new(39.1400681, 112.979919, 31.4799538))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(299.215668, 201.704147, 210.820496, 0.829036474, 0, 0.559194624, 0, 1, 0, -0.559194624, 0, 0.829036474), new(53.7299843, 92.3699722, 13.6299658))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(302.519348, 248.124329, -170.130829, 0.0175017118, 0, 0.999846935, 0, 1, 0, -0.999846935, 0, 0.0175017118), new(53.5899887, 22.2499924, 36.8600044))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-72.5408325, 92.6578674, -226.426178, 0.999847949, 0, 0.017436387, 0, 1, 0, -0.017436387, 0, 0.999847949), new(130.620087, 154.979904, 36.8499527))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(37.5846519, 71.6578674, -237.363373, 0.999847949, 0, -0.017436387, 0, 1, 0, 0.017436387, 0, 0.999847949), new(21.0300751, 112.979919, 29.3599606))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-239.524338, 71.6578674, -200.243027, 0.933587551, 0, 0.358349502, 0, 1, 0, -0.358349502, 0, 0.933587551), new(28.4701061, 112.979919, 26.0899544))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-286.944824, 71.6578674, -186.516891, 0.90629667, 0, 0.422642082, 0, 1, 0, -0.422642082, 0, 0.90629667), new(28.4701061, 112.979919, 26.0899544))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-390.022064, 71.6578674, -175.793915, 0.956294656, 0, 0.292404652, 0, 1, 0, -0.292404652, 0, 0.956294656), new(86.9200897, 112.979919, 26.0899544))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(296.471771, 209.142975, -107.708954, -0.951068401, 0, -0.308980465, 0, 1, 0, 0.308980465, 0, -0.951068401), new(68.9400024, 8.52998447, 9.06999397))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(27.5196838, 170.712921, -245.540726, 0.999847949, 0, 0.017436387, 0, 1, 0, -0.017436387, 0, 0.999847949), new(48.9500923, 94.6499176, 9.41996288))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(285.192871, 209.142975, -142.421982, -0.951068401, 0, -0.308980465, 0, 1, 0, 0.308980465, 0, -0.951068401), new(68.9400024, 8.52998447, 9.06999397))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(304.893066, 229.299469, -222.380829, -0.766061664, 0, 0.642767608, 0, 1, 0, -0.642767608, 0, -0.766061664), new(6.65000296, 61.8299904, 10.8399925))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(39.5098419, 201.152954, -171.609802, 0, 0, -1, 0, 1, 0, 1, 0, 0), new(66.7700806, 155.529922, 28.3999786))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(102.651863, 81.8628693, -404.385468, 0.981621504, 0, -0.190838262, 0, 1, 0, 0.190838262, 0, 0.981621504), new(26.0000801, 133.389938, 184.459961))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(334.250702, 259.569092, -104.673012, -0.173624277, 0, 0.984811902, 0, 1, 0, -0.984811902, 0, -0.173624277), new(80.2499771, 208.099976, 9.06999397))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(257.434692, 240.282928, -114.319412, -0.951068401, 0, -0.308980465, 0, 1, 0, 0.308980465, 0, -0.951068401), new(7.70001984, 77.2699661, 45.7699966))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(331.207611, 201.152954, -268.791962, -0.74314785, 0, -0.669127226, 0, 1, 0, 0.669127226, 0, -0.74314785), new(7.96000004, 155.529922, 50.1699715))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(259.305756, 201.152954, -219.461853, -0.906296611, 0, 0.422642082, 0, 1, 0, -0.422642082, 0, -0.906296611), new(7.96000004, 155.529922, 52.3299637))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(285.489746, 202.64946, -249.168152, -0.681973696, 0, 0.731376648, 0, 1, 0, -0.731376648, 0, -0.681973696), new(68.9400024, 8.52998447, 9.06999397))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(271.153839, 202.64946, -189.05751, -1, 0, 0, 0, 1, 0, 0, 0, -1), new(68.9400024, 8.52998447, 9.06999397))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(26.5978699, 178.708435, -202.503372, 0.469467044, 0, 0.882950008, 0, 1, 0, -0.882950008, 0, 0.469467044), new(87.330101, 11.7599154, 70.6699524))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(146.12854, 82.1978836, -359.938873, 0.788016856, 0, -0.615653694, 0, 1, 0, 0.615653694, 0, 0.788016856), new(26.0000801, 134.059937, 141.20993))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(296.637207, 201.152954, -266.805756, -0.66911006, 0, 0.743163466, 0, 1, 0, -0.743163466, 0, -0.66911006), new(7.96000004, 155.529922, 50.1699715))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(99.3139725, 71.6578674, -192.906723, 0.788016856, 0, -0.615653694, 0, 1, 0, 0.615653694, 0, 0.788016856), new(61.3401108, 112.979919, 38.8199997))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(275.48941, 201.152954, -246.046173, -0.731384635, 0, 0.681965172, 0, 1, 0, -0.681965172, 0, -0.731384635), new(7.96000004, 155.529922, 10.8099756))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(191.84343, 71.6578674, -519.669495, 0.981621504, 0, -0.190838262, 0, 1, 0, 0.190838262, 0, 0.981621504), new(11.7900572, 112.979919, 106.469978))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(8.56675243, 176.11792, -233.824677, 0.469467044, 0, 0.882950008, 0, 1, 0, -0.882950008, 0, 0.469467044), new(48.9500923, 105.459915, 9.41996288))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(4.76045275, 71.6578674, -554.318726, 0.981621504, 0, -0.190838262, 0, 1, 0, 0.190838262, 0, 0.981621504), new(11.7900572, 112.979919, 103.099976))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(336.604401, 238.509155, -76.2662277, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(22.5599785, 165.97998, 3.75999427))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(103.385704, 71.6578674, -584.13147, 0.981621504, 0, -0.190838262, 0, 1, 0, 0.190838262, 0, 0.981621504), new(192.360016, 112.979919, 6.27996731))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(45.7099876, 82.1828537, -415.45401, 0.981621504, 0, -0.190838262, 0, 1, 0, 0.190838262, 0, 0.981621504), new(26.0000801, 134.029907, 184.459961))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(192.358246, 82.1778717, -374.678314, 0.788016856, 0, -0.615653694, 0, 1, 0, 0.615653694, 0, 0.788016856), new(39.2300949, 134.019928, 6.05993652))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-353.975555, 71.6578674, -63.2335167, 0.956294656, 0, 0.292404652, 0, 1, 0, -0.292404652, 0, 0.956294656), new(86.1100769, 112.979919, 26.0899544))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(251.776321, 240.282928, -140.439316, -0.951068401, 0, -0.308980465, 0, 1, 0, 0.308980465, 0, -0.951068401), new(13.0800266, 77.2699661, 10.5299988))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(22.8892059, 108.482849, 344.445435, 0.515037358, 0, -0.857167721, 0, 1, 0, 0.857167721, 0, 0.515037358), new(7.17007732, 196.649918, 88.9599533))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-189.411392, 115.27285, 512.67157, -0.74314785, 0, -0.669127226, 0, 1, 0, 0.669127226, 0, -0.74314785), new(7.17007732, 210.229919, 107.459976))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(3.59355736, 115.27285, 400.595734, 0.79861635, 0, 0.601840496, 0, 1, 0, -0.601840496, 0, 0.79861635), new(20.2200737, 210.229919, 83.4799728))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-48.4561577, 115.27285, 524.388855, 0.994518042, 0, -0.104565002, 0, 1, 0, 0.104565002, 0, 0.994518042), new(29.3600597, 210.229919, 38.3299599))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-217.117432, 108.482849, 331.702698, 0.788016856, 0, 0.615653694, 0, 1, 0, -0.615653694, 0, 0.788016856), new(7.17007732, 196.649918, 65.809967))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-132.738174, 115.27285, 485.842224, -0.656062722, 0, -0.754706323, 0, 1, 0, 0.754706323, 0, -0.656062722), new(15.610075, 210.229919, 80.2799683))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-114.245438, 115.27285, 502.964417, -0.656062722, 0, -0.754706323, 0, 1, 0, 0.754706323, 0, -0.656062722), new(23.2500763, 210.229919, 18.7399883))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-181.212082, 108.482849, 455.194031, -0.978144407, 0, -0.207926437, 0, 1, 0, 0.207926437, 0, -0.978144407), new(7.17007732, 196.649918, 28.6599598))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-171.409775, 108.482849, 480.494568, -0.866007447, 0, -0.500031412, 0, 1, 0, 0.500031412, 0, -0.866007447), new(7.17007732, 196.649918, 28.6599598))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-153.358505, 108.482849, 499.273956, -0.529884458, 0, -0.848069847, 0, 1, 0, 0.848069847, 0, -0.529884458), new(7.17007732, 196.649918, 28.6599598))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(2.28053975, 191.96788, 412.527252, 0.965929627, 0, 0.258804798, 0, 1, 0, -0.258804798, 0, 0.965929627), new(46.6800728, 51.1199303, 30.3899784))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-11.8301239, 69.1528625, -32.3248634, -0.190845728, 0, 0.981620014, 0, 1, 0, -0.981620014, 0, -0.190845728), new(33.9601364, 117.989929, 43.3399582))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-5.22509098, 115.27285, 490.063293, 0.484826028, 0, -0.874610603, 0, 1, 0, 0.874610603, 0, 0.484826028), new(20.2200737, 210.229919, 83.4799728))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-127.205185, 108.482849, 510.990234, -0.275688529, 0, -0.961247265, 0, 1, 0, 0.961247265, 0, -0.275688529), new(8.14007759, 196.649918, 33.0399551))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-159.152649, 108.482849, 380.508484, -0.719358206, 0, 0.694639385, 0, 1, 0, -0.694639385, 0, -0.719358206), new(7.17007732, 196.649918, 28.6599598))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-308.969879, 71.6578674, -94.8810577, 0.961249948, 0, 0.275678426, 0, 1, 0, -0.275678426, 0, 0.961249948), new(27.9000931, 112.979919, 25.8499527))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-196.633072, 71.6578674, 20.2068882, -0.29242146, 0, 0.95628953, 0, 1, 0, -0.95628953, 0, -0.29242146), new(3.35009265, 112.979919, 193.439865))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-64.1702118, 108.482849, 196.430222, 0.808997452, 0, 0.587812185, 0, 1, 0, -0.587812185, 0, 0.808997452), new(7.17007732, 196.649918, 19.1599712))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(21.93013, 115.27285, 434.743622, 0.965929627, 0, 0.258804798, 0, 1, 0, -0.258804798, 0, 0.965929627), new(20.2200737, 210.229919, 83.4799728))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-33.0243149, 115.27285, 372.81546, 0.258864343, 0, 0.965913713, 0, 1, 0, -0.965913713, 0, 0.258864343), new(20.2200737, 210.229919, 83.4799728))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-153.190704, 115.27285, 421.939972, -0.913549781, 0, 0.406727046, 0, 1, 0, -0.406727046, 0, -0.913549781), new(20.2200737, 210.229919, 83.4799728))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-186.537735, 71.6578674, 55.9972839, -0.29242146, 0, 0.95628953, 0, 1, 0, -0.95628953, 0, -0.29242146), new(6.85009241, 112.979919, 191.819916))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-102.091415, 108.482849, 351.480042, -0.374604106, 0, 0.92718488, 0, 1, 0, -0.92718488, 0, -0.374604106), new(7.17007732, 196.649918, 105.239922))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-150.674164, 108.482849, 227.823898, 0.0175017118, 0, 0.999846935, 0, 1, 0, -0.999846935, 0, 0.0175017118), new(1.08007801, 196.649918, 27.1100006))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(2.66658545, 112.507874, 74.4540482, 0.0697871447, 0, 0.997561872, 0, 1, 0, -0.997561872, 0, 0.0697871447), new(121.150146, 204.699951, 38.2499657))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-95.8713608, 108.482849, 212.595322, -0.642763734, 0, 0.766064942, 0, 1, 0, -0.766064942, 0, -0.642763734), new(2.72007704, 196.649918, 74.0400085))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(3.05939007, 111.247864, 1.23464596, -0.342042685, 0, 0.939684391, 0, 1, 0, -0.939684391, 0, -0.342042685), new(106.420143, 202.179932, 38.2499657))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-296.766571, 71.6578674, -104.887527, 0.951068401, 0, 0.308980465, 0, 1, 0, -0.308980465, 0, 0.951068401), new(21.460104, 112.979919, 5.02994967))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-136.902573, 115.27285, 400.373932, -0.587748766, 0, 0.809043527, 0, 1, 0, -0.809043527, 0, -0.587748766), new(20.2200737, 210.229919, 83.4799728))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-126.523605, 71.6578674, -35.9618187, -0.515037298, 0, 0.857167721, 0, 1, 0, -0.857167721, 0, -0.515037298), new(69.3901215, 112.979919, 10.0999537))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-107.43457, 108.482849, 200.957001, -0.642763734, 0, 0.766064942, 0, 1, 0, -0.766064942, 0, -0.642763734), new(2.72007704, 196.649918, 81.4400024))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-156.125748, 115.27285, 447.67746, -0.961273909, 0, -0.275594592, 0, 1, 0, 0.275594592, 0, -0.961273909), new(20.2200737, 210.229919, 83.4799728))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-84.8648453, 108.482849, 167.946167, 0.808997452, 0, 0.587812185, 0, 1, 0, -0.587812185, 0, 0.808997452), new(7.17007732, 196.649918, 22.8599682))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-28.1472721, 112.442856, -60.752491, -0.573599219, 0, 0.81913656, 0, 1, 0, -0.81913656, 0, -0.573599219), new(63.9601364, 204.569916, 38.2499657))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-75.1926804, 108.482849, 332.591461, -0.74314785, 0, 0.669127226, 0, 1, 0, -0.669127226, 0, -0.74314785), new(8.96007824, 196.649918, 53.559948))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-275.843719, 71.6578674, 63.9708595, -0.29242146, 0, 0.95628953, 0, 1, 0, -0.95628953, 0, -0.29242146), new(43.8200836, 112.979919, 32.2699165))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-90.2726288, 108.482849, 117.84272, 0.999391913, 0, -0.0348687991, 0, 1, 0, 0.0348687991, 0, 0.999391913), new(7.17007732, 196.649918, 88.6899643))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-188.159439, 108.482849, 236.08194, -0.342042685, 0, 0.939684391, 0, 1, 0, -0.939684391, 0, -0.342042685), new(7.17007732, 196.649918, 65.809967))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(8.69923592, 108.482849, 164.62558, 0.0175017118, 0, 0.999846935, 0, 1, 0, -0.999846935, 0, 0.0175017118), new(105.130081, 196.649918, 21.1499653))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-217.38678, 71.6578674, -120.78791, 0.981621504, 0, 0.190838262, 0, 1, 0, -0.190838262, 0, 0.981621504), new(28.2900963, 112.979919, 25.8499527))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-177.051682, 71.6578674, -95.5953293, -0.731384635, 0, 0.681965172, 0, 1, 0, -0.681965172, 0, -0.731384635), new(92.0400925, 112.979919, 10.0999537))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-91.2905579, 98.7878723, -180.786469, -0.642763734, 0, 0.766064942, 0, 1, 0, -0.766064942, 0, -0.642763734), new(100.200134, 167.239929, 34.0199585))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-60.8750038, 104.102882, -118.505707, -0.970287442, 0, 0.241955817, 0, 1, 0, -0.241955817, 0, -0.970287442), new(14.3101358, 177.869934, 52.2899513))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-81.9202881, 115.27285, 376.216888, -0.190845728, 0, 0.981620014, 0, 1, 0, -0.981620014, 0, -0.190845728), new(20.2200737, 210.229919, 83.4799728))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(14.3495579, 115.27285, 466.507202, 0.866007268, 0, -0.500031412, 0, 1, 0, 0.500031412, 0, 0.866007268), new(20.2200737, 210.229919, 83.4799728))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(16.8177929, 177.457901, 466.780548, 0.965929627, 0, 0.258804798, 0, 1, 0, -0.258804798, 0, 0.965929627), new(46.6800728, 22.099926, 30.3899784))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-236.081604, 71.6578674, -107.771599, 0.951068401, 0, 0.308980465, 0, 1, 0, -0.308980465, 0, 0.951068401), new(21.460104, 112.979919, 5.02994967))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-51.8448524, 113.727875, -79.1300812, -0.906296611, 0, 0.422642082, 0, 1, 0, -0.422642082, 0, -0.906296611), new(63.9601364, 207.139954, 38.2499657))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(11.4648485, 108.482849, 293.321198, -0.642763734, 0, -0.766064942, 0, 1, 0, 0.766064942, 0, -0.642763734), new(7.17007732, 196.649918, 119.499962))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-37.7696838, 115.27285, 507.855652, 0.241953552, 0, -0.970287859, 0, 1, 0, 0.970287859, 0, 0.241953552), new(26.7200642, 210.229919, 20.9799595))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-182.646271, 108.482849, 427.893585, -0.992540598, 0, 0.121917672, 0, 1, 0, -0.121917672, 0, -0.992540598), new(7.17007732, 196.649918, 28.6599598))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-212.57103, 108.482849, 383.047607, -0.890994906, 0, 0.454013437, 0, 1, 0, -0.454013437, 0, -0.890994906), new(7.17007732, 196.649918, 65.809967))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-219.156174, 115.27285, 442.736725, -0.997561932, 0, -0.0697919354, 0, 1, 0, 0.0697919354, 0, -0.997561932), new(7.17007732, 210.229919, 84.3099747))
    spawn2 = fn12
    new = Vector3.new
    spawn2(CFrame.new(-47.2210999, 115.27285, 512.638611, 0.5592103, 0, -0.829025805, 0, 1, 0, 0.829025805, 0, 0.5592103), new(29.3600597, 210.229919, 13.2199593))
    spawn2 = fn12
    CFrame166 = CFrame
    do
        new = Vector3.new
        spawn2(CFrame.new(-175.036667, 108.482849, 402.054779, -0.890994906, 0, 0.454013437, 0, 1, 0, -0.454013437, 0, -0.890994906), new(7.17007732, 196.649918, 28.6599598))
        spawn2 = fn12
        CFrame167 = CFrame
        do
            new = Vector3.new
            spawn2(CFrame.new(-34.2681313, 108.482849, 220.731842, 0.601813793, 0, 0.798636556, 0, 1, 0, -0.798636556, 0, 0.601813793), new(7.17007732, 196.649918, 65.809967))
            spawn2 = fn12
            CFrame168 = CFrame
            do
                new = Vector3.new
                spawn2(CFrame.new(-267.718323, 71.6578674, -106.124031, 0.933587551, 0, 0.358349502, 0, 1, 0, -0.358349502, 0, 0.933587551), new(47.0600929, 112.979919, 25.8499527))
                spawn2 = fn12
                CFrame169 = CFrame
                do
                    new = Vector3.new
                    spawn2(CFrame.new(-79.1659088, 108.482849, 247.456345, 0.224959731, 0, 0.974368095, 0, 1, 0, -0.974368095, 0, 0.224959731), new(2.72007704, 196.649918, 93.0200272))
                    spawn2 = fn12
                    CFrame170 = CFrame
                    do
                        new = Vector3.new
                        spawn2(CFrame.new(-24.5546627, 153.542862, 346.573395, 0.309060872, 0, 0.951042235, 0, 1, 0, -0.951042235, 0, 0.309060872), new(48.760067, 106.5299, 82.7499619))
                        spawn2 = fn12
                        new = Vector3.new
                        spawn2(CFrame.new(-130.157043, 115.27285, 543.391418, -0.241953492, 0, -0.970287859, 0, 1, 0, 0.970287859, 0, -0.241953492), new(7.17007732, 210.229919, 107.459976))
                        spawn2 = fn12
                        new = Vector3.new
                        spawn2(CFrame.new(-62.0073128, 115.27285, 535.006409, 0.587748766, 0, -0.809043527, 0, 1, 0, 0.809043527, 0, 0.587748766), new(13.5600739, 210.229919, 78.2199707))
                        spawn2 = fn12
                        CFrame173 = CFrame
                        do
                            new = Vector3.new
                            spawn2(CFrame.new(1.19643378, 108.482849, 210.773438, 0.601813793, 0, 0.798636556, 0, 1, 0, -0.798636556, 0, 0.601813793), new(55.8600845, 196.649918, 21.1499653))
                            spawn2 = fn12
                            new = Vector3.new
                            spawn2(CFrame.new(-226.246323, 108.482849, 280.09845, 0.981621504, 0, -0.190838262, 0, 1, 0, 0.190838262, 0, 0.981621504), new(7.17007732, 196.649918, 65.809967))
                            spawn2 = fn12
                            new = Vector3.new
                            spawn2(CFrame.new(-93.2036362, 108.482849, 50.1853981, 0.984812498, 0, 0.173621148, 0, 1, 0, -0.173621148, 0, 0.984812498), new(7.17007732, 196.649918, 49.9200096))
                            spawn2 = fn12
                            CFrame176 = CFrame
                            do
                                new = Vector3.new
                                spawn2(CFrame.new(-99.4887619, 26.6458683, 204.488251, -0.642771602, -0.172286958, 0.74643296, 0.0000349506736, 0.974375129, 0.224929258, -0.766058028, 0.144604191, -0.626294613), new(17.6900787, 52.3899765, 81.5899811))
                                spawn2 = fn12
                                new = Vector3.new
                                spawn2(CFrame.new(-90.5216141, 92.6578674, -212.284851, 0.999847949, 0, 0.017436387, 0, 1, 0, -0.017436387, 0, 0.999847949), new(20.6700878, 154.979904, 64.4999695))
                                spawn2 = fn12
                                new = Vector3.new
                                spawn2(CFrame.new(-69.007225, 150.609619, 414.444153, 0, 1, 0, 1, 0, 0, 0, 0, -1), new(110.670059, 54.7698822, 46.6099701))
                                spawn2 = fn12
                                CFrame179 = CFrame
                                do
                                    new = Vector3.new
                                    spawn2(CFrame.new(-17.0605316, 150.609619, 455.940033, 0, 1, 0, 1, 0, 0, 0, 0, -1), new(110.670059, 16.2098866, 21.2899628))
                                    spawn2 = fn12
                                    new = Vector3.new
                                    spawn2(CFrame.new(44.4533386, 150.080139, -209.457306, 0.828062892, -0.000000211616907, 0.560636103, 0.0000000475783892, 1, -0.000000257120234, -0.560636997, -0.000000133975519, 0.828062534), new(10.25, 33.7498169, 18))
                                    spawn2 = fn12
                                    new = Vector3.new
                                    spawn2(CFrame.new(90.6520691, 55.3309364, -253.047241, 0.615655065, -0.000000831751947, 0.788017154, -0.000000105084027, 1, -0.000000973401143, -0.78802079, -0.000000516469811, 0.615655005), new(112, 5.24979782, 111))
                                    spawn2 = fn12
                                    CFrame182 = CFrame
                                    do
                                        new = Vector3.new
                                        spawn2(CFrame.new(72.5854263, 90.4559326, -213.070435, 0.615655065, -0.000000831751947, 0.788017154, -0.000000105084027, 1, -0.000000973401143, -0.78802079, -0.000000516469811, 0.615655005), new(26.75, 75.4998016, 90.25))
                                        spawn2 = fn12
                                        new = Vector3.new
                                        spawn2(CFrame.new(129.757416, 61.8308907, -222.495361, 0.615655065, -0.000000831751947, 0.788017154, -0.000000105084027, 1, -0.000000973401143, -0.78802079, -0.000000516469811, 0.615655005), new(112, 18.2497978, 11.75))
                                        spawn2 = fn12
                                        new = Vector3.new
                                        spawn2(CFrame.new(151.133179, 61.8308983, -266.707794, 0.615655065, -0.000000831751947, 0.788017154, -0.000000105084027, 1, -0.000000973401143, -0.78802079, -0.000000516469811, 0.615655005), new(16, 18.2497978, 32.5))
                                        spawn2 = fn12
                                        CFrame185 = CFrame
                                        do
                                            new = Vector3.new
                                            spawn2(CFrame.new(102.768631, 61.8309555, -304.493622, 0.615655065, -0.000000831751947, 0.788017154, -0.000000105084027, 1, -0.000000973401143, -0.78802079, -0.000000516469811, 0.615655005), new(16, 18.2497978, 26.75))
                                            spawn2 = fn12
                                            new = Vector3.new
                                            spawn2(CFrame.new(85.0030518, 61.5809021, -314.366455, 0.190837413, -0.00000195113194, 0.981623232, -0.000000210167372, 1, -0.0000019468032, -0.981629729, -0.000000165219262, 0.190840572), new(16.25, 19.2497978, 25.5))
                                            spawn2 = fn12
                                            new = Vector3.new
                                            spawn2(CFrame.new(27.7007961, 61.5810165, -325.506775, 0.190837413, -0.00000195113194, 0.981623232, -0.000000210167372, 1, -0.0000019468032, -0.981629729, -0.000000165219262, 0.190840572), new(16.25, 19.2497978, 26.75))
                                            spawn2 = fn12
                                            CFrame188 = CFrame
                                            do
                                                new = Vector3.new
                                                spawn2(CFrame.new(7.84294891, 61.5429382, -322.138489, -0.156453863, -0.00000391142521, 0.987685323, -0.000000420325563, 1, 0.0000038936123, -0.987685263, 0.000000194021311, -0.156453878), new(7.75, 19.2497978, 25.5))
                                                spawn2 = fn12
                                                new = Vector3.new
                                                spawn2(CFrame.new(-43.5881577, 67.4179993, -313.486664, -0.156449482, -0.00000000000369780161, 0.987686753, 0.000000000000542860245, 1, -0.00000000000365791512, -0.9876858, 0.0000000000000361038239, -0.15644975), new(8.25, 19.9997978, 14.25))
                                                spawn2 = fn12
                                                new = Vector3.new
                                                spawn2(CFrame.new(-87.1848373, 67.0428085, -313.408112, 0.0174364448, -0.00000000000729579678, 0.999851346, 0.00000000000108572136, 1, -0.00000000000731584064, -0.999849319, -0.00000000000121311815, 0.017436415), new(7.25, 20.7497978, 75.5))
                                                spawn2 = fn12
                                                CFrame191 = CFrame
                                                do
                                                    new = Vector3.new
                                                    spawn2(CFrame.new(-156.584213, 67.3979263, -293.36441, -0.559194386, -0.0000000000066722218, 0.829037786, 0.00000000000108572027, 1, -0.00000000000731583284, -0.829036236, 0.00000000000319087291, -0.559195638), new(7.5, 19.9997978, 71))
                                                    spawn2 = fn12
                                                    new = Vector3.new
                                                    spawn2(CFrame.new(-203.402084, 67.4178085, -238.748154, -0.882949471, -0.000000000008786364, 0.469468504, 0.00000000000217144011, 1, -0.0000000000146316795, -0.469466925, 0.0000000000118996219, -0.882953048), new(7, 19.9997978, 79.75))
                                                    spawn2 = fn12
                                                    new = Vector3.new
                                                    spawn2(CFrame.new(-221.330124, 67.1680069, -201.287247, -0.358348906, -0.0000000000288762209, 0.93359375, 0.00000000000434287719, 1, -0.0000000000292634077, -0.933586717, 0.00000000000643207146, -0.358352125), new(15, 19.9997978, 6.25))
                                                    spawn2 = fn12
                                                    CFrame194 = CFrame
                                                    do
                                                        new = Vector3.new
                                                        spawn2(CFrame.new(-198.021118, 65.8308716, -124.031624, -0.309060812, -0.0000000000000000150344096, 0.951042354, -0.00000000000000000175127433, 1, -0.0000000000000000163774614, -0.951042652, 0.00000000000000000672716669, -0.309060782), new(28, 27.7497978, 11.5))
                                                        spawn2 = fn12
                                                        new = Vector3.new
                                                        spawn2(CFrame.new(-166.487717, 67.7930069, -97.6062241, -0.731385112, -0.0000000000000000197760074, 0.681965232, -0.00000000000000000350254989, 1, -0.0000000000000000327549229, -0.681965768, 0.0000000000000000263450672, -0.731384754), new(82.75, 27.7497978, 7.25))
                                                        spawn2 = fn12
                                                        new = Vector3.new
                                                        spawn2(CFrame.new(-119.565308, 67.7930069, -39.0402756, -0.515038013, -0.0000000000000000525450404, 0.85716784, -0.00000000000000000700510723, 1, -0.0000000000000000655098524, -0.857169032, 0.0000000000000000397445693, -0.515037596), new(72, 27.7497978, 9.5))
                                                        spawn2 = fn12
                                                        CFrame197 = CFrame
                                                        do
                                                            new = Vector3.new
                                                            spawn2(CFrame.new(-87.4858704, 62.2829895, 49.0097618, -0.173621446, -0.000000000000000126597385, 0.984812856, -0.0000000000000000140102294, 1, -0.000000000000000131019718, -0.984815359, 0.0000000000000000365452431, -0.173621505), new(51.25, 27.7497978, 10))
                                                            spawn2 = fn12
                                                            new = Vector3.new
                                                            spawn2(CFrame.new(-83.2823715, 63.5329895, 120.683098, 0.0348694921, -0.000000000000000262857167, 0.999392748, -0.0000000000000000280205249, 1, -0.000000000000000262039489, -0.999397576, 0.0000000000000000188664826, 0.0348683298), new(96, 25.2497978, 7))
                                                            spawn2 = fn12
                                                            new = Vector3.new
                                                            spawn2(CFrame.new(-78.467865, 63.5329933, 166.610886, -0.587812185, -0.0000000000000000000000165436123, 0.808997571, 0.0000000000000000000000066174449, 1, -0.000000000000000000000014889251, -0.808997512, -0.0000000000000000000000066174449, -0.587812304), new(18.5, 25.2497978, 4.75))
                                                            spawn2 = fn12
                                                            CFrame200 = CFrame
                                                            do
                                                                new = Vector3.new
                                                                spawn2(CFrame.new(-60.2567482, 64.4079895, 191.676926, -0.587812245, -0.0000000000000000000000324787982, 0.80899781, 0.0000000000000000000000216954798, 1, -0.0000000000000000000000243831762, -0.808997631, -0.00000000000000000000000321885739, -0.587812483), new(16.25, 24.4997978, 4.75))
                                                                spawn2 = fn12
                                                                new = Vector3.new
                                                                spawn2(CFrame.new(-37.4936447, 64.6579895, 210.83847, -0.798636854, -0.0000000000000000000000640018756, 0.60181427, 0.0000000000000000000000433909659, 1, -0.0000000000000000000000487663651, -0.601814091, 0.0000000000000000000000128333249, -0.79863739), new(43.75, 23.9997978, 4.75))
                                                                spawn2 = fn12
                                                                new = Vector3.new
                                                                spawn2(CFrame.new(-313.654449, 46.2073135, -131.273331, -0.275637358, 0, 0.96126169, 0, 1, 0, -0.96126169, 0, -0.275637358), new(110, 14.7497978, 208))
                                                                spawn2 = fn12
                                                                CFrame203 = CFrame
                                                                do
                                                                    new = Vector3.new
                                                                    spawn2(CFrame.new(-165.12883, 54.2137146, 31.6172218, -0.294678897, 0, 0.955596387, 0, 1, 0, -0.955596209, 0, -0.294678926), new(40.5, 2.24979782, 249.25))
                                                                    spawn2 = fn12
                                                                    new = Vector3.new
                                                                    spawn2(CFrame.new(-73.2428131, 56.4560051, -257.687622, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(290.25, 2.99979782, 126))
                                                                    spawn2 = fn12
                                                                    new = Vector3.new
                                                                    spawn2(CFrame.new(-112.780289, 56.830883, -107.574318, 0.857371926, 0, 0.514697373, 0, 1, 0, -0.514697313, 0, 0.857372046), new(93, 2.24979782, 263.25))
                                                                    spawn2 = fn12
                                                                    CFrame206 = CFrame
                                                                    do
                                                                        new = Vector3.new
                                                                        spawn2(CFrame.new(-187.362808, 55.7058716, -134.105606, 0.95104146, 0, 0.309061378, 0, 1, 0, -0.309060663, 0, 0.951044798), new(31.5, 4.49979782, 93.75))
                                                                        spawn2 = fn12
                                                                        new = Vector3.new
                                                                        spawn2(CFrame.new(-34.3526993, 56.1579857, 102.725609, 0.984812677, 0.000000000000000129029866, 0.173621446, -0.000000000000000131019705, 1.00000048, -0.0000000000000000000000397046694, -0.173621535, -0.0000000000000000227477779, 0.984813035), new(110, 3.49979782, 231))
                                                                        spawn2 = fn12
                                                                        new = Vector3.new
                                                                        spawn2(CFrame.new(-69.5363007, 58.0819054, 176.25325, 0.788472474, 0.182033852, 0.587515831, -0.224951565, 0.974369884, -0.000000337541366, -0.57245779, -0.132162333, 0.809212744), new(16, 3.24977589, 25.75))
                                                                        spawn2 = fn12
                                                                        CFrame209 = CFrame
                                                                        do
                                                                            new = Vector3.new
                                                                            spawn2(CFrame.new(-97.6610107, 59.0887032, 8.19114017, 0.955596149, 0.0000000610016286, 0.294679552, 0.0000000805594027, 0.999999285, -0.0000000149011612, -0.294679046, -0.0000000409781933, 0.95559752), new(16.5, 1.99977589, 36))
                                                                            spawn2 = fn12
                                                                            new = Vector3.new
                                                                            spawn2(CFrame.new(-97.7346802, 58.7137032, 7.95224094, 0.955596149, 0.0000000610016286, 0.294679552, 0.0000000805594027, 0.999999285, -0.0000000149011612, -0.294679046, -0.0000000409781933, 0.95559752), new(20, 1.24977589, 40.5))
                                                                            spawn2 = fn12
                                                                            new = Vector3.new
                                                                            spawn2(CFrame.new(-97.6341782, 58.2137032, 7.00558901, 0.955596149, 0.0000000610016286, 0.294679552, 0.0000000805594027, 0.999999285, -0.0000000149011612, -0.294679046, -0.0000000409781933, 0.95559752), new(24.25, 1.24977589, 43.75))
                                                                            spawn2 = fn12
                                                                            CFrame212 = CFrame
                                                                            do
                                                                                new = Vector3.new
                                                                                spawn2(CFrame.new(-113.563217, 56.2356071, 13.2257681, 0.89212507, -0.342453569, 0.294681668, 0.358367622, 0.933576107, -0.000000111758709, -0.275106102, 0.10560298, 0.955603957), new(11, 1.24977589, 43.75))
                                                                                spawn2 = fn12
                                                                                new = Vector3.new
                                                                                spawn2(CFrame.new(-223.621185, 51.8409386, -176.644882, 0.842409015, -0.48570472, 0.233319089, 0.499448329, 0.866343617, 0.000202953815, -0.202233106, 0.116359845, 0.972400308), new(20.75, 6.74979782, 89))
                                                                                spawn2 = fn12
                                                                                new = Vector3.new
                                                                                spawn2(CFrame.new(-212.42215, 57.5808716, -169.559814, 0.951042056, 0.0000000316649675, 0.309060723, 0.0000000111758709, 0.99999994, -0.0000000074505806, -0.309060752, -0.0000000149011612, 0.951042473), new(7.75, 4.24979782, 117))
                                                                                spawn2 = fn12
                                                                                CFrame215 = CFrame
                                                                                do
                                                                                    new = Vector3.new
                                                                                    spawn2(CFrame.new(-224.997284, 52.5610962, -177.975052, 0.811471164, -0.467886627, 0.350137621, 0.499437302, 0.866349936, 0.000212810439, -0.303441286, 0.174699053, 0.936698556), new(17.75, 6.74979782, 32))
                                                                                    spawn2 = fn12
                                                                                    new = Vector3.new
                                                                                    spawn2(CFrame.new(-210.638947, 57.2058716, -170.139297, 0.951042056, 0.0000000316649675, 0.309060723, 0.0000000111758709, 0.99999994, -0.0000000074505806, -0.309060752, -0.0000000149011612, 0.951042473), new(7, 3.49979782, 117))
                                                                                    spawn2 = fn12
                                                                                    new = Vector3.new
                                                                                    spawn2(CFrame.new(86.809967, 54.2058792, -434.137939, 0.188369185, 0.00000000000158486137, 0.982098579, 0.00000000000049803499, 1, 0.00000000000151822587, -0.98209846, -0.000000000000203132501, 0.188369095), new(301, 3.49979782, 287.25))
                                                                                    spawn2 = fn12
                                                                                    CFrame218 = CFrame
                                                                                    do
                                                                                        new = Vector3.new
                                                                                        spawn2(CFrame.new(52.8619156, 58.8309174, -320.487793, 0.190833777, -0.00000374184447, 0.981622398, -0.000000420325563, 1, 0.0000038936123, -0.981622398, -0.00000115563375, 0.190833792), new(17, 1.74979782, 44))
                                                                                        spawn2 = fn12
                                                                                        new = Vector3.new
                                                                                        spawn2(CFrame.new(54.4297676, 58.455925, -320.692352, 0.190833777, -0.00000374184447, 0.981622398, -0.000000420325563, 1, 0.0000038936123, -0.981622398, -0.00000115563375, 0.190833792), new(22, 0.999797821, 47))
                                                                                        spawn2 = fn12
                                                                                        new = Vector3.new
                                                                                        spawn2(CFrame.new(54.7160225, 57.205925, -322.164795, 0.190833777, -0.00000374184447, 0.981622398, -0.000000420325563, 1, 0.0000038936123, -0.981622398, -0.00000115563375, 0.190833792), new(25, 1.49979782, 47))
                                                                                        spawn2 = fn12
                                                                                        CFrame221 = CFrame
                                                                                        do
                                                                                            new = Vector3.new
                                                                                            spawn2(CFrame.new(55.0022812, 55.580925, -323.637238, 0.190833777, -0.00000374184447, 0.981622398, -0.000000420325563, 1, 0.0000038936123, -0.981622398, -0.00000115563375, 0.190833792), new(28, 2.24979782, 47))
                                                                                            spawn2 = fn12
                                                                                            new = Vector3.new
                                                                                            spawn2(CFrame.new(127.154045, 57.9558754, -280.683319, 0.615653574, 0.000000000000227373675, 0.788017035, 0.000000000000113686838, 1, 0.0000000000000710542736, -0.788017035, -0.000000000000227373675, 0.615653574), new(9, 3.99979782, 44))
                                                                                            spawn2 = fn12
                                                                                            new = Vector3.new
                                                                                            spawn2(CFrame.new(129.044098, 56.8308754, -282.696472, 0.615653574, 0.000000000000227373675, 0.788017035, 0.000000000000113686838, 1, 0.0000000000000710542736, -0.788017035, -0.000000000000227373675, 0.615653574), new(20, 4.24979782, 50.5))
                                                                                            spawn2 = fn12
                                                                                            CFrame224 = CFrame
                                                                                            do
                                                                                                new = Vector3.new
                                                                                                spawn2(CFrame.new(130.540146, 55.4558754, -285.017426, 0.615653574, 0.000000000000227373675, 0.788017035, 0.000000000000113686838, 1, 0.0000000000000710542736, -0.788017035, -0.000000000000227373675, 0.615653574), new(20, 4.49979782, 44))
                                                                                                spawn2 = fn12
                                                                                                new = Vector3.new
                                                                                                spawn2(CFrame.new(132.079285, 54.8308754, -286.987457, 0.615653574, 0.000000000000227373675, 0.788017035, 0.000000000000113686838, 1, 0.0000000000000710542736, -0.788017035, -0.000000000000227373675, 0.615653574), new(25, 3.24979782, 44))
                                                                                                spawn2 = fn12
                                                                                                new = Vector3.new
                                                                                                spawn2(CFrame.new(-20.4398537, 57.3308754, -317.710022, 0.984812856, 0.000000000000445411665, 0.17362076, 0.00000000000043284457, 1, 0.000000000000110245187, -0.17362076, 0.0000000000000334200441, 0.984812677), new(35.5, 4.74979782, 7.25))
                                                                                                spawn2 = fn12
                                                                                                CFrame227 = CFrame
                                                                                                do
                                                                                                    new = Vector3.new
                                                                                                    spawn2(CFrame.new(-20.6999245, 56.9558754, -321.345093, 0.984812856, 0.000000000000445411665, 0.17362076, 0.00000000000043284457, 1, 0.000000000000110245187, -0.17362076, 0.0000000000000334200441, 0.984812677), new(53.75, 3.99979782, 20.5))
                                                                                                    spawn2 = fn12
                                                                                                    new = Vector3.new
                                                                                                    spawn2(CFrame.new(-21.2862549, 55.5808754, -322.510986, 0.984812856, 0.000000000000445411665, 0.17362076, 0.00000000000043284457, 1, 0.000000000000110245187, -0.17362076, 0.0000000000000334200441, 0.984812677), new(35.5, 4.74979782, 23))
                                                                                                    spawn2 = fn12
                                                                                                    CFrame229 = CFrame
                                                                                                    local fn51 = CFrame229.new(-21.6769009, 55.0808754, -324.726807, 0.984812856, 0.000000000000445411665, 0.17362076, 0.00000000000043284457, 1, 0.000000000000110245187, -0.17362076, 0.0000000000000334200441, 0.984812677)
                                                                                                    new = Vector3.new
                                                                                                    spawn2(fn51, new(35.5, 3.74979782, 27.5))
                                                                                                    spawn2 = spawn
                                                                                                    fn51 = function()
                                                                                                        while true do
                                                                                                            if workspace:FindFirstChild("playerPickupCannonballRing") then
                                                                                                                break
                                                                                                            end
                                                                                                            wait()
                                                                                                        end
                                                                                                        workspace.playerPickupCannonballRing.Changed:Connect(function(a)
                                                                                                            if a == "Transparency" then
                                                                                                                ok5 = not ok5
                                                                                                                value10 = workspace.playerPickupCannonballRing
                                                                                                            end
                                                                                                        end)
                                                                                                    end
                                                                                                    spawn2(fn51)
                                                                                                end
                                                                                            end
                                                                                        end
                                                                                    end
                                                                                end
                                                                            end
                                                                        end
                                                                    end
                                                                end
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    if _G.destroy_map then
        local borders, value2 = workspace:FindFirstChild("borders"), "Destroy"
        local workspace2 = borders
        if workspace2 then
            workspace2[value2](workspace2)
        end
        borders = workspace:FindFirstChild("borderFix")
        value2 = "Destroy"
        workspace2 = borders
        if workspace2 then
            workspace2[value2](workspace2)
        end
        do
            local pairs2 = pairs
            workspace2 = workspace
            value2 = workspace2
            for k, v in pairs2(value2.GetChildren(value2)) do
                if v.ClassName == "Model"
                    and v.Name ~= "corruptCannons"
                    and v.Name ~= "playerFireCannon"
                    and v ~= game.Players.LocalPlayer.Character
                    and v.Name ~= result3 then
                    local value4, value5 = "Destroy", v
                    value5[value4](value5)
                end
            end
        end
    end
    wait(2)
    while true do
        local game3, value6 = game, "GetService"
        local value7 = game3
        game3 = value7[value6](value7, "Workspace")
        game3 = game3.dungeon
        do
            local room3 = game3.room3
            room3 = room3.enemyFolder
            value6 = "FindFirstChildOfClass"
            value7 = room3
        end
        do
            local item = value7[value6]
            if item(value7, "Model") then
                break
            end
        end
        wait(1)
    end
    ok6 = true
    spawn2 = result9
    local PathfindingService = CFrame.new(58.451, 140.645, -221.236)
    spawn2.CFrame = PathfindingService
    local _, _, _, value15 = fn23()
    while value15 == nil or not (fn22(value15.Position, result9.Position) < 5) do
        wait()
    end
    local game2 = result9
    local result2 = CFrame.new(77.782, 140.645, -233.241)
    game2.CFrame = result2
    while true do
        if not (value15.Position.Y > 135) then
            break
        end
        wait()
    end
    ok6 = false
    while true do
        local game4, value8 = game, "GetService"
        local value9 = game4
        game4 = value9[value8](value9, "Workspace")
        game4 = game4.dungeon
        do
            local room4 = game4.room4
            room4 = room4.enemyFolder
            value8 = "FindFirstChild"
            value9 = room4
        end
        do
            local item2 = value9[value8]
            if item2(value9, "The Kraken") then
                break
            end
        end
        wait(1)
    end
    while true do
        local game5, value11 = game, "GetService"
        local value12 = game5
        game5 = value12[value11](value12, "Workspace")
        game5 = game5.dungeon
        do
            local room42 = game5.room4
            room42 = room42.enemyFolder
            value11 = "FindFirstChild"
            value12 = room42
            room42 = value12[value11](value12, "The Kraken")
            value11 = "FindFirstChild"
            value12 = room42
        end
        do
            local item3 = value12[value11]
            if item3(value12, "HumanoidRootPart") then
                break
            end
        end
        wait(1)
    end
    while true do
        local game6, value13 = game, "GetService"
        local Players3 = game6
        game6 = Players3[value13](Players3, "Workspace")
        game6 = game6.dungeon
        do
            local room43 = game6.room4
            room43 = room43.enemyFolder
            value13 = "FindFirstChild"
            Players3 = room43
            room43 = Players3[value13](Players3, "The Kraken")
            value13 = "FindFirstChild"
            Players3 = room43
            room43 = Players3[value13](Players3, "HumanoidRootPart")
            room43 = room43.Position
            if not (room43.Y < -20) then
                break
            end
        end
        ok6 = true
        do
            local value14 = result9
            Players3 = CFrame.new(100.95, 58.9558, -524.832)
            value14.CFrame = Players3
        end
        wait()
    end
    ok6 = false
    game2 = game
    local value = "GetService"
    result2 = game2
    game2 = result2[value](result2, "Players")
    game2 = game2.LocalPlayer
    local Character = game2.Character
    Character = Character.LowerTorso
    Character = Character.Root
    value = "Remove"
    result2 = Character
    result2[value](result2)
    Character = game
    value = "GetService"
    result2 = Character
    Character = result2[value](result2, "Players")
    Character = Character.LocalPlayer
    local Character2 = Character.Character
    Character2 = Character2.LowerTorso
    Character2.Anchored = true
    spawn(function()
        while true do
            local dungeon = game:GetService("Workspace")
            dungeon = dungeon.dungeon
            local enemyFolder = dungeon.bossRoom.enemyFolder
            if enemyFolder:FindFirstChild("Sea Serpent") then
                local PathfindingService = enemyFolder:FindFirstChild("Sea Serpent")
                while PathfindingService ~= nil do
                    if PathfindingService.Parent == nil then
                        break
                    end
                    if not PathfindingService:FindFirstChild("Humanoid") then
                        break
                    end
                    if not (PathfindingService.Humanoid.Health > 0) then
                        break
                    end
                    if game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid") then
                        local LocalPlayer2 = game.Players.LocalPlayer
                        local HumanoidRootPart2 = LocalPlayer2.Character.HumanoidRootPart
                        local CFrame3 = PathfindingService.PrimaryPart.CFrame
                        local result3 = CFrame.new(0, 0, 10)
                        HumanoidRootPart2.CFrame = CFrame3 * result3
                        local LocalPlayer3 = game.Players.LocalPlayer
                        local Humanoid = LocalPlayer3.Character.Humanoid
                        local ChangeState = Humanoid.ChangeState
                        result3 = 11
                        ChangeState(Humanoid, result3)
                    end
                    local RenderStepped = game:GetService("RunService")
                    RenderStepped = RenderStepped.RenderStepped
                    RenderStepped:wait()
                end
                local LocalPlayer = game.Players.LocalPlayer
                local HumanoidRootPart = LocalPlayer.Character.HumanoidRootPart
                local Players = game.Players
                local Character = Players.LocalPlayer.Character
                local CFrame2 = Character.HumanoidRootPart.CFrame
                local result2 = CFrame.new(0, 220, 0)
                HumanoidRootPart.CFrame = CFrame2 * result2
            end
            wait(1)
        end
    end)
end

function samuraiFix()
    local wait2 = fn12
    local new = Vector3.new
    wait2(CFrame.new(-79.3490448, 17.7415733, -86.7040176, 0.7313537, 0, -0.681998372, 0, 1, 0, 0.681998372, 0, 0.7313537), new(73.0999832, 120, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-121.829887, 46.2415581, -115.202858, 0.974370062, 0, -0.224951044, 0, 1, 0, 0.224951044, 0, 0.974370062), new(34.9499969, 176.999969, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-144.170593, 49.5415764, -131.804932, 0.57357645, 0, -0.819152057, 0, 1, 0, 0.819152057, 0, 0.57357645), new(34.9499969, 183.600006, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-148.874176, 40.8565865, -154.876312, 0.0174523834, 0, -0.99984771, 0, 1, 0, 0.99984771, 0, 0.0174523834), new(34.9499969, 166.230026, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-145.585724, 36.8465843, -173.163925, -0.559192896, -0.0000000488861964, -0.829037547, -0.0000000149460107, 1, -0.0000000488861964, 0.829037547, -0.0000000149460107, -0.559192896), new(34.9499969, 158.210022, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-128.299927, 38.8115654, -190.066727, -0.838670552, -0.0000000733189083, -0.544639051, -0.0000000398089171, 1, -0.0000000733189083, 0.544639051, -0.0000000398089171, -0.838670552), new(34.9499969, 162.139984, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-114.954521, 38.4115791, -193.36969, -0.99862951, -0.0000000873029649, -0.0523359589, -0.0000000828474214, 1, -0.0000000873029649, 0.0523359589, -0.0000000828474214, -0.99862951), new(34.9499969, 161.340012, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-94.6667786, 41.6165733, -187.850113, -0.906307757, -0.0000000792319383, 0.42261827, -0.000000124369237, 1, -0.0000000792319383, -0.42261827, -0.000000124369237, -0.906307757), new(34.9499969, 167.75, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-76.6514664, 42.5215492, -173.739227, -0.484809577, -0.0000000423833981, 0.874619722, -0.000000163884465, 1, -0.0000000423833981, -0.874619722, -0.000000163884465, -0.484809577), new(34.9499969, 169.559952, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-71.1062622, 38.1915855, -159.090225, 0.0174523834, 0, 0.99984771, 0, 1, 0, -0.99984771, 0, 0.0174523834), new(34.9499969, 160.900024, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-70.8261185, 31.206562, -149.575394, 0.49999997, 0, 0.866025448, 0, 1, 0, -0.866025448, 0, 0.49999997), new(34.9499969, 146.929977, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-53.192379, 17.7415733, -112.487228, -0.719339788, -0.0000000628866843, 0.694658399, -0.000000148151742, 1, -0.0000000628866843, -0.694658399, -0.000000148151742, -0.719339788), new(71.1999741, 120, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-16.0917797, 17.7415733, -84.8617783, -0.927183867, -0.0000000810569887, 0.37460658, -0.000000120171919, 1, -0.0000000810569887, -0.37460658, -0.000000120171919, -0.927183867), new(28.6499805, 120, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(18.1154346, 17.7415733, -80.3057556, -1, -0.0000000874227766, 0, -0.0000000874227766, 1, -0.0000000874227766, 0.00000000000000764274186, -0.0000000874227766, -1), new(44.1499825, 120, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(44.4154396, 17.7415733, -77.3612747, -0.866025388, -0.0000000757103464, 0.5, -0.000000131134158, 1, -0.0000000757103464, -0.5, -0.000000131134158, -0.866025388), new(44.1499825, 120, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(86.6246567, 17.7415733, -47.5756416, -0.777145922, -0.0000000679402561, 0.629320383, -0.000000142439717, 1, -0.0000000679402561, -0.629320383, -0.000000142439717, -0.777145922), new(82.649971, 120, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-52.7619934, 17.7415733, 44.2467651, -0.0174523834, -0.00000000152573587, 0.99984771, -0.000000174832238, 1, -0.00000000152573587, -0.99984771, -0.000000174832238, -0.0174523834), new(210.749954, 120, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(113.934662, 17.7415733, 5.35666466, -0.0174523834, -0.00000000152573587, 0.99984771, -0.000000174832238, 1, -0.00000000152573587, -0.99984771, -0.000000174832238, -0.0174523834), new(68.5999527, 120, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(105.848, 17.7415733, 100.737358, -0.0174523834, -0.00000000152573587, 0.99984771, -0.000000174832238, 1, -0.00000000152573587, -0.99984771, -0.000000174832238, -0.0174523834), new(96.9499588, 120, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(76.6631012, 75.4415894, 148.297241, -1, -0.0000000874227766, 0, -0.0000000874227766, 1, -0.0000000874227766, 0.00000000000000764274186, -0.0000000874227766, -1), new(68.8998871, 129, 18.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(22.9380455, 76.1915817, 312.697144, -1, -0.0000000874227766, 0, -0.0000000874227766, 1, -0.0000000874227766, 0.00000000000000764274186, -0.0000000874227766, -1), new(141.350006, 127.5, 10))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(101.938057, 75.9415817, 232.997162, -0.0000000437113883, 0, -1, 0, 1, 0, 1, 0, -0.0000000437113883), new(162.44989, 128, 8.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-132.212021, 79.9415817, 180.147202, -1, -0.0000000874227766, 0, -0.0000000874227766, 1, -0.0000000874227766, 0.00000000000000764274186, -0.0000000874227766, -1), new(168.149887, 120, 72))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-123.587051, 79.9415817, 287.997192, -1, -0.0000000874227766, 0, -0.0000000874227766, 1, -0.0000000874227766, 0.00000000000000764274186, -0.0000000874227766, -1), new(150.899948, 120, 72.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-229.801941, 79.9415817, 220.263245, -0.906307757, -0.0000000792319383, -0.42261827, -0.0000000504763129, 1, -0.0000000792319383, 0.42261827, -0.0000000504763129, -0.906307757), new(55.5999222, 120, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-241.71637, 79.9415817, 221.566833, -0.342020154, -0.0000000299003524, -0.939692616, -0.00000000527224131, 1, -0.0000000299003524, 0.939692616, -0.00000000527224131, -0.342020154), new(55.5999222, 120, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-276.772064, 79.9415817, 273.57489, -0.681998372, -0.0000000596221881, -0.7313537, -0.0000000234858035, 1, -0.0000000596221881, 0.7313537, -0.0000000234858035, -0.681998372), new(73.2999039, 120, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-247.87471, 79.9415817, 294.94928, -0.7313537, -0.000000063936973, -0.681998372, -0.0000000278005885, 1, -0.000000063936973, 0.681998372, -0.0000000278005885, -0.7313537), new(65.2999191, 120, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-217.981018, 79.9415817, 272.917114, -0.997564077, -0.0000000872098198, -0.0697564706, -0.0000000813244725, 1, -0.0000000872098198, 0.0697564706, -0.0000000813244725, -0.997564077), new(17.0999241, 120, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-204.486954, 79.9415817, 264.958984, -0.484809577, -0.0000000423833981, -0.874619722, -0.0000000109610951, 1, -0.0000000423833981, 0.874619722, -0.0000000109610951, -0.484809577), new(27.4999256, 120, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-307.982819, 79.9415817, 295.596252, 0.866025388, 0, -0.5, 0, 1, 0, 0.5, 0, 0.866025388), new(20.2499027, 120, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-324.856873, 79.9415817, 291.09314, 0.999390841, 0, 0.0348994955, 0, 1, 0, -0.0348994955, 0, 0.999390841), new(20.2499027, 120, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-334.888336, 79.9415817, 294.865021, 0.838670552, 0, 0.544639051, 0, 1, 0, -0.544639051, 0, 0.838670552), new(25.0999069, 120, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-344.876831, 79.9415817, 303.412811, 0.544639051, 0, 0.838670552, 0, 1, 0, -0.838670552, 0, 0.544639051), new(25.0999069, 120, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-353.138275, 79.9415817, 319.06076, 0.309016973, 0, 0.95105654, 0, 1, 0, -0.95105654, 0, 0.309016973), new(25.0999069, 120, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-355.918182, 79.9415817, 338.616058, -0.156434491, -0.0000000136759377, 0.987688363, -0.000000173769237, 1, -0.0000000136759377, -0.987688363, -0.000000173769237, -0.156434491), new(25.0999069, 120, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-338.64389, 79.9415817, 361.615967, -0.719339788, -0.0000000628866843, 0.694658399, -0.000000148151742, 1, -0.0000000628866843, -0.694658399, -0.000000148151742, -0.719339788), new(50.5999031, 120, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-340.175018, 79.9415817, 406.1138, -0.642787635, -0.0000000561942812, -0.766044438, -0.0000000204530437, 1, -0.0000000561942812, 0.766044438, -0.0000000204530437, -0.642787635), new(68.14991, 120, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-345.91333, 79.9415817, 462.58136, 0.42261824, 0, -0.906307817, 0, 1, 0, 0.906307817, 0, 0.42261824), new(103.199928, 120, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-308.45636, 79.9415817, 507.855316, 0.987688363, 0, -0.156434476, 0, 1, 0, 0.156434476, 0, 0.987688363), new(47.6499405, 120, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-276.312256, 79.9415817, 511.668976, 0.99984771, 0, 0.0174524058, 0, 1, 0, -0.0174524058, 0, 0.99984771), new(47.6499405, 120, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-241.047165, 79.9415817, 538.805542, -0.453990519, -0.0000000396891124, 0.891006529, -0.000000165317033, 1, -0.0000000396891124, -0.891006529, -0.000000165317033, -0.453990519), new(65.5499344, 120, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-220.261414, 79.9415817, 575.792419, -0.559192896, -0.0000000488861964, 0.829037547, -0.000000159899542, 1, -0.0000000488861964, -0.829037547, -0.000000159899542, -0.559192896), new(47.3499336, 120, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-186.82869, 79.9415817, 601.801575, -0.882947564, -0.0000000771897248, 0.469471574, -0.000000128465288, 1, -0.0000000771897248, -0.469471574, -0.000000128465288, -0.882947564), new(76.9499283, 120, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-273.247772, 79.9415817, 323.264557, -0.42261824, -0.0000000369464601, -0.906307817, -0.00000000819083112, 1, -0.0000000369464601, 0.906307817, -0.00000000819083112, -0.42261824), new(17.9499207, 120, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-278.552307, 79.9415817, 339.3573, -0.207911655, -0.0000000181762143, -0.978147626, -0.00000000191039362, 1, -0.0000000181762143, 0.978147626, -0.00000000191039362, -0.207911655), new(17.9499207, 120, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-283.670166, 79.9415817, 356.718292, -0.35836798, -0.0000000313295239, -0.933580399, -0.00000000580658366, 1, -0.0000000313295239, 0.933580399, -0.00000000580658366, -0.35836798), new(20.6499119, 120, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-268.345642, 79.9415817, 364.530884, 0.999390841, 0, 0.0348994955, 0, 1, 0, -0.0348994955, 0, 0.999390841), new(40.7998962, 120, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-232.930862, 79.9415817, 367.778046, 0.974370062, 0, -0.224951044, 0, 1, 0, 0.224951044, 0, 0.974370062), new(40.7998962, 120, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-198.301727, 79.9415817, 406.548157, -0.438371152, -0.0000000383236234, 0.898794055, -0.000000165997847, 1, -0.0000000383236234, -0.898794055, -0.000000165997847, -0.438371152), new(85.8499603, 120, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-191.77713, 79.9415817, 455.941559, -0.515038073, -0.0000000450260593, -0.857167304, -0.0000000124868293, 1, -0.0000000450260593, 0.857167304, -0.0000000124868293, -0.515038073), new(42.049984, 120, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-208.300247, 79.9415817, 479.683472, -0.629320443, -0.0000000550169403, -0.777145922, -0.0000000194825205, 1, -0.0000000550169403, 0.777145922, -0.0000000194825205, -0.629320443), new(42.049984, 120, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-209.384109, 79.9415817, 507.477234, 0.642787635, 0, -0.766044438, 0, 1, 0, 0.766044438, 0, 0.642787635), new(36.9999733, 120, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-180.930634, 79.9415817, 525.294922, 0.974370062, 0, -0.224951044, 0, 1, 0, 0.224951044, 0, 0.974370062), new(36.9999733, 120, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-145.599655, 79.9415817, 528.387268, 0.997564077, 0, 0.0697564706, 0, 1, 0, -0.0697564706, 0, 0.997564077), new(36.9999733, 120, 5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-132.102982, 79.9415817, 531.453186, -0.0697565079, -0.00000000609830764, 0.997564077, -0.000000174632589, 1, -0.00000000609830764, -0.997564077, -0.000000174632589, -0.0697565079), new(35.899971, 120, 17.3999958))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-153.191727, 79.9415817, 603.870667, 0.49999997, 0, 0.866025448, 0, 1, 0, -0.866025448, 0, 0.49999997), new(36.1999664, 120, 9.19999409))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(92.1630783, 79.9415817, 575.945129, 0.99984771, 0, -0.0174524058, 0, 1, 0, 0.0174524058, 0, 0.99984771), new(129.549896, 120, 14.0500021))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(85.5814362, 79.9415817, 623.537842, 0.99984771, 0, -0.0174524058, 0, 1, 0, 0.0174524058, 0, 0.99984771), new(118.049873, 120, 14.0500021))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(155.319351, 79.9415817, 644.592834, 0.438371152, 0, -0.898794055, 0, 1, 0, 0.898794055, 0, 0.438371152), new(58.5498695, 120, 4.65000153))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(150.972641, 79.9415817, 733.93103, 0.275637388, 0, 0.96126169, 0, 1, 0, -0.96126169, 0, 0.275637388), new(134.699875, 120, 4.65000153))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(113.599823, 79.9415817, 834.299438, 0.469471604, 0, 0.882947564, 0, 1, 0, -0.882947564, 0, 0.469471604), new(82.6498489, 120, 4.65000153))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(83.7891617, 79.9415817, 886.715393, 0.544639051, 0, 0.838670552, 0, 1, 0, -0.838670552, 0, 0.544639051), new(40.299839, 120, 4.65000153))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(57.0700951, 79.9415817, 912.924072, 0.857167304, 0, 0.515038073, 0, 1, 0, -0.515038073, 0, 0.857167304), new(40.299839, 120, 4.65000153))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-16.656601, 79.9415817, 934.313538, 0.981627166, 0, 0.190808997, 0, 1, 0, -0.190808997, 0, 0.981627166), new(116.849838, 120, 4.65000153))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-14.7186928, 79.9415817, 1032.85339, 0.981627166, 0, 0.190808997, 0, 1, 0, -0.190808997, 0, 0.981627166), new(150.649872, 120, 4.65000153))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(100.627106, 79.9415817, 999.678406, 0.91354543, 0, 0.406736642, 0, 1, 0, -0.406736642, 0, 0.91354543), new(96.7998657, 120, 4.65000153))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-82.9455414, 79.9415817, 944.657593, 0.99984771, 0, -0.0174524058, 0, 1, 0, 0.0174524058, 0, 0.99984771), new(37.8998451, 120, 4.65000153))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-131.292542, 79.9415817, 922.620178, 0.798635542, 0, -0.601814985, 0, 1, 0, 0.601814985, 0, 0.798635542), new(75.9498596, 120, 4.65000153))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-232.84433, 79.9415817, 900.761597, 0.99862951, 0, -0.0523359589, 0, 1, 0, 0.0523359589, 0, 0.99862951), new(160.549911, 120, 4.65000153))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-99.3179703, 79.9415817, 1066.7688, 0.515038073, 0, 0.857167304, 0, 1, 0, -0.857167304, 0, 0.515038073), new(47.8498611, 120, 4.65000153))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(191.109024, 79.9415817, 590.424316, 0.96126169, 0, -0.275637358, 0, 1, 0, 0.275637358, 0, 0.96126169), new(129.549896, 120, 14.0500021))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(116.764015, 79.9415817, 982.981506, 0.587785304, 0, 0.809017003, 0, 1, 0, -0.809017003, 0, 0.587785304), new(44.3998642, 120, 4.65000153))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(147.403961, 79.9415817, 956.020203, 0.866025388, 0, 0.5, 0, 1, 0, -0.5, 0, 0.866025388), new(44.3998642, 120, 4.65000153))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(187.493103, 79.9415817, 912.867615, 0.669130564, 0, 0.74314487, 0, 1, 0, -0.74314487, 0, 0.669130564), new(115.299873, 120, 4.65000153))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(199.873352, 79.9415817, 869.370178, -0.0348994955, -0.00000000305101078, 0.999390841, -0.000000174792291, 1, -0.00000000305101078, -0.999390841, -0.000000174792291, -0.0348994955), new(120.999878, 120, 4.65000153))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(203.445938, 79.9415817, 792.87146, 0.309016973, 0, 0.95105654, 0, 1, 0, -0.95105654, 0, 0.309016973), new(36.849865, 120, 4.65000153))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(207.590225, 79.9415817, 760.274048, 0.0348994955, 0, -0.999390841, 0, 1, 0, 0.999390841, 0, 0.0348994955), new(52.099865, 120, 4.65000153))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(220.461777, 79.9415817, 663.820862, -0.258819073, -0.0000000226266827, -0.965925813, -0.00000000297885805, 1, -0.0000000226266827, 0.965925813, -0.00000000297885805, -0.258819073), new(145.199936, 120, 14.2000027))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-312.379059, 79.9415817, 901.517517, 0.642787635, 0, 0.766044438, 0, 1, 0, -0.766044438, 0, 0.642787635), new(55.4000015, 120, 4.65000153))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-325.956299, 79.9415817, 988.109619, -0.0000000437113883, 0, 1, 0, 1, 0, -1, 0, -0.0000000437113883), new(173.950043, 120, 4.65000153))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-198.956482, 79.9415817, 1094.80957, -1, -0.0000000874227766, 0, -0.0000000874227766, 1, -0.0000000874227766, 0.00000000000000764274186, -0.0000000874227766, -1), new(188.15004, 120, 4.65000153))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(46.1631012, 77.6916199, 283.547241, -1, -0.0000000874227766, 0, -0.0000000874227766, 1, -0.0000000874227766, 0.00000000000000764274186, -0.0000000874227766, -1), new(71.8998871, 17.5, 4))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-153.191727, 79.9415817, 603.870667, 0.49999997, 0, 0.866025448, 0, 1, 0, -0.866025448, 0, 0.49999997), new(36.1999664, 120, 9.19999409))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-218.836899, 66.4415817, 262.047241, -1, -0.0000000874227766, 0, -0.0000000874227766, 1, -0.0000000874227766, 0.00000000000000764274186, -0.0000000874227766, -1), new(84.8998871, 1, 108))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-35.8530579, 63.9391098, 607.062622, -1.00000024, 0.000000000000000000000668149738, 0, -0.000000000000000000000668149738, 1, 0, 0, 0, -0.999999881), new(207.399887, 1.5, 166))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(78.6687851, 17.7415791, 47.7285957, -0.0174523834, -0.00000000152573587, 0.99984771, -0.000000174832238, 1, -0.00000000152573587, -0.99984771, -0.000000174832238, -0.0174523834), new(46.0999527, 120, 77))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-14.8169785, 17.7415791, 49.3603935, -0.0174523834, -0.00000000152573587, 0.99984771, -0.000000174832238, 1, -0.00000000152573587, -0.99984771, -0.000000174832238, -0.0174523834), new(46.0999527, 120, 78))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(32.8341637, 5.29244184, 34.5653267, -0.0000000037252903, 0.000000000465661287, 1, -0.244939968, 0.969538212, 0.00000000125146471, -0.969538152, -0.244939908, 0.0000000037252903), new(51.5999527, 5, 20.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(25.6630993, 93.6915894, 151.797241, -1, -0.0000000874227766, 0, -0.0000000874227766, 1, -0.0000000874227766, 0.00000000000000764274186, -0.0000000874227766, -1), new(135.899887, 92.5, 9.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-21.0868988, 73.9415894, 149.297241, -1, -0.0000000874227766, 0, -0.0000000874227766, 1, -0.0000000874227766, 0.00000000000000764274186, -0.0000000874227766, -1), new(69.3998871, 132, 14.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-50.836895, 37.691597, 220.797241, -1, -0.0000000874227766, 0, -0.0000000874227766, 1, -0.0000000874227766, 0.00000000000000764274186, -0.0000000874227766, -1), new(9.89988708, 59.5, 157.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(56.413105, 38.6916161, 283.547241, -1, -0.0000000874227766, 0, -0.0000000874227766, 1, -0.0000000874227766, 0.00000000000000764274186, -0.0000000874227766, -1), new(92.3998871, 61.5, 4))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-32.086895, 38.6916046, 283.547241, -1, -0.0000000874227766, 0, -0.0000000874227766, 1, -0.0000000874227766, 0.00000000000000764274186, -0.0000000874227766, -1), new(28.3998871, 61.5, 4))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(30.4380493, 67.9415741, 211.697144, -1, -0.0000000874227766, 0, -0.0000000874227766, 1, -0.0000000874227766, 0.00000000000000764274186, -0.0000000874227766, -1), new(156.350006, 4, 146))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(29.5450134, 2.84688377, 217.2388, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(165.91008, 22.4399872, 132.789948))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(87.6880493, 67.1915817, 224.947144, -1, -0.0000000874227766, 0, -0.0000000874227766, 1, -0.0000000874227766, 0.00000000000000764274186, -0.0000000874227766, -1), new(24.8500061, 4.5, 172.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(48.4890289, 38.7647934, 298.738983, -0.707106829, -0.707106769, 0.0000000437113883, -0.707106829, 0.707106769, -0.0000000437113847, 0, -0.0000000618172393, -1), new(81.3500061, 5.5, 26))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-8.87301826, 14.249526, 296.988922, -1.00000012, -0.0000000894069672, 0.00000000000000940053089, -0.0000000894069672, 0.99999994, -0.0000000874227695, 0.00000000000000177635684, -0.0000000874227766, -1), new(59.3500061, 0.5, 26.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-28.1230221, 37.4995232, 296.988922, -1.00000012, -0.0000000894069672, 0.00000000000000940053089, -0.0000000894069672, 0.99999994, -0.0000000874227695, 0.00000000000000177635684, -0.0000000874227766, -1), new(20.8500061, 47, 26.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(28.0450134, 2.59688377, 106.488808, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(158.91008, 21.9399872, 94.2899399))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-124.586899, 67.1915894, 236.797241, -1, -0.0000000874227766, 0, -0.0000000874227766, 1, -0.0000000874227766, 0.00000000000000764274186, -0.0000000874227766, -1), new(157.399887, 0.5, 57.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-254.643875, 66.3116455, 432.286926, -0.912263155, 0, -0.409604788, -0.000000000000000000000668149738, 1, 0, 0.409604847, 0, -0.912263036), new(207.399887, 2.5, 151))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-125.181572, 64.4391098, 589.670898, -0.945519269, 0.00000000000000000000200444967, 0.325568169, -0.00000000000000000000204085147, 1, -0.000000000000000000000217528256, -0.325568289, 0.0000000000000000000000000000504870979, -0.945518196), new(17.3998871, 2.5, 166))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-137.709702, 64.9391098, 585.357117, -0.945519269, 0.00000000000000000000200444967, 0.325568169, -0.00000000000000000000204085147, 1, -0.000000000000000000000217528256, -0.325568289, 0.0000000000000000000000000000504870979, -0.945518196), new(22.8998871, 3.5, 166))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(19.0190639, 64.4391098, 609.972961, -0.990270078, 0.00000000000000000000586774583, 0.139173076, -0.00000000000000000000588725364, 1, 0.000000000000000000000591148532, -0.139173225, 0.000000000000000000000870114437, -0.990266919), new(23.8998871, 2.5, 111.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(105.727264, 64.9391098, 804.053894, -0.990270078, 0.00000000000000000000586774583, 0.139173076, -0.00000000000000000000588725364, 1, 0.000000000000000000000591148532, -0.139173225, 0.000000000000000000000870114437, -0.990266919), new(214.149902, 3.5, 514.25))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-224.200012, 65.5, 1001.75006, -1.00000405, 0.000000000000000000011819003, 0.000000298023224, -0.000000000000000000011819003, 1, 0.000000000000000000000546135296, 0.000000298023224, -0.000000000000000000000546135296, -0.999997675), new(181.399902, 4, 138.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-146.199707, 66, 1001.75006, -1.00000405, 0.000000000000000000011819003, 0.000000298023224, -0.000000000000000000011819003, 1, 0.000000000000000000000546135296, 0.000000298023224, -0.000000000000000000000546135296, -0.999997675), new(25.3999023, 5, 138.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-174.199951, 66, 1047.75, -0.62932831, 0.0000000000000000000354571487, 0.777146101, -0.0000000000000000000402626932, 1, -0.00000000000000000000734422647, -0.777149975, -0.00000000000000000000163841185, -0.629315674), new(25.3999023, 5, 138.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-237.197769, 66, 1060.49756, 0.173636138, 0.000000000000000000116034402, 0.984809875, -0.000000000000000000130376718, 1, -0.0000000000000000000948368712, -0.984809875, -0.000000000000000000111929169, 0.173636138), new(25.3999023, 5, 138.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-283.1716, 66, 1015.58191, 0.906302631, 0.000000000000000000116034402, 0.422629356, -0.000000000000000000152466835, 1, 0.0000000000000000000524021665, -0.422629356, -0.000000000000000000111929169, 0.906302631), new(25.3999023, 5, 138.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-261.013458, 66, 946.482361, 0.77715373, 0.000000000000000000116034389, -0.629310906, -0.0000000000000000000197383098, 1, 0.000000000000000000160007905, 0.629310906, -0.000000000000000000111929182, 0.77715373), new(25.3999023, 5, 138.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-210.805298, 66, 933.739136, -0.190796942, 0.000000000000000000116034389, -0.981629729, 0.000000000000000000132012016, 1, 0.0000000000000000000925470866, 0.981629729, -0.000000000000000000111929182, -0.190796942), new(25.3999023, 5, 138.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-162.697159, 66, 955.924011, -0.707098544, 0.000000000000000000116034363, -0.707116008, 0.000000000000000000161194651, 1, 0.00000000000000000000290485394, 0.707116008, -0.000000000000000000111929195, -0.707098544), new(25.3999023, 5, 138.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-160.222321, 66.5, 953.449097, -0.707098544, 0.000000000000000000116034363, -0.707116008, 0.000000000000000000161194651, 1, 0.00000000000000000000290485394, 0.707116008, -0.000000000000000000111929195, -0.707098544), new(25.3999023, 5, 138.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-157.040375, 67, 950.26709, -0.707098544, 0.000000000000000000116034363, -0.707116008, 0.000000000000000000161194651, 1, 0.00000000000000000000290485394, 0.707116008, -0.000000000000000000111929195, -0.707098544), new(25.3999023, 5, 138.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-155.272629, 67.5, 948.499329, -0.707098544, 0.000000000000000000116034363, -0.707116008, 0.000000000000000000161194651, 1, 0.00000000000000000000290485394, 0.707116008, -0.000000000000000000111929195, -0.707098544), new(25.3999023, 5, 138.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-152.797791, 68, 946.024414, -0.707098544, 0.000000000000000000116034363, -0.707116008, 0.000000000000000000161194651, 1, 0.00000000000000000000290485394, 0.707116008, -0.000000000000000000111929195, -0.707098544), new(25.3999023, 5, 138.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-150.676498, 68.5, 943.903076, -0.707098544, 0.000000000000000000116034363, -0.707116008, 0.000000000000000000161194651, 1, 0.00000000000000000000290485394, 0.707116008, -0.000000000000000000111929195, -0.707098544), new(25.3999023, 5, 138.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-144.199692, 66.5, 1001.75006, -1.00000405, 0.000000000000000000011819003, 0.000000298023224, -0.000000000000000000011819003, 1, 0.000000000000000000000546135296, 0.000000298023224, -0.000000000000000000000546135296, -0.999997675), new(25.3999023, 5, 138.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-141.199677, 67, 1001.75006, -1.00000405, 0.000000000000000000011819003, 0.000000298023224, -0.000000000000000000011819003, 1, 0.000000000000000000000546135296, 0.000000298023224, -0.000000000000000000000546135296, -0.999997675), new(25.3999023, 5, 138.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-140.199661, 67.5, 1001.75006, -1.00000405, 0.000000000000000000011819003, 0.000000298023224, -0.000000000000000000011819003, 1, 0.000000000000000000000546135296, 0.000000298023224, -0.000000000000000000000546135296, -0.999997675), new(25.3999023, 5, 138.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-139.199661, 68, 1001.75006, -1.00000405, 0.000000000000000000011819003, 0.000000298023224, -0.000000000000000000011819003, 1, 0.000000000000000000000546135296, 0.000000298023224, -0.000000000000000000000546135296, -0.999997675), new(25.3999023, 5, 138.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-116.44957, 68.5, 1001.75006, -1.00000405, 0.000000000000000000011819003, 0.000000298023224, -0.000000000000000000011819003, 1, 0.000000000000000000000546135296, 0.000000298023224, -0.000000000000000000000546135296, -0.999997675), new(67.8999023, 5, 138.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-112.699554, 68, 1001.75006, -1.00000405, 0.000000000000000000011819003, 0.000000298023224, -0.000000000000000000011819003, 1, 0.000000000000000000000546135296, 0.000000298023224, -0.000000000000000000000546135296, -0.999997675), new(75.3999023, 4, 138.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-107.699532, 67.5, 1001.75006, -1.00000405, 0.000000000000000000011819003, 0.000000298023224, -0.000000000000000000011819003, 1, 0.000000000000000000000546135296, 0.000000298023224, -0.000000000000000000000546135296, -0.999997675), new(85.3999023, 3, 138.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-103.949516, 67, 1001.75006, -1.00000405, 0.000000000000000000011819003, 0.000000298023224, -0.000000000000000000011819003, 1, 0.000000000000000000000546135296, 0.000000298023224, -0.000000000000000000000546135296, -0.999997675), new(92.8999023, 2, 138.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-100.199501, 66.75, 1001.75006, -1.00000405, 0.000000000000000000011819003, 0.000000298023224, -0.000000000000000000011819003, 1, 0.000000000000000000000546135296, 0.000000298023224, -0.000000000000000000000546135296, -0.999997675), new(100.399902, 1.5, 138.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-173.570618, 66.5, 1048.5271, -0.62932831, 0.0000000000000000000354571487, 0.777146101, -0.0000000000000000000402626932, 1, -0.00000000000000000000734422647, -0.777149975, -0.00000000000000000000163841185, -0.629315674), new(25.3999023, 5, 138.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-172.626633, 67, 1049.69287, -0.62932831, 0.0000000000000000000354571487, 0.777146101, -0.0000000000000000000402626932, 1, -0.00000000000000000000734422647, -0.777149975, -0.00000000000000000000163841185, -0.629315674), new(25.3999023, 5, 138.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-171.367981, 67.5, 1051.24719, -0.62932831, 0.0000000000000000000354571487, 0.777146101, -0.0000000000000000000402626932, 1, -0.00000000000000000000734422647, -0.777149975, -0.00000000000000000000163841185, -0.629315674), new(25.3999023, 5, 138.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-168.536011, 68, 1054.74438, -0.62932831, 0.0000000000000000000354571487, 0.777146101, -0.0000000000000000000402626932, 1, -0.00000000000000000000734422647, -0.777149975, -0.00000000000000000000163841185, -0.629315674), new(25.3999023, 5, 138.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-166.962692, 68.5, 1056.68726, -0.62932831, 0.0000000000000000000354571487, 0.777146101, -0.0000000000000000000402626932, 1, -0.00000000000000000000734422647, -0.777149975, -0.00000000000000000000163841185, -0.629315674), new(25.3999023, 5, 138.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-166.018707, 69, 1057.85303, -0.62932831, 0.0000000000000000000354571487, 0.777146101, -0.0000000000000000000402626932, 1, -0.00000000000000000000734422647, -0.777149975, -0.00000000000000000000163841185, -0.629315674), new(25.3999023, 5, 138.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-238.239594, 66.5, 1066.40637, 0.173636138, 0.000000000000000000116034402, 0.984809875, -0.000000000000000000130376718, 1, -0.0000000000000000000948368712, -0.984809875, -0.000000000000000000111929169, 0.173636138), new(25.3999023, 5, 138.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-238.673691, 67, 1068.86841, 0.173636138, 0.000000000000000000116034402, 0.984809875, -0.000000000000000000130376718, 1, -0.0000000000000000000948368712, -0.984809875, -0.000000000000000000111929169, 0.173636138), new(25.3999023, 5, 138.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-239.020966, 67.5, 1070.83801, 0.173636138, 0.000000000000000000116034402, 0.984809875, -0.000000000000000000130376718, 1, -0.0000000000000000000948368712, -0.984809875, -0.000000000000000000111929169, 0.173636138), new(25.3999023, 5, 138.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-239.54187, 68, 1073.79248, 0.173636138, 0.000000000000000000116034402, 0.984809875, -0.000000000000000000130376718, 1, -0.0000000000000000000948368712, -0.984809875, -0.000000000000000000111929169, 0.173636138), new(25.3999023, 5, 138.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-240.062775, 68.5, 1076.74695, 0.173636138, 0.000000000000000000116034402, 0.984809875, -0.000000000000000000130376718, 1, -0.0000000000000000000948368712, -0.984809875, -0.000000000000000000111929169, 0.173636138), new(25.3999023, 5, 138.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-286.343658, 66.5, 1017.0611, 0.906302631, 0.000000000000000000116034402, 0.422629356, -0.000000000000000000152466835, 1, 0.0000000000000000000524021665, -0.422629356, -0.000000000000000000111929169, 0.906302631), new(25.3999023, 5, 138.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-289.515717, 67, 1018.54028, 0.906302631, 0.000000000000000000116034402, 0.422629356, -0.000000000000000000152466835, 1, 0.0000000000000000000524021665, -0.422629356, -0.000000000000000000111929169, 0.906302631), new(25.3999023, 5, 138.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-291.781464, 67.5, 1019.59686, 0.906302631, 0.000000000000000000116034402, 0.422629356, -0.000000000000000000152466835, 1, 0.0000000000000000000524021665, -0.422629356, -0.000000000000000000111929169, 0.906302631), new(25.3999023, 5, 138.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-294.500366, 68, 1020.86475, 0.906302631, 0.000000000000000000116034402, 0.422629356, -0.000000000000000000152466835, 1, 0.0000000000000000000524021665, -0.422629356, -0.000000000000000000111929169, 0.906302631), new(25.3999023, 5, 138.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-298.12558, 68.5, 1022.55524, 0.906302631, 0.000000000000000000116034402, 0.422629356, -0.000000000000000000152466835, 1, 0.0000000000000000000524021665, -0.422629356, -0.000000000000000000111929169, 0.906302631), new(25.3999023, 5, 138.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-262.179199, 66.5, 945.538391, 0.77715373, 0.000000000000000000116034389, -0.629310906, -0.0000000000000000000197383098, 1, 0.000000000000000000160007905, 0.629310906, -0.000000000000000000111929182, 0.77715373), new(25.3999023, 5, 138.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-263.34494, 67, 944.594421, 0.77715373, 0.000000000000000000116034389, -0.629310906, -0.0000000000000000000197383098, 1, 0.000000000000000000160007905, 0.629310906, -0.000000000000000000111929182, 0.77715373), new(25.3999023, 5, 138.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-264.899261, 67.5, 943.335815, 0.77715373, 0.000000000000000000116034389, -0.629310906, -0.0000000000000000000197383098, 1, 0.000000000000000000160007905, 0.629310906, -0.000000000000000000111929182, 0.77715373), new(25.3999023, 5, 138.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-266.065002, 68, 942.391846, 0.77715373, 0.000000000000000000116034389, -0.629310906, -0.0000000000000000000197383098, 1, 0.000000000000000000160007905, 0.629310906, -0.000000000000000000111929182, 0.77715373), new(25.3999023, 5, 138.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-266.842163, 68.5, 941.762512, 0.77715373, 0.000000000000000000116034389, -0.629310906, -0.0000000000000000000197383098, 1, 0.000000000000000000160007905, 0.629310906, -0.000000000000000000111929182, 0.77715373), new(25.3999023, 5, 138.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-210.137512, 66.5, 930.303406, -0.190796942, 0.000000000000000000116034389, -0.981629729, 0.000000000000000000132012016, 1, 0.0000000000000000000925470866, 0.981629729, -0.000000000000000000111929182, -0.190796942), new(25.3999023, 5, 138.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-209.660522, 67, 927.849304, -0.190796942, 0.000000000000000000116034389, -0.981629729, 0.000000000000000000132012016, 1, 0.0000000000000000000925470866, 0.981629729, -0.000000000000000000111929182, -0.190796942), new(25.3999023, 5, 138.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-208.992737, 67.5, 924.413635, -0.190796942, 0.000000000000000000116034389, -0.981629729, 0.000000000000000000132012016, 1, 0.0000000000000000000925470866, 0.981629729, -0.000000000000000000111929182, -0.190796942), new(25.3999023, 5, 138.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-208.706543, 68, 922.941162, -0.190796942, 0.000000000000000000116034389, -0.981629729, 0.000000000000000000132012016, 1, 0.0000000000000000000925470866, 0.981629729, -0.000000000000000000111929182, -0.190796942), new(25.3999023, 5, 138.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-208.420349, 68.5, 921.468689, -0.190796942, 0.000000000000000000116034389, -0.981629729, 0.000000000000000000132012016, 1, 0.0000000000000000000925470866, 0.981629729, -0.000000000000000000111929182, -0.190796942), new(25.3999023, 5, 138.5))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(42.9820786, 0.3806144, 36.3547974, -0.000348969304, 0, 0.99999994, 0, 1, 0, -0.99999994, 0, -0.000348969304), new(49.7200928, 29.8699951, 3.82001257))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(21.461998, -1.51294553, 36.6358871, -0.000348969304, 0, 0.99999994, 0, 1, 0, -0.99999994, 0, -0.000348969304), new(48.7200928, 36.8699951, 3.82001257))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(28.1880493, 67.1915741, 230.697144, -1, -0.0000000874227766, 0, -0.0000000874227766, 1, -0.0000000874227766, 0.00000000000000764274186, -0.0000000874227766, -1), new(160.850006, 2.5, 61))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(29.4380493, 67.6915741, 234.197144, -1, -0.0000000874227766, 0, -0.0000000874227766, 1, -0.0000000874227766, 0.00000000000000764274186, -0.0000000874227766, -1), new(158.350006, 3.5, 61))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(28.6880493, 67.4415741, 230.697144, -1, -0.0000000874227766, 0, -0.0000000874227766, 1, -0.0000000874227766, 0.00000000000000764274186, -0.0000000874227766, -1), new(159.850006, 3, 62))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(27.4380493, 66.9415741, 234.947144, -1, -0.0000000874227766, 0, -0.0000000874227766, 1, -0.0000000874227766, 0.00000000000000764274186, -0.0000000874227766, -1), new(162.350006, 2, 48.5))
    wait2 = fn12
    CFrame162 = CFrame
    local PathfindingService = CFrame162.new(56.7784882, 64.9391098, 983.48761, -0.990270078, 0.00000000000000000000586774583, 0.139173076, -0.00000000000000000000588725364, 1, 0.000000000000000000000591148532, -0.139173225, 0.000000000000000000000870114437, -0.990266919)
    new = Vector3.new
    wait2(PathfindingService, new(261.149902, 3.5, 145.25))
    wait2 = wait
    PathfindingService = 0.1
    wait2(PathfindingService)
    if _G.destroy_map then
        local pairs2, workspace2 = pairs, workspace
        local value2, value3 = "GetChildren", workspace2
        local item = value3[value2]
        for k, v in pairs2(item(value3)) do
            if (v.ClassName == "Model"
                or v.ClassName == "Part"
                or v.ClassName == "UnionOperation"
                or v.ClassName == "WedgePart")
                and v ~= game.Players.LocalPlayer.Character
                and v.Name ~= result3 then
                local value4, value5 = "Destroy", v
                value5[value4](value5)
            end
        end
        local game2 = game
        value3 = "GetService"
        workspace2 = game2
        game2 = workspace2[value3](workspace2, "Workspace")
        game2 = game2.fence
        value3 = "Destroy"
        workspace2 = game2
        workspace2[value3](workspace2)
        local game3 = game
        value3 = "GetService"
        workspace2 = game3
        game3 = workspace2[value3](workspace2, "Workspace")
        game3 = game3.borders
        value3 = "Destroy"
        workspace2 = game3
        workspace2[value3](workspace2)
    end
    wait2 = workspace
    new = "WaitForChild"
    local ChildAdded = wait2
    ChildAdded[new](ChildAdded, "eliteSwordsman")
    wait2 = game
    new = "GetService"
    ChildAdded = wait2
    wait2 = ChildAdded[new](ChildAdded, "Workspace")
    wait2 = wait2.eliteSwordsman
    ChildAdded = wait2.ChildAdded
    new = ChildAdded
    new.Connect(new, function(a)
        if a.ClassName == "Model" and a.Name == "Ultimate Swordsman" then
            a:WaitForChild("HumanoidRootPart")
            fn17(a, 30, "square")
        end
    end)
    while true do
        local game4, value6 = game, "GetService"
        local value7 = game4
        game4 = value7[value6](value7, "Workspace")
        game4 = game4.dungeon
        local room4 = game4.room4
        room4 = room4.enemyFolder
        value6 = "FindFirstChild"
        value7 = room4
        local item2 = value7[value6]
        if item2(value7, "Sanada Yukimura") then
            break
        end
        wait(1)
    end
    while true do
        local game5, value8 = game, "GetService"
        local value9 = game5
        game5 = value9[value8](value9, "Workspace")
        game5 = game5.dungeon
        local room42 = game5.room4
        room42 = room42.enemyFolder
        value8 = "FindFirstChild"
        value9 = room42
        room42 = value9[value8](value9, "Sanada Yukimura")
        value8 = "FindFirstChild"
        value9 = room42
        local item3 = value9[value8]
        if item3(value9, "HumanoidRootPart") then
            break
        end
        wait(1)
    end
    ok6 = true
    ChildAdded = result9
    new = CFrame.new(88.5511551, 72.7995224, 276.368042)
    ChildAdded.CFrame = new
    local _, _, _, value10 = fn23()
    while true do
        if not (value10.Position.Y < 69.999526977539) then
            break
        end
        wait()
    end
    ok6 = false
end

function underworldFix()
    local value = fn12
    local CFrame2 = CFrame.new(487, 65.1197205, 416.394165, 1, 0, 0, 0, 0.89100647, 0.4539904, 0, -0.4539904, 0.89100647)
    value(CFrame2, Vector3.new(68, 1, 83.5))
    local value3 = fn12
    CFrame2 = CFrame
    local PathfindingService = CFrame2.new(487, 61.8143387, 275.542908, 1, 0, 0, 0, 0.89100647, 0.4539904, 0, -0.4539904, 0.89100647)
    value3(PathfindingService, Vector3.new(68, 1, 17.5))
end

function pirateFix()
    local value9
    local wait2 = fn12
    local new = Vector3.new
    wait2(CFrame.new(-68.2813721, 189.801392, 430.691193, 0.997564077, 0, -0.0697564706, 0, 1, 0, 0.0697564706, 0, 0.997564077), new(115.020088, 173.349854, 90.7301254))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-248.68956, 189.686432, 446.980225, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(145.240143, 173.119949, 132.979874))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-156.12616, 190.301392, 468.405304, 0.997564077, 0, -0.0697564706, 0, 1, 0, 0.0697564706, 0, 0.997564077), new(59.0200806, 174.349854, 3.23012543))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-0.124966383, 263.126404, 237.607864, 0.948323667, 0, -0.317304641, 0, 1, 0, 0.317304641, 0, 0.948323667), new(17.7299881, 319.999939, 105.929977))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-13.9006824, 263.126404, 334.261169, 0.998134792, 0, 0.0610485412, 0, 1, 0, -0.0610485412, 0, 0.998134792), new(16.7299881, 319.999939, 102.700035))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(12.5065136, 263.126404, 193.714981, 0.997564077, 0, 0.0697564706, 0, 1, 0, -0.0697564706, 0, 0.997564077), new(10.2299871, 319.999939, 105.929977))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-23.2540989, 263.126404, 130.036514, -0.0958457589, -0.00000000837910274, -0.995396197, -0.000000000402479827, 1, -0.00000000837910274, 0.995396197, -0.000000000402479827, -0.0958457589), new(10.2299871, 319.999939, 108.449997))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-182.51709, 263.126404, 105.839249, 0.113203242, 0, -0.993571877, 0, 1, 0, 0.993571877, 0, 0.113203242), new(93.6899948, 319.999939, 94.2900009))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-210.425171, 225.446411, 136.269073, 0.688354611, 0, -0.725374341, 0, 1, 0, 0.725374341, 0, 0.688354611), new(37.7000008, 244.639954, 70.2799683))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-240.888153, 225.446411, 204.484818, -1, -0.0000000874227766, 0, -0.0000000874227766, 1, -0.0000000874227766, 0.00000000000000764274186, -0.0000000874227766, -1), new(37.7000008, 244.639954, 125.269974))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-242.00853, 223.686432, 287.601959, -0.99984771, -0.000000087409461, 0.0174524058, -0.0000000889485108, 1, -0.000000087409461, -0.0174524058, -0.0000000889485108, -0.99984771), new(84.8199768, 241.119949, 65.279953))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-266.261414, 223.686432, 329.667603, -0.737277329, -0.0000000644548308, 0.675590158, -0.000000146484751, 1, -0.0000000644548308, -0.675590158, -0.000000146484751, -0.737277329), new(84.2599869, 241.119949, 103.149963))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-171.303024, 263.126404, 7.99746418, 0.999961913, 0, -0.00872653536, 0, 1, 0, 0.00872653536, 0, 0.999961913), new(18.7299881, 319.999939, 135.039978))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-186.983673, 308.136475, -85.8008804, 0.878817141, 0, 0.477158755, 0, 1, 0, -0.477158755, 0, 0.878817141), new(15.7299871, 229.979904, 62.4799805))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-228.494202, 263.126404, -183.719955, 0.999961913, 0, -0.00872653536, 0, 1, 0, 0.00872653536, 0, 0.999961913), new(10.2299871, 319.999939, 135.039978))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-216.488495, 308.136475, -116.623718, 0.507538378, 0, 0.861629128, 0, 1, 0, -0.861629128, 0, 0.507538378), new(14.2299871, 229.979904, 31.0399818))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-180.638794, 263.126404, -276.830627, 0.995396197, 0, 0.0958457515, 0, 1, 0, -0.0958457515, 0, 0.995396197), new(113.549988, 319.999939, 97.3899994))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-54.6073608, 263.126404, 74.6437073, 0.891006529, 0, -0.453990489, 0, 1, 0, 0.453990489, 0, 0.891006529), new(14.7299871, 319.999939, 115.449997))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-37.863369, 263.126404, -4.13345909, 0.999961913, 0, -0.00872653536, 0, 1, 0, 0.00872653536, 0, 0.999961913), new(10.2299871, 319.999939, 108.449997))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-31.8706627, 263.126404, -72.4572144, 0.945518553, 0, -0.32556814, 0, 1, 0, 0.32556814, 0, 0.945518553), new(10.2299871, 319.999939, 35.8099937))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-7.3540988, 263.126404, -107.615921, 0.713250458, 0, -0.700909257, 0, 1, 0, 0.700909257, 0, 0.713250458), new(10.2299871, 319.999939, 58.8699951))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(5.32070923, 263.126404, -181.679382, 0.999961913, 0, -0.00872653536, 0, 1, 0, 0.00872653536, 0, 0.999961913), new(10.2299871, 319.999939, 135.039978))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-23.2827835, 263.126404, -230.279099, 0.32556814, 0, 0.945518553, 0, 1, 0, -0.945518553, 0, 0.32556814), new(29.2299881, 319.999939, 142.539978))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-115.024994, 241.249969, -414.445007, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(190.049988, 2.49993896, 169.889999))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-209.274994, 249.999969, -366.445007, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(3.54998779, 19.999939, 20.8899994))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-109.024994, 252.035263, -308.551788, 1, 0, 0, 0, 0.906307757, 0.42261827, 0, -0.42261827, 0.906307757), new(48.0499878, 1.99993896, 61.8899994))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-109.024994, 268.374207, -263.68924, 1, 0, 0, 0, 0.974370062, 0.224951088, 0, -0.224951088, 0.974370062), new(48.0499878, 2.49993896, 36.8899994))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-109.024994, 270.498352, -240.767548, 1, 0, 0, 0, 0.9510566, -0.309016943, 0, 0.309016943, 0.9510566), new(48.0499878, 2.49993896, 11.8899994))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-114.774994, 255.249969, -85.0700073, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(232.549988, 30.499939, 309.140015))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-53.2749939, 255.999969, -24.6950073, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(109.549988, 31.999939, 59.3900146))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-28.5249939, 273.499969, 15.3049927, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(60.0499878, 66.999939, 139.390015))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-80.7749939, 267.999969, 54.8049927, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(164.549988, 6.99993896, 23.3900146))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-154.774994, 279.999969, 52.0549927, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(16.5499878, 30.999939, 28.8900146))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-137.024994, 267.999969, 14.5549927, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(39.0499878, 6.99993896, 29.8900146))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-167.024994, 267.749969, -113.406532, 0.866025388, 0, 0.5, 0, 1, 0, -0.5, 0, 0.866025388), new(39.0499878, 6.49993896, 103.890015))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-170.580597, 271.249969, -111.065025, 0.866025388, 0, 0.5, 0, 1, 0, -0.5, 0, 0.866025388), new(24.5499878, 1.49993896, 92.3900146))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-176.571625, 271.749969, -119.441788, 0.866025388, 0, 0.5, 0, 1, 0, -0.5, 0, 0.866025388), new(15.5499878, 2.49993896, 63.8900146))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-155.324982, 270.499908, -185.195007, 1, 0, 0, 0, 1, 0, 0, 0, 0.99999994), new(35.5499878, 1.99993896, 36.3900146))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-158.574982, 270.999908, -193.195007, 1, 0, 0, 0, 1, 0, 0, 0, 0.99999994), new(21.0499878, 2.99993896, 16.3900146))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-160.074982, 271.249908, -193.695007, 1, 0, 0, 0, 1, 0, 0, 0, 0.99999994), new(10.0499878, 3.49993896, 7.39001465))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-47.5749817, 270.499908, -162.195007, 1, 0, 0, 0, 1, 0, 0, 0, 0.99999994), new(70.0499878, 1.99993896, 118.390015))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-49.8249817, 270.999908, -181.695007, 1, 0, 0, 0, 1, 0, 0, 0, 0.99999994), new(52.5499878, 2.99993896, 55.3900146))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-141.574982, 287.499908, -233.195007, 1, 0, 0, 0, 1, 0, 0, 0, 0.99999994), new(55.0499878, 35.999939, 15.3900146))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-7.88667679, 275.376404, -116.717194, 0.999961913, 0, -0.0087265335, 0, 1, 0, 0.00872653536, 0, 0.999961793), new(15.0499878, 22.499939, 30.8900146))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-216.351822, 277.376404, -126.646851, 0.999961913, 0, -0.00872653257, 0, 1, 0, 0.0087265363, 0, 0.999961674), new(15.0499878, 16.499939, 19.8900146))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-220.909836, 275.376404, -219.818344, 0.995396256, 0, 0.0958457068, 0, 1, 0, -0.0958457515, 0, 0.99539578), new(16.5499878, 13.499939, 8.39001465))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-103.524994, 251.527222, 104.294586, 1, 0, 0, 0, 0.906307757, -0.42261827, 0, 0.42261827, 0.906307757), new(99.0499878, 5.99993896, 78.8900146))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-108.024994, 236.249969, 298.054993, 1, 0, 0, 0, 0.99999994, 0, 0, 0, 0.99999994), new(245.049988, 4.49993896, 338.890015))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-115.274994, 236.749969, 332.554993, 1, 0, 0, 0, 0.99999994, 0, 0, 0, 0.99999994), new(39.5499878, 5.49993896, 40.8900146))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-114.524994, 237.249969, 331.554993, 1, 0, 0, 0, 0.99999994, 0, 0, 0, 0.99999994), new(24.0499878, 6.49993896, 21.8900146))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-201.774994, 236.749969, 305.804993, 1, 0, 0, 0, 0.99999994, 0, 0, 0, 0.99999994), new(59.5499878, 5.49993896, 149.390015))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-206.274994, 259.249969, 305.054993, 1, 0, 0, 0, 0.99999994, 0, 0, 0, 0.99999994), new(50.5499878, 50.499939, 148.890015))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-195.774994, 236.749969, 253.054993, 1, 0, 0, 0, 0.99999994, 0, 0, 0, 0.99999994), new(71.5499878, 5.49993896, 36.8900146))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-201.024994, 237.249969, 251.054993, 1, 0, 0, 0, 0.99999994, 0, 0, 0, 0.99999994), new(61.0499878, 6.49993896, 24.8900146))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-60.7749939, 236.749969, 330.554993, 1, 0, 0, 0, 0.99999994, 0, 0, 0, 0.99999994), new(47.5499878, 5.49993896, 44.8900146))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-61.5249939, 237.249969, 331.554993, 1, 0, 0, 0, 0.99999994, 0, 0, 0, 0.99999994), new(20.0499878, 6.49993896, 17.8900146))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-29.0249939, 236.749969, 293.554993, 1, 0, 0, 0, 0.99999994, 0, 0, 0, 0.99999994), new(30.0499878, 5.49993896, 32.8900146))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-26.0249939, 237.249969, 293.804993, 1, 0, 0, 0, 0.99999994, 0, 0, 0, 0.99999994), new(11.0499878, 6.49993896, 23.3900146))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-16.2749939, 236.749969, 210.804993, 1, 0, 0, 0, 0.99999994, 0, 0, 0, 0.99999994), new(35.5499878, 5.49993896, 34.3900146))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-69.3916397, 236.499969, 184.50386, 0.96126169, 0, 0.275637299, 0, 0.999999821, 0, -0.275637329, 0, 0.961261511), new(84.0499878, 4.99993896, 38.8900146))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-66.1986313, 236.749969, 183.848358, 0.96126169, 0, 0.275637299, 0, 0.999999821, 0, -0.275637329, 0, 0.961261511), new(57.5499878, 5.49993896, 30.3900146))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-62.4224892, 236.999969, 182.505493, 0.96126169, 0, 0.275637299, 0, 0.999999821, 0, -0.275637329, 0, 0.961261511), new(49.5499878, 5.99993896, 24.8900146))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-63.9332924, 237.249969, 182.678635, 0.96126169, 0, 0.275637299, 0, 0.999999821, 0, -0.275637329, 0, 0.961261511), new(29.5499878, 6.49993896, 19.3900146))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-62.1821709, 237.499969, 182.436569, 0.96126169, 0, 0.275637299, 0, 0.999999821, 0, -0.275637329, 0, 0.961261511), new(19.0499878, 6.99993896, 13.8900146))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-103.524994, 238.727341, 132.97348, 1, 0, 0, 0, 0.965925813, -0.258819044, 0, 0.258819044, 0.965925813), new(99.0499878, 9.49993896, 32.3900146))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-130.324982, 238.999908, 150.914978, 1, 0, 0, 0, 0.999999881, -0.0000000149011612, 0, 0, 0.999999821), new(45.5499878, 0.999940872, 19.3900146))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-131.824982, 239.499908, 147.914978, 1, 0, 0, 0, 0.999999881, -0.0000000149011612, 0, 0, 0.999999821), new(34.5499878, 1.99994087, 13.3900146))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-134.824982, 239.749908, 145.914978, 1, 0, 0, 0, 0.999999881, -0.0000000149011612, 0, 0, 0.999999821), new(22.5499878, 2.49994087, 9.39001465))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-2.22501421, 269.749908, 145.414978, 0.999999881, 0, 0.0000000298023224, 0, 0.999999583, 0, 0.0000000298023224, 0, 0.999999583), new(18.5499878, 62.499939, 21.3900146))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-216.172623, 238.749939, 167.096695, 0.788009822, 0, -0.615660012, 0, 0.999997318, 0, 0.615660667, 0, 0.788008869), new(18.5499878, 0.499946952, 55.3900146))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-217.157623, 238.999939, 166.327118, 0.788009822, 0, -0.615660012, 0, 0.999997318, 0, 0.615660667, 0, 0.788008869), new(16.0499878, 0.999946952, 55.3900146))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-217.748642, 239.249939, 165.865372, 0.788009822, 0, -0.615660012, 0, 0.999997318, 0, 0.615660667, 0, 0.788008869), new(14.5499878, 1.49994695, 55.3900146))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-205.281525, 241.749939, 149.908188, 0.788009822, 0, -0.615660012, 0, 0.999997318, 0, 0.615660667, 0, 0.788008869), new(14.5499878, 6.49994707, 14.8900146))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-176.024994, 236.499969, 425.554993, 1, 0, 0, 0, 0.99999994, 0, 0, 0, 0.99999994), new(26.0499878, 4.99993896, 46.8900146))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-177.524994, 236.749969, 425.054993, 1, 0, 0, 0, 0.99999994, 0, 0, 0, 0.99999994), new(23.0499878, 5.49993896, 43.8900146))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-178.774994, 237.249969, 425.804993, 1, 0, 0, 0, 0.99999994, 0, 0, 0, 0.99999994), new(20.5499878, 6.49993896, 38.3900146))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-180.774994, 237.499969, 429.054993, 1, 0, 0, 0, 0.99999994, 0, 0, 0, 0.99999994), new(16.5499878, 6.99993896, 24.8900146))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-181.774994, 237.999969, 430.304993, 1, 0, 0, 0, 0.99999994, 0, 0, 0, 0.99999994), new(14.5499878, 7.99993896, 18.3900146))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-124.774994, 236.499969, 415.804993, 1, 0, 0, 0, 0.99999994, 0, 0, 0, 0.99999994), new(15.5499878, 4.99993896, 38.3900146))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-123.524994, 236.749969, 416.554993, 1, 0, 0, 0, 0.99999994, 0, 0, 0, 0.99999994), new(13.0499878, 5.49993896, 25.8900146))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-121.774994, 236.999969, 416.304993, 1, 0, 0, 0, 0.99999994, 0, 0, 0, 0.99999994), new(9.54998779, 5.99993896, 19.3900146))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-89.5749817, 280.749908, -237.695007, 1, 0, 0, 0, 1, 0, 0, 0, 0.99999994), new(7.04998779, 22.499939, 6.39001465))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-50.7568512, 263.126404, -284.197937, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(82.5499878, 319.999939, 92.3899994))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-84.7568512, 263.126404, -250.447937, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(21.5499878, 319.999939, 24.8899994))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-20.2568512, 263.126404, -418.197937, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(4.54998779, 319.999939, 181.389999))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-212.506851, 263.126404, -418.197937, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(13.0499878, 319.999939, 181.389999))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-168.256851, 263.126404, -328.947937, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(79.5499878, 319.999939, 2.88999939))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-163.006851, 263.126404, -572.947937, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(90.0499878, 319.999939, 150.889999))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-53.5068512, 263.126404, -534.947937, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(71.0499878, 319.999939, 74.8899994))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-75.8494415, 263.126404, -590.692261, -0.258819044, 0, -0.965925753, 0, 1, 0, 0.965925753, 0, -0.258819044), new(50.5499878, 319.999939, 10.3899994))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-47.9917145, 263.126404, -617.715088, -0.898792207, 0, -0.43836987, 0, 1, 0, 0.43836987, 0, -0.898792207), new(50.5499878, 319.999939, 10.3899994))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-5.61179876, 263.126404, -643.846008, -0.798630357, 0, -0.601810753, 0, 1, 0, 0.601810753, 0, -0.798630357), new(50.5499878, 319.999939, 10.3899994))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(21.596756, 263.126404, -678.58075, -0.390731424, 0, -0.920504749, 0, 1, 0, 0.920504749, 0, -0.390731424), new(48.5499878, 319.999939, 12.3899994))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(32.232254, 263.126404, -711.717529, -0.224951372, 0, -0.974370062, 0, 1, 0, 0.974370062, 0, -0.224951372), new(33.5499878, 319.999939, 17.8899994))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-91.2977295, 250.376404, -663.801025, 0.882947803, 0, 0.469471604, 0, 1, 0, -0.469471604, 0, 0.882947803), new(121.049988, 76.499939, 17.8899994))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-35.862896, 250.376404, -706.077393, 0.374607325, 0, 0.927185595, 0, 1, 0, -0.927185595, 0, 0.374607325), new(38.5499878, 76.499939, 17.8899994))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-36.112896, 250.376404, -724.327393, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(24.0499878, 76.499939, 7.38999939))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(46.887104, 250.376404, -749.077393, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(5.04998779, 76.499939, 56.8899994))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(35.387104, 250.376404, -795.827393, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(28.0499878, 76.499939, 47.3899994))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-37.862896, 250.376404, -787.827393, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(27.5499878, 76.499939, 38.3899994))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-48.362896, 250.376404, -748.077393, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(6.54998779, 76.499939, 42.8899994))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-38.4214478, 250.376404, -825.885254, 0.882947505, 0, 0.469471455, 0, 1, 0, -0.469471455, 0, 0.882947505), new(6.04998779, 76.499939, 47.8899994))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(1.74190998, 250.376404, -838.746277, 0.882947505, 0, 0.469471455, 0, 1, 0, -0.469471455, 0, 0.882947505), new(14.0499878, 76.499939, 120.889999))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-78.6714478, 250.376404, -824.135254, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(58.5499878, 76.499939, 44.3899994))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-180.171448, 250.376404, -824.135254, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(120.549988, 76.499939, 44.3899994))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-187.421448, 250.376404, -892.635254, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(95.0499878, 76.499939, 13.3899994))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-114.421448, 250.376404, -892.635254, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(25.0499878, 76.499939, 13.3899994))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-58.4214478, 250.376404, -892.635254, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(55.0499878, 76.499939, 13.3899994))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-32.5747032, 250.376404, -881.752502, 0.866025448, 0, -0.5, 0, 1, 0, 0.5, 0, 0.866025448), new(48.5499878, 76.499939, 13.3899994))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-123.171448, 250.376404, -901.135254, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(80.5499878, 76.499939, 0.38999939))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-140.421448, 250.376404, -897.885254, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(46.0499878, 76.499939, 6.88999939))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-116.171448, 250.376404, -828.635254, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(28.5499878, 76.499939, 10.3899994))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-530.105103, 279.979858, -1092.07043, 0.999390841, 0, -0.0348994955, 0, 1, 0, 0.0348994955, 0, 0.999390841), new(66.3700256, 165.859863, 74.1800003))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-434.260559, 279.979858, -1090.26013, 0.999390841, 0, -0.0348994955, 0, 1, 0, 0.0348994955, 0, 0.999390841), new(66.3700256, 165.859863, 75.3499756))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-623.851563, 279.979858, -1429.71814, -0.719339788, -0.0000000628866843, 0.694658399, -0.000000148151742, 1, -0.0000000628866843, -0.694658399, -0.000000148151742, -0.719339788), new(159.419998, 165.859863, 17.4799919))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-587.972534, 279.979858, -1466.33179, -0.719339788, -0.0000000628866843, 0.694658399, -0.000000148151742, 1, -0.0000000628866843, -0.694658399, -0.000000148151742, -0.719339788), new(160.169998, 165.859863, 44.1299934))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-510.793091, 279.979858, -1412.05334, -0.91354543, -0.0000000798646766, 0.406736642, -0.000000122980822, 1, -0.0000000798646766, -0.406736642, -0.000000122980822, -0.91354543), new(149.439972, 165.859863, 22.9799919))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-471.971405, 279.979858, -1355.68689, -0.0174523834, -0.00000000152573587, 0.99984771, -0.000000174832238, 1, -0.00000000152573587, -0.99984771, -0.000000174832238, -0.0174523834), new(145.919983, 165.859863, 19.7599926))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-585.297424, 279.979858, -1324.81335, -0.182235524, -0.0000000159315352, 0.98325491, -0.00000017338165, 1, -0.0000000159315352, -0.98325491, -0.00000017338165, -0.182235524), new(128.960007, 165.859863, 42.9799919))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-588.963806, 279.979858, -1300.72192, 0.999390841, 0, -0.0348994955, 0, 1, 0, 0.0348994955, 0, 0.999390841), new(142.960007, 165.859863, 17.4799919))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-703.672302, 279.979858, -1446.30786, -0.669130564, -0.0000000584972533, -0.74314487, -0.0000000224549908, 1, -0.0000000584972533, 0.74314487, -0.0000000224549908, -0.669130564), new(69.8000183, 165.859863, 17.4799919))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-756.852478, 279.979858, -1402.3075, -0.870355666, -0.0000000760889094, -0.492423564, -0.000000044373742, 1, -0.0000000760889094, 0.492423564, -0.000000044373742, -0.870355666), new(69.8000183, 165.859863, 17.4799919))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-797.608215, 279.979858, -1387.88354, -0.996917307, -0.0000000871532819, -0.0784590989, -0.000000080563666, 1, -0.0000000871532819, 0.0784590989, -0.000000080563666, -0.996917307), new(55.3900223, 165.859863, 17.4799919))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-820.038269, 279.979858, -1385.85034, -0.662620068, -0.0000000579280872, 0.748955727, -0.000000152898565, 1, -0.0000000579280872, -0.748955727, -0.000000152898565, -0.662620068), new(82.0700302, 165.859863, 17.4799919))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-841.949463, 279.979858, -1427.98669, 0.078459084, 0, -0.996917307, 0, 1, 0, 0.996917307, 0, 0.078459084), new(55.3900223, 165.859863, 17.4799919))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-834.237122, 279.979858, -1469.92981, -0.42261824, -0.0000000369464601, -0.906307817, -0.00000000819083112, 1, -0.0000000369464601, 0.906307817, -0.00000000819083112, -0.42261824), new(86.6100311, 165.859863, 17.4799919))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-767.177551, 279.979858, -1564.18726, -0.656059027, -0.0000000573545016, -0.754709542, -0.0000000214439737, 1, -0.0000000573545016, 0.754709542, -0.0000000214439737, -0.656059027), new(160.029999, 165.859863, 17.4799919))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-720.77832, 279.979858, -1597.55005, -0.656059027, -0.0000000573545016, -0.754709542, -0.0000000214439737, 1, -0.0000000573545016, 0.754709542, -0.0000000214439737, -0.656059027), new(57.8500061, 165.859863, 43.7400017))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-650.672546, 279.979858, -1540.46497, -0.656059027, -0.0000000573545016, -0.754709542, -0.0000000214439737, 1, -0.0000000573545016, 0.754709542, -0.0000000214439737, -0.656059027), new(57.8500061, 165.859863, 43.7400017))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-686.894653, 279.979858, -1577.92639, -0.656059027, -0.0000000573545016, -0.754709542, -0.0000000214439737, 1, -0.0000000573545016, 0.754709542, -0.0000000214439737, -0.656059027), new(57.8500061, 165.859863, 63.2200089))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-773.282104, 285.979858, -1474.0929, -0.669130683, 0, -0.74314481, 0, 1, 0, 0.74314481, 0, -0.669130683), new(214.029999, 2.85986328, 126.479996))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-613.74707, 269.706024, -1446.57446, -0.694678783, 0.11874482, -0.709454238, -0.0000441642478, 0.986274898, 0.165120974, 0.71931982, 0.114737399, -0.685142875), new(22.5299988, 5.10986328, 165.479996))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-527.871521, 279.979858, -1234.82935, 0.999390841, 0, -0.0348994955, 0, 1, 0, 0.0348994955, 0, 0.999390841), new(60.8700256, 165.859863, 61.6799927))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-558.849976, 279.979858, -1109.59131, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(1.87002563, 165.859863, 191.179993))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-417.599976, 279.979858, -1110.34131, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(1.37002563, 165.859863, 189.679993))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-431.140198, 279.979858, -1251.24927, 0.999390841, 0, -0.0348994955, 0, 1, 0, 0.0348994955, 0, 0.999390841), new(71.3700256, 165.859863, 93.3499756))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-494.599976, 243.729858, -1086.84131, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(161.370026, 29.3598633, 664.679993))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-439.099976, 279.979858, -970.341309, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(50.3700256, 165.859863, 95.6799927))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-536.349976, 279.979858, -973.341309, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(68.8700256, 165.859863, 89.6799927))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-528.849976, 305.979858, -872.341309, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(83.8700256, 113.859863, 132.679993))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-522.703003, 305.979858, -802.900574, 0.965925813, 0, 0.258819044, 0, 1, 0, -0.258819044, 0, 0.965925813), new(83.8700256, 113.859863, 87.1799927))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-510.382385, 305.979858, -783.183533, 0.848048031, 0, 0.529919267, 0, 1, 0, -0.529919267, 0, 0.848048031), new(83.8700256, 113.859863, 133.679993))
    wait2 = fn12
    new = Vector3.new
    wait2(CFrame.new(-498.169495, 305.979858, -768.628662, 0.766044259, 0, 0.642787516, 0, 1, 0, -0.642787516, 0, 0.766044259), new(83.8700256, 113.859863, 171.679993))
    wait2 = fn12
    CFrame144 = CFrame
    do
        new = Vector3.new
        wait2(CFrame.new(-483.661346, 305.979858, -758.842712, 0.559192538, 0, 0.82903707, 0, 1, 0, -0.82903707, 0, 0.559192538), new(83.8700256, 113.859863, 206.679993))
        wait2 = fn12
        new = Vector3.new
        wait2(CFrame.new(-364.621796, 305.979858, -708.448608, 0.0174524225, 0, 0.99984771, 0, 1, 0, -0.99984771, 0, 0.0174524225), new(83.8700256, 113.859863, 116.679993))
        wait2 = fn12
        new = Vector3.new
        wait2(CFrame.new(-340.879913, 305.979858, -765.881897, -0.453990519, 0, 0.891006529, 0, 1, 0, -0.891006529, 0, -0.453990519), new(8.37002563, 113.859863, 168.179993))
        wait2 = fn12
        new = Vector3.new
        wait2(CFrame.new(-329.829071, 295.979858, -781.740417, -0.766044497, 0, 0.642787576, 0, 1, 0, -0.642787576, 0, -0.766044497), new(7.37002563, 133.859863, 194.179993))
        wait2 = fn12
        new = Vector3.new
        wait2(CFrame.new(-474.099976, 244.229858, -797.341309, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(257.370026, 30.3598633, 85.6799927))
        wait2 = fn12
        new = Vector3.new
        wait2(CFrame.new(-523.349976, 305.979858, -827.341309, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(94.8700256, 113.859863, 42.6799927))
        wait2 = fn12
        new = Vector3.new
        wait2(CFrame.new(-475.599976, 244.729858, -791.841309, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(254.370026, 31.3598633, 74.6799927))
        wait2 = fn12
        new = Vector3.new
        wait2(CFrame.new(-477.599976, 245.229858, -787.341309, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(250.370026, 32.3598633, 65.6799927))
        wait2 = fn12
        new = Vector3.new
        wait2(CFrame.new(-478.599976, 245.479858, -784.341309, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(248.370026, 32.8598633, 59.6799927))
        wait2 = fn12
        new = Vector3.new
        wait2(CFrame.new(-478.599976, 245.729858, -781.841309, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(248.370026, 33.3598633, 54.6799927))
        wait2 = fn12
        new = Vector3.new
        wait2(CFrame.new(-439.849976, 272.229858, -883.341309, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(51.8700256, 86.3598633, 123.679993))
        wait2 = fn12
        new = Vector3.new
        wait2(CFrame.new(-379.849976, 272.229858, -832.841309, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(68.8700256, 86.3598633, 19.6799927))
        wait2 = fn12
        new = Vector3.new
        wait2(CFrame.new(-325.158051, 241.062012, -822.414978, 0.789027095, 0.334922045, 0.515037596, -0.390731275, 0.920504749, 0.0000000484287739, -0.474095762, -0.201241508, 0.857167423), new(9.37002563, 14.8598633, 8.17999268))
        wait2 = fn12
        new = Vector3.new
        wait2(CFrame.new(-345.652191, 245.233566, -781.809937, 0.850778162, 0.104462422, 0.515038013, -0.121869348, 0.992546141, 0, -0.511199117, -0.0627673566, 0.857167304), new(31.3700256, 33.3598633, 54.6799927))
        wait2 = fn12
        new = Vector3.new
        wait2(CFrame.new(-345.599976, 272.229858, -831.341309, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(0.370025635, 86.3598633, 22.6799927))
        wait2 = fn12
        new = Vector3.new
        wait2(CFrame.new(-341.921783, 249.663269, -835.159546, 0.848048091, 0, 0.529919267, 0, 1, 0, -0.529919267, 0, 0.848048091), new(29.3700256, 76.8598633, 32.1799927))
        wait2 = fn12
        new = Vector3.new
        wait2(CFrame.new(-320.835754, 230.047226, -824.571289, 0.776302516, 0.0652871206, 0.626969218, -0.284233958, 0.92402339, 0.255714566, -0.562643945, -0.37671876, 0.735880792), new(52.3700256, 31.3598633, 95.6799927))
        wait2 = fn12
        new = Vector3.new
        wait2(CFrame.new(-289.109406, 220.88858, -848.419983, 0.778962135, 0.0109720025, 0.626974881, -0.219083488, 0.941601098, 0.255714387, -0.587554574, -0.336551666, 0.735875428), new(50.8700256, 30.8598633, 95.6799927))
        wait2 = fn12
        new = Vector3.new
        wait2(CFrame.new(-89.6850128, 249.173721, -513.710205, 1, 0, 0, 0, 0.994521797, 0.104528457, 0, -0.104528457, 0.994521797), new(5.37002563, 16.8598633, 30.6799927))
        wait2 = fn12
        new = Vector3.new
        wait2(CFrame.new(-510.848236, 279.979858, -1284.52026, 0.798635483, 0, 0.601814926, 0, 1, 0, -0.601814926, 0, 0.798635483), new(12.8700256, 165.859863, 39.6799927))
        wait2 = fn12
        new = Vector3.new
        wait2(CFrame.new(-510.486816, 279.979858, -1279.47107, 0.798635483, 0, 0.601814926, 0, 1, 0, -0.601814926, 0, 0.798635483), new(7.37002563, 165.859863, 42.1799927))
        wait2 = fn12
        new = Vector3.new
        wait2(CFrame.new(-512.099976, 273.589722, -1203.34131, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(15.3700256, 30.3598633, 9.67999268))
        wait2 = fn12
        new = Vector3.new
        wait2(CFrame.new(-450.099976, 273.589722, -1203.34131, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(20.3700256, 30.3598633, 9.67999268))
        wait2 = fn12
        new = Vector3.new
        wait2(CFrame.new(-294.008087, 223.338501, -850.775452, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(25.3700256, 23.8598633, 15.1799927))
        wait2 = fn12
        new = Vector3.new
        wait2(CFrame.new(-328.758087, 223.338501, -860.025452, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(18.8700256, 23.8598633, 7.67999268))
        wait2 = fn12
        new = Vector3.new
        wait2(CFrame.new(-33.4668579, 239.946518, -446.482941, 1, 0, 0, 0, 0.999999762, 0, 0, 0, 0.999999762), new(21.8700256, 7.35986328, 26.1799927))
        wait2 = fn12
        new = Vector3.new
        wait2(CFrame.new(-24.9668579, 249.946518, -446.232941, 1, 0, 0, 0, 0.999999762, 0, 0, 0, 0.999999762), new(4.87002563, 27.3598633, 20.6799927))
        wait2 = fn12
        new = Vector3.new
        wait2(CFrame.new(-327.824738, 237.437775, -801.812622, 0.762220681, 0.371759921, 0.529919147, -0.438371092, 0.898793995, 0.0000000149011612, -0.476288557, -0.232301384, 0.84804821), new(27.8700256, 31.8598633, 64.6799927))
        wait2 = fn12
        new = Vector3.new
        wait2(CFrame.new(-336.758087, 222.838501, -903.525452, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(159.870026, 22.8598633, 147.679993))
        wait2 = fn12
        new = Vector3.new
        wait2(CFrame.new(-339.008087, 269.588501, -954.775452, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(164.370026, 116.359863, 45.1799927))
        wait2 = fn12
        new = Vector3.new
        wait2(CFrame.new(-271.008087, 243.088501, -925.025452, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(28.3700256, 63.3598633, 104.679993))
        wait2 = fn12
        new = Vector3.new
        wait2(CFrame.new(-399.008087, 223.338501, -934.775452, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(35.3700256, 23.8598633, 85.1799927))
        wait2 = fn12
        CFrame176 = CFrame
        do
            new = Vector3.new
            wait2(CFrame.new(-165.758087, 222.838501, -867.025452, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(197.870026, 22.8598633, 69.6799927))
            wait2 = fn12
            new = Vector3.new
            wait2(CFrame.new(-253.171448, 250.376404, -830.885254, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(38.5499878, 76.499939, 57.8899994))
            wait2 = fn12
            new = Vector3.new
            wait2(CFrame.new(-253.171448, 250.376404, -883.635254, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(38.5499878, 76.499939, 21.3899994))
            wait2 = fn12
            new = Vector3.new
            wait2(CFrame.new(-483.418579, 267.041748, -1068.15332, -0.999052703, -0.0155198928, 0.040654961, 0.00000586081296, 0.934192657, 0.356768906, -0.04351658, 0.356431216, -0.933307588), new(31.6913509, 2.7721417, 4.24422979))
            wait2 = fn12
            new = Vector3.new
            wait2(CFrame.new(-483.981842, 260.92804, -1055.25232, -0.999047458, -0.0207527075, 0.0383878089, 0.000000914558768, 0.879672229, 0.475580454, -0.0436382741, 0.475127459, -0.878834188), new(31.6913509, 2.74081826, 18.896841))
            wait2 = fn12
            new = Vector3.new
            wait2(CFrame.new(-483.538757, 266.034851, -1065.40332, -0.999046981, -0.0144734327, 0.0411781222, 0.0000283131376, 0.943206012, 0.332208306, -0.0436476469, 0.331892908, -0.942306757), new(31.6913509, 2.76432514, 4.3225441))
            wait2 = fn12
            new = Vector3.new
            wait2(CFrame.new(-481.38623, 266.034943, -1114.70557, 0.999046981, 0.0144734401, -0.0411781222, 0.0000283066183, 0.943206012, 0.332208335, 0.0436476506, -0.331892937, 0.942306757), new(31.6913509, 2.76432514, 4.3225441))
            wait2 = fn12
            new = Vector3.new
            wait2(CFrame.new(-480.943359, 260.928314, -1124.85657, 0.999047458, 0.0207526181, -0.0383878089, 0.000000990927219, 0.879672289, 0.475580454, 0.0436382294, -0.475127459, 0.878834248), new(31.6913509, 2.74081826, 18.896841))
            wait2 = fn12
            new = Vector3.new
            wait2(CFrame.new(-482.463654, 268.856995, -1090.03271, 0.999048233, 0, -0.0436193869, 0, 1, 0, 0.0436193869, 0, 0.999048233), new(31.6913509, 2.74081826, 23.9508228))
            wait2 = fn12
            new = Vector3.new
            wait2(CFrame.new(-481.854034, 268.718964, -1104.005, 0.999045253, 0.00244113314, -0.0436193869, -0.0000733807683, 0.99853003, 0.0542014502, 0.0436875783, -0.0541465022, 0.997576892), new(31.6913509, 2.74081826, 4.3225441))
            wait2 = fn12
            new = Vector3.new
            wait2(CFrame.new(-483.248901, 268.208527, -1072.04712, -0.999044776, -0.00906737149, 0.0427475348, 0.0000939015299, 0.977787733, 0.209597498, -0.043698512, 0.209401295, -0.976852834), new(31.6913509, 2.74081826, 4.3225441))
            wait2 = fn12
            new = Vector3.new
            wait2(CFrame.new(-481.506134, 267.04184, -1111.95569, 0.999052703, 0.0155199626, -0.040654961, 0.00000579282641, 0.934192657, 0.356768847, 0.0435166061, -0.356431156, 0.933307588), new(31.6913509, 2.7721417, 4.24422979))
            wait2 = fn12
            new = Vector3.new
            wait2(CFrame.new(-481.676361, 268.208527, -1108.06177, 0.999044776, 0.00906729046, -0.0427475348, 0.0000939778984, 0.977787733, 0.209597453, 0.0436984971, -0.20940125, 0.976852894), new(31.6913509, 2.74081826, 4.3225441))
            wait2 = fn12
            new = Vector3.new
            wait2(CFrame.new(-483.071716, 268.719055, -1076.10388, -0.999045253, -0.00244113663, 0.0436193869, -0.0000733849593, 0.99853003, 0.0542014316, -0.0436875783, 0.0541464835, -0.997576892), new(31.6913509, 2.74081826, 4.3225441))
            wait2 = fn12
            new = Vector3.new
            wait2(CFrame.new(-483.349976, 244.229858, -1089.84131, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(39.8700256, 30.3598633, 91.6799927))
            wait2 = fn12
            new = Vector3.new
            wait2(CFrame.new(-367.75824, 249.663269, -845.841492, 0.848048091, 0, 0.529919267, 0, 1, 0, -0.529919267, 0, 0.848048091), new(34.8700256, 76.8598633, 13.6799927))
            wait2 = fn12
            new = Vector3.new
            wait2(CFrame.new(-43.2580872, 223.338501, -867.025452, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(50.8700256, 23.8598633, 69.6799927))
            wait2 = fn12
            new = Vector3.new
            wait2(CFrame.new(-40.5080872, 223.838501, -867.025452, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(47.3700256, 24.8598633, 69.6799927))
            wait2 = fn12
            new = Vector3.new
            wait2(CFrame.new(4.49191284, 224.838501, -762.025452, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(99.3700256, 26.8598633, 124.679993))
            wait2 = fn12
            new = Vector3.new
            wait2(CFrame.new(-25.2580872, 224.338501, -852.025452, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(36.8700256, 25.8598633, 55.6799927))
            wait2 = fn12
            new = Vector3.new
            wait2(CFrame.new(-37.7580872, 237.588501, -825.775452, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(11.8700256, 52.3598633, 22.1799927))
            wait2 = fn12
            new = Vector3.new
            wait2(CFrame.new(10.7419128, 224.838501, -837.275452, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(86.8700256, 26.8598633, 50.1799927))
            wait2 = fn12
            new = Vector3.new
            wait2(CFrame.new(4.49191284, 224.338501, -703.525452, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(99.3700256, 25.8598633, 15.6799927))
            wait2 = fn12
            new = Vector3.new
            wait2(CFrame.new(4.49191284, 223.838501, -701.525452, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(99.3700256, 24.8598633, 19.6799927))
            wait2 = fn12
            new = Vector3.new
            wait2(CFrame.new(8.24191284, 223.338501, -667.775452, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(91.8700256, 23.8598633, 87.1799927))
            wait2 = fn12
            new = Vector3.new
            wait2(CFrame.new(-32.2580872, 223.088501, -637.275452, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(172.870026, 23.3598633, 148.179993))
            wait2 = fn12
            new = Vector3.new
            wait2(CFrame.new(-115.024994, 237.18399, -535.179443, 1, 0, 0, 0, 0.994521797, 0.104528457, 0, -0.104528457, 0.994521797), new(190.049988, 2.49993896, 75.8899994))
            wait2 = fn12
            new = Vector3.new
            wait2(CFrame.new(-110.508087, 223.338501, -580.775452, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(16.3700256, 23.8598633, 35.1799927))
            wait2 = fn12
            new = Vector3.new
            wait2(CFrame.new(14.4349861, 247.448364, -670.319519, 0.874619722, 0, -0.484809607, 0, 1, 0, 0.484809607, 0, 0.874619722), new(16.8700256, 24.3598633, 64.1799927))
            wait2 = fn12
            new = Vector3.new
            wait2(CFrame.new(-114.508087, 246.948364, -651.275452, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(13.3700256, 24.3598633, 42.1799927))
            wait2 = fn12
            new = Vector3.new
            wait2(CFrame.new(-327.09436, 240.060562, -797.918823, 0.789027095, 0.334922045, 0.515037596, -0.390731275, 0.920504749, 0.0000000484287739, -0.474095762, -0.201241508, 0.857167423), new(29.8700256, 28.8598633, 63.1799927))
            wait2 = fn12
            CFrame207 = CFrame
            local PathfindingService = CFrame207.new(-664.139648, 282.215668, -1495.0968, -0.691134691, 0.299709588, -0.657652676, 0, 0.909961283, 0.414693236, 0.722725987, 0.286608875, -0.628905833)
            new = Vector3.new
            wait2(PathfindingService, new(25.5299988, 5.60986328, 12.4799957))
            wait2 = wait
            PathfindingService = 0.1
            wait2(PathfindingService)
        end
    end
    wait2 = game
    new = "GetService"
    local result2 = wait2
    wait2 = result2[new](result2, "Workspace")
    wait2 = wait2.dungeon
    local room5 = wait2.room5
    room5 = room5.barrier
    new = "Destroy"
    result2 = room5
    result2[new](result2)
    if _G.destroy_map then
        local pairs2 = pairs
        local workspace2 = workspace
        local value, value2 = "GetChildren", workspace2
        local item = value2[value]
        for k, v in pairs2(item(value2)) do
            if (v.ClassName == "Model"
                or v.ClassName == "Part"
                or v.ClassName == "UnionOperation"
                or v.ClassName == "WedgePart")
                and v ~= game.Players.LocalPlayer.Character
                and v.Name ~= result3 then
                local value3, value4 = "Destroy", v
                value4[value3](value4)
            end
        end
    end
    while true do
        local game2, value5 = game, "GetService"
        local value6 = game2
        game2 = value6[value5](value6, "Workspace")
        game2 = game2.dungeon
        local room52 = game2.room5
        room52 = room52.enemyFolder
        value5 = "FindFirstChild"
        value6 = room52
        local item2 = value6[value5]
        if item2(value6, "Spider Queen") then
            break
        end
        wait(1)
    end
    while true do
        local game3, value7 = game, "GetService"
        local value8 = game3
        game3 = value8[value7](value8, "Workspace")
        game3 = game3.dungeon
        local room53 = game3.room5
        room53 = room53.enemyFolder
        value7 = "FindFirstChild"
        value8 = room53
        room53 = value8[value7](value8, "Spider Queen")
        value7 = "FindFirstChild"
        value8 = room53
        local item3 = value8[value7]
        if item3(value8, "HumanoidRootPart") then
            break
        end
        wait(1)
    end
    room5 = fn12
    result2 = CFrame.new(-198.633, 235.589, -866.15)
    new = Vector3.new
    room5 = room5(result2, new(3.62, 2.86, 4.93))
    result2 = "CanCollide"
    room5[result2] = false
    ok5 = true
    value10 = room5
    while wait(1) and not (fn22(value9.Position, room5.Position) < 5) do

    end
    ok5 = false
    value10 = nil
end

function kingFix()
    local game2 = fn12
    local new = Vector3.new
    game2(CFrame.new(-265.670135, 39.9012566, 821.916565, 0.267238349, 0, 0.963630438, 0, 1, 0, -0.963630438, 0, 0.267238349), new(205.490036, 121.409996, 83.2699738))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(-84.1567535, 39.9012566, 206.857864, -0.0000000437113883, 0, -1, 0, 1, 0, 1, 0, -0.0000000437113883), new(7.70991707, 121.409996, 20.2999802))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(-87.2210388, 39.9012566, 185.695068, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(7.70991707, 121.409996, 38.0599823))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(30.827137, 50.6512566, 315.457825, -0.0000000437113883, 0, -1, 0, 1, 0, 1, 0, -0.0000000437113883), new(224.909897, 99.909996, 40.819973))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(-201.965851, 39.9012566, 538.666504, 0.999657333, 0, 0.02617695, 0, 1, 0, -0.02617695, 0, 0.999657333), new(182.820007, 121.409996, 128.269974))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(-241.969254, 39.9012566, 610.253235, -0.0261769947, -0.00000000228846564, 0.999657333, -0.000000174815597, 1, -0.00000000228846564, -0.999657333, -0.000000174815597, -0.0261769947), new(251.470016, 121.409996, 81.7699738))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(-13.5106697, 61.6240005, -82.0305099, 0.0261769947, 0, -0.999657333, 0, 1, 0, 0.999657333, 0, 0.0261769947), new(60.3699608, 70.859993, 81.8800201))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(59.8843384, 39.9012566, 206.815186, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(29.4499016, 121.409996, 7.64001656))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(-52.9094086, 39.9012566, 315.457825, -0.0000000437113883, 0, -1, 0, 1, 0, 1, 0, -0.0000000437113883), new(224.909897, 121.409996, 40.819973))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(74.1219025, 39.9012527, 575.307129, -0.999390841, -0.0000000873695214, -0.0348994955, -0.0000000843717629, 1, -0.0000000873695214, 0.0348994955, -0.0000000843717629, -0.999390841), new(125.539993, 121.409996, 237.639999))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(37.6457291, 39.9012566, 151.17514, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(62.3399086, 121.409996, 43.2400017))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(0.196162999, 65.1762543, 441.391022, 0.0261769947, 0, -0.999657333, 0, 1, 0, 0.999657333, 0, 0.0261769947), new(62.0499763, 70.859993, 81.8800201))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(-55.767437, 39.9012566, 12.0568619, -0.0000000437113883, 0, 1, 0, 1, 0, -1, 0, -0.0000000437113883), new(242.48996, 121.409996, 43.2400017))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(31.8941364, 39.9012566, 16.1985588, 0.0174523834, 0, 0.99984771, 0, 1, 0, -0.99984771, 0, 0.0174523834), new(234.210022, 121.409996, 43.2400017))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(-7.2978816, 63.2866745, 155.216705, 0.0261769947, 0, -0.999657333, 0, 1, 0, 0.999657333, 0, 0.0261769947), new(62.0499763, 68.6600037, 81.8800201))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(66.2143402, 39.9012566, 170.095139, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(16.7899017, 121.409996, 81.0800095))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(-108.321632, 39.9012566, 444.232849, 0.0261769947, 0, -0.999657333, 0, 1, 0, 0.999657333, 0, 0.0261769947), new(62.0499763, 121.409996, 155.169968))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(84.8040543, 39.9012566, 451.600067, 0.0348994955, 0, -0.999390841, 0, 1, 0, 0.999390841, 0, 0.0348994955), new(62.0499763, 121.409996, 155.169968))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(97.8463821, 39.9012566, 665.138977, -0.0348994955, -0.00000000305101078, 0.999390841, -0.000000174792291, 1, -0.00000000305101078, -0.999390841, -0.000000174792291, -0.0348994955), new(19.5399895, 121.409996, 56.4300117))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(46.9567528, 39.9012566, 674.57135, -0.366501212, -0.0000000320405533, 0.930417597, -0.000000168762469, 1, -0.0000000320405533, -0.930417597, -0.000000168762469, -0.366501212), new(19.5399895, 121.409996, 56.4300117))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(-34.3111458, 39.9012566, 725.983276, -0.719339788, -0.0000000628866843, 0.694658399, -0.000000148151742, 1, -0.0000000628866843, -0.694658399, -0.000000148151742, -0.719339788), new(42.0399895, 121.409996, 197.409988))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(-112.350136, 39.9012566, 837.091858, -0.965925813, -0.0000000844439185, 0.258819044, -0.000000110049456, 1, -0.0000000844439185, -0.258819044, -0.000000110049456, -0.965925813), new(40.0399895, 121.409996, 103.629967))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(-139.625366, 39.9012566, 961.8349, -0.968147635, -0.0000000846381525, 0.250380009, -0.000000109311692, 1, -0.0000000846381525, -0.250380009, -0.000000109311692, -0.968147635), new(47.8199997, 121.409996, 187.62999))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(-200.630081, 65.554451, 1018.6449, -0.00000000000000000218195708, -0.0000000874227837, 1.00000024, -0.0000000874227695, 1, 0.0000000874227837, -1.00000024, -0.0000000874227979, 0.0000000000000076405599), new(60.8199997, 121.409996, 125.489998))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(-230.756363, 39.9012566, 1027.81616, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(40.8199997, 121.409996, 136.48999))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(-253.298645, 39.9012566, 919.571655, 0.902585268, 0, 0.430511087, 0, 1, 0, -0.430511087, 0, 0.902585268), new(43.3199997, 121.409996, 114.269997))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(-59.9060516, 39.9012566, 151.17514, 1, 0, 0, 0, 1, 0, 0, 0, 1), new(62.3399086, 121.409996, 43.2400017))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(37.8478165, 16.8362617, -190.005951, -0.0000000437113883, 0, 1, 0, 1, 0, -1, 0, -0.0000000437113883), new(16.16996, 75.2800064, 17.949995))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(43.4540367, 16.8362617, -158.997726, -0.819152057, -0.000000071612547, 0.57357645, -0.000000137566417, 1, -0.000000071612547, -0.57357645, -0.000000137566417, -0.819152057), new(28.7199612, 75.2800064, 21.4999905))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(-78.8311462, 39.9012566, -291.1315, -0.0000000437113883, 0, 1, 0, 1, 0, -1, 0, -0.0000000437113883), new(107.669968, 121.409996, 6.42999887))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(-114.162926, 16.8362617, -234.379257, -0.0000000437113883, 0, 1, 0, 1, 0, -1, 0, -0.0000000437113883), new(2.349967, 75.2800064, 3.74999881))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(43.2896805, 16.8362617, -174.360001, -1, -0.0000000874227766, 0, -0.0000000874227766, 1, -0.0000000874227766, 0.00000000000000764274186, -0.0000000874227766, -1), new(16.16996, 75.2800064, 17.949995))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(-11.822731, 61.6240005, -17.5732212, 0.0261769947, 0, -0.999657333, 0, 1, 0, 0.999657333, 0, 0.0261769947), new(3.48996258, 70.859993, 81.8800201))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(-187.323776, 16.8362617, -240.981262, -0.0000000437113883, 0, 1, 0, 1, 0, -1, 0, -0.0000000437113883), new(3.3399663, 75.2800064, 7.0199976))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(-71.4555283, -9.84874344, 8.86862564, 0.0261769947, 0, -0.999657333, 0, 1, 0, 0.999657333, 0, 0.0261769947), new(930.549988, 24.909996, 401.669983))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(-141.047348, 39.9012566, -346.645721, -1, -0.0000000874227766, 0, -0.0000000874227766, 1, -0.0000000874227766, 0.00000000000000764274186, -0.0000000874227766, -1), new(136.869934, 121.409996, 6.42999887))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(36.2830582, 16.8362617, -147.050018, -0.819152057, -0.000000071612547, 0.57357645, -0.000000137566417, 1, -0.000000071612547, -0.57357645, -0.000000137566417, -0.819152057), new(9.30995846, 75.2800064, 31.1199837))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(-209.860611, 39.9012566, -292.526398, -0.0000000437113883, 0, 1, 0, 1, 0, -1, 0, -0.0000000437113883), new(119.619957, 121.409996, 6.42999887))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(17.7576237, -9.09874344, -452.124695, 0.0261769947, 0, -0.999657333, 0, 1, 0, 0.999657333, 0, 0.0261769947), new(28.5499878, 25.409996, 231.169983))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(-51.8212013, -8.75, -568.843323, 0.0261769947, 0, -0.999657333, 0, 1, 0, 0.999657333, 0, 0.0261769947), new(216.549988, 26.409996, 364.169983))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(-261.46759, -21.155468, -615.121277, -0.0000000437113883, -0.406736642, -0.91354543, 0, 0.91354543, -0.406736642, 1, -0.0000000177790227, -0.0000000399323383), new(87.0499878, 26.409996, 69.1699829))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(-250.886627, -11.7916269, -731.871277, -0.0000000437113883, 0, -1, 0, 1, 0, 1, 0, -0.0000000437113883), new(146.550003, 46.909996, 39.6699829))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(-250.886627, -11.7916269, -513.371277, -0.0000000437113883, 0, -1, 0, 1, 0, 1, 0, -0.0000000437113883), new(116.550003, 46.909996, 39.6699829))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(-413.386627, 24.458374, -464.371277, -0.0000000437113883, 0, -1, 0, 1, 0, 1, 0, -0.0000000437113883), new(18.5500031, 119.409996, 364.669983))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(-414.136627, 24.458374, -779.121277, -0.0000000437113883, 0, -1, 0, 1, 0, 1, 0, -0.0000000437113883), new(18.0499878, 119.409996, 366.169983))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(-464.386597, -19.291626, -617.371277, -0.0000000437113883, 0, -1, 0, 1, 0, 1, 0, -0.0000000437113883), new(324.549988, 31.909996, 0.66998291))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(-366.386597, -22.791626, -617.371277, -0.0000000437113883, 0, -1, 0, 1, 0, 1, 0, -0.0000000437113883), new(324.549988, 24.909996, 197.669983))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(-111.886597, 24.458374, -659.621277, -0.0000000437113883, 0, -1, 0, 1, 0, 1, 0, -0.0000000437113883), new(25.0499878, 119.409996, 255.669983))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(-110.386597, 24.458374, -560.871277, -0.0000000437113883, 0, -1, 0, 1, 0, 1, 0, -0.0000000437113883), new(50.5499878, 119.409996, 258.669983))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(79.3634033, 24.458374, -548.871277, -0.0000000437113883, 0, -1, 0, 1, 0, 1, 0, -0.0000000437113883), new(164.549988, 119.409996, 63.1699829))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(56.8634033, 24.458374, -641.121277, -0.0000000437113883, 0, -1, 0, 1, 0, 1, 0, -0.0000000437113883), new(22.0499878, 119.409996, 108.169983))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(11.1134005, 24.458374, -536.621277, -0.0000000437113883, 0, -1, 0, 1, 0, 1, 0, -0.0000000437113883), new(136.049988, 119.409996, 16.6699829))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(-13.6366024, 24.458374, -469.621277, -0.0000000437113883, 0, -1, 0, 1, 0, 1, 0, -0.0000000437113883), new(2.05000305, 119.409996, 66.1699829))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(-43.3866081, 24.458374, -390.371277, -0.0000000437113883, 0, -1, 0, 1, 0, 1, 0, -0.0000000437113883), new(160.550003, 119.409996, 6.66998291))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(111.363388, 24.458374, -390.371277, -0.0000000437113883, 0, -1, 0, 1, 0, 1, 0, -0.0000000437113883), new(160.550003, 119.409996, 6.16998291))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(77.6133881, 24.458374, -258.121277, -0.0000000437113883, 0, -1, 0, 1, 0, 1, 0, -0.0000000437113883), new(128.050003, 119.409996, 73.6699829))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(-22.8866119, 24.458374, -280.621277, -0.0000000437113883, 0, -1, 0, 1, 0, 1, 0, -0.0000000437113883), new(83.0500031, 119.409996, 90.6699829))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(-90.8866119, 24.458374, -216.621277, -0.0000000437113883, 0, -1, 0, 1, 0, 1, 0, -0.0000000437113883), new(60.0500031, 119.409996, 49.6699829))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(-105.136612, 24.458374, -148.621277, -0.0000000437113883, 0, -1, 0, 1, 0, 1, 0, -0.0000000437113883), new(25.0500031, 119.409996, 78.1699829))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(-177.886612, 24.458374, -184.871277, -0.0000000437113883, 0, -1, 0, 1, 0, 1, 0, -0.0000000437113883), new(97.5500031, 119.409996, 73.6699829))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(-43.8866119, 24.458374, -79.8712769, -0.0000000437113883, 0, -1, 0, 1, 0, 1, 0, -0.0000000437113883), new(126.550003, 119.409996, 47.6699829))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(21.6133881, 24.458374, -79.8712769, -0.0000000437113883, 0, -1, 0, 1, 0, 1, 0, -0.0000000437113883), new(126.550003, 119.409996, 46.6699829))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(-595.011597, 29.583374, -617.371277, -0.0000000437113883, 0, -1, 0, 1, 0, 1, 0, -0.0000000437113883), new(324.549988, 129.660004, 5.91998291))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(-528.511597, -4.16662598, -617.371277, -0.0000000437113883, 0, -1, 0, 1, 0, 1, 0, -0.0000000437113883), new(324.549988, 1.15999603, 128.919983))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(-542.636597, 9.45837402, -619.371277, -0.0000000437113883, 0, -1, 0, 1, 0, 1, 0, -0.0000000437113883), new(36.5499878, 25.909996, 41.6699829))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(-559.011597, 23.958374, -619.371277, -0.0000000437113883, 0, -1, 0, 1, 0, 1, 0, -0.0000000437113883), new(36.5499878, 54.909996, 8.91998291))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(-580.636597, 44.083374, -566.496277, -0.0000000437113883, 0, -1, 0, 1, 0, 1, 0, -0.0000000437113883), new(42.2999878, 95.159996, 42.1699829))
    game2 = fn12
    new = Vector3.new
    game2(CFrame.new(-582.511597, 44.083374, -672.246277, -0.0000000437113883, 0, -1, 0, 1, 0, 1, 0, -0.0000000437113883), new(41.2999878, 95.159996, 38.4199829))
    game2 = fn12
    CFrame69 = CFrame
    local PathfindingService = CFrame69.new(-12.2616129, 24.458374, -255.746277, -0.0000000437113883, 0, -1, 0, 1, 0, 1, 0, -0.0000000437113883)
    new = Vector3.new
    game2(PathfindingService, new(132.800003, 119.409996, 34.9199829))
    local _G2 = _G
    PathfindingService = "destroy_map"
    if _G2[PathfindingService] then
        local pairs2 = pairs
        local workspace2 = workspace
        local value2, value3 = "GetChildren", workspace2
        local item = value3[value2]
        for k, v in pairs2(item(value3)) do
            if (v.ClassName == "Model"
                or v.ClassName == "Part"
                or v.ClassName == "UnionOperation"
                or v.ClassName == "WedgePart"
                or v.ClassName == "MeshPart")
                and v ~= game.Players.LocalPlayer.Character
                and v.Name ~= result3 then
                local value4, value5 = "Destroy", v
                value5[value4](value5)
            end
        end
    end
    wait(5)
    while true do
        local game3, value6 = game, "GetService"
        local value7 = game3
        game3 = value7[value6](value7, "Workspace")
        game3 = game3.dungeon
        local room32 = game3.room3
        room32 = room32.enemyFolder
        value6 = "FindFirstChild"
        value7 = room32
        local item2 = value7[value6]
        if item2(value7, "Beast Master") then
            break
        end
        wait(1)
    end
    while true do
        local game4, value8 = game, "GetService"
        local value9 = game4
        game4 = value9[value8](value9, "Workspace")
        game4 = game4.dungeon
        local room33 = game4.room3
        room33 = room33.enemyFolder
        value8 = "FindFirstChild"
        value9 = room33
        room33 = value9[value8](value9, "Beast Master")
        value8 = "FindFirstChild"
        value9 = room33
        local item3 = value9[value8]
        if item3(value9, "HumanoidRootPart") then
            break
        end
        wait(1)
    end
    ok6 = true
    game2 = result9
    local result2 = CFrame.new(3.85899, 5.60531, 31.656)
    game2.CFrame = result2
    game2 = game
    new = "GetService"
    result2 = game2
    game2 = result2[new](result2, "Workspace")
    game2 = game2.dungeon
    local room3 = game2.room3
    room3 = room3.enemyFolder
    new = "FindFirstChild"
    local value = room3
    room3 = value[new](value, "Beast Master")
    while true do
        if not (room3.PrimaryPart.Position.Y > 35) then
            break
        end
        wait()
    end
    ok6 = false
end

function winterFix()
    fn3(workspace, "dungeon")
    local workspace2 = workspace
    workspace2.Terrain:Clear()
    workspace2 = fn12
    local new = Vector3.new
    workspace2(CFrame.new(49.6182404, 44.75, 118.716324, 0.857167304, 0, -0.515038073, 0, 1, 0, 0.515038073, 0, 0.857167304), new(82.5, 2.5, 32))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(65.4887466, 54.5, 107.836174, 0.857167304, 0, -0.515038073, 0, 1, 0, 0.515038073, 0, 0.857167304), new(63.5, 22, 5))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(36.3633881, 54.5, 129.12648, 0.857167304, 0, -0.515038073, 0, 1, 0, 0.515038073, 0, 0.857167304), new(92.5, 22, 1.5))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(53.4067535, 58.25, -19.6698608, -0.342020094, 0, -0.939692616, 0, 1, 0, 0.939692616, 0, -0.342020094), new(64, 29.5, 2))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(6.28490734, 44.75, 78.9878387, 0.438371092, 0, -0.898794055, 0, 1, 0, 0.898794055, 0, 0.438371092), new(54, 2.5, 46))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(26.3271828, 54.5, 64.7621689, 0.438371092, 0, -0.898794055, 0, 1, 0, 0.898794055, 0, 0.438371092), new(62, 22, 5.5))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(-20.3219051, 54.5, 78.6136322, 0.438371092, 0, -0.898794055, 0, 1, 0, 0.898794055, 0, 0.438371092), new(78, 22, 8.5))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(2.55875301, 44.75, 71.3480911, 0.438371092, 0, -0.898794055, 0, 1, 0, 0.898794055, 0, 0.438371092), new(71, 2.5, 46))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(24.2970142, 44.75, -28.1365814, -0.342020094, 0, -0.939692616, 0, 1, 0, 0.939692616, 0, -0.342020094), new(182, 2.5, 62.5))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(47.7676086, 42.7324867, -1175.33252, 0.0000000297297333, -0.00000000207890483, -1, 0.0697564632, 0.997564077, 0.000000000000000326544807, 0.997564077, -0.0697564632, 0.0000000298023295), new(41.5, 15.5, 167))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(34.0146065, 58.25, 20.1416855, -0.798635483, 0, -0.601815045, 0, 1, 0, 0.601815045, 0, -0.798635483), new(57, 29.5, 7))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(59.3021507, 58.25, -66.8049469, -0.0697563887, 0, -0.997563958, 0, 1, 0, 0.997563958, 0, -0.0697563887), new(80.5, 29.5, 2))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(-9.12857437, 56, -32.0551186, -0.342020094, 0, -0.939692616, 0, 1, 0, 0.939692616, 0, -0.342020094), new(173.5, 25, 7))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(72.586441, 57.25, -108.386299, -0.0348994732, 0, -0.999390781, 0, 1, 0, 0.999390781, 0, -0.0348994732), new(8.5, 27.5, 25))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(32.1111145, 57.25, -109.799721, -0.0348994732, 0, -0.999390781, 0, 1, 0, 0.999390781, 0, -0.0348994732), new(8.5, 27.5, 23))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(41.0176544, 44.75, -213.190704, 0.0000000298023224, 0, -0.999999881, 0, 1, 0, 0.999999881, 0, 0.0000000298023224), new(215, 2.5, 91.5))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(3.76765871, 61.5, -213.940704, 0.0000000298023224, 0, -0.999999881, 0, 1, 0, 0.999999881, 0, 0.0000000298023224), new(222.5, 36, 17))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(12.5176563, 61.5, -235.440704, 0.0000000298023224, 0, -0.999999881, 0, 1, 0, 0.999999881, 0, 0.0000000298023224), new(52.5, 36, 34.5))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(11.7676601, 61.5, -132.190704, 0.0000000298023224, 0, -0.999999881, 0, 1, 0, 0.999999881, 0, 0.0000000298023224), new(59, 36, 33))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(81.2676544, 62, -213.440704, 0.0000000298023224, 0, -0.999999881, 0, 1, 0, 0.999999881, 0, 0.0000000298023224), new(215.5, 37, 11))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(74.2676544, 62, -228.690704, 0.0000000298023224, 0, -0.999999881, 0, 1, 0, 0.999999881, 0, 0.0000000298023224), new(53, 37, 25))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(74.2676544, 62, -122.190712, 0.0000000298023224, 0, -0.999999881, 0, 1, 0, 0.999999881, 0, 0.0000000298023224), new(21, 37, 25))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(15.2676544, 61.25, -322.940674, 0.0000000298023224, 0, -0.999999881, 0, 1, 0, 0.999999881, 0, 0.0000000298023224), new(14.5, 35.5, 40))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(71.0176468, 61.25, -322.940674, 0.0000000298023224, 0, -0.999999881, 0, 1, 0, 0.999999881, 0, 0.0000000298023224), new(14.5, 35.5, 37.5))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(51.7676086, 58, -1590.19067, 0.0000000298023224, 0, -0.999999881, 0, 1, 0, 0.999999881, 0, 0.0000000298023224), new(60, 41, 172))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(-2.48238373, 58, -1368.94067, 0.0000000298023224, 0, -0.999999881, 0, 1, 0, 0.999999881, 0, 0.0000000298023224), new(10.5, 41, 74.5))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(87.0176086, 58, -1368.94067, 0.0000000298023224, 0, -0.999999881, 0, 1, 0, 0.999999881, 0, 0.0000000298023224), new(10.5, 41, 69.5))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(41.5176239, 45.25, -964.440674, 0.0000000298023224, 0, -0.999999881, 0, 1, 0, 0.999999881, 0, 0.0000000298023224), new(6.5, 15.5, 141.5))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(113.517601, 58, -1261.19067, 0.0000000298023224, 0, -0.999999881, 0, 1, 0, 0.999999881, 0, 0.0000000298023224), new(213, 41, 3.5))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(47.767601, 44.25, -1501.44067, 0.0000000298023224, 0, -0.999999881, 0, 1, 0, 0.999999881, 0, 0.0000000298023224), new(266.5, 13.5, 167))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(84.6765747, 54.5, 139.489838, 0.857167304, 0, -0.515038073, 0, 1, 0, 0.515038073, 0, 0.857167304), new(4, 22, 30.5))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(43.5176506, 42.4555817, -310.699219, 0.0000000280050312, 0.0000000101929967, -1, -0.342020154, 0.939692736, 0.000000000000000250114324, 0.939692736, 0.342020154, 0.0000000298023295), new(19.5, 9.5, 71.5))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(44.2676468, 41.5, -394.940674, 0.0000000298023224, 0, -0.999999881, 0, 1, 0, 0.999999881, 0, 0.0000000298023224), new(182.5, 8, 43))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(62.5176468, 58.25, -407.940674, 0.0000000298023224, 0, -0.999999881, 0, 1, 0, 0.999999881, 0, 0.0000000298023224), new(182.5, 41.5, 6.5))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(16.2676506, 58.25, -407.690674, 0.0000000298023224, 0, -0.999999881, 0, 1, 0, 0.999999881, 0, 0.0000000298023224), new(184, 41.5, 19))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(44.2676353, 44.4752426, -493.355347, 0.0000000276322254, 0.0000000111641461, -0.999999642, -0.37460652, 0.927183867, 0, 0.927183509, 0.37460655, 0.0000000298023153), new(15, 8.5, 57))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(52.5176392, 43.75, -590.190674, 0.0000000298023224, 0, -0.999999881, 0, 1, 0, 0.999999881, 0, 0.0000000298023224), new(183, 12.5, 94.5))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(58.5176392, 56, -545.190674, 0.0000000298023224, 0, -0.999999881, 0, 1, 0, 0.999999881, 0, 0.0000000298023224), new(93, 37, 14.5))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(21.2676411, 56, -545.190674, 0.0000000298023224, 0, -0.999999881, 0, 1, 0, 0.999999881, 0, 0.0000000298023224), new(93, 37, 24))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(10.517643, 55.75, -635.190674, 0.0000000298023224, 0, -0.999999881, 0, 1, 0, 0.999999881, 0, 0.0000000298023224), new(93, 36.5, 10.5))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(96.0176392, 55.75, -635.190674, 0.0000000298023224, 0, -0.999999881, 0, 1, 0, 0.999999881, 0, 0.0000000298023224), new(93, 36.5, 8.5))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(83.7071075, 55.75, -593.931519, 0.587785304, 0, -0.809017003, 0, 1, 0, 0.809017062, 0, 0.587785304), new(18.5, 36.5, 34))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(44.2676506, 45.7468681, -322.680908, 0.0000000298023224, -0.00000000000000363461795, -1, 0.0000000883349074, 1, -0.00000000000000100203257, 1, -0.0000000883349074, 0.0000000298023224), new(9, 9.5, 43))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(68.7676315, 46.7623405, -677.575806, 0.0000000144484531, -0.0000000260657025, -1, 0.874619722, 0.484809637, -0.00000000000000175880865, 0.484809637, -0.874619722, 0.0000000298023259), new(9, 16, 107))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(50.2676353, 46, -716.690613, 0.0000000298023259, 0, -1, 0, 1, 0, 1, 0, 0.0000000298023259), new(70, 17, 29))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(6.26764297, 58.5, -711.440674, 0.0000000298023224, 0, -0.999999881, 0, 1, 0, 0.999999881, 0, 0.0000000298023224), new(71.5, 42, 74))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(89.2676392, 58.5, -711.440674, 0.0000000298023224, 0, -0.999999881, 0, 1, 0, 0.999999881, 0, 0.0000000298023224), new(71.5, 42, 54))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(41.5176277, 46, -853.940674, 0.0000000298023224, 0, -0.999999881, 0, 1, 0, 0.999999881, 0, 0.0000000298023224), new(215.5, 17, 141.5))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(-25.9823647, 59, -853.940674, 0.0000000298023224, 0, -0.999999881, 0, 1, 0, 0.999999881, 0, 0.0000000298023224), new(215.5, 43, 6.5))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(118.517624, 59, -853.940674, 0.0000000298023224, 0, -0.999999881, 0, 1, 0, 0.999999881, 0, 0.0000000298023224), new(215.5, 43, 23.5))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(111.267616, 59, -883.440796, 0.173648208, 0, -0.984807789, 0, 1, 0, 0.984807789, 0, 0.173648208), new(154.5, 43, 38))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(-5.48237181, 57.75, -964.190674, 0.0000000298023224, 0, -0.999999881, 0, 1, 0, 0.999999881, 0, 0.0000000298023224), new(28, 40.5, 47.5))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(100.517609, 57.75, -964.190674, 0.0000000298023224, 0, -0.999999881, 0, 1, 0, 0.999999881, 0, 0.0000000298023224), new(28, 40.5, 70.5))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(39.0176201, 44.5, -1058.19067, 0.0000000298023259, 0, -1, 0, 1, 0, 1, 0, 0.0000000298023259), new(196, 15, 144.5))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(3.799963, 56, -53.687912, -0.342020094, 0, -0.939692616, 0, 1, 0, 0.939692616, 0, -0.342020094), new(40, 25, 16.5))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(-24.2323837, 58, -1261.19067, 0.0000000298023224, 0, -0.999999881, 0, 1, 0, 0.999999881, 0, 0.0000000298023224), new(213, 41, 23))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(47.7676086, 44.25, -1262.69067, 0.0000000298023224, 0, -0.999999881, 0, 1, 0, 0.999999881, 0, 0.0000000298023224), new(216, 13.5, 167))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(-33.7323837, 58, -1491.94067, 0.0000000298023224, 0, -0.999999881, 0, 1, 0, 0.999999881, 0, 0.0000000298023224), new(256.5, 41, 12))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(120.767601, 58, -1491.94067, 0.0000000298023224, 0, -0.999999881, 0, 1, 0, 0.999999881, 0, 0.0000000298023224), new(256.5, 41, 34))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(-0.232380569, 60.75, -1165.44067, 0.0000000298023224, 0, -0.999999881, 0, 1, 0, 0.999999881, 0, 0.0000000298023224), new(21.5, 46.5, 71))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(85.5176086, 60.75, -1165.44067, 0.0000000298023224, 0, -0.999999881, 0, 1, 0, 0.999999881, 0, 0.0000000298023224), new(21.5, 46.5, 66.5))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(136.517609, 60.75, -1068.69067, 0.0000000298023224, 0, -0.999999881, 0, 1, 0, 0.999999881, 0, 0.0000000298023224), new(215, 46.5, 30.5))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(-36.9823761, 60.75, -1068.69067, 0.0000000298023224, 0, -0.999999881, 0, 1, 0, 0.999999881, 0, 0.0000000298023224), new(215, 46.5, 20.5))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(44.2676506, 42.8013573, -333.105347, 0.0000000281786487, -0.00000000970269021, -1, 0.325568229, 0.945518553, -0.00000000000000109093672, 0.945518553, -0.325568229, 0.0000000298023224), new(19.5, 9.5, 43))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(106.267624, 45.5, -1058.19067, 0.0000000298023259, 0, -1, 0, 1, 0, 1, 0, 0.0000000298023259), new(196, 17, 33))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(39.0176239, 45.5, -987.940674, 0.0000000298023259, 0, -1, 0, 1, 0, 1, 0, 0.0000000298023259), new(55.5, 17, 144.5))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(-19.482378, 45.5, -1058.94067, 0.0000000298023259, 0, -1, 0, 1, 0, 1, 0, 0.0000000298023259), new(197.5, 17, 32.5))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(39.7676201, 45.5, -1145.44067, 0.0000000298023259, 0, -1, 0, 1, 0, 1, 0, 0.0000000298023259), new(24.5, 17, 146))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(105.017624, 45, -1058.19067, 0.0000000298023259, 0, -1, 0, 1, 0, 1, 0, 0.0000000298023259), new(196, 16, 35.5))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(39.0176239, 45, -988.940674, 0.0000000298023259, 0, -1, 0, 1, 0, 1, 0, 0.0000000298023259), new(57.5, 16, 144.5))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(-18.482378, 45, -1058.94067, 0.0000000298023259, 0, -1, 0, 1, 0, 1, 0, 0.0000000298023259), new(197.5, 16, 34.5))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(39.7676201, 45, -1143.69067, 0.0000000298023259, 0, -1, 0, 1, 0, 1, 0, 0.0000000298023259), new(28, 16, 146))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(24.7676239, 46, -1016.19067, 0.0000000298023259, 0, -1, 0, 1, 0, 1, 0, 0.0000000298023259), new(13, 18, 28))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(2.2676239, 45.5, -1031.94067, 0.0000000298023259, 0, -1, 0, 1, 0, 1, 0, 0.0000000298023259), new(44.5, 17, 28))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(1.01762342, 46, -1041.44067, 0.0000000298023259, 0, -1, 0, 1, 0, 1, 0, 0.0000000298023259), new(63.5, 18, 25.5))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(4.76762342, 50, -1050.69067, 0.0000000298023259, 0, -1, 0, 1, 0, 1, 0, 0.0000000298023259), new(44, 26, 23))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(-1.98237896, 50, -1124.94067, 0.0000000298023259, 0, -1, 0, 1, 0, 1, 0, 0.0000000298023259), new(28.5, 26, 19.5))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(13.267621, 50, -1130.19067, 0.0000000298023259, 0, -1, 0, 1, 0, 1, 0, 0.0000000298023259), new(18, 26, 50))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(82.0176239, 50, -1130.19067, 0.0000000298023259, 0, -1, 0, 1, 0, 1, 0, 0.0000000298023259), new(18, 26, 18.5))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(84.2676239, 50, -1124.44067, 0.0000000298023259, 0, -1, 0, 1, 0, 1, 0, 0.0000000298023259), new(29.5, 26, 14))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(84.2676239, 50, -1028.19067, 0.0000000298023259, 0, -1, 0, 1, 0, 1, 0, 0.0000000298023259), new(20, 26, 14))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(75.5176239, 50, -1018.94067, 0.0000000298023259, 0, -1, 0, 1, 0, 1, 0, 0.0000000298023259), new(9.5, 26, 31.5))
    workspace2 = fn12
    new = Vector3.new
    workspace2(CFrame.new(78.0176239, 45.25, -1024.19067, 0.0000000298023259, 0, -1, 0, 1, 0, 1, 0, 0.0000000298023259), new(20, 16.5, 26.5))
    workspace2 = fn12
    CFrame84 = CFrame
    local PathfindingService = CFrame84.new(50.1426544, 61.5, -157.565704, 0.0000000298023224, 0, -0.999999881, 0, 1, 0, 0.999999881, 0, 0.0000000298023224)
    new = Vector3.new
    workspace2(PathfindingService, new(19.75, 36, 15.25))
    workspace2 = wait
    PathfindingService = 0.1
    workspace2(PathfindingService)
    if _G.destroy_map then
        workspace.Terrain:Clear()
        local pairs2 = pairs
        local workspace3, value3 = workspace, "GetChildren"
        local value4 = workspace3
        local item = value4[value3]
        for k, v in pairs2(item(value4)) do
            if (v.ClassName == "Model"
                or v.ClassName == "Part"
                or v.ClassName == "UnionOperation"
                or v.ClassName == "WedgePart")
                and v ~= game.Players.LocalPlayer.Character
                and v.Name ~= result3 then
                local value5, value6 = "Destroy", v
                value6[value5](value6)
            end
        end
        local pairs3 = pairs
        workspace3 = workspace.dungeon
        value3 = "GetChildren"
        value4 = workspace3
        local item2 = value4[value3]
        for k3, v3 in pairs3(item2(value4)) do
            local pairs4 = pairs
            local value7, value8 = "GetChildren", v3
            local item3 = value8[value7]
            for k2, v2 in pairs4(item3(value8)) do
                -- The decompiler lost this condition (it emitted `if nil then`,
                -- so room geometry was never cleared). Reconstructed conservatively:
                -- decoration only. Anything collidable is left alone - in this
                -- build the rooms live under workspace.dungeon and the outer
                -- workspace sweep no longer touches them, so deleting collidable
                -- parts here would drop you through the floor.
                if v2.Name ~= "enemyFolder"
                    and v2.Name ~= "barrier"
                    and v2.Name ~= "order"
                    and not v2:FindFirstChildOfClass("Humanoid")
                    and v2:IsA("BasePart")
                    and not v2.CanCollide then
                    local value9, value10 = "Destroy", v2
                    value10[value9](value10)
                end
            end
        end
    end
    while true do
        local game3, value11 = game, "GetService"
        local value12 = game3
        game3 = value12[value11](value12, "Workspace")
        game3 = game3.dungeon
        local bossRoom2 = game3.bossRoom
        bossRoom2 = bossRoom2.enemyFolder
        value11 = "FindFirstChildOfClass"
        value12 = bossRoom2
        local item4 = value12[value11]
        if item4(value12, "Model") then
            break
        end
        wait(1)
    end
    while true do
        local game4, value13 = game, "GetService"
        local value14 = game4
        game4 = value14[value13](value14, "Workspace")
        game4 = game4.dungeon
        local bossRoom3 = game4.bossRoom
        bossRoom3 = bossRoom3.enemyFolder
        value13 = "FindFirstChildOfClass"
        value14 = bossRoom3
        bossRoom3 = value14[value13](value14, "Model")
        value13 = "FindFirstChild"
        value14 = bossRoom3
        local item5 = value14[value13]
        if item5(value14, "HumanoidRootPart") then
            break
        end
        wait(1)
    end
    workspace2 = game.Players
    workspace2 = workspace2.LocalPlayer
    workspace2 = workspace2.Character
    workspace2 = workspace2.HumanoidRootPart
    local game2, value = game, "GetService"
    new = game2
    game2 = new[value](new, "Workspace")
    game2 = game2.dungeon
    local bossRoom = game2.bossRoom
    bossRoom = bossRoom.enemyFolder
    value = "FindFirstChildOfClass"
    new = bossRoom
    bossRoom = new[value](new, "Model")
    value = "FindFirstChild"
    new = bossRoom
    bossRoom = new[value](new, "HumanoidRootPart")
    bossRoom = bossRoom.CFrame
    new = CFrame.new(0, 0, 5)
    workspace2.CFrame = bossRoom * new
end

function desertFix()
    local PathfindingService = fn3(workspace, "dungeon")
    local pairs2, value = pairs, PathfindingService
    for k2, v2 in pairs2(value.GetChildren(value)) do
        local pairs3, value2 = pairs, v2
        for k, v in pairs3(value2.GetChildren(value2)) do
            if v.ClassName == "Part" then
                if v.Name == "barrier" then
                    v:Destroy()
                end
                local X = v.Orientation.X
                if X ~= math.floor(X) then
                    v:Destroy()
                end
                local Y = v.Orientation.Y
                if Y ~= math.floor(Y) then
                    v:Destroy()
                end
                local Z = v.Orientation.Z
                if Z ~= math.floor(Z) then
                    v:Destroy()
                end
            elseif v.ClassName == "Model"
                or v.ClassName == "UnionOperation"
                or v.ClassName == "WedgePart" then
                v:Destroy()
            end
        end
    end
end

function eggFix()
    game.ReplicatedStorage.remotes.equipSet:FireServer(_G.eggClass)
    local PathfindingService = fn3(workspace, "Map")
    if not PathfindingService then
        ScriptDebug("[compat] workspace.Map missing - eggFix skipped")
        return
    end
    local pairs2, Terrain = pairs, PathfindingService.Parts.Terrain
    for k, v in pairs2(Terrain.GetChildren(Terrain)) do
        item4:AddTag(v, "RayWhitelist")
    end
    local pairs3, Misc = pairs, PathfindingService.Parts.Misc
    for k2, v2 in pairs3(Misc.GetChildren(Misc)) do
        item4:AddTag(v2, "RayWhitelist")
    end
    local pairs4, Barriers = pairs, PathfindingService.Barriers
    for k3, v3 in pairs4(Barriers.GetChildren(Barriers)) do
        item4:AddTag(v3, "RayWhitelist")
    end
    local pairs5, Models = pairs, PathfindingService.Models
    for k4, v4 in pairs5(Models.GetChildren(Models)) do
        item4:AddTag(v4, "RayWhitelist")
    end
    PathfindingService.Props:Destroy()
    wait(5)
    while true do
        local dungeon = game:GetService("Workspace")
        dungeon = dungeon.dungeon
        if dungeon.bossRoom.enemyFolder:FindFirstChild("Egg Mech") then
            break
        end
        wait(1)
    end
    while true do
        local dungeon2 = game:GetService("Workspace")
        dungeon2 = dungeon2.dungeon
        if dungeon2.bossRoom.enemyFolder:FindFirstChild("Egg Mech"):FindFirstChild("HumanoidRootPart") then
            break
        end
        wait(1)
    end
    ok6 = true
    local _, _, _, value8 = fn23()
    local value2 = result9
    local result2 = CFrame.new(570.516174, 124.525772, 5.6751118)
    value2.CFrame = result2
    while true do
        if not (value8.Position.Y > 120) then
            break
        end
        wait()
    end
    ok6 = false
end

function fpsBoost()
    if _G.fpsBoost then
        local game2 = game
        local Workspace, Lighting = game2.Workspace, game2.Lighting
        local Terrain = Workspace.Terrain
        sethiddenproperty(Lighting, "Technology", 2)
        sethiddenproperty(Terrain, "Decoration", false)
        Terrain.WaterWaveSize = 0
        Terrain.WaterWaveSpeed = 0
        Terrain.WaterReflectance = 0
        Terrain.WaterTransparency = 0
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9000000000
        Lighting.Brightness = 0
        local Rendering = settings()
        Rendering = Rendering.Rendering
        Rendering.QualityLevel = "Level01"
        local pairs2, value2 = pairs, game2
        for k, v in pairs2(value2.GetDescendants(value2)) do
            if v:IsA("Part") or v:IsA("Union") or v:IsA("CornerWedgePart") or v:IsA("TrussPart") then
                v.Material = "Plastic"
                v.Reflectance = 0
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
            elseif v:IsA("ParticleEmitter") then
                v.Lifetime = NumberRange.new(0)
            elseif v:IsA("Trail") then
                -- Trail.Lifetime is a plain number, not a NumberRange; the shared
                -- branch threw "cannot be converted to a number" on every trail.
                v.Lifetime = 0
            elseif v:IsA("Explosion") then
                v.BlastPressure = 1
                v.BlastRadius = 1
            elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") or v:IsA("Sparkles") then
                v.Enabled = false
            elseif v:IsA("MeshPart") then
                v.Material = "Plastic"
                v.Reflectance = 0
                -- TextureID is a Content string; the bare asset number would not cast.
                v.TextureID = ""
            end
        end
        local pairs3, value3 = pairs, Lighting
        for k2, v2 in pairs3(value3.GetChildren(value3)) do
            -- The decompiler lost the body of the class test and left the
            -- disable running on every child, so this threw on Lighting.Sky
            -- ("Enabled is not a valid member") and aborted the rest of the pass.
            -- PostEffect is exactly the set of classes it was listing.
            if v2:IsA("PostEffect") then
                v2.Enabled = false
            end
        end
    end
end

function updatecheck()
    -- The old build had one place (and one PlaceVersion to pin) per dungeon.
    -- This build ships Lobby / Level / 100+ only, so there is nothing to pin.
    local tbl = {}
    tbl[LOBBY_PLACE_ID] = { name = "Lobby" }
    tbl[LOBBY_100_PLACE_ID] = { name = "Lobby 100+" }
    tbl[LEVEL_PLACE_ID] = { name = "Level" }
    if tbl[game.PlaceId] == nil then
        ScriptDebug("[compat] unknown place " .. tostring(game.PlaceId) .. " - dungeon fixes may not apply")
    end
end

spawn(updatecheck)

-- Map-geometry fixes, keyed by dungeon name instead of place id.
-- "Oceanic" was this script's internal name for Aquatic Temple.
local dungeonFixes = {
    ["Aquatic Temple"] = oceanFix,
    ["Volcanic Chambers"] = volcanicFix,
    ["Orbital Outpost"] = fixOrbital,
    ["Steampunk Sewers"] = steamFix,
    ["Ghastly Harbor"] = ghastlyFix,
    ["The Canals"] = canalsFix,
    ["Samurai Palace"] = samuraiFix,
    ["The Underworld"] = underworldFix,
    ["King's Castle"] = kingFix,
    ["Pirate Island"] = pirateFix,
    ["Winter Outpost"] = winterFix,
    ["Desert Temple"] = desertFix,
}

local value38, value39, value40
local activeDungeon = currentDungeonName()
tbl8.dungeonName = activeDungeon
farmStatus.dungeon = activeDungeon or (isLobbyPlace() and "Lobby" or "")
if isWaveDefensePlace() then
    tbl8.dungeonName = "Wave Defense"
    value38, value39, value40 = ok8, false, true
elseif isBossRaidPlace() then
    tbl8.dungeonName = "Boss Raid"
    value38, value39, value40 = true, false, ok10
elseif activeDungeon == "Egg Island" then
    ok = true
    spawn(eggFix)
    value38, value39, value40 = ok8, false, false
elseif activeDungeon ~= nil and dungeonFixes[activeDungeon] then
    spawn(dungeonFixes[activeDungeon])
    value38, value39, value40 = ok8, humanoid, ok10
else
    -- Lobby, or a dungeon added after this script was written (Enchanted Forest,
    -- Northern Lands, Gilded Skies, Oni Dungeon, Krampus). No wall data exists
    -- for those maps, so run without the geometry fix.
    if activeDungeon then
        ScriptDebug("[compat] no map fix for dungeon: " .. tostring(activeDungeon))
    end
    value38, value39, value40 = ok8, humanoid, ok10
end
if value39 or value40 or ok then
    local remotes22 = game:GetService("ReplicatedStorage")
    remotes22 = remotes22.remotes
    local changeStartValue = remotes22.changeStartValue
    changeStartValue:FireServer()
    if activeDungeon == "Desert Temple" then
        wait(3)
    end
elseif value38 then
    local workspace3 = workspace
    local value114, value115 = "WaitForChild", workspace3
    value115[value114](value115, "tier")
    game.ReplicatedStorage.remotes.readyUp:FireServer()
end
spawn(fpsBoost)

function deleteFirstBarrier()
    if game:GetService("Workspace"):FindFirstChild("dungeon")
        and game:GetService("Workspace").dungeon.initialRoom:FindFirstChild("barrier") then
        local dungeon = game:GetService("Workspace")
        dungeon = dungeon.dungeon
        dungeon.initialRoom.barrier:Destroy()
    end
end

waitForCharacter().Humanoid.AutoRotate = false
if _G.hide_projectiles then
    spawn(function()
        if game.ReplicatedStorage:FindFirstChild("projectiles") then
            game.ReplicatedStorage.projectiles:Destroy()
        end
        if game.Players.LocalPlayer.PlayerGui:FindFirstChild("abilityLocal") then
            game.Players.LocalPlayer.PlayerGui.abilityLocal.Disabled = true
            if game.Players.LocalPlayer.PlayerGui.abilityLocal:FindFirstChild("abilityLocal2") then
                game.Players.LocalPlayer.PlayerGui.abilityLocal.abilityLocal2.Disabled = true
            end
        end
        game.Players.LocalPlayer.PlayerScripts:FindFirstChild("MapSpecificLocals")
    end)
end
spawn(fn20)
spawn(fn34)
spawn(deleteFirstBarrier)
notify("https://discord.gg/wZGUsk9UXX, Discord : peanut123456 & xr1d123")
