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

SMODS.Atlas({ key = "blinds", atlas_table = "ANIMATION_ATLAS", path = "blinds.png", px = 34, py = 34, frames = 21 })

SMODS.Atlas({ key = "blinds2", atlas_table = "ANIMATION_ATLAS", path = "blinds2.png", px = 34, py = 34, frames = 21 })

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

local old_HUD = create_UIBox_HUD_blind
function create_UIBox_HUD_blind()
    local t = old_HUD()
    if G.GAME.modifiers.dungeon then
        local blind_attacks = CardArea(
            G.ROOM.T.x + 0.2*G.ROOM.T.w/2,G.ROOM.T.h,
            2*G.CARD_W,
            0.25*G.CARD_W, 
        {card_limit = 5, type = 'play', highlight_limit = 0})
        local a = {n=G.UIT.R, config={align = "cm", padding = 0, no_fill = true, id = 'blind_attacks'}, nodes={
            {n=G.UIT.C, config={align = "cm", padding = 0, minh = 0.25*G.CARD_W, minw = (2)*G.CARD_W}, nodes = {{n=G.UIT.O, config={object = blind_attacks}}}},
        }}
        table.insert(t.nodes, a)
    end
    return t
end

function add_attack(key, index)
    G.GAME.blind_attacks = G.GAME.blind_attacks or {}
    local area = G.HUD_blind:get_UIE_by_ID("blind_attacks").children
    area = area[1].children[1].config.object
    if index and G.GAME.blind_attacks[index] and area.cards[index] then
        calculate_blind_effect(G.GAME.blind_attacks[index], {remove = true, index = index})
        area.cards[index]:set_ability(G.P_ATTACKS[key])
        G.GAME.blind_attacks[index] = key
        calculate_blind_effect(key, {add = true, index = index})
    else
        local attack = Card(0, 0, 0.8, 0.8, G.P_CARDS["empty"], G.P_ATTACKS[key])
        area:emplace(attack)
        G.GAME.blind_attacks[#area.cards] = key
        calculate_blind_effect(key, {add = true, index = #area.cards})
        return attack
    end
end

function remove_attack(index)
    G.GAME.blind_attacks = G.GAME.blind_attacks or {}
    local area = G.HUD_blind:get_UIE_by_ID("blind_attacks").children[1].children[1].config.object
    if index and G.GAME.blind_attacks[index] then
        calculate_blind_effect(G.GAME.blind_attacks[index], {remove = true, index = index})
        area.cards[index]:set_ability(G.P_ATTACKS["blank"])
        G.GAME.blind_attacks[index] = "blank"
    end
end

function calculate_blind_effect(key, context)
    local area = G.HUD_blind:get_UIE_by_ID("blind_attacks").children[1].children[1].config.object
    local ability_table = area.cards[context.index].ability
    if context.remove then
        if (key == 'debuff_1') or (key == 'debuff_2') then
            for i = 1, #G.playing_cards do
                if G.playing_cards[i].ability.temp_debuff == key .. tostring(context.index) then
                    G.playing_cards[i].ability.temp_debuff = nil
                    G.playing_cards[i]:set_debuff()
                end
            end
        elseif (key == 'raise_1') or (key == 'raise_2') then
            G.GAME.blind.chips = G.GAME.blind.chips / ability_table.size
            G.GAME.blind.chip_text = number_format(G.GAME.blind.chips)
        elseif (key == 'ring_1') or (key == 'ring_2') then
            for k, v in ipairs(G.playing_cards) do
                if v.ability.forced_selection == key .. tostring(context.index) then
                    v.ability.forced_selection = nil
                end
            end
        end
    elseif context.add then
        if (key == 'debuff_1') or (key == 'debuff_2') then
            for i = 1, #G.playing_cards do
                if not G.playing_cards[i].debuff and (pseudorandom('debuff') < G.GAME.probabilities.normal/ability_table.odds) then
                    G.playing_cards[i].ability.temp_debuff = key .. tostring(context.index)
                    G.playing_cards[i]:set_debuff()
                end
            end
        elseif (key == 'raise_1') or (key == 'raise_2') then
            G.GAME.blind.chips = G.GAME.blind.chips * ability_table.size
            G.GAME.blind.chip_text = number_format(G.GAME.blind.chips)
        elseif (key == 'ring_1') or (key == 'ring_2') then
            local any_forced = 0
            for k, v in ipairs(G.hand.cards) do
                if v.ability.forced_selection == key .. tostring(context.index) then
                    any_forced = any_forced + 1
                end
            end
            if any_forced < ability_table.cards then 
                local pool = {}
                for i = 1, #G.hand.cards do
                    table.insert(pool, G.hand.cards[i])
                end
                G.hand:unhighlight_all()
                for i = 1, ability_table.cards - any_forced do
                    if #pool > 0 then
                        local forced_card, index = pseudorandom_element(pool, pseudoseed('ring'))
                        forced_card.ability.forced_selection = key .. tostring(context.index)
                        G.hand:add_to_highlighted(forced_card)
                        table.remove(pool, index)
                    end
                end
            end
        end
    elseif context.drawn_to_hand then
        if (key == 'ring_1') or (key == 'ring_2') then
            local any_forced = 0
            for k, v in ipairs(G.hand.cards) do
                if v.ability.forced_selection == key .. tostring(context.index) then
                    any_forced = any_forced + 1
                end
            end
            if any_forced < ability_table.cards then 
                local pool = {}
                for i = 1, #G.hand.cards do
                    if not G.hand.cards[i].ability.forced_selection then
                        table.insert(pool, G.hand.cards[i])
                    end
                end
                G.hand:unhighlight_all()
                for i = 1, ability_table.cards - any_forced do
                    if #pool > 0 then
                        local forced_card, index = pseudorandom_element(pool, pseudoseed('ring'))
                        forced_card.ability.forced_selection = key .. tostring(context.index)
                        G.hand:add_to_highlighted(forced_card)
                        table.remove(pool, index)
                    end
                end
            end
        end
    end
end

function add_dungeon_attack()
    if G.GAME.blind.chips <= G.GAME.chips then
        return
    end
    local index = -1
    for i = 1, #G.GAME.blind_attacks do
        if G.GAME.blind_attacks[i] == "blank" then
            index = i
            break
        end
    end
    if index == -1 then
        local pool1 = {}
        index = math.min(#G.GAME.blind_attacks, 1 + math.floor((#G.GAME.blind_attacks) * pseudorandom('attack')))
    end
    local forced_selection_count = 0
    for i, j in ipairs(G.GAME.blind_attacks) do
        if j == 'ring_1' then
            forced_selection_count = forced_selection_count + 1
        elseif j == 'ring_2' then
            forced_selection_count = forced_selection_count + 2
        end
    end
    local pool = {}
    local total = 0
    for i, j in pairs(G.BL_EFFECT_PATTERNS[G.GAME.blind.config.blind.key] or G.BL_EFFECT_PATTERNS['bl_boss']) do
        if i ~= G.GAME.blind_attacks[index] then
            local valid = true
            if i == 'raise_1' and (G.GAME.blind.chips / 1.2 <= G.GAME.chips) then
                valid = false
            elseif i == 'raise_2' and (G.GAME.blind.chips / 1.5 <= G.GAME.chips) then
                valid = false
            elseif i == 'ring_1' and (forced_selection_count > 2) then
                valid = false
            elseif i == 'ring_2' and (forced_selection_count > 1) then
                valid = false
            end
            if valid then
                total = total + j.weight
                table.insert(pool, {key = i, weight = j.weight})
            end
        end
    end
    if #pool == 0 then
        return
    end
    local picked = total * pseudorandom('dungeon')
    local key = nil
    while (picked > 0) and pool[1] do
        key = pool[1].key
        picked = picked - pool[1].weight
        table.remove(pool, 1)
    end
    if not key then
        key = pool[#pool].key
    end
    add_attack(key, index)
end

G.FUNCS.can_common = function(e)
    if ((G.GAME.dollars-G.GAME.bankrupt_at) - 3 < 0) then 
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
    local total = j_total + t_total + p_total + c_total
    local rng = total * pseudorandom('common')
    local card
    if rng < j_total then
        card = SMODS.create_card {set = "Joker", no_edition = true, rarity = 0, area = G.shop_jokers}
    elseif rng < j_total + t_total then
        card = SMODS.create_card {set = "Tarot", no_edition = true, area = G.shop_jokers}
    elseif (rng < j_total + t_total + p_total) or (c_total == 0) then
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
end

G.FUNCS.can_uncommon = function(e)
    if ((G.GAME.dollars-G.GAME.bankrupt_at) - 6 < 0) then 
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
        G.shop_jokers.T.y, G.CARD_W*1.27, G.CARD_H*1.27, G.P_CARDS.empty, get_pack('dungeon'), {bypass_discovery_center = true, bypass_discovery_ui = true})
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
end

G.FUNCS.can_rare = function(e)
    if ((G.GAME.dollars-G.GAME.bankrupt_at) - 10 < 0) then 
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
    if rng < 0.6 then
        card = SMODS.create_card {set = "Joker", rarity = 0.99, area = G.shop_jokers}
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

table.insert(G.CHALLENGES,#G.CHALLENGES+1,
    {name = 'Dungeon',
        id = 'c_dungeon',
        rules = {
            custom = {
                {id = 'dungeon'},
                {id = 'ante_hand_discard_reset'},
                {id = 'no_extra_hand_money'},
                {id = 'dungeon_1_ante_4'},
                {id = 'dungeon_1_ante_8'},
            },
            modifiers = {
                {id = 'hands', value = 8},
                {id = 'discards', value = 6},
            }
        },
        jokers = {       
        },
        consumeables = {
        },
        vouchers = {
        },
        deck = {
            type = 'Challenge Deck',
        },
        restrictions = {
            banned_cards = {
                {id = 'j_burglar'},
                {id = 'v_reroll_surplus'},
                {id = 'v_reroll_glut'},
                {id = 'v_overstock_norm'},
                {id = 'v_overstock_plus'},
                {id = 'v_clearance_sale'},
                {id = 'v_liquidation'},
            },
            banned_tags = {
                {id = 'tag_voucher'},
                {id = 'tag_d_six'},
                {id = 'tag_uncommon'},
                {id = 'tag_rare'},
                {id = 'tag_coupon'},
            },
            banned_other = {
            }
        },
    }
)

----------------------------------------------
------------MOD CODE END----------------------
