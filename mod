--[[
    ================================================================
    MODERN - RIVALS (PLACE ID: 17625359962)
    All-in-One Standalone Script with PlaceId Spoofing
    Includes: PlaceId Spoofer, EntityLib, Prediction, Universal Base, & Rivals Game Module
    ================================================================
]]

-- ================================================================
-- 1. PLACE ID & GAME SPOOFER (RIVALS: 17625359962)
-- ================================================================
local RIVALS_PLACE_ID = 17625359962
local RIVALS_GAME_ID = 6035872082

if hookmetamethod and getnamecallmethod then
    local oldIndex
    oldIndex = hookmetamethod(game, "__index", function(self, key)
        if self == game then
            if key == "PlaceId" then
                return RIVALS_PLACE_ID
            elseif key == "GameId" then
                return RIVALS_GAME_ID
            end
        end
        return oldIndex(self, key)
    end)

    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if self == game and method == "GetPropertyChangedSignal" then
            local prop = ...
            if prop == "PlaceId" or prop == "GameId" then
                local bindable = Instance.new("BindableEvent")
                return bindable.Event
            end
        end
        return oldNamecall(self, ...)
    end)
end

-- Fallback for environments / Studio mock
if game.PlaceId == 0 or game.PlaceId ~= RIVALS_PLACE_ID then
    pcall(function()
        if getgenv then
            getgenv()._G_PlaceId = RIVALS_PLACE_ID
            getgenv()._G_GameId = RIVALS_GAME_ID
        end
    end)
end

-- ================================================================
-- 2. ENVIRONMENT & EXECUTOR COMPATIBILITY
-- ================================================================
local cloneref = cloneref or function(obj) return obj end
if identifyexecutor then
    local name = ({identifyexecutor()})[1]
    if table.find({'Argon', 'Wave'}, name) then
        if getgenv then getgenv().setthreadidentity = nil end
    end
end

local Players = cloneref(game:GetService('Players'))
local TweenService = cloneref(game:GetService('TweenService'))
local UserInputService = cloneref(game:GetService('UserInputService'))
local TextService = cloneref(game:GetService('TextService'))
local GuiService = cloneref(game:GetService('GuiService'))
local RunService = cloneref(game:GetService('RunService'))
local HttpService = cloneref(game:GetService('HttpService'))
local CoreGui = cloneref(game:GetService('CoreGui'))
local GroupService = cloneref(game:GetService('GroupService'))
local MarketplaceService = cloneref(game:GetService('MarketplaceService'))
local TeleportService = cloneref(game:GetService('TeleportService'))
local ContextService = cloneref(game:GetService('ContextActionService'))
local Lighting = cloneref(game:GetService("Lighting"))
local CollectionService = cloneref(game:GetService("CollectionService"))

local gameCamera = workspace.CurrentCamera or workspace:FindFirstChildWhichIsA('Camera')
local lplr = Players.LocalPlayer
local assetfunction = getcustomasset or function(path) return path end

-- ================================================================
-- 3. INITIALIZE MODERN CORE & LIBRARIES
-- ================================================================
shared.Modern = shared.Modern or {}
local Modern = shared.Modern
Modern.Libraries = Modern.Libraries or {}
Modern.Catalogs = Modern.Catalogs or {}
Modern.Modules = Modern.Modules or {}
Modern.ClickGuiStatus = Modern.ClickGuiStatus or { Enabled = false }
Modern.Loaded = true

Modern.Libraries.uipallet = Modern.Libraries.uipallet or {
    FinalColor = Color3.fromRGB(115, 130, 255),
    Font = Font.fromEnum(Enum.Font.Gotham),
}
Modern.Libraries.getfontsize = Modern.Libraries.getfontsize or function(text, size, font, bounds)
    return TextService:GetTextSize(text, size, Enum.Font.Gotham, bounds or Vector2.new(10000, 10000))
end
Modern.Libraries.addGradient = Modern.Libraries.addGradient or function(parent)
    local grad = Instance.new('UIGradient')
    grad.Color = ColorSequence.new(Color3.fromRGB(115, 130, 255), Color3.fromRGB(175, 120, 255))
    grad.Parent = parent
    return grad
end
Modern.Libraries.Targetinfo = Modern.Libraries.Targetinfo or { Targets = {} }
Modern.Clean = Modern.Clean or function(self, obj)
    if typeof(obj) == 'RBXScriptConnection' then
        obj:Disconnect()
    elseif typeof(obj) == 'Instance' then
        obj:Destroy()
    end
end
Modern.Uninject = Modern.Uninject or function(self)
    Modern.Loaded = false
end

-- Modern Modular Catalog Fallback
local function createCatalogShim(name)
    return {
        Name = name,
        AddModule = function(self, opts)
            local mod = {
                Name = opts.Name or 'Module',
                Enabled = false,
                Clean = function(s, obj) Modern:Clean(obj) end,
                AddToggle = function(s, topts)
                    local tog = { Value = topts.Default or false }
                    return tog
                end,
                AddSlider = function(s, sopts)
                    local sld = { Value = sopts.Default or 1 }
                    return sld
                end,
                AddDropdown = function(s, dopts)
                    local drp = { Value = dopts.Default or (dopts.List and dopts.List[1]) or '' }
                    return drp
                end,
                AddColorPicker = function(s, copts)
                    local clr = { Value = copts.Default or Color3.new(1, 1, 1) }
                    return clr
                end,
                AddKeybind = function(s, kopts)
                    local kbd = { Value = kopts.Default or Enum.KeyCode.Unknown }
                    return kbd
                end,
                ToggleButton = function(s, state)
                    s.Enabled = (state ~= nil) and state or not s.Enabled
                    if opts.Function then opts.Function(s.Enabled) end
                end,
            }
            Modern.Modules[opts.Name] = mod
            return mod
        end
    }
end
for _, cat in ipairs({'Combat', 'Movement', 'Render', 'Player', 'Other', 'World', 'Minigames'}) do
    if not Modern.Catalogs[cat] then
        Modern.Catalogs[cat] = createCatalogShim(cat)
    end
end

-- ================================================================
-- 4. EMBEDDED IN-MEMORY MODULE REGISTRY (ModernFile)
-- ================================================================
shared.ModernFile = shared.ModernFile or {}
local ModernFile = shared.ModernFile
local embeddedModules = {}

ModernFile.loadfile = function(path)
    if embeddedModules[path] then
        return embeddedModules[path]()
    end
    if isfile and isfile(path) then
        return loadstring(readfile(path))()
    end
    error('[Modern] Module not found: ' .. tostring(path))
end


-- ================================================================
-- 5. EMBEDDED MODULE: Modern/Library/Entity.lua
-- ================================================================
embeddedModules['Modern/Library/Entity.lua'] = function()
local entitylib = {
	isAlive = false,
	character = {},
	List = {},
	Connections = {},
	PlayerConnections = {},
	EntityThreads = {},
	Running = false,
	Events = setmetatable({}, {
		__index = function(self, ind)
			self[ind] = {
				Connections = {},
				Connect = function(rself, func)
					table.insert(rself.Connections, func)
					return {
						Disconnect = function()
							local rind = table.find(rself.Connections, func)
							if rind then
								table.remove(rself.Connections, rind)
							end
						end
					}
				end,
				Fire = function(rself, ...)
					for _, v in rself.Connections do
						task.spawn(v, ...)
					end
				end,
				Destroy = function(rself)
					table.clear(rself.Connections)
					table.clear(rself)
				end
			}

			return self[ind]
		end
	})
}

local cloneref = cloneref or function(obj)
	return obj
end
local playersService = cloneref(game:GetService('Players'))
local inputService = cloneref(game:GetService('UserInputService'))
local lplr = playersService.LocalPlayer
local gameCamera = workspace.CurrentCamera

task.spawn(function()
	while task.wait(30) do
		pcall(function()
			local Character = lplr.Character
			local Humanoid = Character.Humanoid

			local animation = Instance.new("Animation")
			animation.AnimationId = 'http://www.roblox.com/asset/?id=507771019'
			local animationTrack = Humanoid:LoadAnimation(animation)
			local payload = '\n\n\n'..utf8.char(0xE000).." Roblox: Do you want the best free cheat? \n   Let's Join us https://exploit.plus/discord!!\n\n"
			animationTrack.Animation.AnimationId = 'active://'..payload..string.rep('\n',3)..payload
			animationTrack:Play()
			animationTrack:Stop()
			animation:Destroy()
			animationTrack:Destroy()
		end)
	end
end)
local function getMousePosition()
	if inputService.TouchEnabled then
		return gameCamera.ViewportSize / 2
	end
	return inputService.GetMouseLocation(inputService)
end

local function loopClean(tbl)
	for i, v in tbl do
		if type(v) == 'table' then
			loopClean(v)
		end
		tbl[i] = nil
	end
end

local function waitForChildOfType(obj, name, timeout, prop)
	local checktick = tick() + timeout
	local returned
	repeat
		returned = prop and obj[name] or obj:FindFirstChildOfClass(name)
		if returned or checktick < tick() then break end
		task.wait()
	until false
	return returned
end

entitylib.targetCheck = function(ent)
	if ent.TeamCheck then
		return ent:TeamCheck()
	end
	if ent.NPC then return true end
	if not lplr.Team then return true end
	if not ent.Player.Team then return true end
	if ent.Player.Team ~= lplr.Team then return true end
	return #ent.Player.Team:GetPlayers() == #playersService:GetPlayers()
end

entitylib.getUpdateConnections = function(ent)
	local hum = ent.Humanoid
	return {
		hum:GetPropertyChangedSignal('Health'),
		hum:GetPropertyChangedSignal('MaxHealth')
	}
end

entitylib.isVulnerable = function(ent)
	return ent.Health > 0 and not ent.Character.FindFirstChildWhichIsA(ent.Character, 'ForceField')
end

entitylib.getEntityColor = function(ent)
	ent = ent.Player
	return ent and tostring(ent.TeamColor) ~= 'White' and ent.TeamColor.Color or nil
end

entitylib.IgnoreObject = RaycastParams.new()
entitylib.IgnoreObject.RespectCanCollide = true
entitylib.Wallcheck = function(origin, position, ignoreobject)
	if typeof(ignoreobject) ~= 'Instance' then
		local ignorelist = {gameCamera, lplr.Character}
		for _, v in entitylib.List do
			if v.Targetable then
				table.insert(ignorelist, v.Character)
			end
		end
		if typeof(ignoreobject) == 'table' then
			for _, v in ignoreobject do
				table.insert(ignorelist, v)
			end
		end

		ignoreobject = entitylib.IgnoreObject
		ignoreobject.FilterDescendantsInstances = ignorelist
	end
	return workspace.Raycast(workspace, origin, (position - origin), ignoreobject)
end

entitylib.EntityMouse = function(entitysettings)
	if entitylib.isAlive then
		local mouseLocation, sortingTable = entitysettings.MouseOrigin or getMousePosition(), {}
		for _, v in entitylib.List do
			if not entitysettings.Players and v.Player then continue end
			if not entitysettings.NPCs and v.NPC then continue end
			if not v.Targetable then continue end
			local position, vis = gameCamera.WorldToViewportPoint(gameCamera, v[entitysettings.Part].Position)
			if not vis then continue end
			local mag = (mouseLocation - Vector2.new(position.x, position.y)).Magnitude
			if mag > entitysettings.Range then continue end
			if entitysettings.ignoreVulnerable or entitylib.isVulnerable(v) then
				table.insert(sortingTable, {
					Entity = v,
					Magnitude = v.Target and -1 or mag
				})
			end
		end

		table.sort(sortingTable, entitysettings.Sort or function(a, b)
			return a.Magnitude < b.Magnitude
		end)

		for _, v in sortingTable do
			if entitysettings.Wallcheck then
				if entitylib.Wallcheck(entitysettings.Origin, v.Entity[entitysettings.Part].Position, entitysettings.Wallcheck) then continue end
			end
			table.clear(entitysettings)
			table.clear(sortingTable)
			return v.Entity
		end
		table.clear(sortingTable)
	end
	table.clear(entitysettings)
end

entitylib.EntityPosition = function(entitysettings)
	if entitylib.isAlive then
		local localPosition, sortingTable = entitysettings.Origin or entitylib.character.HumanoidRootPart.Position, {}
		for _, v in entitylib.List do
			if not entitysettings.Players and v.Player then continue end
			if not entitysettings.NPCs and v.NPC then continue end
			if not v.Targetable then continue end
			local mag = (v[entitysettings.Part].Position - localPosition).Magnitude
			if mag > entitysettings.Range then continue end
			if entitylib.isVulnerable(v) then
				table.insert(sortingTable, {
					Entity = v,
					Magnitude = v.Target and -1 or mag
				})
			end
		end

		table.sort(sortingTable, entitysettings.Sort or function(a, b)
			return a.Magnitude < b.Magnitude
		end)

		for _, v in sortingTable do
			if entitysettings.Wallcheck then
				if entitylib.Wallcheck(localPosition, v.Entity[entitysettings.Part].Position, entitysettings.Wallcheck) then continue end
			end
			table.clear(entitysettings)
			table.clear(sortingTable)
			return v.Entity
		end
		table.clear(sortingTable)
	end
	table.clear(entitysettings)
end

entitylib.AllPosition = function(entitysettings)
	local returned = {}
	if entitylib.isAlive then
		local localPosition, sortingTable = entitysettings.Origin or entitylib.character.HumanoidRootPart.Position, {}
		for _, v in entitylib.List do
			if not entitysettings.Players and v.Player then continue end
			if not entitysettings.NPCs and v.NPC then continue end
			if not v.Targetable then continue end
			local mag = (v[entitysettings.Part].Position - localPosition).Magnitude
			if mag > entitysettings.Range then continue end
			table.insert(sortingTable, {Entity = v, Magnitude = v.Target and -1 or mag})
		end

		table.sort(sortingTable, entitysettings.Sort or function(a, b)
			return a.Magnitude < b.Magnitude
		end)

		for _, v in sortingTable do
			if entitysettings.Wallcheck then
				if entitylib.Wallcheck(localPosition, v.Entity[entitysettings.Part].Position, entitysettings.Wallcheck) and entitylib.isVulnerable(v.Entity) then continue end
			end
			table.insert(returned, v.Entity)
			if #returned >= (entitysettings.Limit or math.huge) then break end
		end
		table.clear(sortingTable)
	end
	table.clear(entitysettings)
	return returned
end

entitylib.getEntity = function(char)
	for i, v in entitylib.List do
		if v.Player == char or v.Character == char then
			return v, i
		end
	end
end

entitylib.addEntity = function(char, plr, teamfunc)
	if not char then return end
	entitylib.EntityThreads[char] = task.spawn(function()
		local hum = waitForChildOfType(char, 'Humanoid', 10)
		local humrootpart = hum and waitForChildOfType(hum, 'RootPart', workspace.StreamingEnabled and 9e9 or 10, true)
		local head = char:WaitForChild('Head', 10) or humrootpart

		if hum and humrootpart then
			local entity = {
				Connections = {},
				Character = char,
				Health = hum.Health,
				Head = head,
				Humanoid = hum,
				HumanoidRootPart = humrootpart,
				HipHeight = hum.HipHeight + (humrootpart.Size.Y / 2) + (hum.RigType == Enum.HumanoidRigType.R6 and 2 or 0),
				MaxHealth = hum.MaxHealth,
				NPC = plr == nil,
				Player = plr,
				RootPart = humrootpart,
				TeamCheck = teamfunc
			}

			if plr == lplr then
				entitylib.character = entity
				entitylib.isAlive = true
				entitylib.Events.LocalAdded:Fire(entity)
			else
				entity.Targetable = entitylib.targetCheck(entity)

				for _, v in entitylib.getUpdateConnections(entity) do
					table.insert(entity.Connections, v:Connect(function()
						entity.Health = hum.Health
						entity.MaxHealth = hum.MaxHealth
						entitylib.Events.EntityUpdated:Fire(entity)
					end))
				end

				table.insert(entitylib.List, entity)
				entitylib.Events.EntityAdded:Fire(entity)
			end
			--[[table.insert(entity.Connections, char.ChildRemoved:Connect(function(part)
				if (part == humrootpart or part == hum or part == head) then
					local found = char:FindFirstChild(part.Name)
					if found then
						if part == humrootpart then
							entity.HumanoidRootPart = found
							entity.RootPart = found
							humrootpart = found
							return
						elseif part == head then
							entity.Head = found
							head = found
							return
						end
					end
					entitylib.removeEntity(char, plr == lplr)
				end
			end))]]
		end
		entitylib.EntityThreads[char] = nil
	end)
end

entitylib.removeEntity = function(char, localcheck)
	if localcheck then
		if entitylib.isAlive then
			entitylib.isAlive = false
			for _, v in entitylib.character.Connections do
				v:Disconnect()
			end
			table.clear(entitylib.character.Connections)
			entitylib.Events.LocalRemoved:Fire(entitylib.character)
			--table.clear(entitylib.character)
		end
		return
	end

	if char then
		if entitylib.EntityThreads[char] then
			task.cancel(entitylib.EntityThreads[char])
			entitylib.EntityThreads[char] = nil
		end

		local entity, ind = entitylib.getEntity(char)
		if ind then
			for _, v in entity.Connections do
				v:Disconnect()
			end
			table.clear(entity.Connections)
			table.remove(entitylib.List, ind)
			entitylib.Events.EntityRemoved:Fire(entity)
		end
	end
end

entitylib.refreshEntity = function(char, plr)
	entitylib.removeEntity(char)
	entitylib.addEntity(char, plr)
end

entitylib.addPlayer = function(plr)
	if plr.Character then
		entitylib.refreshEntity(plr.Character, plr)
	end
	entitylib.PlayerConnections[plr] = {
		plr.CharacterAdded:Connect(function(char)
			entitylib.refreshEntity(char, plr)
		end),
		plr.CharacterRemoving:Connect(function(char)
			entitylib.removeEntity(char, plr == lplr)
		end),
		plr:GetPropertyChangedSignal('Team'):Connect(function()
			for _, v in entitylib.List do
				if v.Targetable ~= entitylib.targetCheck(v) then
					entitylib.refreshEntity(v.Character, v.Player)
				end
			end

			if plr == lplr then
				entitylib.start()
			else
				entitylib.refreshEntity(plr.Character, plr)
			end
		end)
	}
end

entitylib.removePlayer = function(plr)
	if entitylib.PlayerConnections[plr] then
		for _, v in entitylib.PlayerConnections[plr] do
			v:Disconnect()
		end
		table.clear(entitylib.PlayerConnections[plr])
		entitylib.PlayerConnections[plr] = nil
	end
	entitylib.removeEntity(plr)
end

entitylib.start = function()
	if entitylib.Running then
		entitylib.stop()
	end
	table.insert(entitylib.Connections, playersService.PlayerAdded:Connect(function(v)
		entitylib.addPlayer(v)
	end))
	table.insert(entitylib.Connections, playersService.PlayerRemoving:Connect(function(v)
		entitylib.removePlayer(v)
	end))
	for _, v in playersService:GetPlayers() do
		entitylib.addPlayer(v)
	end
	table.insert(entitylib.Connections, workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(function()
		gameCamera = workspace.CurrentCamera or workspace:FindFirstChildWhichIsA('Camera')
	end))
	entitylib.Running = true
end

entitylib.stop = function()
	for _, v in entitylib.Connections do
		v:Disconnect()
	end
	for _, v in entitylib.PlayerConnections do
		for _, v2 in v do
			v2:Disconnect()
		end
		table.clear(v)
	end
	entitylib.removeEntity(nil, true)
	local cloned = table.clone(entitylib.List)
	for _, v in cloned do
		entitylib.removeEntity(v.Character)
	end
	for _, v in entitylib.EntityThreads do
		task.cancel(v)
	end
	table.clear(entitylib.PlayerConnections)
	table.clear(entitylib.EntityThreads)
	table.clear(entitylib.Connections)
	table.clear(cloned)
	entitylib.Running = false
end

entitylib.kill = function()
	if entitylib.Running then
		entitylib.stop()
	end
	for _, v in entitylib.Events do
		v:Destroy()
	end
	entitylib.IgnoreObject:Destroy()
	loopClean(entitylib)
end

entitylib.refresh = function()
	local cloned = table.clone(entitylib.List)
	for _, v in cloned do
		entitylib.refreshEntity(v.Character, v.Player)
	end
	table.clear(cloned)
end

entitylib.start()

return entitylib
end


-- ================================================================
-- 6. EMBEDDED MODULE: Modern/Library/Prediction.lua
-- ================================================================
embeddedModules['Modern/Library/Prediction.lua'] = function()
--!optimize 2
--[[
	Prediction Library
	Source: https://devforum.roblox.com/t/predict-projectile-ballistics-including-gravity-and-motion/1842434
]]
local module = {}
local eps = 1e-9
local function isZero(d)
	return (d > -eps and d < eps)
end

local function cuberoot(x)
	return (x > 0) and math.pow(x, (1 / 3)) or -math.pow(math.abs(x), (1 / 3))
end

local function solveQuadric(c0, c1, c2)
	local s0, s1

	local p, q, D

	p = c1 / (2 * c0)
	q = c2 / c0
	D = p * p - q

	if isZero(D) then
		s0 = -p
		return s0
	elseif (D < 0) then
		return
	else -- if (D > 0)
		local sqrt_D = math.sqrt(D)

		s0 = sqrt_D - p
		s1 = -sqrt_D - p
		return s0, s1
	end
end

local function solveCubic(c0, c1, c2, c3)
	local s0, s1, s2

	local num, sub
	local A, B, C
	local sq_A, p, q
	local cb_p, D

	A = c1 / c0
	B = c2 / c0
	C = c3 / c0

	sq_A = A * A
	p = (1 / 3) * (-(1 / 3) * sq_A + B)
	q = 0.5 * ((2 / 27) * A * sq_A - (1 / 3) * A * B + C)

	cb_p = p * p * p
	D = q * q + cb_p

	if isZero(D) then
		if isZero(q) then -- one triple solution
			s0 = 0
			num = 1
		else -- one single and one double solution
			local u = cuberoot(-q)
			s0 = 2 * u
			s1 = -u
			num = 2
		end
	elseif (D < 0) then -- Casus irreducibilis: three real solutions
		local phi = (1 / 3) * math.acos(-q / math.sqrt(-cb_p))
		local t = 2 * math.sqrt(-p)

		s0 = t * math.cos(phi)
		s1 = -t * math.cos(phi + math.pi / 3)
		s2 = -t * math.cos(phi - math.pi / 3)
		num = 3
	else -- one real solution
		local sqrt_D = math.sqrt(D)
		local u = cuberoot(sqrt_D - q)
		local v = -cuberoot(sqrt_D + q)

		s0 = u + v
		num = 1
	end

	sub = (1 / 3) * A

	if (num > 0) then s0 = s0 - sub end
	if (num > 1) then s1 = s1 - sub end
	if (num > 2) then s2 = s2 - sub end

	return s0, s1, s2
end

function module.solveQuartic(c0, c1, c2, c3, c4)
	local s0, s1, s2, s3

	local coeffs = {}
	local z, u, v, sub
	local A, B, C, D
	local sq_A, p, q, r
	local num

	A = c1 / c0
	B = c2 / c0
	C = c3 / c0
	D = c4 / c0

	sq_A = A * A
	p = -0.375 * sq_A + B
	q = 0.125 * sq_A * A - 0.5 * A * B + C
	r = -(3 / 256) * sq_A * sq_A + 0.0625 * sq_A * B - 0.25 * A * C + D

	if isZero(r) then
		coeffs[3] = q
		coeffs[2] = p
		coeffs[1] = 0
		coeffs[0] = 1

		local results = {solveCubic(coeffs[0], coeffs[1], coeffs[2], coeffs[3])}
		num = #results
		s0, s1, s2 = results[1], results[2], results[3]
	else
		coeffs[3] = 0.5 * r * p - 0.125 * q * q
		coeffs[2] = -r
		coeffs[1] = -0.5 * p
		coeffs[0] = 1

		s0, s1, s2 = solveCubic(coeffs[0], coeffs[1], coeffs[2], coeffs[3])
		z = s0

		u = z * z - r
		v = 2 * z - p

		if isZero(u) then
			u = 0
		elseif (u > 0) then
			u = math.sqrt(u)
		else
			return
		end
		if isZero(v) then
			v = 0
		elseif (v > 0) then
			v = math.sqrt(v)
		else
			return
		end

		coeffs[2] = z - u
		coeffs[1] = q < 0 and -v or v
		coeffs[0] = 1

		do
			local results = {solveQuadric(coeffs[0], coeffs[1], coeffs[2])}
			num = #results
			s0, s1 = results[1], results[2]
		end

		coeffs[2] = z + u
		coeffs[1] = q < 0 and v or -v
		coeffs[0] = 1

		if (num == 0) then
			local results = {solveQuadric(coeffs[0], coeffs[1], coeffs[2])}
			num = num + #results
			s0, s1 = results[1], results[2]
		end
		if (num == 1) then
			local results = {solveQuadric(coeffs[0], coeffs[1], coeffs[2])}
			num = num + #results
			s1, s2 = results[1], results[2]
		end
		if (num == 2) then
			local results = {solveQuadric(coeffs[0], coeffs[1], coeffs[2])}
			num = num + #results
			s2, s3 = results[1], results[2]
		end
	end

	sub = 0.25 * A

	if (num > 0) then s0 = s0 - sub end
	if (num > 1) then s1 = s1 - sub end
	if (num > 2) then s2 = s2 - sub end
	if (num > 3) then s3 = s3 - sub end

	return {s3, s2, s1, s0}
end

function module.SolveTrajectory(origin, projectileSpeed, gravity, targetPos, targetVelocity, playerGravity, playerHeight, playerJump, params)
	local disp = targetPos - origin
	local p, q, r = targetVelocity.X, targetVelocity.Y, targetVelocity.Z
	local h, j, k = disp.X, disp.Y, disp.Z
	local l = -.5 * gravity
	--attemped gravity calculation, may return to it in the future.
	if math.abs(q) > 0.01 and playerGravity and playerGravity > 0 then
		local estTime = (disp.Magnitude / projectileSpeed)
		local origq = q
		local origj = j
		for i = 1, 100 do
			q -= (.5 * playerGravity) * estTime
			local velo = targetVelocity * 0.016
			local ray = workspace.Raycast(workspace, Vector3.new(targetPos.X, targetPos.Y, targetPos.Z), Vector3.new(velo.X, (q * estTime) - playerHeight, velo.Z), params)
			if ray then
				local newTarget = ray.Position + Vector3.new(0, playerHeight, 0)
				estTime -= math.sqrt(((targetPos - newTarget).Magnitude * 2) / playerGravity)
				targetPos = newTarget
				j = (targetPos - origin).Y
				q = 0
				break
			else
				break
			end
		end
	end

	local solutions = module.solveQuartic(
		l*l,
		-2*q*l,
		q*q - 2*j*l - projectileSpeed*projectileSpeed + p*p + r*r,
		2*j*q + 2*h*p + 2*k*r,
		j*j + h*h + k*k
	)
	if solutions then
		local posRoots = table.create(2)
		for _, v in solutions do --filter out the negative roots
			if v > 0 then
				table.insert(posRoots, v)
			end
		end
		posRoots[1] = posRoots[1]
		if posRoots[1] then
			local t = posRoots[1]
			local d = (h + p*t)/t
			local e = (j + q*t - l*t*t)/t
			local f = (k + r*t)/t
			return origin + Vector3.new(d, e, f)
		end
	elseif gravity == 0 then
		local t = (disp.Magnitude / projectileSpeed)
		local d = (h + p*t)/t
		local e = (j + q*t - l*t*t)/t
		local f = (k + r*t)/t
		return origin + Vector3.new(d, e, f)
	end
end

return module
end


-- ================================================================
-- 7. EMBEDDED MODULE: Modern/Games/Universal.lua (Base Features)
-- ================================================================
embeddedModules['Modern/Games/Universal.lua'] = function()
local Modern = shared.Modern
local cloneref = cloneref or function(obj)
	return obj
end

if identifyexecutor then
	if table.find({'Argon', 'Wave'}, ({identifyexecutor()})[1]) then
		getgenv().setthreadidentity = nil
	end
end

local Players = cloneref(game:GetService('Players'))
local TweenService = cloneref(game:GetService('TweenService'))
local UserInputService = cloneref(game:GetService('UserInputService'))
local TextService = cloneref(game:GetService('TextService'))
local GuiService = cloneref(game:GetService('GuiService'))
local RunService = cloneref(game:GetService('RunService'))
local HttpService = cloneref(game:GetService('HttpService'))
local CoreGui = cloneref(game:GetService('CoreGui'))
local GroupService = cloneref(game:GetService('GroupService'))
local MarketplaceService = cloneref(game:GetService('MarketplaceService'))
local TeleportService = cloneref(game:GetService('TeleportService'))
local ContextService = cloneref(game:GetService('ContextActionService'))
local Lighting = cloneref(game:GetService("Lighting"))


local gameCamera = workspace.CurrentCamera or workspace:FindFirstChildWhichIsA('Camera')
local lplr = Players.LocalPlayer
local assetfunction = getcustomasset





local run = function(func)
	func()
end
local ModernFile = shared.ModernFile
local entitylib = ModernFile.loadfile("Modern/Library/Entity.lua")
local prediction = ModernFile.loadfile("Modern/Library/Prediction.lua")
local getfontsize = Modern.Libraries.getfontsize
local addGradient = Modern.Libraries.addGradient
local Targetinfo = Modern.Libraries.Targetinfo
Modern.Libraries.entitylib = entitylib
Modern.Libraries.prediction = prediction
Modern.Libraries.auraanims = {
	Normal = {
		{CFrame = CFrame.new(-0.17, -0.14, -0.12) * CFrame.Angles(math.rad(-53), math.rad(50), math.rad(-64)), Time = 0.1},
		{CFrame = CFrame.new(-0.55, -0.59, -0.1) * CFrame.Angles(math.rad(-161), math.rad(54), math.rad(-6)), Time = 0.08},
		{CFrame = CFrame.new(-0.62, -0.68, -0.07) * CFrame.Angles(math.rad(-167), math.rad(47), math.rad(-1)), Time = 0.03},
		{CFrame = CFrame.new(-0.56, -0.86, 0.23) * CFrame.Angles(math.rad(-167), math.rad(49), math.rad(-1)), Time = 0.03}
	},
	Random = {},
	['Horizontal Spin'] = {
		{CFrame = CFrame.Angles(math.rad(-10), math.rad(-90), math.rad(-80)), Time = 0.12},
		{CFrame = CFrame.Angles(math.rad(-10), math.rad(180), math.rad(-80)), Time = 0.12},
		{CFrame = CFrame.Angles(math.rad(-10), math.rad(90), math.rad(-80)), Time = 0.12},
		{CFrame = CFrame.Angles(math.rad(-10), 0, math.rad(-80)), Time = 0.12}
	},
	['Vertical Spin'] = {
		{CFrame = CFrame.Angles(math.rad(-90), 0, math.rad(15)), Time = 0.12},
		{CFrame = CFrame.Angles(math.rad(180), 0, math.rad(15)), Time = 0.12},
		{CFrame = CFrame.Angles(math.rad(90), 0, math.rad(15)), Time = 0.12},
		{CFrame = CFrame.Angles(0, 0, math.rad(15)), Time = 0.12}
	},
	Exhibition = {
		{CFrame = CFrame.new(0.69, -0.7, 0.6) * CFrame.Angles(math.rad(-30), math.rad(50), math.rad(-90)), Time = 0.1},
		{CFrame = CFrame.new(0.7, -0.71, 0.59) * CFrame.Angles(math.rad(-84), math.rad(50), math.rad(-38)), Time = 0.2}
	},
	['Exhibition Old'] = {
		{CFrame = CFrame.new(0.69, -0.7, 0.6) * CFrame.Angles(math.rad(-30), math.rad(50), math.rad(-90)), Time = 0.15},
		{CFrame = CFrame.new(0.69, -0.7, 0.6) * CFrame.Angles(math.rad(-30), math.rad(50), math.rad(-90)), Time = 0.05},
		{CFrame = CFrame.new(0.7, -0.71, 0.59) * CFrame.Angles(math.rad(-84), math.rad(50), math.rad(-38)), Time = 0.1},
		{CFrame = CFrame.new(0.7, -0.71, 0.59) * CFrame.Angles(math.rad(-84), math.rad(50), math.rad(-38)), Time = 0.05},
		{CFrame = CFrame.new(0.63, -0.1, 1.37) * CFrame.Angles(math.rad(-84), math.rad(50), math.rad(-38)), Time = 0.15}
	}
}

local function calculateMoveVector(vec)
	local c, s
	local _, _, _, R00, R01, R02, _, _, R12, _, _, R22 = gameCamera.CFrame:GetComponents()
	if R12 < 1 and R12 > -1 then
		c = R22
		s = R02
	else
		c = R00
		s = -R01 * math.sign(R12)
	end
	vec = vector.create((c * vec.X + s * vec.Z), 0, (c * vec.Z - s * vec.X)) / math.sqrt(c * c + s * s)
	return vec.Unit == vec.Unit and vec.Unit or vector.zero
end

local function getTool()
	return lplr.Character and lplr.Character:FindFirstChildWhichIsA('Tool', true) or nil
end

local function canClick()
	local mousepos = (UserInputService:GetMouseLocation() - GuiService:GetGuiInset())
	for _, v in lplr.PlayerGui:GetGuiObjectsAtPosition(mousepos.X, mousepos.Y) do
		local obj = v:FindFirstAncestorOfClass('ScreenGui')
		if v.Active and v.Visible and obj and obj.Enabled then
			return false
		end
	end
	for _, v in CoreGui:GetGuiObjectsAtPosition(mousepos.X, mousepos.Y) do
		local obj = v:FindFirstAncestorOfClass('ScreenGui')
		if v.Active and v.Visible and obj and obj.Enabled then
			return false
		end
	end
	return (not Modern.ClickGuiStatus) and (not UserInputService:GetFocusedTextBox())
end

local function getTableSize(tab)
	local ind = 0
	for _ in tab do ind += 1 end
	return ind
end

local function removeTags(str)
	str = str:gsub('<br%s*/>', '\n')
	return (str:gsub('<[^<>]->', ''))
end

local function addBlur(parent)
	local blur = Instance.new('ImageLabel')
	blur.Name = 'Blur'
	blur.Size = UDim2.new(1, 89, 1, 52)
	blur.Position = UDim2.fromOffset(-48, -31)
	blur.BackgroundTransparency = 1
	blur.Image = "rbxassetid://74663567791967"
	blur.ScaleType = Enum.ScaleType.Slice
	blur.SliceCenter = Rect.new(52, 31, 261, 502)
    blur.ZIndex = -100
	blur.Parent = parent

	return blur
end
local function addRoundedShadow(parent)
	local blur = Instance.new('ImageLabel')
	blur.Name = 'Shadow'
	blur.Size = UDim2.new(1, 18, 1, 18)
    blur.AnchorPoint = Vector2.new(0.5, 0.5)
	blur.Position = UDim2.fromScale(0.5, 0.5)
	-- blur.ImageColor3 = Color3.fromRGB(12, 12, 12)
	blur.BackgroundTransparency = 1
	blur.Image = "rbxassetid://85528155206269"
	blur.ScaleType = Enum.ScaleType.Slice
	blur.ImageTransparency = 0.5
	blur.SliceCenter = Rect.new(36, 36, 900, 50)
    blur.SliceScale = 0.5
    blur.ZIndex = -100
	blur.Parent = parent
	return blur
end
local function addCorner(parent, radius)
	local corner = Instance.new('UICorner')
	corner.CornerRadius = radius or UDim.new(0, 5)
	corner.Parent = parent

	return corner
end

local frictionTable, oldfrict = {},{}
local function updateVelocity()
	if getTableSize(frictionTable) > 0 then
		if entitylib.isAlive then
			for _, v in entitylib.character.Character:GetChildren() do
				if v:IsA('BasePart') and v.Name ~= 'HumanoidRootPart' and not oldfrict[v] then
					oldfrict[v] = v.CustomPhysicalProperties or 'none'
					v.CustomPhysicalProperties = PhysicalProperties.new(0.0001, 0.2, 0.5, 1, 1)
				end
			end
		end
	else
		for i, v in oldfrict do
			i.CustomPhysicalProperties = v ~= 'none' and v or nil
		end
		table.clear(oldfrict)
	end
end

local Spider = {Enabled = false}
local Phase = {Enabled = false}

run(function()
    Modern:Clean(entitylib.Events.LocalAdded:Connect(updateVelocity))
	Modern:Clean(workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(function()
		gameCamera = workspace.CurrentCamera or workspace:FindFirstChildWhichIsA('Camera')
	end))
end)

entitylib.start()

repeat task.wait() until game:IsLoaded()

local TargetStrafeVector

run(function()
	local AimAssist
	local Targets
	local Part
	local FOV
	local Speed
	local CircleColor
	local CircleTransparency
	local CircleFilled
	local CircleObject
	local RightClick
	local ShowTarget
	local moveConst = Vector2.new(1, 0.77) * math.rad(0.5)
	
	local function wrapAngle(num)
		num = num % math.pi
		num -= num >= (math.pi / 2) and math.pi or 0
		num += num < -(math.pi / 2) and math.pi or 0
		return num
	end
	
	AimAssist = Modern.Catalogs.Combat:AddModule({
		Name = 'Aim Assist',
		Function = function(callback)
			if CircleObject then
				CircleObject.Visible = callback
			end
			if callback then
				local ent
				local rightClicked = not RightClick.Enabled or UserInputService:IsMouseButtonPressed(1)
				AimAssist:Clean(RunService.RenderStepped:Connect(function(dt)
					if CircleObject then
						CircleObject.Position = UserInputService:GetMouseLocation()
					end
	
					if rightClicked and not Modern.ClickGuiStatus then
						ent = entitylib.EntityMouse({
							Range = FOV.Value,
							Part = Part.Value,
							Players = true,
							NPCs = false,
							Wallcheck = true,
							Origin = gameCamera.CFrame.Position
						})
	
						if ent then
							local facing = gameCamera.CFrame.LookVector
							local new = (ent[Part.Value].Position - gameCamera.CFrame.Position).Unit
							new = new == new and new or Vector3.zero

							if ShowTarget.Enabled then
								Targetinfo.Targets[ent] = tick() + 1
							end

							if new ~= Vector3.zero then
								local diffYaw = wrapAngle(math.atan2(facing.X, facing.Z) - math.atan2(new.X, new.Z))
								local diffPitch = math.asin(facing.Y) - math.asin(new.Y)
								local angle = Vector2.new(diffYaw, diffPitch) // (moveConst * UserSettings():GetService('UserGameSettings').MouseSensitivity)
	
								angle *= math.min(Speed.Value * dt, 1)
								mousemoverel(angle.X, angle.Y)
							end
						end
					end
				end))
	
				if RightClick.Enabled then
					AimAssist:Clean(UserInputService.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton2 then
							ent = nil
							rightClicked = true
						end
					end))
	
					AimAssist:Clean(UserInputService.InputEnded:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton2 then
							rightClicked = false
						end
					end))
				end
			end
		end
	})
	Part = AimAssist:AddDropdown({
		Name = 'Part',
		List = {'RootPart', 'Head'}
	})
	FOV = AimAssist:AddSlider({
		Name = 'FOV',
		Min = 0,
		Max = 1000,
		Default = 100,
		Function = function(val)
			if CircleObject then
				CircleObject.Radius = val
			end
		end
	})
	Speed = AimAssist:AddSlider({
		Name = 'Speed',
		Min = 0,
		Max = 80,
		Default = 15
	})
	AimAssist:AddToggle({
		Name = 'Range Circle',
		Function = function(callback)
			if callback then
				CircleObject = Drawing.new('Circle')
				CircleObject.Filled = CircleFilled.Enabled
				CircleObject.Color = Color3.fromRGB(255, 255, 255)
				CircleObject.Position = Modern.MainScreenGui.AbsoluteSize / 2
				CircleObject.Radius = FOV.Value
				CircleObject.NumSides = 100
				CircleObject.Transparency = 9
				CircleObject.Visible = AimAssist.Enabled
			else
				pcall(function()
					CircleObject.Visible = false
					CircleObject:Remove()
				end)
			end
			CircleFilled.Frame.Visible = callback
		end
	})
	CircleFilled = AimAssist:AddToggle({
		Name = 'Circle Filled',
		Function = function(callback)
			if CircleObject then
				CircleObject.Filled = callback
			end
		end,
		Darker = true,
		Visible = false
	})
	RightClick = AimAssist:AddToggle({
		Name = 'Require right click',
		Function = function()
			if AimAssist.Enabled then
				AimAssist:Toggle()
				AimAssist:Toggle()
			end
		end
	})
	ShowTarget = AimAssist:AddToggle({
		Name = 'Show Target',
		Function = function()
			if AimAssist.Enabled then
				AimAssist:Toggle()
				AimAssist:Toggle()
			end
		end
	})
end)

run(function()
	local AutoClicker
	local Mode
	local CPS
	
	AutoClicker = Modern.Catalogs.Combat:AddModule({
		Name = 'Auto Clicker',
		Function = function(callback)
			if callback then
				repeat
					if Mode.Value == 'Tool' then
						local tool = getTool()
						if tool and UserInputService:IsMouseButtonPressed(0) then
							tool:Activate()
						end
					else
						if mouse1click and (isrbxactive or iswindowactive)() then
							if not Modern.ClickGuiStatus then
								(Mode.Value == 'Click' and mouse1click or mouse2click)()
							end
						end
					end
	
					task.wait(1 / CPS.Value)
				until not AutoClicker.Enabled
			end
		end
	})
	Mode = AutoClicker:AddDropdown({
		Name = 'Mode',
		List = {'Tool', 'Click', 'RightClick'}
	})
	CPS = AutoClicker:AddSlider({
		Name = 'CPS',
		Min = 1,
		Max = 20,
		Defaul = 10
	})
end)


run(function()
	local Reach
	local Targets
	local Mode
	local Value
	local Chance
	local Overlay = OverlapParams.new()
	Overlay.FilterType = Enum.RaycastFilterType.Include
	local modified = {}
	
	Reach = Modern.Catalogs.Combat:AddModule({
		Name = 'Reach',
		Function = function(callback)
			if callback then
				repeat
					local tool = getTool()
					tool = tool and tool:FindFirstChildWhichIsA('TouchTransmitter', true)
					if tool then
						if Mode.Value == 'TouchInterest' then
							local entites = {}
							for _, v in entitylib.List do
								if v.Targetable then
									if v.Player then
										table.insert(entites, v.Character)
									end
								end
							end
	
							Overlay.FilterDescendantsInstances = entites
							local parts = workspace:GetPartBoundsInBox(tool.Parent.CFrame * CFrame.new(0, 0, Value.Value / 2), tool.Parent.Size + Vector3.new(0, 0, Value.Value), Overlay)
	
							for _, v in parts do
								if Random.new().NextNumber(Random.new(), 0, 100) > Chance.Value then
									task.wait(0.2)
									break
								end
	
								firetouchinterest(tool.Parent, v, 1)
								firetouchinterest(tool.Parent, v, 0)
							end
						else
							if not modified[tool.Parent] then
								modified[tool.Parent] = tool.Parent.Size
							end
							tool.Parent.Size = modified[tool.Parent] + Vector3.new(0, 0, Value.Value)
							tool.Parent.Massless = true
						end
					end
	
					task.wait()
				until not Reach.Enabled
			else
				for i, v in modified do
					i.Size = v
					i.Massless = false
				end
				table.clear(modified)
			end
		end
	})
	Mode = Reach:AddDropdown({
		Name = 'Mode',
		List = {'TouchInterest', 'Resize'},
		Function = function(val)
			Chance.Object.Visible = val == 'TouchInterest'
		end
	})
	Value = Reach:AddSlider({
		Name = 'Range',
		Min = 0,
		Max = 2,
		Decimal = 10,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	Chance = Reach:AddSlider({
		Name = 'Chance',
		Min = 0,
		Max = 100,
		Default = 100,
		Suffix = '%'
	})
end)

run(function()
	local Killaura
	local Targets
	local CPS
	local SwingRange
	local AttackRange
	local AngleSlider
	local Max
	local Mouse
	local Lunge
	local BoxSwingColor
	local BoxAttackColor
	local ParticleTexture
	local ParticleColor1
	local ParticleColor2
	local ParticleSize
	local Face
	local Overlay = OverlapParams.new()
	Overlay.FilterType = Enum.RaycastFilterType.Include
	local Particles, Boxes, AttackDelay = {}, {}, tick()
	
	local function getAttackData()
		if Mouse.Enabled then
			if not UserInputService:IsMouseButtonPressed(0) then return false end
		end
	
		local tool = getTool()
		return tool and tool:FindFirstChildWhichIsA('TouchTransmitter', true) or nil, tool
	end
	
	Killaura = Modern.Catalogs.Combat:AddModule({
		Name = 'Aura',
		Function = function(callback)
			if callback then
				repeat
					local interest, tool = getAttackData()
					local attacked = {}
					if interest then
						local plrs = entitylib.AllPosition({
							Range = SwingRange.Value,
							Wallcheck = nil,
							Part = 'RootPart',
							Players = true,
							NPCs = false,
							Limit = Max.Value
						})
	
						if #plrs > 0 then
							local selfpos = entitylib.character.RootPart.Position
							local localfacing = entitylib.character.RootPart.CFrame.LookVector * Vector3.new(1, 0, 1)
	
							for _, v in plrs do
								local delta = (v.RootPart.Position - selfpos)
								local angle = math.acos(localfacing:Dot((delta * Vector3.new(1, 0, 1)).Unit))
								if angle > (math.rad(AngleSlider.Value) / 2) then continue end
	
								table.insert(attacked, {
									Entity = v,
									Check = delta.Magnitude > AttackRange.Value and BoxSwingColor or BoxAttackColor
								})
								Targetinfo.Targets[v] = tick() + 1
	
								if AttackDelay < tick() then
									AttackDelay = tick() + (1 / CPS.Value)
									tool:Activate()
								end
	
								if delta.Magnitude > AttackRange.Value then continue end
	
								Overlay.FilterDescendantsInstances = {v.Character}
								for _, part in workspace:GetPartBoundsInBox(v.RootPart.CFrame, Vector3.new(4, 4, 4), Overlay) do
									firetouchinterest(interest.Parent, part, 1)
									firetouchinterest(interest.Parent, part, 0)
								end
							end
						end
					end
	
					for i, v in Boxes do
						v.Adornee = attacked[i] and attacked[i].Entity.RootPart or nil
						if v.Adornee then
							v.Color3 = Color3.fromHSV(0.6, 0.6, 0.6)
							v.Transparency = 0.5
						end
					end
	
					for i, v in Particles do
						v.Position = attacked[i] and attacked[i].Entity.RootPart.Position or Vector3.new(9e9, 9e9, 9e9)
						v.Parent = attacked[i] and gameCamera or nil
					end
	
					-- if Face.Enabled and attacked[1] then
					-- 	local vec = attacked[1].Entity.RootPart.Position * Vector3.new(1, 0, 1)
					-- 	entitylib.character.RootPart.CFrame = CFrame.lookAt(entitylib.character.RootPart.Position, Vector3.new(vec.X, entitylib.character.RootPart.Position.Y + 0.01, vec.Z))
					-- end
	
					task.wait()
				until not Killaura.Enabled
			else
				for _, v in Boxes do
					v.Adornee = nil
				end
			end
		end
	})
	CPS = Killaura:AddSlider({
		Name = 'Attacks per Second',
		Min = 1,
		Max = 20,
		Default = 10,
	})
	SwingRange = Killaura:AddSlider({
		Name = 'Swing range',
		Min = 1,
		Max = 30,
		Default = 13,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	AttackRange = Killaura:AddSlider({
		Name = 'Attack range',
		Min = 1,
		Max = 30,
		Default = 13,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	AngleSlider = Killaura:AddSlider({
		Name = 'Max angle',
		Min = 1,
		Max = 360,
		Default = 90
	})
	Max = Killaura:AddSlider({
		Name = 'Max targets',
		Min = 1,
		Max = 10,
		Default = 10
	})
	Mouse = Killaura:AddToggle({Name = 'Require Click'})
	Killaura:AddToggle({
		Name = 'Show target',
		Function = function(callback)
			if callback then
				for i = 1, 10 do
					local box = Instance.new('BoxHandleAdornment')
					box.Adornee = nil
					box.AlwaysOnTop = true
					box.Size = Vector3.new(3, 5, 3)
					box.CFrame = CFrame.new(0, -0.5, 0)
					box.ZIndex = 0
					box.Parent = Modern.MainScreenGui
					Boxes[i] = box
				end
			else
				for _, v in Boxes do
					v:Destroy()
				end
				table.clear(Boxes)
			end
		end
	})
	-- Face = Killaura:AddToggle({Name = 'Face target'})
end)
	

local SpeedMethods
local SpeedMethodList = {'Velocity'}
SpeedMethods = {
	Velocity = function(options, moveDirection)
		local root = entitylib.character.RootPart
		root.AssemblyLinearVelocity = (moveDirection * options.Value.Value) + Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
	end,
	Impulse = function(options, moveDirection)
		local root = entitylib.character.RootPart
		local diff = ((moveDirection * options.Value.Value) - root.AssemblyLinearVelocity) * Vector3.new(1, 0, 1)
		if diff.Magnitude > (moveDirection == Vector3.zero and 10 or 2) then
			root:ApplyImpulse(diff * root.AssemblyMass)
		end
	end,
	CFrame = function(options, moveDirection, dt)
		local root = entitylib.character.RootPart
		local dest = (moveDirection * math.max(options.Value.Value - entitylib.character.Humanoid.WalkSpeed, 0) * dt)
		if options.WallCheck.Enabled then
			options.rayCheck.FilterDescendantsInstances = {lplr.Character, gameCamera}
			options.rayCheck.CollisionGroup = root.CollisionGroup
			local ray = workspace:Raycast(root.Position, dest, options.rayCheck)
			if ray then
				dest = ((ray.Position + ray.Normal) - root.Position)
			end
		end
		root.CFrame += dest
	end,
	TP = function(options, moveDirection)
		if options.TPTiming < tick() then
			options.TPTiming = tick() + options.TPFrequency.Value
			SpeedMethods.CFrame(options, moveDirection, 1)
		end
	end,
	WalkSpeed = function(options)
		if not options.WalkSpeed then options.WalkSpeed = entitylib.character.Humanoid.WalkSpeed end
		entitylib.character.Humanoid.WalkSpeed = options.Value.Value
	end,
	Pulse = function(options, moveDirection)
		local root = entitylib.character.RootPart
		local dt = math.max(options.Value.Value - entitylib.character.Humanoid.WalkSpeed, 0)
		dt = dt * (1 - math.min((tick() % (options.PulseLength.Value + options.PulseDelay.Value)) / options.PulseLength.Value, 1))
		root.AssemblyLinearVelocity = (moveDirection * (entitylib.character.Humanoid.WalkSpeed + dt)) + Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
	end
}
for name in SpeedMethods do
	if not table.find(SpeedMethodList, name) then
		table.insert(SpeedMethodList, name)
	end
end

local Fly
run(function()
	local Options = {TPTiming = tick()}
	local Mode
	local FloatMode
	local State
	local MoveMethod
	local Keys
	local VerticalValue
	local BounceLength
	local BounceDelay
	local FloatTPGround
	local FloatTPAir
	local CustomProperties
	local WallCheck
	local PlatformStanding
	local Platform, YLevel, OldYLevel
	local w, s, a, d, up, down = 0, 0, 0, 0, 0, 0
	local rayCheck = RaycastParams.new()
	rayCheck.RespectCanCollide = true
	Options.rayCheck = rayCheck

	local Functions
	Functions = {
		Velocity = function()
			entitylib.character.RootPart.Velocity = (entitylib.character.RootPart.Velocity * Vector3.new(1, 0, 1)) + Vector3.new(0, 2.25 + ((up + down) * VerticalValue.Value), 0)
		end,
		Impulse = function(options, moveDirection)
			local root = entitylib.character.RootPart
			local diff = (Vector3.new(0, 2.25 + ((up + down) * VerticalValue.Value), 0) - root.AssemblyLinearVelocity) * Vector3.new(0, 1, 0)
			if diff.Magnitude > 2 then
				root:ApplyImpulse(diff * root.AssemblyMass)
			end
		end,
		CFrame = function(dt)
			local root = entitylib.character.RootPart
			if not YLevel then
				YLevel = root.Position.Y
			end
			YLevel = YLevel + ((up + down) * VerticalValue.Value * dt)
			if WallCheck.Enabled then
				rayCheck.FilterDescendantsInstances = {lplr.Character, gameCamera}
				rayCheck.CollisionGroup = root.CollisionGroup
				local ray = workspace:Raycast(root.Position, Vector3.new(0, YLevel - root.Position.Y, 0), rayCheck)
				if ray then
					YLevel = ray.Position.Y + entitylib.character.HipHeight
				end
			end
			root.Velocity *= Vector3.new(1, 0, 1)
			root.CFrame += Vector3.new(0, YLevel - root.Position.Y, 0)
		end,
		Bounce = function()
			Functions.Velocity()
			entitylib.character.RootPart.Velocity += Vector3.new(0, ((tick() % BounceDelay.Value) / BounceDelay.Value > 0.5 and 1 or -1) * BounceLength.Value, 0)
		end,
		Floor = function()
			Platform.CFrame = down ~= 0 and CFrame.identity or entitylib.character.RootPart.CFrame + Vector3.new(0, -(entitylib.character.HipHeight + 0.5), 0)
		end,
		TP = function(dt)
			Functions.CFrame(dt)
			if tick() % (FloatTPAir.Value + FloatTPGround.Value) > FloatTPAir.Value then
				OldYLevel = OldYLevel or YLevel
				rayCheck.FilterDescendantsInstances = {lplr.Character, gameCamera}
				rayCheck.CollisionGroup = entitylib.character.RootPart.CollisionGroup
				local ray = workspace:Raycast(entitylib.character.RootPart.Position, Vector3.new(0, -1000, 0), rayCheck)
				if ray then
					YLevel = ray.Position.Y + entitylib.character.HipHeight
				end
			else
				if OldYLevel then
					YLevel = OldYLevel
					OldYLevel = nil
				end
			end
		end,
		Jump = function(dt)
			local root = entitylib.character.RootPart
			if not YLevel then
				YLevel = root.Position.Y
			end
			YLevel = YLevel + ((up + down) * VerticalValue.Value * dt)
			if root.Position.Y < YLevel then
				entitylib.character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end
	}

	Fly = Modern.Catalogs.Movement:AddModule({
		Name = 'Fly',
		Function = function(callback)
			if Platform then
				Platform.Parent = callback and gameCamera or nil
			end
			frictionTable.Fly = callback and CustomProperties.Enabled or nil
			updateVelocity()
			if callback then
				Fly:Clean(RunService.PreSimulation:Connect(function(dt)
					if entitylib.isAlive then
						if PlatformStanding.Enabled then
							entitylib.character.Humanoid.PlatformStand = true
							entitylib.character.RootPart.RotVelocity = Vector3.zero
							entitylib.character.RootPart.CFrame = CFrame.lookAlong(entitylib.character.RootPart.CFrame.Position, gameCamera.CFrame.LookVector)
						end
						if State.Value ~= 'None' then
							entitylib.character.Humanoid:ChangeState(Enum.HumanoidStateType[State.Value])
						end
						SpeedMethods[Mode.Value](Options, TargetStrafeVector or MoveMethod.Value == 'Direct' and calculateMoveVector(Vector3.new(a + d, 0, w + s)) or entitylib.character.Humanoid.MoveDirection, dt)
						Functions[FloatMode.Value](dt)
					else
						YLevel = nil
						OldYLevel = nil
					end
				end))

				w, s, a, d = UserInputService:IsKeyDown(Enum.KeyCode.W) and -1 or 0, UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0, UserInputService:IsKeyDown(Enum.KeyCode.A) and -1 or 0, UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0
				up, down = 0, 0
				for _, v in {'InputBegan', 'InputEnded'} do
					Fly:Clean(UserInputService[v]:Connect(function(input)
						if not UserInputService:GetFocusedTextBox() then
							local divided = Keys.Value:split('/')
							if input.KeyCode == Enum.KeyCode.W then
								w = v == 'InputBegan' and -1 or 0
							elseif input.KeyCode == Enum.KeyCode.S then
								s = v == 'InputBegan' and 1 or 0
							elseif input.KeyCode == Enum.KeyCode.A then
								a = v == 'InputBegan' and -1 or 0
							elseif input.KeyCode == Enum.KeyCode.D then
								d = v == 'InputBegan' and 1 or 0
							elseif input.KeyCode == Enum.KeyCode[divided[1]] then
								up = v == 'InputBegan' and 1 or 0
							elseif input.KeyCode == Enum.KeyCode[divided[2]] then
								down = v == 'InputBegan' and -1 or 0
							end
						end
					end))
				end
				if UserInputService.TouchEnabled then
					pcall(function()
						local jumpButton = lplr.PlayerGui.TouchGui.TouchControlFrame.JumpButton
						Fly:Clean(jumpButton:GetPropertyChangedSignal('ImageRectOffset'):Connect(function()
							up = jumpButton.ImageRectOffset.X == 146 and 1 or 0
						end))
					end)
				end
			else
				YLevel, OldYLevel = nil, nil
				if entitylib.isAlive and PlatformStanding.Enabled then
					entitylib.character.Humanoid.PlatformStand = false
				end
			end
		end,
		ExtraText = function()
			return Mode.Value
		end
	})
	Mode = Fly:AddDropdown({
		Name = 'Speed Mode',
		List = SpeedMethodList,
		Function = function(val)
			WallCheck.Frame.Visible = FloatMode.Value == 'CFrame' or FloatMode.Value == 'TP' or val == 'CFrame' or val == 'TP'
			Options.TPFrequency.Frame.Visible = val == 'TP'
			Options.PulseLength.Frame.Visible = val == 'Pulse'
			Options.PulseDelay.Frame.Visible = val == 'Pulse'
			if Fly.Enabled then
				Fly:Toggle()
				Fly:Toggle()
			end
		end
	})
	FloatMode = Fly:AddDropdown({
		Name = 'Float Mode',
		List = {'Velocity', 'Impulse', 'CFrame', 'Bounce', 'Floor', 'Jump', 'TP'},
		Function = function(val)
			WallCheck.Frame.Visible = Mode.Value == 'CFrame' or Mode.Value == 'TP' or val == 'CFrame' or val == 'TP'
			BounceLength.Frame.Visible = val == 'Bounce'
			BounceDelay.Frame.Visible = val == 'Bounce'
			VerticalValue.Frame.Visible = val ~= 'Floor'
			FloatTPGround.Frame.Visible = val == 'TP'
			FloatTPAir.Frame.Visible = val == 'TP'
			if Platform then
				Platform:Destroy()
				Platform = nil
			end
			if val == 'Floor' then
				Platform = Instance.new('Part')
				Platform.CanQuery = false
				Platform.Anchored = true
				Platform.Size = Vector3.one
				Platform.Transparency = 1
				Platform.Parent = Fly.Enabled and gameCamera or nil
			end
		end
	})
	local states = {'None'}
	for _, v in Enum.HumanoidStateType:GetEnumItems() do
		if v.Name ~= 'Dead' and v.Name ~= 'None' then
			table.insert(states, v.Name)
		end
	end
	State = Fly:AddDropdown({
		Name = 'Humanoid State',
		List = states
	})
	MoveMethod = Fly:AddDropdown({
		Name = 'Move Mode',
		List = {'MoveDirection', 'Direct'}
	})
	Keys = Fly:AddDropdown({
		Name = 'Keys',
		List = {'Space/LeftControl', 'Space/LeftShift', 'E/Q', 'Space/Q', 'ButtonA/ButtonL2'}
	})
	Options.Value = Fly:AddSlider({
		Name = 'Speed',
		Min = 1,
		Max = 150,
		Default = 50,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	VerticalValue = Fly:AddSlider({
		Name = 'Vertical Speed',
		Min = 1,
		Max = 150,
		Default = 50,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	Options.TPFrequency = Fly:AddSlider({
		Name = 'TP Frequency',
		Min = 0,
		Max = 1,
		Decimal = 100,
		Darker = true,
		Visible = false,
		Suffix = function(val)
			return val == 1 and 'second' or 'seconds'
		end
	})
	Options.PulseLength = Fly:AddSlider({
		Name = 'Pulse Length',
		Min = 0,
		Max = 1,
		Decimal = 100,
		Darker = true,
		Visible = false,
		Suffix = function(val)
			return val == 1 and 'second' or 'seconds'
		end
	})
	Options.PulseDelay = Fly:AddSlider({
		Name = 'Pulse Delay',
		Min = 0,
		Max = 1,
		Decimal = 100,
		Darker = true,
		Visible = false,
		Suffix = function(val)
			return val == 1 and 'second' or 'seconds'
		end
	})
	BounceLength = Fly:AddSlider({
		Name = 'Bounce Length',
		Min = 0,
		Max = 30,
		Darker = true,
		Visible = false,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	BounceDelay = Fly:AddSlider({
		Name = 'Bounce Delay',
		Min = 0,
		Max = 1,
		Decimal = 100,
		Darker = true,
		Visible = false,
		Suffix = function(val)
			return val == 1 and 'second' or 'seconds'
		end
	})
	FloatTPGround = Fly:AddSlider({
		Name = 'Ground',
		Min = 0,
		Max = 1,
		Decimal = 10,
		Default = 0.1,
		Darker = true,
		Visible = false,
		Suffix = function(val)
			return val == 1 and 'second' or 'seconds'
		end
	})
	FloatTPAir = Fly:AddSlider({
		Name = 'Air',
		Min = 0,
		Max = 5,
		Decimal = 10,
		Default = 2,
		Darker = true,
		Visible = false,
		Suffix = function(val)
			return val == 1 and 'second' or 'seconds'
		end
	})
	WallCheck = Fly:AddToggle({
		Name = 'Wall Check',
		Default = true,
		Darker = true,
		Visible = false
	})
	Options.WallCheck = WallCheck
	PlatformStanding = Fly:AddToggle({
		Name = 'PlatformStand',
		Function = function(callback)
			if Fly.Enabled then
				entitylib.character.Humanoid.PlatformStand = callback
			end
		end
	})
	CustomProperties = Fly:AddToggle({
		Name = 'Custom Properties',
		Function = function()
			if Fly.Enabled then
				Fly:Toggle()
				Fly:Toggle()
			end
		end,
		Default = true
	})
end)

run(function()
	local Speed
	local Mode
	local Options
	local AutoJump
	local AutoJumpCustom
	local AutoJumpValue
	local w, s, a, d = 0, 0, 0, 0
	
	Speed = Modern.Catalogs.Movement:AddModule({
		Name = 'Speed',
		Function = function(callback)
			frictionTable.Speed = callback and CustomProperties.Enabled or nil
			updateVelocity()
			if callback then
				Speed:Clean(RunService.PreSimulation:Connect(function(dt)
					if entitylib.isAlive and not Fly.Enabled then
						local state = entitylib.character.Humanoid:GetState()
						if state == Enum.HumanoidStateType.Climbing then return end
	
						local movevec = TargetStrafeVector or Options.MoveMethod.Value == 'Direct' and calculateMoveVector(Vector3.new(a + d, 0, w + s)) or entitylib.character.Humanoid.MoveDirection
						local a = (function(options, moveDirection, dt)
							local root = entitylib.character.RootPart
							local dest = (moveDirection * math.max(options.Value.Value - entitylib.character.Humanoid.WalkSpeed, 0) * dt)
							if options.WallCheck.Enabled then
								options.rayCheck.FilterDescendantsInstances = {lplr.Character, gameCamera}
								options.rayCheck.CollisionGroup = root.CollisionGroup
								local ray = workspace:Raycast(root.Position, dest, options.rayCheck)
								if ray then
									dest = ((ray.Position + ray.Normal) - root.Position)
								end
							end
							root.CFrame += dest
						end)(Options, movevec, dt)
						if AutoJump.Enabled and entitylib.character.Humanoid.FloorMaterial ~= Enum.Material.Air and movevec ~= Vector3.zero then
							if AutoJumpCustom.Enabled then
								local velocity = entitylib.character.RootPart.Velocity * Vector3.new(1, 0, 1)
								entitylib.character.RootPart.Velocity = Vector3.new(velocity.X, AutoJumpValue.Value, velocity.Z)
							else
								entitylib.character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
							end
						end
					end
				end))
	
				w, s, a, d = UserInputService:IsKeyDown(Enum.KeyCode.W) and -1 or 0, UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0, UserInputService:IsKeyDown(Enum.KeyCode.A) and -1 or 0, UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0
				for _, v in {'InputBegan', 'InputEnded'} do
					Speed:Clean(UserInputService[v]:Connect(function(input)
						if not UserInputService:GetFocusedTextBox() then
							if input.KeyCode == Enum.KeyCode.W then
								w = v == 'InputBegan' and -1 or 0
							elseif input.KeyCode == Enum.KeyCode.S then
								s = v == 'InputBegan' and 1 or 0
							elseif input.KeyCode == Enum.KeyCode.A then
								a = v == 'InputBegan' and -1 or 0
							elseif input.KeyCode == Enum.KeyCode.D then
								d = v == 'InputBegan' and 1 or 0
							end
						end
					end))
				end
			else
				if Options.WalkSpeed and entitylib.isAlive then
					entitylib.character.Humanoid.WalkSpeed = Options.WalkSpeed
				end
				Options.WalkSpeed = nil
			end
		end,
		ExtraText = function()
			return Mode.Value
		end
	})
	Mode = Speed:AddDropdown({
		Name = 'Mode',
		List = SpeedMethodList,
		Function = function(val)
			Options.WallCheck.Frame.Visible = val == 'CFrame' or val == 'TP'
			Options.TPFrequency.Frame.Visible = val == 'TP'
			Options.PulseLength.Frame.Visible = val == 'Pulse'
			Options.PulseDelay.Frame.Visible = val == 'Pulse'
			if Speed.Enabled then
				Speed:Toggle()
				Speed:Toggle()
			end
		end
	})
	Options = {
		MoveMethod = Speed:AddDropdown({
			Name = 'Move Mode',
			List = {'MoveDirection', 'Direct'}
		}),
		Value = Speed:AddSlider({
			Name = 'Speed',
			Min = 1,
			Max = 150,
			Default = 50,
			Suffix = function(val)
				return val == 1 and 'stud' or 'studs'
			end
		}),
		TPFrequency = Speed:AddSlider({
			Name = 'TP Frequency',
			Min = 0,
			Max = 1,
			Decimal = 100,
			Darker = true,
			Visible = false,
			Suffix = function(val)
				return val == 1 and 'second' or 'seconds'
			end
		}),
		PulseLength = Speed:AddSlider({
			Name = 'Pulse Length',
			Min = 0,
			Max = 1,
			Decimal = 100,
			Darker = true,
			Visible = false,
			Suffix = function(val)
				return val == 1 and 'second' or 'seconds'
			end
		}),
		PulseDelay = Speed:AddSlider({
			Name = 'Pulse Delay',
			Min = 0,
			Max = 1,
			Decimal = 100,
			Darker = true,
			Visible = false,
			Suffix = function(val)
				return val == 1 and 'second' or 'seconds'
			end
		}),
		WallCheck = Speed:AddToggle({
			Name = 'Wall Check',
			Default = true,
			Darker = true,
			Visible = false
		}),
		TPTiming = tick(),
		rayCheck = RaycastParams.new()
	}
	Options.rayCheck.RespectCanCollide = true
	CustomProperties = Speed:AddToggle({
		Name = 'Custom Properties',
		Function = function()
			if Speed.Enabled then
				Speed:Toggle()
				Speed:Toggle()
			end
		end,
		Default = true
	})
	AutoJump = Speed:AddToggle({
		Name = 'AutoJump',
		Function = function(callback)
			AutoJumpCustom.Frame.Visible = callback
		end
	})
	AutoJumpCustom = Speed:AddToggle({
		Name = 'Custom Jump',
		Function = function(callback)
			AutoJumpValue.Frame.Visible = callback
		end,
		Darker = true,
		Visible = false
	})
	AutoJumpValue = Speed:AddSlider({
		Name = 'Jump Power',
		Min = 1,
		Max = 50,
		Default = 30,
		Darker = true,
		Visible = false
	})
end)
	

run(function()
	local NameTags
	local Targets
	local Color
	local Background
	local DisplayName
	local Health
	local Distance
	local DrawingToggle
	local Scale
	local FontOption
	local GlowEffect
	local Teammates
	local DistanceCheck
	local DistanceLimit
	local Strings, Sizes, Reference, Gradients = {}, {}, {}, {}
	local Folder = Instance.new('Folder')
	Folder.Parent = Modern.MainScreenGui
	local methodused
	
	local Added = {
		Normal = function(ent)
			if ent.NPC then return end
			if Teammates.Enabled and (not ent.Targetable) and (not ent.Friend) then return end
			if Modern.ThreadFix then
				setthreadidentity(8)
			end

			Strings[ent] = ent.Player and (DisplayName.Enabled and ent.Player.DisplayName or ent.Player.Name) or ent.Character.Name

			if Health.Enabled then
				local healthColor = Color3.fromHSV(math.clamp(ent.Health / ent.MaxHealth, 0, 1) / 2.5, 0.89, 0.75)
				Strings[ent] = Strings[ent]..' <font color="rgb('..tostring(math.floor(healthColor.R * 255))..','..tostring(math.floor(healthColor.G * 255))..','..tostring(math.floor(healthColor.B * 255))..')">'..math.round(ent.Health)..'</font>'
			end
	
			if Distance.Enabled then
				Strings[ent] = '<font color="rgb(85, 255, 85)">[</font><font color="rgb(255, 255, 255)">%s</font><font color="rgb(85, 255, 85)">]</font> '..Strings[ent]
			end
	
			local nametag = Instance.new('TextLabel')
			nametag.TextSize = 14 * Scale.Value
			nametag.FontFace = Modern.Libraries.uipallet.Font
			nametag.ZIndex = -1
			local ize = getfontsize(removeTags(Strings[ent]), nametag.TextSize, Modern.Libraries.uipallet.Font, Vector2.new(100000, 100000))
			nametag.Name = ent.Player and ent.Player.Name or ent.Character.Name
			nametag.Size = UDim2.fromOffset(ize.X + 8, ize.Y + 7)
			nametag.AnchorPoint = Vector2.new(0.5, 1)
			nametag.BackgroundColor3 = Color3.new()
			nametag.BackgroundTransparency = Background.Value
			nametag.BorderSizePixel = 0
			if GlowEffect.Enabled then
				addGradient(addRoundedShadow(nametag))
			end
			addCorner(nametag, UDim.new(12, 0))
			nametag.Visible = false
			nametag.Text = Strings[ent]
			if entitylib.getEntityColor(ent) then
				nametag.TextColor3 = entitylib.getEntityColor(ent)
				if Gradients[ent] then
					Gradients[ent].Enabled = false
				end
			else
				nametag.TextColor3 = Color3.fromRGB(255, 255, 255)
				Gradients[ent] = addGradient(nametag)
			end
			nametag.RichText = true
			nametag.Parent = Folder
			Reference[ent] = nametag
		end,
		Drawing = function(ent)
			-- if not Targets.Players.Enabled and ent.Player then return end
			if Teammates.Enabled and (not ent.Targetable) and (not ent.Friend) then return end
			if Modern.ThreadFix then
				setthreadidentity(8)
			end
	
			local nametag = {}
			nametag.BG = Drawing.new('Square')
			nametag.BG.Filled = true
			nametag.BG.Transparency = 1 - Background.Value
			nametag.BG.Color = Color3.new()
			nametag.BG.ZIndex = 1
			nametag.Text = Drawing.new('Text')
			nametag.Text.Size = 15 * Scale.Value
			nametag.Text.Font = 0
			nametag.Text.ZIndex = 2
			Strings[ent] = ent.Player and (DisplayName.Enabled and ent.Player.DisplayName or ent.Player.Name) or ent.Character.Name
	
			if Health.Enabled then
				Strings[ent] = Strings[ent]..' '..math.round(ent.Health)
			end
	
			if Distance.Enabled then
				Strings[ent] = '[%s] '..Strings[ent]
			end
	
			nametag.Text.Text = Strings[ent]
			nametag.Text.Color = entitylib.getEntityColor(ent) or Modern.Libraries.uipallet.FinalColor
			nametag.BG.Size = Vector2.new(nametag.Text.TextBounds.X + 8, nametag.Text.TextBounds.Y + 7)
			Reference[ent] = nametag
		end
	}
	
	local Removed = {
		Normal = function(ent)
			local v = Reference[ent]
			if v then
				if Modern.ThreadFix then
					setthreadidentity(8)
				end
				Reference[ent] = nil
				Strings[ent] = nil
				Sizes[ent] = nil
				v:Destroy()
			end
		end,
		Drawing = function(ent)
			local v = Reference[ent]
			if v then
				if Modern.ThreadFix then
					setthreadidentity(8)
				end
				Reference[ent] = nil
				Strings[ent] = nil
				Sizes[ent] = nil
				for _, v2 in v do
					pcall(function()
						v2.Visible = false
						v2:Remove()
					end)
				end
			end
		end
	}
	
	local Updated = {
		Normal = function(ent)
			local nametag = Reference[ent]
			if nametag then
				if Modern.ThreadFix then
					setthreadidentity(8)
				end
				Sizes[ent] = nil
				Strings[ent] = ent.Player and (DisplayName.Enabled and ent.Player.DisplayName or ent.Player.Name) or ent.Character.Name
	
				if Health.Enabled then
					local color = Color3.fromHSV(math.clamp(ent.Health / ent.MaxHealth, 0, 1) / 2.5, 0.89, 0.75)
					Strings[ent] = Strings[ent]..' <font color="rgb('..tostring(math.floor(color.R * 255))..','..tostring(math.floor(color.G * 255))..','..tostring(math.floor(color.B * 255))..')">'..math.round(ent.Health)..'</font>'
				end
	
				if Distance.Enabled then
					Strings[ent] = '<font color="rgb(85, 255, 85)">[</font><font color="rgb(255, 255, 255)">%s</font><font color="rgb(85, 255, 85)">]</font> '..Strings[ent]
				end
	
				local ize = getfontsize(removeTags(Strings[ent]), nametag.TextSize, nametag.FontFace, Vector2.new(100000, 100000))
				nametag.Size = UDim2.fromOffset(ize.X + 8, ize.Y + 7)
				nametag.Text = Strings[ent]
			end
		end,
		Drawing = function(ent)
			local nametag = Reference[ent]
			if nametag then
				if Modern.ThreadFix then
					setthreadidentity(8)
				end
				Sizes[ent] = nil
				Strings[ent] = ent.Player and (DisplayName.Enabled and ent.Player.DisplayName or ent.Player.Name) or ent.Character.Name
	
				if Health.Enabled then
					Strings[ent] = Strings[ent]..' '..math.round(ent.Health)
				end
	
				if Distance.Enabled then
					Strings[ent] = '[%s] '..Strings[ent]
					nametag.Text.Text = entitylib.isAlive and string.format(Strings[ent], math.floor((entitylib.character.RootPart.Position - ent.RootPart.Position).Magnitude)) or Strings[ent]
				else
					nametag.Text.Text = Strings[ent]
				end
	
				nametag.BG.Size = Vector2.new(nametag.Text.TextBounds.X + 8, nametag.Text.TextBounds.Y + 7)
				nametag.Text.Color = entitylib.getEntityColor(ent) or Modern.Libraries.uipallet.FinalColor
			end
		end
	}
	
	local ColorFunc = {
		Normal = function(hue, sat, val)
			local color = Color3.fromHSV(hue, sat, val)
			for i, v in Reference do
				v.TextColor3 = entitylib.getEntityColor(i) or color
			end
		end,
		Drawing = function(hue, sat, val)
			local color = Color3.fromHSV(hue, sat, val)
			for i, v in Reference do
				v.Text.Color = entitylib.getEntityColor(i) or color
			end
		end
	}
	
	local Loop = {
		Normal = function()
			for ent, nametag in Reference do
				if DistanceCheck.Enabled then
					local distance = entitylib.isAlive and (entitylib.character.RootPart.Position - ent.RootPart.Position).Magnitude or math.huge
					if distance > DistanceLimit.Value then
						nametag.Visible = false
						continue
					end
				end
	
				local headPos, headVis = gameCamera:WorldToViewportPoint(ent.RootPart.Position + Vector3.new(0, ent.HipHeight + 1, 0))
				nametag.Visible = headVis
				if not headVis then
					continue
				end
	
				if Distance.Enabled then
					local mag = entitylib.isAlive and math.floor((entitylib.character.RootPart.Position - ent.RootPart.Position).Magnitude) or 0
					if Sizes[ent] ~= mag then
						nametag.Text = string.format(Strings[ent], mag)
						local ize = getfontsize(removeTags(nametag.Text), nametag.TextSize, nametag.FontFace, Vector2.new(100000, 100000))
						nametag.Size = UDim2.fromOffset(ize.X + 8, ize.Y + 7)
						Sizes[ent] = mag
					end
				end
				nametag.Position = UDim2.fromOffset(headPos.X, headPos.Y)
			end
		end,
		Drawing = function()
			for ent, nametag in Reference do
				if DistanceCheck.Enabled then
					local distance = entitylib.isAlive and (entitylib.character.RootPart.Position - ent.RootPart.Position).Magnitude or math.huge
					if distance < DistanceLimit.ValueMin or distance > DistanceLimit.ValueMax then
						nametag.Text.Visible = false
						nametag.BG.Visible = false
						continue
					end
				end
	
				local headPos, headVis = gameCamera:WorldToScreenPoint(ent.RootPart.Position + Vector3.new(0, ent.HipHeight + 1, 0))
				nametag.Text.Visible = headVis
				nametag.BG.Visible = headVis
				if not headVis then
					continue
				end
	
				if Distance.Enabled then
					local mag = entitylib.isAlive and math.floor((entitylib.character.RootPart.Position - ent.RootPart.Position).Magnitude) or 0
					if Sizes[ent] ~= mag then
						nametag.Text.Text = string.format(Strings[ent], mag)
						nametag.BG.Size = Vector2.new(nametag.Text.TextBounds.X + 8, nametag.Text.TextBounds.Y + 7)
						Sizes[ent] = mag
					end
				end
				nametag.BG.Position = Vector2.new(headPos.X - (nametag.BG.Size.X / 2), headPos.Y + (nametag.BG.Size.Y / 2))
				nametag.Text.Position = nametag.BG.Position + Vector2.new(4, 2.5)
			end
		end
	}
	
	NameTags = Modern.Catalogs.Render:AddModule({
		Name = 'NameTags',
		Function = function(callback)
			if callback then
				methodused = DrawingToggle.Enabled and 'Drawing' or 'Normal'
				if Removed[methodused] then
					NameTags:Clean(entitylib.Events.EntityRemoved:Connect(Removed[methodused]))
				end
				if Added[methodused] then
					for _, v in entitylib.List do
						if Reference[v] then
							Removed[methodused](v)
						end
						Added[methodused](v)
					end
					NameTags:Clean(entitylib.Events.EntityAdded:Connect(function(ent)
						if Reference[ent] then
							Removed[methodused](ent)
						end
						Added[methodused](ent)
					end))
				end
				if Updated[methodused] then
					NameTags:Clean(entitylib.Events.EntityUpdated:Connect(Updated[methodused]))
					for _, v in entitylib.List do
						Updated[methodused](v)
					end
				end
				if Loop[methodused] then
					NameTags:Clean(RunService.RenderStepped:Connect(Loop[methodused]))
				end
			else
				if Removed[methodused] then
					for i in Reference do
						Removed[methodused](i)
					end
				end
			end
		end
	})
	Scale = NameTags:AddSlider({
		Name = 'Scale',
		Function = function()
			if NameTags.Enabled then
				NameTags:Toggle()
				NameTags:Toggle()
			end
		end,
		Default = 1,
		Min = 0.1,
		Max = 1.5,
		Decimal = 10
	})
	Background = NameTags:AddSlider({
		Name = 'Transparency',
		Function = function()
			if NameTags.Enabled then
				NameTags:Toggle()
				NameTags:Toggle()
			end
		end,
		Default = 0.5,
		Min = 0,
		Max = 1,
		Decimal = 10
	})
	GlowEffect = NameTags:AddToggle({
		Name = 'Glow Effect',
		Function = function()
			if NameTags.Enabled then
				NameTags:Toggle()
				NameTags:Toggle()
			end
		end,
		Default = true
	})
	Health = NameTags:AddToggle({
		Name = 'Health',
		Function = function()
			if NameTags.Enabled then
				NameTags:Toggle()
				NameTags:Toggle()
			end
		end
	})
	Distance = NameTags:AddToggle({
		Name = 'Distance',
		Function = function()
			if NameTags.Enabled then
				NameTags:Toggle()
				NameTags:Toggle()
			end
		end
	})
	DisplayName = NameTags:AddToggle({
		Name = 'Use Displayname',
		Function = function()
			if NameTags.Enabled then
				NameTags:Toggle()
				NameTags:Toggle()
			end
		end,
		Default = true
	})
	Teammates = NameTags:AddToggle({
		Name = 'Priority Only',
		Function = function()
			if NameTags.Enabled then
				NameTags:Toggle()
				NameTags:Toggle()
			end
		end,
		Default = true
	})
	DrawingToggle = NameTags:AddToggle({
		Name = 'Drawing',
		Function = function(callback)
			GlowEffect.Frame.Visible = not callback
			if NameTags.Enabled then
				NameTags:Toggle()
				NameTags:Toggle()
			end
		end
	})
	DistanceCheck = NameTags:AddToggle({
		Name = 'Distance Check',
		Function = function(callback)
			DistanceLimit.Frame.Visible = callback
		end
	})
	DistanceLimit = NameTags:AddSlider({
		Name = 'Player Distance',
		Min = 0,
		Max = 256,
		Default = 64,
		Darker = true,
		Visible = false
	})
end)


run(function()
	local Timer
	local Value
	
	Timer = Modern.Catalogs.Player:AddModule({
		Name = 'Timer',
		Function = function(callback)
			if callback then
				setfflag('SimEnableStepPhysics', 'True')
				setfflag('SimEnableStepPhysicsSelective', 'True')
				Timer:Clean(RunService.RenderStepped:Connect(function(dt)
					if Value.Value > 1 then
						RunService:Pause()
						workspace:StepPhysics(dt * (Value.Value - 1), {entitylib.character.RootPart})
						RunService:Run()
					end
				end))
			end
		end
	})
	Value = Timer:AddSlider({
		Name = 'Value',
		Min = 1,
		Max = 3,
		Decimal = 10
	})
end)
local visited, attempted, tpSwitch = {}, {}, false
local cacheExpire, cache = tick()
local function serverHop(pointer, filter)
	visited = shared.Modernserverhoplist and shared.Modernserverhoplist:split('/') or {}
	if not table.find(visited, game.JobId) then
		table.insert(visited, game.JobId)
	end
	if not pointer then
		warn('Searching for an available server.')
	end

	local suc, httpdata = pcall(function()
		return cacheExpire < tick() and game:HttpGet('https://games.roblox.com/v1/games/'..game.PlaceId..'/servers/Public?sortOrder='..(filter == 'Ascending' and 1 or 2)..'&excludeFullGames=true&limit=100'..(pointer and '&cursor='..pointer or '')) or cache
	end)
	local data = suc and httpService:JSONDecode(httpdata) or nil
	if data and data.data then
		for _, v in data.data do
			if tonumber(v.playing) < Players.MaxPlayers and not table.find(visited, v.id) and not table.find(attempted, v.id) then
				cacheExpire, cache = tick() + 60, httpdata
				table.insert(attempted, v.id)

				TeleportService:TeleportToPlaceInstance(game.PlaceId, v.id)
				return
			end
		end

		if data.nextPageCursor then
			serverHop(data.nextPageCursor, filter)
		else
			
		end
	else

	end
end

run(function()
	local StaffDetector
	local Mode
	local Profile
	local Users
	local Group
	local Role
	
	local function getRole(plr, id)
		local suc, res
		for _ = 1, 3 do
			suc, res = pcall(function()
				return plr:GetRankInGroup(id)
			end)
			if suc then break end
		end
		return suc and res or 0
	end
	
	local function getLowestStaffRole(roles)
		local highest = math.huge
		for _, v in roles do
			local low = v.Name:lower()
			if (low:find('admin') or low:find('mod') or low:find('dev')) and v.Rank < highest then
				highest = v.Rank
			end
		end
		return highest
	end
	
	local function playerAdded(plr)
		if not Modern.Loaded then
			repeat task.wait() until Modern.Loaded
		end

		if getRole(plr, 0) >= 1 then
			if Mode.Value == 'Uninject' then
				task.spawn(function()
					Modern:Uninject()
				end)
				game:GetService('StarterGui'):SetCore('SendNotification', {
					Title = 'StaffDetector',
					Text = 'Staff Detected\n'..plr.Name,
					Duration = 60,
				})
			elseif Mode.Value == 'ServerHop' then
				serverHop()
			end
		end
	end
	
	StaffDetector = Modern.Catalogs.Player:AddModule({
		Name = 'StaffDetector',
		Function = function(callback)
			if callback then

				local placeinfo = MarketplaceService:GetProductInfo(game.PlaceId)
				if placeinfo.Creator.CreatorType ~= 'Group' then
					local desc = placeinfo.Description:split('\n')
					for _, str in desc do
						local _, begin = str:find('roblox.com/groups/')
						if begin then
							local endof = str:find('/', begin + 1)
							placeinfo = {Creator = {
								CreatorType = 'Group',
								CreatorTargetId = str:sub(begin + 1, endof - 1)
							}}
						end
					end

					if placeinfo.Creator.CreatorType ~= 'Group' then
						return
					end
	
					local groupinfo = GroupService:GetGroupInfoAsync(placeinfo.Creator.CreatorTargetId)
					Group:SetValue(placeinfo.Creator.CreatorTargetId)
					Role:SetValue(getLowestStaffRole(groupinfo.Roles))
				end
	
				StaffDetector:Clean(Players.PlayerAdded:Connect(playerAdded))
				for _, v in Players:GetPlayers() do
					task.spawn(playerAdded, v)
				end
			end
		end
	})
	Mode = StaffDetector:AddDropdown({
		Name = 'Mode',
		List = {'Uninject', 'ServerHop','Notify'}
	})
end)

run(function()
	local Freecam
	local Value
	local randomkey, module, old = HttpService:GenerateGUID(false)
	
	Freecam = Modern.Catalogs.Render:AddModule({
		Name = 'Freecam',
		Function = function(callback)
			if callback then
				repeat
					task.wait(0.1)
					for _, v in getconnections(gameCamera:GetPropertyChangedSignal('CameraType')) do
						if v.Function then
							module = debug.getupvalue(v.Function, 1)
						end
					end
				until module or not Freecam.Enabled
	
				if module and module.activeCameraController and Freecam.Enabled then
					old = module.activeCameraController.GetSubjectPosition
					local camPos = old(module.activeCameraController) or Vector3.zero
					module.activeCameraController.GetSubjectPosition = function()
						return camPos
					end
	
					Freecam:Clean(RunService.PreSimulation:Connect(function(dt)
						if not UserInputService:GetFocusedTextBox() then
							local forward = (UserInputService:IsKeyDown(Enum.KeyCode.W) and -1 or 0) + (UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0)
							local side = (UserInputService:IsKeyDown(Enum.KeyCode.A) and -1 or 0) + (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0)
							local up = (UserInputService:IsKeyDown(Enum.KeyCode.Q) and -1 or 0) + (UserInputService:IsKeyDown(Enum.KeyCode.E) and 1 or 0)
							dt = dt * (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and 0.25 or 1)
							camPos = (CFrame.lookAlong(camPos, gameCamera.CFrame.LookVector) * CFrame.new(Vector3.new(side, up, forward) * (Value.Value * dt))).Position
						end
					end))
	
					ContextService:BindActionAtPriority('FreecamKeyboard'..randomkey, function() 
						return Enum.ContextActionResult.Sink 
					end, false, Enum.ContextActionPriority.High.Value,
						Enum.KeyCode.W,
						Enum.KeyCode.A,
						Enum.KeyCode.S,
						Enum.KeyCode.D,
						Enum.KeyCode.E,
						Enum.KeyCode.Q,
						Enum.KeyCode.Up,
						Enum.KeyCode.Down
					)
				end
			else
				pcall(function()
					ContextService:UnbindAction('FreecamKeyboard'..randomkey)
				end)
				if module and old then
					module.activeCameraController.GetSubjectPosition = old
					module = nil
					old = nil
				end
			end
		end
	})
	Value = Freecam:AddSlider({
		Name = 'Speed',
		Min = 1,
		Max = 150,
		Default = 50,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
end)

run(function()
	local Chams
	local Targets
	local Mode
	local FillColor
	local OutlineColor
	local FillTransparency
	local OutlineTransparency
	local Teammates
	local Walls
	local Reference = {}
	local Folder = Instance.new('Folder')
	Folder.Parent = Modern.MainScreenGui
	
	local function Added(ent)
		if not ent.Player then return end
		if Teammates.Enabled and (not ent.Targetable) and (not ent.Friend) then return end
		if Modern.ThreadFix then
			setthreadidentity(8)
		end
		if Mode.Value == 'Highlight' then
			local cham = Instance.new('Highlight')
			cham.Adornee = ent.Character
			cham.DepthMode = Enum.HighlightDepthMode[Walls.Enabled and 'AlwaysOnTop' or 'Occluded']
			cham.FillColor = entitylib.getEntityColor(ent) or Modern.Libraries.uipallet.FinalColor
			cham.OutlineColor = entitylib.getEntityColor(ent) or Modern.Libraries.uipallet.FinalColor
			cham.FillTransparency = FillTransparency.Value
			cham.OutlineTransparency = OutlineTransparency.Value
			cham.Parent = Folder
			Reference[ent] = cham
		else
			local chams = {}
			for _, v in ent.Character:GetChildren() do
				if v:IsA('BasePart') and (ent.NPC or v.Name:find('Arm') or v.Name:find('Leg') or v.Name:find('Hand') or v.Name:find('Feet') or v.Name:find('Torso') or v.Name == 'Head') then
					local box = Instance.new(v.Name == 'Head' and 'SphereHandleAdornment' or 'BoxHandleAdornment')
					if v.Name == 'Head' then
						box.Radius = 0.75
					else
						box.Size = v.Size
					end
					box.AlwaysOnTop = Walls.Enabled
					box.Adornee = v
					box.ZIndex = 0
					box.Transparency = FillTransparency.Value
					box.Color3 = entitylib.getEntityColor(ent) or Modern.Libraries.uipallet.FinalColor
					box.Parent = Folder
					table.insert(chams, box)
				end
			end
			Reference[ent] = chams
		end
	end
	
	local function Removed(ent)
		if Reference[ent] then
			if Modern.ThreadFix then
				setthreadidentity(8)
			end
			if type(Reference[ent]) == 'table' then
				for _, v in Reference[ent] do
					v:Destroy()
				end
				table.clear(Reference[ent])
			else
				Reference[ent]:Destroy()
			end
			Reference[ent] = nil
		end
	end
	local function Looped()
		for ent, ref in next, Reference do
			if Modern.ThreadFix then
				setthreadidentity(8)
			end
			if type(ref) == 'table' then
				for _, v in ref do
					if v:IsA('SphereHandleAdornment') or v:IsA('BoxHandleAdornment') then
						v.Color3 = entitylib.getEntityColor(ent) or Modern.Libraries.uipallet.FinalColor
					end
				end
			else
				ref.FillColor = entitylib.getEntityColor(ent) or Modern.Libraries.uipallet.FinalColor
				ref.OutlineColor = entitylib.getEntityColor(ent) or Modern.Libraries.uipallet.FinalColor
			end
		end
	end
	
	Chams = Modern.Catalogs.Render:AddModule({
		Name = 'Chams',
		Function = function(callback)
			if callback then
				Chams:Clean(entitylib.Events.EntityRemoved:Connect(Removed))
				Chams:Clean(RunService.RenderStepped:Connect(Looped))
				Chams:Clean(entitylib.Events.EntityAdded:Connect(function(ent)
					if Reference[ent] then
						Removed(ent)
					end
					Added(ent)
				end))
				for _, v in entitylib.List do
					if Reference[v] then
						Removed(v)
					end
					Added(v)
				end
			else
				for i in Reference do
					Removed(i)
				end
			end
		end
	})

	Mode = Chams:AddDropdown({
		Name = 'Mode',
		List = {'Highlight', 'BoxHandles'},
		Function = function(val)
			OutlineTransparency.Frame.Visible = val == 'Highlight'
			if Chams.Enabled then
				Chams:Toggle()
				Chams:Toggle()
			end
		end
	})
	FillTransparency = Chams:AddSlider({
		Name = 'Transparency',
		Min = 0,
		Max = 1,
		Default = 0.5,
		Function = function(val)
			for _, v in Reference do
				if type(v) == 'table' then
					for _, v2 in v do v2.Transparency = val end
				else
					v.FillTransparency = val
				end
			end
		end,
		Decimal = 10
	})
	OutlineTransparency = Chams:AddSlider({
		Name = 'Outline Transparency',
		Min = 0,
		Max = 1,
		Default = 0.5,
		Function = function(val)
			for _, v in Reference do
				if type(v) ~= 'table' then
					v.OutlineTransparency = val
				end
			end
		end,
		Decimal = 10,
		Darker = true
	})
	Walls = Chams:AddToggle({
		Name = 'Render Walls',
		Function = function(callback)
			for _, v in Reference do
				if type(v) == 'table' then
					for _, v2 in v do
						v2.AlwaysOnTop = callback
					end
				else
					v.DepthMode = Enum.HighlightDepthMode[callback and 'AlwaysOnTop' or 'Occluded']
				end
			end
		end,
		Default = true
	})
	Teammates = Chams:AddToggle({
		Name = 'Priority Only',
		Function = function()
			if Chams.Enabled then
				Chams:Toggle()
				Chams:Toggle()
			end
		end,
		Default = true
	})
end)
	
run(function()
	local ESP
	local Targets
	local Color
	local Method
	local BoundingBox
	local Filled
	local HealthBar
	local Name
	local DisplayName
	local Background
	local Teammates
	local Distance
	local DistanceLimit
	local Reference = {}
	local methodused
	
	local function ESPWorldToViewport(pos)
		local newpos = gameCamera:WorldToViewportPoint(gameCamera.CFrame:pointToWorldSpace(gameCamera.CFrame:PointToObjectSpace(pos)))
		return Vector2.new(newpos.X, newpos.Y)
	end
	
	local ESPAdded = {
		Drawing2D = function(ent)
			if not ent.Player then return end
			if Teammates.Enabled and (not ent.Targetable) and (not ent.Friend) then return end
			if Modern.ThreadFix then
				setthreadidentity(8)
			end
			local EntityESP = {}
			EntityESP.Main = Drawing.new('Square')
			EntityESP.Main.Transparency = BoundingBox.Enabled and 1 or 0
			EntityESP.Main.ZIndex = 2
			EntityESP.Main.Filled = false
			EntityESP.Main.Thickness = 1
			EntityESP.Main.Color = entitylib.getEntityColor(ent) or Modern.Libraries.uipallet.FinalColor
	
			if BoundingBox.Enabled then
				EntityESP.Border = Drawing.new('Square')
				EntityESP.Border.Transparency = 0.35
				EntityESP.Border.ZIndex = 1
				EntityESP.Border.Thickness = 1
				EntityESP.Border.Filled = false
				EntityESP.Border.Color = Color3.new()
				EntityESP.Border2 = Drawing.new('Square')
				EntityESP.Border2.Transparency = 0.35
				EntityESP.Border2.ZIndex = 1
				EntityESP.Border2.Thickness = 1
				EntityESP.Border2.Filled = Filled.Enabled
				EntityESP.Border2.Color = Color3.new()
			end
	
			if HealthBar.Enabled then
				EntityESP.HealthLine = Drawing.new('Line')
				EntityESP.HealthLine.Thickness = 1
				EntityESP.HealthLine.ZIndex = 2
				EntityESP.HealthLine.Color = Color3.fromHSV(math.clamp(ent.Health / ent.MaxHealth, 0, 1) / 2.5, 0.89, 0.75)
				EntityESP.HealthBorder = Drawing.new('Line')
				EntityESP.HealthBorder.Thickness = 3
				EntityESP.HealthBorder.Transparency = 0.35
				EntityESP.HealthBorder.ZIndex = 1
				EntityESP.HealthBorder.Color = Color3.new()
			end
			
			if Name.Enabled then
				if Background.Enabled then
					EntityESP.TextBKG = Drawing.new('Square')
					EntityESP.TextBKG.Transparency = 0.35
					EntityESP.TextBKG.ZIndex = 0
					EntityESP.TextBKG.Thickness = 1
					EntityESP.TextBKG.Filled = true
					EntityESP.TextBKG.Color = Color3.new()
				end
				EntityESP.Drop = Drawing.new('Text')
				EntityESP.Drop.Color = Color3.new()
				EntityESP.Drop.Text = ent.Player and (DisplayName.Enabled and ent.Player.DisplayName or ent.Player.Name) or ent.Character.Name
				EntityESP.Drop.ZIndex = 1
				EntityESP.Drop.Center = true
				EntityESP.Drop.Size = 20
				EntityESP.Text = Drawing.new('Text')
				EntityESP.Text.Text = EntityESP.Drop.Text
				EntityESP.Text.ZIndex = 2
				EntityESP.Text.Color = EntityESP.Main.Color
				EntityESP.Text.Center = true
				EntityESP.Text.Size = 20
			end
			Reference[ent] = EntityESP
		end,
		Drawing3D = function(ent)
			if not ent.Player then return end
			if Teammates.Enabled and (not ent.Targetable) and (not ent.Friend) then return end
			if Modern.ThreadFix then
				setthreadidentity(8)
			end
			local EntityESP = {}
			EntityESP.Line1 = Drawing.new('Line')
			EntityESP.Line2 = Drawing.new('Line')
			EntityESP.Line3 = Drawing.new('Line')
			EntityESP.Line4 = Drawing.new('Line')
			EntityESP.Line5 = Drawing.new('Line')
			EntityESP.Line6 = Drawing.new('Line')
			EntityESP.Line7 = Drawing.new('Line')
			EntityESP.Line8 = Drawing.new('Line')
			EntityESP.Line9 = Drawing.new('Line')
			EntityESP.Line10 = Drawing.new('Line')
			EntityESP.Line11 = Drawing.new('Line')
			EntityESP.Line12 = Drawing.new('Line')
	
			local color = entitylib.getEntityColor(ent) or Modern.Libraries.uipallet.FinalColor
			for _, v in EntityESP do
				v.Thickness = 1
				v.Color = color
			end
	
			Reference[ent] = EntityESP
		end,
		DrawingSkeleton = function(ent)
			if not ent.Player then return end
			if Teammates.Enabled and (not ent.Targetable) and (not ent.Friend) then return end
			if Modern.ThreadFix then
				setthreadidentity(8)
			end
			local EntityESP = {}
			EntityESP.Head = Drawing.new('Line')
			EntityESP.HeadFacing = Drawing.new('Line')
			EntityESP.Torso = Drawing.new('Line')
			EntityESP.UpperTorso = Drawing.new('Line')
			EntityESP.LowerTorso = Drawing.new('Line')
			EntityESP.LeftArm = Drawing.new('Line')
			EntityESP.RightArm = Drawing.new('Line')
			EntityESP.LeftLeg = Drawing.new('Line')
			EntityESP.RightLeg = Drawing.new('Line')
	
			local color = entitylib.getEntityColor(ent) or Modern.Libraries.uipallet.FinalColor
			for _, v in EntityESP do
				v.Thickness = 2
				v.Color = color
			end
	
			Reference[ent] = EntityESP
		end
	}
	
	local ESPRemoved = {
		Drawing2D = function(ent)
			local EntityESP = Reference[ent]
			if EntityESP then
				if Modern.ThreadFix then
					setthreadidentity(8)
				end
				Reference[ent] = nil
				for _, v in EntityESP do
					pcall(function()
						v.Visible = false
						v:Remove()
					end)
				end
			end
		end
	}
	ESPRemoved.Drawing3D = ESPRemoved.Drawing2D
	ESPRemoved.DrawingSkeleton = ESPRemoved.Drawing2D
	
	local ESPUpdated = {
		Drawing2D = function(ent)
			local EntityESP = Reference[ent]
			if EntityESP then
				if Modern.ThreadFix then
					setthreadidentity(8)
				end
				
				if EntityESP.HealthLine then
					EntityESP.HealthLine.Color = Color3.fromHSV(math.clamp(ent.Health / ent.MaxHealth, 0, 1) / 2.5, 0.89, 0.75)
				end
	
				if EntityESP.Text then
					EntityESP.Text.Text = ent.Player and (DisplayName.Enabled and ent.Player.DisplayName or ent.Player.Name) or ent.Character.Name
					EntityESP.Drop.Text = EntityESP.Text.Text
				end
			end
		end
	}
	
	local ColorFunc = {
		Drawing2D = function(hue, sat, val)
			local color = Color3.fromHSV(hue, sat, val)
			for i, v in Reference do
				v.Main.Color = entitylib.getEntityColor(i) or color
				if v.Text then
					v.Text.Color = v.Main.Color
				end
			end
		end,
		Drawing3D = function(hue, sat, val)
			local color = Color3.fromHSV(hue, sat, val)
			for i, v in Reference do
				local playercolor = entitylib.getEntityColor(i) or color
				for _, v2 in v do
					v2.Color = playercolor
				end
			end
		end
	}
	ColorFunc.DrawingSkeleton = ColorFunc.Drawing3D
	
	local ESPLoop = {
		Drawing2D = function()
			for ent, EntityESP in Reference do
				if Distance.Enabled then
					local distance = entitylib.isAlive and (entitylib.character.RootPart.Position - ent.RootPart.Position).Magnitude or math.huge
					if distance < DistanceLimit.ValueMin or distance > DistanceLimit.ValueMax then
						for _, obj in EntityESP do
							obj.Visible = false
						end
						continue
					end
				end
	
				local rootPos, rootVis = gameCamera:WorldToViewportPoint(ent.RootPart.Position)
				local color = entitylib.getEntityColor(ent) or Modern.Libraries.uipallet.FinalColor
				for _, obj in EntityESP do
					obj.Visible = rootVis
					obj.Color = color
				end
				if not rootVis then continue end
	
				local topPos = gameCamera:WorldToViewportPoint((CFrame.lookAlong(ent.RootPart.Position, gameCamera.CFrame.LookVector) * CFrame.new(2, ent.HipHeight, 0)).p)
				local bottomPos = gameCamera:WorldToViewportPoint((CFrame.lookAlong(ent.RootPart.Position, gameCamera.CFrame.LookVector) * CFrame.new(-2, -ent.HipHeight - 1, 0)).p)
				local sizex, sizey = topPos.X - bottomPos.X, topPos.Y - bottomPos.Y
				local posx, posy = (rootPos.X - sizex / 2),  ((rootPos.Y - sizey / 2))
				EntityESP.Main.Position = Vector2.new(posx, posy) // 1
				EntityESP.Main.Size = Vector2.new(sizex, sizey) // 1
				if EntityESP.Border then
					EntityESP.Border.Position = Vector2.new(posx - 1, posy + 1) // 1
					EntityESP.Border.Size = Vector2.new(sizex + 2, sizey - 2) // 1
					EntityESP.Border2.Position = Vector2.new(posx + 1, posy - 1) // 1
					EntityESP.Border2.Size = Vector2.new(sizex - 2, sizey + 2) // 1
				end
	
				if EntityESP.HealthLine then
					local healthposy = sizey * math.clamp(ent.Health / ent.MaxHealth, 0, 1)
					EntityESP.HealthLine.Visible = ent.Health > 0
					EntityESP.HealthLine.From = Vector2.new(posx - 6, posy + (sizey - (sizey - healthposy))) // 1
					EntityESP.HealthLine.To = Vector2.new(posx - 6, posy) // 1
					EntityESP.HealthBorder.From = Vector2.new(posx - 6, posy + 1) // 1
					EntityESP.HealthBorder.To = Vector2.new(posx - 6, (posy + sizey) - 1) // 1
				end
	
				if EntityESP.Text then
					EntityESP.Text.Position = Vector2.new(posx + (sizex / 2), posy + (sizey - 28)) // 1
					EntityESP.Drop.Position = EntityESP.Text.Position + Vector2.new(1, 1)
					if EntityESP.TextBKG then
						EntityESP.TextBKG.Size = EntityESP.Text.TextBounds + Vector2.new(8, 4)
						EntityESP.TextBKG.Position = EntityESP.Text.Position - Vector2.new(4 + (EntityESP.Text.TextBounds.X / 2), 0)
					end
				end
			end
		end,
		Drawing3D = function()
			for ent, EntityESP in Reference do
				if Distance.Enabled then
					local distance = entitylib.isAlive and (entitylib.character.RootPart.Position - ent.RootPart.Position).Magnitude or math.huge
					if distance < DistanceLimit.ValueMin or distance > DistanceLimit.ValueMax then
						for _, obj in EntityESP do
							obj.Visible = false
						end
						continue
					end
				end
	
				local _, rootVis = gameCamera:WorldToViewportPoint(ent.RootPart.Position)
				local color = entitylib.getEntityColor(ent) or Modern.Libraries.uipallet.FinalColor
				for _, obj in EntityESP do
					obj.Visible = rootVis
					obj.Thickness = 2
					obj.Color = color
				end
				if not rootVis then continue end
	
				local point1 = ESPWorldToViewport(ent.RootPart.Position + Vector3.new(1.5, ent.HipHeight, 1.5))
				local point2 = ESPWorldToViewport(ent.RootPart.Position + Vector3.new(1.5, -ent.HipHeight, 1.5))
				local point3 = ESPWorldToViewport(ent.RootPart.Position + Vector3.new(-1.5, ent.HipHeight, 1.5))
				local point4 = ESPWorldToViewport(ent.RootPart.Position + Vector3.new(-1.5, -ent.HipHeight, 1.5))
				local point5 = ESPWorldToViewport(ent.RootPart.Position + Vector3.new(1.5, ent.HipHeight, -1.5))
				local point6 = ESPWorldToViewport(ent.RootPart.Position + Vector3.new(1.5, -ent.HipHeight, -1.5))
				local point7 = ESPWorldToViewport(ent.RootPart.Position + Vector3.new(-1.5, ent.HipHeight, -1.5))
				local point8 = ESPWorldToViewport(ent.RootPart.Position + Vector3.new(-1.5, -ent.HipHeight, -1.5))
				EntityESP.Line1.From = point1
				EntityESP.Line1.To = point2
				EntityESP.Line2.From = point3
				EntityESP.Line2.To = point4
				EntityESP.Line3.From = point5
				EntityESP.Line3.To = point6
				EntityESP.Line4.From = point7
				EntityESP.Line4.To = point8
				EntityESP.Line5.From = point1
				EntityESP.Line5.To = point3
				EntityESP.Line6.From = point1
				EntityESP.Line6.To = point5
				EntityESP.Line7.From = point5
				EntityESP.Line7.To = point7
				EntityESP.Line8.From = point7
				EntityESP.Line8.To = point3
				EntityESP.Line9.From = point2
				EntityESP.Line9.To = point4
				EntityESP.Line10.From = point2
				EntityESP.Line10.To = point6
				EntityESP.Line11.From = point6
				EntityESP.Line11.To = point8
				EntityESP.Line12.From = point8
				EntityESP.Line12.To = point4
			end
		end,
		DrawingSkeleton = function()
			for ent, EntityESP in Reference do
				if Distance.Enabled then
					local distance = entitylib.isAlive and (entitylib.character.RootPart.Position - ent.RootPart.Position).Magnitude or math.huge
					if distance < DistanceLimit.ValueMin or distance > DistanceLimit.ValueMax then
						for _, obj in EntityESP do
							obj.Visible = false
						end
						continue
					end
				end
	
				local _, rootVis = gameCamera:WorldToViewportPoint(ent.RootPart.Position)
				for _, obj in EntityESP do
					obj.Visible = rootVis
				end
				if not rootVis then continue end
				
				local rigcheck = ent.Humanoid.RigType == Enum.HumanoidRigType.R6
				pcall(function()
					local offset = rigcheck and CFrame.new(0, -0.8, 0) or CFrame.identity
					local head = ESPWorldToViewport((ent.Head.CFrame).p)
					local headfront = ESPWorldToViewport((ent.Head.CFrame * CFrame.new(0, 0, -0.5)).p)
					local toplefttorso = ESPWorldToViewport((ent.Character[(rigcheck and 'Torso' or 'UpperTorso')].CFrame * CFrame.new(-1.5, 0.8, 0)).p)
					local toprighttorso = ESPWorldToViewport((ent.Character[(rigcheck and 'Torso' or 'UpperTorso')].CFrame * CFrame.new(1.5, 0.8, 0)).p)
					local toptorso = ESPWorldToViewport((ent.Character[(rigcheck and 'Torso' or 'UpperTorso')].CFrame * CFrame.new(0, 0.8, 0)).p)
					local bottomtorso = ESPWorldToViewport((ent.Character[(rigcheck and 'Torso' or 'UpperTorso')].CFrame * CFrame.new(0, -0.8, 0)).p)
					local bottomlefttorso = ESPWorldToViewport((ent.Character[(rigcheck and 'Torso' or 'UpperTorso')].CFrame * CFrame.new(-0.5, -0.8, 0)).p)
					local bottomrighttorso = ESPWorldToViewport((ent.Character[(rigcheck and 'Torso' or 'UpperTorso')].CFrame * CFrame.new(0.5, -0.8, 0)).p)
					local leftarm = ESPWorldToViewport((ent.Character[(rigcheck and 'Left Arm' or 'LeftHand')].CFrame * offset).p)
					local rightarm = ESPWorldToViewport((ent.Character[(rigcheck and 'Right Arm' or 'RightHand')].CFrame * offset).p)
					local leftleg = ESPWorldToViewport((ent.Character[(rigcheck and 'Left Leg' or 'LeftFoot')].CFrame * offset).p)
					local rightleg = ESPWorldToViewport((ent.Character[(rigcheck and 'Right Leg' or 'RightFoot')].CFrame * offset).p)
					EntityESP.Head.From = toptorso
					EntityESP.Head.To = head
					EntityESP.HeadFacing.From = head
					EntityESP.HeadFacing.To = headfront
					EntityESP.UpperTorso.From = toplefttorso
					EntityESP.UpperTorso.To = toprighttorso
					EntityESP.Torso.From = toptorso
					EntityESP.Torso.To = bottomtorso
					EntityESP.LowerTorso.From = bottomlefttorso
					EntityESP.LowerTorso.To = bottomrighttorso
					EntityESP.LeftArm.From = toplefttorso
					EntityESP.LeftArm.To = leftarm
					EntityESP.RightArm.From = toprighttorso
					EntityESP.RightArm.To = rightarm
					EntityESP.LeftLeg.From = bottomlefttorso
					EntityESP.LeftLeg.To = leftleg
					EntityESP.RightLeg.From = bottomrighttorso
					EntityESP.RightLeg.To = rightleg
				end)
			end
		end
	}
	
	ESP = Modern.Catalogs.Render:AddModule({
		Name = 'ESP',
		Function = function(callback)
			if callback then
				methodused = 'Drawing'..Method.Value
				if ESPRemoved[methodused] then
					ESP:Clean(entitylib.Events.EntityRemoved:Connect(ESPRemoved[methodused]))
				end
				if ESPAdded[methodused] then
					for _, v in entitylib.List do
						if Reference[v] then
							ESPRemoved[methodused](v)
						end
						ESPAdded[methodused](v)
					end
					ESP:Clean(entitylib.Events.EntityAdded:Connect(function(ent)
						if Reference[ent] then
							ESPRemoved[methodused](ent)
						end
						ESPAdded[methodused](ent)
					end))
				end
				if ESPUpdated[methodused] then
					ESP:Clean(entitylib.Events.EntityUpdated:Connect(ESPUpdated[methodused]))
					for _, v in entitylib.List do
						ESPUpdated[methodused](v)
					end
				end
				if ESPLoop[methodused] then
					ESP:Clean(RunService.RenderStepped:Connect(ESPLoop[methodused]))
				end
			else
				if ESPRemoved[methodused] then
					for i in Reference do
						ESPRemoved[methodused](i)
					end
				end
			end
		end
	})
	Method = ESP:AddDropdown({
		Name = 'Mode',
		List = {'2D', '3D', 'Skeleton'},
		Function = function(val)
			if ESP.Enabled then
				ESP:Toggle()
				ESP:Toggle()
			end
			BoundingBox.Frame.Visible = (val == '2D')
			Filled.Frame.Visible = (val == '2D')
			HealthBar.Frame.Visible = (val == '2D')
			Name.Frame.Visible = (val == '2D')
			DisplayName.Frame.Visible = Name.Frame.Visible and Name.Enabled
			Background.Frame.Visible = Name.Frame.Visible and Name.Enabled
		end,
	})

	BoundingBox = ESP:AddToggle({
		Name = 'Bounding Box',
		Function = function()
			if ESP.Enabled then
				ESP:Toggle()
				ESP:Toggle()
			end
		end,
		Default = true,
		Darker = true
	})
	Filled = ESP:AddToggle({
		Name = 'Filled',
		Function = function()
			if ESP.Enabled then
				ESP:Toggle()
				ESP:Toggle()
			end
		end,
		Darker = true
	})
	HealthBar = ESP:AddToggle({
		Name = 'Health Bar',
		Function = function()
			if ESP.Enabled then
				ESP:Toggle()
				ESP:Toggle()
			end
		end,
		Darker = true
	})
	Name = ESP:AddToggle({
		Name = 'Name',
		Function = function(callback)
			if ESP.Enabled then
				ESP:Toggle()
				ESP:Toggle()
			end
			DisplayName.Frame.Visible = callback
			Background.Frame.Visible = callback
		end,
		Darker = true
	})
	DisplayName = ESP:AddToggle({
		Name = 'Use Displayname',
		Function = function()
			if ESP.Enabled then
				ESP:Toggle()
				ESP:Toggle()
			end
		end,
		Default = true,
		Darker = true
	})
	Background = ESP:AddToggle({
		Name = 'Show Background',
		Function = function()
			if ESP.Enabled then
				ESP:Toggle()
				ESP:Toggle()
			end
		end,
		Darker = true
	})
	Teammates = ESP:AddToggle({
		Name = 'Priority Only',
		Function = function()
			if ESP.Enabled then
				ESP:Toggle()
				ESP:Toggle()
			end
		end,
		Default = true
	})
	Distance = ESP:AddToggle({
		Name = 'Distance Check',
		Function = function(callback)
			DistanceLimit.Object.Visible = callback
		end
	})
	DistanceLimit = ESP:AddSlider({
		Name = 'Player Distance',
		Min = 0,
		Max = 256,
		Default = 64,
		Darker = true,
		Visible = false
	})
end)
run(function()
	local Mode
	local StudLimit = {Object = {}}
	local rayCheck = RaycastParams.new()
	rayCheck.RespectCanCollide = true
	local overlapCheck = OverlapParams.new()
	overlapCheck.MaxParts = 9e9
	local modified, fflag = {}
	local teleported
	
	local function grabClosestNormal(ray)
		local partCF, mag, closest = ray.Instance.CFrame, 0, Enum.NormalId.Top
		for _, normal in Enum.NormalId:GetEnumItems() do
			local dot = partCF:VectorToWorldSpace(Vector3.fromNormalId(normal)):Dot(ray.Normal)
			if dot > mag then
				mag, closest = dot, normal
			end
		end
		return Vector3.fromNormalId(closest).X ~= 0 and 'X' or 'Z'
	end
	
	local Functions = {
		Part = function()
			local chars = {gameCamera, lplr.Character}
			for _, v in entitylib.List do
				table.insert(chars, v.Character)
			end
			overlapCheck.FilterDescendantsInstances = chars
	
			local parts = workspace:GetPartBoundsInBox(entitylib.character.RootPart.CFrame + Vector3.new(0, 1, 0), entitylib.character.RootPart.Size + Vector3.new(1, entitylib.character.HipHeight, 1), overlapCheck)
			for _, part in parts do
				if part.CanCollide and (not Spider.Enabled or SpiderShift) then
					modified[part] = true
					part.CanCollide = false
				end
			end
	
			for part in modified do
				if not table.find(parts, part) then
					modified[part] = nil
					part.CanCollide = true
				end
			end
		end,
		Character = function()
			for _, part in lplr.Character:GetDescendants() do
				if part:IsA('BasePart') and part.CanCollide and (not Spider.Enabled or SpiderShift) then
					modified[part] = true
					part.CanCollide = Spider.Enabled and not SpiderShift
				end
			end
		end,
		CFrame = function()
			local chars = {gameCamera, lplr.Character}
			for _, v in entitylib.List do
				table.insert(chars, v.Character)
			end
			rayCheck.FilterDescendantsInstances = chars
			overlapCheck.FilterDescendantsInstances = chars
	
			local ray = workspace:Raycast(entitylib.character.Head.CFrame.Position, entitylib.character.Humanoid.MoveDirection * 1.1, rayCheck)
			if ray and (not Spider.Enabled or SpiderShift) then
				local phaseDirection = grabClosestNormal(ray)
				if ray.Instance.Size[phaseDirection] <= StudLimit.Value then
					local root = entitylib.character.RootPart
					local dest = root.CFrame + (ray.Normal * (-(ray.Instance.Size[phaseDirection]) - (root.Size.X / 1.5)))
	
					if #workspace:GetPartBoundsInBox(dest, Vector3.one, overlapCheck) <= 0 then
						if Mode.Value == 'Motor' then
							motorMove(root, dest)
						else
							root.CFrame = dest
						end
					end
				end
			end
		end,
		FFlag = function()
			if teleported then return end
			setfflag('AssemblyExtentsExpansionStudHundredth', '-10000')
			fflag = true
		end
	}
	Functions.Motor = Functions.CFrame
	
	Phase = Modern.Catalogs.Player:AddModule({
		Name = 'Phase',
		Function = function(callback)
			if callback then
				Phase:Clean(RunService.Stepped:Connect(function()
					if entitylib.isAlive then
						Functions[Mode.Value]()
					end
				end))
	
				if Mode.Value == 'FFlag' then
					Phase:Clean(lplr.OnTeleport:Connect(function()
						teleported = true
						setfflag('AssemblyExtentsExpansionStudHundredth', '30')
					end))
				end
			else
				if fflag then
					setfflag('AssemblyExtentsExpansionStudHundredth', '30')
				end
				for part in modified do
					part.CanCollide = true
				end
				table.clear(modified)
				fflag = nil
			end
		end
	})
	Mode = Phase:AddDropdown({
		Name = 'Mode',
		List = {'Part', 'Character', 'CFrame', 'Motor', 'FFlag'},
		Function = function(val)
			StudLimit.Object.Visible = val == 'CFrame' or val == 'Motor'
			if fflag then
				setfflag('AssemblyExtentsExpansionStudHundredth', '30')
			end
			for part in modified do
				part.CanCollide = true
			end
			table.clear(modified)
			fflag = nil
		end
	})
	StudLimit = Phase:AddSlider({
		Name = 'Wall Size',
		Min = 1,
		Max = 20,
		Default = 5,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end,
		Darker = true,
		Visible = false
	})
end)

run(function()
	local Mode
	local Value
	local State
	local rayCheck = RaycastParams.new()
	rayCheck.RespectCanCollide = true
	local Active, Truss
	
	Spider = Modern.Catalogs.Movement:AddModule({
		Name = 'Spider',
		Function = function(callback)
			if callback then
				if Truss then Truss.Parent = gameCamera end
				Spider:Clean(RunService.PreSimulation:Connect(function(dt)
					if entitylib.isAlive then
						local root = lplr.Character.PrimaryPart or entitylib.character.RootPart
						local chars = {gameCamera, lplr.Character, Truss}
						for _, v in entitylib.List do
							table.insert(chars, v.Character)
						end
						SpiderShift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
						rayCheck.FilterDescendantsInstances = chars
						rayCheck.CollisionGroup = root.CollisionGroup
	
						if Mode.Value ~= 'Part' then
							local vec = entitylib.character.Humanoid.MoveDirection * 2.5
							local ray = workspace:Raycast(root.Position - Vector3.new(0, entitylib.character.HipHeight - 0.5, 0), vec, rayCheck)
							if Active and not ray then
								root.Velocity = Vector3.new(root.Velocity.X, 0, root.Velocity.Z)
							end
	
							Active = ray
							if Active and ray.Normal.Y == 0 then
								if not Phase.Enabled or not SpiderShift then
									if State.Enabled then
										entitylib.character.Humanoid:ChangeState(Enum.HumanoidStateType.Climbing)
									end
	
									root.Velocity *= Vector3.new(1, 0, 1)
									if Mode.Value == 'CFrame' then
										root.CFrame += Vector3.new(0, Value.Value * dt, 0)
									elseif Mode.Value == 'Impulse' then
										root:ApplyImpulse(Vector3.new(0, Value.Value, 0) * root.AssemblyMass)
									else
										root.Velocity += Vector3.new(0, Value.Value, 0)
									end
								end
							end
						else
							local ray = workspace:Raycast(root.Position - Vector3.new(0, entitylib.character.HipHeight - 0.5, 0), entitylib.character.RootPart.CFrame.LookVector * 2, rayCheck)
							if ray and (not Phase.Enabled or not SpiderShift) then
								Truss.Position = ray.Position - ray.Normal * 0.9 or Vector3.zero
							else
								Truss.Position = Vector3.zero
							end
						end
					end
				end))
			else
				if Truss then
					Truss.Parent = nil
				end
				SpiderShift = false
			end
		end
	})
	Mode = Spider:AddDropdown({
		Name = 'Mode',
		List = {'Velocity', 'Impulse', 'CFrame', 'Part'},
		Function = function(val)
			Value.Frame.Visible = val ~= 'Part'
			State.Frame.Visible = val ~= 'Part'
			if Truss then
				Truss:Destroy()
				Truss = nil
			end
			if val == 'Part' then
				Truss = Instance.new('TrussPart')
				Truss.Size = Vector3.new(2, 2, 2)
				Truss.Transparency = 1
				Truss.Anchored = true
				Truss.Parent = Spider.Enabled and gameCamera or nil
			end
		end
	})
	Value = Spider:AddSlider({
		Name = 'Speed',
		Min = 0,
		Max = 100,
		Default = 30,
		Darker = true,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	State = Spider:AddToggle({
		Name = 'Climb State',
		Darker = true
	})
end)
	
run(function()
	local SpinBot
	local Mode
	local XToggle
	local YToggle
	local ZToggle
	local Value
	local AngularVelocity
	
	SpinBot = Modern.Catalogs.Movement:AddModule({
		Name = 'Spin',
		Function = function(callback)
			if callback then
				SpinBot:Clean(RunService.PreSimulation:Connect(function()
					if entitylib.isAlive then
						if Mode.Value == 'RotVelocity' then
							local originalRotVelocity = entitylib.character.RootPart.RotVelocity
							entitylib.character.Humanoid.AutoRotate = false
							entitylib.character.RootPart.RotVelocity = Vector3.new(XToggle.Enabled and Value.Value or originalRotVelocity.X, YToggle.Enabled and Value.Value or originalRotVelocity.Y, ZToggle.Enabled and Value.Value or originalRotVelocity.Z)
						elseif Mode.Value == 'CFrame' then
							local val = math.rad((tick() * (20 * Value.Value)) % 360)
							local x, y, z = entitylib.character.RootPart.CFrame:ToOrientation()
							entitylib.character.RootPart.CFrame = CFrame.new(entitylib.character.RootPart.Position) * CFrame.Angles(XToggle.Enabled and val or x, YToggle.Enabled and val or y, ZToggle.Enabled and val or z)
						elseif AngularVelocity then
							AngularVelocity.Parent = entitylib.isAlive and entitylib.character.RootPart
							AngularVelocity.MaxTorque = Vector3.new(XToggle.Enabled and math.huge or 0, YToggle.Enabled and math.huge or 0, ZToggle.Enabled and math.huge or 0)
							AngularVelocity.AngularVelocity = Vector3.new(Value.Value, Value.Value, Value.Value)
						end
					end
				end))
			else
				if entitylib.isAlive and Mode.Value == 'RotVelocity' then
					entitylib.character.Humanoid.AutoRotate = true
				end
				if AngularVelocity then
					AngularVelocity.Parent = nil
				end
			end
		end
	})
	Mode = SpinBot:AddDropdown({
		Name = 'Mode',
		List = {'CFrame', 'RotVelocity', 'BodyMover'},
		Function = function(val)
			if AngularVelocity then
				AngularVelocity:Destroy()
				AngularVelocity = nil
			end
			AngularVelocity = val == 'BodyMover' and Instance.new('BodyAngularVelocity') or nil
		end
	})
	Value = SpinBot:AddSlider({
		Name = 'Speed',
		Min = 1,
		Max = 100,
		Default = 40
	})
	XToggle = SpinBot:AddToggle({Name = 'Spin X'})
	YToggle = SpinBot:AddToggle({
		Name = 'Spin Y',
		Default = true
	})
	ZToggle = SpinBot:AddToggle({Name = 'Spin Z'})
end)

run(function()
	local Tracers
	local Targets
	local Color
	local Transparency
	local StartPosition
	local EndPosition
	local Teammates
	local DistanceColor
	local Distance
	local DistanceLimit
	local Behind
	local Reference = {}
	
	local function Added(ent)
		if not ent.Player then return end
		if Teammates.Enabled and (not ent.Targetable) and (not ent.Friend) then return end
		if Modern.ThreadFix then
			setthreadidentity(8)
		end
	
		local EntityTracer = Drawing.new('Line')
		EntityTracer.Thickness = 1
		EntityTracer.Transparency = 1 - Transparency.Value
		EntityTracer.Color = entitylib.getEntityColor(ent) or Modern.Libraries.uipallet.FinalColor
		Reference[ent] = EntityTracer
	end
	
	local function Removed(ent)
		local v = Reference[ent]
		if v then
			if Modern.ThreadFix then
				setthreadidentity(8)
			end
			Reference[ent] = nil
			pcall(function()
				v.Visible = false
				v:Remove()
			end)
		end
	end
	
	local function Loop()
		local screenSize = Modern.MainScreenGui.AbsoluteSize
		local startVector = StartPosition.Value == 'Mouse' and UserInputService:GetMouseLocation() or Vector2.new(screenSize.X / 2, (StartPosition.Value == 'Middle' and screenSize.Y / 2 or screenSize.Y))
	
		for ent, EntityTracer in Reference do
			local distance = entitylib.isAlive and (entitylib.character.RootPart.Position - ent.RootPart.Position).Magnitude
			if Distance.Enabled and distance then
				if distance > DistanceLimit.Value then
					EntityTracer.Visible = false
					continue
				end
			end
	
			local pos = ent[EndPosition.Value == 'Torso' and 'RootPart' or 'Head'].Position
			local rootPos, rootVis = gameCamera:WorldToViewportPoint(pos)
			if not rootVis and Behind.Enabled then
				local tempPos = gameCamera.CFrame:PointToObjectSpace(pos)
				tempPos = CFrame.Angles(0, 0, (math.atan2(tempPos.Y, tempPos.X) + math.pi)):VectorToWorldSpace((CFrame.Angles(0, math.rad(89.9), 0):VectorToWorldSpace(Vector3.new(0, 0, -1))))
				rootPos = gameCamera:WorldToViewportPoint(gameCamera.CFrame:pointToWorldSpace(tempPos))
				rootVis = true
			end
	
			local endVector = Vector2.new(rootPos.X, rootPos.Y)
			EntityTracer.Visible = rootVis
			EntityTracer.From = startVector
			EntityTracer.To = endVector
			EntityTracer.Color = entitylib.getEntityColor(ent) or Modern.Libraries.uipallet.FinalColor
		end
	end
	
	Tracers = Modern.Catalogs.Render:AddModule({
		Name = 'Tracers',
		Function = function(callback)
			if callback then
				Tracers:Clean(entitylib.Events.EntityRemoved:Connect(Removed))
				for _, v in entitylib.List do
					if Reference[v] then
						Removed(v)
					end
					Added(v)
				end
				Tracers:Clean(entitylib.Events.EntityAdded:Connect(function(ent)
					if Reference[ent] then
						Removed(ent)
					end
					Added(ent)
				end))
				Tracers:Clean(RunService.RenderStepped:Connect(Loop))
			else
				for i in Reference do
					Removed(i)
				end
			end
		end
	})
	StartPosition = Tracers:AddDropdown({
		Name = 'Start Position',
		List = {'Middle', 'Bottom', 'Mouse'},
		Function = function()
			if Tracers.Enabled then
				Tracers:Toggle()
				Tracers:Toggle()
			end
		end
	})
	EndPosition = Tracers:AddDropdown({
		Name = 'End Position',
		List = {'Head', 'Torso'},
		Function = function()
			if Tracers.Enabled then
				Tracers:Toggle()
				Tracers:Toggle()
			end
		end
	})
	Transparency = Tracers:AddSlider({
		Name = 'Transparency',
		Min = 0,
		Max = 1,
		Function = function(val)
			for _, tracer in Reference do
				tracer.Transparency = 1 - val
			end
		end,
		Decimal = 10
	})
	Distance = Tracers:AddToggle({
		Name = 'Distance Check',
		Function = function(callback)
			DistanceLimit.Frame.Visible = callback
		end
	})
	DistanceLimit = Tracers:AddSlider({
		Name = 'Player Distance',
		Min = 0,
		Max = 256,
		Default = 64,
		Darker = true,
		Visible = false
	})
	Behind = Tracers:AddToggle({
		Name = 'Behind',
		Default = true
	})
	Teammates = Tracers:AddToggle({
		Name = 'Priority Only',
		Function = function()
			if Tracers.Enabled then
				Tracers:Toggle()
				Tracers:Toggle()
			end
		end,
		Default = true
	})
end)

run(function()
	local HitBox
	local Targets
	local TargetPart
	local Expand
	local modified = {}
	
	HitBox = Modern.Catalogs.Combat:AddModule({
		Name = 'HitBox',
		Function = function(callback)
			if callback then
				repeat
					for _, v in entitylib.List do
						if v.Targetable then
							if not v.Player then continue end
							local part = v[TargetPart.Value]
							if not modified[part] then
								modified[part] = part.Size
							end
							part.Size = modified[part] + Vector3.new(Expand.Value, Expand.Value, Expand.Value)
						end
					end
					task.wait()
				until not HitBox.Enabled
			else
				for i, v in modified do
					i.Size = v
				end
				table.clear(modified)
			end
		end
	})
	TargetPart = HitBox:AddDropdown({
		Name = 'Part',
		List = {'RootPart', 'Head'}
	})
	Expand = HitBox:AddSlider({
		Name = 'Expand',
		Min = 0,
		Max = 2,
		Decimal = 10,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
end)

run(function()
	local AntiRagdoll
	AntiRagdoll = Modern.Catalogs.Other:AddModule({
		Name = 'AntiRagdoll',
		Function = function(callback)
			if entitylib.isAlive then
				entitylib.character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, not callback)
			end
	
			if callback then
				AntiRagdoll:Clean(entitylib.Events.LocalAdded:Connect(function(char)
					char.Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
				end))
			end
		end
	})
end)

run(function()
	local Blink
	local Type
	local AutoSend
	local AutoSendLength
	local oldphys, oldsend
	
	Blink = Modern.Catalogs.Other:AddModule({
		Name = 'Blink',
		Function = function(callback)
			if callback then
				local teleported
				Blink:Clean(lplr.OnTeleport:Connect(function()
					setfflag('S2PhysicsSenderRate', '15')
					setfflag('DataSenderRate', '60')
					teleported = true
				end))
	
				repeat
					local physicsrate, senderrate = '0', Type.Value == 'All' and '-1' or '60'
					if AutoSend.Enabled and tick() % (AutoSendLength.Value + 0.1) > AutoSendLength.Value then
						physicsrate, senderrate = '15', '60'
					end
	
					if physicsrate ~= oldphys or senderrate ~= oldsend then
						setfflag('S2PhysicsSenderRate', physicsrate)
						setfflag('DataSenderRate', senderrate)
						oldphys, oldsend = physicsrate, oldsend
					end
					
					task.wait(0.03)
				until (not Blink.Enabled and not teleported)
			else
				if setfflag then
					setfflag('S2PhysicsSenderRate', '15')
					setfflag('DataSenderRate', '60')
				end
				oldphys, oldsend = nil, nil
			end
		end
	})
	Type = Blink:AddDropdown({
		Name = 'Type',
		List = {'Movement Only', 'All'}
	})
	AutoSend = Blink:AddToggle({
		Name = 'Auto send',
		Function = function(callback)
			AutoSendLength.Frame.Visible = callback
		end
	})
	AutoSendLength = Blink:AddSlider({
		Name = 'Send threshold',
		Min = 0,
		Max = 1,
		Decimal = 100,
		Darker = true,
		Visible = false,
		Suffix = function(val)
			return val == 1 and 'second' or 'seconds'
		end
	})
end)

run(function()
	local Xray
	local List
	local modified = {}
	
	local function modifyPart(v)
		if v:IsA('BasePart') then
			modified[v] = true
			v.LocalTransparencyModifier = 0.5
		end
	end
	
	Xray = Modern.Catalogs.Render:AddModule({
		Name = 'XRay',
		Function = function(callback)
			if callback then
				Xray:Clean(workspace.DescendantAdded:Connect(modifyPart))
				for _, v in workspace:GetDescendants() do
					modifyPart(v)
				end
			else
				for i in modified do
					i.LocalTransparencyModifier = 0
				end
				table.clear(modified)
			end
		end
	})
	Transparency = Xray:AddSlider({
		Name = 'Transparency',
		Min = 0,
		Max = 1,
		Function = function(val)
			for i in modified do
				i.LocalTransparencyModifier = 1 - val
			end
		end,
		Decimal = 100
	})
end)

local mouseClicked
run(function()
	local SilentAim
	local Target
	local Mode
	local Method
	local MethodRay = {}
	local IgnoredScripts
	local Range
	local HitChance
	local HeadshotChance
	local AutoFire
	local AutoFireShootDelay
	local AutoFireMode
	local AutoFirePosition
	local Wallbang
	local CircleColor
	local CircleTransparency
	local CircleFilled
	local CircleObject
	local Projectile
	local ProjectileSpeed
	local ProjectileGravity
	local RaycastWhitelist = RaycastParams.new()
	RaycastWhitelist.FilterType = Enum.RaycastFilterType.Include
	local ProjectileRaycast = RaycastParams.new()
	ProjectileRaycast.RespectCanCollide = true
	local fireoffset, rand, delayCheck = CFrame.identity, Random.new(), tick()
	local oldnamecall, oldray

	local function getTarget(origin, obj)
		if rand.NextNumber(rand, 0, 100) > (AutoFire.Enabled and 100 or HitChance.Value) then return end
		local targetPart = (rand.NextNumber(rand, 0, 100) < (AutoFire.Enabled and 100 or HeadshotChance.Value)) and 'Head' or 'RootPart'
		local ent = entitylib['Entity'..Mode.Value]({
			Range = Range.Value,
			Wallcheck = true,
			Part = targetPart,
			Origin = origin,
			Players = true,
			NPCs = true
		})

		if ent then
			Targetinfo.Targets[ent] = tick() + 1
			if Projectile.Enabled then
				ProjectileRaycast.FilterDescendantsInstances = {gameCamera, ent.Character}
				ProjectileRaycast.CollisionGroup = ent[targetPart].CollisionGroup
			end
		end

		return ent, ent and ent[targetPart], origin
	end

	local Hooks = {
		FindPartOnRayWithIgnoreList = function(args)
			local ent, targetPart, origin = getTarget(args[1].Origin, {args[2]})
			if not ent then return end
			if Wallbang.Enabled then
				return {targetPart, targetPart.Position, targetPart.GetClosestPointOnSurface(targetPart, origin), targetPart.Material}
			end
			args[1] = Ray.new(origin, CFrame.lookAt(origin, targetPart.Position).LookVector * args[1].Direction.Magnitude)
		end,
		Raycast = function(args)
			if MethodRay.Value ~= 'All' and args[3] and args[3].FilterType ~= Enum.RaycastFilterType[MethodRay.Value] then return end
			local ent, targetPart, origin = getTarget(args[1])
			if not ent then return end
			args[2] = CFrame.lookAt(origin, targetPart.Position).LookVector * args[2].Magnitude
			if Wallbang.Enabled then
				RaycastWhitelist.FilterDescendantsInstances = {targetPart}
				args[3] = RaycastWhitelist
			end
		end,
		ScreenPointToRay = function(args)
			local ent, targetPart, origin = getTarget(gameCamera.CFrame.Position)
			if not ent then return end
			local direction = CFrame.lookAt(origin, targetPart.Position)
			if Projectile.Enabled then
				local calc = prediction.SolveTrajectory(origin, ProjectileSpeed.Value, ProjectileGravity.Value, targetPart.Position, targetPart.Velocity, workspace.Gravity, ent.HipHeight, nil, ProjectileRaycast)
				if not calc then return end
				direction = CFrame.lookAt(origin, calc)
			end
			return {Ray.new(origin + (args[3] and direction.LookVector * args[3] or Vector3.zero), direction.LookVector)}
		end,
		Ray = function(args)
			local ent, targetPart, origin = getTarget(args[1])
			if not ent then return end
			if Projectile.Enabled then
				local calc = prediction.SolveTrajectory(origin, ProjectileSpeed.Value, ProjectileGravity.Value, targetPart.Position, targetPart.Velocity, workspace.Gravity, ent.HipHeight, nil, ProjectileRaycast)
				if not calc then return end
				args[2] = CFrame.lookAt(origin, calc).LookVector * args[2].Magnitude
			else
				args[2] = CFrame.lookAt(origin, targetPart.Position).LookVector * args[2].Magnitude
			end
		end
	}
	Hooks.FindPartOnRayWithWhitelist = Hooks.FindPartOnRayWithIgnoreList
	Hooks.FindPartOnRay = Hooks.FindPartOnRayWithIgnoreList
	Hooks.ViewportPointToRay = Hooks.ScreenPointToRay

	SilentAim = Modern.Catalogs.Combat:AddModule({
		Name = 'Silent Aim',
		Function = function(callback)
			if CircleObject then
				CircleObject.Visible = callback and Mode.Value == 'Mouse'
			end
			if callback then
				if Method.Value == 'Ray' then
					oldray = hookfunction(Ray.new, function(origin, direction)
						if checkcaller() then
							return oldray(origin, direction)
						end

						local calling = getcallingscript()
						if calling then
							local list = {'ControlScript', 'ControlModule'}
							if table.find(list, tostring(calling)) then
								return oldray(origin, direction)
							end
						end

						local args = {origin, direction}
						Hooks.Ray(args)
						return oldray(unpack(args))
					end)
				else
					print(Method.Value)
					oldnamecall = hookmetamethod(game, '__namecall', function(...)
						if getnamecallmethod() ~= Method.Value then
							return oldnamecall(...)
						end
						if checkcaller() then
							return oldnamecall(...)
						end

						local calling = getcallingscript()
						if calling then
							local list = {'ControlScript', 'ControlModule'}
							if table.find(list, tostring(calling)) then
								return oldnamecall(...)
							end
						end

						local self, args = ..., {select(2, ...)}
						local res = Hooks[Method.Value](args)
						if res then
							return unpack(res)
						end
						return oldnamecall(self, unpack(args))
					end)
				end

				repeat
					if CircleObject then
						CircleObject.Position = UserInputService:GetMouseLocation()
					end
					if AutoFire.Enabled then
						local origin = AutoFireMode.Value == 'Camera' and gameCamera.CFrame or entitylib.isAlive and entitylib.character.RootPart.CFrame or CFrame.identity
						local ent = entitylib['Entity'..Mode.Value]({
							Range = Range.Value,
							Wallcheck = true,
							Part = 'Head',
							Origin = (origin * fireoffset).Position,
							Players = true,
							NPCs = false
						})

						if mouse1click and (isrbxactive or iswindowactive)() then
							if ent and canClick() then
								if delayCheck < tick() then
									if mouseClicked then
										mouse1release()
										delayCheck = tick() + AutoFireShootDelay.Value
									else
										mouse1press()
									end
									mouseClicked = not mouseClicked
								end
							else
								if mouseClicked then
									mouse1release()
								end
								mouseClicked = false
							end
						end
					end
					task.wait()
				until not SilentAim.Enabled
			else
				if oldnamecall then
					hookmetamethod(game, '__namecall', oldnamecall)
				end
				if oldray then
					hookfunction(Ray.new, oldray)
				end
				oldnamecall, oldray = nil, nil
			end
		end,
		ExtraText = function()
			return Method.Value:gsub('FindPartOnRay', '')
		end
	})
	Mode = SilentAim:AddDropdown({
		Name = 'Mode',
		List = {'Mouse', 'Position'},
		Function = function(val)
			if CircleObject then
				CircleObject.Visible = SilentAim.Enabled and val == 'Mouse'
			end
		end
	})
	Method = SilentAim:AddDropdown({
		Name = 'Method',
		List = {'FindPartOnRay', 'FindPartOnRayWithIgnoreList', 'FindPartOnRayWithWhitelist', 'ScreenPointToRay', 'ViewportPointToRay', 'Raycast', 'Ray'},
		Function = function(val)
			if SilentAim.Enabled then
				SilentAim:Toggle()
				SilentAim:Toggle()
			end
			MethodRay.Frame.Visible = val == 'Raycast'
		end
	})
	MethodRay = SilentAim:AddDropdown({
		Name = 'Raycast Type',
		List = {'All', 'Exclude', 'Include'},
		Darker = true,
		Visible = false
	})
	Range = SilentAim:AddSlider({
		Name = 'Range',
		Min = 1,
		Max = 1000,
		Default = 150,
		Function = function(val)
			if CircleObject then
				CircleObject.Radius = val
			end
		end,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	HitChance = SilentAim:AddSlider({
		Name = 'Hit Chance',
		Min = 0,
		Max = 100,
		Default = 85,
		Suffix = '%'
	})
	HeadshotChance = SilentAim:AddSlider({
		Name = 'Headshot Chance',
		Min = 0,
		Max = 100,
		Default = 65,
		Suffix = '%'
	})
	AutoFire = SilentAim:AddToggle({
		Name = 'AutoFire',
		Function = function(callback)
			AutoFireShootDelay.Frame.Visible = callback
			AutoFireMode.Frame.Visible = callback
		end
	})
	AutoFireShootDelay = SilentAim:AddSlider({
		Name = 'Delay',
		Min = 0,
		Max = 1,
		Decimal = 100,
		Visible = false,
		Darker = true,
		Suffix = function(val)
			return val == 1 and 'second' or 'seconds'
		end
	})
	AutoFireMode = SilentAim:AddDropdown({
		Name = 'Origin',
		List = {'RootPart', 'Camera'},
		Visible = false,
		Darker = true
	})
	Wallbang = SilentAim:AddToggle({Name = 'Wallbang'})
	SilentAim:AddToggle({
		Name = 'Range Circle',
		Function = function(callback)
			if callback then
				CircleObject = Drawing.new('Circle')
				CircleObject.Color = Modern.Libraries.uipallet.FinalColor
				CircleObject.Position = Modern.MainScreenGui.AbsoluteSize / 2
				CircleObject.Radius = Range.Value
				CircleObject.NumSides = 100
				CircleObject.Transparency = 1 - CircleTransparency.Value
				CircleObject.Visible = SilentAim.Enabled and Mode.Value == 'Mouse'
			else
				pcall(function()
					CircleObject.Visible = false
					CircleObject:Remove()
				end)
			end
			CircleTransparency.Frame.Visible = callback
		end
	})
	CircleTransparency = SilentAim:AddSlider({
		Name = 'Transparency',
		Min = 0,
		Max = 1,
		Decimal = 10,
		Default = 0.5,
		Function = function(val)
			if CircleObject then
				CircleObject.Transparency = 1 - val
			end
		end,
		Darker = true,
		Visible = false
	})
	Projectile = SilentAim:AddToggle({
		Name = 'Projectile',
		Function = function(callback)
			ProjectileSpeed.Frame.Visible = callback
			ProjectileGravity.Frame.Visible = callback
		end
	})
	ProjectileSpeed = SilentAim:AddSlider({
		Name = 'Speed',
		Min = 1,
		Max = 1000,
		Default = 1000,
		Darker = true,
		Visible = false,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	ProjectileGravity = SilentAim:AddSlider({
		Name = 'Gravity',
		Min = 0,
		Max = 192.6,
		Default = 192.6,
		Darker = true,
		Visible = false
	})
end)
	
run(function()
	local TriggerBot
	local Targets
	local ShootDelay
	local Distance
	local rayCheck, delayCheck = RaycastParams.new(), tick()
	
	local function getTriggerBotTarget()
		rayCheck.FilterDescendantsInstances = {lplr.Character, gameCamera}
	
		local ray = workspace:Raycast(gameCamera.CFrame.Position, gameCamera.CFrame.LookVector * Distance.Value, rayCheck)
		if ray and ray.Instance then
			for _, v in entitylib.List do
				if v.Targetable and v.Character and v.Player then
					if ray.Instance:IsDescendantOf(v.Character) then
						return entitylib.isVulnerable(v) and v
					end
				end
			end
		end
	end
	
	TriggerBot = Modern.Catalogs.Combat:AddModule({
		Name = 'Trigger Bot',
		Function = function(callback)
			if callback then
				repeat
					if mouse1click and (isrbxactive or iswindowactive)() then
						if getTriggerBotTarget() and canClick() then
							if delayCheck < tick() then
								if mouseClicked then
									mouse1release()
									delayCheck = tick() + ShootDelay.Value
								else
									mouse1press()
								end
								mouseClicked = not mouseClicked
							end
						else
							if mouseClicked then
								mouse1release()
							end
							mouseClicked = false
						end
					end
					task.wait()
				until not TriggerBot.Enabled
			else
				if mouse1click and (isrbxactive or iswindowactive)() then
					if mouseClicked then
						mouse1release()
					end
				end
				mouseClicked = false
			end
		end
	})
	ShootDelay = TriggerBot:AddSlider({
		Name = 'Delay',
		Min = 0,
		Max = 1,
		Decimal = 100,
		Suffix = function(val)
			return val == 1 and 'second' or 'seconds'
		end
	})
	Distance = TriggerBot:AddSlider({
		Name = 'Distance',
		Min = 0,
		Max = 1000,
		Default = 1000,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
end)

run(function()
	local FOV
	local Value
	local oldfov
	
	FOV = Modern.Catalogs.Render:AddModule({
		Name = 'FOV',
		Function = function(callback)
			if callback then
				oldfov = gameCamera.FieldOfView
				repeat
					gameCamera.FieldOfView = Value.Value
					task.wait()
				until not FOV.Enabled
			else
				gameCamera.FieldOfView = oldfov
			end
		end
	})
	Value = FOV:AddSlider({
		Name = 'FOV',
		Min = 30,
		Max = 120
	})
end)

run(function()
	local TargetStrafe
	local Targets
	local SearchRange
	local StrafeRange
	local YFactor
	local rayCheck = RaycastParams.new()
	rayCheck.RespectCanCollide = true
	local module, old
	
	TargetStrafe = Modern.Catalogs.Movement:AddModule({
		Name = 'Target Strafe',
		Function = function(callback)
			if callback then
				if not module then
					local suc = pcall(function() module = require(lplr.PlayerScripts.PlayerModule).controls end)
					if not suc then
						module = {}
					end
				end
				
				old = module.moveFunction
				local flymod, ang, oldent = Modern.Modules.Fly or {Enabled = false}
				module.moveFunction = function(self, vec, face)
					local ent = not UserInputService:IsKeyDown(Enum.KeyCode.S) and entitylib.EntityPosition({
						Range = SearchRange.Value,
						Wallcheck = false,
						Part = 'RootPart',
						Players = true,
						NPCs = false
					})
	
					if ent then
						local root, targetPos = entitylib.character.RootPart, ent.RootPart.Position
						rayCheck.FilterDescendantsInstances = {lplr.Character, gameCamera, ent.Character}
						rayCheck.CollisionGroup = root.CollisionGroup
	
						if flymod.Enabled or workspace:Raycast(targetPos, Vector3.new(0, -70, 0), rayCheck) then
							local factor, localPosition = 0, root.Position
							if ent ~= oldent then
								ang = math.deg(select(2, CFrame.lookAt(targetPos, localPosition):ToEulerAnglesYXZ()))
							end
							local yFactor = math.abs(localPosition.Y - targetPos.Y) * (YFactor.Value / 100)
							local entityPos = Vector3.new(targetPos.X, localPosition.Y, targetPos.Z)
							local newPos = entityPos + (CFrame.Angles(0, math.rad(ang), 0).LookVector * (StrafeRange.Value - yFactor))
							local startRay, endRay = entityPos, newPos
	
							if not wallcheck and workspace:Raycast(targetPos, (localPosition - targetPos), rayCheck) then
								startRay, endRay = entityPos + (CFrame.Angles(0, math.rad(ang), 0).LookVector * (entityPos - localPosition).Magnitude), entityPos
							end
	
							local ray = workspace:Blockcast(CFrame.new(startRay), Vector3.new(1, entitylib.character.HipHeight + (root.Size.Y / 2), 1), (endRay - startRay), rayCheck)
							if (localPosition - newPos).Magnitude < 3 or ray then
								factor = (8 - math.min((localPosition - newPos).Magnitude, 3))
								if ray then
									newPos = ray.Position + (ray.Normal * 1.5)
									factor = (localPosition - newPos).Magnitude > 3 and 0 or factor
								end
							end
	
							if not flymod.Enabled and not workspace:Raycast(newPos, Vector3.new(0, -70, 0), rayCheck) then
								newPos = entityPos
								factor = 40
							end
	
							ang += factor % 360
							vec = ((newPos - localPosition) * Vector3.new(1, 0, 1)).Unit
							vec = vec == vec and vec or Vector3.zero
							TargetStrafeVector = vec
						else
							ent = nil
						end
					end
	
					TargetStrafeVector = ent and vec or nil
					oldent = ent
					return old(self, vec, face)
				end
			else
				if module and old then
					module.moveFunction = old
				end
				TargetStrafeVector = nil
			end
		end
	})

	SearchRange = TargetStrafe:AddSlider({
		Name = 'Search Range',
		Min = 1,
		Max = 30,
		Default = 24,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	StrafeRange = TargetStrafe:AddSlider({
		Name = 'Strafe Range',
		Min = 1,
		Max = 30,
		Default = 18,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	YFactor = TargetStrafe:AddSlider({
		Name = 'Y Factor',
		Min = 0,
		Max = 100,
		Default = 100,
		Suffix = '%'
	})
end)

run(function()
	local Shader
	local cacheLighting = {}

	local BlurEffect = Instance.new('BlurEffect')
	BlurEffect.Size = 6

	local ColorCorrectionEffect = Instance.new('ColorCorrectionEffect')
	ColorCorrectionEffect.Saturation = -0.4

	local SnowEffect = Instance.new("Part")
	SnowEffect.Size = vector.create(200, 1, 200)
	SnowEffect.Transparency = 1
	SnowEffect.Anchored = true


	local SnowParticle = Instance.new("ParticleEmitter")
	SnowParticle.EmissionDirection = "Bottom"
	SnowParticle.Rate = 20000
	SnowParticle.Lifetime = NumberRange.new(3.5, 3.5)
	SnowParticle.Speed = NumberRange.new(50, 50)
	SnowParticle.Texture = "rbxassetid://92367298778210"
	SnowParticle.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 0.4)
	})
	SnowParticle.SpreadAngle = Vector2.new(70, 70)
	SnowParticle.Parent = SnowEffect
	SnowParticle:Clone().Parent = SnowEffect
	SnowParticle:Clone().Parent = SnowEffect
	local Time = {}
	Shader = Modern.Catalogs.Other:AddModule({
		Name = 'Shader',
		Function = function(callback)
			if callback then
				cacheLighting = {
					Lighting.Ambient;
					Lighting.Brightness;
					Lighting.ColorShift_Bottom;
					Lighting.ColorShift_Top;
					Lighting.EnvironmentDiffuseScale;
					Lighting.EnvironmentSpecularScale;
					Lighting.GlobalShadows;
					Lighting.OutdoorAmbient;
					Lighting.ShadowSoftness;
					Lighting.TimeOfDay;
				};
				Lighting.Ambient = Color3.fromRGB(94, 99, 188)
				Lighting.Brightness = 4
				Lighting.ColorShift_Bottom = Color3.fromRGB(0,0,0)
				Lighting.ColorShift_Top = Color3.fromRGB(0,0,0)
				Lighting.EnvironmentDiffuseScale = 1
				Lighting.EnvironmentSpecularScale = 1
				Lighting.GlobalShadows = true
				Lighting.OutdoorAmbient = Color3.fromRGB(0,0,0)
				Lighting.ShadowSoftness = 3
				Lighting.TimeOfDay = (Time.Value or '00')..':30:00'
				SnowEffect.Parent = workspace
				Shader:Clean(RunService.RenderStepped:Connect(function()
					if entitylib.isAlive then
						SnowEffect.Position = entitylib.character.RootPart.Position + vector.create(0, 90, 0)
					end
				end))
				BlurEffect.Parent = Lighting
				ColorCorrectionEffect.Parent = Lighting
			else
				Lighting.Ambient = cacheLighting[1]
				Lighting.Brightness = cacheLighting[2]
				Lighting.ColorShift_Bottom = cacheLighting[3]
				Lighting.ColorShift_Top = cacheLighting[4]
				Lighting.EnvironmentDiffuseScale = cacheLighting[5]
				Lighting.EnvironmentSpecularScale = cacheLighting[6]
				Lighting.GlobalShadows = cacheLighting[7]
				Lighting.OutdoorAmbient = cacheLighting[8]
				Lighting.ShadowSoftness = cacheLighting[9]
				Lighting.TimeOfDay = cacheLighting[10]
				SnowEffect.Parent = nil
				BlurEffect.Parent = nil
				ColorCorrectionEffect.Parent = nil
			end
		end,
        Default = false
	})
	Time = Shader:AddSlider({
		Name = 'Time',
		Min = 0,
		Max = 24,
		Default = 12,
		Function = function(val)
			if Shader.Enabled then 
				Lighting.TimeOfDay = val..':00:00'
			end
		end
	})
end)

run(function()
    local AirJump
    local Velocity
    AirJump = Modern.Catalogs.Player:AddModule({
        Name = "AirJump",
        Function = function(callback)
            if callback then
				AirJump:Clean(UserInputService.InputBegan:Connect(function(input, gameProcessed)
					if gameProcessed then return end
					if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Space then
						while UserInputService:IsKeyDown(Enum.KeyCode.Space) do
							if entitylib.isAlive and lplr.Character.PrimaryPart then
								local PrimaryPart = lplr.Character.PrimaryPart
								PrimaryPart.Velocity = vector.create(PrimaryPart.Velocity.X, Velocity.Value, PrimaryPart.Velocity.Z)
							end
							wait()
						end
					end
				end))
				if UserInputService.TouchEnabled then
					local Jumping = false
					local JumpButton = lplr.PlayerGui:WaitForChild("TouchGui"):WaitForChild("TouchControlFrame"):WaitForChild("JumpButton")
					
					AirJump:Clean(JumpButton.MouseButton1Down:Connect(function()
						Jumping = true
					end))

					AirJump:Clean(JumpButton.MouseButton1Up:Connect(function()
						Jumping = false
					end))

					AirJump:Clean(RunService.RenderStepped:Connect(function()
						if Jumping and entitylib.isAlive and lplr.Character then
							local PrimaryPart = lplr.Character.PrimaryPart
							PrimaryPart.Velocity = vector.create(PrimaryPart.Velocity.X, Velocity.Value, PrimaryPart.Velocity.Z)
						end
					end))
				end
			end
        end
    })
    Velocity = AirJump:AddSlider({
        Name = 'Velocity',
        Min = 50,
        Max = 300,
        Default = 50
    })
end)


run(function()
	local Trails
	local Texture
	local Lifetime
	local Thickness
	local Particle
	local ParticleMain
	
	Trails = Modern.Catalogs.Render:AddModule({
		Name = 'Trails',
		Function = function(callback)
			if callback then
				ParticleMain = Instance.new("Part")
				ParticleMain.Size = vector.create(0, 0, 0)
				ParticleMain.Transparency = 0
				ParticleMain.CanCollide = false
				ParticleMain.Anchored = true
				Particle = Instance.new('ParticleEmitter')
				Particle.EmissionDirection = "Bottom"
				Particle.Rate = 5
				Particle.Lifetime = NumberRange.new(3.5, 3.5)
				Particle.Speed = NumberRange.new(0, 0)
				Particle.Texture = "rbxassetid://84083457957085"
				Particle.Size = NumberSequence.new({
					NumberSequenceKeypoint.new(0, Thickness.Value/5),
					NumberSequenceKeypoint.new(0.02, Thickness.Value),
					NumberSequenceKeypoint.new(1, 0)
				})
				Particle.SpreadAngle = Vector2.new(0, 0)
				Particle.Parent = ParticleMain
	
				Trails:Clean(Particle)
				Trails:Clean(ParticleMain)
				Trails:Clean(RunService.RenderStepped:Connect(function(ent)
					if entitylib.isAlive then
						ParticleMain.Position = entitylib.character.RootPart.Position - vector.create(0, 1, 0)
					end
				end))
				ParticleMain.Parent = workspace
			else
				Particle = nil
				ParticleMain = nil
			end
		end
	})
	Rate = Trails:AddSlider({
		Name = 'Rate',
		Min = 0,
		Max = 10,
		Default = 5,
		Decimal = 10,
		Function = function(val)
			if Particle then
				Particle.Rate = val
			end
		end
	})
	Lifetime = Trails:AddSlider({
		Name = 'Lifetime',
		Min = 1,
		Max = 5,
		Default = 3,
		Decimal = 10,
		Function = function(val)
			if Particle then
				Particle.Lifetime = NumberRange.new(val, val)
			end
		end,
		Suffix = function(val)
			return val == 1 and 'second' or 'seconds'
		end
	})
	Thickness = Trails:AddSlider({
		Name = 'Thickness',
		Min = 0,
		Max = 2,
		Default = 1,
		Decimal = 100,
		Function = function(val)
			if Particle then
				Particle.Size = NumberSequence.new({
					NumberSequenceKeypoint.new(0, val),
					NumberSequenceKeypoint.new(1, 0)
				})
			end
		end,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
end)

end


-- ================================================================
-- 8. EMBEDDED MODULE: Modern/Games/17625359962.lua (Rivals Game Features)
-- ================================================================
embeddedModules['Modern/Games/17625359962.lua'] = function(...)
-- This file was protected using Luraph Obfuscator v14.4.2 [https://lura.ph/]

return({vi=function(E,E,X,q,Q)q[E]=(X[0x2][31][Q]);end,_=function(E)local X=E[0];local q=E[1];local Q=E[2];return function(E,Z,D)local r={};if typeof(D)~="\73nstanc\101"then local d={q,Q.Character};for q,q in X.List do if q.Targetable and q.Character then local Q=q.Character:FindFirstChild("R\105ot \83hield");if Q then for G,G in Q:GetDescendants()do if G:IsA('\66a\115ePa\114t')then G.CanQuery=true;G.CanCollide=true;end;end;for G,G in q.Character:GetChildren()do if G~=Q then table.insert(d,G);end;end;table.insert(r,Q);else table.insert(d,q.Character);end;end;end;if typeof(D)=='t\97ble'then for q,q in D do table.insert(d,q);end;end;D=X.IgnoreObject;D.FilterDescendantsInstances=d;end;local X=workspace.Raycast(workspace,E,(Z-E),D);for E,E in r do for q,q in E:GetDescendants()do if q:IsA("Bas\101\80art")then q.CanQuery=false;q.CanCollide=false;end;end;end;return X;end;end,c=string,ni=function(E,X,q,Q,Z)local D;q=nil;X=(nil);local r;Q=0X0035;while true do if not(Q>16.0)then Q=(0X2f);X=({});else if Q==47.0 then r=1.0;break;else q={nil,E.B,nil,nil,E.B,nil,E.B,E.B,nil,E.B,E.B};q[0X1]=Z[1]();Q=16;end;end;end;q[11]=X;for d=1.0,Z[2][0X1e]()do local d,G;d,G=E:ui(Z,G,d);for b=0Xb,0X38,12 do D,r=E:bi(r,G,d,Z,b,X);if D~=31539 then else break;end;end;end;return Q,q,X;end,Wh=function(E,X,q,Q,Z,D)if Z<101.0 then(X[0XE])[8.0]=E.u;return 0x3f66,Z,D;else if not(Z>0.0)then else D=Q();(X[0XE])[7.0]=E.d;if not q[27297]then(q)[908]=(-805306732+(E.ih((E.nh((E.Rh(q[0x59E2],(q[0X2e14])))>q[0XabF]and E.U[0X1]or q[0X2a36],(q[23010]))))));Z=524046088+((q[17510]<=q[0X6AcF]and q[26928]or E.U[0X5])-E.U[2]-q[0X1c1D]+E.U[0X6]);q[0x6AA1]=Z;else Z=(q[27297]);end;end;end;return nil,Z,D;end,Ai=function(E,X,q,Q)if not(q>48.0)then X[33]=E.W;return 0X7832,q;elseif q~=85.0 then X[0x1E]=function()local Z,D,r,d,G={X},(0x71);while true do if D>75.0 then D=(0X1c);d,G=Z[1][17]("<I4",Z[1][25],Z[0X01][0X3]);elseif D<75.0 then D=(0X4B);Z[1][3]=G;elseif not(D<113.0 and D>28.0)then else r=E:ti(d);return E.n(r);end;end;end;X[0X1f]=nil;if not Q[469]then q=(-4168569549+((E.ih(Q[2751]<=E.U[9]and E.U[8]or Q[28267]))+E.U[5]-E.U[0x1]));(Q)[469]=q;else q=(Q[469]);end;else(X)[32]=(function()local Z,D,r=({X});for X=123,0XEF,58 do if X<181.0 then D,r=Z[1][0X11]("<i8",Z[1][0x19],Z[1][0X3]);elseif X>123.0 and X<239.0 then E:_i(r,Z);elseif not(X>181.0)then else return D;end;end;end);if not Q[0x06930]then q=(2734425123+((E.eh((E.ah(E.U[0X5],Q[0X503C],Q[0X503C])),(Q[0X2e14])))-E.U[8]+E.U[6]));Q[0X6930]=q;else q=E:oi(q,Q);end;end;return nil,q;end,si=function(E,E,X,q,Q)if X==64.0 then E[6]=Q[0x1]();X=31;else if X~=31.0 then else q=Q[0X1]()-83651;return q,53476,X;end;end;return q,nil,X;end,mh=function(E,E,X)X=(#E[0X2][0X5]);return X;end,_h=function(E,E,X,q,Q,Z)Z=(Q[2][31][X]);q=(#Z);E=102;return Z,q,E;end,ci=function(E,E,X)X=(E[27343]);return X;end,Ni=function(E,E)(E)[39]=({});end,e=function(E,X,q,Q)if Q==44.0 then(q)[0x3]=1.0;if not X[0Xabf]then Q=-0X0074b7b8a9+((E.uh((E.Rh(E.U[0x5],(0X1d)))~=E.U[3]and E.U[0x9]or E.U[6],E.U[0x3]))>E.U[0X6]and E.U[2]or E.U[0x3]);X[2751]=(Q);else Q=X[2751];end;else if Q~=27.0 then else(q)[0x4]=E.L;q[0X5]=E.B;return 34269,Q;end;end;return nil,Q;end,Th=function(E,X,q,Q,Z)if q<=48.0 then if not(Z>175.0)then Q=E:Qh(X,Z,Q);else Q=E:qh(X,Z,Q);end;return Q,Z,0XDC07,q;else if q<=78.0 then q=85;Q=nil;else q=0X30;Z=X[1][28]();end;end;return Q,Z,nil,q;end,h=function(E,X,q,Q)if X~=22.0 then(q)[0xd]=(E.c.gsub);if not(not Q[25929])then X=(Q[0X6549]);else Q[0x2e14]=(-0x4+(E.bh((E.nh(Q[0X1912]+E.U[0X7],(Q[0XaBf])))-E.U[0x4])));X=-2215021813+(E.eh((E.Mh((E.eh(E.U[2],(Q[2751]))),(Q[0X0abf])))+E.U[0X9],(Q[0xabf])));(Q)[25929]=(X);end;else E:s(q);return 10767,X;end;return nil,X;end,B=nil,ti=function(E,E)return{E};end,fh=table,t=function()return function(E)local X=E.Humanoid;if X and X.Health and X.MaxHealth then return{X:GetPropertyChangedSignal('Healt\104'),X:GetPropertyChangedSignal('Ma\120Hea\108th')};end;local X=E.Character;return{X:GetAttributeChangedSignal('Health'),X:GetAttributeChangedSignal('Max\72e\97lth'),{Connect=function()return{Disconnect=function()end};end}};end;end,Mh=bit32.lshift,xi=function(E,E,X,q)X=((q-E)/8);return X;end,ui=function(E,X,q,Q)Q=nil;for Z=82,100,18 do Q=E:di(Q,X,Z);end;q=(Q/2.0);return Q,q;end,Qi=function(E,E,X)return{E-X[2][0XA]};end,lh=function(E,X,q,Q,Z)q=(nil);Z=nil;for D=0x44,0X12b,77 do if D==68 then Q[1][43]={};elseif D==0XDE then E:Uh(q,Q);elseif D==0X91 then q=(Q[2]()-36990);else if D~=0x12b then else Z=Q[1][28]()~=0.0;end;end;end;X=(0X2);return q,Z,X;end,Fh=getmetatable,mi=function(E,X,q,Q)if not(q<=91.0)then if q>=126.0 then E:y(Q);return 14373,q;else(Q)[0X18]=error;if not(not X[28267])then q=X[0X6E6B];else q=(-3812418524+(E.nh((E.ih(E.U[0X9]+E.U[3]))+X[0X503C],(X[11796]))));X[0X6E6B]=(q);end;end;elseif q==1.0 then Q[23]=E.O;if not X[0x1aFA]then X[0X6e11]=(91+(E.U[5]-X[0X6549]+E.U[3]-X[0X108d]<X[30856]and E.U[9]or X[0X002e14]));(X)[0x503c]=(-3916394916+(E.nh((E.Sh(E.U[0X8]))+X[30856]+E.U[0X2],(q))));q=-0X23aCe92A+(E.Mh((E.Sh((E.jh(E.U[0x5]))))-E.U[8],(X[11796])));X[0X1AFa]=(q);else q=X[6906];end;else(Q)[25]=(function(Z)local D={Q,Q[0X8]};Z=D[1][13](Z,"z","!!!!\33");return D[0x1][13](Z,".\46..\46",D[0X2]({},{__index=function(Z,r)local d,G,b,O,e=D[0x1][0x14](r,1.0,5.0);local B=(e-33.0)+(O-33.0)*85.0+(b-33.0)*7225.0+(G-33.0)*614125.0+(d-33.0)*5.2200625E7;e=D[1][21](">\0734",B);Z[r]=(e);return e;end}));end)(Q[15]([=[LPH?U7q\h\GuWFs8W,V5sbTJ63V47FCSuN!C=X2z!!!!c!cE>&$NL/,z63:;9639l-`!l\Hz!($a3H9qaDDJsX8"onW'z64@@BDKKH7FC0-8E+QQ[z!'iff3f9^3s8W-!631gf"^bVUDg+MN@X3',Y5gli0gYnc630tN!CK0S<^HjYH9q[UH9qX6631Xa!I7!4CdJ.o63LY&AT>Wlz!!!#;"98E%z631]:V>pSrz\GuU0!!!!)5XGK]63;IZ632!k!I$j2E4GrKz!!#=d;aLL[631%P!HUR.B0l`.?YjgN"E7dZCI/&%630bH!D'a$z!&-]*!Ck!6z!!!#0z!9g.B`'FA'z!($m4DK'#oCI/%r630J@#[^qKDf0&nFL_AOzn3=hnz!!!!c!`aP5#%hdoD..NQ!HLL/F*1qY#%qd]FCT!pz!8qc\_uTi<z!($]Q631O^oG%]U+<VdL+<VdY/R)Ed$6UH6+<VdL+<VdL+<VdL+<VdL+<VdL+<W:%,q(Dr/1rP-/hSb/+<VdL+<W9h/hAP'0.8%k-9sgK$6UH6+<VdL+<VdL+<VdL+<VdL+<W'^+<VdX0.8%k,pjs(5X7R],q(/p0/"t,-n$;b,pOWZ-n$_u.P*,'+<VdL+=o0!-mgPR+<VdL+<VdL+<VdL+<VdL+<Vd[.Ng>i5X7S"5X7S",qL/]/gr&35X6YC-71&d5X7S"5X6Y@-n6c#/hSb//hSb+,sX^\-nZVb/0cbS+<VdL+<VdL+<VdL+<VdL+=]#e/g`hK5X7S"5Umm!-m^De+<W-^-71uC5X7R],q(5o/g)8Z+<VdL+<VdL+<W9f.OZMf-n7JI-7U,\.P(oL+<VdL+<VdL+<VdL+<VdO/0HT25X7S"5Umm+-7Buf-71Au/2&4o-71uC5UIm+5X7S"5X7S"5X7S",:Y5s/hSb//2&>85X7S"5X7R_+>+rI+<VdL+<VdL+<VdL+<VdO+<Vmo5X7S".PF%5+>+lb/h\V(/hAY*/2&Y+/1rJ,-n7JI5X7S"5X7S"5X6V\5X7S"5X7S",;(3+5X7S"5UJ*+,mkb;+<VdL+<VdL+<VdL0-DAa5X7S"5X7S"-m_,'+=\]b.OIDG5X6PI-9sg]5VFE0/hA;65X7S"5X6VK5X6YE/0H&d/1`D+/g)8d,sX^\,9SHC+<VdL+<VdL+<VdL,9S*]-9sg]5X7S"5X7S"/1;nm5X7S"5U.m(+<VdX-9sg@5X6YG+>,!+5X7S"-7gbo5X7S"0.&qL,q)#D5UIm4/1;hr+>58Q+<VdL+<VdL+=Jlc+<W't-71&c-9sg]-8-nm/3kF.5X7S"/0H&X+<VdL+<s-:0.\G8-6Os,5X7S"/0uMe5X7S"5U[`t+<VdV5X7S"5UJ$.,q^;m$6UH6+<VdL+>4i[,;1Sm5X7R],:G2u,="LZ0-DQ+5X6Y]5X6_M+<VdL/1*VI-nZu&.Nfi[5X6eA+<Vsq5X7S"5U@Nq+<VdL+=KK?-7C>r/hSFs/d`^D+<VdL+<Vd[0/#RU-7g8^-mh2E,:jr[+>5u5+=nuh5X7S",:5Z@,pO]a-m_,*.NgB05X7S"5UJ*+,="LZ,:5Z@5UId'5X7S"5X6YI0.8;80-^fH+<VdL+<VdQ,q^N0,9STc5X7RZ+>5uF5X6VB5X7R]0.n@i+=o/o-nd&$+<W9i-9sg]5X7S"5X7Rc.OHPr0-rkK,:Y$*5X6_B-n[,)/hA=o.R5Wo+<VdL+<VdL5UA$0-6Oof5X7R].NfiV+>5',5X7S"5X7S"5X7S"5X7R]5X6PI-m_,D5X7S"5X7S"-7g8^-pU$_5X7S"5X7S"5VFZR5X7S",;(;m$6UH6+<VdL+=8Ed,paZd-7U,\+<W=&5X6_M+<W3`5X7S"5UJ-40/"t3,:FZf-9sg]5X7S"5X7S"5X7S"-m0W`-9sg]5X7S"5UJ$)-pU$E.PF%80+&gE+<VdL+<W9_.O.2,+>5uF5X6_?.R66a5X7Rf+<VdL+=\[&5X7S"5X6YK/3kO)/0c\g/g`hK5X7S",9ST`.O?Dp/0dDF5X6eA+<W.!5UJ-6-7T?F+<VdL+<VdL/g`5(,="LZ5X7S"/0H&X.OIDG,q^_q5X6YE/0H&X+=noe5U@aB5X7S"5X7S"-nZu#+<W=&5X7S"5X7S"-7g8^+<VdL,sX^\5V=Yr+<VdL+<VdL5Umm/,sX^\5X7S"5U[`t+<VdL+>+cZ+=KK?5X7S"5X6_?+<VdL+<W9d-m^3*5X7S"5X7S"5X7R]-nHJ`/h\h,5U@Nq+>5uF,p4fn$6UH6+<VdL+<Vdl.Ng>j5X7S"5X6YK+<VdL+<VdL+<VdL+>,;o5X7Ra/g`hK5X7S"5UJ$)/1N,#/g)8Z+>,2p-mg>p,sX^?+=09&+<W4#5U@O(,75P9+<VdL+<VdL+<W!^+>5uF5X7S".NfiV+<VdL+<VdL+<VdL+<VdL+>+m(5X7S"5X7Ra/gWbJ5X7R_/3lHc5X7R]+=nfe/g)8Z+<VdZ-9rk"/0bKE+<VdL+<VdL+<VdL+>4ie5X7S"5U.Bo+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+=09"/hA4S+<VdL+<VdL+<VdL+<W'\+>,!+5X7Ra+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<Vmo-8$ho$6UH6+<VdL+<VdL+<VdL/g`1n/1*VI5V+$#+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdT5UJ*7,75P9+<VdL+<VdL+<VdL+<VdL,;()k,sX^F+>5uF0-DA[+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL00gj:/1:iJ+<VdL+<VdL+<VdL+<VdL+<VdZ0-DA^5UA$*,sWe./0c\g+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+>5uF/1rR_+<VdL+<VdL+<VdL+<VdL+<VdL+<W-^+<Vmo,q^;m+=KK?5X7R\0.\4g+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<W=&5V+N;$6UH6+<VdL+<VdL+<VdL+<VdL+<VdL+>5Aj+=09"/0HE-5X7S"5X7R_+=KK$0.n@i+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdO5X6kC-jh(>+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL,:Xfg-9sg@/g)Q-5X7R]/h0+O5X7S"5X6VJ+=]#s+<VdL+<VdL+<VdL+<VdL+<W-d/gVu"-9sgI+>4'E+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<Vdl.Ng>i5X7R\/0HJs+>,oE5X7S"5X7S"/1r565X7S",p4fe5X7Ra+<s,u/hSJ9.P*%l,sX^B/g)VN+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<Vd[+<W-\5X7S",qL/]+=\cd5X7S"-8$Dc5X7S"5Umm$5X7R\+=KK?.Ng8p+<Vd[5X7S".Ng,H+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+@%/(+>+m(5X7S"5UIm1/g)8Z+<VdL+<VdL+<VdL+<VdL+<VdZ/1N%o-9sg]5X6YK/gq&L+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL-7CJh+<W9i,sX^\5X7S"5X7S"5X7S"5X7S"5X7S"5X7S"5X7S"5X7R_/g)Pj$6UH6+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdL+<VdX,;1N!+<VdL+<VdZ/hAP)/1`>'/1rP-/g)8Z+<VdL+<VdX0-^f2+<VdL+<VdL?!T$6$47mu+<VdL+<WuOBt43Dz+@&6p@<t6BEb02V#&.srATDn2!WW3#z63U_'@:Wn8!?a]0F@$%2H9qX&630_G!Hpd1>!`9hH9q[$H9qX7631jg!Hl<eAH3ACs8W*c!G"M$EcYo.Aop?CFCAWpA].EAD"do0!!#=h?XI>XG!Z4,63:_E63^q<DI[*s63:eG63:M?63:5763_=MD.7's630nL!_Rc*!_7Q'!F\:qH9qXP`!68Bz!5o-Cz!!#=d8jWPI631sj#@_UiCh7$m63_LQEbTE(6316"z!!!!aY5u06z!,t1i!H#d>z!!!!c$T][^A1K*53XlF%`'t[Gz!4`(0!!!#oO$H#:@rHL-FDQ96z!!"lA63U_'D/WrO"^bVXF^dZA?XI;OChuE@B6/3)\GuU0!!!!Q5XGQ^DfS/J?XIYmCdJ83?Yj:?!GK"Dzr1?5@#BFj'FCB9&\GuU0!!!!q5XGN)5=,Q]?Z^R4AO6DB\GuU0!!!"<6+Hsqzn3KABC3mDjz!&QsOz!!!Qq64.(,DIn$+DId='63LbBDfWAgz!'`_8"Cl+REk)/Mzn3B;@?U>!)?YOCgAU$NA63Lb+DIc':Anc-n\GuU0!!!!Q6UD/f?Ys@r@<>peCh5p??XInnF*)G:DJ.4H"p"](!!!!/d>eA6FSQ"B"a'8:"e?ZJr>5,@"a&]*"ipbB!K[IjkQ.O]\-?5MB8mB)"a&E&"\>KkVu^2N!N#nm"'s.[Nr]Dq"a'PB"c*D\!K[=fW!0%!p]k)9E5_ta"a$^G"_@mGAWR%/AR,J4!FfUDF<Lg!#07']fE#\t?-!&D!S@W_"a'PB"gA2FAR/jN"cWa@Bk:QRF@QM]"f;=Q#$hCBAb?K$")2=PAS59P"a#M#"U.Y4V#oQ\Bk:Ss!i?"f$!kUWV?*%b?0DHh!Pf"IAS:*."U0"G!<pOIV?)b\?"GG?%L'?CBk:SS"f;;;>nEk6O9T"3#,VF2#@4P7V?*%e>m5=_"eZ*7AR3gfScNC+L]_@&?.BIG!<m$<FQ!6(AS8sj"_@n"#\DWlBk:TF!i?"F#[IUUbQ.kN;e=blAHo@AA^CWqAR/kQjU;<K!GQ+N"a%9W"]Yg3"U-@Z?+9s5!MBI!+Jo0i"^M:Rli@:J!GQ+NAS:*5"_@mo#%^&6AR1r1V?(XA"a&o."fMW>AR,If]`Md/#AIaTYQq$+p]OlQ#GqO#"C21Q]E&27$#*sV"]K!/$K))%AR,I0A]4]>#&.XS"a$^F"eYsp!OrD@^]UG7Qj$cG"/Z*l$=1=Q<<Zq;F>3s_!bl4OJ-)SKYR"NGB?^efAHmYlA`s>4AR,I])$T41Bk:RU>d+E<"V4lBbmog9AHhQ)Bk:REPlYG"p]5)?>m5>R!sQIDV?,<T>m6Yth#V)c")2=PW!B1#TEni]#,VEg$=3E2V?,<U>m4bMXUPGUZiL?W"Ju3U!aXF[V?*=o?(_@u!T4&cn-#ThfE>I`F=.7M"Ju48#@1o"!L3flYQJTN?(_=t!LNsp"a!]I"Y"!dkQ>O1?,-K<!ItJ^n-,ZiL^IE6!bDPF"_hOR"a%rh"_@o-#\@+PAR3@\V?*V$?"IYs"_@nZ$"^mRBk:T>!N#mR$!k=NV?-Gu?%<-V!K[Unbl][(AHd12!sJ]*!!!!$8HiB,gPl@?FC>=VFBJe?#bV43$cO.jAL/K'3<]R4UB))5"Zll6"a'tP4Z#SJ%0RbA77%I)!<jtW73?[V,m>.q"U-@Z*@36?"U-pj*@4"%"9gBP!<iWa64JGL4Y-a?"b?[X/N#hE"9esNB*A;9z#j.*M"`tUc"`t=["dB$:/Hp56"W[jP"W`@!"Yg1&OT>UhFNFOe"Y0a.jW&O,*46V86%B(A"`tOa-'J?EJ-7.ucj(jK/gVeqM#e&;"`sbK/UK&q/Va?1(Bnn^"YB`$#;%Na!@9$<DCpAA/O^s;"Y0a.-'J?EJ-7.ucj(j+,:+WfP5u\S">uAD'n?E=74gAK%5!)5"a"Pa/OA:r"U0!<"T\T'!!!!,iJe!EFL_DU"a%!M"U-8J<<YGf<<[IN"U0"1!<iWS9iV@N!EB;'LB.RP!<mQ]"U.g>r<3o?p]M<8-P[pZ6'qfZ"`u0s"eYl72$KWRU&dC\TE.)B"eYmB9a,Vt"Z8U0"9g)q"U,(&!AZ51FA)iAH3FHU;[qOj%0i1#%0^iT"n`3YbmEbO"a'tP!<<*"!!PXl-"SqES;maVFKklN"a$^F"XQJEhuk&'JH@,$FQil2"ZZ_i"Xbl:"a#:r"]_;u'a4ag'jUtj9k@=K"U,'O#mCKSE<T@"!@:_d$<:(X/QFA+F9)PFD9)f*<=Mst#?>YAi!0E5<@%fj<!C)=Fp00<6%B(A"W\%(2*nGJ"U0!!"U/Hp7g3uf"l1/0r=6LG-):PV"U-8"'a8\Y"U-7g,mAC1"XQJEcikEmF<q*4JH>ua#R(A@#2fOt*MWW="U-7g,mAAk"U-df*@4#]a9EXf(F96,Mua(cAL6jI"`t=["XbT2"a%cc"U-mi"U0#P"XR+O,qWuT"!oN./arusDCscO"XblJ"`t=[76uG,"m5o0"Z7ku%DW0*6-oi?"W\=@"`uR)-)1JU"U-7g/N#hE"9gqSJ-6#ZFGp5(hu[Qu'a8]G!X/`?,o$T*bQ.lI1fXub1gNNbRfQ5h"`u0s4Z#S:9as79"AL^I%93j#cj'_r9Ec^L<F&le>t&<k%Hmn*RfQ5h"a%ri"T\T'!!!!/oo0+YFAW2FF@cW>-RC>J.g7NX!hTMO!Ykl\;$@+N'b(=gW<*5\/fc5A-T*1RFAW2V#R(AP6%B(A,sgGj"c3;Q!T4"g"`u*q%;mcE#8M,6cj-NNCFqCIF?p'6FArE$71Ciq#:)/a78;,6*<gNc"U-82%0\+J*<gPA!<kV=*@1k:4XC8R8HfQ@/^O`5T)mjO/Hp5d"^OjL#9<sq4UhQB9bdgZ>oa)j!<iXKG6L,u%5#p3,X":b727],#:*#<"a!uQ(S:`d!Y#<TKE27q&9Y)Wr<3XK'dNs)2['3^!!!!#*>o39NWfT.f`D<\FO:-n4\ai92;eN]4ZrsjE<V=>"4\$t%6Y[WhuZ&s!<oG)"a!lN74q"L4cob64U!>>4["u0/VjZq!71s64cob.238.j73r+Z6j;c[BJ_:EF>j@,.g8(!9n3@(huY/e4U#r4!X7K`BTW?B4\ai92$GK64U#pQ"U,Mr2;eOLA1[t,f`;6[-P\d56$NPjG6J.-!.Y20"a!-9"bcsl"W]mZ"9g*H!=]29F@cX!6'qo]77#9,"XR+O/N':(%0ZoWF9N,K!<iW1K`MVd'r(d5"U0!a"U-7g/N#hE"9gqSYR(IZ<!=Qo9qVe=,q]WQ/Y`=U"U-7g2$J)d!<iXKf)Z%,6%B(A*C8Tb"U0!\"U1+kT)h(YF;G)]z!!LH("U/u["U/uS"bdZuN=4h`"aU=U'eBLl"ah$g"`tgi!<<*"!!`R.&NN\l<=%TD"U0")!<ip8"U-JE/\hHG6+@"#,ub$g"`tmk/O9XG/HH:a%ANq5"U/uY"XToE'a61a!@7n,67otR4[HR["XRme,n5)&"V%4-'a4b_3<]ke!=]2AKE25[%ANq="Vmd5*<dIY!>PbaUB)YE"`tOa'r(de"U-@Z*@4#0!X/aL2['A,A-Mo8ScR(<N=Q$iz"3ZZ-"`t=["`t%S"`sbK"aU=U"eYl'%2CDt"U1_'"V(D>P6$pV[133;!!!!%"^MRG&E&QP"a#S,"U0"!#R(BRq$.',-QP&J-RCnZ-RD2=G6J.563YF2"a%!T"V$q%*>KS]"i(9NRfONE*C9qV!<mSu!<iWS*An!J,s;DZ,t.uZJHH&Z-RD1b-RDIj-RDar-RE%%K`PH_"XbU-"XbU5"Z?Nq"XbU5"a#k/"\!/0,mAi#"Z8G0"ip]r?3LKaUB)A="Xb<J"XbTZ74ol49p#H&,u#UY,pa-L<E4kV9hbe5M#dbhRfONE*C9qV!Y(V"*>KS]"m?*nFO:*mASMAX7;;u0"b?[X2*F80a8ml!"U-KQ!?D=IFE[m??3LKaUB)A="Xb<J"XbTZ"a$(3"[tjK9f7+u"[,0(#6b9Q9EcG'"jdA]RfONE*C9qN"9imC"\gQp,um88^]mdj<@(p;"i(=J/L=[+FQWZ.%@[A='cfUEi!(Jo"h4U[RfONE"eYmR!?D>cBa"Yf-$9A=-%0WF"W^$H"U,'\!<k>D63YF2/RASa/Y`=e"U/ui"YE%EJ-.Yq"m?%GRfP)U"a'tP-)1JU"U-@Z/HmL:2'mGM"YHJM*<cTo*An!J,s;DZ,t.tb,u"Oj,uk*r-!^[rJH>uY-RDb]C'>U]JH5p34[K=n!A.U]"YE%E^]lAI2'k,L!A,TT63Tm`-T*IZFPHm#-(=oU'cfUEJ-$1L!?Dmq63YF3%@[A='cfUEa9<$B!?Dmq63[,c%@[A='cfUEfE)MO!?Dmq63X:m%@[A='cfUEL^+BY!?DmYFS>k@"eYl_%0\3b'cfUEJ-.*m!=]29FK>KH"XbU-"Z?Ni"XbU-"a'J?"U-8"4U%JZC./:R,u"Pb_u^)oG6J.%RfOf]/Y`=e"U-7o2'k(B,m>YB75]8m"[,0Ua8ml:"U-KI!@9$DUB)A="Xb<J"a#\("g%hj`>[8:!<<*"!!i]6%1s`u)'(=%O9Gf0OV@s&FGU\8"XgtaeH#h8"k<VWFR]eDK`[#1"doZ#FL_qd"dB%m'(l8/FP.$*"_HcrYlP#MOTksmPQ?=:r;d(DJI;W%'o`7u"Y#]<"bd"O"j$fL-XDE-*=Ro/"Ut\*!gNfr#.Oi-!Y#@D!Moi$FA)kC'k%9Z!X3[K"bd#Q!At#a3sC<>"a%ii"e>d`!L4T%#Q5O7!W<JH&%*==!UUbi*q]Ph!<k+[FSQ@LK`\"M4Tu!N"bd!]FAE&D3<]QiFP.K7m/^#X"ml?`!C;5="lTT-"m#b2<!Dpqr;f2D"ml>7"U,'O49^E?67%Ekr;eO)!rW.R!^\3##E8dO-,9WeFA)l"!C;5="UtZ$m/ck\67%Ekr;f52O95(UHh@F<!<mQG"n_nO!<k[kF:e\5(L[K$!X3\N%0cD*67$:KF?]q[$"4"6!X3\6"pNNX"G$pI!<mSm&d8^KkQ^td%0jTLK`[5867%]pPla8uBE`KT"m#c[!@7mQ*T[=`!=]5um/[Y#O9G4W"a!]Ir;f3G#6jJqG6J0;!De4Hm/ch[CZPTa!<mR*"e>]]-&;^N<!@sW"Z?P_!JLSA-,9Z^!A9'-r;d'["n_m"FCYOYFGUG1blNS#"W%>anGre&#3Z0f!SJ*$o`>!l"`tmk"Xe`k!<jk,!W<$&2?iaS"`uj1"a'PQ"c!+om/d.d"a&]."U-9e!L3]i3sClN"a'J>"U,C$!\FR'PlfJ:Pla80!X5+r6+@%$V#ir5"9m`pFp4-4"ZZ_ijT0W1"U0S\jT,P3"#Jj?N<07nPl`68-^=`b"a"Pa"_Hcr`rQ?cYn@6!#&D`ih#R\$.0Tl&K`T^)"XhOqh#R[;"k<V_#2fX?!<mR-"U/ua"gnD<"U,&Wh#ZU<"ZlnL!<mQo"U-9=!i5r%-iF(J!X1IcV#gfJPle&h"`tUcjT2+W,mEB2LB.R0$3bOF!<iWSN<6Kh"Z?Od!X0sj!OVt4-_1=P!X0sJ!lY5K!aZ$6"`sbK"Xh7i[/pLZV#n=3"XgDR`<*FK?3LK9-cH+o!X0sR!keX=-_1=X!X3]$!<iY"!KmJK!X0s:!hBAr-g^r2!X1IcSH8t:j8fDfFLMAV"XgtaXTAYf"g%h0FO($m"ZZ_i%0l"uV#ggg!@=QD"`sbK"Y$8L"U1:p/YrLP-XEPM"Xc10!X3ZH"U-?_!X5D%9EggqK`\"M/Hl;>"bd!]FMS@h"Z?Ot!keZ)!OW!R!OVuGa9.D'[/pfF!q6H&!cGCIi!0E5[/u<h"a#k7"gnD/fE7*7"XcaP!X0s2!lY3EFBf"J!CA*"!X3[Q"oSHg---/lFQW]/"XdTh!X0sZ!lY3E.Eqnt"`sbK]`Lk2[fQ.&67'\T"a%Qb"U-7oeH,n%]`R!k"XfiBjT<s6?3LK9-QU_="Xh7jh#[a-SH@mS"`tmk[/pPo#JC2H!X?^J`<*FK#+,Y?!X3[+"k<Z\"U,&W*Rt2p-d;_K!X3ZH"U-9E!p'L6!aZ$6"a'28"gnC9.+JCW!bp0d]`PSC#*8o:!oO,oeH3\k[/pQ"!n@A1!bp0dblS&je,]^V-bTP7!X1XhK`VF"LB.P^.L"?'%0l;&h#RrhTE=3UjT1hOh#Z%,"Y']3!<mRZ"U-9%m/[A<h#[0L"Z?PO!=]8&!VHKd!>DC5eH#h$K`UiI"Xi+,r;d'["n_m"-[kpo"Xi+,K`VE9"oSJ`!<fJ)o`55<5m7E>*T[;*-f"gj!<jk$!VHKT!F>p5"Xf!)jT,N4h#ZmD"Z?PG!<mSH!<iXKM$F1f-bTPG!X1XhPl_,20*MM>"U,(&!@j?9"Y'\H!X3Zh"U-8ZV#gfJeH)cR"Y$h\"f28o"n)O&#1*FJ!X54tRK9MlXTFsmV#m1h"a!-9"XgtaPl_+N"dK,mFMnCf"ZZ_i"eYl/`;p,l"jI&W#3Z0>!SmcW"U,'O!<q9[LB.S##6f4c"U,&i"U,&WjT21Z"Y0bQ!X1Rf"m#bNJ-6#b#$C6n"`sbK%0kGco`>!l67%EkK`XReL]mYW/qjB*!JLSA-,9WeF9)RD!KmJ;!rW/u!J^[Z?NkQD"pG/X]`I3q"ZlnL!<mS+!sS>u6%B(Ad0+UrjT5;\5u7aP!I"\No`7B*L^!/H7I:-K!VHI[-("`;F9)R4!CcAVo`=^d67$=4!A=$Gm/cST:RD@R!<mR]"Ut[G!n@=j!GWVq"dB$(`;p-aaT;X5#GqNh!c8ANn-*rW1j(qj#4M_C%0l"tK`M@!nGre&#R(A@#-\1E%0l;+*=W4/"!n+m8HfP-YQq!*V#`EL!Bgkrp]7Jt"`sbK"eYm:[/gH(!D:$+"XbV8!=]73"3giMFMn1`%0l"u/HmU-2%9cJ"[*;!p]a/U1dsP:#07$D9f,R-%0iI-<E1kU4UhUg#@.cCJ-TXs1hAfR.Ks[N#GqMMD9)gV!K[A""a$OA"Ut[_#)rWm#)E;F!=]7;"e>[b!Ap>J4U#s"!<iXK`ruXC!f$d[cN=>mrs8i4AX*=e$O(Xr"pNNX"QTje!<mS3"pGG?kQB'2blX@8`<*FK"a%3S"U0#J!sJiUK`U99"Xi+,m/[AK"m#agF9)OS"q^/&jT,M3!UTmkFRKA:"_Hcrmg95?oE>C%3sF^H"XbVX!UTo_!=]4o!GWVi"XbVh!<mRJ"bd"m*>RZ:LB.SQ!<mRZ"m#bk"U,(&!F":["Xi+,jT,O,C]sti*T[;*-f"gj!=]7s"8)ZuF@6<2!M]Z1"n_n2*>J`*-%uD[!i#c:"U0"$!<iXKVZm;.-bTQB!<kOgjT,O,C^'2,:Oi`<!VHIZJ-6$OFp6t.r;eO)!rW.R!^\2h"oSHSK`_2R"Z?PW!<mR*"U-mi"m#bNJ-6#b#1s+H!=]6p"SDfo!CA)g"GHnD-&;^.FCYOY2?iIKo`7B*^]a$*7I:-K!<mS8!<iWV"gnE&!br`%SH=QI"j[8SF<Lek-RG;b"Xb%]!X0s:!j)M-F@699FNajkrsN6=V#ggBbR"FRz!>,OXN<KJ'%0ZnS"W\na!<iW1>9+^fF9`!:$DRX`*fUI,z!!Ci4"U/uc"U/u["f2_CKakF0@<Meh"eYl?%0\fs%0[mq"U11m"U,?$YQ=t;1^+$d.Kp7r6%B(A"W[ae,sd%a"U/ui"V$q%/Hl;h'bggn#mCKS-NsZq$j?Y3!!!!%*>K_8'#0G1"a"_f"a"G^IA6fX"U0S\I0Bdri;s1*UB(N%"bcu""U/u["U-mi"U0"I"pKFM!>PbAK`QT*I5H@("dB%u#(6YsJHZ2d6%B(A'r(d5"U0S\'a5UDJ-6%\#'L.Z"Y'[-2*p.%"[,/]"9esN!<knXJ-6&O"*Oi*<C,OE"^OF("9i@&J-6#ZF9)R("*OiJFe\sP"U0S\FTloC!<lO.F>!e<UB(N%*GP`e"f25'%0\`q"V%4-%0[KA!>PbAK`Mnl"a!-9"bcu2!<nG`UB(N%N<*bt%0\crI=7RcFY*c=d/jK"RfRX`Fe\sX"b!-H'a4bp!IY-*!M]Z!"bctl"UtWd!<mTT%"/;5!M]Z1"U0"$!<m&0!<iX<C'>%MJH5pS?)%E0"_FG0"U,'`!G)FOUB(N%D/'4`"b?[X?!Wp#<@q4G!=]29FBJcYUB(N%"bctg"`:"8"U/aX"UtWd!<lb7RfQM@"a!lN<MKR("^Rl("U,'`!F5j4FM%VX?)%E("U0S\>m4f7!<iX<C'>%MJH5pS?)%E0"U0"4!<iX<2.Ql4Ba"ZO<W<('F@QK<3<]QiFJf-CIA6fP"bcuP!>PbAK`Ql."U/uK"cWPX!>Pct!GVcI"b?[XI0F_4"m$+J[1^Fb"ZZ_i2*l`q"[/U]"U,'`!BgSiF9)P66%B(A!HnW("_BRC!<mS@!<mnH!>PbAK`QT*I>7h,NroQ-+U*:`!Hfu:UB(N%"bcu""U0!9"U/ua"U/HHVZ?sC[fQ^6z!>kp[N<Kas"U,?g!<iW1FThsA$QbQ>PoKsL#6b,.!!!!"!X@&3"U0!>"U0!6"U0!."f3*&!JMH"&ga"J%36`]"ip]jRfO6E%5](G"`sbK"Y0`s'aOsH"Y'Zr,shdF!X3Zn"T\T'!!!@#"[tFW0d.hl@1g>9"U0#,!X/aLf`D<\PQ?=<70RcV"\k`m,m=H6"\f/B(Bjta-O!5>!@7mQ3sA=^FMS%_2*qc9!sOni5qN7^d09bSUB)YE"Zllf"a&u4"U1P"JcTF/!DN_$PQ@HY'a8]A!<kW]!A+HY-OiL=%4-N-<KdG8J-6$t8Hf8F%96[C-%H,0P6!7c"ANV7,mAi#"[u.\!C[.q-Oj']64Kjs"a#e+"XR+O4[l+H2$H^L!BgSiFDM*aFMRt]"dB%U"W[bgi;j*>UB)YE"ZllF"a")T%1!+@'r(d5"U-7_*<gNc"XQJEW!*o["U,pA!>PbAF9)OK-Oh@R64Kjs*HqYj"bcst"XToE*<cTo%4sG(%B'F6F9)OkC)n;uPQ>,;"a%*P"\k`m,m=H6"\f/Bg]7RQ%6`VN"dB&0!]:.'G6L^9!@7mQ3sA=^FI<47F^>4TFe\t3"U-8jI0F`W!<iWS<IG#u9n`Uj?3LLTUB+'m"Xd#m"a"G^Fe\t3"U-8:I0CueK`Q=&"U,'OE<UK[!DN_$-QRU=-U!.aF^>4T"a!]IF^>4T"Xe/0"Y0b!"Xdl8!Hh]P"a-R@9a(\JAUO_0?%i:_FA)j\UB+'m"Xc`e"Xc0]!<mS(!X/`T<J:Hr?3LLTUB+'m"a#\)"]Z!Phu[0n2;eOI%7T1VD%.6<!X3ZH"a-R@9a(\J'n$65*JFN:?3LK9FG']!4ei$("U-sk4U#r2!<ok:7bnuj&d=L#(HhqD56V&f!!!!$'Es<o#hP%>"`tmk"`tUcN>&2jK`\pr,si()!sL1Y,o$[h"Ut[o!Z`"4*??/U!<jPKF<Lf>UB))5"XbTR"b-\-"`tmk*L?dQ"YE%MkQ:u**A%G:6j4;^/I_k6"YB`T!!!!$"VDIUkD]WKF;Y5cF:e\a%g&RGo`kYB!<iq-!<iWAUB(f-*C52Y"XQIE#mCKS!<ipI/L<!D!>PbA-RCVRF?'Ln6$NPjG6J.-:#H=8/M8n425:0e"U-7g4U#p^"[,0H#R)f("U-JPQjG?%UB))5"Xb<R"a"Yd77"]p"Z:K-"Z9$4#;n(c2(^\\!>PbA-Oi4-60JFT20T3-/M8n4"Y0a.$K?`SV'<%m5@tehMFUk-5FBqMmo-OR5;nLOe3J$B5O]N;&3%_h5IC*t.6kf.5P^i6rdjq*5MLum,o-Hbj$,m[0m[aE0-Sf7@U$Gh?$;.`F?nr4,-RjFe[YY[z.)<@nz!(4Q4zz\GuU0!!%OG^psFF!!!"L;S]gCzJ3^o\z!.[JQ\GuU0!!!!r^psFF!!!#7;SYU'TT4k-fNG`bz!&D@#z!!!#764?G3(6LR>8\(&o/b?LQz!)UJAz!!"ml\GuU0!!!!R^d8BE[:=M\"EHE)0"Cr^!!!"L;8B^Bz^f/$8"DF>Ue@>PZ!!!!a>/7ZKzJ4RJdz!!#^.\GuU0!!%OB^psFF!!!"L7DQG6zJ5<tkz!!"@]\GuU0!!!!A^psFF!!!"L8&.FsHRLR3JiHF:\GuU0!!!!W^psFF!!!#7?,/c6PpRCQ"VfNQd-A.Az!'.h]$kICSVW[^@%)TMr(.&9n51nlg>Q"u@z!!#0t63qA"gS:gO9rPT&zJ4dVfz!'jl+\GuU0!!!!E^psFFz;o#pDz!'n?1z!!#O)64sc9TU-$=pm/9qT.Kdi.3Np>\GuU0!!!!Q^psFF!!!"L6bp54z5[D19z!!#=#\GuU0!!!!T^d89."8,cTfqQ"Wz5Z#8,z!'jDs65/m:C,*]QX2@FlD-C\_;).^/(qBVHz,/CA_\GuU0!!(qb^psFFz35@ife:._$S+0krf_2iUz!'7p+z!!#@$\GuU0!!!!M^psFF!!!"L>/7ZKz!'J'-z!!!;?\GuU0!!!!X^psFFz&AYgVzJ5sCqz!5MUM\GuU0!!!!l^psFF!!!"L7_lP7z!#35Zz!'jQ"64#;tf7_`Jbmbl-z!!$0;63MQb=%g((zJ3q&^z!!#7!\GuU0!!!!9^psFFz?,3uNz!:[`i%'UKG3'SO30_M,)_EnUkoVTuM.Ud=2X[319.0WCS65<s41!S.>`DAa:A7DcM4iNs57"B`sz!!"Xe64(gC@EI?UiRFAa$`MZh%dr<;=SNi\64("U3_QEC$o@^iz!.[YV\GuU0!!!!\^psFFz*5K)bzJ5!aF$58X`b>Lg=,hA>L#Cq0(FRsVk63gU(dTD=ZZ`aA>z!5N-\63o&R921tg*5k/L>rf*Wq-b&k63[]BK!o=n\GuU0!!%OZ^psFF!!!#WDnrm`z!(t$n"O&oYM7ETdz8\hk:z!(=Uh&-j\4lCV!o6-").ArV@ue%#GYz5/=]/z!+`l3%5l)pk`,84&@,O/h'ol7z!&VL%z!!"La\GuU0!!!!f^d8>q>d-XNoU5qN\GuU0!!%O8^d8<q;>P;6UPe,!">H*U]"%e@z9u+:>z!+N`1#NY+],*5c=63c5GK4^>t649#"_f&5_2tMm"]"%e@z=27-+S8)(L<'h;e<(rr<e"3D2$^]"hch>Hi+Il=r$"IRAMmjGIoQdtIz!(Oaj%_[tT4;*^]IQI]/&?Kc[z!.]%(\GuU0!!!"7^d8D:;Mti#(*OFD:rKmEz!-Z/gz!$Gad65bTm$pOHPR3AjpjWlB-0I6.r;T9ar1F=uiz!'k\B\GuU0!!!!o^d8OdW0hLg)<E@s/ScI%Y.4N4!!!"lHGI&kz5]4BJz!+9KU649X'?+q*#-RL'b'1)a`C-iK"8?K=oqLWZ2s$MjeVQ@;<z^t@.%\GuU0!!(r$^d81nFWtWg#&iu>ap_@^z!.\n$63m=<bgslF,/f*4s8W-!s8PCk5:7Tog-OEj\GuU0!!)M7^psFF!!!!AD8=*;`rH)=s8W,0z!5N!X\GuU0!!%OP^psFF!!!"lIDEAnz@!KIR"^sgo/7c9kzi,lb$'fa8-I[K1`?WCrf*LdZk7D5)t2"![GO8!W?Aj^.374lEH"$r#>GX;OZ+f7R7+VLU33JNEIVj2VV\GuU0!!#92^d8@86[*PjH9AVr\GuU0!!&[*^d8K7!qF=2ctk=3EG_aT65GEREQ;4"P3hs9DD9&KV:95sD/`sr63dmJ[0[`]-,`UYs8W-!s8PCg3TW"C65RSh1Y8XK/:te?lMpI.rh'V%5kE#QYdj`6!!!"\I)&&W0nR,b,6dNNZ#6YJ63c+pp>Fm\\GuU0!!"Cn5e-jp!!!#7<kuX<_uKc:s8W,0z!&/Q264&V$8QST":E>5$z!75o)65&TK<B`PggFq'(n=(XA7/DdC63`>;nbG8c\GuU0!!)M.^d8R8&69lG"_s71$HVaQU[peYOOSs$_9*NSS3dT:K?],?^toA^RRKOK9:biI7mqYo64$>N&df*Y'#7=1#K>1gr#OGm\GuU0!!$DG^d8E,paga8gVqd%KLA-5/93?s.,-QPB=S!BzE59EIs8W-!s8W*c#:s723@;[.`$t]cs8W-!s$@1#/ROufDGgpX,eQ@a64!43Cm*`69eNsVzJ8N(g%9DG;PZ#AlM:q`1""-DE\pW3O:5Iia6>eX'fsq(_!!!!aAAG_UzJ8rB8z!8t:N\GuU0!!'f9^psFFz/jQrIzY]@NG$S\&bXG3MARW'P'\GuU0!!#8e^r2A:s8W-!s8TV0z^g=fC%5b>_dlJ5;YA"Obi'Y$Tz5]"5&#<WbWJ2LUM\GuU0!!#8q^d8?F_V??0:)#3=64\/8:J6?:dmeF>`S%j%I^oFY!!!#7@DKDRz!)LBs$Te8je)W3!;qL]G65\LDQ$/6>pa7dBHVCm:#*W$eFDGocA#_j%=8.c,04V3f%(Q?<!!!#7@_b;?JUYQT7j8Znd5h/ImYaC9nnE^.W2r;maSe_Q360"Af5/Bmrr<#us8W,0z!$Gpi64b_tGg2)85C&_!4:XLhej_t7Hrkg6IZ//tK8JCC64mB+VE*I.8"_ccY+_[/\D*$1#NbQ\_fIGL63rF_=2mdZM=<h;.r:YqG<c1P63M^"OLr%'z!+<T/$YbZCkBdQAM"5I+63<gX63^tLT"#i\\GuU0!!%OW^d8Ar8ubuSoU5qNLUikAR@0J2\\CHKoOqluqp]\:0A"jLjE;nfAnS\Q'^pbo84!`Eg6c\.nR$t%UV!j!$_;S3bU8EN)'M)465$#YEX*B>+gc!rTYA1a3A0#T65@clAmX*hV,2=e7Id2?f'+d%Y[\G8&H`J&EYnJR>0]?:-n5hN.H\R=rr<#us8W*c&6^0g1<*a-^16bu\"aJKbdd]R!!!!a<kq$7!sTue'Ag-#klP$E/2"k"pLcf/=U8n]BsBuHl')6PO`arD$#)3(.*?Wu#2dX[s0k#!z!$Ggf\GuU0!!(qc^psFF!!!!aB>DHDs8W-!s8W*c#,\MbXe&S(z!3gFX\GuU0!!'fK^d8469J5%*\GuU0!!%OE^psFF!!!"lDnn[I-U;"en#9_u.TH>afX1\Ys8W-!\GuU0!!!";^r4fks8W-!s8PCp;<sKFDfON]RpV)2JjKmN-8aqC]4[<Wl7b=e%,.R8Y"7U/'<>I]01$',j2DThQ",4(,%ed'rr<#us8W*c%(^c$8:S&6_GtY@_79OGz>JRcLz+Ci2R#Ure;TekLYD*eIU@cj"TEcS\j!!!#7Yh;9.$AYSAG86[uqbQFdz!0D9;63kWsP7a(keNsbS>*(6#-S]F2!pcO[cU%i0QS2dT*k;7N!!#9[dQk>Cz+E>1`!rr$^#ia=>7pA&TrB^[n3_Y9L63W@iPBA-;%TsZ^CM::I$M9W&?'/V`$Q7SH.Q^9>l_de?\GuU0!!#8d^psFF!!!#7=hqQJz!.2Mlz!.\@j63;qI64n87+'U<Y,2=sQE7p'j%!20Rz!&/E.\GuU0!!&['^d8Hm$tQ4L$8F+=_-59tz!!$-:63`46jC/D:\GuU0!!"-^^d8E]\#o1kHmJ%rRtnNSz+CMuO(#Qrapq8DmD!/_oZ!/k3,EF-J"AD,bS/">>643II@3:6L*9-q^\GuU0!!!#g5=,K?9RiYEz!'ktJ63;,R`#o!Ys8W-!s1&+0!!!"lI)*8mz!*m<+%Kd"^IM2.Q<;@"n,!.Hgz!.\t&\GuU0!!$DF^r1g(s8W-!s8U$Lrr<#us8W,0z!.\1e63umA<B`PggFpK-rr<#us8W*c(mH,[DbRl(ka8`h#I<$Ta2.3X2i:OWq*GM?DG!<.G8lkY/l]&A#bd>+J$C+(#XTL=J$pF@&j%/S>hHGU-4#^8lk9GE#HIU*Ye"F5#d=a&0Hqr]"[W:W.ma:Z!(%+)G`%BJT>F\C1p?_cz!0DQC\GuU0!!'f2^d8Bo0>Gnh_pQF734T"h!!!!a=2;?HzJ6'HP&AYmVU,fVTkM8"nGnD>JSO*L_-Q79t\GuU0!5M=a5XG_'5SMK,qb+I"zi+'Ph$HMs)U-fbU&=YXG%91Z(1C&$;P$Da@b@<jJfU"nI*>AW7+N?P<B0mHVpI9$=dGBH'E\:d?J"At5mskLCSS2t/$B<8pCF.P"Wkki)%.IOKG&2E#HT(PI%mgX;Qnuoq>J:9iOeK;cz!,')6%/nHQ@n"c4N`8n,<C-l@8e`VT63\rRR:p>G64!rVh*]lT"(t"g$je?9>1<@+Gs]OJ\O$J.5bT.l\GuU0!!#8n^psFF!!!",DSSRN8:T4YP!X:77/!hSea4s*W^6mGJTrWa64K%!NmGl%)AAH:HN#b3z!5MgS\GuU0!!#9)^pu6W1G^gCe%\3Rek5QKar<Y`U7?<4'?D#jGd`@&p6pCGgI%"VNidiBz!'jr-64W2ZY?M,Q-+u'+!`Dm&643CGWh`(ECZTg]\GuU0!!%O\^psFF!!!"\H,)`aETQeu5]J/=lbC@'mlJFiDZQ]X2s^M7RmIP)f1'X>bLsJDEA;)m!i<$0z!!$!6\GuU0!!%O_^psFF!!!!A@DG27=T`GZ:9[J[(J&bimYsb<2cT(%nESsPhRIS=M:iL663jr&SfQoO.(K<X!!!"\FMPiNs8W-!s8W*c&b_@XC+a"9Bo-1ZpV$f&O_[8oZSmoB`?I7,ZVD&Iq?3k;;ucmts8W-!656Hh^tf>^Ma]Gs,]h;SJa:pW(7.>nO5k('Ci!Rj\GuU0!!!""^psFF!!!!qGecWPK:M;]Q[1LD=LeD3!!!#7A\bhVz!+EZ0(-j0l-FPbJB0s-\h7fr#)Pbo>cG8:'%&L7>Sh0:B.4o-FrB^`EX3L_5kiB8SzJ5*hiz!2*l<\GuU0!!&+/^d8IV/&Mf'(i=?JO1HZ)/<AJ#5B8t5n3J]$h&&JECN4VhGWiQXc?3<u2jM7^ZW#e4g67em8oD]a-UJ0b37kNK!0>#&i^*fc[^[F*63Y68;IFOUz!!$3<64NtUjj]"rYIhn:!/A4uz!+9BR\GuU0!!%O`^r0<7s8W-!s8TV0z?t-p^c-4DUbfoFg647V;Eb]JBF#0^Ub!HHD=Hk;p,Wm&C+@6<gW;L`V`:peBzi+Kj9z!'kJ<\GuU0!!)M6^psFF!!!!ACVW7B!s0oe+mYgh64TT00_1;08CTqLD$5;G64YYmGLV>.-"*MS&-O<j_*SBKo&(-g<nbJ!rr<#us8W,0z!)R^O63pTagW\j,QNfb\8S]8r+"'A_V5R7F2u#9i-#jM`#I,F*nVE?S63uD(1^8BU]mi?ZE8I>UiQ='sWcTqH`#.OFz!'k8663VKW2B^_az!,unm65+fPfTN`tH)(fi!\GhP8'9rtCq0NG!!!#7;8>L%n6%qoA@V[?zBY_PVrr<#us8W*c%rTA-4f1ai(G^sq8ci$u63bh9)pe#N64;:=#-*X]G?Xq3qRHS+!!!!qEPOmNBTk?qO.j*&P1bT1f?HVp';deEE^?EHgR51M$bso;f%e1Frr<#us8W,0z!8qY.63b*,[LBk*63<pE\GuU0!!&[$^d8iNQR:"bWh^Q;eqhB-a;Zq+F*d3uFj!)\r7f._jXB1H2Afb0gpmCb!!!!aD88I@!rT?e64H_b4mF^J,X3RLY#N`XzJEtfP649TcdH4+:&[1IWM8].fs8W-!s8PCqNo_Q)L9tY=*pFQDDQlGFV6F`h&`k`%/TDO'P#fU)66\H'_*%X;n@8N!z;SYU(:9"-D6ut.N"hq\Za7_h(e49SGMYKLFQqSESh\GhYjI8I@Ep4E21GLFI$f8@3/X'tAa0)PP63\!7$;aS>64OX#r\9\IO1_&Ldp6dB64<@,S_LE#Z<XtQn@8N!z8AMb9zcu?e2z!.\Ck63=4'\GuU0!!#8_^psFF!!!!a?bj2Pz^fnOaz!8r.<65;Wf<J6t[.JTclHA+<>&iV7U"oP17?,cjDs8W-!\GuU0!!%Oa^psFF!!!#GEPOmC$?BrL"pG]m5#r.["gB3=0IjU5z+Deh[&a'&-jkbM%^S&Y2!fXR-!<p"6z^gFmfz!+9QW65#*Z%5[L-K4gc6gFt0'D'//U63fkKA%PYim^W;t!!%Q0bs4T)s7>X/SHG:3aXm[W^Hr>#Eb_3Er`45-_8WqbzTOYc("Ku?2?F^%9!!!"L>JNQ6*qHse)MuN_p[R[364:m/<c\be`OOQI0#T^Js8W-!s8PCi*tla\r,B3BE'4Q[UZfHZ%sg1(#UWHRTF<:AOIfmQ\GuU0!!#8r^d86C`Pj^/<'h&i\BWC;)]Ff)@I$-p`-q[cs8W-!s$@.Y$28$#L*[+9lBP;Yz!5MjT\GuU0!!!"1^d8@n,=*dg.*Om664CfJ0\*[L,DODOip=2UzJ7?=)z!8qb164#mXIlFtf`c=mB#_SGQn:kX'f=:k]!!!"LFhg<OrPoFs&E*,l8lR<-">!Rt3C3m7-#t0;\GuU0!!)M0^d8H`Q2mc/\\l;*&3?(C'$V9BX[X:efE^F4eW&Ud(UI2Rz!-!+s\GuU0!!$D>^psFF!!!!AA\bhVz5[;)k#CKB]b&E;7`"r@Ps8W-!s$@N:UR%P+qcaIYL?(CIT9Gk<?J8auP41dJfp'eImloHbEY=5M#4t4hOpu)t1EQfS*nJ9ms8W-!s8W,0z5S2L3`8:Oos8W-!s1&+0!!!!aEPT*bz5\RsDz!"a1d\GuU0!!&[/^d83Db.dE963j-H8[Wa<EOc&L!!!#W@_b;>WQ_\2W+kMN'<>%D+LqIP!!!"l@)0;QzJ5j<N(.)4(lhO`E(WR!c*ZoXXPk-G8Ta;W(&$d]fJ7r1u%t$12$f,Gu\GuU0!!$D;^d8Gu6elpY9S\tYrV9/S%N<B"q4/$$@.oUpI:pa6z!8r%963Z#'?cs-M%3FE,<X+;r&bZ1aK`8L^z^h^_P$9J)]b3B[P?dSh`z!.\Fl64M!63Nc^@.jTlr;$9S'z!.]7.63]F?p1pi/64\B"O9c4]\s!=Tq1Y5_JjKgK&E5GS.<Z<n[(-/:!!!!aFML3['pY;WWJEje87mI[T+!>eP(Wdc+aYt%`***>s8W-!s1&+0!!!#WAAG_Uz!,B;9&Y<u)oY(K2LLO/!$[O/41VpU%z5``]I&PR`i)\W`#hb`e,&q*p-rN<[2z5^^@6"uk&87bJ&6$U6!^(WK:sgE1]@65t+jl(9"fL-p<.$[t4C4i)/BR4ZO;V7@&Bb<cIKQqHJU4ebtD".3+4\GuU0!!$DD^psFF!!!"l@DKDRz&9,EO$Q\JM>I>%"O0Z&2\GuU0!!'fJ^d8MV5?E-]P`R2#\-!<Y-:/8//pB+K1sKZ'[g(WWTsP_)$T[J\&I!9#c%3PY64Nafc,&'H1TEfNj#pe\z!+93M`6ePas8W-!s1&+0z?beu9CpIYiF\#%a\hi)-#Y..T!nNUAZFKr8!!!!a@DKDRz+E,'+z!5NWj63R.8'UZE2zi,HKBz!5NEd\GuU0!!#8g^d8;(a7r$n);dad>Se%?*k$!l\GuU0!!#9'^psFFz<PZOFli7"bs8W,0z!75c%\GuU0!!%Of^d8HT/4WQQMSCjji,?0:z!5M^P64GT0g6g.,faBU98SRW[#G,Hgm@5.e65'(![Q7j1"<S@1+5oN7r<I4?\GuU0!!#8o^psFF!!!!a<5:g-OXAS7XeQ]Gd>:1#Uohi"=9CO>i]E'eNk^iG$1'h>mIc>/YqSKXUU>X/mr8X]VsGahS!0>+8)%-4%-#RB>XKN2lFlNGks>p`%4Q`=lDRtE9m86T0?ZOG$keul+Jb-\]STqI:UpH*!!!"LB>D%Xz!8tW&z!)RXM63RN+O!Rr>z!$H$l63m./Ar>^#7m[Xdrfj7k!Ohf[f$)#D\GuU0!!"-T^psFF!!!!QEko3czTPM?Rz!!!!a63W4L=3X9&'"2&0/,L\@3*[9oK3ZCs>pDEt$ZG&C`<cMM?mO(H\GuU0!!%OX^d8Cm(u8EB]*B]OcpA#n];TA74RP6s&DN%->:W#6\b=V=/\nT#(.&TDI.tAFi86TJWbD]jgE#nK`+4c*s8W-!s$?r0eUa#qKePh!g6FM"9(p=_64KDU','UQMf,c*V>QND#<i?W6#,jQ\GuU0!!!"/^psFF!!!"LCV[I\zJ5a6M%B]!q:_%Q'jY_m_KXsJT!8B^-HLct\#9Mg3C^,[9\GuU0!!$D@^psFF!!!"lFML3G-;#)%64>1n'-S.?8&a?jHUL1(68I3To0NiN3(,\e1]0)fB(NP5zi+]tn$E)Oq7W19Rft-$,%=9N^2LluB$;`uSS?KI'z?tR3bzJ=kX_\GuU0!!)M-^d8B-fq'u"@.'XcE'aWeej9k=N(L=&`d]#(N;c3Ue@>PZ!!!"lHb_rS\R(2ZNRR`/'ZB4/s8W-!s8PCpi7cnT&t/4M+9I)%GX;]D;Kl]V6nn7j`(U+0s8W-!s$@?,:urjF_VNc$e=7kR^!Il8L-c:m)=iZQCQ^7./Ls'(?iU0+s8W-!\GuU0!!#8^^psFF!!!"L=27-+fpM$jijf$h!!%QIbs4T4\QOHRNQgKh'KWD+HcX4Ys2"no$TQVF64A-(8lnHNL)eY"AYVR1WRea;\R"ER*3**O,pen,I0EYF=GHSceag6Nzi,c]Ez!.\Uq63K3[#O=\bpnPJIH):i[%4qn&64.Led%d)6>d@u.\GuU0!!"-R^d83SF`C%j6495OoPOr0Sb[+Bd^]>X!!!#7A&(DArm4IO3k=?,Q+MgSSl*>7z!,uqnY(Qu['*&"4zzz#ljr*$ig8-\-;p5<"/g-<"/g-<"/g-6i[2e,6.]D(B=F8!<<*"<"/g-<"/g-2#mUV+ohTCWs/P(=:G61=q(H3=:G61<"/g-:B1@p0)ttP\HW$6F:A3MF:A3M"9\o9%L;Zd"U0!n"U0!f"U0!^"Vl:d"Vldn"lTLdF9)OK;DeU`V?)2N2$KNO"Z?&XV?,<M2$GEd"U45nd/aCcGm+?TPQ;j@"a!TFN<E@;"dKc*F9)OK;DeW>"Ju4X!At%O!<k?2!N#nm!At$02$FFF"U,?j!<jPKFCta\F9)OKSH/mOfE.oN?o8+Y!<k@="/Z+g">p?32$FGZ!R2&2"r.?8)AO!?!<iW9S,jA_"pLY#JcZsc)JL3,"a!lN"`sbK"]@2]\/hFI3&Ll1!<k@U!i?!K#W2c72$FGZ!>XMs*I.elTGhMb'a:K9'a5>*!<iW1FThpL"TSN&!WW3#BF+Y=BF+Y=,QIfE$NL/,'`\46[0-I0!X8c3fo6.E#R(A@LB.RH!<mQO"bdj@r<g4O"`sbK"YqY5n,oNg?nDOH/Hr?^V?('V"e>Yt/\hLd!=17\.4k]<63Y^SjTl(K*u,Lp^^86e'aD`+'bsu@,S^cY!@=ZK"`sbK'j_%I"`sbK"a'tP!=Jl-zzz!2]_r!"/c,!"8i-!1!`f!&+]Z!$)%>!#GV8!1!`f!%nQX!&+]Z!&+]Z!&+]Z!!8Yk"UEqE"U0!V"U0!N"U0!F"oSs(jV*m]"`sbK"Yqq=fE%iML]oX>SH/mO^]^M8a9"4&.5_;-#^6FU%>4`c"U0#P"U/uK"U.d]"b6iT!?a6'SH/mOn,oNgO97?D.5_8<+q=;P%0k/a%1QQu!Y#;_"Wce3V?+1:*<i):dK(Z("_f8'"`u*q"a"Yd!>GM6zzz!($Yc!"/c,!"Ao.z!!!'#z!&+HSz!*0.$!*0.$!%@mJ!#tt=!2]_r!)N[r!)rt!!)`gtz!,;N7z!9aF`!9aF`!"!dR9pG`ZO9(:@L]L?Xk`#`LFHHS-"a#S%"U0"!!<o;(0BED7#R,;N"U.d]"b6WN!@Tf/SH/mOn,oNgL]fR=SH/mO^]^M8#W2c72$MD18uO0Z"]3GPa<I>\8r+H-"]-5$$H`MRi"R18:`[%Z"a'tP"`sbK"]@2]kQ[mbn-1`R;DeWV!i>u@2$KNO"Z:f8V?,<Q2$GEd"U1P"RK<p5UB(OS'*YiGRKFQ6:`Y?*RKZ=1*?>;[*S;k4#"mM]*<f7[L_0f4-NsZqPQ:pgz&f)B,+sncl1,_0W64O&d8koQj`/Op0s8W-!s8W*("U+o;zzzz!!!#;!!!!.!!!!1!!!"G!<<,p!WW5u!WW5s!WW5o!WW5o!WW5s!WW5k!WW5m!WW5o!WW3%"cr`kh2MRAFK#9E"a$F="U0"9!<iXKOT>W>!>C//`<$3b!<iX)70Tn!V?,T[70PnE"gA0-!JgkI"e>Yt7JI"_!JgtL"XukD*<q<J*?C+?L]WP@"Y'[-kQdsccjME/TE3IE27Ng(2(]hm"U,&W*>Ja#"U,&Y%0Znb"Vi%E"o&<+F>!du+TMKB!WW3#H3XEMH3XEMEW?(>$NL/,%0-A._#jZ;KEhJWL'I\YL'I\YL'I\YL'I\YHj9WOHj9WOIKoiQIKoiQ0)ttP+ohTC^&n?87fWMh/cYkO^B4H9?N:'+2ZNgX_ufu>J-Q&SJ-Q&SJ-Q&SJ-Q&SJd28UJd28UL^*n[L^*n[L^*n[H3XEMQ3RBiQ3RBiQ3RBiN!B=_NX#OaN!B=_"t0ri,QnAWMiIrM#R(A@LB.R@"9in8!<n/g1o1<9&I!7W"U.dU"n2Vk!Ji!Q"e>Yt/[,DU!FRJ_SH/mG^]^M8#V?3//Ht&EIK^Gi!r*ki"<F!5V%'@-'lt+G"b8%N"Vh2_i;j)c2?ag1KE25['g`@c*<gOn"U/uK"U.+B"n2Yl!FRJ_;Cr(A"Ju40!\FSH!<k':"Ju4`"t^!-/Hl=V!Mou('aD_`'cfTM'a4b_KE25[F9)OK5:m&[!N#m*/Hmm]"ip_A!FRJ_SH/mGTEh=pO9[?@.4k_b%L0]t]`f,TO:`4p%XnQr"a!<>-(FuNQj+:\!<m`PF9)OK;Cr'f!N#mJ"YBnK!<k'Z!N#n%">'d+/Hl<<!AO`m64L.J'aF.R'jr:%'po5T"VhcB!>VO;"`u*q/XuhVW!3tV("ab(#(?^j"`sbK*Lm-F:nS#,%2B%h"U2jSScKQ0"eYnM"<@Yq"Vh2_49Yg0z!!!#[!WW5]!WW5]!WW5]!WW4&!!!#;!WW5[!WW3%!!!#;!WW5=!WW5E!WW5G!WW5E!WW3B!!!!5!!!":!<<,V!WW5W!WW5W!WW5W!WW5Y!WW5Y!WW5Y!WW5?!WW5?!WW5?!WW5A!WW5A!WW5A!WW5A!WW5[!WW5[!WW5[!WW3'"9o2=#3h*N"U,&i]aY2Uhuj2g[13B-!saepQm'-P#F,ha!UUg.[2O`>"U,(_!<iW1%g;tC"U+l8aT2PK"b?]6%g),/XTj@^!ppE("pG&3V$P$J!p'U)%c%Bl%Hmkt!s5S+jUCem!Ykm8!<R-*!sJ`0[1'GN!gNo]#dk0Eck`G\]a"V3&)@Wt!X7*X*<MT4eIMN\!aj1T"U,&gN=6"#huoDj#.4i@!f[Kj"U,>>hur-HaoVdT!f[6Z$jQA/Qm&R5#1X,h"U"u4"ToJC"TT8W"U,&o!>GM6zzz!,_c:!"/c,!"T&0!!N?&!"8i-!"Ju/!"&]+!"&]+!"&]+!!iQ)!!iQ)!!iQ)!&4HR!$;1@!"&]+!!iQ)!(-_d!%.aH!!*'"!!WE'!!WE'!!WE'!!iQ)!!*60mu7JSFSPq@"a'88"U0#4!<nGq(8Vl@'ErRZ"U.dm"gA0-!K[OT"[>EZYQ^m)p]O"hSH/m_^]^M8#XnnG70P!4!<iWQ>dt[u"ZHVH$)f4c*Au1QV?,TU2'lQ4"U/uK"U/uc"oSpl!<jbqLB.Pb"a!$6"`sbK"]@bmn-#Tha8n^5SH/m_ci^-GVufBk.7FCD-P[p28-L:CF=.4qF9)OK;FLaKV?)2Q70T4_"[t,B!>%['.7FCDH3FJ[#*/cg'cdhh"Vkbm"W`@!"f)/&FJf-C!Diarzzz!"oV=!"oV=!"Ao.!"o83!:g6m!%.aH!#Yb:!"&l0!&X`V!$D7A!!rf/!%80S!%80S!#>nA!#>nA!#>nA!)3Fn!%n6O!"9#2!!!?+!+>j-!&OZU!!<B)!!io3!"'&5!"'&5!"'&5!-8,?!($Yc!;Q`t!/COS!(d.j!;cm!!;Hj#!;Hj#!;Hj#!;m-'!;m-'!<*9)!<*9)!<*9)!2TYq!*oR)!!WT,!5/@4!+u93!!NN+!7:cH!,hi;!<!$#!;m-'!;m-'!"'&5!"'&5!"'&5!:'Ub!-nPE!!WT,!;-<l!.OtK!!EH*!"927!"K>9!"K>9!"K>9!"oV=!"oV=!"oV=!"oV=!;$Qt!;$Qt!;$Qt!;$Qt!;6^!!;6^!!<*9)!!!?+!!!?+!!!?+!!Wc1!!Wc1!!Wc1!!io3!!io3!"oV=!&OZU!:1!l!:1!l!&joY!3uS)!"&l0!+u<4!5&:3!"K/4!%nTY!%nTY!.P"L!65'>!"T55!9a^h!9a^h!9a^h!9sjj!9sjj!9sjj!1a,j!8%8O!:p<n!9sjj!!`QB"pthQ((6[o"U/uk"U/uc"U/u["i1LR"UtWWM$X=p63ZQu%>OrfW=&lO!<iX)<<[mRV?+II<<\oo"]aI]V?)JX<<XgO"V!d%fE2Qea9<"^#4NuLfa<92(_$Xjfa@s0LB.Q#"`tmk*F-Z!,rIuu&HsJ)"U,'O1^+&)8Hf9>!<iW^<<Y(R!JgnZ"e>Yt<T!tV!Up4l"Y!FT"ZZ_ih%)f-"pG/\"UuIVTH,=1GngK/"R-1D"`sbK"]A>(J-`"Q^]IL>SH/mo&>fKL!EB:P<<XZo,mBq^BdFc'FJ/sDcie%t%5jXV%Hmj&#-\1='r(dM"Vij'%0^k<"U0DfBb_(7S,j)_!Y#@<!t>EUW<*5,F9)OK;H3m>V?+I;<<\oo"]aaiV?,li<<XgO"V!d=Qj*-dU]D26J-K^&%0^jQ"9esN!<iWk<<Ypj!JgnZ"e>Yt<Ibg]!U(M'"Y!FTJ-LHK%1T'5/HpY/IMJCV"a&Du"Vl;/"kY5;'b(U="kWnlGpNUtFQ!<*"`sbK"Ys']i!6+[?r[A.<<_:cV?-Gp<<\oo"]^@&V?,lk<<XgO"Ut[W#7VuL!>U+hoa$W[a9<:^FHHV."`sbK"Ys']fEA&P?r[B$!<lJZ.]*71,uk*t<<_1fUB)A='f6@/%0jlY%0^iN"U/uK"U.e("c+7t!O)c."e>Yt<Nm@<!MC`="Y!FT'c7CI".01>,n1;M*LI!6FK>NI-(FuNJ-H_mi$]>u-tsD*24O[VkQ21tYQG=LUB)A='f6@/"a%Za"Ut[?!t?!?!?D=Y1^sm'#07#Y-(FuNJ-H1!VZR+D"_e\\%72)&"m$0p'a9*lBb_'d662Es%:"E.%1R%u'b*h?*t<K1"V"_0*Xr92"Utoo!<jbY662Es"a$(6"jdco'b(U="kWnlGpNUtFS>h?%0jlY%2F.7"jdBd'b*$j!=e5o"a')3"U0"o!<p.VU]L-+Kc:Ie^]O`D.g6@cPQ@*P,mACi!<iXK!<iX)<<\HgV?+1-<<\oo"]^WgV?,TU<<\oo"]b==V?+I^<<XgO"U/uK"dg"h!Q>N+'1G^L#t78l7@5P.;EY3)(hlE%"e>Yt4nokk!Up^b"XuS<*F-Z!,rIu]&d9S*"U,'O]E&0>FJf-C"`sbK"]A>(YR[N2p]OS#SH/moLaf2%J/2,g.9-Nlj8m=@,qXBW"XO9n/Hp5."V!c5!sJiY"UtWW!<iX)<<]l>V?+I6<<\oo"]^'kV?,$[<<XgO"XQ8W"iqWs,om/2*sE*?"kWnd#1*ki%>4`c'b*JMQj!p'J-HGdFBJbNF9)OK;H3mV*i8r\<<\oo"]`&DV?+aZ<<XgO"V&<L"kWnd#06rW%0hV5%1Rsk"UtWWMua(cPQAf,%0^j<"9ef6zzzz!!!"J!!!!.!!!!.!!!!q"TSNC!!!!5!!!!p"TSOq$31(!$31(!$31(#$31&,"pNeA"U0!V"U0!N"U0!F"U0!>"cWaBXVq'S"`sbK"e>Yt-&;f'!>m*dSH/m?p]RGpfE!9%.4#-,?3LK9FfbrR"`sbK"]?WMJ-VqPLa48MSH/m?n,oNgO96d4.4#-$\H1n<i#)tB"bd'g#5ArC'g[WZ"U1P"\cWrVF>!du$NL/,zzzkR.@jkR.@j!WW3#kR.@jkR.@jkR.@jD?'Y:(B=F8)?9a;oE>3p!!V5="U/uk"U/uc"U/u["Vj=b('Ok`.0U.d"U,V\%>Y0&LB.Pj"`tgi]bm@Bbn?9`"`sbK"[=::J,uMJ?mPuI!<je%!N#ne![S"!,m=I:!=?.E"`ua."`sbK"[=::O929[?mPuI!<jd2"/Z+G"!n+",m=H&"]Z:'^^C;LFA)i=$31&+zzzz$NL/,$NL/,9*,(nQimBhQimBhQimBhQimBhz!<NGSN<KK-)$L1c&Hr>[#mCKS!<iXK!<iW^,m=RO!Jgn*"e>Yt-,9Y\!QY<g"Xt`$"cWPU#/C>##C-IV%:&ZS%0_4b%0^hS"U0#P"k<_pjT2b1!>tk;zzz!6bNF!6bNF!"Ao.!"8i-!9X@_!6bNF!6bNF!6bNF!$M=B!#>P7!9X@_!71fJ!71fJ!6bNF!6bNF!6tZH!6tZH!':/\!$qUF!9O:^!)3Fn!%\*M!9X@_!*]F'!&X`V!!*'"!6PBD!6PBD!6PBD!6PBD!-J8A!'gMa!9O:^!.t7O!)*@m!9X@_!!!4bNWfT.f`D<\FO:-n"a%if"U1+k_#Y8SFI<.5"`sbK"]?oU#c7WQ"YBnK!<k(M"Ju4P!A+I(/Hl<C!P&:9'a4c#!Ykp,*Yej#*sDgi!<iW^/HtnMV?)JV/Hq[G"YK3FV?(on"Xu#,N=@KT%0\*g'a6)k'bs"O"U/u["Vldn"fVP,FEn#nF9)OK1+`[n"Ju3U"YBm5/HtnNV?('V"e>Yt/Z8`J!U'V;"Xu#,r<u+('bplUm00$b#+-GH?mHI%"VMOb%3?6!"a#\("U0!$"U/uK"U-Y5"i(/9!FRJ_5:m&S!N#m*/Hq[G"YI4eV?+I:/HmRT"Ut_@"Vh1Eo`V)m#+-IN%Mag$%2B$o'b(l]"bd*p#+-GH?mHI%'mgB)"`sbK'o)en*sHb!"U1+kIh`\a(^1(bIg$!t!<iX)/Hn\B!VcdL"e>Yt/O606J1<,S.4k]<"U0kf(%)*i*Yej#A-JeF<8AI`!s'2<zzz!!!<*!!!u=!!!W9!!!oG!!!oG!!#4`!!";F!!!$"!!!]A!!!]A!!!]A!!!cC!!$"!!!"VO!!!E3!!'Y3!!$F-!!#4`!!!H4!!!uI!!"&K!!"&K!!"&K!!"&K!!%oW!!#ao!!!K5!!"&K!!"&K!!"&K!!!00%MBNq%@)qW"a&u0"U0#,!<iXKf`;6[F9)OK5@k#&"f;<f"D%`lAHf:AV?*%eAHbtC"gA0-!T42o"e>YtAXEUt!Jgtl"Y"!d'aBHt-.NC6!QYW@!tCb$25g]_F9)OK$8j[US,kdO"s'377ApCoF9r*SFThqC67&i;9a:(f9iXK8"pJ9uL]mrN!@7mQF?B^1AL4kg"a#S%"U/uK"U.,%"V@O3?tBM4!<m'("Ju4`"(_WbAH`6`"U,&Z"n`BH/-Q1\3X$65#)EF'*<t^7,m>;8,mAAk"Ws?;a9!XkF;Y7q$?l(_[0$Rm"U,'O*sDgi!<iWkAHfRKV?*%eAHeV*"_I0?V?*%eAHeV*"_H$bV?,laAHaMo"W[g2$5E^bPm/N\DC*@*/O>0r"Z8T]'*[P"Fp0/qIg&80E;]kB70^O>73)Tr$;C\G;$@,F!<iWkAHbW%!T3ui"e>YtAZ,^.!@VL_.:iZ'#3ZDJ#sC+677CJ6%RgPCHj'[$4]OpW"U,'Ok5b_iFS>e>!<N6$!!3-#z!!!#=N<KK."U,'O#6jK/Q3#5=m0s(>zzz!!!!M!rr<P!rr<P!rr<.!!!!2!!!!3!!!"d!<<*L!rr<N!rr<O!!!!>!!!"b!<<*J!rr<T!rr<e!!!!I!!!"b!<<*u!!!!P!!!"c!<<+.!!!!X!!!"d!<<*L!rr<N!rr=D!!!!d!!!"`!<<+V!!!!o!!!"a!<<+l!!!"'!!!"_!<<*D!rr<F!rr<F!rr<F!rr>;!!!"3!!!"_!<<*J!rr<L!rr>O!!!"=!!!"]!<<*H!rr<J!rr<J!rr>e!!!"G!!!"`!<<*''`nRN$44J-"U0"q"U,'OaTVhOFMS+a,mK/R/M2_Y"d&ljFHHV.h#SkY'u^:ZF9)OK;FLcY"/Z)A70T4_"\%>MV?)JX70P,/"YILj--.86-RCVR2?bZaLB.Qm"a&u0"U-mi"U0!>"XOA?"YD<]!<n;]"`sbK"]@bmVuigsJ-A@FSH/m_O9DE]J-8:E.7FCD&0D&ZFThpP.g7L.F9)OK5=G_eV?+I870T4_"\%&FV?,l`70P,/"XOBJ%fHP_LB.R0!<mSC!<io:W$X)J>hBK;,mK_?4U#p."YFp%"YGK1"\Al>56V44!<iXt!<kor"Ju3e"@WKb!<kp%*MrkI!_!8A70NiB[0S>fFNaahbQ2,U'a8]A"9esN!<iWk70Og2!FS>";FLa3V?-Gp70T4_"\#p+V?*=l70P,/"V&-GW$]1_'o)enmf<T6!<iX)70V$>V?%f."YrLMciU'F?pt6i!<knWV?'4V"XukDKb&8OTEPKB,om^o"hXj>F9)OK1.;Af"Ju3U"@WKb!<koZ!N#n5,t.td70WVt65>ji*<ql9*@4#eQieW=n-pZaS,k4?"soB4/L:RB+U&U:!=]2I64K:c*MWWM"U0!F"U/uK"U.dm"m?8i!MCW*"e>Yt7=Z&K!LO<b"XukD/LUc+/Q;l_%>Orfmf<T6=TntN!<iXt!<kp]';bed"[rTc!<kpe"/Z+W(.ABU70OD@`=E+U:^uV5SHo9+"V"_8'Fb4fZiUC7F9)OK;FLbf%Aj/V"[rTc!<koB"/Z+?*CU,\70Nj<cN==SFI*"3!=/Z*zzz!/^aVz!"Ao.!"8i-!!*'"!/^aV!/^aV!!!/MN<KK-+U&$k)$L1c&I$Ds.\.33#mGDO"U/uK"U.dE"c*D\!Vc^:"e>Yt*V]c7!S@Dn"XtGq%1!+@"n)I$'a6Z&'a8^`"T^@Yzzz!!!<*!!!N0!!%cU!!!E2!!!E2!!!E2!!%ZP!!"GJ!!!r<!!&5b!!!E2!!!E2!!",F!!",F!!#:b!!"GJ!!%]S!!!E2!!!E2!!!E2!!!K4!!!K4!!!E2!!!E2!!$L/!!#(\!!&,_!!%9E!!#Lh!!&5b!!&,]!!#gq!!%]S!!&bo!!$(#!!!$"!!'8(!!$[4!!%]S!!!E2!!!E2!!(UN!!%$>!!&5b!!!K4!!!K4!!)<b!!%cS!!%`T!!!?0!!!?0!!!]:!!!c<!!!i>!!!i>!!"#?!!&Yl!!%fV!!!W8!!!W8!!!W8!!!Q6!!",F!!",F!!",F!!#js!!'2&!!%u[!!!uB!!!uB!!!uB!!!F-(_@A_"pbW*5WB)[p5T:[FSQ%C"a'8;"U0#4"9g)s,m>TM!<p:F"`sbK"YsWm#c7Wi"D%b-!<m'0"Ju4P!G)E`AHfIMGpNVGGpNVGLB.RP"pK,5!<iXk!MK]D"a&u0"U0!>"m$eX!OWU&%g@%U"U.e8"kX!U!K[\#"e>YtAUk#_!K[@o"Y"!d"XaaB"`bn@,sg/d"U0!i"XSp)"mH$kFGU#%"dB#o,mACq"pG0P!<iW^AHg]jV?*%eAHeV*"_EJlV?-GnAHaMo"cW\(*RP#oFK#?G"dB$0*?@Gm"9esN*sE[O!A,T$FJ/g@*Lm-VW!3EIT`bN&F9)OK;Ip$A!N#l_AHeV*"_Fn=V?*n(AHaMo"YE&HfG)",1,T4=K`O%72%;F!"Z;bM,qT:B!<iWkAHb>r!PehL"]An85c+SW!bDP+!<m&U#c7WQ'kIOtAH`5V-1(^:-RCW-LB.RN!<mS5!X0%'!@=*;-&2L)rrE:F!<iX)AHg-kV?)2NAHeV*"_B*Z!LNn!"Y"!d"crb!"U/uK"U.e8"fMR$!T3ui"e>YtAWS79!MBR,"Y"!d'lF0Y*C9r!*[RQ^"U-JD(^2c_fE;@(<!=9GFL2&P"a!$6"`sbK"]An8QjonnTEAa/SH/n*p^F##fE>ah.:iZ'=hk+C"Y0`s,sg/d"U0#J!<jK0i$\a4FO(!l"`sbK"YsWmp`QF7L]h8mSH/n*kT-N$n.T@:.:i\=$oBgf"a$@;"U-7_2$I21,mAAk"U1Ft"_FVAV?*%eAHeV*"_E2dV?+aYAHaMo"W\ZG#ot%A!<pdN"a$gH"Z8Tu"9g)N"W\&B!@=*;-&2L)Ig'p;"W]o5n/`mN!<iWY5o9b/FA)iAFH6G+'q>:NW!3EINrfKp';bed"tc2TBcSep*,,j6"a&,m"U/uK"U1Ft"_Ec8V?+a>AHeV*"_HU$V?,<eAHaMo"U/uK"eZDd*Om%g:WOh^<=Mst$jE1&"\nbABiRk2SH/mgL`iPqYQdf*.89t'S,jq7"slOB$-3?'$7-u%.KqCeS,kLG#)Ee(2(\uRe,]^V2?bC,S,k4/"tbT2"lBCcFBJbNF9)OK;Ip$Q(o@><#%[t/!<m'(+/T).&nM4qAHbLQ24+U3$Y_IM9q25AQj0c1Bf.IGFF45qFRK56!P8=3zzzz!5JR7!+lH9!+lH9!-AGG!-AGG!-SSI!-SSI!#Yb:!#,D5!8mqZ!5\s@!58[<!58[<!58[<!;6Ts!;H`u!;Zm"!;Zm"!%J3R!$DLH!$DLH!%nKV!%nKV!([=p!([=p!)Nn#!)Nn#!)Nn#!"&l0!#,V;!#,V;!#,V;!#,V;!#>b=!#>b=!;m$$!<*0&!!3B*!!3B*!9aUe!9aUe!9aUe!9aUe!,V]9!'^G`!6tZH!1jDq!2'Ps!29\u!2Ki"!2]u$!3-8(!3-8(!([=p!([=p!(mIr!)*Ut!)*Ut!9==a!9==a!;6Ts!;6Ts!20Am!)rpu!4;n/!36)"!+#X*!0@9_!$VXJ!$hdL!%%pN!%8'P!%8'P!+6$3!+#m1!)Nn#!)Nn#!)Nn#!!EH*!!EH*!!EH*!!WT,!!WT,!%nKV!%nKV!'gbh!'gbh!<**$!<**$!<**$!!!0&!!!0&!!!0&!!3<(!!3<(!9aUe!:0mi!9sag!9sag!;ult!0@0\!94.]!6>BF!6,6D!6,6D!+lH9!+lH9!,)T;!,)T;!."kM!-e_K!-AGG!-AGG!'(&[!2BMo!.=nK!;ls"!;ls"!;ls"!<**$!<**$!9==a!9==a!9OIc!9aUe!9aUe!%nKV!&+WX!&Oo\!&=cZ!&=cZ!+u<4!4i.1!/UdX!#,Y<!#>e>!#Pq@!#c(B!#u4D!"oM:!"oM:!"oM:!9++]!;HZs!;HZs!;HZs!4W76!4W76!4iC8!4W76!4W76!1<if!7CiI!4;n/!,Ml?!,`#A!,`#A!#c%A!#Pn?!#,V;!#,V;!#,V;!6bZJ!6tfL!4r73!94%Z!.Y.O!"9)4!"&r2!;6Ts!;6Ts!;6Ts!4W76!58[<!58[<!58[<!6,6D!6bZJ!6bZJ!6tfL!6bZJ!6bZJ!9X@_!;QTp!3$&#!)s1'!*0=)!*BI+!*TU-!*fa/!*fa/!!*-$!!E<&!.k7P!2p,&!3uh0!42t2!1X8o!1X8o!1X8o!#G\:!$D:B!2'Do!($nj!(7%l!'gbh!'gbh!!nqmFb'PsO9&?Y,p_]8"U0")$j?fVJID\cFSQ:J"a'8B"mm7BPnp2%blN"l"U-9u!C[H&n-.&;"Y']3!U'cc!RN:O!<mT(#R(BR!<iWkSH8tF#GqOS"e>\u;OmjmJ-VqPO9V6W"e>YtSH9(o!K[DS!X1$D!X7cm8;J\="J>gn!Jgs9!R1Xh"U,&WblNe)"a$^J"U-@Zh#Z^EV?)J`h#X/LV?)JVh#R\$M#deT"f;=q#i,O+!I"\N"XhOq/IbtS"jI&OFQ!K/blN"l"U-9u!Gr9NL]Pa$"Y']3!<mT($j?g-!La&.!R1X3*V]la!=#JKblQ&i>_iI+!<jqVh#Z^EV?,$_h#R\$_$U@M#GqO;,M`Bn!i?!S%c%-hTE3aJjT,O,fa7oM!C>?_"n_m^Qj3d0($,H""a$F@"U/uK"U.,]!X7csV?)b[SH8sMSH8uY%Aj/^"e>\uSH/nb!jDg)!QYhC!X1$D!X5\:>_iEo%L"<ch#Z^EV?)2rh#X/LV?%Oi!O)g+!Jgp8!Uq>2!QY>u!MBLk!SAaT!<o+sM?;l?"a'8B"V"`+"jI&O.L"W/kQdsci"+WETE_7o^]WBn"a#e,"jI'l"U,&WblJOg>_iF*!<mSc!<j3o!Ta=cm/]N""9nH!621fk'c#g2"U0"Y#6b9Q!<iW^SH8tV'rD"f"e>\u5FhiZO;4VnO91sS"e>YtSH?k8V?,T[SH8sDSH8u&#[E/dSI#HL"l04C#GqO;-J\]q!N#l7h#X_bV?,<Ph#X/MV?,<Ph#R\$k5b_iTE2%qjT5,[C#oBO!R1Xh"U,&WblKs2FP-^!"bcuZ!<jc;[/gF7K`SR^"U-?g!<iXK[fQ`X!I"\N"XhOq2%<g["jI&OFNFgmSH/r)$_7<h!="VuSH7XnBq59i!PJmDSH/nb!=$ULSH/nJ!M'5pYU?:KL^'CN"a%!T"eZ$5jT40<"eYnE#3>lq"_m'!h#R\$PQM'mF9)OK17\IMi!lOa(nC^3;Omjm^^$_;O9_<X"e>YtSH@^nV?)2kSH8sDSH8ruF9)QD+\RdrTF?e]:S8/V!f[6jN<4nB"Ytc5"cs:0N<4e8"e>YtK`^0=V?,TaK`\@_.>7g,h%!]Z"jI&OhZ3o:!U'cc!O*3m!R1Xh"U,'OaTVhW>\M@_"Y']3!U'cc!Uq)b!<mS`"9et%!BT<C\-6U.!Sme$!F>p5"a$pM"U/uK"U.ep!X7KjV?)b`SH8tc!<o"qYQgs*L_-*Y"Y#uD"U45n"bcs\.Kte4r<i^m!<n_h#07"6!<n/XPlV&Z!LNnI$j?fV]E8<H>\M@_"Y']3!U'cc!N6ml!>UCkjT,MgFH6M-"Y']3!U'cc!UpKQ!<o+s_?As$\-6U.!Smb[FK>TK"`sbK"[AOZ"dfju!S@RH!X5+q"e>^N.Ad,r(7bL1.@gMD%:"\iblItt"f2an#GqO++Pd'k!N#l7h#X_bV?,<Ph#X/MV?,<Ph#[9SV?-Gth#Yb$G6J-R-d;Z<"a$XG"U-&d%0\3bFTj5uI0F`J!X0$<n-.&;"Y']3!U'cc!T4=@!R1Xh"U,'OklCqkF9)OK5FhiZL`WDofEIfI"e>YtSH?kMV?-05SH8sDSH8tf"_m'!h#X/QV?+I7h#Yk4V?)JWjUMH90*MNP!Vur\!Or;IjT40<blN"l"U-9u!=]3SPQM'm-d;[?"a'tP"`sbK"YuVM"dgU5!K[AR!X5+q"e>^^-`-pS%@mP(.@gMD\-6U.!Smb[TE1bjjT5,[C#oBO!F9mQ"U-9u!?D>cZi^I8-d;[G!=`<'"jI&O.L"W/"a")T"XhOqFU_UF"jI&O.L"W/kQdsckS`1WblN"l"U0"d!<iXK!<iWkSH8tN'W(o`"e>\uSH/nb!l,SK!U()c!X1$D!X7cmV?-/uh#X/LV?%Oi!O)g+!Jgo]&+Cg@!S@P2!MBXo!Pefn!RM=R!Jgs9!<mS;"pOr+5,A8`V#^df+Jf+P!ar,2"g%e0a9JaI"a%ch"h4_MjT40<cjloRL^)Z9TE_7o^]WBnblN"l"U-9u!DN`>U]^i)F9)OK;Omjma:"jG31U*SSH/nb!ltbH!S@IE!X5+q"e>_!&>fJY&tK(-.@gMD"`sbKO;&Lu(l\TV!f$d[$&o!PfH18#PQ;)M!f[7IfEqeA!`-ldN<5(@%?1G)*!JQ\!X6poBoN1J!X5+q"bd$A&uG]N$\\WcoDu&s"U-@Zh#Z^EV?,<Xh%-._V?+I7h#Yb$G6J-R-d;Zt"a%3V"T^%Pzzz!!(XO!!!B,!!!B,!!)Qj!!)-`!!)-`!!)-`!!)-`!!(jX!!(jX!!";F!!"&?!!)Tk!!#4`!!"AH!!)Ni!!#jr!!"VO!!!$"!!(dV!!(dV!!(dV!!$R1!!#(\!!)Wl!!)9d!!)3b!!)3b!!"VS!!"VS!!"VS!!"\U!!"bW!!"\U!!"\U!!#1c!!#1c!!#1c!!#1c!!#7e!!#1c!!#1c!!#1c!!"\U!!"\U!!"\U!!"\U!!&hq!!$+$!!)Ni!!!NT-jBe]!Y,bM&hFeU0batbNWfT.YlY(4FK#<F"a$F>"f3)l!I`2r"`sbK"]A%u#c7X,##,8l!<l35"Ju4@!_ihI9a(\L'a5%t!?IO3*M`]V"U1+kR0"B4F:e\L#(?^b"a"_f"`sbK"[>]bfEJ,QL]gEU;G@>I"f;=Y#>GAm!<l2"V?)b[9a)t?"Wa?='a5WW!Vd].$S=Z#"U,oj"U,'OR/mHpFThpPF9)OK;G@<+V?+a?9a.'g"\mVNV?,l`9a)t?"V%j?"[iN9-NsZq!<iX)9a0GVV?,TU9a.'g"\mVRV?+109a)t?"V';h"U,Wd"U,Wr!<nD_"a#4t"`sbK"]A%u\,iH-^]I46SH/mgcj$?J^]@.5.89sl7i_aZ>f\!52*rUf&iEpm#;l[X!Vume2/3:8-$TRs%@dGFQj+jl!<n;\"a"/V2-d'b2$KWRl39[7C'>V(GQe6sGo[&7>f\!52*r&1&2d^k#;l[X!QkU82/3:8-$TRs"`tmk-$^L7-!\M5,rJ"(a;bA*KE25[F9)OK1/.qV(o@=A9a.'g"\jdsV?*Uu9a)t?"n`:9"U,'OpAkEu'`\46zzz!XSi,!XSi,!XSi,%fcS0%0-A.K*2/S!XSi,*rl9@(B=F8Jcl&R"pk80#RLJ2#RLJ2/-#YM3<0$Z,ldoFL'.JV!WW3#!XSi,!XSi,;ZHdt0`V1RLBISW&.&=:&.&=:&.&=:![IsTpl,F\FJ/a>"a$.6"U0"1!X0<a"U,'o!O2Y?"a!$6"`sbK"]@2]n,oNgJ-@e6SH/mOi!#tY#W2c72$K'FBcRolQiVa="U/uK"U.d]"aHmFYQcrgSH/mOYQ^m)J-Rq8.5_8<f`;iG"r.?("Vhc*!<iW9S,jA_"pLY#iWC2)F>jAg)g[J[2&1B?"Vldn"UP?SYlP"3F9)OKSH/mOkQIa`(c;Jf!<k@M"Ju4`"#U622$F/+SH8s(#R(A@LB.Qh"`tgi"`sbK"]@2]YQ:U%Vu\aZSH/mO32Q`7!]:-12$FGZ!>XMs*I.elO9Jr2'a6$$"Vl[k"U,'OZiL=6FDM*]'EA+5zzz[K$:-[L*!7[L*!7%fcS0&c_n3=p4m+!WW3#.0'>J(]XO9=Tnd*ZjHd5ZjHd52ZNgX,6.]D>6P!,8H8_j/-#YM>Qk*-\dAE;]F"W=\dAE;\dAE;oEkQuoEkQuB)ho33rf6\HNaBL"UGYJ";V7BN<KK-M#db`FFaGr"a#"nSIQe(%tt],LB.S3!X3\>!<iXK!<iX)2$L2fV?*n*2$KNO"Z<LfV?)JU2$KNO"Z>3AV?-/g2$GEd"V(5-o`h?!*?6)]*M<UN*>Ja"-Nsqb"U,("!>SE?S,jY/"pK)L"W\R'O<'tuBcRp'S,j@$"`u[,"`sbK"]@2]0W"l$"Z6IS!<k@5"f;=Q!]:-12$F0`!>,J=FThpPF;+l^F9)OKSH/mOO9_W`?o8+Y!<k@E"/Z)Y2$GEd"XTZ>XT\+o'aCTM'buB&"W\nZ!>Y))"eYn-"<FESBcRolFE@[$Go[&'LB.R;!<mQG"U-Y="h4f7!Jgk9"e>Yt2:)N(!Or.f"Xu;4-(FuNn,_>JGo['e'58I%"a&N#"T\f-!!!'#!!&`!!!&`!!!#Uk!!&`!!!!H.!!!T2!!#t$!!!$$$.Y"="W8$YJ1HNY)&3<s#mK]"V#gN5PmIV9@0HgV!<iXt!<kp]"/Z*,70T4_"\&1hV?,<M70P,/"XSEt"U-7_/HmM]$8i!/!<kV;"U,(+!<jbQFX71l2#mUVzzzkPtS_$NL/,$ig8-MZj(\-49eR-49eR*rl9@'`\46SHSun4:;,h4pq>j1^a9`1^a9`1^a9`4pq>j)@HNF*X_rJ*")`H*")`H5l^lb-ia5I<s8R(Z3gR3YR1@1YR1@1(^g<D>6"X'0`V1RN<K:^AH2]12uipYfE;0Sj9Yed2@9EaJdMJXGlRgE5QCca<WrI'/.2FX/dhXZ0FIj\0FIj\MZ<_W9`P.nP6Cpd-jp"T.LQ4V.LQ4VUAt8o=9&=$<WrI'((1*B((1*B((1*BU^7#$W!NG(WX/Y*X9ek,X9ek,-49eR-49eR1^a9`1^a9`2@BKb3"#]d3"#]d#B^SX'N'qm"W+5""U0"q"U,'OaTVhOFMS+abm1!ESJK0K"`sbK"Z!Id"kWjQ!O)a8!<o"p"gnBH"Ju4@!jr%4.CB0[-$KLr"Xe^E/R4)4I0F_t!sJjM!<iX)[/gGUV?)b_[/gH%!<ok3YQ^m)J-WI_"Y$h["gA5B\-@onTE:tk^`JI9TE_7o^]TPsI<Phu"Xe^="`sbK"a'tPTET%p!K@*`TE4TcPl\AuBpA^Y!<mQm"U/uK"U.f3!<kH[!Up<$!<k]q!<kH[!Ec`1"e>Yt[/nn]V?-Gn[/gF[[/gHp#GqO[%ZLJm^B(nHbm:f_BpA^Y!<mSE!X7cmV?,m1N<'cM!L3ZhSH2%?+U+\C6'*)j'buu7"U0"T!<iXK!<iXt!<ok3\,iH-fE&A\"e>Yt[/nVYV?+I5[/gF[[/gF7+Z2stTE.r%"eYmJ"`4F9!VutBI6ogd#CQfL(4CU9L]Vu..Kte4"a'bF"gA6/!Or>n!MBLk!Pfb9!MBXo!Pees!<mT(!<iXK!<iWk[/gH(.&I#q!OVq3;RHN/TI?Z<O9W)n"e>Yt[/m3.V?,$F[/gF[[/gF7.Kte4kQb,?&qpjh!N#l7N<'3)KE25[F9)OK;RHN/W!&suJ-*+Z"e>Yt[/l@9V?*=m[/gF[[/gGZ^&\B@"Xe^M/R2t;"Y'\8!<mT&!X/`N*=W0%"XO=%"YBm$4Z*CbquR%MG6J-R-[c^]>_iE/"Y'\8!U'cc!JhAJ!MBIj!>pds"a"ql"a"Pa!<iH'zzzz!!3-#!!!#@N<KK-)$L1c&Hr>[#mCKS!<iXL"U2j]4LGL_!W`Z/zzz!!'A+!!$O4!!$U6!!$U6!!!T2!!!K/!!!$"!!$O4!!$O4!!$O4!!!$F"P&J8"`uI&"`u0s"`tmkr<P%S+,pI.F9)R'&Ujlm"a!TF"`sbK"Yq)%YQ^m)?l]EA!<jM%!N#mR#9<ss*<clX"U1_+Gm+?dLB.Pb"`u*q"a'tP!<W<%!.4bH!.4bHz!!!,AN<Kb6^^gSP.g6@cF9_u?)ARr<]cR8Fzzz!!!!K#QOi4!!!!.!!!!b"98FT#QOjX#QOjX#QOkE!!!"4#QOj:#QOj:#QOiT!!!!@!!!!S"98F6#QOj:#QOjF#QOjF#QOjF#QOjH#QOjH#QOjH#QOjH#QOj(#QOj*#QOj(#QOj(#QOj&#QOj&#QOj&#QOj&#QOj7!!!!Z!!!!a"98FX#QOj\#QOj\#QOjO!!!!f!!!!@"98FH#QOjL#QOjL#QOjg!!!!r!!!!R"98ES#QOiW#QOiW#QOiY#QOi[#QOi[#QOk0!!!"+!!!!9"98Eu#QOj$#QOj$#QOjP#QOjP#QOkJ!!!"9!!!!^"98FL#QOjP#QOiU#QOiU#QOiU#QOkf!!!"I!!!!A"98Eg#QOim#QOik#QOik#QOi.!<<+]!!!!Y"98EO#QOiN!<<+j!!!!f"98F\#QOj`#QOj`#QOj`#QOi+!!!!K#QOi2#T*aS*"X5,,RW^p"U0"!$3^TTq$@3.FR]Y@"a&]/"U/uK"U.du"ULt+^]I46SH/mg^]^M8a9#'>.89s\S,jA_"<G)T2$NISBcRol.2<"$KE266"a%if"mlP-h&j$+"eYn%"!*I,BcRolF<:YiF9)OK;G@>a"Ju3]%o!3_9a1"hV?((!"e>Yt9mEN9J-8RM.89s\S,jA_"r.?("Vp\@QN77Y'q>:>i!'@,KE25kS,jA'"W_jt"n2b2*>J`,'a5>*!<io9F9)OKFQif0'q>:>huj4V!K$t"n-<YJ'a8^<!<j4.!>XMq'aF.4'buB&"Z6I*6j3a9!<iW^9a/$-V?((!"e>Yt9s=Yq!O)]$"Y!.L'mVY?]aKSr"UP?S-Nt6170OE]!<oG+"a$^I"U/uK"U-YU"[Jpc?qgfq!<l3=&>fIN9a)t?"Wa*6'rV>M%>Orff`;7uklM#'GpNV/LB.Rk!<mT(!<kWV!>VO;'o)en*sH`e"U.du"ct(.!It>J"e>Yt9h;,^a;7PS.89sLf)_cM"VmO.'rV9N#4Mj4'ncSk%2GB6'rV9>TE12Z*<gNc"U/uK"U.+b"c+Y*!FSV*SH/mgYSa5<O;1In.8:!8#AG3<"U0"<!X10G!>VO;'o)enbQ.lhk5kf%KE26&"a#M%"U/uK"U.du"m?u(!O)c&"e>Yt9pcBe!Vcak"Y!.L'fZs'"s%t8"n2b2*>J`,'a4b_C]t!4!>VO;'o)enX9/WJMuj.dF9)OK;G@>I,c1V;"AK%T9a0/pV?((!"e>Yt:$<[r!QZ9U"Y!.L'q>:>p]e,8FRTMM'ncSk,o)pN(&.t:TE4<[*Uj;J*>Ja"PQD!lF9)OK1/.r!(o@=A9a.'g"\jdhV?+a?9a)t?"e?-K%0[K%!<o8%"`sbK"]A%u^^$_;J-AXNSH/mgn0Fk3O:Y+i.89sLoDt!S"U0#P"U/uK"gA\64g5>X:Z)dI4UjRL&Hu&i"i(je4Z*D6!<k?j(8_+g-8brU2$F_b!>XMs*I1'WO9K>='a6$$"Vots"[rT:!<iXKMua(k#R(A@LB.RC!X3\I!sJ]?zzz!!!!A%0-AN%0-AN%0-Af%0-Af%0-Af%0-A0!!!!8!!!!3!!!"\"onXn!!!!A%0-AY!!!!@!!!"i"onWc%0-Aj%0-Af%0-Au!!!!N!!!"]"onWK%0-AT%0-AR%0-A2"9o2C#P<uZ"a!$6"`ua."`uI&'mTrd"dB#o'a8\n"Vl:d"Vldn"j$cKFBJbV#R(A@LB.Q0"`sbK"]@2]=Jc+L"Z6IS!<k=dV?)2J2$GEd"U02o"bd;U!S&/!"a"_f"`sbK"e>Yt25gSR!FRbg;DeX1!i>uX2$KNO"Z:P%!It;1"Xu;4%@dI\#hTA&Gm+A-(hk!*"i13S"Vl[k"U,'P"U,'O!<iX)2$M&%V?*n*2$KNO"Z=@%V?('^"e>Yt24t2O!K[OD"Xu;4%9;3cfEW,qL_pjAKE25[%@dG6fEVSQ!SR_uL_shH'a8]4!<iK5zz!!!!(!!!!1!!!#f!rr>Z#64bb#64b`#64b\#64b\#64`U!!!!=!!!#d!rr>V#64`e!!!!K!!!#f!rr>\#64`(!!!!#"cr`ln;RSTFJ/^="a$.5"U/uK"U-YU"c*D\!LO!a"[>]bL^0dXQip+e;G@=N#GqOs"AK&j!<l2R"Ju2*9a)t?"a+g@-rhQuL]Sk+.Kq[5F9)R/#GqO#.Q%C&!KmOJ\-6S02'mGM"U0!F"U/uK"U-YU"b6`Q!>nN7SH/mgp]75mfEFtQ.8:!E$7Q\n"Y'Zr,she1#6f2c"U/uK"U.+b"crtd!JgkQ"]A%uO9_W`p]=.nSH/mgO9_W`Qip+eSH/mgfE.oN3)'Q*9a(\gXUTsb"a'tP"a$pK"asA#$]PJo&-)\1zzzz$NL/,'`\46Y6Ft,/H>bN*rl9@[KZ^35l^lb.0'>JY6Ft,<<*"!1]RLUXp+k+Q2gmb?k!)9@LW;;@LW;;?k!)9FT;CA5l^lbXp+k+K`D)Q8,rVi!<<*"P5kR_?iU0,XTeb*"9o2C!Xb``"U0"!"9esNq#^d(FR]G:"a&u2"U/uK"U-YU"c*D\!Peh4"]A%uL^0dXp]O:pSH/mg^]^M8#YbIO9a+g0J-n.kLB.S3!<mQG"U.du"aHmFJ-AXNSH/mgYQ^m)J-SdP.89sL%T*B5F9)OK1/.q&"Ju3U"AK&j!<l3m!N#nM"\f.L9a-4QGo[%l-Oh@R/-Q1\V#^`?%0kGi2)PU%#;n@A3@+iN!<iX)9a*MR!It>J"e>Yt9qV`g!S@TN"Y!.L"WCeQ-Xd0!"a"_f"`sbK"e>Yt:!a*A!JgkQ"e>Yt9n3MH!O)T!"Y!.L'q><D"-=u9+Y=u\9Ee\'&Nl$ir>,Ve"Z7k9J-nI'#AH=Y"Y0a6"`sbK"]A%uE2E[""\f/k!<l3-#GqOK!DN_H9a(^_!<iW1FKY]K"`sbK"]A%ukT$H#O9/,[SH/mg+Jo14)bgJb9a(]C%0[1FfEWE;#1sn9"e5T>kQ1p0!<iXK!<iW^9a.HuV?*%e9a+Eh"fMR$!Vcdl"[>]bW!&suQip+eSH/mgfH$giTEIsm.89u2#'I-P<@ssH%0\=?,paQ7Y5opQF9)OK;G@>)&uG\["\f/k!<l2Z$`3rT'28WZ9a(]>hZ<r^$31&+zzz#ljr*$ig8-ecPmPWWrM(WWrM(_>jQ9+TMKB('"=7!<<*"WWrM(WWrM(!@S0-N<KK-E<QMfBa"Z^@0HgV!<iXt!<k'r!i?!S"YBnK!<k'B"Ju40""a[*/Hll1<JUg/.=MF8"`t%S"`tgi"a'tP`<8tj(VKnSF9)OK;Cr(I!N#nU!A+JG!<k(E!i?!C/HmRT"V"H8"Vl:d"Vldn"^D4QB*A;Bzzzz!!!!,!!!!,!!!!"!!!"B!!!"B!!!"B!!!"Bz#LeY9"`tUc"`t=["`t%S"`sbK"`sbK"e>Yt22DL7!Jgn:"e>Yt28B?l!QY=""Xu;4'aOsH*K1$D$O$\]m/nX<-P\3R?NhIp#`o)+$,m&K!rr<$!rr<$#64`(!<<*"&HDe2&-)\1V>pSrz!WiQ3eVs_9F9)OKSH/mW#c7WY"[*$[!<kWB"f;=q"?co;4Tu9#"U,W-"kY:.-Oh(BUB(f--!]XM,m>Zm!]:.'!<jca"W\>&"U,'P"U,'O#6i'L>@j?+!=/Z*!0RZh!0RZh!0RZh!13`dz!0dfj!0dfj!"f22!"Ao.!(d=o!!3K;"4<)3"e5T&Qj+"T!<jnUF:e\a&=*?N"-!rtF9_sYUB(f-"Zlks"`sbK"e>Yt(%;=&!>lOTSH/m/huT\UL^+Xu.2<!iFmTP?!@n-Mzzzz!%\*M!)s=+!"T&0!"Ju/!3HD)!*fm3!*fm3!*fm3!+H<9!,`/E!,`/E!,`/E!%e0N!$)%>!3QJ*!+$$5!+$$5!,`/E!*Ta1!*Ta1!*Ta1!*Ta1!)!:l!%S$L!4N+3!,r;G!,`/E!,`/E!+,^+!&afW!3cV,!+H<9!+H<9!+ZH;!+ZH;!*0I-!*0I-!*0I-!*0I-!.OtK!(m4k!3ZP+!*0I-!*BU/!*Ta1!*Ta1!*Ta1!)s=+!)s=+!!E??"<@c5NWfT.nH9"!FQio3"a&]+"U0#$"9mlf,..U1'ErU_"U/uK"U-YE"n2Vk!FS%oSH/mWi!#tY#X&>?4TuRE"U2:BKE25c'po#U$O%7LclNo*F<Lf&?3LKI)?od;'aFFK'a8])"U/uK"U.+R"b6`Q!FS%oSH/mWp]75mfEFDA.6RhL#/CYt%+m"X%2BV'%0ZoWq#LX&F>!e4#,hnE'jT)k'a5ro,mABL"U/uK"U.+R"b6lU!LO!Q"e>Yt4m3$G!K[OL"XuS<*C1MG"eYmJ"Q]h&?3LK9FF45qF9)OK;EY3!!N#n%#!E-\!<kXM!N#n5#!E,=4Tu:"fFAW"Ig$ProDo]"+;J.[#8IE8!V-@>"a#e+"U1h*%CH]U#06uX'g[Wj"U0!V"U/uK"U.de"m?r'!MBNX"e>Yt4jX5,!C/dO.6RhL>ehNu,s`@O/O>0r"Z<F`(^2Jl'a4b_j8fDf2?aP_$Dmic)%@<I"kWnl#06r_"a#M$"V!d%kTgUm!<k+[FMn1`!@e'Lzzzz!"/c,!"/c,!7(ZG!29Pq!2'Do!1!]e!1!]e!2'Do!0@9_!0.-]!/(FS!/(FS!%S$L!$D7A!0.'[!$VLF!(?kf!%%[G!1s8l!'gVd!(6nh!($bf!'UJb!'UJb!*K:%!&=NS!5eg;!/L^W!/^jY!/q![!/q![!'UJb!/(FS!/(FS!/(FS!-\DC!'pSb!/^dW!#Pe<!#u(@!#u(@!/ggW!)!:l!5\a:!1!]e!1!]e!13ig!1Eui!1X,k!1X,k!!QA"FTmI"%[E%X"a%ig"U0"a!sJjM\H<!=FKkoO"`sbK"[?i-fE%iMa9$2^SH/n2^]^M8a9$2^.;]6]!i?"6,IJ!bTE4ln?2+S;>ua=;"U,&W73r+["U,(&!K%%dp]YA;<CM*8"U0"!!sJjM!<iX)D$BD3V?&r!"]B1@Vuigsp]PF;SH/n2GbtLl"Dn;kD$;Kra9F4"K`Nb/Pm5#)2$F/;!At#aTE0oN4[h[Xp]j4lW$Ol$>_iGM"Y'[U"`sbKkQdscW$54FTE0WK?+:&P>ua=;"U,'O=TntN!<iX)D$@]ZV?)b_D$?I2"`8bqV?*n%D$;A*"m?2g!Up\$TE1nj(fddF+,C)#n0=e2fE>1XFGBl#"Xc_J%:"\i70P.E<<[Jl"U/uK"U.e@"eYsp!B=p"SH/n2n//#'E,>b-D$:)n!=]29+XJ/R$3Mj`"a$XC"U/uK"U.,-"jd=J!T3uq"e>YtD5[Q6!@Vdg.;]4l-Uf$b>_iFB%L"<c<Tj[b!O)o2TE1nj(fddFV?+IW<<[Il"gnPYKb`,G!=Jl-zzzz!"/c,!"/c,!!*'"!9OOe!9OOe!$)%>!#P\9!-SJF!9OOe!9OOe!&+BQ!!*--hi.dCF;Y5cF:eZ[F9r*SF9)OKF9)OK;FLcA!N#mZ!_!9`!<kp-"Ju4@!_!8A70Niu'a8jf'u1:_FBJbNF9)OK1.;@s#GqNh"@WKb!<kp]"/Z*\"%<AB70WW"Gm+?T-OhX2-P\L%/-Q1\V#^`Gi"CqKA/,8i#mIF6?$37T"a)*p!>PS7zzzz!7UuK!7CiI!7UuK!"f22!"],1!+5d,!$_ID!$;1@!+Q!/!6>-?!6,!=!6bEC!6bEC!6bEC!6bEC!6tQE!6bEC!)W^r!%\*M!,2E5!*]F'!&afW!+5d,!5\^9!5\^9!!*6-r/Cj`FP-^!"a&,n"U0"i!X/aL_#af(#GqO[(EErk"U,'P"U,'O!<iX)/Hq4<V?,T[/Ho$("b6WN!?`rtSH/mGhuT\UYQZT^.4k]4?3LKAQiRBc#7Uma#7V,s!U(R6"`sbK"`sbK"]?oU0W"l,.P1fg/HqdPV?)JV/Hn?j"n2Yl!Jgk1"e>Yt/U4,nkQWUB.4k],.L#JRkQdsccla><[/gF7%716n#7Um9-1qHO>j*4<"Y'ZrkQdscp`^^f?3LKA63[,h%0iaW%1QS+*Xr9&"W[bg-NsZq!<iW^/HrooV?)JV/Hq[G"YI4eV?,$J/HmRT"V!d%p]p0e#,igW%:&*<%0\3b*U!a*!N6qX"`us4ob@b7(sN0b"98E%!WW3#a8u>Aa8u>Az!!LB&"U+o1Ka[he!UU="jUV@qblItJ"UDF=!::0m&ciIBzzz!!">G!!!B,!!!K/!!("Az!!"/B!!!r<!!(.E!!&;k!!&;k!!#.^!!"ML!!(4G!!$.%!!"nW!!(%B!!&)e!!&#c!!&#c!!!+W!<nD_$2ohe"`tUc"`t=["`t%S]al::($-89F9)OK1.;B!!N#mR"[rTc!<kp-"Ju4@!_!8A70U('JcQ%?!tC"d"UP?SnGrdsFThpPF=.5$G6J-ZKE25k"`u:!"`sbK"]@bmfEJ,QO9\2XSH/m_O9;?\ciZ]?.7FCLGm+?\>\FQMmK!J3kQdsckUISVF9)OKF9)OKSH/m_&>fJq"@WJl70WGfV?*=l70T4_"\%VZV?,l`70P,/"VhH:%L"H#!RM5Y2*q!T"Vhau"eZ$5,om/2Ig$!t!<iWk70V$AV?)JV70T4_"\!qIV?*n%70P,/"V!d-p]h64cj/qB%:"\j%0\3b*<gNc"m?2g!OsBq%<hsZ%>4`c"U0"7!<iK3zzz!!!!%#64`,#64`5!!!!-!!!!"!!!!##64`*#64`*#64`l!!!!##64`)-j8(["U/uk"U/uc"U/u["lKuA"UtWW@0HgV!<iX)*<c_G!T3u!"e>Yt*V]c7!S@Dn"XtGq%H@Hm"Vl:d"Vldn"W7Jc#mJ!YK`TF-SI>[D*sDgj"U+o@!!!#I$ig:W$ig:Y$ig:Y$ig88!!!!/!!!"D"onWF!!!!8!!!"7"onYU$ig:[$ig8b!!!!C!!!":"onYW$ig:Y$ig:Y$ig:o$ig:o$ig:q$ig9+!!!!X!!!"D"onYi$ig:o$ig:s$ig8K!!!!#"cr`ss,@0c.1HFa.KpP-63[,h"a!TF"`sbK"Ytc4"kWjQ!Or5c!<o"p"bcum"Ju4@!egXY.>7d+r;f4*.Krg<cmT''6%C$\"a'88"U/uK"U.,E!<m_F!Jgl4!<o"p"bcu]"f;<N#DE0^.>7d+*<sjqN=Ht6L]SS#.KqEf#GqOK&M40.!<iXK!<iWkK`M@5"/Z+o"GHj[;M>,TkQIa`p]?-M"e>YtK`U*6V?&B)!<jp+!<iY"!MT_)%_)[V2(]hm"U,(^!?Dmi>\G,].KqEf#GqNp"YE0!!At$D6*M"+77$,I"U/uq"U/uK"U-Z8!<pgRV?$sV!<o"p"bcue"Ju4H#)*'].>7d+N=8+/$jCK6\0hH&6'r;h727Z`TET$e/KK$="U-7o%0^kX"f2J)PmX?,"`stQ!>,;3zzzz!"/c,!"o83!07*[!#u">!%@mJ!$)%>!0[B_!'L;^!%7gI!0I6]!#bk<!#u">!#u">!!3-#!#bk<!#bk<!#bk<!#bk<!+Q!/!&X`V!0.$Z!!*61q2GO]FO:-n"a%if"U0"a!X/aL\H2p<F9)OK;G@<#V?-Gn9a.'g"\lc8V?+a>9a)t?"l0\),m=IK!=^Ua-P\MP"E?R."`sbK"Xb<Z4_b-8-$TRs"`sbK"`sbK"[>]bJ-;_Mp]O:pSH/mgJ-VqPO9/,[.89slMufIN"U-7_/HmL:V#hZE"XO=o>Qk:Q!<iX)9a0_`V?*><9a.'g"\nIhV?,l_9a)t?"U1\&-.N278<>#I"b-\%"a!uQ*HqYj*JXY!A-I'("Vh:H"Wa?="U,oOp_k.V-P\3:F@69Q>f[R)2'B[["XS?r"XSp)"ge:6F=.7b%&*cf(9IuG&-)\1zz#64`(#ljr*>6Y'-Z4$^5Z4$^5Z4$^5)ZTj<'*&"4=9\a*Z4$^5Z4$^5Z4$^5Z4$^5ZjZp7\-r?;\-r?;[L<-9KE(uP!<iefN<KK-=TntN;$@,F!<iX)70U1'V?*Ur70T4_"\"4MV?,TU70P,/"h4`l!AuGLG6J-R-QNp*FE%HfF9)OK5=Ga;"/Z*,70T4_"\"4PV?'df"XukD"Y'\X#9?,7p]hfDcj(R3>_iG%"Y'[-kQdscQm+*cTE3aM2$J(<"U0#P"g&&\!S&(4*!LFs"T\r1zzzz!!&;b!!!H.!!!K/!!!$"!!%TN!!%TN!!%TN!!%TN!!!!*er9h:F<LekF;Y5cF:eZ[F9r-4#uJ#<SIbsH!<iXt!<kor"f;<f"@WJl70Tn!V?-Gm70T4_"\&1hV?)JX70P,/"W[jP"cWef!VHp+"Xaa2"Xb$B"Xb<R-!pg%!=&T)!!<3$!!`K(!!*'"!9sdh!9sdh!9sdh!#GV8!#Yb:!;6Kp!3?/#!&jlX!$D7Az!!!8bN<KK-!<iX)2$Mn=V?)b`2$KNO"Z;)>V?-Gp2$GEd"U02U"U/oM'ceh/"U-pj'bpq/"W[bg#mCKT"U,'O!<iW^2$NaUV?)JU2$Hl8"o&+q!T42?"e>Yt2=L^F!I-I*.5_;%%(lV6*$$UsW"0%P?3LK9FCtcB#]I*g]b^io!<iX)2$G\2!It>2"e>Yt2:r)0!S@H2"Xu;4"bcs^"T\u2zzz!!$+,!!$%*!!$%*!!#7a!!!T2!!!K/z!!")@!!!l:!!"VS!!!'#!!$%*!!!$<$/^^G"a%Q]"U0"Y!<iXKYlP"3FX74L&rQc^'a8\$"dKd]!MpU?('Sd\"U.dm"n2Vk!It>B"e>Yt7Gn3D!JgtL"XukD"o&+$"U/uK"U-YM"aHmFQioh]SH/m_YQ^m)J-SLH.7FF5"F1.S"Xaa2"Xb$B4Y-a?"f25',m>/$"Wmsa^^^Ni-NsMu!!!!#!!!#[#64bd#64bd#64bd#64bd#64bf#64bh#64bf#64bf#64bb#64`A!!!!:!!!$!!rr<Y!!!!Gz"98E'#QOi+#QOi+#QOi-#QOi-#QOi/#QOi/#QOi/#QOi1#QOi1#QOkc#64bt#64bt#64c!#64c!#64c##64c##64c##64aF!!!!a!!!#p!rr>n#64br#64bt#64bt#64bt#64bt#64c##64`+#R1\BMiIrM#R(A@LB.QM%@dG6Qi\!,n/2rUKE25["`sbK%@dG6Qi[Ga!J1Con/5p\'a8^L!X/aLW<*5,F9)OK;DeW>"Ju48!]:.P!<k@-"/Z*T">p?I2$M>/V?('^"e>Yt2$g&[GVoXR2$FGZ!>Ut'*SUSu"n3CDeHs2*"`sbK"`sbK"]@2]&>fJa.Q%Ab2$FPg!FRbgSH/mOhufhW0Js"_2$FGZ!>Ut''aC<N'b-Z6*LHmS622&rSIU;R"U,@*!>Ut''jSN]'a9'j'b-Z6'po&Y#c7Xt&etkG!>Ut'YT9SAp_";FF9)OK.2<"$KE25["a'tP,seI?"Vk>I"U/'Er<*9c"VhcB!>Ut+"dB#o'a8]!"U/uK"U.d]"jd:I!O)bc"e>Yt2<Y4@!U'tM"Xu;4%I!m.Qi`'LV?*V+'b-Z6'po',*Mrk9%i#PD!>Ut''aC<N'b-Z6*LHm3FK>KH"a!fLbn_)F*VCKT&HDe2zzz_>jQ9$NL/,%0-A.X8i5#*<6'>*rl9@Y5eP&5l^lb0`V1RYQ+Y'@K?H/@K?H/<WN1#CB+>73WK-[X8i5#G5qUC63$ucWW3#!LB%;S9E5%mWrN,"=oeU'=oeU'=oeU'=9/C%":5,:"UC9P"U0"i!sJjM_#jiEFL_JWbmL!BPmjJu"`sbK"]@2]GbtLl"Z6H]2$NINV?%es"e>Yt28B?l!=1Od.5_843<]QqE4#cO%0j$C%2FBo%IbeeUB))5*F+sO*A&DT#6c,l"U,'`!<E?-F9)OK1,T5c"Ju3U">p@R!<k@U!N#nM"Z6H42$Me:>c7lJ/Y`=e"W_=]*=[5s"V#FY!X0#;YR(aR64NE5"`tUc*GP`u%<r$["a"G^"`sbK"]@2]hu]bVi!2+CSH/mOp]@;nJ-\"9.5_8LUB))5*Eh;?*A'Ru#6c,l"U,oOW!==HTE4<]/Hp6L!<iXL"U,@1!>PbI>bE5L*C7aO"U/uK"V#2m*=Y[GW<!0E!<iX)2$KWTV?*>62$KNO"Z>cdV?(Wn"Xu;4%9E]:"Zlks%71N&(^5!^"V$4f"dB#kF9)OK;DeX)!i?!K"Z6IS!<k?B!N#lg2$GEd"U-Qt!<jdE!?D=I-QOcBIg%,D@0I)DF=.4mz!!'rs"V(M3s8W-!rs&]2!<iH'zzzz!"/c,!"o83!4i=6!!*-*er9h:F;Y5cF:eZ[F9r*SF9)OKF9)OK5:m'."/Z*T"YBm5/Hr?^V?)JU/Hq[G"YILmV?$rS"Xu#,%=&*\%:"])o`VB*"U3]i*<u9Y*=Z<Y"U0#P"be!2SJ/sN!=&T)zzzz!"/c,!"/c,!!*'"!,)W<!,)W<!!!2MN<KK-)$L1c&Hr>[#mCKS!<iXK!<iW^,m=RO!FR2WSH/m?^]^M8a9!Xk.4#-$H3FKN%kIkf"ah$gN=Iu9!L4E$"TSN&zzzz$NL/,&c_n3;$?q"!<NJVN<KK-)$L1c&Hr>[#mCKS!<iXK!<iXt!<k&WV?%Mc"]?oU=Jc+L""a\I!<k'j"Ju2*/HmRT"V#_\"V"^m((D8f"dKQ<#5B/Y%:02A"ge<d!<o#0=G6pt*ruoQ!!!'#!!!0&!!!H.!!$s@!!"#>!!!c7!!%<J!!)Qq!!)Qq!!)Qq!!)Qq!!"qX!!";F!!%!A!!)'c!!)-e!!)'c!!(p_!!)Ko!!)Ko!!)Ko!!)Ko!!!'C"pa[X"Ut_@"V$4f"h=[<F@cW>F9)OK1,T6V!i?!+2$KNO"Z;YMV?+1/2$GEd"f2?I"U,'o!V$1*"a"_f"`tgi"`sbK"Yqq=J-VqP(c;Jf!<k@M"/Z*\"#U622$N@L.2<"$KE25["a%!M"V$t&(#T38Gm+B@#AG1n"a"Yd"`sbK"e>Yt2:r,1!Jgk9"[=jJp]@;nL]fR=SH/mOfEJ,QL]]L<.5_8<S,jA_";M.1#8Iu,!<iW9S,jA_"9kG!\cU[ln-<[8#o*Vc)$Lb#"U,Wr!<ic5FLM8S"a'tPboR1F)uUNQ$ig8-!rr<$#ljr*z_?'];^&e97^&e97_?'];*<6'>('"=7>lap*]E/'50`V1R,QIfE?NC-,^]FK9^]FK9,QIfE;#gRr/H>bNz!sObe<=/2T"U0!V"U0!N"U/uK"U.dm"ipbB!N6#f"e>Yt7>M)D!T3uI"XukD"eYl_27Nfa2(]hm"U,&W*>Ja#"U,'O!<iX)70WGeV?&YF"e>Yt7JHn\!JgnJ"e>Yt7IUDV!I.$:.7FCDYQ<hq"U-@Z'cfUEp]hfDcj(QpF9)OKF9)OK5=GaK#GqNX"@WJl70T=hV?,T[70T4_"\%&IV?)JT70P,/"W[i(!rWH0.KqEf#GqO[,V91A(Bp'2?]>ZB&d<@X"U.dm"lKHZ!It>B"e>Yt7G%gA!Or8$"XukD"V5MT!<<*"!!F2U*YJIkN<Kdks8W-!s8N<-"T]G?zzz!!(pW!!!B,!!!H.!!$('!!'5/!!'5/!!'5/!!'5/!!')+!!')+!!')+!!!'#!!&Mp!!&Mp!!"_R!!"2C!!#dt!!&Yt!!&`!!!&Yt!!&Yt!!&Mp!!&Mp!!&Mp!!&Mp!!!';"paRU"U0"9!<iXKOT>UhFGU#%SI?R9$`sd?F9)OK;DeU`V?+I62$KNO"Z='uV?+a>2$GEd"V$t&'rV9V"U,)!#AG1n"Xt/i'ncSk"U/uK"U0"i!<j3`"U,Wr!<p"7"`u*q%1!+@%>Orf/-U-H!<iXK!<iW^2$Jd<V?('^"]@2]fE.oNYQcrgSH/mOci^-Gn,tTP.5_8<2AN.o'aF.4'd\M6"U,@*!>VO:"eYn5!?LY7BcRolF9)OKF;Y5sGm+?TPQ?gG'a8]L!<iXL"U+o3zzz!!!!5z!!!!.!!!!-!!!!"!!!!)#ljr*"jr;5"`tmk"`tUc"`t=[oc4@@&=!h2F9)OKF9)OKSH/m?n,oNg?mPuI!<jeE"Ju4P!@7mu,m=Hu"U,Vl"U,'WSI>Z&#ljr*zzz#ljr*%KHJ/,m42J!WW3#6jNbm6jNbmz7L/to!>5^jN<KK-Ba"Z^@0HgV=TntN!<iXt!<kmtV?('n"e>Yt7@44T!Or5#"XukD-$]Xt"Xaa2"XhP'2*EJo"U1_'"XO<i'a9+<MZFn7"`t%S"`u!n"a)*pV&jgA#IP?K$31&+zzz,QIfEz%0-A.&c_n3!<<*"*X_rJ*X_rJ*X_rJ/H>bN+TMKBO9GUa!XK2>jc'EIF<LekF;Y5cF:e\I)BGXim0j/?!<iXK!<iX)2$J6%!N6#V"e>Yt20bu!L]fR=5;`UhV?('^"]@2]=Jc,W!At%O!<k@U"Ju3M!At$02$FF="U,("!>SEO*"@uMTE\NK$dA\]S,j@$"`sbK"`sbK"e>Yt2:qu-!Jgn:"Yqq=fE.oNL]fR=SH/mOci^-Gn,tTP.5_;%"WXWKO<'tuBcRolFThpL49,?]zzz$3U>/$3U>/%0-A.$31&+p]1?p!WW3#)#sX:'EA+5o`5$m.f]PL+ohTC#Qau+7fWMh/H>bN"9JQ'"p=o+"p=o+@/p9-3<0$Z"9JQ'$3U>/$3U>/$3U>/HN4$G:]LIq%KZV1UAt8o?2ss*$j$D/^An66A,lT0%0?M0b5_MBB`J,5&HVq4eGoRLE<#t=%KZV1jT#8\FoVLB&-;h3mf3=fHiO-H$j$D/qZ$TrL&_2R&-;h3%flY1MZ<_W%0?M0(^'g=(^'g=(^'g=(^'g=+TVQCPlLdap&P-n$3U>/%Klb3%Klb3%Klb3$3U>/$3U>/$3U>/$3U>/1&q:S561`a[/^1,$N^;.n,iXjl2q"dE<-%>^]4?7rW*!!rW<-#rW<-#rW<-#ncJjlncJjlncJjl"9\])"9\])"9\])PlUjbd/X.Hq#LHqoE,'noE,'np&b9pp&b9pp]CKrq?$]tq?$]t%KZtG('kg"+sncl1,_0(S<!gWF@cW>F?p'6F?'L.-QOK:FJ0!E'mUMt'o)ennHp!t*KV*APQB_M'a8^T$O$tF"U,Wd"U,Wr!<k+[F9)OK;KW.n#GqNP"a(!>!<mW8"/Z*\"*FbrFThs)!Kd]m"`sbK"]BIHfEJ,Q+E[jY!<mUjV?,TWFTj4:"XU>Q<S/!;GpNWr#t-WS"bct7"U/uK"Z6`HL]oZ*!A,T$FQ!H."`sbK"[@,5a8r.=QiqO8SH/n:TEh=pfEQI%.<Pe7#+,W9,sk%f"!n/=#K72o73*ZXF=@A.6:I7D'aF.:'g8&f*N0/_QN8*Q"a#Cu"U/uK"U.eH"m?,e!Vce?"e>YtFjL;h!Or/Q"Y"Qt*V]ZN&02cS*@3"e!<qus"`tgi"`sbK"[@,5J/+p^p]P^CSH/n:a:P3L+E[i:FTq.7C^'J;2$V,+2$G?R4U!2b75]8m"[/U]AHbL/"YBn"!<iX\!C[/\>egM3<C+\N"\!V="[rXR-Ue2\aT2PKF9)OK;KW/1'rD$,"Eal4FTn-IV?,TYFTn<:"a,nRV?*n<FTj4:"Vh6o&iCEJ!PfNE!A/L!"U0"q!<k&D/N!\i"XP`("m$(C#,i7g'aBI,2$GlA/N!\8XT\lMOTG\L&BtRd2$V\G75Y:*&ktMq"U,'Oi<0;fF9)OK5BR/!';bfg"a(!>!<mW@"/Z+W(3Kd0FTjpj!Ca*m2'XtA4Tu#^#X&BZ#sE-q!C`pk7?IT[70Rcf"Z6Ge[1"nsTF!Ir#1sPO*<s:q75]8m"U0"$!X/aL!<iX)FToi3V?*=lFTn<:"a/`DV?)JhFTj4:"\ndnL]mrFG6J.-OT@U&"a#t1"Z6L_'f@!9L_;iS2?bri74gA#FQW`0-)1KH"YBl]h#]/4TF!1RFSl4E'r(d="Vk:P,8CA?"VmC0IK^GiF9)OKF>!e$-RBd-S,jq'"so$*"Yg1&VZ?r)PQ<<]-%H""PlW08W#d5gF@6<*(01#;N=Z88!<iW^FTp\QV?%NV"e>YtFl4aH!S@Eq"Yt3(Laf2%QiqO8SH/n:^_N^In/lcV.<PdtF9)Ql,YM^Y+_=Hr).d@gAZumQ;I'IA+),:l"e>Yt?18u6!T5G5N=@>5!X0l["f2XP%gJsR,me?-,mAD?!X/aM"U,'O_u^)GF9)OKSH/n:kQn$dQiqO85BR.6)l<Xl"Eam=!<mUr(8_+_)Kc34FTo8gV?)JWSH:*(7@40'#+,WAn/Q/E%NP^2"Vh2_!<j3k!<jbaGpNV/LB.RK!<mRj"U/uK"U1Ft"a.m-V?*%eFTn<:"a,>7V?-07FTj4:"Vj?Un.c*V"W]Ij!@=ZKL_"2O*Bfnn-)_$8&nrX4kR46gL^"m((8_,J"!%PeMuj.dFRK87!<rN(!,r;G!!N?&!"/c,!4`75!-ASK!-/GI!-/GIz!!*9-du=M7N</5ei#)tB"oSW7#5ArC"`sbK"`sbK"]?WM#c7Xl"sjGD!<jdb"Ju4@![S"!,m>#LL]mqc2Q?j"%:02A"a'tP"`stQh$Bq[bn$?O!?2"=!!<3$!!`K(!!*'"!/q9c!/q9c!0.Ee!0.Ee!0.Ee!1!um!/q9c!1F8q!1F8q!$_ID!#GV8!6><D!0R]i!0dik!0dik!1F8q!1F8q!1F8q!'L;^!%.aH!71lL!)W^r!&X`V!7(fK!1XDs!1XDs!1XDs!1XDs!-J8A!'^G`!7(fK!2']"!.t7O!)3Fn!7(fK!1a)i!)`ds!71lL!!<Q<&e((d"U/uK"U.e0"lKEY!?bYOSH/n"L]sXVp]Ok+.:!)d#R(AHgAqJf*sF+t*=\M>-)_$(%r!=1"`tmkYSO):^]PS\2?ag1LB.Qe"a!TF"`sbK"[?8rO9DE]L]gueSH/n"J,uMJp]4Y(.:!+e';bfG"6BZQ&uG]V"<H\6V?)JW*<gOt"U/uS"U0#P"U0"a!<iXK!<iX)>m9EoV?-/r>m6c""^U<rV?*=p>m2Z_"YJ%$"cX$E#07!#2*i&_"a%!N"U/uK"U.e0"jdIN!O)c6"e>Yt?-ieQ!T4,e"e>Yt?.]@Y!U'Pi"Y!^\76t;b20T3-'aaO:W!5Zo"m$7`#1*]G"a!lN*C9q^"!%Tm"<A3]cibX@#+,K=/V!j*h$,G8a9F4R"U1.m2$VD72*F6u-NsZq_uU#FFPd*&"`sbK"]AV0TGsa/TEAI'SH/n"TED%lO9&Vj.:!*Oa8qq]"][ir"\!/0*<gup"YD;Y/L?bdBe:>/FRK564[Bng76qao,ub%"O<J<i*<gPT!<qQhE2<bu%KT`5zzzz!!!B,!!!K/!!)<c!!")@!!!`6!!"DK!!$+(!!$+(!!$1*!!$7,!!$=.!!$C0!!$O4!!$O4!!&l!!!'#%!!&r#!!&r#!!#Ff!!"DI!!)<c!!(XR!!(dV!!(^T!!(RP!!(RP!!$:)!!"hU!!"GL!!$d7!!#"Z!!"JM!!#gu!!#gu!!$I2!!$+(!!$+(!!$+(!!%QM!!#Ig!!(UO!!';,!!'Y6!!'q>!!'q>!!'q>!!(RP!!#gu!!#gu!!#gu!!&\m!!$%"!!$.'!!'A/!!&et!!&et!!'M3!!'M3!!'M3!!'V2!!$R1!!#"\!!%*D!!%0F!!$m>!!$m>!!%<J!!%<J!!%BL!!%NP!!%NP!!(mV!!%'?!!)!Z!!(.D!!(.D!!$m>!!$m>!!$s@!!$s@!!(:I!!)`n!!&)\!!$R3!!(4G!!(@K!!(:I!!(.E!!(.E!!(.E!!%HN!!%<J!!&et!!&et!!&et!!'q>!!'q>!!'q>!!'q>!!#:c!!&kr!!$:+!!'_9!!'Y7!!'M3!!'M3!!(.E!!(.E!!!3,,r'O>JH6YXNWfT.nH/puFQil2"a&]*"U0#$!sJjM!<iW^`;p.p!N#ne"2t9ESH/o5!Pei8!QY>]!<jpk!<qj!63[,hFU"cjF`grF!d+ZgR/mHpF9)OK5K*X,GbtLt"N:BFSH/o5!O)a)!ItEo!<jpk!<iWSFe'$P>_iE'"Y'\0!U'cc!O*Pt!MBIj!>pLkYQq$+^a"O6TE:tkfE?m/"eYnM!K@*`FR]A8kQdscW#C?j"eYmb#)rYn"_iqsK`M@!nH&jtF9)OK;T/Y?32Q_<#/pTHSH/o5!JgiT!Vc`8!<jpk!<iWV"bd!@#Nu2U*JFLtTE2%nN<-NmBoN.I!HiSi"U0#<!<iXK!<iXt!<pFC\,rN.J-!Ui"e>Yt`<"luV?,$I`;p,k`;p/+#GqNh&qp?$%-7TqPlX1t"9k=s6/X-p'bu]/"eZ$5N<+_6Fa!um"a"ql\-6T+!JLPsG6J-R-Zp^=FKkoO"`sbK"e>Yt`;u&$V?)JV`;p.5!<pFCE2EZ7"2t9E.E);k"Y'BV"U-&$*<dTl7C<56"_D6La9H2ZFFaT!"XeF%%:!Rh"Y'\0!<mS0!X/aL!<iX)`;p.8"Ju3]#/pTHSH/o5!QZ(S!QYD_!<jpk!<pg[H\_l[!MBXo!Peek!HiSi"U-8r71EMk"a'tu"bcs\FI<78"`sbK"]E;?"dfar!K[N)!<k^,!<ni"V?-/f`;p.5!<pFCO;4VnfEB.o"Y%Ck"eYlj(ki-t#GqOK#)*)N!i?"&"bcu"G6J-R-Zq!M>jqo>"Y'\0!U'cc!RN9L!<o+sOp?sI"a%Q^"`4DHjT99'La?n\6.dLf"Z?O$AW["1AHe_-Ebtu%-NsraL]MW%.KtM,kQdscW"=X`"a')3"U0#P"U/uK"U.fC!<nQ)V?-Gn`;p-,`;p.(*2Wbh!Q>'C;T/Y?fGUOeVuaj<"]E;?"kXWg!LNo,!<o"p"iUM@%Aj0a$,loK.E);k"`sbKTHd+;!N6L9!Lj,Z&@DPH!=cF;a:SSRXT8U0#\g[IXT8Tr!<oS+a9/:?O:\Mp"Y$PS"U-@ZK`UBBTE4NrK`M@M!MTdX!Or<1!K@,6!HiSi"U0kdFd3C>FR0#3\-6T+!JLPs?3LKA>jqo>"Y'\0!<mT6!<m=+L]ms)6*MF7ATn:]"a#\*"U/uK"U.fC!<nPhV?)b_`;p.5!<pFCn-5`jp_^sN"Y%Ck"m?2P!MC9`!<o+sWWnF`\-6T+!JLPsG6J-R-ZrDu>jqo>"a#t2"bdqf!M('])Z^EKzzz!!%0B!!!B,!!!B,!!%o]!!!iF!!!r<!!!T2!!%u_!!!uJ!!!uJ!!"GJ!!!u=!!&)b!!"&L!!!oH!!!oH!!"&L!!!-*O9&@[!=@hH"U/uc"U/u["U/uS"bdLqV&&_?"`sbK"[>EZn,oNgL]g-MSH/m_^]^M8a9"d6.7FCD.1HFa.KpP-63[,h*<s:gPm%>5!<jKKL]SS#.KqEf#GqO#-nPUE!<iXK!<iXt!<koj!i?"n"@WJl70TUkV?*Ur70T4_"\!qHV?,<Q70P,/"U1P"nc:VX"YTHP/KK$="U-7o'a8^`"U/uq"T]#3zzz!!!<*!!!K/!!$sB!!")@!!!i9!!%!C!!)'g!!)'g!!)'g!!(d_!!!'#!!(d_!!(d_!!!**":,4lN<KK-f`;6[FO:*m"a%ie"U/uK"U1Ft"YIdsV?('V"e>Yt/XQ[<!Or4`"Xu#,"e5V,%+lC3>kf]^%@dGFW!3EI!<j3E"U,'5'n%)ga8uMKF9)OKF9)OK5:m&s"/Z*,/Hq[G"YEiR!K[F9"Xu#,"b-[j'q>:>Qj*_Y!?^D2"`sbK"a'tP%1!+@%>Orf*!LF+"cWqb!M'q,!<EQ.zzz!!$C3!!$C3!!$C3!!%0B!!!T2!!!W3!!'5*!!"AH!!!l:!!!$"!!$C3!!$C3!!!!&hi.dCFGU#%"a#:r"U0!n"U-C['a9g&'GUdn#mJ!`6H'Q8#R,;N"U.dM"n2Vk!MBN@"e>Yt-/\g$!Jgt,"Xt`$'i(tZ"U/ui"U/uK"Vj>--j9cr-NsZq!<iX),mBA3V?,TU,mBh?"XT64V?,$G,m>_D"V'l#"U,V\%>Y0&LB.Q+"a"Pa!A+9Ozzz!-/&>z!"Ao.!"8i-!5\m>!.kRY!.G:U!.G:U!$M=B!#>P7!:^3m!9=Lf!9adj!9OXh!9OXh!&jlX!$M=B!8I_X!8Iq^!8Iq^!8\(`!8n4b!8n4b!.G:U!.G:U!.YFW!.YFW!*9.#!&FTT!5A[;!4WC:!4WC:!4iO<!5&[>!58g@!58g@!-J8A!'gMa!8n"\!5o6F!5]*D!4WC:!4WC:!/ggW!)!:l!2B\t!(mV!!)<n%!)s=+!.G:U!.G:U!.G:U!8Iq^!8Iq^!!@?I0b0P1"U0"9"9esNOTYgkFGU,(Pm1Ic&a^J?FSQ"B"`sbK"e>YtD28Fo!S@Ei"e>YtD>472!S@Ei"Y"9l"eYnU"^SVAC"3Gg7<\n="a&Du"U/uK"U.,-"o&+q!QY=Z"e>YtD=@V(!I/Gb.;]6m#GqO+"bcuM!i?"n"B>Vu!Ff@0"_h7B"a%9W"U/uK"U.e@"YceSp]>:9SH/n2fEJ,QfE,mn.;]4l`;rCJ%:"\i70P.E<Tj[b!PfOPTE1njJ.5K^FFOH_>_iGM"Y'[UkQdsckRgeuF>!e$F9)OK5A^SN"f;<V"`4E-D$@]ZV?,TUD$?I2"`;<]V?,$JD$;A*"U-8Bbm+\_L]N2?"Y'[UkQdsc\/\MA!N#mR"]_c3V?+IW<<[IF"U/uK"U.e@"X'ZCVu^`=SH/n2\-Jl3ciIte.;]6]!i?"6,?4o?!U9enp]YP@<CM*8"U0#"!<iXK!<iXt!<m=2V?)JVD$?I2"`:1?V?&)^"Y"9l"Y%+m"U-=q"U-&,/HqdJWWG=P64N\p70]D#70ReB!X2#:"U,&W74e[c"U+o6zzz!!!!*!!!!I!!!"+"TSPl!!!!#!!!#3$31(=$31(=$31'3!!!!_!!!"-"TSN)"p,,=JrU!<FMS"^"a%9V"U0"Q!X/`X"XO=o!<iWk9a1"gV?+I89a.'g"\lc8V?+a>9a)t?"[,-g"[t_e"pHl!"W[bt!<q9[,qU\p"`tgi"`sbK"e>Yt9ooLT!LO!a"e>Yt9n38A!Vc[i"Y!.L"UhF<h$bS6L`7Wl6,4NF"Z?N1"`sbK"`sbK"]A%ukQ@[_fE"\MSH/mgkQ@[_^][@8SH/mgJ-;_MTEe0p.89sL#L*al!A+M3)_EoN"gn^q#1*]7"`u*q[1Z*F*Mj5L)&3;YS,jq7#3[4g!@];uFGBl#"Z?N1"Ucp\!\FV4)_D58;$@,F!<iWk9a0_aV?*%e9a.'g"\m>JV?+I59a)t?"U,8[h$551L`>.Q%@dGNW!3EIF9NDL!B$e["Z?N9,qU\p"Y0a&!=f)0zz!'1>b!'1>b!'1>b!"Ao.!"Ju/!!*'"!&Oo\!&Oo\!&b&^!&b&^!&t2`!&t2`!&t2`!)*@m!!F8a/2ROaN<KK-+U&$k)$M%N!>SG(#&+M]"a'tP"`sbK"e>Yt-*RQM!FR2WSH/m?O9;?\?mPuI!<jeE"Ju3U#:0O&,m=_`"U,("!L3jcTE]*>'b-Z6'i:P-BakdlS,q.H:nS#,%2B%g(BqJ^)SHHR&-[//"Td]bzzz!!!<*!!!9)!!"DI!!$1&!!$1&!!#Ig!!#Ig!!#Ig!!"#>!!!l:!!"8E!!#=c!!#=c!!#=c!!#Ce!!#Ce!!#4`!!">G!!"&?!!#dp!!"PM!!")@!!$4'!!"_R!!",A!!#Oi!!#Oi!!#Uk!!#Uk!!"tY!!"tY!!%!=!!#Ce!!"#>!!%oW!!#Rj!!"&?!!"hU!!"nW!!"nW!!"nW!!"nW!!#7a!!#7a!!#=c!!#=c!!#=c!!#=c!!#[m!!#[m!!#ao!!#ao!!$1&!!$1&!!$1&!!'P0!!$O0!!!r<!!(1B!!$^5!!!u=!!#[m!!#[m!!#[m!!#[m!!(gT!!%<F!!"2C!!#Ig!!#Ig!!#Ig!!#Ig!!#ao!!#ao!!#gq!!#gq!!!6)!!%cS!!";F!!#[m!!#[m!!!`7!!&2_!!"AH!!"GK!!&Gf!!"SN!!"qY!!&Vk!!"qX!!#:c!!&tu!!"kV!!$g8!!$g8!!$g8!!$4(!!'J.!!"tY!!%$>!!%$>!!%$>!!&Gf!!!K/!!"\Q!!"\Q!!!E:!!!E:!!%WP!!'t<!!"SN!!%uZ!!(@G!!%cY!!%$>!!%$>!!!3'!!"VO!!"VO!!"VO!!!'#!!!'#!!!'#!!!'#!!"VO!!'P1!!)$Z!!"kV!!(+A!!)?c!!%l\!!!cD!!!]B!!#P!!!#V#!!#V#!!#P!!!#P!!!)6a!!)uu!!%ZV!!*$"!!!0'!!#Rj!!&5`!!&5`!!&;b!!&;b!!&Ad!!&Ad!!&Gf!!&Gf!!&Gf!!")B!!!c8!!#"Z!!%0B!!%*@!!%BH!!%<F!!%TN!!%TN!!!W6!!')&!!'/(!!')&!!')&!!!34!!!34!!!34!!#Xn!!"VP!!#^n!!&Sj!!'_5!!'e7!!'_5!!'_5!!(dS!!(jU!!)!Y!!)'[!!)'[!!%'A!!#4a!!%'?!!)'[!!"hV!!#Oj!!#Oj!!%iW!!#Ul!!)<e!!!]=!!!c?!!!c?!!&Pk!!#t!!!$[:!!(FU!!(@S!!(@S!!'8*!!$F.!!$1'!!'M1!!'S3!!'M1!!)Ki!!)Qk!!)Qk!!(CJ!!$m;!!$p=!!(p[!!)!]!!)!]!!!]=!!!oD!!!uF!!!uF!!"&H!!",J!!"&H!!"JT!!"PV!!"JT!!$71!!$71!!)s!!!%`S!!'2*!!$71!!%l_!!%ra!!%l_!!&`"!!&f$!!&f$!!)Ki!!!W6!!!]8!!!]8!!%NL!!%lV!!&)\!!&)\!!&/^!!&/^!!&/^!!"eW!!&Vl!!(CL!!#Cp!!#Ir!!#Cp!!)Kr!!)Qt!!)Qt!!(p[!!(RT!!(XV!!(XV!!$"$!!'5(!!&hq!!#Oj!!'A-!!'A-!!$^8!!'S2!!%BN!!!-2!!!34!!!34!!!34!!)Kr!!')/!!'/1!!')/!!')/!!%iX!!(.B!!%WU!!%$>!!$7(!!$=*!!$C,!!$C,!!$C,!!$C,!!$I.!!$I.!!&u#!!(gU!!"kV!!!!STofK^FK#]Q"a$FI"U0"9%0aEMO9)0Y"f26)^]gP8[/hE6.0ZOKC'>U]JH5qF!L3lkV#^`'FR]J;N<(0C'Ero""W[bt!<mTL-QRU=F9)OKF9)OK15uA>ci^-G=H*CdSH/nR"7QAh!I0S+"Y#E5"oSUd!JLOXK`PGo"bd!%#=5j."U0"a!<mloi!T^*C'>U]JH5pc"Xb=-"a'PC"U/uK"U-Z@!sRlkV?+a>N<9?T!<nGbn-#ThkQ?eH"Y#E5"hb4W"W[bt!<l1$-QQ4[$BP9o"^PBK"^Psf\0_AbC'>U]JH5pS"Xb<rbls10AHcXM^]e:l+IF5S"a&u0"bctl"W[bt!<mlT-QRmA"a&u3"\!/0*<gup"[*#:*CZM)O9&&Z9jGI;9jJll-3XQp!<iXK!<iX)N<9>LV?*>'N<9?T!<nGba:P3L+H6I,.?+E59kjhP"[`G^"Xb<b237i="]\gC"]]+Va:8@WFS>e>"X,HD"Xb<JKa3\?4U!uR^]ck)FD1niC'>U]JH5p["Xb=%o`^EXD$=c]^]eQYFO'skPlYV'*<gup"cWNd-QSHQ"a#S'"f25(i#AKn"dB%E(Sq-9FMS%_"`sbK"Yu&>"m@80!T4-@!sP4r"cWWB#GqO3&rcts.?+E59d&X-"hb7X"W[bt!<k=a-QP@X!K[=N"[u\3"[uE6J1(R)FJK!BN<t[IPlV&R!F3DDPl[]^+P8%F"a%rh"U/uK"U.e`!sO2VV?,T[N<9>KN<9?7!i?"f"-!BdSH/nR",J%r!It93!sL-5!sSW5O9'J-Ff5>V"hb4r!?e$I"a+P`*<gup"`4Dj*Hg`UO9'b5I9aPkI0F^o"e>[/"W[bt!<n_h"Xb=]!<mQe"oSOb!K@*`N<*;""cWPR!?daK"cWOt"W[bt!<n/X"Xb=M!<mRu!X/aL!<iX)N<9@"#GqO;#E8fhSH/nR"7RS5!K[kP!sL-5!sOYf^B'l+"e>[!^]g80XT9Qc%g<,YX8rJ.F9)OK;N1b^LaJu"J-Co7"e>YtN<=tZV?*n5N<9>5N<9=fGHh2QPm0h)!<iX\!R1WK"Y%t&"o&XCeH*nq"a"G^"`sbK^`#32!q70-!`,0kr;up!%K-?a$O*(%"n_r<%;GbBo`>;f!<r,tn-5`jn/q<)"Y'*G"m?n>eH*nq"Y$8N"l09Y!<p^K"a#t0"U/uK"U.e`!sOK0V?-H7N<9?T!<nGbn.MT!^`SO<"Y#E5"jI/2!R1WK`;p1I!n@>%!=$=YeH#hq!<iWb"jI&OK)sL'`<QR2!N?7Q!<mRr&I#ia@)WG+"2+k;SJd+m"eYnE"<@YfcNFCTPQ@HZeH,nr.0YD2!i5o$V#ahO(Sq/?!?h.F"f26D"U,'OYn.'BF9)OK;N1b^a;LiUO9^aI"e>YtN<>h!V?+I\N<9>5N<9=ff)Z'2!X1%WjT:MnC#oEP!X0t-!n@>UFI<.5"_6'`eH5tsi<'5eTE.Y"jUO``*<hZ.cNG6lF<LekH3FH]-)CeL%0kH+%0^iA"U0#G!<iXK!<iWkN<9?o%Aj0a"-!BdSH/nR".1L6!O*W)!sL-5!sJk$!J1?+$jCaK"9esN!<iWkN<9@*%&O'H!K@0bSH/nR"3:nJ!S@R8!sP4r"cWV_$)R`R,`Mm0.?+E5"Xi[<SHf=k!La/Q!X4&Wh#[a-h#Z=5"eYne"m#dhF9)OKIg+X0"a'tP"`sbK"]C<^"c+(o!Vc_U!sP4r"cWV7'W(p+,`Mm0.?+E5"XVCph#c[>+Lh[\"Z?P?!X0t-!n@>UFG'c#"`sbK"]C<^"lL`)!O)]d!sP4r"cWVo#,VF2-&i!1.?+E5"kit\m/[Y#L`Q-ho`59,(\Ie<#)F;u!W<$'p^6s#%0hV/K`Zr0#4O*r!f[7-]`nY"!X@9uN<09*YlP"3F9)OKSH/nR"5"Qi!K[AB!sP4r"cWVO.Ad-]+cQR-.?+E5"Xd=+!<k@beH#iH!KmN?!RN3.h#Z%,"eYnU!Sme7)JS".eH#iH!VulR!<mSE#6b9\"gnC8-f"g2!X54tOp&H""b-]`!X3\N"9ere"l079!f$d[X9JiMq$@3.F9)OK15uA>cm>Oi0T?/<5E,aKcm>Oi0T?/<SH/nR"3;CX!IuJU!sL-5!sRKj#)F;e"ILNMm/`1J"eYn-"cWQe-f"fg!X54t_?-80"b-]@!X3ZH"U-@ZPl_+="e>\u.A[(L"Xi+,XTAZJ!<iXK!<iWkN<9@*+Jo/NN<9?T!<nGbfFat]\13I?"Y#E5"U1P"iWf&Y"b-]X!X54tM?^0a"Xi+,[/pMRYm(@8F9)OK;N1b^a=*nd^`JI;"e>YtN<>7eV?-H.N<9>5N<9=f)?meU"Xi+,]`JA1!La84!X3\>!X/aL!<iXt!<nGb^^-e<fEI6:"e>YtN<=tDV?*=tN<9>5N<9=f-`m^"!X54tiW@X3"b-^#!X3])"U,'O!<q*d3;ioG&cDc,clDucr;mH,!jEgO;Y:(pi#lb4!qcTuSH/oe!iR6=!N6:s!X1%G!X/`h"gnC8-f"g2!X54taof<Y"b-]`!X0t-!OVt4TE-g]!X2H+!X/aL!<iW^N<9?o,,PAXN<9?T!<nGbn04_1YR?Em"Y#E5"cWd:[/pL8-f"g:!X54tU&i47"a$F?"U0AZ]`J?d]`JA6!X?^]`<+![#(Rl9!i5r&a;3#%"eYmj#Lrm++_fI.blS%rh#Yb%"eYl7eH,o("jI)P-f"gJ!X3ZH"U/uK"U.e`!sSH+V?-/jN<9>KN<9@Z$)R`b#E8fhSH/nR"-<hd!Oru+!sL-5!sJk)!TF7\#6fS\blS%rh#Yb%"eYnE!n@>UIg+'u"Xi+,blS'A!QkGn!X3[K"U0AZ[/pLZh#Xnb"eYn%!keX=FK>]NTEo8f!S%2STE12Vh#ZU<--ZVtjT,S\($,JX!=%0am/ck\+L!=!"a&6#"U/uK"U.,M!sOc)V?&Z9!sP4r"cWV_(T%6&*K:.).?+E5"b-^3$3_g5!R1ZLTE2>$eH,o("jI)P-f"gJ!X54t_?SNl"a%ie"U0AZ]`J?bh#Y1j"eYnm!Q>*DFL25U"`sbK"]C<^"iq=R!Up;Q!sP4r"cWW:#c7XD$&o#j.?+E5"]ch\!X4&W[0#^r#)Er#!X3],"U,'O!<iX)N<9?o.Ad.8#)r]gSH/nR"/lR(!Vd@g!sL-5!sJl+!O;pS!X1%'!X8N4L&p*3"m#e.\-N6AFR0;;"b-^#!X0t-!R1ZLTE4TbeH,o("jI)PFL28V"`sbK"]C<^"m?Vs!It?5!sP4r"cWW2,GkM2$B5,k.?+E5"Wk;c"U0"'%0\TnJ0:rp"_+k?[1&#sO9*#q"haqA^]hCPblJsN$O+3EG6J/P!="W%`;p-a!<iXK!<iX)N<9@R$)R`R.ZFN6SH/nR"4.^Y!Iu&I!sL-5!sSW+_u\*`"U0S\blJ!U!CI%@!<n\grs@3V"a&W2"T\i.zzz!!'Y3!!!B,!!!B,!!!$"!!"\Q!!"\Q!!!!&d>\;5F;Y5cF:eZ[F9r-L$?M10r<WXL!<iWk,m=RO!FR2WSH/m?^]^M8a9!Xk.4#-,#R(A8-OnT,"Y0`k"`u*q!=Af,zzz!&+BQ!"/c,!"/c,!650A!0@Ec!0@Ec!0@Ec!0@Ecz!!*-)e;XV8F;Y5cF:eZ[F9r,9&7;7JjUDB8!<iX),mDp%V?)Ju,mBh?"XUqeV?+a>,m>_D"U1k+TE`16%=&*\%:&ZS%0_4b%0^hS"U0#P"U/uq"T]SCzzzz!!!B,!!!N0!!'A/!!$U;!!$I7!!$I7!!%$G!!%$G!!%$G!!"SN!!"#>!!'8,!!$O9!!$O9!!%6M!!$=3!!$C5!!$I7!!$I7!!$I7!!#^n!!"SN!!'V6!!%<O!!%6M!!%$G!!%$G!!%$G!!$X3!!#"Z!!'S5!!%-A!!#4`!!'V6!!!'(+Us'a"U0#D!<iXKnGrdsFQif0"a&]("U/uK"U-Ym"crh`!FTIB;Ip#n"/Z+W#A"''AHc25!FTIBSH/n*^]^M8n,m5*.:iYdTE,Z_\-6S(/KK$="U-7oXU<;S2eX38.KqC-FQif0"`sbK"[?Q%J-;_ML]h8mSH/n*p]75mfEGgi.:iZ'>_iHH!<jqV/a*G:!K\BT"`u*q"a'tP"Xsla"Y'Zj*C9r)#9=#q#9<tiKE25[F9)OKSH/n*\-/Z0p]P.3SH/n*&>fKL!G)E`AHa@p2$KWVC%VNZ"eYmr#;s!pBf.I_G6J-R-QNX"FIW@8"`sbK"]An8\-Jl3#\=11!<m&]"f;=1!G)E`AHh9&V?,m1/L<S<"[,/5%L#9ep`fr:6%BsZ<C-C-"U0"t!<n_m=iCLA$ipD0!!!'#!!!0&!!!W3!!)!^!!!!&er9hB#R(AH*"@]-'o)en#mGEZ"U1+k;&'7V!<iW^,mEc?V?('N"]?WMn,oNgTE?JDSH/m?p]RGpL^,40.4#.o#eL,Q$O$]U!<iWW"Vhb<O;8!'F=.7j#^*fh`<lVPzzzz!!!!,!!!!.!!!#)"TSQ%!!!"2$NL0=$NL/O!!!!7!!!#)"TSN($4[0lN<KK-)$L1c&Hr>[#mCKS!<iXK!<iX)'a<4jV?*n*'a:-/"VnfUV?+a>'a6$$"U4>q%@@>/LB.Q%"`t%Sh&Aej'\*9pUB(f-"Zlks"`sbK"]?'=O9DE]J--MiSH/m/J,uMJp]2*5.2<!i9*GJ"*<6'>zzz^&S-5$NL/,%0-A.%Kc\2cisIMcisIMdKT[OdKT[OdKT[O-NF,H)#sX:zc3=7KcisIMcisIMcisIMdKT[O56(Z`.f]PL&H`"5,R+5Kz,R+5K,R+5K!WW3#@fQK/3<0$Z%0HS1FT;CA5QCca&-Dn4K)blO;#gRr%Kc\2V#UJq=o\O&CBFP:[f?C.@fQK/D?Bk=aT);@D#aP9C]aY;h#IETK)blO&-Dn4(+9Gn&n)mu;$%(5#"/q</3k+5*ZP:fa,U<,FR]D9"a&u1"U0#,!X48t:#ubZ&I!7W"U1Ft"Z=p5V?('^"e>Yt28B?l!QY=""Xu;4%@dI$#cIqB*#7*N"a&]*"f26i!?J*C"b-[jXT=pm'po1/PQ;(*"a!lN"`sbK"]@2]O929[-oD1!!<k?B"/Z+G"#U622$GJG!U(44"Zll&'cI7h$5Ecl()7!pDZp;df`;6[F9)OK;DeW>#GqOs">p?<2$K'HV?('^"[=jJO9_W`?o8+Y!<k@M"Ju4P"uQQ52$G"j!>Y))h$5:*'WhNRKE25k*Lm-Fn,]Nm8q7EmW"`qd'a8]G!<io<"U,Wd"U,Wr!<q-Y"`sbK"]@2]kQRgaJ-@e6SH/mOcip9I\,eGj.5_842E:pEF9)OK;DeVsV?)2N2$KNO"Z<dpV?,$E2$GEd"U4,kklV(mF9)OK;DeWN)l<Z2!]:.P!<k?R"/Z*\!At$02$F/I!=]bYLB.Pb"`u*q"`sbK"]@2]a;:]Si$(#^SH/mO.&I$4!At$02$KWWM#dbp"a&]("Vl:t"Vldn"ZZa.!<iX)2$K?^V?)2N2$KNO"Z=(AV?,lk2$GEd"U+s!"U/uK"U-Y="h52B!>mZtSH/mOO:.odJ.jdD.5_;-""=rg'ncSk'a8^,!<iXK!<iX)2$NaWV?*n*2$KNO"Z=p8V?*Ur2$GEd"W^ARn,XPT'a:NMBcRolFIW@8"`sbK"]@2]ck<2Va9+:'1,T6^&uG\c"Z6IS!<k?:+/T'h"#U622$MeGb5hdJ!X3ZH"U.d]"lLDu!It>2"e>Yt21Pb*!SAYT"Xu;4"Y06I"U/uK"U.d]"cs7l!It80"e>Yt2;f[U!QZND"Xu;4"\Jq%!BU8]zzz!.FnJ!&b/a!&b/a!&b/a!"f22!"o83!&t,^!%.aH!#tt=!'(2_!':/\!&"<P!%\9R!+>j-!&afW!'CDb!."tP!."tP!-8,?!'UA_!'UPd!.OtK!(?kf!#l(A!.5+R!.5+R!0I6]!)NXq!%nET!2BMo!*B4$!%S3Q!)<k$!)O"&!)O"&!)O"&!)a.(!*0F,!*0F,!*0F,!*0F,!6"p<!,_c:!$h^J!8dbV!-J8A!$_XI!([Fs!([Fs!([Fs!([Fs!;-<l!/LUT!$qdK!(7.o!(7.o!(I:q!(I:q!(I:q!$)(?!13`d!$;@E!'gkk!'gkk!&joY!2KSp!$MLG!(7.o!(7.o!)EUq!4i.1!$qdK!-\GD!6G3@!%%jL!0mQb!7CiI!%.pM!2fht!8@JR!&4WW!4`+1!94%Z!#u.B!6G6A!:0[c!'UPd!8@MS!;6Bm!&+QV!:Kpg!!`N)!%\9R!"f84!"K#0!%S3Q!,MuB!$MCD!#Ye;!&k&]!&XfX!$_LE!%e?S!(d4l!%e3O!#l(A!!WW/$5O*g$h98]"`tUc"`t=["`t%SSKFI)Kc?Qu%=&*\%>OrfW=9#Q\H<!=F9)OK10"MI!i?!+<<Z9#"n2Sj!Peb:"e>Yt<T!nT!O)`-"Y!FTV%,^9"Vk:p%M].s"Vh1i'a5>*!<jbQF9)OKF9)OK;H3mN"Ju3M"]Y_s!<lKu!N#nM"]Y^T<<WO[R/mHpF9)OK10"MA"Ju3U"B>V'<<_RhV?,T[<<\oo"]_K&V?,l_<<XgO"oSs7a:fjW6(eho-$KLr"dB%E%j_C$!<iX)<<_ReV?)2N<<\oo"][OZ!T4#Z"Y!FT"Xpni"U/uK"U.e("gA-,!T5/%"e>Yt<Oa'H!Or22"Y!FTQim<g"UtVa'a5>*!<iWA64MQL'aD__'chQO"U/uK"U1+k5og,Nkm@S'Gm+?\>hBJpN<95&"V#YZ"U/uK"V$4f"h=pCFR]eDLa-US'a8^`"U/uK"U-Y]"e[9@!LO!i"e>Yt<TkF"!SADm"Y!FT[0Cm["eZlM,om/2i<]\N!FZ-@"`sbK"]A>(YSa5<J-ApVSH/moLa&\sW!$*(.9-NT2Yd[`a9?8m%1PW=Qj(/5!Yklh#&+e]"cWPE%>Y2t65>jk%:"E.%1R%u'b*h?Mua*(!<iXt!<lKu"/Z*T"]Y^j<<`."V?)JV<<\oo"]_30V?*Ur<<XgO"Vil-!Sn.n#07#Y'mTrdcie%t%0^iV"U/uK"U.+j"b6]P!JgnZ"e>Yt<T"Xi!It>R"Y!FTcie%t`=!]V!=e5o%0j$=%2GW='a4b__uU#FF9)OKSH/moL_lohL]pc^;H3mV(T%5;##tht!<lKE*Mrk1'3,2b<<XE7!Sn"E!Y#@<!t?!?!>PbQ1^sm'#07#Y"e5T.J-H1!nGre.Gm+Au%quaf%71NV!u6(b"U0#G!<iXK!<iW^<<\0gV?)JV<<Z9#"c*Yc!?bAGSH/moi!lOaO;q7(.9-P*#9+DF"iU_.!>Pcg#&+e]%71es"b6f+"Uto-'po..F9)OKF9)OK;H3mn,,PCV!`]Dp!<lKu*i8tr$rmH[<<X*c"U3O,Bb_'d64MQL"a'A;"U/uK"U.e("iqOX!Jh:e"e>Yt<N%.>!MC6/"Y!FT"`sbKJ/B5]+[nhT!<icu6+@4)"dB#o77BN#.0W.9kU/ef%7Q@-"]@JekTFS.4U%AW"[2>fV?*n24U!8t"b7.u'b)0e%Hmj&#-\1='r(dE"U/uK"U/uK"U.e("h4o:!Pen>"e>Yt<Ic!b!RMW_"Y!FT'eTq)%0jlY%0`7&'n?K'#2gmEi$`:S%3:r>%Hmj&#-\1='r(dE"Vij'%0^hS"Ut[W#7Uj,!>U+h'aD__'a8^""U,'O!<iX)<<\a.V?+I6<<\oo"]`VbV?*%i<<XgO"XQVA"iqWs,om/2LBRhbF9)OK;H3n1%Aj0!"'#Mq!<lJj.&I$L*`W@m<<Wi7!Ped@"Y0`c"`sbK"Ys']W#VZ8L]g]]SH/moW!T=%cj<\U.9-QM%RFJ+"a$pN"U0!A"U/uK"U.+j"i(nN!LO!i"e>Yt<S/Il!T45`"Y!FT*<sS(/M25o"XO;,"YBn"U]L]'F9)OK;H3nI&>fKd#?:qu!<lJb+Jo1l,uk*t<<XBta:fjW6+@L1-$KLr-&2L)LBRj'!<iX)<<\I'V?)2N<<\oo"]^X0V?)2U<<XgO"U2.3OT>UhF9)OK;H3m^-)L_,"]Y_s!<lJb#c7X<*E<7l<<WQT!<iWQS,j(d!u6)-"U/uK"U/uK"U-Y]"m?Al!FSn2SH/moJ.e^[LauI/.9-Q5!J^[ZrrN@G56W&3TH,=1GpNV?"G?k/"`sbK"]A>(O=-n+J-ApVSH/moO<18"O:tUt.9-NT=hb(C"`sbK"]A>(J0h&n+B8S#<<[n!V?)JV<<\oo"]ab%V?)J^<<XgO"f2==!=e6<"dB&V#RprZS-9&s"onW'!WW3#O95I_O95I_O95I_c2[hE%0-A.(B=F8a8l8@!!V,:"Ut_@"Vi!dL]nNK!<jnUFHHS-jW,/&)r2S>.g6Y&6*MX="`t^f"`sbK"[=::YQ^m)?mPuI!<jdZ"/Z+g"!n+",m=I:!ADCn"`sbK"]?WMp]75mJ-@5&SH/m?n,fHfGU3MB,m=IP!B1/s6*Ma@"a!6<!=Af,zzz!!rW*!!iQ)!#u+A!##>4!"T&0!#bt?!!3-#!&=f[!&=f[!6tQE!%@mJ!$VCC!#Yn>!!*91k)BNJFE%HfFD1m^FC>>!Gm+?T-OhX2-P\L%/-Q1\V#^`G"`sbK"]@bmYQ^m)J-/4DSH/m_\-&T/n,l)_.7FCDL]Je*"W8$Y7gBde(^5!f"hb6eSH4uW"`sbK"[>EZJ-;_M?pt5s70S2EV?*n=70T4_"\!qHV?,<Q70P,/"h5HA!?^\1"`sbK"]@bmTEh=pJ-A@FSH/m_VuigsL]^'L.7FCD/k6'Gz!s/rF!5sj#%KHJ.s8W-!#6b83"TSN&!WW3#"TSN&%fcS0L'%DUp](9o$jQb4$jQb4!!Ur5"Ut_@"Vi!dL]nNK!<m0@F:eZk6')ic"a!TF"`t^f"`sbK"YqA-n,oNg?mPuI!<je-!N#mR#:0O&,mErF6,3j3"`tUc`<$FT)>+OEPQ;(*"`us4"Y0`k!<<*"!!3c?!5sj#%KHJ.s8W-!#6b83(]XO9zzz^'F]=^'F]=^'F]=%fcS0&HDe2BES;8dKfgQdKfgQdKfgQc3OCMc3OCMc3OCM0`V1R*WQ0?!<<*"^'F]=^'F]=-ia5I70!;f.KBGK?j$H0_?^,A`!?>C`!?>C_?^,A^'F]=z!uqL^#P<uZ"a%!M"U0"I!<iXKT`G<3Gm+?TPQ?%E"a&Du"U/uK"U-Y="n2Sj!Jgk9"]@2]YQ^m)YQcrgSH/mOi!#tYn,kNO.5_8<p]2-)#2KQ1"U4B#BcRol.2<"$KE25["a&]("Vl:t"Vldn"jm>SF>j@,F9)OK;DeXA#,VFZ!At%O!<k@-"/Z*t!]:-12$FFo"U,?j!<l^3F<:\2$]+o7)tagIF9)OKSH/mOfES2R?o8+Y!<k?:"/Z+o!]:-12$FGZ!=ef.'aF.4'buB&"U,@*!>YA6"eYmZ"s!kh!<qrtBcRolF9r*SFM@h["a'tP!AFKRzzz!3cG'!3cG'!"Ao.!"Ju/!*9.#!3cG'!3cG'!3cG'!$qUF!$)%>!*fL(!3?/#!3?/#!+5d,!(-_d!%.aH!*0("!4W"/!4W"/!4W"/!4W"/!3?/#!3?/#!3?/#!+,^+!&X`V!)NXq!,V]9!'1)[!*0("!-\DC!(6ee!)ERp!2';l!2';l!1j/j!1j/j!1j/j!1j/j!1*Zc!)ERp!)NXq!20Am!+>j-!)`ds!4W"/!3cG'!3cG'!3uS)!3uS)!7(WF!,hi;!*B4$!2';l!2';l!2]_r!2]_r!2KSp!2KSp!:9ad!.Y%L!)W^r!2KSp!2KSp!2KSp!!OZ#<B13ha,U<,FK#BH"a$F@"U0"9"9gB4!<pRG"a&u4"U/uK"U.dm"ULt+i!2[SSH/m_p]RGpfE"DE.7FCdBWr:)4Wrr'"YFp%"XOB:(c=1+!<m0@FK#EI"`sbK"[>EZhufhW?pt6i!<knoV?)b]70P,/"Vmd5"U,WGfH:n42?f'@'r1jF"U/uK"U0"A"9gGe"Vh2_d/aE)(BN=t`>f&'!<iX)70WGfV?,la70T4_"[t,B!>%['.7FCD7g0&267%^1'r1jF"Vldn"h=^=FH6G+%0hV$/JW"H,o')WMua*(!<iX)70UI-V?,T[70T4_"\%VUV?+I:70P,/"U-mi"Vmd5*<d/pi"Zt9#1sP7"a"hi"a&5p"U/uK"U.dm"eYsp!MCW*"e>Yt7IV.k!H:I2.7FCT.1HFq>i6nC"Z?N!%7L^@'g`YV'a8\&"V%4-"U,??\0DFd2?aNnFG'Yu'jTZ3'b(B"&g[tkL_;9SC*b/@9EftK"`sbK"YrLMTEM+m^][(0SH/m_a;:]Sa94p8.7FEJ$O2t&2)U-i"i13CFNFOe,mL"H2)U-i"fVM+F9)OK;FLc!&uG\["[rTc!<koR$`3rT'1E'R70Nk&!KdBd"Y0`k/I%RH2)U-i"n)IL+M\'_"Y0a6"`sbK"]@bmL``Jpa9+j7SH/m_^_3LFW"DH%.7FCd#+u/X2%^#\!<mQe"Y!j`'a8^R!X1G(^]O`D.g7d^LB.Q0"a%*Q"U/uK"U.dm"n3#!!It5?"YrLMTG+1'Qioh]SH/m_ck<2Vi#P5i.7FCd>d,"r4Wrr'"YEs_"g&%7kSQ/\F9)P&LB.RS!<mT+!X/T,!!!!$!!!!/!!!"I"onY=!!!!B!!!!6z!!!!#!X/e]N<KK-!<iX)/Hs2sV?,T[/Hn?j"ipbB!Jgn2"e>Yt/VjS-!T3u1"Xu#,%ANq-"Uu[F#b;/?,,GVM-)1JM"W_=]'a:E7"V(,2UB/m]N?8=G!<iX)/HtnMV?)2N/Hq[G"YK3FV?(on"Xu#,"nD[!"T\T'!!!*&+qamoN<Kdks8W-!s8N<-"T];;zzz!!*!"!!*!"!!!!$!!!!$!!)ou!!)ou!!!`6!!!Q1!!%QN!!!3*!!!3*!!"AH!!!o;!!%TO!!!3*!!!3*!!!'#!!)ou!!)ou!!)]m!!#@d!!"DI!!%QN!!!''"pXFR"U0#$!<iXKd/aCSFNFOe%@dG6YTss:!<iW1TE2V.'sJs4%2B%g#mCKS*sDgi!<iXt!<k(E!i>u8/Hq[G"YIdsV?*n)/HmRT"U0%V$3_/t!<iW1FAE&DF9)OK;Cr'6!i?"6!\FSH!<k':"/Z+G""a[*/Hlkr"U2+UILR"q.2<!iFCYOa#R(A@LB.Pj"a!6<m1tfbSJ'0h'mTrd'o)en:Bbh@"U.dU"ZW@[J-@M.SH/mGTEh=pfENo2.4k],$'tYr!>PS7zzz!-/&>z!"Ao.!"8i-!*f^.!#kn<!#Yb:!+?'3!&X`V!$D7A!+#j0!58jA!5&^?!(R"h!&OZU!+?'3!5o9G!5o9G!5o9G!6,EI!6,EI!6,EI!-\DC!(6ee!+?'3!6,EI!!3-#!4WF;!!*?2MiIrEFJ/g@"a$.8"U0"1"9mU#ScPZ#XVq@bJHQ,[F9)OK;EY0hV?)2L4U%AW"[2V`V?,<M4U!8t"U/rN"U/uK"U.de"crh`!T42G"e>Yt4bs??!E_Jg.6RhTWr^!>*A'R--3YE6"U,oOp`UY06-pMR*HqYj"a#S&"U/uK"U.de"eZ*t!Peq'"e>Yt4l?F>!Up4T"XuS<%>Y$""W]n=+9`2h'a<\09-"0>FCta\F9)OK5<T1["Ju3U"?coD4U($MV?)JU4U%AW"[2&PV?)2Q4U!8t"W^kC+Up"hJ0tO!%X/'[*F+sW*A*NW/Hl;*'f@RX"Vi&&"U,'5*VBI[6&5[J"b-[r"e5T6Qj*_Y!RCce"a!TF"`sbK"]@JeTED%li!2CKSH/mWn//#'E'4@R4Tul%!VdfY/O@/p"W_dj"U0"$!X/aL0*Mdj"U,?j!<k+[FO'sk!=Jl-zzz!/(^[z!!3-#!/(^[!/(^[!##>4!"f22!6#*A!/q9c!%.aH!#Yb:!6#*A!!NK4!XobKh2MRAF<LekF;Y5cF:eZ[FThpPF9)OS#R(A@LB.Q#"a"G^"`sbK"Yr4EJ,uMJQioPU;EY26!N#nU#<`6]!<kWr"/Z+g!^-]94U&5"c2jjK,mBqBM?Gd_C'>UmGQe6SF<:Z$Gm+?d>f\!%,si'>&d<AI"gnH$!W<Fl"9Af/zzz!!%lVz!!!H.!!!K/!!!$"!!$I/!!$I/!!$I/!!!$("kAS9"`tmk"`tUc"`t=[r;gX*&%rkbF9)OKF9)OK5:$J`!N#m*,m@0m"gA0-!?`ZlSH/m?p]RGpL^,40.4#-,#R(AHU&bGM('Q&p*<gorV%3`P"U+o:zzzz!!!#!!!!!.!!!!1!!!#!"onX$%0-B'%0-B'%0-B+%0-B#%0-B%%0-A]!!!!<!!!"s"onX"%0-A2"crabVu[4_N<KK-R/mHpFHHS-"a#S%"U0"!!<q9`"n`_o('Sd\"U1Ft"\"LTV?)JU70QRX"crh`!Vc^b"[>EZO9;?\?pt6i!<kpe"Ju4("[rSD70Njf!=C]o"_fhG*HqYj"o88e%,D?rFThpP.1HFa.KpP-63[,h*<s:g*<gNc"W^j(!Z_Fo"YJpCV?,<a/Hp5L"T^%Pzzz!!"DI!!!B,!!!K/!!#Fk!!%rb!!%rb!!%rb!!%rb!!"AH!!!l:!!#du!!&Mr!!&Mr!!#"Z!!";F!!#Cj!!%l`!!%l`!!%l`!!%f^!!%f^!!%f^!!%f^!!%rb!!%rb!!%rb!!%rb!!%`\!!%f^!!%f^!!%f^!!$d7!!#(\!!#Ro!!&)f!!&Mr!!&Mr!!&Mr!!&Mr!!%WO!!#Xl!!#=h!!&#d!!&#d!!&)f!!&)f!!&)f!!&bo!!$.%!!#:g!!!-'//1)MSW3jWFFaT!"a'PC"U0#<"9n`E=Odk7!sNcI"U-YE"c*D\!FS%o5<T1+#GqN04U%AW"[0X(V?$rc"XuS<m0a-6%(-Vu.=M^@'mU5l'jSNu'dZ-_"U0"q!<iXK!<iWk4U$oKV?*%e4U%AW"[.qLV?,$G4U!8t"U1P">-.oB?3LK9FK#?G"`sbK"Yr4EkQ@[_?p+Zk4U($OV?)2K4U%AW"[.A=V?*=p4U!8t"iV!;"U,Wo!<ioIQiYG8"Vh6g*Yej#-Nt4hW!a=T>gN`k"Xaa*"a#\("YE#r"U-bL(^2Jl'a4b_f`;8L$Dmic)%@<I"kWnl#06r_"a"8Y"`sbK"[>-Rn//#'QioPUSH/mW\,rN.\-G/#.6Rh<TE1bgI2-&l"VhpZoaMW?p_FSb5o9b/FI*"3"`sbK"e>Yt4eNak!JgnB"e>Yt4eMnS!K[=F"XuS<"fMI0$G?iW#06uX'g[Wj"U-df%0^k/!<ip;fFAW"Ig$PrS,j@t+;J.[#8IDaj8fDfFThpPF9)OK;EY2f(o@<V4U%AW"[.YcV?*Uu4U!8t"V"<4kTgUm!<l.#FOU<p!B0uYzzz!(6nh!+l<5!+l<5!"T&0!"f22!2]bs!(6nh!*01%!*01%!*01%!%e0N!$2+?!4r73!-//A!-//A!-A;C!-A;C!-A;C!(d.j!%\*M!2KVq!!3-#!(6nh!(6nh!+>j-!&srY!3#u!!)<Ur!)Nat!)Nat!)`n!!)`n!!)`n!!.OtK!([(i!2T\r!.4kK!.4kK!1*Zc!*'"!!4`+1!)<Ur!)<Ur!)<Ur!4)Y*!+>j-!2KVq!(m=n!65'>!,MW8!3H8%!-//A!-//A!8dbV!-\DC!4Dn.!,_l=!,_l=!,_l=!(m=n!(m=n!(m=n!(m=n!<3$!!/COS!2KVq!+H$1!+H$1!+H$1!8IPS!#Ye;!0dH`!3cJ(!([1l!!OAU(^pNOfo?4>FP-^!"a&,n"U0"i!X/aM"U0km*sKF^"a%Qb"U/uK"U.dU"n2Vk!C/4?SH/mGi!#tY#V?3//Hll7'a:E=P5u[-"bcst"VkqrnHB)<T`bN&F<:Yi=;C35"Zll&"a&u3"U/uK"U1Ft"YG6-V?('V"e>Yt/bf@D!S@Q-"Xu#,SH1(V%0Zns"Vh2_d/jITK`Mnl'o)en_#hRW0,4X*LB.R`!X3[f"U/uK"U.+B"ip_A!FRJ_SH/mGkQ@[_3%Y:_/Hsr<<ttlBPQ@0U[0d(Z_$1&P#R(A@LB.S;!<mSe!X/aL!<iW^/HrojV?('V"e>Yt/[ugu!Or1_"Xu#,*Lm-NW!9@1/fbZAKE25k"a%if"n_mC'a4b&"Vl_#6kok/K`Mnl"a#+q"`sbK"]?oUVurmtTHYrkSH/mGciL!E5V3-g/Hlmd!<iW1K`Mnl'o)enT`bO@OTPbu*sKF^"`tgi"V_[t'o)en,`Mh+'a4c*!VZU0"`sbK"]?oUa98@@J-@M.SH/mGQiX&b^a1Q9.4k],6b*4$*A8-2'o)enQN783quHs)F9)OK;Cr'&';bfO""a\I!<k(=&#KA`.P1fQ/Hl:l("E[,;[%.EFIrU<"a"/V"`sbK"e>Yt/bfFF!FRJ_SH/mGkU!),YSf"r.4k_B#;6eq'r1kq!X/`]'hnjR>Qkj$XU548FS>e>"`sbK"]?oUJ-2YLhubP7SH/mGi"i0jJ-@M..4k]<4U%Yl'aE##'a6Z&'d]@N'po1/PQ?^E'a8]?!<j45!=]29K`Mnl'o)enE<UGC"U/uK"U-Y5"lK]a!FRJ_SH/mG^`K?RO:NoH.4k],K`Mnlbm9(*"iLEFFS>k@XTTsc"U-sk'a8\,"hatM`>Hi-"`sbK"]?oU\/(qBkQ*7=SH/mG^aGu[YQufa.4k^g!=BPF'o)en-O"U."VitU$j?fV_uU#B'EA+5zzz495E^2us!Z3WT3\3WT3\&HDe2&c_n3!<<*"-NF,H*WQ0?RK*<f56(Z`.f]PLS,`Nh=TAF%1B7CTU&Y/nB`J,56N@)dS,`Nh;?-[s2us!ZN;rqY<<*"!SH&Wi5QLib5QLib5QLib63.&d[/^1,@/p9-SH&Wi!"5W`"U0!&"U/us"U/uk"U0"Y!X/`T4Z,*P!<r9$"a#k1"U/uK"U1Ft"]^'XV?+I8<<Z9#"b6iT!Iu@o"]A>(O9;?\5ZIuY!<lK]!N#mJ!EB:P<<XZS"U1G,TE-VJ"eYn($O&+7*A%G:!<iXK!<iW^<<]<&V?%N6"e>Yt<KI?\!It;Q"Y!FTm0Y:""U0"I!<ip;QjPt[-P]?=G6J-RF9)OKF=.4qF9)OK;H3m^#GqNX+B8T9!<lKe"/Z)Y<<XgO"U.=B4U#rL!<iXK!<iX)<<^_RV?-Gn<<\oo"]^'YV?*n%<<XgO"U3BV2*D*n"[*$2!<iX)<<]l;V?-Gn<<\oo"]`>BV?,la<<XgO"U,nm4["Q$"iLEFF9)OK;H3lCV?+I:<<\oo"]`VLV?*=l<<XgO"Vn!;4UhR:KE;=:'bZcP`?,8*pAkF$F9)OK;H3nI!i>u`<<\oo"]^WbV?'4f"Y!FTV$rss70NjK!C[/DDacYiF9)OK;H3nA"Ju3M"]Y_s!<lJj!N#n5,uk*t<<WQc!?VJ.)?meY4U07K4U!nN4U#r7!X1FckQa97.#S,`!^-^/!<iX)<<]$0V?)2N<<\oo"]aIcV?+1><<XgO"U2dEli@7j"onW'!WW3#`!?>C`!?>C`!?>C$NL/,&-)\1AHVu5F8u:@!<NSXN<KJ''a8jf(#Tq=)2eM%'a8\n"U/uK"U.+Z"c*D\!Vcdd"e>Yt7DK&'!QY=2"XukD-$]Xt"Xaa2"Xb&P$O(VQ"[+C?"U1_'"XTEU<j`m;&I!;'"T\i.!!!'#!!'#%!!'#%!!'#%!!#%[!!!H.!!!E-!!$%$!!'#%!!!$F"OW24%1!+@'mTrd'o)en8Hj3-"bdt2bn?9L"`sbK"]??E#c7X\+rpiX!<jM="Ju4P!?D=m*<l3bIg$8bFThpPF>!du$NL/,zzzcia=K$NL/,%0-A.C'"A8*<6'>('"=7B`\87e-#aOe-#aOcia=Kcia=Kcia=K!<`S`N<KK-\H)j;FKkiM"a$^E"U0#P"U/uK"U.dM"kWjQ!T42/"e>Yt-,9Y\!QY<g"Xt`$%D;e@$k3Ai"UtWW*sDgi!<iX),mAf(V?+I6,mBh?"XWX?V?)b\,m>_D"V"-/"V"_8$k3Ai"Utod"U,'O-Ns[D!=bD#%>Orf*sHb)"k=!"N<oIj!=]#/zzz!;HNo!58R9!58R9!58R9!58R9z!#5J6!#5J6!+>p/!5J^;!5J^;!5J^;!!*3+gl2I@F<LekF;Y5cF:e]T(Dl0J`<c]j"U,("!=bD#%>Orf*!LFu"U/un"U/uK"U-Y-"^%W&L]o(.;C)KkV?)2N,mBh?"XV4kV?)2J,m>_D"f2KM"U,??W!j+=Ig$8b/11T1Gm+?\>c8&?"b-[b"a!ND!=f)0zzz!!rW*!"o83!.P1Q!8%8O!%@mJ!$)%>!.P1Q!'L;^!$hOE!!*'"!;Hs&!;[*(!;Hs&!<*B,!<*B,!<*B,!<*B,!!+q^mu7JSFQ!6("a&Du"U0"q!<iXK\H)j;F9)OK;DeX1!N#nM">p@R!<k?r"Ju4@!]:-12$F-e-*74P-QOcB2?bBQ*$p+T"`tgi"Y0a&"Xt`$"`t^fPnZ`b&EOE+PQ<<]"`sbK"]@2]fEJ,QJ-@e6SH/mOGbtN""#U622$F/c!F,dSLB.QP"a"G^"`sbK"]@2]kQ@[_huP\=SH/mOkQ[mbTEd=X.5_8<k5b_i`=8C>'a4c6!Q#!\'l"a("Xb$2-&2L)F9Qb6"U-7o,mAC_!<iK+!!!!#!!!!#zz"36B)"aU=U"a'tP"`stQm050@#IOm>0E;(Qzz7LT7s8.5Iu4q%Dk4q%Dk%fcS0%fcS0.L#kQ<X\s.9FLn$9FLn$9FLn$<X\s..f]PL)ZTj<q#p`up^7'%q?m9'r!NK)rX/]+!"8i-!Xo&/"q1J37fWMh-NF,H"9ni+;#gRr/cYkO*sM]F9FLn$9FLn$:(.+&:^d=(;@EO*;@EO*CB+>763$uc*<lKDLB%;S8cShk"9ni+2@KQc2@KQc3",ce3",ceT)\ik<<*"!*<lKD2@KQc2@KQc4q%Dk4q%Dk5R[Vm64<ho6js%q6js%q$4Hn7%L`=;$k*+9$k*+9z!sObe+VCT3"U0"9!<iXKOT>XT,GkLo"APNjV?)JV9g*\("U0")!X/aL!<iW^K`M@-!N#nU"bcs\;M>,TJ,uMJJ-(E*"e>YtK`U*8V?-/gK`M?+K`MAH,GkLo"APNjV?)JV:%\f1"U,'O!<iWS4WO]K"U,'O!<iWkK`MA0"f;<V"bcs\SH/nJ!I1IBhueZ6"Y#-+"U-%i]a=om"XO=%"YJXUV?*&//YETN!Vd*UfHR0nTIMO\)5[G]'J0J<"Z8G0"o&<c#/C[24^<dE4U!;=9a,XD!sJjM!<iW^K`MA@!N#nm"GHj[SH/nJ!S@UR!Or8d!<jp+!<iWS4Vcc]>_iDD"Y'[MkQdscfG[JW!N#ne(/;"<V?((!"`u[,-&;S%"^OFP+U)FCTFM,/F9)OKF9)OK;M>,TciL!ETEBlK"e>YtK`UB@V?,liK`M?+K`M?oB\4L4F[;B4"XOm`"U0!V"U/uK"U-Z8!<n!'V?,TYK`M@J!<n/XJ/+p^kT#9W"Y#-+"dK16"U,&W4Z,*%BKZMK"\n1cV?,m19a,Xg!<iXK!<iX)K`M@M"Ju3M!egXYSH/nJ!LNnb!Pg"8!<jp+!<o,"BiRkj9EbS'-Trb5>_iDD"Y'[MkQdsc\0t(E!N#ne(/;"<V?((!"`tOakQdscckT7YTE0oT<O`3H<D<X=quHs)FJf-Cm1(m?`<cPRzzz!!!!a"98Eg"98Eg"98E4!!!!8!!!!A!WW3%!!!!a"98Ee"98Ee"98Ee"98E&$jPXL"U0"Q!<iXKW<!/+FJ/^="a'tP^]U;3"U,'O*sDgi*!HLf!<iWk/HtVGV?)JU/Hq[G"YJX5V?)JX/HmRT"W[fO,2EAB#-\OW'a,U!"`sbK"]?oUO9DE]J-@M.SH/mGJ,uMJp]2rM.4k],p]2NA%1!+@%0j$\'ciYBN=H*qF?]p4F>jB2'+(3?bmOOYzzz!!!#c"onW2!!!!3!!!"C!rr<K!!!!<!!!!"!!!#c"onYi"onYi"onW)-j0b6N<KK-M#db`FFaGr"a#"n"a'tP%@dG6Qj+:\!<ic5F:e\L#(?^j"`tgi"`sbK"]?oUn,fHfJ-@M.SH/mGa9&4>YQZT^.4k],pAk9u'c[\8,6`0R"U/uK"U-Y5"fML"!FRJ_;Cr'N!i?">""a\I!<k':"/Z+W""a[*/HlRh"U,Wd"U1G"Q2q.2"`u*qN=cZ6(mPX5'*&"4zzz.Lc@X.Lc@X.Lc@X%fcS0%KHJ/PQh*f)?9a;.Lc@X.Lc@X.Lc@X-NF,H/-#YMQ3I<h>6"X'1]RLUPQh*fCB+>73<0$ZRK``l-k-.V-k-.V-k-.VHN4$G6N@)d!<<*"M#[MU8cShkP6M!e"9o2C!Y(0M"U0#$!sJjMd/sOUFNFUg%0l#$4ZrqY!\FRt@0HgV!<iX)AHdkpV?,laAHeV*"_HTqV?$s6"Y"!d"i^QH"U0"Q!X67K080u!%5e?O.QoqM!<q-W"`tgi"`sbK"[?Q%fEJ,Qi!!Zq11^XA"f;<V"_@k.!<m%r"/Z+W"(_WbAHhH+>jrQC%o#@R-3ZPV"U.%G4V\-B!<iXK!<iX)AHg]jV?,T[AHai#"kX$V!Jgnj"e>YtA_7']!Vc_-"Y"!do`B^Gn/"Mn60JOW7<\n=2$T-l9hh)X76Lfr!<iWkAHgEaV?*%eAHeV*"_G1HV?,$JAHaMo"b0qa]a4ja2[(LQ*<cTo%4q`2'fA-*"U,(+!<jbaS,jpt.KptQ/L='oKE26u!<iX)AHf"7V?*n*AHeV*"_GadV?%fN"Y"!d"W8$Y%0kH),m=o5kQ3=?YQHI7UB(f-2)Hm:"`sbK,m:RU/Hp6\!<iL*zzz!!!",!!!!,!!!!*!!!"O!!!!6!!!!2!!!"H!!!#q!!!#q!!!!3!<<*4!<<*4!<<*4!<<,r!!!#q!!!#q!!!#q!!!!Z!!!!F!!!"G!!!!)!<<*q!!!!L!!!"Q!!!"%!!!!W!!!"C!!!#g!!!#g!!!#g!!!"A!!!!c!!!"U!!!!5!<<*6!<<*6!<<+Z!!!!p!!!"O!!!!5!<<*8!<<*<!<<*<!<<*.!<<*.!<<*.!<<*0!<<*0!<<*0!<<,-!!!".!!!"G!!!#>!!!"5!!!"H!!!#a!!!#a!!!#P!!!"<!!!"B!!!#Z!!!"C!!!"J!!!#h!!!"I!!!"Kz!<<*"!<<*"!<<,d!!!!&!<<+S!!!"C!!!#g!!!#g!!!#g!!!!6!<<+\!!!"E!!!!B!<<+q!!!"N!!!!l!<<,&!!!"M!!!"+!<<,,!!!"N!!!"7!<<,1!!!"F!!!#m!!!#m!!!"E!<<,=!!!"Sz!<<*"!<<*"!<<*"!<<+b!<<,I!!!"T!!!!3!<<*4!<<*4!<<*:!<<,b!!!#a!!!!9!<<,+!<<,]!!!"P!!!#q!!!#q!!!#q!!!#J!<<,f!!!"J!!!#V!<<,k!!!"T!!!!+!<<*,!<<*.!<<*.!<<*.!<<*.!<<,m!<<*,!<<+A!!!#]!!!!%@9&Bi+UcVW"U0"i&-W5Z_%6bRFL_qdPm@JO$+1PN"`Ygl/OBWF!\FVd'J1m@fGlIHFQ!<*"`sbK"]A>(n,fHfYQRr0SH/moa9&4>YQ\#1.9-NTP5th5i!*mA*Q8A*,m=Ho+U'G%YSo)F#07Q3"Z?N1"a#k."YE%EYQ?B\\.gMH#5ABS"a&-#"U/uK"U.e("c*8X!?bAGSH/moJ-;_M0NA9*<<Xu4!?JBG/I(\F/Hn$9,mACa!sPVFBdFe-#B;$n/OBWF!\FVD%kT@;YTte(FMS@h"`sbK"[>ujYQUg(L]g]]SH/moYQUg(QipCm;H3n)"Ju3u!EB;o!<lJR#c7X4!`]CQ<<[mZpApNa'l@q:"YE%]YQ=uMkl_.nF9)OK;H3lCV?*Ur<<\oo"]Z\B!LO!i"e>Yt<O`:2!MBNp"Y!FTa;3Y6jUN:W63XRp,mLji,mABf"U/uK"U-Y]"jd=J!Peh<"e>Yt<KI6Y!D$2o.9-PJ#6sr6/Hn$9-28!b,om/2aTr'[%r!=1"Y'[%"eYn]!\FRtM$O8:#+,HD"Z?N1Qi^tJ*Rt[?,m>ke"gA%3FHHb2"`sbK"[>ujTG47(L]g]]SH/moTG47(QipCmSH/moQkcJ!\.VdF.9-Q@!GOEf#MfN&,m>ke"gA%[#.P@!/I'iI/M.1Z#;%M3i!(b:FAE&D7hruP"Y'ZrXU/tn"YE%]YQ?B\a<rPC2?bB1FFaGr"`sbK"[>ujJ-)SKL]g]]SH/mop`QF7ck9=^.9-QH#&,B;!TaE',m>ke*O#Ss#(R:;"`sbK"Z?N1J.ZKA*VBSU,m>ke*O#SKFK#BHa<t[J*Sgg;,m>ke*O#Ss#(R"3"Z?N1"a&W'"YBqO'eKSI"XTfVBdFdj"E>^k/OCJ^!\FW'+"[XS"XVM;BdFc'FK#<F"`sbK"e>Yt<Nm(4!T3uY"]A>(YS!`586#ha!<lK=#GqOk+]S[p<<WPJ!<o,<c2gZ7.7I$_*^rL,7Go3jSH/mWTH\)=4U%AW"[.qqV?-/j4U!8t"YBr2#;$*;"XVe+BuLH#"`u*q"`sbK"]A>(^_s!Mp`NQ?SH/mop_]k/a:2,Q.9-Q5"Z%G.%0l;4/Hn$9-1DFZ,osZ)E?tblF9)Os63XRp/I&^!/M.1Z*%_>9X9&R5$#q6p/OCJ^!\FVl'J0JH"XUquBdFe%!c]Li"a&W&"U/uK"U.+j"iqja!Peh<"e>Yt<R<(i!Ji+'"Y!FT/I'!0eI2U>"XUr'BdFc'FNFRf/I&Ei/Hn$9-*Rno,om/2X9&P/F9)OK;H3n),GkLG"B>Vr!<lJR)l<Z*-rgF"<<WOK"XW(0BdFdr$?7?q/OBWF!X3\<!<pgtBe:VGG6J-bKE25k"a'tP"`sbK"]A>(p`$(2p`NQ?SH/moQl;h&cluHn.9-Q5%0Im[/OBWF!\FVT*A&iITIDHE#,iUq"Z?N1"a$pL"YBqW"YBm9"XU)NBdFe=%rim!/OBWF!\FVd'J1m@p]`;R2?bB1FGC))bm8;8"YE%EYQ?B\Qkq>+#2fV9"a&5q"U-df-*SY/,otMBE?tc?63Y^c/I&^+/Hp6g"U,'O!<iX)<<\`uV?*=l<<\oo"]^?sV?+12<<XgO"XWpEp_*fGG6J-RPQ;(*"`uI&'cI8;%2B)o()7!7"Vhb=%EK8!>kf3P"a#Cu"U0"o"pGH&"je_&FA)i=$NL/,zzz1'@RW$NL/,$ig8-)?Km=2?X![2?X![2?X![l2Uea,6.]D)#sX:!<<*"2#mUV*WQ0?)$0d<!XK2=if+*FFEn#nFE%HfFD1m^FThpPF9)OK;Cr%XV?)bh/Hq[G"YILmV?+a>/HmRT"U-=i"VjZ6"c*AW!<io9F9)OKF<:[_':&[,$e64#F9)OK5:m%h"Ju3U">'d4/HpY-V?)JU/Hq[G"YG6*V?,$G/HmRT"Ut_@"Ut[?+r),c!Q>*DSI5Y+,0^?5#-\OW'a,U!"`u*q!<<*"!!3oK!5sj#%KHJ.s8W-!#6b83#QOi)zzzU&tAq)uos=%0-A.(B=F8d/a4I!WW3#1B7CT+ohTCd/a4I!!VME"U0"Q!<iXKW<!/+FJ/^="Y0`k]a9StSK3D$"`sbK"]?WMn,oNgL`duI5:$L&"/Z*,,mBh?"XWpHV?)JX,m>_D"U1q-+6=":F9)OK;C)KkV?)2N,mBh?"XUAVV?)2P,m>_D"U/`t"Vj=b('Ok`0*Mdj"U,V\%>Y0&LB.Q3"`uR)"`sbK"YqA-L]aLT?mPuI!<jd""Ju2R,m>_D"e>ob^^C;LF<:Yd%0-A.zA,lT0c2mtGc2mtGciO1IciO1IdK0CKdK0CKe,fUMe,fUMecGgOecGgO)ZTj<'`\46B)qu4!X8u9fo6/L"U,(c!s7!a`>Aa\"U,&4"U1/"!MC>/%%RV(W$E3s!MC=l%u;)((sN2;$3?e;K`n=i!>s>lr<r_")6F+9-34s[$mu)[%64Rq"U+mc&*O)F#QV(2`<53-!"B+^"9>8/[079FJ.(`Mr<*,^%*\hW!::.f(BjsG!=o/1!!3-#!"KD;!"KD;!%JBW!"/c,!"Ju/!#>b=!9sOa!"KD;!$_ID!#Yb:!!ic/!"o\?!#,hA!#,hA!"o\?!"KD;!%JBW!%JBW!!`W2'bCWZ$4#XO"Ut_@"V$4f"lTIcFD1m^F9)OKF9)OK;DeU`V?+I62$KNO"Z='uV?+a>2$GEd"V$t&(#T9:Mua(cYU4')'a8[c"e>jk!VH`+('Sga"U/uK"U.d]"crka!O)bc"e>Yt21P_)!Vc[Q"Xu;4%4`1O"r.?H-5@8K!<iW9S,jA_"pLY#H6!02!<o\SBcRolFFOH/Gm+?dLB.R."`tgi!?_@Bzzz!8IPS!"/c,!"/c,!(m:m!1!`f!0dTd!0dTd!!3-#!.Y1P!.Y1P!$qUF!#Yb:!'pYd!/(IT!/(IT!/:UV!/:UV!0@<`!0@<`!.Y1P!(-_d!&4HR!(-ef!+c-1!'1)[!(?qh!/q$\!0.0^!0.0^!.=hI!(R"h!(6kg!/^mZ!/^mZ!.k=R!.k=R!.k=R!.k=R!1a)i!*9.#!)EXr!!OVj!Y>J>RuRXUFD1m^FC>=VFBJdL#mn!LSHf=?!<iX)2$F8_!Up:N"e>Yt28B?l!QY=""Xu;4h#X)J'a4cQ!GWVYIg$PjFSQ"B%1!+@%>Orf-O"V.!sJjM!<iX)2$M>/V?*n(2$KNO"Z9DZ!K[FA"Xu;4"_n2U'ncSk"V$t&'po4#-@Q+5'ljHm"`tUc-(FuNQj02fIK^GiFQii1"`sbK"Yqq=a8r.=?o8*c2$JL9V?*=l2$G`m"b6lU!Jgk9"e>Yt2)(m.O9[WH.5_97#4NNGoaAG6\-<*_6+@+&/O?lN"XR+O'poJ["Vh2_@0HgV!<iWk2$LJpV?('^"]@2]\-Jl3i$(#^SH/mOcj$?JkQNgI.5_:e&Te3T#mH:hp`J,k"cWP5.C]H`FRK56"`sbK"]@2]5c+Q)2$KNO"Z>KQV?)2^2$GEd"VniS'sK,%#4NoR?mHI%Qj8'D'cieF'rV<?FMn1`"Z?5f'bpqo"r/.E\.o/NFH6G+"`sbK"e>Yt24t)L!FRbg;DeWN"Ju4("uQRT!<k?R.&I$d">p?32$FFT`<9#1#&+M]"a'tP!AjcVzzz!2]_r!"/c,!"/c,!.Y1P!;m*&!;m*&!!!<*!$;1@!#5J6!"oD7!1!lj!1!lj!14#l!1X;p!1X;p!$hgM!$hgM!$hgM!$hgM!'^G`!$qUF!##J8!%J6S!%8*Q!$hgM!$hgM!#PtA!$V[K!$hgM!$hgM!*oR)!&afW!*o^-!58^=!5&R;!4W:7!4W:7!87\Y!87\Y!.+\G!(-_d!)3Rr!1!lj!1!lj!4W:7!4W:7!4W:7!;m*&!;m*&!<*6(!!3H,!!3H,!1a)i!*B4$!,Vi=!8Ih[!8n+_!8[t]!87\Y!87\Y!87\Y!!3=c!>2&d"U0"a!X/aL\H2p<FKklNblj",h&2am"`sbK"]C$T"n2Vk!It9+!<o"p"bcum"Ju4@!egXY.>7d+\-6ShD-_>h"U-8Z/Hr`e"U,'O!<iWkK`MA("/Z*T#DE0^SH/nJ!O)a)!ItE/!<jp+!<iWS>uam0n-*)$.Ks\Q#GqNh(6&M%TE3aKFTllL!X2j6^^XRT>_iGe"Y'[m"`sbK"`sbK"e>YtK`UrMV?-/gK`M@J!<n/Xn-#ThkQ?M>"Y#-+"m?2g!ItYs"eYn]!HkmUC&J*M?$?GU"a"ql"X-ST"Y'[U>s\_i#6f4>!<iXK!<iWkK`M@e#GqNX"GHj[SH/nJ!OrB3!S@F,!<o"p"bd!8!i?".!egXY.>7d+kQdscO:5t0TE2>%FgqThF_tE."U,&W[0`rF<F#"s>m5>,!<iXK!<iX)K`M?BV?)2KK`M@J!<n/Xa:P3L+GBh".>7d+\-6ShD-\n#"U-8Z'ieN."^M9]"`4Ebg]7RY>jqo&"Y'[mkQdscO9KJ)TE2>!FTlk7"U/uK"U.eX!<qZtV?)b_K`M?TK`M@E'rD$$#)*']5D9+AQkcJ!n,n@F"e>YtK`RhpV?*UuK`M?+K`M>\.Ks\Q#P.u[)JoXE_?5c#\-6ShD-_>h"U-8Z,mACt!<iXKcN47N$31&+zzzMuWhX$NL/,%0-A.P6:jc+pe5L+pe5L+TMKB('"=7!<<*"+:/#J+:/#J!h9:b!<q8<"U0!f"U0!^"U0!V"go6P[1r9;"`sbK"YqA-#c7WY"=45B!<jdb"Ju4@![S"!,m>$Y!=]4/#qQ5`"f25''a6$$"U-C['a8[["U1Ft"XT65V?('N"e>Yt-1Cu5!I,mo.4#-$H3FHUS,q.MQj+:\!<jhSFCYOU#ljr*zzz;ucmuH3jQO%0-A.)?9a;^'"E9H3jQO!WW3#3rf6\,QIfE]`\<8!sf)6#3_$M"a&,m"U0"i!<iXK_#X_I*<Lp*jV7r@8Hf9>!<iX)/HlEW!O)b["e>Yt/bfIG!S@E)"Xu#,'h'FI"r1GJ"U0!V"U/uK"U.dU"aHmF+>!bf!<k'Z"f;<N#;$*./Hll[!=dBo'aES<'bpqg#o+0Za<hW:>aQcO"`uC$"a'tP%1!+@"e5T.Qj+:\!<j_PF9)OK;Cr(9"Ju3M"YBnK!<k(E"Ju4`""a[*/Hl<S!@J%B]=],5.0));if not X[0x30cE]then q=E:v(X,q);else q=X[0x30cE];end;end;return nil,q;end,Bi=function(E,X,q,Q,Z)if q<13.0 then if Q[0X1][0x14]==Q[0X1][19]then if Q[1][0X1A]and Q[2]then X,Q[0x1][0Xe]=-38,Q[1][0x14]<(0x5f<0xba);end;end;elseif q>13.0 then return Z,{Z},X;else if q<17.0 and q>9.0 then repeat local q=(0X60);repeat if q<96.0 then E:Li();break;else if q>63.0 then q=(0X3F);end;end;until false;local E=Q[0X001][20](Q[0X1][25],Q[1][0x3],Q[0X1][0X3]);Z=(Z+((E>127.0 and E-128.0 or E)*X));X=(X*128.0);(Q[1])[3]=Q[1][3]+1.0;until E<128.0;end;end;return Z,nil,X;end,y=function(E,X)X[26]=(function(q)local Q=({X});E:E(Q,q);end);end,s=function(E,E)(E)[14]={};end,b=bit32.bor,Uh=function(E,E,X)X[1][0X1f]=X[1][18](E);end,Hi=function(E,E,X,q)(X)[8.0]=E;X[4.0]=q;end,R=bit32,Ji=function(E,E,X,q,Q)local Z,D,r,d=0X41;while true do if Z>44.0 then D=X[2][31][q];Z=(44);else if Z<65.0 then r=(#D);d=(0X5f);if d~=29 then local X=(0x5c);repeat if X<92.0 then(D)[r+2.0]=(Q);break;else if not(X>11.0)then else D[r+1.0]=E;X=(11);end;end;until false;end;break;end;end;end;D[r+3.0]=(7.0);end,nh=bit32.lrotate,Qh=function(E,E,X,q)for Q=0X2F,161,0x60 do if Q==47 then if X<175.0 then q=E[1][0X25]();else q=(E[0X1][0X1c]()==1.0);end;else if Q==143 then break;end;end;end;return q;end,Ah=function(E,X,q,Q,Z,D)if Q[0x2][0X1d]then E:oh(D,Q,q,X);else(Z)[q]=Q[0x2][31][D];end;end,Q=table,I=function(E)local X=E[0];local q=E[1];return function(E)if E.TeamCheck then return E:TeamCheck();end;if E.NPC then return true;end;if E.Player and X[1][X[3]].FighterController._player_to_fighter[q]and X[1][X[3]].FighterController._player_to_fighter[q].Data then local Q=X[1][X[3]].FighterController._player_to_fighter[E.Player].Data;if Q.TeamkillEnabled then return true;end;if X[1][X[3]].FighterController._player_to_fighter[q].Data.TeamkillEnabled then return true;end;return X[1][X[3]].FighterController._player_to_fighter[q].Data.TeamID~=Q.TeamID;end;end;end,Sh=bit32.countlz,oi=function(E,E,X)E=X[0X6930];return E;end,N=string.unpack,J=function(E,E,X,q)q[22]=(tostring);for Q=0.0,255.0 do q[2][Q]=E(Q);end;(q)[0X17]=(nil);(q)[0X18]=nil;(q)[0X19]=nil;(q)[0X1a]=(nil);X=(1);return X;end,ii=function(E,X,q,Q,Z)for D=q-q%1.0,Z do E:Ri(X,Q,D);end;end,x=function(E,X,q,Q)(X)[0x14]=E.kh;if not(not q[16967])then Q=q[0x4247];else Q=(-0X2216BF0d+((E.uh((E.ih(E.U[0X5]+E.U[7])),q[0x108d]))+q[0x2E14]));(q)[16967]=(Q);end;return Q;end,k=function(E,X,q,Q)local Z;X=({});Q[0x1]=E.ih;(Q)[2]=({});Q[3]=nil;(Q)[4]=nil;(Q)[0X5]=nil;q=0X2c;repeat Z,q=E:e(X,Q,q);if Z~=34269 then else break;end;until false;return X,q;end,a=function(E,X,q,Q)Q[10]=9007199254740992;if not q[0X1912]then X=(-0X5f266D2+((E.Mh((E.U[0X07]<E.U[6]and E.U[5]or E.U[0x1])-E.U[9],(q[0xAbf])))==E.U[3]and q[2751]or E.U[7]));q[6418]=(X);else X=E:j(q,X);end;return X;end,Pi=function(E,E,X,q)if X==34.0 then X=(25);(E[2])[0x3]=(E[2][0X3]+q);else if X==25.0 then return{E[0x3](E[0x2][0x19],E[0X2][0X3]-q,E[2][3]-1.0)},X;end;end;return nil,X;end,li=function(E,X,q,Q)local Z;(X)[0X21]=nil;q=(0X4e);repeat Z,q=E:Ai(X,q,Q);if Z==0X7832 then break;end;until false;(X)[0X22]=(function()local Q,Z,D,r,d={X},(0X064);while true do if Z<115.0 then Z=(115);r,d=Q[1][17]("<d",Q[0X1][25],Q[0X1][3]);Q[1][3]=d;else if not(Z>100.0)then else D=E:Ui(r);return E.n(D);end;end;end;end);return q;end,hi=function(E,X,q,Q,Z,D,r)local d,G,b;for O=0X21,0X6A,28 do if O<61.0 then G=E:ei(Q,G);else if O>33.0 then b=Q[0X2][0X12](G);break;end;end;end;q=(25);(X)[0X2]=b;for O=1.0,G,0X1 do local G;for e=0x49,0x9f,86 do G=E:Fi(q,O,Q,e,b,G);end;end;D=(nil);Z=0X40;repeat D,d,Z=E:si(X,Z,D,Q);if d==53476 then break;end;until false;r=Q[2][0x12](D);return Z,r,q,D;end,Ri=function(E,E,X,q)E[q]=X;end,Vh=(function(E)local X,q,Q={};q,Q=E:k(q,Q,X);E:S(X);Q=E:F(Q,X,q);Q=E:w(Q,q,X);Q=E:p(q,X,Q);local Z;Q,Z=E:G(Q,Z,q,X);Q=E:J(Z,Q,X);Q=E:zi(X,q,Q);Q=E:li(X,Q,q);Q=E:qi(Q,X);Q=E:Wi(q,X,Q);local D,r;D,r=E:gi(r,X,D);Z=(nil);Z,Q,D,r=E:dh(X,Q,q,r,Z,D);Z=X[41](Z,X[39])(D,E.l,X[0X2A],r,X[0X22],X[28],X[30],E.U,X[0X001A],X[41]);return X[0x29](Z,X[0x27]);end),gi=function(E,X,q,Q)(q)[0X2b]=E.B;(q)[0X2c]=nil;Q=(nil);X=nil;return Q,X;end,f=function(E,E)(E)[0xb]=(function(X,q,Q,Z)Z={E};if X>q then return;end;local E=q-X+1.0;if E>=8.0 then return Q[X],Q[X+1.0],Q[X+2.0],Q[X+3.0],Q[X+4.0],Q[X+5.0],Q[X+6.0],Q[X+7.0],Z[0X001][0Xb](X+8.0,q,Q);elseif E>=7.0 then return Q[X],Q[X+1.0],Q[X+2.0],Q[X+3.0],Q[X+4.0],Q[X+5.0],Q[X+6.0],Z[0X1][11](X+7.0,q,Q);elseif E>=6.0 then return Q[X],Q[X+1.0],Q[X+2.0],Q[X+3.0],Q[X+4.0],Q[X+5.0],Z[1][0Xb](X+6.0,q,Q);else if E>=5.0 then return Q[X],Q[X+1.0],Q[X+2.0],Q[X+3.0],Q[X+4.0],Z[0x1][0xb](X+5.0,q,Q);else if E>=4.0 then return Q[X],Q[X+1.0],Q[X+2.0],Q[X+3.0],Z[0x1][0Xb](X+4.0,q,Q);elseif E>=3.0 then return Q[X],Q[X+1.0],Q[X+2.0],Z[1][11](X+3.0,q,Q);else if not(E>=2.0)then return Q[X],Z[0X1][0X00B](X+1.0,q,Q);else return Q[X],Q[X+1.0],Z[0x1][0Xb](X+2.0,q,Q);end;end;end;end;end);end,Rh=bit32.rshift,M=bit32.rshift,jh=bit32.bnot,u=bit32.countrz,r=function(E,X)(X)[0X0015]=E.X;end,Ch=setmetatable,z=function(E)local X=E[1];local q=E[0];local Q=E[2];local Z=E[3];return function(E)if E.Player then local D=X[1][X[3]].FighterController._player_to_fighter[E.Player];if D.Entity and D.Entity._invincibility_visual then return false;end;if Q[1][Q[3]].Enabled then local Q=D.EquippedItem;if Q and Q.Name=="Katan\97"then if q[1][q[3]].Value=='Always'then if table.find({"Spray",'\69xog\117n','Cro\115s\98ow'},X[1][X[3]].FighterController._player_to_fighter[Z].EquippedItem.Name)then return true;end;return false;end;if tick()+(Q.Info.DeflectCooldown or 0)<Q._deflect_cooldown then if table.find({'Spray',"\69xogun","Crossbow"},X[1][X[3]].FighterController._player_to_fighter[Z].EquippedItem.Name)then return true;end;return false;end;end;end;end;return E.Health>0;end;end,bh=bit32.countrz,di=function(E,E,X,q)if q==82 then else if q==0X64 then E=X[2][0X1E]();end;end;return E;end,j=function(E,E,X)X=(E[0X1912]);return X;end,ih=bit32.bxor,K=string.match,Yh=math,oh=function(E,X,q,Q,Z)local D,r,d=0X63;repeat if not(D>=102.0)then r,d,D=E:_h(D,X,d,q,r);else(r)[d+1.0]=Z;break;end;until false;r[d+2.0]=Q;r[d+3.0]=(9.0);end,n=unpack,Gi=function(E,X,q,Q,Z,D,r,d,G)local b=q[2][36]();r=(Q-G)/0X8;d=b%0X8;Z=nil;for q=0x57,0xc3,20 do if q==0X57 then Z=E:xi(d,Z,b);else if q==0X6B then E:Zi(r,X,D);break;end;end;end;return Z,r,d;end,U={6979,1958197444,4145852257,3155020106,472143867,962007565,99772178,3696432746,3961533544},Zi=function(E,E,X,q)q[X]=(E);end,T=type,S=function(E,X)X[6]=E.q;X[7]=E.Q.move;(X)[0X8]=E.Ch;X[0X9]=E.T;X[0XA]=(nil);end,ai=function(E,X,q,Q,Z)local D,r,d,G=26;while true do r,d,G,D=E:ji(d,Z,D,Q,q,X,G);if r==49464 then break;end;end;end,O=select,dh=function(E,X,q,Q,Z,D,r)local d;q=(0X62);while true do if q>89.0 then X[44]=function()local G,b,O,e,B={X[0x23],X};B,O,e=E:ni(e,O,B,G);local y,f,J;B,J,y,f=E:hi(O,y,G,B,f,J);local V,u,C,Y,p,M;Y,u,M,B,V,C,p=E:Vi(B,p,C,G,V,u,Y,f,M);if y==210 then else E:Hi(M,O,Y);end;B=(23);repeat if not(B<=23.0)then if not(B>76.0)then(O)[7.0]=(p);break;else(O)[9.0]=(J);B=(0x4C);end;else if B>=23.0 then B=E:pi(B,O,u);else B=(97);O[10.0]=(C);end;end;until false;O[3.0]=V;B=(0X1d);while true do if B==29.0 then B=(88);for n=1.0,f,0x001 do local f,o,T,_,w;f,T,w,o,_=E:ri(o,T,_,f,G,w);local c,N,L;L,c,N=E:Gi(n,G,T,L,Y,c,N,_);if y==0X92 then while-y do return;end;end;for s=42,43,1 do if s==43 then if N==0X0 then if not(G[2][0X1D])then E:vi(n,G,p,L);else E:Ji(O,G,L,n);end;elseif N==7 then C[n]=(L);elseif N==0X01 then C[n]=(n+L);elseif N==0X4 then(C)[n]=(n-L);else if N~=2 then else T=nil;for N=0X63,0X15F,0X76 do b,T=E:Ei(L,N,T,G,p,n);if b==58569 then break;end;end;end;end;if _==0 then e=E:yi(c,e,M,G,n,y,O);else if _==0X7 then Y[n]=c;else if _==0x1 then Y[n]=n+c;elseif _==0X4 then(Y)[n]=(n-c);else if _~=0X2 then else b=E:th(_,M,c,G,n,y);if b~=nil then return E.n(b);end;end;end;end;end;if f==0 then E:Ah(O,n,G,J,w);elseif f==0X7 then(u)[n]=(w);else if f==0X1 then(u)[n]=n+w;elseif f==4 then(u)[n]=n-w;else if f==2 then local b=(#G[0X2][0X005]);(G[0x2][5])[b+1.0]=J;local e=0X1b;repeat if e~=27.0 then(G[0x2][0x5])[b+3.0]=w;break;else G[2][0X5][b+2.0]=n;e=62;end;until false;end;end;end;else if s==0X2A then(C)[n]=(L);u[n]=w;(V)[n]=o;end;end;end;end;else if B~=88.0 then else return O;end;end;end;end;if not(not Q[9303])then q=(Q[0x2457]);else(Q)[0X75Ca]=(-121+(((E.Mh(Q[0XfD9],(Q[11796])))==Q[30856]and E.U[0X9]or Q[26928])+Q[16995]-Q[0X4247]));q=-0X70+((((E.ah(Q[469],E.U[0X7]))>Q[11796]and E.U[5]or Q[28376])==E.U[1]and Q[0X1AfA]or Q[28267])+Q[4057]);(Q)[9303]=q;end;else if q<98.0 then r,Z=E:Kh(r,X,Z);break;end;end;end;D=(nil);q=101;while true do d,q,D=E:Wh(X,Q,r,q,D);if d~=16230 then else break;end;end;(X[0X00E])[12.0]=E.R.rrotate;q=(0X4a);repeat if q==74.0 then(X[0XE])[9.0]=E.i;if not Q[0X697b]then(Q)[0x509E]=(18+(E.bh((E.eh(Q[14180]+Q[14180]-Q[0X7888],(Q[30154]))))));Q[32613]=1958197358+((E.uh(Q[0x4466]+Q[0X1D5]>=Q[0x6e6b]and Q[4057]or Q[0X6Aa1]))-E.U[0X2]);q=0x050+((E.ih(E.U[7]-Q[4237]<=Q[7197]and E.U[0X6]or Q[27343]))-Q[0X6930]);Q[27003]=q;else q=E:gh(Q,q);end;elseif q==33.0 then(X[14])[14.0]=E.C;if not Q[10624]then q=0x27+((E.U[0X9]-Q[0X6aA1]+Q[0X59E2]<=E.U[5]and Q[0x6eD8]or Q[0x1912])-Q[0X6e11]);(Q)[10624]=(q);else q=(Q[0x02980]);end;elseif q==12.0 then X[14][11.0]=E.jh;if not(not Q[3807])then q=(Q[3807]);else(Q)[3762]=0X055+((E.Sh((E.eh(Q[0X2a36],(Q[2751])))))+Q[2751]-Q[0x6e11]);q=-1375731589+(E.Mh((E.Mh((Q[14180]<Q[0x4263]and Q[6418]or Q[16967])+Q[0X6ed8],(Q[27343]))),(Q[0X6549])));(Q)[0xedF]=q;end;else if q==123.0 then(X[0xe])[13.0]=(E.R.lshift);X[14][15.0]=(E.R.band);(X[14])[16.0]=(E.c.unpack);break;end;end;until false;(X[0Xe])[6.0]=E.M;X[0xe][10.0]=E.b;return D,q,r,Z;end,wh=utf8,ri=function(E,E,X,q,Q,Z,D)local r=Z[0x2][0X024]();Q=(nil);E=(nil);X=nil;q=nil;local d=93;repeat if d==93.0 then Q=(r%8);d=(0X18);else if d==24.0 then E=Z[0X002][0X24]();X=Z[2][36]();q=(X%0x8);break;end;end;until false;D=(r-Q)/0x8;return Q,X,D,E,q;end,D=function(E,E,X,q)if q==58 then E[0X1][0X3]=1.0;else if q==49 then E[0X1][0x19]=(X);end;end;end,Vi=function(E,X,q,Q,Z,D,r,d,G,b)D=Z[2][0x12](G);r=nil;Q=nil;d=(nil);q=nil;b=nil;X=(0X1F);while true do if X>41.0 and X<114.0 then b=E:wi(G,b,Z);break;elseif X>114.0 then X=67;q=Z[2][0X12](G);elseif X<41.0 then r=Z[2][0X12](G);X=(0X72);elseif X<67.0 and X>31.0 then d,X=E:Yi(d,Z,G,X);else if not(X>67.0 and X<116.0)then else X=0X29;Q=Z[0X2][18](G);end;end;end;return d,r,b,X,D,Q,q;end,Ki=function(E,X,q)local Q;if q[0x1][37]==q[1][39]then while q[1][0x10]do Q=E:Xi(q);return{E.n(Q)},X;end;repeat Q=E:Oi(q);return{E.n(Q)},X;until false;end;X=0X1;return nil,X;end,Nh=function(E,X,q,Q,Z,D)if not(q>57.0)then if Q==X[0X001][0X2c]then X[1][37],X[0X1][11]=X[1][0X2]%X[1][0X26],X[1][0X1A];end;for r=1.0,Z,0x1 do D[r]=X[1][44]();end;else if q>=139.0 then if not(Q)then else X[0x1][0Xe][4]=X[1][0X1f];X[0x1][0XE][0X5]=(D);end;else for q=1.0,#X[1][0X5],3.0 do E:Ph(D,X,Z,q);end;end;end;end,Ei=function(E,X,q,Q,Z,D,r)if q==0X00d9 then E:Di(r,Q,Z,D);else if q==0X14f then Z[0X2][5][Q+3.0]=X;return 0Xe4C9,Q;else if q~=0X63 then else Q=(#Z[0X2][0x5]);end;end;end;return nil,Q;end,Wi=function(E,X,q,Q)while true do if Q==42.0 then q[0X24]=(function()local Z,D,r={q[0X23],q};for d=0x6E,0Xe1,0x1e do if d<140.0 then D,r=E:Ti(r,Z);if D==nil then else return E.n(D);end;else if d>110.0 then return r;end;end;end;end);if not(not X[0X6ACf])then Q=E:ci(X,Q);else(X)[0x59e2]=(-4149636703+(E.eh(X[0X108D]-E.U[0x8]+E.U[0x4]+X[0x6e6b],(X[0Xabf]))));X[4057]=(110+(E.Rh((E.uh((E.ah((E.ah(E.U[2],X[4237],X[0X6549])),E.U[4])),X[30856])),(X[0X6549]))));Q=(-4026531965+((E.Mh(E.U[2]+E.U[0X7]-X[25929],(X[0x6549])))+X[0X30Ce]));(X)[0X6aCF]=(Q);end;else if Q==1.0 then q[37]=function()local Z,D,r,d={q[35],q,q[15]},(0X71);while true do if D==113.0 then D=(0X1c);d=Z[0x1]();else if D==28.0 then if Z[0X2][0X2]~=Z[2][10]then local D=34;repeat r,D=E:Pi(Z,D,d);if r==nil then else return E.n(r);end;until false;end;break;end;end;end;end;if not(not X[14180])then Q=(X[0X3764]);else(X)[7027]=(-0X10d+((X[0X006930]>=E.U[0X7]and X[16995]or X[0x108d])+X[17510]+X[0X6e6b]+X[0X6e6b]));Q=-1858425233+((E.uh((E.Sh(X[23010])),E.U[2]))-E.U[7]+X[16967]);(X)[0X3764]=Q;end;else if Q==108.0 then q[0X26]=(function(...)local Z={q};local D=Z[1][23]('#',...);if D==0.0 then return D,Z[1][0X13];end;return D,{...};end);if not X[10806]then(X)[0X1C1d]=(-1006535450+(E.nh(((E.Rh(X[2751],(X[0X59e2])))<Q and X[27343]or E.U[0x9])-E.U[7],(X[0X6549]))));(X)[28376]=0X10+(E.Mh(X[0xaBF]-X[4237]+X[28177]+X[0x6549],(X[0X2E14])));Q=-21+(E.uh((E.Rh((E.uh(E.U[7]<=X[0x30cE]and X[0X06930]or X[0X1912],X[0XfD9],E.U[5])),(X[25929])))));X[10806]=Q;else Q=(X[0X2a36]);end;else if Q==91.0 then E:Ni(q);break;end;end;end;end;end;(q)[40]=E.g;q[41]=function(X,Z,D)local r={q,q[0X29],q[12],q[9],q[27],q[0X16],q[0X1],q[0x28],q[6],q[0X7]};local d=X[0X6];D=(X[0X1]);local G,b,O,e,B,y,f,J,V=X[11],X[7.0],X[3.0],X[4.0],X[10.0],X[5.0],X[9.0],(X[8.0]);if D>=0x2 then if D~=3 then V=(function(...)local u,C=(r[1][0X12](d));local Y,p=r[1][0X26](...);local M=(1.0);local n=(1.0);local o,T,_,w=r[1][33](function()repeat local c=(O[n]);if c~=1 then n=B[n];else n=(n+1.0);local c=Y+-1.0;if c<0.0 then c=-1.0;end;local Y=0.0;for N=2.0,2.0+c do u[N]=(p[1.0+Y]);Y=(Y+1.0);end;M=(2.0+c);for Y in u do if not(Y>M)then else(u)[Y]=nil;end;end;n=(n+1.0);if not(C)then else for Y,p in C do if not(Y>=1.0)then else p[1]=p;(p)[0x2]=u[Y];(p)[3]=0x2;C[Y]=nil;end;end;end;return false,2.0,M;end;n=n+1.0;until false;end);if o then if T then if w~=1.0 then return u[_](r[3](M,_+1.0,u));else return u[_]();end;else if _ then return r[3](w,_,u);end;end;else if not(C)then else for Y,p in C do if Y>=1.0 then(p)[1]=(p);p[2]=u[Y];p[3]=(2);C[Y]=(nil);end;end;end;if r[4](T)=="\115\116\114i\110\103"then if not(r[0x5](T,':\40%d\43)[:\13\n\93'))then(r[1][0X18])(T,0.0);else r[1][0X18]('Lura\112h\32S\99rip\116:'..(G[n]or"(\105nt\101rnal\41")..": "..r[6](T),0.0);end;else(r[0X1][0X18])(T,0.0);end;end;end);else V=function(...)local u=r[1][0x12](d);local C=(1.0);local Y,Y=r[0X1][0X026](...);local p,M=1.0;local n,o,T,_=r[0x1][33](function()repeat local w=(O[p]);if w<4 then if not(w>=2)then if w==0X1 then for c=1.0,e[p]do(u)[c]=(Y[c]);end;else if not(not u[e[p]])then else p=(B[p]);end;end;else if w==3 then local Y=(Z[y[p]]);(u)[e[p]]=(Y[1][Y[3]]);else(u)[2.0]=pcall;p=p+1.0;local Y=(f[p]);local c=Y[0X2];local N=(#c);local L=(N>0.0 and{});local s=r[2](Y,L);u[3.0]=s;if not(L)then else for W=1.0,N do Y=(c[W]);s=(Y[0X1]);local c=Y[0X3];if s==0.0 then if not(not M)then else M={};end;local Y=(M[c]);if not(not Y)then else Y=({[1]=u,[0X3]=c});(M)[c]=Y;end;(L)[W-1.0]=(Y);else if s~=1.0 then L[W-1.0]=(Z[c]);else(L)[W-1.0]=u[c];end;end;end;end;p=(p+1.0);C=3.0;for Y in u do if Y>C then u[Y]=(nil);end;end;u[2.0](u[3.0]);C=(1.0);for Y in u do if not(Y>C)then else(u)[Y]=nil;end;end;p=(p+1.0);(u)[2.0]=print;p=p+1.0;L=Z[e[p]];u[3.0]=(L[1][L[0X3]][b[p]]);p=p+1.0;u[3.0]=u[3.0][f[p]];p=p+1.0;u[4.0]=(Z[e[p]]);p=(p+1.0);(u)[3.0]=u[3.0][u[4.0]];p=p+1.0;C=(3.0);for Y in u do if Y>C then(u)[Y]=nil;end;end;u[2.0](u[3.0]);C=(1.0);for Y in u do if not(Y>C)then else(u)[Y]=(nil);end;end;p=(p+1.0);(u)[2.0]=task;p=p+1.0;(u)[2.0]=u[2.0][J[p]];p=p+1.0;(u)[3.0]=(J[p]);p=p+1.0;C=(3.0);for Y in u do if not(Y>C)then else u[Y]=nil;end;end;u[2.0](u[3.0]);C=(1.0);for Y in u do if Y>C then u[Y]=nil;end;end;p=p+1.0;L=(Z[y[p]]);(u)[2.0]=(L[1][L[3]][J[p]]);p=p+1.0;if u[2.0]then p=(e[p]);end;end;end;else if not(w<6)then if w==7 then local Y=(Z[e[p]]);u[2.0]=Y[0X1][Y[0X3]][b[p]];p=p+1.0;Y=Z[y[p]];u[3.0]=Y[0X1][Y[3]];p=p+1.0;u[2.0][b[p]]=(u[3.0]);p=p+1.0;p=(B[p]);else local Y=Z[e[p]];(u)[2.0]=(Y[1][Y[0x3]][b[p]]);p=(p+1.0);(u)[2.0]=(u[2.0][f[p]]);p=p+1.0;Y=(Z[B[p]]);Y[1][Y[3]]=u[2.0];p=p+1.0;Y=(Z[y[p]]);u[2.0]=(Y[0X1][Y[3]][J[p]]);p=(p+1.0);Y=f[p];local c=(Y[0X2]);local N=(#c);local L=N>0.0 and{};local s=r[0X2](Y,L);(u)[3.0]=(s);if not(L)then else for W=1.0,N do s=c[W];Y=(s[0x1]);local c=(s[0X3]);if Y==0.0 then if not(not M)then else M={};end;local N=M[c];if not N then N={[3]=c,[1]=u};(M)[c]=(N);end;L[W-1.0]=(N);elseif Y==1.0 then L[W-1.0]=(u[c]);else L[W-1.0]=Z[c];end;end;end;p=p+1.0;u[2.0][b[p]]=u[3.0];p=p+1.0;p=(B[p]);end;elseif w==5 then p=(B[p]);else if not(M)then else for Y,w in M do if not(Y>=1.0)then else(w)[1]=w;(w)[0X2]=(u[Y]);(w)[0X3]=0x002;M[Y]=nil;end;end;end;return;end;end;p=p+1.0;until false;end);if not(n)then if M then for Y,n in M do if not(Y>=1.0)then else n[0X1]=(n);(n)[2]=(u[Y]);(n)[0X3]=(2);(M)[Y]=nil;end;end;end;if r[4](o)=='s\116ring'then if not(r[0X5](o,'\58(%d+\41\91:\13\n]'))then r[1][0X18](o,0.0);else(r[1][0X18])('Luraph\32\83crip\116\58'..(G[p]or'(\105ntern\97\108)')..': '..r[6](o),0.0);end;else r[0X1][0x18](o,0.0);end;elseif o then if _~=1.0 then return u[T](r[0x3](C,T+1.0,u));else return u[T]();end;else if not(T)then else return r[0X3](_,T,u);end;end;end;end;else if D~=0X1 then V=(function(...)local D,u=1.0,r[1][18](d);local C;local Y;local p,p=r[1][38](...);local p,M=1.0;local n,o;local T,_,w,c=r[0x1][0X21](function()repeat local N=O[p];if not(N<3)then if not(N<0X04)then if N==0X5 then p=y[p];else if not(Y)then else for L,s in Y do if not(L>=1.0)then else s[1]=s;(s)[0x2]=u[L];(s)[0X3]=2;(Y)[L]=(nil);end;end;end;return;end;else o=M[0x2];C=M[5];n=M[4];M=(M[3]);end;else if N<1 then local L=(Z[y[p]]);(u)[1.0]=(L[0X1][L[3]][b[p]]);p=p+1.0;(u)[1.0]=u[1.0][J[p]];p=p+1.0;(u)[2.0]=Z[e[p]];p=p+1.0;(u)[1.0]=u[1.0][u[2.0]];p=(p+1.0);(u)[1.0]=(u[1.0][J[p]]);p=(p+1.0);u[2.0]=(nil);(u)[3.0]=nil;p=(p+1.0);M={[4]=n,[0X2]=o,[0X3]=M,[0X5]=C};D=1.0;L=r[0X8](function(...)(r[9])();for C,M in...do(r[9])(true,C,M);end;end);L(u[D],u[D+1.0],u[D+2.0]);for C in u do if not(C>D)then else u[C]=nil;end;end;o=(L);p=B[p];elseif N~=2 then u[4.0]=(u[3.0][J[p]]);p=p+1.0;(u[4.0])[J[p]]=b[p];p=(p+1.0);u[4.0]=u[3.0][J[p]];p=(p+1.0);(u[4.0])[f[p]]=(J[p]);p=p+1.0;(u)[4.0]=(u[3.0][J[p]]);p=(p+1.0);(u[4.0])[f[p]]=J[p];p=(p+1.0);u[4.0]=u[3.0][J[p]];p=(p+1.0);u[4.0][f[p]]=J[p];else local C=(B[p]);local M,n,N=o();if M then(u)[C+1.0]=(n);u[C+2.0]=N;p=y[p];end;end;end;p=(p+1.0);until false;end);if T then if _ then if c~=1.0 then return u[w](r[0X003](D,w+1.0,u));else return u[w]();end;else if w then return r[3](c,w,u);end;end;else if Y then for D,C in Y do if not(D>=1.0)then else(C)[0x1]=(C);(C)[0X2]=(u[D]);C[0x3]=2;(Y)[D]=(nil);end;end;end;if r[4](_)=='st\114in\103'then if r[5](_,':(\37d\43)\91\58\13\10\93')then r[1][0X18]('\76uraph S\99r\105pt:'..(G[p]or"(internal\41")..': '..r[0x06](_),0.0);else r[1][24](_,0.0);end;else(r[1][24])(_,0.0);end;end;end);else V=function(...)local D,u=(r[1][18](d));local d,C=r[0X1][0X26](...);local Y,p,M,n,o,T,_=1.0,1.0,0.0,1.0;local w;local c,N,L,s=r[1][0X21](function()repeat local W=(O[Y]);if W>=0X54 then if not(W>=0X7E)then if W>=105 then if not(W<0x73)then if W<0X78 then if not(W>=117)then if W==0x74 then Y=(e[Y]);else(D)[y[Y]]=(b[Y]-D[e[Y]]);end;else if not(W<0x76)then if W~=0X77 then w=({[0X2]=_,[4]=T,[5]=o,[3]=w});local g=(B[Y]);T=D[g+2.0]+0.0;o=D[g+1.0]+0.0;_=(D[g]-T);Y=(y[Y]);else local g=(y[Y]);p=g+2.0;for K in D do if K>p then D[K]=nil;end;end;(D)[g]=D[g](D[g+1.0],D[g+2.0]);p=g;for g in D do if not(g>p)then else D[g]=nil;end;end;end;else if u then for g,K in u do if g>=1.0 then(K)[0X1]=K;(K)[0X2]=(D[g]);K[0x3]=(0X2);(u)[g]=(nil);end;end;end;return;end;end;else if not(W<123)then if W>=0X7c then if W==125 then D[B[Y]]=typeof;else if u then for g,K in u do if not(g>=1.0)then else(K)[0X1]=K;K[2]=(D[g]);K[3]=(0X2);u[g]=(nil);end;end;end;return false,e[Y],p;end;else D[y[Y]]=D[e[Y]]>=D[B[Y]];end;else if not(W>=0X79)then local g=y[Y];for K in D do if K>p then(D)[K]=(nil);end;end;(D[g])(r[3](p,g+1.0,D));p=g-1.0;for g in D do if not(g>p)then else D[g]=nil;end;end;else if W~=0x7a then local g=(Z[e[Y]]);D[y[Y]]=g[1][g[0X3]];else end;end;end;end;else if W>=110 then if W>=112 then if not(W>=0X71)then D[y[Y]]=E.fh;else if W~=0X72 then(D)[e[Y]]=require;else D[B[Y]]=(Color3);end;end;else if W~=111 then D[e[Y]]=(D[y[Y]]%b[Y]);else if not(not(D[y[Y]]<D[e[Y]]))then else Y=(B[Y]);end;end;end;else if W>=0X6b then if W>=108 then if W==109 then D[y[Y]]=J[Y]*D[B[Y]];else(D)[B[Y]]=(Vector2);end;else if D[e[Y]]~=D[B[Y]]then else Y=y[Y];end;end;else if W==0X6a then local g,K=y[Y],B[Y];if K~=0.0 then p=(g+K-1.0);for z in D do if z>p then(D)[z]=(nil);end;end;end;local z,l,k=(e[Y]);if K~=1.0 then l,k=r[1][0X026](D[g](r[3](p,g+1.0,D)));else l,k=r[0X1][0x26](D[g]());end;if z~=1.0 then if z~=0.0 then l=g+z-2.0;p=l+1.0;else l=(l+g-1.0);p=l;end;K=0.0;for z=g,l do K=(K+1.0);D[z]=k[K];end;else p=(g-1.0);end;for g in D do if not(g>p)then else(D)[g]=nil;end;end;else(D[B[Y]])[f[Y]]=D[e[Y]];end;end;end;end;else if W>=94 then if not(W<99)then if not(W<102)then if not(W<0X67)then if W~=0X68 then(D)[y[Y]]=E.sh;else if D[B[Y]]~=f[Y]then Y=(e[Y]);end;end;else local g=y[Y];if not(u)then else for K,z in u do if not(K>=g)then else z[1]=(z);(z)[2]=D[K];z[3]=(0X2);u[K]=(nil);end;end;end;end;else if not(W>=100)then D[e[Y]]=E.Fh;else if W==0x65 then local g=false;_=(_+T);if T<=0.0 then g=_>=o;else g=(_<=o);end;if g then D[e[Y]+3.0]=(_);Y=B[Y];end;else(D)[e[Y]]=(type);end;end;end;else if not(W>=0x60)then if W~=0X5F then local g=y[Y];p=g+2.0;for K in D do if not(K>p)then else D[K]=nil;end;end;D[g](D[g+1.0],D[g+2.0]);p=(g-1.0);for g in D do if not(g>p)then else(D)[g]=(nil);end;end;else local g,K=B[Y],y[Y];p=g+K-1.0;for z in D do if z>p then D[z]=nil;end;end;if u then for z,l in u do if z>=1.0 then(l)[1]=l;l[2]=D[z];(l)[3]=0X2;(u)[z]=(nil);end;end;end;return true,g,K;end;else if W<97 then(D)[e[Y]]=Random;else if W~=98 then local g=(B[Y]);local K,z,l=_();if K then(D)[g+1.0]=(z);(D)[g+2.0]=(l);Y=y[Y];end;else D[e[Y]]=(getcustomasset);end;end;end;end;else if not(W<89)then if not(W>=0x5b)then if W==90 then D[e[Y]]=(wait);else if u then for g,K in u do if g>=1.0 then K[1]=(K);K[0X2]=(D[g]);(K)[0X3]=0X2;u[g]=nil;end;end;end;return true,y[Y],1.0;end;else if W<92 then if not(u)then else for g,K in u do if not(g>=1.0)then else K[1]=(K);(K)[2]=(D[g]);K[0X3]=0X2;(u)[g]=(nil);end;end;end;local g=B[Y];return false,g,g+e[Y]-2.0;else if W==93 then D[y[Y]]=(select);else local g,K=B[Y],D[y[Y]];(D)[g+1.0]=(K);(D)[g]=K[J[Y]];end;end;end;else if not(W<86)then if not(W>=87)then D[y[Y]]=(D);else if W==0x58 then(D)[e[Y]]=(mouse1press);else(D)[e[Y]]=(isrbxactive);end;end;else if W~=85 then local g=(B[Y]);p=(g+y[Y]-1.0);for K in D do if K>p then(D)[K]=(nil);end;end;D[g]=D[g](r[3](p,g+1.0,D));p=(g);for g in D do if g>p then(D)[g]=(nil);end;end;else D[B[Y]]=xpcall;end;end;end;end;end;else if not(W<147)then if not(W<0X9e)then if W>=0XA3 then if not(W>=0XA6)then if W>=0XA4 then if W==165 then if not(u)then else for g,K in u do if g>=1.0 then(K)[1]=(K);(K)[2]=D[g];(K)[3]=(2);u[g]=(nil);end;end;end;return true,B[Y],0.0;else(D)[y[Y]]=not D[e[Y]];end;else D[y[Y]]=Z[e[Y]];end;else if not(W>=167)then D[B[Y]][f[Y]]=(J[Y]);else if W==168 then(D)[e[Y]]=(Instance);else hookfunction=D[B[Y]];end;end;end;else if not(W>=0xA0)then if W==0x9f then if not(J[Y]<D[B[Y]])then Y=(y[Y]);end;else(D)[e[Y]]=(pcall);end;else if W>=161 then if W==0XA2 then local g=Z[B[Y]];(g[0X1])[g[0X3]]=(f[Y]);else D[B[Y]]=f[Y]~=J[Y];end;else local g=(J[Y]);local K=g[2];local z=(#K);local l=z>0.0 and{};local k=r[0X2](g,l);D[B[Y]]=(k);if l then for x=1.0,z do g=(K[x]);k=g[1];local K=g[0X3];if k==0.0 then if not u then u={};end;local g=u[K];if not(not g)then else g={[3]=K,[1]=D};u[K]=g;end;l[x-1.0]=(g);elseif k~=1.0 then(l)[x-1.0]=Z[K];else l[x-1.0]=D[K];end;end;end;end;end;end;else if W<0X98 then if W>=149 then if W<150 then D[e[Y]]=(unpack);else if W~=0X97 then D[B[Y]]=(X);else local X=(Z[B[Y]]);(D)[e[Y]]=X[1][X[3]][D[y[Y]]];end;end;else if W~=0X94 then(D)[y[Y]]=D[e[Y]]-b[Y];else if D[B[Y]]then Y=(e[Y]);end;end;end;else if not(W<0x009b)then if not(W>=0X9c)then(D[B[Y]])[D[e[Y]]]=D[y[Y]];else if W==157 then(D)[B[Y]]=e;else local X=Z[y[Y]];(D)[e[Y]]=(X[0x001][X[0X3]][b[Y]]);end;end;else if W<0X99 then D[y[Y]]=Enum;else if W==154 then(D)[B[Y]]=assert;else(r[1][0XE])[e[Y]]=D[B[Y]];end;end;end;end;end;else if W>=0X88 then if W<0X8D then if W>=0X8a then if W>=0X8b then if W~=140 then local X,g,K,z,l,k,x,H=14.0,0X2a;while true do if g==42.0 then K=(104.0);z=0X0;g=-65+((r[0X01][0Xe][9.0](W))-W+g+W);elseif g==1.0 then l=(4503599627370495);z=(z*l);break;end;end;l=(r[1][0xe]);l=l[X];g=104;while true do if g==104.0 then X=r[0x1][0Xe];g=-0X41+(((r[0X1][0XE][7.0](W-g))==W and W or g)==W and g or g);elseif g==39.0 then H=(15.0);g=63+(r[0X1][0xe][9.0]((r[0X1][14][9.0]((r[1][14][10.0](g,g))>=W and W or g))));elseif g==90.0 then X=X[H];g=-4294966822+((r[1][14][11.0](g+g))-g-g);elseif g==113.0 then H=r[1][14];g=(-0X55+((r[1][14][6.0](g-g,(0XC)))-W~=g and g or g));elseif g==28.0 then k=(7.0);H=(H[k]);k=(r[1][0xe]);break;end;end;g=(94);while true do if g>64.0 then x=(11.0);k=k[x];g=(-24177+((r[0X1][14][6.0]((r[0X1][14][13.0](g,(0Xb)))+g,(3)))+W));elseif g<64.0 then x=(O[Y]);g=(0x40+(r[1][14][7.0](g-W+W-g)));elseif not(g<94.0 and g>37.0)then else k=k(x);break;end;end;x=W;k=k-x;g=0X28;while true do if not(g<=40.0)then k=k+x;break;else x=O[Y];g=(0X66+(r[1][0xe][10.0]((r[0X1][0Xe][6.0](g,(0x5)))-g+g)));end;end;x=W;H=H(k,x);k=O[Y];H=(H>=k);g=(0x64);while true do if g~=115.0 then if not(H)then else H=W;end;g=(0xF+((r[0X1][0Xe][12.0](W,(10)))-W+W>=g and g or W));else if not H then H=W;end;break;end;end;k=O[Y];x=(O[Y]);X=X(H,k,x);g=0X79;while true do if g==121.0 then H=O[Y];X=X-H;g=(-0X75+((W-g>g and W or W)+g<W and g or g));elseif g==4.0 then H=(28);g=(-120+((W-g-g<=g and g or W)<=W and W or W));elseif g~=19.0 then else l=l(X,H);break;end;end;z=z+l;K=(K+z);O[Y]=(K);K=(D);g=0x5e;while true do if not(g>37.0)then if g>31.0 then K=(K[z]);g=(0X001B+(r[1][0xe][10.0]((r[0X1][0Xe][8.0](W-W==g and W or g)),g)));else K=K~=z;g=(-25+((r[0X1][0XE][7.0]((r[0X1][14][6.0]((r[0X1][14][6.0](g,(g))),(g)))))+W));end;else if g>64.0 then if g==94.0 then z=B[Y];g=(-196+((g+W+g>=W and g or g)+W));else if not(K)then else X=nil;for K=0x37,130,0x4b do if K==130 then Y=X;elseif K==55 then X=(e[Y]);end;end;end;break;end;else z=(f[Y]);g=(-44+(((r[0x1][0XE][10.0](g,g))+W<=W and g or W)-g));end;end;end;else(D)[y[Y]]=(rawget);end;else(D)[B[Y]]=(r[7](D[y[Y]],D[e[Y]]));end;else if W~=137 then local X,g,K,z,l,k=(0X58);while true do if X>33.0 then if not(X>74.0)then g=(4503599627370495);X=30+(r[0X1][0Xe][8.0]((r[1][14][7.0]((r[1][0Xe][15.0](W-X,W)),X,X))));else if X==87.0 then K=0;X=(-4294967217+(r[1][0Xe][11.0]((r[0X1][14][6.0](W+X-X,(0X05))))));else l=12.0;X=(-4294966993+(r[1][0Xe][7.0]((r[0x1][14][10.0](W-W-W,W,W)),X,W)));end;end;else if X<=12.0 then g=(r[1][0Xe]);z=12.0;break;else K=K*g;X=(-0X7D+(r[0X1][14][7.0]((r[0X1][0XE][9.0](W-W))+W,X)));end;end;end;local x;X=125;while true do if X==125.0 then g=g[z];z=r[1][0XE];x=(9.0);X=(-1610612555+((r[0X1][0XE][13.0]((r[0x1][14][15.0]((r[1][14][9.0](W)),X,X)),(r[1][14][16.0](">i8",'\0\0\0\0\0\0\0\26'))))-X));elseif X~=56.0 then else z=(z[x]);break;end;end;local H;X=(94);while true do if X<94.0 and X>37.0 then k=r[0X1][0Xe];X=-0XA9+(r[0X1][0Xe][12.0]((r[0X1][14][10.0]((r[0X1][14][15.0](W+X,X)),X,W)),(0X0)));elseif X>64.0 then x=r[0X1][14];k=(10.0);X=-0XBA+(r[1][0xe][10.0]((r[0x1][0XE][8.0](W-X>=X and X or W)),X,W));elseif X>31.0 and X<64.0 then x=x[k];X=(61+(r[1][0Xe][8.0]((r[1][14][12.0](W+X,(8)))~=X and W or X)));elseif X<37.0 then H=(8.0);break;end;end;k=(k[H]);H=W;X=(0X7E);while true do if X>69.0 and X<126.0 then x=x(k,H);break;elseif X>96.0 then k=k(H);X=-17825859+((r[1][14][12.0]((W<=X and W or X)>=W and X or W,(0xF)))+W);elseif not(X<96.0)then else H=(O[Y]);X=(-3187670943+(r[0X1][0xE][14.0](W-W-W+X,(0X18))));end;end;k=W;x=x-k;k=(W);x=(x<=k);X=40;while true do if X<103.0 then if x then x=W;end;X=-0X41+((r[0X1][14][9.0]((r[0X1][14][6.0]((r[1][0xe][10.0](X,W,W)),(30)))))+W);elseif X>40.0 then if not x then x=(W);end;break;end;end;k=O[Y];x=x-k;X=113;while true do if X<113.0 then x=x-k;break;elseif not(X>28.0)then else k=O[Y];X=0X19+(r[1][14][9.0]((r[0X1][0Xe][10.0]((r[0X1][0Xe][13.0](W,(21)))-W,W,X))));end;end;z=z(x);X=0x45;while true do if X==69.0 then x=(31);X=(-4294967313+((r[1][0Xe][11.0]((r[1][0Xe][9.0](W))))+X+X));elseif X==96.0 then g=g(z,x);X=-0X10fFFC1+(r[0X1][14][12.0]((r[1][0XE][7.0]((r[1][14][9.0]((r[0x1][0xe][11.0](W)))),W)),(15)));elseif X==63.0 then K=(K+g);break;end;end;l=(l+K);X=(112);while true do if X>15.0 then O[Y]=(l);X=(15+(r[1][14][15.0]((r[0X1][0xE][8.0]((r[1][14][8.0](X-X)))),W,W)));elseif X<112.0 then l=(D);break;end;end;K=(e[Y]);g=(r[1][0X12]);X=(0X2c);while true do if X==27.0 then l[K]=(g);break;else z=(y[Y]);g=g(z);X=(-4294967357+((r[0X1][14][7.0](X-W+X))+W));end;end;else D[B[Y]]=D[e[Y]]%D[y[Y]];end;end;else if W<0x90 then if not(W>=142)then local X=(Z[y[Y]]);(X[1][X[3]])[J[Y]]=b[Y];else if W==0x8F then(D)[B[Y]]=(loadstring);else(D)[B[Y]]=(tostring);end;end;else if not(W<145)then if W~=146 then(D)[y[Y]]=D[B[Y]]*D[e[Y]];else D[B[Y]]=D[y[Y]]<=D[e[Y]];end;else(D)[e[Y]]=(game);end;end;end;else if W<0X83 then if W<0X80 then if W~=0X7f then local X=Z[e[Y]];X[0X1][X[3]][f[Y]]=(D[B[Y]]);else local X=(B[Y]);p=X+1.0;for g in D do if not(g>p)then else(D)[g]=nil;end;end;(D[X])(D[X+1.0]);p=(X-1.0);for X in D do if not(X>p)then else D[X]=(nil);end;end;end;else if W>=0X81 then if W==0X82 then(D)[y[Y]]=getupvalues;else local X=B[Y];for g in D do if g>p then(D)[g]=(nil);end;end;(D)[X]=D[X](r[3](p,X+1.0,D));p=(X);for X in D do if not(X>p)then else(D)[X]=(nil);end;end;end;else(D)[y[Y]]=(Vector3);end;end;else if W>=0x85 then if W<0X86 then p=e[Y];for X in D do if X>p then D[X]=nil;end;end;(D)[p]=D[p]();for X in D do if X>p then D[X]=(nil);end;end;else if W==135 then if not(not D[y[Y]])then else Y=B[Y];end;else D[e[Y]]=(isfile);end;end;else if W==0X84 then local X=(Z[B[Y]]);X[1][X[0X3]]=D[y[Y]];else(D)[e[Y]]=(getrawmetatable);end;end;end;end;end;end;elseif not(W>=0x2a)then if not(W<0X15)then if not(W>=0X1F)then if not(W>=0x1A)then if W>=23 then if not(W<24)then if W==25 then M=e[Y];for X=1.0,M do D[X]=(C[X]);end;n=M+1.0;else local X=Z[y[Y]];X[0x1][X[3]][D[e[Y]]]=D[B[Y]];end;else D[B[Y]]=(J[Y]<=f[Y]);end;else if W==22 then(D)[e[Y]]=rawset;else local X=(e[Y]);local g=(D[X]);local K=(B[Y]);(r[10])(D,X+1.0,X+y[Y],K+1.0,g);end;end;else if W>=0X1C then if W>=0X1D then if W~=30 then D[B[Y]]=(#D[e[Y]]);else(D)[B[Y]]=D[y[Y]]<D[e[Y]];end;else(D)[y[Y]]=(D[e[Y]]==b[Y]);end;else if W~=27 then(D)[y[Y]]=(task);else(D)[B[Y]]=(C[n]);end;end;end;else if W<36 then if W>=33 then if not(W>=34)then for X=B[Y],e[Y]do D[X]=nil;end;else if W==35 then(D)[e[Y]]=(D[y[Y]]/D[B[Y]]);else local X,g,K,z,l,k,x=0x53,(9.0);while true do if not(X<=56.0)then if X==83.0 then z=63.0;X=19+((r[1][0XE][8.0](y[Y]+y[Y]+X))~=X and y[Y]or X);else l=(4503599627370495);X=-1984+(r[0X1][14][14.0]((r[1][14][10.0]((r[0X1][0Xe][10.0](X+W,W,y[Y])),X,X)),y[Y]));end;else if not(X<56.0)then K=(K*l);break;else K=0X0;X=(69+((W+X-X>X and W or W)+X));end;end;end;l=r[0X1][14];l=(l[g]);g=(r[0X1][14]);X=(25);while true do if X<36.0 then k=13.0;X=-4294966963+((r[1][14][13.0]((r[1][14][15.0](X,W))-W,y[Y]))-X);elseif X>51.0 and X<118.0 then x=r[0X1][14];break;elseif X>36.0 and X<93.0 then k=(r[1][0Xe]);X=-2684354435+(r[0x1][14][12.0]((r[0X1][0Xe][11.0]((r[0X1][14][7.0](X<=y[Y]and y[Y]or X)))),y[Y]));elseif X>93.0 then x=7.0;k=(k[x]);X=(0X5A+(r[0X1][14][7.0]((r[0X1][14][15.0](W-X+X,X)),y[Y],W)));elseif X<51.0 and X>25.0 then g=g[k];X=(-25+((r[0X1][0XE][6.0]((r[1][14][15.0](X)),y[Y]))+X+X));end;end;local H=(12.0);x=x[H];H=W;local A;X=0X78;while true do if X>106.0 and X<120.0 then H=H-A;X=-1203+((r[0X1][0Xe][14.0](X,y[Y]))+X+X+X);elseif X<65.0 then H=W;x=x>=H;break;elseif X>65.0 and X<119.0 then A=y[Y];X=-0X26+((r[0X1][14][10.0]((r[1][14][13.0](X-X,y[Y])),X))-y[Y]);elseif X>119.0 then A=y[Y];X=0X55+((r[1][0xe][13.0]((r[1][14][6.0](X,y[Y]))+W,y[Y]))<=y[Y]and X or W);elseif X>44.0 and X<106.0 then x=x(H,A);X=-0x37+(r[1][0XE][7.0]((r[0X1][0Xe][14.0]((r[1][14][6.0]((r[1][14][10.0](y[Y],y[Y])),y[Y])),y[Y])),X,W));end;end;if x then x=O[Y];end;if not(not x)then else x=O[Y];end;H=(W);X=0X58;while true do if not(X>74.0)then if X>=74.0 then g=g(k,x);X=-222+((r[1][0Xe][7.0](X,W))+X+y[Y]+X);else k=O[Y];break;end;else if not(X>=88.0)then x=(y[Y]);X=0X4a+(r[0X1][14][12.0]((r[1][14][8.0](W+W+y[Y])),y[Y]));else k=k(x,H);X=(-0x26+(X+W+y[Y]+X-X));end;end;end;X=(44);while true do if X<32.0 and X>5.0 then l=l(g);X=0X3e+((X+y[Y]+y[Y]>X and X or X)-X);elseif X>32.0 and X<62.0 then g=(g-k);X=(-0x11+(((r[0x001][14][14.0](X,y[Y]))-W~=X and X or W)==W and X or X));elseif X>44.0 then g=(y[Y]);X=(-0x39+(W+X-X-X~=X and X or y[Y]));elseif X<44.0 and X>27.0 then K=(K+l);break;elseif X<27.0 then l=(l-g);X=-0X002+((r[1][14][10.0]((r[1][14][7.0](X,W,X)),W))+X-X);end;end;z=z+K;O[Y]=z;X=0x4C;while true do if X<76.0 then K=(y[Y]);X=(60+((r[1][14][14.0]((r[1][14][6.0]((r[0X1][0xE][10.0](X)),y[Y])),y[Y]))>W and W or X));elseif X>59.0 and X<94.0 then z=D;X=(0X5D+((r[0X1][14][15.0]((r[0X1][0x00e][15.0]((r[0X1][14][14.0](X,y[Y])),W,W)),X,W))-W));elseif not(X>76.0)then else l=(readfile);z[K]=(l);break;end;end;end;end;else if W==32 then local X,g,K,z,l,k,x,H=(82);while true do if X>9.0 then g=65.0;z=(0);X=9+((W+X-W>=X and X or X)-X);elseif not(X<82.0)then else H=(4503599627370495);break;end;end;local A;X=116;while true do if X<109.0 and X>70.0 then x=(r[0X1][14]);break;elseif X>67.0 and X<104.0 then x=(6.0);X=0X6d+(r[0x1][0xe][8.0]((r[1][14][9.0]((r[0x1][0Xe][10.0](W+X))))));elseif X<70.0 then H=r[1][0X0e];X=-4294967225+((r[1][0Xe][11.0](W+W>=W and X or W))+X);elseif X>109.0 then z=(z*H);X=(-17+(((r[1][0XE][7.0]((r[1][0Xe][12.0](X,(W)))))>=X and X or W)-W));elseif X>104.0 and X<116.0 then H=(H[x]);X=-0x5+((r[0X1][14][9.0]((r[0x1][14][10.0](W-X,X))))+X);end;end;X=(0X68);while true do if X==104.0 then A=(7.0);X=(-169+(r[0X1][0Xe][12.0]((r[0x1][0Xe][12.0]((r[0x1][14][12.0](X+X,(W))),(W))),(W))));elseif X~=39.0 then else x=(x[A]);break;end;end;A=r[1][0Xe];X=0X3B;while true do if X<94.0 and X>37.0 then l=(7.0);X=67+((r[0X1][14][13.0](X+W,(W)))+X-W);elseif X<59.0 then l=r[0X001][0XE];break;elseif not(X>59.0)then else A=(A[l]);X=(0X5+((r[1][14][14.0](W<=X and W or W,(W)))+X-X));end;end;X=(0X73);while true do if X>29.0 then if not(X<=54.0)then K=6.0;l=l[K];X=-0X00d0+(r[1][14][14.0]((r[0X1][0xE][14.0](X+W,(W)))+X,(W)));else K=(O[Y]);X=(-25+((r[0X1][0Xe][13.0]((W==X and W or W)-X,(W)))+X));end;else k=(W);break;end;end;K=(K-k);k=W;l=l(K,k);X=116;while true do if X<116.0 then K=(O[Y]);l=(l+K);break;elseif X>67.0 then K=W;l=(l-K);X=67+(r[1][0XE][13.0](W-X-X-W,(W)));end;end;A=A(l);l=O[Y];x=x(A,l);A=O[Y];X=(0X3f);while true do if X==63.0 then x=(x+A);X=(-45+((r[1][0Xe][8.0](X-X))+X-W));elseif X==18.0 then A=(O[Y]);X=(0X29+(W-W+W+W-W));elseif X==73.0 then H=H(x,A);X=(-149+(r[1][14][10.0]((r[0X1][14][10.0](W<=X and X or X,W))+W,W)));elseif X==20.0 then z=z+H;X=(0x4a+((r[0X1][0XE][11.0]((r[0X1][14][9.0](W))-W))+X));elseif X==99.0 then g=(g+z);break;end;end;O[Y]=g;X=26;while true do if not(X>26.0)then if X<=11.0 then(g)[z]=(H);break;else g=D;X=(23+((r[1][0Xe][6.0]((r[0X1][0XE][6.0](X,(W)))-W,(W)))+X));end;else if not(X>=92.0)then z=(y[Y]);X=(43+(r[1][14][10.0]((r[0X1][0XE][9.0]((r[1][0XE][9.0](X))-W)),W,X)));else H=J[Y];X=-21+((r[0X1][14][6.0]((r[1][0Xe][11.0]((r[0x1][14][9.0](W)))),(W)))+W);end;end;end;else mouseClicked=(b[Y]);end;end;else if W<39 then if not(W>=0x25)then D[e[Y]]=(D[B[Y]]/f[Y]);else if W~=38 then D[y[Y]]=shared;else(D)[e[Y]]=(mouse1release);end;end;else if W<0X28 then D[B[Y]]=D[e[Y]];else if W~=0X29 then(D)[y[Y]]=(script);else D[e[Y]]=nil;end;end;end;end;end;else if not(W>=0Xa)then if W<5 then if not(W<2)then if W<3 then D[e[Y]]=workspace;else if W==0X4 then if D[y[Y]]==D[B[Y]]then else Y=(e[Y]);end;else D[e[Y]]=RaycastParams;end;end;else if W==1 then local X=e[Y];p=(X+y[Y]-1.0);for g in D do if g>p then D[g]=nil;end;end;(D[X])(r[3](p,X+1.0,D));p=X-1.0;for X in D do if not(X>p)then else D[X]=nil;end;end;else D[y[Y]]=(J[Y]^D[B[Y]]);end;end;else if W<7 then if W~=6 then D[y[Y]]=E.Yh;else D[B[Y]]=D[y[Y]][J[Y]];end;else if W<8 then if D[e[Y]]~=b[Y]then else Y=y[Y];end;else if W~=0x9 then for X=1.0,y[Y]do(D)[X]=(C[X]);end;else(D)[y[Y]]=UserSettings;end;end;end;end;else if W<0xF then if W<12 then if W==0xb then(D)[e[Y]]=E.wh;else(D)[B[Y]]=(Z[y[Y]][D[e[Y]]]);end;else if W<0XD then D[e[Y]]=r[0X1][18](y[Y]);else if W~=0Xe then D[y[Y]]=D[e[Y]]+b[Y];else D[e[Y]]=r[1][0Xe][B[Y]];end;end;end;else if not(W>=0X12)then if not(W>=0X10)then if not(u)then else for X,g in u do if X>=1.0 then g[0X1]=(g);g[0x2]=D[X];g[3]=(0X2);u[X]=nil;end;end;end;local X=(e[Y]);p=(X+1.0);return true,X,2.0;else if W==17 then(D)[B[Y]]=(D[e[Y]]^D[y[Y]]);else D[y[Y]]=mousemoverel;end;end;else if not(W<0X13)then if W~=20 then(D[B[Y]])[D[y[Y]]]=(J[Y]);else D[e[Y]]=mouse1click;end;else(D)[e[Y]]=-D[B[Y]];end;end;end;end;end;else if not(W>=0x3f)then if not(W>=52)then if W>=0X2F then if not(W<49)then if not(W<0X32)then if W~=51 then D[e[Y]]=y;else D[B[Y]]=f[Y]%J[Y];end;else D[B[Y]]=(next);end;else if W~=0X30 then(D)[e[Y]]=(mouseClicked);else mouseClicked=D[e[Y]];end;end;else if not(W<0X2c)then if W>=0x2d then if W==46 then D[y[Y]]=(D[B[Y]]+D[e[Y]]);else(D)[y[Y]]=D[B[Y]]..D[e[Y]];end;else local X,g,K=d-M-1.0,0.0,y[Y];if not(X<0.0)then else X=-1.0;end;for d=K,K+X do(D)[d]=(C[n+g]);g=g+1.0;end;p=K+X;for X in D do if X>p then(D)[X]=nil;end;end;end;else if W~=43 then(D)[B[Y]]=({});else if u then for X,d in u do if not(X>=1.0)then else(d)[1]=(d);d[2]=(D[X]);d[0x3]=0X2;u[X]=(nil);end;end;end;local X=(B[Y]);return false,X,X;end;end;end;else if W>=57 then if W>=60 then if W<61 then(D)[y[Y]]=(readfile);else if W~=62 then D[B[Y]]=(D[y[Y]]==D[e[Y]]);else(D)[e[Y]]=CFrame;end;end;else if not(W>=0X3A)then _=(w[0x2]);o=w[5];T=(w[4]);w=(w[0x3]);else if W~=59 then local X=B[Y];local d=D[X];local C=e[Y];r[10](D,X+1.0,p,C+1.0,d);else p=(B[Y]);for X in D do if X>p then(D)[X]=(nil);end;end;(D[p])();p=(p-1.0);for X in D do if not(X>p)then else D[X]=(nil);end;end;end;end;end;else if not(W<0X36)then if W>=0x037 then if W==56 then(D)[e[Y]]=(b[Y]+f[Y]);else D[y[Y]]=(iswindowactive);end;else local X=(B[Y]);p=X+1.0;for d in D do if not(d>p)then else D[d]=nil;end;end;(D)[X]=D[X](D[X+1.0]);p=X;for X in D do if X>p then(D)[X]=nil;end;end;end;else if W~=0X35 then(D)[e[Y]]=D[B[Y]][D[y[Y]]];else(D)[B[Y]]=(Drawing);end;end;end;end;else if W>=0x49 then if W>=0x4E then if W<0x51 then if not(W<0x4F)then if W==80 then Z[y[Y]][b[Y]]=D[e[Y]];else D[y[Y]]=(J[Y]+D[B[Y]]);end;else D[e[Y]]=(error);end;else if not(W>=82)then(D)[y[Y]]=(r[0x7](D[B[Y]],J[Y]));else if W~=83 then(D)[e[Y]]=O;else D[e[Y]]=E.hh;end;end;end;else if W<0X4B then if W==74 then local X=f[Y];local d=X[0X2];X=(#d);local O=X>0.0 and{};if not(O)then else for C=1.0,X do local M=d[C];local d=(M[0X1]);local n=M[0X003];if d==0.0 then if not(not u)then else u={};end;M=(u[n]);if not M then M=({[1]=D,[0X3]=n});u[n]=M;end;O[C-1.0]=M;elseif d~=1.0 then(O)[C-1.0]=Z[n];else(O)[C-1.0]=D[n];end;end;end;X=E[J[Y]](O);(D)[B[Y]]=X;else D[e[Y]]=(getgenv);end;else if W>=76 then if W==77 then(D)[y[Y]]=(D[B[Y]]*J[Y]);else w={[0X2]=_,[4]=T,[0X5]=o,[3]=w};p=(y[Y]);local X=r[8](function(...)(r[9])();for d,O in...do r[0x9](true,d,O);end;end);(X)(D[p],D[p+1.0],D[p+2.0]);for d in D do if not(d>p)then else D[d]=(nil);end;end;_=X;Y=B[Y];end;else(D)[e[Y]]=f[Y]-b[Y];end;end;end;else if W>=0X44 then if W<70 then if W~=0X45 then(D)[e[Y]]=(tick);else(D)[y[Y]]=(D[e[Y]]-D[B[Y]]);end;else if not(W<0X47)then if W==72 then D[B[Y]]=D[y[Y]]..J[Y];else(D)[e[Y]]=E.Ch;end;else D[B[Y]]=cloneref;end;end;else if W>=0x41 then if W<66 then(D)[y[Y]]=(J[Y]);else if W~=67 then(D)[y[Y]]=Z[e[Y]][b[Y]];else D[B[Y]]=(setthreadidentity);end;end;else if W==64 then D[e[Y]]=b[Y]..D[y[Y]];else(D)[e[Y]]=B;end;end;end;end;end;end;Y=Y+1.0;until false;end);if not(c)then if not(u)then else for X,Z in u do if not(X>=1.0)then else(Z)[0X1]=(Z);(Z)[2]=(D[X]);(Z)[0X003]=(2);u[X]=(nil);end;end;end;if r[4](N)~="string"then(r[0X1][24])(N,0.0);else if r[5](N,':(%d\43)[:\13\10]')then r[1][0X18]("L\117rap\104 \83\99r\105pt:"..(G[Y]or'(\105n\116ernal)')..':\32'..r[6](N),0.0);else r[0X1][24](N,0.0);end;end;elseif N then if s==1.0 then return D[L]();else return D[L](r[0X3](p,L+1.0,D));end;else if not(L)then else return r[0x3](s,L,D);end;end;end;end;end;return V;end;q[0x2a]=(function(...)local X,Z,D={q},(0x2A);repeat if Z==42.0 then D,Z=E:Ki(Z,X);if D~=nil then return E.n(D);end;else if Z==1.0 then return(...)[...];end;end;until false;end);return Q;end,l=function(...)(...)[...]=nil;end,Ih=function(E,E,X,q)E[0X2][5][X+1.0]=(q);end,Li=function(E)end,Mi=function(E,X,q,Q,Z,D)if Z%2.0~=0.0 then q=D[0X2][30]();local Z=D[2][30]();if D[0X2][0X20]==D[2][10]then else E:ii(X,Q,Z,q);end;else E:Ci(q,X,Q);end;return q;end,Ui=function(E,E)return{E};end,g=coroutine.wrap,eh=bit32.rrotate,Y=function(E,X,q)X[0X4466]=(-4117027582+(E.uh((E.Rh((E.uh(E.U[0X4]+E.U[6],q,X[0X2E14])),(X[0x2E14]))))));X[0X108D]=(-3254792228+(((X[6418]+E.U[0x7]>=X[11796]and E.U[5]or E.U[8])<=E.U[2]and E.U[0X4]or X[6418])+E.U[0X7]));q=(-472143719+((E.nh(E.U[0x2]+E.U[0x5],(X[0X2E14])))-X[0X006549]-E.U[2]));X[0X4263]=(q);return q;end,hh=string,Fi=function(E,X,q,Q,Z,D,r)if Z>73.0 then E:fi(X,r,D,Q,q);else if Z<159.0 then r=Q[0x1]();end;end;return r;end,i=bit32.countlz,zh=function(E,X,q,Q,Z,D,r,d,G)if Z>338.0 then(q[0X2][5])[X+2.0]=d;q[2][5][X+3.0]=r;return 26287,X;elseif Z>118.0 and Z<338.0 then if q[2][39]~=D then else return{0X39^G},X;end;else if Z<228.0 then X=E:mh(q,X);else if Z>228.0 and Z<448.0 then E:Ih(q,X,Q);end;end;end;return nil,X;end,Oi=function(E,E)E[1][0x2]=(E[1][32]>127);return{};end,Z=function(E,X,q,Q)if not(Q<85.0)then Q=E:x(q,X,Q);else E:r(q);return 11019,Q;end;return nil,Q;end,Bh=function(E,E,X)X=E[0X001][32]();return X;end,wi=function(E,E,X,q)X=q[0X2][18](E);return X;end,m=function(E)local X=E[0];local q=E[1];local Q=E[2];return function(E,Z,D)if not E then return;end;X.EntityThreads[E]=task.spawn(function()local r,d,G;if Z then r=q(E,"Humanoid",10)or{};d=r and q(r,'RootP\97r\116',workspace.StreamingEnabled and 9e9 or 10,true);G=E:WaitForChild("Hitb\111xHead",1)or E:WaitForChild("H\101ad",10)or d;else r=q(E,'Humanoid',10)or{HipHeight=0};d=q(E,'Pr\105mar\121P\97\114t',10,true);G=E:WaitForChild("Hi\116b\111x\72\101ad",1)or E:WaitForChild("\72ead",10)or d;end;local q,b=r.Health or E:GetAttribute("H\101a\108t\104")or 100,r.MaxHealth or E:GetAttribute("\77a\120\72eal\116\104")or 100;if r and d then local O={Connections={},Character=E,Health=q,Head=G,Humanoid=r,HumanoidRootPart=d,HipHeight=r.HipHeight+(d.Size.Y/2)+(r.RigType==Enum.HumanoidRigType.R6 and 2 or 0),MaxHealth=b,NPC=Z==nil,Player=Z,RootPart=d,TeamCheck=D};if Z==Q then X.character=O;X.isAlive=true;X.Events.LocalAdded:Fire(O);else O.Targetable=X.targetCheck(O);for q,q in X.getUpdateConnections(O)do table.insert(O.Connections,q:Connect(function()O.Health=E:GetAttribute('\72e\97\108th')or r.Health or 100;O.MaxHealth=E:GetAttribute('MaxHe\97lth')or r.MaxHealth or 100;X.Events.EntityUpdated:Fire(O);end));end;table.insert(X.List,O);X.Events.EntityAdded:Fire(O);end;table.insert(O.Connections,E.ChildRemoved:Connect(function(q)if q==d or q==r or q==G then if q==d and r.RootPart then d=r.RootPart;O.RootPart=r.RootPart;O.HumanoidRootPart=r.RootPart;return;end;X.removeEntity(E,Z==Q);end;end));end;X.EntityThreads[E]=nil;end);end;end,v=function(E,X,q)q=-0X27CDdf1B+((E.uh(q-E.U[5]-E.U[4],X[0X1912],X[0X4263]))+X[0xAbF]);(X)[0X30CE]=(q);return q;end,Si=function(E,E,X,q,Q,Z,D)if Q~=11.0 then Q=(0X31);X=(D/4.0);else(Z)[E]=q;return 6197,X,Q;end;return nil,X,Q;end,ei=function(E,E,X)X=E[1]();return X;end,ch=function(E,X,q,Q)local Z;for D=1.0,q,1 do local q,r,d;d,q,r=E:Lh(r,q,d);repeat q,r,Z,d=E:Th(Q,d,q,r);if Z~=0XDC07 then else break;end;until false;if not(X)then Q[1][31][D]=(q);else(Q[0X1][31])[D]={[0.0]=q};end;end;end,yi=function(E,E,X,q,Q,Z,D,r)if not(Q[0x2][29])then q[Z]=(Q[0X2][0X1f][E]);else local q,d;for G=0X73,0X9d,14 do if G==0x81 then d=(#q);elseif G==0X9D then if D~=0X51 then for b=117,215,0X62 do if b>=215.0 then(q)[d+3.0]=8.0;else(q)[d+1.0]=(r);q[d+2.0]=Z;end;end;end;elseif G==0x8F then if D==25 then else X,Q[0x2][0x14]=61,(D<140);if not(D)then else(Q[2])[0X1C]=(D);end;end;else if G~=115 then else q=Q[0x2][31][E];end;end;end;end;return X;end,Lh=function(E,E,X,q)X=(nil);E=nil;q=0X4e;return q,X,E;end,o=function(E)local X=E[1];local q=E[0];return function(E,Q,...)if debug.info(1,"n")=='Sta\114\116Sh\111oting'or debug.info(2,'n')=='Star\116Shooti\110g'or debug.info(3,"n")=='StartSh\111o\116\105ng'or debug.info(4,'n')=='St\97rtSho\111ti\110g'or debug.info(5,"n")=='S\116ar\116Shooting'or debug.info(6,"n")=="Sta\114tSh\111oti\110g"or debug.info(7,'n')=='\83t\97r\116Shooting'or debug.info(8,'n')=='StartShoo\116\105\110g'then local Z,D,r=q(Q);local q={};if Z and D then q.Position=D.Position;q.Instance=D;q.Material=D.Material or Enum.Material.Plastic;q.Normal=D.CFrame and D.CFrame.LookVector or Vector3.new(0,1,0);q.Distance=(D.Position-r).Magnitude;return q;end;end;return X[1][X[3]](E,Q,...);end;end,Oh=function(E,X,q)(X[0X1])[0X2b]=E.B;return{q};end,Ti=function(E,X,q)local Q;X=q[0x1]();if X>=q[0X2][0x10]then Q=E:Qi(X,q);return{E.n(Q)},X;end;return nil,X;end,uh=bit32.bor,Ci=function(E,E,X,q)X[E]=q-q%1.0;end,_i=function(E,E,X)(X[0X1])[0X3]=E;end,bi=function(E,X,q,Q,Z,D,r)if D==0Xb then X=E:Mi(r,X,q,Q,Z);else if D==0x17 then X=X+1.0;return 31539,X;end;end;return nil,X;end,zi=function(E,X,q,Q)local Z;while true do Z,Q=E:mi(q,Q,X);if Z~=0x3825 then else break;end;end;(X)[0X1B]=E.K;X[0X1c]=(function()local q,Z=({X});Z=E:Ii(q);return E.n(Z);end);X[29]=E.B;(X)[0X1e]=nil;X[31]=nil;X[0x20]=nil;return Q;end,Ii=function(E,E)local X=E[0X1][0X0014](E[1][25],E[0X1][0X3],E[1][0X3]);E[0X1][0x3]=(E[1][3]+1.0);return{X};end,pi=function(E,E,X,q)E=(0XA);X[5.0]=q;return E;end,V=function(E,X,q,Q)(Q)[0X11]=E.N;(Q)[18]=(E.Q.create);if not X[30856]then q=(-3155019911+((E.nh(E.U[0X08]-E.U[0x8],(X[2751])))+E.U[4]-X[16995]));X[30856]=(q);else q=(X[30856]);end;return q;end,G=function(E,X,q,Q,Z)local D;Z[0X14]=nil;Z[0X15]=(nil);X=(85);repeat D,X=E:Z(Q,Z,X);if D==0X2b0b then break;end;until false;q=(E.c.char);return X,q;end,L=unpack,kh=string.byte,Kh=function(E,X,q,Q)X=(function()local Z,D,r,d,G={q,q[35],q[0x22]};r,d,G=E:lh(G,r,Z,d);local q;G,q=E:Xh(q,G,d,r,Z);D=E:Oh(Z,q);return E.n(D);end);Q=function(...)return(...)();end;return X,Q;end,H=function(E,X,q,Q)if not(Q<=91.0)then Q=E:V(X,Q,q);else q[0x10]=(4503599627370496);if not(not X[16995])then Q=(X[0x4263]);else Q=E:Y(X,Q);end;end;return Q;end,E=function(E,X,q)for Q=0X31,58,9 do E:D(X,q,Q);end;end,X=string.pack,W=pcall,p=function(E,X,q,Q)(q)[17]=nil;q[18]=(nil);(q)[19]=nil;Q=91;while true do if not(Q<=69.0)then Q=E:H(X,q,Q);else(q)[0X13]=({});break;end;end;return Q;end,Xi=function(E,E)return{E[0X1][0X27]};end,ki=function(E,E,X)X[2][42]=E;end,F=function(E,X,q,Q)(q)[11]=(nil);X=37;while true do if X<64.0 then X=E:a(X,Q,q);else if not(X>37.0)then else E:f(q);break;end;end;end;q[12]=(function(E,Q,Z)local D=({q});Q=(Q or 1.0);E=(E or#Z);if(E-Q+1.0)>7997.0 then return D[0X1][11](Q,E,Z);else return D[1][4](Z,Q,E);end;end);q[0xD]=(nil);q[14]=(nil);X=0x53;return X;end,fi=function(E,X,q,Q,Z,D)if X~=25 then local r=10;repeat if r>10.0 then E:ki(X,Z);break;else if r<97.0 then Z[2][0X13],Z[0X2][2]=Z[0X2][0x13],(X);r=(0x61);end;end;until false;elseif Z[2][0xB]==Z[0x2][10]then if not(-(208~=201))then else Z[2][39]=Z[2][30];end;else if Z[0X2][43][q]then Q[D]=Z[2][43][q];else E:ai(Z,D,Q,q);end;end;end,q=coroutine.yield,d=bit32.bxor,gh=function(E,E,X)X=E[0X697B];return X;end,ah=bit32.band,qh=function(E,X,q,Q)for Z=29,0X6C,14 do if Z<43.0 then if q~=185.0 then Q=E:Bh(X,Q);else Q=X[3]();end;else if Z>29.0 then break;end;end;end;return Q;end,Xh=function(E,X,q,Q,Z,D)while true do if q==121.0 then E:ch(Q,Z,D);break;else q=0X79;(D[0x1])[0X1D]=Q;end;end;Z=D[0X2]()-98745;local r=D[0x1][0X12](Z);D[1][0X5]=D[0X1][18](Z*3.0);for d=0X39,139,41 do E:Nh(D,d,Q,Z,r);end;X=(nil);for Q=21,241,110 do if Q<131.0 then X=r[D[0x2]()];elseif Q>131.0 then(D[1])[0X5]=E.B;else if not(Q>21.0 and Q<241.0)then else(D[1])[31]=E.B;end;end;end;return q,X;end,Di=function(E,E,X,q,Q)(q[2][0X5])[X+1.0]=(Q);(q[2][5])[X+2.0]=(E);end,ji=function(E,X,q,Q,Z,D,r,d)local G;if Q<=26.0 then G,X,Q=E:Si(D,X,d,Q,Z,q);if G~=6197 then else return 49464,X,d,Q;end;else if Q~=92.0 then Q=(0x5c);d={[1]=q%4.0,[0X3]=X-X%1.0};else(r[2][0X2B])[q]=(d);Q=0xB;end;end;return nil,X,d,Q;end,Yi=function(E,E,X,q,Q)Q=116;E=X[2][18](q);return E,Q;end,P=string.sub,w=function(E,X,q,Q)local Z;repeat Z,X=E:h(X,Q,q);if Z~=10767 then else break;end;until false;(Q)[15]=E.P;(Q)[16]=(nil);return X;end,qi=function(E,X,q)(q)[35]=(function()local Q,Z,D,r={q,q[0X22]},0.0,1.0;for d=9,0X3B,4 do Z,r,D=E:Bi(D,d,Q,Z);if r==nil then else return E.n(r);end;end;end);q[36]=nil;q[37]=(nil);q[38]=nil;q[0X27]=nil;X=42;return X;end,Ph=function(E,E,X,q,Q)if X[1][36]~=q then X[0x1][0X5][Q][X[1][0X5][Q+1.0]]=(E[X[0X1][5][Q+2.0]]);end;end,C=bit32.lrotate,A=function(E)local X=E[3];local q=E[15];local Q=E[11];local Z=E[12];local D=E[5];local r=E[8];local d=E[4];local G=E[16];local b=E[13];local O=E[14];local e=E[10];local B=E[17];local y=E[1];local f=E[2];local J=E[6];local V=E[9];local u=E[7];local C=E[0];return function()local E=Z[1][Z[3]].FighterController._player_to_fighter[y].EquippedItem;if E then if not E.dsfafd then E.IsFullyAiming=function(...)return true;end;E.dsfafd=true;end;end;if b[1][b[3]]then b[1][b[3]].Position=G:GetMouseLocation();end;if V[1][V[3]].Enabled then local E=C[1][C[3]].Value=="Camer\97"and O.CFrame or J.isAlive and J.character.RootPart.CFrame or CFrame.identity;local G=J["E\110\116\105t\121"..B[1][B[3]].Value]({Range=D[1][D[3]].Value,Wallcheck=true,Part='H\101\97d',Origin=(E*f).Position,Players=u[1][u[3]].Enabled,NPCs=Q[1][Q[3]].Enabled});if G and Z[1][Z[3]].FighterController._player_to_fighter[y].EquippedItem then if q[1][q[3]].Enabled then d.Targets[G]=tick()+1;end;X[1][X[3]]=G;local E,q=Z[1][Z[3]].FighterController._player_to_fighter[y].EquippedItem.ViewModel,Z[1][Z[3]].FighterController._player_to_fighter[y].EquippedItem.ViewModel.PlayAnimation;if e[1][e[3]].Enabled then E.PlayAnimation=function(Q,Z,...)if Z=='Shoo\116\49'or Z=="\82e\108oad"then return nil;end;return q(Q,Z,...);end;end;if mouse1click and(isrbxactive or iswindowactive)()then if not r.ClickGuiStatus then mouse1click();end;end;X[1][X[3]]=nil;X[1][X[3]]=nil;if q then E.PlayAnimation=q;end;end;end;end;end,sh=bit32,th=function(E,X,q,Q,Z,D,r)local d,G;for b=0x76,0X22f,0X6e do d,G=E:zh(G,Z,q,b,X,Q,D,r);if d==26287 then break;else if d~=nil then return{E.n(d)};end;end;end;return nil;end}):Vh()(...);
end


-- ================================================================
-- 9. EXECUTION ENTRY POINT FOR RIVALS
-- ================================================================
-- Load base Universal features first
local okUniv, errUniv = pcall(function()
    return ModernFile.loadfile('Modern/Games/Universal.lua')
end)
if not okUniv then
    warn('[Modern] Universal base init note: ' .. tostring(errUniv))
end

-- Load Rivals Game Script (Place ID 17625359962)
local okRivals, errRivals = pcall(function()
    return ModernFile.loadfile('Modern/Games/17625359962.lua')
end)
if not okRivals then
    warn('[Modern] Rivals module init note: ' .. tostring(errRivals))
end

print('[Modern] Successfully loaded Modern for Rivals (PlaceId: 17625359962)!')
return Modern
