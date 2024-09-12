util.ensure_package_is_installed("lua/auto-updater")
local auto_updater = require("auto-updater")
auto_updater.run_auto_update({
    source_url="https://github.com/SXZenith/BootyScript/blob/main/BootyScript.lua",
    script_relpath=SCRIPT_RELPATH,
})

util.require_natives("3095a")
util.require_natives("2944a", "g")
util.require_natives("1627063482")
util.require_natives("1672190175")

function show_startup_message()    
    util.toast("Hey Booty Bandit!")
end
show_startup_message()

local function request_model(hash, timeout)
    local end_time = os.time() + (timeout or 5)
    STREAMING.REQUEST_MODEL(hash)
    while not STREAMING.HAS_MODEL_LOADED(hash) and end_time >= os.time() do
        util.yield()
    end
    return STREAMING.HAS_MODEL_LOADED(hash)
end

local function request_control(entity, timeout)
    local end_time = os.time() + (timeout or 5)
    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)
    while not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity) and end_time >= os.time() do
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)
        util.yield()
    end
    return NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity)
end

local function get_vehicle_ped_is_in(ped, includeLastVehicle)
    if includeLastVehicle or PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
        return PED.GET_VEHICLE_PED_IS_IN(ped, false)
    end
    return 0
end

-- MAIN MENU tabs ----------
menu.divider(menu.my_root(), "--- Booty Script ---")
local self_tab = menu.list(menu.my_root(), "Self", {}, "")
local veh_tab = menu.list(menu.my_root(), "Vehicle", {}, "")
local fun_tab = menu.list(menu.my_root(), "Fun", {}, "")
local chaos_tab = menu.list(menu.my_root(), "Chaos", {}, "")
local world_tab = menu.list(menu.my_root(), "World", {}, "")
local anim_tab = menu.list(menu.my_root(), "Animations", {}, "")

-- SELF TAB ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local movement_menu = menu.list(self_tab, "Movement", {""}, "Player movement options")

local finger_menu = menu.list(self_tab, "Godlike Finger", {"godlikefinger"}, "Godlike Finger Options.\n(not to be confused with God Finger)")
--Shock Finger
read_global = {
	byte = function(global)
		local address = memory.script_global(global)
		return memory.read_byte(address)
	end,
	int = function(global)
		local address = memory.script_global(global)
		return memory.read_int(address)
	end,
	float = function(global)
		local address = memory.script_global(global)
		return memory.read_float(address)
	end,
	string = function(global)
		local address = memory.script_global(global)
		return memory.read_string(address)
	end
}

write_global = {
	byte = function(global, value)
		local address = memory.script_global(global)
		memory.write_byte(address, value)
	end,
	int = function(global, value)
		local address = memory.script_global(global)
		memory.write_int(address, value)
	end,
	float = function(global, value)
		local address = memory.script_global(global)
		memory.write_float(address, value)
	end
}

local function is_player_pointing()
	return read_global.int(4521801 + 932) == 3
end

function get_offset_from_cam(dist)
	local rot = GET_FINAL_RENDERED_CAM_ROT(2)
	local pos = GET_FINAL_RENDERED_CAM_COORD()
	local dir = rot:toDir()
	dir:mul(dist)
	local offset = v3.new(pos)
	offset:add(dir)
	return offset
end

function get_raycast_result(dist, flag)
	local result = {}
	flag = flag or 4294967295
	local didHit = memory.alloc(1)
	local endCoords = v3.new()
	local normal = v3.new()
	local hitEntity = memory.alloc_int()
	local camPos = GET_FINAL_RENDERED_CAM_COORD()
	local offset = get_offset_from_cam(dist)
	local handle = START_EXPENSIVE_SYNCHRONOUS_SHAPE_TEST_LOS_PROBE(
		camPos.x, camPos.y, camPos.z,
		offset.x, offset.y, offset.z,
		flag,
		players.user_ped(), 7
	)
	GET_SHAPE_TEST_RESULT(handle, didHit, endCoords, normal, hitEntity)
	result.didHit = memory.read_byte(didHit) ~= 0
	result.endCoords = endCoords
	result.surfaceNormal = normal
	result.hitEntity = memory.read_int(hitEntity)
	return result
end

local function draw_line(start, to, colour)
	DRAW_LINE(start.x, start.y, start.z, to.x, to.y, to.z, colour.r, colour.g, colour.b, colour.a)
end

local function draw_rect(pos0, pos1, pos2, pos3, colour)
	DRAW_POLY(pos0.x, pos0.y, pos0.z, pos1.x, pos1.y, pos1.z, pos3.x, pos3.y, pos3.z, colour.r, colour.g, colour.b, colour.a)
	DRAW_POLY(pos3.x, pos3.y, pos3.z, pos2.x, pos2.y, pos2.z, pos0.x, pos0.y, pos0.z, colour.r, colour.g, colour.b, colour.a)
end

function draw_bounding_box(entity, showPoly, colour)
	if not DOES_ENTITY_EXIST(entity) then
		return
	end
	colour = colour or {r = 0, g = 0, b = 255, a = 255}
	local min = v3.new()
	local max = v3.new()
	GET_MODEL_DIMENSIONS(GET_ENTITY_MODEL(entity), min, max)
	min:abs(); max:abs()
	local upperLeftRear = GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, -max.x, -max.y, max.z)
	local upperRightRear = GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, min.x, -max.y, max.z)
	local lowerLeftRear = GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, -max.x, -max.y, -min.z)
	local lowerRightRear = GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, min.x, -max.y, -min.z)
	draw_line(upperLeftRear, upperRightRear, colour)
	draw_line(lowerLeftRear, lowerRightRear, colour)
	draw_line(upperLeftRear, lowerLeftRear, colour)
	draw_line(upperRightRear, lowerRightRear, colour)
	local upperLeftFront = GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, -max.x, min.y, max.z)
	local upperRightFront = GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, min.x, min.y, max.z)
	local lowerLeftFront = GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, -max.x, min.y, -min.z)
	local lowerRightFront = GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, min.x, min.y, -min.z)
	draw_line(upperLeftFront, upperRightFront, colour)
	draw_line(lowerLeftFront, lowerRightFront, colour)
	draw_line(upperLeftFront, lowerLeftFront, colour)
	draw_line(upperRightFront, lowerRightFront, colour)
	draw_line(upperLeftRear, upperLeftFront, colour)
	draw_line(upperRightRear, upperRightFront, colour)
	draw_line(lowerLeftRear, lowerLeftFront, colour)
	draw_line(lowerRightRear, lowerRightFront, colour)
	if type(showPoly) ~= "boolean" or showPoly then
		draw_rect(lowerLeftRear, upperLeftRear, lowerLeftFront, upperLeftFront, colour)
		draw_rect(upperRightRear, lowerRightRear, upperRightFront, lowerRightFront, colour)
		draw_rect(lowerLeftFront, upperLeftFront, lowerRightFront, upperRightFront, colour)
		draw_rect(upperLeftRear, lowerLeftRear, upperRightRear, lowerRightRear, colour)
		draw_rect(upperRightRear, upperRightFront, upperLeftRear, upperLeftFront, colour)
		draw_rect(lowerRightFront, lowerRightRear, lowerLeftFront, lowerLeftRear, colour)
	end
end

function SetBit(bits, place)
	return (bits | (1 << place))
end

function ClearBit(bits, place)
	return (bits & ~(1 << place))
end

function set_explosion_proof(entity, value)
	local pEntity = entities.handle_to_pointer(entity)
	if pEntity == 0 then return end
	local damageBits = memory.read_uint(pEntity + 0x188)
	damageBits = value and SetBit(damageBits, 11) or ClearBit(damageBits, 11)
	memory.write_uint(pEntity + 0x188, damageBits)
end

function newTimer()
	local self = {
		start = util.current_time_millis(),
		m_enabled = false,
	}
	local function reset()
		self.start = util.current_time_millis()
		self.m_enabled = true
	end
	local function elapsed()
		return util.current_time_millis() - self.start
	end
	local function disable() self.m_enabled = false end
	local function isEnabled() return self.m_enabled end
	return
	{
		isEnabled = isEnabled,
		reset = reset,
		elapsed = elapsed,
		disable = disable,
	}
end

function request_control_once(entity)
	if not NETWORK_IS_IN_SESSION() then
		return true
	end
	local netId = NETWORK_GET_NETWORK_ID_FROM_ENTITY(entity)
	SET_NETWORK_ID_CAN_MIGRATE(netId, true)
	return NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)
end
local function apply_shock(entity)
    if not DOES_ENTITY_EXIST(entity) then return end
    request_control_once(entity)
    local playerPed = players.user_ped()
    local playerCoords = GET_ENTITY_COORDS(playerPed, true)
    local entityCoords = GET_ENTITY_COORDS(entity, true)
    SHOOT_SINGLE_BULLET_BETWEEN_COORDS(
        playerCoords.x, playerCoords.y, playerCoords.z,
        entityCoords.x, entityCoords.y, entityCoords.z,
        1,        -- Damage (keep it low to simulate tazer effect)
        true,     -- Is it the player's shot
        util.joaat("weapon_stungun_mp"),  -- Stungun weapon hash
        playerPed,  -- The shooter (player)
        true,     -- Should the shot cause damage
        false,    -- Should the shot use vehicle-related logic
        -1        -- Speed (default bullet speed)
    )
end

local shockerToggle = finger_menu:toggle_loop("Shock Finger", {}, "Point at a player to shock/taze them.", function()
    if is_player_pointing() then
        write_global.int(4521801 + 937, GET_NETWORK_TIME())
        if not targetEntity then
            local flag = 8 | 2 | 4 | 16
            local raycastResult = get_raycast_result(500.0, flag)
            if raycastResult.didHit and DOES_ENTITY_EXIST(raycastResult.hitEntity) then
                targetEntity = raycastResult.hitEntity
            end
        else
            apply_shock(targetEntity)
            draw_bounding_box(targetEntity, false, {r = 0, g = 0, b = 255, a = 255})
        end
    elseif targetEntity then
        targetEntity = nil
    end
end)

--The Phazer
local function apply_raygun(entity)
    if not DOES_ENTITY_EXIST(entity) then return end
    request_control_once(entity)
    local playerPed = players.user_ped()
    local playerCoords = GET_ENTITY_COORDS(playerPed, true)
    local entityCoords = GET_ENTITY_COORDS(entity, true)
    SHOOT_SINGLE_BULLET_BETWEEN_COORDS(
        playerCoords.x, playerCoords.y, playerCoords.z,
        entityCoords.x, entityCoords.y, entityCoords.z,
        1,        -- Damage (keep it low to simulate tazer effect)
        true,     -- Is it the player's shot
        util.joaat("weapon_raypistol"),  -- Raygun weapon hash
        playerPed,  -- The shooter (player)
        true,     -- Should the shot cause damage
        false,    -- Should the shot use vehicle-related logic
        -1        -- Speed (default bullet speed)
    )
end

local raygunToggle = finger_menu:toggle_loop("Raygun Finger", {}, "Point at a player to raygun them.", function()
    if is_player_pointing() then
        write_global.int(4521801 + 937, GET_NETWORK_TIME())
        if not targetEntity then
            local flag = 8 | 2 | 4 | 16
            local raycastResult = get_raycast_result(500.0, flag)
            if raycastResult.didHit and DOES_ENTITY_EXIST(raycastResult.hitEntity) then
                targetEntity = raycastResult.hitEntity
            end
        else
            apply_raygun(targetEntity)
            draw_bounding_box(targetEntity, false, {r = 0, g = 0, b = 255, a = 255})
        end
    elseif targetEntity then
        targetEntity = nil
    end
end)

-- Fire Finger
local function apply_fire(entity)
    if not DOES_ENTITY_EXIST(entity) then return end
    request_control_once(entity)
    
    local entityCoords = GET_ENTITY_COORDS(entity, true)
    local molotovHash = util.joaat("p_molotov_01")
    local molotov = CREATE_OBJECT(molotovHash, entityCoords.x, entityCoords.y, entityCoords.z, true, true, false)
    local offset = v3.new(0, 0, 1.0)  -- Adjust the offset as needed
    SET_ENTITY_COORDS_NO_OFFSET(molotov, entityCoords.x, entityCoords.y, entityCoords.z + offset.z, true, true, true)
    -- Add a delay before the explosion
    util.yield(1000)  -- Delay for 1 second, adjust as needed
    ADD_EXPLOSION(entityCoords.x, entityCoords.y, entityCoords.z, 3, 1.0, true, false, 1.0)  -- Explosion type 3 is fire
    if DOES_ENTITY_EXIST(molotov) then
        DELETE_OBJECT(molotov)
    end
end

local fireToggle = finger_menu:toggle_loop("Fire Finger", {}, "Point at a player to set them on fire.", function()
    if is_player_pointing() then
        write_global.int(4521801 + 937, GET_NETWORK_TIME())
        if not targetEntity then
            local flag = 8 | 2 | 4 | 16
            local raycastResult = get_raycast_result(500.0, flag)
            if raycastResult.didHit and DOES_ENTITY_EXIST(raycastResult.hitEntity) then
                targetEntity = raycastResult.hitEntity
            end
        else
            apply_fire(targetEntity)
            draw_bounding_box(targetEntity, false, {r = 0, g = 0, b = 255, a = 255})
        end
    elseif targetEntity then
        targetEntity = nil
    end
end)

