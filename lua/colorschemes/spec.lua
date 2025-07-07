local M = {}

M.default_spec = {
	colorschemes = {}, ---@type string[]
	activate = function(name)
		vim.cmd.colorscheme(name)
	end,
	deactivate = function(name) end,
}

local check_colorscheme_spec = function(spec)
	if type(spec) ~= "table" then
		error("Colorscheme spec must be a table")
	end
	if not spec.colorschemes or type(spec.colorschemes) ~= "table" then
		error("Colorscheme spec must have a 'colorschemes' table")
	end
	for _, name in ipairs(spec.colorschemes) do
		if type(name) ~= "string" then
			error("Each colorscheme name must be a string in colorscheme spec")
		end
	end
	if spec.activate and type(spec.activate) ~= "function" then
		error("'activate' must be a function in colorscheme spec")
	end
	if spec.deactivate and type(spec.deactivate) ~= "function" then
		error("'deactivate' must be a function in colorscheme spec")
	end
end

M.check_colorscheme_specs = function(specs)
	if type(specs) ~= "table" then
		error("Colorscheme specs must be a table")
	end
	local map = {}
	for _, spec in ipairs(specs) do
		check_colorscheme_spec(spec)
		for _, name in ipairs(spec.colorschemes) do
			if map[name] then
				error("Duplicate colorscheme name: " .. name)
			end
			map[name] = true
		end
	end
end

return M
