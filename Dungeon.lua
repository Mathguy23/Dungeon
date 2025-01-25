--- STEAMODDED HEADER
--- MOD_NAME: Dungeon
--- MOD_ID: DNG
--- PREFIX: dng
--- MOD_AUTHOR: [mathguy]
--- MOD_DESCRIPTION: Harder Dungeon challenges
--- VERSION: 1.0.0
----------------------------------------------
------------MOD CODE -------------------------

SMODS.current_mod.set_debuff = function(card)
    if card.ability.temp_debuff then
        return true
    end
end

SMODS.Atlas({ key = "attacks", atlas_table = "ASSET_ATLAS", path = "attacks.png", px = 34, py = 34})

SMODS.Atlas({ key = "tags", atlas_table = "ASSET_ATLAS", path = "tags.png", px = 34, py = 34})

SMODS.Atlas({ key = "blinds", atlas_table = "ANIMATION_ATLAS", path = "blinds.png", px = 34, py = 34, frames = 21 })

SMODS.Atlas({ key = "blinds2", atlas_table = "ANIMATION_ATLAS", path = "blinds2.png", px = 34, py = 34, frames = 21 })

SMODS.Atlas({ key = "blinds3", atlas_table = "ANIMATION_ATLAS", path = "blinds3.png", px = 34, py = 34, frames = 21 })

SMODS.Blind	{
    key = 'scarlet_spider',
    config = {},
    boss = {showdown = true, min = 2, max = 10},
    showdown = true, 
    boss_colour = HEX("ff2400"),
    atlas = "blinds",
    pos = { x = 0, y = 0},
    name = 'Scarlet Spider',
    vars = {},
    dollars = 8,
    mult = 2,
    in_pool = function(self)
        return false
    end,
    set_blind = function(self, reset, silent)
        if not reset then
            ease_hands_played(4)
        end
    end,
    disable = function(self)
        ease_hands_played(-4)
    end,
    discovered = true,
}

SMODS.Blind	{
    key = 'string',
    config = {},
    boss = {min = 2, max = 10},
    boss_colour = HEX("7ca4a1"),
    atlas = "blinds2",
    pos = { x = 0, y = 0},
    name = 'The String',
    vars = {},
    dollars = 8,
    mult = 2,
    in_pool = function(self)
        return false
    end,
    drawn_to_hand = function(self)
        if G.GAME.blind.prepped then
            G.GAME.blind.prepped = nil
            local any_forced = 0
            for k, v in ipairs(G.hand.cards) do
                if v.ability.forced_selection then
                    any_forced = any_forced + 1
                end
            end
            if any_forced < 2 then 
                local pool = {}
                for i = 1, #G.hand.cards do
                    if not G.hand.cards[i].ability.forced_selection then
                        table.insert(pool, G.hand.cards[i])
                    end
                end
                G.hand:unhighlight_all()
                for i = 1, 2 - any_forced do
                    if #pool > 0 then
                        local forced_card, index = pseudorandom_element(pool, pseudoseed('ring'))
                        forced_card.ability.forced_selection = true
                        G.hand:add_to_highlighted(forced_card)
                        table.remove(pool, index)
                    end
                end
            end
        end
    end,
    press_play  = function(self)
        G.GAME.blind.prepped = true
    end,
    disable = function(self)
        for k, v in ipairs(G.playing_cards) do
            v.ability.forced_selection = nil
        end
    end,
    discovered = true,
}

function dunegon_selection(theBlind)
    stop_use()
    if G.blind_select then 
        G.GAME.facing_blind = true
        G.blind_prompt_box:get_UIE_by_ID('prompt_dynatext1').config.object.pop_delay = 0
        G.blind_prompt_box:get_UIE_by_ID('prompt_dynatext1').config.object:pop_out(5)
        G.blind_prompt_box:get_UIE_by_ID('prompt_dynatext2').config.object.pop_delay = 0
        G.blind_prompt_box:get_UIE_by_ID('prompt_dynatext2').config.object:pop_out(5) 

        G.E_MANAGER:add_event(Event({
        trigger = 'before', delay = 0.2,
        func = function()
            G.blind_prompt_box.alignment.offset.y = -10
            G.blind_select.alignment.offset.y = 40
            G.blind_select.alignment.offset.x = 0
            return true
        end}))
        G.E_MANAGER:add_event(Event({
        trigger = 'immediate',
        func = function()
            ease_round(1)
            inc_career_stat('c_rounds', 1)
            if _DEMO then
            G.SETTINGS.DEMO_ROUNDS = (G.SETTINGS.DEMO_ROUNDS or 0) + 1
            inc_steam_stat('demo_rounds')
            G:save_settings()
            end
            -- G.GAME.round_resets.blind = e.config.ref_table
            -- G.GAME.round_resets.blind_states[G.GAME.blind_on_deck] = 'Current'
            G.blind_select:remove()
            G.blind_prompt_box:remove()
            G.blind_select = nil
            delay(0.2)
            return true
        end}))
        G.E_MANAGER:add_event(Event({
        trigger = 'immediate',
        func = function()
            dungeon_new_round(theBlind)
            return true
        end
        }))
    end
end

function dungeon_new_round(theBlind)
    G.RESET_JIGGLES = nil
    delay(0.4)
    G.E_MANAGER:add_event(Event({
      trigger = 'immediate',
      func = function()
            G.GAME.current_round.discards_left = math.max(0, G.GAME.round_resets.discards + G.GAME.round_bonus.discards)
            G.GAME.current_round.hands_left = (math.max(1, G.GAME.round_resets.hands + G.GAME.round_bonus.next_hands))
            G.GAME.current_round.hands_played = 0
            G.GAME.current_round.discards_used = 0
            G.GAME.current_round.reroll_cost_increase = 0
            G.GAME.current_round.used_packs = {}

            for k, v in pairs(G.GAME.hands) do 
                v.played_this_round = 0
            end

            for k, v in pairs(G.playing_cards) do
                v.ability.wheel_flipped = nil
            end

            local chaos = find_joker('Chaos the Clown')
            G.GAME.current_round.free_rerolls = #chaos
            calculate_reroll_cost(true)

            G.GAME.round_bonus.next_hands = 0
            G.GAME.round_bonus.discards = 0

            local blhash = 'S'
            -- if G.GAME.round_resets.blind == G.P_BLINDS.bl_small then
            --     G.GAME.round_resets.blind_states.Small = 'Current'
            --     G.GAME.current_boss_streak = 0
            --     blhash = 'S'
            -- elseif G.GAME.round_resets.blind == G.P_BLINDS.bl_big then
            --     G.GAME.round_resets.blind_states.Big = 'Current'
            --     G.GAME.current_boss_streak = 0
            --     blhash = 'B'
            -- else
            --     G.GAME.round_resets.blind_states.Boss = 'Current'
            --     blhash = 'L'
            -- end
            G.GAME.subhash = (G.GAME.round_resets.ante)..(blhash)

            -- local customBlind = {name = 'The Ox', defeated = false, order = 4, dollars = 5, mult = 2,  vars = {localize('ph_most_played')}, debuff = {}, pos = {x=0, y=2}, boss = {min = 6, max = 10, bonus = true}, boss_colour = HEX('b95b08')}
            G.GAME.blind_on_deck = 'Dungeon'
            G.GAME.last_blind.boss = nil
            G.HUD_blind.alignment.offset.y = -10
            G.HUD_blind:recalculate(false)
            
            delay(0.4)

            G.E_MANAGER:add_event(Event({
                trigger = 'immediate',
                func = function()
                    G.STATE = G.STATES.DRAW_TO_HAND
                    G.deck:shuffle('nr'..G.GAME.round_resets.ante)
                    G.deck:hard_set_T()
                    G.STATE_COMPLETE = false
                    return true
                end
            }))
            return true
            end
        }))