-- The Snowball Shooter
local function apply_snowballs(entity)
    if not DOES_ENTITY_EXIST(entity) then return end
    request_control_once(entity)
    local playerPed = players.user_ped()
    local playerCoords = GET_ENTITY_COORDS(playerPed, true)
    local entityCoords = GET_ENTITY_COORDS(entity, true)
    SHOOT_SINGLE_BULLET_BETWEEN_COORDS(
        playerCoords.x, playerCoords.y, playerCoords.z,
        entityCoords.x, entityCoords.y, entityCoords.z,
        1,        -- Damage (keep it low as we're simulating snowballs)
        true,     -- Is it the player's shot
        util.joaat("weapon_snowball"),  -- Snowball weapon hash
        playerPed,  -- The shooter (player)
        true,     -- Should the shot cause damage
        false,    -- Should the shot use vehicle-related logic
        -1        -- Speed (default bullet speed)
    )
end

local snowballToggle = finger_menu:toggle_loop("Snowball Finger", {}, "Point at a player to shoot snowballs at them.", function()
    if is_player_pointing() then
        write_global.int(4521801 + 937, GET_NETWORK_TIME())
        if not targetEntity then
            local flag = 8 | 2 | 4 | 16
            local raycastResult = get_raycast_result(500.0, flag)
            if raycastResult.didHit and DOES_ENTITY_EXIST(raycastResult.hitEntity) then
                targetEntity = raycastResult.hitEntity
            end
        end
        if targetEntity then
            local interval = 1000  -- Time between snowballs in milliseconds
            while is_player_pointing() and DOES_ENTITY_EXIST(targetEntity) do
                apply_snowballs(targetEntity)
                util.yield(interval)
            end
        end
    else
        targetEntity = nil
    end
end)

-- Firework Finger
local function apply_firework(entity)
    if not DOES_ENTITY_EXIST(entity) then return end
    request_control_once(entity)
    local playerPed = players.user_ped()
    local playerCoords = GET_ENTITY_COORDS(playerPed, true)
    local entityCoords = GET_ENTITY_COORDS(entity, true)
    SHOOT_SINGLE_BULLET_BETWEEN_COORDS(
        playerCoords.x, playerCoords.y, playerCoords.z,
        entityCoords.x, entityCoords.y, entityCoords.z,
        1,        
        true,     
        util.joaat("weapon_firework"),  
        playerPed,  
        true,     
        false,    
        -1        
    )
end

local fireworkToggle = finger_menu:toggle_loop("Firework Finger", {}, "Point at a player to shoot fireworks at them.", function()
    if is_player_pointing() then
        write_global.int(4521801 + 937, GET_NETWORK_TIME())
        if not targetEntity then
            local flag = 8 | 2 | 4 | 16
            local raycastResult = get_raycast_result(500.0, flag)
            if raycastResult.didHit and DOES_ENTITY_EXIST(raycastResult.hitEntity) then
                targetEntity = raycastResult.hitEntity
            end
        end
        if targetEntity then
            local interval = 1000
            while is_player_pointing() and DOES_ENTITY_EXIST(targetEntity) do
                apply_firework(targetEntity)
                util.yield(interval)
            end
        end
    else
        targetEntity = nil
    end
end)

-- RPG Finger
local function apply_rpg(entity)
    if not DOES_ENTITY_EXIST(entity) then return end
    request_control_once(entity)
    local playerPed = players.user_ped()
    local playerCoords = GET_ENTITY_COORDS(playerPed, true)
    local entityCoords = GET_ENTITY_COORDS(entity, true)
    SHOOT_SINGLE_BULLET_BETWEEN_COORDS(
        playerCoords.x, playerCoords.y, playerCoords.z,
        entityCoords.x, entityCoords.y, entityCoords.z,
        1,        
        true,     
        util.joaat("weapon_rpg"),  
        playerPed,  
        true,     
        false,    
        -1        
    )
end

local rpgToggle = finger_menu:toggle_loop("RPG Finger", {}, "Point at a player to shoot an RPG at them.", function()
    if is_player_pointing() then
        write_global.int(4521801 + 937, GET_NETWORK_TIME())
        if not targetEntity then
            local flag = 8 | 2 | 4 | 16
            local raycastResult = get_raycast_result(500.0, flag)
            if raycastResult.didHit and DOES_ENTITY_EXIST(raycastResult.hitEntity) then
                targetEntity = raycastResult.hitEntity
            end
        end
        if targetEntity then
            local interval = 1000
            while is_player_pointing() and DOES_ENTITY_EXIST(targetEntity) do
                apply_rpg(targetEntity)
                util.yield(interval)
            end
        end
    else
        targetEntity = nil
    end
end)

-- Railgun Finger
local function apply_railgun(entity)
    if not DOES_ENTITY_EXIST(entity) then return end
    request_control_once(entity)
    local playerPed = players.user_ped()
    local playerCoords = GET_ENTITY_COORDS(playerPed, true)
    local entityCoords = GET_ENTITY_COORDS(entity, true)
    SHOOT_SINGLE_BULLET_BETWEEN_COORDS(
        playerCoords.x, playerCoords.y, playerCoords.z,
        entityCoords.x, entityCoords.y, entityCoords.z,
        1,        
        true,     
        util.joaat("weapon_railgun"),  
        playerPed,  
        true,     
        false,    
        -1        
    )
end

local railgunToggle = finger_menu:toggle_loop("Railgun Finger", {}, "Point at a player to shoot a railgun at them.", function()
    if is_player_pointing() then
        write_global.int(4521801 + 937, GET_NETWORK_TIME())
        if not targetEntity then
            local flag = 8 | 2 | 4 | 16
            local raycastResult = get_raycast_result(500.0, flag)
            if raycastResult.didHit and DOES_ENTITY_EXIST(raycastResult.hitEntity) then
                targetEntity = raycastResult.hitEntity
            end
        end
        if targetEntity then
            local interval = 1000
            while is_player_pointing() and DOES_ENTITY_EXIST(targetEntity) do
                apply_railgun(targetEntity)
                util.yield(interval)
            end
        end
    else
        targetEntity = nil
    end
end)

--Ghost
menu.toggle(self_tab, "Ghost", { "bghost" },
    "Invisibility and Off The Radar",
    function(state)
        menu.trigger_command(
            menu.ref_by_path("Self>Appearance>Invisibility>" .. (state and "Enabled" or "Disabled"), 38), "")
        menu.set_value(menu.ref_by_path("Online>Off The Radar", 38), state)
    end
)

--Ghost
menu.toggle(self_tab, "Ghost2", { "bghost2" },
    "Invisibility and Off The Radar",
    function(state)
        menu.trigger_command(
            menu.ref_by_path("Self>Appearance>Invisibility>" .. (state and "Enabled" or "Disabled"), 38), "")
        menu.set_value(menu.ref_by_path("Online>Off The Radar", 38), state)
    end
)

--Fast Roll
menu.toggle_loop(movement_menu, "Fast Roll", {"fastroll"}, "Roll faster when aiming.", function()
    STATS.STAT_SET_INT(util.joaat("MP"..util.get_char_slot().."_SHOOTING_ABILITY"), 200, true)
end)

--Better Super Jump
local jumpVelocity = 10.0
local superJumpActive = false
local toggleSuperJump = menu.toggle(movement_menu, "Better Super Jump", {}, "Allows you to keep jumping as long as you hold or tap the jump button.", function(toggle)
    superJumpActive = toggle
    local playerPed = PLAYER.PLAYER_PED_ID()
    while superJumpActive do
        if PAD.IS_CONTROL_PRESSED(0, 22) then -- Jump button pressed
            local velocity = ENTITY.GET_ENTITY_VELOCITY(playerPed)
            ENTITY.SET_ENTITY_VELOCITY(playerPed, velocity.x, velocity.y, jumpVelocity)
        end
        util.yield()
    end
end)
menu.slider(movement_menu, "Super jump Height", {""}, "Adjusts the height of Better Super Jump.", 5, 50, 10, 5, function(value)
    jumpVelocity = value
end)


--Crawl/Crouch
local function request_anim(anim_dict)
    if not STREAMING.HAS_ANIM_DICT_LOADED(anim_dict) then
        STREAMING.REQUEST_ANIM_DICT(anim_dict)
        local timeout_ms = util.current_time_millis() + 3000
        while timeout_ms > util.current_time_millis() and not STREAMING.HAS_ANIM_DICT_LOADED(anim_dict) do
            util.yield()
        end
    end
    return STREAMING.HAS_ANIM_DICT_LOADED(anim_dict)
end

function startCrouching(ped)
    if not ped then
        ped = players.user_ped()
    end

    is_crouched = true

    PED.SET_PED_MOVEMENT_CLIPSET(ped, "move_ped_crouched", 0.80)
    PED.SET_PED_STRAFE_CLIPSET(ped, "move_ped_crouched_strafing")
end

function stopCrouching(ped)
    if not ped then
        ped = players.user_ped()
    end

    is_crouched = false

    if STREAMING.HAS_ANIM_SET_LOADED("move_ped_crouched") then
        STREAMING.REMOVE_ANIM_SET("move_ped_crouched")
    end
    PED.RESET_PED_MOVEMENT_CLIPSET(ped, 0.30)
    PED.RESET_PED_STRAFE_CLIPSET(ped)
end

menu.toggle_loop(movement_menu, "Crouch", {"CrouchToggel"}, "Press Stealth key to crouch",
    function()
        local ped = players.user_ped()
        local clip_set = "move_ped_crouched"
        STREAMING.REQUEST_ANIM_SET(clip_set)
        PAD.DISABLE_CONTROL_ACTION(0, 36, true)
        if PED.GET_PED_STEALTH_MOVEMENT(ped) then
            PED.SET_PED_STEALTH_MOVEMENT(ped, 0, "DEFAULT_ACTION")
        end
        
        if not HUD.IS_PAUSE_MENU_ACTIVE() then
            -- uncomment next line to turn firstperson off
            PAD.DISABLE_CONTROL_ACTION(0, 36, true) 
            if PAD.IS_DISABLED_CONTROL_PRESSED(0, 36) then
                if is_crouched then
                    stopCrouching(ped)
                else
                    startCrouching(ped)
                end
                util.yield(200)
            end
        end
        if is_crouched then
            if PED.IS_PED_USING_ACTION_MODE(ped) then
                PED.SET_PED_USING_ACTION_MODE(ped, false, -1, "DEFAULT_ACTION")
            end
        end
    end, function()
    stopCrouching()
    PAD.ENABLE_CONTROL_ACTION(0, 36, true)
end)

function requestAnimDict(animDict)
	while not HAS_ANIM_DICT_LOADED(animDict) do
		REQUEST_ANIM_DICT(animDict)
		yield()
	end
end

menu.toggle_loop(movement_menu, "Crawl", {"crawl"}, "Use movement keys to control where you crawl", function(toggled)
	request_anim("missfbi3_sniping")
	local dict = "move_crawl"
	local forwards = "onfront_fwd"
	local backwards = "onfront_bwd"
	request_anim(dict)
	if IS_CONTROL_PRESSED(0, 32) and not IS_ENTITY_PLAYING_ANIM(players.user_ped(), dict, forwards, 3) then
		TASK_PLAY_ANIM(players.user_ped(), dict, forwards, 2.5, 2.5, -1, 1|32, 1.0, false, false, false)
	elseif IS_CONTROL_PRESSED(0, 33) and not IS_ENTITY_PLAYING_ANIM(players.user_ped(), dict, backwards, 3) then
		TASK_PLAY_ANIM(players.user_ped(), dict, backwards, 2.5, 2.5, -1, 1|32, 1.0, false, false, false)
	elseif IS_PED_ARMED(players.user_ped(), 6) and not IS_ENTITY_PLAYING_ANIM(players.user_ped(), "missfbi3_sniping", "prone_michael", 3) and not IS_CONTROL_PRESSED(0, 32) and not IS_CONTROL_PRESSED(0, 33) then
		TASK_PLAY_ANIM(players.user_ped(), "missfbi3_sniping", "prone_michael", 2.5, 2.5, -1, 1|32, 1.0, false, false, false)
	end
end, function()
	CLEAR_PED_TASKS(players.user_ped())
end)


--Silent Steps
menu.toggle(movement_menu, "Silent Footsteps", {"silentfootsteps"}, "Makes your footsteps silent.", function(toggle)
    AUDIO.SET_PED_FOOTSTEPS_EVENTS_ENABLED(players.user_ped(), not toggle)
end)

--Slide
local slide_menu = menu.list(movement_menu, "Slide", {" "}, "EXPERIMENTAL Options to Slide around the map.")
local isSliding = false
menu.toggle(slide_menu, "Slide - Circular movement", {}, "Worst option..\nPlayer moves with movement keys, but doesn't change directions.", function(toggle)
    isSliding = toggle
    if isSliding then
        STREAMING.REQUEST_ANIM_DICT("missheistfbi3b_ig6_v2")
        while not STREAMING.HAS_ANIM_DICT_LOADED("missheistfbi3b_ig6_v2") do
            util.yield()
        end
        while isSliding do
            local playerPed = PLAYER.PLAYER_PED_ID()
            TASK.TASK_PLAY_ANIM(playerPed, "missheistfbi3b_ig6_v2", "rubble_slide_alt_gunman", 8.0, 8.0, -1, 1, 0, false, false, false)
            local velocity = ENTITY.GET_ENTITY_VELOCITY(playerPed)
            if PAD.IS_CONTROL_PRESSED(0, 32) then -- W or Up
                velocity.y = 3.0
            elseif PAD.IS_CONTROL_PRESSED(0, 33) then -- S or Down
                velocity.y = -3.0
            elseif PAD.IS_CONTROL_PRESSED(0, 34) then -- A or Left
                velocity.x = -3.0
            elseif PAD.IS_CONTROL_PRESSED(0, 35) then -- D or Right
                velocity.x = 3.0
            else
                velocity.x = 0.0
                velocity.y = 0.0
            end

            ENTITY.SET_ENTITY_VELOCITY(playerPed, velocity.x, velocity.y, velocity.z)

            util.yield(0) -- Short delay to prevent freezing
        end
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(playerPed)
    end
end)

local isSliding = false
menu.toggle(slide_menu, "Slide - Directional movement", {}, "Mediocre option..\nMove and turn with movement keys.", function(toggle)
    isSliding = toggle
    if isSliding then
        STREAMING.REQUEST_ANIM_DICT("missheistfbi3b_ig6_v2")
        while not STREAMING.HAS_ANIM_DICT_LOADED("missheistfbi3b_ig6_v2") do
            util.yield()
        end
        local fixedHeading = ENTITY.GET_ENTITY_HEADING(PLAYER.PLAYER_PED_ID()) -- Initial heading
        while isSliding do
            local playerPed = PLAYER.PLAYER_PED_ID()
            TASK.TASK_PLAY_ANIM(playerPed, "missheistfbi3b_ig6_v2", "rubble_slide_alt_gunman", 8.0, 8.0, -1, 1, 0, false, false, false)
            local velocity = ENTITY.GET_ENTITY_VELOCITY(playerPed)
            local moveInput = false
            if PAD.IS_CONTROL_PRESSED(0, 32) then -- W or Up
                velocity.y = 3.0
                fixedHeading = 0.0
                moveInput = true
            elseif PAD.IS_CONTROL_PRESSED(0, 33) then -- S or Down
                velocity.y = -3.0
                fixedHeading = 180.0
                moveInput = true
            elseif PAD.IS_CONTROL_PRESSED(0, 34) then -- A or Left
                velocity.x = -3.0
                fixedHeading = 270.0
                moveInput = true
            elseif PAD.IS_CONTROL_PRESSED(0, 35) then -- D or Right
                velocity.x = 3.0
                fixedHeading = 90.0
                moveInput = true
            else
                velocity.x = 0.0
                velocity.y = 0.0
            end
            if moveInput then
                ENTITY.SET_ENTITY_HEADING(playerPed, fixedHeading)
            end
            ENTITY.SET_ENTITY_VELOCITY(playerPed, velocity.x, velocity.y, velocity.z)
            util.yield(0)
        end
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(playerPed)
    end
end)

local isSliding = false
menu.toggle(slide_menu, "Slide - Camera movement", {}, "Best option..\nMove by holding forward key.\nShift to speed up.", function(toggle)
    isSliding = toggle
    if isSliding then
        STREAMING.REQUEST_ANIM_DICT("missheistfbi3b_ig6_v2")
        while not STREAMING.HAS_ANIM_DICT_LOADED("missheistfbi3b_ig6_v2") do
            util.yield()
        end
        while isSliding do
            local playerPed = PLAYER.PLAYER_PED_ID()
            TASK.TASK_PLAY_ANIM(playerPed, "missheistfbi3b_ig6_v2", "rubble_slide_alt_gunman", 8.0, 8.0, -1, 1, 0, false, false, false)
            local camRot = CAM.GET_GAMEPLAY_CAM_ROT(2) -- Rotation of the camera (yaw, pitch, roll)
            local heading = camRot.z -- The Z-axis rotation is the direction the camera is facing
            ENTITY.SET_ENTITY_HEADING(playerPed, heading)
            -- Base speed
            local speedMultiplier = 5.0
            if PAD.IS_CONTROL_PRESSED(0, 21) then -- L SHIFT
                speedMultiplier = 10.0 -- Increase speed multiplier when L SHIFT is pressed
            end
            if PAD.IS_CONTROL_PRESSED(0, 32) then -- W or Up
                local forwardVector = ENTITY.GET_ENTITY_FORWARD_VECTOR(playerPed)
                local velocity = {
                    x = forwardVector.x * speedMultiplier,
                    y = forwardVector.y * speedMultiplier,
                    z = 0.0 -- adjust Z to move up/down
                }
                ENTITY.SET_ENTITY_VELOCITY(playerPed, velocity.x, velocity.y, velocity.z)
            else
                -- Stop movement if W is not pressed
                ENTITY.SET_ENTITY_VELOCITY(playerPed, 0.0, 0.0, 0.0)
            end
            util.yield(0)
        end
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(playerPed)
    end
end)


--Quick Swap
menu.toggle_loop(self_tab, "Quick Swap", {"quickswap"}, "Quickly swap between weapons", function()
	if GET_IS_TASK_ACTIVE(players.user_ped(), 56) then
		FORCE_PED_AI_AND_ANIMATION_UPDATE(players.user_ped())
	end
end)

--Hulk
menu.toggle(self_tab, "Hulk", {"hulk"}, "Makes you very strong and jump high.", function(toggle)
if toggle then
menu.trigger_commands("damagemultiplier 10000")
menu.trigger_commands("superjump")
util.toast("Hulk: On")
else
menu.trigger_commands("damagemultiplier 1.01")
menu.trigger_commands("damagemultiplier 1")
menu.trigger_commands("superjump")
util.toast("Hulk: Off")
end
end)

--TP Forward
local distances = {}
for i = 1, 100 do
    table.insert(distances, tostring(i))
end

menu.action_slider(movement_menu, "TP Forward", {"tpforward"}, "Select distance and teleport forward", distances, function(index, value)
    local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(players.user_ped(), 0, tonumber(value), 0)
    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PLAYER.PLAYER_PED_ID(), pos.x, pos.y, pos.z, true, false, false)
end)

-- Missile Aimbot -- credits to Chalk
local function ls_log(content)
    if ls_debug then
        util.toast(content)
        util.log(translations.script_name_for_log .. content)
    end
end

