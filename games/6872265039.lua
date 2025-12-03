local run = function(func) func() end
local cloneref = cloneref or function(obj) return obj end

local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local inputService = cloneref(game:GetService('UserInputService'))
local httpService = cloneref(game:GetService('HttpService'))

local lplr = playersService.LocalPlayer
local vape = shared.vape
local entitylib = vape.Libraries.entity
local sessioninfo = vape.Libraries.sessioninfo
local bedwars = {}
local role = vape.role or "guest"
local user = vape.user or "GUEST"
task.spawn(function()
	while task.wait(.1) do
		vape.role = role
		vape.user = user
	end
end)

local function notif(...)
	return vape:CreateNotification(...)
end

--[[run(function()
	local function dumpRemote(tab)
		local ind = table.find(tab, 'Client')
		return ind and tab[ind + 1] or ''
	end

	local KnitInit, Knit
	repeat
		KnitInit, Knit = pcall(function() return debug.getupvalue(require(lplr.PlayerScripts.TS.knit).setup, 9) end)
		if KnitInit then break end
		task.wait()
	until KnitInit
	if not debug.getupvalue(Knit.Start, 1) then
		repeat task.wait() until debug.getupvalue(Knit.Start, 1)
	end
	local Flamework = require(replicatedStorage['rbxts_include']['node_modules']['@flamework'].core.out).Flamework
	local Client = require(replicatedStorage.TS.remotes).default.Client

	bedwars = setmetatable({
		Client = Client,
		CrateItemMeta = debug.getupvalue(Flamework.resolveDependency('client/controllers/global/reward-crate/crate-controller@CrateController').onStart, 3),
		Store = require(lplr.PlayerScripts.TS.ui.store).ClientStore
	}, {
		__index = function(self, ind)
			rawset(self, ind, Knit.Controllers[ind])
			return rawget(self, ind)
		end
	})--]]

run(function()
			local function dumpRemote(tab)
		local ind = table.find(tab, 'Client')
		return ind and tab[ind + 1] or ''
	end
	local KnitInit, Knit
	repeat
		KnitInit, Knit = pcall(function()
			return debug.getupvalue(require(lplr.PlayerScripts.TS.knit).setup, 9)
		end)
		if KnitInit then break end
		task.wait(0.1)
	until KnitInit

	if not debug.getupvalue(Knit.Start, 1) then
		repeat task.wait(0.1) until debug.getupvalue(Knit.Start, 1)
	end

	local Flamework = require(replicatedStorage['rbxts_include']['node_modules']['@flamework'].core.out).Flamework
	local InventoryUtil = require(replicatedStorage.TS.inventory['inventory-util']).InventoryUtil
	local Client = require(replicatedStorage.TS.remotes).default.Client
	local OldGet, OldBreak = Client.Get
local function safeGetProto(func, index)
    if not func then return nil end
    local success, proto = pcall(safeGetProto, func, index)
    if success then
        return proto
    else
        warn("function:", func, "index:", index) 
        return nil
    end
end

	bedwars = setmetatable({
		AbilityController = Flamework.resolveDependency('@easy-games/game-core:client/controllers/ability/ability-controller@AbilityController'),
		AnimationType = require(replicatedStorage.TS.animation['animation-type']).AnimationType,
		AnimationUtil = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out['shared'].util['animation-util']).AnimationUtil,
		AppController = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out.client.controllers['app-controller']).AppController,
		BedBreakEffectMeta = require(replicatedStorage.TS.locker['bed-break-effect']['bed-break-effect-meta']).BedBreakEffectMeta,
		BedwarsKitMeta = require(replicatedStorage.TS.games.bedwars.kit['bedwars-kit-meta']).BedwarsKitMeta,
		ClickHold = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out.client.ui.lib.util['click-hold']).ClickHold,
		Client = Client,
		ClientConstructor = require(replicatedStorage['rbxts_include']['node_modules']['@rbxts'].net.out.client),
		MatchHistoryController = require(lplr.PlayerScripts.TS.controllers.global['match-history']['match-history-controller']),
		PlayerProfileUIController = require(lplr.PlayerScripts.TS.controllers.global['player-profile']['player-profile-ui-controller']),
		TitleTypes = require(game.ReplicatedStorage.TS.locker.title['title-type']).TitleType,
		TitleTypesMeta =  require(game.ReplicatedStorage.TS.locker.title['title-meta']).TitleMeta,
		EmoteType = require(replicatedStorage.TS.locker.emote['emote-type']).EmoteType,
		GameAnimationUtil = require(replicatedStorage.TS.animation['animation-util']).GameAnimationUtil,
		NotificationController = Flamework.resolveDependency('@easy-games/game-core:client/controllers/notification-controller@NotificationController'),
		getIcon = function(item, showinv)
			local itemmeta = bedwars.ItemMeta[item.itemType]
			return itemmeta and showinv and itemmeta.image or ''
		end,
		getInventory = function(plr)
			local suc, res = pcall(function()
				return InventoryUtil.getInventory(plr)
			end)
			return suc and res or {
				items = {},
				armor = {}
			}
		end,
		HudAliveCount = require(lplr.PlayerScripts.TS.controllers.global['top-bar'].ui.game['hud-alive-player-counts']).HudAlivePlayerCounts,
		ItemMeta = debug.getupvalue(require(replicatedStorage.TS.item['item-meta']).getItemMeta, 1),
		--KillEffectMeta = require(replicatedStorage.TS.locker['kill-effect']['kill-effect-meta']).KillEffectMeta,
		Knit = Knit,
		KnockbackUtil = require(replicatedStorage.TS.damage['knockback-util']).KnockbackUtil,
		MageKitUtil = require(replicatedStorage.TS.games.bedwars.kit.kits.mage['mage-kit-util']).MageKitUtil,
		NametagController = Knit.Controllers.NametagController,
		PartyController = Flamework.resolveDependency('@easy-games/lobby:client/controllers/party-controller@PartyController'),
		ProjectileMeta = require(replicatedStorage.TS.projectile['projectile-meta']).ProjectileMeta,
		QueryUtil = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out).GameQueryUtil,
		QueueCard = require(lplr.PlayerScripts.TS.controllers.global.queue.ui['queue-card']).QueueCard,
		QueueMeta = require(replicatedStorage.TS.game['queue-meta']).QueueMeta,
		Roact = require(replicatedStorage['rbxts_include']['node_modules']['@rbxts']['roact'].src),
		RuntimeLib = require(replicatedStorage['rbxts_include'].RuntimeLib),
		SoundList = require(replicatedStorage.TS.sound['game-sound']).GameSound,
		--SoundManager = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out).SoundManager,
		Store = require(lplr.PlayerScripts.TS.ui.store).ClientStore,
		TeamUpgradeMeta = debug.getupvalue(require(replicatedStorage.TS.games.bedwars['team-upgrade']['team-upgrade-meta']).getTeamUpgradeMetaForQueue, 6),
		UILayers = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out).UILayers,
		VisualizerUtils = require(lplr.PlayerScripts.TS.lib.visualizer['visualizer-utils']).VisualizerUtils,
		WeldTable = require(replicatedStorage.TS.util['weld-util']).WeldUtil,
		WinEffectMeta = require(replicatedStorage.TS.locker['win-effect']['win-effect-meta']).WinEffectMeta,
		ZapNetworking = require(lplr.PlayerScripts.TS.lib.network),
	}, {
		__index = function(self, ind)
			rawset(self, ind, Knit.Controllers[ind])
			return rawget(self, ind)
		end
	})

	local kills = sessioninfo:AddItem('Kills')
	local beds = sessioninfo:AddItem('Beds')
	local wins = sessioninfo:AddItem('Wins')
	local games = sessioninfo:AddItem('Games')

	vape:Clean(function()
		table.clear(bedwars)
	end)
