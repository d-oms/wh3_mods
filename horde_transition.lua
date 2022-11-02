function local_out(message)
    out("horde_transition\t" .. tostring(message))
end

--------------------------------------------------

ship_buildings = {}

core:add_listener(
    "horde_converter_FirstTickAfterWorldCreated",
    "FirstTickAfterWorldCreated",
    true,
    function(context)
        local_out("FirstTickAfterWorldCreated event triggered")
        local_out("Starting campaign setup")
        for key, value in pairs(ship_buildings) do
            local character = cm:get_character_by_cqi(key)
			
			if character ~= false then
				local military_force = character:military_force()
    
				if character:is_at_sea() and not character:has_garrison_residence() then
					local_out("character cqi [" .. key .. "] is_at_sea, converting to SEA_LOCKED_HORDE")
					cm:convert_force_to_type(military_force, "SEA_LOCKED_HORDE");
					force_type = military_force:force_type():key()
					local_out("military_force converted to [" .. force_type .. "]")
					rebuild_ship_buildings(character)
				else
					local_out("character cqi [" .. key .. "] NOT is_at_sea, passing")
				end

            
                local_out("Loading buildings for character cqi [" .. key .. "]")
                rebuild_ship_buildings(character)
            else
				local_out("character cqi [" .. key .. "] does not exist! Check this")
			end
        end
        local_out("Ending campaign setup")
    end,
    false
);

function rebuild_ship_buildings(character)
    local subtype = character:character_subtype_key();  
    local cqi = character:command_queue_index()
    
    if ship_buildings[tostring(cqi)] == nil then
        local_out("No record of character cqi [" .. cqi .. "], generating")
        ship_buildings[tostring(cqi)] = {}
    else
        out("Adding buildings for character cqi [" .. cqi .. "]: ")
        for key, value in pairs(ship_buildings[tostring(cqi)]) do
            out("\t" .. key)
            cm:add_building_to_force(character:military_force():command_queue_index(), key)
        end   
    end
end

function horde_transition()
    core:add_listener(
        "horde_converter_CharacterEntersGarrison",
        "CharacterEntersGarrison",
        function(context)
            return context:character():military_force():force_type():key() == "SEA_LOCKED_HORDE"
        end,
        function(context)
            local_out("CharacterEntersGarrison event triggered")
            military_force = context:character():military_force()
    
            -- SEA_LOCKED_HORDE -> CHARACTER_BOUND_HORDE
            force_type = military_force:force_type():key()
            local_out("force_type == [" .. force_type .. "]")
        
            if force_type == "SEA_LOCKED_HORDE" then
                local_out("[" .. force_type .. "] detected, converting to CHARACTER_BOUND_HORDE")
                cm:convert_force_to_type(military_force, "CHARACTER_BOUND_HORDE");
                force_type = military_force:force_type():key()
                local_out("military_force converted to [" .. force_type .. "]")
                rebuild_ship_buildings(context:character())
            else
                local_out("[" .. force_type .. "] detected, passing")
            end
        end,
        true
    );
    
    core:add_listener(
        "horde_converter_CharacterLeavesGarrison",
        "CharacterLeavesGarrison",
        function(context)
            return context:character():military_force():force_type():key() == "CHARACTER_BOUND_HORDE"
        end,
        function(context)
            local_out("CharacterLeavesGarrison event triggered")
            character = context:character()
            military_force = character:military_force()
    
            -- CHARACTER_BOUND_HORDE -> SEA_LOCKED_HORDE
            force_type = military_force:force_type():key()
            local_out("force_type == [" .. force_type .. "]")
            
            if force_type == "CHARACTER_BOUND_HORDE" then
                local_out("[" .. force_type .. "] detected, checking if character is_at_sea")
                if character:is_at_sea() then
                    local_out("character is_at_sea, converting to SEA_LOCKED_HORDE")
                    cm:convert_force_to_type(military_force, "SEA_LOCKED_HORDE");
                    force_type = military_force:force_type():key()
                    local_out("military_force converted to [" .. force_type .. "]")
                    rebuild_ship_buildings(context:character())
                else
                    local_out("character NOT is_at_sea, passing")
                end
            else
                local_out("[" .. force_type .. "] detected, passing")
            end
        end,
        true
    );
    
    core:add_listener(
	"horde_converter_MilitaryForceBuildingCompleteEvent",
	"MilitaryForceBuildingCompleteEvent",
	true,
	function(context) 
            local_out("MilitaryForceBuildingCompleteEvent event triggered")
            if context:character():is_null_interface() == false then
                local_out("character NOT is_null_interface, inserting record")
                local subtype = context:character():character_subtype_key();
                local cqi = context:character():command_queue_index()
                local building_key = context:building()
		
                if ship_buildings[tostring(cqi)] == nil then
                    local_out("No record of character [" .. cqi .. "], generating")
                    ship_buildings[tostring(cqi)] = {}
                end
        
                local_out("Inserting building record [" .. building_key .."] for character cqi [" .. cqi .. "]")
                ship_buildings[tostring(cqi)][building_key] = 1
        
                local_out("current table for character cqi [" .. cqi .. "]: ")
                for key, value in pairs(ship_buildings[tostring(cqi)]) do
                    local_out("\t" .. value)
                end
            else
                local_out("character is_null_interface, passing")
            end
        end,
		true
	);
    
    core:add_listener( 
        "horde_converter_UnitTrained",
        "UnitTrained",
        function(context)
			if context:unit():has_force_commander() then
                local_out("testing : " ..tostring(context:unit():force_commander():command_queue_index()))
				return ship_buildings[tostring(context:unit():force_commander():command_queue_index())] ~= nil
            end
        end,
        function(context)
            local_out("UnitCreated event triggered")
            rebuild_ship_buildings(context:unit():force_commander())
        end,
        true
    );
end

cm:add_saving_game_callback(
    function(context)
        cm:save_named_value("ship_buildings", ship_buildings, context);
        local_out("Saving the following character cqis")
        for key in pairs(ship_buildings) do
            local_out("\t[" .. key .."]")
        end
    end
);

cm:add_loading_game_callback(
    function(context)
        ship_buildings = cm:load_named_value("ship_buildings", ship_buildings, context);
        local_out("Loading the following character cqis")
        for key in pairs(ship_buildings) do
            local_out("\t[" .. key .. "]")
        end
    end
);
