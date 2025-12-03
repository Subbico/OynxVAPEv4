repeat task.wait() until game:IsLoaded()
if shared.vape then shared.vape:Uninject() end

if identifyexecutor then
	if table.find({'Argon'}, ({identifyexecutor()})[1]) then
		getgenv().setthreadidentity = nil
	end
end

local vape
local loadstring = function(...)
	local res, err = loadstring(...)
	if err and vape then
		vape:CreateNotification("Onyx", 'Failed to load : '..err, 30, 'alert')
	end
	return res
end


local queue_on_teleport = queue_on_teleport or function() end

local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local cloneref = cloneref or function(obj)
	return obj
end
local playersService = cloneref(game:GetService('Players'))

local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/soryed/OynxVAPEv4/'..readfile('ReVape/profiles/commit.txt')..'/'..select(1, path:gsub('ReVape/', '')), true)
		end)
		if not suc or res == '404: Not Found' then
			error(res)
		end
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end
local function serializeValue(v)
    local t = type(v)
    if t == "string" then
        return ("%q"):format(v)
    elseif t == "number" or t == "boolean" or t == "nil" then
        return tostring(v)
    elseif t == "table" then
        local isArray = true
        local max = 0
        for k,_ in pairs(v) do
            if type(k) ~= "number" then isArray = false break end
            if k > max then max = k end
        end
        if isArray then
            local parts = {}
            for i = 1, max do
                table.insert(parts, serializeValue(v[i]))
            end
            return "{" .. table.concat(parts, ",") .. "}"
        else
            local parts = {}
            for k,val in pairs(v) do
                local key
                if type(k) == "string" and k:match("^[_%a][_%w]*$") then
                    key = k
                else
                    key = "[" .. serializeValue(k) .. "]"
                end
                table.insert(parts, key .. "=" .. serializeValue(val))
            end
            return "{" .. table.concat(parts, ",") .. "}"
        end
    else
        return ("%q"):format(tostring(v))
    end
end

local function finishLoading()

	vape.Init = nil
	vape:Load()
	task.spawn(function()
		repeat
			vape:Save()
			task.wait(10)
		until not vape.Loaded
	end)


	local teleportedServers
		vape:Clean(playersService.LocalPlayer.OnTeleport:Connect(function()
				
		if (not teleportedServers) and (not shared.VapeIndependent) then
			teleportedServers = true
			local teleportScript = [[
				shared.vapereload = true
				if shared.VapeDeveloper then

					loadstring(readfile('ReVape/loader.lua'), 'loader')()
				else

					loadstring(game:HttpGet('https://raw.githubusercontent.com/soryed/OynxVAPEv4/'..readfile('ReVape/profiles/commit.txt')..'/loader.lua', true), 'loader')()
				end
			]]
			if shared.VapeDeveloper then

				teleportScript = 'shared.VapeDeveloper = true\n'..teleportScript
						
			end
			    if getgenv().username ~= nil then
        teleportScript = "getgenv().username = " .. serializeValue(getgenv().username) .. "\n" .. teleportScript
    end
    if getgenv().password ~= nil then
        teleportScript = "getgenv().password = " .. serializeValue(getgenv().password) .. "\n" .. teleportScript
    end
    if getgenv().SLS then
        teleportScript = "getgenv().SLS = true\n" .. teleportScript
    end
    if getgenv().SkipLoadingScreen then
        teleportScript = "getgenv().SkipLoadingScreen = true\n" .. teleportScript
    end
	if getgenv().TestMode then
        teleportScript = "getgenv().TestMode = true\n" .. teleportScript
    end
    if shared.VapeCustomProfile then
        teleportScript = "shared.VapeCustomProfile = " .. serializeValue(shared.VapeCustomProfile) .. "\n" .. teleportScript
    end

			vape:Save()
			queue_on_teleport(teleportScript)
		end
	end))

	if not shared.vapereload then
		if not vape.Categories then return end
		if vape.Categories.Main.Options['GUI bind indicator'].Enabled then
			vape:CreateNotification('Onyx', "Initialized as " .. vape.user .. " with role " .. vape.role, 3)
			task.wait(2.75)
			vape:CreateNotification('Finished Loading', vape.VapeButton and 'Press the button in the top right to open GUI' or 'Press '..table.concat(vape.Keybind, ' + '):upper()..' to open GUI', 5)
		end
	end