AIM_WHITELIST = {}
function GetClosestPlayerWithRange_Whitelist(range, inair)
    local pedPointers = entities.get_all_peds_as_pointers()
    local rangesq = range * range
    local ourCoords = ENTITY.GET_ENTITY_COORDS(players.user_ped())
    local tbl = {}
    local closest_player = 0
    for i = 1, #pedPointers do
        local tarcoords = entities.get_position(pedPointers[i])
        local vdist = SYSTEM.VDIST2(ourCoords.x, ourCoords.y, ourCoords.z, tarcoords.x, tarcoords.y, tarcoords.z)
        if vdist <= rangesq then
            local handle = entities.pointer_to_handle(pedPointers[i])
            if (inair and (ENTITY.GET_ENTITY_HEIGHT_ABOVE_GROUND(handle) >= 9)) or (not inair) then --air check
                local playerID = NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(handle)
                if not AIM_WHITELIST[playerID] then
                    tbl[#tbl+1] = handle
                end
            end
        end
    end
    if tbl ~= nil then
        local dist = 999999
        for i = 1, #tbl do
            if tbl[i] ~= players.user_ped() then
                if PED.IS_PED_A_PLAYER(tbl[i]) then
                    local tarcoords = ENTITY.GET_ENTITY_COORDS(tbl[i])
                    local e = SYSTEM.VDIST2(ourCoords.x, ourCoords.y, ourCoords.z, tarcoords.x, tarcoords.y, tarcoords.z)
                    if e < dist then
                        dist = e
                        closest_player = tbl[i]
                    end
                end
            end
        end
    end
    if closest_player ~= 0 then
        return closest_player
    else
        return nil
    end
end

function GetTableFromV3Instance(v3int)
    local tbl = {x = v3.getX(v3int), y = v3.getY(v3int), z = v3.getZ(v3int)}
    return tbl
end

--Defining What is a Projectile
local function is_entity_a_projectile_all(hash)     -- All Projectile Offests
    local all_projectile_hashes = {
        util.joaat("w_ex_vehiclemissile_1"),
        util.joaat("w_ex_vehiclemissile_2"),
        util.joaat("w_ex_vehiclemissile_3"),
        util.joaat("w_ex_vehiclemissile_4"),
        util.joaat("w_ex_vehiclemortar"),
        util.joaat("w_ex_apmine"),
        util.joaat("w_ex_arena_landmine_01b"),
        util.joaat("w_ex_birdshat"),
        util.joaat("w_ex_grenadefrag"),
        util.joaat("xm_prop_x17_mine_01a"),
        util.joaat("xm_prop_x17_mine_02a"),
        util.joaat("w_ex_grenadesmoke"),
        util.joaat("w_ex_molotov"),
        util.joaat("w_ex_pe"),
        util.joaat("w_ex_pipebomb"),
        util.joaat("w_ex_snowball"),
        util.joaat("w_lr_rpg_rocket"),
        util.joaat("w_lr_homing_rocket"),
        util.joaat("w_lr_firework_rocket"),
        util.joaat("xm_prop_x17_silo_rocket_01"),
        util.joaat("w_ex_vehiclegrenade"),
        util.joaat("w_ex_vehiclemine"),
        util.joaat("w_lr_40mm"),
        util.joaat("w_smug_bomb_01"),
        util.joaat("w_smug_bomb_02"),
        util.joaat("w_smug_bomb_03"),
        util.joaat("w_smug_bomb_04"),
        util.joaat("w_am_flare"),
        util.joaat("w_arena_airmissile_01a"),
        util.joaat("w_pi_flaregun_shell"),
        util.joaat("w_smug_airmissile_01b"),
        util.joaat("w_smug_airmissile_02"),
        util.joaat("w_sr_heavysnipermk2_mag_ap2"),
        util.joaat("w_battle_airmissile_01"),
        util.joaat("gr_prop_gr_pmine_01a")
    }
    return table.contains(all_projectile_hashes, hash)
end

local function is_entity_a_missle(hash)     -- Missile Projectile Offsets
    local missle_hashes = {
        util.joaat("w_ex_vehiclemissile_1"),
        util.joaat("w_ex_vehiclemissile_2"),
        util.joaat("w_ex_vehiclemissile_3"),
        util.joaat("w_ex_vehiclemissile_4"),
        util.joaat("w_lr_rpg_rocket"),
        util.joaat("w_lr_homing_rocket"),
        util.joaat("w_lr_firework_rocket"),
        util.joaat("xm_prop_x17_silo_rocket_01"),
        util.joaat("w_arena_airmissile_01a"),
        util.joaat("w_smug_airmissile_01b"),
        util.joaat("w_smug_airmissile_02"),
        util.joaat("w_battle_airmissile_01"),
        util.joaat("h4_prop_h4_airmissile_01a")
    }
    return table.contains(missle_hashes, hash)
end

local function is_entity_a_grenade(hash)    -- Grenade Projectile Offsets
    local grenade_hashes = {
        util.joaat("w_ex_vehiclemortar"),
        util.joaat("w_ex_grenadefrag"),
        util.joaat("w_ex_grenadesmoke"),
        util.joaat("w_ex_molotov"),
        util.joaat("w_ex_pipebomb"),
        util.joaat("w_ex_snowball"),
        util.joaat("w_ex_vehiclegrenade"),
        util.joaat("w_lr_40mm")
    }
    return table.contains(grenade_hashes, hash)
end

local function is_entity_a_mine(hash)       -- Mine Projectile Offsets
    local mine_hashes = {
        util.joaat("w_ex_apmine"),
        util.joaat("w_ex_arena_landmine_01b"),
        util.joaat("w_ex_pe"),
        util.joaat("w_ex_vehiclemine"),
        util.joaat("xm_prop_x17_mine_01a"),
        util.joaat("xm_prop_x17_mine_02a"),
        util.joaat("gr_prop_gr_pmine_01a")
    }
    return table.contains(mine_hashes, hash)
end

local function is_entity_a_miscprojectile(hash)     -- Misc Projectile Offsets
    local miscproj_hashes = {
        util.joaat("w_ex_birdshat"),
        util.joaat("w_ex_snowball"),
        util.joaat("w_pi_flaregun_shell"),
        util.joaat("w_am_flare"),
        util.joaat("w_lr_ml_40mm"),
        util.joaat("w_sr_heavysnipermk2_mag_ap2")
    }
    return table.contains(miscproj_hashes, hash)
end

local function is_entity_a_bomb(hash)
   local bomb_hashes = {
        util.joaat("w_smug_bomb_01"),
        util.joaat("w_smug_bomb_02"),
        util.joaat("w_smug_bomb_03"),
        util.joaat("w_smug_bomb_04")
   } 
   return table.contains(bomb_hashes, hash)
end

object_uses = 0
local function mod_uses(type, incr)
    if incr < 0 and is_loading then
        ls_log("Not incrementing use var of type " .. type .. " by " .. incr .. "- script is loading")
        return
    end
    ls_log("Incrementing use var of type " .. type .. " by " .. incr)
    if type == "vehicle" then
        if vehicle_uses <= 0 and incr < 0 then
            return
        end
        vehicle_uses = vehicle_uses + incr
    elseif type == "pickup" then
        if pickup_uses <= 0 and incr < 0 then
            return
        end
        pickup_uses = pickup_uses + incr
    elseif type == "ped" then
        if ped_uses <= 0 and incr < 0 then
            return
        end
        ped_uses = ped_uses + incr
    elseif type == "player" then
        if player_uses <= 0 and incr < 0 then
            return
        end
        player_uses = player_uses + incr
    elseif type == "object" then
        if object_uses <= 0 and incr < 0 then
            return
        end
        object_uses = object_uses + incr
    end
end

objects_thread = util.create_thread(function(thr)
    while true do
        if object_uses > 0 then
            all_objects = entities.get_all_objects_as_handles()
            for k,obj in pairs(all_objects) do
                if is_entity_a_projectile_all(ENTITY.GET_ENTITY_MODEL(obj)) then  --Edit Proj Offsets Here
                    if projectile_spaz then 
                        local strength = 20
                        ENTITY.APPLY_FORCE_TO_ENTITY(obj, 1, math.random(-strength, strength), math.random(-strength, strength), math.random(-strength, strength), 0.0, 0.0, 0.0, 1, true, false, true, true, true)
                    end
                    if slow_projectiles then
                        ENTITY.SET_ENTITY_MAX_SPEED(obj, 0.5)
                    end
                    if vehicle_APS then
                        local gce_all_objects = entities.get_all_objects_as_handles()
                        local Range = CountermeasureAPSrange
                        local RangeSq = Range * Range
                        local EntitiesToTarget = {}
                        for index, entity in pairs(gce_all_objects) do
                            if is_entity_a_missle(ENTITY.GET_ENTITY_MODEL(entity)) or is_entity_a_grenade(ENTITY.GET_ENTITY_MODEL(entity)) then
                                local EntityCoords = ENTITY.GET_ENTITY_COORDS(entity)
                                local LocalCoords = ENTITY.GET_ENTITY_COORDS(players.user_ped())
                                local VehCoords = ENTITY.GET_ENTITY_COORDS(player_cur_car)
                                local ObjPointers = entities.get_all_objects_as_pointers()
                                local vdist = SYSTEM.VDIST2(VehCoords.x, VehCoords.y, VehCoords.z, EntityCoords.x, EntityCoords.y, EntityCoords.z)
                                if vdist <= RangeSq then
                                    EntitiesToTarget[#EntitiesToTarget+1] = entities.pointer_to_handle(ObjPointers[index])
                                end
                                if EntitiesToTarget ~= nil then
                                    local dist = 999999
                                    for i = 1, #EntitiesToTarget do
                                        local tarcoords = ENTITY.GET_ENTITY_COORDS(EntitiesToTarget[index])
                                        local e = SYSTEM.VDIST2(VehCoords.x, VehCoords.y, VehCoords.z, EntityCoords.x, EntityCoords.y, EntityCoords.z)
                                        if e < dist then
                                            dist = e
                                            closest_entity = EntitiesToTarget[index]
                                            local closestEntity = entity
                                            local ProjLocation = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(closestEntity, 0, 0, 0)
                                            local ProjRotation = ENTITY.GET_ENTITY_ROTATION(closestEntity)
                                            local lookAtProj = v3.lookAt(VehCoords, EntityCoords)
                                            STREAMING.REQUEST_NAMED_PTFX_ASSET("scr_sm_counter")
                                            STREAMING.REQUEST_NAMED_PTFX_ASSET("core") 
                                            STREAMING.REQUEST_NAMED_PTFX_ASSET("weap_gr_vehicle_weapons")
                                            if STREAMING.HAS_NAMED_PTFX_ASSET_LOADED("scr_sm_counter") and STREAMING.HAS_NAMED_PTFX_ASSET_LOADED("core") and STREAMING.HAS_NAMED_PTFX_ASSET_LOADED("veh_xs_vehicle_mods") then
                                                ENTITY.SET_ENTITY_ROTATION(entity, lookAtProj.x - 180, lookAtProj.y, lookAtProj.z, 1, true)
                                                lookAtPos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, 0, Range - 2, 0)
                                                GRAPHICS.USE_PARTICLE_FX_ASSET("scr_sm_counter")
                                                GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD("scr_sm_counter_chaff", ProjLocation.x, ProjLocation.y, ProjLocation.z, ProjRotation.x + 90, ProjRotation.y, ProjRotation.z, 1, 0, 0, 0)
                                                GRAPHICS.USE_PARTICLE_FX_ASSET("core")
                                                GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD("exp_grd_sticky", ProjLocation.x, ProjLocation.y, ProjLocation.z, ProjRotation.x - 90, ProjRotation.y, ProjRotation.z, 0.2, 0, 0, 0)
                                                GRAPHICS.USE_PARTICLE_FX_ASSET("weap_gr_vehicle_weapons")
                                                GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD("muz_mounted_turret_apc_missile", lookAtPos.x, lookAtPos.y, lookAtPos.z + .2, lookAtProj.x + 180, lookAtProj.y, lookAtProj.z, 1.3, 0, 0, 0)
                                                GRAPHICS.USE_PARTICLE_FX_ASSET("weap_gr_vehicle_weapons")
                                                GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD("muz_mounted_turret_apc", lookAtPos.x, lookAtPos.y, lookAtPos.z + .2, lookAtProj.x + 180, lookAtProj.y, lookAtProj.z, 1.3, 0, 0, 0)
                                                GRAPHICS.USE_PARTICLE_FX_ASSET("weap_gr_vehicle_weapons")
                                                GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD("muz_mounted_turret_apc_missile", lookAtPos.x, lookAtPos.y, lookAtPos.z + .2, lookAtProj.x + 180, lookAtProj.y, lookAtProj.z, 1.3, 0, 0, 0)
                                                GRAPHICS.USE_PARTICLE_FX_ASSET("weap_gr_vehicle_weapons")
                                                GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD("muz_mounted_turret_apc", lookAtPos.x, lookAtPos.y, lookAtPos.z + .2, lookAtProj.x + 180, lookAtProj.y, lookAtProj.z, 1.3, 0, 0, 0)
                                                entities.delete_by_handle(entity)
                                                APS_charges = APS_charges - 1
                                                util.toast("-BootyScript-\n\nAPS Destroyed Incoming Projectile.\n"..APS_charges.."/"..CountermeasureAPSCharges.."  APS Shells Left.")
                                                if APS_charges == 0 then
                                                    util.toast("-BootyScript-\n\nNo APS Shells Left. Reloading...")
                                                    util.yield(CountermeasureAPSTimeout)
                                                    APS_charges = CountermeasureAPSCharges
                                                    util.toast("-BootyScript-\n\nAPS Ready.")
                                                end
                                            else
                                                for i = 0, 10, 1 do
                                                    STREAMING.REQUEST_NAMED_PTFX_ASSET("scr_sm_counter")
                                                    STREAMING.REQUEST_NAMED_PTFX_ASSET("core") 
                                                    STREAMING.REQUEST_NAMED_PTFX_ASSET("veh_xs_vehicle_mods")
                                                end
                                                if not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED("scr_sm_counter") or STREAMING.HAS_NAMED_PTFX_ASSET_LOADED("core") or STREAMING.HAS_NAMED_PTFX_ASSET_LOADED("veh_xs_vehicle_mods") then
                                                    util.toast("-BootyScript-\n\nCould Not Load Particle Effect.")
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                    if homing_missles then
                        local localped = players.user_ped()
                        local localcoords = ENTITY.GET_ENTITY_COORDS(players.user_ped())
                        local forOffset = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(localped, 0, 5, 0)
                        RRocket = OBJECT.GET_CLOSEST_OBJECT_OF_TYPE(forOffset.x, forOffset.y, forOffset.z, 10, HomingM_SelectedMissle, false, true, true, true)
                        local p
                        p = GetClosestPlayerWithRange_Whitelist(homing_missle_range, false)
                        local ppcoords = ENTITY.GET_ENTITY_COORDS(p)
                        util.create_thread(function ()
                            local plocalized = p
                            local msl = RRocket
                            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(msl)
                            if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(msl) then
                                for i = 1, 10 do
                                    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(msl)
                                end
                            end
                            if not PED.IS_PED_DEAD_OR_DYING(plocalized) then
                                while ENTITY.DOES_ENTITY_EXIST(msl) do
                                    local pcoords2 = ENTITY.GET_ENTITY_COORDS(plocalized)
                                    local pcoords = GetTableFromV3Instance(pcoords2)
                                    local lc2 = ENTITY.GET_ENTITY_COORDS(msl)
                                    local lc = GetTableFromV3Instance(lc2)
                                    local look2 = v3.lookAt(lc2, pcoords2)
                                    local look = GetTableFromV3Instance(look2)
                                    local dir2 = v3.toDir(look2)
                                    local dir = GetTableFromV3Instance(dir2) 
                                    if ENTITY.DOES_ENTITY_EXIST(msl) then
                                        if (ENTITY.HAS_ENTITY_CLEAR_LOS_TO_ENTITY(msl, plocalized, 17)) then
                                            ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(msl, 1, 0, 1, 0, true, true, false, true)
                                            ENTITY.SET_ENTITY_ROTATION(msl, look.x, look.y, look.z, 2, true)
                                        end
                                    end
                                    util.yield()
                                end  
                            end   
                        end)
                    end
                    if missle_MCLOS then
                        local localped = players.user_ped()
                        local localcoords = ENTITY.GET_ENTITY_COORDS(players.user_ped())
                        local forOffset = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(localped, 0, 5, 0)
                        RRocket = OBJECT.GET_CLOSEST_OBJECT_OF_TYPE(forOffset.x, forOffset.y, forOffset.z, 10, MCLOS_SelectedMissle, false, true, true, true)
                        local mclos_msl_rot = ENTITY.GET_ENTITY_ROTATION(RRocket)
                        local mclos_look_r = mclos_msl_rot.x
                        local mclos_look_p = mclos_msl_rot.y
                        local mclos_look_y = mclos_msl_rot.z
                        util.create_thread(function ()
                            local msl = RRocket
                            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(msl)
                            if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(msl) then
                                for i = 1, 10 do
                                    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(msl)
                                end
                            end     
                            while ENTITY.DOES_ENTITY_EXIST(msl) do       
                                if ENTITY.GET_ENTITY_SPEED(msl) == 0 then
                                    local mclos_msl_rot = ENTITY.GET_ENTITY_ROTATION(RRocket)
                                    mclos_look_p = mclos_msl_rot.x
                                    mclos_look_r = mclos_msl_rot.y
                                    mclos_look_y = mclos_msl_rot.z
                                end  
                                if ENTITY.DOES_ENTITY_EXIST(msl) then
                                    if not MCLOS_mouseControl then
                                        if PAD.IS_CONTROL_PRESSED(MCLOS_controlModeU, MCLOS_controlModeU) then --Nmp 8
                                            mclos_look_p = mclos_look_p + MCLOS_TurnSpeed
                                            ENTITY.SET_ENTITY_ROTATION(msl, mclos_look_p, 0, mclos_look_y, 1, true)
                                        end
                                        if PAD.IS_CONTROL_PRESSED(MCLOS_controlModeD, MCLOS_controlModeD) then --Nmp 5
                                            mclos_look_p = mclos_look_p - MCLOS_TurnSpeed
                                            ENTITY.SET_ENTITY_ROTATION(msl, mclos_look_p, 0, mclos_look_y, 1, true)
                                        end
                                        if PAD.IS_CONTROL_PRESSED(MCLOS_controlModeL, MCLOS_controlModeL) then --Nmp 4
                                            mclos_look_y = mclos_look_y + MCLOS_TurnSpeed
                                            ENTITY.SET_ENTITY_ROTATION(msl, mclos_look_p, 0, mclos_look_y, 1, true)
                                        end
                                        if PAD.IS_CONTROL_PRESSED(MCLOS_controlModeR, MCLOS_controlModeR) then --Nmp 6
                                            mclos_look_y = mclos_look_y - MCLOS_TurnSpeed
                                            ENTITY.SET_ENTITY_ROTATION(msl, mclos_look_p, 0, mclos_look_y, 1, true)
                                        end
                                        ENTITY.SET_ENTITY_ROTATION(msl, mclos_look_p, 0, mclos_look_y, 1, true)
                                        ENTITY.APPLY_FORCE_TO_ENTITY(msl, 1, 0, 1, 0, 0, 0, 0, 1, true, false, false, true, true)
                                        ENTITY.SET_ENTITY_MAX_SPEED(msl, MCLOS_MaxSpeed)
                                        --ENTITY.APPLY_FORCE_TO_ENTITY(msl, 1, 0, 1, 0, true, true, false, true)
                                    else
                                        local MCOLS_mouseHorizontal = PAD.GET_CONTROL_NORMAL(1, 1)
                                        local MCOLS_mouseVertical = PAD.GET_CONTROL_NORMAL(2, 2)
                                        if MCOLS_mouseVertical < 0 then -- Mouse Up
                                            mclos_look_p = mclos_look_p + (MCLOS_TurnSpeed / 4)
                                            ENTITY.SET_ENTITY_ROTATION(msl, mclos_look_p, 0, mclos_look_y, 1, true)
                                        end
                                        if MCOLS_mouseVertical > 0 then --Mouse Down
                                            mclos_look_p = mclos_look_p - (MCLOS_TurnSpeed / 4)
                                            ENTITY.SET_ENTITY_ROTATION(msl, mclos_look_p, 0, mclos_look_y, 1, true)
                                        end
                                        if MCOLS_mouseHorizontal < 0 then -- Mouse Left
                                            mclos_look_y = mclos_look_y + (MCLOS_TurnSpeed / 4)
                                            ENTITY.SET_ENTITY_ROTATION(msl, mclos_look_p, 0, mclos_look_y, 1, true)
                                        end
                                        if MCOLS_mouseHorizontal > 0 then -- Mouse Right
                                            mclos_look_y = mclos_look_y - (MCLOS_TurnSpeed / 4)
                                            ENTITY.SET_ENTITY_ROTATION(msl, mclos_look_p, 0, mclos_look_y, 1, true)
                                        end
                                    end
                                end
                                util.yield()
                            end 
                        end)
                    end 
                    if missle_SACLOS then                                                       
                        local localped = players.user_ped()
                        local localcoords = ENTITY.GET_ENTITY_COORDS(players.user_ped())
                        local forOffset = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(localped, 0, 5, 0)
                        RRocket = OBJECT.GET_CLOSEST_OBJECT_OF_TYPE(forOffset.x, forOffset.y, forOffset.z, 10, SACLOS_SelectedMissle, false, true, true)
                        util.create_thread(function ()
                            local msl = RRocket
                            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(msl)
                            if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(msl) then
                                for i = 1, 10 do
                                    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(msl)
                                end
                            end     
                            while ENTITY.DOES_ENTITY_EXIST(msl) do       
                                local rc = raycast_gameplay_cam(-1, 1000000.0)[2]
                                local lc2 = ENTITY.GET_ENTITY_COORDS(msl)
                                local lc = GetTableFromV3Instance(lc2)
                                local look2 = v3.lookAt(lc2, rc)
                                local look = GetTableFromV3Instance(look2)
                                if ENTITY.GET_ENTITY_SPEED(msl) == 0 then
                                    goto CONTINUE
                                end
                                if SACLOS_drawLaser then
                                    local LaserStartCoords = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(players.user_ped(), 0, 0, 0)
                                    GRAPHICS.DRAW_LINE(LaserStartCoords.x, LaserStartCoords.y, LaserStartCoords.z, rc.x, rc.y, rc.z, 0, 50, 255, 150)
                                    util.yield()
                                end
                                if ENTITY.DOES_ENTITY_EXIST(msl) then
                                    ENTITY.SET_ENTITY_ROTATION(msl, look.x, look.y, look.z, 1, true)
                                    ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(msl, 1, 0, 1, 0, true, true, false, true)
                                    ENTITY.SET_ENTITY_MAX_SPEED(msl, SACLOS_MaxSpeed)
                                end
                                ::CONTINUE::
                                util.yield()
                            end 
                        end)
                    end
                end
            end
        end
        util.yield()
    end
end)

--Missile Aimbot submenu
local missile_aimbot_menu = menu.list(self_tab, "Missile Aimbot", {"missileaimbotmenu"}, "Missile Aimbot Options.")

homing_missles = false
menu.toggle(missile_aimbot_menu, "Missile Aimbot", {"missileaimbot"}, "Missiles now have aimbot.", function(on)
    homing_missles = on
    mod_uses("object", if on then 1 else -1)
end)

HomingM_SelectedMissle = util.joaat("w_lr_rpg_rocket")
menu.slider(missile_aimbot_menu, "Missile Aimbot - Select Missile", {" "}, "The Missile that will be used for 'Missile Aimbot'.\n\n1 - RPG\n2 - Homing Launcher\n3 - Oppressor Missile\n4 - B-11 Barrage\n5 - B-11 Homing\n6 - Chernobog Missile\n7 - Explosive Bomb\n8 - Incendiary Bomb\n9 - Gas Bomb\n10 - Cluster Bomb", 1, 10, 2, 1, function(value)
    if value == 1 then HomingM_SelectedMissle = util.joaat("w_lr_rpg_rocket")
    elseif value == 2 then HomingM_SelectedMissle = util.joaat("w_lr_homing_rocket")
    elseif value == 3 then HomingM_SelectedMissle = util.joaat("w_ex_vehiclemissile_3")
    elseif value == 4 then HomingM_SelectedMissle = util.joaat("w_smug_airmissile_01b")
    elseif value == 5 then HomingM_SelectedMissle = util.joaat("w_battle_airmissile_01")
    elseif value == 6 then HomingM_SelectedMissle = util.joaat("w_ex_vehiclemissile_4")
    elseif value == 7 then HomingM_SelectedMissle = util.joaat("w_smug_bomb_01")
    elseif value == 8 then HomingM_SelectedMissle = util.joaat("w_smug_bomb_02")
    elseif value == 9 then HomingM_SelectedMissle = util.joaat("w_smug_bomb_03")
    elseif value == 10 then HomingM_SelectedMissle = util.joaat("w_smug_bomb_04") end
end)

homing_missle_range = 1000
menu.slider(missile_aimbot_menu, "Missle Aimbot Range", {" "}, "Range at which the missile will track the player.", 50, 35000, 1000, 50, function(value)
    homing_missle_range = value
    homing_missle_range_org = value
end)

--Blackhole Grenade
menu.action(self_tab, "Blackhole Grenade", {"blackholegrenade"}, "Throw a grenade that creates a temporary blackhole\nAT THE PLAYERS LOCATION,\nNOT WHERE THE GRENADE LANDS.", function()
    local grenade_hash = util.joaat("weapon_grenade")
    local player_ped = players.user_ped()
    WEAPON.GIVE_WEAPON_TO_PED(player_ped, grenade_hash, 1, false, true)
    WEAPON.SET_PED_WEAPON_TINT_INDEX(player_ped, grenade_hash, 0)  
    util.yield(3000)
    local explosion_coords = ENTITY.GET_ENTITY_COORDS(player_ped, true)
    local blackhole_duration = 5000 -- 5 seconds
    local blackhole_radius = 30.0
    local start_time = util.current_time_millis()
    while util.current_time_millis() - start_time < blackhole_duration do
        local entities_to_pull = entities.get_all_vehicles_as_handles()
        for _, entity in ipairs(entities_to_pull) do
            local entity_coords = ENTITY.GET_ENTITY_COORDS(entity)
            local direction = {
                x = explosion_coords.x - entity_coords.x,
                y = explosion_coords.y - entity_coords.y,
                z = explosion_coords.z - entity_coords.z
            }
            local magnitude = math.sqrt(direction.x^2 + direction.y^2 + direction.z^2)
            direction.x = direction.x / magnitude
            direction.y = direction.y / magnitude
            direction.z = direction.z / magnitude
            ENTITY.APPLY_FORCE_TO_ENTITY(entity, 1, direction.x * 2.0, direction.y * 2.0, direction.z * 2.0, 0, 0, 0, 1, false, true, true, true, true)
        end
        util.yield(50)
    end
end)

-- VEHICLE TAB ----------------------------------------------------------------------------------------------------------------------------------

--Repair Vehicle
menu.action(veh_tab, "Repair Vehicle", {}, "Repairs the current vehicle.", function()
    menu.trigger_commands("fixvehicle")
end)

menu.action(veh_tab, "Enter Last Vehicle", {}, "Teleports you into your last vehicle.", function()
    menu.trigger_commands("enterlastvehicle")
end)

menu.action(veh_tab, "Teleport Last Vehicle", {}, "Teleports your last vehicle to you.", function()
    menu.trigger_commands("calllastvehicle")
end)

--Delete Vehicle
menu.action(veh_tab, "Delete Vehicle", {}, "Deletes the current vehicle.", function()
    menu.trigger_commands("deletevehicle")
end)

--Switch Seats
menu.click_slider(veh_tab, "Switch Seats", {"switchseats"}, "Switches your seats.\n-1 Driver\n0 Passenger\n1 Back Driver\n2 Back Passenger\n3-8 Other Vehicle Seats", -1, 8, -1, 1, function (value)
    local locped = players.user_ped()
    if PED.IS_PED_IN_ANY_VEHICLE(locped, false) then
        local veh = PED.GET_VEHICLE_PED_IS_IN(locped, false)
        PED.SET_PED_INTO_VEHICLE(locped, veh, value)
    else
        util.toast("Get in a vehicle first you silly goose.")
    end
end)

--Downforce
menu.toggle_loop(veh_tab, "Downforce",{"downforce"}, "Applies a downforce to your car.", function()
    local player_cur_car = entities.get_user_vehicle_as_handle()
    if player_cur_car ~= 0 then
        ENTITY.APPLY_FORCE_TO_ENTITY(player_cur_car, 1, 0, 0, -1, 0, 0, 0, 0, true, false, true, false, true)
    end
end)

--Instant On
function TurnCarOnInstantly()
    local localped = players.user_ped()
    if PED.IS_PED_GETTING_INTO_A_VEHICLE(localped) then
        local veh = PED.GET_VEHICLE_PED_IS_ENTERING(localped)
        if not VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(veh) then
            VEHICLE.SET_VEHICLE_FIXED(veh)
            VEHICLE.SET_VEHICLE_ENGINE_HEALTH(veh, 1000)
            VEHICLE.SET_VEHICLE_ENGINE_ON(veh, true, true, false)
        end
        if VEHICLE.GET_VEHICLE_CLASS(veh) == 15 then
            VEHICLE.SET_HELI_BLADES_FULL_SPEED(veh)
        end
    end
end

menu.toggle_loop(veh_tab, "Instantly Start Engine", {"instantcarengine"}, "Instantly starts the engine of the vehicle.", function(on)
    TurnCarOnInstantly()
end)

--Radio Off
menu.toggle_loop(veh_tab, "Radio Off", {"radiooff"}, "Turn off the radio locally (for you).", function ()
local veh = PED.GET_VEHICLE_PED_IS_IN(players.user_ped())
if PED.IS_PED_IN_ANY_VEHICLE(players.user_ped(), false) then
AUDIO.SET_VEHICLE_RADIO_ENABLED(veh, false)
util.yield()
end
end, function ()
local veh = PED.GET_VEHICLE_PED_IS_IN(players.user_ped())
AUDIO.SET_VEHICLE_RADIO_ENABLED(veh, true)
end)

--Vanishing Act
local punchVehicleToggle = false
menu.toggle(veh_tab, "Vanishing Act", {}, "Toggle the ability to punch/kick vehicles and delete them from the world.", function(toggle)
    punchVehicleToggle = toggle
    if punchVehicleToggle then
        util.toast("Punch Vehicle to Delete: ON")
    else
        util.toast("Punch Vehicle to Delete: OFF")
    end
end)
local function requestControl(entity)
    if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity) then
        NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(entity)
        local startTime = util.current_time_millis()
        while not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(entity) do
            util.yield(10) -- Wait 10 ms before retrying
            if util.current_time_millis() - startTime > 500 then -- Timeout after 500 ms
                return false
            end
        end
    end
    return true