end)

for _, v in vape.Modules do
	if v.Category == 'Combat' or v.Category == 'Minigames' then
		vape:Remove(i)
	end
end

run(function()
	local Sprint
	local old
	
	Sprint = vape.Categories.Combat:CreateModule({
		Name = 'Sprint',
		Function = function(callback)
			if callback then
				if inputService.TouchEnabled then pcall(function() lplr.PlayerGui.MobileUI['2'].Visible = false end) end
				old = bedwars.SprintController.stopSprinting
				bedwars.SprintController.stopSprinting = function(...)
					local call = old(...)
					bedwars.SprintController:startSprinting()
					return call
				end
				Sprint:Clean(entitylib.Events.LocalAdded:Connect(function() bedwars.SprintController:stopSprinting() end))
				bedwars.SprintController:stopSprinting()
			else
				if inputService.TouchEnabled then pcall(function() lplr.PlayerGui.MobileUI['2'].Visible = true end) end
				bedwars.SprintController.stopSprinting = old
				bedwars.SprintController:stopSprinting()
			end
		end,
		Tooltip = 'Sets your sprinting to true.'
	})
end)
	
run(function()
	local AutoGamble
	
	AutoGamble = vape.Categories.Minigames:CreateModule({
		Name = 'AutoGamble',
		Function = function(callback)
			if callback then
				AutoGamble:Clean(bedwars.Client:GetNamespace('RewardCrate'):Get('CrateOpened'):Connect(function(data)
					if data.openingPlayer == lplr then
						local tab = bedwars.CrateItemMeta[data.reward.itemType] or {displayName = data.reward.itemType or 'unknown'}
						notif('AutoGamble', 'Won '..tab.displayName, 5)
					end
				end))
	
				repeat
					if not bedwars.CrateAltarController.activeCrates[1] then
						for _, v in bedwars.Store:getState().Consumable.inventory do
							if v.consumable:find('crate') then
								bedwars.CrateAltarController:pickCrate(v.consumable, 1)
								task.wait(1.2)
								if bedwars.CrateAltarController.activeCrates[1] and bedwars.CrateAltarController.activeCrates[1][2] then
									bedwars.Client:GetNamespace('RewardCrate'):Get('OpenRewardCrate'):SendToServer({
										crateId = bedwars.CrateAltarController.activeCrates[1][2].attributes.crateId
									})
								end
								break
							end
						end
					end
					task.wait(1)
				until not AutoGamble.Enabled
			end
		end,
		Tooltip = 'Automatically opens lucky crates, piston inspired!'
	})
end)

run(function()	
	NM = vape.Categories.Minigames:CreateModule({
		Name = 'Nightmare Emote',
		Tooltip = 'Client-Sided nightmare emote, animation is Server-Side visuals are Client-Sided',
		Function = function(callback)
			if callback then				
				local l__TweenService__9 = game:GetService("TweenService")
				local player = game:GetService("Players").LocalPlayer
				local p6 = player.Character
				
				if not p6 then return end
				
				local v10 = game:GetService("ReplicatedStorage"):WaitForChild("Assets"):WaitForChild("Effects"):WaitForChild("NightmareEmote"):Clone();
				asset = v10
				v10.Parent = game.Workspace
				lastPosition = p6.PrimaryPart and p6.PrimaryPart.Position or Vector3.new()
				
				task.spawn(function()
					while asset ~= nil do
						local currentPosition = p6.PrimaryPart and p6.PrimaryPart.Position
						if currentPosition and (currentPosition - lastPosition).Magnitude > 0.1 then
							asset:Destroy()
							asset = nil
							NM:Toggle()
							break
						end
						lastPosition = currentPosition
						v10:SetPrimaryPartCFrame(p6.LowerTorso.CFrame + Vector3.new(0, -2, 0));
						task.wait()
					end
				end)
				
				local v11 = v10:GetDescendants();
				local function v12(p8)
					if p8:IsA("BasePart") then
						p8.CanCollide = false;
						p8.Anchored = true;
					end;
				end;
				for v13, v14 in ipairs(v11) do
					v12(v14, v13 - 1, v11);
				end;
				local l__Outer__15 = v10:FindFirstChild("Outer");
				if l__Outer__15 then
					l__TweenService__9:Create(l__Outer__15, TweenInfo.new(1.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), {
						Orientation = l__Outer__15.Orientation + Vector3.new(0, 360, 0)
					}):Play();
				end;
				local l__Middle__16 = v10:FindFirstChild("Middle");
				if l__Middle__16 then
					l__TweenService__9:Create(l__Middle__16, TweenInfo.new(12.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), {
						Orientation = l__Middle__16.Orientation + Vector3.new(0, -360, 0)
					}):Play();
				end;
                anim = Instance.new("Animation")
				anim.AnimationId = "rbxassetid://9191822700"
				anim = p6.Humanoid:LoadAnimation(anim)
				anim:Play()
			else 
                if anim then 
					anim:Stop()
					anim = nil
				end
				if asset then
					asset:Destroy() 
					asset = nil
				end
			end
		end
	})
end)


