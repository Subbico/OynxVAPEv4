local accountinfo = {}

local ARGS = ... or {}
if ARGS.Refresh then
	delfolder('ReVape')
end

if getgenv().username  and next(ARGS) == nil then
	ARGS.username = getgenv().username
	ARGS.password = getgenv().password
end
if typeof(ARGS) ~= "table" then
	getgenv().username = 'GUEST' 
	getgenv().password = 'PASSWORD' 
end
getgenv().username = ARGS.username
getgenv().password = ARGS.password
getgenv().TestMode = ARGS.TestMode or false

local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)
	return suc and res ~= nil and res ~= ''
end
local delfile = delfile or function(file)
	writefile(file, '')
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

local function wipeFolder(path)
	if not isfolder(path) then return end
	for _, file in listfiles(path) do
		if file:find('loader') then continue end
		if isfile(file) and select(1, readfile(file):find('--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.')) == 1 then
			delfile(file)
		end
	end
end
if not isfile("ReVape/profiles/theme.txt") then
	writefile('ReVape/profiles/theme.txt', 'Dark')
end
for _, folder in {'ReVape', 'ReVape/games', 'ReVape/profiles', 'ReVape/assets', 'ReVape/libraries', 'ReVape/guis', 'ReVape/sounds', 'ReVape/sounds/1oneam', 'ReVape/sounds/boolymon', 'ReVape/sounds/killjae', 'ReVape/sounds/xtrovert'} do
	if not isfolder(folder) then
		makefolder(folder)
	end
end

if not shared.VapeDeveloper then
	local _, subbed = pcall(function()
		return game:HttpGet('https://github.com/soryed/OynxVAPEv4')
	end)
	local commit = subbed:find('currentOid')
	commit = commit and subbed:sub(commit + 13, commit + 52) or nil
	commit = commit and #commit == 40 and commit or 'main'
	if commit == 'main' or (isfile('ReVape/profiles/commit.txt') and readfile('ReVape/profiles/commit.txt') or '') ~= commit then
		wipeFolder('ReVape')
		wipeFolder('ReVape/games')
		wipeFolder('ReVape/guis')
		wipeFolder('ReVape/libraries')
	end
	writefile('ReVape/profiles/commit.txt', commit)
end

return loadstring(downloadFile('ReVape/main.lua'), 'main')()
