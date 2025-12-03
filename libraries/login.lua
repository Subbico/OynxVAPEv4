local login = {}
if not shared.vape then repeat task.wait() until shared.vape end

local vape = shared.vape
local http = game:GetService("HttpService")

local apiBase = "https://onyxclient.fsl58.workers.dev/"
local apiLogin = apiBase
local apiHWID = apiBase .. "hwid?user="

local username = ""
local password = ""

if getgenv().TestAccount then
    username = "GUEST"
    password = "PASSWORD"
else
    username = getgenv().username or "GUEST"
    password = getgenv().password or "PASSWORD"
end


local function fetchServerHWID(user)
    if not user or user:lower() == "guest" then
        return "GuestHWID"
    end
    local ok, res = pcall(function()
        return game:HttpGet(apiHWID .. user)
    end)

    if not ok then return nil end

    local decoded
    pcall(function() decoded = http:JSONDecode(res) end)

    if decoded and decoded.hwid then
        return decoded.hwid
    end

    return nil
end


local function postLogin(u, p)
    local req = request or http_request or syn.request
    if not req then return nil end

    return req({
        Url = apiLogin,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = http:JSONEncode({
            username = u,
            password = p
        })
    })
end



function login:Login()
    local role, U, P = "guest", "GUEST", "PASSWORD"

    local ok = pcall(function()
        local req = postLogin(username, password)

        if not req or req.StatusCode ~= 200 then
            vape:CreateNotification("Onyx", "API Unreachable. Guest mode.", 7,'warning')
            return
        end

        local decoded
        pcall(function() decoded = http:JSONDecode(req.Body) end)
        if not decoded then
            vape:CreateNotification("Onyx", "Bad login response. Guest mode.", 7,'warning')
            return
        end

        local serverHWID = fetchServerHWID(username)

        if not serverHWID then
            vape:CreateNotification("Onyx", "Account missing HWID. Using Guest.", 7,'warning')
            return
        end
        if serverHWID == "GuestHWID" then
            return
        end
        role = decoded.role or "guest"
        U = username
        P = password

        vape:CreateNotification("Onyx", "Logged in as "..U.." ("..role..")", 7)
    end)

    return role, U, P
end



function login:SlientLogin()
    local role, U, P = "guest", "GUEST", "PASSWORD"

    pcall(function()
        local req = postLogin(username, password)
        if not req or req.StatusCode ~= 200 then
            vape:CreateNotification("Onyx", "API Unreachable. Guest mode.", 7,'warning')
            return
        end

        local decoded
        pcall(function() decoded = http:JSONDecode(req.Body) end)
        if not decoded then
            vape:CreateNotification("Onyx", "Bad login response. Guest mode.", 7,'warning')
            return
        end

        local serverHWID = fetchServerHWID(username)

        if not serverHWID then
            vape:CreateNotification("Onyx", "Account missing HWID. Using Guest.", 7,'warning')
            return
        end
        if serverHWID == "GuestHWID" then
            return
        end
        role = decoded.role or "guest"
        U = username
        P = password
    end)

    return role, U, P
end

return login