run(function()
local AG
local QueueTypes
	AG = vape.Categories.AltFarm:CreateModule({
		Name = "AccountGrinding",
		Function = function(callback)
			if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium"then
				vape:CreateNotification("Onyx", "You do not have permission to use this", 10, "alert")
				return
			end       
			if QueueTypes.Value == "duels" then 
				bedwars.QueueController:joinQueue('bedwars_duels')
			elseif QueueTypes.Value == "1v1s" then 
				bedwars.QueueController:joinQueue('winstreak_1v1')
			end
		end,
		Tooltip ='Used for getting accounts having rank enabled'
	})
    QueueTypes = AG:CreateDropdown({
        Name = "Type",
        List = {'duels', '1v1s'},
    })

end)


																																						
run(function()
    local Users = {
        KnownUsers = {
            Chase = {22808138, 4782733628, 7447190808, 3196162848},
            Orion = {547598710, 5728889572, 4652232128, 7043591647, 7209929547, 7043958628, 7418525152, 3774791573, 8606089749},
            LisNix = {162442297, 702354331, 9350301723},
            Nwr = {307212658, 5097000699, 4923561416},
            Gorilla = {514679433, 2431747703, 4531785383},
            Typhoon = {2428373515, 7659437319},
            Erin = {2465133159},
            Ghost = {7558211130, 1708400489,9554637663},
            Sponge = {376388734, 5157136850},
            Gora = {589533315, 567497793},
            Apple = {334013471, 145981200, 4721068661, 8006518573, 3547758846, 7155624750, 7468661659},
            Dom = {239431610, 2621170992},
            Kevin = {575474067, 4785639950, 8735055832},
            Vic = {839818760, 1524739259},
        },
        UnknownUsers = {
            7547477786, 7574577126, 5816563976, 240526951, 7587479685, 7876617827,
            2568824396, 7604102307, 7901878324, 5087196317, 7187604802, 7495829767,
            7718511355, 7928472983, 7922414080, 7758683476, 4079687909, 1160595313
        }
    }

    local ACMOD
    local Side
    local Specific
    local IncludeOffline
    local IncludeStudio

    ACMOD = vape.Categories.Exploits:CreateModule({
        Name = 'Anti-Cheat Mods',
        Tooltip = "Fetches all AC mod users (including unknowns)",
        Function = function()
            vape:CreateNotification('ReVape', "Currently fetching mods", 3)
            task.wait(4)

            local HttpService = httpService
            local Players = game:GetService("Players")

            local Offline, InGame, Online, Studio = 0, 0, 0, 0
            local url = "https://presence.roproxy.com/v1/presence/users"
            local data = {userIds = {}}

            if Side and Side.Value == "Known" then
                if Specific and Specific.Value == "All" then
                    for _, numbers in pairs(Users.KnownUsers) do
                        for _, num in ipairs(numbers) do
                            table.insert(data.userIds, num)
                        end
                    end
                elseif Specific and Users.KnownUsers[Specific.Value] then
                    for _, num in ipairs(Users.KnownUsers[Specific.Value]) do
                        table.insert(data.userIds, num)
                    end
                end
            elseif Side and Side.Value == "Unknown" then
                for _, num in ipairs(Users.UnknownUsers) do
                    table.insert(data.userIds, num)
                end
            end

            if #data.userIds == 0 then
                vape:CreateNotification('No Users Selected', "Pick a Side/Specific to fetch", 5, "alert")
                return
            end

            local jsonData = HttpService:JSONEncode(data)
            local response
            local success, err = pcall(function()
                response = HttpService:PostAsync(url, jsonData, Enum.HttpContentType.ApplicationJson)
            end)

            if success and response then
                local okDecode, result = pcall(function()
                    return HttpService:JSONDecode(response)
                end)

                if not okDecode or not result then
                    vape:CreateNotification('Failed!', "Failed to decode presence JSON", 15, "alert")
                    return
                end

                if result.userPresences then
                    for _, user in pairs(result.userPresences) do
                        local username = tostring(user.userId)
                        local okName, nameOrErr = pcall(function()
                            return Players:GetNameFromUserIdAsync(user.userId)
                        end)
                        if okName and nameOrErr then
                            username = nameOrErr
                        end

                        if user.userPresenceType == 0 then
                            Offline = Offline + 1
                            if IncludeOffline and IncludeOffline.Value then
                                vape:CreateNotification('Offline Mod detected!', username, 5, "alert")
                            end
                        elseif user.userPresenceType == 1 then 
                            Online = Online + 1
                            vape:CreateNotification('Online Mod detected!', username, 15, "warning")
                        elseif user.userPresenceType == 2 then 
                            InGame = InGame + 1
                            vape:CreateNotification('InGame Mod detected!', username, 15, "warning")
                        elseif user.userPresenceType == 3 then 
                            Studio = Studio + 1
                            if IncludeStudio and IncludeStudio.Value then
                                vape:CreateNotification('Studio Mod detected!', username, 5, "warning")
                            end
                        end
                    end
                end

                task.wait(5)
                if InGame >= 2 then
                    vape:CreateNotification('Multiple Mods In-Game!', "There are [" .. InGame .. "] mods in game", 45)
                elseif InGame == 0 then
                    vape:CreateNotification('No Mods In-Game!', "There are none in-game", 45)
                end

                if Online >= 2 then
                    vape:CreateNotification('Multiple Mods Online!', "There are [" .. Online .. "] mods online", 45)
                elseif Online == 0 then
                    vape:CreateNotification('No Mods Online!', "There are none online", 45)
                end
            else
                vape:CreateNotification('ReVape', "Failed to get presence data: " .. tostring(err), 15, "alert")
            end
        end
    })

    Side = ACMOD:CreateDropdown({
        Name = "Version",
        List = {'Known', 'Unknown'},
    })

    Specific = ACMOD:CreateDropdown({
        Name = "Specific",
        Tooltip = 'Fetch a specific user (mains and alts)',
        List = {'All', 'Chase', 'Orion', 'LisNix', 'Nwr', 'Gorilla', 'Typhoon', 'Vic', 'Erin', 'Ghost', 'Sponge', 'Apple', 'Dom', 'Gora', 'Kevin'},
    })

    IncludeStudio = ACMOD:CreateToggle({
        Name = "Include Studio",
        Tooltip = "Include when a mod is in studio",
        Default = false
    })

    IncludeOffline = ACMOD:CreateToggle({
        Name = "Include Offline",
        Tooltip = "Include when a mod is offline",
        Default = false
    })
end)