end

function get_specific_pack(seed, cat)
    local cume, it, center = 0, 0, nil
    local pool = {}
    for k, v in ipairs(G.P_CENTER_POOLS['Booster']) do
        local c_cat
        if v.config.choose > 1 then
            c_cat = 3
        elseif v.config.extra > 3 then
            c_cat = 2
        else
            c_cat = 1
        end
        if c_cat == cat then
            table.insert(pool, v) 
        end
    end
    if #pool == 0 then
        return G.P_CENTERS["p_buffoon_normal_1"]
    end
    for k, v in ipairs(pool) do
        if not G.GAME.banned_keys[v.key] then cume = cume + (v.weight or 1 ) end
    end
    local poll = pseudorandom(pseudoseed((seed or 'pack_generic')..G.GAME.round_resets.ante))*cume
    for k, v in ipairs(pool) do
        if not G.GAME.banned_keys[v.key] then 
            if true then it = it + (v.weight or 1) end
            if it >= poll and it - (v.weight or 1) <= poll then center = v; break end
        end
    end
    return center
end

G.FUNCS.can_common = function(e)
    if to_big and ((to_big(G.GAME.dollars)-to_big(G.GAME.bankrupt_at)) - to_big(3) < to_big(0)) or ((G.GAME.dollars-G.GAME.bankrupt_at) - 3 < 0) then 
        e.config.colour = G.C.UI.BACKGROUND_INACTIVE
        e.config.button = nil
    else
        e.config.colour = G.C.BLUE
        e.config.button = 'make_common_loot'
    end
end

G.FUNCS.make_common_loot = function(e)
    ease_dollars(-3)
    local j_total = 40
    local t_total = G.GAME.tarot_rate
    local p_total = G.GAME.planet_rate
    local c_total = G.GAME.playing_card_rate or 0
    local b_total = 11
    local total = j_total + t_total + p_total + c_total + b_total
    local rng = total * pseudorandom('common')
    local card
    if rng < j_total then
        card = SMODS.create_card {set = "Joker", no_edition = true, rarity = 0, area = G.shop_jokers}
    elseif rng < j_total + t_total then
        card = SMODS.create_card {set = "Tarot", no_edition = true, area = G.shop_jokers}
    elseif rng < j_total + t_total + b_total then
        card = Card(G.shop_jokers.T.x + G.shop_jokers.T.w/2,
        G.shop_jokers.T.y, G.CARD_W*1.27, G.CARD_H*1.27, G.P_CARDS.empty, get_specific_pack('dungeon', 1), {bypass_discovery_center = true, bypass_discovery_ui = true})
        create_shop_card_ui(card, 'Booster', G.shop_jokers)
        card.ability.booster_pos = #G.shop_jokers.cards + 1
        card:start_materialize()
    elseif (rng < j_total + t_total + b_total + p_total) or (c_total == 0) then
        card = SMODS.create_card {set = "Planet", no_edition = true, area = G.shop_jokers}
    else
        card = SMODS.create_card {set = "Base", area = G.shop_jokers}
    end
    G.E_MANAGER:add_event(Event({
        func = (function()
            for k, v in ipairs(G.GAME.tags) do
              if v:apply_to_run({type = 'store_joker_modify', card = card}) then break end
            end
            return true
        end)
    }))
    G.shop_jokers:emplace(card)
    card.ability.couponed = true
    card:set_cost()
    create_shop_card_ui(card, card.ability.set, G.shop_jokers)
    G.E_MANAGER:add_event(Event({ func = function() save_run(); return true end}))
end

G.FUNCS.can_uncommon = function(e)
    if to_big and ((to_big(G.GAME.dollars)-to_big(G.GAME.bankrupt_at)) - to_big(6) < to_big(0)) or ((G.GAME.dollars-G.GAME.bankrupt_at) - 6 < 0) then 
        e.config.colour = G.C.UI.BACKGROUND_INACTIVE
        e.config.button = nil
    else
        e.config.colour = G.C.GREEN
        e.config.button = 'make_uncommon_loot'
    end
end

G.FUNCS.make_uncommon_loot = function(e)
    ease_dollars(-6)
    local rng = pseudorandom('common')
    local card
    if rng < 0.5 then
        card = SMODS.create_card {set = "Joker", rarity = 0.9, area = G.shop_jokers}
    elseif rng < 0.85 then
        card = Card(G.shop_jokers.T.x + G.shop_jokers.T.w/2,
        G.shop_jokers.T.y, G.CARD_W*1.27, G.CARD_H*1.27, G.P_CARDS.empty, get_specific_pack('dungeon', 2), {bypass_discovery_center = true, bypass_discovery_ui = true})
        create_shop_card_ui(card, 'Booster', G.shop_jokers)
        card.ability.booster_pos = #G.shop_jokers.cards + 1
        card:start_materialize()
    else
        card = SMODS.create_card {set = "Spectral", no_edition = true, area = G.shop_jokers}
    end
    G.E_MANAGER:add_event(Event({
        func = (function()
            for k, v in ipairs(G.GAME.tags) do
              if v:apply_to_run({type = 'store_joker_modify', card = card}) then break end
            end
            return true
        end)
    }))
    G.shop_jokers:emplace(card)
    card.ability.couponed = true
    card:set_cost()
    create_shop_card_ui(card, card.ability.set, G.shop_jokers)
    G.E_MANAGER:add_event(Event({ func = function() save_run(); return true end}))
end

G.FUNCS.can_rare = function(e)
    if to_big and ((to_big(G.GAME.dollars)-to_big(G.GAME.bankrupt_at)) - to_big(10) < to_big(0)) or ((G.GAME.dollars-G.GAME.bankrupt_at) - 10 < 0) then 
        e.config.colour = G.C.UI.BACKGROUND_INACTIVE
        e.config.button = nil
    else
        e.config.colour = G.C.RED
        e.config.button = 'make_rare_loot'
    end
end