end

if not isfile('ReVape/profiles/gui.txt') then
	writefile('ReVape/profiles/gui.txt', 'new')
end

local gui = readfile('ReVape/profiles/gui.txt')

if not isfolder('ReVape/assets/'..gui) then
	makefolder('ReVape/assets/'..gui)
end
vape = loadstring(downloadFile('ReVape/guis/'..gui..'.lua'), 'gui')()
shared.vape = vape

if not shared.VapeIndependent then
	loadstring(downloadFile('ReVape/libraries/announcement.lua'), 'announcement')()
	loadstring(downloadFile('ReVape/libraries/base64.lua'), 'base64')()
	loadstring(downloadFile('ReVape/libraries/create.lua'), 'create')()
	loadstring(downloadFile('ReVape/libraries/spotify.lua'), 'spotify')()
	loadstring(downloadFile('ReVape/libraries/pathfind.lua'), 'pathfind')()
	loadstring(downloadFile('ReVape/games/universal.lua'), 'universal')()
	if isfile('ReVape/games/'..game.PlaceId..'.lua') then
		loadstring(readfile('ReVape/games/'..game.PlaceId..'.lua'), tostring(game.PlaceId))(...)
	else
		if not shared.VapeDeveloper then
			local suc, res = pcall(function()
				return game:HttpGet('https://raw.githubusercontent.com/soryed/OynxVAPEv4/'..readfile('ReVape/profiles/commit.txt')..'/games/'..game.PlaceId..'.lua', true)
			end)
			if suc and res ~= '404: Not Found' then
				loadstring(downloadFile('ReVape/games/'..game.PlaceId..'.lua'), tostring(game.PlaceId))(...)
			end
		end
	end

	finishLoading()
else
	vape.Init = finishLoading
	return vape