end
util.create_thread(function()
    while true do
        if punchVehicleToggle then
            local playerPed = PLAYER.PLAYER_PED_ID()
            local punchRange = 3.0
            if PED.IS_PED_PERFORMING_MELEE_ACTION(playerPed) then
                local nearbyVehicles = entities.get_all_vehicles_as_handles()
                for i, vehicle in ipairs(nearbyVehicles) do
                    local vehiclePos = ENTITY.GET_ENTITY_COORDS(vehicle, true)
                    local playerPos = ENTITY.GET_ENTITY_COORDS(playerPed, true)
                    local distance = MISC.GET_DISTANCE_BETWEEN_COORDS(playerPos.x, playerPos.y, playerPos.z, vehiclePos.x, vehiclePos.y, vehiclePos.z, true)
                    if distance <= punchRange then
                        if requestControl(vehicle) then
                            util.yield(1000) -- Wait for 1 second
                            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(vehicle, true, true)
                            entities.delete_by_handle(vehicle)
                            util.toast("Vehicle Deleted!")
                        else
                            util.toast("Failed to gain control of the vehicle.")
                        end
                    end
                end
            end
        end
        util.yield()
    end
end)

--Remove C4
menu.toggle_loop(veh_tab, "Auto-Remove C4", {"removec4"}, "Automatically remove sticky bombs on vehicle.", function(on)
    if player_cur_car ~= 0 then
        NETWORK.REMOVE_ALL_STICKY_BOMBS_FROM_ENTITY(player_cur_car, players.user_ped())
    end 
end)

--Flares
RealFlares = false
menu.toggle_loop(veh_tab, "Flares", {"vehflares"}, "Honk to spawn flares behind vehicle", function(on)    
    if PAD.IS_CONTROL_PRESSED(46, 46) then
        if player_cur_car ~= 0 then
            if RealFlares == false then
                local target = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(players.user_ped(), -2, -2.0, 0)
                local target2 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(players.user_ped(), -3, -25.0, 0)
                MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(target['x'], target['y'], target['z'], target2['x'], target2['y'], target2['z'], 100.0, true, 1198879012, players.user_ped(), true, false, 25.0)
                local target = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(players.user_ped(), 2, -2.0, 0)
                local target2 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(players.user_ped(), 3, -25.0, 0)
                MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(target['x'], target['y'], target['z'], target2['x'], target2['y'], target2['z'], 100.0, true, 1198879012, players.user_ped(), true, false, 25.0)
                util.yield(350)
                local target = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(players.user_ped(), -4, -2.0, 0)
                local target2 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(players.user_ped(), -10, -20.0, -1)
                MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(target['x'], target['y'], target['z'], target2['x'], target2['y'], target2['z'], 100.0, true, 1198879012, players.user_ped(), true, false, 25.0)
                local target = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(players.user_ped(), 4, -2.0, 0)
                local target2 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(players.user_ped(), 10, -20.0, -1)
                MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(target['x'], target['y'], target['z'], target2['x'], target2['y'], target2['z'], 100.0, true, 1198879012, players.user_ped(), true, false, 25.0)
                util.toast("Flares on charge...")
                util.yield(2000)
                util.toast("Flares ready to deploy!")
            elseif RealFlares then
                for i = 0, 10, 1 do 
                    local target = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(players.user_ped(), 0, -2, -1)
                    local target2 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(players.user_ped(), 0, -20, -15)
                    MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(target['x'], target['y'], target['z'], target2['x'], target2['y'], target2['z'], 100.0, true, 1198879012, players.user_ped(), true, false, 25.0)
                    util.yield(200)
                end
                util.toast("Flares on charge...")
                util.yield(2000)
                util.toast("Flares ready to deploy!")
            end
        else
            util.toast("You need to be in a car first you silly goose.")
        end
    end
end)

--Annoying Horn
menu.toggle_loop(veh_tab, "Annoying Horn", {"annoyinghorn"}, "Spams an annoying horn.", function(toggle)    
    if player_cur_car ~= 0 and  PED.IS_PED_IN_ANY_VEHICLE(players.user_ped(), true) then
        VEHICLE.SET_VEHICLE_MOD(player_cur_car, 14, math.random(0, 51), false)
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(2, 86, 1.0)
        util.yield(50)
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(2, 86, 0.0)
    end
end)


-- Function to get the closest vehicle to the player
function get_closest_vehicle()
    local playerPed = PLAYER.PLAYER_PED_ID()
    local playerPos = ENTITY.GET_ENTITY_COORDS(playerPed)
    local closestVehicle = nil
    local minDistance = math.huge

    for _, vehicle in ipairs(entities.get_all_vehicles_as_handles()) do
        local vehiclePos = ENTITY.GET_ENTITY_COORDS(vehicle)
        local distance = MISC.GET_DISTANCE_BETWEEN_COORDS(playerPos.x, playerPos.y, playerPos.z, vehiclePos.x, vehiclePos.y, vehiclePos.z, true)

        if distance < minDistance then
            minDistance = distance
            closestVehicle = vehicle
        end
    end

    if closestVehicle then
        util.toast("Closest Vehicle ID: " .. tostring(closestVehicle))
    else
        util.toast("No vehicles found.")
    end

    return closestVehicle
end

-- Function to get the player's current vehicle
function get_player_vehicle()
    local playerPed = PLAYER.PLAYER_PED_ID()
    local playerVehicle = PED.GET_VEHICLE_PED_IS_IN(playerPed, false)

    if playerVehicle then
        util.toast("Player Vehicle ID: " .. tostring(playerVehicle))
    else
        util.toast("Player is not in any vehicle.")
    end

    return playerVehicle
end

-- FUN TAB -----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Create the "Bootys Pets" submenu under the "Fun" tab
local pets_menu = menu.list(fun_tab, "Bootys Pets", {"bootyspetsmenu"}, "Ride a collection of Bootys pets")
local active_rideable_animal = 0
local x_offset = 0.0
local y_offset = 0.0
local z_offset = 0.0
local rotation_x = 0.0
local rotation_y = 0.0
local rotation_z = 0.0

function notify(text)
    util.toast('Ride a collection of Bootys pets: ' .. text)
end

function request_model_load(hash)
    util.request_model(hash, 2000)
end

local function request_anim_dict(dict)
    while not HAS_ANIM_DICT_LOADED(dict) do
        REQUEST_ANIM_DICT(dict)
        util.yield()
    end
end

-- Create sliders for XYZ coordinates and rotation
menu.slider_float(pets_menu, "X Offset", {}, "Adjust X offset", -1000, 1000, 0, 1, function(value)
    x_offset = value / 100.0
end)

menu.slider_float(pets_menu, "Y Offset", {}, "Adjust Y offset", -1000, 1000, 0, 1, function(value)
    y_offset = value / 100.0
end)

menu.slider_float(pets_menu, "Z Offset", {}, "Adjust Z offset", -1000, 1000, 0, 1, function(value)
    z_offset = value / 100.0
end)

menu.slider(pets_menu, "Rotation X", {}, "Adjust rotation around X axis", 0, 360, 0, 90, function(value)
    rotation_x = value
end)

menu.slider(pets_menu, "Rotation Y", {}, "Adjust rotation around Y axis", 0, 360, 0, 90, function(value)
    rotation_y = value
end)

menu.slider(pets_menu, "Rotation Z", {}, "Adjust rotation around Z axis", 0, 360, 0, 90, function(value)
    rotation_z = value
end)

-- tick handler
util.create_tick_handler(function()
    if active_rideable_animal ~= 0 then 
        -- Update attachment position and rotation dynamically
        ATTACH_ENTITY_TO_ENTITY(players.user_ped(), active_rideable_animal, GET_PED_BONE_INDEX(active_rideable_animal, 24816), x_offset, y_offset, z_offset, rotation_x, rotation_y, rotation_z, false, false, false, true, 2, true)

        -- dismounting 
        if IS_CONTROL_JUST_PRESSED(23, 23) then 
            DETACH_ENTITY(players.user_ped())
            entities.delete_by_handle(active_rideable_animal)
            CLEAR_PED_TASKS_IMMEDIATELY(players.user_ped())
            active_rideable_animal = 0
        end

        -- movement
        if not IS_ENTITY_IN_AIR(active_rideable_animal) then 
            if IS_CONTROL_PRESSED(32, 32) then 
                local side_move = GET_CONTROL_NORMAL(146, 146)
                local fwd = GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(active_rideable_animal, side_move * 10.0, 8.0, 0.0)
                TASK_LOOK_AT_COORD(active_rideable_animal, fwd.x, fwd.y, fwd.z, 0, 0, 2)
                TASK_GO_STRAIGHT_TO_COORD(active_rideable_animal, fwd.x, fwd.y, fwd.z, 20.0, -1, GET_ENTITY_HEADING(active_rideable_animal), 0.5)
            end
            if IS_CONTROL_JUST_PRESSED(76, 76) then 
                local w = {}
                w.x, w.y, w.z, _ = players.get_waypoint(players.user())
                if w.x == 0.0 and w.y == 0.0 then 
                    notify("No waypoint set.")
                else
                    TASK_FOLLOW_NAV_MESH_TO_COORD(active_rideable_animal, w.x, w.y, w.z, 1.0, -1, 100, 0, 0)
                end
            end
        end
    end
end)