G.FUNCS.make_rare_loot = function(e)
    ease_dollars(-10)
    local rng = pseudorandom('common')
    local card
    if rng < 0.5 then
        card = SMODS.create_card {set = "Joker", rarity = 0.99, area = G.shop_jokers}
    elseif rng < 0.7 then
        card = Card(G.shop_jokers.T.x + G.shop_jokers.T.w/2,
        G.shop_jokers.T.y, G.CARD_W*1.27, G.CARD_H*1.27, G.P_CARDS.empty, get_specific_pack('dungeon', 3), {bypass_discovery_center = true, bypass_discovery_ui = true})
        create_shop_card_ui(card, 'Booster', G.shop_jokers)
        card.ability.booster_pos = #G.shop_jokers.cards + 1
        card:start_materialize()
    else
        card = Card(G.shop_jokers.T.x + G.shop_jokers.T.w/2,
        G.shop_jokers.T.y, G.CARD_W, G.CARD_H, G.P_CARDS.empty, G.P_CENTERS[get_next_voucher_key()], {bypass_discovery_center = true, bypass_discovery_ui = true})
        create_shop_card_ui(card, 'Voucher', G.shop_jokers)
    end
    G.E_MANAGER:add_event(Event({
        func = (function()
            for k, v in ipairs(G.GAME.tags) do
              if v:apply_to_run({type = 'store_joker_modify', card = card}) then break end
            end
            return true
        end)
    }))
    G.shop_jokers:emplace(card)
    card.ability.couponed = true
    card:set_cost()
    create_shop_card_ui(card, card.ability.set, G.shop_jokers)
    G.E_MANAGER:add_event(Event({ func = function() save_run(); return true end}))
end

function G.UIDEF.loot_shop()
    G.shop_jokers = CardArea(
      G.hand.T.x+0,
      G.hand.T.y+G.ROOM.T.y + 9,
      4*1.02*G.CARD_W,
      1.05*G.CARD_H, 
      {card_limit = 4, type = 'shop', highlight_limit = 1})

    local shop_sign = AnimatedSprite(0,0, 4.4, 2.2, G.ANIMATION_ATLAS['shop_sign'])
    shop_sign:define_draw_steps({
      {shader = 'dissolve', shadow_height = 0.05},
      {shader = 'dissolve'}
    })
    G.SHOP_SIGN = UIBox{
      definition = 
        {n=G.UIT.ROOT, config = {colour = G.C.DYN_UI.MAIN, emboss = 0.05, align = 'cm', r = 0.1, padding = 0.1}, nodes={
          {n=G.UIT.R, config={align = "cm", padding = 0.1, minw = 4.72, minh = 3.1, colour = G.C.DYN_UI.DARK, r = 0.1}, nodes={
            {n=G.UIT.R, config={align = "cm"}, nodes={
              {n=G.UIT.O, config={object = shop_sign}}
            }},
            {n=G.UIT.R, config={align = "cm"}, nodes={
              {n=G.UIT.O, config={object = DynaText({string = {localize('ph_improve_run')}, colours = {lighten(G.C.GOLD, 0.3)},shadow = true, rotate = true, float = true, bump = true, scale = 0.5, spacing = 1, pop_in = 1.5, maxw = 4.3})}}
            }},
          }},
        }},
      config = {
        align="cm",
        offset = {x=0,y=-15},
        major = G.HUD:get_UIE_by_ID('row_blind'),
        bond = 'Weak'
      }
    }
    G.E_MANAGER:add_event(Event({
      trigger = 'immediate',
      func = (function()
          G.SHOP_SIGN.alignment.offset.y = 0
          return true
      end)
    }))
    local t = {n=G.UIT.ROOT, config = {align = 'cl', colour = G.C.CLEAR}, nodes={
            UIBox_dyn_container({
                {n=G.UIT.C, config={align = "cm", padding = 0.1, emboss = 0.05, r = 0.1, colour = G.C.DYN_UI.BOSS_MAIN}, nodes={
                    {n=G.UIT.R, config={align = "cm", padding = 0.05}, nodes={
                      {n=G.UIT.C, config={align = "cm", padding = 0.1}, nodes={
                        {n=G.UIT.R,config={id = 'next_round_button', align = "cm", minw = 2.8, minh = 1.5, r=0.15,colour = G.C.RED, one_press = true, button = 'toggle_shop', hover = true,shadow = true}, nodes = {
                          {n=G.UIT.R, config={align = "cm", padding = 0.07, focus_args = {button = 'y', orientation = 'cr'}, func = 'set_button_pip'}, nodes={
                            {n=G.UIT.R, config={align = "cm", maxw = 1.3}, nodes={
                              {n=G.UIT.T, config={text = localize('b_next_round_1'), scale = 0.4, colour = G.C.WHITE, shadow = true}}
                            }},
                            {n=G.UIT.R, config={align = "cm", maxw = 1.3}, nodes={
                              {n=G.UIT.T, config={text = localize('b_next_round_2'), scale = 0.4, colour = G.C.WHITE, shadow = true}}
                            }}   
                          }},              
                        }},
                      }},
                      {n=G.UIT.C, config={align = "cm", padding = 0.2, r=0.2, colour = G.C.L_BLACK, emboss = 0.05, minw = 8.2}, nodes={
                          {n=G.UIT.O, config={object = G.shop_jokers}},
                      }},
                    }},
                    {n=G.UIT.R, config={align = "cm", minh = 0.2}, nodes={}},
                    {n=G.UIT.R, config={align = "cm", padding = 0.1}, nodes={
                        {n=G.UIT.C, config={align = "cm", minw = 2.8, minh = 1.6, r=0.15,colour = G.C.BLUE, button = 'make_common_loot', func = 'can_common', hover = true,shadow = true}, nodes = {
                            {n=G.UIT.R, config={align = "cm", padding = 0.07, focus_args = {button = 'x', orientation = 'cr'}, func = 'set_button_pip'}, nodes={
                                {n=G.UIT.R, config={align = "cm", maxw = 1.3}, nodes={
                                    {n=G.UIT.T, config={text = localize('b_common_loot'), scale = 0.4, colour = G.C.WHITE, shadow = true}},
                                }},
                                {n=G.UIT.R, config={align = "cm", maxw = 1.3}, nodes={
                                    {n=G.UIT.T, config={text = localize('b_loot'), scale = 0.4, colour = G.C.WHITE, shadow = true}},
                                }},
                                {n=G.UIT.R, config={align = "cm", maxw = 1.3, minw = 1}, nodes={
                                    {n=G.UIT.T, config={text = localize('$') .. 3, scale = 0.7, colour = G.C.WHITE, shadow = true}},
                                }}
                            }}
                        }},
                        {n=G.UIT.C, config={align = "cm", minw = 2.8, minh = 1.6, r=0.15,colour = G.C.GREEN, button = 'make_uncommon_loot', func = 'can_uncommon', hover = true,shadow = true}, nodes = {
                            {n=G.UIT.R, config={align = "cm", padding = 0.07, focus_args = {button = 'x', orientation = 'cr'}, func = 'set_button_pip'}, nodes={
                                {n=G.UIT.R, config={align = "cm", maxw = 1.3}, nodes={
                                    {n=G.UIT.T, config={text = localize('b_uncommon_loot'), scale = 0.4, colour = G.C.WHITE, shadow = true}},
                                }},
                                {n=G.UIT.R, config={align = "cm", maxw = 1.3}, nodes={
                                    {n=G.UIT.T, config={text = localize('b_loot'), scale = 0.4, colour = G.C.WHITE, shadow = true}},
                                }},
                                {n=G.UIT.R, config={align = "cm", maxw = 1.3, minw = 1}, nodes={
                                    {n=G.UIT.T, config={text = localize('$') .. 6, scale = 0.7, colour = G.C.WHITE, shadow = true}},
                                }}
                            }}
                        }},
                        {n=G.UIT.C, config={align = "cm", minw = 2.8, minh = 1.6, r=0.15,colour = G.C.RED, button = 'make_rare_loot', func = 'can_rare', hover = true,shadow = true}, nodes = {
                            {n=G.UIT.R, config={align = "cm", padding = 0.07, focus_args = {button = 'x', orientation = 'cr'}, func = 'set_button_pip'}, nodes={
                                {n=G.UIT.R, config={align = "cm", maxw = 1.3}, nodes={
                                    {n=G.UIT.T, config={text = localize('b_rare_loot'), scale = 0.4, colour = G.C.WHITE, shadow = true}},
                                }},
                                {n=G.UIT.R, config={align = "cm", maxw = 1.3}, nodes={
                                    {n=G.UIT.T, config={text = localize('b_loot'), scale = 0.4, colour = G.C.WHITE, shadow = true}},
                                }},
                                {n=G.UIT.R, config={align = "cm", maxw = 1.3, minw = 1}, nodes={
                                    {n=G.UIT.T, config={text = localize('$') .. 10, scale = 0.7, colour = G.C.WHITE, shadow = true}},
                                }}
                            }}
                        }},
                    }}
                }
              },
              
              }, false)
        }}
    return t
