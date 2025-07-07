local Spec = require("colorschemes.spec")

local M = {}

local default_config = {
	default_colorscheme = false, ---@type string|boolean
	create_commands = false, ---@type boolean
	notice = true, ---@type boolean
}

M.config = default_config

local current = nil

local Info = function(msg, title)
	if M.config.notice then
		vim.notify(msg, vim.log.levels.INFO, { title = title or "Colorscheme Info" })
	end
end

local Error = function(msg, title)
	vim.notify(msg, vim.log.levels.ERROR, { title = title or "Colorscheme Error" })
end

local get_colorscheme_map = function()
	local specs = vim.g.colorscheme_specs or {}
	Spec.check_colorscheme_specs(specs)
	local wrapper = function(func, action)
		return function(name)
			local ok, err = pcall(func, name)
			if ok then
				return true
			end
			Error("Failed to " .. action .. " colorscheme '" .. name .. "': " .. err)
			return false
		end
	end

	local colorscheme_map = {}
	for _, spec in ipairs(specs) do
		spec = vim.tbl_deep_extend("force", Spec.default_spec, spec)
		for _, name in ipairs(spec.colorschemes) do
			if colorscheme_map[name] then
				error("Duplicate colorscheme name: " .. name)
			end
			colorscheme_map[name] = {
				activate = wrapper(spec.activate, "activate"),
				deactivate = wrapper(spec.deactivate, "deactivate"),
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
		Info("Already using colorscheme '" .. name .. "'")
		return
	end
	if current then
		if not map[current].deactivate(current) then
			return
		end
	end
	if not map[name].activate(name) then
		return
	end
	local msg = "Switched from '" .. (current or "none") .. "' to '" .. name .. "'"
	Info(msg, "Colorscheme Switched")
	current = name
end

M.setup = function(config)
	M.config = vim.tbl_deep_extend("force", default_config, config or {})
	if M.config.default_colorscheme then
		M.switch_to(M.config.default_colorscheme)
	end

	if not M.config.create_commands then
		return
	end

	vim.api.nvim_create_user_command("ColorschemeList", function()
		local names = M.get_colorscheme_names()
		Info("Available colorschemes: " .. table.concat(names, ", "), "Colorscheme List")
	end, { nargs = 0 })

	vim.api.nvim_create_user_command("ColorschemeSwitch", function(opts)
		local colorscheme = vim.split(opts.args, "%s+", { trimempty = true })[1]
		M.switch_to(colorscheme)
	end, {
		nargs = 1,
		complete = function(_, cmd_line)
			local params = vim.split(cmd_line, "%s+", { trimempty = true })
			if #params == 1 then
				return M.get_colorscheme_names()
			end
		end,
	})
end

return M