end
--[[

didnt rlly like
	repeat task.wait() until game:IsLoaded()
if shared.vape then shared.vape:Uninject() end

if identifyexecutor then
	if table.find({'Argon'}, ({identifyexecutor()})[1]) then
		getgenv().setthreadidentity = nil
	end
end

local vape
local loadstring = function(...)
	local res, err = loadstring(...)
	if err and vape then
		vape:CreateNotification("Onyx", 'Failed to load : '..err, 30, 'alert')
	end
	return res
end


local queue_on_teleport = queue_on_teleport or function() end

local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local cloneref = cloneref or function(obj)
	return obj
end
local playersService = cloneref(game:GetService('Players'))
local gethui = gethui or function() return game:GetService('Players').LocalPlayer.PlayerGui end
local tweenService = game:GetService('TweenService')

local gui : ScreenGui = Instance.new('ScreenGui', gethui())
gui.Enabled = true
gui.Name = "OynxUIMain"
local stages = {
	UDim2.new(0, 25, 1, 0),
	UDim2.new(0, 50, 1, 0),
	UDim2.new(0, 75, 1, 0),
	UDim2.new(0, 135, 1, 0),
	UDim2.new(0, 160, 1, 0),
	UDim2.new(0, 185, 1, 0),
	UDim2.new(0, 200, 1, 0),
	UDim2.new(0, 229, 1, 0),
	UDim2.new(0, 235, 1, 0),
	UDim2.new(0, 240, 1, 0),
}

local createinstance = function(class, properties)
	local res = Instance.new(class)
	
	for property, value in properties do
		res[property] = value
	end

	return res
end

if gui.Enabled then
	createinstance('ImageLabel', {
		Name = 'Main',
		Parent = gui,
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(685, 399),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ScaleType = Enum.ScaleType.Fit,
		Image = 'rbxassetid://93496634716737'
	})

	local Exit = createinstance('ImageButton', {
		Name = 'Exit',
		Parent = gui.Main,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(624, 23),
		Size = UDim2.fromOffset(40, 30),
		AutoButtonColor = false,
		ImageColor3 = Color3.fromRGB(34, 33, 34),
		Image = 'rbxassetid://110629770884920',
		ScaleType = Enum.ScaleType.Fit
	})
	Exit.MouseButton1Click:Connect(function()
		task.spawn(function() 
			for _, v in gui:GetDescendants() do
				for __, prop in ipairs({'BackgroundTransparency', 'ImageTransparency', 'TextTransparency'}) do
					task.spawn(function()
						pcall(function()
							tweenService:Create(v, TweenInfo.new(1, Enum.EasingStyle.Quad), {
								[prop] = 1
							}):Play()
							task.wait(1.5)
							v:Destory()
						end)
					end)
				end
			end
		end)
	end)
	createinstance('ImageLabel', {
		Name = 'Icon',
		Parent = gui.Main.Exit,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		AnchorPoint = Vector2.new(0, 0.5),
		ImageTransparency = 0.4,
		ImageColor3 = Color3.new(1, 1, 1),
		Image = 'rbxassetid://128518278755224',
		ScaleType = Enum.ScaleType.Fit
	})

	createinstance('ImageButton', {
		Name = 'Minimize',
		Parent = gui.Main,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(582, 23),
		Size = UDim2.fromOffset(40, 30),
		AutoButtonColor = false,
		ImageColor3 = Color3.fromRGB(34, 33, 34),
		Image = 'rbxassetid://133363055871405',
		ScaleType = Enum.ScaleType.Fit
	})

	createinstance('ImageLabel', {
		Name = 'Icon',
		Parent = gui.Main.Minimize,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 14, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		AnchorPoint = Vector2.new(0, 0.5),
		ImageTransparency = 0.4,
		ImageColor3 = Color3.new(1, 1, 1),
		Image = 'rbxassetid://83568668289707',
		ScaleType = Enum.ScaleType.Fit
	})

	createinstance('ImageLabel', {
		Name = 'textvape',
		Parent = gui.Main,
		AnchorPoint = Vector2.new(0.48, 0.31),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.48, 0.31),
		Size = UDim2.fromOffset(70, 70),
		Image = 'rbxassetid://84228868064393',
		ScaleType = Enum.ScaleType.Fit
	})

	createinstance('ImageLabel', {
		Name = 'version',
		Parent = gui.Main.textvape,
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(1, 0.3),
		Size = UDim2.fromOffset(29, 29),
		Image = 'rbxassetid:///14368357095',
		ImageColor3 = Color3.fromRGB(98, 198, 158),
		ScaleType = Enum.ScaleType.Fit
	})

	createinstance('Frame', {
		Name = 'loadbar',
		Parent = gui.Main,
		AnchorPoint = Vector2.new(0.5, 0.53),
		BackgroundColor3 = Color3.fromRGB(20, 20, 20),
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.5, 0.53),
		Size = UDim2.fromOffset(240, 6)
	})

	createinstance('Frame', {
		Name = 'fullbar',
		Parent = gui.Main.loadbar,
		BackgroundColor3 = Color3.fromRGB(3, 102, 79),
		BorderSizePixel = 0,
		Size = UDim2.new(0, 0, 1, 0),
		ZIndex = 2
	})

	createinstance('TextLabel', {
		Name = 'action',
		Parent = gui.Main,
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.353284657, 0.556391001),
		Size = UDim2.fromOffset(200, 15),
		Font = Enum.Font.Arial,
		Text = '',
		TextColor3 = Color3.new(1, 1, 1),
		TextSize = 12,
		TextTransparency = 0.3
	})

	Instance.new('UICorner', gui.Main.loadbar)
	Instance.new('UICorner', gui.Main.loadbar.fullbar)
	Instance.new('UIScale', gui.Main).Scale = math.max(gui.AbsoluteSize.X / 1920, 0.485)
end;

makestage = function(stage, package, dely)
	dely = dely or 0.01
	pcall(function()
		task.delay(dely, function()
			tweenService:Create(gui.Main.loadbar.fullbar, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {
				Size = stages[stage]
			}):Play()

			gui.Main.action.Text = package or ''

			if stage == 10 then 
				task.wait(dely - 0.95)
				for _, v in gui:GetDescendants() do
					for __, prop in ipairs({'BackgroundTransparency', 'ImageTransparency', 'TextTransparency'}) do
						task.spawn(function()
							pcall(function()
								tweenService:Create(v, TweenInfo.new(1, Enum.EasingStyle.Quad), {
									[prop] = 1
								}):Play()
							end)
						end)
					end
				end
			end
		end)
	end)
