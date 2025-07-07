local Spec = require("colorschemes.spec")

local M = {}

local default_config = {
	default_colorscheme = false, ---@type string|boolean
	create_commands = false, ---@type boolean
}

M.config = default_config

local current = nil

local Error = function(msg, title)
	vim.notify(msg, vim.log.levels.ERROR, { title = title or "Colorscheme Error" })
end

local get_colorscheme_map = function()
	local specs = vim.g.colorscheme_specs or {}
	Spec.check_colorscheme_specs(specs)

	local colorscheme_map = {}
	for _, spec in ipairs(specs) do
		spec = vim.tbl_deep_extend("force", Spec.default_spec, spec)
		for _, name in ipairs(spec.colorschemes) do
			if colorscheme_map[name] then
				error("Duplicate colorscheme name: " .. name)
			end
			colorscheme_map[name] = {
				activate = spec.activate,
				deactivate = spec.deactivate,
			}
		end
	end
	return colorscheme_map
end

M.get_colorscheme_names = function()
	local colorscheme_map = get_colorscheme_map()
	local names = vim.tbl_keys(colorscheme_map)
	table.sort(names)
	return names
end

M.switch_to = function(name)
	if type(name) ~= "string" then
		Error("Colorscheme name must be a string")
		return
	end
	local map = get_colorscheme_map()
	if not map[name] then
		Error("Colorscheme '" .. name .. "' not found.")
		return
	end
	if current == name then
		return
	end
	if current then
		local ok, err = pcall(map[current].deactivate, current)
		if not ok then
			Error("Failed to deactivate colorscheme '" .. current .. "': " .. err)
			return
		end
	end
	local ok, err = pcall(map[name].activate, name)
	if not ok then
		Error("Failed to activate colorscheme '" .. name .. "': " .. err)
		return
	end
	current = name
end

M.get_current = function()
	return current and current or "none"
end

M.switch_to_default = function()
	if M.config.default_colorscheme then
		M.switch_to(M.config.default_colorscheme)
	else
		Error("No default colorscheme set.")
	end
end

local create_user_commands = function()
	vim.api.nvim_create_user_command("ColorschemeCurrent", function()
		local msg = "Current colorscheme: " .. M.get_current()
		vim.notify(msg, vim.log.levels.INFO, { title = "Current Colorscheme" })
	end, { nargs = 0 })

	vim.api.nvim_create_user_command("ColorschemeList", function()
		local names = M.get_colorscheme_names()
		vim.notify(
			"Available colorschemes: " .. table.concat(names, ", "),
			vim.log.levels.INFO,
			{ title = "Colorscheme List" }
		)
	end, { nargs = 0 })

	vim.api.nvim_create_user_command("ColorschemeSwitch", function(opts)
		local colorscheme = vim.split(opts.args, "%s+", { trimempty = true })[1]
		M.switch_to(colorscheme)
	end, {
		nargs = 1,
		complete = function(_, args)
			local parts = vim.split(args, "%s+", { trimempty = true })
			if args:sub(-1) == " " then
				parts[#parts + 1] = ""
			end
			if #parts < 3 then
				return vim.tbl_filter(function(key)
					return key:find(parts[2], 1, true) == 1
				end, M.get_colorscheme_names())
			end
		end,
	})

	vim.api.nvim_create_user_command("ColorschemeSwitchDefault", function()
		M.switch_to_default()
	end, { nargs = 0 })
end

M.setup = function(config)
	M.config = vim.tbl_deep_extend("force", default_config, config or {})
	if M.config.default_colorscheme then
		M.switch_to(M.config.default_colorscheme)
	end
	if M.config.create_commands then
		create_user_commands()
	end
end

return M
