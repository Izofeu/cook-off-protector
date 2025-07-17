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

-- Setup global namespace
cookoffprotector = cookoffprotector or {}
cookoffprotector.modpath = ModPath
-- List of forbidden equipment
local forbidden_equipment = {
	caustic_soda = true,
	acid = true,
	hydrogen_chloride = true
}
-- Path to config
cookoffprotector.configpath = "mods/saves/cookoffprotector.txt"

function cookoffprotector.saveconfig(config)
	io.save_as_json(config, cookoffprotector.configpath)
end

function cookoffprotector.loadconfig()
	if io.file_is_readable(cookoffprotector.configpath) then
		local config = io.load_as_json(cookoffprotector.configpath)
		return config
	else
		-- No config file, create one
		local defaultconfig = {
			autokick = false,
			disallow_pickups = true,
			debugvar = false,
		}
		io.save_as_json(defaultconfig, cookoffprotector.configpath)
		return defaultconfig
	end
end
-- Load the config file
cookoffprotector.config = cookoffprotector.loadconfig()

-- Save the old function to call it later
local old_on_executed = ElementEquipment.on_executed

function cookoffprotector.getpeer(instigator)
	return managers.network:session():peer_by_unit(instigator)
end

function cookoffprotector.pass()
	return
end

-- Override on mission equipment pickup function
function ElementEquipment:on_executed(instigator)
	-- If we are the host, run original logic only
	if not Network:is_server() then
		old_on_executed(self, instigator)
		return
	end
	if not self._values.enabled then
		return
	end
	if self._values.equipment ~= "none" then
		local name = self._values.equipment
		local amount = self._values.amount
		local peer = nil
		-- Obtain who picked up the item
		local status, value = pcall(cookoffprotector.getpeer, instigator)
		if status then
			peer = value
		else
			old_on_executed(self, instigator)
			return
		end
		-- Check if the pick up player is the host
		if not peer:is_host() or cookoffprotector.config.debugvar then
			if forbidden_equipment[name] then
				-- Send a message about picking up a cooking ingredient
				managers.chat:send_message(ChatManager.GAME, managers.network:session():local_peer(), peer:name() .. " picked up a cooking ingredient: " .. tostring(name))
				if cookoffprotector.config.disallow_pickups or cookoffprotector.config.autokick then
					-- If pickups are disallowed, add the picked up item to host and ignore the pickup
					managers.player:add_special({transfer = true, name = name, amount = amount, silent = false})
					if cookoffprotector.config.autokick then
						-- Kick player if autokick is enabled
						managers.network:session():send_to_peers("kick_peer", peer:id(), 1)
						managers.network:session():on_peer_kicked(peer, peer:id(), 1)
					end
					return
				end
			--else
			--	managers.chat:send_message(ChatManager.GAME, managers.network:session():local_peer(), peer:name() .. " picked up an allowed item: " .. tostring(name))
			end
		end
	end
	-- Execute the pickup item logic if conditions weren't met
	old_on_executed(self, instigator)
end

Hooks:Add("NetworkManagerOnPeerAdded", "on_peer_added", function(peer, peer_id)
	if not Network:is_server() then
		return
	end
	-- Send a welcome message notifying joining players of the presence of the mod
	DelayedCalls:Add("CookOffProtectorJoinMsg" .. tostring(peer_id), 5, function()
		local message = "This lobby is running a Cook Off Protector mod - picking up meth ingredients is punishable!"
		if cookoffprotector.config.autokick then
			message = message .. " Autokick is ENABLED."
		end
		-- Check if peer is still here
		peer = managers.network:session() and managers.network:session():peer(peer_id)
		if peer and cookoffprotector.config.disallow_pickups then
			-- Send a message if disallowing pickups is enabled
			peer:send("send_chat_message", ChatManager.GAME, message)
		end
	end)
end)