end
local function serializeValue(v)
    local t = type(v)
    if t == "string" then
        return ("%q"):format(v)
    elseif t == "number" or t == "boolean" or t == "nil" then
        return tostring(v)
    elseif t == "table" then
        local isArray = true
        local max = 0
        for k,_ in pairs(v) do
            if type(k) ~= "number" then isArray = false break end
            if k > max then max = k end
        end
        if isArray then
            local parts = {}
            for i = 1, max do
                table.insert(parts, serializeValue(v[i]))
            end
            return "{" .. table.concat(parts, ",") .. "}"
        else
            local parts = {}
            for k,val in pairs(v) do
                local key
                if type(k) == "string" and k:match("^[_%a][_%w]*$") then
                    key = k
                else
                    key = "[" .. serializeValue(k) .. "]"
                end
                table.insert(parts, key .. "=" .. serializeValue(val))
            end
            return "{" .. table.concat(parts, ",") .. "}"
        end
    else
        return ("%q"):format(tostring(v))
    end
end

local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/soryed/OynxVAPEv4/'..readfile('ReVape/profiles/commit.txt')..'/'..select(1, path:gsub('ReVape/', '')), true)
		end)
		if not suc or res == '404: Not Found' then
			error(res)
		end
		if path:find('.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end

local function finishLoading()

	vape.Init = nil
	vape:Load()
	task.spawn(function()
		repeat
			vape:Save()
			task.wait(10)
		until not vape.Loaded
	end)


	local teleportedServers
		vape:Clean(playersService.LocalPlayer.OnTeleport:Connect(function()
				
		if (not teleportedServers) and (not shared.VapeIndependent) then
			teleportedServers = true
			local teleportScript = 
				shared.vapereload = true
				if shared.VapeDeveloper then
					loadstring(readfile('newvape/loader.lua'), 'loader')()
				else
					loadstring(game:HttpGet('https://raw.githubusercontent.com/7GrandDadPGN/VapeV4ForRoblox/'..readfile('newvape/profiles/commit.txt')..'/loader.lua', true), 'loader')()
end
			
			if shared.VapeDeveloper then

				teleportScript = 'shared.VapeDeveloper = true\n'..teleportScript
						
			end
			    if getgenv().username ~= nil then
        teleportScript = "getgenv().username = " .. serializeValue(getgenv().username) .. "\n" .. teleportScript
    end
    if getgenv().password ~= nil then
        teleportScript = "getgenv().password = " .. serializeValue(getgenv().password) .. "\n" .. teleportScript
    end
    if getgenv().SLS then
        teleportScript = "getgenv().SLS = true\n" .. teleportScript
    end
    if getgenv().SkipLoadingScreen then
        teleportScript = "getgenv().SkipLoadingScreen = true\n" .. teleportScript
    end
    if shared.VapeCustomProfile then
        teleportScript = "shared.VapeCustomProfile = " .. serializeValue(shared.VapeCustomProfile) .. "\n" .. teleportScript
    end
			vape:Save()
			queue_on_teleport(teleportScript)
		end
	end))

	if not shared.vapereload then
		if not vape.Categories then return end
		if vape.Categories.Main.Options['GUI bind indicator'].Enabled then
			makestage(10, 'finished :D', 0.85)
			task.wait(1.25)
			vape:CreateNotification('Onyx', "Initialized as " .. vape.user .. " with role " .. vape.role, 3)
			task.wait(2.75)
			vape:CreateNotification('Finished Loading', vape.VapeButton and 'Press the button in the top right to open GUI' or 'Press '..table.concat(vape.Keybind, ' + '):upper()..' to open GUI', 5)
		end
	end
end

if not isfile('ReVape/profiles/gui.txt') then
	writefile('ReVape/profiles/gui.txt', 'new')
end

local gui = readfile('ReVape/profiles/gui.txt')

if not isfolder('ReVape/assets/'..gui) then
	makefolder('ReVape/assets/'..gui)
end
makestage(1, 'loading functions/modules.', .96)
task.wait(.99)
vape = loadstring(downloadFile('ReVape/guis/'..gui..'.lua'), 'gui')()
shared.vape = vape
makestage(2, 'checking executor support.', 1)
task.wait(1)
makestage(3, 'validating executor functions.', 0.5)
task.wait(.5)
makestage(4, 'analyzing supported environment.', .5)
task.wait(.5)
if identifyexecutor then
	if table.find({'Codex','Macsploit','Nihon','Argon','Xeno'}, ({identifyexecutor()})[1]) then
		makestage(4, 'executor not support.', .5)
			task.wait(.55)
					makestage(4, 'uninjecting.', .85)
			task.wait(.9)
			task.spawn(function() 
for _, v in gui:GetDescendants() do
					for __, prop in ipairs({'BackgroundTransparency', 'ImageTransparency', 'TextTransparency'}) do
						task.spawn(function()
							pcall(function()
								tweenService:Create(v, TweenInfo.new(1, Enum.EasingStyle.Quad), {
									[prop] = 1
								}):Play()
							end)
						end)
					end
				end
		end)
			vape:Uninject()

			return
	end
	if table.find({'Delta','Hydrogen','Sirhurt','Solara'}, ({identifyexecutor()})[1]) then
			makestage(4, 'executor is support, may cause some issues.', .5)
			getgenv().CheatEngineMode = true
			task.wait(.5)
		end
end
makestage(5, 'checking for updates.', 0.7)
task.wait(0.7)
local CV = vape.Version or "0.0.1"
local UV = game:HttpGet("https://raw.githubusercontent.com/soryed/OynxVAPEv4/refs/heads/main/verison")
local IVM = false
task.spawn(function()
	if CV == tostring(UV) or CV == UV or CV ~= UV then IVM = false else IVM = true end
end)
if IVM then
		makestage(5, 'verison miss-match currentVerison - '..CV, 1)
		task.wait(1.2)
		makestage(5, 'restarting...', .8)
		task.wait(.95)
		task.spawn(function() 
			for _, v in gui:GetDescendants() do
					for __, prop in ipairs({'BackgroundTransparency', 'ImageTransparency', 'TextTransparency'}) do
						task.spawn(function()
							pcall(function()
								tweenService:Create(v, TweenInfo.new(1, Enum.EasingStyle.Quad), {
									[prop] = 1
								}):Play()
							end)
						end)
					end
				end
		end)
		shared.vapereload = true
		if shared.VapeDeveloper then

			getgenv().username =getgenv().username or "GUEST"
			getgenv().password =getgenv().password or "PASSWORD"
			loadstring(readfile('ReVape/loader.lua'), 'loader')()

		else
			getgenv().username =getgenv().username or "GUEST"
			getgenv().password =getgenv().password or "PASSWORD"							
			loadstring(game:HttpGet('https://raw.githubusercontent.com/soryed/OynxVAPEv4/'..readfile('ReVape/profiles/commit.txt')..'/loader.lua', true))()
		end
	else
		makestage(6, 'fetching latest version.', 0.7)
		task.wait(0.8)
	end
if not shared.VapeIndependent then
	makestage(7, 'downloading game packages.', 2.34)
	task.wait(2.5)
	makestage(8, 'verifying game packages.', 0.15)
	task.wait(.15)
	loadstring(downloadFile('ReVape/games/universal.lua'), 'universal')()
	loadstring(downloadFile('ReVape/games/modules.luau'), 'modules')()
	loadstring(downloadFile('ReVape/libraries/announcement.lua'), 'announcement')()
	if isfile('ReVape/games/'..game.PlaceId..'.lua') then
		makestage(9, 'loading all packages.', 1.005)
		loadstring(readfile('ReVape/games/'..game.PlaceId..'.lua'), tostring(game.PlaceId))(...)
	else
		if not shared.VapeDeveloper then
			local suc, res = pcall(function()
				return game:HttpGet('https://raw.githubusercontent.com/soryed/OynxVAPEv4/'..readfile('ReVape/profiles/commit.txt')..'/games/'..game.PlaceId..'.lua', true)
			end)
			if suc and res ~= '404: Not Found' then
				loadstring(downloadFile('ReVape/games/'..game.PlaceId..'.lua'), tostring(game.PlaceId))(...)
			end
		end
	end

	finishLoading()
else
	vape.Init = finishLoading
	return vape
end
--]]
