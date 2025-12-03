local base = {}
base.Strings = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789`~!@#$%^&*()_-+=|>.<,/?[{}]"

local encodeMap = {}
local decodeMap = {}

for i = 1, #base.Strings do
    local c = base.Strings:sub(i,i)
    encodeMap[i-1] = c  
    decodeMap[c]    = i-1 
end

function base:Encode(str)
    local result = {}
    local buffer = 0
    local bits = 0
    for i = 1, #str do
        buffer = bit32.lshift(buffer, 8) + string.byte(str, i)
        bits = bits + 8
        while bits >= 6 do
            bits = bits - 6
            local index = bit32.rshift(buffer, bits)
            buffer = buffer - bit32.lshift(index, bits)
            result[#result+1] = encodeMap[index]
        end
    end
    if bits > 0 then
        local index = bit32.lshift(buffer, 6 - bits)
        result[#result+1] = encodeMap[index]
        result[#result+1] = "="
    end
    return table.concat(result)
end

function base:Decode(str)
    local result = {}
    local buffer = 0
    local bits = 0
    for i = 1, #str do
        local c = str:sub(i,i)
        if c == "=" then break end
        local val = decodeMap[c]
        if val then
            buffer = bit32.lshift(buffer, 6) + val
            bits = bits + 6
            while bits >= 8 do
                bits = bits - 8
                local byte = bit32.rshift(buffer, bits)
                buffer = buffer - bit32.lshift(byte, bits)
                result[#result+1] = string.char(byte)
            end
        end
    end
    return table.concat(result)
end

return base
