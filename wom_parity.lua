function wom_parity_out(message)
    out("wom_parity\t\t" .. tostring(message))
end

local battle_results = {
    ["heroic_victory"] = 100,
    ["decisive_victory"] = 85,
    ["close_victory"] = 55,
    ["pyrrhic_victory"] = 50,
    ["valiant_defeat" ] = 35,
    ["close_defeat"] = 30,
    ["decisive_defeat"] = 10,
    ["crushing_defeat"] = 5
}

local magic_table = {
    ["death"] = {
        ["wh_main_spell_death_spirit_leech"] = 8,
        ["wh_main_spell_death_spirit_leech_upgraded"] = 11,
        ["wh_main_spell_death_aspect_of_the_dreadknight"] = 4,
        ["wh_main_spell_death_aspect_of_the_dreadknight_upgraded"] = 8,
        ["wh_main_spell_death_soulblight"] = 8,
        ["wh_main_spell_death_soulblight_upgraded"] = 14,
        ["wh_main_spell_death_doom_and_darkness"] = 7,
        ["wh_main_spell_death_doom_and_darkness_upgraded"] = 14,
        ["wh_main_spell_death_the_fate_of_bjuna"] = 22,
        ["wh_main_spell_death_the_purple_sun_of_xereus"] = 18,    
        ["wh_main_spell_death_the_purple_sun_of_xereus_upgraded"] = 24 },
    ["heavens"] = {
        ["wh_main_spell_heavens_harmonic_convergence"] = 6,
        ["wh_main_spell_heavens_harmonic_convergence_upgraded"] = 10,
        ["wh_main_spell_heavens_wind_blast"] = 8,
        ["wh_main_spell_heavens_wind_blast_upgraded"] = 11,
        ["wh_main_spell_heavens_urannons_thunderbolt"] = 6,
        ["wh_main_spell_heavens_urannons_thunderbolt_upgraded"] = 10,
        ["wh_main_spell_heavens_curse_of_the_midnight_wind"] = 11,
        ["wh_main_spell_heavens_curse_of_the_midnight_wind_upgraded"] = 17,
        ["wh_main_spell_heavens_comet_of_casandora"] = 13,
        ["wh_main_spell_heavens_comet_of_casandora_upgraded"] = 20,    
        ["wh_main_spell_heavens_chain_lightning"] = 14 },
    ["metal"] = {
        ["wh_main_spell_metal_plague_of_rust"] = 4,
        ["wh_main_spell_metal_plague_of_rust_upgraded"] = 6,
        ["wh_main_spell_metal_searing_doom"] = 6,
        ["wh_main_spell_metal_searing_doom_upgraded"] = 10,
        ["wh_main_spell_metal_glittering_robe"] = 6,
        ["wh_main_spell_metal_glittering_robe_upgraded"] = 12,
        ["wh_main_spell_metal_gehennas_golden_hounds"] = 8,
        ["wh_main_spell_metal_gehennas_golden_hounds_upgraded"] = 12,
        ["wh_main_spell_metal_transmutation_of_lead"] = 11,
        ["wh_main_spell_metal_transmutation_of_lead_upgraded"] = 16,    
        ["wh_main_spell_metal_final_transmutation"] = 18,
        ["wh_main_spell_metal_final_transmutation_upgraded"] = 28 },
    ["nurgle"] = {
        ["wh3_main_spell_nurgle_miasma_of_pestilence"] = 4,
        ["wh3_main_spell_nurgle_miasma_of_pestilence_upgraded"] = 8,
        ["wh3_main_spell_nurgle_stream_of_corruption"] = 5,
        ["wh3_main_spell_nurgle_stream_of_corruption_upgraded"] = 8,
        ["wh3_main_spell_nurgle_curse_of_the_leper"] = 7,
        ["wh3_main_spell_nurgle_curse_of_the_leper_upgraded"] = 10,
        ["wh3_main_spell_nurgle_rancid_visitations"] = 16,
        ["wh3_main_spell_nurgle_rancid_visitations_upgraded"] = 24,
        ["wh3_main_spell_nurgle_fleshy_abundance"] = 16,
        ["wh3_main_spell_nurgle_fleshy_abundance_upgraded"] = 28,    
        ["wh3_main_spell_nurgle_pestilent_pustule"] = 13,
        ["wh3_main_spell_nurgle_pestilent_pustule_upgraded"] = 18 },
    ["yin"] = {
        ["wh3_main_spell_yin_storm_of_shadows"] = 4,
        ["wh3_main_spell_yin_storm_of_shadows_upgraded"] = 8,
        ["wh3_main_spell_yin_cloak_of_jet"] = 4,
        ["wh3_main_spell_yin_cloak_of_jet_upgraded"] = 6,
        ["wh3_main_spell_yin_blossom_wind"] = 9,
        ["wh3_main_spell_yin_blossom_wind_upgraded"] = 14,
        ["wh3_main_spell_yin_missile_mirror"] = 10,
        ["wh3_main_spell_yin_missile_mirror_upgraded"] = 15,
        ["wh3_main_spell_yin_talons_of_night"] = 14,
        ["wh3_main_spell_yin_talons_of_night_upgraded"] = 21,    
        ["wh3_main_spell_yin_ancestral_warriors"] = 16,
        ["wh3_main_spell_yin_ancestral_warriors_upgraded"] = 22 
    }
}