run(function()
    local UsersList = {
        22808138, 4782733628, 7447190808, 3196162848,
        547598710, 5728889572, 4652232128, 7043591647, 7209929547, 7043958628, 7418525152, 3774791573, 8606089749,
        162442297, 702354331, 9350301723,
        307212658, 5097000699, 4923561416,
        514679433, 2431747703, 4531785383,
        2428373515, 7659437319,
        2465133159,
        7558211130, 1708400489,
        376388734, 5157136850,
        589533315, 567497793,
        334013471, 145981200, 4721068661, 8006518573, 3547758846, 7155624750, 7468661659,
        239431610, 2621170992,
        575474067, 4785639950, 8735055832,
        839818760, 1524739259,
        7547477786, 7574577126, 5816563976, 240526951, 7587479685, 7876617827,
        2568824396, 7604102307, 7901878324, 5087196317, 7187604802, 7495829767,
        7718511355, 7928472983, 7922414080, 7758683476, 4079687909, 1160595313
    }

    local UsersSet = {}
    for _, id in ipairs(UsersList) do
        UsersSet[id] = true
    end

    local playersService = game:GetService("Players")
    local lplr = playersService.LocalPlayer
    local joined = {} 

    local StaffDetector
    local Party
    local IncludeSpecs
    local CreateLogsOfMODS

    local function notif(title, body, duration, typ)
        if vape and vape.CreateNotification then
            vape:CreateNotification(title, body, duration or 5, typ)
        else
            print(("NOTIF [%s] %s"):format(title, body))
        end
    end

    local function checkFriends(list)
        for _, v in ipairs(list) do
            local id = v
            if type(v) == "table" and v.Id then id = v.Id end
            if joined[id] then
                return joined[id]
            end
        end
        return nil
    end

local function staffFunction(plr, checktype, checktypee)
    if not vape or not vape.Loaded then
        repeat task.wait() until vape and vape.Loaded
    end
if checktype == "spectator_join" then

else
notif('StaffDetector', 'Staff Detected ('..checktype..'): '..plr.Name..' ('..plr.UserId..')', 60, checktypee)
end
    

    if whitelist and whitelist.customtags then
        whitelist.customtags[plr.Name] = {{text = 'GAME STAFF', color = Color3.new(1, 0, 0)}}
    end


    if Party and Party.Enabled then
        if checktype == "impossible_join" or checktype == "detected_mod_join" then
            if bedwars and bedwars.PartyController and bedwars.PartyController.leaveParty then
                pcall(function()
                    bedwars.PartyController:leaveParty()
                end)
            end
        end
    end

    if CreateLogsOfMODS and CreateLogsOfMODS.Enabled then
        local Format
        local date = DateTime.now():ToLocalTime():ToTable()
        local dateString = string.format("%02d/%02d/%04d %02d:%02d:%02d", 
            date.month, date.day, date.year, date.hour, date.min, date.sec
        )

        if checktype == "impossible_join" then
            Format = "[USERNAME]:"..plr.Name.."|"..
                     "[USERID]:"..plr.UserId.."|"..
                     "[DATE]:"..dateString.."|"..
                     "[TYPE]:[IMPOSSIBLE JOIN]\n"

        elseif checktype == "detected_mod_join" then
            Format = "[USERNAME]:"..plr.Name.."|"..
                     "[USERID]:"..plr.UserId.."|"..
                     "[DATE]:"..dateString.."|"..
                     "[TYPE]:[KNOWN MOD JOIN]\n"

        elseif checktype == "spectator_join" then
            Format = "[USERNAME]:"..plr.Name.."|"..
                     "[USERID]:"..plr.UserId.."|"..
                     "[DATE]:"..dateString.."|"..
                     "[TYPE]:[SPECTATOR JOIN]\n"
        end
if Format then
    local path = "ReVape/profiles/logs.txt"

    if not isfolder("ReVape/profiles") then
        makefolder("ReVape/profiles")
    end

    if not isfile(path) then
        writefile(path, Format)
    else
        local prev = readfile(path)
        writefile(path, prev .. Format)
    end
end
     end
end
    local function checkJoin(plr, connection)
        if not plr or not plr.UserId then return false end

        local spectatorAttr = plr:GetAttribute('Spectator')
        local teamAttr = plr:GetAttribute('Team')
        local isCustomMatch = false
        if bedwars and bedwars.Store and bedwars.Store.getState then
            local ok, state = pcall(bedwars.Store.getState, bedwars.Store)
            if ok and state and state.Game and state.Game.customMatch then
                isCustomMatch = true
            end
        end

        if (not teamAttr) and spectatorAttr and not isCustomMatch then
            if connection then connection:Disconnect() end

            local tab = {}
            local success, pages = pcall(function()
                return playersService:GetFriendsAsync(plr.UserId)
            end)

            if not success or not pages then
                staffFunction(plr, 'impossible_join','warning')
                return true
            end

            for _ = 1, 4 do
                local currentPage = pages:GetCurrentPage()
                for _, v in ipairs(currentPage) do
                    table.insert(tab, v.Id or v.id or v.Id)
                end
                if pages.IsFinished then break end
                pages:AdvanceToNextPageAsync()
            end

            local friend = checkFriends(tab)
            if not friend then
                staffFunction(plr, 'impossible_join','warning')
                return true
            elseif UsersSet[plr.UserId] then
                staffFunction(plr, 'detected_mod_join','alert')
                return true
            else
                if IncludeSpecs and IncludeSpecs.Enabled then
                    notif('StaffDetector', string.format('Spectator %s joined from %s', plr.Name, tostring(friend)), 20, 'warning')
                    if CreateLogsOfMODS and CreateLogsOfMODS.Enabled then
                        staffFunction(plr, "spectator_join", 'info')
                    end
                end
            end
        end

        return false
    end

    local function playerAdded(plr)
        if not plr then return end
        joined[plr.UserId] = plr.Name
        if plr == lplr then return end

        local connection
        connection = plr:GetAttributeChangedSignal('Spectator'):Connect(function()
            checkJoin(plr, connection)
        end)
        if StaffDetector and StaffDetector.Clean then
            StaffDetector:Clean(connection)
        end

        if checkJoin(plr, connection) then
            return
        end
    end

    StaffDetector = vape.Categories.Utility:CreateModule({
        Name = 'StaffDetectorV2',
        Function = function(callback)
            if callback then
                if playersService and playersService.PlayerAdded then
                    StaffDetector:Clean(playersService.PlayerAdded:Connect(playerAdded))
                end
                for _, v in ipairs(playersService:GetPlayers()) do
                    task.spawn(playerAdded, v)
                end
            else
                table.clear(joined)
            end
        end,
        Tooltip = 'A Newer verison of Staff-Detector'
    })

    Party = StaffDetector:CreateToggle({
        Name = 'Leave party',
        Default = true,
    })
    IncludeSpecs = StaffDetector:CreateToggle({
        Name = 'Include Spectators',
        Tooltip = 'NOTE: Anti-Cheat mods could create new alts, ill say to keep this on to get the new username. BUT THIS CAN DO FALSE DETECTIONS!!',
        Default = true,
    })
    CreateLogsOfMODS = StaffDetector:CreateToggle({
        Name = 'Logs',
        Default = false,
        Tooltip = 'all this does is keep track of every mod/spectators has joined you with a date'
    })
end)


