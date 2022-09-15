function mad_count_out(message)
    out("mad_count\t\t" .. tostring(message))
end

local marius_personality = {
	current = "",
	faction = nil
}
trait_table = {
    "ravings",
    "rage",
    "delusions",
    "brilliance",
    "insult",
    "bravado" }

empire_factions = {
	"wh2_dlc13_emp_golden_order",
	"wh2_dlc13_emp_the_huntmarshals_expedition",
	"wh3_main_emp_cult_of_sigmar",
	"wh_main_emp_averland",
	"wh_main_emp_empire",
	"wh_main_emp_hochland",
	"wh_main_emp_marienburg",
	"wh_main_emp_middenland",
	"wh_main_emp_nordland",
	"wh_main_emp_ostermark",
	"wh_main_emp_ostland",
	"wh_main_emp_stirland",
	"wh_main_emp_talabecland",
	"wh_main_emp_wissenland" }

core:add_listener(
	"marius_personality_swap",
	"FactionTurnStart",
	function(context)
		-- we want to check where marius is once per turn rotation, but we want to prioritize the script triggering on the players -- turn in case he was confederated. This will trigger finding Marius at the beginning of the player turn.
		if context:faction():is_human() then
			marius_personality.faction = find_marius_faction()
		end
	
		if marius_personality.faction ~= nil then
			return context:faction():name()	== (marius_personality.faction):name()
		end
		return false
	end,
	function()
        mad_count_out("FactionTurnStart event triggered")
        mad_count_out("Rolling 3D60 dice")

        local roll_dice_1 = cm:random_number(60, 1)
        mad_count_out("Dice 1: [" .. tostring(roll_dice_1) .. "]")

        local roll_dice_2 = cm:random_number(60, 1)
        mad_count_out("Dice 2: [" .. tostring(roll_dice_2) .. "]")

        local roll_dice_3 = cm:random_number(60, 1)
        mad_count_out("Dice 3: [" .. tostring(roll_dice_3) .. "]")

        local roll_total = math.max((roll_dice_1 + roll_dice_2), (roll_dice_1 + roll_dice_3), (roll_dice_2 + roll_dice_3))
        mad_count_out("Roll Total: [" .. tostring(roll_total) .. "]")

        local faction = marius_personality.faction
	
        for i = 0, faction:character_list():num_items() - 1 do
            local character = faction:character_list():item_at(i)
            if character:character_subtype("wh_main_emp_marius_leitdorf") then 
                local ccoCampaignCharacter = cco("CcoCampaignCharacter", character:command_queue_index())
                local ccoUnitDetails = ccoCampaignCharacter:Call("UnitDetailsContext")
                local leadership_total = ccoUnitDetails:Call("StatList.FirstContext(Name.Contains(\"Leadership\")).Value")
                mad_count_out("Marius Leadership score: [" .. tostring(leadership_total) .. "]")
                
                if roll_total > leadership_total then
                    mad_count_out("Leadership test failed!")

                    roll_trait = cm:random_number(#trait_table)
                    mad_count_out("Trait roll: [" .. tostring(roll_trait +  1) .. "]")

                    trait = trait_table[roll_trait]
                     mad_count_out("Trait selected: [" .. tostring(trait_table[roll_trait]) .. "]")

                    marius_personality_trait_replace(character, trait)
                else
                    mad_count_out("Leadership test passed!")
                    marius_personality_trait_replace(character, "normal")
                end
            end
        end
    end,
	true
)

function find_marius_faction()
	for _, faction_name in pairs(empire_factions) do
        faction = cm:get_faction(faction_name)
		mad_count_out("checking faction [" .. faction:name() .. "]")
		if cm:get_most_recently_created_character_of_type(faction, "general", "wh_main_emp_marius_leitdorf") ~= nil then
            mad_count_out("found character in faction [" .. faction:name() .."]")
			return faction
		end
	end
    return nil
end

function marius_personality_trait_replace(character, trait)
    if marius_personality.current ~= trait then
        cm:disable_event_feed_events(true, "", "wh_event_subcategory_character_traits", "")
        cm:force_remove_trait(cm:char_lookup_str(character), "wh3_main_trait_marius_personality_" .. marius_personality.current)
        cm:callback(function() cm:disable_event_feed_events(false, "", "wh_event_subcategory_character_traits", "") end, 0.2)
        cm:trigger_incident_with_targets(character:faction():command_queue_index(), "wh3_main_emp_leitdorf_mind_change_" .. trait, 0, 0, character:command_queue_index(), 0, 0, 0)
        
        marius_personality.current =  trait
    else
        mad_count_out("Marius already has trait [" .. tostring(trait) .. "], skipping trait replace!")
	end
end

cm:add_saving_game_callback(
	function(context)
		cm:save_named_value("marius_personality", marius_personality, context)
	end
)

cm:add_loading_game_callback(
	function(context)
		marius_personality = cm:load_named_value("marius_personality", marius_personality, context)
	end
)
