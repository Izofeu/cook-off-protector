-- Cook Off Protector - An anti-griefing PAYDAY2 mod created to combat trolls on meth cooking heists.
-- Copyright (C) 2025 - Izofeu

-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.

-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.

-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.

-- Initialize English names for menu items
Hooks:Add("LocalizationManagerPostInit", "cookoffprotector_localization", function( loc )
	loc:load_localization_file(cookoffprotector.modpath .. "titles.txt", false)
end)

-- Initialize mod options
Hooks:Add("MenuManagerInitialize", "cookoffprotector_menu", function (menu_manager)
	-- Toggle disallow pickups
	MenuCallbackHandler.disallowpickupstoggle = function(self, item)
		local value = item:value() == "on"
		cookoffprotector.config.disallow_pickups = value
		cookoffprotector.saveconfig(cookoffprotector.config)
	end
	-- Toggle autokick
	MenuCallbackHandler.autokicktoggle = function(self, item)
		local value = item:value() == "on"
		cookoffprotector.config.autokick = value
		cookoffprotector.saveconfig(cookoffprotector.config)
	end
	-- Load the menu and the values from config
	MenuHelper:LoadFromJsonFile(cookoffprotector.modpath .. "menu/options.txt", MenuCallbackHandler, cookoffprotector.config)
	
end)