end

-----Blackjack Minigame----------

local old_buttons = create_UIBox_buttons
function create_UIBox_buttons()
    local t = old_buttons()
    if G and G.GAME and G.GAME.modifiers and G.GAME.modifiers.dungeon then
        local index = 3
        if G.SETTINGS.play_button_pos ~= 1 then
            index = 1
        end
        local button = t.nodes[index]
        button.nodes[1].nodes[1].config.text = localize("b_hit")
        button.config.button = 'hit'
        button.config.func = 'can_hit'
        -- button.config.color = G.C[checking[G.GAME.active].colour]
    end
    if G and G.GAME and G.GAME.modifiers and G.GAME.modifiers.dungeon then
        local index = 1
        if G.SETTINGS.play_button_pos ~= 1 then
            index = 3
        end
        local button = t.nodes[index]
        button.nodes[1].nodes[1].config.text = localize("b_stand")
        button.config.button = 'stand'
        button.config.func = 'can_stand'
        -- button.config.color = G.C[checking[G.GAME.passive].colour]
    end
    return t
end

G.FUNCS.can_hit = function(e)
    if G.GAME.stood or G.GAME.dng_busted or (#G.deck.cards == 0) then
        e.config.colour = G.C.UI.BACKGROUND_INACTIVE
        e.config.button = nil
    else
        e.config.colour = G.C.RED
        e.config.button = 'hit'
    end
end

G.FUNCS.hit = function(e)
    G.GAME.hit_limit = (G.GAME.hit_limit or 2) + 1
    G.E_MANAGER:add_event(Event({
        trigger = 'immediate',
        func = function()
            G.STATE = G.STATES.DRAW_TO_HAND
            G.STATE_COMPLETE = false
            return true
        end
    }))
end

G.FUNCS.can_stand = function(e)
    if G.GAME.stood then
        e.config.colour = G.C.UI.BACKGROUND_INACTIVE
        e.config.button = nil
    else
        e.config.colour = G.C.GREEN
        e.config.button = 'stand'
    end
end

G.FUNCS.stand = function(e)
    local total = 0
    local aces = 0
    G.GAME.dng_busted = nil
    G.GAME.stood = true
    G.enemy_deck:shuffle('enemy_deck')
    for i = 1, #G.hand.cards do
        local id = G.hand.cards[i]:get_id()
        if id > 0 then
            local rank = SMODS.Ranks[G.hand.cards[i].base.value] or {}
            local nominal = rank.nominal
            if rank.key == 'Ace' then
                total = total + 1
                aces = aces + 1
            else
                total = total + nominal
            end
        end
    end
    while (total <= 11) and (aces >= 1) do
        total = total + 10
        aces = aces + 1
    end
    if total > 21 then
        total = -1
    end
    local bl_total = 0
    local bl_aces = 0
    local bl_cards = 0
    while bl_total <= 21 do
        local index = #G.enemy_deck.cards - bl_cards
        if index <= 0 then
            break
        else
            local id = G.enemy_deck.cards[index]:get_id()
            if id > 0 then
                local rank = SMODS.Ranks[G.enemy_deck.cards[index].base.value] or {}
                local nominal = rank.nominal
                if rank.key == 'Ace' then
                    bl_total = bl_total + 11
                    bl_aces = bl_aces + 1
                else
                    bl_total = bl_total + nominal
                end
            end
            if bl_total > 21 then
                while (bl_total > 21) and (bl_aces > 0) do
                    bl_total = bl_total - 10
                    bl_aces = bl_aces - 1
                end
            end
            if (bl_total >= 17) and (bl_total <= 21) then
                bl_cards = bl_cards + 1
                break
            end
        end
        bl_cards = bl_cards + 1
    end 
    if bl_total > 21 then
        bl_total = -1
    end
    G.E_MANAGER:add_event(Event({
        trigger = 'immediate',
        func = function()
            if bl_cards > 0 then
                for i = 1, bl_cards do
                    draw_card(G.enemy_deck, G.play, i*100/5, 'up')
                end
            end
            delay(0.5)
            if bl_total < total then
                if bl_total == -1 then
                    play_area_status_text("Win (" .. tostring(total) .. " > Bust)")
                else
                    play_area_status_text("Win (" .. tostring(total) .. " > " .. tostring(bl_total) .. ")")
                end
                G.GAME.hit_limit = 2
                ease_hands_played(1)
                G.E_MANAGER:add_event(Event({
                    trigger = 'immediate',
                    func = function()
                        for i = 1, #G.play.cards do
                            draw_card(G.play, G.enemy_deck, i*100/5, 'up')
                        end
                        G.E_MANAGER:add_event(Event({
                            trigger = 'immediate',
                            func = function()
                                for i = 1, #G.hand.cards do
                                    if not G.hand.cards[i].highlighted then
                                        G.hand:add_to_highlighted(G.hand.cards[i])
                                    end
                                end
                                G.FUNCS.play_cards_from_highlighted()
                                G.GAME.dng_busted = nil
                                G.E_MANAGER:add_event(Event({
                                    trigger = 'immediate',
                                    func = function()
                                        G.GAME.stood = nil
                                        return true
                                    end
                                }))
                                return true
                            end
                        }))
                        return true
                    end
                }))
                if #G.deck.cards - bl_cards <= 0 then
                    G.GAME.dng_busted = true
                    G.GAME.hit_limit = 0
                end
            elseif bl_total == total then
                if bl_total == -1 then
                    play_area_status_text("Push (Bust = Bust)")
                else
                    play_area_status_text("Push (" .. tostring(total) .. " = " .. tostring(bl_total) .. ")")
                end
                G.GAME.hit_limit = 2
                G.E_MANAGER:add_event(Event({
                    trigger = 'immediate',
                    func = function()
                        for i = 1, #G.play.cards do
                            draw_card(G.play, G.enemy_deck, i*100/5, 'up')
                        end
                        for i = 1, #G.hand.cards do
                            draw_card(G.hand, G.discard, i*100/5, 'up')
                        end
                        G.E_MANAGER:add_event(Event({
                            trigger = 'immediate',
                            func = function()
                                G.GAME.stood = nil
                                return true
                            end
                        }))
                        return true
                    end
                }))
                if #G.deck.cards - bl_cards <= 0 then
                    G.GAME.dng_busted = true
                    G.GAME.hit_limit = 0
                    G.E_MANAGER:add_event(Event({
                        trigger = 'immediate',
                        func = function()
                            G.STATE = G.STATES.DRAW_TO_HAND
                            G.STATE_COMPLETE = false
                            return true
                        end
                    }))
                end
            elseif bl_total > total then
                if total == -1 then
                    play_area_status_text("Loss (Bust < " .. tostring(bl_total) .. ")")
                else
                    play_area_status_text("Loss (" .. tostring(total) .. " < " .. tostring(bl_total) .. ")")
                end
                G.GAME.hit_limit = 2
                ease_hands_played(-1)
                G.E_MANAGER:add_event(Event({
                    trigger = 'immediate',
                    func = function()
                        G.E_MANAGER:add_event(Event({
                            trigger = 'immediate',
                            func = function()
                                for i = 1, #G.hand.cards do
                                    draw_card(G.hand, G.discard, i*100/5, 'up')
                                end
                                G.GAME.negate_hand = true
                                G.E_MANAGER:add_event(Event({
                                    trigger = 'immediate',
                                    func = function()
                                        G.STATE = G.STATES.HAND_PLAYED
                                        G.STATE_COMPLETE = true
                                        return true
                                    end
                                }))
                                G.E_MANAGER:add_event(Event({
                                    trigger = 'immediate',
                                    func = function()
                                        G.FUNCS.evaluate_play()
                                        return true
                                    end
                                }))
                                G.E_MANAGER:add_event(Event({
                                    trigger = 'immediate',
                                    func = function()
                                        local play_count = #G.play.cards
                                        local it = 1
                                        for k, v in ipairs(G.play.cards) do
                                            if (not v.shattered) and (not v.destroyed) then 
                                                draw_card(G.play,G.enemy_deck, it*100/play_count,'down', false, v)
                                                it = it + 1
                                            end
                                        end
                                        return true
                                    end
                                }))
                                G.E_MANAGER:add_event(Event({
                                    trigger = 'immediate',
                                    func = function()
                                        G.STATE_COMPLETE = false
                                        return true
                                    end
                                }))
                                G.GAME.dng_busted = nil
                                G.E_MANAGER:add_event(Event({
                                    trigger = 'immediate',
                                    func = function()
                                        G.GAME.stood = nil
                                        return true
                                    end
                                }))
                                return true
                            end
                        }))
                        return true
                    end
                }))
                if #G.deck.cards - bl_cards <= 0 then
                    G.GAME.dng_busted = true
                    G.GAME.hit_limit = 0
                end
            end
            return true
        end
    }))
end

local old_draw_from_deck = G.FUNCS.draw_from_deck_to_hand
G.FUNCS.draw_from_deck_to_hand = function(e)
    if G and G.GAME and G.GAME.modifiers and G.GAME.modifiers.dungeon and not (G.STATE == G.STATES.TAROT_PACK or G.STATE == G.STATES.SPECTRAL_PACK or G.STATE == G.STATES.SMODS_BOOSTER_OPENED) then
        local hand_space =  math.max(0, (G.GAME.hit_limit or 2) - #G.hand.cards)
        if hand_space >= 1 then
            for i = 1, hand_space do
                draw_card(G.deck,G.hand, i*100/hand_space,'up', true)
            end
        end
    else
        old_draw_from_deck()
    end
end

-----------Memory Game----------

G.FUNCS.can_play_memory = function(e)
    if (G.GAME.currently_choosing ~= nil) or (G.GAME.dng_tries_left <= 0) then
        e.config.colour = G.C.UI.BACKGROUND_INACTIVE
        e.config.button = nil
    else
        e.config.colour = G.C.BLUE
        e.config.button = 'play_memory'
    end
end

G.FUNCS.play_memory = function(e)
    G.GAME.currently_choosing = true
    G.GAME.memory_cards = {}
    G.memory_row_1.highlighted = {}
    G.memory_row_2.highlighted = {}
    G.GAME.dng_tries_left = G.GAME.dng_tries_left - 1
end

SMODS.Tag {
    key = 'memory',
    atlas = 'tags',
    loc_txt = {
        name = "Memory Tag",
        text = {
            "Play a",
            "Memory Game"
        }
    },
    discovered = true,
    in_pool = function(self)
        return G.GAME.modifiers.dungeon
    end,
    pos = {x = 1, y = 0},
    apply = function(self, tag, context)
        if context.type == 'immediate' then
            tag:yep('+', G.C.GREEN,function()
                return true
            end)
            tag.triggered = true
            return true
        end
    end,
    config = {type = 'immediate', minigame = true}
}

function G.UIDEF.memory()
    local rows = {}
    G.GAME.currently_choosing = nil
    G.GAME.memory_cards = nil
    for i = 1, 2 do
        G["memory_row_" .. tostring(i)] = CardArea(
        G.hand.T.x+0,
        G.hand.T.y+G.ROOM.T.y + 9,
        5*1.02*G.CARD_W,
        1.05*G.CARD_H, 
        {card_limit = 5, type = 'shop', highlight_limit = 5})
        table.insert(rows, {n=G.UIT.R, config={align = "cm", padding = 0.05}, nodes={
            {n=G.UIT.C, config={align = "cm", padding = 0.2, r=0.2, colour = G.C.L_BLACK, emboss = 0.05, minw = 8.2}, nodes={
                {n=G.UIT.O, config={object = G["memory_row_" .. tostring(i)]}},
            }},
        }})
    end
    if not G.load_memory_row_1 then
        G.GAME.dng_tries_left = nil
        local pools = {G.P_JOKER_RARITY_POOLS[2], G.P_JOKER_RARITY_POOLS[3], G.P_CENTER_POOLS["Spectral"], G.P_CENTER_POOLS["Spectral"], G.P_CENTER_POOLS["Voucher"]}
        local keys = {}
        for i, j in ipairs(pools) do
            local pool = {}
            for k, v in ipairs(j) do
                local valid = true
                local in_pool, pool_opts
                if v.in_pool and type(v.in_pool) == 'function' then
                    in_pool, pool_opts = v:in_pool({})
                end
                if (G.GAME.used_jokers[v.key] and (not pool_opts or not pool_opts.allow_duplicates) and not next(find_joker("Showman"))) then
                    valid = false
                end
                if not v.unlocked then
                    valid = false
                end
                if (i == 4) and (keys[3] == v.key) then
                    valid = false
                end
                if G.GAME.banned_keys[v.key] then
                    valid = false
                end
                if G.GAME.used_vouchers[v.key] then
                    valid = false
                end
                if v.requires then 
                    for i2, j2 in pairs(v.requires) do
                        if not G.GAME.used_vouchers[j2] then 
                            valid = false
                        end
                    end
                end
                for i2, j2 in ipairs(SMODS.Consumable.legendaries) do
                    if v.key == j2.key then
                        valid = false
                        break
                    end
                end
                if (v.key == 'c_black_hole') or (v.key == 'c_soul') then
                    valid = false
                end
                if valid then
                    table.insert(pool, v.key)
                end
            end
            if #pool == 0 then
                keys[#keys + 1] = 'c_pluto'
            else
                keys[#keys + 1] = pseudorandom_element(pool, pseudoseed('remember'))
            end
        end
        local row_1 = {}
        local row_2 = {}
        local pool = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
        for _, j in pairs(keys) do
            for k = 1, 2 do
                local slot, index = pseudorandom_element(pool, pseudoseed('remember2'))
                table.remove(pool, index)
                if slot > 5 then
                    row_2[slot - 5] = j
                else
                    row_1[slot] = j
                end
            end
        end
        for i, j in ipairs(row_1) do
            local card = SMODS.create_card {key = j, no_edition = true}
            G.memory_row_1:emplace(card)
            card:flip()
        end
        for i, j in ipairs(row_2) do
            local card = SMODS.create_card {key = j, no_edition = true}
            G.memory_row_2:emplace(card)
            card:flip()
        end
    else
        G.memory_row_1:load(G.load_memory_row_1)
        G.memory_row_2:load(G.load_memory_row_2)
        G.load_memory_row_1 = nil
        G.load_memory_row_2 = nil
    end
    G.GAME.dng_tries_left = G.GAME.dng_tries_left or 6


    local shop_sign = AnimatedSprite(0,0, 4.4, 2.2, G.ANIMATION_ATLAS['shop_sign'])
    shop_sign:define_draw_steps({
      {shader = 'dissolve', shadow_height = 0.05},
      {shader = 'dissolve'}
    })
    G.SHOP_SIGN = UIBox{
      definition = 
        {n=G.UIT.ROOT, config = {colour = G.C.DYN_UI.MAIN, emboss = 0.05, align = 'cm', r = 0.1, padding = 0.1}, nodes={
          {n=G.UIT.R, config={align = "cm", padding = 0.1, minw = 4.72, minh = 3.1, colour = G.C.DYN_UI.DARK, r = 0.1}, nodes={
            {n=G.UIT.R, config={align = "cm"}, nodes={
              {n=G.UIT.O, config={object = shop_sign}}
            }},
            {n=G.UIT.R, config={align = "cm"}, nodes={
              {n=G.UIT.O, config={object = DynaText({string = {localize('ph_test_memory')}, colours = {lighten(G.C.GOLD, 0.3)},shadow = true, rotate = true, float = true, bump = true, scale = 0.5, spacing = 1, pop_in = 1.5, maxw = 4.3})}}
            }},
          }},
        }},
      config = {
        align="cm",
        offset = {x=0,y=-15},
        major = G.HUD:get_UIE_by_ID('row_blind'),
        bond = 'Weak'
      }
    }
    G.E_MANAGER:add_event(Event({
      trigger = 'immediate',
      func = (function()
          G.SHOP_SIGN.alignment.offset.y = 0
          return true
      end)
    }))


    local t = {n=G.UIT.ROOT, config = {align = 'cl', colour = G.C.CLEAR}, nodes={
            UIBox_dyn_container({
                {n=G.UIT.C, config={align = "cm", padding = 0.1, emboss = 0.05, r = 0.1, colour = G.C.DYN_UI.BOSS_MAIN}, nodes={
                rows[1], rows[2],
                {n=G.UIT.R, config={align = "cm", padding = 0.1}, nodes={
                    {n=G.UIT.C, config={align = "cm", minw = 2.8, minh = 0.7, r=0.04,colour = G.C.BLUE, button = 'play_memory', func = 'can_play_memory', hover = true,shadow = true}, nodes = {
                        {n=G.UIT.R, config={align = "cm", padding = 0.07, focus_args = {button = 'x', orientation = 'cr'}, func = 'set_button_pip'}, nodes={
                            {n=G.UIT.R, config={align = "cm", maxw = 1.3}, nodes={
                                {n=G.UIT.T, config={text = localize('b_choose_cards'), scale = 0.4, colour = G.C.WHITE, shadow = true}},
                            }},
                            {n=G.UIT.R, config={align = "cm", maxw = 1.3, minw = 1}, nodes={
                              {n=G.UIT.T, config={text = " (", scale = 0.4, colour = G.C.WHITE, shadow = true}},
                              {n=G.UIT.T, config={ref_table = G.GAME, ref_value = 'dng_tries_left', scale = 0.4, colour = G.C.WHITE, shadow = true}},
                              {n=G.UIT.T, config={text = ")", scale = 0.4, colour = G.C.WHITE, shadow = true}},
                            }}
                        }}
                    }},
                    {n=G.UIT.C, config={id = 'next_round_button', align = "cm", minw = 2.8, minh = 0.7, r=0.04,colour = G.C.RED, one_press = true, button = 'toggle_shop', hover = true,shadow = true}, nodes = {
                        {n=G.UIT.R, config={align = "cm", padding = 0.07, focus_args = {button = 'x', orientation = 'cr'}, func = 'set_button_pip'}, nodes={
                            {n=G.UIT.R, config={align = "cm", maxw = 1.3}, nodes={
                                {n=G.UIT.T, config={text = localize('b_exit'), scale = 0.4, colour = G.C.WHITE, shadow = true}},
                            }},
                        }}
                    }},
                }}}
            },
              }, false)
        }}
    return t
end

--------------------------------

table.insert(G.CHALLENGES,#G.CHALLENGES+1,
    {name = 'Dungeon',
        id = 'c_dungeon',
        rules = {
            custom = {
                {id = 'dungeon'},
                -- {id = 'ante_hand_discard_reset'},
                -- {id = 'no_extra_hand_money'},
                {id = 'dungeon_1_ante_4'},
                {id = 'dungeon_1_ante_8'},
            },
            modifiers = {
                {id = 'hands', value = 4},
                {id = 'discards', value = 6},
            }
        },
        jokers = {   
            {id = 'j_splash', eternal = true, edition = 'negative'},
        },
        consumeables = {
            {id = 'c_black_hole'},
            {id = 'c_black_hole'},
        },
        vouchers = {
        },
        deck = {
            type = 'Challenge Deck',
        },
        restrictions = {
            banned_cards = {
                {id = 'j_burglar'},
                -- effective useless
                {id = 'j_crazy'},
                {id = 'j_droll'},
                {id = 'j_devious'},
                {id = 'j_crafty'},
                {id = 'j_four_fingers'},
                {id = 'j_runner'},
                {id = 'j_superposition'},
                {id = 'j_seance'},
                {id = 'j_shortcut'},
                {id = 'j_obelisk'},
                {id = 'j_family'},
                {id = 'j_order'},
                {id = 'j_tribe'},
                -- really useless
                {id = 'j_mime'},
                {id = 'j_raised_fist'},
                {id = 'j_blackboard'},
                {id = 'j_dna'},
                {id = 'j_sixth_sense'},
                {id = 'j_baron'},
                {id = 'j_reserved_parking'},
                {id = 'j_mail'},
                {id = 'j_juggler'},
                {id = 'j_troubadour'},
                {id = 'j_shoot_the_moon'},
                {id = 'j_dusk'},
                {id = 'j_acrobat'},
                -- discard based
                {id = 'j_banner'},
                {id = 'j_mystic_summit'},
                {id = 'j_delayed_grat'},
                {id = 'j_faceless'},
                {id = 'j_green_joker'},
                {id = 'j_drunkard'},
                {id = 'j_trading'},
                {id = 'j_ramen'},
                {id = 'j_castle'},
                {id = 'j_merry_andy'},
                {id = 'j_hit_the_road'},
                {id = 'j_yorick'},
                -- stuntman
                {id = 'j_stuntman'},
                -- non jokers
                {id = 'v_reroll_surplus'},
                {id = 'v_reroll_glut'},
                {id = 'v_overstock_norm'},
                {id = 'v_overstock_plus'},
                {id = 'v_clearance_sale'},
                {id = 'v_liquidation'},
                {id = 'v_paint_brush'},
                {id = 'v_palette'},
                {id = 'v_wasteful'},
                {id = 'v_recyclomancy'},
            },
            banned_tags = {
                {id = 'tag_voucher'},
                {id = 'tag_d_six'},
                {id = 'tag_uncommon'},
                {id = 'tag_rare'},
                {id = 'tag_coupon'},
                {id = 'tag_garbage'},
            },
            banned_other = {
                {id = 'bl_hook', type = 'blind'},
                {id = 'bl_psychic', type = 'blind'},
                {id = 'bl_manacle', type = 'blind'},
                {id = 'bl_eye', type = 'blind'},
                {id = 'bl_serpent', type = 'blind'},
                {id = 'bl_final_bell', type = 'blind'},
            }
        },
    }
)

function G.UIDEF.view_enemy_deck(unplayed_only)
	local deck_tables = {}
	remove_nils(G.enemy_cards or {})
	G.VIEWING_DECK = true
	table.sort(G.enemy_cards or {}, function(a, b) return a:get_nominal('suit') > b:get_nominal('suit') end)
	local SUITS = {}
	local suit_map = {}
	for i = #SMODS.Suit.obj_buffer, 1, -1 do
		SUITS[SMODS.Suit.obj_buffer[i]] = {}
		suit_map[#suit_map + 1] = SMODS.Suit.obj_buffer[i]
	end
	for k, v in ipairs(G.enemy_cards or {}) do
		if v.base.suit then table.insert(SUITS[v.base.suit], v) end
	end
	local num_suits = 0
	for j = 1, #suit_map do
		if SUITS[suit_map[j]][1] then num_suits = num_suits + 1 end
	end
	for j = 1, #suit_map do
		if SUITS[suit_map[j]][1] then
			local view_deck = CardArea(
				G.ROOM.T.x + 0.2 * G.ROOM.T.w / 2, G.ROOM.T.h,
				6.5 * G.CARD_W,
				((num_suits > 8) and 0.2 or (num_suits > 4) and (1 - 0.1 * num_suits) or 0.6) * G.CARD_H,
				{
					card_limit = #SUITS[suit_map[j]],
					type = 'title',
					view_deck = true,
					highlight_limit = 0,
					card_w = G
						.CARD_W * 0.7,
					draw_layers = { 'card' }
				})
			table.insert(deck_tables,
				{n = G.UIT.R, config = {align = "cm", padding = 0}, nodes = {
					{n = G.UIT.O, config = {object = view_deck}}}}
			)

			for i = 1, #SUITS[suit_map[j]] do
				if SUITS[suit_map[j]][i] then
					local greyed, _scale = nil, 0.7
					local copy = copy_card(SUITS[suit_map[j]][i], nil, _scale)
					copy.greyed = greyed
					copy.T.x = view_deck.T.x + view_deck.T.w / 2
					copy.T.y = view_deck.T.y

					copy:hard_set_T()
					view_deck:emplace(copy)
				end
			end
		end
	end

	local flip_col = G.C.WHITE

	local suit_tallies = {}
	local mod_suit_tallies = {}
	for _, v in ipairs(suit_map) do
		suit_tallies[v] = 0
		mod_suit_tallies[v] = 0
	end
	local rank_tallies = {}
	local mod_rank_tallies = {}
	local rank_name_mapping = SMODS.Rank.obj_buffer
	for _, v in ipairs(rank_name_mapping) do
		rank_tallies[v] = 0
		mod_rank_tallies[v] = 0
	end
	local face_tally = 0
	local mod_face_tally = 0
	local num_tally = 0
	local mod_num_tally = 0
	local ace_tally = 0
	local mod_ace_tally = 0
	local wheel_flipped = 0

	for k, v in ipairs(G.enemy_cards or {}) do
		if v.ability.name ~= 'Stone Card' then
			--For the suits
			if v.base.suit then suit_tallies[v.base.suit] = (suit_tallies[v.base.suit] or 0) + 1 end
			for kk, vv in pairs(mod_suit_tallies) do
				mod_suit_tallies[kk] = (vv or 0) + (v:is_suit(kk) and 1 or 0)
			end

			--for face cards/numbered cards/aces
			local card_id = v:get_id()
			if v.base.value then face_tally = face_tally + ((SMODS.Ranks[v.base.value].face) and 1 or 0) end
			mod_face_tally = mod_face_tally + (v:is_face() and 1 or 0)
			if v.base.value and not SMODS.Ranks[v.base.value].face and card_id ~= 14 then
				num_tally = num_tally + 1
				if not v.debuff then mod_num_tally = mod_num_tally + 1 end
			end
			if card_id == 14 then
				ace_tally = ace_tally + 1
				if not v.debuff then mod_ace_tally = mod_ace_tally + 1 end
			end

			--ranks
			if v.base.value then rank_tallies[v.base.value] = rank_tallies[v.base.value] + 1 end
			if v.base.value and not v.debuff then mod_rank_tallies[v.base.value] = mod_rank_tallies[v.base.value] + 1 end
		end
	end
	local modded = face_tally ~= mod_face_tally
	for kk, vv in pairs(mod_suit_tallies) do
		modded = modded or (vv ~= suit_tallies[kk])
		if modded then break end
	end

	if wheel_flipped > 0 then flip_col = mix_colours(G.C.FILTER, G.C.WHITE, 0.7) end

	local rank_cols = {}
	for i = #rank_name_mapping, 1, -1 do
		if rank_tallies[rank_name_mapping[i]] ~= 0 or not SMODS.Ranks[rank_name_mapping[i]].in_pool or SMODS.Ranks[rank_name_mapping[i]]:in_pool({suit=''}) then
			local mod_delta = mod_rank_tallies[rank_name_mapping[i]] ~= rank_tallies[rank_name_mapping[i]]
			rank_cols[#rank_cols + 1] = {n = G.UIT.R, config = {align = "cm", padding = 0.07}, nodes = {
				{n = G.UIT.C, config = {align = "cm", r = 0.1, padding = 0.04, emboss = 0.04, minw = 0.5, colour = G.C.L_BLACK}, nodes = {
					{n = G.UIT.T, config = {text = SMODS.Ranks[rank_name_mapping[i]].shorthand, colour = G.C.JOKER_GREY, scale = 0.35, shadow = true}},}},
				{n = G.UIT.C, config = {align = "cr", minw = 0.4}, nodes = {
					mod_delta and {n = G.UIT.O, config = {
							object = DynaText({
								string = { { string = '' .. rank_tallies[rank_name_mapping[i]], colour = flip_col }, { string = '' .. mod_rank_tallies[rank_name_mapping[i]], colour = G.C.BLUE } },
								colours = { G.C.RED }, scale = 0.4, y_offset = -2, silent = true, shadow = true, pop_in_rate = 10, pop_delay = 4
							})}}
					or {n = G.UIT.T, config = {text = rank_tallies[rank_name_mapping[i]], colour = flip_col, scale = 0.45, shadow = true } },}}}}
		end
	end

	local tally_ui = {
		-- base cards
		{n = G.UIT.R, config = {align = "cm", minh = 0.05, padding = 0.07}, nodes = {
			{n = G.UIT.O, config = {
					object = DynaText({ 
						string = { 
							{ string = localize('k_base_cards'), colour = G.C.RED }, 
							modded and { string = localize('k_effective'), colour = G.C.BLUE } or nil
						},
						colours = { G.C.RED }, silent = true, scale = 0.4, pop_in_rate = 10, pop_delay = 4
					})
				}}}},
		-- aces, faces and numbered cards
		{n = G.UIT.R, config = {align = "cm", minh = 0.05, padding = 0.1}, nodes = {
			tally_sprite(
				{ x = 1, y = 0 },
				{ { string = '' .. ace_tally, colour = flip_col }, { string = '' .. mod_ace_tally, colour = G.C.BLUE } },
				{ localize('k_aces') }
			), --Aces
			tally_sprite(
				{ x = 2, y = 0 },
				{ { string = '' .. face_tally, colour = flip_col }, { string = '' .. mod_face_tally, colour = G.C.BLUE } },
				{ localize('k_face_cards') }
			), --Face
			tally_sprite(
				{ x = 3, y = 0 },
				{ { string = '' .. num_tally, colour = flip_col }, { string = '' .. mod_num_tally, colour = G.C.BLUE } },
				{ localize('k_numbered_cards') }
			), --Numbers
		}},
	}
	-- add suit tallies
	local hidden_suits = {}
	for _, suit in ipairs(suit_map) do
		if suit_tallies[suit] == 0 and SMODS.Suits[suit].in_pool and not SMODS.Suits[suit]:in_pool({rank=''}) then
			hidden_suits[suit] = true
		end
	end
	local i = 1
	local num_suits_shown = 0
	for i = 1, #suit_map do
		if not hidden_suits[suit_map[i]] then
			num_suits_shown = num_suits_shown+1
		end
	end
	local suits_per_row = num_suits_shown > 6 and 4 or num_suits_shown > 4 and 3 or 2
	local n_nodes = {}
	while i <= #suit_map do
		while #n_nodes < suits_per_row and i <= #suit_map do
			if not hidden_suits[suit_map[i]] then
				table.insert(n_nodes, tally_sprite(
					SMODS.Suits[suit_map[i]].ui_pos,
					{
						{ string = '' .. suit_tallies[suit_map[i]], colour = flip_col },
						{ string = '' .. mod_suit_tallies[suit_map[i]], colour = G.C.BLUE }
					},
					{ localize(suit_map[i], 'suits_plural') },
					suit_map[i]
				))
			end
			i = i + 1
		end
		if #n_nodes > 0 then
			local n = {n = G.UIT.R, config = {align = "cm", minh = 0.05, padding = 0.1}, nodes = n_nodes}
			table.insert(tally_ui, n)
			n_nodes = {}
		end
	end
	local t = {n = G.UIT.ROOT, config = {align = "cm", colour = G.C.CLEAR}, nodes = {
		{n = G.UIT.R, config = {align = "cm", padding = 0.05}, nodes = {}},
		{n = G.UIT.R, config = {align = "cm"}, nodes = {
			{n = G.UIT.C, config = {align = "cm", minw = 1.5, minh = 2, r = 0.1, colour = G.C.BLACK, emboss = 0.05}, nodes = {
				{n = G.UIT.C, config = {align = "cm", padding = 0.1}, nodes = {
					{n = G.UIT.R, config = {align = "cm", r = 0.1, colour = G.C.L_BLACK, emboss = 0.05, padding = 0.15}, nodes = {
						{n = G.UIT.R, config = {align = "cm"}, nodes = {
							{n = G.UIT.O, config = {
									object = DynaText({ string = G.GAME.selected_back.loc_name, colours = {G.C.WHITE}, bump = true, rotate = true, shadow = true, scale = 0.6 - string.len(G.GAME.selected_back.loc_name) * 0.01 })
								}},}},
						{n = G.UIT.R, config = {align = "cm", r = 0.1, padding = 0.1, minw = 2.5, minh = 1.3, colour = G.C.WHITE, emboss = 0.05}, nodes = {
							{n = G.UIT.O, config = {
									object = UIBox {
										definition = G.GAME.selected_back:generate_UI(nil, 0.7, 0.5, G.GAME.challenge), config = {offset = { x = 0, y = 0 } }
									}
								}}}}}},
					{n = G.UIT.R, config = {align = "cm", r = 0.1, outline_colour = G.C.L_BLACK, line_emboss = 0.05, outline = 1.5}, nodes = 
						tally_ui}}},
				{n = G.UIT.C, config = {align = "cm"}, nodes = rank_cols},
				{n = G.UIT.B, config = {w = 0.1, h = 0.1}},}},
			{n = G.UIT.B, config = {w = 0.2, h = 0.1}},
			{n = G.UIT.C, config = {align = "cm", padding = 0.1, r = 0.1, colour = G.C.BLACK, emboss = 0.05}, nodes =
				deck_tables}}},
		{n = G.UIT.R, config = {align = "cm", minh = 0.8, padding = 0.05}, nodes = {
			modded and {n = G.UIT.R, config = {align = "cm"}, nodes = {
				{n = G.UIT.C, config = {padding = 0.3, r = 0.1, colour = mix_colours(G.C.BLUE, G.C.WHITE, 0.7)}, nodes = {}},
				{n = G.UIT.T, config = {text = ' ' .. localize('ph_deck_preview_effective'), colour = G.C.WHITE, scale = 0.3}},}}
			or nil,
			wheel_flipped > 0 and {n = G.UIT.R, config = {align = "cm"}, nodes = {
				{n = G.UIT.C, config = {padding = 0.3, r = 0.1, colour = flip_col}, nodes = {}},
				{n = G.UIT.T, config = {
						text = ' ' .. (wheel_flipped > 1 and
							localize { type = 'variable', key = 'deck_preview_wheel_plural', vars = { wheel_flipped } } or
							localize { type = 'variable', key = 'deck_preview_wheel_singular', vars = { wheel_flipped } }),
						colour = G.C.WHITE, scale = 0.3
					}},}}
			or nil,}}}}
	return t
end

----------------------------------------------
------------MOD CODE END----------------------