-- battle completed
core:add_listener(
    "wom_parity_CharacterCompletedBattle",
	"CharacterCompletedBattle",
	true,
	function (context)
        wom_parity_out("CharacterCompletedBattle triggered")
        local battle_results = context:pending_battle();
		local character = context:character();
		local faction = character:faction();

        wom_parity_out("analyzing character [" .. tostring(character:get_forename()) .. "] for faction [" .. tostring(faction:name()) .. "]")
        local wom_usage = 0

        -- There is no mechanism that simulates ability usage in the game for the sake of determining battle 
        -- results. The only situation we CAN determine ability usage is when the player manually fights a 
        -- battle. Otherwise, we need to artifically simulate the ability usage results. I've tried to do this 
        -- in the context of the battle_result_types table for maximum compatibility with mods that 
        -- could edit combat potential, auto resolve mechanics, etc. Effectively, we don't care the power 
        -- dynamic BETWEEN the two armies for determing how much WOM should be consumed as a result. 
        if battle_results:is_auto_resolved() and not character:has_garrison_residence() then
            wom_parity_out("autoresolved battle, simulating results")

            -- We capture the ratio of casters to total units in the army to try and differentiate WOM usage 
            -- between army comps. For example, a stack of 20 casters getting a heroic victiory is WAY 
            -- different than a stack of 1 caster + 19 elites doing the same
            local unit_count = character:military_force():unit_list():num_items()
            local caster_count = 0

            wom_parity_out("unit count [" .. tostring(unit_count) .. "]")

            for i = 0, character:military_force():character_list():num_items() - 1 do
                local battle_character = character:military_force():character_list():item_at(i)
                if battle_character:is_caster() then
                    caster_count = caster_count + 1
                end
            end

            wom_parity_out("caster count [" .. tostring(caster_count) .. "]")

            local caster_ratio = caster_count / unit_count
            local max_wom = character:military_force():pooled_resource_manager():resource("wh3_main_winds_of_magic"):maximum_value()
            local ratio_wom = max_wom * caster_ratio

            wom_parity_out("caster ratio [" .. tostring(caster_ratio) .. "]")
            wom_parity_out("max wom [" .. tostring(max_wom) .. "]")
            wom_parity_out("ratio wom [" .. tostring(ratio_wom) .. "]")

            local result = nil
            if character:cqi() == battle_results:defender():cqi() then
                result = tostring(battle_results:defender_battle_result())
                wom_parity_out("defending army with result [" .. tostring(result) .. "]")
            elseif character:cqi() == battle_results:attacker():cqi() then
                result = tostring(battle_results:attacker_battle_result())
                wom_parity_out("attacking army with result [" .. tostring(result) .. "]")
            end


            wom_parity_out(tostring(ratio_wom))
            wom_parity_out(tostring(battle_results[result]))
            wom_parity_out(tostring(100))

            -- wom_usage = math.ceil(tonumber(ratio_wom) * (battle_results[result] / 100 ))
            wom_usage = math.ceil(tonumber(ratio_wom))
        elseif not character:has_garrison_residence() then
            for lore, _ in pairs(magic_table) do
                wom_parity_out("checking lore [" .. tostring(lore) .. "]")
                for spell, wom_cost in pairs(magic_table[lore]) do
                    wom_parity_out("checking spell [" .. tostring(spell) .. "] with cost [" .. tostring(wom_cost) .. "]")
                    wom_usage = wom_usage + (cm:model():pending_battle():get_how_many_times_ability_has_been_used_in_battle(faction:command_queue_index(), spell) * wom_cost)
                end
            end
        else
            wom_parity_out("this is a garrison army, skipping")
        end

        wom_parity_out("total wom usage [" .. tostring(wom_usage) .. "]")
        wom_parity_out("capping wom usage between battle [" .. tostring(wom_usage) .. "] and campaign [" ..tostring(wom_current) .. "]")
        wom_usage = math.min(wom_current, wom_usage)
        if wom_usage > 0 then
            -- WOM usage is not strict in battle, and can exceed the campaign pool value, so if we end up using 
            -- more than what is available, we need to reduce the wom_usage value to, at maximum, what we have 
            -- in the campaign pool. Otherwise, the ritual will fail to execute due to a lack of resources
            local wom_current = character:military_force():pooled_resource_manager():resource("wh3_main_winds_of_magic"):value()

            local ritual_setup = cm:create_new_ritual_setup(faction, "wh3_main_ritual_winds_of_magic_spent_" .. tostring(wom_usage))
            wom_parity_out("creating new ritual for faction [" .. faction:name() .. "] with key [wh3_main_ritual_winds_of_magic_spent_" .. tostring(wom_usage) .. "]")
            local ritual_target = ritual_setup:target();

            ritual_target:set_target_force(character:military_force())
            wom_parity_out("setting ritual target to military_force cqi [" .. tostring(character:military_force():command_queue_index()) .. "]")

            if not character:faction():is_human() then
                cm:perform_ritual_with_setup(ritual_setup)
                wom_parity_out("performed ritual")
            else
                -- Initially, I couldn't figure out a way to apply WOM reduction instantaneously, so the idea was to try and apply
                -- an effect bundle to reduce post end-turn. This ends up being bad for multi-battle scenarios, as the player had
                -- access to repeatedly high WOM pools. After working around that, I found that the effect bundles applies a nice 
                -- visual indicator in the WOM meter as to how much a player lost due to battle usage, so I left this in place as a
                -- visual queue
                if character:military_force():has_effect_bundle("wh2_main_bundle_power_drain") then
                    wom_parity_out("found existing effect_bundle applied")
                    local effect_bundle_list = character:military_force():effect_bundles()
                    for i = 0, effect_bundle_list:num_items() - 1 do
                        local effect_bundle = effect_bundle_list:item_at(i)
                        local effect = effect_bundle:key();
					
                        if effect_bundle:key() == "wh2_main_bundle_power_drain" then
                            wom_parity_out("existing value [" .. tostring(effect_bundle:effects():item_at(0):value() * -1) .. "]")
                            wom_usage = wom_usage + (effect_bundle:effects():item_at(0):value() * -1)
                            wom_parity_out("new total wom usage [" .. tostring(wom_usage) .. "]") 
                        end
                    end
                end

                local bundle_to_apply = cm:create_new_custom_effect_bundle("wh2_main_bundle_power_drain")
                local new_effect = bundle_to_apply:effects():item_at(0)
                bundle_to_apply:set_effect_value(new_effect, (wom_usage * -1))
                bundle_to_apply:set_duration(1)

                cm:apply_custom_effect_bundle_to_force(bundle_to_apply, character:military_force())
                wom_parity_out("applied effect bundle [" .. tostring(bundle_to_apply:key()) .. "] with effect [" .. tostring(bundle_to_apply:effects():item_at(0):key()) .. "] with value [" .. tostring(bundle_to_apply:effects():item_at(0):value()) .. "] to force")

                -- we can't even perform a ritual during the post-battle screen, so we're setting up a listener post-battle exit in order
                -- to remove the visual aid (effect bundle) and actually perform the winds of magic deduction
                core:add_listener(
                    "wom_parity_ComponentLClickUp",
                    "ComponentLClickUp",
                    function(context)
                        local uic_context_name = UIComponent(context.component):Id()
                        wom_parity_out("checking uic_context_name [" .. uic_context_name .. "]")
                        return uic_context_name == "tab_army"
                    end,
                    function(context)
                        wom_parity_out("performing ritual")
                        cm:perform_ritual_with_setup(ritual_setup)
                        cm:remove_effect_bundle_from_force("wh2_main_bundle_power_drain", character:military_force():command_queue_index())
                        wom_parity_out("performed ritual")
                    end,
                    false
                );
            end
        end
    end,
	true
);	