local ranimal_hashes = {
    util.joaat("a_c_deer"), util.joaat("a_c_boar"), util.joaat("a_c_cow"),
    util.joaat('a_c_coyote'), util.joaat('a_c_mtlion'), util.joaat('a_c_pig'), util.joaat('a_c_retriever'),
    util.joaat('a_c_rottweiler'), util.joaat('a_c_shepherd'), util.joaat('a_c_rabbit_02'), util.joaat('a_c_pigeon'), util.joaat('a_c_rat'), util.joaat('a_c_hen'), 
    util.joaat('a_c_chimp'), util.joaat('a_c_dolphin'), util.joaat('a_c_pug'), util.joaat('a_c_rhesus'), util.joaat('a_c_poodle'), util.joaat('a_f_m_fatcult_01'), util.joaat('a_m_m_tranvest_01'), util.joaat('u_m_y_juggernaut_01')
}

menu.list_action(pets_menu, "Ride an animal", {"rideanimal"}, "", {"Deer", "Boar", "Cow", "Coyote", "Mountain Lion", "Pig", "Golden Retriever", 'Rottweiler', 'Shepherd', 'Rabbit', 'Pigeon', 'Rat', 'Hen', 'Chimp', 'Dolphin', 'Pug', 'Rhesus', 'Poodle', 'CultFemale', 'Trans', 'Jugg'}, function(index)
    if active_rideable_animal ~= 0 then 
        notify("You are already riding a pet.")
        return 
    end
    local hash = ranimal_hashes[index]
    request_model_load(hash)
    local animal = entities.create_ped(8, hash, players.get_position(players.user()), GET_ENTITY_HEADING(players.user_ped()))
    SET_ENTITY_INVINCIBLE(animal, true)
    FREEZE_ENTITY_POSITION(animal, true)
    FREEZE_ENTITY_POSITION(players.user_ped(), true)
    active_rideable_animal = animal

    ATTACH_ENTITY_TO_ENTITY(players.user_ped(), animal, GET_PED_BONE_INDEX(animal, 24816), x_offset, y_offset, z_offset, rotation_x, rotation_y, rotation_z, false, false, false, true, 2, true)
    request_anim_dict("rcmjosh2")
    TASK_PLAY_ANIM(players.user_ped(), "rcmjosh2", "josh_sitting_loop", 8.0, 1, -1, 2, 1.0, false, false, false)
    notify("Use your regular player movement controls to move the animal.\nPress your vehicle dismount key to dismount.\nPress your jump key to teleport to your waypoint.")
    FREEZE_ENTITY_POSITION(animal, false)
    FREEZE_ENTITY_POSITION(players.user_ped(), false)
end)

-- Photo Shoot
menu.action(fun_tab, "Photography Shoot", {}, "Spawns 3 peds with video cameras performing a photoshoot.", function()
    local pedModel = util.joaat("u_m_m_streetart_01")  -- Monkey Man ped model
    local cameraModel = util.joaat("prop_pap_camera_01") -- Video camera model
    local animDict = "amb@world_human_paparazzi@male@idle_a" -- Paparazzi animation dict
    local animName = "idle_a" -- Paparazzi animation name
    util.request_model(pedModel)
    while not STREAMING.HAS_MODEL_LOADED(pedModel) do
        util.yield()  -- Wait until the model is loaded
    end
    util.request_model(cameraModel)
    while not STREAMING.HAS_MODEL_LOADED(cameraModel) do
        util.yield()  -- Wait until the model is loaded
    end
    STREAMING.REQUEST_ANIM_DICT(animDict)
    while not STREAMING.HAS_ANIM_DICT_LOADED(animDict) do
        util.yield()  -- Wait until the animation dict is loaded
    end
    local playerPed = players.user_ped()
    local pos = ENTITY.GET_ENTITY_COORDS(playerPed, true)
    local forwardVector = ENTITY.GET_ENTITY_FORWARD_VECTOR(playerPed)
    local offset1 = v3.new(pos.x + forwardVector.x * 2, pos.y + forwardVector.y * 2, pos.z)
    local offset2 = v3.new(pos.x + forwardVector.x * 4, pos.y + forwardVector.y * 4, pos.z)
    local offset3 = v3.new(pos.x + forwardVector.x * 6, pos.y + forwardVector.y * 6, pos.z)
    local function spawnPed(offset)
        local ped = entities.create_ped(0, pedModel, v3.new(offset.x, offset.y, offset.z + 1), 0)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(ped, offset.x, offset.y, offset.z, false, false, false)
        local camera = entities.create_object(cameraModel, v3.new(offset.x, offset.y, offset.z + 1))
        local boneIndex = PED.GET_PED_BONE_INDEX(ped, 28422)  -- 28422 is the bone index for the right hand
        local offsetX = -0.05  -- Adjust to move the camera left/right
        local offsetY = 0.0  -- Adjust to move the camera back/forwards
        local offsetZ = -0.03  -- Adjust to move the camera up/down
        ENTITY.ATTACH_ENTITY_TO_ENTITY(camera, ped, boneIndex, offsetX, offsetY, offsetZ, 0, 0, 0, true, true, false, true, 1, true)
        local camPos = ENTITY.GET_ENTITY_COORDS(camera, true)
        local function getRotationFromPosition(cameraPos, targetPos)
            local deltaX = targetPos.x - cameraPos.x
            local deltaY = targetPos.y - cameraPos.y
            local deltaZ = targetPos.z - cameraPos.z
            local heading = math.deg(math.atan2(deltaY, deltaX))
            local pitch = math.deg(math.atan2(deltaZ, math.sqrt(deltaX * deltaX + deltaY * deltaY)))
            local roll = 0.0
            return pitch, heading, roll
        end
        local pitch, heading, roll = getRotationFromPosition(camPos, pos)
        pitch = pitch - 30
        ENTITY.SET_ENTITY_ROTATION(camera, pitch, heading, roll, 0, true)
        TASK.TASK_PLAY_ANIM(ped, animDict, animName, 8.0, -8.0, -1, 1, 0, false, false, false)
        return ped, camera
    end
    local ped1, camera1 = spawnPed(offset1)
    local ped2, camera2 = spawnPed(offset2)
    local ped3, camera3 = spawnPed(offset3)
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(pedModel)
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(cameraModel)
    STREAMING.REMOVE_ANIM_DICT(animDict)

    util.yield(30000) -- Keep them for 30 seconds
    entities.delete_by_handle(ped1)
    entities.delete_by_handle(ped2)
    entities.delete_by_handle(ped3)
    entities.delete_by_handle(camera1)
    entities.delete_by_handle(camera2)
    entities.delete_by_handle(camera3)
end)

-- Grand Theft Auto
local current_vehicle_index = 1
local vehicles = {}
local function update_vehicle_list()
    vehicles = entities.get_all_vehicles_as_handles()
    if #vehicles == 0 then
        util.toast("No vehicles found.")
    end
end