--[[run(function()
  local Players = game:GetService("Players")
local player = Players.LocalPlayer
    local PlayerLevel
	local level 
  local old

PlayerLevel = vape.Categories.Exploits:CreateModule({
        Name = 'SetPlayerLevel',
	Tooltip = "Sets your player level to 100 (client sided)",
        Function = function(callback)
if callback then
				notif("SetPlayerLevel", "This is client sided (only u will see the new level)", 3,"warning")
	old = game.Players.LocalPlayer:GettAttribute("PlayerLevel")				
game.Players.LocalPlayer:SetAttribute("PlayerLevel", level.Value)
else
	game.Players.LocalPlayer:SetAttribute("PlayerLevel", old)
	old = nil
end
	end
})

level = PlayerLevel:CreateSlider({
        Name = 'Player Level',
        Min = 1,
        Max = 1000,
        Default = 100,
	Function = function(val)
	    player:SetAttribute("PlayerLevel", val)
	end
    })
end)--]]
run(function()
    local QueueDisplayConfig = {
        ActiveState = false,
        GradientControl = {Enabled = true},
        ColorSettings = {
            Gradient1 = {Hue = 0, Saturation = 0, Brightness = 1},
            Gradient2 = {Hue = 0, Saturation = 0, Brightness = 0.8}
        },
        Animation = {Speed = 0.5, Progress = 0}
    }

    local DisplayUtils = {
        createGradient = function(parent)
            local gradient = parent:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
            gradient.Parent = parent
            return gradient
        end,
        updateColor = function(gradient, config)
            local time = tick() * config.Animation.Speed
            local interp = (math.sin(time) + 1) / 2
            local h = config.ColorSettings.Gradient1.Hue + (config.ColorSettings.Gradient2.Hue - config.ColorSettings.Gradient1.Hue) * interp
            local s = config.ColorSettings.Gradient1.Saturation + (config.ColorSettings.Gradient2.Saturation - config.ColorSettings.Gradient1.Saturation) * interp
            local b = config.ColorSettings.Gradient1.Brightness + (config.ColorSettings.Gradient2.Brightness - config.ColorSettings.Gradient1.Brightness) * interp
            gradient.Color = ColorSequence.new(Color3.fromHSV(h, s, b))
        end
    }

	local CoreConnection

    local function enhanceQueueDisplay()
		pcall(function() 
			CoreConnection:Disconnect()
		end)
        local success, err = pcall(function()
            if not lplr.PlayerGui:FindFirstChild('QueueApp') then return end
            
            for attempt = 1, 3 do
                if QueueDisplayConfig.GradientControl.Enabled then
                    local queueFrame = lplr.PlayerGui.QueueApp['1']
                    queueFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    
                    local gradient = DisplayUtils.createGradient(queueFrame)
                    gradient.Rotation = 180
                    
                    local displayInterface = {
                        module = vape.watermark,
                        gradient = gradient,
                        GetEnabled = function()
                            return QueueDisplayConfig.ActiveState
                        end,
                        SetGradientEnabled = function(state)
                            QueueDisplayConfig.GradientControl.Enabled = state
                            gradient.Enabled = state
                        end
                    }
                    CoreConnection = game:GetService("RunService").RenderStepped:Connect(function()
                        if QueueDisplayConfig.ActiveState and QueueDisplayConfig.GradientControl.Enabled then
                            DisplayUtils.updateColor(gradient, QueueDisplayConfig)
                        end
                    end)
                end
                task.wait(0.1)
            end
        end)
        
        if not success then
            warn("Queue display enhancement failed: " .. tostring(err))
        end
    end

    local QueueDisplayEnhancer
    QueueDisplayEnhancer = vape.Categories.Utility:CreateModule({
        Name = 'QueueCardMods',
        Tooltip = 'Enhances the Queues display with dynamic gradients!!',
        Function = function(enabled)
            QueueDisplayConfig.ActiveState = enabled
            if enabled then
                enhanceQueueDisplay()
                QueueDisplayEnhancer:Clean(lplr.PlayerGui.ChildAdded:Connect(enhanceQueueDisplay))
			else
				pcall(function() 
					CoreConnection:Disconnect()
				end)
			end
        end
    })

   	QueueDisplayEnhancer:CreateSlider({
        Name = "Animation Speed",
        Function = function(speed)
            QueueDisplayConfig.Animation.Speed = math.clamp(speed, 0.1, 5)
        end,
        Min = 1,
        Max = 6,
        Default = 5
    })

    QueueDisplayEnhancer:CreateColorSlider({
        Name = "Color 1",
        Function = function(h, s, v)
            QueueDisplayConfig.ColorSettings.Gradient1 = {Hue = h, Saturation = s, Brightness = v}
        end
    })

    QueueDisplayEnhancer:CreateColorSlider({
        Name = "Color 2",
        Function = function(h, s, v)
            QueueDisplayConfig.ColorSettings.Gradient2 = {Hue = h, Saturation = s, Brightness = v}
        end
    })
end)
run(function()
	local TAG
	local CustomTAG
	local R, G, B
	local Org = ""
	local OrgText = ""
	local player = game:GetService('Players').LocalPlayer

	if not player:FindFirstChild("Tags") then
		notif("Onyx", "Couldn't find the folder 'Tags' to change your tag", 20, "alert")
		return
	end

	local tagObj = player.Tags:FindFirstChild("0")
	if not tagObj then
		notif("Onyx", "Couldn't find any tag inside 'Tags'", 20, "alert")
		return 	end

	local function Color3ToHex(r, g, b)
		return string.lower(string.format("#%02X%02X%02X", r, g, b))
	end

	Org = tagObj.Value
	OrgText = tagObj:GetAttribute("Text")

	CustomTAG = vape.Categories.Troll:CreateModule({
		Name = "CustomTag",
		Function = function(callback)
			if callback then
				tagObj.Value = string.format(
					"<font color='rgb(%s,%s,%s)'>[%s]</font>",
					R.Value, G.Value, B.Value, TAG.Value
				)
				tagObj:SetAttribute("Text", TAG.Value)
				player:SetAttribute("ClanTag", TAG.Value)

				local player = game.Players.LocalPlayer

				local function Color3ToHex(color)
					return string.format("#%02X%02X%02X", color.R * 255, color.G * 255, color.B * 255)
				end

				player.PlayerGui.ChildAdded:Connect(function(child)
					if child.Name == "TabListScreenGui" and child:IsA("ScreenGui") then
						task.spawn(function()
							while CustomTAG.Enabled do
								for _, v in ipairs(child:GetDescendants()) do
									if v:IsA("TextLabel") then
										local nameToFind = (player.DisplayName == "" or player.DisplayName == player.Name)
											and player.Name
											or player.DisplayName

										if string.find(string.lower(v.Text), string.lower(nameToFind)) then
											v.Text = string.format(
												'<font transparency="0.3" color="%s">[%s]</font> %s',
												Color3ToHex(Color3.fromRGB(R.Value, G.Value, B.Value)),
												TAG.Value,
												nameToFind
											)
										end
									end
								end
								task.wait()
							end

							for _, v in ipairs(child:GetDescendants()) do
								if v:IsA("TextLabel") then
									local nameToFind = (player.DisplayName == "" or player.DisplayName == player.Name)
										and player.Name
										or player.DisplayName

									if string.find(string.lower(v.Text), string.lower(nameToFind)) then
										v.Text = string.format(
											'<font transparency="0.3" color="%s">[%s]</font> %s',
											Color3ToHex(Color3.fromRGB(255, 255, 255)),
											tagObj:GetAttribute("Text"),
											nameToFind
										)
									end
								end
							end
						end)
					end
				end)
			else
				tagObj.Value = Org
				tagObj:SetAttribute("Text", OrgText)
				player:SetAttribute("ClanTag", OrgText)
			end
		end,
		Tooltip = "Client-Sided visual custom clan tag on-chat",
	})

	TAG = CustomTAG:CreateTextBox({
		Name = "Tag Text",
		Placeholder = "",
		Function = function()
			CustomTAG:Toggle()
			task.wait()
			CustomTAG:Toggle()
		end,
	})

	R = CustomTAG:CreateSlider({
		Name = "R",
		Min = 0,
		Max = 255,
		Default = 255,
		Function = function()
			CustomTAG:Toggle()
			task.wait()
			CustomTAG:Toggle()
		end,
	})

	G = CustomTAG:CreateSlider({
		Name = "G",
		Min = 0,
		Max = 255,
		Default = 255,
		Function = function()
			CustomTAG:Toggle()
			task.wait()
			CustomTAG:Toggle()
		end,
	})

	B = CustomTAG:CreateSlider({
		Name = "B",
		Min = 0,
		Max = 255,
		Default = 255,
		Function = function()
			CustomTAG:Toggle()
			task.wait()
			CustomTAG:Toggle()
		end,
	})
end)
run(function()
	local ViewProfiles
	local lplr = game.Players.LocalPlayer
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local function create(name, props)
		local obj = Instance.new(name)
		for k, v in pairs(props) do
			if type(k) == "number" then
				v.Parent = obj
			else
				obj[k] = v
			end
		end
		return obj
	end

	local function CreateProfile()
		local Profile = create("ScreenGui", {
			Name = "Profile",
			DisplayOrder = 30,
			ResetOnSpawn = false,
			Parent = lplr:WaitForChild("PlayerGui"),
			IgnoreGuiInset = true
		})

		local BackgroundProfileUI = create("ImageButton", {
			Name = "Background",
			AutoButtonColor = false,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 0.6,
			BackgroundColor3 = Color3.new(0, 0, 0),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(2, 2),
			Parent = Profile
		})

		local MainProfileFrame = create("Frame", {
			Name = "Main",
			Parent = Profile,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1)
		})

		local MainMainBG = create("ImageButton", {
			Name = "MainBG",
			AutoButtonColor = false,
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.05),
			Size = UDim2.fromOffset(800, 700),
			Parent = MainProfileFrame
		})

		create("UIAspectRatioConstraint", { Parent = MainMainBG, AspectRatio = 1.143 })
		create("UIScale", { Parent = MainMainBG, Scale = 1.297 })

		local IconButtonWrapper = create("ImageButton", {
			Name = "IconButtonWrapper",
			Parent = MainMainBG,
			AnchorPoint = Vector2.new(1, 0),
			BackgroundTransparency = 1,
			Position = UDim2.new(1, -4, 0, 4),
			Size = UDim2.fromOffset(40, 40)
		})
		create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = IconButtonWrapper })
		create("UIPadding", {
			PaddingBottom = UDim.new(0.1, 0),
			PaddingLeft = UDim.new(0.1, 0),
			PaddingRight = UDim.new(0.1, 0),
			PaddingTop = UDim.new(0.1, 0),
			Parent = IconButtonWrapper
		})
		create("ImageLabel", {
			Name = "Icon",
			Parent = IconButtonWrapper,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			ZIndex = 100,
			Image = "rbxassetid://6693945013",
			ImageTransparency = 0.2
		})

		local FrameMainBG = create("Frame", {
			Parent = MainMainBG,
			BackgroundColor3 = Color3.fromRGB(100, 103, 167),
			Size = UDim2.fromScale(1, 1)
		})
		create("UICorner", { CornerRadius = UDim.new(0.05, 0), Parent = FrameMainBG })
		create("UIListLayout", {
			Parent = FrameMainBG,
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder
		})

		local UserFrame = create("Frame", {
			Name = "UserFrame",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromRGB(78, 80, 130),
			Parent = FrameMainBG
		})
		create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = UserFrame })

		local BGImage = create("ImageLabel", {
			Name = "BGImage",
			Parent = UserFrame,
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.05, 0.05),
			Size = UDim2.new(0.9, 0, 0.9, 0),
			Image = "rbxassetid://71356717298935",
			ScaleType = Enum.ScaleType.Crop,
			ImageTransparency = 0.38
		})
		create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = BGImage })

		create("TextLabel", {
			Name = "Title",
			Parent = UserFrame,
			BackgroundTransparency = 1,
			Position = UDim2.new(0.043, 0, 0, 0),
			Size = UDim2.new(0, 703, 0, 46),
			Text = "⚠️⚠️ PLEASE NOTE: USER MUST BE INGAME ⚠️⚠️",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			FontFace = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.SemiBold),
			TextScaled = true
		})

		local err = create("TextLabel", {
			Name = "Error",
			Parent = UserFrame,
			Visible = false,
			BackgroundTransparency = 1,
			Position = UDim2.new(0.066, 0, 0.3, 0),
			Size = UDim2.new(0, 703, 0, 46),
			TextColor3 = Color3.fromRGB(213, 48, 48),
			Text = "[ERROR]:",
			FontFace = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.SemiBold),
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Left
		})

		local RequestHistory = create("TextButton", {
			Name = "RequestHistory",
			Parent = UserFrame,
			BackgroundTransparency = 0.15,
			BackgroundColor3 = Color3.fromRGB(85, 170, 127),
			Position = UDim2.new(0.066, 0, 0.176, 0),
			Size = UDim2.new(0, 683, 0, 62),
			Text = "Request history",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			FontFace = Font.new("rbxasset://fonts/families/TitilliumWeb.json", Enum.FontWeight.Regular, Enum.FontStyle.Italic),
			TextSize = 24
		})
		create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = RequestHistory })

		local textbox = create("TextBox", {
			Name = "UserTextbox",
			Parent = UserFrame,
			BackgroundColor3 = Color3.fromRGB(95, 99, 159),
			Position = UDim2.new(0.066, 0, 0.066, 0),
			ShowNativeInput = false,
			Size = UDim2.new(0, 685, 0, 54),
			Text = "",
			PlaceholderText = "@Roblox",
			TextColor3 = Color3.fromRGB(155, 155, 155),
			TextSize = 32,
			TextXAlignment = Enum.TextXAlignment.Left,
			FontFace = Font.new("rbxasset://fonts/families/RobotoMono.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Italic)
		})


		local function HandleRequest()
			local plrrr = Players:FindFirstChild(textbox.Text)
			if not plrrr then
				notif('Onyx', "Player does not exist ingame", 10, "alert")
				return
			end

			local userid = plrrr.UserId
			local NTDR = ReplicatedStorage.rbxts_include.node_modules:FindFirstChild("@rbxts").net.out._NetManaged.NametagDataRequest
			local RPD = ReplicatedStorage.rbxts_include.node_modules:FindFirstChild("@rbxts").net.out._NetManaged.RequestProfileData
if gengenv().TestMode then
																				bedwars.MatchHistoryController.requestMatchHistory(plrrr)
																			else
																				
																			bedwars.PlayerProfileUIController:openPlayerProfile(plrrr)
																			end
			ViewProfiles:Toggle(false)
		end
																				
		ViewProfiles:Clean(textbox.FocusLost:Connect(function(enterPressed)
			if enterPressed then
				HandleRequest()
			end
		end))

		ViewProfiles:Clean(RequestHistory.MouseButton1Click:Connect(HandleRequest))

		ViewProfiles:Clean(IconButtonWrapper.MouseButton1Click:Connect(function()
			ViewProfiles:Toggle()
		end))
	end

	local function DestroyProfile()
		local p = lplr.PlayerGui:FindFirstChild("Profile")
		if p then p:Destroy() end
	end

	ViewProfiles = vape.Categories.Exploits:CreateModule({
		Name = "ViewProfile",
		Function = function(callback)
			   			if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium"then
				vape:CreateNotification("Onyx", "You do not have permission to use this", 10, "alert")
				return
			end  
			if callback then
				CreateProfile()
			else
				DestroyProfile()
			end
		end,
		Tooltip = "Allows you to see other players' profiles"
	})
end)

