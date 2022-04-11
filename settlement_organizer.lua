function organizer_out(message)
    out("settlement_organizer\t" .. tostring(message))
end

start_building = nil
start_slot = nil
start_region = nil
start_uic = nil
end_building = nil
end_slot = nil
end_region = nil
end_uic = nil

-- inverse of find_child_uicomponent that allows us to find a 
-- parent, from a provided string, based on a child object
function find_parent_uicomponent(uic_child, name)
    local uic_parent = UIComponent(uic_child:Parent())
    
    if uic_parent:Id() == nil then
		-- not found
		return nil;
    elseif string.find(uic_parent:Id(), name) ~= nil then
		-- found
		return uic_parent
	else
		-- recurse
        return find_parent_uicomponent(uic_parent, name)
	end
end;

function sanitize_globals()
    organizer_out("sanitizing global variables")
        
    if start_building ~= nil then
        start_uic:Highlight(false, true, 0)
        start_building = nil
    end

    start_slot = nil
    start_region = nil
    start_uic = nil
    end_building = nil
    end_slot = nil
    end_region = nil
    end_uic = nil
end

-- settlement selected
core:add_listener(
    "settlement_organizer_ComponentLClickUp",
    "ComponentLClickUp",
    function(context)
        local uic_context_name = UIComponent(context.component):Id()
        organizer_out("checking uic_context_name [" .. uic_context_name .. "]")
		return uic_context_name == "default_view" or uic_context_name == "square_building_button" or uic_context_name == "button_expand_slot"
    end,
    function(context) 
        local uic_context = UIComponent(context.component)
        -- unowned slot selected
        if uic_context:Id() == "default_view" then
            organizer_out("unowned slot selected")
            sanitize_globals()
        -- owned/empty slot selected
        else
            organizer_out("owned/empty slot selected")

            -- get the slot
            -- CcoCampaignBuildingSlot<REGION_SLOT> <-- slot_entry <-- square_building_button
            local uic_slot = find_parent_uicomponent(uic_context, "CcoCampaignBuildingSlot")
            local uic_slot_name = string.gsub(uic_slot:Id(), "CcoCampaignBuildingSlot", "") 
            local slot_id = common.get_context_value("CcoCampaignBuildingSlot", uic_slot_name, "Index")

            -- get the region
            -- CcoCampaignSettlement<REGION_NAME> <-- settlement_view <-- default_view <-- default_slots_list <-- CcoCampaignBuildingSlot<REGION_SLOT>
            local uic_region = find_parent_uicomponent(uic_context, "CcoCampaignSettlement")
            local uic_region_name = string.gsub(uic_region:Id(), "CcoCampaignSettlement", "")

            -- get script interfaces
            region = cm:get_region(uic_region_name)
            local slot = region:slot_list():item_at(slot_id)
            local building_name
            if region:slot_list():item_at(slot_id):has_building() then
                building_name = region:slot_list():item_at(slot_id):building():name()
            else
                building_name = "none"
            end

            -- get construction status
            local isActive_flag = common.get_context_value("CcoCampaignBuildingSlot", uic_slot_name, "IsActive")
            local isUpgrading_flag = common.get_context_value("CcoCampaignBuildingSlot", uic_slot_name, "IsUpgrading")
            local canRepair_flag = common.get_context_value("CcoCampaignBuildingSlot", uic_slot_name, "CanRepair")
            local isRepairing_flag = common.get_context_value("CcoCampaignBuildingSlot", uic_slot_name, "IsRepairing")
            local isBuildingNew_flag = common.get_context_value("CcoCampaignBuildingSlot", uic_slot_name, "IsBuildingNew")
            local isConverting_flag = common.get_context_value("CcoCampaignBuildingSlot", uic_slot_name, "IsConverting")
            local isDismantling_flag = common.get_context_value("CcoCampaignBuildingSlot", uic_slot_name, "IsDismantling")
            local isNotNewConstruction_flag = find_parent_uicomponent(uic_context, "construction_building_tree")

            organizer_out("selected building [" .. building_name .. "] in slot [" .. slot_id .. "] in region [" .. uic_region_name .. "] with flags:")
            organizer_out("\tisActive_flag [" .. tostring(isActive_flag) .. "]")
            organizer_out("\tcanRepair_flag [" .. tostring(canRepair_flag) .. "]")
            organizer_out("\tisUpgrading_flag [" .. tostring(isUpgrading_flag) .. "]")
            organizer_out("\tisRepairing_flag [" .. tostring(isRepairing_flag) .. "]")
            organizer_out("\tisBuildingNew_flag [" .. tostring(isBuildingNew_flag) .. "]")
            organizer_out("\tisConverting_flag [" .. tostring(isConverting_flag) .. "]")
            organizer_out("\tisDismantling_flag [" .. tostring(isDismantling_flag) .. "]")
            organizer_out("\tisNotNewConstruction_flag [" .. tostring(isNotNewConstruction_flag == nil) .. "]")

            -- if we clicked any slot with a pending construction queue, then cancel
            -- the move
            if isActive_flag and not isUpgrading_flag and not canRepair_flag and not isRepairing_flag and not isBuildingNew_flag and not isConverting_flag and not isDismantling_flag and isNotNewConstruction_flag == nil then
                -- if we re-clicked the same building, clicked a settlement building,
                -- or we clicked a port, then cancel the move
                if building_name == region:settlement():primary_slot():building():name() then
                    organizer_out("primary building selected, this is invalid")
                    sanitize_globals()
                elseif region:settlement():is_port() and building_name == region:settlement():port_slot():building():name() then
                    organizer_out("port building selected, this is invalid")
                    sanitize_globals()
                elseif start_building == nil and start_slot == nil and start_uic == nil and start_region == nil then
                    start_building = building_name
                    start_slot = slot
                    start_uic = uic_slot
                    start_uic:Highlight(true, true, 0)

                    organizer_out("valid start building selected")
                elseif end_building == nil and end_slot == nil and end_uic == nil and end_region == nil then
                    end_building = building_name
                    end_slot = slot
                    
                    organizer_out("valid end building selected") 
                    -- make sure we are moving buildings in the same region
                    if start_slot:region():name() == end_slot:region():name() then
                        -- prevent building demolition notification
                        cm:disable_event_feed_events(true, "","","provinces_building_demolished")

                        -- function call causes player to receive income from demolishing, so we
                        -- measure treasury value pre-/post-demolish, and adjust accordingly
                        local faction = cm:get_local_faction()
                        local pre_gold = faction:treasury()

                        -- Kislev specifically uses devotion pooled_resource for some building
                        -- construction, so creating a one-off check to account for them for now
                        local pre_resource
                        if faction:subculture() == "wh3_main_pro_sc_ksl_kislev" or faction:subculture() == "wh3_main_sc_ksl_kislev" then
                            pre_resource = faction:pooled_resource_manager():resource("wh3_main_ksl_devotion"):value()
                        end

                        -- do the demolition
                        cm:region_slot_instantly_dismantle_building(start_slot)                            
                        cm:region_slot_instantly_dismantle_building(end_slot)

                        -- do the construction
                        cm:region_slot_instantly_upgrade_building(start_slot, end_building)
                        cm:region_slot_instantly_upgrade_building(end_slot, start_building)

                        -- do the pooled_resource adjustment
                        local post_resource
                        local diff_resource
                        if faction:subculture() == "wh3_main_pro_sc_ksl_kislev" or faction:subculture() == "wh3_main_sc_ksl_kislev" then
                            post_resource = faction:pooled_resource_manager():resource("wh3_main_ksl_devotion"):value()
                            diff_resource = tonumber(pre_resource) - tonumber(post_resource)
                            cm:faction_add_pooled_resource(faction:name(), "wh3_main_ksl_devotion", "building_construction", diff_resource)
                        end

                        -- do the gold adjustment
                        local post_gold = faction:treasury()
                        local diff_gold = tonumber(pre_gold) - tonumber(post_gold)
                        cm:treasury_mod(faction:name(), diff_gold)

                        -- re-enable building demolition notification
                        cm:disable_event_feed_events(false, "","","provinces_building_demolished")
                    end
                    sanitize_globals()
                end
            else
                organizer_out("invalid building selected") 
                sanitize_globals()
            end
        end
    end,
    true
);
      
-- settlement de-selected
core:add_listener(
    "settlement_organizer_PanelClosedCampaign",
    "PanelClosedCampaign",
    function(context)
        return context.string == "settlement_panel";
    end,
    function(context) 
        organizer_out("PanelClosedCampaign triggered")
        sanitize_globals()
    end,
    true
);