local function get_next_vehicle()
    if #vehicles == 0 then return 0 end
    local vehicle = vehicles[current_vehicle_index]
    current_vehicle_index = (current_vehicle_index % #vehicles) + 1  -- Move to next vehicle index
    return vehicle
end

local function Draw_Box_Vehicles()
end

menu.toggle_loop(chaos_tab, "Grand Theft Auto", {""}, "Constantly teleports you into each vehicle on the map...\nand they fall from the sky!", function()
    Draw_Box_Vehicles()
    update_vehicle_list()
    local player = PLAYER.PLAYER_PED_ID()
    local P_Coords = ENTITY.GET_ENTITY_COORDS(player, true)
    local vehicle = get_next_vehicle()
    
    if ENTITY.DOES_ENTITY_EXIST(vehicle) then
        -- Teleport into the vehicle
        PED.SET_PED_INTO_VEHICLE(player, vehicle, -1)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(vehicle, P_Coords.x + math.random(20, 500), P_Coords.y + math.random(20, 500), P_Coords.z + math.random(20, 500), true, false, false)
        util.yield(50)  -- second to allow teleportation
        -- Teleport out
        TASK.CLEAR_PED_TASKS(player)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(player, P_Coords.x, P_Coords.y, P_Coords.z, true, false, false)
        util.yield(1)  -- second before teleporting into the next vehicle
    end
end)

--Vehicle Seizures/Chaos
menu.toggle_loop(chaos_tab, "Vehicle Seizures", {"vehicleseizures"}, "Makes every vehicle have a seizure.", function(on)
    allVehicles = entities.get_all_vehicles_as_handles()
    for k,obj in pairs(allVehicles) do
        ENTITY.APPLY_FORCE_TO_ENTITY(obj, 1, math.random(0,100), math.random(0,100), math.random(0,100), math.random(0,100), math.random(0,100), math.random(0,100), 1, true, false, false, true, true)
    end
end)

menu.toggle_loop(chaos_tab, "Vehicle Chaos", {"vehiclechaos"}, "Makes all vehicles chaotic", function(on)
    allVehicles = entities.get_all_vehicles_as_handles()
    for k,obj in pairs(allVehicles) do
        ENTITY.APPLY_FORCE_TO_ENTITY(obj, 1, math.random(0,3500), math.random(0,3500), math.random(0,3500), math.random(0,3500), math.random(0,3500), math.random(0,3500), 1, true, false, false, true, true)
    end
end)

--Fly Vehicles
local speed = 10
local dont_stop = false
menu.toggle_loop(chaos_tab,"Control All Vehicles", {"controlvehicles"}, "Ability to fly and control all vehicles. Use movement keys.", function()
for k, veh in pairs(entities.get_all_vehicles_as_handles()) do
NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
cam_pos = CAM.GET_GAMEPLAY_CAM_ROT(0)
ENTITY.SET_ENTITY_ROTATION(veh, cam_pos.x, cam_pos.y, cam_pos.z, 1, true);
local locspeed = speed*10
local locspeed2 = speed
if PAD.IS_CONTROL_PRESSED(0, 61) then
locspeed = locspeed*2
locspeed2 = locspeed2*2
end
if PAD.IS_CONTROL_PRESSED(2, 71) then
if dont_stop then
    ENTITY.APPLY_FORCE_TO_ENTITY(veh, 1, 0.0, speed, 0.0, 0.0, 0.0, 0.0, 0, 1, 1, 1, 0, 1)
else
    VEHICLE.SET_VEHICLE_FORWARD_SPEED(veh, locspeed)
end
end
if PAD.IS_CONTROL_PRESSED(2, 72) then
local lsp = speed
if not PAD.IS_CONTROL_PRESSED(0, 61) then
    lsp = speed * 2
end
if dont_stop then
    ENTITY.APPLY_FORCE_TO_ENTITY(veh, 1, 0.0, 0 - (lsp), 0.0, 0.0, 0.0, 0.0, 0, 1, 1, 1, 0, 1)
else
    VEHICLE.SET_VEHICLE_FORWARD_SPEED(veh, 0 - (locspeed));
end
end
if PAD.IS_CONTROL_PRESSED(2, 63) then
local lsp = (0 - speed)*2
if not PAD.IS_CONTROL_PRESSED(0, 61) then
    lsp = 0 - speed
end
if dont_stop then
    ENTITY.APPLY_FORCE_TO_ENTITY(veh, 1, (lsp), 0.0, 0.0, 0.0, 0.0, 0.0, 0, 1, 1, 1, 0, 1)
else
    ENTITY.APPLY_FORCE_TO_ENTITY(veh, 1, 0 - (locspeed), 0.0, 0.0, 0.0, 0.0, 0.0, 0, 1, 1, 1, 0, 1);
end
end
if PAD.IS_CONTROL_PRESSED(2, 64) then
local lsp = speed
if not PAD.IS_CONTROL_PRESSED(0, 61) then
    lsp = speed*2
end
if dont_stop then
    ENTITY.APPLY_FORCE_TO_ENTITY(veh, 1, lsp, 0.0, 0.0, 0.0, 0.0, 0.0, 0, 1, 1, 1, 0, 1)
else
    ENTITY.APPLY_FORCE_TO_ENTITY(veh, 1, locspeed, 0.0, 0.0, 0.0, 0.0, 0.0, 0, 1, 1, 1, 0, 1)
end
end
if not dont_stop and not PAD.IS_CONTROL_PRESSED(2, 71) and not PAD.IS_CONTROL_PRESSED(2, 72) then
VEHICLE.SET_VEHICLE_FORWARD_SPEED(veh, 0.0);
end
end
end)

--Flatbed (tow/repo)
menu.action(fun_tab, "Flatbed (Repo Cars)", {}, "Use left arrow key to tow/repo nearby vehicles.", function ()
    local FlatbedSpawnPoint = GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(players.user_ped(), 0, 0, 0)
    local FlatbedSpawnHeading = GET_ENTITY_HEADING(players.user_ped())
    local FlatbedHash = util.joaat("flatbed")
    util.request_model(FlatbedHash)
    local Flatbed = entities.create_vehicle(FlatbedHash, FlatbedSpawnPoint, FlatbedSpawnHeading)
    SET_PED_INTO_VEHICLE(players.user_ped(), Flatbed, -1)
    util.create_tick_handler(function()
    local FlatbedSpawnPoint = GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(Flatbed, 0, 0, 0)
    local SelectedCar = GET_CLOSEST_VEHICLE(FlatbedSpawnPoint.x, FlatbedSpawnPoint.y, FlatbedSpawnPoint.z, 30, 0, 131078);
    local height = GET_ENTITY_HEIGHT_ABOVE_GROUND(SelectedCar)
    local Flatbedheight = GET_ENTITY_HEIGHT_ABOVE_GROUND(Flatbed)
    local Offset = 0
    if height > Flatbedheight then
        Offset = Flatbedheight + 0.5
    else
        Offset = 0
    end
    if IS_CONTROL_PRESSED(0, 189) and not IS_ENTITY_ATTACHED(SelectedCar) then       
        ATTACH_ENTITY_TO_ENTITY(SelectedCar, Flatbed, 0, 0, -2, 0.5 + height - Offset, 0, 0, 0, true, false, false, true, 0, true, 0)
        util.yield(500)
        VEHICLE_START_PARACHUTING(Flatbed, true)
    end   
    if IS_CONTROL_PRESSED(0, 189) and IS_ENTITY_ATTACHED(SelectedCar) then
        DETACH_ENTITY(SelectedCar, true, true)
        util.yield(500)
    end
    if not DOES_ENTITY_EXIST(Flatbed) then
        return false
    end
    if not IS_PED_IN_VEHICLE(players.user_ped(), Flatbed) then
    end  
    end)
end)

menu.toggle_loop(chaos_tab, "Peds Can't Drive", {" "}, "Where are these guys from?\nNew York?", function()
    for entities.get_all_peds_as_handles() as ped do 
        if not IS_PED_A_PLAYER(ped) then
            local v = GET_VEHICLE_PED_IS_IN(ped, false)
            if v ~= 0 then
                entities.request_control(ped)
                SET_PED_FLEE_ATTRIBUTES(ped, 1, true)
                TASK_REACT_AND_FLEE_PED(ped, players.user_ped())
            end
        end
    end
end)

-- WORLD TAB ---------------------------------------------------------------------------------------------------------------------------------------------------------------

--Clean World Submenu--
local clear_menu = menu.list(world_tab, "Clean World", {" "}, "Clear objects and entities from the area")

menu.action(clear_menu, "Full Clean", {"cleanworldfull"}, "This deletes EVERY possible entity in range. Can break things.", function(on_click)
    local ct = 0
    for k,ent in pairs(entities.get_all_vehicles_as_handles()) do
        entities.delete_by_handle(ent)
        ct = ct + 1
    end
    for k,ent in pairs(entities.get_all_peds_as_handles()) do
        if not PED.IS_PED_A_PLAYER(ent) then
            entities.delete_by_handle(ent)
            ct = ct + 1
        end
    end
    for k,ent in pairs(entities.get_all_objects_as_handles()) do
        entities.delete_by_handle(ent)
        ct = ct + 1
    end
    util.toast("-BootyScript-\n\nFull Clean Complete! Removed "..ct.." Entities in Total.")
end)

menu.action(clear_menu, "Safe Clean", {"cleanworldsafe"}, "This deletes most things in range. Probably won't break things. Who knows.", function(on_click)
    local ct = 0 
    for k, ent in pairs(entities.get_all_vehicles_as_handles()) do
        entities.delete_by_handle(ent)
        ct = ct + 1
    end
    for k, ent in pairs(entities.get_all_peds_as_handles()) do
        if not PED.IS_PED_A_PLAYER(ent) then
            entities.delete_by_handle(ent)
            ct = ct + 1
        end
    end
    util.toast("-BootyScript-\n\nSuccessfully Deleted "..ct.." Entities.")
end)

--Clear Specific Entities submenu----
local clearspecific_menu = menu.list(clear_menu, "Clear Specific Entities", {" "}, "Clear specific entities in range")
menu.action(clearspecific_menu, "Clear Vehicles", {"clearvehicles"}, "Deletes all Vehicles.", function(on_click)
    local ct = 0
    for k,ent in pairs(entities.get_all_vehicles_as_handles()) do
        entities.delete_by_handle(ent)
        ct = ct + 1
    end
    util.toast("-BootyScript-\n\nSuccessfully Deleted "..ct.." Vehicles.")
end)

menu.action(clearspecific_menu, "Clear Peds", {"clearpeds"}, "Deletes all pedestrians.", function(on_click)
    local ct = 0
    for k,ent in pairs(entities.get_all_peds_as_handles()) do 
        if not PED.IS_PED_A_PLAYER(ent) then
            entities.delete_by_handle(ent)
            ct = ct + 1
        end
    end
    util.toast("-BootyScript-\n\nSuccessfully Deleted "..ct.." Peds.")
end)

menu.action(clearspecific_menu, "Clear Objects", {"clearobjects"}, "Deletes all objects. This can break missions.", function(on_click)
    local ct = 0
    for k,ent in pairs(entities.get_all_objects_as_handles()) do
        entities.delete_by_handle(ent)
        ct = ct + 1
    end
    util.toast("-BootyScript-\n\nSuccessfull Deleted "..ct.." Objects.")
end)

menu.action(clearspecific_menu, "Clear Pickups", {"clearpickups"}, "Deletes all pickups.", function(on_click)
    local ct = 0
    for k,ent in pairs(entities.get_all_pickups_as_handles()) do
        entities.delete_by_handle(ent)
        util.toast("Successfully Deleted "..ct.." Pickups")
    end
end)

--Auto-TP Waypoint
function teleport_to_waypoint()
    if HUD.IS_WAYPOINT_ACTIVE() then
        local waypointBlip = HUD.GET_FIRST_BLIP_INFO_ID(HUD.GET_WAYPOINT_BLIP_ENUM_ID())
        if HUD.DOES_BLIP_EXIST(waypointBlip) then
            local waypointCoords = HUD.GET_BLIP_COORDS(waypointBlip)
            local zPos = 0.0
            local foundGround = false
            for i = 1000, 0, -10 do
                local groundZ = memory.alloc(4)
                MISC.GET_GROUND_Z_FOR_3D_COORD(waypointCoords.x, waypointCoords.y, i + 0.0, groundZ, true)
                zPos = memory.read_float(groundZ)
                if zPos > 0 then
                    foundGround = true
                    waypointCoords.z = zPos
                    break
                end
            end
            if not foundGround then
                waypointCoords.z = 50.0
            end
            local playerPed = PLAYER.PLAYER_PED_ID()
            ENTITY.SET_ENTITY_COORDS(playerPed, waypointCoords.x, waypointCoords.y, waypointCoords.z, false, false, false, true)
            util.toast("Teleported to waypoint!")
        else
            util.toast("Invalid waypoint!")
        end
    else
        util.toast("No waypoint set!")
    end
end

menu.toggle_loop(self_tab, "Auto Teleport to Waypoint", {"autotp"}, "Automatically teleport to the waypoint when it's set.", function()
    if HUD.IS_WAYPOINT_ACTIVE() then
        teleport_to_waypoint()
        HUD.SET_WAYPOINT_OFF()
    end
    util.yield(2000)  -- Check every 2 seconds
end)


--Traffic Blips
local trafficBlips = {}
menu.toggle_loop(world_tab, "Traffic Blips", {"trafficblips"}, "Puts a blip on all AI traffic. (Good for drifting or cruising)", function(on)
    for i,ped in pairs(entities.get_all_peds_as_handles()) do 
        if not PED.IS_PED_A_PLAYER(ped) and PED.IS_PED_IN_ANY_VEHICLE(ped) then
            pedVehicle = PED.GET_VEHICLE_PED_IS_IN(ped, false)
            if VEHICLE.IS_VEHICLE_DRIVEABLE(pedVehicle, false) and HUD.GET_BLIP_FROM_ENTITY(pedVehicle) == 0 then
                pedBlip = HUD.ADD_BLIP_FOR_ENTITY(pedVehicle)
                HUD.SET_BLIP_ROTATION(pedBlip, math.ceil(ENTITY.GET_ENTITY_HEADING(pedVehicle)))
                HUD.SET_BLIP_SPRITE(pedBlip, 286)
                HUD.SET_BLIP_SCALE_2D(pedBlip, .5, .5)
                HUD.SET_BLIP_COLOUR(pedBlip, 28)
                trafficBlips[#trafficBlips + 1] = pedBlip
            elseif VEHICLE.IS_VEHICLE_DRIVEABLE(pedVehicle, false) and HUD.GET_BLIP_FROM_ENTITY(pedVehicle) != 0 then
                local currentPedVehicleBlip = HUD.GET_BLIP_FROM_ENTITY(pedVehicle)
                HUD.SET_BLIP_ROTATION(currentPedVehicleBlip, math.ceil(ENTITY.GET_ENTITY_HEADING(pedVehicle)))
            end
        end
    end
    for i,b in pairs(trafficBlips) do
        if HUD.GET_BLIP_INFO_ID_ENTITY_INDEX(b) == 0 or not VEHICLE.IS_VEHICLE_DRIVEABLE(pedVehicle, false) then 
            util.remove_blip(b)
            trafficBlips[i] = nil
        end
    end
end, function(on_stop)
    for i,b in pairs(trafficBlips) do
        util.remove_blip(b) 
        trafficBlips[i] = nil
    end
end)

--Peds Wander
menu.action(world_tab, "Peds Wander", {"pedswander"}, "Makes peds leave their vehicles and wander around.", function()
    for _, ped in ipairs(entities.get_all_peds_as_handles()) do
        if not PED.IS_PED_A_PLAYER(ped) then
            TASK.TASK_WANDER_STANDARD(ped, 10.0, 10)
        end
    end
    util.yield(10000) -- lasts 10 seconds
end)

--FPS Boosts
menu.toggle(world_tab, "FPS Boost", {"fpsboost"}, "Can boost FPS by an additional 10 frames", function(on_toggle)
    if on_toggle then
    menu.trigger_commands("weather" .. " extrasunny")
    menu.trigger_commands("clouds" .. " clear01")
    menu.trigger_commands("time" .. " 6")
    menu.trigger_commands("noidlecam ")
    else
    menu.trigger_commands("weather" .. " normal")
    menu.trigger_commands("clouds" .. " normal")
    menu.trigger_commands("noidlecam ")
    end
end)

menu.toggle(world_tab, "FPS Boost - Insane", {"fpsboostinsane"}, "Looks shitty but can boost FPS by an additional 15 frames", function(on_toggle)
    if on_toggle then
    menu.trigger_commands("weather" .. " extrasunny")
    menu.trigger_commands("clouds" .. " clear01")
    menu.trigger_commands("time" .. " 6")
    menu.trigger_commands("potatomode ")
    menu.trigger_commands("nosky ")
    menu.trigger_commands("noidlecam ")
    else
    menu.trigger_commands("weather" .. " normal")
    menu.trigger_commands("clouds" .. " normal")
    menu.trigger_commands("potatomode ")
    menu.trigger_commands("nosky ")
    menu.trigger_commands("noidlecam ")
    end
end)

local is_toggled_on = true
menu.toggle_loop(world_tab, "Who is talking?", {"displaytalkers"}, "Shows who is talking on-screen.", function(on)
    for players.list(true, true, true) as pid do 
        if NETWORK_IS_PLAYER_TALKING(pid) then 
            util.draw_debug_text(GET_PLAYER_NAME(pid) .. ' is talking.')
        end
    end
end)

menu.toggle_loop(world_tab, "Display Coordinates", {}, "Displays Coordinates on-screen", function(on)
    local RealOffset = GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(players.user_ped(), 0, 0, 0)
    util.draw_debug_text("X : " .. RealOffset.x)
    util.draw_debug_text("Y : " .. RealOffset.y)
    util.draw_debug_text("Z : " .. RealOffset.z)
end, function()
end)




--PLAYER OPTIONS VEHICLE ROOT TAB -------------------------------------------------------------------------------------------------------------------

local function repair_player_vehicle(pid)
    local player_ped = PLAYER.GET_PLAYER_PED(pid)
    local player_vehicle = get_vehicle_ped_is_in(player_ped, Include_last_vehicle_for_player_functions)
    if player_vehicle == 0 then
        util.toast(players.get_name(pid) .. " is not in any vehicle.")
    else
        if request_control(player_vehicle) then
            VEHICLE.SET_VEHICLE_FIXED(player_vehicle)
        else
            util.toast("Couldn't get control of their vehicle.")
        end
    end
end

local function toggle_player_vehicle_engine(pid)
    local player_ped = PLAYER.GET_PLAYER_PED(pid)
    local player_vehicle = get_vehicle_ped_is_in(player_ped, Include_last_vehicle_for_player_functions)
    if player_vehicle == 0 then
        util.toast(players.get_name(pid) .. " is not in any vehicle.")
    else
        local is_running = VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(player_vehicle)
        if request_control(player_vehicle) then
            VEHICLE.SET_VEHICLE_ENGINE_ON(player_vehicle, not is_running, true, true)
        else
            util.toast("Couldn't get control of their vehicle.")
        end
    end
end

local function break_player_vehicle_engine(pid)
    local player_ped = PLAYER.GET_PLAYER_PED(pid)
    local player_vehicle = get_vehicle_ped_is_in(player_ped, Include_last_vehicle_for_player_functions)
    if player_vehicle == 0 then
        util.toast(players.get_name(pid) .. " is not in any vehicle.")
    else
        if request_control(player_vehicle) then
            VEHICLE.SET_VEHICLE_ENGINE_HEALTH(player_vehicle, -10.0)
        else
            util.toast("Couldn't get control of their vehicle.")
        end
    end
end

local function launch_up_player_vehicle(pid)
    local player_ped = PLAYER.GET_PLAYER_PED(pid)
    local player_vehicle = get_vehicle_ped_is_in(player_ped, Include_last_vehicle_for_player_functions)
    if player_vehicle == 0 then
        util.toast(players.get_name(pid) .. " is not in any vehicle.")
    else
        if request_control(player_vehicle) then
            ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(player_vehicle, 1, 0.0, 0.0, 1000.0, true, true, true, true)
        else
            util.toast("Couldn't get control of their vehicle.")
        end
    end
end

local function boost_player_vehicle_forward(pid)
    local player_ped = PLAYER.GET_PLAYER_PED(pid)
    local player_vehicle = get_vehicle_ped_is_in(player_ped, Include_last_vehicle_for_player_functions)
    if player_vehicle == 0 then
        util.toast(players.get_name(pid) .. " is not in any vehicle.")
    else
        request_control(player_vehicle)
        ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(player_vehicle, 1, 0.0, 1000.0, 0.0, true, true, true, true)
    end
end

local function stop_player_vehicle(pid)
    local player_ped = PLAYER.GET_PLAYER_PED(pid)
    local player_vehicle = get_vehicle_ped_is_in(player_ped, Include_last_vehicle_for_player_functions)
    if player_vehicle == 0 then
        util.toast(players.get_name(pid) .. " is not in any vehicle.")
    else
        request_control(player_vehicle)
        VEHICLE.BRING_VEHICLE_TO_HALT(player_vehicle, 0.0, 1, false)
    end
end

local function flip_player_vehicle(pid)
    local player_ped = PLAYER.GET_PLAYER_PED(pid)
    local player_vehicle = get_vehicle_ped_is_in(player_ped, Include_last_vehicle_for_player_functions)
    if player_vehicle == 0 then
        util.toast(players.get_name(pid) .. " is not in any vehicle.")
    else
        request_control(player_vehicle)
        local heading = ENTITY.GET_ENTITY_HEADING(player_vehicle)
        ENTITY.SET_ENTITY_ROTATION(player_vehicle, 0, 180, -heading, 1, true)
    end
end

local function turn_player_vehicle(pid)
    local player_ped = PLAYER.GET_PLAYER_PED(pid)
    local player_vehicle = get_vehicle_ped_is_in(player_ped, Include_last_vehicle_for_player_functions)
    if player_vehicle == 0 then
        util.toast(players.get_name(pid) .. " is not in any vehicle.")
    else
        request_control(player_vehicle)
        local heading = ENTITY.GET_ENTITY_HEADING(player_vehicle)
        local alter_heading = heading >= 180 and heading - 180 or heading + 180
        ENTITY.SET_ENTITY_ROTATION(player_vehicle, 0, 0, alter_heading, 2, true)
    end
end

--------- Animations -----------------------------------------------------------------------------------------------------------
--                                        Thanks to the devs of the Animations+ lua for their code
-- Functions
function request_model_load(hash)
    request_time = os.time()
    if not STREAMING.IS_MODEL_VALID(hash) then
        return
    end
    STREAMING.REQUEST_MODEL(hash)
    while not STREAMING.HAS_MODEL_LOADED(hash) do
        if os.time() - request_time >= 10 then
            break
        end
        util.yield()
    end
end

function attachto(offx, offy, offz, pid, angx, angy, angz, hash, bone, isnpc, isveh, tint)
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local bone = PED.GET_PED_BONE_INDEX(ped, bone)
    local coords = ENTITY.GET_ENTITY_COORDS(ped, true)
    coords.x = coords['x']
    coords.y = coords['y']
    coords.z = coords['z']
    if isnpc then
        obj = entities.create_ped(1, hash, coords, 90.0)
    elseif isveh then
        obj = entities.create_vehicle(hash, coords, 90.0)
    else
        obj = OBJECT.CREATE_OBJECT_NO_OFFSET(hash, coords['x'], coords['y'], coords['z'], true, false, false)
    end
    if tint ~= nil then
        OBJECT.SET_OBJECT_TINT_INDEX(obj, tint)
    end
    ENTITY.SET_ENTITY_INVINCIBLE(obj, true)
    ENTITY.ATTACH_ENTITY_TO_ENTITY(obj, ped, bone, offx, offy, offz, angx, angy, angz, false, false, true, false, 0, true)
    ENTITY.SET_ENTITY_COMPLETELY_DISABLE_COLLISION(obj, false, true)
end

function play_animstationary(dict, name, duration)
    ped = PLAYER.PLAYER_PED_ID()
    while not STREAMING.HAS_ANIM_DICT_LOADED(dict) do
        STREAMING.REQUEST_ANIM_DICT(dict)
        util.yield()
    end
    TASK.TASK_PLAY_ANIM(ped, dict, name, 3.0, 2.0, duration, 3, 1.0, false, false, false)
end

--Animations
menu.divider(anim_tab, "-- Use with Animations+ --")
menu.action(anim_tab, "Lounge (Black)", {"lounge1"}, "", function(on_click)
    request_model_load(94826578)
    attachto(-0.15, -0.540, 0.05, players.user(), 102, 5.0, 169.5, 94826578, 0, false, false)
    play_animstationary("anim@scripted@robbery@tunf_iaa_ig1_interrogation@", "idle_before_cs_dealer", -1)
end)

menu.action(anim_tab, "Lounge (Brown)", {"loungechair2"}, "", function(on_click)
    request_model_load(-671738639)
    attachto(-0.15, -0.540, 0.05, players.user(), 102, 5.0, 169.5, -671738639, 0, false, false)
    play_animstationary("anim@scripted@robbery@tunf_iaa_ig1_interrogation@", "idle_before_cs_dealer", -1)
end)

menu.action(anim_tab, "Dining Chair", {"chair1"}, "", function(on_click)
    request_model_load(451260528)
    --attachto(-0.05, -0.600, -0.05, players.user(), 100.0, -3.0, 170.0, -671738639, 0, false, false)
    attachto(0.05, 0.005, -0.63, players.user(), 5.0, 3.0, 185.0, 451260528, 0, false, false)  ------------ left/right, for/back, up/down -------- up/down, left/right, for/back
    play_animstationary("anim@scripted@player@fix_astu_ig8_weed_smoke@male@", "male_pos_d_p1_base", -1)
end)

menu.action(anim_tab, "Circular Chair", {"chair2"}, "", function(on_click)
    request_model_load(-1785811936)
    attachto(0.05, -0.7, -0.63, players.user(), 5.0, 3.0, 185.0, -1785811936, 0, false, false)
    play_animstationary("anim@scripted@player@fix_astu_ig8_weed_smoke@male@", "male_pos_d_p1_base", -1)
end)

menu.action(anim_tab, "Red Chair", {"chair3"}, "", function(on_click)
    request_model_load(-2033210578)
    attachto(0.05, -0.1, -0.63, players.user(), 5.0, 3.0, 185.0, -2033210578, 0, false, false)
    play_animstationary("anim@scripted@player@fix_astu_ig8_weed_smoke@male@", "male_pos_d_p1_base", -1)
end)

menu.action(anim_tab, "White Sofa", {"chair4"}, "", function(on_click)
    request_model_load(-546388559)
    attachto(0.05, -0.1, -0.63, players.user(), 5.0, 0.05, 185.0, -546388559, 0, false, false)
    play_animstationary("anim@scripted@player@fix_astu_ig8_weed_smoke@male@", "male_pos_d_p1_base", -1)
end)

menu.action(anim_tab, "Red Sofa", {"chair5"}, "", function(on_click)
    request_model_load(338307413)
    attachto(0.05, -0.49, -0.4, players.user(), 50.0, 0.05, 185.0, 338307413, 0, false, false)  ------------ OFFSETS: left/right, for/back, up/down -------- ROTATIONS: up/down, left/right, for/back
    play_animstationary("switch@michael@on_sofa", "base_jimmy", -1)
end)

menu.action(anim_tab, "Wheelchair", {"wheelchair"}, "", function(on_click)
    request_model_load(1262298127)
    attachto(-0.05, -0.08, -0.15, players.user(), 30, 5.0, 169.5, 1262298127, 0, false, false)
    play_animstationary("anim@scripted@player@fix_astu_ig8_weed_smoke@male@", "male_pos_a_p1_base", -1)
end)


-- PLAYERS OPTIONS FEATURES ----------------------

local function generate_features(pid)
    menu.divider(menu.player_root(pid), SCRIPT_NAME)                                                -- VEHICLE OPTIONS ---------------------------
    local vehicles_player_root = menu.list(menu.player_root(pid), "Vehicle Options", {}, "")
    
    do
        local strength, current_option
        menu.list_select(vehicles_player_root, "Horn Boost", {},
            "Boosts their vehicle forward when they honk.",
            { { "Off", {}, "Low Boost" }, { "Low Boost", {}, "Slow" },
              { "Neutral Boost", {}, "Mid" },
              { "High Boost", {}, "Fast" },
              { "Fast Boost", {}, "Super Fast" } }, 1,
            function(index)
                local player_ped = PLAYER.GET_PLAYER_PED(pid)
                local player_vehicle = get_vehicle_ped_is_in(player_ped, false)
                strength = index == 5 and 50 or index / 3
                current_option = index
                if current_option ~= 1 then
                    while index == current_option do
                        if AUDIO.IS_HORN_ACTIVE(player_vehicle) then
                            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(player_vehicle)
                            ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(player_vehicle, 1, 0.0, strength, 0.0, true, true, true, true)
                        end
                        util.yield()
                    end
                end
            end)
    end
    
    do
        local strength, current_option
        menu.list_select(vehicles_player_root, "Car Jump", {},
            "Makes their vehicle jump when they honk.",
            { { "Off", {}, "Default." }, { "Low Boost", {}, "Small Jump" },
              { "Neutral Boost", {}, "Mid Jump" },
              { "High Boost", {}, "High Jump" },
              { "Extreme Boost", {}, "Super Jump." } }, 1,
            function(index)
                local player_ped = PLAYER.GET_PLAYER_PED(pid)
                local player_vehicle = get_vehicle_ped_is_in(player_ped, false)
                strength = index == 5 and 50 or index / 3
                current_option = index
                if current_option ~= 1 then
                    while index == current_option do
                        if AUDIO.IS_HORN_ACTIVE(player_vehicle) then
                            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(player_vehicle)
                            ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(player_vehicle, 1, 0.0, 0.0, strength, true, true, true, true)
                        end
                        util.yield()
                    end
                end
            end)
    end
    
    menu.action(vehicles_player_root, "Repair", {}, "Repairs their vehicle.",
        function() repair_player_vehicle(pid) end)
    menu.action(vehicles_player_root, "Toggle Engine", {}, "Turns engine on or off.",
        function() toggle_player_vehicle_engine(pid) end)
    menu.action(vehicles_player_root, "Break Engine", {}, "Destroys their engine.",
        function() break_player_vehicle_engine(pid) end)
    menu.action(vehicles_player_root, "Boost Forward", {}, "Boosts their vehicle forward.",
        function() boost_player_vehicle_forward(pid) end)
    menu.action(vehicles_player_root, "Launch To Sky", {}, "Launches their vehicle into the sky",
        function() launch_up_player_vehicle(pid) end)
    menu.action(vehicles_player_root, "Halt Vehicle", {}, "Stops their vehicle.",
        function() stop_player_vehicle(pid) end)
    menu.action(vehicles_player_root, "Flip Vehicle Upside Down", {}, "Flips their car.",
        function() flip_player_vehicle(pid) end)
    menu.action(vehicles_player_root, "Turn Vehicle Around", {}, "Turns their car.",
        function() turn_player_vehicle(pid) end)


local attach_to_vehicle_list = menu.list(vehicles_player_root, "Attach To Vehicle", {}, "Attach your vehicle to another player's vehicle")
local position = 1
menu.slider(attach_to_vehicle_list, "Position", {""}, "1 = Front\n2 = Middle\n3 = Back\n4 = Top\n5 = Bottom\n6 = Left\n7 = Right", 1, 7, 1, 1, function(count)
    position = count
end)
local function control_vehicle(pid, callback)
    local playerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local vehicle = PED.GET_VEHICLE_PED_IS_IN(playerPed, false)
    if ENTITY.DOES_ENTITY_EXIST(vehicle) then
        callback(vehicle)
    else
        util.toast("Player is not in a vehicle.")
    end
end
local function get_model_dimensions_from_hash(modelHash)
    local min = memory.alloc()
    local max = memory.alloc()
    MISC.GET_MODEL_DIMENSIONS(modelHash, min, max)
    local size = {
        x = memory.read_float(max) - memory.read_float(min),
        y = memory.read_float(max + 4) - memory.read_float(min + 4),
        z = memory.read_float(max + 8) - memory.read_float(min + 8)
    }
    memory.free(min)
    memory.free(max)
    return size
end

menu.action(attach_to_vehicle_list, "Attach", {}, "", function()
    local playerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    if pid ~= players.user() then  -- Ensure you don't attach to yourself
        local vehicle = PED.GET_VEHICLE_PED_IS_IN(playerPed, false) -- Get the vehicle of the target player
        if vehicle and ENTITY.DOES_ENTITY_EXIST(vehicle) then
            local entity1
            local minDim, maxDim = v3(), v3()
            MISC.GET_MODEL_DIMENSIONS(ENTITY.GET_ENTITY_MODEL(vehicle), minDim, maxDim)
            local height = {x = maxDim.x - minDim.x, y = maxDim.y - minDim.y, z = maxDim.z - minDim.z}
            local posX, posY, posZ = 0.0, 0.0, 0.0
            if not PED.IS_PED_IN_ANY_VEHICLE(players.user_ped(), false) then
                entity1 = players.user_ped()
                if position == 1 then -- Front
                    posY = height.y / 2
                elseif position == 2 then -- Middle
                    posY = 0.0
                elseif position == 3 then -- Back
                    posY = -height.y / 2
                elseif position == 4 then -- Top
                    posZ = height.z
                elseif position == 5 then -- Bottom
                    posZ = -height.z
                elseif position == 6 then -- Left
                    posX = -height.x / 2
                elseif position == 7 then -- Right
                    posX = height.x / 2
                end
            else
                entity1 = entities.get_user_vehicle_as_handle(false)
                if position == 1 then -- Front
                    posY = height.y / 2
                elseif position == 2 then -- Middle
                    posY = 0.0
                elseif position == 3 then -- Back
                    posY = -height.y / 2
                elseif position == 4 then -- Top
                    posZ = height.z
                elseif position == 5 then -- Bottom
                    posZ = -height.z
                elseif position == 6 then -- Left
                    posX = -height.x / 2
                elseif position == 7 then -- Right
                    posX = height.x / 2
                end
            end
            ENTITY.ATTACH_ENTITY_TO_ENTITY(entity1, vehicle, 0, posX, posY, posZ, 0, 0, 0, true, false, true, false, 0, true)
            if ENTITY.IS_ENTITY_ATTACHED_TO_ENTITY(entity1, vehicle) then
                util.toast("Success")
            else
                util.toast("Failed")
            end
        else
            util.toast("Target is not in a valid vehicle.")
        end
    else
        util.toast("You can't do this on yourself.")
    end
end)

menu.action(attach_to_vehicle_list, "Detach", {}, "Detaches your vehicle from the target", function()
    if PED.IS_PED_IN_ANY_VEHICLE(players.user_ped(), false) then
        local vehicle = entities.get_user_vehicle_as_handle(false)
        if ENTITY.IS_ENTITY_ATTACHED(vehicle) then
            ENTITY.DETACH_ENTITY(vehicle, true, true)
            util.toast("Vehicle detached.")
        else
            util.toast("Vehicle is not attached to anything.")
        end
    else
        if ENTITY.IS_ENTITY_ATTACHED(players.user_ped()) then
            ENTITY.DETACH_ENTITY(players.user_ped(), true, true)
            util.toast("You have been detached.")
        else
            util.toast("You are not attached to anything.")
        end
    end
end)
    

    -- Trolling Options list
    local trolling_player_root = menu.list(menu.player_root(pid), "Trolling Options", {}, "")

    menu.action(trolling_player_root, "Stun", {"stun"}, "", function()
        local targetPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local targetCoords = ENTITY.GET_ENTITY_COORDS(targetPed, true)

        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(
            targetCoords.x, targetCoords.y, targetCoords.z,
            targetCoords.x, targetCoords.y, targetCoords.z + 0.1,
            0, 1, util.joaat("weapon_stungun_mp"), players.user_ped(), true, false, 100.0
        )
    end)


    menu.action(trolling_player_root, "Raygun", {"raygun"}, "Shoots a raygun shot at the player's feet.", function()
        local targetPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local targetCoords = ENTITY.GET_ENTITY_COORDS(targetPed, true)
        local endCoords = {
            x = targetCoords.x,
            y = targetCoords.y,
            z = targetCoords.z - 1.0
        }
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(
            targetCoords.x, targetCoords.y, targetCoords.z,
            endCoords.x, endCoords.y, endCoords.z,
            0, 1, util.joaat("weapon_raypistol"), players.user_ped(), true, false, 100.0
        )
    end)
    
    menu.action(trolling_player_root, "Burn", {"burn"}, "Throws a Molotov at the player to set them on fire.", function()
        local targetPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local targetCoords = ENTITY.GET_ENTITY_COORDS(targetPed, true)
        local groundCoords = {
            x = targetCoords.x,
            y = targetCoords.y,
            z = targetCoords.z - 1.0
        }
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(
            targetCoords.x, targetCoords.y, targetCoords.z + 0.05,  -- Start the bullet slightly above the player
            groundCoords.x, groundCoords.y, groundCoords.z,        -- End it at ground level
            0, 1, util.joaat("weapon_molotov"), players.user_ped(), true, false, 100.0
        )
    end)
    

    menu.action(trolling_player_root, "Stab", {"stab"}, "Sends an NPC to stab the player.", function()
        local targetPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local targetCoords = ENTITY.GET_ENTITY_COORDS(targetPed, true)
        local muggerModel = util.joaat("g_m_m_chigoon_02")
        STREAMING.REQUEST_MODEL(muggerModel)
        while not STREAMING.HAS_MODEL_LOADED(muggerModel) do
            util.yield()
        end
        local mugger = entities.create_ped(5, muggerModel, targetCoords, 0)
        PED.SET_PED_COMBAT_ATTRIBUTES(mugger, 46, true)
        TASK.TASK_COMBAT_PED(mugger, targetPed, 0, 16)
        WEAPON.GIVE_WEAPON_TO_PED(mugger, util.joaat("weapon_knife"), 1, false, true)
        ENTITY.SET_ENTITY_HEALTH(mugger, 200)
        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(muggerModel)
    end)

        menu.action(trolling_player_root, "Airstrike", {""}, "Delivers an airstike to the player.", function(on_click)
        local pidPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local abovePed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 0, 50)
        local abovePed2 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 0, 15)
        local onPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 0, .5)
        local frontOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 3, 1)
        local frontOfPed2 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 5, 1)
        local backOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, -3, 1)
        local backOfPed2 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, -5, 1)
        local rightOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 3, 0, 1)
        local rightOfPed2 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 5, 0, 1)
        local leftOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, -3, 0, 1)
        local leftOfPed2 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, -5, 0, 1)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(abovePed2.x, abovePed2.y, abovePed2.z, onPed.x, onPed.y, onPed.z, 100, true, 1233104067, 0, true, false, 100) --1233104067 is Flare
        util.yield(5000)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(abovePed.x, abovePed.y, abovePed.z, backOfPed.x, backOfPed.y, backOfPed.z, 100, true, 1752584910, 0, true, false, 250) --1752584910 is Homing Missle
        util.yield(500)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(abovePed.x, abovePed.y, abovePed.z, leftOfPed.x, leftOfPed.y, leftOfPed.z, 100, true, 1752584910, 0, true, false, 250)
        util.yield(500)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(abovePed.x, abovePed.y, abovePed.z, frontOfPed.x, frontOfPed.y, frontOfPed.z, 100, true, 1752584910, 0, true, false, 250)
        util.yield(500)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(abovePed.x, abovePed.y, abovePed.z, rightOfPed.x, rightOfPed.y, rightOfPed.z, 100, true, 1752584910, 0, true, false, 250)
        util.yield(500)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(abovePed.x, abovePed.y, abovePed.z, backOfPed2.x, backOfPed2.y, backOfPed2.z, 100, true, 1752584910, 0, true, false, 250)
        util.yield(500)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(abovePed.x, abovePed.y, abovePed.z, leftOfPed2.x, leftOfPed2.y, leftOfPed2.z, 100, true, 1752584910, 0, true, false, 250)
        util.yield(500)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(abovePed.x, abovePed.y, abovePed.z, frontOfPed2.x, frontOfPed2.y, frontOfPed2.z, 100, true, 1752584910, 0, true, false, 250)
        util.yield(500)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(abovePed.x, abovePed.y, abovePed.z, rightOfPed2.x, rightOfPed2.y, rightOfPed2.z, 100, true, 1752584910, 0, true, false, 250)
    end)

    -- Heads Up! submenu creation
    local hu_menu = menu.list(trolling_player_root, "Heads Up!", {" "}, "Heads Up!\nDrop entities on the player's head.")
    local dropveh = menu.list(hu_menu, "Vehicles", {" "}, "Heads Up!\nDrop Vehicles on the player's head.")
    local dropobj = menu.list(hu_menu, "Objects", {" "}, "Heads Up!\nDrop Objects on the player's head.")
    local dropped = menu.list(hu_menu, "Peds/Animals", {" "}, "Heads Up!\nDrop Peds/Animals on the player's head.")

    -- Drop Taco Truck
    menu.action(dropveh, "Taco Truck", {""}, "Drops a Taco Truck on the selected player.", function(on_click)
        local pidPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local abovePidPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 0, 10)
        local vehHash = util.joaat("taco")
        STREAMING.REQUEST_MODEL(vehHash)
        while not STREAMING.HAS_MODEL_LOADED(vehHash) do util.yield() end
        local spawnedTruck = VEHICLE.CREATE_VEHICLE(vehHash, abovePidPed.x, abovePidPed.y, abovePidPed.z, 0, true, true, false)
        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(vehHash)
        util.yield(3000)
        entities.delete_by_handle(spawnedTruck)
    end)

    -- Drop Dumptruck
    menu.action(dropveh, "DumpTruck", {""}, "Drops a DumpTruck on the selected player.", function(on_click)
        local pidPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local abovePidPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 0, 10)
        local vehHash = util.joaat("dump")
        STREAMING.REQUEST_MODEL(vehHash)
        while not STREAMING.HAS_MODEL_LOADED(vehHash) do util.yield() end
        local spawnedTruck = VEHICLE.CREATE_VEHICLE(vehHash, abovePidPed.x, abovePidPed.y, abovePidPed.z, 0, true, true, false)
        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(vehHash)
        util.yield(3000)
        entities.delete_by_handle(spawnedTruck)
    end)

    -- Drop Dozer
        menu.action(dropveh, "Bulldozer", {""}, "Drops a Bulldozer on the selected player.", function(on_click)
        local pidPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local abovePidPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 0, 10)
        local vehHash = util.joaat("bulldozer")
        STREAMING.REQUEST_MODEL(vehHash)
        while not STREAMING.HAS_MODEL_LOADED(vehHash) do util.yield() end
        local spawnedTruck = VEHICLE.CREATE_VEHICLE(vehHash, abovePidPed.x, abovePidPed.y, abovePidPed.z, 0, true, true, false)
        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(vehHash)
        util.yield(3000)
        entities.delete_by_handle(spawnedTruck)
    end)

    -- Drop Tractor
        menu.action(dropveh, "Tractor", {""}, "Drops a Tractor on the selected player.", function(on_click)
        local pidPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local abovePidPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 0, 10)
        local vehHash = util.joaat("tractor")
        STREAMING.REQUEST_MODEL(vehHash)
        while not STREAMING.HAS_MODEL_LOADED(vehHash) do util.yield() end
        local spawnedTruck = VEHICLE.CREATE_VEHICLE(vehHash, abovePidPed.x, abovePidPed.y, abovePidPed.z, 0, true, true, false)
        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(vehHash)
        util.yield(3000)
        entities.delete_by_handle(spawnedTruck)
    end)

    -- Drop Lawn Mower
        menu.action(dropveh, "Lawn Mower", {""}, "Drops a Lawn Mower on the selected player.", function(on_click)
        local pidPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local abovePidPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 0, 10)
        local vehHash = util.joaat("mower")
        STREAMING.REQUEST_MODEL(vehHash)
        while not STREAMING.HAS_MODEL_LOADED(vehHash) do util.yield() end
        local spawnedTruck = VEHICLE.CREATE_VEHICLE(vehHash, abovePidPed.x, abovePidPed.y, abovePidPed.z, 0, true, true, false)
        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(vehHash)
        util.yield(3000)
        entities.delete_by_handle(spawnedTruck)
    end)

    -- Drop BMX
        menu.action(dropveh, "BMX", {""}, "Drops a BMX on the selected player.", function(on_click)
        local pidPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local abovePidPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 0, 10)
        local vehHash = util.joaat("bmx")
        STREAMING.REQUEST_MODEL(vehHash)
        while not STREAMING.HAS_MODEL_LOADED(vehHash) do util.yield() end
        local spawnedTruck = VEHICLE.CREATE_VEHICLE(vehHash, abovePidPed.x, abovePidPed.y, abovePidPed.z, 0, true, true, false)
        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(vehHash)
        util.yield(3000)
        entities.delete_by_handle(spawnedTruck)
    end)

    -- Function to drop an object on the selected player
    local function dropObjectOnPlayer(pid, objectModel)
        local pidPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local abovePidPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 0, 10)
        STREAMING.REQUEST_MODEL(objectModel)
        while not STREAMING.HAS_MODEL_LOADED(objectModel) do 
            util.yield() 
        end
        local spawnedObject = OBJECT.CREATE_OBJECT(objectModel, abovePidPed.x, abovePidPed.y, abovePidPed.z, true, true, false)
        ENTITY.SET_ENTITY_DYNAMIC(spawnedObject, true)
        ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(spawnedObject, 1, 0.0, 0.0, -10.0, true, true, true, true)
        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(objectModel)
        util.yield(6000)
        entities.delete_by_handle(spawnedObject)
    end

    menu.action(dropobj, "Coffin", {}, "Drops a Coffin on the selected player.", function()
        dropObjectOnPlayer(pid, util.joaat("prop_coffin_01"))
    end)

    menu.action(dropobj, "Yacht", {}, "Drops a Yacht on the selected player.", function()
        dropObjectOnPlayer(pid, util.joaat("prop_cj_big_boat"))
    end)

    menu.action(dropobj, "Soccer Ball", {}, "Drops a Yacht on the selected player.", function()
        dropObjectOnPlayer(pid, util.joaat("p_ld_soc_ball_01"))
    end)

    menu.action(dropobj, "Big Soccer Ball", {}, "Drops a Big Soccer Ball on the selected player.", function()
        dropObjectOnPlayer(pid, util.joaat("stt_prop_stunt_soccer_lball"))
    end)

    menu.action(dropobj, "Asteroid", {}, "Drops a Yacht on the selected player.", function()
        dropObjectOnPlayer(pid, util.joaat("prop_asteroid_01"))
    end)

    menu.action(dropobj, "Alien Egg", {}, "Drops an Alien Egg on the selected player.", function()
        dropObjectOnPlayer(pid, util.joaat("prop_alien_egg_01"))
    end)

    menu.action(dropobj, "Barbell", {}, "Drops a Barbell on the selected player.", function()
        dropObjectOnPlayer(pid, util.joaat("prop_barbell_01"))
    end)

    menu.action(dropobj, "Toilet", {}, "Drops a Toilet on the selected player.", function()
        dropObjectOnPlayer(pid, util.joaat("prop_toilet_01"))
    end)

    menu.action(dropobj, "Dildo", {}, "Drops a Dildo on the selected player.", function()
        dropObjectOnPlayer(pid, util.joaat("prop_cs_dildo_01"))
    end)


    -- Function to drop a ped (animal) on the selected player
    local function dropPedOnPlayer(pid, pedModel)
    local pidPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
    local abovePidPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 0, 10)
    STREAMING.REQUEST_MODEL(pedModel)
    while not STREAMING.HAS_MODEL_LOADED(pedModel) do 
        util.yield() 
    end
    local spawnedPed = entities.create_ped(0, pedModel, abovePidPed, 0.0)
    ENTITY.SET_ENTITY_DYNAMIC(spawnedPed, true)
    ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(spawnedPed, 1, 0.0, 0.0, -10.0, true, true, true, true)
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(pedModel)
    util.yield(6000)
    entities.delete_by_handle(spawnedPed)
    end

    menu.action(dropped, "Pig", {}, "Drops a Pig on the selected player.", function()
        dropPedOnPlayer(pid, util.joaat("a_c_pig"))
    end)

    menu.action(dropped, "Cow", {}, "Drops a Cow on the selected player.", function()
        dropPedOnPlayer(pid, util.joaat("a_c_cow"))
    end)
    
    menu.action(dropped, "Mountain Lion", {}, "Drops a Mountain Lion on the selected player.", function()
        dropPedOnPlayer(pid, util.joaat("a_c_mtlion"))
    end)
    
    menu.action(dropped, "Dog (Rottweiler)", {}, "Drops a Rottweiler Dog on the selected player.", function()
        dropPedOnPlayer(pid, util.joaat("a_c_rottweiler"))
    end)
    
    menu.action(dropped, "Dog (Poodle)", {}, "Drops a Poodle on the selected player.", function()
        dropPedOnPlayer(pid, util.joaat("a_c_poodle"))
    end)
    
    menu.action(dropped, "Dog (Husky)", {}, "Drops a Husky on the selected player.", function()
        dropPedOnPlayer(pid, util.joaat("a_c_husky"))
    end)
    
    menu.action(dropped, "Rabbit", {}, "Drops a Rabbit on the selected player.", function()
        dropPedOnPlayer(pid, util.joaat("a_c_rabbit_01"))
    end)

    menu.action(dropped, "Big Rabbit", {}, "Drops a Big Rabbit on the selected player.", function()
        dropPedOnPlayer(pid, util.joaat("a_c_rabbit_02"))
    end)

    menu.action(dropped, "Rat", {}, "Drops a Rat on the selected player.", function()
        dropPedOnPlayer(pid, util.joaat("a_c_rat"))
    end)
    
    menu.action(dropped, "Hen", {}, "Drops a Hen on the selected player.", function()
        dropPedOnPlayer(pid, util.joaat("a_c_hen"))
    end)
    
    menu.action(dropped, "Seagull", {}, "Drops a Seagull on the selected player.", function()
        dropPedOnPlayer(pid, util.joaat("a_c_seagull"))
    end)
    
    menu.action(dropped, "Fish", {}, "Drops a Fish on the selected player.", function()
        dropPedOnPlayer(pid, util.joaat("a_c_fish"))
    end)

    menu.action(dropped, "Shark", {}, "Drops a Shark on the selected player.", function()
        dropPedOnPlayer(pid, util.joaat("a_c_sharktiger"))
    end)

    menu.action(dropped, "Chimp", {}, "Drops a Chimp on the selected player.", function()
        dropPedOnPlayer(pid, util.joaat("a_c_chimp"))
    end)

    menu.toggle_loop(trolling_player_root, "Infinite Ladder", {}, "Do you think this player needs to reach higher elevation?", function(on)    -- Credit to Lola
        local LadderHash = 1122863164 --3469023669
        local pedm = GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local SpawnOffset = GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pedm, 0, 2, 2.5)
        if not DOES_ENTITY_EXIST(OBJ) then
            OBJ = entities.create_object(LadderHash, SpawnOffset)
        end
        local SpawnOffset = GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pedm, 0, 2, 2.5)
        local Player_Rot = GET_ENTITY_ROTATION(pedm, 2)
        SET_ENTITY_COORDS_NO_OFFSET(OBJ, SpawnOffset.x, SpawnOffset.y, SpawnOffset.z, false, false, false)
        SET_ENTITY_ROTATION(OBJ, Player_Rot.x, Player_Rot.y, Player_Rot.z, 2, true)
    end, function()
        entities.delete(OBJ)
    end)


    -- Self-Destructing Animals
    local animal_options = {
        { name = "Bunny", model = util.joaat("a_c_rabbit_01") },
        { name = "Cat", model = util.joaat("a_c_cat_01") },
        { name = "Rat", model = util.joaat("a_c_rat") },
        { name = "Hen", model = util.joaat("a_c_hen") },
        { name = "Pug", model = util.joaat("a_c_pug") },
        { name = "Pig", model = util.joaat("a_c_pig") }
    }
    
    local function spawn_self_destruct_animal(pid, animal)
        util.request_model(animal.model)
        local pedm = GET_PLAYER_PED_SCRIPT_INDEX(pid)
        local radius = 5
        local SpawnOffset = GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pedm, math.random(-radius, radius), math.random(-radius, radius), 0)
        local pet = entities.create_ped(28, animal.model, SpawnOffset, 0)
        entities.set_can_migrate(pet, false)
        NETWORK_REQUEST_CONTROL_OF_ENTITY(pet)
    
        util.create_tick_handler(function()
            local pos = GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pedm, 0, 0, 0)
            SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(pet, true)
            TASK_GO_TO_COORD_ANY_MEANS(pet, pos.x, pos.y, pos.z, 5.0, 0, false, 0, 0.0)
            local petOffset = GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pet, 0, 0, 0)
            util.yield(1500)
            if IS_ENTITY_DEAD(pet) then
                entities.delete(pet)
                ADD_EXPLOSION(petOffset.x, petOffset.y, petOffset.z, 0, 1.0, true, false, 1.0, false)
                return false
            end
        end)
    end
    
    local animal_menu = menu.list(trolling_player_root, "Self-Destruct Animals", {}, "Choose an animal to spawn that follows the player and explodes when killed.")
    for _, animal in ipairs(animal_options) do
        menu.action(animal_menu, animal.name, {}, "Spawn a self-destructing " .. animal.name .. ".", function()
            spawn_self_destruct_animal(pid, animal)
        end)
    end
    
    local rain_menu = menu.list(trolling_player_root, "Rain", {}, "Make it rain in certain ways above the selected player.")
    menu.toggle_loop(rain_menu, "Snow", {}, "Makes it snow over the player.", function(on)
        local hashSnowball = 126349499
        local radius = 4
        local owner = players.user_ped()
        local Offset = GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(players.user_ped(), math.random(-radius, radius), math.random(-radius, radius), math.random(-radius, radius))
        SHOOT_SINGLE_BULLET_BETWEEN_COORDS(Offset.x, Offset.y, Offset.z+5, Offset.x, Offset.y, Offset.z+2, 0, true, hashSnowball, owner, true, false, 1.0)
    end, function()
    end)
    menu.toggle_loop(rain_menu, "Tazer", {}, "Spawns shocking rain over the player.", function(on)
        local hashSnowball = 911657153
        local radius = 4
        local owner = players.user_ped()
        local Offset = GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(players.user_ped(), math.random(-radius, radius), math.random(-radius, radius), math.random(-radius, radius))
        SHOOT_SINGLE_BULLET_BETWEEN_COORDS(Offset.x, Offset.y, Offset.z+5, Offset.x, Offset.y, Offset.z+2, 0, true, hashSnowball, owner, true, false, 1.0)
    end, function()
    end)
    menu.toggle_loop(rain_menu, "Fire", {}, "Rain fire over the player.", function(on)
        local hashSnowball = 615608432
        local radius = 4
        local owner = players.user_ped()
        local Offset = GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(players.user_ped(), math.random(-radius, radius), math.random(-radius, radius), math.random(-radius, radius))
        SHOOT_SINGLE_BULLET_BETWEEN_COORDS(Offset.x, Offset.y, Offset.z+5, Offset.x, Offset.y, Offset.z+2, 0, true, hashSnowball, owner, true, false, 1.0)
    end, function()
    end)

    local stopSigns = {}
    menu.toggle(trolling_player_root, "Stop Signs", {"stopsigns"}, "Spawns stop signs around the player. Toggle off to remove them.", function(state)
        local playerPed = PLAYER.GET_PLAYER_PED(pid)
        local playerCoords = ENTITY.GET_ENTITY_COORDS(playerPed, true)
        local stopSignHash = util.joaat("prop_sign_road_01a")
        local radius = 2.8 -- Radius of the circle
        local numSigns = 5 -- Number of stop signs to spawn
        STREAMING.REQUEST_MODEL(stopSignHash)
        while not STREAMING.HAS_MODEL_LOADED(stopSignHash) do
            util.yield()
        end
    
        if state then
            for _, stopSign in ipairs(stopSigns) do
                if ENTITY.DOES_ENTITY_EXIST(stopSign) then
                    ENTITY.SET_ENTITY_AS_MISSION_ENTITY(stopSign, true, true)
                    OBJECT.DELETE_OBJECT(stopSign)
                end
            end
            stopSigns = {}

            for i = 0, numSigns - 1 do
                local angle = (i / numSigns) * 2 * math.pi -- Calculate angle in radians
                local x = playerCoords.x + radius * math.cos(angle)
                local y = playerCoords.y + radius * math.sin(angle)
                local z = playerCoords.z
    
                local stopSign = OBJECT.CREATE_OBJECT(stopSignHash, x, y, z, true, true, false)
                OBJECT.w_ON_GROUND_OR_OBJECT_PROPERLY(stopSign)
                local heading = (angle + math.pi) % (2 * math.pi) -- Face inwards
                ENTITY.SET_ENTITY_HEADING(stopSign, math.deg(heading))  
                ENTITY.FREEZE_ENTITY_POSITION(stopSign, true)
                table.insert(stopSigns, stopSign)
            end
        else
            for _, stopSign in ipairs(stopSigns) do
                if ENTITY.DOES_ENTITY_EXIST(stopSign) then
                    ENTITY.SET_ENTITY_AS_MISSION_ENTITY(stopSign, true, true)
                    OBJECT.DELETE_OBJECT(stopSign)
                end
            end
            stopSigns = {}
        end
    end)

    -- The Force --
    local player_force_radius = 6.0 -- Radius for the force

    local function calculate_distance(pos1, pos2)
        return math.sqrt((pos2.x - pos1.x)^2 + (pos2.y - pos1.y)^2 + (pos2.z - pos1.z)^2)
    end
    local function normalize_vector(vector)
        local magnitude = math.sqrt(vector.x^2 + vector.y^2 + vector.z^2)
        if magnitude == 0 then return {x = 0, y = 0, z = 0} end
        return {x = vector.x / magnitude, y = vector.y / magnitude, z = vector.z / magnitude}
    end
    
    menu.toggle_loop(trolling_player_root, "The Force", {""}, "Pushes away nearby entities within a 6 meter radius.", function()
        local player_ped = PLAYER.GET_PLAYER_PED(pid)
        local player_pos = ENTITY.GET_ENTITY_COORDS(player_ped, true)

        local vehicles = entities.get_all_vehicles_as_pointers()
        for _, vehicle_pointer in ipairs(vehicles) do
            local vehicle_handle = entities.pointer_to_handle(vehicle_pointer)
            if vehicle_handle ~= vehicle_main then
                local vehicle_pos = ENTITY.GET_ENTITY_COORDS(vehicle_handle, true)
                local distance = calculate_distance(player_pos, vehicle_pos)
                if distance <= player_force_radius then
                    local direction = {x = vehicle_pos.x - player_pos.x, y = vehicle_pos.y - player_pos.y, z = vehicle_pos.z - player_pos.z}
                    direction = normalize_vector(direction)
                    ENTITY.APPLY_FORCE_TO_ENTITY(vehicle_handle, 3, direction.x, direction.y, direction.z, 0.0, 0.0, 1.0, 0, false, false, true, false, false)
                end
            end
        end

        local peds = entities.get_all_peds_as_pointers()
        for _, ped_pointer in ipairs(peds) do
            local ped_handle = entities.pointer_to_handle(ped_pointer)
            if ped_handle ~= player_ped then
                local ped_pos = ENTITY.GET_ENTITY_COORDS(ped_handle, true)
                local distance = calculate_distance(player_pos, ped_pos)
                if distance <= player_force_radius then
                    local direction = {x = ped_pos.x - player_pos.x, y = ped_pos.y - player_pos.y, z = ped_pos.z - player_pos.z}
                    direction = normalize_vector(direction)
                    PED.SET_PED_TO_RAGDOLL(ped_handle, 2500, 0, 0, false, false, false)
                    ENTITY.APPLY_FORCE_TO_ENTITY(ped_handle, 3, direction.x, direction.y, direction.z, 0.0, 0.0, 1.0, 0, false, false, true, false, false)
                end
            end
        end
    end)

     -- Blackhole --
    local blackhole_radius = 8.0 -- Radius for the blackhole effect

    local function calculate_distance(pos1, pos2)
        return math.sqrt((pos2.x - pos1.x)^2 + (pos2.y - pos1.y)^2 + (pos2.z - pos1.z)^2)
    end

    local function normalize_vector(vector)
        local magnitude = math.sqrt(vector.x^2 + vector.y^2 + vector.z^2)
        if magnitude == 0 then return {x = 0, y = 0, z = 0} end
        return {x = vector.x / magnitude, y = vector.y / magnitude, z = vector.z / magnitude}
    end

    menu.toggle_loop(trolling_player_root, "Blackhole", {"blackhole"}, "Pulls entities towards the player within a 6 meter radius.", function()
        local player_ped = PLAYER.GET_PLAYER_PED(pid)
        local player_pos = ENTITY.GET_ENTITY_COORDS(player_ped, true)

        local vehicles = entities.get_all_vehicles_as_pointers()
        for _, vehicle_pointer in ipairs(vehicles) do
            local vehicle_handle = entities.pointer_to_handle(vehicle_pointer)
            if vehicle_handle ~= vehicle_main then
                local vehicle_pos = ENTITY.GET_ENTITY_COORDS(vehicle_handle, true)
                local distance = calculate_distance(player_pos, vehicle_pos)
                if distance <= blackhole_radius then
                    local direction = {x = player_pos.x - vehicle_pos.x, y = player_pos.y - vehicle_pos.y, z = player_pos.z - vehicle_pos.z}
                    direction = normalize_vector(direction)
                    ENTITY.APPLY_FORCE_TO_ENTITY(vehicle_handle, 3, direction.x, direction.y, direction.z, 0.0, 0.0, 1.0, 0, false, false, true, false, false)
                end
            end
        end

        local peds = entities.get_all_peds_as_pointers()
        for _, ped_pointer in ipairs(peds) do
            local ped_handle = entities.pointer_to_handle(ped_pointer)
            if ped_handle ~= player_ped then
                local ped_pos = ENTITY.GET_ENTITY_COORDS(ped_handle, true)
                local distance = calculate_distance(player_pos, ped_pos)
                if distance <= blackhole_radius then
                    local direction = {x = player_pos.x - ped_pos.x, y = player_pos.y - ped_pos.y, z = player_pos.z - ped_pos.z}
                    direction = normalize_vector(direction)
                    PED.SET_PED_TO_RAGDOLL(ped_handle, 2500, 0, 0, false, false, false)
                    ENTITY.APPLY_FORCE_TO_ENTITY(ped_handle, 3, direction.x, direction.y, direction.z, 0.0, 0.0, 1.0, 0, false, false, true, false, false)
                end
            end
        end
    end)

    menu.toggle_loop(trolling_player_root, "Stumble", {}, "Makes the selected player stumble.", function()
        local playerPed = GET_PLAYER_PED_SCRIPT_INDEX(pid) 
        if playerPed == nil or playerPed == 0 then return end
        local mdl = util.joaat("prop_roofvent_06a")
        local pos = players.get_position(playerPed)
        pos.z = pos.z - 2.4
        util.request_model(mdl)
        local middleVent = entities.create_object(mdl, pos)
        ENTITY.SET_ENTITY_VISIBLE(middleVent, false)
        local vent = {}
        for i = 1, 4 do
            local angle = math.rad((i / 4) * 360)
            local obj_pos = v3.new(math.cos(angle) * 1.25, math.sin(angle) * 1.25, pos.z)
            obj_pos:add(pos)
            vent[i] = entities.create_object(mdl, obj_pos)
            ENTITY.SET_ENTITY_VISIBLE(vent[i], false)
        end
        util.yield(500)
        entities.delete(middleVent)
        for _, obj in ipairs(vent) do
            entities.delete(obj)
        end
    end)
   
    menu.action(trolling_player_root, "Launch Player Upwards", {}, "Sends the player flying into the air.", function()
        local playerPed = PLAYER.GET_PLAYER_PED(pid)
        if playerPed == 0 then return end
        local playerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(playerID)
        ENTITY.APPLY_FORCE_TO_ENTITY(playerPed, 1, 0, 0, 100.0, 0, 0, 0, 0, true, false, true, false, true)
    end)

    menu.action(trolling_player_root, "Trip Player", {}, "Makes the selected player trip and fall.", function()
        local playerPed = PLAYER.GET_PLAYER_PED(pid)
        if playerPed == 0 then return end
        local playerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(targetPlayerID)
        PED.SET_PED_TO_RAGDOLL(playerPed, 5000, 5000, 0, false, false, false)
    end)

    local targetPlayerID = pid
    local function get_player_coords(player_id)
        local playerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
        return ENTITY.GET_ENTITY_COORDS(playerPed, true)
    end
    local function normalize_vector(x, y, z)
        local length = math.sqrt(x * x + y * y + z * z)
        if length > 0 then
            return x / length, y / length, z / length
        else
            return 0, 0, 0
        end
    end
    local function make_vehicles_drive_towards_player(target_coords)
        local vehicles = entities.get_all_vehicles_as_handles()
        for _, vehicle in ipairs(vehicles) do
            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(vehicle)
            local veh_coords = ENTITY.GET_ENTITY_COORDS(vehicle, true)
            local dir_x = target_coords.x - veh_coords.x
            local dir_y = target_coords.y - veh_coords.y
            local dir_z = target_coords.z - veh_coords.z
            local norm_x, norm_y, norm_z = normalize_vector(dir_x, dir_y, dir_z)
            -- Set the vehicle's forward speed to move towards the player
            VEHICLE.SET_VEHICLE_FORWARD_SPEED(vehicle, 30.0)  -- Adjust speed as needed
            ENTITY.SET_ENTITY_ROTATION(vehicle, math.deg(math.atan2(norm_y, norm_x)), 0, 0, 2, true, true)
        end
    end
    menu.toggle_loop(trolling_player_root, "Chaotic Car Show", {"chaoticcarshow"}, "Vehicles around the player become chaotic.", function(on)
        local target_coords = get_player_coords(targetPlayerID)
        make_vehicles_drive_towards_player(target_coords)
    end)
end


local function on_player_join(pid)
    generate_features(pid)
end

players.on_join(on_player_join)
players.dispatch_on_join()

util.on_stop(function()
    util.toast("Bye Booty Lover!")
end)