run(function()
	local SetFPS
	local FPS
	
	SetFPS = vape.Categories.Utility:CreateModule({
		Name = "SetFPS",
		Function = function(callback)
			

			if callback then
				setfpscap(FPS.Value)
			else
				setfpscap(240)
			end
		end,
		Tooltip = "Removes or customizes the Frame-Per-Second limit",
	})
	
	FPS = SetFPS:CreateSlider({
		Name = "Frames Per Second",
		Min = 0,
		Max = 420,
		Default = 240,
		Function = function(value)
			setfpscap(value)
		end
	})
end)

run(function()
    local TypeData
    local PlayerData
    local includeEmptyMatches
	local Clean
    PlayerData = vape.Categories.Minigames:CreateModule({
        Name = "PlayerData",
        Function = function(callback)
			if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium"then
				vape:CreateNotification("Onyx", "You do not have permission to use this", 10, "alert")
				return
			end  
	    	if not callback then return end

            local http = httpService
            local store = bedwars.Store:getState()

            if TypeData.Value == "important" then
                local stats = {}
                local totals = {
                    TotalWins = 0,
                    TotalLosses = 0,
                    TotalMatches = 0,
                    TotalBedBreaks = 0,
                    TotalFinalKills = 0
                }

                local leaderboard = store and store.Leaderboard and store.Leaderboard.queues

                if leaderboard then
                    for mode, data in pairs(leaderboard) do
                        local wins = data.wins or 0																
                        local losses = data.losses or 0
						local ties = data.ties or 0
                        local matches = data.matches or (wins + losses)
                        local winrate = (wins + losses > 0) and ((wins / (wins + losses)) * 100) or 0
						local earlyleaves = data.earlyLeaves or 0
                        local bedBreaks = data.bedBreaks or 0
                        local finalKills = data.finalKills or 0

                        totals.TotalWins += wins
                        totals.TotalLosses += losses
                        totals.TotalMatches += matches
                        totals.TotalBedBreaks += bedBreaks
                        totals.TotalFinalKills += finalKills

                        if includeEmptyMatches.Value or (wins > 0 or losses > 0 or matches > 0) then
                            stats[mode] = {
                                Winrate = string.format("%.2f%%", winrate),
                                Wins = wins,
                                Losses = losses,
								Ties = ties,
                                Matches = matches,
								EarlyLeaves = earlyleaves,
                                BedBreaks = bedBreaks,
                                FinalKills = finalKills
                            }
                        end
                    end
                end

                local achievements = {}
                if store and store.Bedwars and store.Bedwars.achievements then
                    for _, ach in pairs(store.Bedwars.achievements) do
                        table.insert(achievements, ach)
                    end
                elseif leaderboard and leaderboard.bedwars_duels and leaderboard.bedwars_duels.obtainedAchievements then
                    achievements = leaderboard.bedwars_duels.obtainedAchievements
                end

                local dataOut = {
					GameModes = stats,
                    Totals = totals,
                    Achievements = achievements
                }
				if Clean then
					local json = http:JSONEncode(dataOut)
	                json = json:gsub(',"', ',\n    "')
	                json = json:gsub('{', '{\n    ')
	                json = json:gsub('}', '\n}')
	
	                writefile("ReVape/profiles/PlayerData.txt", json)
	                vape:CreateNotification("PlayerData", "Created PlayerData.txt file at profiles", 10)
					else
						local json = dataOut
						
                		writefile("ReVape/profiles/PlayerData.txt", json)
                		vape:CreateNotification("PlayerData", "Created PlayerData.txt file at profiles", 10)
					end
            elseif TypeData.Value == "full" then

				if Clean then
					local json = http:JSONEncode(bedwars.Store:getState())
	                json = json:gsub(',"', ',\n    "')
	                json = json:gsub('{', '{\n    ')
	                json = json:gsub('}', '\n}')
	
	                writefile("ReVape/profiles/PlayerDataJSON.txt", json)
	                vape:CreateNotification("PlayerData", "Created PlayerData.json file at profiles", 10)
					else
						local json = http:JSONEncode(bedwars.Store:getState())
						
                		writefile("ReVape/profiles/PlayerDataJSON.txt", json)
                		vape:CreateNotification("PlayerData", "Created PlayerData.json file at profiles", 10)
					end
            end
		PlayerData:Toggle()
        end,
        Tooltip = "Creates a file that has your data"
    })

    TypeData = PlayerData:CreateDropdown({
        Name = "Type",
        List = {"important", "full"}
    })

    includeEmptyMatches = PlayerData:CreateToggle({
        Name = "EmptyMatches",
        Default = false,
        Tooltip = "ONLY FOR IMPORTANT TYPE (adds 0-stats matches to your file)"
    })
	Clean = PlayerData:CreateToggle({
        Name = "Clean",
        Default = true,
        Tooltip = "Cleans up the JSON file"
    })
end)

