local run = function(func)
	func()
end
local cloneref = cloneref or function(obj)
	return obj
end

local vapeEvents = setmetatable({}, {
	__index = function(self, index)
		self[index] = Instance.new('BindableEvent')
		return self[index]
	end
})

local playersService = cloneref(game:GetService('Players'))
local replicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
local runService = cloneref(game:GetService('RunService'))
local inputService = cloneref(game:GetService('UserInputService'))
local tweenService = cloneref(game:GetService('TweenService'))
local httpService = cloneref(game:GetService('HttpService'))
local textChatService = cloneref(game:GetService('TextChatService'))
local collectionService = cloneref(game:GetService('CollectionService'))
local contextActionService = cloneref(game:GetService('ContextActionService'))
local guiService = cloneref(game:GetService('GuiService'))
local coreGui = cloneref(game:GetService('CoreGui'))
local starterGui = cloneref(game:GetService('StarterGui'))
local isnetworkowner = identifyexecutor and table.find({'Nihon'}, ({identifyexecutor()})[1]) and isnetworkowner or function()
	return true
end


local gameCamera = workspace.CurrentCamera
local lplr = playersService.LocalPlayer
local assetfunction = getcustomasset

local vape = shared.vape
local entitylib = vape.Libraries.entity
local targetinfo = vape.Libraries.targetinfo
local sessioninfo = vape.Libraries.sessioninfo
local uipallet = vape.Libraries.uipallet
local tween = vape.Libraries.tween
local color = vape.Libraries.color
local whitelist = vape.Libraries.whitelist
local prediction = vape.Libraries.prediction
local getfontsize = vape.Libraries.getfontsize
local getcustomasset = vape.Libraries.getcustomasset
local role = vape.role or "premium"
local user = vape.user or "GUEST"
task.spawn(function()
	while task.wait(0.01) do
		vape.role = role
		vape.user = user
	end
end)

local store = {
	attackReach = 0,
	attackReachUpdate = tick(),
	damageBlockFail = tick(),
	hand = {},
	inventory = {
		inventory = {
			items = {},
			armor = {}
		},
		hotbar = {}
	},
	inventories = {},
	matchState = 0,
	queueType = 'bedwars_test',
	tools = {}
}
local Reach = {}
local HitBoxes = {}
local InfiniteFly = {}
local TrapDisabler
local AntiFallPart
local Speed
local Fly
local AutoTool
local bedwars, remotes, sides, oldinvrender, oldSwing = {}, {}, {}

local function addBlur(parent)
	local blur = Instance.new('ImageLabel')
	blur.Name = 'Blur'
	blur.Size = UDim2.new(1, 89, 1, 52)
	blur.Position = UDim2.fromOffset(-48, -31)
	blur.BackgroundTransparency = 1
	blur.Image = getcustomasset('ReVape/assets/new/blur.png')
	blur.ScaleType = Enum.ScaleType.Slice
	blur.SliceCenter = Rect.new(52, 31, 261, 502)
	blur.Parent = parent
	return blur
end

local function collection(tags, module, customadd, customremove)
	tags = typeof(tags) ~= 'table' and {tags} or tags
	local objs, connections = {}, {}

	for _, tag in tags do
		table.insert(connections, collectionService:GetInstanceAddedSignal(tag):Connect(function(v)
			if customadd then
				customadd(objs, v, tag)
				return
			end
			table.insert(objs, v)
		end))
		table.insert(connections, collectionService:GetInstanceRemovedSignal(tag):Connect(function(v)
			if customremove then
				customremove(objs, v, tag)
				return
			end
			v = table.find(objs, v)
			if v then
				table.remove(objs, v)
			end
		end))

		for _, v in collectionService:GetTagged(tag) do
			if customadd then
				customadd(objs, v, tag)
				continue
			end
			table.insert(objs, v)
		end
	end

	local cleanFunc = function(self)
		for _, v in connections do
			v:Disconnect()
		end
		table.clear(connections)
		table.clear(objs)
		table.clear(self)
	end
	if module then
		module:Clean(cleanFunc)
	end
	return objs, cleanFunc
end

local function getBestArmor(slot)
	local closest, mag = nil, 0

	for _, item in store.inventory.inventory.items do
		local meta = item and bedwars.ItemMeta[item.itemType] or {}

		if meta.armor and meta.armor.slot == slot then
			local newmag = (meta.armor.damageReductionMultiplier or 0)

			if newmag > mag then
				closest, mag = item, newmag
			end
		end
	end

	return closest
end

local function getBow()
	local bestBow, bestBowSlot, bestBowDamage = nil, nil, 0
	for slot, item in store.inventory.inventory.items do
		local bowMeta = bedwars.ItemMeta[item.itemType].projectileSource
		if bowMeta and table.find(bowMeta.ammoItemTypes, 'arrow') then
			local bowDamage = bedwars.ProjectileMeta[bowMeta.projectileType('arrow')].combat.damage or 0
			if bowDamage > bestBowDamage then
				bestBow, bestBowSlot, bestBowDamage = item, slot, bowDamage
			end
		end
	end
	return bestBow, bestBowSlot
end

local function getItem(itemName, inv)
	for slot, item in (inv or store.inventory.inventory.items) do
		if item.itemType == itemName then
			return item, slot
		end
	end
	return nil
end

local function getRoactRender(func)
	return debug.getupvalue(debug.getupvalue(debug.getupvalue(func, 3).render, 2).render, 1)
end

local function getSword()
	local bestSword, bestSwordSlot, bestSwordDamage = nil, nil, 0
	for slot, item in store.inventory.inventory.items do
		local swordMeta = bedwars.ItemMeta[item.itemType].sword
		if swordMeta then
			local swordDamage = swordMeta.damage or 0
			if swordDamage > bestSwordDamage then
				bestSword, bestSwordSlot, bestSwordDamage = item, slot, swordDamage
			end
		end
	end
	return bestSword, bestSwordSlot
end

local function getTool(breakType)
	local bestTool, bestToolSlot, bestToolDamage = nil, nil, 0
	for slot, item in store.inventory.inventory.items do
		local toolMeta = bedwars.ItemMeta[item.itemType].breakBlock
		if toolMeta then
			local toolDamage = toolMeta[breakType] or 0
			if toolDamage > bestToolDamage then
				bestTool, bestToolSlot, bestToolDamage = item, slot, toolDamage
			end
		end
	end
	return bestTool, bestToolSlot
end

local function getWool()
	for _, wool in (inv or store.inventory.inventory.items) do
		if wool.itemType:find('wool') then
			return wool and wool.itemType, wool and wool.amount
		end
	end
end

local function getStrength(plr)
	if not plr.Player then
		return 0
	end

	local strength = 0
	for _, v in (store.inventories[plr.Player] or {items = {}}).items do
		local itemmeta = bedwars.ItemMeta[v.itemType]
		if itemmeta and itemmeta.sword and itemmeta.sword.damage > strength then
			strength = itemmeta.sword.damage
		end
	end

	return strength
end

local function getPlacedBlock(pos)
	if not pos then
		return
	end
	local roundedPosition = bedwars.BlockController:getBlockPosition(pos)
	return bedwars.BlockController:getStore():getBlockAt(roundedPosition), roundedPosition
end

local function getBlocksInPoints(s, e)
	local blocks, list = bedwars.BlockController:getStore(), {}
	for x = s.X, e.X do
		for y = s.Y, e.Y do
			for z = s.Z, e.Z do
				local vec = Vector3.new(x, y, z)
				if blocks:getBlockAt(vec) then
					table.insert(list, vec * 3)
				end
			end
		end
	end
	return list
end

local function getNearGround(range)
	range = Vector3.new(3, 3, 3) * (range or 10)
	local localPosition, mag, closest = entitylib.character.RootPart.Position, 60
	local blocks = getBlocksInPoints(bedwars.BlockController:getBlockPosition(localPosition - range), bedwars.BlockController:getBlockPosition(localPosition + range))

	for _, v in blocks do
		if not getPlacedBlock(v + Vector3.new(0, 3, 0)) then
			local newmag = (localPosition - v).Magnitude
			if newmag < mag then
				mag, closest = newmag, v + Vector3.new(0, 3, 0)
			end
		end
	end

	table.clear(blocks)
	return closest
end

local function getShieldAttribute(char)
	local returned = 0
	for name, val in char:GetAttributes() do
		if name:find('Shield') and type(val) == 'number' and val > 0 then
			returned += val
		end
	end
	return returned
end

local function getSpeed()
	local multi, increase, modifiers = 0, true, bedwars.SprintController:getMovementStatusModifier():getModifiers()

	for v in modifiers do
		local val = v.constantSpeedMultiplier and v.constantSpeedMultiplier or 0
		if val and val > math.max(multi, 1) then
			increase = false
			multi = val - (0.06 * math.round(val))
		end
	end

	for v in modifiers do
		multi += math.max((v.moveSpeedMultiplier or 0) - 1, 0)
	end

	if multi > 0 and increase then
		multi += 0.16 + (0.02 * math.round(multi))
	end

	return 20 * (multi + 1)
end

local function getTableSize(tab)
	local ind = 0
	for _ in tab do
		ind += 1
	end
	return ind
end

local function hotbarSwitch(slot)
	if slot and store.inventory.hotbarSlot ~= slot then
		bedwars.Store:dispatch({
			type = 'InventorySelectHotbarSlot',
			slot = slot
		})
		vapeEvents.InventoryChanged.Event:Wait()
		return true
	end
	return false
end

local function isFriend(plr, recolor)
	if vape.Categories.Friends.Options['Use friends'].Enabled then
		local friend = table.find(vape.Categories.Friends.ListEnabled, plr.Name) and true
		if recolor then
			friend = friend and vape.Categories.Friends.Options['Recolor visuals'].Enabled
		end
		return friend
	end
	return nil
end

local function isTarget(plr)
	return table.find(vape.Categories.Targets.ListEnabled, plr.Name) and true
end

local function notif(...) return
	vape:CreateNotification(...)
end

local function removeTags(str)
	str = str:gsub('<br%s*/>', '\n')
	return (str:gsub('<[^<>]->', ''))
end

local function roundPos(vec)
	return Vector3.new(math.round(vec.X / 3) * 3, math.round(vec.Y / 3) * 3, math.round(vec.Z / 3) * 3)
end

local function coreswitch(tool, ignore)
    local character = lplr.Character
    if not character then return end

    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end

	if not ignore then
		local currentHandItem
		for _, acc in character:GetChildren() do
			if acc:IsA("Accessory") and acc:GetAttribute("InvItem") == true and acc:GetAttribute("ArmorSlot") == nil and acc:GetAttribute("IsBackpack") == nil then
				currentHandItem = acc
				break
			end
		end
		if currentHandItem then
			currentHandItem:Destroy()
		end
	
		for _, weld in pairs(character:GetDescendants()) do
			if weld:IsA("Weld") and weld.Name == "HandItemWeld" then
				weld:Destroy()
			end
		end
	
		local inventoryFolder = character:FindFirstChild("InventoryFolder")
		if not inventoryFolder or not inventoryFolder.Value then return end
		local toolInstance = inventoryFolder.Value:FindFirstChild(tool.Name)
		if not toolInstance then return end
		local clone = toolInstance:Clone()
	
		clone:SetAttribute("InvItem", true)
	
		humanoid:AddAccessory(clone)
	
		local handle = clone:FindFirstChild("Handle")
		if handle and handle:IsA("BasePart") then
			local attachment = handle:FindFirstChildWhichIsA("Attachment")
			if attachment then
				local characterAttachment = character:FindFirstChild(attachment.Name, true)
				if characterAttachment and characterAttachment:IsA("Attachment") then
					local weld = Instance.new("Weld")
					weld.Name = "HandItemWeld"
					weld.Part0 = characterAttachment.Parent 
					weld.Part1 = handle
					weld.C0 = characterAttachment.CFrame
					weld.C1 = attachment.CFrame
					weld.Parent = handle
				end
			end
		end
	
		local handInvItem = character:FindFirstChild("HandInvItem")
		if handInvItem then
			handInvItem.Value = tool
		end
	end

	pcall(function()
		local res = bedwars.Client:Get(remotes.SetInvItem):CallServerAsync({hand = tool})
		if res ~= nil and res == true then
			local handInvItem = character:FindFirstChild("HandInvItem")
			if handInvItem then
				handInvItem.Value = tool
			end
		elseif string.find(string.lower(tostring(res)), 'promise') then
			res:andThen(function(res)
				if res == true then
					local handInvItem = character:FindFirstChild("HandInvItem")
					if handInvItem then
						handInvItem.Value = tool
					end
				end
			end)
		end
	end)

    return true
end
local function corehotbarswitch(tool)
	local function findChild(name, className, children, nodebug)
		children = children:GetChildren()
        for i,v in pairs(children) do if v.Name == name and v.ClassName == className then return v end end
        local args = {Name = tostring(name), ClassName == tostring(className), Children = children}
		if not nodebug then
			warn("[findChild]: CHILD NOT FOUND! Args: ", game:GetService("HttpService"):JSONEncode(args), name, className, children)
		end
        return nil
    end
	local function resolveHotbar()
		local hotbar
		hotbar = findChild("hotbar", "ScreenGui", lplr:WaitForChild("PlayerGui"))
		if not hotbar then return false end

		local _1 = findChild("1", "Frame", hotbar, true)
		if not _1 then return false end

		local ItemsHotbar = findChild("ItemsHotbar", "Frame", _1)
		if not ItemsHotbar then return false end

		return {
			hotbar = hotbar,
			items = ItemsHotbar
		}
	end
	local function resolveItemHotbar(hotbar)
		if tostring(hotbar) == "10" then return "blacklisted" end
		local res = {
			id = hotbar.Name,
			toolImage = "",
			toolAmount = 0,
			object = hotbar
		}
		if not tonumber(res.id) then return false end

		local _1 = findChild("1", "ImageButton", hotbar, true)
		if not _1 then return false end

		local __1 = findChild("1", "TextLabel", _1, true)
		if __1 then 
			res.toolAmount = tonumber(__1.Text) or nil
		end

		local _3 = findChild("3", "Frame", _1, true)
		if not _3 then return false end

		local ___1 = findChild("1", "ImageLabel", _3, true)
		if not ___1 then return false end
		res.toolImage = ___1.Image

		return res
	end
	local function resolveItemsHotbar(hotbar)
		local res = {}
		for i,v in pairs(hotbar:GetChildren()) do
			local rev = resolveItemHotbar(v)
			local name = tostring(v.Name)
			if rev and type(rev) == "table" then 
				if res[name] then warn("Duplication found! Overwriting... ["..name.."]") end
				res[name] = rev
			else
				if rev == "blacklisted" then continue end
				if res[name] then warn("Duplication found! Overwriting... ["..name.."]") end
				res[name] = {
					object = v
				}
			end
		end
		return res
	end
	local function findTool(items_rev, img)
		local res = {
			tool = nil,
			activated = nil
		}
		for i,v in pairs(items_rev) do
			if v.toolImage and tostring(v.toolImage) == tostring(img) then 
				res.tool = v
			end
			local img = findChild("1", "ImageButton", v.object)
			if img and img.Position ~= UDim2.new(0, 0, 0, 0) then
				res.activated = v
			end
		end
		return res
	end
	local function deactivatify(object)
		local img = findChild("1", "ImageButton", object)
		if img then
			img.Position = UDim2.new(0, 0, 0, 0)
			img.BorderColor3 = Color3.fromRGB(114, 127, 172)
			local text = findChild("1", "TextLabel", img)
			text.TextColor3 = Color3.fromRGB(255, 255, 255)
			text.BackgroundColor3 = Color3.fromRGB(114, 127, 172)
		end
	end
	local function activatify(object)
		local img = findChild("1", "ImageButton", object)
		if img then
			img.Position = UDim2.new(0, 0, -0.075, 0)
			img.BorderColor3 = Color3.fromRGB(255, 255, 255)
			local text = findChild("1", "TextLabel", img)
			text.TextColor3 = Color3.fromRGB(0, 0, 0)
			text.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		end
	end
	task.spawn(function()
		local function run(func)
			local suc, err = pcall(function()
				func()
			end)
			if err then warn("[CoreSwitch Error]: "..tostring(debug.traceback(err))) end
		end
		run(function()
			if not lplr.Character then return false end

			if not tool then
				tool = lplr.Character and lplr.Character:FindFirstChild('HandInvItem') and lplr.Character:FindFirstChild('HandInvItem').Value or nil
			end
			if not tool then return false end
			tool = tostring(tool)

			local hotbar_rev = resolveHotbar()
			if not hotbar_rev then return false end

			local ItemsHotbar = hotbar_rev.items
			local items_rev = resolveItemsHotbar(ItemsHotbar)
			if not items_rev then return false end

			repeat task.wait() until (bedwars.ItemMeta ~= nil and type(bedwars.ItemMeta) == "table") or (bedwars.ItemTable ~= nil and type(bedwars.ItemTable) == "table")
			local meta = ((bedwars.ItemMeta and bedwars.ItemMeta[tool]) or (bedwars.ItemTable and bedwars.ItemTable[tool]))
			if ((not meta) or (meta ~= nil and (not meta.image))) then return false end

			local img = meta.image
			
			local tool_rev = findTool(items_rev, img)
			if ((not tool_rev) or ((tool_rev ~= nil) and (not tool_rev.tool))) then return false end
			local rev = {
				image = findChild("1", "ImageButton", tool_rev.tool.object)
			}
			if tool_rev.activated then 
				rev.activate = findChild("1", "ImageButton", tool_rev.activated.object)
			end
			if (not rev.image) then return false end

			if rev.activate then
				deactivatify(tool_rev.activated.object)
			end
			activatify(tool_rev.tool.object)
		end)	
	end)
end

local function switchItem(tool, delayTime)
	delayTime = delayTime or 0.05
	delayTime = (delayTime == 0 and 0.05 or delayTime)
	if tool ~= nil and type(tool) == "string" then
		tool = getItem(tool) and getItem(tool).tool
	end
		local _tool = lplr.Character and lplr.Character:FindFirstChild('HandInvItem') and lplr.Character:FindFirstChild('HandInvItem').Value or nil
		if _tool ~= nil and _tool ~= tool then
			coreswitch(tool, true)
			corehotbarswitch()
		end
end

local function switchItemV2(tool, delayTime)
	delayTime = delayTime or 0.05
	delayTime = (delayTime == 0 and 0.05 or delayTime)
	if tool ~= nil and typeof(tool) == "string" then
		tool = getItem(tool) and getItem(tool).tool
	end
	task.delay(delayTime,function()
		bedwars.Client:Get('SetInvItem'):CallServer({hand = tool})
	end)
end
getgenv().SIV2 = switchItemV2
getgenv().SI = switchItem

local function waitForChildOfType(obj, name, timeout, prop)
	local check, returned = tick() + timeout
	repeat
		returned = prop and obj[name] or obj:FindFirstChildOfClass(name)
		if returned and returned.Name ~= 'UpperTorso' or check < tick() then
			break
		end
		task.wait(0.1)
	until false
	return returned
end

local frictionTable, oldfrict = {}, {}
local frictionConnection
local frictionState

local function modifyVelocity(v)
	if v:IsA('BasePart') and v.Name ~= 'HumanoidRootPart' and not oldfrict[v] then
		oldfrict[v] = v.CustomPhysicalProperties or 'none'
		v.CustomPhysicalProperties = PhysicalProperties.new(0.0001, 0.2, 0.5, 1, 1)
	end
end

local function updateVelocity(force)
	local newState = getTableSize(frictionTable) > 0
	if frictionState ~= newState or force then
		if frictionConnection then
			frictionConnection:Disconnect()
		end
		if newState then
			if entitylib.isAlive then
				for _, v in entitylib.character.Character:GetDescendants() do
					modifyVelocity(v)
				end
				frictionConnection = entitylib.character.Character.DescendantAdded:Connect(modifyVelocity)
			end
		else
			for i, v in oldfrict do
				i.CustomPhysicalProperties = v ~= 'none' and v or nil
			end
			table.clear(oldfrict)
		end
	end
	frictionState = newState
end

local function isEveryoneDead()
	return #bedwars.Store:getState().Party.members <= 0
end
	
local function joinQueue()
	if not bedwars.Store:getState().Game.customMatch and bedwars.Store:getState().Party.leader.userId == lplr.UserId and bedwars.Store:getState().Party.queueState == 0 then
		bedwars.QueueController:joinQueue(store.queueType)
	end
end

local function lobby()
	game.ReplicatedStorage.rbxts_include.node_modules['@rbxts'].net.out._NetManaged.TeleportToLobby:FireServer()
end

local kitorder = {
	hannah = 5,
	spirit_assassin = 4,
	dasher = 3,
	jade = 2,
	regent = 1
}

local sortmethods = {
	Damage = function(a, b)
		return a.Entity.Character:GetAttribute('LastDamageTakenTime') < b.Entity.Character:GetAttribute('LastDamageTakenTime')
	end,
	Threat = function(a, b)
		return getStrength(a.Entity) > getStrength(b.Entity)
	end,
	Kit = function(a, b)
		return (a.Entity.Player and kitorder[a.Entity.Player:GetAttribute('PlayingAsKits')] or 0) > (b.Entity.Player and kitorder[b.Entity.Player:GetAttribute('PlayingAsKits')] or 0)
	end,
	Health = function(a, b)
		return a.Entity.Health < b.Entity.Health
	end,
	Angle = function(a, b)
		local selfrootpos = entitylib.character.RootPart.Position
		local localfacing = entitylib.character.RootPart.CFrame.LookVector * Vector3.new(1, 0, 1)
		local angle = math.acos(localfacing:Dot(((a.Entity.RootPart.Position - selfrootpos) * Vector3.new(1, 0, 1)).Unit))
		local angle2 = math.acos(localfacing:Dot(((b.Entity.RootPart.Position - selfrootpos) * Vector3.new(1, 0, 1)).Unit))
		return angle < angle2
	end
}


run(function()
	local oldstart = entitylib.start
	local function customEntity(ent)
		if ent:HasTag('inventory-entity') and not ent:HasTag('Monster') then
			return
		end

		entitylib.addEntity(ent, nil, ent:HasTag('Drone') and function(self)
			local droneplr = playersService:GetPlayerByUserId(self.Character:GetAttribute('PlayerUserId'))
			return not droneplr or lplr:GetAttribute('Team') ~= droneplr:GetAttribute('Team')
		end or function(self)
			return lplr:GetAttribute('Team') ~= self.Character:GetAttribute('Team')
		end)
	end

	entitylib.start = function()
		oldstart()
		if entitylib.Running then
			for _, ent in collectionService:GetTagged('entity') do
				customEntity(ent)
			end
			table.insert(entitylib.Connections, collectionService:GetInstanceAddedSignal('entity'):Connect(customEntity))
			table.insert(entitylib.Connections, collectionService:GetInstanceRemovedSignal('entity'):Connect(function(ent)
				entitylib.removeEntity(ent)
			end))
		end
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
			plr:GetAttributeChangedSignal('Team'):Connect(function()
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

	entitylib.addEntity = function(char, plr, teamfunc)
		if not char then return end
		entitylib.EntityThreads[char] = task.spawn(function()
			local hum, humrootpart, head
			if plr then
				hum = waitForChildOfType(char, 'Humanoid', 10)
				humrootpart = hum and waitForChildOfType(hum, 'RootPart', workspace.StreamingEnabled and 9e9 or 10, true)
				head = char:WaitForChild('Head', 10) or humrootpart
			else
				hum = {HipHeight = 0.5}
				humrootpart = waitForChildOfType(char, 'PrimaryPart', 10, true)
				head = humrootpart
			end
			local updateobjects = plr and plr ~= lplr and {
				char:WaitForChild('ArmorInvItem_0', 5),
				char:WaitForChild('ArmorInvItem_1', 5),
				char:WaitForChild('ArmorInvItem_2', 5),
				char:WaitForChild('HandInvItem', 5)
			} or {}

			if hum and humrootpart then
				local entity = {
					Connections = {},
					Character = char,
					Health = (char:GetAttribute('Health') or 100) + getShieldAttribute(char),
					Head = head,
					Humanoid = hum,
					HumanoidRootPart = humrootpart,
					HipHeight = hum.HipHeight + (humrootpart.Size.Y / 2) + (hum.RigType == Enum.HumanoidRigType.R6 and 2 or 0),
					Jumps = 0,
					JumpTick = tick(),
					Jumping = false,
					LandTick = tick(),
					MaxHealth = char:GetAttribute('MaxHealth') or 100,
					NPC = plr == nil,
					Player = plr,
					RootPart = humrootpart,
					TeamCheck = teamfunc
				}

				if plr == lplr then
					entity.AirTime = tick()
					entitylib.character = entity
					entitylib.isAlive = true
					entitylib.Events.LocalAdded:Fire(entity)
					table.insert(entitylib.Connections, char.AttributeChanged:Connect(function(attr)
						vapeEvents.AttributeChanged:Fire(attr)
					end))
				else
					entity.Targetable = entitylib.targetCheck(entity)

					for _, v in entitylib.getUpdateConnections(entity) do
						table.insert(entity.Connections, v:Connect(function()
							entity.Health = (char:GetAttribute('Health') or 100) + getShieldAttribute(char)
							entity.MaxHealth = char:GetAttribute('MaxHealth') or 100
							entitylib.Events.EntityUpdated:Fire(entity)
						end))
					end

					for _, v in updateobjects do
						table.insert(entity.Connections, v:GetPropertyChangedSignal('Value'):Connect(function()
							task.delay(0.1, function()
								if bedwars.getInventory then
									store.inventories[plr] = bedwars.getInventory(plr)
									entitylib.Events.EntityUpdated:Fire(entity)
								end
							end)
						end))
					end

					if plr then
						local anim = char:FindFirstChild('Animate')
						if anim then
							pcall(function()
								anim = anim.jump:FindFirstChildWhichIsA('Animation').AnimationId
								table.insert(entity.Connections, hum.Animator.AnimationPlayed:Connect(function(playedanim)
									if playedanim.Animation.AnimationId == anim then
										entity.JumpTick = tick()
										entity.Jumps += 1
										entity.LandTick = tick() + 1
										entity.Jumping = entity.Jumps > 1
									end
								end))
							end)
						end

						task.delay(0.1, function()
							if bedwars.getInventory then
								store.inventories[plr] = bedwars.getInventory(plr)
							end
						end)
					end
					table.insert(entitylib.List, entity)
					entitylib.Events.EntityAdded:Fire(entity)
				end

				table.insert(entity.Connections, char.ChildRemoved:Connect(function(part)
					if part == humrootpart or part == hum or part == head then
						if part == humrootpart and hum.RootPart then
							humrootpart = hum.RootPart
							entity.RootPart = hum.RootPart
							entity.HumanoidRootPart = hum.RootPart
							return
						end
						entitylib.removeEntity(char, plr == lplr)
					end
				end))
			end
			entitylib.EntityThreads[char] = nil
		end)
	end

	entitylib.getUpdateConnections = function(ent)
		local char = ent.Character
		local tab = {
			char:GetAttributeChangedSignal('Health'),
			char:GetAttributeChangedSignal('MaxHealth'),
			{
				Connect = function()
					ent.Friend = ent.Player and isFriend(ent.Player) or nil
					ent.Target = ent.Player and isTarget(ent.Player) or nil
					return {Disconnect = function() end}
				end
			}
		}

		if ent.Player then
			table.insert(tab, ent.Player:GetAttributeChangedSignal('PlayingAsKit'))
		end

		for name, val in char:GetAttributes() do
			if name:find('Shield') and type(val) == 'number' then
				table.insert(tab, char:GetAttributeChangedSignal(name))
			end
		end

		return tab
	end

	entitylib.targetCheck = function(ent)
		if ent.TeamCheck then
			return ent:TeamCheck()
		end
		if ent.NPC then return true end
		if isFriend(ent.Player) then return false end
		if not select(2, whitelist:get(ent.Player)) then return false end
		return lplr:GetAttribute('Team') ~= ent.Player:GetAttribute('Team')
	end
	vape:Clean(entitylib.Events.LocalAdded:Connect(updateVelocity))
end)
entitylib.start()
local function safeGetProto(func, index)
    if not func then return nil end
    local success, proto = pcall(safeGetProto, func, index)
    if success then
        return proto
    else
        warn("function:", func, "index:", index,", WM - proto") 
        return nil
    end
end



run(function()
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

	bedwars = setmetatable({
		AbilityController = Flamework.resolveDependency('@easy-games/game-core:client/controllers/ability/ability-controller@AbilityController'),
		AnimationType = require(replicatedStorage.TS.animation['animation-type']).AnimationType,
		AnimationUtil = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out['shared'].util['animation-util']).AnimationUtil,
		AppController = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out.client.controllers['app-controller']).AppController,
		BedBreakEffectMeta = require(replicatedStorage.TS.locker['bed-break-effect']['bed-break-effect-meta']).BedBreakEffectMeta,
		BedwarsKitMeta = require(replicatedStorage.TS.games.bedwars.kit['bedwars-kit-meta']).BedwarsKitMeta,
		BlockBreaker = Knit.Controllers.BlockBreakController.blockBreaker,
		BlockController = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['block-engine'].out).BlockEngine,
		BlockEngine = require(lplr.PlayerScripts.TS.lib['block-engine']['client-block-engine']).ClientBlockEngine,
		BlockPlacer = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['block-engine'].out.client.placement['block-placer']).BlockPlacer,
		BowConstantsTable = debug.getupvalue(Knit.Controllers.ProjectileController.enableBeam, 8),
		ClickHold = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out.client.ui.lib.util['click-hold']).ClickHold,
		Client = Client,
		ClientConstructor = require(replicatedStorage['rbxts_include']['node_modules']['@rbxts'].net.out.client),
		ClientDamageBlock = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['block-engine'].out.shared.remotes).BlockEngineRemotes.Client,
		CombatConstant = require(replicatedStorage.TS.combat['combat-constant']).CombatConstant,
		SharedConstants = require(replicatedStorage.TS['shared-constants']),
		DamageIndicator = Knit.Controllers.DamageIndicatorController.spawnDamageIndicator,
		DefaultKillEffect = require(lplr.PlayerScripts.TS.controllers.global.locker['kill-effect'].effects['default-kill-effect']),
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
		KillEffectMeta = require(replicatedStorage.TS.locker['kill-effect']['kill-effect-meta']).KillEffectMeta,
		KillFeedController = Flamework.resolveDependency('client/controllers/game/kill-feed/kill-feed-controller@KillFeedController'),
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
		SoundManager = require(replicatedStorage['rbxts_include']['node_modules']['@easy-games']['game-core'].out.shared.sound['sound-manager']),
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

	local remoteNames = {
		AfkStatus = safeGetProto(Knit.Controllers.AfkController.KnitStart, 1),
		AttackEntity = Knit.Controllers.SwordController.sendServerRequest,
		BeePickup = Knit.Controllers.BeeNetController.trigger,
		CannonAim = safeGetProto(Knit.Controllers.CannonController.startAiming, 5),
		CannonLaunch = Knit.Controllers.CannonHandController.launchSelf,
		ConsumeBattery = safeGetProto(Knit.Controllers.BatteryController.onKitLocalActivated, 1),
		ConsumeItem = safeGetProto(Knit.Controllers.ConsumeController.onEnable, 1),
		ConsumeSoul = Knit.Controllers.GrimReaperController.consumeSoul,
		ConsumeTreeOrb = safeGetProto(Knit.Controllers.EldertreeController.createTreeOrbInteraction, 1),
		DepositPinata = safeGetProto(Knit.Controllers.PiggyBankController.KnitStart, 5),
		DragonBreath = safeGetProto(Knit.Controllers.VoidDragonController.onKitLocalActivated, 5),
		DragonEndFly = safeGetProto(Knit.Controllers.VoidDragonController.flapWings, 1),
		DragonFly = Knit.Controllers.VoidDragonController.flapWings,
		DropItem = Knit.Controllers.ItemDropController.dropItemInHand,
		SetInvItem = safeGetProto(require(replicatedStorage.TS.entity.entities['inventory-entity']).InventoryEntity.SetInvItem, 3),
		FireProjectile = debug.getupvalue(Knit.Controllers.ProjectileController.launchProjectileWithValues, 2),
		GroundHit = Knit.Controllers.FallDamageController.KnitStart,
		GuitarHeal = Knit.Controllers.GuitarController.performHeal,
		HannahKill = safeGetProto(Knit.Controllers.HannahController.registerExecuteInteractions, 1),
		HarvestCrop = safeGetProto(safeGetProto(Knit.Controllers.CropController.KnitStart, 4), 1),
		KaliyahPunch = safeGetProto(Knit.Controllers.DragonSlayerController.onKitLocalActivated, 1),
		MageSelect = safeGetProto(Knit.Controllers.MageController.registerTomeInteraction, 1),
		MinerDig = safeGetProto(Knit.Controllers.MinerController.setupMinerPrompts, 1),
		PickupItem = Knit.Controllers.ItemDropController.checkForPickup,
		PickupMetal = safeGetProto(Knit.Controllers.HiddenMetalController.onKitLocalActivated, 4),
		ReportPlayer = require(lplr.PlayerScripts.TS.controllers.global.report['report-controller']).default.reportPlayer,
		ResetCharacter = safeGetProto(Knit.Controllers.ResetController.createBindable, 1),
		SpawnRaven = safeGetProto(Knit.Controllers.RavenController.KnitStart, 1),
		SummonerClawAttack = Knit.Controllers.SummonerClawHandController.attack,
		WarlockTarget = safeGetProto(Knit.Controllers.WarlockStaffController.KnitStart, 2),
	}
	local function dumpRemote(tab)
		local ind
		for i, v in tab do
			if v == 'Client' then
				ind = i
				break
			end
		end
		return ind and tab[ind + 1] or ''
	end

	for i, v in remoteNames do
		local remote = dumpRemote(debug.getconstants(v))
		if remote == '' then
			notif('Onyx', 'Failed to grab remote ('..i..')', 10, 'alert')
		end
		remotes[i] = remote
	end

	OldBreak = bedwars.BlockController.isBlockBreakable

	Client.Get = function(self, remoteName)
		local call = OldGet(self, remoteName)
		if remoteName == remotes.AttackEntity then
			return {
				instance = call.instance,
				SendToServer = function(_, attackTable, ...)
					local suc, plr = pcall(function()
						return playersService:GetPlayerFromCharacter(attackTable.entityInstance)
					end)

					local selfpos = attackTable.validate.selfPosition.value
					local targetpos = attackTable.validate.targetPosition.value
					store.attackReach = ((selfpos - targetpos).Magnitude * 100) // 1 / 100
					store.attackReachUpdate = tick() + 1

					if Reach.Enabled or HitBoxes.Enabled then
						attackTable.validate.raycast = attackTable.validate.raycast or {}
						attackTable.validate.selfPosition.value += CFrame.lookAt(selfpos, targetpos).LookVector * math.max((selfpos - targetpos).Magnitude - 14.399, 0)
					end

					if suc and plr then
						if not select(2, whitelist:get(plr)) then return end
					end

					return call:SendToServer(attackTable, ...)
				end
			}
		elseif remoteName == 'StepOnSnapTrap' and TrapDisabler.Enabled then
			return {SendToServer = function() end}
		end

		return call
	end

	bedwars.BlockController.isBlockBreakable = function(self, breakTable, plr)
		local obj = bedwars.BlockController:getStore():getBlockAt(breakTable.blockPosition)

		if obj and obj.Name == 'bed' then
			for _, plr in playersService:GetPlayers() do
				if obj:GetAttribute('Team'..(plr:GetAttribute('Team') or 0)..'NoBreak') and not select(2, whitelist:get(plr)) then
					return false
				end
			end
		end

		return OldBreak(self, breakTable, plr)
	end

	local cache, blockhealthbar = {}, {blockHealth = -1, breakingBlockPosition = Vector3.zero}
	store.blockPlacer = bedwars.BlockPlacer.new(bedwars.BlockEngine, 'wool_white')

	local function getBlockHealth(block, blockpos)
		local blockdata = bedwars.BlockController:getStore():getBlockData(blockpos)
		return (blockdata and (blockdata:GetAttribute('1') or blockdata:GetAttribute('Health')) or block:GetAttribute('Health'))
	end

	local function getBlockHits(block, blockpos)
		if not block then return 0 end
		local breaktype = bedwars.ItemMeta[block.Name].block.breakType
		local tool = store.tools[breaktype]
		tool = tool and bedwars.ItemMeta[tool.itemType].breakBlock[breaktype] or 2
		return getBlockHealth(block, bedwars.BlockController:getBlockPosition(blockpos)) / tool
	end

	local function calculatePath(target, blockpos)
		if cache[blockpos] then
			return unpack(cache[blockpos])
		end
		local visited, unvisited, distances, air, path = {}, {{0, blockpos}}, {[blockpos] = 0}, {}, {}

		for _ = 1, 10000 do
			local _, node = next(unvisited)
			if not node then break end
			table.remove(unvisited, 1)
			visited[node[2]] = true

			for _, side in sides do
				side = node[2] + side
				if visited[side] then continue end

				local block = getPlacedBlock(side)
				if not block or block:GetAttribute('NoBreak') or block == target then
					if not block then
						air[node[2]] = true
					end
					continue
				end

				local curdist = getBlockHits(block, side) + node[1]
				if curdist < (distances[side] or math.huge) then
					table.insert(unvisited, {curdist, side})
					distances[side] = curdist
					path[side] = node[2]
				end
			end
		end

		local pos, cost = nil, math.huge
		for node in air do
			if distances[node] < cost then
				pos, cost = node, distances[node]
			end
		end

		if pos then
			cache[blockpos] = {
				pos,
				cost,
				path
			}
			return pos, cost, path
		end
	end

	bedwars.placeBlock = function(pos, item)
		if getItem(item) then
			store.blockPlacer.blockType = item
			return store.blockPlacer:placeBlock(bedwars.BlockController:getBlockPosition(pos))
		end
	end

	bedwars.breakBlock = function(block, effects, anim, customHealthbar)
		if lplr:GetAttribute('DenyBlockBreak') or not entitylib.isAlive or InfiniteFly.Enabled then return end
		local handler = bedwars.BlockController:getHandlerRegistry():getHandler(block.Name)
		local cost, pos, target, path = math.huge

		for _, v in (handler and handler:getContainedPositions(block) or {block.Position / 3}) do
			local dpos, dcost, dpath = calculatePath(block, v * 3)
			if dpos and dcost < cost then
				cost, pos, target, path = dcost, dpos, v * 3, dpath
			end
		end

		if pos then
			if (entitylib.character.RootPart.Position - pos).Magnitude > 30 then return end
			local dblock, dpos = getPlacedBlock(pos)
			if not dblock then return end

			if (workspace:GetServerTimeNow() - bedwars.SwordController.lastAttack) > 0.4 then
				local breaktype = bedwars.ItemMeta[dblock.Name].block.breakType
				local tool = store.tools[breaktype]
				if tool then
					switchItem(tool.tool)
				end
			end

			if blockhealthbar.blockHealth == -1 or dpos ~= blockhealthbar.breakingBlockPosition then
				blockhealthbar.blockHealth = getBlockHealth(dblock, dpos)
				blockhealthbar.breakingBlockPosition = dpos
			end

			bedwars.ClientDamageBlock:Get('DamageBlock'):CallServerAsync({
				blockRef = {blockPosition = dpos},
				hitPosition = pos,
				hitNormal = Vector3.FromNormalId(Enum.NormalId.Top)
			}):andThen(function(result)
				if result then
					if result == 'cancelled' then
						store.damageBlockFail = tick() + 1
						return
					end

					if effects then
						local blockdmg = (blockhealthbar.blockHealth - (result == 'destroyed' and 0 or getBlockHealth(dblock, dpos)))
						customHealthbar = customHealthbar or bedwars.BlockBreaker.updateHealthbar
						customHealthbar(bedwars.BlockBreaker, {blockPosition = dpos}, blockhealthbar.blockHealth, dblock:GetAttribute('MaxHealth'), blockdmg, dblock)
						blockhealthbar.blockHealth = math.max(blockhealthbar.blockHealth - blockdmg, 0)

						if blockhealthbar.blockHealth <= 0 then
							bedwars.BlockBreaker.breakEffect:playBreak(dblock.Name, dpos, lplr)
							bedwars.BlockBreaker.healthbarMaid:DoCleaning()
							blockhealthbar.breakingBlockPosition = Vector3.zero
						else
							bedwars.BlockBreaker.breakEffect:playHit(dblock.Name, dpos, lplr)
						end
					end

					if anim then
						local animation = bedwars.AnimationUtil:playAnimation(lplr, bedwars.BlockController:getAnimationController():getAssetId(1))
						bedwars.ViewmodelController:playAnimation(15)
						task.wait(0.3)
						animation:Stop()
						animation:Destroy()
					end
				end
			end)

			if effects then
				return pos, path, target
			end
		end
	end

	for _, v in Enum.NormalId:GetEnumItems() do
		table.insert(sides, Vector3.FromNormalId(v) * 3)
	end
	local function updateStore(new, old)
		if new.Bedwars ~= old.Bedwars then
			store.equippedKit = new.Bedwars.kit ~= 'none' and new.Bedwars.kit or ''
		end

		if new.Game ~= old.Game then
			store.matchState = new.Game.matchState
			store.queueType = new.Game.queueType or 'bedwars_test'
		end

		if new.Inventory ~= old.Inventory then
			local newinv = (new.Inventory and new.Inventory.observedInventory or {inventory = {}})
			local oldinv = (old.Inventory and old.Inventory.observedInventory or {inventory = {}})
			store.inventory = newinv

			if newinv ~= oldinv then
				vapeEvents.InventoryChanged:Fire()
			end

			if newinv.inventory.items ~= oldinv.inventory.items then
				vapeEvents.InventoryAmountChanged:Fire()
				store.tools.sword = getSword()
				for _, v in {'stone', 'wood', 'wool'} do
					store.tools[v] = getTool(v)
				end
			end

			if newinv.inventory.hand ~= oldinv.inventory.hand then
				local currentHand, toolType = new.Inventory.observedInventory.inventory.hand, ''
				if currentHand then
					local handData = bedwars.ItemMeta[currentHand.itemType]
					toolType = handData.sword and 'sword' or handData.block and 'block' or currentHand.itemType:find('bow') and 'bow'
				end

				store.hand = {
					tool = currentHand and currentHand.tool,
					amount = currentHand and currentHand.amount or 0,
					toolType = toolType
				}
			end
		end
	end


	local storeChanged = bedwars.Store.changed:connect(updateStore)
	updateStore(bedwars.Store:getState(), {})

	for _, event in {'MatchEndEvent', 'EntityDeathEvent', 'BedwarsBedBreak', 'BalloonPopped', 'AngelProgress', 'GrapplingHookFunctions'} do
		if not vape.Connections then return end
		bedwars.Client:WaitFor(event):andThen(function(connection)
			vape:Clean(connection:Connect(function(...)
				vapeEvents[event]:Fire(...)
			end))
		end)
	end

	vape:Clean(bedwars.ZapNetworking.EntityDamageEventZap.On(function(...)
		vapeEvents.EntityDamageEvent:Fire({
			entityInstance = ...,
			damage = select(2, ...),
			damageType = select(3, ...),
			fromPosition = select(4, ...),
			fromEntity = select(5, ...),
			knockbackMultiplier = select(6, ...),
			knockbackId = select(7, ...),
			disableDamageHighlight = select(13, ...)
		})
	end))

	for _, event in {'PlaceBlockEvent', 'BreakBlockEvent'} do
		vape:Clean(bedwars.ZapNetworking[event..'Zap'].On(function(...)
			local data = {
				blockRef = {
					blockPosition = ...,
				},
				player = select(5, ...)
			}
			for i, v in cache do
				if ((data.blockRef.blockPosition * 3) - v[1]).Magnitude <= 30 then
					table.clear(v[3])
					table.clear(v)
					cache[i] = nil
				end
			end
			vapeEvents[event]:Fire(data)
		end))
	end

	store.blocks = collection('block', gui)
	store.shop = collection({'BedwarsItemShop', 'TeamUpgradeShopkeeper'}, gui, function(tab, obj)
		table.insert(tab, {
			Id = obj.Name,
			RootPart = obj,
			Shop = obj:HasTag('BedwarsItemShop'),
			Upgrades = obj:HasTag('TeamUpgradeShopkeeper')
		})
	end)
	store.enchant = collection({'enchant-table', 'broken-enchant-table'}, gui, nil, function(tab, obj, tag)
		if obj:HasTag('enchant-table') and tag == 'broken-enchant-table' then return end
		obj = table.find(tab, obj)
		if obj then
			table.remove(tab, obj)
		end
	end)

	local kills = sessioninfo:AddItem('Kills')
	local beds = sessioninfo:AddItem('Beds')
	local wins = sessioninfo:AddItem('Wins')
	local games = sessioninfo:AddItem('Games')

	local mapname = 'Unknown'
	sessioninfo:AddItem('Map', 0, function()
		return mapname
	end, false)

	task.delay(1, function()
		games:Increment()
	end)

	task.spawn(function()
		pcall(function()
			repeat task.wait(0.1) until store.matchState ~= 0 or vape.Loaded == nil
			if vape.Loaded == nil then return end
			mapname = workspace:WaitForChild('Map', 5):WaitForChild('Worlds', 5):GetChildren()[1].Name
			mapname = string.gsub(string.split(mapname, '_')[2] or mapname, '-', '') or 'Blank'
		end)
	end)

	vape:Clean(vapeEvents.BedwarsBedBreak.Event:Connect(function(bedTable)
		if bedTable.player and bedTable.player.UserId == lplr.UserId then
			beds:Increment()
		end
	end))

	vape:Clean(vapeEvents.MatchEndEvent.Event:Connect(function(winTable)
		if (bedwars.Store:getState().Game.myTeam or {}).id == winTable.winningTeamId or lplr.Neutral then
			wins:Increment()
		end
	end))

	vape:Clean(vapeEvents.EntityDeathEvent.Event:Connect(function(deathTable)
		local killer = playersService:GetPlayerFromCharacter(deathTable.fromEntity)
		local killed = playersService:GetPlayerFromCharacter(deathTable.entityInstance)
		if not killed or not killer then return end

		if killed ~= lplr and killer == lplr then
			kills:Increment()
		end
	end))

	task.spawn(function()
		repeat
			if entitylib.isAlive then
				entitylib.character.AirTime = entitylib.character.Humanoid.FloorMaterial ~= Enum.Material.Air and tick() or entitylib.character.AirTime
			end

			for _, v in entitylib.List do
				v.LandTick = math.abs(v.RootPart.Velocity.Y) < 0.1 and v.LandTick or tick()
				if (tick() - v.LandTick) > 0.2 and v.Jumps ~= 0 then
					v.Jumps = 0
					v.Jumping = false
				end
			end
			task.wait(0.1)
		until vape.Loaded == nil
	end)

	pcall(function()
		if getthreadidentity and setthreadidentity then
			local old = getthreadidentity()
			setthreadidentity(2)

			bedwars.Shop = require(replicatedStorage.TS.games.bedwars.shop['bedwars-shop']).BedwarsShop
			bedwars.ShopItems = debug.getupvalue(debug.getupvalue(bedwars.Shop.getShopItem, 1), 2)
			bedwars.Shop.getShopItem('iron_sword', lplr)

			setthreadidentity(old)
			store.shopLoaded = true
		else
			task.spawn(function()
				repeat
					task.wait(0.1)
				until vape.Loaded == nil or bedwars.AppController:isAppOpen('BedwarsItemShopApp')

				bedwars.Shop = require(replicatedStorage.TS.games.bedwars.shop['bedwars-shop']).BedwarsShop
				bedwars.ShopItems = debug.getupvalue(debug.getupvalue(bedwars.Shop.getShopItem, 1), 2)
				store.shopLoaded = true
			end)
		end
	end)

	vape:Clean(function()
		Client.Get = OldGet
		bedwars.BlockController.isBlockBreakable = OldBreak
		store.blockPlacer:disable()
		for _, v in vapeEvents do
			v:Destroy()
		end
		for _, v in cache do
			table.clear(v[3])
			table.clear(v)
		end
		table.clear(store.blockPlacer)
		table.clear(vapeEvents)
		table.clear(bedwars)
		table.clear(store)
		table.clear(cache)
		table.clear(sides)
		table.clear(remotes)
		storeChanged:disconnect()
		storeChanged = nil
	end)
end)
if not bedwars.Client then
end
local KaidaController = {}
function KaidaController:request(target)
	if target then 
		return bedwars.Client:Get("SummonerClawAttackRequest"):FireServer({
			["clientTime"] = tick(), 
			["direction"] = (target:FindFirstChild("HumanoidRootPart") and target:FindFirstChild("HumanoidRootPart").Position - lplr.Character.HumanoidRootPart.Position).unit, 
			["position"] = target:FindFirstChild("HumanoidRootPart") and target:FindFirstChild("HumanoidRootPart").Position
		})
	else return nil end
end

local WhisperController = {}
function WhisperController:request(target,type)
	if type == "Heal" then
	if target then 
		if bedwars.AbilityController:canUseAbility('OWL_HEAL') then
			bedwars.AbilityController:useAbility('OWL_HEAL')
			bedwars.Client:Get("OwlActionAbilites"):FireServer({
				["target"] = target,
				['ability'] = 'OWL_HEAL'
			})
		end

	else return end
	elseif type == "Fly" then
	if target then 
		if bedwars.AbilityController:canUseAbility('OWL_LIFT') then
			bedwars.AbilityController:useAbility('OWL_LIFT')
			bedwars.Client:Get("OwlActionAbilites"):FireServer({
				["target"] = target,
				['ability'] = 'OWL_LIFT'
			})
		end
	else return  end
	end
end

local function BedwarsInfoNotification(mes)
	bedwars.NotificationController:sendInfoNotification({
		message = tostring(mes),
		image = "rbxassetid://14399506978"
	});
end

local function BedwarsErrorNotification(mes)
	bedwars.NotificationController:sendErrorNotification({
		message = tostring(mes),
		image = "rbxassetid://18518244636"
	});
end

local reportedPlayers = {}
local function TryToReport(targettedplayer,value)
    reportedPlayers[targettedplayer] = true
	if value == "VapeNotify" then
	    if reportedPlayers[targettedplayer] then
	       	vape:CreateNotification('AutoReport', "You have already reported this player!", 1, "alert")
	        return
		else
	bedwars.Client:Get("ReportPlayer"):SendToServer(targettedplayer)
		vape:CreateNotification('AutoReport', "Reported '" .. targettedplayer.Name .. "'", 1)
		task.wait(1 + math.random())
	    end


	elseif value == "BedwarsNotify" then
	    if reportedPlayers[targettedplayer] then
	        BedwarsErrorNotification("You have already reported this player!")
	        return
		else
			bedwars.Client:Get("ReportPlayer"):SendToServer(targettedplayer)
			BedwarsInfoNotification("Reported " .. targettedplayer.Name)
			task.wait(1 + math.random())
	    end

	elseif value == "Hidden" then
		bedwars.Client:Get("ReportPlayer"):SendToServer(targettedplayer)
		task.wait(1 + math.random())
	else
		bedwars.Client:Get("ReportPlayer"):SendToServer(targettedplayer)
		task.wait(1 + math.random())
	end
end
getgenv().TTR = TryToReport
getgenv().BIN = BedwarsInfoNotification
getgenv().BEN = BedwarsErrorNotification
getgenv().Remotes = bedwars.Client.Get
for _, v in {'AntiRagdoll', 'TriggerBot', 'AutoRejoin', 'Rejoin', 'Disabler', 'Timer', 'ServerHop', 'MouseTP', 'MurderMystery','SilentAim','GetUnc','GetExecutor'} do
	vape:Remove(v)
end
run(function()
	local AimAssist
	local Targets
	local Sort
	local AimSpeed
	local Distance
	local AngleSlider
	local StrafeIncrease
	local KillauraTarget
	local ClickAim
	
	AimAssist = vape.Categories.Combat:CreateModule({
		Name = 'AimAssist',
		Function = function(callback)
			if callback then
				AimAssist:Clean(runService.Heartbeat:Connect(function(dt)
					if entitylib.isAlive and ((not ClickAim.Enabled) or (tick() - bedwars.SwordController.lastSwing) < 0.4) then
						local ent = not KillauraTarget.Enabled and entitylib.EntityPosition({
							Range = Distance.Value,
							Part = 'RootPart',
							Wallcheck = Targets.Walls.Enabled,
							Players = Targets.Players.Enabled,
							NPCs = Targets.NPCs.Enabled,
							Sort = sortmethods[Sort.Value]
						}) or store.KillauraTarget
	
						if ent then
							local delta = (ent.RootPart.Position - entitylib.character.RootPart.Position)
							local localfacing = entitylib.character.RootPart.CFrame.LookVector * Vector3.new(1, 0, 1)
							local angle = math.acos(localfacing:Dot((delta * Vector3.new(1, 0, 1)).Unit))
							if angle >= (math.rad(AngleSlider.Value) / 2) then return end
							targetinfo.Targets[ent] = tick() + 1
							gameCamera.CFrame = gameCamera.CFrame:Lerp(CFrame.lookAt(gameCamera.CFrame.p, ent.RootPart.Position), (AimSpeed.Value + (StrafeIncrease.Enabled and (inputService:IsKeyDown(Enum.KeyCode.A) or inputService:IsKeyDown(Enum.KeyCode.D)) and 10 or 0)) * dt)
						end
					end
				end))
			end
		end,
		Tooltip = 'Smoothly aims to closest valid target with sword'
	})
	Targets = AimAssist:CreateTargets({
		Players = true,
		Walls = true
	})
	local methods = {'Damage', 'Distance'}
	for i in sortmethods do
		if not table.find(methods, i) then
			table.insert(methods, i)
		end
	end
	Sort = AimAssist:CreateDropdown({
		Name = 'Target Mode',
		List = methods
	})
	AimSpeed = AimAssist:CreateSlider({
		Name = 'Aim Speed',
		Min = 1,
		Max = 20,
		Default = 6
	})
	Distance = AimAssist:CreateSlider({
		Name = 'Distance',
		Min = 1,
		Max = 30,
		Default = 30,
		Suffx = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	AngleSlider = AimAssist:CreateSlider({
		Name = 'Max angle',
		Min = 1,
		Max = 360,
		Default = 70
	})
	ClickAim = AimAssist:CreateToggle({
		Name = 'Click Aim',
		Default = true
	})
	KillauraTarget = AimAssist:CreateToggle({
		Name = 'Use killaura target',
	})
	StrafeIncrease = AimAssist:CreateToggle({Name = 'Strafe increase'})
end)


	
run(function()
	local old
	
	AutoCharge = vape.Categories.Combat:CreateModule({
	    Name = 'AutoCharge',
	    Function = function(callback)
	        debug.setconstant(bedwars.SwordController.attackEntity, 58, callback and 'damage' or 'multiHitCheckDurationSec')
	        if callback then
	            local chargeSwingTime = 0
	            local canSwing
	
	            old = bedwars.SwordController.sendServerRequest
	            bedwars.SwordController.sendServerRequest = function(self, ...)
	                if (os.clock() - chargeSwingTime) < AutoChargeTime.Value then return end
	                self.lastSwingServerTimeDelta = 0.5
	                chargeSwingTime = os.clock()
	                canSwing = true
	
	                local item = self:getHandItem()
	                if item and item.tool then
	                    self:playSwordEffect(bedwars.ItemMeta[item.tool.Name], false)
	                end
	
	                return old(self, ...)
	            end
	
	            oldSwing = bedwars.SwordController.playSwordEffect
	            bedwars.SwordController.playSwordEffect = function(...)
	                if not canSwing then return end
	                canSwing = false
	                return oldSwing(...)
	            end
	        else
	            if old then
	                bedwars.SwordController.sendServerRequest = old
	                old = nil
	            end
	
	            if oldSwing then
	                bedwars.SwordController.playSwordEffect = oldSwing
	                oldSwing = nil
	            end
	        end
	    end,
	    Tooltip = 'Allows you to get charged hits while spam clicking.'
	})
	AutoChargeTime = AutoCharge:CreateSlider({
	    Name = 'Charge Time',
	    Min = 0,
	    Max = 0.5,
	    Default = 0.4,
	    Decimal = 100
	})
				vape:Remove('AutoCharge')
end)
	
run(function()
	local AutoClicker
	local CPS
	local BlockCPS = {}
	local Thread
	
	local function AutoClick()
		if Thread then
			task.cancel(Thread)
		end
	
		Thread = task.delay(1 / 7, function()
			repeat
				if not bedwars.AppController:isLayerOpen(bedwars.UILayers.MAIN) then
					local blockPlacer = bedwars.BlockPlacementController.blockPlacer
					if store.hand.toolType == 'block' and blockPlacer then
						if (workspace:GetServerTimeNow() - bedwars.BlockCpsController.lastPlaceTimestamp) >= ((1 / 12) * 0.5) then
							local mouseinfo = blockPlacer.clientManager:getBlockSelector():getMouseInfo(0)
							if mouseinfo and mouseinfo.placementPosition == mouseinfo.placementPosition then
								task.spawn(blockPlacer.placeBlock, blockPlacer, mouseinfo.placementPosition)
							end
						end
					elseif store.hand.toolType == 'sword' then
						bedwars.SwordController:swingSwordAtMouse(0.39)
					end
				end
	
				task.wait(1 / (store.hand.toolType == 'block' and BlockCPS or CPS).GetRandomValue())
			until not AutoClicker.Enabled
		end)
	end
	
	AutoClicker = vape.Categories.Combat:CreateModule({
		Name = 'AutoClicker',
		Function = function(callback)
			if callback then
				AutoClicker:Clean(inputService.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						AutoClick()
					end
				end))
	
				AutoClicker:Clean(inputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 and Thread then
						task.cancel(Thread)
						Thread = nil
					end
				end))
	
				if inputService.TouchEnabled then
					pcall(function()
						AutoClicker:Clean(lplr.PlayerGui.MobileUI['2'].MouseButton1Down:Connect(AutoClick))
						AutoClicker:Clean(lplr.PlayerGui.MobileUI['2'].MouseButton1Up:Connect(function()
							if Thread then
								task.cancel(Thread)
								Thread = nil
							end
						end))
					end)
				end
			else
				if Thread then
					task.cancel(Thread)
					Thread = nil
				end
			end
		end,
		Tooltip = 'Hold attack button to automatically click'
	})
	CPS = AutoClicker:CreateTwoSlider({
		Name = 'CPS',
		Min = 1,
		Max = 9,
		DefaultMin = 7,
		DefaultMax = 7
	})
	AutoClicker:CreateToggle({
		Name = 'Place Blocks',
		Default = true,
		Function = function(callback)
			if BlockCPS.Object then
				BlockCPS.Object.Visible = callback
			end
		end
	})
	BlockCPS = AutoClicker:CreateTwoSlider({
		Name = 'Block CPS',
		Min = 1,
		Max = 12,
		DefaultMin = 12,
		DefaultMax = 12,
		Darker = true
	})
end)
	
run(function()
	local old
	local Delay
	local NoClickDelay
	NoClickDelay = vape.Categories.Combat:CreateModule({
		Name = 'NoClickDelay',
		Function = function(callback)
			if callback then
				old = bedwars.SwordController.isClickingTooFast
				bedwars.SwordController.isClickingTooFast = function(self)
				if Delay.Value == 0 then
					Delay.Value = os.clock()
				else
					Delay.Value = Delay.Value
				end
				
					self.lastSwing = Delay.Value
					return false
				end
			else
				bedwars.SwordController.isClickingTooFast = old
			end
		end,
		Tooltip = 'Remove the CPS cap'
	})
	Delay  = NoClickDelay:CreateSlider({
		Name = "Delay",
		Min = 0,
		Max = 1,
		Decimal = 100,
	})
end)
	
run(function()
	local Attack
	local Place
	local Mine


	Reach = vape.Categories.Combat:CreateModule({
		Name = 'Reach',
		Function = function(callback)
			bedwars.CombatConstant.RAYCAST_SWORD_CHARACTER_DISTANCE = callback and Attack.Value + 2 or 14.4
		end,
		Tooltip = 'Extends reach to attack, placing, and mining'
	})
	Attack = Reach:CreateSlider({
		Name = 'Attack Range',
		Min = 0,
		Max = 20,
		Default = 18,
		Function = function(val)
			if Reach.Enabled then
				bedwars.CombatConstant.RAYCAST_SWORD_CHARACTER_DISTANCE = val + 2
			end
		end,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	Mine = Reach:CreateSlider({
		Name = 'Mine Range',
		Min = 0,
		Max = 20,
		Default = 18,
		Function = function(val)
			if Reach.Enabled then
				bedwars.CombatConstant.RAYCAST_SWORD_CHARACTER_DISTANCE = val + 2
			end
		end,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	Place = Reach:CreateSlider({
		Name = 'Place Range',
		Min = 0,
		Max = 20,
		Default = 18,
		Function = function(val)
			if Reach.Enabled then
				bedwars.CombatConstant.RAYCAST_SWORD_CHARACTER_DISTANCE = val + 2
			end
		end,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
end)
	
run(function()
	local Sprint
	local old
	
	Sprint = vape.Categories.Combat:CreateModule({
		Name = 'Sprint',
		Function = function(callback)
			if callback then
				if inputService.TouchEnabled then 
					pcall(function() 
						lplr.PlayerGui.MobileUI['4'].Visible = false 
					end) 
				end
				old = bedwars.SprintController.stopSprinting
				bedwars.SprintController.stopSprinting = function(...)
					local call = old(...)
					bedwars.SprintController:startSprinting()
					return call
				end
				Sprint:Clean(entitylib.Events.LocalAdded:Connect(function() 
					task.delay(0.1, function() 
						bedwars.SprintController:stopSprinting() 
					end) 
				end))
				bedwars.SprintController:stopSprinting()
			else
				if inputService.TouchEnabled then 
					pcall(function() 
						lplr.PlayerGui.MobileUI['4'].Visible = true 
					end) 
				end
				bedwars.SprintController.stopSprinting = old
				bedwars.SprintController:stopSprinting()
			end
		end,
		Tooltip = 'Sets your sprinting to true.'
	})
end)
	
run(function()
	local TriggerBot
	local CPS
	local rayParams = RaycastParams.new()
	
	TriggerBot = vape.Categories.Combat:CreateModule({
		Name = 'TriggerBot',
		Function = function(callback)
			if callback then
				repeat
					local doAttack
					if not bedwars.AppController:isLayerOpen(bedwars.UILayers.MAIN) then
						if entitylib.isAlive and store.hand.toolType == 'sword' and bedwars.DaoController.chargingMaid == nil then
							local attackRange = bedwars.ItemMeta[store.hand.tool.Name].sword.attackRange
							rayParams.FilterDescendantsInstances = {lplr.Character}
	
							local unit = lplr:GetMouse().UnitRay
							local localPos = entitylib.character.RootPart.Position
							local rayRange = (attackRange or 14.4)
							local ray = bedwars.QueryUtil:raycast(unit.Origin, unit.Direction * 200, rayParams)
							if ray and (localPos - ray.Instance.Position).Magnitude <= rayRange then
								local limit = (attackRange)
								for _, ent in entitylib.List do
									doAttack = ent.Targetable and ray.Instance:IsDescendantOf(ent.Character) and (localPos - ent.RootPart.Position).Magnitude <= rayRange
									if doAttack then
										break
									end
								end
							end
	
							doAttack = doAttack or bedwars.SwordController:getTargetInRegion(attackRange or 3.8 * 3, 0)
							if doAttack then
								bedwars.SwordController:swingSwordAtMouse()
							end
						end
					end
	
					task.wait(doAttack and 1 / CPS.GetRandomValue() or 0.016)
				until not TriggerBot.Enabled
			end
		end,
		Tooltip = 'Automatically swings when hovering over a entity'
	})
	CPS = TriggerBot:CreateTwoSlider({
		Name = 'CPS',
		Min = 1,
		Max = 9,
		DefaultMin = 7,
		DefaultMax = 7
	})
end)
	
run(function()
	local Velocity
	local Horizontal
	local Vertical
	local Chance
	local TargetCheck
	local rand, old = Random.new()
	
	Velocity = vape.Categories.Combat:CreateModule({
		Name = 'Velocity',
		Function = function(callback)
			if callback then
				old = bedwars.KnockbackUtil.applyKnockback
				bedwars.KnockbackUtil.applyKnockback = function(root, mass, dir, knockback, ...)
					if rand:NextNumber(0, 100) > Chance.Value then return end
					local check = (not TargetCheck.Enabled) or entitylib.EntityPosition({
						Range = 50,
						Part = 'RootPart',
						Players = true
					})
	
					if check then
						knockback = knockback or {}
						if Horizontal.Value == 0 and Vertical.Value == 0 then return end
						knockback.horizontal = (knockback.horizontal or 1) * (Horizontal.Value / 100)
						knockback.vertical = (knockback.vertical or 1) * (Vertical.Value / 100)
					end
					
					return old(root, mass, dir, knockback, ...)
				end
			else
				bedwars.KnockbackUtil.applyKnockback = old
			end
		end,
		Tooltip = 'Reduces knockback taken'
	})
	Horizontal = Velocity:CreateSlider({
		Name = 'Horizontal',
		Min = 0,
		Max = 100,
		Default = 0,
		Suffix = '%'
	})
	Vertical = Velocity:CreateSlider({
		Name = 'Vertical',
		Min = 0,
		Max = 100,
		Default = 0,
		Suffix = '%'
	})
	Chance = Velocity:CreateSlider({
		Name = 'Chance',
		Min = 0,
		Max = 100,
		Default = 100,
		Suffix = '%'
	})
	TargetCheck = Velocity:CreateToggle({Name = 'Only when targeting'})
end)
	
local AntiFallDirection
run(function()
	local AntiFall
	local Mode
	local Material
	local Color
	local rayCheck = RaycastParams.new()
	rayCheck.RespectCanCollide = true

	local function getLowGround()
		local mag = math.huge
		for _, pos in bedwars.BlockController:getStore():getAllBlockPositions() do
			pos = pos * 3
			if pos.Y < mag and not getPlacedBlock(pos + Vector3.new(0, 3, 0)) then
				mag = pos.Y
			end
		end
		return mag
	end

	AntiFall = vape.Categories.Blatant:CreateModule({
		Name = 'AntiFall',
		Function = function(callback)
			if callback then
				repeat task.wait(0.1) until store.matchState ~= 0 or (not AntiFall.Enabled)
				if not AntiFall.Enabled then return end

				local pos, debounce = getLowGround(), tick()
				if pos ~= math.huge then
					AntiFallPart = Instance.new('Part')
					AntiFallPart.Size = Vector3.new(10000, 1, 10000)
					AntiFallPart.Transparency = 1 - Color.Opacity
					AntiFallPart.Material = Enum.Material[Material.Value]
					AntiFallPart.Color = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
					AntiFallPart.Position = Vector3.new(0, pos - 2, 0)
					AntiFallPart.CanCollide = Mode.Value == 'Collide'
					AntiFallPart.Anchored = true
					AntiFallPart.CanQuery = false
					AntiFallPart.Parent = workspace
					AntiFall:Clean(AntiFallPart)
					AntiFall:Clean(AntiFallPart.Touched:Connect(function(touched)
						if touched.Parent == lplr.Character and entitylib.isAlive and debounce < tick() then
							debounce = tick() + 0.1
							if Mode.Value == 'Normal' then
								local top = getNearGround()
								if top then
									local lastTeleport = lplr:GetAttribute('LastTeleported')
									local connection
									connection = runService.PreSimulation:Connect(function()
										if vape.Modules.Fly.Enabled or vape.Modules.InfiniteFly.Enabled or vape.Modules.LongJump.Enabled then
											connection:Disconnect()
											AntiFallDirection = nil
											return
										end

										if entitylib.isAlive and lplr:GetAttribute('LastTeleported') == lastTeleport then
											local delta = ((top - entitylib.character.RootPart.Position) * Vector3.new(1, 0, 1))
											local root = entitylib.character.RootPart
											AntiFallDirection = delta.Unit == delta.Unit and delta.Unit or Vector3.zero
											root.Velocity *= Vector3.new(1, 0, 1)
											rayCheck.FilterDescendantsInstances = {gameCamera, lplr.Character}
											rayCheck.CollisionGroup = root.CollisionGroup

											local ray = workspace:Raycast(root.Position, AntiFallDirection, rayCheck)
											if ray then
												for _ = 1, 10 do
													local dpos = roundPos(ray.Position + ray.Normal * 1.5) + Vector3.new(0, 3, 0)
													if not getPlacedBlock(dpos) then
														top = Vector3.new(top.X, pos.Y, top.Z)
														break
													end
												end
											end

											root.CFrame += Vector3.new(0, top.Y - root.Position.Y, 0)
											if not frictionTable.Speed then
												root.AssemblyLinearVelocity = (AntiFallDirection * getSpeed()) + Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
											end

											if delta.Magnitude < 1 then
												connection:Disconnect()
												AntiFallDirection = nil
											end
										else
											connection:Disconnect()
											AntiFallDirection = nil
										end
									end)
									AntiFall:Clean(connection)
								end
							elseif Mode.Value == 'Velocity' then
								entitylib.character.RootPart.Velocity = Vector3.new(entitylib.character.RootPart.Velocity.X, 100, entitylib.character.RootPart.Velocity.Z)
							end
						end
					end))
				end
			else
				AntiFallDirection = nil
			end
		end,
		Tooltip = 'Help\'s you with your Parkinson\'s\nPrevents you from falling into the void.'
	})
	Mode = AntiFall:CreateDropdown({
		Name = 'Move Mode',
		List = {'Normal', 'Collide', 'Velocity'},
		Function = function(val)
			if AntiFallPart then
				AntiFallPart.CanCollide = val == 'Collide'
			end
		end,
	Tooltip = 'Normal - Smoothly moves you towards the nearest safe point\nVelocity - Launches you upward after touching\nCollide - Allows you to walk on the part'
	})
	local materials = {'ForceField'}
	for _, v in Enum.Material:GetEnumItems() do
		if v.Name ~= 'ForceField' then
			table.insert(materials, v.Name)
		end
	end
	Material = AntiFall:CreateDropdown({
		Name = 'Material',
		List = materials,
		Function = function(val)
			if AntiFallPart then
				AntiFallPart.Material = Enum.Material[val]
			end
		end
	})
	Color = AntiFall:CreateColorSlider({
		Name = 'Color',
		DefaultOpacity = 0.5,
		Function = function(h, s, v, o)
			if AntiFallPart then
				AntiFallPart.Color = Color3.fromHSV(h, s, v)
				AntiFallPart.Transparency = 1 - o
			end
		end
	})
end)
	
run(function()
	local FastBreak
	local Time
	
	FastBreak = vape.Categories.Blatant:CreateModule({
		Name = 'FastBreak',
		Function = function(callback)
			if callback then
				repeat
					bedwars.BlockBreakController.blockBreaker:setCooldown(Time.Value)
					task.wait(0.1)
				until not FastBreak.Enabled
			else
				bedwars.BlockBreakController.blockBreaker:setCooldown(0.3)
			end
		end,
		Tooltip = 'Decreases block hit cooldown'
	})
	Time = FastBreak:CreateSlider({
		Name = 'Break speed',
		Min = 0,
		Max = 0.25,
		Default = 0.25,
		Decimal = 100,
		Suffix = 'seconds'
	})
end)
	
local LongJump

	
run(function()
	local Mode
	local Expand
	local objects, set = {}
	
	local function createHitbox(ent)
		if ent.Targetable and ent.Player then
			local hitbox = Instance.new('Part')
			hitbox.Size = Vector3.new(3, 6, 3) + Vector3.one * (Expand.Value / 5)
			hitbox.Position = ent.RootPart.Position
			hitbox.CanCollide = false
			hitbox.Massless = true
			hitbox.Transparency = 1
			hitbox.Parent = ent.Character
			local weld = Instance.new('Motor6D')
			weld.Part0 = hitbox
			weld.Part1 = ent.RootPart
			weld.Parent = hitbox
			objects[ent] = hitbox
		end
	end
	
	HitBoxes = vape.Categories.Blatant:CreateModule({
		Name = 'HitBoxes',
		Function = function(callback)
			if callback then
				if Mode.Value == 'Sword' then
					debug.setconstant(bedwars.SwordController.swingSwordInRegion, 6, (Expand.Value / 3))
					set = true
				else
					HitBoxes:Clean(entitylib.Events.EntityAdded:Connect(createHitbox))
					HitBoxes:Clean(entitylib.Events.EntityRemoving:Connect(function(ent)
						if objects[ent] then
							objects[ent]:Destroy()
							objects[ent] = nil
						end
					end))
					for _, ent in entitylib.List do
						createHitbox(ent)
					end
				end
			else
				if set then
					debug.setconstant(bedwars.SwordController.swingSwordInRegion, 6, 3.8)
					set = nil
				end
				for _, part in objects do
					part:Destroy()
				end
				table.clear(objects)
			end
		end,
		Tooltip = 'Expands attack hitbox'
	})
	Mode = HitBoxes:CreateDropdown({
		Name = 'Mode',
		List = {'Sword', 'Player'},
		Function = function()
			if HitBoxes.Enabled then
				HitBoxes:Toggle(false)
				HitBoxes:Toggle(true)
			end
		end,
		Tooltip = 'Sword - Increases the range around you to hit entities\nPlayer - Increases the players hitbox'
	})
	Expand = HitBoxes:CreateSlider({
		Name = 'Expand amount',
		Min = 0,
		Max = 14.4,
		Default = 14.4,
		Decimal = 10,
		Function = function(val)
			if HitBoxes.Enabled then
				if Mode.Value == 'Sword' then
					debug.setconstant(bedwars.SwordController.swingSwordInRegion, 6, (val / 3))
				else
					for _, part in objects do
						part.Size = Vector3.new(3, 6, 3) + Vector3.one * (val / 5)
					end
				end
			end
		end,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
end)
	
run(function()
	vape.Categories.Blatant:CreateModule({
		Name = 'KeepSprint',
		Function = function(callback)
			debug.setconstant(bedwars.SprintController.startSprinting, 5, callback and 'blockSprinting' or 'blockSprint')
			bedwars.SprintController:stopSprinting()
		end,
		Tooltip = 'Lets you sprint with a speed potion.'
	})
end)

local Attacking

																	
	
run(function()
	local Value
	local CameraDir
	local start
	local JumpTick, JumpSpeed, Direction = tick(), 0
	local projectileRemote = {InvokeServer = function() end}
	task.spawn(function()
		projectileRemote = bedwars.Client:Get(remotes.FireProjectile).instance
	end)
	
	local function launchProjectile(item, pos, proj, speed, dir)
		if not pos then return end
	
		pos = pos - dir * 0.1
		local shootPosition = (CFrame.lookAlong(pos, Vector3.new(0, -speed, 0)) * CFrame.new(Vector3.new(-bedwars.BowConstantsTable.RelX, -bedwars.BowConstantsTable.RelY, -bedwars.BowConstantsTable.RelZ)))
		switchItem(item.tool, 0)
		task.wait(0.1)
		bedwars.ProjectileController:createLocalProjectile(bedwars.ProjectileMeta[proj], proj, proj, shootPosition.Position, '', shootPosition.LookVector * speed, {drawDurationSeconds = 1})
		if projectileRemote:InvokeServer(item.tool, proj, proj, shootPosition.Position, pos, shootPosition.LookVector * speed, httpService:GenerateGUID(true), {drawDurationSeconds = 1}, workspace:GetServerTimeNow() - 0.045) then
			local shoot = bedwars.ItemMeta[item.itemType].projectileSource.launchSound
			shoot = shoot and shoot[math.random(1, #shoot)] or nil
			if shoot then
				bedwars.SoundManager:playSound(shoot)
			end
		end
	end
	
	local LongJumpMethods = {
		cannon = function(_, pos, dir)
			pos = pos - Vector3.new(0, (entitylib.character.HipHeight + (entitylib.character.RootPart.Size.Y / 2)) - 3, 0)
			local rounded = Vector3.new(math.round(pos.X / 3) * 3, math.round(pos.Y / 3) * 3, math.round(pos.Z / 3) * 3)
			bedwars.placeBlock(rounded, 'cannon', false)
	
			task.delay(0, function()
				local block, blockpos = getPlacedBlock(rounded)
				if block and block.Name == 'cannon' and (entitylib.character.RootPart.Position - block.Position).Magnitude < 20 then
					local breaktype = bedwars.ItemMeta[block.Name].block.breakType
					local tool = store.tools[breaktype]
					if tool then
						switchItem(tool.tool)
					end
	
					bedwars.Client:Get(remotes.CannonAim):SendToServer({
						cannonBlockPos = blockpos,
						lookVector = dir
					})
	
					local broken = 0.1
					if bedwars.BlockController:calculateBlockDamage(lplr, {blockPosition = blockpos}) < block:GetAttribute('Health') then
						broken = 0.4
						bedwars.breakBlock(block, true, true)
					end
	
					task.delay(broken, function()
						for _ = 1, 3 do
							local call = bedwars.Client:Get(remotes.CannonLaunch):CallServer({cannonBlockPos = blockpos})
							if call then
								bedwars.breakBlock(block, true, true)
								JumpSpeed = 5.25 * Value.Value
								JumpTick = tick() + 2.3
								Direction = Vector3.new(dir.X, 0, dir.Z).Unit
								break
							end
							task.wait(0.1)
						end
					end)
																																				LongJump:Toggle()
				end
			end)
		end,
		cat = function(_, _, dir)
			LongJump:Clean(vapeEvents.CatPounce.Event:Connect(function()
				JumpSpeed = 4 * Value.Value
				JumpTick = tick() + 2.5
				Direction = Vector3.new(dir.X, 0, dir.Z).Unit
				entitylib.character.RootPart.Velocity = Vector3.zero
			end))
	
			if not bedwars.AbilityController:canUseAbility('CAT_POUNCE') then
				repeat task.wait(0.1) until bedwars.AbilityController:canUseAbility('CAT_POUNCE') or not LongJump.Enabled
			end
	
			if bedwars.AbilityController:canUseAbility('CAT_POUNCE') and LongJump.Enabled then
				bedwars.AbilityController:useAbility('CAT_POUNCE')
			end
																																																																					LongJump:Toggle()
LongJump:Toggle()
		end,
		fireball = function(item, pos, dir)
			launchProjectile(item, pos, 'fireball', 60, dir)
																																																																					LongJump:Toggle()
LongJump:Toggle()
		end,
		grappling_hook = function(item, pos, dir)
			launchProjectile(item, pos, 'grappling_hook_projectile', 140, dir)
																																	LongJump:Toggle()
		end,
		jade_hammer = function(item, _, dir)
			if not bedwars.AbilityController:canUseAbility(item.itemType..'_jump') then
				repeat task.wait(0.1) until bedwars.AbilityController:canUseAbility(item.itemType..'_jump') or not LongJump.Enabled
			end
	
			if bedwars.AbilityController:canUseAbility(item.itemType..'_jump') and LongJump.Enabled then
				bedwars.AbilityController:useAbility(item.itemType..'_jump')
				JumpSpeed = 1.4 * Value.Value
				JumpTick = tick() + 2.5
				Direction = Vector3.new(dir.X, 0, dir.Z).Unit
			end
																																	LongJump:Toggle()
		end,
		tnt = function(item, pos, dir)
			pos = pos - Vector3.new(0, (entitylib.character.HipHeight + (entitylib.character.RootPart.Size.Y / 2)) - 3, 0)
			local rounded = Vector3.new(math.round(pos.X / 3) * 3, math.round(pos.Y / 3) * 3, math.round(pos.Z / 3) * 3)
			start = Vector3.new(rounded.X, start.Y, rounded.Z) + (dir * (item.itemType == 'pirate_gunpowder_barrel' and 2.6 or 0.2))
			bedwars.placeBlock(rounded, item.itemType, false)
																																	LongJump:Toggle()
		end,
		wood_dao = function(item, pos, dir)
			if (lplr.Character:GetAttribute('CanDashNext') or 0) > workspace:GetServerTimeNow() or not bedwars.AbilityController:canUseAbility('dash') then
				repeat task.wait(0.1) until (lplr.Character:GetAttribute('CanDashNext') or 0) < workspace:GetServerTimeNow() and bedwars.AbilityController:canUseAbility('dash') or not LongJump.Enabled
			end
	
			if LongJump.Enabled then
				bedwars.SwordController.lastAttack = workspace:GetServerTimeNow()
				switchItem(item.tool, 0.1)
				replicatedStorage['events-@easy-games/game-core:shared/game-core-networking@getEvents.Events'].useAbility:FireServer('dash', {
					direction = dir,
					origin = pos,
					weapon = item.itemType
				})
				JumpSpeed = 4.5 * Value.Value
				JumpTick = tick() + 2.4
				Direction = Vector3.new(dir.X, 0, dir.Z).Unit


			
			end
																																	LongJump:Toggle()
		end
	}
	for _, v in {'stone_dao', 'iron_dao', 'diamond_dao', 'emerald_dao'} do
		LongJumpMethods[v] = LongJumpMethods.wood_dao
	end
	LongJumpMethods.void_axe = LongJumpMethods.jade_hammer
	LongJumpMethods.siege_tnt = LongJumpMethods.tnt
	LongJumpMethods.pirate_gunpowder_barrel = LongJumpMethods.tnt
	
	LongJump = vape.Categories.Blatant:CreateModule({
		Name = 'LongJump',
		Function = function(callback)
			frictionTable.LongJump = callback or nil
			updateVelocity()
			if callback then
				LongJump:Clean(vapeEvents.EntityDamageEvent.Event:Connect(function(damageTable)
					if damageTable.entityInstance == lplr.Character and damageTable.fromEntity == lplr.Character and (not damageTable.knockbackMultiplier or not damageTable.knockbackMultiplier.disabled) then
						local knockbackBoost = bedwars.KnockbackUtil.calculateKnockbackVelocity(Vector3.one, 1, {
							vertical = 0,
							horizontal = (damageTable.knockbackMultiplier and damageTable.knockbackMultiplier.horizontal or 1)
						}).Magnitude * 1.1
	
						if knockbackBoost >= JumpSpeed then
							local pos = damageTable.fromPosition and Vector3.new(damageTable.fromPosition.X, damageTable.fromPosition.Y, damageTable.fromPosition.Z) or damageTable.fromEntity and damageTable.fromEntity.PrimaryPart.Position
							if not pos then return end
							local vec = (entitylib.character.RootPart.Position - pos)
							JumpSpeed = knockbackBoost
							JumpTick = tick() + 2.5
							Direction = Vector3.new(vec.X, 0, vec.Z).Unit
						end
					end
				end))
				LongJump:Clean(vapeEvents.GrapplingHookFunctions.Event:Connect(function(dataTable)
					if dataTable.hookFunction == 'PLAYER_IN_TRANSIT' then
						local vec = entitylib.character.RootPart.CFrame.LookVector
						JumpSpeed = 2.5 * Value.Value
						JumpTick = tick() + 2.5
						Direction = Vector3.new(vec.X, 0, vec.Z).Unit
					end
				end))
	
				start = entitylib.isAlive and entitylib.character.RootPart.Position or nil
				LongJump:Clean(runService.PreSimulation:Connect(function(dt)
					local root = entitylib.isAlive and entitylib.character.RootPart or nil
	
					if root and isnetworkowner(root) then
						if JumpTick > tick() then
							root.AssemblyLinearVelocity = Direction * (getSpeed() + ((JumpTick - tick()) > 1.1 and JumpSpeed or 0)) + Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
							if entitylib.character.Humanoid.FloorMaterial == Enum.Material.Air and not start then
								root.AssemblyLinearVelocity += Vector3.new(0, dt * (workspace.Gravity - 23), 0)
							else
								root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 15, root.AssemblyLinearVelocity.Z)
							end
							start = nil
						else
							if start then
								root.CFrame = CFrame.lookAlong(start, root.CFrame.LookVector)
							end
							root.AssemblyLinearVelocity = Vector3.zero
							JumpSpeed = 0
						end
					else
						start = nil
					end
				end))
	
				if store.hand and LongJumpMethods[store.hand.tool.Name] then
					task.spawn(LongJumpMethods[store.hand.tool.Name], getItem(store.hand.tool.Name), start, (CameraDir.Enabled and gameCamera or entitylib.character.RootPart).CFrame.LookVector)
					return
				end
	
				for i, v in LongJumpMethods do
					local item = getItem(i)
					if item or store.equippedKit == i then
						task.spawn(v, item, start, (CameraDir.Enabled and gameCamera or entitylib.character.RootPart).CFrame.LookVector)
						break
					end
				end
			else
				JumpTick = tick()
				Direction = nil
				JumpSpeed = 0
			end
		end,
		ExtraText = function()
			return 'Heatseeker'
		end,
		Tooltip = 'Lets you jump farther'
	})
	Value = LongJump:CreateSlider({
		Name = 'Speed',
		Min = 1,
		Max = 37,
		Default = 37,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	CameraDir = LongJump:CreateToggle({
		Name = 'Camera Direction'
	})
end)
	
run(function()
	local SoftenDamage
	local NoFall
	local Mode
	local rayParams = RaycastParams.new()
	local groundHit

	task.spawn(function()
		groundHit = bedwars.Client:Get(remotes.GroundHit).instance
	end)

	NoFall = vape.Categories.Blatant:CreateModule({
		Name = 'NoFall',
		Function = function(callback)
			if callback then
				local tracked = 0
				if Mode.Value == 'Gravity' then
					local extraGravity = 0
					NoFall:Clean(runService.PreSimulation:Connect(function(dt)
						if entitylib.isAlive then
							local root = entitylib.character.RootPart
							if root.AssemblyLinearVelocity.Y < -85 then
								rayParams.FilterDescendantsInstances = {lplr.Character, gameCamera}
								rayParams.CollisionGroup = root.CollisionGroup

								local rootSize = root.Size.Y / 2 + entitylib.character.HipHeight
								local ray = workspace:Blockcast(root.CFrame, Vector3.new(3, 3, 3), Vector3.new(0, (tracked * 0.1) - rootSize, 0), rayParams)
								if not ray then
									local fallY = root.AssemblyLinearVelocity.Y
									if SoftenDamage.Enabled then
										fallY = -76
									else
										fallY = -86
									end
									root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, fallY, root.AssemblyLinearVelocity.Z)
									root.CFrame += Vector3.new(0, extraGravity * dt, 0)
									extraGravity += -workspace.Gravity * dt
								end
							else
								extraGravity = 0
							end
						end
					end))
				else
					repeat
						if entitylib.isAlive then
							local root = entitylib.character.RootPart
							tracked = entitylib.character.Humanoid.FloorMaterial == Enum.Material.Air and math.min(tracked, root.AssemblyLinearVelocity.Y) or 0

							if tracked < -85 then
								if Mode.Value == 'Packet' then
									if SoftenDamage.Enabled then
										groundHit:FireServer(nil, Vector3.new(0, tracked * 1.05, 0), workspace:GetServerTimeNow())
									else
										groundHit:FireServer(nil, Vector3.new(0, tracked, 0), workspace:GetServerTimeNow())
									end

								else
									rayParams.FilterDescendantsInstances = {lplr.Character, gameCamera}
									rayParams.CollisionGroup = root.CollisionGroup

									local rootSize = root.Size.Y / 2 + entitylib.character.HipHeight
									if Mode.Value == 'Teleport' then
										local ray = workspace:Blockcast(root.CFrame, Vector3.new(3, 3, 3), Vector3.new(0, -1000, 0), rayParams)
										if ray then
											root.CFrame -= Vector3.new(0, root.Position.Y - (ray.Position.Y + rootSize), 0)
										end
									else
										local ray = workspace:Blockcast(root.CFrame, Vector3.new(3, 3, 3), Vector3.new(0, (tracked * 0.1) - rootSize, 0), rayParams)
										if ray then
											tracked = 0
											local newY = SoftenDamage.Enabled and -75 or -80
											root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, newY, root.AssemblyLinearVelocity.Z)
										end
									end
								end
							end
						end

						task.wait(0.03)
					until not NoFall.Enabled
				end
			end
		end,
		Tooltip = 'Prevents or reduces fall damage.'
	})

	Mode = NoFall:CreateDropdown({
		Name = 'Mode',
		List = {'Packet', 'Gravity', 'Teleport', 'Bounce'},
		Function = function()
			if NoFall.Enabled then
				NoFall:Toggle()
				NoFall:Toggle()
			end
		end
	})

	SoftenDamage = NoFall:CreateToggle({
		Name = 'Soften Damage',
		Default = true,
		Tooltip = 'Reduces fall velocity instead of fully negating it.'
	})
end)

																														
	
run(function()
	local old
	
	vape.Categories.Blatant:CreateModule({
		Name = 'NoSlowdown',
		Function = function(callback)
			local modifier = bedwars.SprintController:getMovementStatusModifier()
			if callback then
				old = modifier.addModifier
				modifier.addModifier = function(self, tab)
					if tab.moveSpeedMultiplier then
						tab.moveSpeedMultiplier = math.max(tab.moveSpeedMultiplier, 1)
					end
					return old(self, tab)
				end
	
				for i in modifier.modifiers do
					if (i.moveSpeedMultiplier or 1) < 1 then
						modifier:removeModifier(i)
					end
				end
			else
				modifier.addModifier = old
				old = nil
			end
		end,
		Tooltip = 'Prevents slowing down when using items.'
	})
end)
	
run(function()
	local SilentAim = {Enabled = true}
	local TargetPart
	local Targets
	local FOV
	local OtherProjectiles
	local Blacklist

	local rayCheck = RaycastParams.new()
	rayCheck.FilterType = Enum.RaycastFilterType.Include
	rayCheck.FilterDescendantsInstances = {workspace:FindFirstChild('Map')}
	local old
	
	local ProjectileAimbot; ProjectileAimbot = vape.Categories.Blatant:CreateModule({
		Name = 'Projectile Aimbot',
		Function = function(callback)
			if callback then
				local newpos = nil
				local canshoot = os.clock()
				
				old = bedwars.ProjectileController.calculateImportantLaunchValues
				bedwars.ProjectileController.calculateImportantLaunchValues = function(...)	
					local self, projmeta, worldmeta, origin, shootpos = ...
					local plr = entitylib.EntityMouse({
						Part = 'RootPart',
						Range = FOV.Value,
						Players = Targets.Players.Enabled,
						NPCs = Targets.NPCs.Enabled,
						Wallcheck = Targets.Walls.Enabled,
						Origin = entitylib.isAlive and (shootpos or entitylib.character.RootPart.Position) or Vector3.zero
					})
	
					if plr then
						local pos = shootpos or self:getLaunchPosition(origin)
						if not pos then
							return old(...)
						end
	
						if (not OtherProjectiles.Enabled) and not projmeta.projectile:find('arrow') then
							return old(...)
						end

						if table.find(Blacklist.ListEnabled, projmeta.projectile) then
							return old(...)
						end
	
						local meta = projmeta:getProjectileMeta()
						local lifetime = (worldmeta and meta.predictionLifetimeSec or meta.lifetimeSec or 3)
						local gravity = (meta.gravitationalAcceleration or 196.2) * projmeta.gravityMultiplier
						local projSpeed = (meta.launchVelocity or 100) 
						local offsetpos = pos + (projmeta.projectile == 'owl_projectile' and Vector3.zero or projmeta.fromPositionOffset)
						local balloons = plr.Character:GetAttribute('InflatedBalloons')
						local playerGravity = workspace.Gravity
	
						if balloons and balloons > 0 then
							playerGravity = (workspace.Gravity * (1 - ((balloons >= 4 and 1.2 or balloons >= 3 and 1 or 0.975))))
						end
	
						if plr.Character.PrimaryPart:FindFirstChild('rbxassetid://8200754399') then
							playerGravity = 6
						end

						if not plr.NPC and plr.Player:GetAttribute('IsOwlTarget') then
							for _, owl in collectionService:GetTagged('Owl') do
								if owl:GetAttribute('Target') == plr.Player.UserId and owl:GetAttribute('Status') == 2 then
									playerGravity = 0
								end
							end
						end
	
						local newlook = CFrame.new(offsetpos, plr[TargetPart.Value].Position) * CFrame.new(projmeta.projectile == 'owl_projectile' and Vector3.zero or Vector3.new(bedwars.BowConstantsTable.RelX, bedwars.BowConstantsTable.RelY, bedwars.BowConstantsTable.RelZ))
						local calc = prediction.SolveTrajectory(newlook.p, projSpeed, gravity, plr[TargetPart.Value].Position, projmeta.projectile == 'telepearl' and Vector3.zero or plr[TargetPart.Value].Velocity, playerGravity, plr.HipHeight, plr.Jumping and 42.6 or nil, rayCheck, plr.Humanoid.MoveDirection ~= Vector3.zero, lplr:GetNetworkPing())
						if calc then
							targetinfo.Targets[plr] = os.clock() + 1
							if not SilentAim.Enabled then
								newpos = calc - Vector3.new(0, 4, 0)
								canshoot = os.clock() + 0.1
								return old(...)
							end
							return {
								initialVelocity = CFrame.new(newlook.Position, calc).LookVector * projSpeed,
								positionFrom = offsetpos,
								deltaT = lifetime,
								gravitationalAcceleration = gravity,
								drawDurationSeconds = 5
							}
						end
					end
	
					return old(...)
				end

				ProjectileAimbot:Clean(runService.PreRender:Connect(function(delta)
					if canshoot > os.clock() and newpos and mousemoverel and not SilentAim.Enabled and entitylib.EntityMouse({
						Part = 'RootPart',
						Range = FOV.Value,
						Players = Targets.Players.Enabled,
						NPCs = Targets.NPCs.Enabled,
						Wallcheck = Targets.Walls.Enabled
					}) then
						local pos, vis = workspace.CurrentCamera:WorldToViewportPoint(newpos)

						if vis and isrbxactive() then
							pos = (Vector2.new(pos.X, pos.Y) - game.UserInputService:GetMouseLocation()) * (100 * delta / 3)
							mousemoverel(pos.X, pos.Y)
						end
					end
				end))
			else
				bedwars.ProjectileController.calculateImportantLaunchValues = old
			end
		end,
		Tooltip = 'Silently adjusts your aim towards the enemy'
	})
	Targets = ProjectileAimbot:CreateTargets({
		Players = true,
		Walls = true
	})
	TargetPart = ProjectileAimbot:CreateDropdown({
		Name = 'Part',
		List = {'RootPart', 'Head'}
	})
	FOV = ProjectileAimbot:CreateSlider({
		Name = 'FOV',
		Min = 1,
		Max = 1000,
		Default = 1000
	})
	--SilentAim = ProjectileAimbot:CreateToggle({Name = 'Silent aim', Default = true})
	OtherProjectiles = ProjectileAimbot:CreateToggle({
		Name = 'Other Projectiles',
		Default = true,
		Function = function(call)
			if Blacklist then
				Blacklist.Object.Visible = call
			end
		end
	})
	Blacklist = ProjectileAimbot:CreateTextList({
		Name = 'Blacklist',
		Darker = true,
		Default = {'telepearl'}
	})
end)
	
local ProjectileAura
local Targets
local Range
local List
local ReverseList
local LimitItem
local FireWait
local AutoSwitch
local IgnoreList

local rayCheck = RaycastParams.new()
rayCheck.FilterType = Enum.RaycastFilterType.Include
rayCheck.FilterDescendantsInstances = {workspace:FindFirstChild('Map')}

local projectileRemote = {InvokeServer = function() end}
local FireDelays = {}
local normalMode = true -- Default mode is normal

-- Add ToolCheck support
local function isToolCheckEnabled()
    -- Check if ToolCheck module exists and is enabled
    local toolCheck = vape.Modules.ToolCheck
    return toolCheck and toolCheck.Enabled
end

-- Enhanced tool state tracking with ToolCheck support
local toolState = {
    previous = {
        tool = nil,
        slot = nil,
        switchTime = 0
    },
    switching = false,
    cooldown = 0.3,
    manualSwitchOccurred = false,
    toolCheckActive = false  -- Track if ToolCheck is preventing switches
}

-- Function to detect manual switches
local function setupManualSwitchDetection()
    local lastAutoSwitchTime = 0
    
    -- Monitor inventory changes
    store.inventory.observeInventory(function()
        if toolState.switching then return end  -- Ignore changes during auto-switching
        
        -- If the change happened significantly after our last auto-switch, consider it manual
        if tick() - lastAutoSwitchTime > 0.2 then
            toolState.manualSwitchOccurred = true
        end
    end)
    
    -- Update lastAutoSwitchTime when we perform an auto-switch
    local originalSwitchHotbarItem = switchHotbarItem
    switchHotbarItem = function(...)
        lastAutoSwitchTime = tick()
        return originalSwitchHotbarItem(...)
    end
end

task.spawn(function()
    projectileRemote = bedwars.Client:Get(remotes.FireProjectile).instance
end)

local function getAmmo(check)
    for _, item in store.inventory.inventory.items do
        if check.ammoItemTypes and table.find(check.ammoItemTypes, item.itemType) then
            return item.itemType
        end
    end
end

local function hasProjectileEquipped(check)
    if not store.hand.tool then return false end
    local itemMeta = bedwars.ItemMeta[store.hand.tool.Name]
    return itemMeta and itemMeta.projectileSource == check
end

local function isItemInIgnoreList()
    if not store.hand.tool then return false end
    return table.find(IgnoreList.ListEnabled, store.hand.tool.Name) ~= nil
end

local function isHoldingBlock()
    if not store.hand.tool then return false end
    local itemMeta = bedwars.ItemMeta[store.hand.tool.Name]
    return itemMeta and itemMeta.block ~= nil
end

local function isHoldingBreakingTool()
    if not store.hand.tool then return false end
    
    if isItemInIgnoreList() then
        return true
    end
    
    local itemMeta = bedwars.ItemMeta[store.hand.tool.Name]
    if not itemMeta then return false end
    if itemMeta.sword then return false end
    if itemMeta.breakType then return true end
    
    if itemMeta.pickaxe or itemMeta.axe or itemMeta.shears or itemMeta.hammer then
        return true
    end
    
    local breakingItems = {
        "wood_pickaxe", "stone_pickaxe", "iron_pickaxe", "diamond_pickaxe",
        "wood_axe", "stone_axe", "iron_axe", "diamond_axe",
        "shears", "hammer"
    }
    
    for _, item in ipairs(breakingItems) do
        if store.hand.tool.Name == item then
            return true
        end
    end
    
    for toolType, tool in pairs(store.tools or {}) do
        if tool.itemType == store.hand.tool.Name and toolType ~= "sword" then
            return true
        end
    end
    
    return false
end

local function getCurrentHotbarSlot()
    if not store.hand.tool then return nil end
    
    for i, v in pairs(store.inventory.hotbar) do
        if v.item and store.hand.tool.Name == v.item.itemType then
            return i - 1
        end
    end
    return nil
end

-- Enhanced switchHotbarItem function with ToolCheck support
local function switchHotbarItem(itemType)
    if not itemType or toolState.switching then return false end
    
    -- Check if ToolCheck is enabled and blocking switches
    if isToolCheckEnabled() then
        local toolCheck = vape.Modules.ToolCheck
        if toolCheck and toolCheck.Enabled then
            -- Check if we're currently in a tool-check protected state
            if toolCheck.isProtected and toolCheck:isProtected() then
                toolState.toolCheckActive = true
                return false
            end
        end
    end
    
    -- Don't switch if we're in cooldown
    if tick() - toolState.previous.switchTime < toolState.cooldown then
        return false
    end
    
    toolState.manualSwitchOccurred = false
    toolState.toolCheckActive = false
    
    -- Save current item state before switching
    if store.hand.tool then
        toolState.previous.tool = store.hand.tool
        toolState.previous.slot = getCurrentHotbarSlot()
        toolState.previous.switchTime = tick()
    end
    
    -- Find and switch to the target item
    for i, v in pairs(store.inventory.hotbar) do
        if v.item and v.item.itemType == itemType then
            toolState.switching = true
            if hotbarSwitch then
                hotbarSwitch(i - 1)
                task.delay(0.1, function()
                    toolState.switching = false
                end)
                return true
            end
        end
    end
    
    return false
end

-- Improved switchBackToPreviousTool function with ToolCheck support
local function switchBackToPreviousTool()
    if toolState.switching then return false end
    
    -- Don't switch back if ToolCheck is active
    if toolState.toolCheckActive then
        toolState.previous.tool = nil
        toolState.previous.slot = nil
        return false
    end
    
    -- Don't switch back if player has manually switched items
    if toolState.manualSwitchOccurred then
        toolState.previous.tool = nil
        toolState.previous.slot = nil
        return false
    end
    
    -- Check ToolCheck state before switching back
    if isToolCheckEnabled() then
        local toolCheck = vape.Modules.ToolCheck
        if toolCheck and toolCheck.Enabled and toolCheck.isProtected and toolCheck:isProtected() then
            toolState.toolCheckActive = true
            return false
        end
    end
    
    if toolState.previous.slot ~= nil then
        toolState.switching = true
        hotbarSwitch(toolState.previous.slot)
        
        task.delay(0.1, function()
            toolState.previous.tool = nil
            toolState.previous.slot = nil
            toolState.switching = false
        end)
        return true
    elseif toolState.previous.tool then
        toolState.switching = true
        store.hand:EquipTool(toolState.previous.tool)
        
        task.delay(0.1, function()
            toolState.previous.tool = nil
            toolState.previous.slot = nil
            toolState.switching = false
        end)
        return true
    end
    
    return false
end

-- Update the projectile handling with ToolCheck support
local function handleProjectileSwitch(item, itemMeta)
    local switched = false
    
    if AutoSwitch.Enabled and not hasProjectileEquipped(itemMeta) then
        if not isHoldingBlock() and not isHoldingBreakingTool() then
            -- Check ToolCheck state before attempting switch
            if not isToolCheckEnabled() or not vape.Modules.ToolCheck:isProtected() then
                switched = switchHotbarItem(item.itemType)
                if switched then
                    task.wait(0.15)
                end
            end
        end
    end
    
    return switched
end

local function getProjectiles()
    local items = {}
    for _, item in store.inventory.inventory.items do
        local itemMeta = bedwars.ItemMeta[item.itemType]
        local proj = itemMeta and itemMeta.projectileSource
        local ammo = proj and getAmmo(proj)
        
        if normalMode then
            if ammo and table.find(List.ListEnabled, ammo) then
                if not LimitItem.Enabled or hasProjectileEquipped(proj) then
                    table.insert(items, {item, ammo, proj.projectileType(ammo), proj})
                end
            end
        else
            if ammo and not table.find(ReverseList.ListEnabled, ammo) then
                if not LimitItem.Enabled or hasProjectileEquipped(proj) then
                    table.insert(items, {item, ammo, proj.projectileType(ammo), proj})
                end
            end
        end
    end
    return items
end

-- Initialize the manual switch detection
task.spawn(function()
    setupManualSwitchDetection()
end)

ProjectileAura = vape.Categories.Blatant:CreateModule({
    Name = 'ProjectileAura',
    Function = function(callback)
        if callback then
            repeat
                if (workspace:GetServerTimeNow() - bedwars.SwordController.lastAttack) > 0.5 then
                    local ent = entitylib.EntityPosition({
                        Part = 'RootPart',
                        Range = Range.Value,
                        Players = Targets.Players.Enabled,
                        NPCs = Targets.NPCs.Enabled,
                        Wallcheck = Targets.Walls.Enabled
                    })
                    
                    if ent then
                        local pos = entitylib.character.RootPart.Position
                        for _, data in getProjectiles() do
                            local item, ammo, projectile, itemMeta = unpack(data)
                            if (FireDelays[item.itemType] or 0) < tick() then
                                rayCheck.FilterDescendantsInstances = {workspace.Map}
                                local meta = bedwars.ProjectileMeta[projectile]
                                local projSpeed = meta.launchVelocity
                                local gravity = (meta.gravitationalAcceleration or 196.2)
                                
                                local balloons = ent.Character:GetAttribute('InflatedBalloons')
                                local playerGravity = workspace.Gravity
                                
                                if balloons and balloons > 0 then
                                    playerGravity = (workspace.Gravity * (1 - ((balloons >= 4 and 1.2 or balloons >= 3 and 1 or 0.975))))
                                end
                                
                                if ent.Character.PrimaryPart:FindFirstChild('rbxassetid://8200754399') then
                                    playerGravity = 6
                                end
                                
                                local shootPosition = pos + (projectile == 'owl_projectile' and Vector3.zero or itemMeta.fromPositionOffset or Vector3.zero)
                                
                                local calc = prediction.SolveTrajectory(
                                    shootPosition,
                                    projSpeed,
                                    gravity,
                                    ent.RootPart.Position,
                                    projectile == 'telepearl' and Vector3.zero or ent.RootPart.Velocity,
                                    playerGravity,
                                    ent.HipHeight,
                                    ent.Jumping and 42.6 or nil,
                                    rayCheck
                                )
                                
                                if calc then
                                    targetinfo.Targets[ent] = tick() + 1
                                    local switched = handleProjectileSwitch(item, itemMeta)
                                    
                                    task.spawn(function()
                                        local dir = CFrame.lookAt(shootPosition, calc).LookVector
                                        local id = httpService:GenerateGUID(true)
                                        
                                        bedwars.ProjectileController:createLocalProjectile(
                                            meta,
                                            ammo,
                                            projectile,
                                            shootPosition,
                                            id,
                                            dir * projSpeed,
                                            {drawDurationSeconds = 1}
                                        )
                                        
                                        local res = projectileRemote:InvokeServer(
                                            item.tool,
                                            ammo,
                                            projectile,
                                            shootPosition,
                                            pos,
                                            dir * projSpeed,
                                            id,
                                            {drawDurationSeconds = 1, shotId = httpService:GenerateGUID(false)},
                                            workspace:GetServerTimeNow() - 0.045
                                        )
                                        
                                        if not res then
                                            FireDelays[item.itemType] = tick()
                                        else
                                            local shoot = itemMeta.launchSound
                                            shoot = shoot and shoot[math.random(1, #shoot)] or nil
                                            if shoot then
                                                bedwars.SoundManager:playSound(shoot)
                                            end
                                            -- Play the projectile animation
                                            if itemMeta.launchAnimation then
                                                local player = game.Players.LocalPlayer
                                                local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
                                                if humanoid then
                                                    local anim = Instance.new("Animation")
                                                    anim.AnimationId = itemMeta.launchAnimation
                                                    local track = humanoid:LoadAnimation(anim)
                                                    track:Play()
                                                    task.delay(0.5, function()
                                                        track:Stop()
                                                        anim:Destroy()
                                                    end)
                                                end
                                            end
                                        end
                                    end)
                                    
                                    FireDelays[item.itemType] = tick() + math.max(itemMeta.fireDelaySec, FireWait.Value)
                                    
                                    if switched and not toolState.toolCheckActive then
                                        task.wait(0.2)
                                        local switchBack = switchBackToPreviousTool()
                                        if switchBack then
                                            task.wait(0.1)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                task.wait(0.1)
            until not ProjectileAura.Enabled
        end
    end,
    Tooltip = 'Shoots people around you with enhanced prediction'
})

Targets = ProjectileAura:CreateTargets({
    Players = true,
    Walls = true
})

List = ProjectileAura:CreateTextList({
    Name = 'Projectiles',
    Default = {'arrow', 'snowball'}
})

ReverseList = ProjectileAura:CreateTextList({
    Name = 'Reverse Projectiles',
    Default = {}
})

Range = ProjectileAura:CreateSlider({
    Name = 'Range',
    Min = 1,
    Max = 50,
    Default = 50,
    Suffix = function(val)
        return val == 1 and 'stud' or 'studs'
    end
})

LimitItem = ProjectileAura:CreateToggle({
    Name = 'Limit to items',
    Default = true,
    Tooltip = 'Only shoots when projectile tools are equipped'
})

AutoSwitch = ProjectileAura:CreateToggle({
    Name = 'Auto Switch',
    Default = false,
    Tooltip = 'Automatically switches to the projectile tool and back (except when holding blocks or breaking tools)'
})

FireWait = ProjectileAura:CreateSlider({
    Name = 'Fire Wait',
    Min = 1,
    Max = 5,
    Default = 1,
    Suffix = 'sec'
})

IgnoreList = ProjectileAura:CreateTextList({
    Name = 'Ignore Items',
    Default = {}
})

ProjectileAura:CreateToggle({
    Name = 'Mode Toggle',
    Default = true,
    Tooltip = 'Toggle between normal and reverse mode',
    Function = function(enabled)
        normalMode = enabled
    end
})
	

	
run(function()
	local BedESP
	local Reference = {}
	local Folder = Instance.new('Folder')
	Folder.Parent = vape.gui
	
	local function Added(bed)
		if not BedESP.Enabled then return end
		local BedFolder = Instance.new('Folder')
		BedFolder.Parent = Folder
		Reference[bed] = BedFolder
		local parts = bed:GetChildren()
		table.sort(parts, function(a, b)
			return a.Name > b.Name
		end)
	
		for _, part in parts do
			if part:IsA('BasePart') and part.Name ~= 'Blanket' then
				local handle = Instance.new('BoxHandleAdornment')
				handle.Size = part.Size + Vector3.new(.01, .01, .01)
				handle.AlwaysOnTop = true
				handle.ZIndex = 2
				handle.Visible = true
				handle.Adornee = part
				handle.Color3 = part.Color
				if part.Name == 'Legs' then
					handle.Color3 = Color3.fromRGB(167, 112, 64)
					handle.Size = part.Size + Vector3.new(.01, -1, .01)
					handle.CFrame = CFrame.new(0, -0.4, 0)
					handle.ZIndex = 0
				end
				handle.Parent = BedFolder
			end
		end
	
		table.clear(parts)
	end
	
	BedESP = vape.Categories.Render:CreateModule({
		Name = 'BedESP',
		Function = function(callback)
			if callback then
				BedESP:Clean(collectionService:GetInstanceAddedSignal('bed'):Connect(function(bed)
					task.delay(0.2, Added, bed)
				end))
				BedESP:Clean(collectionService:GetInstanceRemovedSignal('bed'):Connect(function(bed)
					if Reference[bed] then
						Reference[bed]:Destroy()
						Reference[bed] = nil
					end
				end))
				for _, bed in collectionService:GetTagged('bed') do
					Added(bed)
				end
			else
				Folder:ClearAllChildren()
				table.clear(Reference)
			end
		end,
		Tooltip = 'Render Beds through walls'
	})
end)
	
run(function()
	local Health
	
	Health = vape.Categories.Render:CreateModule({
		Name = 'Health',
		Function = function(callback)
			if callback then
				local label = Instance.new('TextLabel')
				label.Size = UDim2.fromOffset(100, 20)
				label.Position = UDim2.new(0.5, 6, 0.5, 30)
				label.BackgroundTransparency = 1
				label.AnchorPoint = Vector2.new(0.5, 0)
				label.Text = entitylib.isAlive and math.round(lplr.Character:GetAttribute('Health'))..' ❤️' or ''
				label.TextColor3 = entitylib.isAlive and Color3.fromHSV((lplr.Character:GetAttribute('Health') / lplr.Character:GetAttribute('MaxHealth')) / 2.8, 0.86, 1) or Color3.new()
				label.TextSize = 18
				label.Font = Enum.Font.Arial
				label.Parent = vape.gui
				Health:Clean(label)
				Health:Clean(vapeEvents.AttributeChanged.Event:Connect(function()
					label.Text = entitylib.isAlive and math.round(lplr.Character:GetAttribute('Health'))..' ❤️' or ''
					label.TextColor3 = entitylib.isAlive and Color3.fromHSV((lplr.Character:GetAttribute('Health') / lplr.Character:GetAttribute('MaxHealth')) / 2.8, 0.86, 1) or Color3.new()
				end))
			end
		end,
		Tooltip = 'Displays your health in the center of your screen.'
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
	local Equipment
	local DrawingToggle
	local Scale
	local FontOption
	local Teammates
	local DistanceCheck
	local DistanceLimit
	local Strings, Sizes, Reference = {}, {}, {}
	local Folder = Instance.new('Folder')
	Folder.Parent = vape.gui
	local methodused
	
	local Added = {
		Normal = function(ent)
			if not Targets.Players.Enabled and ent.Player then return end
			if not Targets.NPCs.Enabled and ent.NPC then return end
			if Teammates.Enabled and (not ent.Targetable) and (not ent.Friend) then return end
	
			local nametag = Instance.new('TextLabel')
			Strings[ent] = ent.Player and whitelist:tag(ent.Player, true, true)..(DisplayName.Enabled and ent.Player.DisplayName or ent.Player.Name) or ent.Character.Name
	
			if Health.Enabled then
				local healthColor = Color3.fromHSV(math.clamp(ent.Health / ent.MaxHealth, 0, 1) / 2.5, 0.89, 0.75)
				Strings[ent] = Strings[ent]..' <font color="rgb('..tostring(math.floor(healthColor.R * 255))..','..tostring(math.floor(healthColor.G * 255))..','..tostring(math.floor(healthColor.B * 255))..')">'..math.round(ent.Health)..'</font>'
			end
	
			if Distance.Enabled then
				Strings[ent] = '<font color="rgb(85, 255, 85)">[</font><font color="rgb(255, 255, 255)">%s</font><font color="rgb(85, 255, 85)">]</font> '..Strings[ent]
			end
	
			if Equipment.Enabled then
				for i, v in {'Hand', 'Helmet', 'Chestplate', 'Boots', 'Kit'} do
					local Icon = Instance.new('ImageLabel')
					Icon.Name = v
					Icon.Size = UDim2.fromOffset(30, 30)
					Icon.Position = UDim2.fromOffset(-60 + (i * 30), -30)
					Icon.BackgroundTransparency = 1
					Icon.Image = ''
					Icon.Parent = nametag
				end
			end
	
			nametag.TextSize = 14 * Scale.Value
			nametag.FontFace = FontOption.Value
			local size = getfontsize(removeTags(Strings[ent]), nametag.TextSize, nametag.FontFace, Vector2.new(100000, 100000))
			nametag.Name = ent.Player and ent.Player.Name or ent.Character.Name
			nametag.Size = UDim2.fromOffset(size.X + 8, size.Y + 7)
			nametag.AnchorPoint = Vector2.new(0.5, 1)
			nametag.BackgroundColor3 = Color3.new()
			nametag.BackgroundTransparency = Background.Value
			nametag.BorderSizePixel = 0
			nametag.Visible = false
			nametag.Text = Strings[ent]
			nametag.TextColor3 = entitylib.getEntityColor(ent) or Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
			nametag.RichText = true
			nametag.Parent = Folder
			Reference[ent] = nametag
		end,
		Drawing = function(ent)
			if not Targets.Players.Enabled and ent.Player then return end
			if not Targets.NPCs.Enabled and ent.NPC then return end
			if Teammates.Enabled and (not ent.Targetable) and (not ent.Friend) then return end
	
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
			Strings[ent] = ent.Player and whitelist:tag(ent.Player, true)..(DisplayName.Enabled and ent.Player.DisplayName or ent.Player.Name) or ent.Character.Name
	
			if Health.Enabled then
				Strings[ent] = Strings[ent]..' '..math.round(ent.Health)
			end
	
			if Distance.Enabled then
				Strings[ent] = '[%s] '..Strings[ent]
			end
	
			nametag.Text.Text = Strings[ent]
			nametag.Text.Color = entitylib.getEntityColor(ent) or Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
			nametag.BG.Size = Vector2.new(nametag.Text.TextBounds.X + 8, nametag.Text.TextBounds.Y + 7)
			Reference[ent] = nametag
		end
	}
	
	local Removed = {
		Normal = function(ent)
			local v = Reference[ent]
			if v then
				Reference[ent] = nil
				Strings[ent] = nil
				Sizes[ent] = nil
				v:Destroy()
			end
		end,
		Drawing = function(ent)
			local v = Reference[ent]
			if v then
				Reference[ent] = nil
				Strings[ent] = nil
				Sizes[ent] = nil
				for _, obj in v do
					pcall(function()
						obj.Visible = false
						obj:Remove()
					end)
				end
			end
		end
	}
	
	local Updated = {
		Normal = function(ent)
			local nametag = Reference[ent]
			if nametag then
				Sizes[ent] = nil
				Strings[ent] = ent.Player and whitelist:tag(ent.Player, true, true)..(DisplayName.Enabled and ent.Player.DisplayName or ent.Player.Name) or ent.Character.Name
	
				if Health.Enabled then
					local healthColor = Color3.fromHSV(math.clamp(ent.Health / ent.MaxHealth, 0, 1) / 2.5, 0.89, 0.75)
					Strings[ent] = Strings[ent]..' <font color="rgb('..tostring(math.floor(healthColor.R * 255))..','..tostring(math.floor(healthColor.G * 255))..','..tostring(math.floor(healthColor.B * 255))..')">'..math.round(ent.Health)..'</font>'
				end
	
				if Distance.Enabled then
					Strings[ent] = '<font color="rgb(85, 255, 85)">[</font><font color="rgb(255, 255, 255)">%s</font><font color="rgb(85, 255, 85)">]</font> '..Strings[ent]
				end
	
				if Equipment.Enabled and store.inventories[ent.Player] then
					local kit = ent.Player:GetAttribute('PlayingAsKits')
					local inventory = store.inventories[ent.Player]
					nametag.Hand.Image = bedwars.getIcon(inventory.hand or {itemType = ''}, true)
					nametag.Helmet.Image = bedwars.getIcon(inventory.armor[4] or {itemType = ''}, true)
					nametag.Chestplate.Image = bedwars.getIcon(inventory.armor[5] or {itemType = ''}, true)
					nametag.Boots.Image = bedwars.getIcon(inventory.armor[6] or {itemType = ''}, true)
					nametag.Kit.Image = kit and kit ~= 'none' and bedwars.BedwarsKitMeta[kit].renderImage or ''
				end
	
				local size = getfontsize(removeTags(Strings[ent]), nametag.TextSize, nametag.FontFace, Vector2.new(100000, 100000))
				nametag.Size = UDim2.fromOffset(size.X + 8, size.Y + 7)
				nametag.Text = Strings[ent]
			end
		end,
		Drawing = function(ent)
			local nametag = Reference[ent]
			if nametag then
				if vape.ThreadFix then
					setthreadidentity(8)
				end
				Sizes[ent] = nil
				Strings[ent] = ent.Player and whitelist:tag(ent.Player, true)..(DisplayName.Enabled and ent.Player.DisplayName or ent.Player.Name) or ent.Character.Name
	
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
				nametag.Text.Color = entitylib.getEntityColor(ent) or Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
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
					if distance < DistanceLimit.ValueMin or distance > DistanceLimit.ValueMax then
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
	
				local headPos, headVis = gameCamera:WorldToViewportPoint(ent.RootPart.Position + Vector3.new(0, ent.HipHeight + 1, 0))
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
				nametag.BG.Position = Vector2.new(headPos.X - (nametag.BG.Size.X / 2), headPos.Y - nametag.BG.Size.Y)
				nametag.Text.Position = nametag.BG.Position + Vector2.new(4, 3)
			end
		end
	}
	
	NameTags = vape.Categories.Render:CreateModule({
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
				if ColorFunc[methodused] then
					NameTags:Clean(vape.Categories.Friends.ColorUpdate.Event:Connect(function()
						ColorFunc[methodused](Color.Hue, Color.Sat, Color.Value)
					end))
				end
				if Loop[methodused] then
					NameTags:Clean(runService.RenderStepped:Connect(Loop[methodused]))
				end
			else
				if Removed[methodused] then
					for i in Reference do
						Removed[methodused](i)
					end
				end
			end
		end,
		Tooltip = 'Renders nametags on entities through walls.'
	})
	Targets = NameTags:CreateTargets({
		Players = true,
		Function = function()
			if NameTags.Enabled then
				NameTags:Toggle()
				NameTags:Toggle()
			end
		end
	})
	FontOption = NameTags:CreateFont({
		Name = 'Font',
		Blacklist = 'Arial',
		Function = function()
			if NameTags.Enabled then
				NameTags:Toggle()
				NameTags:Toggle()
			end
		end
	})
	Color = NameTags:CreateColorSlider({
		Name = 'Player Color',
		Function = function(hue, sat, val)
			if NameTags.Enabled and ColorFunc[methodused] then
				ColorFunc[methodused](hue, sat, val)
			end
		end
	})
	Scale = NameTags:CreateSlider({
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
	Background = NameTags:CreateSlider({
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
	Health = NameTags:CreateToggle({
		Name = 'Health',
		Function = function()
			if NameTags.Enabled then
				NameTags:Toggle()
				NameTags:Toggle()
			end
		end
	})
	Distance = NameTags:CreateToggle({
		Name = 'Distance',
		Function = function()
			if NameTags.Enabled then
				NameTags:Toggle()
				NameTags:Toggle()
			end
		end
	})
	Equipment = NameTags:CreateToggle({
		Name = 'Equipment',
		Function = function()
			if NameTags.Enabled then
				NameTags:Toggle()
				NameTags:Toggle()
			end
		end
	})
	DisplayName = NameTags:CreateToggle({
		Name = 'Use Displayname',
		Function = function()
			if NameTags.Enabled then
				NameTags:Toggle()
				NameTags:Toggle()
			end
		end,
		Default = true
	})
	Teammates = NameTags:CreateToggle({
		Name = 'Priority Only',
		Function = function()
			if NameTags.Enabled then
				NameTags:Toggle()
				NameTags:Toggle()
			end
		end,
		Default = true
	})
	DrawingToggle = NameTags:CreateToggle({
		Name = 'Drawing',
		Function = function()
			if NameTags.Enabled then
				NameTags:Toggle()
				NameTags:Toggle()
			end
		end,
	})
	DistanceCheck = NameTags:CreateToggle({
		Name = 'Distance Check',
		Function = function(callback)
			DistanceLimit.Object.Visible = callback
		end
	})
	DistanceLimit = NameTags:CreateTwoSlider({
		Name = 'Player Distance',
		Min = 0,
		Max = 256,
		DefaultMin = 0,
		DefaultMax = 64,
		Darker = true,
		Visible = false
	})
end)
	
run(function()
	local StorageESP
	local List
	local Background
	local Color = {}
	local Reference = {}
	local Folder = Instance.new('Folder')
	Folder.Parent = vape.gui
	
	local function nearStorageItem(item)
		for _, v in List.ListEnabled do
			if item:find(v) then return v end
		end
	end
	
	local function refreshAdornee(v)
		local chest = v.Adornee:FindFirstChild('ChestFolderValue')
		chest = chest and chest.Value or nil
		if not chest then
			v.Enabled = false
			return
		end
	
		local chestitems = chest and chest:GetChildren() or {}
		for _, obj in v.Frame:GetChildren() do
			if obj:IsA('ImageLabel') and obj.Name ~= 'Blur' then
				obj:Destroy()
			end
		end
	
		v.Enabled = false
		local alreadygot = {}
		for _, item in chestitems do
			if not alreadygot[item.Name] and (table.find(List.ListEnabled, item.Name) or nearStorageItem(item.Name)) then
				alreadygot[item.Name] = true
				v.Enabled = true
				local blockimage = Instance.new('ImageLabel')
				blockimage.Size = UDim2.fromOffset(32, 32)
				blockimage.BackgroundTransparency = 1
				blockimage.Image = bedwars.getIcon({itemType = item.Name}, true)
				blockimage.Parent = v.Frame
			end
		end
		table.clear(chestitems)
	end
	
	local function Added(v)
		local chest = v:WaitForChild('ChestFolderValue', 3)
		if not (chest and StorageESP.Enabled) then return end
		chest = chest.Value
		local billboard = Instance.new('BillboardGui')
		billboard.Parent = Folder
		billboard.Name = 'chest'
		billboard.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
		billboard.Size = UDim2.fromOffset(36, 36)
		billboard.AlwaysOnTop = true
		billboard.ClipsDescendants = false
		billboard.Adornee = v
		local blur = addBlur(billboard)
		blur.Visible = Background.Enabled
		local frame = Instance.new('Frame')
		frame.Size = UDim2.fromScale(1, 1)
		frame.BackgroundColor3 = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
		frame.BackgroundTransparency = 1 - (Background.Enabled and Color.Opacity or 0)
		frame.Parent = billboard
		local layout = Instance.new('UIListLayout')
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.Padding = UDim.new(0, 4)
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
			billboard.Size = UDim2.fromOffset(math.max(layout.AbsoluteContentSize.X + 4, 36), 36)
		end)
		layout.Parent = frame
		local corner = Instance.new('UICorner')
		corner.CornerRadius = UDim.new(0, 4)
		corner.Parent = frame
		Reference[v] = billboard
		StorageESP:Clean(chest.ChildAdded:Connect(function(item)
			if table.find(List.ListEnabled, item.Name) or nearStorageItem(item.Name) then
				refreshAdornee(billboard)
			end
		end))
		StorageESP:Clean(chest.ChildRemoved:Connect(function(item)
			if table.find(List.ListEnabled, item.Name) or nearStorageItem(item.Name) then
				refreshAdornee(billboard)
			end
		end))
		task.spawn(refreshAdornee, billboard)
	end
	
	StorageESP = vape.Categories.Render:CreateModule({
		Name = 'StorageESP',
		Function = function(callback)
			if callback then
				StorageESP:Clean(collectionService:GetInstanceAddedSignal('chest'):Connect(Added))
				for _, v in collectionService:GetTagged('chest') do
					task.spawn(Added, v)
				end
			else
				table.clear(Reference)
				Folder:ClearAllChildren()
			end
		end,
		Tooltip = 'Displays items in chests'
	})
	List = StorageESP:CreateTextList({
		Name = 'Item',
		Function = function()
			for _, v in Reference do
				task.spawn(refreshAdornee, v)
			end
		end
	})
	Background = StorageESP:CreateToggle({
		Name = 'Background',
		Function = function(callback)
			if Color.Object then Color.Object.Visible = callback end
			for _, v in Reference do
				v.Frame.BackgroundTransparency = 1 - (callback and Color.Opacity or 0)
				v.Blur.Visible = callback
			end
		end,
		Default = true
	})
	Color = StorageESP:CreateColorSlider({
		Name = 'Background Color',
		DefaultValue = 0,
		DefaultOpacity = 0.5,
		Function = function(hue, sat, val, opacity)
			for _, v in Reference do
				v.Frame.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
				v.Frame.BackgroundTransparency = 1 - opacity
			end
		end,
		Darker = true
	})
end)
	
run(function()
	local AutoBalloon
	
	AutoBalloon = vape.Categories.Utility:CreateModule({
		Name = 'AutoBalloon',
		Function = function(callback)
			if callback then
				repeat task.wait(0.1) until store.matchState ~= 0 or (not AutoBalloon.Enabled)
				if not AutoBalloon.Enabled then return end
	
				local lowestpoint = math.huge
				for _, v in store.blocks do
					local point = (v.Position.Y - (v.Size.Y / 2)) - 50
					if point < lowestpoint then 
						lowestpoint = point 
					end
				end
	
				repeat
					if entitylib.isAlive then
						if entitylib.character.RootPart.Position.Y < lowestpoint and (lplr.Character:GetAttribute('InflatedBalloons') or 0) < 3 then
							local balloon = getItem('balloon')
							if balloon then
								for _ = 1, 3 do 
									bedwars.BalloonController:inflateBalloon() 
								end
							end
							task.wait(0.1)
						end
					end
					task.wait(0.1)
				until not AutoBalloon.Enabled
			end
		end,
		Tooltip = 'Inflates when you fall into the void'
	})
end)
		
run(function()
	local AutoPearl
	local rayCheck = RaycastParams.new()
	rayCheck.RespectCanCollide = true
	local projectileRemote = {InvokeServer = function() end}
	task.spawn(function()
		projectileRemote = bedwars.Client:Get(remotes.FireProjectile).instance
	end)
	
	local function firePearl(pos, spot, item)
		switchItem(item.tool)
		local meta = bedwars.ProjectileMeta.telepearl
		local calc = prediction.SolveTrajectory(pos, meta.launchVelocity, meta.gravitationalAcceleration, spot, Vector3.zero, workspace.Gravity, 0, 0)
	
		if calc then
			local dir = CFrame.lookAt(pos, calc).LookVector * meta.launchVelocity
			bedwars.ProjectileController:createLocalProjectile(meta, 'telepearl', 'telepearl', pos, nil, dir, {drawDurationSeconds = 1})
			projectileRemote:InvokeServer(item.tool, 'telepearl', 'telepearl', pos, pos, dir, httpService:GenerateGUID(true), {drawDurationSeconds = 1, shotId = httpService:GenerateGUID(false)}, workspace:GetServerTimeNow() - 0.045)
		end
	
		if store.hand then
			switchItem(store.hand.tool)
		end
	end
	
	AutoPearl = vape.Categories.Utility:CreateModule({
		Name = 'AutoPearl',
		Function = function(callback)
			if callback then
				local check
				repeat
					if entitylib.isAlive then
						local root = entitylib.character.RootPart
						local pearl = getItem('telepearl')
						rayCheck.FilterDescendantsInstances = {lplr.Character, gameCamera, AntiFallPart}
						rayCheck.CollisionGroup = root.CollisionGroup
	
						if pearl and root.Velocity.Y < -100 and not workspace:Raycast(root.Position, Vector3.new(0, -200, 0), rayCheck) then
							if not check then
								check = true
								local ground = getNearGround(20)
	
								if ground then
									firePearl(root.Position, ground, pearl)
								end
							end
						else
							check = false
						end
					end
					task.wait(0.1)
				until not AutoPearl.Enabled
			end
		end,
		Tooltip = 'Automatically throws a pearl onto nearby ground after\nfalling a certain distance.'
	})
end)
	

	

	
run(function()
	local AutoToxic
	local GG
	local Toggles, Lists, said, dead = {}, {}, {}
	
	local function sendMessage(name, obj, default)
		local tab = Lists[name].ListEnabled
		local custommsg = #tab > 0 and tab[math.random(1, #tab)] or default
		if not custommsg then return end
		if #tab > 1 and custommsg == said[name] then
			repeat 
				task.wait(0.1) 
				custommsg = tab[math.random(1, #tab)] 
			until custommsg ~= said[name]
		end
		said[name] = custommsg
	
		custommsg = custommsg and custommsg:gsub('<obj>', obj or '') or ''
		if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
			textChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync(custommsg)
		else
			replicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(custommsg, 'All')
		end
	end
	
	AutoToxic = vape.Categories.Utility:CreateModule({
		Name = 'AutoToxic',
		Function = function(callback)
			if callback then
				AutoToxic:Clean(vapeEvents.BedwarsBedBreak.Event:Connect(function(bedTable)
					if Toggles.BedDestroyed.Enabled and bedTable.brokenBedTeam.id == lplr:GetAttribute('Team') then
						sendMessage('BedDestroyed', (bedTable.player.DisplayName or bedTable.player.Name), 'why would you bed break me <obj> onyx will obviously diff you xd')
					elseif Toggles.Bed.Enabled and bedTable.player.UserId == lplr.UserId then
						local team = bedwars.QueueMeta[store.queueType].teams[tonumber(bedTable.brokenBedTeam.id)]
						sendMessage('Bed', team and team.displayName:lower() or 'white', 'nice bed btw, switch to onyx forever on top | <obj>')
					end
				end))
				AutoToxic:Clean(vapeEvents.EntityDeathEvent.Event:Connect(function(deathTable)
					if deathTable.finalKill then
						local killer = playersService:GetPlayerFromCharacter(deathTable.fromEntity)
						local killed = playersService:GetPlayerFromCharacter(deathTable.entityInstance)
						if not killed or not killer then return end
						if killed == lplr then
							if (not dead) and killer ~= lplr and Toggles.Death.Enabled then
								dead = true
								sendMessage('Death', (killer.DisplayName or killer.Name), 'ur trash btw and onyx on top forever :( | <obj>')
							end
						elseif killer == lplr and Toggles.Kill.Enabled then
							sendMessage('Kill', (killed.DisplayName or killed.Name), 'you should switch to onyx my friend named | <obj>')
						end
					end
				end))
				AutoToxic:Clean(vapeEvents.MatchEndEvent.Event:Connect(function(winstuff)
					if GG.Enabled then
						if textChatService.ChatVersion == Enum.ChatVersion.TextChatService then
							textChatService.ChatInputBarConfiguration.TargetTextChannel:SendAsync('ez + onyx forever')
						else
							replicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer('ez and onyx forever', 'All')
						end
					end
					
					local myTeam = bedwars.Store:getState().Game.myTeam
					if myTeam and myTeam.id == winstuff.winningTeamId or lplr.Neutral then
						if Toggles.Win.Enabled then 
							sendMessage('Win', nil, 'yall garbage and onyx on top') 
						end
					end
				end))
			end
		end,
		Tooltip = 'Says a message after a certain action'
	})
	GG = AutoToxic:CreateToggle({
		Name = 'AutoGG',
		Default = true
	})
	for _, v in {'Kill', 'Death', 'Bed', 'BedDestroyed', 'Win'} do
		Toggles[v] = AutoToxic:CreateToggle({
			Name = v..' ',
			Function = function(callback)
				if Lists[v] then
					Lists[v].Object.Visible = callback
				end
			end
		})
		Lists[v] = AutoToxic:CreateTextList({
			Name = v,
			Darker = true,
			Visible = false
		})
	end
end)
	
run(function()
	local AutoVoidDrop
	local OwlCheck
	
	AutoVoidDrop = vape.Categories.Utility:CreateModule({
		Name = 'AutoVoidDrop',
		Function = function(callback)
			if callback then
				repeat task.wait(0.1) until store.matchState ~= 0 or (not AutoVoidDrop.Enabled)
				if not AutoVoidDrop.Enabled then return end
	
				local lowestpoint = math.huge
				for _, v in store.blocks do
					local point = (v.Position.Y - (v.Size.Y / 2)) - 50
					if point < lowestpoint then
						lowestpoint = point
					end
				end
	
				repeat
					if entitylib.isAlive then
						local root = entitylib.character.RootPart
						if root.Position.Y < lowestpoint and (lplr.Character:GetAttribute('InflatedBalloons') or 0) <= 0 and not getItem('balloon') then
							if not OwlCheck.Enabled or not root:FindFirstChild('OwlLiftForce') then
								for _, item in {'iron', 'diamond', 'emerald', 'gold'} do
									item = getItem(item)
									if item then
										item = bedwars.Client:Get(remotes.DropItem):CallServer({
											item = item.tool,
											amount = item.amount
										})
	
										if item then
											item:SetAttribute('ClientDropTime', tick() + 100)
										end
									end
								end
							end
						end
					end
	
					task.wait(0.1)
				until not AutoVoidDrop.Enabled
			end
		end,
		Tooltip = 'Drops resources when you fall into the void'
	})
	OwlCheck = AutoVoidDrop:CreateToggle({
		Name = 'Owl check',
		Default = true,
		Tooltip = 'Refuses to drop items if being picked up by an owl'
	})
end)
	
run(function()
	local MissileTP
	
	MissileTP = vape.Categories.Utility:CreateModule({
		Name = 'MissileTP',
		Function = function(callback)
			if callback then
				MissileTP:Toggle()
				local plr = entitylib.EntityMouse({
					Range = 1000,
					Players = true,
					Part = 'RootPart'
				})
	
				if getItem('guided_missile') and plr then
					local projectile = bedwars.RuntimeLib.await(bedwars.GuidedProjectileController.fireGuidedProjectile:CallServerAsync('guided_missile'))
					if projectile then
						local projectilemodel = projectile.model
						if not projectilemodel.PrimaryPart then
							projectilemodel:GetPropertyChangedSignal('PrimaryPart'):Wait()
						end
	
						local bodyforce = Instance.new('BodyForce')
						bodyforce.Force = Vector3.new(0, projectilemodel.PrimaryPart.AssemblyMass * workspace.Gravity, 0)
						bodyforce.Name = 'AntiGravity'
						bodyforce.Parent = projectilemodel.PrimaryPart
	
						repeat
							projectile.model:SetPrimaryPartCFrame(CFrame.lookAlong(plr.RootPart.CFrame.p, gameCamera.CFrame.LookVector))
							task.wait(0.1)
						until not projectile.model or not projectile.model.Parent
					else
						notif('MissileTP', 'Missile on cooldown.', 3)
					end
				end
			end
		end,
		Tooltip = 'Spawns and teleports a missile to a player\nnear your mouse.'
	})
end)
	
run(function()
	local PickupRange
	local Range
	local Network
	local Lower
	
	PickupRange = vape.Categories.Utility:CreateModule({
		Name = 'PickupRange',
		Function = function(callback)
			if callback then
				local items = collection('ItemDrop', PickupRange)
				repeat
					if entitylib.isAlive then
						local localPosition = entitylib.character.RootPart.Position
						for _, v in items do
							if tick() - (v:GetAttribute('ClientDropTime') or 0) < 2 then continue end
							if isnetworkowner(v) and Network.Enabled and entitylib.character.Humanoid.Health > 0 then 
								v.CFrame = CFrame.new(localPosition - Vector3.new(0, 3, 0)) 
							end
							
							if (localPosition - v.Position).Magnitude <= Range.Value then
								if Lower.Enabled and (localPosition.Y - v.Position.Y) < (entitylib.character.HipHeight - 1) then continue end
								task.spawn(function()
									bedwars.Client:Get(remotes.PickupItem):CallServerAsync({
										itemDrop = v
									}):andThen(function(suc)
										if suc and bedwars.SoundList then
											bedwars.SoundManager:playSound(bedwars.SoundList.PICKUP_ITEM_DROP)
											local sound = bedwars.ItemMeta[v.Name].pickUpOverlaySound
											if sound then
												bedwars.SoundManager:playSound(sound, {
													position = v.Position,
													volumeMultiplier = 0.9
												})
											end
										end
									end)
								end)
							end
						end
					end
					task.wait(0.1)
				until not PickupRange.Enabled
			end
		end,
		Tooltip = 'Picks up items from a farther distance'
	})
	Range = PickupRange:CreateSlider({
		Name = 'Range',
		Min = 1,
		Max = 10,
		Default = 10,
		Suffix = function(val) 
			return val == 1 and 'stud' or 'studs' 
		end
	})
	Network = PickupRange:CreateToggle({
		Name = 'Network TP',
		Default = true
	})
	Lower = PickupRange:CreateToggle({Name = 'Feet Check'})
end)
	
run(function()
	local RavenTP
	
	RavenTP = vape.Categories.Utility:CreateModule({
		Name = 'RavenTP',
		Function = function(callback)
			if callback then
				RavenTP:Toggle()
				local plr = entitylib.EntityMouse({
					Range = 1000,
					Players = true,
					Part = 'RootPart'
				})
	
				if getItem('raven') and plr then
					bedwars.Client:Get(remotes.SpawnRaven):CallServerAsync():andThen(function(projectile)
						if projectile then
							local bodyforce = Instance.new('BodyForce')
							bodyforce.Force = Vector3.new(0, projectile.PrimaryPart.AssemblyMass * workspace.Gravity, 0)
							bodyforce.Parent = projectile.PrimaryPart
	
							if plr then
								task.spawn(function()
									for _ = 1, 20 do
										if plr.RootPart and projectile then
											projectile:SetPrimaryPartCFrame(CFrame.lookAlong(plr.RootPart.Position, gameCamera.CFrame.LookVector))
										end
										task.wait(0.05)
									end
								end)
								task.wait(0.3)
								bedwars.RavenController:detonateRaven()
							end
						end
					end)
				end
			end
		end,
		Tooltip = 'Spawns and teleports a raven to a player\nnear your mouse.'
	})
end)
	
local Scaffold
local Expand
local Downwards
local Diagonal
local LimitItem
local Mouse
local TowerCPS

-- Pre-calculate adjacent positions
local adjacent = table.create(26)
for x = -3, 3, 3 do
    for y = -3, 3, 3 do
        for z = -3, 3, 3 do
            if x ~= 0 or y ~= 0 or z ~= 0 then
                adjacent[#adjacent + 1] = Vector3.new(x, y, z)
            end
        end
    end
end

local lastpos = Vector3.zero
local label
local lastPlace = 0
local lastPlacementTime = 0 -- For rate limiting

-- Optimized corner check using cached unit vectors
local function nearCorner(poscheck, pos)
    local offset = Vector3.new(3, 3, 3)
    local startpos = poscheck - offset
    local endpos = poscheck + offset
    local dir = (pos - poscheck).Unit
    local check = poscheck + dir * 100
    return Vector3.new(
        math.clamp(check.X, startpos.X, endpos.X),
        math.clamp(check.Y, startpos.Y, endpos.Y),
        math.clamp(check.Z, startpos.Z, endpos.Z)
    )
end

-- Optimized block proximity check with local caching
local function blockProximity(pos)
    local mag = 60
    local returned
    local startPos = bedwars.BlockController:getBlockPosition(pos - Vector3.new(15, 15, 15))
    local endPos = bedwars.BlockController:getBlockPosition(pos + Vector3.new(15, 15, 15))
    local blocks = getBlocksInPoints(startPos, endPos)
    
    for i = 1, #blocks do
        local blockpos = nearCorner(blocks[i], pos)
        local newmag = (pos - blockpos).Magnitude
        if newmag < mag then
            mag = newmag
            returned = blockpos
        end
    end
    table.clear(blocks)
    return returned
end

-- Optimized adjacent check
local function checkAdjacent(pos)
    for i = 1, #adjacent do
        if getPlacedBlock(pos + adjacent[i]) then
            return true
        end
    end
    return false
end

local function getScaffoldBlock()
    if store.hand.toolType == 'block' then
        return store.hand.tool.Name, store.hand.amount
    elseif not LimitItem.Enabled then
        local wool, amount = getWool()
        if wool then
            return wool, amount
        end
        for _, item in store.inventory.inventory.items do
            if bedwars.ItemMeta[item.itemType].block then
                return item.itemType, item.amount
            end
        end
    end
    return nil, 0
end

-- Animation manipulation
local jumpAnim = Instance.new("Animation")
jumpAnim.AnimationId = "http://www.roblox.com/asset/?id=507765000"
local fallAnim = Instance.new("Animation")
fallAnim.AnimationId = "http://www.roblox.com/asset/?id=507767968"
local jumpTrack, fallTrack

Scaffold = vape.Categories.Utility:CreateModule({
    Name = 'Scaffold',
    Function = function(callback)
        if label then
            label.Visible = callback
        end

        if callback then
            local towerThread
            
            -- Fast tower building with CPS and animation manipulation
            local function startTowerBuild()
                if towerThread then return end
                towerThread = task.spawn(function()
                    local lastBlockPos = nil
                    while Scaffold.Enabled and Tower.Enabled and (inputService:IsKeyDown(Enum.KeyCode.Space) or 
                        (inputService.TouchEnabled and lplr.PlayerGui.TouchGui.TouchControlFrame.JumpButton.ImageTransparency < 1)) do
                        local currentTime = tick()
                        if currentTime - lastPlace >= (1 / TowerCPS.GetRandomValue()) then
                            if entitylib.isAlive then
                                local root = entitylib.character.RootPart
                                local humanoid = entitylib.character.Humanoid
                                if root and humanoid then
                                    local wool = getScaffoldBlock()
                                    -- Only apply velocity if we have blocks or LimitItem is off
                                    if (wool or not LimitItem.Enabled) and not bedwars.AppController:isLayerOpen(bedwars.UILayers.MAIN) then
                                        root.Velocity = Vector3.new(root.Velocity.X, 38, root.Velocity.Z)
                                        
                                        -- Play jump animation when going up
                                        if not jumpTrack or not jumpTrack.IsPlaying then
                                            jumpTrack = humanoid:LoadAnimation(jumpAnim)
                                            jumpTrack.Priority = Enum.AnimationPriority.Action
                                            jumpTrack:Play()
                                            if fallTrack then fallTrack:Stop() end
                                        end
                                    else
                                        -- Play fall animation when going down (not applying upward velocity)
                                        if root.Velocity.Y < 0 and (not fallTrack or not fallTrack.IsPlaying) then
                                            fallTrack = humanoid:LoadAnimation(fallAnim)
                                            fallTrack.Priority = Enum.AnimationPriority.Action
                                            fallTrack:Play()
                                            if jumpTrack then jumpTrack:Stop() end
                                        end
                                    end
                                    
                                    -- Place blocks if we have them
                                    if wool and not bedwars.AppController:isLayerOpen(bedwars.UILayers.MAIN) then
                                        local pos = root.Position - Vector3.new(0, entitylib.character.HipHeight + 1.5, 0)
                                        local roundedPos = roundPos(pos)
                                        
                                        -- Only do proximity check if position changed
                                        if lastBlockPos ~= roundedPos then
                                            local block, blockpos = getPlacedBlock(roundedPos)
                                            if not block then
                                                blockpos = checkAdjacent(blockpos * 3) and blockpos * 3 or blockProximity(pos)
                                                if blockpos then
                                                    task.spawn(bedwars.placeBlock, blockpos, wool, false)
                                                    lastPlace = currentTime
                                                    lastBlockPos = roundedPos
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        task.wait(0.01)
                    end
                    towerThread = nil
                end)
            end
            
            local function stopTowerBuild()
                if towerThread then
                    task.cancel(towerThread)
                    towerThread = nil
                end
                -- Stop animation tracks when stopping tower
                if jumpTrack then jumpTrack:Stop() end
                if fallTrack then fallTrack:Stop() end
                jumpTrack = nil
                fallTrack = nil
            end
            
            -- Input handlers for tower
            Scaffold:Clean(inputService.InputBegan:Connect(function(input)
                if input.KeyCode == Enum.KeyCode.Space and Tower.Enabled then
                    startTowerBuild()
                end
            end))
            
            Scaffold:Clean(inputService.InputEnded:Connect(function(input)
                if input.KeyCode == Enum.KeyCode.Space then
                    stopTowerBuild()
                end
            end))
            
            -- Mobile support
            if inputService.TouchEnabled then
                pcall(function()
                    local touchGui = lplr.PlayerGui:WaitForChild("TouchGui", 2)
                    if touchGui then
                        local jumpButton = touchGui.TouchControlFrame:WaitForChild("JumpButton", 2)
                        if jumpButton then
                            Scaffold:Clean(jumpButton.MouseButton1Down:Connect(function()
                                if Tower.Enabled then startTowerBuild() end
                            end))
                            Scaffold:Clean(jumpButton.MouseButton1Up:Connect(stopTowerBuild))
                        end
                    end
                end)
            end

            -- Main scaffold loop
            repeat
                if entitylib.isAlive then
                    local wool, amount = getScaffoldBlock()

                    if Mouse.Enabled and not inputService:IsMouseButtonPressed(0) then
                        wool = nil
                    end

                    if label then
                        amount = amount or 0
                        label.Text = amount..' <font color="rgb(170, 170, 170)">(Scaffold)</font>'
                        label.TextColor3 = Color3.fromHSV((amount / 128) / 2.8, 0.86, 1)
                    end

                    if wool then
                        local root = entitylib.character.RootPart
                        local moveDir = entitylib.character.Humanoid.MoveDirection
                        local hipHeight = entitylib.character.HipHeight
                        local downOffset = Downwards.Enabled and inputService:IsKeyDown(Enum.KeyCode.LeftShift) and 4.5 or 1.5
                        local basePos = root.Position - Vector3.new(0, hipHeight + downOffset, 0)

                        -- Smoother placement: 1-stud intervals with rate limiting
                        for i = 1, Expand.Value do
                            if tick() - lastPlacementTime < 0.02 then break end -- Rate limit: max 50 placements/sec
                            local currentpos = roundPos(basePos + moveDir * i)
                            
                            if Diagonal.Enabled then
                                local angle = math.abs(math.round(math.deg(math.atan2(-moveDir.X, -moveDir.Z)) / 45) * 45)
                                if angle % 90 == 45 then
                                    local dt = (lastpos - currentpos)
                                    if ((dt.X == 0 and dt.Z ~= 0) or (dt.X ~= 0 and dt.Z == 0)) and 
                                       ((lastpos - root.Position) * Vector3.new(1, 0, 1)).Magnitude < 2.5 then
                                        currentpos = lastpos
                                    end
                                end
                            end

                            local block, blockpos = getPlacedBlock(currentpos)
                            if not block then
                                blockpos = checkAdjacent(blockpos * 3) and blockpos * 3 or blockProximity(currentpos)
                                if blockpos then
                                    task.spawn(bedwars.placeBlock, blockpos, wool, false)
                                    lastPlacementTime = tick()
                                end
                            end
                            lastpos = currentpos
                        end
                    end
                end
                task.wait(0.01)
            until not Scaffold.Enabled
        else
            Label = nil
            -- Stop tracks when disabling
            if jumpTrack then jumpTrack:Stop() end
            if fallTrack then fallTrack:Stop() end
            jumpTrack = nil
            fallTrack = nil
        end
    end,
    Tooltip = 'Helps you make bridges/scaffold walk.'
})

Expand = Scaffold:CreateSlider({
    Name = 'Expand',
    Min = 1,
    Max = 6
})

Tower = Scaffold:CreateToggle({
    Name = 'Tower',
    Default = true
})

Downwards = Scaffold:CreateToggle({
    Name = 'Downwards',
    Default = true
})

Diagonal = Scaffold:CreateToggle({
    Name = 'Diagonal',
    Default = true
})

LimitItem = Scaffold:CreateToggle({Name = 'Limit to items'})
Mouse = Scaffold:CreateToggle({Name = 'Require mouse down'})

Count = Scaffold:CreateToggle({
    Name = 'Block Count',
    Function = function(callback)
        if callback then
            label = Instance.new('TextLabel')
            label.Size = UDim2.fromOffset(100, 20)
            label.Position = UDim2.new(0.5, 6, 0.5, 60)
            label.BackgroundTransparency = 1
            label.AnchorPoint = Vector2.new(0.5, 0)
            label.Text = '0'
            label.TextColor3 = Color3.new(0, 1, 0)
            label.TextSize = 18
            label.RichText = true
            label.Font = Enum.Font.Arial
            label.Visible = Scaffold.Enabled
            label.Parent = vape.gui
        else
            label:Destroy()
            label = nil
        end
    end
})

TowerCPS = Scaffold:CreateTwoSlider({
    Name = 'Tower CPS',
    Min = 1,
    Max = 40,
    DefaultMin = 20,
    DefaultMax = 20,
    Darker = true
})




	
run(function()
	local ShopTierBypass
	local tiered, nexttier = {}, {}
	
	ShopTierBypass = vape.Categories.Utility:CreateModule({
		Name = 'ShopTierBypass',
		Function = function(callback)
			if ShopTierBypass.Enabled then
				if store.equippedKit == "berserker" then
					vape:CreateNotification("ShopTierBypass","Cannot use 'ShopTierBypass' with the current kit 'RAGNAR'",6,"warning")
					return
				end
			end
			if callback then
				repeat task.wait(0.1) until store.shopLoaded or not ShopTierBypass.Enabled
				if ShopTierBypass.Enabled then
					for _, v in bedwars.Shop.ShopItems do
						tiered[v] = v.tiered
						nexttier[v] = v.nextTier
						v.nextTier = nil
						v.tiered = nil
					end
				end
			else
				for i, v in tiered do
					i.tiered = v
				end
				for i, v in nexttier do
					i.nextTier = v
				end
				table.clear(nexttier)
				table.clear(tiered)
			end
		end,
		Tooltip = 'Lets you buy things like armor early.'
	})
end)
	
run(function()
	local StaffDetector
	local Mode
	local Clans
	local Party
	local Profile
	local Users
	local blacklistedclans = {'gg', 'gg2', 'DV', 'DV2'}
	local blacklisteduserids = {1502104539, 3826146717, 4531785383, 1049767300, 4926350670, 653085195, 184655415, 2752307430, 5087196317, 5744061325, 1536265275}
	local joined = {}
	
	local function getRole(plr, id)
		local suc, res = pcall(function()
			return plr:GetRankInGroup(id)
		end)
		if not suc then
			notif('StaffDetector', res, 30, 'alert')
		end
		return suc and res or 0
	end
	
	local function staffFunction(plr, checktype)
		if not vape.Loaded then
			repeat task.wait(0.1) until vape.Loaded
		end
	
		notif('StaffDetector', 'Staff Detected ('..checktype..'): '..plr.Name..' ('..plr.UserId..')', 60, 'alert')
		whitelist.customtags[plr.Name] = {{text = 'GAME STAFF', color = Color3.new(1, 0, 0)}}
	
		if Party.Enabled and not checktype:find('clan') then
			bedwars.PartyController:leaveParty()
		end
	
		if Mode.Value == 'Uninject' then
			task.spawn(function()
				vape:Uninject()
			end)
			game:GetService('StarterGui'):SetCore('SendNotification', {
				Title = 'StaffDetector',
				Text = 'Staff Detected ('..checktype..')\n'..plr.Name..' ('..plr.UserId..')',
				Duration = 60,
			})
		elseif Mode.Value == 'Requeue' then
			bedwars.QueueController:joinQueue(store.queueType)
		elseif Mode.Value == 'Profile' then
			vape.Save = function() end
			if vape.Profile ~= Profile.Value then
				vape:Load(true, Profile.Value)
			end
		elseif Mode.Value == 'AutoConfig' then
			local safe = {'AutoClicker', 'Reach', 'Sprint', 'HitFix', 'StaffDetector'}
			vape.Save = function() end
			for i, v in vape.Modules do
				if not (table.find(safe, i) or v.Category == 'Render') then
					if v.Enabled then
						v:Toggle()
					end
					v:SetBind('')
				end
			end
		end
	end
	
	local function checkFriends(list)
		for _, v in list do
			if joined[v] then
				return joined[v]
			end
		end
		return nil
	end
	
	local function checkJoin(plr, connection)
		if not plr:GetAttribute('Team') and plr:GetAttribute('Spectator') and not bedwars.Store:getState().Game.customMatch then
			connection:Disconnect()
			local tab, pages = {}, playersService:GetFriendsAsync(plr.UserId)
			for _ = 1, 4 do
				for _, v in pages:GetCurrentPage() do
					table.insert(tab, v.Id)
				end
				if pages.IsFinished then break end
				pages:AdvanceToNextPageAsync()
			end
	
			local friend = checkFriends(tab)
			if not friend then
				staffFunction(plr, 'impossible_join')
				return true
			else
				notif('StaffDetector', string.format('Spectator %s joined from %s', plr.Name, friend), 20, 'warning')
			end
		end
	end
	
	local function playerAdded(plr)
		joined[plr.UserId] = plr.Name
		if plr == lplr then return end
	
		if table.find(blacklisteduserids, plr.UserId) or table.find(Users.ListEnabled, tostring(plr.UserId)) then
			staffFunction(plr, 'blacklisted_user')
		elseif getRole(plr, 5774246) >= 100 then
			staffFunction(plr, 'staff_role')
		else
			local connection
			connection = plr:GetAttributeChangedSignal('Spectator'):Connect(function()
				checkJoin(plr, connection)
			end)
			StaffDetector:Clean(connection)
			if checkJoin(plr, connection) then
				return
			end
	
			if not plr:GetAttribute('ClanTag') then
				plr:GetAttributeChangedSignal('ClanTag'):Wait()
			end
	
			if table.find(blacklistedclans, plr:GetAttribute('ClanTag')) and vape.Loaded and Clans.Enabled then
				connection:Disconnect()
				staffFunction(plr, 'blacklisted_clan_'..plr:GetAttribute('ClanTag'):lower())
			end
		end
	end
	
	StaffDetector = vape.Categories.Utility:CreateModule({
		Name = 'StaffDetector',
		Function = function(callback)
			if callback then
				StaffDetector:Clean(playersService.PlayerAdded:Connect(playerAdded))
				for _, v in playersService:GetPlayers() do
					task.spawn(playerAdded, v)
				end
			else
				table.clear(joined)
			end
		end,
		Tooltip = 'Detects people with a staff rank ingame'
	})
	Mode = StaffDetector:CreateDropdown({
		Name = 'Mode',
		List = {'Notify', 'Profile', 'Requeue', 'AutoConfig', 'Uninject'},
		Function = function(val)
			if Profile.Object then
				Profile.Object.Visible = val == 'Profile'
			end
		end
	})
	Clans = StaffDetector:CreateToggle({
		Name = 'Blacklist clans',
		Default = false
	})
	Party = StaffDetector:CreateToggle({
		Name = 'Leave party'
	})
	Profile = StaffDetector:CreateTextBox({
		Name = 'Profile',
		Default = 'default',
		Darker = true,
		Visible = false
	})
	Users = StaffDetector:CreateTextList({
		Name = 'Users',
		Placeholder = 'player (userid)'
	})
	

end)
	
run(function()
	TrapDisabler = vape.Categories.Utility:CreateModule({
		Name = 'TrapDisabler',
		Tooltip = 'Disables Snap Traps -- FIXED THIS MODULE'
	})
end)
	
run(function()
local afk	
afk = vape.Categories.Minigames:CreateModule({
		Name = 'Anti-AFK',
		Function = function(callback)
			if callback then
				for _, v in getconnections(lplr.Idled) do
					v:Disconnect()
				end
	
				for _, v in getconnections(runService.Heartbeat) do
					if type(v.Function) == 'function' and table.find(debug.getconstants(v.Function), remotes.AfkStatus) then
						v:Disconnect()
					end
				end
	
				repeat 
				bedwars.Client:Get(remotes.AfkStatus):SendToServer({
					afk = false
				}) 
				task.wait(0.001)
				until not afk.Enabled
			end
		end,
		Tooltip = 'Lets you stay ingame without getting kicked'
	})
end)
	
run(function()
	local AutoSuffocate
	local Range
	local LimitItem
	local InstantSuffocate
	local SmartMode
	
	local function fixPosition(pos)
		return bedwars.BlockController:getBlockPosition(pos) * 3
	end
	
	local function countSurroundingBlocks(pos)
		local count = 0
		for _, side in Enum.NormalId:GetEnumItems() do
			if side == Enum.NormalId.Top or side == Enum.NormalId.Bottom then continue end
			local checkPos = fixPosition(pos + Vector3.fromNormalId(side) * 2)
			if getPlacedBlock(checkPos) then
				count += 1
			end
		end
		return count
	end
	
	local function isInVoid(pos)
		for i = 1, 10 do
			local checkPos = fixPosition(pos - Vector3.new(0, i * 3, 0))
			if getPlacedBlock(checkPos) then
				return false
			end
		end
		return true
	end
	
	local function getSmartSuffocationBlocks(ent)
		local rootPos = ent.RootPart.Position
		local headPos = ent.Head.Position
		local needPlaced = {}
		local surroundingBlocks = countSurroundingBlocks(rootPos)
		local inVoid = isInVoid(rootPos)
		
		if surroundingBlocks >= 1 and surroundingBlocks <= 2 then
			for _, side in Enum.NormalId:GetEnumItems() do
				if side == Enum.NormalId.Top or side == Enum.NormalId.Bottom then continue end
				local sidePos = fixPosition(rootPos + Vector3.fromNormalId(side) * 2)
				if not getPlacedBlock(sidePos) then
					table.insert(needPlaced, sidePos)
				end
			end
			table.insert(needPlaced, fixPosition(headPos))
			table.insert(needPlaced, fixPosition(rootPos - Vector3.new(0, 3, 0)))
		
		elseif inVoid then
			table.insert(needPlaced, fixPosition(rootPos - Vector3.new(0, 3, 0)))
			table.insert(needPlaced, fixPosition(headPos + Vector3.new(0, 3, 0)))
			for _, side in Enum.NormalId:GetEnumItems() do
				if side == Enum.NormalId.Top or side == Enum.NormalId.Bottom then continue end
				local sidePos = fixPosition(rootPos + Vector3.fromNormalId(side) * 2)
				table.insert(needPlaced, sidePos)
			end
			table.insert(needPlaced, fixPosition(headPos))
		
		elseif surroundingBlocks == 3 then
			for _, side in Enum.NormalId:GetEnumItems() do
				if side == Enum.NormalId.Top or side == Enum.NormalId.Bottom then continue end
				local sidePos = fixPosition(rootPos + Vector3.fromNormalId(side) * 2)
				if not getPlacedBlock(sidePos) then
					table.insert(needPlaced, sidePos)
				end
			end
			table.insert(needPlaced, fixPosition(headPos))
			table.insert(needPlaced, fixPosition(rootPos - Vector3.new(0, 3, 0)))
		
		elseif surroundingBlocks >= 4 then
			table.insert(needPlaced, fixPosition(headPos))
			table.insert(needPlaced, fixPosition(rootPos - Vector3.new(0, 3, 0)))
		
		else
			table.insert(needPlaced, fixPosition(rootPos - Vector3.new(0, 3, 0)))
			for _, side in Enum.NormalId:GetEnumItems() do
				if side == Enum.NormalId.Top or side == Enum.NormalId.Bottom then continue end
				local sidePos = fixPosition(rootPos + Vector3.fromNormalId(side) * 2)
				table.insert(needPlaced, sidePos)
			end
			table.insert(needPlaced, fixPosition(headPos))
		end
		
		return needPlaced
	end
	
	local function getBasicSuffocationBlocks(ent)
		local needPlaced = {}
		
		for _, side in Enum.NormalId:GetEnumItems() do
			side = Vector3.fromNormalId(side)
			if side.Y ~= 0 then continue end
			
			side = fixPosition(ent.RootPart.Position + side * 2)
			if not getPlacedBlock(side) then
				table.insert(needPlaced, side)
			end
		end
		
		if #needPlaced < 3 then
			table.insert(needPlaced, fixPosition(ent.Head.Position))
			table.insert(needPlaced, fixPosition(ent.RootPart.Position - Vector3.new(0, 1, 0)))
		end
		
		return needPlaced
	end
	
	AutoSuffocate = vape.Categories.World:CreateModule({
		Name = 'AutoSuffocate',
		Function = function(callback)
			if callback then
				repeat
					local item = store.hand.toolType == 'block' and store.hand.tool.Name or not LimitItem.Enabled and getWool()
	
					if item then
						local plrs = entitylib.AllPosition({
							Part = 'RootPart',
							Range = Range.Value,
							Players = true
						})
	
						for _, ent in plrs do
							local needPlaced = SmartMode.Enabled and getSmartSuffocationBlocks(ent) or getBasicSuffocationBlocks(ent)
	
							if InstantSuffocate.Enabled then
								for _, pos in needPlaced do
									if not getPlacedBlock(pos) then
										task.spawn(bedwars.placeBlock, pos, item)
									end
								end
							else
								for _, pos in needPlaced do
									if not getPlacedBlock(pos) then
										task.spawn(bedwars.placeBlock, pos, item)
										break
									end
								end
							end
						end
					end
	
					task.wait(InstantSuffocate.Enabled and 0.05 or 0.09)
				until not AutoSuffocate.Enabled
			end
		end,
		Tooltip = 'Places blocks on nearby confined entities'
	})
	Range = AutoSuffocate:CreateSlider({
		Name = 'Range',
		Min = 1,
		Max = 20,
		Default = 20,
		Function = function() end,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	SmartMode = AutoSuffocate:CreateToggle({
		Name = 'Smart Mode',
		Default = true,
		Tooltip = 'Detects scenarios: walls, void, corners, open areas'
	})
	LimitItem = AutoSuffocate:CreateToggle({
		Name = 'Limit to Items',
		Default = true,
		Function = function() end
	})
	InstantSuffocate = AutoSuffocate:CreateToggle({
		Name = 'Instant Suffocate',
		Function = function() end,
		Tooltip = 'Instantly places all suffocation blocks instead of one at a time'
	})
end)
	
run(function()

	local old, event
	
	local function switchHotbarItem(block)
		if block and not block:GetAttribute('NoBreak') and not block:GetAttribute('Team'..(lplr:GetAttribute('Team') or 0)..'NoBreak') then
			local tool, slot = store.tools[bedwars.ItemMeta[block.Name].block.breakType], nil
			if tool then
				for i, v in store.inventory.hotbar do
					if v.item and v.item.itemType == tool.itemType then slot = i - 1 break end
				end
	
				if hotbarSwitch(slot) then
					if inputService:IsMouseButtonPressed(0) then 
						event:Fire() 
					end
					return true
				end
			end
		end
	end
	
	AutoTool = vape.Categories.World:CreateModule({
		Name = 'AutoTool',
		Function = function(callback)
			if callback then
				event = Instance.new('BindableEvent')
				AutoTool:Clean(event)
				AutoTool:Clean(event.Event:Connect(function()
					contextActionService:CallFunction('block-break', Enum.UserInputState.Begin, newproxy(true))
				end))
				old = bedwars.BlockBreaker.hitBlock
				bedwars.BlockBreaker.hitBlock = function(self, maid, raycastparams, ...)
					local block = self.clientManager:getBlockSelector():getMouseInfo(1, {ray = raycastparams})
					if switchHotbarItem(block and block.target and block.target.blockInstance or nil) then return end
					return old(self, maid, raycastparams, ...)
				end
			else
				bedwars.BlockBreaker.hitBlock = old
				old = nil
			end
		end,
		Tooltip = 'Automatically selects the correct tool'
	})
end)
	
run(function()
	local BedProtector
	
	local function getBedNear()
		local localPosition = entitylib.isAlive and entitylib.character.RootPart.Position or Vector3.zero
		for _, v in collectionService:GetTagged('bed') do
			if (localPosition - v.Position).Magnitude < 20 and v:GetAttribute('Team'..(lplr:GetAttribute('Team') or -1)..'NoBreak') then
				return v
			end
		end
	end
	
	local function getBlocks()
		local blocks = {}
		for _, item in store.inventory.inventory.items do
			local block = bedwars.ItemMeta[item.itemType].block
			if block then
				table.insert(blocks, {item.itemType, block.health})
			end
		end
		table.sort(blocks, function(a, b) 
			return a[2] > b[2]
		end)
		return blocks
	end
	
	local function getPyramid(size, grid)
		local positions = {}
		for h = size, 0, -1 do
			for w = h, 0, -1 do
				table.insert(positions, Vector3.new(w, (size - h), ((h + 1) - w)) * grid)
				table.insert(positions, Vector3.new(w * -1, (size - h), ((h + 1) - w)) * grid)
				table.insert(positions, Vector3.new(w, (size - h), (h - w) * -1) * grid)
				table.insert(positions, Vector3.new(w * -1, (size - h), (h - w) * -1) * grid)
			end
		end
		return positions
	end
	
	BedProtector = vape.Categories.World:CreateModule({
		Name = 'BedProtector',
		Function = function(callback)
			if callback then
				local bed = getBedNear()
				bed = bed and bed.Position or nil
				if bed then
					for i, block in getBlocks() do
						for _, pos in getPyramid(i, 3) do
							if not BedProtector.Enabled then break end
							if getPlacedBlock(bed + pos) then continue end
							bedwars.placeBlock(bed + pos, block[1], false)
						end
					end
					if BedProtector.Enabled then 
						BedProtector:Toggle() 
					end
				else
					notif('BedProtector', 'Unable to locate bed', 5)
					BedProtector:Toggle()
				end
			end
		end,
		Tooltip = 'Automatically places strong blocks around the bed.'
	})
end)
	
run(function()
	local ChestSteal
	local Range
	local Open
	local Skywars
	local Delays = {}
	
	local function lootChest(chest)
		chest = chest and chest.Value or nil
		local chestitems = chest and chest:GetChildren() or {}
		if #chestitems > 1 and (Delays[chest] or 0) < tick() then
			Delays[chest] = tick() + 0.2
			bedwars.Client:GetNamespace('Inventory'):Get('SetObservedChest'):SendToServer(chest)
	
			for _, v in chestitems do
				if v:IsA('Accessory') then
					task.spawn(function()
						pcall(function()
							bedwars.Client:GetNamespace('Inventory'):Get('ChestGetItem'):CallServer(chest, v)
						end)
					end)
				end
			end
	
			bedwars.Client:GetNamespace('Inventory'):Get('SetObservedChest'):SendToServer(nil)
		end
	end
	
	ChestSteal = vape.Categories.World:CreateModule({
		Name = 'ChestSteal',
		Function = function(callback)
			if callback then
				local chests = collection('chest', ChestSteal)
				repeat task.wait(0.1) until store.queueType ~= 'bedwars_test'
				if (not Skywars.Enabled) or store.queueType:find('skywars') then
					repeat
						if entitylib.isAlive and store.matchState ~= 2 then
							if Open.Enabled then
								if bedwars.AppController:isAppOpen('ChestApp') then
									lootChest(lplr.Character:FindFirstChild('ObservedChestFolder'))
								end
							else
								local localPosition = entitylib.character.RootPart.Position
								for _, v in chests do
									if (localPosition - v.Position).Magnitude <= Range.Value then
										lootChest(v:FindFirstChild('ChestFolderValue'))
									end
								end
							end
						end
						task.wait(0.1)
					until not ChestSteal.Enabled
				end
			end
		end,
		Tooltip = 'Grabs items from near chests.'
	})
	Range = ChestSteal:CreateSlider({
		Name = 'Range',
		Min = 0,
		Max = 18,
		Default = 18,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	Open = ChestSteal:CreateToggle({Name = 'GUI Check'})
	Skywars = ChestSteal:CreateToggle({
		Name = 'Only Skywars',
		Function = function()
			if ChestSteal.Enabled then
				ChestSteal:Toggle()
				ChestSteal:Toggle()
			end
		end,
		Default = false
	})
end)
	
run(function()
	local Schematica
	local File
	local Mode
	local Transparency
	local parts, guidata, poschecklist = {}, {}, {}
	local point1, point2
	
	for x = -3, 3, 3 do
		for y = -3, 3, 3 do
			for z = -3, 3, 3 do
				if Vector3.new(x, y, z) ~= Vector3.zero then
					table.insert(poschecklist, Vector3.new(x, y, z))
				end
			end
		end
	end
	
	local function checkAdjacent(pos)
		for _, v in poschecklist do
			if getPlacedBlock(pos + v) then return true end
		end
		return false
	end
	
	local function getPlacedBlocksInPoints(s, e)
		local list, blocks = {}, bedwars.BlockController:getStore()
		for x = (e.X > s.X and s.X or e.X), (e.X > s.X and e.X or s.X) do
			for y = (e.Y > s.Y and s.Y or e.Y), (e.Y > s.Y and e.Y or s.Y) do
				for z = (e.Z > s.Z and s.Z or e.Z), (e.Z > s.Z and e.Z or s.Z) do
					local vec = Vector3.new(x, y, z)
					local block = blocks:getBlockAt(vec)
					if block and block:GetAttribute('PlacedByUserId') == lplr.UserId then
						list[vec] = block
					end
				end
			end
		end
		return list
	end
	
	local function loadMaterials()
		for _, v in guidata do 
			v:Destroy() 
		end
		local suc, read = pcall(function() 
			return isfile(File.Value) and httpService:JSONDecode(readfile(File.Value)) 
		end)
	
		if suc and read then
			local items = {}
			for _, v in read do 
				items[v[2]] = (items[v[2]] or 0) + 1 
			end
			
			for i, v in items do
				local holder = Instance.new('Frame')
				holder.Size = UDim2.new(1, 0, 0, 32)
				holder.BackgroundTransparency = 1
				holder.Parent = Schematica.Children
				local icon = Instance.new('ImageLabel')
				icon.Size = UDim2.fromOffset(24, 24)
				icon.Position = UDim2.fromOffset(4, 4)
				icon.BackgroundTransparency = 1
				icon.Image = bedwars.getIcon({itemType = i}, true)
				icon.Parent = holder
				local text = Instance.new('TextLabel')
				text.Size = UDim2.fromOffset(100, 32)
				text.Position = UDim2.fromOffset(32, 0)
				text.BackgroundTransparency = 1
				text.Text = (bedwars.ItemMeta[i] and bedwars.ItemMeta[i].displayName or i)..': '..v
				text.TextXAlignment = Enum.TextXAlignment.Left
				text.TextColor3 = uipallet.Text
				text.TextSize = 14
				text.FontFace = uipallet.Font
				text.Parent = holder
				table.insert(guidata, holder)
			end
			table.clear(read)
			table.clear(items)
		end
	end
	
	local function save()
		if point1 and point2 then
			local tab = getPlacedBlocksInPoints(point1, point2)
			local savetab = {}
			point1 = point1 * 3
			for i, v in tab do
				i = bedwars.BlockController:getBlockPosition(CFrame.lookAlong(point1, entitylib.character.RootPart.CFrame.LookVector):PointToObjectSpace(i * 3)) * 3
				table.insert(savetab, {
					{
						x = i.X, 
						y = i.Y, 
						z = i.Z
					}, 
					v.Name
				})
			end
			point1, point2 = nil, nil
			writefile(File.Value, httpService:JSONEncode(savetab))
			notif('Schematica', 'Saved '..getTableSize(tab)..' blocks', 5)
			loadMaterials()
			table.clear(tab)
			table.clear(savetab)
		else
			local mouseinfo = bedwars.BlockBreaker.clientManager:getBlockSelector():getMouseInfo(0)
			if mouseinfo and mouseinfo.target then
				if point1 then
					point2 = mouseinfo.target.blockRef.blockPosition
					notif('Schematica', 'Selected position 2, toggle again near position 1 to save it', 3)
				else
					point1 = mouseinfo.target.blockRef.blockPosition
					notif('Schematica', 'Selected position 1', 3)
				end
			end
		end
	end
	
	local function load(read)
		local mouseinfo = bedwars.BlockBreaker.clientManager:getBlockSelector():getMouseInfo(0)
		if mouseinfo and mouseinfo.target then
			local position = CFrame.new(mouseinfo.placementPosition * 3) * CFrame.Angles(0, math.rad(math.round(math.deg(math.atan2(-entitylib.character.RootPart.CFrame.LookVector.X, -entitylib.character.RootPart.CFrame.LookVector.Z)) / 45) * 45), 0)
	
			for _, v in read do
				local blockpos = bedwars.BlockController:getBlockPosition((position * CFrame.new(v[1].x, v[1].y, v[1].z)).p) * 3
				if parts[blockpos] then continue end
				local handler = bedwars.BlockController:getHandlerRegistry():getHandler(v[2]:find('wool') and getWool() or v[2])
				if handler then
					local part = handler:place(blockpos / 3, 0)
					part.Transparency = Transparency.Value
					part.CanCollide = false
					part.Anchored = true
					part.Parent = workspace
					parts[blockpos] = part
				end
			end
			table.clear(read)
	
			repeat
				if entitylib.isAlive then
					local localPosition = entitylib.character.RootPart.Position
					for i, v in parts do
						if (i - localPosition).Magnitude < 60 and checkAdjacent(i) then
							if not Schematica.Enabled then break end
							if not getItem(v.Name) then continue end
							bedwars.placeBlock(i, v.Name, false)
							task.delay(0.1, function()
								local block = getPlacedBlock(i)
								if block then
									v:Destroy()
									parts[i] = nil
								end
							end)
						end
					end
				end
				task.wait(0.1)
			until getTableSize(parts) <= 0
	
			if getTableSize(parts) <= 0 and Schematica.Enabled then
				notif('Schematica', 'Finished building', 5)
				Schematica:Toggle()
			end
		end
	end
	
	Schematica = vape.Categories.World:CreateModule({
		Name = 'Schematica',
		Function = function(callback)
			if callback then
				if not File.Value:find('.json') then
					notif('Schematica', 'Invalid file', 3)
					Schematica:Toggle()
					return
				end
	
				if Mode.Value == 'Save' then
					save()
					Schematica:Toggle()
				else
					local suc, read = pcall(function() 
						return isfile(File.Value) and httpService:JSONDecode(readfile(File.Value)) 
					end)
	
					if suc and read then
						load(read)
					else
						notif('Schematica', 'Missing / corrupted file', 3)
						Schematica:Toggle()
					end
				end
			else
				for _, v in parts do 
					v:Destroy() 
				end
				table.clear(parts)
			end
		end,
		Tooltip = 'Save and load placements of buildings'
	})
	File = Schematica:CreateTextBox({
		Name = 'File',
		Function = function()
			loadMaterials()
			point1, point2 = nil, nil
		end
	})
	Mode = Schematica:CreateDropdown({
		Name = 'Mode',
		List = {'Load', 'Save'}
	})
	Transparency = Schematica:CreateSlider({
		Name = 'Transparency',
		Min = 0,
		Max = 1,
		Default = 0.7,
		Decimal = 10,
		Function = function(val)
			for _, v in parts do 
				v.Transparency = val 
			end
		end
	})
end)
	
run(function()
	local ArmorSwitch
	local Mode
	local Targets
	local Range
	
	ArmorSwitch = vape.Categories.Inventory:CreateModule({
		Name = 'ArmorSwitch',
		Function = function(callback)
			if callback then
				if Mode.Value == 'Toggle' then
					repeat
						local state = entitylib.EntityPosition({
							Part = 'RootPart',
							Range = Range.Value,
							Players = Targets.Players.Enabled,
							NPCs = Targets.NPCs.Enabled,
							Wallcheck = Targets.Walls.Enabled
						}) and true or false
	
						for i = 0, 2 do
							if (store.inventory.inventory.armor[i + 1] ~= 'empty') ~= state and ArmorSwitch.Enabled then
								bedwars.Store:dispatch({
									type = 'InventorySetArmorItem',
									item = store.inventory.inventory.armor[i + 1] == 'empty' and state and getBestArmor(i) or nil,
									armorSlot = i
								})
								vapeEvents.InventoryChanged.Event:Wait()
							end
						end
						task.wait(0.1)
					until not ArmorSwitch.Enabled
				else
					ArmorSwitch:Toggle()
					for i = 0, 2 do
						bedwars.Store:dispatch({
							type = 'InventorySetArmorItem',
							item = store.inventory.inventory.armor[i + 1] == 'empty' and getBestArmor(i) or nil,
							armorSlot = i
						})
						vapeEvents.InventoryChanged.Event:Wait()
					end
				end
			end
		end,
		Tooltip = 'Puts on / takes off armor when toggled for baiting.'
	})
	Mode = ArmorSwitch:CreateDropdown({
		Name = 'Mode',
		List = {'Toggle', 'On Key'}
	})
	Targets = ArmorSwitch:CreateTargets({
		Players = true,
		NPCs = true
	})
	Range = ArmorSwitch:CreateSlider({
		Name = 'Range',
		Min = 1,
		Max = 30,
		Default = 30,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
end)
	
run(function()
	local AutoBank
	local UIToggle
	local UI
	local Chests
	local Items = {}
	
	local function addItem(itemType, shop)
		local item = Instance.new('ImageLabel')
		item.Image = bedwars.getIcon({itemType = itemType}, true)
		item.Size = UDim2.fromOffset(32, 32)
		item.Name = itemType
		item.BackgroundTransparency = 1
		item.LayoutOrder = #UI:GetChildren()
		item.Parent = UI
		local itemtext = Instance.new('TextLabel')
		itemtext.Name = 'Amount'
		itemtext.Size = UDim2.fromScale(1, 1)
		itemtext.BackgroundTransparency = 1
		itemtext.Text = ''
		itemtext.TextColor3 = Color3.new(1, 1, 1)
		itemtext.TextSize = 16
		itemtext.TextStrokeTransparency = 0.3
		itemtext.Font = Enum.Font.Arial
		itemtext.Parent = item
		Items[itemType] = {Object = itemtext, Type = shop}
	end
	
	local function refreshBank(echest)
		for i, v in Items do
			local item = echest:FindFirstChild(i)
			v.Object.Text = item and item:GetAttribute('Amount') or ''
		end
	end
	
	local function nearChest()
		if entitylib.isAlive then
			local pos = entitylib.character.RootPart.Position
			for _, chest in Chests do
				if (chest.Position - pos).Magnitude < 20 then
					return true
				end
			end
		end
	end
	
	local function handleState()
		local chest = replicatedStorage.Inventories:FindFirstChild(lplr.Name..'_personal')
		if not chest then return end
	
		local mapCF = workspace.MapCFrames:FindFirstChild((lplr:GetAttribute('Team') or 1)..'_spawn')
		if mapCF and (entitylib.character.RootPart.Position - mapCF.Value.Position).Magnitude < 80 then
			for _, v in chest:GetChildren() do
				local item = Items[v.Name]
				if item then
					task.spawn(function()
						bedwars.Client:GetNamespace('Inventory'):Get('ChestGetItem'):CallServer(chest, v)
						refreshBank(chest)
					end)
				end
			end
		else
			for _, v in store.inventory.inventory.items do
				local item = Items[v.itemType]
				if item then
					task.spawn(function()
						bedwars.Client:GetNamespace('Inventory'):Get('ChestGiveItem'):CallServer(chest, v.tool)
						refreshBank(chest)
					end)
				end
			end
		end
	end
	
	AutoBank = vape.Categories.Inventory:CreateModule({
		Name = 'AutoBank',
		Function = function(callback)
			if callback then
				Chests = collection('personal-chest', AutoBank)
				UI = Instance.new('Frame')
				UI.Size = UDim2.new(1, 0, 0, 32)
				UI.Position = UDim2.fromOffset(0, -240)
				UI.BackgroundTransparency = 1
				UI.Visible = UIToggle.Enabled
				UI.Parent = vape.gui
				AutoBank:Clean(UI)
				local Sort = Instance.new('UIListLayout')
				Sort.FillDirection = Enum.FillDirection.Horizontal
				Sort.HorizontalAlignment = Enum.HorizontalAlignment.Center
				Sort.SortOrder = Enum.SortOrder.LayoutOrder
				Sort.Parent = UI
				addItem('iron', true)
				addItem('gold', true)
				addItem('diamond', false)
				addItem('emerald', true)
				addItem('void_crystal', true)
	
				repeat
					local hotbar = lplr.PlayerGui:FindFirstChild('hotbar')
					hotbar = hotbar and hotbar['1']:FindFirstChild('HotbarHealthbarContainer')
					if hotbar then
						UI.Position = UDim2.fromOffset(0, (hotbar.AbsolutePosition.Y + guiService:GetGuiInset().Y) - 40)
					end
	
					local newState = nearChest()
					if newState then
						handleState()
					end
	
					task.wait(0.1)
				until (not AutoBank.Enabled)
			else
				table.clear(Items)
			end
		end,
		Tooltip = 'Automatically puts resources in ender chest'
	})
	UIToggle = AutoBank:CreateToggle({
		Name = 'UI',
		Function = function(callback)
			if AutoBank.Enabled then
				UI.Visible = callback
			end
		end,
		Default = true
	})
end)
	
run(function()
	local AutoBuy
	local Sword
	local Armor
	local Upgrades
	local TierCheck
	local BedwarsCheck
	local GUI
	local SmartCheck
	local Custom = {}
	local CustomPost = {}
	local UpgradeToggles = {}
	local Functions, id = {}
	local Callbacks = {Custom, Functions, CustomPost}
	local npctick = tick()
	local swords = {
		'wood_sword',
		'stone_sword',
		'iron_sword',
		'diamond_sword',
		'emerald_sword'
	}
	
	local armors = {
		'none',
		'leather_chestplate',
		'iron_chestplate',
		'diamond_chestplate',
		'emerald_chestplate'
	}
	
	local axes = {
		'none',
		'wood_axe',
		'stone_axe',
		'iron_axe',
		'diamond_axe'
	}
	
	local pickaxes = {
		'none',
		'wood_pickaxe',
		'stone_pickaxe',
		'iron_pickaxe',
		'diamond_pickaxe'
	}
	
	local function getShopNPC()
		local shop, items, upgrades, newid = nil, false, false, nil
		if entitylib.isAlive then
			local localPosition = entitylib.character.RootPart.Position
			for _, v in store.shop do
				if (v.RootPart.Position - localPosition).Magnitude <= 20 then
					shop = v.Upgrades or v.Shop or nil
					upgrades = upgrades or v.Upgrades
					items = items or v.Shop
					newid = v.Shop and v.Id or newid
				end
			end
		end
		return shop, items, upgrades, newid
	end
	
	local function canBuy(item, currencytable, amount)
		amount = amount or 1
		if not currencytable[item.currency] then
			local currency = getItem(item.currency)
			currencytable[item.currency] = currency and currency.amount or 0
		end
		if item.ignoredByKit and table.find(item.ignoredByKit, store.equippedKit or '') then return false end
		if item.lockedByForge or item.disabled then return false end
		if item.require and item.require.teamUpgrade then
			if (bedwars.Store:getState().Bedwars.teamUpgrades[item.require.teamUpgrade.upgradeId] or -1) < item.require.teamUpgrade.lowestTierIndex then
				return false
			end
		end
		return currencytable[item.currency] >= (item.price * amount)
	end
	
	local function buyItem(item, currencytable)
		if not id then return end
		notif('AutoBuy', 'Bought '..bedwars.ItemMeta[item.itemType].displayName, 3)
		bedwars.Client:Get('BedwarsPurchaseItem'):CallServerAsync({
			shopItem = item,
			shopId = id
		}):andThen(function(suc)
			if suc then
				bedwars.SoundManager:playSound(bedwars.SoundList.BEDWARS_PURCHASE_ITEM)
				bedwars.Store:dispatch({
					type = 'BedwarsAddItemPurchased',
					itemType = item.itemType
				})
				bedwars.BedwarsShopController.alreadyPurchasedMap[item.itemType] = true
			end
		end)
		currencytable[item.currency] -= item.price
	end
	
	local function buyUpgrade(upgradeType, currencytable)

		return
	end
	
	local function buyTool(tool, tools, currencytable)
		local bought, buyable = false
		tool = tool and table.find(tools, tool.itemType) and table.find(tools, tool.itemType) + 1 or math.huge
	
		for i = tool, #tools do
			local v = bedwars.Shop.getShopItem(tools[i], lplr)
			if canBuy(v, currencytable) then
				if SmartCheck.Enabled and bedwars.ItemMeta[tools[i]].breakBlock and i > 2 then
					if Armor.Enabled then
						local currentarmor = store.inventory.inventory.armor[2]
						currentarmor = currentarmor and currentarmor ~= 'empty' and currentarmor.itemType or 'none'
						if (table.find(armors, currentarmor) or 3) < 3 then break end
					end
					if Sword.Enabled then
						if store.tools.sword and (table.find(swords, store.tools.sword.itemType) or 2) < 2 then break end
					end
				end
				bought = true
				buyable = v
			end
			if TierCheck.Enabled and v.nextTier then break end
		end
	
		if buyable then
			buyItem(buyable, currencytable)
		end
	
		return bought
	end
	
	AutoBuy = vape.Categories.Inventory:CreateModule({
		Name = 'AutoBuy',
		Function = function(callback)
			if callback then
				repeat task.wait(0.1) until store.queueType ~= 'bedwars_test'
				if BedwarsCheck.Enabled and not store.queueType:find('bedwars') then return end
	
				local lastupgrades
				AutoBuy:Clean(vapeEvents.InventoryAmountChanged.Event:Connect(function()
					if (npctick - tick()) > 1 then npctick = tick() end
				end))
	
				repeat
					local npc, shop, upgrades, newid = getShopNPC()
					id = newid
					if GUI.Enabled then
						if not (bedwars.AppController:isAppOpen('BedwarsItemShopApp') or bedwars.AppController:isAppOpen('TeamUpgradeApp')) then
							npc = nil
						end
					end
	
					if npc and lastupgrades ~= upgrades then
						if (npctick - tick()) > 1 then npctick = tick() end
						lastupgrades = upgrades
					end
	
					if npc and npctick <= tick() and store.matchState ~= 2 and store.shopLoaded then
						local currencytable = {}
						local waitcheck
						for _, tab in Callbacks do
							for _, callback in tab do
								if callback(currencytable, shop, upgrades) then
									waitcheck = true
								end
							end
						end
						npctick = tick() + (waitcheck and 0.4 or math.huge)
					end
	
					task.wait(0.1)
				until not AutoBuy.Enabled
			else
				npctick = tick()
			end
		end,
		Tooltip = 'Automatically buys items when you go near the shop'
	})
	Sword = AutoBuy:CreateToggle({
		Name = 'Buy Sword',
		Function = function(callback)
			npctick = tick()
			Functions[2] = callback and function(currencytable, shop)
				if not shop then return end
	
				if store.equippedKit == 'dasher' then
					swords = {
						[1] = 'wood_dao',
						[2] = 'stone_dao',
						[3] = 'iron_dao',
						[4] = 'diamond_dao',
						[5] = 'emerald_dao'
					}
				elseif store.equippedKit == 'ice_queen' then
					swords[5] = 'ice_sword'
				elseif store.equippedKit == 'ember' then
					swords[5] = 'infernal_saber'
				elseif store.equippedKit == 'lumen' then
					swords[5] = 'light_sword'
				end
	
				return buyTool(store.tools.sword, swords, currencytable)
			end or nil
		end
	})
	Armor = AutoBuy:CreateToggle({
		Name = 'Buy Armor',
		Function = function(callback)
			npctick = tick()
			Functions[1] = callback and function(currencytable, shop)
				if not shop then return end
				local currentarmor = store.inventory.inventory.armor[2] ~= 'empty' and store.inventory.inventory.armor[2] or getBestArmor(1)
				currentarmor = currentarmor and currentarmor.itemType or 'none'
				return buyTool({itemType = currentarmor}, armors, currencytable)
			end or nil
		end,
		Default = true
	})
	AutoBuy:CreateToggle({
		Name = 'Buy Axe',
		Function = function(callback)
			npctick = tick()
			Functions[3] = callback and function(currencytable, shop)
				if not shop then return end
				return buyTool(store.tools.wood or {itemType = 'none'}, axes, currencytable)
			end or nil
		end
	})
	AutoBuy:CreateToggle({
		Name = 'Buy Pickaxe',
		Function = function(callback)
			npctick = tick()
			Functions[4] = callback and function(currencytable, shop)
				if not shop then return end
				return buyTool(store.tools.stone, pickaxes, currencytable)
			end or nil
		end
	})
	local count = 0
	for i, v in bedwars.TeamUpgradeMeta do
		local toggleCount = count
		table.insert(UpgradeToggles, AutoBuy:CreateToggle({
			Name = 'Buy '..(v.name == 'Armor' and 'Protection' or v.name),
			Function = function(callback)
				npctick = tick()
				Functions[5 + toggleCount + (v.name == 'Armor' and 20 or 0)] = callback and function(currencytable, shop, upgrades)
					if not upgrades then return end
					if v.disabledInQueue and table.find(v.disabledInQueue, store.queueType) then return end
					return buyUpgrade(i, currencytable)
				end or nil
			end,
			Darker = true,
			Default = (i == 'ARMOR' or i == 'DAMAGE')
		}))
		count += 1
	end
	TierCheck = AutoBuy:CreateToggle({Name = 'Tier Check'})
	BedwarsCheck = AutoBuy:CreateToggle({
		Name = 'Only Bedwars',
		Function = function()
			if AutoBuy.Enabled then
				AutoBuy:Toggle()
				AutoBuy:Toggle()
			end
		end,
		Default = true
	})
	GUI = AutoBuy:CreateToggle({Name = 'GUI check'})
	SmartCheck = AutoBuy:CreateToggle({
		Name = 'Smart check',
		Default = true,
		Tooltip = 'Buys iron armor before iron axe'
	})
	AutoBuy:CreateTextList({
		Name = 'Item',
		Placeholder = 'priority/item/amount/after',
		Function = function(list)
			table.clear(Custom)
			table.clear(CustomPost)
			for _, entry in list do
				local tab = entry:split('/')
				local ind = tonumber(tab[1])
				if ind then
					(tab[4] and CustomPost or Custom)[ind] = function(currencytable, shop)
						if not shop then return end
	
						local v = bedwars.Shop.getShopItem(tab[2], lplr)
						if v then
							local item = getItem(tab[2] == 'wool_white' and bedwars.Shop.getTeamWool(lplr:GetAttribute('Team')) or tab[2])
							item = (item and tonumber(tab[3]) - item.amount or tonumber(tab[3])) // v.amount
							if item > 0 and canBuy(v, currencytable, item) then
								for _ = 1, item do
									buyItem(v, currencytable)
								end
								return true
							end
						end
					end
				end
			end
		end
	})
end)
	
run(function()
	local AutoConsume
	local Health
	local SpeedPotion
	local Apple
	local ShieldPotion
	
	local function consumeCheck(attribute)
		if entitylib.isAlive then
			if SpeedPotion.Enabled and (not attribute or attribute == 'StatusEffect_speed') then
				local speedpotion = getItem('speed_potion')
				if speedpotion and (not lplr.Character:GetAttribute('StatusEffect_speed')) then
					for _ = 1, 4 do
						if bedwars.Client:Get(remotes.ConsumeItem):CallServer({item = speedpotion.tool}) then break end
					end
				end
			end
	
			if Apple.Enabled and (not attribute or attribute:find('Health')) then
				if (lplr.Character:GetAttribute('Health') / lplr.Character:GetAttribute('MaxHealth')) <= (Health.Value / 100) then
					local apple = getItem('orange') or (not lplr.Character:GetAttribute('StatusEffect_golden_apple') and getItem('golden_apple')) or getItem('apple')
					
					if apple then
						bedwars.Client:Get(remotes.ConsumeItem):CallServerAsync({
							item = apple.tool
						})
					end
				end
			end
	
			if ShieldPotion.Enabled and (not attribute or attribute:find('Shield')) then
				if (lplr.Character:GetAttribute('Shield_POTION') or 0) == 0 then
					local shield = getItem('big_shield') or getItem('mini_shield')
	
					if shield then
						bedwars.Client:Get(remotes.ConsumeItem):CallServerAsync({
							item = shield.tool
						})
					end
				end
			end
		end
	end
	
	AutoConsume = vape.Categories.Inventory:CreateModule({
		Name = 'AutoConsume',
		Function = function(callback)
			if callback then
				AutoConsume:Clean(vapeEvents.InventoryAmountChanged.Event:Connect(consumeCheck))
				AutoConsume:Clean(vapeEvents.AttributeChanged.Event:Connect(function(attribute)
					if attribute:find('Shield') or attribute:find('Health') or attribute == 'StatusEffect_speed' then
						consumeCheck(attribute)
					end
				end))
				consumeCheck()
			end
		end,
		Tooltip = 'Automatically heals for you when health or shield is under threshold.'
	})
	Health = AutoConsume:CreateSlider({
		Name = 'Health Percent',
		Min = 1,
		Max = 99,
		Default = 70,
		Suffix = '%'
	})
	SpeedPotion = AutoConsume:CreateToggle({
		Name = 'Speed Potions',
		Default = true
	})
	Apple = AutoConsume:CreateToggle({
		Name = 'Apple',
		Default = true
	})
	ShieldPotion = AutoConsume:CreateToggle({
		Name = 'Shield Potions',
		Default = true
	})
end)
	
run(function()
	local AutoHotbar
	local Mode
	local Clear
	local List
	local Active
	
	local function CreateWindow(self)
		local selectedslot = 1
		local window = Instance.new('Frame')
		window.Name = 'HotbarGUI'
		window.Size = UDim2.fromOffset(660, 465)
		window.Position = UDim2.fromScale(0.5, 0.5)
		window.BackgroundColor3 = uipallet.Main
		window.AnchorPoint = Vector2.new(0.5, 0.5)
		window.Visible = false
		window.Parent = vape.gui.ScaledGui
		local title = Instance.new('TextLabel')
		title.Name = 'Title'
		title.Size = UDim2.new(1, -10, 0, 20)
		title.Position = UDim2.fromOffset(math.abs(title.Size.X.Offset), 12)
		title.BackgroundTransparency = 1
		title.Text = 'AutoHotbar'
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextColor3 = uipallet.Text
		title.TextSize = 13
		title.FontFace = uipallet.Font
		title.Parent = window
		local divider = Instance.new('Frame')
		divider.Name = 'Divider'
		divider.Size = UDim2.new(1, 0, 0, 1)
		divider.Position = UDim2.fromOffset(0, 40)
		divider.BackgroundColor3 = color.Light(uipallet.Main, 0.04)
		divider.BorderSizePixel = 0
		divider.Parent = window
		addBlur(window)
		local modal = Instance.new('TextButton')
		modal.Text = ''
		modal.BackgroundTransparency = 1
		modal.Modal = true
		modal.Parent = window
		local corner = Instance.new('UICorner')
		corner.CornerRadius = UDim.new(0, 5)
		corner.Parent = window
		local close = Instance.new('ImageButton')
		close.Name = 'Close'
		close.Size = UDim2.fromOffset(24, 24)
		close.Position = UDim2.new(1, -35, 0, 9)
		close.BackgroundColor3 = Color3.new(1, 1, 1)
		close.BackgroundTransparency = 1
		close.Image = getcustomasset('ReVape/assets/new/close.png')
		close.ImageColor3 = color.Light(uipallet.Text, 0.2)
		close.ImageTransparency = 0.5
		close.AutoButtonColor = false
		close.Parent = window
		close.MouseEnter:Connect(function()
			close.ImageTransparency = 0.3
			tween:Tween(close, TweenInfo.new(0.2), {
				BackgroundTransparency = 0.6
			})
		end)
		close.MouseLeave:Connect(function()
			close.ImageTransparency = 0.5
			tween:Tween(close, TweenInfo.new(0.2), {
				BackgroundTransparency = 1
			})
		end)
		close.MouseButton1Click:Connect(function()
			window.Visible = false
			vape.gui.ScaledGui.ClickGui.Visible = true
		end)
		local closecorner = Instance.new('UICorner')
		closecorner.CornerRadius = UDim.new(1, 0)
		closecorner.Parent = close
		local bigslot = Instance.new('Frame')
		bigslot.Size = UDim2.fromOffset(110, 111)
		bigslot.Position = UDim2.fromOffset(11, 71)
		bigslot.BackgroundColor3 = color.Dark(uipallet.Main, 0.02)
		bigslot.Parent = window
		local bigslotcorner = Instance.new('UICorner')
		bigslotcorner.CornerRadius = UDim.new(0, 4)
		bigslotcorner.Parent = bigslot
		local bigslotstroke = Instance.new('UIStroke')
		bigslotstroke.Color = color.Light(uipallet.Main, 0.034)
		bigslotstroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		bigslotstroke.Parent = bigslot
		local slotnum = Instance.new('TextLabel')
		slotnum.Size = UDim2.fromOffset(80, 20)
		slotnum.Position = UDim2.fromOffset(25, 200)
		slotnum.BackgroundTransparency = 1
		slotnum.Text = 'SLOT 1'
		slotnum.TextColor3 = color.Dark(uipallet.Text, 0.1)
		slotnum.TextSize = 12
		slotnum.FontFace = uipallet.Font
		slotnum.Parent = window
		for i = 1, 9 do
			local slotbkg = Instance.new('TextButton')
			slotbkg.Name = 'Slot'..i
			slotbkg.Size = UDim2.fromOffset(51, 52)
			slotbkg.Position = UDim2.fromOffset(89 + (i * 55), 382)
			slotbkg.BackgroundColor3 = color.Dark(uipallet.Main, 0.02)
			slotbkg.Text = ''
			slotbkg.AutoButtonColor = false
			slotbkg.Parent = window
			local slotimage = Instance.new('ImageLabel')
			slotimage.Size = UDim2.fromOffset(32, 32)
			slotimage.Position = UDim2.new(0.5, -16, 0.5, -16)
			slotimage.BackgroundTransparency = 1
			slotimage.Image = ''
			slotimage.Parent = slotbkg
			local slotcorner = Instance.new('UICorner')
			slotcorner.CornerRadius = UDim.new(0, 4)
			slotcorner.Parent = slotbkg
			local slotstroke = Instance.new('UIStroke')
			slotstroke.Color = color.Light(uipallet.Main, 0.04)
			slotstroke.Thickness = 2
			slotstroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			slotstroke.Enabled = i == selectedslot
			slotstroke.Parent = slotbkg
			slotbkg.MouseEnter:Connect(function()
				slotbkg.BackgroundColor3 = color.Light(uipallet.Main, 0.034)
			end)
			slotbkg.MouseLeave:Connect(function()
				slotbkg.BackgroundColor3 = color.Dark(uipallet.Main, 0.02)
			end)
			slotbkg.MouseButton1Click:Connect(function()
				window['Slot'..selectedslot].UIStroke.Enabled = false
				selectedslot = i
				slotstroke.Enabled = true
				slotnum.Text = 'SLOT '..selectedslot
			end)
			slotbkg.MouseButton2Click:Connect(function()
				local obj = self.Hotbars[self.Selected]
				if obj then
					window['Slot'..i].ImageLabel.Image = ''
					obj.Hotbar[tostring(i)] = nil
					obj.Object['Slot'..i].Image = '	'
				end
			end)
		end
		local searchbkg = Instance.new('Frame')
		searchbkg.Size = UDim2.fromOffset(496, 31)
		searchbkg.Position = UDim2.fromOffset(142, 80)
		searchbkg.BackgroundColor3 = color.Light(uipallet.Main, 0.034)
		searchbkg.Parent = window
		local search = Instance.new('TextBox')
		search.Size = UDim2.new(1, -10, 0, 31)
		search.Position = UDim2.fromOffset(10, 0)
		search.BackgroundTransparency = 1
		search.Text = ''
		search.PlaceholderText = ''
		search.TextXAlignment = Enum.TextXAlignment.Left
		search.TextColor3 = uipallet.Text
		search.TextSize = 12
		search.FontFace = uipallet.Font
		search.ClearTextOnFocus = false
		search.Parent = searchbkg
		local searchcorner = Instance.new('UICorner')
		searchcorner.CornerRadius = UDim.new(0, 4)
		searchcorner.Parent = searchbkg
		local searchicon = Instance.new('ImageLabel')
		searchicon.Size = UDim2.fromOffset(14, 14)
		searchicon.Position = UDim2.new(1, -26, 0, 8)
		searchicon.BackgroundTransparency = 1
		searchicon.Image = getcustomasset('ReVape/assets/new/search.png')
		searchicon.ImageColor3 = color.Light(uipallet.Main, 0.37)
		searchicon.Parent = searchbkg
		local children = Instance.new('ScrollingFrame')
		children.Name = 'Children'
		children.Size = UDim2.fromOffset(500, 240)
		children.Position = UDim2.fromOffset(144, 122)
		children.BackgroundTransparency = 1
		children.BorderSizePixel = 0
		children.ScrollBarThickness = 2
		children.ScrollBarImageTransparency = 0.75
		children.CanvasSize = UDim2.new()
		children.Parent = window
		local windowlist = Instance.new('UIGridLayout')
		windowlist.SortOrder = Enum.SortOrder.LayoutOrder
		windowlist.FillDirectionMaxCells = 9
		windowlist.CellSize = UDim2.fromOffset(51, 52)
		windowlist.CellPadding = UDim2.fromOffset(4, 3)
		windowlist.Parent = children
		windowlist:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
			if vape.ThreadFix then
				setthreadidentity(8)
			end
			children.CanvasSize = UDim2.fromOffset(0, windowlist.AbsoluteContentSize.Y / vape.guiscale.Scale)
		end)
		table.insert(vape.Windows, window)
	
		local function createitem(id, image)
			local slotbkg = Instance.new('TextButton')
			slotbkg.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
			slotbkg.Text = ''
			slotbkg.AutoButtonColor = false
			slotbkg.Parent = children
			local slotimage = Instance.new('ImageLabel')
			slotimage.Size = UDim2.fromOffset(32, 32)
			slotimage.Position = UDim2.new(0.5, -16, 0.5, -16)
			slotimage.BackgroundTransparency = 1
			slotimage.Image = image
			slotimage.Parent = slotbkg
			local slotcorner = Instance.new('UICorner')
			slotcorner.CornerRadius = UDim.new(0, 4)
			slotcorner.Parent = slotbkg
			slotbkg.MouseEnter:Connect(function()
				slotbkg.BackgroundColor3 = color.Light(uipallet.Main, 0.04)
			end)
			slotbkg.MouseLeave:Connect(function()
				slotbkg.BackgroundColor3 = color.Light(uipallet.Main, 0.02)
			end)
			slotbkg.MouseButton1Click:Connect(function()
				local obj = self.Hotbars[self.Selected]
				if obj then
					window['Slot'..selectedslot].ImageLabel.Image = image
					obj.Hotbar[tostring(selectedslot)] = id
					obj.Object['Slot'..selectedslot].Image = image
				end
			end)
		end
	
		local function indexSearch(text)
			for _, v in children:GetChildren() do
				if v:IsA('TextButton') then
					v:ClearAllChildren()
					v:Destroy()
				end
			end
	
			if text == '' then
				for _, v in {'diamond_sword', 'diamond_pickaxe', 'diamond_axe', 'shears', 'wood_bow', 'wool_white', 'fireball', 'apple', 'iron', 'gold', 'diamond', 'emerald'} do
					createitem(v, bedwars.ItemMeta[v].image)
				end
				return
			end
	
			for i, v in bedwars.ItemMeta do
				if text:lower() == i:lower():sub(1, text:len()) then
					if not v.image then continue end
					createitem(i, v.image)
				end
			end
		end
	
		search:GetPropertyChangedSignal('Text'):Connect(function()
			indexSearch(search.Text)
		end)
		indexSearch('')
	
		return window
	end
	
	vape.Components.HotbarList = function(optionsettings, children, api)
		if vape.ThreadFix then
			setthreadidentity(8)
		end
		local optionapi = {
			Type = 'HotbarList',
			Hotbars = {},
			Selected = 1
		}
		local hotbarlist = Instance.new('TextButton')
		hotbarlist.Name = 'HotbarList'
		hotbarlist.Size = UDim2.fromOffset(220, 40)
		hotbarlist.BackgroundColor3 = optionsettings.Darker and (children.BackgroundColor3 == color.Dark(uipallet.Main, 0.02) and color.Dark(uipallet.Main, 0.04) or color.Dark(uipallet.Main, 0.02)) or children.BackgroundColor3
		hotbarlist.Text = ''
		hotbarlist.BorderSizePixel = 0
		hotbarlist.AutoButtonColor = false
		hotbarlist.Parent = children
		local textbkg = Instance.new('Frame')
		textbkg.Name = 'BKG'
		textbkg.Size = UDim2.new(1, -20, 0, 31)
		textbkg.Position = UDim2.fromOffset(10, 4)
		textbkg.BackgroundColor3 = color.Light(uipallet.Main, 0.034)
		textbkg.Parent = hotbarlist
		local textbkgcorner = Instance.new('UICorner')
		textbkgcorner.CornerRadius = UDim.new(0, 4)
		textbkgcorner.Parent = textbkg
		local textbutton = Instance.new('TextButton')
		textbutton.Name = 'HotbarList'
		textbutton.Size = UDim2.new(1, -2, 1, -2)
		textbutton.Position = UDim2.fromOffset(1, 1)
		textbutton.BackgroundColor3 = uipallet.Main
		textbutton.Text = ''
		textbutton.AutoButtonColor = false
		textbutton.Parent = textbkg
		textbutton.MouseEnter:Connect(function()
			tween:Tween(textbkg, TweenInfo.new(0.2), {
				BackgroundColor3 = color.Light(uipallet.Main, 0.14)
			})
		end)
		textbutton.MouseLeave:Connect(function()
			tween:Tween(textbkg, TweenInfo.new(0.2), {
				BackgroundColor3 = color.Light(uipallet.Main, 0.034)
			})
		end)
		local textbuttoncorner = Instance.new('UICorner')
		textbuttoncorner.CornerRadius = UDim.new(0, 4)
		textbuttoncorner.Parent = textbutton
		local textbuttonicon = Instance.new('ImageLabel')
		textbuttonicon.Size = UDim2.fromOffset(12, 12)
		textbuttonicon.Position = UDim2.fromScale(0.5, 0.5)
		textbuttonicon.AnchorPoint = Vector2.new(0.5, 0.5)
		textbuttonicon.BackgroundTransparency = 1
		textbuttonicon.Image = getcustomasset('ReVape/assets/new/add.png')
		textbuttonicon.ImageColor3 = Color3.fromHSV(0.46, 0.96, 0.52)
		textbuttonicon.Parent = textbutton
		local childrenlist = Instance.new('Frame')
		childrenlist.Size = UDim2.new(1, 0, 1, -40)
		childrenlist.Position = UDim2.fromOffset(0, 40)
		childrenlist.BackgroundTransparency = 1
		childrenlist.Parent = hotbarlist
		local windowlist = Instance.new('UIListLayout')
		windowlist.SortOrder = Enum.SortOrder.LayoutOrder
		windowlist.HorizontalAlignment = Enum.HorizontalAlignment.Center
		windowlist.Padding = UDim.new(0, 3)
		windowlist.Parent = childrenlist
		windowlist:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
			if vape.ThreadFix then
				setthreadidentity(8)
			end
			hotbarlist.Size = UDim2.fromOffset(220, math.min(43 + windowlist.AbsoluteContentSize.Y / vape.guiscale.Scale, 603))
		end)
		textbutton.MouseButton1Click:Connect(function()
			optionapi:AddHotbar()
		end)
		optionapi.Window = CreateWindow(optionapi)
	
		function optionapi:Save(savetab)
			local hotbars = {}
			for _, v in self.Hotbars do
				table.insert(hotbars, v.Hotbar)
			end
			savetab.HotbarList = {
				Selected = self.Selected,
				Hotbars = hotbars
			}
		end
	
		function optionapi:Load(savetab)
			for _, v in self.Hotbars do
				v.Object:ClearAllChildren()
				v.Object:Destroy()
				table.clear(v.Hotbar)
			end
			table.clear(self.Hotbars)
			for _, v in savetab.Hotbars do
				self:AddHotbar(v)
			end
			self.Selected = savetab.Selected or 1
		end
	
		function optionapi:AddHotbar(data)
			local hotbardata = {Hotbar = data or {}}
			table.insert(self.Hotbars, hotbardata)
			local hotbar = Instance.new('TextButton')
			hotbar.Size = UDim2.fromOffset(200, 27)
			hotbar.BackgroundColor3 = table.find(self.Hotbars, hotbardata) == self.Selected and color.Light(uipallet.Main, 0.034) or uipallet.Main
			hotbar.Text = ''
			hotbar.AutoButtonColor = false
			hotbar.Parent = childrenlist
			hotbardata.Object = hotbar
			local hotbarcorner = Instance.new('UICorner')
			hotbarcorner.CornerRadius = UDim.new(0, 4)
			hotbarcorner.Parent = hotbar
			for i = 1, 9 do
				local slot = Instance.new('ImageLabel')
				slot.Name = 'Slot'..i
				slot.Size = UDim2.fromOffset(17, 18)
				slot.Position = UDim2.fromOffset(-7 + (i * 18), 5)
				slot.BackgroundColor3 = color.Dark(uipallet.Main, 0.02)
				slot.Image = hotbardata.Hotbar[tostring(i)] and bedwars.getIcon({itemType = hotbardata.Hotbar[tostring(i)]}, true) or ''
				slot.BorderSizePixel = 0
				slot.Parent = hotbar
			end
			hotbar.MouseButton1Click:Connect(function()
				local ind = table.find(optionapi.Hotbars, hotbardata)
				if ind == optionapi.Selected then
					vape.gui.ScaledGui.ClickGui.Visible = false
					optionapi.Window.Visible = true
					for i = 1, 9 do
						optionapi.Window['Slot'..i].ImageLabel.Image = hotbardata.Hotbar[tostring(i)] and bedwars.getIcon({itemType = hotbardata.Hotbar[tostring(i)]}, true) or ''
					end
				else
					if optionapi.Hotbars[optionapi.Selected] then
						optionapi.Hotbars[optionapi.Selected].Object.BackgroundColor3 = uipallet.Main
					end
					hotbar.BackgroundColor3 = color.Light(uipallet.Main, 0.034)
					optionapi.Selected = ind
				end
			end)
			local close = Instance.new('ImageButton')
			close.Name = 'Close'
			close.Size = UDim2.fromOffset(16, 16)
			close.Position = UDim2.new(1, -23, 0, 6)
			close.BackgroundColor3 = Color3.new(1, 1, 1)
			close.BackgroundTransparency = 1
			close.Image = getcustomasset('ReVape/assets/new/closemini.png')
			close.ImageColor3 = color.Light(uipallet.Text, 0.2)
			close.ImageTransparency = 0.5
			close.AutoButtonColor = false
			close.Parent = hotbar
			local closecorner = Instance.new('UICorner')
			closecorner.CornerRadius = UDim.new(1, 0)
			closecorner.Parent = close
			close.MouseEnter:Connect(function()
				close.ImageTransparency = 0.3
				tween:Tween(close, TweenInfo.new(0.2), {
					BackgroundTransparency = 0.6
				})
			end)
			close.MouseLeave:Connect(function()
				close.ImageTransparency = 0.5
				tween:Tween(close, TweenInfo.new(0.2), {
					BackgroundTransparency = 1
				})
			end)
			close.MouseButton1Click:Connect(function()
				local ind = table.find(self.Hotbars, hotbardata)
				local obj = self.Hotbars[self.Selected]
				local obj2 = self.Hotbars[ind]
				if obj and obj2 then
					obj2.Object:ClearAllChildren()
					obj2.Object:Destroy()
					table.remove(self.Hotbars, ind)
					ind = table.find(self.Hotbars, obj)
					self.Selected = table.find(self.Hotbars, obj) or 1
				end
			end)
		end
	
		api.Options.HotbarList = optionapi
	
		return optionapi
	end
	
	local function getBlock()
		local clone = table.clone(store.inventory.inventory.items)
		table.sort(clone, function(a, b)
			return a.amount < b.amount
		end)
	
		for _, item in clone do
			local block = bedwars.ItemMeta[item.itemType].block
			if block and not block.seeThrough then
				return item
			end
		end
	end
	
	local function getCustomItem(v)
		if v == 'diamond_sword' then
			local sword = store.tools.sword
			v = sword and sword.itemType or 'wood_sword'
		elseif v == 'diamond_pickaxe' then
			local pickaxe = store.tools.stone
			v = pickaxe and pickaxe.itemType or 'wood_pickaxe'
		elseif v == 'diamond_axe' then
			local axe = store.tools.wood
			v = axe and axe.itemType or 'wood_axe'
		elseif v == 'wood_bow' then
			local bow = getBow()
			v = bow and bow.itemType or 'wood_bow'
		elseif v == 'wool_white' then
			local block = getBlock()
			v = block and block.itemType or 'wool_white'
		end
	
		return v
	end
	
	local function findItemInTable(tab, item)
		for slot, v in tab do
			if item.itemType == getCustomItem(v) then
				return tonumber(slot)
			end
		end
	end
	
	local function findInHotbar(item)
		for i, v in store.inventory.hotbar do
			if v.item and v.item.itemType == item.itemType then
				return i - 1, v.item
			end
		end
	end
	
	local function findInInventory(item)
		for _, v in store.inventory.inventory.items do
			if v.itemType == item.itemType then
				return v
			end
		end
	end
	
	local function dispatch(...)
		bedwars.Store:dispatch(...)
		vapeEvents.InventoryChanged.Event:Wait()
	end
	
	local function sortCallback()
		if Active then return end
		Active = true
		local items = (List.Hotbars[List.Selected] and List.Hotbars[List.Selected].Hotbar or {})
	
		for _, v in store.inventory.inventory.items do
			local slot = findItemInTable(items, v)
			if slot then
				local olditem = store.inventory.hotbar[slot]
				if olditem.item and olditem.item.itemType == v.itemType then continue end
				if olditem.item then
					dispatch({
						type = 'InventoryRemoveFromHotbar',
						slot = slot - 1
					})
				end
	
				local newslot = findInHotbar(v)
				if newslot then
					dispatch({
						type = 'InventoryRemoveFromHotbar',
						slot = newslot
					})
					if olditem.item then
						dispatch({
							type = 'InventoryAddToHotbar',
							item = findInInventory(olditem.item),
							slot = newslot
						})
					end
				end
	
				dispatch({
					type = 'InventoryAddToHotbar',
					item = findInInventory(v),
					slot = slot - 1
				})
			elseif Clear.Enabled then
				local newslot = findInHotbar(v)
				if newslot then
				   	dispatch({
						type = 'InventoryRemoveFromHotbar',
						slot = newslot
					})
				end
			end
		end
	
		Active = false
	end
	
	AutoHotbar = vape.Categories.Inventory:CreateModule({
		Name = 'AutoHotbar',
		Function = function(callback)
			if callback then
				task.spawn(sortCallback)
				if Mode.Value == 'On Key' then
					AutoHotbar:Toggle()
					return
				end
	
				AutoHotbar:Clean(vapeEvents.InventoryAmountChanged.Event:Connect(sortCallback))
			end
		end,
		Tooltip = 'Automatically arranges hotbar to your liking.'
	})
	Mode = AutoHotbar:CreateDropdown({
		Name = 'Activation',
		List = {'Toggle', 'On Key'},
		Function = function()
			if AutoHotbar.Enabled then
				AutoHotbar:Toggle()
				AutoHotbar:Toggle()
			end
		end
	})
	Clear = AutoHotbar:CreateToggle({Name = 'Clear Hotbar'})
	List = AutoHotbar:CreateHotbarList({})
end)
	
run(function()
	local Value
	local oldclickhold, oldshowprogress
	
	local FastConsume = vape.Categories.Inventory:CreateModule({
		Name = 'FastConsume',
		Function = function(callback)
			if callback then
				oldclickhold = bedwars.ClickHold.startClick
				oldshowprogress = bedwars.ClickHold.showProgress
				bedwars.ClickHold.startClick = function(self)
					self.startedClickTime = tick()
					local handle = self:showProgress()
					local clicktime = self.startedClickTime
					bedwars.RuntimeLib.Promise.defer(function()
						task.wait(self.durationSeconds * (Value.Value / 40))
						if handle == self.handle and clicktime == self.startedClickTime and self.closeOnComplete then
							self:hideProgress()
							if self.onComplete then self.onComplete() end
							if self.onPartialComplete then self.onPartialComplete(1) end
							self.startedClickTime = -1
						end
					end)
				end
	
				bedwars.ClickHold.showProgress = function(self)
					local roact = debug.getupvalue(oldshowprogress, 1)
					local countdown = roact.mount(roact.createElement('ScreenGui', {}, { roact.createElement('Frame', {
						[roact.Ref] = self.wrapperRef,
						Size = UDim2.new(),
						Position = UDim2.fromScale(0.5, 0.55),
						AnchorPoint = Vector2.new(0.5, 0),
						BackgroundColor3 = Color3.fromRGB(0, 0, 0),
						BackgroundTransparency = 0.8
					}, { roact.createElement('Frame', {
						[roact.Ref] = self.progressRef,
						Size = UDim2.fromScale(0, 1),
						BackgroundColor3 = Color3.new(1, 1, 1),
						BackgroundTransparency = 0.5
					}) }) }), lplr:FindFirstChild('PlayerGui'))
	
					self.handle = countdown
					local sizetween = tweenService:Create(self.wrapperRef:getValue(), TweenInfo.new(0.1), {
						Size = UDim2.fromScale(0.11, 0.005)
					})
					local countdowntween = tweenService:Create(self.progressRef:getValue(), TweenInfo.new(self.durationSeconds * (Value.Value / 100), Enum.EasingStyle.Linear), {
						Size = UDim2.fromScale(1, 1)
					})
	
					sizetween:Play()
					countdowntween:Play()
					table.insert(self.tweens, countdowntween)
					table.insert(self.tweens, sizetween)
					
					return countdown
				end
			else
				bedwars.ClickHold.startClick = oldclickhold
				bedwars.ClickHold.showProgress = oldshowprogress
				oldclickhold = nil
				oldshowprogress = nil
			end
		end,
		Tooltip = 'Use/Consume items quicker.'
	})
	Value = FastConsume:CreateSlider({
		Name = 'Multiplier',
		Min = 0,
		Max = 100
	})
end)
	
run(function()
	local FastDrop
	
	FastDrop = vape.Categories.Inventory:CreateModule({
		Name = 'FastDrop',
		Function = function(callback)
			if callback then
				repeat
					if entitylib.isAlive and (not store.inventory.opened) and (inputService:IsKeyDown(Enum.KeyCode.H) or inputService:IsKeyDown(Enum.KeyCode.Backspace)) and inputService:GetFocusedTextBox() == nil then
						task.spawn(bedwars.ItemDropController.dropItemInHand)
						task.wait(0.1)
					else
						task.wait(0.1)
					end
				until not FastDrop.Enabled
			end
		end,
		Tooltip = 'Drops items fast when you hold Q'
	})
end)
	
run(function()
	local BedPlates
	local Background
	local Color = {}
	local Reference = {}
	local Folder = Instance.new('Folder')
	Folder.Parent = vape.gui
	
	local function scanSide(self, start, tab)
		for _, side in sides do
			for i = 1, 15 do
				local block = getPlacedBlock(start + (side * i))
				if not block or block == self then break end
				if not block:GetAttribute('NoBreak') and not table.find(tab, block.Name) then
					table.insert(tab, block.Name)
				end
			end
		end
	end
	
	local function refreshAdornee(v)
		for _, obj in v.Frame:GetChildren() do
			if obj:IsA('ImageLabel') and obj.Name ~= 'Blur' then
				obj:Destroy()
			end
		end
	
		local start = v.Adornee.Position
		local alreadygot = {}
		scanSide(v.Adornee, start, alreadygot)
		scanSide(v.Adornee, start + Vector3.new(0, 0, 3), alreadygot)
		table.sort(alreadygot, function(a, b)
			return (bedwars.ItemMeta[a].block and bedwars.ItemMeta[a].block.health or 0) > (bedwars.ItemMeta[b].block and bedwars.ItemMeta[b].block.health or 0)
		end)
		v.Enabled = #alreadygot > 0
	
		for _, block in alreadygot do
			local blockimage = Instance.new('ImageLabel')
			blockimage.Size = UDim2.fromOffset(32, 32)
			blockimage.BackgroundTransparency = 1
			blockimage.Image = bedwars.getIcon({itemType = block}, true)
			blockimage.Parent = v.Frame
		end
	end
	
	local function Added(v)
		local billboard = Instance.new('BillboardGui')
		billboard.Parent = Folder
		billboard.Name = 'bed'
		billboard.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
		billboard.Size = UDim2.fromOffset(36, 36)
		billboard.AlwaysOnTop = true
		billboard.ClipsDescendants = false
		billboard.Adornee = v
		local blur = addBlur(billboard)
		blur.Visible = Background.Enabled
		local frame = Instance.new('Frame')
		frame.Size = UDim2.fromScale(1, 1)
		frame.BackgroundColor3 = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
		frame.BackgroundTransparency = 1 - (Background.Enabled and Color.Opacity or 0)
		frame.Parent = billboard
		local layout = Instance.new('UIListLayout')
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.Padding = UDim.new(0, 4)
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
			billboard.Size = UDim2.fromOffset(math.max(layout.AbsoluteContentSize.X + 4, 36), 36)
		end)
		layout.Parent = frame
		local corner = Instance.new('UICorner')
		corner.CornerRadius = UDim.new(0, 4)
		corner.Parent = frame
		Reference[v] = billboard
		refreshAdornee(billboard)
	end
	
	local function refreshNear(data)
		data = data.blockRef.blockPosition * 3
		for i, v in Reference do
			if (data - i.Position).Magnitude <= 30 then
				refreshAdornee(v)
			end
		end
	end
	
	BedPlates = vape.Categories.Minigames:CreateModule({
		Name = 'BedPlates',
		Function = function(callback)
			if callback then
				for _, v in collectionService:GetTagged('bed') do 
					task.spawn(Added, v) 
				end
				BedPlates:Clean(vapeEvents.PlaceBlockEvent.Event:Connect(refreshNear))
				BedPlates:Clean(vapeEvents.BreakBlockEvent.Event:Connect(refreshNear))
				BedPlates:Clean(collectionService:GetInstanceAddedSignal('bed'):Connect(Added))
				BedPlates:Clean(collectionService:GetInstanceRemovedSignal('bed'):Connect(function(v)
					if Reference[v] then
						Reference[v]:Destroy()
						Reference[v]:ClearAllChildren()
						Reference[v] = nil
					end
				end))
			else
				table.clear(Reference)
				Folder:ClearAllChildren()
			end
		end,
		Tooltip = 'Displays blocks over the bed'
	})
	Background = BedPlates:CreateToggle({
		Name = 'Background',
		Function = function(callback)
			if Color.Object then 
				Color.Object.Visible = callback 
			end
			for _, v in Reference do
				v.Frame.BackgroundTransparency = 1 - (callback and Color.Opacity or 0)
				v.Blur.Visible = callback
			end
		end,
		Default = true
	})
	Color = BedPlates:CreateColorSlider({
		Name = 'Background Color',
		DefaultValue = 0,
		DefaultOpacity = 0.5,
		Function = function(hue, sat, val, opacity)
			for _, v in Reference do
				v.Frame.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
				v.Frame.BackgroundTransparency = 1 - opacity
			end
		end,
		Darker = true
	})
end)
	

run(function()
	local Breaker
	local Delay
	local AutoAim
	local AimSpeed	
	local Range
	local Cache
	local UpdateRate
	local Custom
	local Bed
	local LuckyBlock
	local AutoTool
	local IronOre
	local Effect
	local CustomHealth = {}
	local Animation
	local SelfBreak
	local WallCheck
	local LimitItem
	local customlist, parts = {}, {}
	
	local function customHealthbar(self, blockRef, health, maxHealth, changeHealth, block)
		pcall(function()
			if block:GetAttribute('NoHealthbar') then return end
			if not self.healthbarPart or not self.healthbarBlockRef or self.healthbarBlockRef.blockPosition ~= blockRef.blockPosition then
				self.healthbarMaid:DoCleaning()
				self.healthbarBlockRef = blockRef
				local create = bedwars.Roact.createElement
				local percent = math.clamp(health / maxHealth, 0, 1)
				local cleanCheck = true
				local part = Instance.new('Part')
				part.Size = Vector3.one
				part.CFrame = CFrame.new(bedwars.BlockController:getWorldPosition(blockRef.blockPosition))
				part.Transparency = 1
				part.Anchored = true
				part.CanCollide = false
				part.Parent = workspace
				self.healthbarPart = part
				bedwars.QueryUtil:setQueryIgnored(self.healthbarPart, true)
		
				local mounted = bedwars.Roact.mount(create('BillboardGui', {
					Size = UDim2.fromOffset(249, 102),
					StudsOffset = Vector3.new(0, 2.5, 0),
					Adornee = part,
					MaxDistance = 40,
					AlwaysOnTop = true
				}, {
					create('Frame', {
						Size = UDim2.fromOffset(160, 50),
						Position = UDim2.fromOffset(44, 32),
						BackgroundColor3 = Color3.new(),
						BackgroundTransparency = 0.5
					}, {
						create('UICorner', {CornerRadius = UDim.new(0, 5)}),
						create('ImageLabel', {
							Size = UDim2.new(1, 89, 1, 52),
							Position = UDim2.fromOffset(-48, -31),
							BackgroundTransparency = 1,
							Image = getcustomasset('catrewrite/assets/new/blur.png'),
							ScaleType = Enum.ScaleType.Slice,
							SliceCenter = Rect.new(52, 31, 261, 502)
						}),
						create('TextLabel', {
							Size = UDim2.fromOffset(145, 14),
							Position = UDim2.fromOffset(13, 12),
							BackgroundTransparency = 1,
							Text = bedwars.ItemMeta[block.Name].displayName or block.Name,
							TextXAlignment = Enum.TextXAlignment.Left,
							TextYAlignment = Enum.TextYAlignment.Top,
							TextColor3 = Color3.new(),
							TextScaled = true,
							Font = Enum.Font.Arial
						}),
						create('TextLabel', {
							Size = UDim2.fromOffset(145, 14),
							Position = UDim2.fromOffset(12, 11),
							BackgroundTransparency = 1,
							Text = bedwars.ItemMeta[block.Name].displayName or block.Name,
							TextXAlignment = Enum.TextXAlignment.Left,
							TextYAlignment = Enum.TextYAlignment.Top,
							TextColor3 = color.Dark(uipallet.Text, 0.16),
							TextScaled = true,
							Font = Enum.Font.Arial
						}),
						create('Frame', {
							Size = UDim2.fromOffset(138, 4),
							Position = UDim2.fromOffset(12, 32),
							BackgroundColor3 = uipallet.Main
						}, {
							create('UICorner', {CornerRadius = UDim.new(1, 0)}),
							create('Frame', {
								[bedwars.Roact.Ref] = self.healthbarProgressRef,
								Size = UDim2.fromScale(percent, 1),
								BackgroundColor3 = Color3.fromHSV(math.clamp(percent / 2.5, 0, 1), 0.89, 0.75)
							}, {create('UICorner', {CornerRadius = UDim.new(1, 0)})})
						})
					})
				}), part)
		
				self.healthbarMaid:GiveTask(function()
					cleanCheck = false
					self.healthbarBlockRef = nil
					bedwars.Roact.unmount(mounted)
					if self.healthbarPart then
						self.healthbarPart:Destroy()
					end
					self.healthbarPart = nil
				end)
		
				bedwars.RuntimeLib.Promise.delay(5):andThen(function()
					if cleanCheck then
						self.healthbarMaid:DoCleaning()
					end
				end)
			end
		
			local newpercent = math.clamp((health - changeHealth) / maxHealth, 0, 1)
			tweenService:Create(self.healthbarProgressRef:getValue(), TweenInfo.new(0.3), {
				Size = UDim2.fromScale(newpercent, 1), BackgroundColor3 = Color3.fromHSV(math.clamp(newpercent / 2.5, 0, 1), 0.89, 0.75)
			}):Play()
		end)
	end
	
	local hit = 0
	local targetting = nil
	
	local function attemptBreak(tab, localPosition)
		if not tab then return end
		table.sort(tab, function(a, b)
			return (a.Position - localPosition).Magnitude >= (b.Position - localPosition).Magnitude
		end)
		for _, v in tab do
			if (v.Position - localPosition).Magnitude < Range.Value and bedwars.BlockController:isBlockBreakable({blockPosition = v.Position / 3}, lplr) then
				if not SelfBreak.Enabled and v:GetAttribute('PlacedByUserId') == lplr.UserId then continue end
				if (v:GetAttribute('BedShieldEndTime') or 0) > workspace:GetServerTimeNow() then continue end
				if LimitItem.Enabled and not (store.hand.tool and bedwars.ItemMeta[store.hand.tool.Name].breakBlock) then continue end
	
				hit += 1
				local target, path, endpos = bedwars.breakBlock(v, Effect.Enabled, Animation.Enabled, CustomHealth.Enabled and customHealthbar or nil, AutoTool.Enabled, WallCheck.Enabled, Cache.Enabled)
				if path then
					local currentnode = target
					if currentnode then
						targetting = currentnode
					end
					for _, part in parts do
						part.Position = currentnode or Vector3.zero
						if currentnode then
							part.BoxHandleAdornment.Color3 = currentnode == endpos and Color3.new(1, 0.2, 0.2) or currentnode == target and Color3.new(0.2, 0.2, 1) or Color3.new(0.2, 1, 0.2)
						end
						currentnode = path[currentnode]
					end
				end
	
				task.wait(Delay.Value)

				targetting = nil
	
				return true
			end
		end
	
		return false
	end
	
	Breaker = vape.Categories.Minigames:CreateModule({
		Name = 'Breaker',
		Function = function(callback)
			if callback then
				for _ = 1, 30 do
					local part = Instance.new('Part')
					part.Anchored = true
					part.CanQuery = false
					part.CanCollide = false
					part.Transparency = 1
					part.Parent = gameCamera
					local highlight = Instance.new('BoxHandleAdornment')
					highlight.Size = Vector3.one
					highlight.AlwaysOnTop = true
					highlight.ZIndex = 1
					highlight.Transparency = 0.5
					highlight.Adornee = part
					highlight.Parent = part
					table.insert(parts, part)
				end
	
				local beds = collection('bed', Breaker)
				local luckyblock = collection('LuckyBlock', Breaker)
				local ironores = collection('iron-ore', Breaker)
				customlist = collection('block', Breaker, function(tab, obj)
					if table.find(Custom.ListEnabled, obj.Name) then
						table.insert(tab, obj)
					end
				end)
	
				Breaker:Clean(runService.PreSimulation:Connect(function(dt)
					if AutoAim.Enabled and targetting then
						gameCamera.CFrame = gameCamera.CFrame:Lerp(CFrame.lookAt(gameCamera.CFrame.p, targetting), AimSpeed.Value * dt)
					end
				end))

				repeat
					task.wait(1 / UpdateRate.Value)
					if not Breaker.Enabled then break end
					if entitylib.isAlive then
						local localPosition = entitylib.character.RootPart.Position
	
						if attemptBreak(Bed.Enabled and beds, localPosition) then continue end
						if attemptBreak(customlist, localPosition) then continue end
						if attemptBreak(LuckyBlock.Enabled and luckyblock, localPosition) then continue end
						if attemptBreak(IronOre.Enabled and ironores, localPosition) then continue end
	
						for _, v in parts do
							v.Position = Vector3.zero
						end
					end
				until not Breaker.Enabled
			else
				for _, v in parts do
					v:ClearAllChildren()
					v:Destroy()
				end
				table.clear(parts)
			end
		end,
		Tooltip = 'Break blocks around you automatically'
	})
	Range = Breaker:CreateSlider({
		Name = 'Break range',
		Min = 1,
		Max = 30,
		Default = 30,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	Delay = Breaker:CreateSlider({
		Name = 'Break Delay',
		Min = 0,
		Max = 0.3,
		Default = 0.25,
		Decimal = 5,
		Suffix = function(val)
			return 's'
		end
	})
	AimSpeed = Breaker:CreateSlider({
		Name = 'Aim Speed',
		Min = 1,
		Max = 20,
		Default = 20
	})
	AimSpeed.Object.Visible = false
	UpdateRate = Breaker:CreateSlider({
		Name = 'Update rate',
		Min = 1,
		Max = 120,
		Default = 60,
		Suffix = 'hz'
	})
	Custom = Breaker:CreateTextList({
		Name = 'Custom',
		Function = function()
			if not customlist then return end
			table.clear(customlist)
			for _, obj in store.blocks do
				if table.find(Custom.ListEnabled, obj.Name) then
					table.insert(customlist, obj)
				end
			end
		end
	})
	Bed = Breaker:CreateToggle({
		Name = 'Break Bed',
		Default = true
	})
	AutoAim = Breaker:CreateToggle({
		Name = 'Auto Aim',
		Function = function(call)
			AimSpeed.Object.Visible = call
		end
	})
	LuckyBlock = Breaker:CreateToggle({
		Name = 'Break Lucky Block',
		Default = true
	})
	IronOre = Breaker:CreateToggle({
		Name = 'Break Iron Ore',
		Default = true
	})
	Effect = Breaker:CreateToggle({
		Name = 'Show Healthbar & Effects',
		Function = function(callback)
			if CustomHealth.Object then
				CustomHealth.Object.Visible = callback
			end
		end,
		Default = true
	})
	CustomHealth = Breaker:CreateToggle({
		Name = 'Custom Healthbar',
		Default = true,
		Darker = true
	})
	Animation = Breaker:CreateToggle({Name = 'Animation'})
	SelfBreak = Breaker:CreateToggle({Name = 'Self Break'})
	WallCheck = Breaker:CreateToggle({Name = 'Wall Check'})
	Cache = Breaker:CreateToggle({Name = 'Break through block'})
	AutoTool = Breaker:CreateToggle({Name = 'Auto Tool'})
	LimitItem = Breaker:CreateToggle({
		Name = 'Limit to items',
		Tooltip = 'Only breaks when tools are held'
	})
end)

run(function()
	local BedBreakEffect
	local Mode
	local List
	local NameToId = {}
	
	BedBreakEffect = vape.Legit:CreateModule({
		Name = 'Bed Break Effect',
		Function = function(callback)
			if callback then
	            BedBreakEffect:Clean(vapeEvents.BedwarsBedBreak.Event:Connect(function(data)
	                firesignal(bedwars.Client:Get('BedBreakEffectTriggered').instance.OnClientEvent, {
	                    player = data.player,
	                    position = data.bedBlockPosition * 3,
	                    effectType = NameToId[List.Value],
	                    teamId = data.brokenBedTeam.id,
	                    centerBedPosition = data.bedBlockPosition * 3
	                })
	            end))
	        end
		end,
		Tooltip = 'Custom bed break effects'
	})
	local BreakEffectName = {}
	for i, v in bedwars.BedBreakEffectMeta do
		table.insert(BreakEffectName, v.name)
		NameToId[v.name] = i
	end
	table.sort(BreakEffectName)
	List = BedBreakEffect:CreateDropdown({
		Name = 'Effect',
		List = BreakEffectName
	})
end)
	
run(function()
	vape.Legit:CreateModule({
		Name = 'Clean Kit',
		Function = function(callback)
			if callback then
				bedwars.WindWalkerController.spawnOrb = function() end
				local zephyreffect = lplr.PlayerGui:FindFirstChild('WindWalkerEffect', true)
				if zephyreffect then 
					zephyreffect.Visible = callback or true 
				end
			end
		end,
		Tooltip = 'Removes zephyr status indicator'
	})
end)
	
run(function()
	local old
	local Image
	
	local Crosshair = vape.Legit:CreateModule({
		Name = 'Crosshair',
		Function = function(callback)
			if callback then
				old = debug.getconstant(bedwars.ViewmodelController.showCrosshair, 25)
				debug.setconstant(bedwars.ViewmodelController.showCrosshair, 25, Image.Value)
				debug.setconstant(bedwars.ViewmodelController.showCrosshair, 37, Image.Value)
			else
				debug.setconstant(bedwars.ViewmodelController.showCrosshair, 25, old)
				debug.setconstant(bedwars.ViewmodelController.showCrosshair, 37, old)
				old = nil
			end
	
			if bedwars.ViewmodelController.crosshair then
				bedwars.ViewmodelController:hideCrosshair()
				bedwars.ViewmodelController:showCrosshair()
			end
		end,
		Tooltip = 'Custom first person crosshair depending on the image choosen.'
	})
	Image = Crosshair:CreateTextBox({
		Name = 'Image',
		Placeholder = 'image id (roblox)',
		Function = function(enter)
			if enter and Crosshair.Enabled then
				Crosshair:Toggle()
				Crosshair:Toggle()
			end
		end
	})
end)

run(function()
	local FOV
	local Value
	local old, old2
	
	FOV = vape.Legit:CreateModule({
		Name = 'FOV',
		Function = function(callback)
			if callback then
				old = bedwars.FovController.setFOV
				old2 = bedwars.FovController.getFOV
				bedwars.FovController.setFOV = function(self) 
					return old(self, Value.Value) 
				end
				bedwars.FovController.getFOV = function() 
					return Value.Value 
				end
			else
				bedwars.FovController.setFOV = old
				bedwars.FovController.getFOV = old2
			end
			
			bedwars.FovController:setFOV(bedwars.Store:getState().Settings.fov)
		end,
		Tooltip = 'Adjusts camera vision'
	})
	Value = FOV:CreateSlider({
		Name = 'FOV',
		Min = 30,
		Max = 120
	})
end)
	
run(function()
	local FPSBoost
	local Kill
	local Visualizer
	local effects, util = {}, {}
	
	FPSBoost = vape.Legit:CreateModule({
		Name = 'FPS Boost',
		Function = function(callback)
			if callback then
				if Kill.Enabled then
					for i, v in bedwars.KillEffectController.killEffects do
						if not i:find('Custom') then
							effects[i] = v
							bedwars.KillEffectController.killEffects[i] = {
								new = function() 
									return {
										onKill = function() end, 
										isPlayDefaultKillEffect = function() 
											return true 
										end
									} 
								end
							}
						end
					end
				end
	
				if Visualizer.Enabled then
					for i, v in bedwars.VisualizerUtils do
						util[i] = v
						bedwars.VisualizerUtils[i] = function() end
					end
				end
	
				repeat task.wait(0.1) until store.matchState ~= 0
				if not bedwars.AppController then return end
				bedwars.NametagController.addGameNametag = function() end
				for _, v in bedwars.AppController:getOpenApps() do
					if tostring(v):find('Nametag') then
						bedwars.AppController:closeApp(tostring(v))
					end
				end
			else
				for i, v in effects do 
					bedwars.KillEffectController.killEffects[i] = v 
				end
				for i, v in util do 
					bedwars.VisualizerUtils[i] = v 
				end
				table.clear(effects)
				table.clear(util)
			end
		end,
		Tooltip = 'Improves the framerate by turning off certain effects'
	})
	Kill = FPSBoost:CreateToggle({
		Name = 'Kill Effects',
		Function = function()
			if FPSBoost.Enabled then
				FPSBoost:Toggle()
				FPSBoost:Toggle()
			end
		end,
		Default = true
	})
	Visualizer = FPSBoost:CreateToggle({
		Name = 'Visualizer',
		Function = function()
			if FPSBoost.Enabled then
				FPSBoost:Toggle()
				FPSBoost:Toggle()
			end
		end,
		Default = true
	})
end)
	
run(function()
	local HitColor
	local Color
	local done = {}
	
	HitColor = vape.Legit:CreateModule({
		Name = 'Hit Color',
		Function = function(callback)
			if callback then 
				repeat
					for i, v in entitylib.List do 
						local highlight = v.Character and v.Character:FindFirstChild('_DamageHighlight_')
						if highlight then 
							if not table.find(done, highlight) then 
								table.insert(done, highlight) 
							end
							highlight.FillColor = Color3.fromHSV(Color.Hue, Color.Sat, Color.Value)
							highlight.FillTransparency = Color.Opacity
						end
					end
					task.wait(0.1)
				until not HitColor.Enabled
			else
				for i, v in done do 
					v.FillColor = Color3.new(1, 0, 0)
					v.FillTransparency = 0.4
				end
				table.clear(done)
			end
		end,
		Tooltip = 'Customize the hit highlight options'
	})
	Color = HitColor:CreateColorSlider({
		Name = 'Color',
		DefaultOpacity = 0.4
	})
end)
	
	
run(function()
	local Interface
	local HotbarOpenInventory = require(lplr.PlayerScripts.TS.controllers.global.hotbar.ui['hotbar-open-inventory']).HotbarOpenInventory
	local HotbarHealthbar = require(lplr.PlayerScripts.TS.controllers.global.hotbar.ui.healthbar['hotbar-healthbar']).HotbarHealthbar
	local HotbarApp = getRoactRender(require(lplr.PlayerScripts.TS.controllers.global.hotbar.ui['hotbar-app']).HotbarApp.render)
	local old, new = {}, {}
	
	vape:Clean(function()
		for _, v in new do
			table.clear(v)
		end
		for _, v in old do
			table.clear(v)
		end
		table.clear(new)
		table.clear(old)
	end)
	
	local function modifyconstant(func, ind, val)
		if not func then return end
		if not old[func] then old[func] = {} end
		if not new[func] then new[func] = {} end
		if not old[func][ind] then
			old[func][ind] = debug.getconstant(func, ind)
		end
		if typeof(old[func][ind]) ~= typeof(val) then return end
		new[func][ind] = val
	
		if Interface.Enabled then
			if val then
				debug.setconstant(func, ind, val)
			else
				debug.setconstant(func, ind, old[func][ind])
				old[func][ind] = nil
			end
		end
	end
	
	Interface = vape.Legit:CreateModule({
		Name = 'Interface',
		Function = function(callback)
			for i, v in (callback and new or old) do
				for i2, v2 in v do
					debug.setconstant(i, i2, v2)
				end
			end
		end,
		Tooltip = 'Customize bedwars UI'
	})
	local fontitems = {'LuckiestGuy'}
	for _, v in Enum.Font:GetEnumItems() do
		if v.Name ~= 'LuckiestGuy' then
			table.insert(fontitems, v.Name)
		end
	end
	Interface:CreateDropdown({
		Name = 'Health Font',
		List = fontitems,
		Function = function(val)
			modifyconstant(HotbarHealthbar.render, 77, val)
		end
	})
	Interface:CreateColorSlider({
		Name = 'Health Color',
		Function = function(hue, sat, val)
			modifyconstant(HotbarHealthbar.render, 16, tonumber(Color3.fromHSV(hue, sat, val):ToHex(), 16))
			if Interface.Enabled then
				local hotbar = lplr.PlayerGui:FindFirstChild('hotbar')
				hotbar = hotbar and hotbar:FindFirstChild('HealthbarProgressWrapper', true)
				if hotbar then
					hotbar['1'].BackgroundColor3 = Color3.fromHSV(hue, sat, val)
				end
			end
		end
	})
	Interface:CreateColorSlider({
		Name = 'Hotbar Color',
		DefaultOpacity = 0.8,
		Function = function(hue, sat, val, opacity)
			local func = oldinvrender or HotbarOpenInventory.render
			modifyconstant(debug.getupvalue(HotbarApp, 23).render, 51, tonumber(Color3.fromHSV(hue, sat, val):ToHex(), 16))
			modifyconstant(debug.getupvalue(HotbarApp, 23).render, 58, tonumber(Color3.fromHSV(hue, sat, math.clamp(val > 0.5 and val - 0.2 or val + 0.2, 0, 1)):ToHex(), 16))
			modifyconstant(debug.getupvalue(HotbarApp, 23).render, 54, 1 - opacity)
			modifyconstant(debug.getupvalue(HotbarApp, 23).render, 55, math.clamp(1.2 - opacity, 0, 1))
			modifyconstant(func, 31, tonumber(Color3.fromHSV(hue, sat, val):ToHex(), 16))
			modifyconstant(func, 32, math.clamp(1.2 - opacity, 0, 1))
			modifyconstant(func, 34, tonumber(Color3.fromHSV(hue, sat, math.clamp(val > 0.5 and val - 0.2 or val + 0.2, 0, 1)):ToHex(), 16))
		end
	})
end)
	
run(function()
	local KillEffect
	local Mode
	local List
	local NameToId = {}
	
	local killeffects = {
		Gravity = function(_, _, char, _)
			char:BreakJoints()
			local highlight = char:FindFirstChildWhichIsA('Highlight')
			local nametag = char:FindFirstChild('Nametag', true)
			if highlight then
				highlight:Destroy()
			end
			if nametag then
				nametag:Destroy()
			end
	
			task.spawn(function()
				local partvelo = {}
				for _, v in char:GetDescendants() do
					if v:IsA('BasePart') then
						partvelo[v.Name] = v.Velocity
					end
				end
				char.Archivable = true
				local clone = char:Clone()
				clone.Humanoid.Health = 100
				clone.Parent = workspace
				game:GetService('Debris'):AddItem(clone, 30)
				char:Destroy()
				task.wait(0.01)
				clone.Humanoid:ChangeState(Enum.HumanoidStateType.Dead)
				clone:BreakJoints()
				task.wait(0.01)
				for _, v in clone:GetDescendants() do
					if v:IsA('BasePart') then
						local bodyforce = Instance.new('BodyForce')
						bodyforce.Force = Vector3.new(0, (workspace.Gravity - 10) * v:GetMass(), 0)
						bodyforce.Parent = v
						v.CanCollide = true
						v.Velocity = partvelo[v.Name] or Vector3.zero
					end
				end
			end)
		end,
		Lightning = function(_, _, char, _)
			char:BreakJoints()
			local highlight = char:FindFirstChildWhichIsA('Highlight')
			if highlight then
				highlight:Destroy()
			end
			local startpos = 1125
			local startcf = char.PrimaryPart.CFrame.p - Vector3.new(0, 8, 0)
			local newpos = Vector3.new((math.random(1, 10) - 5) * 2, startpos, (math.random(1, 10) - 5) * 2)
	
			for i = startpos - 75, 0, -75 do
				local newpos2 = Vector3.new((math.random(1, 10) - 5) * 2, i, (math.random(1, 10) - 5) * 2)
				if i == 0 then
					newpos2 = Vector3.zero
				end
				local part = Instance.new('Part')
				part.Size = Vector3.new(1.5, 1.5, 77)
				part.Material = Enum.Material.SmoothPlastic
				part.Anchored = true
				part.Material = Enum.Material.Neon
				part.CanCollide = false
				part.CFrame = CFrame.new(startcf + newpos + ((newpos2 - newpos) * 0.5), startcf + newpos2)
				part.Parent = workspace
				local part2 = part:Clone()
				part2.Size = Vector3.new(3, 3, 78)
				part2.Color = Color3.new(0.7, 0.7, 0.7)
				part2.Transparency = 0.7
				part2.Material = Enum.Material.SmoothPlastic
				part2.Parent = workspace
				game:GetService('Debris'):AddItem(part, 0.5)
				game:GetService('Debris'):AddItem(part2, 0.5)
				bedwars.QueryUtil:setQueryIgnored(part, true)
				bedwars.QueryUtil:setQueryIgnored(part2, true)
				if i == 0 then
					local soundpart = Instance.new('Part')
					soundpart.Transparency = 1
					soundpart.Anchored = true
					soundpart.Size = Vector3.zero
					soundpart.Position = startcf
					soundpart.Parent = workspace
					bedwars.QueryUtil:setQueryIgnored(soundpart, true)
					local sound = Instance.new('Sound')
					sound.SoundId = 'rbxassetid://6993372814'
					sound.Volume = 2
					sound.Pitch = 0.5 + (math.random(1, 3) / 10)
					sound.Parent = soundpart
					sound:Play()
					sound.Ended:Connect(function()
						soundpart:Destroy()
					end)
				end
				newpos = newpos2
			end
		end,
		Delete = function(_, _, char, _)
			char:Destroy()
		end
	}
	
	KillEffect = vape.Legit:CreateModule({
		Name = 'Kill Effect',
		Function = function(callback)
			if callback then
				for i, v in killeffects do
					bedwars.KillEffectController.killEffects['Custom'..i] = {
						new = function()
							return {
								onKill = v,
								isPlayDefaultKillEffect = function()
									return false
								end
							}
						end
					}
				end
				KillEffect:Clean(lplr:GetAttributeChangedSignal('KillEffectType'):Connect(function()
					lplr:SetAttribute('KillEffectType', Mode.Value == 'Bedwars' and NameToId[List.Value] or 'Custom'..Mode.Value)
				end))
				lplr:SetAttribute('KillEffectType', Mode.Value == 'Bedwars' and NameToId[List.Value] or 'Custom'..Mode.Value)
			else
				for i in killeffects do
					bedwars.KillEffectController.killEffects['Custom'..i] = nil
				end
				lplr:SetAttribute('KillEffectType', 'default')
			end
		end,
		Tooltip = 'Custom final kill effects'
	})
	local modes = {'Bedwars'}
	for i in killeffects do
		table.insert(modes, i)
	end
	Mode = KillEffect:CreateDropdown({
		Name = 'Mode',
		List = modes,
		Function = function(val)
			List.Object.Visible = val == 'Bedwars'
			if KillEffect.Enabled then
				lplr:SetAttribute('KillEffectType', val == 'Bedwars' and NameToId[List.Value] or 'Custom'..val)
			end
		end
	})
	local KillEffectName = {}
	for i, v in bedwars.KillEffectMeta do
		table.insert(KillEffectName, v.name)
		NameToId[v.name] = i
	end
	table.sort(KillEffectName)
	List = KillEffect:CreateDropdown({
		Name = 'Bedwars',
		List = KillEffectName,
		Function = function(val)
			if KillEffect.Enabled then
				lplr:SetAttribute('KillEffectType', NameToId[val])
			end
		end,
		Darker = true
	})
end)
	
run(function()
	local ReachDisplay
	local label
	
	ReachDisplay = vape.Legit:CreateModule({
		Name = 'Reach Display',
		Function = function(callback)
			if callback then
				repeat
					label.Text = (store.attackReachUpdate > tick() and store.attackReach or '0.00')..' studs'
					task.wait(0.4)
				until not ReachDisplay.Enabled
			end
		end,
		Size = UDim2.fromOffset(100, 41)
	})
	ReachDisplay:CreateFont({
		Name = 'Font',
		Blacklist = 'Gotham',
		Function = function(val)
			label.FontFace = val
		end
	})
	ReachDisplay:CreateColorSlider({
		Name = 'Color',
		DefaultValue = 0,
		DefaultOpacity = 0.5,
		Function = function(hue, sat, val, opacity)
			label.BackgroundColor3 = Color3.fromHSV(hue, sat, val)
			label.BackgroundTransparency = 1 - opacity
		end
	})
	label = Instance.new('TextLabel')
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 0.5
	label.TextSize = 15
	label.Font = Enum.Font.Gotham
	label.Text = '0.00 studs'
	label.TextColor3 = Color3.new(1, 1, 1)
	label.BackgroundColor3 = Color3.new()
	label.Parent = ReachDisplay.Children
	local corner = Instance.new('UICorner')
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = label
end)
	
run(function()
	local SongBeats
	local List
	local FOV
	local FOVValue = {}
	local Volume
	local alreadypicked = {}
	local beattick = tick()
	local oldfov, songobj, songbpm, songtween
	
	local function choosesong()
		local list = List.ListEnabled
		if #alreadypicked >= #list then 
			table.clear(alreadypicked) 
		end
	
		if #list <= 0 then
			notif('SongBeats', 'no songs', 10)
			SongBeats:Toggle()
			return
		end
	
		local chosensong = list[math.random(1, #list)]
		if #list > 1 and table.find(alreadypicked, chosensong) then
			repeat 
				task.wait(0.1) 
				chosensong = list[math.random(1, #list)] 
			until not table.find(alreadypicked, chosensong) or not SongBeats.Enabled
		end
		if not SongBeats.Enabled then return end
	
		local split = chosensong:split('/')
		if not isfile(split[1]) then
			notif('SongBeats', 'Missing song ('..split[1]..')', 10)
			SongBeats:Toggle()
			return
		end
	
		songobj.SoundId = assetfunction(split[1])
		repeat task.wait(0.1) until songobj.IsLoaded or not SongBeats.Enabled
		if SongBeats.Enabled then
			beattick = tick() + (tonumber(split[3]) or 0)
			songbpm = 60 / (tonumber(split[2]) or 50)
			songobj:Play()
		end
	end
	
	SongBeats = vape.Legit:CreateModule({
		Name = 'Song Beats',
		Function = function(callback)
			if callback then
				songobj = Instance.new('Sound')
				songobj.Volume = Volume.Value / 100
				songobj.Parent = workspace
				repeat
					if not songobj.Playing then choosesong() end
					if beattick < tick() and SongBeats.Enabled and FOV.Enabled then
						beattick = tick() + songbpm
						oldfov = math.min(bedwars.FovController:getFOV() * (bedwars.SprintController.sprinting and 1.1 or 1), 120)
						gameCamera.FieldOfView = oldfov - FOVValue.Value
						songtween = tweenService:Create(gameCamera, TweenInfo.new(math.min(songbpm, 0.2), Enum.EasingStyle.Linear), {FieldOfView = oldfov})
						songtween:Play()
					end
					task.wait(0.1)
				until not SongBeats.Enabled
			else
				if songobj then
					songobj:Destroy()
				end
				if songtween then
					songtween:Cancel()
				end
				if oldfov then
					gameCamera.FieldOfView = oldfov
				end
				table.clear(alreadypicked)
			end
		end,
		Tooltip = 'Built in mp3 player'
	})
	List = SongBeats:CreateTextList({
		Name = 'Songs',
		Placeholder = 'filepath/bpm/start'
	})
	FOV = SongBeats:CreateToggle({
		Name = 'Beat FOV',
		Function = function(callback)
			if FOVValue.Object then
				FOVValue.Object.Visible = callback
			end
			if SongBeats.Enabled then
				SongBeats:Toggle()
				SongBeats:Toggle()
			end
		end,
		Default = true
	})
	FOVValue = SongBeats:CreateSlider({
		Name = 'Adjustment',
		Min = 1,
		Max = 30,
		Default = 5,
		Darker = true
	})
	Volume = SongBeats:CreateSlider({
		Name = 'Volume',
		Function = function(val)
			if songobj then 
				songobj.Volume = val / 100 
			end
		end,
		Min = 1,
		Max = 100,
		Default = 100,
		Suffix = '%'
	})
end)
	
run(function()
	local SoundChanger
	local List
	local soundlist = {}
	local old
	
	SoundChanger = vape.Legit:CreateModule({
		Name = 'SoundChanger',
		Function = function(callback)
			if callback then
				old = bedwars.SoundManager.playSound
				bedwars.SoundManager.playSound = function(self, id, ...)
					if soundlist[id] then
						id = soundlist[id]
					end
	
					return old(self, id, ...)
				end
			else
				bedwars.SoundManager.playSound = old
				old = nil
			end
		end,
		Tooltip = 'Change ingame sounds to custom ones.'
	})
	List = SoundChanger:CreateTextList({
		Name = 'Sounds',
		Placeholder = '(DAMAGE_1/ben.mp3)',
		Function = function()
			table.clear(soundlist)
			for _, entry in List.ListEnabled do
				local split = entry:split('/')
				local id = bedwars.SoundList[split[1]]
				if id and #split > 1 then
					soundlist[id] = split[2]:find('rbxasset') and split[2] or isfile(split[2]) and assetfunction(split[2]) or ''
				end
			end
		end
	})
end)
	
run(function()
	local UICleanup
	local OpenInv
	local KillFeed
	local OldTabList
	local HotbarApp = getRoactRender(require(lplr.PlayerScripts.TS.controllers.global.hotbar.ui['hotbar-app']).HotbarApp.render)
	local HotbarOpenInventory = require(lplr.PlayerScripts.TS.controllers.global.hotbar.ui['hotbar-open-inventory']).HotbarOpenInventory
	local old, new = {}, {}
	local oldkillfeed
	
	vape:Clean(function()
		for _, v in new do
			table.clear(v)
		end
		for _, v in old do
			table.clear(v)
		end
		table.clear(new)
		table.clear(old)
	end)
	
	local function modifyconstant(func, ind, val)
		if not old[func] then old[func] = {} end
		if not new[func] then new[func] = {} end
		if not old[func][ind] then
			local typing = type(old[func][ind])
			if typing == 'function' or typing == 'userdata' then return end
			old[func][ind] = debug.getconstant(func, ind)
		end
		if typeof(old[func][ind]) ~= typeof(val) and val ~= nil then return end
	
		new[func][ind] = val
		if UICleanup.Enabled then
			if val then
				debug.setconstant(func, ind, val)
			else
				debug.setconstant(func, ind, old[func][ind])
				old[func][ind] = nil
			end
		end
	end
	
	UICleanup = vape.Legit:CreateModule({
		Name = 'UI Cleanup',
		Function = function(callback)
			for i, v in (callback and new or old) do
				for i2, v2 in v do
					debug.setconstant(i, i2, v2)
				end
			end
			if callback then
				if OpenInv.Enabled then
					oldinvrender = HotbarOpenInventory.render
					HotbarOpenInventory.render = function()
						return bedwars.Roact.createElement('TextButton', {Visible = false}, {})
					end
				end
	
				if KillFeed.Enabled then
					oldkillfeed = bedwars.KillFeedController.addToKillFeed
					bedwars.KillFeedController.addToKillFeed = function() end
				end
	
				if OldTabList.Enabled then
					starterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
				end
			else
				if oldinvrender then
					HotbarOpenInventory.render = oldinvrender
					oldinvrender = nil
				end
	
				if KillFeed.Enabled then
					bedwars.KillFeedController.addToKillFeed = oldkillfeed
					oldkillfeed = nil
				end
	
				if OldTabList.Enabled then
					starterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
				end
			end
		end,
		Tooltip = 'Cleans up the UI for kits & main'
	})
	UICleanup:CreateToggle({
		Name = 'Resize Health',
		Function = function(callback)
			modifyconstant(HotbarApp, 60, callback and 1 or nil)
			modifyconstant(debug.getupvalue(HotbarApp, 15).render, 30, callback and 1 or nil)
			modifyconstant(debug.getupvalue(HotbarApp, 23).tweenPosition, 16, callback and 0 or nil)
		end,
		Default = true
	})
	UICleanup:CreateToggle({
		Name = 'No Hotbar Numbers',
		Function = function(callback)
			local func = oldinvrender or HotbarOpenInventory.render
			modifyconstant(debug.getupvalue(HotbarApp, 23).render, 90, callback and 0 or nil)
			modifyconstant(func, 71, callback and 0 or nil)
		end,
		Default = true
	})
	OpenInv = UICleanup:CreateToggle({
		Name = 'No Inventory Button',
		Function = function(callback)
			modifyconstant(HotbarApp, 78, callback and 0 or nil)
			if UICleanup.Enabled then
				if callback then
					oldinvrender = HotbarOpenInventory.render
					HotbarOpenInventory.render = function()
						return bedwars.Roact.createElement('TextButton', {Visible = false}, {})
					end
				else
					HotbarOpenInventory.render = oldinvrender
					oldinvrender = nil
				end
			end
		end,
		Default = true
	})
	KillFeed = UICleanup:CreateToggle({
		Name = 'No Kill Feed',
		Function = function(callback)
			if UICleanup.Enabled then
				if callback then
					oldkillfeed = bedwars.KillFeedController.addToKillFeed
					bedwars.KillFeedController.addToKillFeed = function() end
				else
					bedwars.KillFeedController.addToKillFeed = oldkillfeed
					oldkillfeed = nil
				end
			end
		end,
		Default = true
	})
	OldTabList = UICleanup:CreateToggle({
		Name = 'Old Player List',
		Function = function(callback)
			if UICleanup.Enabled then
				starterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, callback)
			end
		end,
		Default = true
	})
	UICleanup:CreateToggle({
		Name = 'Fix Queue Card',
		Function = function(callback)
			modifyconstant(bedwars.QueueCard.render, 15, callback and 0.1 or nil)
		end,
		Default = true
	})
end)
	
run(function()
	local Viewmodel
	local Depth
	local Horizontal
	local Vertical
	local NoBob
	local Rots = {}
	local old, oldc1
	
	Viewmodel = vape.Categories.Combat:CreateModule({
		Name = 'NoBob',
		Function = function(callback)
			local viewmodel = gameCamera:FindFirstChild('Viewmodel')
			if callback then
				old = bedwars.ViewmodelController.playAnimation
				oldc1 = viewmodel and viewmodel.RightHand.RightWrist.C1 or CFrame.identity
				if NoBob.Enabled then
					bedwars.ViewmodelController.playAnimation = function(self, animtype, ...)
						if bedwars.AnimationType and animtype == bedwars.AnimationType.FP_WALK then return end
						return old(self, animtype, ...)
					end
				end
	
				bedwars.InventoryViewmodelController:handleStore(bedwars.Store:getState())
				if viewmodel then
					gameCamera.Viewmodel.RightHand.RightWrist.C1 = oldc1 * CFrame.Angles(math.rad(Rots[1].Value), math.rad(Rots[2].Value), math.rad(Rots[3].Value))
				end
				lplr.PlayerScripts.TS.controllers.global.viewmodel['viewmodel-controller']:SetAttribute('ConstantManager_DEPTH_OFFSET', -Depth.Value)
				lplr.PlayerScripts.TS.controllers.global.viewmodel['viewmodel-controller']:SetAttribute('ConstantManager_HORIZONTAL_OFFSET', Horizontal.Value)
				lplr.PlayerScripts.TS.controllers.global.viewmodel['viewmodel-controller']:SetAttribute('ConstantManager_VERTICAL_OFFSET', Vertical.Value)
			else
				bedwars.ViewmodelController.playAnimation = old
				if viewmodel then
					viewmodel.RightHand.RightWrist.C1 = oldc1
				end
	
				bedwars.InventoryViewmodelController:handleStore(bedwars.Store:getState())
				lplr.PlayerScripts.TS.controllers.global.viewmodel['viewmodel-controller']:SetAttribute('ConstantManager_DEPTH_OFFSET', 0)
				lplr.PlayerScripts.TS.controllers.global.viewmodel['viewmodel-controller']:SetAttribute('ConstantManager_HORIZONTAL_OFFSET', 0)
				lplr.PlayerScripts.TS.controllers.global.viewmodel['viewmodel-controller']:SetAttribute('ConstantManager_VERTICAL_OFFSET', 0)
				old = nil
			end
		end,
		Tooltip = 'Changes the viewmodel animations'
	})
	Depth = Viewmodel:CreateSlider({
		Name = 'Depth',
		Min = 0,
		Max = 2,
		Default = 0.8,
		Decimal = 10,
		Function = function(val)
			if Viewmodel.Enabled then
				lplr.PlayerScripts.TS.controllers.global.viewmodel['viewmodel-controller']:SetAttribute('ConstantManager_DEPTH_OFFSET', -val)
			end
		end
	})
	Horizontal = Viewmodel:CreateSlider({
		Name = 'Horizontal',
		Min = 0,
		Max = 2,
		Default = 0.8,
		Decimal = 10,
		Function = function(val)
			if Viewmodel.Enabled then
				lplr.PlayerScripts.TS.controllers.global.viewmodel['viewmodel-controller']:SetAttribute('ConstantManager_HORIZONTAL_OFFSET', val)
			end
		end
	})
	Vertical = Viewmodel:CreateSlider({
		Name = 'Vertical',
		Min = -0.2,
		Max = 2,
		Default = -0.2,
		Decimal = 10,
		Function = function(val)
			if Viewmodel.Enabled then
				lplr.PlayerScripts.TS.controllers.global.viewmodel['viewmodel-controller']:SetAttribute('ConstantManager_VERTICAL_OFFSET', val)
			end
		end
	})
	for _, name in {'Rotation X', 'Rotation Y', 'Rotation Z'} do
		table.insert(Rots, Viewmodel:CreateSlider({
			Name = name,
			Min = 0,
			Max = 360,
			Function = function(val)
				if Viewmodel.Enabled then
					gameCamera.Viewmodel.RightHand.RightWrist.C1 = oldc1 * CFrame.Angles(math.rad(Rots[1].Value), math.rad(Rots[2].Value), math.rad(Rots[3].Value))
				end
			end
		}))
	end
	NoBob = Viewmodel:CreateToggle({
		Name = 'No Bobbing',
		Default = true,
		Function = function()
			if Viewmodel.Enabled then
				Viewmodel:Toggle()
				Viewmodel:Toggle()
			end
		end
	})
end)
	
run(function()
	local WinEffect
	local List
	local NameToId = {}
	
	WinEffect = vape.Legit:CreateModule({
		Name = 'WinEffect',
		Function = function(callback)
			if callback then
				WinEffect:Clean(vapeEvents.MatchEndEvent.Event:Connect(function()
					for i, v in getconnections(bedwars.Client:Get('WinEffectTriggered').instance.OnClientEvent) do
						if v.Function then
							v.Function({
								winEffectType = NameToId[List.Value],
								winningPlayer = lplr
							})
						end
					end
				end))
			end
		end,
		Tooltip = 'Allows you to select any clientside win effect'
	})
	local WinEffectName = {}
	for i, v in bedwars.WinEffectMeta do
		table.insert(WinEffectName, v.name)
		NameToId[v.name] = i
	end
	table.sort(WinEffectName)
	List = WinEffect:CreateDropdown({
		Name = 'Effects',
		List = WinEffectName
	})
end)

run(function()
	local Value
	local WallCheck
	local AutoJump
	local AlwaysJump
	local rayCheck = RaycastParams.new()
	rayCheck.RespectCanCollide = true
	
	Speed = vape.Categories.Blatant:CreateModule({
		Name = 'Speed',
		Function = function(callback)
			frictionTable.Speed = callback or nil
			updateVelocity()

	
			if callback then
				Speed:Clean(runService.PreSimulation:Connect(function(dt)
					bedwars.StatefulEntityKnockbackController.lastImpulseTime = callback and math.huge or time()
					if entitylib.isAlive and not Fly.Enabled and not InfiniteFly.Enabled and not LongJump.Enabled and isnetworkowner(entitylib.character.RootPart) then
						local state = entitylib.character.Humanoid:GetState()
						if state == Enum.HumanoidStateType.Climbing then return end
	
						local root, velo = entitylib.character.RootPart, getSpeed()
						local moveDirection = AntiFallDirection or entitylib.character.Humanoid.MoveDirection
						local destination = (moveDirection * math.max(Value.Value - velo, 0) * dt)
	
						if WallCheck.Enabled then
							rayCheck.FilterDescendantsInstances = {lplr.Character, gameCamera}
							rayCheck.CollisionGroup = root.CollisionGroup
							local ray = workspace:Raycast(root.Position, destination, rayCheck)
							if ray then
								destination = ((ray.Position + ray.Normal) - root.Position)
							end
						end
	
						root.CFrame += destination
						root.AssemblyLinearVelocity = (moveDirection * velo) + Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
						if AutoJump.Enabled and (state == Enum.HumanoidStateType.Running or state == Enum.HumanoidStateType.Landed) and moveDirection ~= Vector3.zero and (Attacking or AlwaysJump.Enabled) then
							entitylib.character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
						end
					end
				end))
			end
		end,
		ExtraText = function()
			return 'Heatseeker'
		end,
		Tooltip = 'Increases your movement with various methods. (higher than 23 will cause major anti-cheat)'
	})
	Value = Speed:CreateSlider({
		Name = 'Speed',
		Min = 1,
		Max = 45,
		Default = 23,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	WallCheck = Speed:CreateToggle({
		Name = 'Wall Check',
		Default = true
	})
	AutoJump = Speed:CreateToggle({
		Name = 'AutoJump',
		Function = function(callback)
			AlwaysJump.Object.Visible = callback
		end
	})
	AlwaysJump = Speed:CreateToggle({
		Name = 'Always Jump',
		Visible = false,
		Darker = true
	})
end)

run(function()
	local Value
	local VerticalValue
	local WallCheck
	local PopBalloons
	local TP
	local rayCheck = RaycastParams.new()
	rayCheck.RespectCanCollide = true
	local up, down, old = 0, 0

	Fly = vape.Categories.Blatant:CreateModule({
		Name = 'Fly',
		Function = function(callback)
			frictionTable.Fly = callback or nil
			updateVelocity()
			if callback then
				up, down, old = 0, 0, bedwars.BalloonController.deflateBalloon
				bedwars.BalloonController.deflateBalloon = function() end
				local tpTick, tpToggle, oldy = tick(), true

				if lplr.Character and (lplr.Character:GetAttribute('InflatedBalloons') or 0) == 0 and getItem('balloon') then
					bedwars.BalloonController:inflateBalloon()
				end
				Fly:Clean(vapeEvents.AttributeChanged.Event:Connect(function(changed)
					if changed == 'InflatedBalloons' and (lplr.Character:GetAttribute('InflatedBalloons') or 0) == 0 and getItem('balloon') then
						bedwars.BalloonController:inflateBalloon()
					end
				end))
				Fly:Clean(runService.PreSimulation:Connect(function(dt)
					if entitylib.isAlive and not InfiniteFly.Enabled and isnetworkowner(entitylib.character.RootPart) then
						local flyAllowed = (lplr.Character:GetAttribute('InflatedBalloons') and lplr.Character:GetAttribute('InflatedBalloons') > 0) or store.matchState == 2
						local mass = (1.5 + (flyAllowed and 6 or 0) * (tick() % 0.4 < 0.2 and -1 or 1)) + ((up + down) * VerticalValue.Value)
						local root, moveDirection = entitylib.character.RootPart, entitylib.character.Humanoid.MoveDirection
						local velo = getSpeed()
						local destination = (moveDirection * math.max(Value.Value - velo, 0) * dt)
						rayCheck.FilterDescendantsInstances = {lplr.Character, gameCamera, AntiFallPart}
						rayCheck.CollisionGroup = root.CollisionGroup

						if WallCheck.Enabled then
							local ray = workspace:Raycast(root.Position, destination, rayCheck)
							if ray then
								destination = ((ray.Position + ray.Normal) - root.Position)
							end
						end

						if not flyAllowed then
							if tpToggle then
								local airleft = (tick() - entitylib.character.AirTime)
								if airleft > 2 then
									if not oldy then
										local ray = workspace:Raycast(root.Position, Vector3.new(0, -1000, 0), rayCheck)
										if ray and TP.Enabled then
											tpToggle = false
											oldy = root.Position.Y
											tpTick = tick() + 0.11
											root.CFrame = CFrame.lookAlong(Vector3.new(root.Position.X, ray.Position.Y + entitylib.character.HipHeight, root.Position.Z), root.CFrame.LookVector)
										end
									end
								end
							else
								if oldy then
									if tpTick < tick() then
										local newpos = Vector3.new(root.Position.X, oldy, root.Position.Z)
										root.CFrame = CFrame.lookAlong(newpos, root.CFrame.LookVector)
										tpToggle = true
										oldy = nil
									else
										mass = 0
									end
								end
							end
						end

						root.CFrame += destination
						root.AssemblyLinearVelocity = (moveDirection * velo) + Vector3.new(0, mass, 0)
					end
				end))
				Fly:Clean(inputService.InputBegan:Connect(function(input)
					if not inputService:GetFocusedTextBox() then
						if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA then
							up = 1
						elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonL2 then
							down = -1
						end
					end
				end))
				Fly:Clean(inputService.InputEnded:Connect(function(input)
					if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA then
						up = 0
					elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonL2 then
						down = 0
					end
				end))
				if inputService.TouchEnabled then
					pcall(function()
						local jumpButton = lplr.PlayerGui.TouchGui.TouchControlFrame.JumpButton
						Fly:Clean(jumpButton:GetPropertyChangedSignal('ImageRectOffset'):Connect(function()
							up = jumpButton.ImageRectOffset.X == 146 and 1 or 0
						end))
					end)
				end
			else
				bedwars.BalloonController.deflateBalloon = old
				if PopBalloons.Enabled and entitylib.isAlive and (lplr.Character:GetAttribute('InflatedBalloons') or 0) > 0 then
					for _ = 1, 3 do
						bedwars.BalloonController:deflateBalloon()
					end
				end
			end
		end,
		ExtraText = function()
			return 'Heatseeker'
		end,
		Tooltip = 'Makes you go zoom.'
	})
	Value = Fly:CreateSlider({
		Name = 'Speed',
		Min = 1,
		Max = 23,
		Default = 23,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	VerticalValue = Fly:CreateSlider({
		Name = 'Vertical Speed',
		Min = 1,
		Max = 150,
		Default = 50,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	WallCheck = Fly:CreateToggle({
		Name = 'Wall Check',
		Default = true
	})
	PopBalloons = Fly:CreateToggle({
		Name = 'Pop Balloons',
		Default = true
	})
	TP = Fly:CreateToggle({
		Name = 'TP Down',
		Default = true
	})
end)
																																																						
run(function()	

	NM = vape.Categories.Troll:CreateModule({
		Name = 'Nightmare Emote',
		Tooltip = 'Client-Sided nightmare emote, animation is Server-Side visuals are Client-Sided',
		Function = function(callback)
			if callback then				
				local TweenService = game:GetService("TweenService")
				local player = game:GetService("Players").LocalPlayer
				local CharForNM = lplr.Character
				
				if not CharForNM then return end
				
				local NightmareEmote = game:GetService("ReplicatedStorage"):WaitForChild("Assets"):WaitForChild("Effects"):WaitForChild("NightmareEmote"):Clone()
				asset = NightmareEmote
				NightmareEmote.Parent = game.Workspace
				lastPosition = CharForNM.PrimaryPart and CharForNM.PrimaryPart.Position or Vector3.new()
				
				task.spawn(function()
					while asset ~= nil do
						local currentPosition = CharForNM.PrimaryPart and CharForNM.PrimaryPart.Position
						if currentPosition and (currentPosition - lastPosition).Magnitude > 0.1 then
							asset:Destroy()
							asset = nil
							NM:Toggle()
							break
						end
						lastPosition = currentPosition
						NightmareEmote:SetPrimaryPartCFrame(CharForNM.LowerTorso.CFrame + Vector3.new(0, -2, 0))
						task.wait(0.1)
					end
				end)
				
				local NMDescendants = NightmareEmote:GetDescendants()
				local function PartStuff(Prt)
					if Prt:IsA("BasePart") then
						Prt.CanCollide = false
						Prt.Anchored = true
					end
				end
				for i, v in ipairs(NMDescendants) do
					PartStuff(v, i - 1, NMDescendants)
				end
				local Outer = NightmareEmote:FindFirstChild("Outer")
				if Outer then
					TweenService:Create(Outer, TweenInfo.new(1.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), {
						Orientation = Outer.Orientation + Vector3.new(0, 360, 0)
					}):Play()
				end
				local Middle = NightmareEmote:FindFirstChild("Middle")
				if Middle then
					TweenService:Create(Middle, TweenInfo.new(12.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), {
						Orientation = Middle.Orientation + Vector3.new(0, -360, 0)
					}):Play()
				end
                anim = Instance.new("Animation")
				anim.AnimationId = "rbxassetid://9191822700"
				anim = CharForNM.Humanoid:LoadAnimation(anim)
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
	local GetHost = {}
	GetHost = vape.Categories.Troll:CreateModule({
		Name = "GetHost",
		Tooltip = "this module is only for show. None of the settings will work.",
		Function = function(callback) 
			if callback then
				task.spawn(function()
					game.Players.LocalPlayer:SetAttribute("CustomMatchRole", "host")
				end)
			end	
		end
	})
end)

run(function()
	local collectionService = game:GetService("CollectionService")
	local debris = game:GetService("Debris")
	local Icons = {
		["iron"] = "rbxassetid://6850537969",
		["bee"] = "rbxassetid://7343272839",
		["natures_essence_1"] = "rbxassetid://11003449842",
		["thorns"] = "rbxassetid://9134549615",
		["mushrooms"] = "rbxassetid://9134534696",
		["wild_flower"] = "rbxassetid://9134545166",
		["crit_star"] = "rbxassetid://9866757805",
		["vitality_star"] = "rbxassetid://9866757969",
		["sheep"] = "rbxassetid://78493823174512",
		["crystal"] = "rbxassetid://94842987168294",
		["Ghost"] = "rbxassetid://78249785309968",
		['Spirit'] = "rbxassetid://132108376114488"
	}
	local espobjs = {}
	local espfold = Instance.new("Folder")
	local gui = Instance.new("ScreenGui", game:GetService("Players").LocalPlayer.PlayerGui)
	gui.ResetOnSpawn = false
	espfold.Parent = gui

	local hidden = false

	local function isKeybindValid(key)
		return Enum.KeyCode[key] ~= nil
	end

	local function showNotification(message)
		local notification = Instance.new("TextLabel")
		notification.Size = UDim2.new(0, 300, 0, 50)
		notification.Position = UDim2.new(0.5, -150, 0, 50)
		notification.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		notification.TextColor3 = Color3.new(1, 1, 1)
		notification.Font = Enum.Font.SourceSansBold
		notification.TextSize = 20
		notification.Text = message
		notification.AnchorPoint = Vector2.new(0.5, 0)
		notification.Parent = gui

		debris:AddItem(notification, 3)
	end

	local function espadd(v, icon)
		local billboard = Instance.new("BillboardGui")
		billboard.Parent = espfold
		billboard.Name = "iron"
		billboard.StudsOffsetWorldSpace = Vector3.new(0, 3, 1.5)
		billboard.Size = UDim2.new(0, 32, 0, 32)
		billboard.AlwaysOnTop = true
		billboard.Adornee = v
		local image = Instance.new("ImageLabel")
		image.BackgroundTransparency = 0.5
		image.BorderSizePixel = 0
		image.Image = Icons[icon] or ""
		image.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
		image.Size = UDim2.new(0, 32, 0, 32)
		image.AnchorPoint = Vector2.new(0.5, 0.5)
		image.Parent = billboard
		local uicorner = Instance.new("UICorner")
		uicorner.CornerRadius = UDim.new(0, 4)
		uicorner.Parent = image
		espobjs[v] = billboard
	end

	local connections = {}

	local function reset()
		for _, v in pairs(connections) do
			pcall(function() v:Disconnect() end)
		end
		espfold:ClearAllChildren()
		table.clear(espobjs)
	end

	local function addKit(tag, icon, custom)
		if not custom then
			local con1 = collectionService:GetInstanceAddedSignal(tag):Connect(function(v)
				espadd(v.PrimaryPart, icon)
			end)
			local con2 = collectionService:GetInstanceRemovedSignal(tag):Connect(function(v)
				if espobjs[v.PrimaryPart] then
					espobjs[v.PrimaryPart]:Destroy()
					espobjs[v.PrimaryPart] = nil
				end
			end)
			table.insert(connections, con1)
			table.insert(connections, con2)
			for _, v in pairs(collectionService:GetTagged(tag)) do
				espadd(v.PrimaryPart, icon)
			end
		else
			local function check(v)
				if v.Name == tag and v.ClassName == "Model" then
					espadd(v.PrimaryPart, icon)
				end
			end
			KitESP:Clean(game.Workspace.ChildAdded:Connect(check))
			KitESP:Clean(game.Workspace.ChildRemoved:Connect(function(v)
				pcall(function()
					if espobjs[v.PrimaryPart] then
						espobjs[v.PrimaryPart]:Destroy()
						espobjs[v.PrimaryPart] = nil
					end
				end)
			end))
			for _, v in pairs(game.Workspace:GetChildren()) do
				check(v)
			end
		end
	end

	local function recreateESP()
		reset()
		addKit("hidden-metal", "iron")
		addKit("bee", "bee")
		addKit("treeOrb", "natures_essence_1")
		
		addKit("Thorns", "thorns", true)
		addKit("Mushrooms", "mushrooms", true)
		addKit("Flower", "wild_flower", true)
		addKit("CritStar", "crit_star", true)
		addKit("VitalityStar", "vitality_star", true)
		addKit("alchemy_crystal", "crystal")															
		addKit("SheepModel", "sheep")															
		addKit("ghost", "Ghost")	
		addKit('spirit_gardener_energy','Spirit',true)
	end

	KitESP = vape.Categories.Minigames:CreateModule({
		Name = "KitESP",
		Tooltip = "Specfic kits work for this module",
		Function = function(callback)
			if callback then
				recreateESP()
			else
				reset()
			end
		end
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
            vape:CreateNotification('Onyx', "Currently fetching mods", 3)
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
                vape:CreateNotification('Onyx', "No Users Selected, Pick a Side/Specific to fetch", 5, "alert")
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
                    vape:CreateNotification('Onyx', "Failed to decode presence JSON", 15, "alert")
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
                                vape:CreateNotification('Onyx', username, 5, "alert")
                            end
                        elseif user.userPresenceType == 1 then 
                            Online = Online + 1
                            vape:CreateNotification('Onyx', username, 15, "warning")
                        elseif user.userPresenceType == 2 then 
                            InGame = InGame + 1
                            vape:CreateNotification('Onyx', username, 15, "warning")
                        elseif user.userPresenceType == 3 then 
                            Studio = Studio + 1
                            if IncludeStudio and IncludeStudio.Value then
                                vape:CreateNotification('Onyx', username, 5, "warning")
                            end
                        end
                    end
                end

                task.wait(5)
                if InGame >= 2 then
                    vape:CreateNotification('Onyx', "There are [" .. InGame .. "] mods in game", 45)
                elseif InGame == 0 then
                    vape:CreateNotification('Onyx', "There are none in-game", 45)
                end

                if Online >= 2 then
                    vape:CreateNotification('Onyx', "There are [" .. Online .. "] mods online", 45)
                elseif Online == 0 then
                    vape:CreateNotification('Onyx', "There are none online", 45)
                end
            else
                vape:CreateNotification('Onyx', "Failed to get presence data: " .. tostring(err), 15, "alert")
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
        7718511355, 7928472983, 7922414080, 7758683476, 4079687909, 1160595313,9613415615
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
	local IdentifyMod
																																																																																		
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
        repeat task.wait(0.1) until vape and vape.Loaded
    end
if checktype == "spectator_join" then
	if 	IdentifyMod.Enabled then 
		if plr.UserId == 22808138 or  plr.UserId == 4782733628 or  plr.UserId == 7447190808 or  plr.UserId == 3196162848 then
		vape:CreateNotification('Onyx', "Chase Has joined!","alert", 15)																																																																																
		end
	if plr.UserId == 547598710 or  plr.UserId == 5728889572 or  plr.UserId == 4652232128 or  plr.UserId == 7043591647  or  plr.UserId == 7209929547 or  plr.UserId == 7043958628 or  plr.UserId == 7418525152 or  plr.UserId == 3774791573 or  plr.UserId == 8606089749 then
	vape:CreateNotification('Onyx', "Orion Has joined!","alert", 15)
	end
	if plr.UserId == 162442297 or  plr.UserId == 702354331 or  plr.UserId == 9350301723  then
	vape:CreateNotification('Onyx', "Lisnix Has joined!","alert", 15)
	end
	if plr.UserId == 307212658 or  plr.UserId == 5097000699 or  plr.UserId == 4923561416 then
	vape:CreateNotification('Onyx', "Nwr Has joined!","alert", 15)
	end
	if plr.UserId == 514679433 or  plr.UserId == 2431747703 or  plr.UserId == 4531785383 then
	vape:CreateNotification('Onyx', "Gorilla Has joined!","alert", 15)
	end
	if plr.UserId == 2428373515 or  plr.UserId == 7659437319 then
	vape:CreateNotification('Onyx', "Typhoon Has joined!","alert", 15)
	end
	if plr.UserId == 2465133159 then
	vape:CreateNotification('Onyx', "Erin Has joined!","alert", 15)
	end
	if plr.UserId == 7558211130 or  plr.UserId == 1708400489 or  plr.UserId == 9554637663 then
	vape:CreateNotification('Onyx', "Ghost Has joined!","alert", 15)
	end
	if plr.UserId == 376388734 or  plr.UserId == 5157136850 then
	vape:CreateNotification('Onyx', "Sponge Has joined!","alert", 15)
	end
	if plr.UserId == 589533315 or  plr.UserId == 567497793 then
	vape:CreateNotification('Onyx', "Gora Has joined!","alert", 15)
	end
	if plr.UserId == 334013471 or  plr.UserId == 145981200 or  plr.UserId == 4721068661 or  plr.UserId == 8006518573 or  plr.UserId == 3547758846 or  plr.UserId == 7155624750 or  plr.UserId == 7468661659 or plr.UserId == 9575298878 then
	vape:CreateNotification('Onyx', "Apple Has joined!","alert", 15)
	end
	if plr.UserId == 239431610 or  plr.UserId == 2621170992 or  plr.UserId == 9613415615 then
	vape:CreateNotification('Onyx', "Dom Has joined!","alert", 15)
	end
	if plr.UserId == 575474067 or  plr.UserId == 4785639950 or  plr.UserId == 8735055832 or plr.UserId == 9636668830 then
	vape:CreateNotification('Onyx', "Kevin Has joined!","alert", 15)
	end
	if plr.UserId == 839818760 or plr.UserId == 1524739259  then
	vape:CreateNotification('Onyx', "Vic Has joined!","alert", 15)
	end
if plr.UserId == 1092621569 or  plr.UserId == 9673014247 or  plr.UserId == 9673085642 or  plr.UserId == 9701608749 or  plr.UserId == 9617190012 or  plr.UserId == 9673029143 or plr.UserId == 9705518292  then
	vape:CreateNotification('Onyx', "Subbico Has joined!","alert", 15)
end
		end	
else
notif('StaffDetector', 'Staff Detected ('..checktype..'): '..plr.Name..' ('..plr.UserId..')', 60, checktypee)
	if 	IdentifyMod.Enabled then 
		if plr.UserId == 22808138 or  plr.UserId == 4782733628 or  plr.UserId == 7447190808 or  plr.UserId == 3196162848 then
		vape:CreateNotification('Onyx', "Chase Has joined!","alert", 15)																																																																																
		end
	if plr.UserId == 547598710 or  plr.UserId == 5728889572 or  plr.UserId == 4652232128 or  plr.UserId == 7043591647  or  plr.UserId == 7209929547 or  plr.UserId == 7043958628 or  plr.UserId == 7418525152 or  plr.UserId == 3774791573 or  plr.UserId == 8606089749 then
	vape:CreateNotification('Onyx', "Orion Has joined!","alert", 15)
	end
	if plr.UserId == 162442297 or  plr.UserId == 702354331 or  plr.UserId == 9350301723  then
	vape:CreateNotification('Onyx', "Lisnix Has joined!","alert", 15)
	end
	if plr.UserId == 307212658 or  plr.UserId == 5097000699 or  plr.UserId == 4923561416 then
	vape:CreateNotification('Onyx', "Nwr Has joined!","alert", 15)
	end
	if plr.UserId == 514679433 or  plr.UserId == 2431747703 or  plr.UserId == 4531785383 then
	vape:CreateNotification('Onyx', "Gorilla Has joined!","alert", 15)
	end
	if plr.UserId == 2428373515 or  plr.UserId == 7659437319 then
	vape:CreateNotification('Onyx', "Typhoon Has joined!","alert", 15)
	end
	if plr.UserId == 2465133159 then
	vape:CreateNotification('Onyx', "Erin Has joined!","alert", 15)
	end
	if plr.UserId == 7558211130 or  plr.UserId == 1708400489 or  plr.UserId == 9554637663 then
	vape:CreateNotification('Onyx', "Ghost Has joined!","alert", 15)
	end
	if plr.UserId == 376388734 or  plr.UserId == 5157136850 then
	vape:CreateNotification('Onyx', "Sponge Has joined!","alert", 15)
	end
	if plr.UserId == 589533315 or  plr.UserId == 567497793 then
	vape:CreateNotification('Onyx', "Gora Has joined!","alert", 15)
	end
	if plr.UserId == 334013471 or  plr.UserId == 145981200 or  plr.UserId == 4721068661 or  plr.UserId == 8006518573 or  plr.UserId == 3547758846 or  plr.UserId == 7155624750 or  plr.UserId == 7468661659 or plr.UserId == 9575298878 then
	vape:CreateNotification('Onyx', "Apple Has joined!","alert", 15)
	end
	if plr.UserId == 239431610 or  plr.UserId == 2621170992 or  plr.UserId == 9613415615 then
	vape:CreateNotification('Onyx', "Dom Has joined!","alert", 15)
	end
	if plr.UserId == 575474067 or  plr.UserId == 4785639950 or  plr.UserId == 8735055832 or plr.UserId == 9636668830 then
	vape:CreateNotification('Onyx', "Kevin Has joined!","alert", 15)
	end
	if plr.UserId == 839818760 or plr.UserId == 1524739259  then
	vape:CreateNotification('Onyx', "Vic Has joined!","alert", 15)
	end
if plr.UserId == 1092621569 or  plr.UserId == 9673014247 or  plr.UserId == 9673085642 or  plr.UserId == 9701608749 or  plr.UserId == 9617190012 or  plr.UserId == 9673029143 or plr.UserId == 9705518292  then
	vape:CreateNotification('Onyx', "Subbico Has joined!","warning", 15)
end
																																																																																
     end																																																																																				
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
        local dateString = tostring(DateTime.now())

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

	IdentifyMod = StaffDetector:CreateToggle({
        Name = 'IdentifyMods',
        Default = true,
        Tooltip = "Identify's known mods"
    })																																																																																		
end)																																																												
run(function()
  local Players = game:GetService("Players")
local player = Players.LocalPlayer
    local PlayerLevel
	local level 
  

PlayerLevel = vape.Categories.Exploits:CreateModule({
        Name = 'SetPlayerLevel',
	Tooltip = "Sets your player level to 1000 (client sided)",
        Function = function()
		game.Players.LocalPlayer:SetAttribute("PlayerLevel", level.Value)
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


end)

run(function()
    local KitRender
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    local PlayerGui = player:WaitForChild("PlayerGui")

    local ids = {
        ['none'] = "rbxassetid://16493320215",
        ["random"] = "rbxassetid://79773209697352",
        ["cowgirl"] = "rbxassetid://9155462968",
        ["davey"] = "rbxassetid://9155464612",
        ["warlock"] = "rbxassetid://15186338366",
        ["ember"] = "rbxassetid://9630017904",
        ["black_market_trader"] = "rbxassetid://9630017904",
        ["yeti"] = "rbxassetid://9166205917",
        ["scarab"] = "rbxassetid://137137517627492",
        ["defender"] = "rbxassetid://131690429591874",
        ["cactus"] = "rbxassetid://104436517801089",
        ["oasis"] = "rbxassetid://120283205213823",
        ["berserker"] = "rbxassetid://90258047545241",
        ["sword_shield"] = "rbxassetid://131690429591874",
        ["airbender"] = "rbxassetid://74712750354593",
        ["gun_blade"] = "rbxassetid://138231219644853",
        ["frost_hammer_kit"] = "rbxassetid://11838567073",
        ["spider_queen"] = "rbxassetid://95237509752482",
        ["archer"] = "rbxassetid://9224796984",
        ["axolotl"] = "rbxassetid://9155466713",
        ["baker"] = "rbxassetid://9155463919",
        ["barbarian"] = "rbxassetid://9166207628",
        ["builder"] = "rbxassetid://9155463708",
        ["necromancer"] = "rbxassetid://11343458097",
        ["cyber"] = "rbxassetid://9507126891",
        ["sorcerer"] = "rbxassetid://97940108361528",
        ["bigman"] = "rbxassetid://9155467211",
        ["spirit_assassin"] = "rbxassetid://10406002412",
        ["farmer_cletus"] = "rbxassetid://9155466936",
        ["ice_queen"] = "rbxassetid://9155466204",
        ["grim_reaper"] = "rbxassetid://9155467410",
        ["spirit_gardener"] = "rbxassetid://132108376114488",
        ["hannah"] = "rbxassetid://10726577232",
        ["shielder"] = "rbxassetid://9155464114",
        ["summoner"] = "rbxassetid://18922378956",
        ["glacial_skater"] = "rbxassetid://84628060516931",
        ["dragon_sword"] = "rbxassetid://16215630104",
        ["lumen"] = "rbxassetid://9630018371",
        ["flower_bee"] = "rbxassetid://101569742252812",
        ["jellyfish"] = "rbxassetid://18129974852",
        ["melody"] = "rbxassetid://9155464915",
        ["mimic"] = "rbxassetid://14783283296",
        ["miner"] = "rbxassetid://9166208461",
        ["nazar"] = "rbxassetid://18926951849",
        ["seahorse"] = "rbxassetid://11902552560",
        ["elk_master"] = "rbxassetid://15714972287",
        ["rebellion_leader"] = "rbxassetid://18926409564",
        ["void_hunter"] = "rbxassetid://122370766273698",
        ["taliyah"] = "rbxassetid://13989437601",
        ["angel"] = "rbxassetid://9166208240",
        ["harpoon"] = "rbxassetid://18250634847",
        ["void_walker"] = "rbxassetid://78915127961078",
        ["spirit_summoner"] = "rbxassetid://95760990786863",
        ["triple_shot"] = "rbxassetid://9166208149",
        ["void_knight"] = "rbxassetid://73636326782144",
        ["regent"] = "rbxassetid://9166208904",
        ["vulcan"] = "rbxassetid://9155465543",
        ["owl"] = "rbxassetid://12509401147",
        ["dasher"] = "rbxassetid://9155467645",
        ["disruptor"] = "rbxassetid://11596993583",
        ["wizard"] = "rbxassetid://13353923546",
        ["aery"] = "rbxassetid://9155463221",
        ["agni"] = "rbxassetid://17024640133",
        ["alchemist"] = "rbxassetid://9155462512",
        ["spearman"] = "rbxassetid://9166207341",
        ["beekeeper"] = "rbxassetid://9312831285",
        ["falconer"] = "rbxassetid://17022941869",
        ["bounty_hunter"] = "rbxassetid://9166208649",
        ["blood_assassin"] = "rbxassetid://12520290159",
        ["battery"] = "rbxassetid://10159166528",
        ["steam_engineer"] = "rbxassetid://15380413567",
        ["vesta"] = "rbxassetid://9568930198",
        ["beast"] = "rbxassetid://9155465124",
        ["dino_tamer"] = "rbxassetid://9872357009",
        ["drill"] = "rbxassetid://12955100280",
        ["elektra"] = "rbxassetid://13841413050",
        ["fisherman"] = "rbxassetid://9166208359",
        ["queen_bee"] = "rbxassetid://12671498918",
        ["card"] = "rbxassetid://13841410580",
        ["frosty"] = "rbxassetid://9166208762",
        ["gingerbread_man"] = "rbxassetid://9155464364",
        ["ghost_catcher"] = "rbxassetid://9224802656",
        ["tinker"] = "rbxassetid://17025762404",
        ["ignis"] = "rbxassetid://13835258938",
        ["oil_man"] = "rbxassetid://9166206259",
        ["jade"] = "rbxassetid://9166306816",
        ["dragon_slayer"] = "rbxassetid://10982192175",
        ["paladin"] = "rbxassetid://11202785737",
        ["pinata"] = "rbxassetid://10011261147",
        ["merchant"] = "rbxassetid://9872356790",
        ["metal_detector"] = "rbxassetid://9378298061",
        ["slime_tamer"] = "rbxassetid://15379766168",
        ["nyoka"] = "rbxassetid://17022941410",
        ["midnight"] = "rbxassetid://9155462763",
        ["pyro"] = "rbxassetid://9155464770",
        ["raven"] = "rbxassetid://9166206554",
        ["santa"] = "rbxassetid://9166206101",
        ["sheep_herder"] = "rbxassetid://9155465730",
        ["smoke"] = "rbxassetid://9155462247",
        ["spirit_catcher"] = "rbxassetid://9166207943",
        ["star_collector"] = "rbxassetid://9872356516",
        ["styx"] = "rbxassetid://17014536631",
        ["block_kicker"] = "rbxassetid://15382536098",
        ["trapper"] = "rbxassetid://9166206875",
        ["hatter"] = "rbxassetid://12509388633",
        ["ninja"] = "rbxassetid://15517037848",
        ["jailor"] = "rbxassetid://11664116980",
        ["warrior"] = "rbxassetid://9166207008",
        ["mage"] = "rbxassetid://10982191792",
        ["void_dragon"] = "rbxassetid://10982192753",
        ["cat"] = "rbxassetid://15350740470",
        ["wind_walker"] = "rbxassetid://9872355499",
		['skeleton'] = "rbxassetid://120123419412119"
    }

    local function createkitrender(plr)
        local icon = Instance.new("ImageLabel")
        icon.Name = "ReVapeKitRender"
        icon.AnchorPoint = Vector2.new(1, 0.5)
        icon.BackgroundTransparency = 1
        icon.Position = UDim2.new(1.05, 0, 0.5, 0)
        icon.Size = UDim2.new(1.5, 0, 1.5, 0)
        icon.SizeConstraint = Enum.SizeConstraint.RelativeYY
        icon.ImageTransparency = 0.4
        icon.ScaleType = Enum.ScaleType.Crop
        local uar = Instance.new("UIAspectRatioConstraint")
        uar.AspectRatio = 1
        uar.AspectType = Enum.AspectType.FitWithinMaxSize
        uar.DominantAxis = Enum.DominantAxis.Width
        uar.Parent = icon
        icon.Image = ids[plr:GetAttribute("PlayingAsKits")] or  ids[plr:GetAttribute("PlayingAsKit")] or ids["none"]
        return icon
    end

    local function removeallkitrenders()
        for _, v in ipairs(PlayerGui:GetDescendants()) do
            if v:IsA("ImageLabel") and v.Name == "ReVapeKitRender" then
                v:Destroy()
            end
        end
    end

    local function refreshicon(icon, plr)
        icon.Image = ids[plr:GetAttribute("PlayingAsKits")] or  ids[plr:GetAttribute("PlayingAsKit")] or ids["none"]
    end

    local function findPlayer(label, container)
        local render = container:FindFirstChild("PlayerRender", true)
        if render and render:IsA("ImageLabel") and render.Image then
            local userId = string.match(render.Image, "id=(%d+)")
            if userId then
                local plr = Players:GetPlayerByUserId(tonumber(userId))
                if plr then return plr end
            end
        end
        local text = label.Text
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Name == text or plr.DisplayName == text or plr:GetAttribute("DisguiseDisplayName") == text then
                return plr
            end
        end
    end

    local function handleLabel(label)
        if not (label:IsA("TextLabel") and label.Name == "PlayerName") then return end
        task.spawn(function()
            local container = label.Parent
            for _ = 1, 3 do
                if container and container.Parent then
                    container = container.Parent
                end
            end
            if not container or not container:IsA("Frame") then return end
            local playerFound = findPlayer(label, container)
            if not playerFound then
                task.wait(0.5)
                playerFound = findPlayer(label, container)
            end
            if not playerFound then return end
            container.Name = playerFound.Name
            local card = container:FindFirstChild("1") and container["1"]:FindFirstChild("MatchDraftPlayerCard")
            if not card then return end
            local icon = card:FindFirstChild("ReVapeKitRender")
            if not icon then
                icon = createkitrender(playerFound)
                icon.Parent = card
            end
            task.spawn(function()
                while container and container.Parent do
                    local updatedPlayer = findPlayer(label, container)
                    if updatedPlayer and updatedPlayer ~= playerFound then
                        playerFound = updatedPlayer
                    end
                    if playerFound and icon then
                        refreshicon(icon, playerFound)
                    end
                    task.wait(1.2)
                end
            end)
        end)
    end

    KitRender = vape.Categories.Exploits:CreateModule({
        Name = "KitRender",
        Tooltip = "Allows you to see everyone's kit during kit phase (5v5, Ranked)",
        Function = function(callback)
            if callback then
                task.spawn(function()
                    local team2 = PlayerGui:WaitForChild("MatchDraftApp"):WaitForChild("DraftAppBackground"):WaitForChild("BodyContainer"):WaitForChild("Team2Column")
                    for _, child in ipairs(team2:GetDescendants()) do
                        if KitRender.Enabled then handleLabel(child) end
                    end
                    KitRender:Clean(team2.DescendantAdded:Connect(function(child)
                        if KitRender.Enabled then handleLabel(child) end
                    end))
                end)
            else
                removeallkitrenders()
            end
        end
    })
end)

run(function()

    local aim = 0.158
    local tnt = 0.0045
    local aunchself = 0.395

    local defaultaim = 0.4
    local defaulttnt = 0.2
    local defaultself = 0.4

    local function getWorldFolder()
        local Map = workspace:WaitForChild("Map", math.huge)
        local Worlds = Map:WaitForChild("Worlds", math.huge)
        if not Worlds then return nil end

        return Worlds:GetChildren()[1] 
    end

    local function setCannonSpeeds(blocksFolder, aimDur, tntDur, selfDur)
        for _, v in ipairs(blocksFolder:GetChildren()) do 
            if v:IsA("BasePart") and v.Name == "cannon" then
                local AimPrompt = v:FindFirstChild("AimPrompt")
                local FirePrompt = v:FindFirstChild("FirePrompt")
                local LaunchSelfPrompt = v:FindFirstChild("LaunchSelfPrompt")
                if AimPrompt and FirePrompt and LaunchSelfPrompt then
                    AimPrompt.HoldDuration = aimDur
                    FirePrompt.HoldDuration = tntDur
                    LaunchSelfPrompt.HoldDuration = selfDur
                end
            end
        end
    end

    BetterDavey = vape.Categories.Exploits:CreateModule({
        Name = "BetterDavey",
        Tooltip = "makes u look better with davey",
        Function = function(callback)
            local worldFolder = getWorldFolder()
            if not worldFolder then return end
            local blocks = worldFolder:WaitForChild("Blocks")

            if callback then
                setCannonSpeeds(blocks, aim, tnt, aunchself)

               BetterDavey:Clean( blocks.ChildAdded:Connect(function(child)
                    if child:IsA("BasePart") and child.Name == "cannon" and BetterDavey.Enabled then
                        local AimPrompt = child:WaitForChild("AimPrompt")
                        local FirePrompt = child:WaitForChild("FirePrompt")
                        local LaunchSelfPrompt = child:WaitForChild("LaunchSelfPrompt")

                        AimPrompt.HoldDuration = aim
                        FirePrompt.HoldDuration = tnt
                        LaunchSelfPrompt.HoldDuration = aunchself
					BetterDavey:Clean(LaunchSelfPrompt.Triggered:Connect(function(p)
						local humanoid = lplr.Character and lplr.Character:FindFirstChildOfClass("Humanoid")
					
						if not humanoid then return end
					
						if Speed.Enabled and Fly.Enabled then
							Fly:Toggle(false)
							task.wait(0.025)
							Speed:Toggle(false)
						elseif Speed.Enabled then
							Speed:Toggle(false)
						elseif Fly.Enabled then
							Fly:Toggle(false)
						end

						bedwars.breakBlock(child)

					
						if humanoid:GetState() ~= Enum.HumanoidStateType.Jumping then
							humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
						end
					end))
                    end
                end))
            else
                setCannonSpeeds(blocks, defaultaim, defaulttnt, defaultself)
            end
        end
    })

end)



run(function() 
	local MatchHistory
	MatchHistory = vape.Categories.AltFarm:CreateModule({
		Name = "MatchHistory",
		Tooltip = 'Resets ur history',
		Function = function(callback)
			if callback then
				MatchHistory:Toggle(false)
				local TeleportService = game:GetService("TeleportService")
				local data = TeleportService:GetLocalPlayerTeleportData()
				MatchHistory:Clean(game:GetService("TeleportService"):Teleport(game.PlaceId, game.Players.LocalPlayer, data))
			end
		end,
	}) 
end)
run(function() 
	local AutoBan
	AutoBan = vape.Categories.AltFarm:CreateModule({
		Name = "AutoBan",
		Tooltip = 'Automatically bans a kit for you(5v5, ranked only)',
		Function = function(callback)
			if callback then
				AutoBan:Toggle(false)
				  local kits = {"berserker", "hatter", "flower_bee", "glacial_skater",'void_dragon','card','cat'}
    for _, kit in ipairs(kits) do
        for i = 0, 1 do
            local args = {kit, i}
			if getgenv().TestMode then
				bedwars.Client:Get('BanKit'):CallServerAsync({[1] = kit,[2] = i})
			else
           		game:GetService("ReplicatedStorage")
                	:WaitForChild("rbxts_include")
                	:WaitForChild("node_modules")
                	:WaitForChild("@rbxts")
                	:WaitForChild("net")
                	:WaitForChild("out")
                	:WaitForChild("_NetManaged")
                	:WaitForChild("BanKit")
                	:InvokeServer(unpack(args))
			end

				
        end
    end

    for i = 0, 1 do
        local args = {"none", i}

			if getgenv().TestMode then
				bedwars.Client:Get('SelectKit'):CallServerAsync({[1] = 'none',[2] = i})
			else
				game:GetService("ReplicatedStorage")
					:WaitForChild("rbxts_include")
					:WaitForChild("node_modules")
					:WaitForChild("@rbxts")
					:WaitForChild("net")
					:WaitForChild("out")
					:WaitForChild("_NetManaged")
					:WaitForChild("SelectKit")
					:InvokeServer(unpack(args))
			end
    end

    task.wait(0.01)
			end
		end,
	}) 
end)



run(function()
	local ItemlessLongjump = {Enabled = false}

	ItemlessLongjump = vape.Categories.Blatant:CreateModule({
		Name = "ItemlessLongjump",
		Function = function(call)
			ItemlessLongjump.Enabled = call
			if call then
				lplr.Character.HumanoidRootPart.Velocity = lplr.Character.HumanoidRootPart.Velocity + Vector3.new(0, 100, 0)
				task.wait(0.3)
				for i = 1, 4 do
					task.wait(0.4)
					lplr.Character.HumanoidRootPart.Velocity = lplr.Character.HumanoidRootPart.Velocity + Vector3.new(0, 75, 0)
				end
task.wait(0.025)
				for i = 1, 2 do
					task.wait(0.125)
					lplr.Character.HumanoidRootPart.Velocity = lplr.Character.HumanoidRootPart.Velocity + Vector3.new(0, 85, 0)
				end

			else
				workspace.Gravity = 192.6
			end
		end,
		Tooltip = "Lets you do a longjump without any items/kits"
	})
end)




run(function()
local AutoReport = {Enabled = false}
local Mode
	 AutoReport = vape.Categories.Exploits:CreateModule({
		Name = "AutoReport",
		Function = function(callback)
			if callback then

				for _, v in ipairs(game:GetService("Players"):GetPlayers()) do
					if v ~= game.Players.LocalPlayer then
						TryToReport(v,Mode.Value)
					end
				end
			end
		end,
		Tooltip = "Automatically reports everyone in the game",
	})
 	Mode = AutoReport:CreateDropdown({
		Name = "Mode",
		List= {"VapeNotify", "BedwarsNotify", "Hidden"}
	})
	AutoReport:Toggle(false)
end)


run(function()
	local AutoQueue
	

	
	AutoQueue = vape.Categories.Exploits:CreateModule({
		Name = 'AutoQueue',
		Function = function(callback)
   			if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium"and role ~= "user"then
				
																							vape:CreateNotification("Onyx", "You do not have permission to use this", 10, "alert")
				return
			end       
			if callback then
				AutoQueue:Clean(vapeEvents.EntityDeathEvent.Event:Connect(function(deathTable)
					if deathTable.finalKill and deathTable.entityInstance == lplr.Character and isEveryoneDead() and store.matchState ~= 2 then
						joinQueue()
					end
				end))
				AutoQueue:Clean(vapeEvents.MatchEndEvent.Event:Connect(joinQueue))
			end
		end,
		Tooltip = 'Automatically queues for the next match'
	})

end)
			
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
        Name = 'QueueMods',
        Tooltip = 'Enhances the Queues display with dynamic gradients!! very cool lel xd nigger',
        Function = function(enabled)
   			if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium"then
																								vape:CreateNotification("Onyx", "You do not have permission to use this", 10, "alert")
				return
			end       
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
        Max = 8,
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

local Attacking
run(function()
	local Killaura
	local SyncHits
	local Targets
	local Sort
	local SwingRange
	local AttackRange
	local ChargeTime
	local AfterSwing
	local UpdateRate
	local AngleSlider
	local MaxTargets
	local Mouse
	local Swing
	local GUI
	local BoxSwingColor
	local BoxAttackColor
	local ParticleTexture
	local ParticleColor1
	local ParticleColor2
	local ParticleSize
	local Face
	local Animation
	local AnimationMode
	local AnimationSpeed
	local AnimationTween
	local Limit
	local SC = {Enabled = false}
	local RV
	local LegitAura = {}
	local Particles, Boxes = {}, {}
	local anims, AnimDelay, AnimTween, armC0 = vape.Libraries.auraanims, tick()
	local AttackRemote = {FireServer = function() end}
	task.spawn(function()
		AttackRemote = bedwars.Client:Get(remotes.AttackEntity).instance
	end)

	local function getAttackData()
		if Mouse.Enabled then
			if not inputService:IsMouseButtonPressed(0) then return false end
		end

		if GUI.Enabled then
			if bedwars.AppController:isLayerOpen(bedwars.UILayers.MAIN) then return false end
		end

		local sword = Limit.Enabled and store.hand or store.tools.sword
		if not sword or not sword.tool then return false end

		local meta = bedwars.ItemMeta[sword.tool.Name]
		if Limit.Enabled then
			if store.hand.toolType ~= 'sword' or bedwars.DaoController.chargingMaid then return false end
		end

		if LegitAura.Enabled then
			if (tick() - bedwars.SwordController.lastSwing) > 0.2 then return false end
		end

		return sword, meta
	end

	Killaura = vape.Categories.Blatant:CreateModule({
		Name = 'Killaura',
		Function = function(callback)
			if callback then
				if inputService.TouchEnabled then
					pcall(function()
						lplr.PlayerGui.MobileUI['2'].Visible = Limit.Enabled
					end)
				end

				if Animation.Enabled and not (identifyexecutor and table.find({'Argon', 'Delta','Codex'}, ({identifyexecutor()})[1])) then
					local fake = {
						Controllers = {
							ViewmodelController = {
								isVisible = function()
									return not Attacking
								end,
								playAnimation = function(...)
									if not Attacking then
										bedwars.ViewmodelController:playAnimation(select(2, ...))
									end
								end
							}
						}
					}
					debug.setupvalue(oldSwing or bedwars.SwordController.playSwordEffect, 6, fake)
					debug.setupvalue(bedwars.ScytheController.playLocalAnimation, 3, fake)

					task.spawn(function()
						local started = false
						repeat
							if Attacking then
								if not armC0 then
									armC0 = gameCamera.Viewmodel.RightHand.RightWrist.C0
								end
								local first = not started
								started = true

								if AnimationMode.Value == 'Random' then
									anims.Random = {{CFrame = CFrame.Angles(math.rad(math.random(1, 360)), math.rad(math.random(1, 360)), math.rad(math.random(1, 360))), Time = 0.12}}
								end

								for _, v in anims[AnimationMode.Value] do
									AnimTween = tweenService:Create(gameCamera.Viewmodel.RightHand.RightWrist, TweenInfo.new(first and (AnimationTween.Enabled and 0.001 or 0.1) or v.Time / AnimationSpeed.Value, Enum.EasingStyle.Linear), {
										C0 = armC0 * v.CFrame
									})
									AnimTween:Play()
									AnimTween.Completed:Wait()
									first = false
									if (not Killaura.Enabled) or (not Attacking) then break end
								end
							elseif started then
								started = false
								AnimTween = tweenService:Create(gameCamera.Viewmodel.RightHand.RightWrist, TweenInfo.new(AnimationTween.Enabled and 0.001 or 0.3, Enum.EasingStyle.Exponential), {
									C0 = armC0
								})
								AnimTween:Play()
							end

							if not started then
								task.wait(1 / UpdateRate.Value)
							end
						until (not Killaura.Enabled) or (not Animation.Enabled)
					end)
				end

				local swingCooldown = 0
				repeat
					local attacked, sword, meta = {}, getAttackData()
					Attacking = false
					store.KillauraTarget = nil
					if sword then
						if SC.Enabled and entitylib.isAlive and lplr.Character:FindFirstChild("elk") then return end
						local isClaw = string.find(string.lower(tostring(sword and sword.itemType or "")), "summoner_claw")	
						local plrs = entitylib.AllPosition({
							Range = SwingRange.Value,
							Wallcheck = Targets.Walls.Enabled or nil,
							Part = 'RootPart',
							Players = Targets.Players.Enabled,
							NPCs = Targets.NPCs.Enabled,
							Limit = MaxTargets.Value,
							Sort = sortmethods[Sort.Value]
						})

						if #plrs > 0 then
							if store.equippedKit == "ember" and sword.itemType == "infernal_saber" then
								bedwars.Client:Get('HellBladeRelease'):FireServer({chargeTime = 1, player = lplr, weapon = sword.tool})
							end
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
								targetinfo.Targets[v] = tick() + 1

								if not Attacking then
									Attacking = true
									store.KillauraTarget = v
									if not Swing.Enabled and AnimDelay < tick() and not LegitAura.Enabled then
										AnimDelay = tick() + (meta.sword.respectAttackSpeedForEffects and meta.sword.attackSpeed or math.max(ChargeTime.Value, 0.11))
										bedwars.SwordController:playSwordEffect(meta, false)
										if meta.displayName:find(' Scythe') then
											bedwars.ScytheController:playLocalAnimation()
										end

										if vape.ThreadFix then
											setthreadidentity(8)
										end
									end
								end

								if delta.Magnitude > AttackRange.Value then continue end
								if delta.Magnitude < 14.4 and (tick() - swingCooldown) < math.max(ChargeTime.Value, 0.02) then continue end

								local actualRoot = v.Character.PrimaryPart
								if actualRoot then
									local dir = CFrame.lookAt(selfpos, actualRoot.Position).LookVector
									local pos = selfpos + dir * math.max(delta.Magnitude - 14.399, 0)
									swingCooldown = SyncHit.Enabled and (tick() - 0.045) or tick()
									bedwars.SwordController.lastAttack = workspace:GetServerTimeNow()
									store.attackReach = SyncHit.Enabled and ((delta.Magnitude * 100) // 1 / 100 - 0.045) or (delta.Magnitude * 100) // 1 / 100
									store.attackReachUpdate = SyncHit.Enabled and (tick() + 1 - 0.0045) or tick() + 1

									if delta.Magnitude < 14.4 and ChargeTime.Value > 0.11 then
										AnimDelay = tick()
									end

									local Q = 0.5
									if SyncHit.Enabled  then Q = 0.35 else Q = 0.5 end
										if isClaw then
											KaidaController:request(v.Character)
										else
											AttackRemote:FireServer({
												weapon = sword.tool,
												chargedAttack = {chargeRatio = 0},
												entityInstance = v.Character,
												validate = {
													raycast = {},
													targetPosition = {value = actualRoot.Position},
													selfPosition = {value = pos}
												}
										})
										if not v.Character then
											print("player is dead")
										end
									end
								end
							end
						end
					end

					for i, v in Boxes do
						v.Adornee = attacked[i] and attacked[i].Entity.RootPart or nil
						if v.Adornee then
							v.Color3 = Color3.fromHSV(attacked[i].Check.Hue, attacked[i].Check.Sat, attacked[i].Check.Value)
							v.Transparency = 1 - attacked[i].Check.Opacity
						end
					end

					for i, v in Particles do
						v.Position = attacked[i] and attacked[i].Entity.RootPart.Position or Vector3.new(9e9, 9e9, 9e9)
						v.Parent = attacked[i] and gameCamera or nil
					end

					if Face.Enabled and attacked[1] then
						local vec = attacked[1].Entity.RootPart.Position * Vector3.new(1, 0, 1)
						entitylib.character.RootPart.CFrame = CFrame.lookAt(entitylib.character.RootPart.Position, Vector3.new(vec.X, entitylib.character.RootPart.Position.Y + 0.001, vec.Z))
					end

					task.wait(1 / UpdateRate.Value)
				until not Killaura.Enabled
			else
				store.KillauraTarget = nil
				for _, v in Boxes do
					v.Adornee = nil
				end
				for _, v in Particles do
					v.Parent = nil
				end
				if inputService.TouchEnabled then
					pcall(function()
						lplr.PlayerGui.MobileUI['2'].Visible = true
					end)
				end
				debug.setupvalue(oldSwing or bedwars.SwordController.playSwordEffect, 6, bedwars.Knit)
				debug.setupvalue(bedwars.ScytheController.playLocalAnimation, 3, bedwars.Knit)
				Attacking = false
				if armC0 then
					AnimTween = tweenService:Create(gameCamera.Viewmodel.RightHand.RightWrist, TweenInfo.new(AnimationTween.Enabled and 0.001 or 0.3, Enum.EasingStyle.Exponential), {
						C0 = armC0
					})
					AnimTween:Play()
				end
			end
		end,
		Tooltip = 'Attack players around you\nwithout aiming at them.'
	})
	Targets = Killaura:CreateTargets({
		Players = true,
		NPCs = true
	})
	RV = Killaura:CreateToggle({Name = "Range Visual";Default = false;Darker = true;Visible = false})
	local methods = {'Damage', 'Distance'}
	for i in sortmethods do
		if not table.find(methods, i) then
			table.insert(methods, i)
		end
	end
	local MaxRange = 0
	if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium" and role ~= "user"  then
		MaxRange = 14
		SyncHit = {Enabled = false}
	elseif role == "user" then
		MaxRange = 18
		SyncHit = Killaura:CreateToggle({
			Name = 'Sync Hit-Time',
			Tooltip = "Synchronize's ur hit time",
			Default = false
		})
	elseif role == "premium" then
		MaxRange = 24
		SyncHit = Killaura:CreateToggle({
			Name = 'Sync Hit-Time',
			Tooltip = "Synchronize's ur hit time",
			Default = false
		})
	elseif role == "friend" or role == "admin" or role == "coowner" or role == "owner" then
		MaxRange = 32
		SyncHit = Killaura:CreateToggle({
			Name = 'Sync Hit-Time',
			Tooltip = "Synchronize's ur hit time",
			Default = false
		})
	else
		MaxRange = 18
		SyncHit = {Enabled = false}
	end

	SwingRange = Killaura:CreateSlider({
		Name = 'Swing range',
		Min = 1,
		Max = MaxRange,
		Default = 18,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	AttackRange = Killaura:CreateSlider({
		Name = 'Attack range',
		Min = 1,
		Max = MaxRange,
		Default = 18,
		Suffix = function(val)
			return val == 1 and 'stud' or 'studs'
		end
	})
	ChargeTime = Killaura:CreateSlider({
		Name = 'Swing time',
		Min = 0,
		Max = 1,
		Default = 0.3,
		Decimal = 100
	})
	AfterSwing = Killaura:CreateSlider({
		Name = 'After Swing',
		Min = 0.25,
		Max = 2,
		Default = 0.5,
		Suffix = 's',
	})
	AngleSlider = Killaura:CreateSlider({
		Name = 'Max angle',
		Min = 1,
		Max = 360,
		Default = 360
	})
	UpdateRate = Killaura:CreateSlider({
		Name = 'Update rate',
		Min = 1,
		Max = 360,
		Default = 60,
		Suffix = 'hz'
	})
	MaxTargets = Killaura:CreateSlider({
		Name = 'Max targets',
		Min = 1,
		Max = 8,
		Default = 5
	})
	Sort = Killaura:CreateDropdown({
		Name = 'Target Mode',
		List = methods
	})
	Mouse = Killaura:CreateToggle({Name = 'Require mouse down'})
	Swing = Killaura:CreateToggle({Name = 'No Swing'})
	GUI = Killaura:CreateToggle({Name = 'GUI check'})
	Killaura:CreateToggle({
		Name = 'Show target',
		Function = function(callback)
			BoxSwingColor.Object.Visible = callback
			BoxAttackColor.Object.Visible = callback
			if callback then
				for i = 1, 10 do
					local box = Instance.new('BoxHandleAdornment')
					box.Adornee = nil
					box.AlwaysOnTop = true
					box.Size = Vector3.new(3, 5, 3)
					box.CFrame = CFrame.new(0, -0.5, 0)
					box.ZIndex = 0
					box.Parent = vape.gui
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
	BoxSwingColor = Killaura:CreateColorSlider({
		Name = 'Target Color',
		Darker = true,
		DefaultHue = 0.6,
		DefaultOpacity = 0.5,
		Visible = false
	})
	BoxAttackColor = Killaura:CreateColorSlider({
		Name = 'Attack Color',
		Darker = true,
		DefaultOpacity = 0.5,
		Visible = false
	})
	Killaura:CreateToggle({
		Name = 'Target particles',
		Function = function(callback)
			ParticleTexture.Object.Visible = callback
			ParticleColor1.Object.Visible = callback
			ParticleColor2.Object.Visible = callback
			ParticleSize.Object.Visible = callback
			if callback then
				for i = 1, 10 do
					local part = Instance.new('Part')
					part.Size = Vector3.new(2, 4, 2)
					part.Anchored = true
					part.CanCollide = false
					part.Transparency = 1
					part.CanQuery = false
					part.Parent = Killaura.Enabled and gameCamera or nil
					local particles = Instance.new('ParticleEmitter')
					particles.Brightness = 1.5
					particles.Size = NumberSequence.new(ParticleSize.Value)
					particles.Shape = Enum.ParticleEmitterShape.Sphere
					particles.Texture = ParticleTexture.Value
					particles.Transparency = NumberSequence.new(0)
					particles.Lifetime = NumberRange.new(0.4)
					particles.Speed = NumberRange.new(16)
					particles.Rate = 128
					particles.Drag = 16
					particles.ShapePartial = 1
					particles.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromHSV(ParticleColor1.Hue, ParticleColor1.Sat, ParticleColor1.Value)),
						ColorSequenceKeypoint.new(1, Color3.fromHSV(ParticleColor2.Hue, ParticleColor2.Sat, ParticleColor2.Value))
					})
					particles.Parent = part
					Particles[i] = part
				end
			else
				for _, v in Particles do
					v:Destroy()
				end
				table.clear(Particles)
			end
		end
	})
	ParticleTexture = Killaura:CreateTextBox({
		Name = 'Texture',
		Default = 'rbxassetid://14736249347',
		Function = function()
			for _, v in Particles do
				v.ParticleEmitter.Texture = ParticleTexture.Value
			end
		end,
		Darker = true,
		Visible = false
	})
	ParticleColor1 = Killaura:CreateColorSlider({
		Name = 'Color Begin',
		Function = function(hue, sat, val)
			for _, v in Particles do
				v.ParticleEmitter.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHSV(hue, sat, val)),
					ColorSequenceKeypoint.new(1, Color3.fromHSV(ParticleColor2.Hue, ParticleColor2.Sat, ParticleColor2.Value))
				})
			end
		end,
		Darker = true,
		Visible = false
	})
	ParticleColor2 = Killaura:CreateColorSlider({
		Name = 'Color End',
		Function = function(hue, sat, val)
			for _, v in Particles do
				v.ParticleEmitter.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromHSV(ParticleColor1.Hue, ParticleColor1.Sat, ParticleColor1.Value)),
					ColorSequenceKeypoint.new(1, Color3.fromHSV(hue, sat, val))
				})
			end
		end,
		Darker = true,
		Visible = false
	})
	ParticleSize = Killaura:CreateSlider({
		Name = 'Size',
		Min = 0,
		Max = 1,
		Default = 0.2,
		Decimal = 100,
		Function = function(val)
			for _, v in Particles do
				v.ParticleEmitter.Size = NumberSequence.new(val)
			end
		end,
		Darker = true,
		Visible = false
	})
	Face = Killaura:CreateToggle({Name = 'Face target'})
	Animation = Killaura:CreateToggle({
		Name = 'Custom Animation',
		Function = function(callback)
			AnimationMode.Object.Visible = callback
			AnimationTween.Object.Visible = callback
			AnimationSpeed.Object.Visible = callback
			if Killaura.Enabled then
				Killaura:Toggle()
				Killaura:Toggle()
			end
		end
	})
	local animnames = {}
	for i in anims do
		table.insert(animnames, i)
	end
	AnimationMode = Killaura:CreateDropdown({
		Name = 'Animation Mode',
		List = animnames,
		Darker = true,
		Visible = false
	})
	AnimationSpeed = Killaura:CreateSlider({
		Name = 'Animation Speed',
		Min = 0,
		Max = 2,
		Default = 1,
		Decimal = 10,
		Darker = true,
		Visible = false
	})
	AnimationTween = Killaura:CreateToggle({
		Name = 'No Tween',
		Darker = true,
		Visible = false
	})
	Limit = Killaura:CreateToggle({
		Name = 'Limit to items',
		Function = function(callback)
			if inputService.TouchEnabled and Killaura.Enabled then
				pcall(function()
					lplr.PlayerGui.MobileUI['2'].Visible = callback
				end)
			end
		end,
		Tooltip = 'Only attacks when the sword is held'
	})

end)


run(function()
	local Disabler
	
	local function characterAdded(char)
		for _, v in getconnections(char.RootPart:GetPropertyChangedSignal('CFrame')) do
			hookfunction(v.Function, function() end)
		end
		for _, v in getconnections(char.RootPart:GetPropertyChangedSignal('Velocity')) do
			hookfunction(v.Function, function() end)
		end
	end
	
	Disabler = vape.Categories.Exploits:CreateModule({
		Name = 'Disabler',
		Function = function(callback)
			if callback then
				Disabler:Clean(entitylib.Events.LocalAdded:Connect(characterAdded))
				if entitylib.isAlive then
					characterAdded(entitylib.character)
				end
			end
		end,
		Tooltip = 'Disables GetPropertyChangedSignal detections for movement'
	})
end)

run(function()
	local function test()
		local root = entitylib.character.RootPart
		local basePos = root.Position

		local item, amount = getWool()
		if not item then
			vape:CreateNotification("Funny", "No wool found in inventory!", 5, "warning")
			return
		end
		local wool = bedwars.ItemMeta[dblock.Name].block.breakType
				local tool = store.tools[breaktype]
				local wool = store.inventory.inventory.items
		switchItem(item)
		bedwars.placeBlock(basePos, item)
	end
	

	local function penis()
		local root = entitylib.character.RootPart
		local basePos = root.Position

		local item, amount = getWool()
		if not item then
			vape:CreateNotification("Funny", "No wool found in inventory!", 5, "warning")
			return
		end

			local forward = root.CFrame.LookVector * 3
		local origin = (basePos + forward) - Vector3.new(0, 3, 0)

		local pattern = {
			Vector3.new(0, 0, 0),  
			Vector3.new(-1, 0, 0),
			Vector3.new(1, 0, 0),  
			Vector3.new(0, 1, 0), 
			Vector3.new(0, 2, 0),  
		}
		for _, offset in ipairs(pattern) do
			local pos = basePos + offset * 3

			bedwars.placeBlock(pos, item)
			task.wait(1 / 1000)
		end
	end
local Funny
local Options
	Funny = vape.Categories.Troll:CreateModule({
		Name = "Funny",
		Function = function(callback)
			if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium" and role ~= "user" then
																																			vape:CreateNotification("Onyx", "You do not have permission to use this", 10, "alert")
				return
			end

			if callback then
				if Options.Value == "penis" then
					penis()
				elseif Options.Value == "smile" then
					vape:CreateNotification("Funny", "Coming soon :D", 5)
				elseif Options.Value == "nazi" then
					vape:CreateNotification("Funny", "Coming soon :D", 5)
				elseif Options.Value == "test" then
					test()
				end
			end
		end,
		Tooltip = ":troll: rewrite some day when i feel like it"
	})

	Options = Funny:CreateDropdown({
		Name = "Options",
		List = {"penis", "nazi", "smile",'test'}
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
	local LP 
	 LP = vape.Categories.Exploits:CreateModule({
		Name = "LeaveParty",
		Function = function(callback)
   			if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium"and role ~= "user"then
				vape:CreateNotification("Onyx", "You do not have permission to use this", 10, "alert")
				return
			end   																															
			if callback then
				LP:Toggle(false)
				bedwars.PartyController:leaveParty()
			end
		end,
		Tooltip = "Makes u leave ur current party",
	})
end)


run(function()
	local Desync
	local Type
	local AutoSend
	local AutoSendLength
	local oldphys, oldsend
	local enabled
	Desync = vape.Categories.Exploits:CreateModule({
		Name = 'Desync',
		Function = function(callback)
						if not enabled.Enabled then vape:CreateNotification('Onyx', "Ignored, You do not have the setting on to use this module",5,"warning") return end
			if callback then
				local teleported
				Desync:Clean(lplr.OnTeleport:Connect(function()
					setfflag('PhysicsSenderMaxBandwidthBps', '38760')
					setfflag('DataSenderRate', '60')
					teleported = true
				end))
	
				repeat
					local physicsrate, senderrate = '0', Type.Value == 'All' and '-1' or '60'
					if AutoSend.Enabled and tick() % (AutoSendLength.Value + 0.1) > AutoSendLength.Value then
						physicsrate, senderrate = '38760', '60'
					end
	
					if physicsrate ~= oldphys or senderrate ~= oldsend then
						setfflag('PhysicsSenderMaxBandwidthBps', physicsrate)
						setfflag('DataSenderRate', senderrate)
						oldphys, oldsend = physicsrate, senderrate
					end
	
					task.wait(0.03)
				until (not Desync.Enabled and not teleported)
			else
				if setfflag then
					setfflag('PhysicsSenderMaxBandwidthBps', '38760')
					setfflag('DataSenderRate', '60')
				end
				oldphys, oldsend = nil, nil
			end
		end,
		Tooltip = 'Note this will ban you for client modifications.'
	})
	Type = Desync:CreateDropdown({
		Name = 'Type',
		List = {'Movement Only', 'All'},
		Tooltip = 'Movement Only - Only chokes movement packets\nAll - Chokes remotes & movement'
	})
	AutoSend = Desync:CreateToggle({
		Name = 'Auto send',
		Function = function(callback)
			AutoSendLength.Object.Visible = callback
		end,
		Tooltip = 'Automatically send packets in intervals'
	})
	AutoSendLength = Desync:CreateSlider({
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

	enabled = Desync:CreateToggle({
        Name = 'Enabled',
        Default = false,
        Tooltip = 'Enables so you can use desync fflag method'
	})
end)


run(function()
	local Clutch
	local runService = game:GetService("RunService")
	local workspace = game:GetService("Workspace")
	local HoldBase = 0.15
	local FallVelocity = -6
	local lastPlace = 0
    local UseBlacklisted_Blocks
    local blacklisted
	local function callPlace(blockpos, wool, rotate)
		local placeFn
		if type(vape) == "table" and type(vape.clean) == "function" then
			vape:clean(blockpos, wool, rotate)
			return
		end
		if type(vape) == "table" and type(vape.place) == "function" then
			placeFn = vape.place
		elseif type(place) == "function" then
			placeFn = place
		else
			placeFn = bedwars.placeBlock
		end
		task.spawn(placeFn, blockpos, wool, rotate)
	end

	local function nearCorner(poscheck, pos)
		local startpos = poscheck - Vector3.new(3, 3, 3)
		local endpos = poscheck + Vector3.new(3, 3, 3)
		local check = poscheck + (pos - poscheck).Unit * 100
		return Vector3.new(math.clamp(check.X, startpos.X, endpos.X), math.clamp(check.Y, startpos.Y, endpos.Y), math.clamp(check.Z, startpos.Z, endpos.Z))
	end

	local function blockProximity(pos)
		local mag, returned = 60
		local tab = getBlocksInPoints(bedwars.BlockController:getBlockPosition(pos - Vector3.new(21, 21, 21)), bedwars.BlockController:getBlockPosition(pos + Vector3.new(21, 21, 21)))
		for _, v in tab do
			local blockpos = nearCorner(v, pos)
			local newmag = (pos - blockpos).Magnitude
			if newmag < mag then
				mag, returned = newmag, blockpos
			end
		end
		table.clear(tab)
		return returned
	end

	local function getClutchBlock()
		if store.hand.toolType == 'block' then
			return store.hand.tool.Name, store.hand.amount
		end
		return nil, 0
	end

	Clutch = vape.Categories.Exploits:CreateModule({
		Name = 'Clutch',
		Function = function(call)
			if call then
			if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium" then
				vape:CreateNotification("Onyx", "You do not have permission to use this", 10, "alert")
				return
			end      
				Clutch:Clean(runService.Heartbeat:Connect(function()
					if not Clutch.Enabled then
						return
					end
					if not entitylib.isAlive then
						return
					end
					local root = entitylib.character.RootPart
					if not root or inputService:GetFocusedTextBox() then
						return
					end

					if Clutch.LimitToItems and Clutch.LimitToItems.Enabled then
						if getClutchBlock then
							if store.hand.toolType ~= "block" then
								return
							end
						end
					end
					local wool = select(1, getClutchBlock())
					if not wool then
						return
					end
					if wool and not UseBlacklisted_Blocks.Enabled then
						for i,v in blacklisted.ListEnabled do
							if wool == v then
								return																																																																																																																																																																									
							end																																																																																																																																																																												
						end
					end
					if Clutch.RequireMouse and Clutch.RequireMouse.Enabled and not inputService:IsMouseButtonPressed(0) then
						return
					end
					local vy = root.Velocity.Y
					local now = os.clock()
					local speedVal = (Clutch.Speed and Clutch.Speed.Value) or 0
					local cooldown = math.clamp(HoldBase - (speedVal * 0.015), 0.01, HoldBase)
					if vy < FallVelocity and (now - lastPlace) > cooldown then
						local target = roundPos(root.Position - Vector3.new(0, entitylib.character.HipHeight + 4.5, 0))
						local exists, blockpos = getPlacedBlock(target)
						if not exists then
							local prox = blockProximity(target)
							local placePos = prox or (target * 3)
							callPlace(placePos, wool, false)
							lastPlace = now
							if Clutch.SilentAim and Clutch.SilentAim.Enabled then
								local camera = workspace.CurrentCamera
								local camCFrame = camera and camera.CFrame
								local camType = camera and camera.CameraType
								local camSubject = camera and camera.CameraSubject
								local lv = root.CFrame.LookVector
								local newLook = -Vector3.new(lv.X, 0, lv.Z).Unit
								local rootPos = root.Position
								root.CFrame = CFrame.new(rootPos, rootPos + newLook)
								if camera and camCFrame then
									camera.CameraType = camType
									camera.CameraSubject = camSubject
									camera.CFrame = camCFrame
								end
							end
						end
					end
				end))
			end
		end,
		Tooltip = 'Automatically places a block when falling to clutch'
	})

	UseBlacklisted_Blocks = Clutch:CreateToggle({
		Name = "Use Blacklisted Blocks",
		Default = false
	})

	blacklisted = Clutch:CreateTextList({
		Name = "Blacklisted Blocks",
		Placeholder = "tnt"
	})
	
	Clutch.LimitToItems = Clutch:CreateToggle({
		Name = 'Limit to items',
		Default = false,
	})

	Clutch.RequireMouse = Clutch:CreateToggle({
		Name = 'Require mouse down',
		Default = false,
	})

	Clutch.SilentAim = Clutch:CreateToggle({
		Name = 'Silent Aim',
		Default = false,
	})

	Clutch.Speed = Clutch:CreateSlider({
		Name = 'Speed',
		Min = 0,
		Max = 9,
		Default = 6
	})
end)

run(function()
    local Antihit = {Enabled = false}
    local Range, TimeUp, Down = 16, 0.5, 0.14

    Antihit = vape.Categories.Blatant:CreateModule({
        Name = "AntiHit",
        Function = function(call)
			if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium" and role ~= "user"then
				vape:CreateNotification("Onyx", "You do not have permission to use this", 10, "alert")
				return
			end  
            if call then
                task.spawn(function()
                    while Antihit.Enabled do
                        local root = lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart")
                        if root then
                            local orgPos = root.Position
                            local foundEnemy = false

                            for _, v in next, playersService:GetPlayers() do
                                if v ~= lplr and v.Team ~= lplr.Team then
                                    local enemyChar = v.Character
                                    local enemyRoot = enemyChar and enemyChar:FindFirstChild("HumanoidRootPart")
                                    local enemyHum = enemyChar and enemyChar:FindFirstChild("Humanoid")
                                    if enemyRoot and enemyHum and enemyHum.Health > 0 then
                                        local dist = (root.Position - enemyRoot.Position).Magnitude
                                        if dist <= Range.Value then
                                            foundEnemy = true
                                            break
                                        end
                                    end
                                end
                            end

                            if foundEnemy then
                                root.CFrame = CFrame.new(orgPos + Vector3.new(0, -230, 0))
                                task.wait(TimeUp.Value)
                                if Antihit.Enabled and lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart") then
                                    lplr.Character.HumanoidRootPart.CFrame = CFrame.new(orgPos)
                                end
                            end
                        end
                        task.wait(Down.Value)
                    end
                end)
            end
        end,
        Tooltip = "Prevents you from dying"
    })

    Range = Antihit:CreateSlider({
        Name = "Range",
        Min = 0,
        Max = 50,
        Default = 15,
        Function = function(val) Range.Value = val end
    })

    TimeUp = Antihit:CreateSlider({
        Name = "Time Up",
        Min = 0,
        Max = 1,
        Default = 0.4,
        Function = function(val) TimeUp.Value = val end
    })

    Down = Antihit:CreateSlider({
        Name = "Time Down",
        Min = 0,
        Max = 1,
        Default = 0.1,
        Function = function(val) Down.Value = val end
    })
end)


run(function()
    local BlockIn
    local PD
    local UseBlacklisted_Blocks
    local blacklisted
	local SlientAim
	local LimitedToItem
    local function getBedNear()
        local localPosition = entitylib.isAlive and entitylib.character.RootPart.Position or Vector3.zero
        for _, v in collectionService:GetTagged("bed") do
            if (localPosition - v.Position).Magnitude < 20 
                and v:GetAttribute("Team" .. (lplr:GetAttribute("Team") or -1) .. "NoBreak")
            then
                return v
            end
        end
    end

    local function getBlocks()
        local blocks = {}

        for _, item in store.inventory.inventory.items do
            local block = bedwars.ItemMeta[item.itemType].block
			print(block)
            if block then
                table.insert(blocks, { item.itemType, block.health })
            end
        end

        table.sort(blocks, function(a, b)
            return a[2] < b[2]
        end)

        return blocks
    end

    local function getPyramid(size, grid)
        return {
            Vector3.new(3, 0, 0),
            Vector3.new(0, 0, 3),
            Vector3.new(-3, 0, 0),
            Vector3.new(0, 0, -3),
            Vector3.new(3, 3, 0),
            Vector3.new(0, 3, 3),
            Vector3.new(-3, 3, 0),
            Vector3.new(0, 3, -3),
            Vector3.new(0, 6, 0),
            Vector3.new(0, -2.8, 0),
        }
    end

    BlockIn = vape.Categories.Blatant:CreateModule({
        Name = "BlockIn",
        Tooltip = "Automatically places strong blocks around the me.",
        Function = function(callback)
			if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium" and role ~= "user"then
				vape:CreateNotification("Onyx", "You do not have permission to use this", 10, "alert")
				return
			end  
			local number = 0
            if not callback then 
                return 
            end

            local me = entitylib.isAlive and entitylib.character.RootPart.Position or nil
            if not me then
                notif("BlockIn", "Unable to locate me", 5, "warning")
                BlockIn:Toggle(false)
                return
            end

            local item = getBlocks()
            if not item or #item == 0 then
                notif("BlockIn", "No blocks found in inventory!", 5, "warning")
                BlockIn:Toggle(false)
                return
            end
			for i, block in ipairs(item) do
			    for _, pos in ipairs(getPyramid(i, 3)) do
			        if not BlockIn.Enabled then 
			            break 
			        end
			
			        local targetPos = me + pos
			        if getPlacedBlock(targetPos) then 
			            continue 
			        end
					task.spawn(function()
						for i=0,8 do
					    	number = i
							task.wait(PD.Value / 100)																													
						end
					end)
					local woolitem,amount = getWool()
					switchItem(woolitem)
					repeat
    					task.spawn(bedwars.placeBlock, targetPos, block[1])
   						task.wait(PD.Value / 100)
    				until number == 8
			    end
			end
			
			if BlockIn.Enabled then
			    BlockIn:Toggle(false)
			end
        end
    })

	LimitedToItem = BlockIn:CreateToggle({
		Name = "Limited To Item",
		Default = false
	})

	SlientAim = BlockIn:CreateToggle({
		Name = "SlientAim",
		Default = false
	})

    PD = BlockIn:CreateSlider({
        Name = "Place Delay",
        Min = 0,
        Max = 5,
        Default = 3,
        Suffix = "ms"
    })

	UseBlacklisted_Blocks = BlockIn:CreateToggle({
		Name = "Use Blacklisted Blocks",
		Default = false
	})

	blacklisted = BlockIn:CreateTextList({
		Name = "Blacklisted Blocks",
		Placeholder = "tnt"
	})
end)


run(function()
    local DamageAffect = {Enabled = false}
    local connection
	local Fonts
	local DamageMessages = {
		'Pow!',
		'Pop!',
		'Hit!',
		'Smack!',
		'Bang!',
		'Boom!',
		'Whoop!',
		'Damage!',
		'-9e9!',
		'Whack!',
		'Crash!',
		'Slam!',
		'Zap!',
		'Snap!',
		'Thump!',
		'Ouch!',
		'Crack!',
		'Bam!',
		'Clap!',
		'Blitz!',
		'Crunch!',
		'Shatter!',
		'Blast!',
		'Womp!',
		'Thunk!',
		'Zing!',
		'Rip!',
		'Rattle!',
		'Kaboom!',
		'Wack!',
		'Boomer!',
		'Slammer!',
		'Powee!',
		'Zappp!',
		'Thunker!',
		'Rippler!',
		'Bap!',
		'Bomp!',
		'Sock!',
		'Chop!',
		'Sting!',
		'Slice!',
		'Swipe!',
		'Punch!',
		'Tonk!',
		'Bonk!',
		'Jolt!',
		'Spike!',
		'Pierce!',
		'Crush!',
		'Bruise!',
		'Ding!',
	    'Clang!',
		'Crashhh!',
		'Kablam!',
		'Zapshot!',
		'Oynx On top!'
	}
	
	local RGBColors = {
		Color3.fromRGB(255, 0, 0),
		Color3.fromRGB(255, 127, 0),
		Color3.fromRGB(255, 255, 0),
		Color3.fromRGB(0, 255, 0),
		Color3.fromRGB(0, 0, 255),
		Color3.fromRGB(75, 0, 130),
		Color3.fromRGB(148, 0, 211)
	}
	
	local function randomizer(tbl)
	    if not typeof(tbl) == "table" then return end
	    local index = math.random(1,#tbl)
	    local value = tbl[index]
	    return value,index
	end
	local font  = 'Arial'
    DamageAffect = vape.Categories.Render:CreateModule({
        Name = "DamageAffect",
        Function = function(call)
			if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium" and role ~= "user"then
				vape:CreateNotification("Onyx", "You do not have permission to use this", 10, "alert")
				return
			end  
			if call then
				connection = DamageAffect:Clean(workspace.DescendantAdded:Connect(function(part)
				    if part.Name == "DamageIndicatorPart" and part:IsA("BasePart") then
				        for i, v in part:GetDescendants() do
				            if v:IsA("TextLabel") then
				                local txt = randomizer(DamageMessages)
				                local clr = randomizer(RGBColors)
				
				                v.Text = txt
				                v.TextColor3 = clr
								v.FontFace = font
				            end
				        end
				    end
				end))
			else
				connection:Disconnect()
				connection = nil
			end
        end,
        Tooltip = "Customizes Damage Affects"
    })

	Fonts = DamageAffect:CreateFont({
		Name = 'Font',
		Function = function(val)
			font = val
		end
	})
end)

run(function()
	local PlayerGui = lplr:WaitForChild("PlayerGui")
	local MutipleKits 
	MutipleKits = vape.Categories.Exploits:CreateModule({
		Name = "MutipleKits",
		Function = function(callback)
			if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium" and role ~= "user"then
				vape:CreateNotification("Onyx", "You do not have permission to use this", 10, "alert")
				return
			end  
			if callback then
				local draft = PlayerGui:FindFirstChild("MatchDraftApp")
				local header = draft:FindFirstChild('DraftAppBackground'):FindFirstChild('HeaderContainer'):FindFirstChild('1'):FindFirstChild('PhaseTitleContainer'):FindFirstChild('1')
				local kitSelection = draft:FindFirstChild('DraftAppBackground'):FindFirstChild('BodyContainer'):FindFirstChild('KitSelection')																																												
				if not bedwars.AppController:isAppOpen('MatchDraftApp') then
					getgenv().BEN("Couldn't find MatchDraftApp")
					return																																												
				end
				if not kitSelection or not header.Text == "SELECT YOUR KIT" then
					getgenv().BEN("Couldn't find Kit Selection, you must be in Kit Selection mode")
					return																																												
				end
				getgenv().BIN("Please select your kit")
				task.wait(2)
				getgenv().BIN("SPAM CLICK THE RANDOM KIT")

			end
		end,
		Tooltip = "5v5, ranked only allow's u to have mutiple kit's in a game -- NOTE THIS WILL NOT WORK EVERYTIME",
	})
end)
run(function()
local ennabled = false
    local ZephyrExploit = {Enabled = false}
    ZephyrExploit = vape.Categories.Exploits:CreateModule({
        Name = "ZephyrExploit",
        Function = function(callback)
						if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium" and role ~= "user"then
				vape:CreateNotification("Onyx", "You do not have permission to use this", 10, "alert")
				return
			end  
			if not store.equippedKit == "wind_walker" then
				notif("ZephyrExploit", "You are not 'ZEPHYR' kit, you are not allowed to use this module", 5, "warning") 
				return
			end	
			
            local zephyreffect = lplr.PlayerGui:FindFirstChild("WindWalkerEffect", true)
            local StackTxt = zephyreffect and zephyreffect:FindFirstChild("EffectStack", true)
		if not zephyreffect then
				notif("ZephyrExploit", "You are not 'ZEPHYR' kit, you are not allowed to use this module", 5, "warning")
return			
			end
            if not callback then
                notif("ZephyrExploit", "Disabled next game", 5, "warning")
                return
            end
			pcall(function()
				debug.setconstant(bedwars.WindWalkerController.updateSpeed, 7, callback and 'constantSpeedMultiplier' or 'moveSpeedMultiplier')
			end)
task.spawn(function()
while task.wait(1) do
if  StackTxt.Text == "0" then
ennabled = false
		    	bedwars.JumpHeightController:getJumpModifier():addModifier({
                        airJumps = 0
                    })
		Speed:Toggle(false)
end
end
end)
			if ennabled then return end

            bedwars.WindWalkerController.updateJump = function(StackCount, Listed)
                if StackTxt then
                    StackTxt.Text = "5"
					ennabled = true
                end

                if Speed then
                    pcall(function()
                        Speed:Toggle(true)
                    end)
                end

                vape:CreateNotification(
                    "Onyx",
                    "Anti-Cheat bypasser enabled! keep speed on for this, and can u also use fly!",
                    10,
                    "success"
                )

                StackCount = 5
                Listed = Listed or {doubleJumpActive = false}

                if StackCount >= 5 and not Listed.doubleJumpActive then
                    Listed.doubleJumpActive = true
                    bedwars.JumpHeightController:getJumpModifier():addModifier({
                        airJumps = 2
                    })
                elseif StackCount < 5 and Listed.doubleJumpActive then
                    Listed.doubleJumpActive = false
                end
            end
        end,
        Tooltip = "Zephyr AntiCheat bypasser",
    })
end)		

run(function()
    local HackerDetector

    local exploitersPath = "ReVape/profiles/exploiters.txt"

    if not isfile(exploitersPath) then 
        writefile(exploitersPath, "")
    end

	

    local reportschecks = {
        Cache = true,
        InfFly = true,
        Fly = true,
        Teleport = true,
        Speed = true,
        Nuker = false,
        Invisible = false,
        AntiHit = false,
        NameDetects = true,
    }
	
    local cachedExploiters = {}
	task.spawn(function()
	    do
	        local content = readfile(exploitersPath)
	        for name in string.gmatch(content, "([^\n]+)") do
	            cachedExploiters[name] = true
	        end
	    end
	end)

    local badNames = {
        "vape","voidware","catvape","catvxpe","vxpe",
        "void","her","him","vxidwxre",'Subbico'
    }
	local currentplayers = {}
	local maxreports = 6
	
	local function createmsg(msg, time, player, reason)
	    time = time or 8
	
	    if not currentplayers[player] then
	        currentplayers[player] = { reports = 0, ignore = false, reasons = {} }
	    end
	
	    local pdata = currentplayers[player]
	
	    if pdata.ignore then return end
	
	    if not pdata.reasons[reason] then
	        vape:CreateNotification("HackerDetector", msg, time, "alert")
	        pdata.reports = pdata.reports + 1
	        pdata.reasons[reason] = true
	    end
	
	    if pdata.reports >= maxreports then
	        pdata.ignore = true
	    end
	end

    local function addToCache(name)
        if cachedExploiters[name] then end
        cachedExploiters[name] = true
        appendfile(exploitersPath, name.."\n")
			return
    end

    local function nameDetectCheck(player)
		local str = ""
		if player.DisplayName == "" or player.DisplayName == nil or player.DisplayName == player.Name then str = player.Name else str = player.DisplayName end
        local lower = string.lower(str)
        for _, bad in ipairs(badNames) do
            if string.find(lower, bad, 1, true) then
                addToCache(player.Name)
				createmsg(player.Name.." flagged for suspicious name", 8,player,'name')
            end
        end
    end


	local lastJumpTime = {}
	
	local function detectInfFly(player)
	    local char = player.Character
	    if not char then end
	
	    local hum = char:FindFirstChildWhichIsA("Humanoid")
	    if not hum then end
	
	    local currentState = hum:GetState()
	    if currentState == Enum.HumanoidStateType.Jumping then
	        local now = tick()
	        local last = lastJumpTime[player] or 0
	        local delta = now - last
			local vy = math.abs(root.AssemblyLinearVelocity.Y)
	        if delta < 0.15 or vy > 35 then
				createmsg(player.Name.." flagged for infinite fly", 8,player,'inffly')
	            addToCache(player.Name)
	        end
	
	        lastJumpTime[player] = now
	    end
	end

    local posStore = {}

    local function detectFly(player)
        local char = player.Character
        if not char then end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then end

        local p = root.Position
        local old = posStore[player]

        if old then
            local dy = math.abs(p.Y - old.Y)
            local vy = math.abs(root.AssemblyLinearVelocity.Y)

            if dy > 1.5 and vy > 35 and hum.FloorMaterial == Enum.Material.Air then
				createmsg(player.Name.." flagged for flying", 8,player,'fly')

                addToCache(player.Name)
            end
        end

        posStore[player] = p
    end

    local lastPos = {}

    local function detectTeleport(player)
        local char = player.Character
        if not char then end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then end

        local p = root.Position
        local old = lastPos[player]

        if old then
            local dist = (p - old).Magnitude

            if dist > 40 then
                if dist < 180 then
				createmsg(player.Name.." flagged for teleporting ("..math.floor(dist)..")", 8,player,'tp')

                    addToCache(player.Name)
                end
            end
        end

        lastPos[player] = p
    end

    local function detectSpeed(player)
        local char = player.Character
        if not char then end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then end

        local velo = math.floor(root.AssemblyLinearVelocity.Magnitude)
        if hum:GetState() == Enum.HumanoidStateType.FallingDown
        or hum:GetState() == Enum.HumanoidStateType.Freefall then return end

        if velo >= 48 then
			createmsg(player.Name.." flagged for speed ("..math.floor(horizontal)..")", 8,player,'speed')
            addToCache(player.Name)
        end
    end
local c 
    HackerDetector = vape.Categories.Utility:CreateModule({
        Name = "HackerDetector",
        Function = function(callback)
	   			if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium"and role ~= "user"then
					vape:CreateNotification("Onyx", "You do not have permission to use this", 10, "alert")
					return
				end																																																																								
           		 if callback then
																																																																																
               c = runService.Heartbeat:Connect(function()
                    for _, plr in playersService:GetPlayers() do
                        local char = plr.Character
                        if not char then end

                        if reportschecks.Cache and cachedExploiters[plr.Name] then
							createmsg(plr.Name.." was previously flagged", 8,plr,'cache')
                        end

                        if reportschecks.NameDetects then
                            task.spawn(nameDetectCheck,plr)
                        end

                        if reportschecks.InfFly then task.spawn(detectInfFly,plr) end
                        if reportschecks.Fly then task.spawn(detectFly,plr) end
                        if reportschecks.Teleport then  task.spawn(detectTeleport,plr)end
                        if reportschecks.Speed then task.spawn(detectSpeed,plr) end
                    end
                end)
	else
		c:Disconnect()
		c = nil
            end
        end,
        Tooltip = "Detects when a blatant cheater is in the game with you",
    })
end)

run(function()
    local AutoChargeBow = {Enabled = false}
    local old
    
    AutoChargeBow = vape.Categories.Blatant:CreateModule({
        Name = 'AutoChargeBow',
        Function = function(callback)
			if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium" and role ~= "user"then
				vape:CreateNotification("Onyx", "You do not have permission to use this", 10, "alert")
				return
			end  
            if callback then
                old = bedwars.ProjectileController.calculateImportantLaunchValues
                bedwars.ProjectileController.calculateImportantLaunchValues = function(...)
                    local self, projmeta, worldmeta, origin, shootpos = ...
                    
                    if projmeta.projectile:find('arrow') then
                        local pos = shootpos or self:getLaunchPosition(origin)
                        if not pos then
                            return old(...)
                        end
                        
                        local meta = projmeta:getProjectileMeta()
                        local lifetime = (worldmeta and meta.predictionLifetimeSec or meta.lifetimeSec or 3)
                        local gravity = (meta.gravitationalAcceleration or 196.2) * projmeta.gravityMultiplier
                        local projSpeed = (meta.launchVelocity or 100)
                        local offsetpos = pos + (projmeta.projectile == 'owl_projectile' and Vector3.zero or projmeta.fromPositionOffset)
                        
                        local camera = workspace.CurrentCamera
                        local mouse = lplr:GetMouse()
                        local unitRay = camera:ScreenPointToRay(mouse.X, mouse.Y)
                        
                        local targetPoint = unitRay.Origin + (unitRay.Direction * 1000)
                        local aimDirection = (targetPoint - offsetpos).Unit
                        
                        local newlook = CFrame.new(offsetpos, targetPoint) * CFrame.new(projmeta.projectile == 'owl_projectile' and Vector3.zero or Vector3.new(bedwars.BowConstantsTable.RelX, bedwars.BowConstantsTable.RelY, bedwars.BowConstantsTable.RelZ))
                        local finalDirection = (targetPoint - newlook.Position).Unit
                        
                        return {
                            initialVelocity = finalDirection * projSpeed,
                            positionFrom = offsetpos,
                            deltaT = lifetime,
                            gravitationalAcceleration = gravity,
                            drawDurationSeconds = 5
                        }
                    end
                    
                    return old(...)
                end
            else
                bedwars.ProjectileController.calculateImportantLaunchValues = old
				old = nil
            end
        end,
        Tooltip = 'Automatically charges your bow to full power with trajectory line preview'
    })
end)
	

run(function()
	local AutoKit
	local Legit
	local Toggles = {}
	
	local function kitCollection(id, func, range, specific)
		local objs = type(id) == 'table' and id or collection(id, AutoKit)
		repeat
			if entitylib.isAlive then
				local localPosition = entitylib.character.RootPart.Position
				for _, v in objs do
					if InfiniteFly.Enabled or not AutoKit.Enabled then break end
					local part = not v:IsA('Model') and v or v.PrimaryPart
					if part and (part.Position - localPosition).Magnitude <= (not Legit.Enabled and specific and math.huge or range) then
						func(v)
					end
				end
			end
			task.wait(0.1)
		until not AutoKit.Enabled
	end
	
	local AutoKitFunctions = {
		battery = function()
			repeat
				if entitylib.isAlive then
					local localPosition = entitylib.character.RootPart.Position
					for i, v in bedwars.BatteryEffectsController.liveBatteries do
						if (v.position - localPosition).Magnitude <= 10 then
							local BatteryInfo = bedwars.BatteryEffectsController:getBatteryInfo(i)
							if not BatteryInfo or BatteryInfo.activateTime >= workspace:GetServerTimeNow() or BatteryInfo.consumeTime + 0.1 >= workspace:GetServerTimeNow() then continue end
							BatteryInfo.consumeTime = workspace:GetServerTimeNow()
							bedwars.Client:Get(remotes.ConsumeBattery):SendToServer({batteryId = i})
						end
					end
				end
				task.wait(0.1)
			until not AutoKit.Enabled
		end,
		beekeeper = function()
			kitCollection('bee', function(v)
				bedwars.Client:Get(remotes.BeePickup):SendToServer({beeId = v:GetAttribute('BeeId')})
			end, 18, false)
		end,
		bigman = function()
			kitCollection('treeOrb', function(v)
				if bedwars.Client:Get(remotes.ConsumeTreeOrb):CallServer({treeOrbSecret = v:GetAttribute('TreeOrbSecret')}) then
					v:Destroy()
				end
			end, 12, false)
		end,
		block_kicker = function()
			local old = bedwars.BlockKickerKitController.getKickBlockProjectileOriginPosition
			bedwars.BlockKickerKitController.getKickBlockProjectileOriginPosition = function(...)
				local origin, dir = select(2, ...)
				local plr = entitylib.EntityMouse({
					Part = 'RootPart',
					Range = 1000,
					Origin = origin,
					Players = true,
					Wallcheck = true
				})
	
				if plr then
					local calc = prediction.SolveTrajectory(origin, 100, 20, plr.RootPart.Position, plr.RootPart.Velocity, workspace.Gravity, plr.HipHeight, plr.Jumping and 42.6 or nil)
	
					if calc then
						for i, v in debug.getstack(2) do
							if v == dir then
								debug.setstack(2, i, CFrame.lookAt(origin, calc).LookVector)
							end
						end
					end
				end
	
				return old(...)
			end
	
			AutoKit:Clean(function()
				bedwars.BlockKickerKitController.getKickBlockProjectileOriginPosition = old
			end)
		end,
		cat = function()
			local old = bedwars.CatController.leap
			bedwars.CatController.leap = function(...)
				vapeEvents.CatPounce:Fire()
				return old(...)
			end
	
			AutoKit:Clean(function()
				bedwars.CatController.leap = old
			end)
		end,
		davey = function()
			local old = bedwars.CannonHandController.launchSelf
			bedwars.CannonHandController.launchSelf = function(...)
				local res = {old(...)}
				local self, block = ...
	
				if block:GetAttribute('PlacedByUserId') == lplr.UserId and (block.Position - entitylib.character.RootPart.Position).Magnitude < 30 then
					task.spawn(bedwars.breakBlock, block, false, nil, true)
				end
	
				return unpack(res)
			end
	
			AutoKit:Clean(function()
				bedwars.CannonHandController.launchSelf = old
			end)
		end,
		dragon_slayer = function()
			kitCollection('KaliyahPunchInteraction', function(v)
				bedwars.DragonSlayerController:deleteEmblem(v)
				bedwars.DragonSlayerController:playPunchAnimation(Vector3.zero)
				bedwars.Client:Get(remotes.KaliyahPunch):SendToServer({
					target = v
				})
			end, 18, true)
		end,
		farmer_cletus = function()
			kitCollection('HarvestableCrop', function(v)
				if bedwars.Client:Get(remotes.HarvestCrop):CallServer({position = bedwars.BlockController:getBlockPosition(v.Position)}) then
					bedwars.GameAnimationUtil:playAnimation(lplr.Character, bedwars.AnimationType.PUNCH)
					bedwars.SoundManager:playSound(bedwars.SoundList.CROP_HARVEST)
				end
			end, 10, false)
		end,
		fisherman = function()
			local old = bedwars.FishingMinigameController.startMinigame
			bedwars.FishingMinigameController.startMinigame = function(_, _, result)
				result({win = true})
			end
	
			AutoKit:Clean(function()
				bedwars.FishingMinigameController.startMinigame = old
			end)
		end,
		gingerbread_man = function()
			local old = bedwars.LaunchPadController.attemptLaunch
			bedwars.LaunchPadController.attemptLaunch = function(...)
				local res = {old(...)}
				local self, block = ...
	
				if (workspace:GetServerTimeNow() - self.lastLaunch) < 0.4 then
					if block:GetAttribute('PlacedByUserId') == lplr.UserId and (block.Position - entitylib.character.RootPart.Position).Magnitude < 30 then
						task.spawn(bedwars.breakBlock, block, false, nil, true)
					end
				end
	
				return unpack(res)
			end
	
			AutoKit:Clean(function()
				bedwars.LaunchPadController.attemptLaunch = old
			end)
		end,
		hannah = function()
			kitCollection('HannahExecuteInteraction', function(v)
				local billboard = bedwars.Client:Get(remotes.HannahKill):CallServer({
					user = lplr,
					victimEntity = v
				}) and v:FindFirstChild('Hannah Execution Icon')
	
				if billboard then
					billboard:Destroy()
				end
			end, 30, true)
		end,
		jailor = function()
			kitCollection('jailor_soul', function(v)
				bedwars.JailorController:collectEntity(lplr, v, 'JailorSoul')
			end, 20, false)
		end,
		grim_reaper = function()
			kitCollection(bedwars.GrimReaperController.soulsByPosition, function(v)
				if entitylib.isAlive and lplr.Character:GetAttribute('Health') <= (lplr.Character:GetAttribute('MaxHealth') / 4) and (not lplr.Character:GetAttribute('GrimReaperChannel')) then
					bedwars.Client:Get(remotes.ConsumeSoul):CallServer({
						secret = v:GetAttribute('GrimReaperSoulSecret')
					})
				end
			end, 120, false)
		end,
		melody = function()
			repeat
				local mag, hp, ent = 30, math.huge
				if entitylib.isAlive then
					local localPosition = entitylib.character.RootPart.Position
					for _, v in entitylib.List do
						if v.Player and v.Player:GetAttribute('Team') == lplr:GetAttribute('Team') then
							local newmag = (localPosition - v.RootPart.Position).Magnitude
							if newmag <= mag and v.Health < hp and v.Health < v.MaxHealth then
								mag, hp, ent = newmag, v.Health, v
							end
						end
					end
				end
	
				if ent and getItem('guitar') then
					bedwars.Client:Get(remotes.GuitarHeal):SendToServer({
						healTarget = ent.Character
					})
				end
	
				task.wait(0.1)
			until not AutoKit.Enabled
		end,
		metal_detector = function()
			kitCollection('hidden-metal', function(v)
				bedwars.Client:Get(remotes.PickupMetal):SendToServer({
					id = v:GetAttribute('Id')
				})
			end, 20, false)
		end,
		miner = function()
			kitCollection('petrified-player', function(v)
				bedwars.Client:Get(remotes.MinerDig):SendToServer({
					petrifyId = v:GetAttribute('PetrifyId')
				})
			end, 6, true)
		end,
		pinata = function()
			kitCollection(lplr.Name..':pinata', function(v)
				if getItem('candy') then
					bedwars.Client:Get(remotes.DepositPinata):CallServer(v)
				end
			end, 6, true)
		end,
		spirit_assassin = function()
			kitCollection('EvelynnSoul', function(v)
				bedwars.SpiritAssassinController:useSpirit(lplr, v)
			end, 120, true)
		end,
		star_collector = function()
			kitCollection('stars', function(v)
				bedwars.StarCollectorController:collectEntity(lplr, v, v.Name)
			end, 20, false)
		end,
		summoner = function()
			repeat
				local plr = entitylib.EntityPosition({
					Range = 31,
					Part = 'RootPart',
					Players = true,
					Sort = sortmethods.Health
				})
	
				if plr and (not Legit.Enabled or (lplr.Character:GetAttribute('Health') or 0) > 0) then
					local localPosition = entitylib.character.RootPart.Position
					local shootDir = CFrame.lookAt(localPosition, plr.RootPart.Position).LookVector
					localPosition += shootDir * math.max((localPosition - plr.RootPart.Position).Magnitude - 16, 0)
	
					bedwars.Client:Get(remotes.SummonerClawAttack):SendToServer({
						position = localPosition,
						direction = shootDir,
						clientTime = workspace:GetServerTimeNow()
					})
				end
	
				task.wait(0.1)
			until not AutoKit.Enabled
		end,
		void_dragon = function()
			local old = bedwars.VoidDragonController.voidDragonActive
			local oldflap = bedwars.VoidDragonController.flapWings
	
			bedwars.VoidDragonController.voidDragonActive = function(self, ...)
				local Client = bedwars.Client
				local Remote = remotes.DragonEndFly
				self.SpeedMaid:GiveTask(function()
					Client:Get(Remote):SendToServer()
				end)
	
				task.spawn(function()
					for i = 1, 10 do
						if bedwars.Client:Get(remotes.DragonFly):CallServer() then
							local modifier = bedwars.SprintController:getMovementStatusModifier():addModifier({
								blockSprint = true,
								constantSpeedMultiplier = 1.7
							})
							self.SpeedMaid:GiveTask(modifier)
							break
						end
					end
				end)
	
				return old(self, ...)
			end
			bedwars.VoidDragonController.flapWings = function() end
	
			AutoKit:Clean(function()
				bedwars.VoidDragonController.voidDragonActive = old
				bedwars.VoidDragonController.flapWings = oldflap
				task.spawn(function()
					bedwars.Client:Get(remotes.DragonEndFly):SendToServer()
				end)
			end)
	
			repeat
				if bedwars.VoidDragonController.inDragonForm then
					local plr = entitylib.EntityPosition({
						Range = 30,
						Part = 'RootPart',
						Players = true
					})
	
					if plr then
						bedwars.Client:Get(remotes.DragonBreath):SendToServer({
							player = lplr,
							targetPoint = plr.RootPart.Position
						})
					end
				end
				task.wait(0.1)
			until not AutoKit.Enabled
		end,
		warlock = function()
			local lastTarget
			repeat
				if store.hand.tool and store.hand.tool.Name == 'warlock_staff' then
					local plr = entitylib.EntityPosition({
						Range = 30,
						Part = 'RootPart',
						Players = true,
						NPCs = true
					})
	
					if plr and plr.Character ~= lastTarget then
						if not bedwars.Client:Get(remotes.WarlockTarget):CallServer({
							target = plr.Character
						}) then
							plr = nil
						end
					end
	
					lastTarget = plr and plr.Character
				else
					lastTarget = nil
				end
	
				task.wait(0.1)
			until not AutoKit.Enabled
		end,
		wizard = function()
			repeat
				local ability = lplr:GetAttribute('WizardAbility')
				if ability and bedwars.AbilityController:canUseAbility(ability) then
					local plr = entitylib.EntityPosition({
						Range = 50,
						Part = 'RootPart',
						Players = true,
						Sort = sortmethods.Health
					})
	
					if plr then
						bedwars.AbilityController:useAbility(ability, newproxy(true), {target = plr.RootPart.Position})
					end
				end
	
				task.wait(0.1)
			until not AutoKit.Enabled
		end
	}
	
	AutoKit = vape.Categories.Utility:CreateModule({
		Name = 'AutoKit',
		Function = function(callback)
			if callback then
				repeat task.wait() until store.equippedKit ~= '' and store.matchState ~= 0 or (not AutoKit.Enabled)
				if AutoKit.Enabled and AutoKitFunctions[store.equippedKit] and Toggles[store.equippedKit].Enabled then
					AutoKitFunctions[store.equippedKit]()
				end
			end
		end,
		Tooltip = 'Automatically uses kit abilities.'
	})
	Legit = AutoKit:CreateToggle({Name = 'Legit Range'})
	local sortTable = {}
	for i in AutoKitFunctions do
		table.insert(sortTable, i)
	end
	table.sort(sortTable, function(a, b)
		return bedwars.BedwarsKitMeta[a].name < bedwars.BedwarsKitMeta[b].name
	end)
	for _, v in sortTable do
		Toggles[v] = AutoKit:CreateToggle({
			Name = bedwars.BedwarsKitMeta[v].name,
			Default = true
		})
	end
end)

run(function()
		local BetterWhisper 
		local FlyY 
		local Fly
		local Heal
		local db = false
		local connection
		local HealthHP
	    BetterWhisper = vape.Categories.Exploits:CreateModule({
	        Name = "BetterWhisper",
	        Function = function(callback)
	   			if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium"and role ~= "user"then
					vape:CreateNotification("Onyx", "You do not have permission to use this", 10, "alert")
					return
				end																																																																													
	            if callback then
					db = true
	   				local targetplayer
					for i, v in workspace:GetDescendants() do
						if not db then return end
					    if v:IsA("Model") then
					        if v.Name == "ServerOwl" then 
					            if v:GetAttribute("Owner") == game.Players.LocalPlayer.UserId then
											
					                targetplayer = game.Players:GetPlayerByUserId(v:GetAttribute("Target"))

					                local Y = math.floor(targetplayer.Character.HumanoidRootPart.Position.Y) 
									while task.wait(0.1) do
										Y = math.floor(targetplayer.Character.HumanoidRootPart.Position.Y) 
																																																							print(Y)
										task.spawn(function()
												if targetplayer.Character.Humanoid.Health <=HealthHP.Value then
													WhisperController:request(targetplayer,"Heal")
												end
										end)
										if Y <= FlyY.Value then
												WhisperController:request(targetplayer,"Fly")
										end
										if not targetplayer.Character then break end
									end
					            end
					        end
					    end
					end
					
					connection = BetterWhisper:Clean(workspace.DescendantAdded:Connect(function(v)
					    if v:IsA("Model") then
					        if v.Name == "ServerOwl" then 
					            if v:GetAttribute("Owner") == game.Players.LocalPlayer.UserId then
					                targetplayer = game.Players:GetPlayerByUserId(v:GetAttribute("Target"))
					                local Y = math.floor(targetplayer.Character.HumanoidRootPart.Position.Y)   
									while task.wait(0.1) do
										Y = math.floor(targetplayer.Character.HumanoidRootPart.Position.Y) 
										task.spawn(function()
												if targetplayer.Character.Humanoid.Health <=HealthHP.Value then
													WhisperController:request(targetplayer,"Heal")
												end
											
										end)
										if Y <= FlyY.Value then
												WhisperController:request(targetplayer,"Fly")
											
										end
										if not targetplayer.Character then break end
									end
					            end
					        end
					    end
					end))
				else
					connection:Disconnect()
					connection = nil
					db = false
	            end
	        end,
	        Tooltip = "Better whisper skills xd and u look like u play like therac!",
	    })
		FlyY = BetterWhisper:CreateSlider({
			Name = 'Y-Level fly',																																																																							
			Min = -50,
			Max = -100,
			Default = -90,
		
		})	
		HealthHP = BetterWhisper:CreateSlider({
			Name = 'Heal HP',																																																																							
			Min = 1,
			Max = 99,
			Default = 80,
		
		})	
		Fly = BetterWhisper:CreateToggle({
			Name = 'Fly',
			Default = true,
		})
		Heal = BetterWhisper:CreateToggle({
			Name = 'Heal',
			Default = true,
		})
end)
	
run(function()
		local char = lplr.Character or lplr.CharacterAdded:Wait()
		local teamID = char:GetAttribute("Team")
		local Distance = 15
		local db = true
		local ABDU
		local Upgrade
		local REMOTE = ""
		local tbllist = {
		    ["bed alarm"] = "bed_alarm",
		    ["bedalarm"] = "bed_alarm",
		    ["alarm"] = "bed_alarm",
		
		    ["bed shield"] = "bed_shield",
		    ["bedshield"] = "bed_shield",
		    ["shield"] = "bed_shield",
	
		    ["team"] = "TEAM_GENERATOR",
		    ["gen"] = "TEAM_GENERATOR",
		    ["team generator"] = "TEAM_GENERATOR",
		    ["team gen"] = "TEAM_GENERATOR",
		    ["teamgenerator"] = "TEAM_GENERATOR",
		    ["teamgen"] = "TEAM_GENERATOR",
		
		    ["diamond"] = "DIAMOND_GENERATOR",
		    ["diamond generator"] = "DIAMOND_GENERATOR",
		    ["diamond gen"] = "DIAMOND_GENERATOR",
		    ["diamondgen"] = "DIAMOND_GENERATOR",
		    ["diamondgenerator"] = "DIAMOND_GENERATOR",
		
		    ["dim"] = "DIAMOND_GENERATOR",
		    ["dim generator"] = "DIAMOND_GENERATOR",
		    ["dim gen"] = "DIAMOND_GENERATOR",
		    ["dimgenerator"] = "DIAMOND_GENERATOR",
		    ["dimgen"] = "DIAMOND_GENERATOR",
		
		    ["armor"] = "ARMOR",
		    ["arm"] = "ARMOR",
		
		    ["damage"] = "DAMAGE",
		    ["dmg"] = "DAMAGE",
	}
	local upgradePrices = {
	    bed_alarm = 2,
	    bed_shield = 5,
	
	    TEAM_GENERATOR = {4, 8, 16},
	    DIAMOND_GENERATOR = {4, 8, 12},
	
	    ARMOR = {4, 8, 18},
	    DAMAGE = {5, 10, 20},
	}

	local function getPrice(upgradeName, currentTier)
	    local prices = upgradePrices[upgradeName]
	    if not prices then return nil end
	
	    return prices[currentTier]  
	end
	local function purchase(upgrade)
	    local grade = string.lower(upgrade)
	    local mapped = tbllist[grade]
	
	    if not mapped then
	        getgenv().BEN("Invalid upgrade:", upgrade)
	        return
	    end
	
	    local function buyBed(price)
	        local item, amount = getItem("diamond")
	        if not (item and amount) then return end
	
	        if amount >= price then
	            game:GetService("ReplicatedStorage")
	                .rbxts_include.node_modules["@rbxts"].net.out._NetManaged
	                .RequestPurchaseBedTeamUpgrade:InvokeServer(mapped)
	            ABDU:Toggle(false)
	        else
	            getgenv().BEN("You do not have enough to autopurchase")
	        end
	    end
	
	    if mapped == "bed_alarm" then
	        buyBed(2)
	        return
	    end
	    if mapped == "bed_shield" then
	        buyBed(5)
	        return
	    end
	
	    local tier = 1
	
	    while true do
	        local price = getPrice(mapped, tier)
	        if not price then break end 
	
	        local item, amount = getItem("diamond")
	        if not (item and amount) then break end
	
	        if amount < price then
	            getgenv().BEN("Stopped: not enough for tier or max tier: "..tier)
	            break
	        end
	
	        game:GetService("ReplicatedStorage")
	            .rbxts_include.node_modules["@rbxts"].net.out._NetManaged
	            .RequestPurchaseTeamUpgrade:InvokeServer(mapped)
		
	        tier += 1
	    end
	end


	    ABDU = vape.Categories.Inventory:CreateModule({
	        Name = "AutoBuyUpgrades",
	        Function = function(callback)
	   			if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium"and role ~= "user"then
					vape:CreateNotification("Onyx", "You do not have permission to use this", 10, "alert")
					return
				end																																																																															
	            if callback then
	    			db = true

					while task.wait(0.5) do
					    for i, v in workspace:GetChildren() do
					        if v:IsA("BasePart") then
					            if v.Name == "1_upgrade_shop" then
					                if v:GetAttribute("GeneratorTeam") == teamID then
					                    local NewDis = (v.florist.PrimaryPart.Position - char.HumanoidRootPart.Position).Magnitude
					                    if NewDis <= Distance then
						                	purchase(Upgrade.Value)
					                    else
					                        
					                    end
					                else
					                    getgenv().BEN("Cannot locate where ur upgrade shop is at")
					                end
					            end
					        end
					    end

						if not db then break end
					end
				else
					db = false
	            end
	        end,
	        Tooltip = "Automatically buys upgrades when you go near the shop",
	    })
		Upgrade = ABDU:CreateTextBox({
			Name = 'Upgrade',
			Placeholder = 'Generator/Damage/Armor/BedShield/BedAlarm/Etc',
			Darker = true,
		})																																									
end)
run(function()
	local RH
	local AG
	
	AG = vape.Categories.AltFarm:CreateModule({
		Name = "AccountGrinding",
		Tooltip = "Used for getting accounts having rank enabled",
		Function = function(callback)
			if callback then
			if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium" then
				vape:CreateNotification("Onyx", "You do not have permission to use this", 10, "alert")
				return
			end       

			local function handleEndEvent()
				if not RH.Value then
					return lobby()
				end
				
				if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" then
					vape:CreateNotification("Onyx", "You do not have permission to use this", 10, "alert")
					return lobby()
				end

				local TeleportService = game:GetService("TeleportService")
				local data = TeleportService:GetLocalPlayerTeleportData()
				TeleportService:Teleport(game.PlaceId, game.Players.LocalPlayer, data)
			end

			AG:Clean(vapeEvents.EntityDeathEvent.Event:Connect(function(deathTable)
				if deathTable.finalKill and deathTable.entityInstance == lplr.Character and isEveryoneDead() and store.matchState ~= 2 then
					handleEndEvent()
				end
			end))

			AG:Clean(vapeEvents.MatchEndEvent.Event:Connect(function()
				handleEndEvent()
			end))
else
return
end

		end
	})

	RH = AG:CreateToggle({
		Name = "Reset History",
		Default = false,
	})
end)

	run(function()
	local WhitelistChecker
	local cachedData = {}
	local lastCheck = 0
	local checkInterval = 35
	
	local function fetchAPI(url)
		local success, result = pcall(function()
			return game:HttpGet(url, true)
		end)
		if success then
			return httpService:JSONDecode(result)
		end
		return nil
	end
	
	local function getUserHash(userId)
		return tostring(userId)
	end
	
	local function checkPlayer(player, data)
		local userId = tostring(player.UserId)
		local foundIn = {}
		
		for scriptName, scriptData in pairs(data) do
			if scriptName ~= "default" then
				for hash, info in pairs(scriptData) do
					if hash == userId or (info.names and table.find(info.names, player.Name)) then
						table.insert(foundIn, {
							script = scriptName,
							level = info.level or info.attackable or "N/A",
							tag = info.names and info.names[1] and info.names[1].text or "N/A",
							attackable = info.attackable ~= nil and (info.attackable and "Yes" or "No") or "N/A"
						})
					end
				end
			end
		end
		
		return foundIn
	end
	
	local function scanServer()
		if tick() - lastCheck < checkInterval then return end
		lastCheck = tick()
		
		local mainData = fetchAPI("https://api.love-skidding.lol/fetchcheaters")
		local vapeData = fetchAPI("https://whitelist.vapevoidware.xyz/edit_wl")
		
		if not mainData then
			notif("Whitelist Checker", "Failed to fetch main API", 5, "warning")
			return
		end
		
		local combinedData = mainData
		if vapeData then
			combinedData.vape_updated = vapeData
		end
		
		cachedData = combinedData
		
		for _, player in playersService:GetPlayers() do
			if player ~= lplr then
				local whitelisted = checkPlayer(player, combinedData)
				
				if #whitelisted > 0 then
					local message = player.Name .. " is whitelisted in:\n"
					for _, info in whitelisted do
						message = message .. string.format(
							"• %s | Level: %s | Tag: %s | Attackable: %s\n",
							info.script:upper(),
							tostring(info.level),
							info.tag,
							info.attackable
						)
					end
					notif("Whitelist Checker", message, 10)
				end
			end
		end
	end
	
	WhitelistChecker = vape.Categories.Exploits:CreateModule({
		Name = "Whitelist Checker",
		Function = function(callback)
			if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium" and role ~= "user"then
				vape:CreateNotification("Onyx", "You do not have permission to use this", 10, "alert")
				return
			end  
			if callback then
				task.spawn(scanServer)
				
				WhitelistChecker:Clean(playersService.PlayerAdded:Connect(function(player)
					task.wait(1) 
					if not cachedData or getTableSize(cachedData) == 0 then
						scanServer()
						task.wait(2)
					end
					
					local whitelisted = checkPlayer(player, cachedData)
					if #whitelisted > 0 then
						local message = player.Name .. " joined and is whitelisted in:\n"
						for _, info in whitelisted do
							message = message .. string.format(
								"• %s | Level: %s | Tag: %s | Attackable: %s\n",
								info.script:upper(),
								tostring(info.level),
								info.tag,
								info.attackable
							)
						end
						notif("Whitelist Checker", message, 10, "warning")
					end
				end))
				
				repeat
					scanServer()
					task.wait(checkInterval)
				until not WhitelistChecker.Enabled
			else
				lastCheck = 0
				table.clear(cachedData)
			end
		end,
		Tooltip = "Checks if players in your server are whitelisted in Vape/Voidware/QP/Velocity"
	})
	
	WhitelistChecker:CreateToggle({
		Name = "Notify on Join",
		Default = true,
		Tooltip = "Notify immediately when a whitelisted player joins"
	})
	
	WhitelistChecker:CreateToggle({
		Name = "Show Level",
		Default = true,
		Tooltip = "Show the whitelist level in notifications"
	})
	
	WhitelistChecker:CreateToggle({
		Name = "Show Tags",
		Default = true,
		Tooltip = "Show custom tags in notifications"
	})
end)

	run(function()
		local AutoGloopInterval
		local AutoGloopSwitchSpeed
		local AutoGloopWaitDelay
		local AutoGloopRange
		local AutoGloopFOV
		local lastAutoGloopTime = 0
		local autoGloopEnabled = false
		local GloopKillauraTargetCheck
		local FirstPersonCheck
		
		local VirtualInputManager = game:GetService("VirtualInputManager")
		
		local function leftClick()
			pcall(function()
				VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
				task.wait(0.05)
				VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
			end)
		end
		
		local function hasGloop()
			local gloopItem = getItem('glue_projectile')
			return gloopItem and gloopItem.amount > 0
		end
		
		local function getGloopSlots()
			local gloops = {}
			for i, v in store.inventory.hotbar do
				if v.item and v.item.itemType then
					if v.item.itemType == 'glue_projectile' then
						table.insert(gloops, i - 1)
					end
				end
			end
			return gloops
		end
		
		local function getSwordSlot()
			for i, v in store.inventory.hotbar do
				if v.item and bedwars.ItemMeta[v.item.itemType] then
					local meta = bedwars.ItemMeta[v.item.itemType]
					if meta.sword then
						return i - 1
					end
				end
			end
			return nil
		end
		
		local function getClosestTargetDistance()
			if not entitylib.isAlive then return math.huge end
			
			local myPos = entitylib.character.RootPart.Position
			local myLook = entitylib.character.RootPart.CFrame.LookVector
			local closestDist = math.huge
			
			for _, entity in entitylib.List do
				if entity.Player == lplr then continue end
				if not entity.Character then continue end
				if not entity.RootPart then continue end
				
				if entity.Player then
					if lplr:GetAttribute('Team') == entity.Player:GetAttribute('Team') then
						continue
					end
				else
					if not entity.Targetable then
						continue
					end
				end
				
				local distance = (entity.RootPart.Position - myPos).Magnitude
				if distance > AutoGloopRange.Value then continue end
				
				local toTarget = (entity.RootPart.Position - myPos).Unit
				local dot = myLook:Dot(toTarget)
				local angle = math.acos(dot)
				local fovRad = math.rad(AutoGloopFOV.Value)
				
				if angle <= fovRad then
					closestDist = math.min(closestDist, distance)
				end
			end
			
			return closestDist
		end
		
		local function hasValidTarget()
			if GloopKillauraTargetCheck.Enabled then
				return store.KillauraTarget ~= nil
			else
				return getClosestTargetDistance() <= AutoGloopRange.Value
			end
		end
		
		local AutoGloop = vape.Categories.Combat:CreateModule({
			Name = 'AutoGloop',
			Function = function(callback)
				if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium" then
					vape:CreateNotification("Onyx", "You do not have permission to use this", 10, "alert")
					return
				end   
				if callback then
					autoGloopEnabled = true
					
					task.spawn(function()
						repeat
							task.wait(0.1)
							if autoGloopEnabled and not _G.autoShootLock then
								if not hasGloop() then
									continue
								end
								
								if FirstPersonCheck.Enabled and not isFirstPerson() then
									continue
								end
								
								if not hasValidTarget() then
									continue
								end
								
								local closestDist = getClosestTargetDistance()
								if closestDist > 14 then
									continue
								end
								
								local currentTime = tick()
								if (currentTime - lastAutoGloopTime) >= AutoGloopInterval.Value then
									local gloops = getGloopSlots()
									local swordSlot = getSwordSlot()
									
									if #gloops > 0 then
										_G.autoShootLock = true
										lastAutoGloopTime = currentTime
										local originalSlot = store.inventory.hotbarSlot
										
										for _, gloopSlot in gloops do
											if hotbarSwitch(gloopSlot) then
												task.wait(AutoGloopSwitchSpeed.Value)
												task.wait(AutoGloopWaitDelay.Value)
												leftClick()
												task.wait(0.05)
											end
										end
										
										if swordSlot then
											hotbarSwitch(swordSlot)
										else
											hotbarSwitch(originalSlot)
										end
										
										_G.autoShootLock = false
									end
								end
							end
						until not autoGloopEnabled
					end)
				else
					autoGloopEnabled = false
				end
			end,
			Tooltip = 'Automatically throws gloop at close range enemies (under 12 studs)'
		})
		
		AutoGloopInterval = AutoGloop:CreateSlider({
			Name = 'Throw Interval',
			Min = 0.1,
			Max = 16,
			Default = 0.8,
			Decimal = 10,
			Suffix = function(val)
				return val == 1 and 'second' or 'seconds'
			end,
			Tooltip = 'How often to throw gloop'
		})
		
		AutoGloopSwitchSpeed = AutoGloop:CreateSlider({
			Name = 'Switch Delay',
			Min = 0,
			Max = 0.2,
			Default = 0.05,
			Decimal = 100,
			Suffix = 's',
			Tooltip = 'Delay between switching and throwing (lower = faster)'
		})
		
		AutoGloopWaitDelay = AutoGloop:CreateSlider({
			Name = 'Wait Delay',
			Min = 0,
			Max = 1,
			Default = 0,
			Decimal = 100,
			Suffix = 's',
			Tooltip = 'Delay before throwing (helps prevent ghosting)'
		})
		
		AutoGloopRange = AutoGloop:CreateSlider({
			Name = 'Range',
			Min = 1,
			Max = 30,
			Default = 15,
			Suffix = function(val)
				return val == 1 and 'stud' or 'studs'
			end,
			Tooltip = 'Maximum range to detect targets'
		})
		
		AutoGloopFOV = AutoGloop:CreateSlider({
			Name = 'FOV',
			Min = 1,
			Max = 180,
			Default = 90,
			Tooltip = 'Field of view for target detection (1-180 degrees)'
		})
		
		GloopKillauraTargetCheck = AutoGloop:CreateToggle({
			Name = 'Require Killaura Target',
			Default = false,
			Tooltip = 'Only throw gloop when Killaura has a target'
		})
		
		FirstPersonCheck = AutoGloop:CreateToggle({
			Name = 'First Person Only',
			Default = false,
			Tooltip = 'Only works in first person mode'
		})
	end)



	run(function()
		local KnitInit, Knit
		repeat
			KnitInit, Knit = pcall(function()
				return debug.getupvalue(require(game:GetService("Players").LocalPlayer.PlayerScripts.TS.knit).setup, 9)
			end)
			if KnitInit then break end
			task.wait()
		until KnitInit
	
		if not debug.getupvalue(Knit.Start, 1) then
			repeat task.wait() until debug.getupvalue(Knit.Start, 1)
		end
	
		local Players = game:GetService("Players")
	
		shared.PERMISSION_CONTROLLER_HASANYPERMISSIONS_REVERT = shared.PERMISSION_CONTROLLER_HASANYPERMISSIONS_REVERT or Knit.Controllers.PermissionController.hasAnyPermissions
		shared.MATCH_CONTROLLER_GETPLAYERPARTY_REVERT = shared.MATCH_CONTROLLER_GETPLAYERPARTY_REVERT or Knit.Controllers.MatchController.getPlayerParty
	
		local AC_MOD_View = {
			playerConnections = {},
			Enabled = false,
			Friends = {}, 
			parties = {}, 
			teamMap = {}, 
			display = {},
			isRefreshing = false,
			cacheDirty = true,
			disable_disguises = false,
			disguises = {},
			teamData = {},
			StaffDetectionConfig = {
				Actions = {
					Current = "Notify",
					Options = {
						Notify = function() end,
						Teleport = function() end
					}
				},
				Blacklist = {
					Users = {},
					GroupRanks = {}
				},
				LeaveParty = {
					Enabled = false
				}
			}
		}
	
		AC_MOD_View.controller = Knit.Controllers.PermissionController
		AC_MOD_View.match_controller = Knit.Controllers.MatchController
	
		function AC_MOD_View:notify(message)
			vape:CreateNotification(message)
		end
	
		function AC_MOD_View:saveStaffRecord(player, detectionType)
		end
	
		function AC_MOD_View:triggerAction(player, detectionType, extraInfo)
			local message = string.format("%s (@%s) detected as staff via %s! Executing %s action...", player.DisplayName, player.Name, detectionType, self.StaffDetectionConfig.Actions.Current)
			if extraInfo then
				message = message .. " Info: " .. extraInfo
			end
			
			self:notify(message)
			self:saveStaffRecord(player, detectionType)
			if self.StaffDetectionConfig.LeaveParty and self.StaffDetectionConfig.LeaveParty.Enabled then
				bedwars.PartyController:leaveParty()
				self:notify("Left party")
			end
			if self.StaffDetectionConfig.Actions.Options[self.StaffDetectionConfig.Actions.Current] then
				self.StaffDetectionConfig.Actions.Options[self.StaffDetectionConfig.Actions.Current]()
			end
		end
	
		function AC_MOD_View:checkPermissions(player)
			if shared.ACMODVIEWENABLED then return end
			if player == Players.LocalPlayer then return end
			if self.controller:isStaffMember(player) then
				self:triggerAction(player, "Permissions")
			end
		end
	
		function AC_MOD_View:checkBlacklist(player)
			if table.find(self.StaffDetectionConfig.Blacklist.Users, player.Name) then
				self:triggerAction(player, "Blacklist")
			end
		end
	
		function AC_MOD_View:checkGroupRank(player)
			local success, rank = pcall(function() return player:GetRankInGroup(5774246) end)
			rank = success and rank or 0
			
			local rankInfo = self.StaffDetectionConfig.Blacklist.GroupRanks[rank]
			if rankInfo then
				self:triggerAction(player, "GroupRank", "Role: " .. rankInfo)
			elseif self.YoutuberToggle and self.YoutuberToggle.Enabled and rank == 42378457 then
				self:triggerAction(player, "GroupRank", "Role: Youtuber/Famous")
			end
		end
	
		function AC_MOD_View:scanPlayer(player)
			if player == Players.LocalPlayer then return end
			task.spawn(function() 
				pcall(self.checkBlacklist, self, player) 
			end)
			task.spawn(function() 
				pcall(self.checkGroupRank, self, player) 
			end)
			task.spawn(function() 
				pcall(self.checkPermissions, self, player) 
			end)
		end
	
		function AC_MOD_View:getPartyById(displayId)
			if not displayId then return end
			displayId = tostring(displayId)
			if self.display[displayId] then return self.display[displayId] end
			for _, party in pairs(self.parties) do
				if party.displayId == tostring(displayId) then
					self.display[displayId] = party
					return party
				end
			end
		end
	
		function AC_MOD_View:refreshDisplayCache()
			for _, plr in pairs(Players:GetPlayers()) do
				local playerId = tostring(plr.UserId)
	
				local playerPartyId = self.teamMap[playerId]
				if playerPartyId ~= nil then
					self:getPartyById(playerPartyId)
				end
				task.wait()
			end
		end
	
		function AC_MOD_View:refreshDisplayCacheAsync()
			task.spawn(self.refreshDisplayCache, self)
		end
	
		function AC_MOD_View:getPlayerTeamData(plr)
			if self.teamData[plr] then return self.teamData[plr] end
	
			self.teamData[plr] = {}
	
			local teamMembers = {}
			local playerTeam = plr.Team 
			if not playerTeam then
				return teamMembers 
			end
	
			local playerId = tostring(plr.UserId)
			self.Friends[playerId] = self.Friends[playerId] or {}
	
			for _, otherPlayer in pairs(Players:GetPlayers()) do
				if otherPlayer == plr then continue end 
	
				local otherPlayerId = tostring(otherPlayer.UserId)
				local areFriends = self.Friends[playerId][otherPlayerId]
	
				if areFriends == nil then
					local suc, res = pcall(function()
						return plr:IsFriendsWith(otherPlayer.UserId)
					end)
					areFriends = suc and res or false
	
					if suc then
						self.Friends = self.Friends or {}
						self.Friends[playerId] = self.Friends[playerId] or {}
						self.Friends[playerId][otherPlayerId] = areFriends
						self.Friends[otherPlayerId] = self.Friends[otherPlayerId] or {}
						self.Friends[otherPlayerId][playerId] = areFriends
					end
				end
	
				if areFriends and otherPlayer.Team == playerTeam then
					table.insert(teamMembers, otherPlayerId)
				end
			end
	
			self.teamData[plr] = teamMembers
	
			return teamMembers
		end
	
		function AC_MOD_View:refreshPlayerTeamData()
			for i,v in pairs(Players:GetPlayers()) do
				self:getPlayerTeamData(v)
				task.wait()
			end
		end
	
		function AC_MOD_View:refreshPlayerTeamDataAsync()
			task.spawn(self.refreshPlayerTeamData, self)
		end
	
		function AC_MOD_View:refreshTeamMap()
			local allTeams = {}
			for _, p in pairs(Players:GetPlayers()) do
				local teamMembers = self:getPlayerTeamData(p)
				if teamMembers and #teamMembers > 0 then 
					allTeams[p] = teamMembers
				end
			end
	
			local validTeams = {}
			for playerInTeams, members in pairs(allTeams) do
				local playerIdInTeams = tostring(playerInTeams.UserId)
				local cleanedMembers = {}
	
				for _, memberId in pairs(members) do
					local memberIdStr = tostring(memberId)
					if memberIdStr == playerIdInTeams then
						print("Warning: Player " .. playerIdInTeams .. " has themselves in their team list.")
					else
						table.insert(cleanedMembers, memberIdStr)
					end
				end
	
				if #cleanedMembers > 0 then
					validTeams[playerInTeams] = cleanedMembers
				end
			end
	
			self.parties = {}
			self.teamMap = {}
			local teamId = 0
			for playerInTeams, members in pairs(validTeams) do
				local playerIdInTeams = tostring(playerInTeams.UserId)
				if not self.teamMap[playerIdInTeams] then
					self.teamMap[playerIdInTeams] = teamId
					table.insert(self.parties, {
						displayId = tostring(teamId),
						members = members
					})
					teamId = teamId + 1
	
					for _, memberId in pairs(members) do
						self.teamMap[memberId] = teamId - 1
					end
				end
			end
	
			self.cacheDirty = false
			self.isRefreshing = false
		end
	
		function AC_MOD_View:refreshTeamMapAsync()
			if self.isRefreshing then return end 
			self.isRefreshing = true
			task.spawn(function()
				self:refreshTeamMap()
			end)
		end
	
		function AC_MOD_View:getPlayerParty(plr)
			if not plr or not plr:IsA("Player") then
				return nil
			end
	
			local playerId = tostring(plr.UserId)
	
			if self.cacheDirty or not next(self.teamMap) then
				self:refreshTeamMapAsync()
			end
	
			local playerPartyId = self.teamMap[playerId]
			if playerPartyId ~= nil then
				return self:getPartyById(playerPartyId)
			end
	
			return nil 
		end
	
		AC_MOD_View.mockGetPlayerParty = function(self, plr)
			local parties = self.parties 
			if parties ~= nil and #parties > 0 then
				return shared.MATCH_CONTROLLER_GETPLAYERPARTY_REVERT(self, plr)
			end
			return AC_MOD_View:getPlayerParty(plr)
		end
	
		function AC_MOD_View:toggleDisableDisguises()
			if not self.Enabled then return end
			if self.disable_disguises then
				for _,v in pairs(Players:GetPlayers()) do
					if v == Players.LocalPlayer then continue end
					if tostring(v:GetAttribute("Disguised")) == "true" then
						v:SetAttribute("Disguised", false)
						vape:CreateNotification("Remove Disguises", "Disabled streamer mode for "..tostring(v.Name).."!", 3)
						table.insert(self.disguises, v)
					end
				end
			else
				for i,v in pairs(self.disguises) do
					if tostring(v:GetAttribute("Disguised")) ~= "true" then
						v:SetAttribute("Disguised", true)
						vape:CreateNotification("Remove Disguises", "Re - enabled Streamer mode for "..tostring(v.Name).."!", 2)
					end
				end
				table.clear(self.disguises)
			end
		end
	
		function AC_MOD_View:refreshCore()
			self:refreshTeamMapAsync()
			self:refreshDisplayCacheAsync()
			self:refreshPlayerTeamDataAsync()
	
			self:toggleDisableDisguises()
			
			for _, player in pairs(Players:GetPlayers()) do
				if player ~= Players.LocalPlayer then
					self:scanPlayer(player)
				end
			end
		end
	
		function AC_MOD_View:refreshCoreAsync()
			task.spawn(self.refreshCore, self)
		end
	
		function AC_MOD_View:init()
			self.Enabled = true
			self.controller.hasAnyPermissions = function(self)
				return true
			end
			self.match_controller.getPlayerParty = self.mockGetPlayerParty
	
			self.playerConnections = {
				added = Players.PlayerAdded:Connect(function(player)
					self.cacheDirty = true
					self:refreshCoreAsync()
					task.spawn(function()
						task.wait(1)
						self:scanPlayer(player)
					end)
					player:GetPropertyChangedSignal("Team"):Connect(function()
						self.cacheDirty = true
						self:refreshCoreAsync()
					end)
				end),
				removed = Players.PlayerRemoving:Connect(function(player)
					local playerId = tostring(player.UserId)
					self.Friends[playerId] = nil 
					for _, cache in pairs(self.Friends) do
						cache[playerId] = nil
					end
					self.cacheDirty = true
					self:refreshCoreAsync()
				end)
			}
	
			self:refreshCore()
		end
	
		function AC_MOD_View:disable()
			self.Enabled = false
	
			self.controller.hasAnyPermissions = shared.PERMISSION_CONTROLLER_HASANYPERMISSIONS_REVERT
			self.match_controller.getPlayerParty = shared.MATCH_CONTROLLER_GETPLAYERPARTY_REVERT
	
			if self.playerConnections then
				for _, v in pairs(self.playerConnections) do
					pcall(function() v:Disconnect() end)
				end
				table.clear(self.playerConnections)
			end
	
			self.parties = {}
			self.teamMap = {}
			self.Friends = {}
			self.display = {}
			self.teamData = {}
			self.cacheDirty = true
	
			self:toggleDisableDisguises()
		end
		
		shared.ACMODVIEWENABLED = false
		AC_MOD_View.moduleInstance = vape.Categories.Exploits:CreateModule({
			Name = "AC MOD View",
			Function = function(call)
				if role ~= "owner" and role ~= "coowner" and role ~= "admin" and role ~= "friend" and role ~= "premium" then
					vape:CreateNotification("Onyx", "You do not have permission to use this", 10, "alert")
					return
				end  
				shared.ACMODVIEWENABLED = call
				if call then
					AC_MOD_View:init()
				else
					AC_MOD_View:disable()
				end
			end
		})
	
		AC_MOD_View.disableDisguisesToggle = AC_MOD_View.moduleInstance:CreateToggle({
			Name = "Remove Disguises",
			Function = function(call)
				AC_MOD_View.disable_disguises = call
				AC_MOD_View:toggleDisableDisguises()
			end,
			Default = true
		})
	end)

run(function()
	local TexturePacks = {["Enabled"] = false}
	local packselected = {["Value"] = "OldBedwars"}

	local toolFunction = function() end
	local con

	local packfunctions = {
		SeventhPack = function() 
			task.spawn(function()
				local Players = game:GetService("Players")
				local ReplicatedStorage = game:GetService("ReplicatedStorage")
				local Workspace = game:GetService("Workspace")
				local objs = game:GetObjects("rbxassetid://14033898270")
				local import = objs[1]
				import.Parent = ReplicatedStorage
				local index = {
					{
						name = "wood_sword",
						offset = CFrame.Angles(math.rad(0), math.rad(-100), math.rad(-90)),
						model = import:WaitForChild("Wood_Sword"),
					},	
					{
						name = "stone_sword",
						offset = CFrame.Angles(math.rad(0), math.rad(-100), math.rad(-90)),
						model = import:WaitForChild("Stone_Sword"),
					},
					{
						name = "iron_sword",
						offset = CFrame.Angles(math.rad(0), math.rad(-100), math.rad(-90)),
						model = import:WaitForChild("Iron_Sword"),
					},
					{
						name = "diamond_sword",
						offset = CFrame.Angles(math.rad(0), math.rad(-100), math.rad(-90)),
						model = import:WaitForChild("Diamond_Sword"),
					},
					{
						name = "emerald_sword",
						offset = CFrame.Angles(math.rad(0), math.rad(-100), math.rad(-90)),
						model = import:WaitForChild("Emerald_Sword"),
					},
					{
						name = "wood_pickaxe",
						offset = CFrame.Angles(math.rad(0), math.rad(-190), math.rad(-95)),
						model = import:WaitForChild("Wood_Pickaxe"),
					},
					{
						name = "stone_pickaxe",
						offset = CFrame.Angles(math.rad(0), math.rad(-190), math.rad(-95)),
						model = import:WaitForChild("Stone_Pickaxe"),
					},
					{
						name = "iron_pickaxe",
						offset = CFrame.Angles(math.rad(0), math.rad(-190), math.rad(-95)),
						model = import:WaitForChild("Iron_Pickaxe"),
					},
					{
						name = "diamond_pickaxe",
						offset = CFrame.Angles(math.rad(0), math.rad(80), math.rad(-95)),
						model = import:WaitForChild("Diamond_Pickaxe"),
					},	
					{
						name = "wood_axe",
						offset = CFrame.Angles(math.rad(0), math.rad(-10), math.rad(-95)),
						model = import:WaitForChild("Wood_Axe"),
					},	
					{
						name = "stone_axe",
						offset = CFrame.Angles(math.rad(0), math.rad(-10), math.rad(-95)),
						model = import:WaitForChild("Stone_Axe"),
					},	
					{
						name = "iron_axe",
						offset = CFrame.Angles(math.rad(0), math.rad(-10), math.rad(-95)),
						model = import:WaitForChild("Iron_Axe"),
					},	
					{
						name = "diamond_axe",
						offset = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(-95)),
						model = import:WaitForChild("Diamond_Axe"),
					},	
					{
						name = "fireball",
						offset = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(90)),
						model = import:WaitForChild("Fireball"),
					},	
					{
						name = "telepearl",
						offset = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(90)),
						model = import:WaitForChild("Telepearl"),
					},
				}
				toolFunction = function(tool)	
					if not tool:IsA("Accessory") then return end	
					for _, v in ipairs(index) do	
						if v.name == tool.Name then		
							for _, part in ipairs(tool:GetDescendants()) do
								if part:IsA("BasePart") or part:IsA("MeshPart") or part:IsA("UnionOperation") then				
									part.Transparency = 1
								end			
							end		
							local model = v.model:Clone()
							model.CFrame = tool:WaitForChild("Handle").CFrame * v.offset
							model.CFrame *= CFrame.Angles(math.rad(0), math.rad(-50), math.rad(0))
							model.Parent = tool			
							local weld = Instance.new("WeldConstraint", model)
							weld.Part0 = model
							weld.Part1 = tool:WaitForChild("Handle")			
							local tool2 = Players.LocalPlayer.Character:WaitForChild(tool.Name)			
							for _, part in ipairs(tool2:GetDescendants()) do
								if part:IsA("BasePart") or part:IsA("MeshPart") or part:IsA("UnionOperation") then				
									part.Transparency = 1				
								end			
							end			
							local model2 = v.model:Clone()
							model2.Anchored = false
							model2.CFrame = tool2:WaitForChild("Handle").CFrame * v.offset
							model2.CFrame *= CFrame.Angles(math.rad(0), math.rad(-50), math.rad(0))
							if v.name:match("sword") or v.name:match("blade") then
								model2.CFrame *= CFrame.new(.5, 0, -1.1) - Vector3.new(0, 0, -.3)
							elseif v.name:match("axe") and not v.name:match("pickaxe") and v.name:match("diamond") then
								model2.CFrame *= CFrame.new(.08, 0, -1.1) - Vector3.new(0, 0, -.9)
							elseif v.name:match("axe") and not v.name:match("pickaxe") and not v.name:match("diamond") then
								model2.CFrame *= CFrame.new(-.2, 0, -2.4) + Vector3.new(0, 0, 2.12)
							else
								model2.CFrame *= CFrame.new(.2, 0, -.09)
							end
							model2.Parent = tool2
							local weld2 = Instance.new("WeldConstraint", model)
							weld2.Part0 = model2
							weld2.Part1 = tool2:WaitForChild("Handle")
						end
					end
				end
			end)
		end,
		EighthPack = function() 
			task.spawn(function()
				local Players = game:GetService("Players")
				local ReplicatedStorage = game:GetService("ReplicatedStorage")
				local Workspace = game:GetService("Workspace")
				local objs = game:GetObjects("rbxassetid://14078540433")
				local import = objs[1]
				import.Parent = game:GetService("ReplicatedStorage")
				index = {
					{
						name = "wood_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(-100),math.rad(-90)),
						model = import:WaitForChild("Wood_Sword"),
					},
					{
						name = "stone_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(-100),math.rad(-90)),
						model = import:WaitForChild("Stone_Sword"),
					},
					{
						name = "iron_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(-100),math.rad(-90)),
						model = import:WaitForChild("Iron_Sword"),
					},
					{
						name = "diamond_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(-100),math.rad(-90)),
						model = import:WaitForChild("Diamond_Sword"),
					},
					{
						name = "emerald_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(-100),math.rad(-90)),
						model = import:WaitForChild("Emerald_Sword"),
					},
					{
						name = "rageblade",
						offset = CFrame.Angles(math.rad(0),math.rad(-90),math.rad(90)),
						model = import:WaitForChild("Rageblade"),
					}, 
				}
				toolFunction = function(tool)
					if(not tool:IsA("Accessory")) then return end
					for i,v in pairs(index) do
						if(v.name == tool.Name) then
							for i,v in pairs(tool:GetDescendants()) do
								if(v:IsA("Part") or v:IsA("MeshPart") or v:IsA("UnionOperation")) then
									v.Transparency = 1
								end
							end
							local model = v.model:Clone()
							model.CFrame = tool:WaitForChild("Handle").CFrame * v.offset
							model.CFrame *= CFrame.Angles(math.rad(0),math.rad(-50),math.rad(0))
							model.Parent = tool
							local weld = Instance.new("WeldConstraint",model)
							weld.Part0 = model
							weld.Part1 = tool:WaitForChild("Handle")
							local tool2 = Players.LocalPlayer.Character:WaitForChild(tool.Name)
							for i,v in pairs(tool2:GetDescendants()) do
								if(v:IsA("Part") or v:IsA("MeshPart") or v:IsA("UnionOperation")) then
									v.Transparency = 1
								end
							end
							local model2 = v.model:Clone()
							model2.Anchored = false
							model2.CFrame = tool2:WaitForChild("Handle").CFrame * v.offset
							model2.CFrame *= CFrame.Angles(math.rad(0),math.rad(-50),math.rad(0))
							model2.CFrame *= CFrame.new(.5,0,-.8)
							model2.Parent = tool2
							local weld2 = Instance.new("WeldConstraint",model)
							weld2.Part0 = model2
							weld2.Part1 = tool2:WaitForChild("Handle")
						end
					end
				end
			end)
		end,
		SixthPack = function() 
			task.spawn(function()
				local Players = game:GetService("Players")
				local ReplicatedStorage = game:GetService("ReplicatedStorage")
				local Workspace = game:GetService("Workspace")

				local objs = game:GetObjects("rbxassetid://13780890894")
				local import = objs[1]
				import.Parent = ReplicatedStorage
				
				local swordIndex = {
					{
						name = "wood_sword",
						offset = CFrame.Angles(math.rad(0), math.rad(-100), math.rad(-90)),
						model = import:WaitForChild("Wood_Sword"),
					},
					{
						name = "stone_sword",
						offset = CFrame.Angles(math.rad(0), math.rad(-100), math.rad(-90)),
						model = import:WaitForChild("Stone_Sword"),
					},
					{
						name = "iron_sword",
						offset = CFrame.Angles(math.rad(0), math.rad(-100), math.rad(-90)),
						model = import:WaitForChild("Iron_Sword"),
					},
					{
						name = "diamond_sword",
						offset = CFrame.Angles(math.rad(0), math.rad(-100), math.rad(-90)),
						model = import:WaitForChild("Diamond_Sword"),
					},
					{
						name = "emerald_sword",
						offset = CFrame.Angles(math.rad(0), math.rad(-100), math.rad(-90)),
						model = import:WaitForChild("Emerald_Sword"),
					},
				}
				
				local pickaxeIndex = {
					{
						name = "wood_pickaxe",
						offset = CFrame.Angles(math.rad(0), math.rad(-190), math.rad(-95)),
						model = import:WaitForChild("Wood_Pickaxe"),
					},
					{
						name = "stone_pickaxe",
						offset = CFrame.Angles(math.rad(0), math.rad(-190), math.rad(-95)),
						model = import:WaitForChild("Stone_Pickaxe"),
					},
					{
						name = "iron_pickaxe",
						offset = CFrame.Angles(math.rad(0), math.rad(-190), math.rad(-95)),
						model = import:WaitForChild("Iron_Pickaxe"),
					},
					{
						name = "diamond_pickaxe",
						offset = CFrame.Angles(math.rad(0), math.rad(80), math.rad(-95)),
						model = import:WaitForChild("Diamond_Pickaxe"),
					},
				}

				local swordFunction = function(tool)
					if not tool:IsA("Accessory") then
						return
					end
					
					for _, v in pairs(swordIndex) do
						if v.name == tool.Name then
							for _, v in pairs(tool:GetDescendants()) do
								if v:IsA("Part") or v:IsA("MeshPart") or v:IsA("UnionOperation") then
									v.Transparency = 1
								end
							end
							
							local model = v.model:Clone()
							model.CFrame = tool.Handle.CFrame * v.offset
							model.CFrame *= CFrame.Angles(math.rad(0), math.rad(-50), math.rad(0))
							model.Parent = tool
							
							local weld = Instance.new("WeldConstraint", model)
							weld.Part0 = model
							weld.Part1 = tool.Handle
							
							local tool2 = Players.LocalPlayer.Character[tool.Name]
							
							for _, v in pairs(tool2:GetDescendants()) do
								if v:IsA("Part") or v:IsA("MeshPart") or v:IsA("UnionOperation") then
									v.Transparency = 1
								end
							end
							
							local model2 = v.model:Clone()
							model2.Anchored = false
							model2.CFrame = tool2.Handle.CFrame * v.offset
							model2.CFrame *= CFrame.Angles(math.rad(0), math.rad(-50), math.rad(0))
							model2.CFrame *= CFrame.new(0.4, 0, -0.9)
							model2.Parent = tool2
							
							local weld2 = Instance.new("WeldConstraint", model)
							weld2.Part0 = model2
							weld2.Part1 = tool2.Handle
						end
					end
				end

				local pickaxeFunction = function(tool)
					if not tool:IsA("Accessory") then
						return
					end

					for _, v in pairs(pickaxeIndex) do
						if v.name == tool.Name then
							for _, v in pairs(tool:GetDescendants()) do
								if v:IsA("Part") or v:IsA("MeshPart") or v:IsA("UnionOperation") then
									v.Transparency = 1
								end
							end
							local model = v.model:Clone()
							model.CFrame = tool.Handle.CFrame * v.offset
							model.CFrame *= CFrame.Angles(math.rad(0), math.rad(-50), math.rad(0))
							model.Parent = tool
							local weld = Instance.new("WeldConstraint", model)
							weld.Part0 = model
							weld.Part1 = tool.Handle
							local tool2 = Players.LocalPlayer.Character[tool.Name]
							for _, v in pairs(tool2:GetDescendants()) do
								if v:IsA("Part") or v:IsA("MeshPart") or v:IsA("UnionOperation") then
									v.Transparency = 1
								end
							end
							local model2 = v.model:Clone()
							model2.Anchored = false
							model2.CFrame = tool2.Handle.CFrame * v.offset
							model2.CFrame *= CFrame.Angles(math.rad(0), math.rad(-50), math.rad(0))
							model2.CFrame *= CFrame.new(-0.2, 0, -0.08)
							model2.Parent = tool2
							local weld2 = Instance.new("WeldConstraint", model)
							weld2.Part0 = model2
							weld2.Part1 = tool2.Handle
						end
					end
				end

				toolFunction = function(tool)
					task.spawn(function() swordFunction(tool) end)
					task.spawn(function() pickaxeFunction(tool) end)
				end
			end)
		end,
		FifthPack = function() 
			task.spawn(function()
				local Players = game:GetService("Players")
				local ReplicatedStorage = game:GetService("ReplicatedStorage")
				local Workspace = game:GetService("Workspace")
				
				local objs = game:GetObjects("rbxassetid://13802020264")
				local import = objs[1]
				
				import.Parent = game:GetService("ReplicatedStorage")
				
				index = {
					{
						name = "wood_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(-100),math.rad(-90)),
						model = import:WaitForChild("Wood_Sword"),
					},
					
					{
						name = "stone_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(-100),math.rad(-90)),
						model = import:WaitForChild("Stone_Sword"),
					},
					
					{
						name = "iron_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(-100),math.rad(-90)),
						model = import:WaitForChild("Iron_Sword"),
					},
					
					{
						name = "diamond_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(-100),math.rad(-90)),
						model = import:WaitForChild("Diamond_Sword"),
					},
					
					{
						name = "emerald_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(-100),math.rad(-90)),
						model = import:WaitForChild("Emerald_Sword"),
					},
					
					
				}
				
				toolFunction = function(tool)
					if(not tool:IsA("Accessory")) then return end
					for i,v in pairs(index) do
						if(v.name == tool.Name) then
							for i,v in pairs(tool:GetDescendants()) do
								if(v:IsA("Part") or v:IsA("MeshPart") or v:IsA("UnionOperation")) then
									v.Transparency = 1
								end
							end
						
							local model = v.model:Clone()
							model.CFrame = tool:WaitForChild("Handle").CFrame * v.offset
							model.CFrame *= CFrame.Angles(math.rad(0),math.rad(-50),math.rad(0))
							model.Parent = tool
							
							local weld = Instance.new("WeldConstraint",model)
							weld.Part0 = model
							weld.Part1 = tool:WaitForChild("Handle")
							
							local tool2 = Players.LocalPlayer.Character:WaitForChild(tool.Name)
							
							for i,v in pairs(tool2:GetDescendants()) do
								if(v:IsA("Part") or v:IsA("MeshPart") or v:IsA("UnionOperation")) then
									v.Transparency = 1
								end
							end
							
							local model2 = v.model:Clone()
							model2.Anchored = false
							model2.CFrame = tool2:WaitForChild("Handle").CFrame * v.offset
							model2.CFrame *= CFrame.Angles(math.rad(0),math.rad(-50),math.rad(0))
							model2.CFrame *= CFrame.new(0.8,0,-.9)
							model2.Parent = tool2
							
							local weld2 = Instance.new("WeldConstraint",model)
							weld2.Part0 = model2
							weld2.Part1 = tool2:WaitForChild("Handle")			
						end
					end
				end
			end)
		end,
		FourthPack = function() 
			task.spawn(function()
				local Players = game:GetService("Players")
				local ReplicatedStorage = game:GetService("ReplicatedStorage")
				local Workspace = game:GetService("Workspace")
				
				local objs = game:GetObjects("rbxassetid://13801509384")
				local import = objs[1]
				
				import.Parent = game:GetService("ReplicatedStorage")
				
				index = {
				
					{
						name = "wood_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(-100),math.rad(-90)),
						model = import:WaitForChild("Wood_Sword"),
					},
					
					{
						name = "stone_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(-100),math.rad(-90)),
						model = import:WaitForChild("Stone_Sword"),
					},
					
					{
						name = "iron_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(-100),math.rad(-90)),
						model = import:WaitForChild("Iron_Sword"),
					},
					
					{
						name = "diamond_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(-100),math.rad(-90)),
						model = import:WaitForChild("Diamond_Sword"),
					},
					
					{
						name = "emerald_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(-100),math.rad(-90)),
						model = import:WaitForChild("Emerald_Sword"),
					},
					
					{
						name = "rageblade",
						offset = CFrame.Angles(math.rad(0),math.rad(-100),math.rad(-270)),
						model = import:WaitForChild("Rageblade"),
					},
					
					
				}

				toolFunction = function(tool)
					if(not tool:IsA("Accessory")) then return end
					for i,v in pairs(index) do
						if(v.name == tool.Name) then	
							for i,v in pairs(tool:GetDescendants()) do
								if(v:IsA("Part") or v:IsA("MeshPart") or v:IsA("UnionOperation")) then	
									v.Transparency = 1
								end
							end
						
							local model = v.model:Clone()
							model.CFrame = tool:WaitForChild("Handle").CFrame * v.offset
							model.CFrame *= CFrame.Angles(math.rad(0),math.rad(-50),math.rad(0))
							model.Parent = tool
							
							local weld = Instance.new("WeldConstraint",model)
							weld.Part0 = model
							weld.Part1 = tool:WaitForChild("Handle")
							
							local tool2 = Players.LocalPlayer.Character:WaitForChild(tool.Name)
							
							for i,v in pairs(tool2:GetDescendants()) do
								if(v:IsA("Part") or v:IsA("MeshPart") or v:IsA("UnionOperation")) then	
									v.Transparency = 1	
								end	
							end

							local model2 = v.model:Clone()
							model2.Anchored = false
							model2.CFrame = tool2:WaitForChild("Handle").CFrame * v.offset
							model2.CFrame *= CFrame.Angles(math.rad(0),math.rad(-50),math.rad(0))
							model2.CFrame *= CFrame.new(0.4,0,-.9)
							model2.Parent = tool2
							
							local weld2 = Instance.new("WeldConstraint",model)
							weld2.Part0 = model2
							weld2.Part1 = tool2:WaitForChild("Handle")					
						end
					end
				end
			end)
		end,
		SecondPack = function() 
			task.spawn(function()
				local Players = game:GetService("Players")
				local ReplicatedStorage = game:GetService("ReplicatedStorage")
				local Workspace = game:GetService("Workspace")
				local objs = game:GetObjects("rbxassetid://13801616054")
				local import = objs[1]
				import.Parent = game:GetService("ReplicatedStorage")
				index = {
					{
						name = "wood_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(100),math.rad(-90)),
						model = import:WaitForChild("Wood_Sword"),
					},
					
					{
						name = "stone_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(100),math.rad(-90)),
						model = import:WaitForChild("Stone_Sword"),
					},
					
					{
						name = "iron_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(100),math.rad(-90)),
						model = import:WaitForChild("Iron_Sword"),
					},
					
					{
						name = "diamond_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(100),math.rad(-90)),
						model = import:WaitForChild("Diamond_Sword"),
					},
					
					{
						name = "emerald_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(100),math.rad(-90)),
						model = import:WaitForChild("Emerald_Sword"),
					},
					
					{
						name = "rageblade",
						offset = CFrame.Angles(math.rad(0),math.rad(100),math.rad(-270)),
						model = import:WaitForChild("Rageblade"),
					},
					
					
				}

				toolFunction = function(tool)
					if(not tool:IsA("Accessory")) then return end
					for i,v in pairs(index) do
						if(v.name == tool.Name) then
							for i,v in pairs(tool:GetDescendants()) do
								if(v:IsA("Part") or v:IsA("MeshPart") or v:IsA("UnionOperation")) then
									v.Transparency = 1
								end
							end
						
							local model = v.model:Clone()
							model.CFrame = tool:WaitForChild("Handle").CFrame * v.offset
							model.CFrame *= CFrame.Angles(math.rad(0),math.rad(-50),math.rad(0))
							model.Parent = tool
							
							local weld = Instance.new("WeldConstraint",model)
							weld.Part0 = model
							weld.Part1 = tool:WaitForChild("Handle")
							
							local tool2 = Players.LocalPlayer.Character:WaitForChild(tool.Name)
							
							for i,v in pairs(tool2:GetDescendants()) do
								if(v:IsA("Part") or v:IsA("MeshPart") or v:IsA("UnionOperation")) then
									v.Transparency = 1
								end
							end
							
							local model2 = v.model:Clone()
							model2.Anchored = false
							model2.CFrame = tool2:WaitForChild("Handle").CFrame * v.offset
							model2.CFrame *= CFrame.Angles(math.rad(0),math.rad(-50),math.rad(0))
							model2.CFrame *= CFrame.new(0.8,0,-.9)
							model2.Parent = tool2
							
							local weld2 = Instance.new("WeldConstraint",model)
							weld2.Part0 = model2
							weld2.Part1 = tool2:WaitForChild("Handle")
						end
					end
				end
			end)
		end,
		FirstPack = function() 
			task.spawn(function()
				local Players = game:GetService("Players")
				local ReplicatedStorage = game:GetService("ReplicatedStorage")
				local Workspace = game:GetService("Workspace")
				local objs = game:GetObjects("rbxassetid://13783192680")
				local import = objs[1]
				import.Parent = game:GetService("ReplicatedStorage")
				index = {
					{
						name = "wood_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(-100),math.rad(-90)),
						model = import:WaitForChild("Wood_Sword"),
					},
					
					{
						name = "stone_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(-100),math.rad(-90)),
						model = import:WaitForChild("Stone_Sword"),
					},
					
					{
						name = "iron_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(-100),math.rad(-90)),
						model = import:WaitForChild("Iron_Sword"),
					},
					
					{
						name = "diamond_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(-100),math.rad(-90)),
						model = import:WaitForChild("Diamond_Sword"),
					},
					
					{
						name = "emerald_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(-100),math.rad(-90)),
						model = import:WaitForChild("Emerald_Sword"),
					},
					
					
				}
				toolFunction = function(tool)
					if(not tool:IsA("Accessory")) then return end
					for i,v in pairs(index) do
						if(v.name == tool.Name) then
							for i,v in pairs(tool:GetDescendants()) do
								if(v:IsA("Part") or v:IsA("MeshPart") or v:IsA("UnionOperation")) then
									v.Transparency = 1
								end
							end
							local model = v.model:Clone()
							model.CFrame = tool:WaitForChild("Handle").CFrame * v.offset
							model.CFrame *= CFrame.Angles(math.rad(0),math.rad(-50),math.rad(0))
							model.Parent = tool
							
							local weld = Instance.new("WeldConstraint",model)
							weld.Part0 = model
							weld.Part1 = tool:WaitForChild("Handle")
							
							local tool2 = Players.LocalPlayer.Character:WaitForChild(tool.Name)
							
							for i,v in pairs(tool2:GetDescendants()) do
								if(v:IsA("Part") or v:IsA("MeshPart") or v:IsA("UnionOperation")) then
									v.Transparency = 1
								end
							end
							
							local model2 = v.model:Clone()
							model2.Anchored = false
							model2.CFrame = tool2:WaitForChild("Handle").CFrame * v.offset
							model2.CFrame *= CFrame.Angles(math.rad(0),math.rad(-50),math.rad(0))
							model2.CFrame *= CFrame.new(0.4,0,-.9)
							model2.Parent = tool2
							
							local weld2 = Instance.new("WeldConstraint",model)
							weld2.Part0 = model2
							weld2.Part1 = tool2:WaitForChild("Handle")
						end
					end
				end
			end)
		end,
		CottonCandy = function() 
			task.spawn(function() 
				local Players = game:GetService("Players")
				local ReplicatedStorage = game:GetService("ReplicatedStorage")
				local Workspace = game:GetService("Workspace")
				local objs = game:GetObjects("rbxassetid://14161283331")
				local import = objs[1]
				import.Parent = ReplicatedStorage
				local index = {
					{
						name = "wood_sword",
						offset = CFrame.Angles(math.rad(0), math.rad(-89), math.rad(-90)),
						model = import:WaitForChild("Wood_Sword"),
					},	
					{
						name = "stone_sword",
						offset = CFrame.Angles(math.rad(0), math.rad(-89), math.rad(-90)),
						model = import:WaitForChild("Stone_Sword"),
					},
					{
						name = "iron_sword",
						offset = CFrame.Angles(math.rad(0), math.rad(-89), math.rad(-90)),
						model = import:WaitForChild("Iron_Sword"),
					},
					{
						name = "diamond_sword",
						offset = CFrame.Angles(math.rad(0), math.rad(-89), math.rad(-90)),
						model = import:WaitForChild("Diamond_Sword"),
					},
					{
						name = "emerald_sword",
						offset = CFrame.Angles(math.rad(0), math.rad(-89), math.rad(-90)),
						model = import:WaitForChild("Emerald_Sword"),
					},
					{
						name = "rageblade",
						offset = CFrame.Angles(math.rad(0),math.rad(-100),math.rad(90)),
						model = import:WaitForChild("Rageblade"),
					}, 
					{
						name = "wood_pickaxe",
						offset = CFrame.Angles(math.rad(0), math.rad(-180), math.rad(-95)),
						model = import:WaitForChild("Wood_Pickaxe"),
					},
					{
						name = "stone_pickaxe",
						offset = CFrame.Angles(math.rad(0), math.rad(-180), math.rad(-95)),
						model = import:WaitForChild("Stone_Pickaxe"),
					},
					{
						name = "iron_pickaxe",
						offset = CFrame.Angles(math.rad(0), math.rad(-18033), math.rad(-95)),
						model = import:WaitForChild("Iron_Pickaxe"),
					},
					{
						name = "diamond_pickaxe",
						offset = CFrame.Angles(math.rad(0), math.rad(80), math.rad(-95)),
						model = import:WaitForChild("Diamond_Pickaxe"),
					},	
					{
						name = "wood_axe",
						offset = CFrame.Angles(math.rad(0), math.rad(-10), math.rad(-95)),
						model = import:WaitForChild("Wood_Axe"),
					},	
					{
						name = "stone_axe",
						offset = CFrame.Angles(math.rad(0), math.rad(-10), math.rad(-95)),
						model = import:WaitForChild("Stone_Axe"),
					},	
					{
						name = "iron_axe",
						offset = CFrame.Angles(math.rad(0), math.rad(-10), math.rad(-95)),
						model = import:WaitForChild("Iron_Axe"),
					},	
					{
						name = "diamond_axe",
						offset = CFrame.Angles(math.rad(0), math.rad(-89), math.rad(-95)),
						model = import:WaitForChild("Diamond_Axe"),
					},	
					{
						name = "fireball",
						offset = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(90)),
						model = import:WaitForChild("Fireball"),
					},	
					{
						name = "telepearl",
						offset = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(90)),
						model = import:WaitForChild("Telepearl"),
					},
					{
						name = "diamond",
						offset = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(90)),
						model = import:WaitForChild("Diamond"),
					},
					{
						name = "iron",
						offset = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(90)),
						model = import:WaitForChild("Iron"),
					},
					{
						name = "gold",
						offset = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(90)),
						model = import:WaitForChild("Gold"),
					},
					{
						name = "emerald",
						offset = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(90)),
						model = import:WaitForChild("Emerald"),
					},
					{
						name = "wood_bow",
						offset = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
						model = import:WaitForChild("Bow"),
					},
					{
						name = "wood_crossbow",
						offset = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
						model = import:WaitForChild("Bow"),
					},
					{
						name = "tactical_crossbow",
						offset = CFrame.Angles(math.rad(0), math.rad(180), math.rad(-90)),
						model = import:WaitForChild("Bow"),
					},
				}
				toolFunction = function(tool)	
					if not tool:IsA("Accessory") then return end	
					for _, v in ipairs(index) do	
						if v.name == tool.Name then		
							for _, part in ipairs(tool:GetDescendants()) do
								if part:IsA("BasePart") or part:IsA("MeshPart") or part:IsA("UnionOperation") then				
									part.Transparency = 1
								end			
							end		
							local model = v.model:Clone()
							model.CFrame = tool:WaitForChild("Handle").CFrame * v.offset
							model.CFrame *= CFrame.Angles(math.rad(0), math.rad(-50), math.rad(0))
							model.Parent = tool			
							local weld = Instance.new("WeldConstraint", model)
							weld.Part0 = model
							weld.Part1 = tool:WaitForChild("Handle")			
							local tool2 = Players.LocalPlayer.Character:WaitForChild(tool.Name)			
							for _, part in ipairs(tool2:GetDescendants()) do
								if part:IsA("BasePart") or part:IsA("MeshPart") or part:IsA("UnionOperation") then				
									part.Transparency = 1				
								end			
							end			
							local model2 = v.model:Clone()
							model2.Anchored = false
							model2.CFrame = tool2:WaitForChild("Handle").CFrame * v.offset
							model2.CFrame *= CFrame.Angles(math.rad(0), math.rad(-50), math.rad(0))
							if v.name:match("rageblade") then
								model2.CFrame *= CFrame.new(0.7, 0, -1)                           
							elseif v.name:match("sword") or v.name:match("blade") then
								model2.CFrame *= CFrame.new(.6, 0, -1.1) - Vector3.new(0, 0, -.3)
							elseif v.name:match("axe") and not v.name:match("pickaxe") and v.name:match("diamond") then
								model2.CFrame *= CFrame.new(.08, 0, -1.1) - Vector3.new(0, 0, -1.1)
							elseif v.name:match("axe") and not v.name:match("pickaxe") and not v.name:match("diamond") then
								model2.CFrame *= CFrame.new(-.2, 0, -2.4) + Vector3.new(0, 0, 2.12)
							elseif v.name:match("iron") then
								model2.CFrame *= CFrame.new(0, -.24, 0)
							elseif v.name:match("gold") then
								model2.CFrame *= CFrame.new(0, .03, 0)
							elseif v.name:match("diamond") then
								model2.CFrame *= CFrame.new(0, .027, 0)
							elseif v.name:match("emerald") then
								model2.CFrame *= CFrame.new(0, .001, 0)
							elseif v.name:match("telepearl") then
								model2.CFrame *= CFrame.new(.1, 0, .1)
							elseif v.name:match("fireball") then
								model2.CFrame *= CFrame.new(.28, .1, 0)
							elseif v.name:match("bow") and not v.name:match("crossbow") then
								model2.CFrame *= CFrame.new(-.29, .1, -.2)
							elseif v.name:match("wood_crossbow") and not v.name:match("tactical_crossbow") then
								model2.CFrame *= CFrame.new(-.6, 0, 0)
							elseif v.name:match("tactical_crossbow") and not v.name:match("wood_crossbow") then
								model2.CFrame *= CFrame.new(-.5, 0, -1.2)
							else
								model2.CFrame *= CFrame.new(.2, 0, -.2)
							end
							model2.Parent = tool2
							local weld2 = Instance.new("WeldConstraint", model)
							weld2.Part0 = model2
							weld2.Part1 = tool2:WaitForChild("Handle")
						end
					end
				end   
			end)
		end,
		EgirlPack = function() 
			task.spawn(function() 	
				local Players = game:GetService("Players")
				local ReplicatedStorage = game:GetService("ReplicatedStorage")
				local Workspace = game:GetService("Workspace")
				local objs = game:GetObjects("rbxassetid://14126814481")
				local import = objs[1]
				import.Parent = game:GetService("ReplicatedStorage")
				index = {
					{
						name = "wood_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(-100),math.rad(-90)),
						model = import:WaitForChild("Wood_Sword"),
					},
					{
						name = "stone_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(-100),math.rad(-90)),
						model = import:WaitForChild("Stone_Sword"),
					},
					{
						name = "iron_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(-100),math.rad(-90)),
						model = import:WaitForChild("Iron_Sword"),
					},
					{
						name = "diamond_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(-100),math.rad(-90)),
						model = import:WaitForChild("Diamond_Sword"),
					},
					{
						name = "emerald_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(-100),math.rad(-90)),
						model = import:WaitForChild("Emerald_Sword"),
					},
					{
						name = "rageblade",
						offset = CFrame.Angles(math.rad(0),math.rad(-90),math.rad(90)),
						model = import:WaitForChild("Rageblade"),
					}, 
				}
				toolFunction = function(tool)
					if(not tool:IsA("Accessory")) then return end
					for i,v in pairs(index) do
						if(v.name == tool.Name) then
							for i,v in pairs(tool:GetDescendants()) do
								if(v:IsA("Part") or v:IsA("MeshPart") or v:IsA("UnionOperation")) then
									v.Transparency = 1
								end
							end
							local model = v.model:Clone()
							model.CFrame = tool:WaitForChild("Handle").CFrame * v.offset
							model.CFrame *= CFrame.Angles(math.rad(0),math.rad(-50),math.rad(0))
							model.Parent = tool
							local weld = Instance.new("WeldConstraint",model)
							weld.Part0 = model
							weld.Part1 = tool:WaitForChild("Handle")
							local tool2 = Players.LocalPlayer.Character:WaitForChild(tool.Name)
							for i,v in pairs(tool2:GetDescendants()) do
								if(v:IsA("Part") or v:IsA("MeshPart") or v:IsA("UnionOperation")) then
									v.Transparency = 1
								end
							end
							local model2 = v.model:Clone()
							model2.Anchored = false
							model2.CFrame = tool2:WaitForChild("Handle").CFrame * v.offset
							model2.CFrame *= CFrame.Angles(math.rad(0),math.rad(-50),math.rad(0))
							model2.CFrame *= CFrame.new(.6,0,-1)
							model2.Parent = tool2
							local weld2 = Instance.new("WeldConstraint",model)
							weld2.Part0 = model2
							weld2.Part1 = tool2:WaitForChild("Handle")
						end
					end
				end             
			end)
		end,
		GlizzyPack = function() 
			task.spawn(function()
				local Players = game:GetService("Players")
				local ReplicatedStorage = game:GetService("ReplicatedStorage")
				local Workspace = game:GetService("Workspace")
				local objs = game:GetObjects("rbxassetid://13804645310")
				local import = objs[1]
				import.Parent = game:GetService("ReplicatedStorage")
				index = {
					{
						name = "wood_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(-100),math.rad(-90)),
						model = import:WaitForChild("Wood_Sword"),
					},
					{
						name = "stone_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(-100),math.rad(-90)),
						model = import:WaitForChild("Stone_Sword"),
					},
					{
						name = "iron_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(-100),math.rad(-90)),
						model = import:WaitForChild("Iron_Sword"),
					},
					{
						name = "diamond_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(-100),math.rad(-90)),
						model = import:WaitForChild("Diamond_Sword"),
					},
					{
						name = "emerald_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(-100),math.rad(-90)),
						model = import:WaitForChild("Emerald_Sword"),
					},
					{
						name = "rageblade",
						offset = CFrame.Angles(math.rad(0),math.rad(-100),math.rad(-270)),
						model = import:WaitForChild("Rageblade"),
					},
				}
				toolFunction = function(tool)
					if(not tool:IsA("Accessory")) then return end
					for i,v in pairs(index) do
						if(v.name == tool.Name) then
							for i,v in pairs(tool:GetDescendants()) do
								if(v:IsA("Part") or v:IsA("MeshPart") or v:IsA("UnionOperation")) then
									v.Transparency = 1
								end
							end
							local model = v.model:Clone()
							model.CFrame = tool:WaitForChild("Handle").CFrame * v.offset
							model.CFrame *= CFrame.Angles(math.rad(0),math.rad(100),math.rad(0))
							model.Parent = tool
							local weld = Instance.new("WeldConstraint",model)
							weld.Part0 = model
							weld.Part1 = tool:WaitForChild("Handle")
							local tool2 = Players.LocalPlayer.Character:WaitForChild(tool.Name)
							for i,v in pairs(tool2:GetDescendants()) do
								if(v:IsA("Part") or v:IsA("MeshPart") or v:IsA("UnionOperation")) then
									v.Transparency = 1
								end
							end
							local model2 = v.model:Clone()
							model2.Anchored = false
							model2.CFrame = tool2:WaitForChild("Handle").CFrame * v.offset
							model2.CFrame *= CFrame.Angles(math.rad(0),math.rad(-105),math.rad(0))
							model2.CFrame *= CFrame.new(-0.4,0,-0.10)
							model2.Parent = tool2
							local weld2 = Instance.new("WeldConstraint",model)
							weld2.Part0 = model2
							weld2.Part1 = tool2:WaitForChild("Handle")
						end
					end
				end
			end)
        end,
		PrivatePack = function() 
			task.spawn(function()
				local Players = game:GetService("Players")
				local ReplicatedStorage = game:GetService("ReplicatedStorage")
				local Workspace = game:GetService("Workspace")
				local objs = game:GetObjects("rbxassetid://14161283331")
				local import = objs[1]
				import.Parent = ReplicatedStorage
				local index = {
					{
						name = "wood_sword",
						offset = CFrame.Angles(math.rad(0), math.rad(-89), math.rad(-90)),
						model = import:WaitForChild("Wood_Sword"),
					},	
					{
						name = "stone_sword",
						offset = CFrame.Angles(math.rad(0), math.rad(-89), math.rad(-90)),
						model = import:WaitForChild("Stone_Sword"),
					},
					{
						name = "iron_sword",
						offset = CFrame.Angles(math.rad(0), math.rad(-89), math.rad(-90)),
						model = import:WaitForChild("Iron_Sword"),
					},
					{
						name = "diamond_sword",
						offset = CFrame.Angles(math.rad(0), math.rad(-89), math.rad(-90)),
						model = import:WaitForChild("Diamond_Sword"),
					},
					{
						name = "emerald_sword",
						offset = CFrame.Angles(math.rad(0), math.rad(-89), math.rad(-90)),
						model = import:WaitForChild("Emerald_Sword"),
					},
					{
						name = "rageblade",
						offset = CFrame.Angles(math.rad(0),math.rad(-100),math.rad(90)),
						model = import:WaitForChild("Rageblade"),
					}, 
					{
						name = "wood_pickaxe",
						offset = CFrame.Angles(math.rad(0), math.rad(-180), math.rad(-95)),
						model = import:WaitForChild("Wood_Pickaxe"),
					},
					{
						name = "stone_pickaxe",
						offset = CFrame.Angles(math.rad(0), math.rad(-180), math.rad(-95)),
						model = import:WaitForChild("Stone_Pickaxe"),
					},
					{
						name = "iron_pickaxe",
						offset = CFrame.Angles(math.rad(0), math.rad(-18033), math.rad(-95)),
						model = import:WaitForChild("Iron_Pickaxe"),
					},
					{
						name = "diamond_pickaxe",
						offset = CFrame.Angles(math.rad(0), math.rad(80), math.rad(-95)),
						model = import:WaitForChild("Diamond_Pickaxe"),
					},	
					{
						name = "wood_axe",
						offset = CFrame.Angles(math.rad(0), math.rad(-10), math.rad(-95)),
						model = import:WaitForChild("Wood_Axe"),
					},	
					{
						name = "stone_axe",
						offset = CFrame.Angles(math.rad(0), math.rad(-10), math.rad(-95)),
						model = import:WaitForChild("Stone_Axe"),
					},	
					{
						name = "iron_axe",
						offset = CFrame.Angles(math.rad(0), math.rad(-10), math.rad(-95)),
						model = import:WaitForChild("Iron_Axe"),
					},	
					{
						name = "diamond_axe",
						offset = CFrame.Angles(math.rad(0), math.rad(-89), math.rad(-95)),
						model = import:WaitForChild("Diamond_Axe"),
					},	
					{
						name = "fireball",
						offset = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(90)),
						model = import:WaitForChild("Fireball"),
					},	
					{
						name = "telepearl",
						offset = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(90)),
						model = import:WaitForChild("Telepearl"),
					},
					{
						name = "diamond",
						offset = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(90)),
						model = import:WaitForChild("Diamond"),
					},
					{
						name = "iron",
						offset = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(90)),
						model = import:WaitForChild("Iron"),
					},
					{
						name = "gold",
						offset = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(90)),
						model = import:WaitForChild("Gold"),
					},
					{
						name = "emerald",
						offset = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(90)),
						model = import:WaitForChild("Emerald"),
					},
					{
						name = "wood_bow",
						offset = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
						model = import:WaitForChild("Bow"),
					},
					{
						name = "wood_crossbow",
						offset = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
						model = import:WaitForChild("Bow"),
					},
					{
						name = "tactical_crossbow",
						offset = CFrame.Angles(math.rad(0), math.rad(180), math.rad(-90)),
						model = import:WaitForChild("Bow"),
					},
				}
				toolFunction = function(tool)	
					if not tool:IsA("Accessory") then return end	
					for _, v in ipairs(index) do	
						if v.name == tool.Name then		
							for _, part in ipairs(tool:GetDescendants()) do
								if part:IsA("BasePart") or part:IsA("MeshPart") or part:IsA("UnionOperation") then				
									part.Transparency = 1
								end			
							end		
							local model = v.model:Clone()
							model.CFrame = tool:WaitForChild("Handle").CFrame * v.offset
							model.CFrame *= CFrame.Angles(math.rad(0), math.rad(-50), math.rad(0))
							model.Parent = tool			
							local weld = Instance.new("WeldConstraint", model)
							weld.Part0 = model
							weld.Part1 = tool:WaitForChild("Handle")			
							local tool2 = Players.LocalPlayer.Character:WaitForChild(tool.Name)			
							for _, part in ipairs(tool2:GetDescendants()) do
								if part:IsA("BasePart") or part:IsA("MeshPart") or part:IsA("UnionOperation") then				
									part.Transparency = 1				
								end			
							end			
							local model2 = v.model:Clone()
							model2.Anchored = false
							model2.CFrame = tool2:WaitForChild("Handle").CFrame * v.offset
							model2.CFrame *= CFrame.Angles(math.rad(0), math.rad(-50), math.rad(0))
							if v.name:match("rageblade") then
								model2.CFrame *= CFrame.new(0.7, 0, -1)                           
							elseif v.name:match("sword") or v.name:match("blade") then
								model2.CFrame *= CFrame.new(.6, 0, -1.1) - Vector3.new(0, 0, -.3)
							elseif v.name:match("axe") and not v.name:match("pickaxe") and v.name:match("diamond") then
								model2.CFrame *= CFrame.new(.08, 0, -1.1) - Vector3.new(0, 0, -1.1)
							elseif v.name:match("axe") and not v.name:match("pickaxe") and not v.name:match("diamond") then
								model2.CFrame *= CFrame.new(-.2, 0, -2.4) + Vector3.new(0, 0, 2.12)
							elseif v.name:match("iron") then
								model2.CFrame *= CFrame.new(0, -.24, 0)
							elseif v.name:match("gold") then
								model2.CFrame *= CFrame.new(0, .03, 0)
							elseif v.name:match("diamond") then
								model2.CFrame *= CFrame.new(0, .027, 0)
							elseif v.name:match("emerald") then
								model2.CFrame *= CFrame.new(0, .001, 0)
							elseif v.name:match("telepearl") then
								model2.CFrame *= CFrame.new(.1, 0, .1)
							elseif v.name:match("fireball") then
								model2.CFrame *= CFrame.new(.28, .1, 0)
							elseif v.name:match("bow") and not v.name:match("crossbow") then
								model2.CFrame *= CFrame.new(-.29, .1, -.2)
							elseif v.name:match("wood_crossbow") and not v.name:match("tactical_crossbow") then
								model2.CFrame *= CFrame.new(-.6, 0, 0)
							elseif v.name:match("tactical_crossbow") and not v.name:match("wood_crossbow") then
								model2.CFrame *= CFrame.new(-.5, 0, -1.2)
							else
								model2.CFrame *= CFrame.new(.2, 0, -.2)
							end
							model2.Parent = tool2
							local weld2 = Instance.new("WeldConstraint", model)
							weld2.Part0 = model2
							weld2.Part1 = tool2:WaitForChild("Handle")
						end
					end
				end          
			end)
        end,
		DemonSlayerPack = function() 
			task.spawn(function()
				local Players = game:GetService("Players")
				local ReplicatedStorage = game:GetService("ReplicatedStorage")
				local Workspace = game:GetService("Workspace")
				local objs = game:GetObjects("rbxassetid://14241215869")
				local import = objs[1]
				import.Parent = ReplicatedStorage
				local index = {
					{
						name = "wood_sword",
						offset = CFrame.Angles(math.rad(0), math.rad(-89), math.rad(-90)),
						model = import:WaitForChild("Wood_Sword"),
					},	
					{
						name = "stone_sword",
						offset = CFrame.Angles(math.rad(0), math.rad(-89), math.rad(-90)),
						model = import:WaitForChild("Stone_Sword"),
					},
					{
						name = "iron_sword",
						offset = CFrame.Angles(math.rad(0), math.rad(-89), math.rad(-90)),
						model = import:WaitForChild("Iron_Sword"),
					},
					{
						name = "diamond_sword",
						offset = CFrame.Angles(math.rad(0), math.rad(-89), math.rad(-90)),
						model = import:WaitForChild("Diamond_Sword"),
					},
					{
						name = "emerald_sword",
						offset = CFrame.Angles(math.rad(0), math.rad(-89), math.rad(-90)),
						model = import:WaitForChild("Emerald_Sword"),
					},
					{
						name = "wood_pickaxe",
						offset = CFrame.Angles(math.rad(0), math.rad(-180), math.rad(-95)),
						model = import:WaitForChild("Wood_Pickaxe"),
					},
					{
						name = "stone_pickaxe",
						offset = CFrame.Angles(math.rad(0), math.rad(-180), math.rad(-95)),
						model = import:WaitForChild("Stone_Pickaxe"),
					},
					{
						name = "iron_pickaxe",
						offset = CFrame.Angles(math.rad(0), math.rad(-180), math.rad(-95)),
						model = import:WaitForChild("Iron_Pickaxe"),
					},
					{
						name = "diamond_pickaxe",
						offset = CFrame.Angles(math.rad(0), math.rad(90), math.rad(-95)),
						model = import:WaitForChild("Diamond_Pickaxe"),
					},	
					{
						name = "fireball",
						offset = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(90)),
						model = import:WaitForChild("Fireball"),
					},	
					{
						name = "telepearl",
						offset = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(90)),
						model = import:WaitForChild("Telepearl"),
					},
					{
						name = "diamond",
						offset = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(-90)),
						model = import:WaitForChild("Diamond"),
					},
					{
						name = "iron",
						offset = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(90)),
						model = import:WaitForChild("Iron"),
					},
					{
						name = "gold",
						offset = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(90)),
						model = import:WaitForChild("Gold"),
					},
					{
						name = "emerald",
						offset = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(-90)),
						model = import:WaitForChild("Emerald"),
					},
					{
						name = "wood_bow",
						offset = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
						model = import:WaitForChild("Bow"),
					},
					{
						name = "wood_crossbow",
						offset = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
						model = import:WaitForChild("Bow"),
					},
					{
						name = "tactical_crossbow",
						offset = CFrame.Angles(math.rad(0), math.rad(180), math.rad(-90)),
						model = import:WaitForChild("Bow"),
					},
					{
						name = "wood_dao",
						offset = CFrame.Angles(math.rad(0), math.rad(89), math.rad(-90)),
						model = import:WaitForChild("Wood_Sword"),
					},
					{
						name = "stone_dao",
						offset = CFrame.Angles(math.rad(0), math.rad(89), math.rad(-90)),
						model = import:WaitForChild("Stone_Sword"),
					},
					{
						name = "iron_dao",
						offset = CFrame.Angles(math.rad(0), math.rad(89), math.rad(-90)),
						model = import:WaitForChild("Iron_Sword"),
					},
					{
						name = "diamond_dao",
						offset = CFrame.Angles(math.rad(0), math.rad(89), math.rad(-90)),
						model = import:WaitForChild("Diamond_Sword"),
					},
				}
				toolFunction = function(tool)	
					if not tool:IsA("Accessory") then return end	
					for _, v in ipairs(index) do	
						if v.name == tool.Name then		
							for _, part in ipairs(tool:GetDescendants()) do
								if part:IsA("BasePart") or part:IsA("MeshPart") or part:IsA("UnionOperation") then				
									part.Transparency = 1
								end			
							end		
							local model = v.model:Clone()
							model.CFrame = tool:WaitForChild("Handle").CFrame * v.offset
							model.CFrame *= CFrame.Angles(math.rad(0), math.rad(-50), math.rad(0))
							model.Parent = tool			
							local weld = Instance.new("WeldConstraint", model)
							weld.Part0 = model
							weld.Part1 = tool:WaitForChild("Handle")			
							local tool2 = Players.LocalPlayer.Character:WaitForChild(tool.Name)			
							for _, part in ipairs(tool2:GetDescendants()) do
								if part:IsA("BasePart") or part:IsA("MeshPart") or part:IsA("UnionOperation") then				
									part.Transparency = 1				
								end			
							end			
							local model2 = v.model:Clone()
							model2.Anchored = false
							model2.CFrame = tool2:WaitForChild("Handle").CFrame * v.offset
							model2.CFrame *= CFrame.Angles(math.rad(0), math.rad(-50), math.rad(0))
							if v.name:match("rageblade") then
								model2.CFrame *= CFrame.new(0.7, 0, -.7)                           
							elseif v.name:match("sword") or v.name:match("blade") then
								model2.CFrame *= CFrame.new(.2, 0, -.8)
							elseif v.name:match("dao") then
								model2.CFrame *= CFrame.new(.7, 0, -1.3)
							elseif v.name:match("axe") and not v.name:match("pickaxe") and v.name:match("diamond") then
								model2.CFrame *= CFrame.new(.08, 0, -1.1) - Vector3.new(0, 0, -1.1)
							elseif v.name:match("axe") and not v.name:match("pickaxe") and not v.name:match("diamond") then
								model2.CFrame *= CFrame.new(-.2, 0, -2.4) + Vector3.new(0, 0, 2.12)
							elseif v.name:match("diamond_pickaxe") then
								model2.CFrame *= CFrame.new(.2, 0, -.26)
							elseif v.name:match("iron") and not v.name:match("iron_pickaxe") then
								model2.CFrame *= CFrame.new(0, -.24, 0)
							elseif v.name:match("gold") then
								model2.CFrame *= CFrame.new(0, .03, 0)
							elseif v.name:match("diamond") or v.name:match("emerald") then
								model2.CFrame *= CFrame.new(0, -.03, 0)
							elseif v.name:match("telepearl") then
								model2.CFrame *= CFrame.new(.1, 0, .1)
							elseif v.name:match("fireball") then
								model2.CFrame *= CFrame.new(.28, .1, 0)
							elseif v.name:match("bow") and not v.name:match("crossbow") then
								model2.CFrame *= CFrame.new(-.2, .1, -.05)
							elseif v.name:match("wood_crossbow") and not v.name:match("tactical_crossbow") then
								model2.CFrame *= CFrame.new(-.5, 0, .05)
							elseif v.name:match("tactical_crossbow") and not v.name:match("wood_crossbow") then
								model2.CFrame *= CFrame.new(-.35, 0, -1.2)
							else
								model2.CFrame *= CFrame.new(.0, 0, -.06)
							end
							model2.Parent = tool2
							local weld2 = Instance.new("WeldConstraint", model)
							weld2.Part0 = model2
							weld2.Part1 = tool2:WaitForChild("Handle")
						end
					end
				end
			end)
		end,
        FirstHighResPack = function() 
            task.spawn(function()
				local Players = game:GetService("Players")
				local ReplicatedStorage = game:GetService("ReplicatedStorage")
				local Workspace = game:GetService("Workspace")
				local objs = game:GetObjects("rbxassetid://14224565815")
				local import = objs[1]
				import.Parent = ReplicatedStorage
				local index = {
					{
						name = "wood_sword",
						offset = CFrame.Angles(math.rad(0), math.rad(-89), math.rad(-90)),
						model = import:WaitForChild("Wood_Sword"),
					},
					{
						name = "stone_sword",
						offset = CFrame.Angles(math.rad(0), math.rad(-89), math.rad(-90)),
						model = import:WaitForChild("Stone_Sword"),
					},
					{
						name = "iron_sword",
						offset = CFrame.Angles(math.rad(0), math.rad(-89), math.rad(-90)),
						model = import:WaitForChild("Iron_Sword"),
					},
					{
						name = "diamond_sword",
						offset = CFrame.Angles(math.rad(0), math.rad(-89), math.rad(-90)),
						model = import:WaitForChild("Diamond_Sword"),
					},
					{
						name = "emerald_sword",
						offset = CFrame.Angles(math.rad(0), math.rad(-89), math.rad(-90)),
						model = import:WaitForChild("Emerald_Sword"),
					},
          			{
                        name = "rageblade",
                        offset = CFrame.Angles(math.rad(0),math.rad(-100),math.rad(90)),
                        model = import:WaitForChild("Rageblade"),
          			},
					{
						name = "wood_pickaxe",
						offset = CFrame.Angles(math.rad(0), math.rad(-180), math.rad(-95)),
						model = import:WaitForChild("Wood_Pickaxe"),
					},
					{
						name = "stone_pickaxe",
						offset = CFrame.Angles(math.rad(0), math.rad(-180), math.rad(-95)),
						model = import:WaitForChild("Stone_Pickaxe"),
					},
					{
						name = "iron_pickaxe",
						offset = CFrame.Angles(math.rad(0), math.rad(-180), math.rad(-95)),
						model = import:WaitForChild("Iron_Pickaxe"),
					},
					{
						name = "diamond_pickaxe",
						offset = CFrame.Angles(math.rad(0), math.rad(90), math.rad(-95)),
						model = import:WaitForChild("Diamond_Pickaxe"),
					},
					{
						name = "wood_axe",
						offset = CFrame.Angles(math.rad(0), math.rad(-10), math.rad(-95)),
						model = import:WaitForChild("Wood_Axe"),
					},
					{
						name = "stone_axe",
						offset = CFrame.Angles(math.rad(0), math.rad(-10), math.rad(-95)),
						model = import:WaitForChild("Stone_Axe"),
					},
					{
						name = "iron_axe",
						offset = CFrame.Angles(math.rad(0), math.rad(-10), math.rad(-95)),
						model = import:WaitForChild("Iron_Axe"),
					},
					{
						name = "diamond_axe",
						offset = CFrame.Angles(math.rad(0), math.rad(-89), math.rad(-95)),
						model = import:WaitForChild("Diamond_Axe"),
					},
					{
						name = "fireball",
						offset = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(90)),
						model = import:WaitForChild("Fireball"),
					},
					{
						name = "telepearl",
						offset = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(90)),
						model = import:WaitForChild("Telepearl"),
					},
					{
						name = "diamond",
						offset = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(-90)),
						model = import:WaitForChild("Diamond"),
					},
					{
						name = "iron",
						offset = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(90)),
						model = import:WaitForChild("Iron"),
					},
					{
						name = "gold",
						offset = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(90)),
						model = import:WaitForChild("Gold"),
					},
					{
						name = "emerald",
						offset = CFrame.Angles(math.rad(0), math.rad(-90), math.rad(-90)),
						model = import:WaitForChild("Emerald"),
					},
					{
						name = "wood_bow",
						offset = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
						model = import:WaitForChild("Bow"),
					},
					{
						name = "wood_crossbow",
						offset = CFrame.Angles(math.rad(0), math.rad(0), math.rad(90)),
						model = import:WaitForChild("Bow"),
					},
					{
						name = "tactical_crossbow",
						offset = CFrame.Angles(math.rad(0), math.rad(180), math.rad(-90)),
						model = import:WaitForChild("Bow"),
					},
				}
				toolFunction = function(tool)
					if not tool:IsA("Accessory") then return end
					for _, v in ipairs(index) do
						if v.name == tool.Name then
							for _, part in ipairs(tool:GetDescendants()) do
								if part:IsA("BasePart") or part:IsA("MeshPart") or part:IsA("UnionOperation") then
									part.Transparency = 1
								end
							end
							local model = v.model:Clone()
							model.CFrame = tool:WaitForChild("Handle").CFrame * v.offset
							model.CFrame *= CFrame.Angles(math.rad(0), math.rad(-50), math.rad(0))
							model.Parent = tool
							local weld = Instance.new("WeldConstraint", model)
							weld.Part0 = model
							weld.Part1 = tool:WaitForChild("Handle")
							local tool2 = Players.LocalPlayer.Character:WaitForChild(tool.Name)
							for _, part in ipairs(tool2:GetDescendants()) do
								if part:IsA("BasePart") or part:IsA("MeshPart") or part:IsA("UnionOperation") then
									part.Transparency = 1
								end
							end
							local model2 = v.model:Clone()
							model2.Anchored = false
							model2.CFrame = tool2:WaitForChild("Handle").CFrame * v.offset
							model2.CFrame *= CFrame.Angles(math.rad(0), math.rad(-50), math.rad(0))
							if v.name:match("rageblade") then
								model2.CFrame *= CFrame.new(0.7, 0, -1)
							elseif v.name:match("sword") or v.name:match("blade") then
								model2.CFrame *= CFrame.new(.6, 0, -1.1) - Vector3.new(0, 0, -.3)
							elseif v.name:match("axe") and not v.name:match("pickaxe") and v.name:match("diamond") then
								model2.CFrame *= CFrame.new(.08, 0, -1.1) - Vector3.new(0, 0, -1.1)
							elseif v.name:match("axe") and not v.name:match("pickaxe") and not v.name:match("diamond") then
								model2.CFrame *= CFrame.new(-.2, 0, -2.4) + Vector3.new(0, 0, 2.12)
							elseif v.name:match("diamond_pickaxe") then
								model2.CFrame *= CFrame.new(.2, 0, -.26)
							elseif v.name:match("iron") and not v.name:match("iron_pickaxe") then
								model2.CFrame *= CFrame.new(0, -.24, 0)
							elseif v.name:match("gold") then
								model2.CFrame *= CFrame.new(0, .03, 0)
							elseif v.name:match("diamond") or v.name:match("emerald") then
								model2.CFrame *= CFrame.new(0, -.03, 0)
							elseif v.name:match("telepearl") then
								model2.CFrame *= CFrame.new(.1, 0, .1)
							elseif v.name:match("fireball") then
								model2.CFrame *= CFrame.new(.28, .1, 0)
							elseif v.name:match("bow") and not v.name:match("crossbow") then
								model2.CFrame *= CFrame.new(-.2, .1, -.05)
							elseif v.name:match("wood_crossbow") and not v.name:match("tactical_crossbow") then
								model2.CFrame *= CFrame.new(-.5, 0, .05)
							elseif v.name:match("tactical_crossbow") and not v.name:match("wood_crossbow") then
								model2.CFrame *= CFrame.new(-.35, 0, -1.2)
							else
								model2.CFrame *= CFrame.new(.2, 0, -.24)
							end
							model2.Parent = tool2
							local weld2 = Instance.new("WeldConstraint", model)
							weld2.Part0 = model2
							weld2.Part1 = tool2:WaitForChild("Handle")
						end
					end
				end
           end)
		end,
        RandomPack = function() 
            task.spawn(function()  
				local Players = game:GetService("Players")
				local ReplicatedStorage = game:GetService("ReplicatedStorage")
				local Workspace = game:GetService("Workspace")
				local objs = game:GetObjects("rbxassetid://14282106674")
				local import = objs[1]
				import.Parent = game:GetService("ReplicatedStorage")
				index = {
					{
						name = "wood_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(-89),math.rad(-90)),
						model = import:WaitForChild("Wood_Sword"),
					},
					{
						name = "stone_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(-89),math.rad(-90)),
						model = import:WaitForChild("Stone_Sword"),
					},
					{
						name = "iron_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(-89),math.rad(-90)),
						model = import:WaitForChild("Iron_Sword"),
					},
					{
						name = "diamond_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(-89),math.rad(-90)),
						model = import:WaitForChild("Diamond_Sword"),
					},
					{
						name = "emerald_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(-89),math.rad(-90)),
						model = import:WaitForChild("Emerald_Sword"),
					},
				}
				toolFunction = function(tool)
					if(not tool:IsA("Accessory")) then return end
					for i,v in pairs(index) do
						if(v.name == tool.Name) then
							for i,v in pairs(tool:GetDescendants()) do
								if(v:IsA("Part") or v:IsA("MeshPart") or v:IsA("UnionOperation")) then
									v.Transparency = 1
								end
							end
							local model = v.model:Clone()
							model.CFrame = tool:WaitForChild("Handle").CFrame * v.offset
							model.CFrame *= CFrame.Angles(math.rad(0),math.rad(-50),math.rad(0))
							model.Parent = tool
							local weld = Instance.new("WeldConstraint",model)
							weld.Part0 = model
							weld.Part1 = tool:WaitForChild("Handle")
							local tool2 = Players.LocalPlayer.Character:WaitForChild(tool.Name)
							for i,v in pairs(tool2:GetDescendants()) do
								if(v:IsA("Part") or v:IsA("MeshPart") or v:IsA("UnionOperation")) then
									v.Transparency = 1
								end            
							end            
							local model2 = v.model:Clone()
							model2.Anchored = false
							model2.CFrame = tool2:WaitForChild("Handle").CFrame * v.offset
							model2.CFrame *= CFrame.Angles(math.rad(0),math.rad(-50),math.rad(0))
							model2.CFrame *= CFrame.new(0.6,0,-.9)
							model2.Parent = tool2
							local weld2 = Instance.new("WeldConstraint",model)
							weld2.Part0 = model2
							weld2.Part1 = tool2:WaitForChild("Handle")
						end
					end
				end  
           end)
		end,
		SecondHighResPack = function() 
            task.spawn(function()
				local Players = game:GetService("Players")
				local ReplicatedStorage = game:GetService("ReplicatedStorage")
				local Workspace = game:GetService("Workspace")
				local objs = game:GetObjects("rbxassetid://14078540433")
				local import = objs[1]
				import.Parent = game:GetService("ReplicatedStorage")
				index = {
					{
						name = "wood_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(-100),math.rad(-90)),
						model = import:WaitForChild("Wood_Sword"),
					},
					{
						name = "stone_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(-100),math.rad(-90)),
						model = import:WaitForChild("Stone_Sword"),
					},
					{
						name = "iron_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(-100),math.rad(-90)),
						model = import:WaitForChild("Iron_Sword"),
					},
					{
						name = "diamond_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(-100),math.rad(-90)),
						model = import:WaitForChild("Diamond_Sword"),
					},
					{
						name = "emerald_sword",
						offset = CFrame.Angles(math.rad(0),math.rad(-100),math.rad(-90)),
						model = import:WaitForChild("Emerald_Sword"),
					},
					{
						name = "rageblade",
						offset = CFrame.Angles(math.rad(0),math.rad(-90),math.rad(90)),
						model = import:WaitForChild("Rageblade"),
					}, 
				}
				toolFunction = function(tool)
					if(not tool:IsA("Accessory")) then return end
					for i,v in pairs(index) do
						if(v.name == tool.Name) then
							for i,v in pairs(tool:GetDescendants()) do
								if(v:IsA("Part") or v:IsA("MeshPart") or v:IsA("UnionOperation")) then
									v.Transparency = 1
								end
							end
							local model = v.model:Clone()
							model.CFrame = tool:WaitForChild("Handle").CFrame * v.offset
							model.CFrame *= CFrame.Angles(math.rad(0),math.rad(-50),math.rad(0))
							model.Parent = tool
							local weld = Instance.new("WeldConstraint",model)
							weld.Part0 = model
							weld.Part1 = tool:WaitForChild("Handle")
							local tool2 = Players.LocalPlayer.Character:WaitForChild(tool.Name)
							for i,v in pairs(tool2:GetDescendants()) do
								if(v:IsA("Part") or v:IsA("MeshPart") or v:IsA("UnionOperation")) then
									v.Transparency = 1
								end
							end
							local model2 = v.model:Clone()
							model2.Anchored = false
							model2.CFrame = tool2:WaitForChild("Handle").CFrame * v.offset
							model2.CFrame *= CFrame.Angles(math.rad(0),math.rad(-50),math.rad(0))
							model2.CFrame *= CFrame.new(.5,0,-.8)
							model2.Parent = tool2
							local weld2 = Instance.new("WeldConstraint",model)
							weld2.Part0 = model2
							weld2.Part1 = tool2:WaitForChild("Handle")
						end
					end
				end
           end)
		end
	}

	if (not TexturePacks.Enabled) then toolFunction = function() end end

	local function refresh()
		pcall(function() con:Disconnect() end)
		con = game:GetService("Workspace"):WaitForChild("Camera").Viewmodel.ChildAdded:Connect(toolFunction)
		for i,v in pairs(game:GetService("Workspace"):WaitForChild("Camera").Viewmodel:GetChildren()) do toolFunction(v) end
	end

	TexturePacks = vape.Categories.Render:CreateModule({
		["Name"] = "TexturePacks",
		["Function"] = function(callback) 
			if callback then 
				packfunctions[packselected["Value"]]()
				refresh()
            else 
				toolFunction = function() end
				refresh()
		end
	end
	})
	local list = {}
	for i,v in pairs(packfunctions) do table.insert(list, tostring(i)) end
	packselected = TexturePacks:CreateDropdown({
		Name = "Pack",
		Function = function() if TexturePacks.Enabled then packfunctions[packselected["Value"]](); refresh() end end,
		List = list
	})
end)

run(function()
	local BCR
	local Value
	local old
	local inf = math.huge or 9e9
	BCR = vape.Categories.Blatant:CreateModule({
		Name = "BlockCPSRemover",
		Function = function(callback) 
			if callback then
				old = bedwars.SharedConstants.CpsConstants['BLOCK_PLACE_CPS']
				task.spawn(function()
					while BCR.Enabled do
						bedwars.SharedConstants.CpsConstants['BLOCK_PLACE_CPS'] = Value.Value == 0 and inf or Value.Value
						task.wait(0.1)
					end
				end)
			else
				bedwars.SharedConstants.CpsConstants['BLOCK_PLACE_CPS'] = 12
				old = nil
			end
		end
	})
	Value = BCR:CreateSlider({
		Name = "CPS",
		Suffix = "s",
		Tooltip = "Changes the limit to the CPS cap(0 = remove)",
		Default = 0,
		Min = 0,
		Max = 100,
		Function = function()
			bedwars.SharedConstants.CpsConstants['BLOCK_PLACE_CPS'] = Value.Value == 0 and inf or Value.Value
		end,
	})
end)


if getgenv().TestMode then	
	warn("loaded test mode!")
else
end
