-- Auto Taunt After Kill
-- Made by ChatGPT, Edited by Horizon 

local nextTauntTime = 0
local state = { enabled = true, chance = 100, delay = 0.5, taunt_slot = 8 }

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
    local enabled = state.enabled
    if not enabled then return end
    if not is_local_killer(event) then return end

    local chance_val = state.chance
    if math.random(1,100) > chance_val then return end

    local delay_val = state.delay
    nextTauntTime = globals.CurTime() + delay_val
end
callbacks.Register("FireGameEvent", "AutoTauntKill", handle_game_event)

---@param cmd UserCmd
local function on_create_move(cmd)
    if nextTauntTime > 0 and globals.CurTime() >= nextTauntTime then
        local slot_val = state.taunt_slot
        client.Command(string.format("taunt %i", slot_val), false)
        print("Auto Taunt: Executed taunt slot " .. tostring(slot_val))
        nextTauntTime = 0
    end
end
callbacks.Register("CreateMove", "AutoTauntMove", on_create_move)

-- ===== Overlay ===== --
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
    draw.Text(win.x + 12, win.y + 66, "Chance: " .. tostring(state.chance) .. "%   (<- / ->)")
    draw.Text(win.x + 12, win.y + 92, string.format("Delay: %.1fs   (Up / Down)", state.delay))
    draw.Text(win.x + 12, win.y + 118, "Taunt Slot: " .. tostring(state.taunt_slot) .. "   (PgUp / PgDn)")

    draw.Color(180, 180, 180, 180)
    draw.Text(win.x + 12, win.y + win.h - 22, "Use keys while menu is open")
end
callbacks.Register("Draw", "AutoTauntDraw", DrawOverlay)

-- keyboard controls --
callbacks.Register("CreateMove", "AutoTauntInput", function(cmd)
    if not gui.IsMenuOpen() then return end
    if input.IsButtonDown(KEY_LEFT) then state.chance = math.max(0, state.chance - 1) end
    if input.IsButtonDown(KEY_RIGHT) then state.chance = math.min(100, state.chance + 1) end
    if input.IsButtonDown(KEY_UP) then state.delay = math.min(5, math.floor((state.delay + 0.1) * 10 + 0.5) / 10) end
    if input.IsButtonDown(KEY_DOWN) then state.delay = math.max(0, math.floor((state.delay - 0.1) * 10 + 0.5) / 10) end
    if input.IsButtonDown(KEY_PAGEUP) then state.taunt_slot = math.min(8, state.taunt_slot + 1) end
    if input.IsButtonDown(KEY_PAGEDOWN) then state.taunt_slot = math.max(0, state.taunt_slot - 1) end
    if input.IsButtonDown(KEY_ENTER) then
        local t = globals.RealTime()
        if t - lastKeyToggle > 0.2 then
            state.enabled = not state.enabled
            lastKeyToggle = t
        end
    end
end)

--- Unload callback --
callbacks.Register("Unload", function()
    --- Unregister the named callbacks
    --- Just in case Lmaobox doesn't do it for us
    callbacks.Unregister("CreateMove", "AutoTauntInput")
    callbacks.Unregister("CreateMove", "AutoTauntMove")
    callbacks.Unregister("FireGameEvent", "AutoTauntKill")

    --- free it
    state = nil

    --- ask the garbage collector to free the unused memory
    collectgarbage("collect")

    print("Auto Taunt unloaded!")
end)

-- ===== Loaded message ===== --
print("Auto Taunt After Kill loaded!")