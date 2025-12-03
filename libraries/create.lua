local create = {}

function create:Create(name, props)
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

return create
