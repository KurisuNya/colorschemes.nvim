local spec_module = require("colorschemes.spec")

local M = {}

---@class colorschemes.Config
M.config = {
	default_colorscheme = false, ---@type string|boolean
	create_commands = false, ---@type boolean
	specs = {}, ---@type Spec
}

local current = nil
local colorscheme_map = {}
local colorscheme_names = {}

local Error = function(msg, title)
	vim.notify(msg, vim.log.levels.ERROR, { title = title or "Colorscheme Error" })
end

M.get_current = function()
	return current and current or "none"
end

M.switch_to = function(name)
	if type(name) ~= "string" then
		Error("Colorscheme name must be a string")
		return
	end
	if not colorscheme_map[name] then
		Error("Colorscheme '" .. name .. "' not found.")
		return
	end
	if current == name then
		return
	end
	if current then
		local ok, err = pcall(colorscheme_map[current].deactivate)
		if not ok then
			Error("Failed to deactivate colorscheme '" .. current .. "': " .. err)
			return
		end
	end
	local ok, err = pcall(colorscheme_map[name].activate)
	if not ok then
		Error("Failed to activate colorscheme '" .. name .. "': " .. err)
		return
	end
	current = name
end

M.switch_to_default = function()
	if M.config.default_colorscheme then
		M.switch_to(M.config.default_colorscheme)
	else
		Error("No default colorscheme set.")
	end
end

local get_colorscheme_map = function(specs)
	spec_module.check_colorscheme_specs(specs)
	local map = {}
	for _, spec in ipairs(specs) do
		spec = vim.tbl_deep_extend("force", spec_module.default_spec, spec)
		for _, name in ipairs(spec.colorschemes) do
			map[name] = {
				activate = function()
					spec.activate(name)
				end,
				deactivate = function()
					spec.deactivate(name)
				end,
			}
		end
	end
	return map
end

local create_user_commands = function()
	vim.api.nvim_create_user_command("ColorschemeCurrent", function()
		local msg = "Current colorscheme: " .. M.get_current()
		vim.notify(msg, vim.log.levels.INFO, { title = "Current Colorscheme" })
	end, { nargs = 0 })

	vim.api.nvim_create_user_command("ColorschemeSwitch", function(opts)
		M.switch_to(vim.split(opts.args, "%s+", { trimempty = true })[1])
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
				end, colorscheme_names)
			end
		end,
	})

	vim.api.nvim_create_user_command("ColorschemeSwitchDefault", function()
		M.switch_to_default()
	end, { nargs = 0 })
end

---@param config colorschemes.Config
M.setup = function(config)
	M.config = vim.tbl_deep_extend("force", M.config, config or {})
	colorscheme_map = get_colorscheme_map(M.config.specs)
	colorscheme_names = vim.tbl_keys(colorscheme_map)
	table.sort(colorscheme_names)

	if M.config.default_colorscheme then
		M.switch_to_default()
	end
	if M.config.create_commands then
		create_user_commands()
	end
end
return M