run(function()
	local TC
	local list
	local TABLE = {}
	local old
	TC = vape.Categories.Render:CreateModule({
	Name = "TitleChanger",
	Function = function(callback)
		if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium" then
			vape:CreateNotification("Onyx", "You do not have permission to use this", 10, "alert")
			return
		end
		if callback then
			if old then else old = lplr:GetAttribute("TitleType") end
				lplr:SetAttribute("TitleType",list.Value)
			else
				lplr:SetAttribute("TitleType",old)
				old = nil
			end
		end,
		Tooltip ='This is only client sided, fakes ur title'
	})
	for _, v in pairs(bedwars.TitleTypes) do
		TABLE[#TABLE+1] = v
	end
	list = TC:CreateDropdown({
		Name = "Titles",
		List = TABLE,
		Function = function()
			if old then else old = lplr:GetAttribute("TitleType") end
				lplr:SetAttribute("TitleType",list.Value)
			end,
		})
end)

run(function()
	local CK
	local kit
	
	local KitsTable = {
		['no kit'] = 'none',
	    ['none'] = 'none',
	    ['nokit'] = 'none',
		['uma'] = 'spirit_summoner',
		['zeno'] = 'wizard',
	    ['wizard'] = 'wizard',
		['bounty hunter'] = 'bounty_hunter',
	    ['bounty'] = 'bounty_hunter',
	    ['hunter'] = 'bounty_hunter',
	    ['shielder'] = 'shielder',
	    ['infernal'] = 'shielder',
	    ['inferno'] = 'shielder',
	    ['infernal shielder'] = 'shielder',
		['inferno shielder'] = 'shielder',
		['merchant'] = 'merchant',
	    ['marco'] = 'merchant',
	    ['merchant marco'] = 'merchant',
		['miner'] = 'miner',
	    ['isabel'] = 'sword_shield',
	    ['defender'] = 'defender',
		['marcel'] = 'defender',
	    ['skeleton'] = 'skeleton',
	    ['marrow'] = 'skeleton',
	    ['berserker'] = 'berserker',
	    ['ragnar'] = 'berserker',
	    ['rangar'] = 'berserker',
	    ['scarab'] = 'scarab',
	    ['abaddon'] = 'scarab',
	    ['ade'] = 'frost_hammer_kit',
	    ['adetunde'] = 'frost_hammer_kit',
	    ['arachne'] = 'spider_queen',
	    ['spider'] = 'spider_queen',
	    ['archer'] = 'archer',
	    ['axolotl'] = 'axolotl',
	    ['amy'] = 'axolotl',
 	   	['axolotl amy'] = 'axolotl',
	    ['axo'] = 'axolotl',
	    ['baker'] = 'baker',
	    ['barbarian'] = 'barbarian',
	    ['barb'] = 'barbarian',
	    ['builder'] = 'builder',
	    ['crypt'] = 'necromancer',
	    ['cyber'] = 'cyber',
	    ['bigman'] = 'bigman',
		['death adder'] = 'sorcerer',
		['adder'] = 'sorcerer',
		['elder'] = 'bigman',
	    ['eldertree'] = 'bigman',
	    ['eldric'] = 'warlock',
	    ['ember'] = 'ember',
	    ['evelynn'] = 'spirit_assassin',
	    ['eve'] = 'spirit_assassin',
	    ['farmer'] = 'farmer_cletus',
	    ['cletus'] = 'farmer_cletus',
	    ['farmer cletus'] = 'farmer_cletus',
	    ['freiya'] = 'ice_queen',
	    ['reaper'] = 'grim_reaper',
	    ['grim'] = 'grim_reaper',
	    ['grim reaper'] = 'grim_reaper',
	    ['grove'] = 'spirit_gardener',
	    ['hannah'] = 'hannah',
	    ['kaida'] = 'summoner',
	    ['krystal'] = 'glacial_skater',	
		['crystal'] = 'glacial_skater',
	    ['lassy'] = 'cowgirl',
		['lian'] = 'dragon_sword',
	    ['lumen'] = 'lumen',
	    ['lyla'] = 'flower_bee',
		['marina'] = 'jellyfish',
		['martin'] = 'cactus',
		['melody'] = 'melody',
		['milo'] = 'mimic',
	    ['nahla'] = 'oasis',
	    ['nazar'] = 'nazar',
		['davey'] = 'davey',
		['best kit'] = 'davey',
		['ramil'] = 'airbender',
		['sheila'] = 'seahorse',
	    ['elk'] = 'elk_master',
	    ['sigrid'] = 'elk_master',
		['silas'] = 'rebellion_leader',
		['skoll'] = 'void_hunter',
	    ['taliyah'] = 'taliyah',
	    ['chicken'] = 'taliyah',
		['kfc'] = 'taliyah',
		['trinity'] = 'angel',
	    ['angel'] = 'angel',
	    ['triton'] = 'harpoon',
		['trixie'] = 'void_walker',
	    ['vanessa'] = 'triple_shot',
	    ['void knight'] = 'void_knight',
		['regent'] = 'regent',
		['knight'] = 'void_knight',
	    ['void'] = 'regent',
	    ['vr'] = 'regent',
		['vk'] = 'void_knight',
	    ['vulcan'] = 'vulcan',
	    ['owl'] = 'owl',
		['bird'] = 'owl',
	    ['whisper'] = 'owl',
	    ['wren'] = 'black_market_trader',
		['yuzi'] = 'dasher',
	    ['dasher'] = 'dasher',
	    ['zarrah'] = 'gun_blade',
		['zenith'] = 'disruptor',
	    ['aery'] = 'aery',
	    ['agni'] = 'agni',
	    ['alchemist'] = 'alchemist',
	    ['alc'] = 'alchemist',
	    ['ares'] = 'spearman',
	    ['beekeeper'] = 'beekeeper',
	    ['beatrix'] = 'beekeeper',
	    ['beekeeper beatrix'] = 'beekeeper',
	    ['bee'] = 'beekeeper',
	    ['falconer'] = 'falconer',
	    ['bekzat'] = 'falconer',
	    ['assassin'] = 'blood_assassin',
	    ['cait'] = 'blood_assassin',
	    ['caitlyn'] = 'blood_assassin',
	    ['robot'] = 'battery',
	    ['cobalt'] = 'battery',
	    ['cogsworth'] = 'steam_engineer',
	    ['vesta'] = 'vesta',
	    ['conqueror'] = 'vesta',
	    ['conq'] = 'vesta',
	    ['croc'] = 'beast',
	    ['croco'] = 'beast',
	    ['crocowolf'] = 'beast',
	    ['wolf'] = 'beast',
	    ['beast'] = 'beast',
	    ['dino'] = 'dino_tamer',
	    ['dom'] = 'dino_tamer',
	    ['dino tamer dom'] = 'dino_tamer',
	    ['drill'] = 'drill',
	    ['elektra'] = 'elektra',
	    ['fisherman'] = 'fisherman',
	    ['fisher'] = 'fisherman',
	    ['flora'] = 'queen_bee',
	    ['fortuna'] = 'card',
	    ['frosty'] = 'frosty',
	    ['snowman'] = 'frosty',
	    ['ginger'] = 'gingerbread_man',
	    ['gingerbread'] = 'gingerbread_man',
	    ['gingerbread man'] = 'gingerbread_man',
	    ['ghost catcher'] = 'ghost_catcher',
	    ['ghost'] = 'ghost_catcher',
	    ['gompy'] = 'ghost_catcher',
	    ['hephaestus'] = 'tinker',
	    ['tinker'] = 'tinker',
	    ['ignis'] = 'ignis',
	    ['ghost walker'] = 'ignis',
	    ['oil man'] = 'oil_man',
	    ['oil'] = 'oil_man',
	    ['jack'] = 'oil_man',
	    ['jade'] = 'jade',
	    ['fire dragon'] = 'dragon_slayer',
	    ['kaliyah'] = 'dragon_slayer',
	    ['lani'] = 'paladin',
	    ['lucia'] = 'pinata',
		['pinata'] = 'pinata',
	    ['metal'] = 'metal_detector',
	    ['detector'] = 'metal_detector',
	    ['metal detector'] = 'metal_detector',
	    ['noelle'] = 'slime_tamer',
	    ['slime tamer'] = 'slime_tamer',
	    ['nyoka'] = 'nyoka',
	    ['midnight'] = 'midnight',
		['nyx'] = 'midnight',
	    ['pyro'] = 'pyro',
	    ['flamethrower'] = 'pyro',
	    ['raven'] = 'raven',
	    ['santa'] = 'santa',
	    ['ohsxnta'] = 'santa',
	    ['sheep'] = 'sheep_herder',
	    ['sheep herder'] = 'sheep_herder',
	    ['smoke'] = 'smoke',
		['spirit catcher'] = 'spirit_catcher',
	    ['sc'] = 'spirit_catcher',
	    ['spirit'] = 'spirit_catcher',
		['star'] = 'star_collector',
		['star collector'] = 'star_collector',
		['stella'] = 'star_collector',
		['styx'] = 'styx',
		['terra'] = 'block_kicker',
		['trapper'] = 'trapper',
		['umbra'] = 'hatter',
		['ninja'] = 'ninja',
		['umeko'] = 'ninja',
		['jailor'] = 'jailor',
		['warden'] = 'jailor',
		['warrior'] = 'warrior',
		['whim'] = 'mage',
		['mage'] = 'mage',
		['void dragon'] = 'void_dragon',
		['dragon'] = 'void_dragon',
		['xurot'] = 'axolotl',
		["xu'rot"] = 'void_dragon',
		['cat'] = 'cat',
		['yamini'] = 'cat',
		['yeti'] = 'yeti',
		['ice demon'] = 'yeti',
		['wind walker'] = 'wind_walker',
		['zephyr'] = 'wind_walker',
		[''] = 'none',
	}
	
	CK = vape.Categories.Exploits:CreateModule({
	    Name = "Switch Kits",
	    Function = function(callback)
			if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium"then
				vape:CreateNotification("Onyx", "You do not have permission to use this", 10, "alert")
				return
			end  																	
			if not callback then return end
			local name = string.lower(kit.Value)
			local NewKit = KitsTable[name] or "none"
					
	        if callback then
	            local args = {
					[1] = {
					    ["kit"] = NewKit
					}
				}
					
				game:GetService("ReplicatedStorage").rbxts_include.node_modules:FindFirstChild("@rbxts").net.out._NetManaged.BedwarsActivateKit:InvokeServer(unpack(args))
				kit.Placeholder = NewKit
	        end
	    end,
	    Tooltip = "This is for reconnecting, you can switch ur kit with this",
	})
	
	kit = CK:CreateTextBox({
		Name = "Kit",
		Tooltip = "Changes kit for reconnecting to a new match",
		Placeholder = lplr:GetAttribute("PlayingAsKits"),
	})
end)

if getgenv().TestMode then	
	run(function()
		local ResetHistory
		ResetHistory = vape.Categories.AltFarm:CreateModule({
			Name = "ResetHistory",
			Function = function(callback)
				if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium" then
					vape:CreateNotification("Onyx", "You do not have permission to use this", 10, "alert")
					return
				end      
				vape:CreateNotification("ResetHistory", "Module is not finished yet soon", 6, "warning")
			end,
			Tooltip ='This resets ur whole history'
		})

	end)
	warn("loaded test mode!")
else
end