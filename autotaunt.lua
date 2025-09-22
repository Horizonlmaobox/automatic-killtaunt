-- Auto Taunt After Kill (finalized)
-- Uses native Lmaobox GUI if available, otherwise falls back to a prettier overlay panel.
-- Made by ChatGPT, Edited by Horizon 
local nextTauntTime = 0

-- candidate gui.Reference paths to try
local candidate_refs = {
    {"Misc", "Enhancement"},
    {"Misc", "General"},
    {"Misc"},
    {"Visuals"},
    {"Visuals", "World"},
    {"Visuals", "Other"},
    {"Aimbot"},
    {"Aimbot", "Anti Aim"},
    {"Settings"},
    {"Lua"},
    {"Scripts"},
    {"Config"},
    {"Menu"}
}

local function try_reference(path)
    local ok, res = pcall(gui.Reference, table.unpack(path))
    if ok and res ~= nil then
        return res
    end
    return nil
end

local parentRef, parentPath = nil, nil
for _,p in ipairs(candidate_refs) do
    local r = try_reference(p)
    if r then
        parentRef, parentPath = r, p
        break
    end
end

local using_native_gui = false
local controls = {}

if parentRef ~= nil then
    local success, grp = pcall(gui.Groupbox, parentRef, "Auto Taunt After Kill", 15, 300, 270, 200)
    if success and grp ~= nil then
        using_native_gui = true
        controls.enable = gui.Checkbox(grp, "autotaunt.enable", "Enable Auto Taunt", true)
        controls.chance = gui.Slider(grp, "autotaunt.chance", "Taunt Chance %", 100, 0, 100)
        local ok_delay
        ok_delay, controls.delay = pcall(gui.Slider, grp, "autotaunt.delay", "Delay (s)", 0.5, 0, 5, 0.1)
        if not ok_delay then
            controls.delay = gui.Slider(grp, "autotaunt.delay", "Delay (s)", 0.5, 0, 5)
        end
        controls.slot = gui.Slider(grp, "autotaunt.slot", "Taunt Slot", 8, 1, 8)
        print("Auto Taunt: attached native GUI to gui.Reference(" .. table.concat(parentPath, " -> ") .. ")")
    else
        print("Auto Taunt: gui.Reference found, but Groupbox failed -> fallback overlay.")
        parentRef = nil
    end
else
    print("Auto Taunt: no gui.Reference parent found -> fallback overlay.")
end

-- ===== Core Taunt Logic =====
local function is_local_killer(event)
    if event:GetName() ~= "player_death" then return false end
    local me = entities.GetLocalPlayer()
    if not me then return false end
    local attacker = entities.GetByUserID(event:GetInt("attacker"))
    if not attacker then return false end
    return attacker:GetIndex() == me:GetIndex()
end

local function handle_game_event(event)
    local enabled = using_native_gui and controls.enable:GetValue() or state.enabled
    if not enabled then return end
    if not is_local_killer(event) then return end

    local chance_val = using_native_gui and controls.chance:GetValue() or state.chance
    if math.random(1,100) > chance_val then return end

    local delay_val = using_native_gui and (controls.delay and controls.delay:GetValue() or 0.5) or state.delay
    nextTauntTime = globals.CurTime() + delay_val
end
callbacks.Register("FireGameEvent", "AutoTauntKill", handle_game_event)

local function on_create_move(cmd)
    if nextTauntTime > 0 and globals.CurTime() >= nextTauntTime then
        local slot_val = using_native_gui and controls.slot:GetValue() or state.taunt_slot
        client.Command("taunt " .. tostring(slot_val), false)
        print("Auto Taunt: Executed taunt slot " .. tostring(slot_val))
        nextTauntTime = 0
    end
end
callbacks.Register("CreateMove", "AutoTauntMove", on_create_move)

-- ===== Prettier Fallback Overlay =====
state = { enabled = true, chance = 100, delay = 0.5, taunt_slot = 8 }

if not using_native_gui then
    local win = { x = 220, y = 160, w = 320, h = 160 }
    local titleFont = draw.CreateFont("Verdana", 16, 800)
    local textFont  = draw.CreateFont("Verdana", 14, 500)
    local lastKeyToggle = 0

    local function DrawOverlay()
        if not gui.IsMenuOpen() then return end

        -- background
        draw.Color(40, 0, 60, 220)
        draw.FilledRect(win.x, win.y, win.x + win.w, win.y + win.h)

        -- header gradient + outline
        draw.FilledRectFade(win.x, win.y, win.x + win.w, win.y + 28, 255, 100, true)
        draw.Color(120, 40, 160, 255)
        draw.OutlinedRect(win.x, win.y, win.x + win.w, win.y + win.h)

        -- title
        draw.SetFont(titleFont)
        draw.Color(255, 255, 255, 255)
        draw.Text(win.x + 12, win.y + 6, "Auto Taunt After Kill")

        -- body
        draw.SetFont(textFont)
        draw.Color(230, 230, 230, 255)
        draw.Text(win.x + 12, win.y + 40, (state.enabled and "[x]" or "[ ]") .. " Enabled   (Enter)")
        draw.Text(win.x + 12, win.y + 66, "Chance: " .. tostring(state.chance) .. "%   (← / →)")
        draw.Text(win.x + 12, win.y + 92, string.format("Delay: %.1fs   (Up / Down)", state.delay))
        draw.Text(win.x + 12, win.y + 118, "Taunt Slot: " .. tostring(state.taunt_slot) .. "   (PgUp / PgDn)")

        draw.Color(180, 180, 180, 180)
        draw.Text(win.x + 12, win.y + win.h - 22, "Use keys while menu is open")
    end
    callbacks.Register("Draw", "AutoTauntFallback_Draw", DrawOverlay)

    -- keyboard controls
    callbacks.Register("CreateMove", "AutoTauntFallback_Input", function(cmd)
        if not gui.IsMenuOpen() then return end
        if input.IsButtonDown(KEY_LEFT) then state.chance = math.max(0, state.chance - 1) end
        if input.IsButtonDown(KEY_RIGHT) then state.chance = math.min(100, state.chance + 1) end
        if input.IsButtonDown(KEY_UP) then state.delay = math.min(5, math.floor((state.delay + 0.1) * 10 + 0.5) / 10) end
        if input.IsButtonDown(KEY_DOWN) then state.delay = math.max(0, math.floor((state.delay - 0.1) * 10 + 0.5) / 10) end
        if input.IsButtonDown(KEY_PAGEUP) then state.taunt_slot = math.min(8, state.taunt_slot + 1) end
        if input.IsButtonDown(KEY_PAGEDOWN) then state.taunt_slot = math.max(1, state.taunt_slot - 1) end
        if input.IsButtonDown(KEY_ENTER) then
            local t = globals.RealTime()
            if t - lastKeyToggle > 0.2 then
                state.enabled = not state.enabled
                lastKeyToggle = t
            end
        end
    end)
end

-- ===== Loaded message =====
if using_native_gui then
    print("Auto Taunt After Kill loaded with native GUI (see: " .. table.concat(parentPath, " -> ") .. ").")
else
    print("Auto Taunt After Kill loaded in fallback mode (pretty overlay).")
end
