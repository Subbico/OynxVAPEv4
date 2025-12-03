local annc = {} -- FINISHED UI, TIME TO CODE THE MAIN THING

local vape = shared.vape
local function create(name, props)
    local obj = Instance.new(name)
    for i, v in pairs(props) do
        obj[i] = v
    end
    return obj
end

local NAMEOFSTUFF = "("..game:GetService("HttpService"):GenerateGUID(false).."||"..string.upper(game:GetService("HttpService"):GenerateGUID(true))..")"
local gethui = gethui or function() 
	return game:GetService('Players').LocalPlayer.PlayerGui 
end

function annc:CreateAnnc(msg,ticker,settings)
	local gui = create("ScreenGui", {Name = NAMEOFSTUFF,Parent = gethui(),IgnoreGuiInset = true,ResetOnSpawn = false,DisplayOrder = math.huge})
	NAMEOFSTUFF = "("..game:GetService("HttpService"):GenerateGUID(false).."||"..string.upper(game:GetService("HttpService"):GenerateGUID(true))..")"
	local frame = create("Frame", {Name = NAMEOFSTUFF,Parent = gui,BackgroundTransparency = 1,Position = UDim2.fromScale(0,0),Size = UDim2.fromScale(1,1)})
	NAMEOFSTUFF = "("..game:GetService("HttpService"):GenerateGUID(false).."||"..string.upper(game:GetService("HttpService"):GenerateGUID(true))..")"
	local text = create("TextLabel", {Name = NAMEOFSTUFF,Parent = frame,BackgroundTransparency = 1,Position = UDim2.fromScale(0,-1.5),Size = UDim2.fromScale(1,0.15),TextScaled = true,FontFace = Font.fromEnum(Enum.Font.Arimo, Enum.FontWeight.Bold),TextColor3 = Color3.new(1,1,1),Text = ""})
	local info = TweenInfo.new(1.5,Enum.EasingStyle.Sine)
	local tween = game:GetService("TweenService"):Create(text, info, {Position = UDim2.fromScale(0,0)})
	tween:Play()
	
	task.spawn(function()
		tween.Completed:Connect(function()
			task.wait(0.2)
			tween:Destroy()
		end)
	end)


    text.Text = "From:"..vape.user.." | "..msg
	task.spawn(function()
		local tween2 = game:GetService("TweenService"):Create(text, info, {Position = UDim2.fromScale(0,-1.5)})

		task.spawn(function()
			tween2.Completed:Connect(function()
				task.wait(0.2)
				tween2:Destroy()
				game:GetService("Debris"):AddItem(gui,0.05)
			end)
		end)
		task.wait(ticker)
		tween2:Play()
	end)
    if settings.Rainbow then
        task.spawn(function()
        	while gui do
        		for h = 0, 1, 0.002 do
        			text.TextColor3 = Color3.fromHSV(h, 1, 1)
        			text.TextTransparency = math.abs(math.sin(tick() * 2)) * 0.3
        			task.wait()
        		end
        	end
        end)
    elseif settings.Flip then
        task.spawn(function()
        	while settings.Flip.HMR > 0 or gui do
        		for angle = 0, 360 do
        			text.Rotation = angle
        			task.wait(0.01)
        		end
        		settings.Flip.HMR -= 1
        	end
        	text.Rotation = 0
    end)
    elseif settings.Flip and settings.Rainbow then
      task.spawn(function()
        	while gui do
        		for h = 0, 1, 0.002 do
        			text.TextColor3 = Color3.fromHSV(h, 1, 1)
        			text.TextTransparency = math.abs(math.sin(tick() * 2)) * 0.3
        			task.wait()
        		end
        	end
        end)
        task.spawn(function()
        	while settings.Flip.HMR > 0 or gui do
        		for angle = 0, 360 do
        			text.Rotation = angle
        			task.wait(0.01)
        		end
        		settings.Flip.HMR -= 1
        	end
        	text.Rotation = 0
        end)
    end
end

function annc:Announce(stats)
    local type = stats.TYPE or "notify"
    local msg = stats.Message or "nigga no message"
    local title = stats.Title or "Onyx"
    local Timer = stats.Time or 6
    local stings = stats.Setting or 'info'
    if type == "notify" then
        vape:CreateNotification(title,msg,Timer,stings)
    else
        annc:CreateAnnc(msg,Timer,stings)
    end
end

return annc
