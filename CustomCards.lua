--- STEAMODDED HEADER
--- MOD_NAME: Custom Playing Cards
--- MOD_ID: CustomCards
--- PREFIX: pc
--- MOD_AUTHOR: [mathguy]
--- MOD_DESCRIPTION: Playing Cards with special abilities.
--- VERSION: 1.0.0
----------------------------------------------
------------MOD CODE -------------------------

SMODS.Enhancement {
    key = 'trading',
    name = "Speical Card",
    config = {},
    replace_base_card = true,
    no_suit = true,
    no_rank = true,
    pos = {x = 0, y = 0},
    in_pool = function(self)
        return false
    end,
    loc_text = {
        name = "Trading"
    }
}

SMODS.Atlas({ key = "trading", atlas_table = "ASSET_ATLAS", path = "cards.png", px = 71, py = 95})

SMODS.Atlas({ key = "tarots", atlas_table = "ASSET_ATLAS", path = "tarots.png", px = 71, py = 95})

SMODS.Atlas({ key = "decks", atlas_table = "ASSET_ATLAS", path = "decks.png", px = 71, py = 95})

SMODS.Atlas({ key = "booster", atlas_table = "ASSET_ATLAS", path = "boosters.png", px = 71, py = 95})

SMODS.Atlas({ key = "tags", atlas_table = "ASSET_ATLAS", path = "tags.png", px = 34, py = 34})

SMODS.current_mod.custom_collection_tabs = function()
	return { UIBox_button {
        count = G.ACTIVE_MOD_UI and modsCollectionTally(G.P_CENTER_POOLS["Exotic"]),
        button = 'your_collection_trading_cards',
        label = {"Cards"}, minw = 5, id = 'your_collection_trading_cards'
    }}
end

function create_UIBox_Trading()
    local deck_tables = {}

    G.your_collection = {}
    for j = 1, 2 do
      G.your_collection[j] = CardArea(
        G.ROOM.T.x + 0.2*G.ROOM.T.w/2,G.ROOM.T.h,
        (5.25)*G.CARD_W,
        1*G.CARD_H, 
        {card_limit = 5, type = 'title', highlight_limit = 0, collection = true})
      table.insert(deck_tables, 
      {n=G.UIT.R, config={align = "cm", padding = 0, no_fill = true}, nodes={
        {n=G.UIT.O, config={object = G.your_collection[j]}}
      }}
      )
    end

    local tarot_options = {}
    for i = 1, math.ceil(#G.P_CENTER_POOLS['Exotic']/10) do
      table.insert(tarot_options, localize('k_page')..' '..tostring(i)..'/'..tostring(math.ceil(#G.P_CENTER_POOLS['Exotic']/10)))
    end
  
    for j = 1, #G.your_collection do
        for i = 1, 5 do
            if (i+(j-1)*(5)) <= #G.P_CENTER_POOLS['Exotic'] then
                local trading = G.P_CENTER_POOLS['Exotic'][i+(j-1)*(5)]
                local card = Card(G.your_collection[j].T.x + G.your_collection[j].T.w/2, G.your_collection[j].T.y, G.CARD_W, G.CARD_H, G.P_CARDS[trading.base], G.P_CENTERS.c_base)
                card:start_materialize(nil, i>1 or j>1)
                card:set_ability(G.P_CENTERS["m_pc_trading"], true)
                card.ability.trading = copy_table(trading)
                card:set_sprites(card.config.center)
                G.your_collection[j]:emplace(card)
                card.playing_card = true
            end
        end
    end
  
    INIT_COLLECTION_CARD_ALERTS()
    
    local t = create_UIBox_generic_options({ back_func = G.ACTIVE_MOD_UI and "openModUI_"..G.ACTIVE_MOD_UI.id or 'your_collection', contents = {
              {n=G.UIT.R, config={align = "cm", minw = 2.5, padding = 0.1, r = 0.1, colour = G.C.BLACK, emboss = 0.05}, nodes=deck_tables},
                    {n=G.UIT.R, config={align = "cm"}, nodes={
                      create_option_cycle({options = tarot_options, w = 4.5, cycle_shoulders = true, opt_callback = 'your_collection_trading_page', focus_args = {snap_to = true, nav = 'wide'},current_option = 1, colour = G.C.RED, no_pips = true})
                    }}
            }})
    return t
end

G.FUNCS.your_collection_trading_cards = function(e)
	G.SETTINGS.paused = true
	G.FUNCS.overlay_menu{
	  definition = create_UIBox_Trading(),
	}
end

G.FUNCS.your_collection_trading_page = function(args)
    if not args or not args.cycle_config then return end
    for j = 1, #G.your_collection do
        for i = #G.your_collection[j].cards,1, -1 do
            local c = G.your_collection[j]:remove_card(G.your_collection[j].cards[i])
            c:remove()
            c = nil
        end
    end
    for i = 1, 5 do
        for j = 1, #G.your_collection do
            local trading = G.P_CENTER_POOLS['Exotic'][i+(j-1)*5 + (5*#G.your_collection*(args.cycle_config.current_option - 1))]
            if not trading then break end
            local card = Card(G.your_collection[j].T.x + G.your_collection[j].T.w/2, G.your_collection[j].T.y, G.CARD_W, G.CARD_H, G.P_CARDS[trading.base], G.P_CENTERS.c_base)
            card:set_ability(G.P_CENTERS["m_pc_trading"], true)
            card.ability.trading = copy_table(trading)
            card:set_sprites(card.config.center)
            G.your_collection[j]:emplace(card)
            card.playing_card = true
        end
    end
    INIT_COLLECTION_CARD_ALERTS()
end

function Card:calculate_exotic(context, do_repeat)
    local new_do_repeat = {self}
    if do_repeat then
        for j = 1, #do_repeat do
            table.insert(new_do_repeat, do_repeat[j])
        end
    end
    if self.ability and self.doubled_down and context.after then
        self:set_ability(G.P_CENTERS["m_pc_trading"])
        self.ability.trading = copy_table(G.P_TRADING['double_down'])
        self:set_sprites(self.config.center)
        local doubled = self.doubled_down
        self.doubled_down = nil
        self.ability = doubled.ability
        self:set_edition(doubled.edition, true, true)
        self:set_seal(doubled.seal, true, true)
        self:set_base(doubled.base)
        self:juice_up()
        return {}
    end
    if self.debuff then
        if context.does_score then
            return false
        elseif context.is_suit or context.get_id or context.is_face then
            
        else
            return {}
        end
    end
    local obj = self.config.center
    local name = self.ability.trading and self.ability.trading.name
    if not name then
        if context.does_score then
            return false
        elseif context.is_suit or context.get_id or context.is_face then
            return nil
        else
            return {}
        end
    end
    local effects = {}
    local reps = {1}
    local i = 1
    while (i <= #reps) do
        local valid = true
        if do_repeat and (i ~= 1) then
            for j = 1, #do_repeat do
                if (i ~= 1) and (do_repeat[j] == self) then
                    valid = false
                end
            end
        end
        if valid then
            if i ~= 1 then
                if reps[i] then
                    if reps[i].cards then
                        if context.using_consumeable then
                            for j = ((context.individual) and (context.cardarea == G.play) and 1) or 1, #reps[i].cards do
                                local m = reps[i]
                                card_eval_status_text(m.cards[j], 'jokers', nil, nil, nil, m)
                            end
                        else
                            for j = ((context.individual) and (context.cardarea == G.play) and 1) or 1, #reps[i].cards do
                                local m = reps[i]
                                table.insert(effects, {extra = {func = function()
                                    card_eval_status_text(m.cards[j], 'jokers', nil, nil, nil, m)
                                end}})
                            end
                        end
                    end
                end
            end
            local config_thing = self.ability.trading.config 
            if context.individual and (context.cardarea == G.play) then
                if self.area == G.play then
                    if name == "Golden Ratio" then
                        local first_fib = nil
                        for j = 1, #context.scoring_hand do
                            local id = context.scoring_hand[j]:get_id()
                            if (id == 2) or (id == 3) or (id == 5) or (id == 8) or (id == 14) then
                                first_fib = context.scoring_hand[j]
                                break
                            end
                        end
                        if context.other_card == first_fib then
                            table.insert(effects, {
                                dollars = config_thing.dollars,
                                x_mult = config_thing.x_mult,
                                card = context.other_card
                            })
                        end
                    end
                elseif self.area == G.hand then

                end
            elseif context.individual and (context.cardarea == G.hand) then
                if self.area == G.play then
                    if name == "Pocket Ace" then
                        if context.other_card:get_id() == 14 then
                            table.insert(effects, {
                                pc_h_chips = config_thing.h_chips,
                                card = self
                            })
                        end
                    end
                elseif self.area == G.hand then

                end
            elseif context.playing_card_main then
                if name == "Flint Card" then
                    table.insert(effects, {
                        mult = config_thing.mult,
                        card = self
                    })
                elseif name == "Scholar's Mate" then
                    local mult = (G.GAME.current_round.hands_played == 1) and config_thing.mult or nil
                    table.insert(effects, {
                        chips = config_thing.chips,
                        mult = mult,
                        card = self
                    })
                elseif name == "Scandinavian Defense" then
                    local valid = true
                    for i = 1, #context.scoring_hand do
                        if context.scoring_hand[i]:is_suit("Spades") or context.scoring_hand[i]:is_suit("Clubs") then
                            valid = false
                        end
                    end
                    table.insert(effects, {
                        chips = config_thing.chips,
                        mult = valid and config_thing.mult or nil,
                        card = self
                    })
                elseif name == "Eye Card" then
                    table.insert(effects, {
                        chips = config_thing.chips,
                        card = self
                    })
                elseif name == "Sunflower" then
                    table.insert(effects, {
                        chips = config_thing.chips,
                        card = self
                    })
                    config_thing.chips = config_thing.chips + config_thing.gain
                    table.insert(effects, {extra = {message = localize{type='variable',key='a_chips',vars={config_thing.gain}}, colour = G.C.BLUE}})
                elseif name == "Wild Draw 4" then
                    table.insert(effects, {
                        chips = config_thing.chips,
                        card = self
                    })
                elseif name == "Jack in a Box" then
                    table.insert(effects, {
                        chips = config_thing.chips,
                        card = self
                    })
                    config_thing.scored = config_thing.scored + 1
                    if config_thing.scored >= config_thing.scores then
                        config_thing.scored = 0
                        table.insert(effects, {extra = {func = function()
                            G.E_MANAGER:add_event(Event({ func = function()
                                local suit = pseudorandom_element(SMODS.Suits, pseudoseed('jack'))
                                local card = Card(self.T.x, self.T.y, G.CARD_W, G.CARD_H, G.P_CARDS["H_J"], G.P_CENTERS['c_base'], {playing_card = G.playing_card})
                                SMODS.change_base(card, suit.key)
                                local pool = {}
                                for k, v in pairs(G.P_CENTER_POOLS["Enhanced"]) do
                                    if (v.key ~= 'm_stone') and (v.key ~= 'm_pc_trading') then 
                                        local valid = true
                                        if v.in_pool and (type(v.in_pool) == "function") and not v:in_pool() then
                                            valid = false
                                        end
                                        if valid then
                                            pool[#pool+1] = v
                                        end
                                    end
                                end
                                local center = pseudorandom_element(pool, pseudoseed('jack'))
                                card:set_ability(center)
                                card:flip()
                                G.deck:emplace(card)
                                table.insert(G.playing_cards, card)
                                card:set_sprites(card.config.center)
                                return true
                            end
                            }))
                        end, message = "+1 " .. localize("Jack", 'ranks')}})
                    end
                elseif name == "2mbstone" then
                    table.insert(effects, {
                        chips = config_thing.chips,
                        card = self
                    })
                elseif name == "Mane 6" then
                    local total_x_mult = 1
                    for j = 1, #G.play.cards do
                        if G.play.cards[j].ability and G.play.cards[j].ability.trading and (G.play.cards[j].ability.trading.name == "Mane 6") then
                            total_x_mult = total_x_mult + config_thing.x_mult
                        end
                    end
                    table.insert(effects, {
                        chips = config_thing.chips,
                        x_mult = (total_x_mult ~= 1) and total_x_mult or nil,
                        card = self
                    })
                elseif name == ":3" then
                    table.insert(effects, {
                        chips = config_thing.chips,
                        card = self
                    })
                    config_thing.scored = config_thing.scored + 1
                    if config_thing.scored == config_thing.scores then
                        table.insert(effects, {extra = {func = function()
                            G.E_MANAGER:add_event(Event({ func = function()
                                if G.jokers.config.card_limit > #G.jokers.cards then
                                    local card = create_card('Joker', G.jokers, true, nil, nil, nil, nil, '3')
                                    card:add_to_deck()
                                    card.ability.perishable = true
                                    card.ability.perish_tally = G.GAME.perishable_rounds
                                    card.ability.force_perish = true
                                    G.jokers:emplace(card)
                                end
                                return true
                            end
                            }))
                        end, message = "+1 " .. localize("k_legendary")}})
                    end
                elseif name == "Executor" then
                    table.insert(effects, {
                        chips = config_thing.chips,
                        card = self
                    })
                elseif name == "Monarch" then
                    table.insert(effects, {
                        chips = config_thing.chips,
                        card = self
                    })
                elseif name == "Meteor" then
                    table.insert(effects, {
                        chips = config_thing.chips,
                        card = self
                    })
                elseif name == "Bust Card" then
                    table.insert(effects, {
                        mult = config_thing.mult,
                        card = self
                    })
                elseif name == "Old Bell" then
                    table.insert(effects, {
                        chips = config_thing.chips,
                        x_mult = config_thing.x_mult,
                        card = self
                    })
                end
            elseif context.playing_card_hand then
                if name == "Aluminum Plate" then
                    table.insert(effects, {
                        x_mult = config_thing.h_x_mult,
                        card = self
                    })
                end
            elseif context.discard and (context.other_card == self) then
                if name == "Playable Joker" then
                    local pool = {}
                    for i, j in ipairs(G.hand.cards) do
                        local card = G.hand.cards[i]
                        if not card.edition and (card ~= self) then
                            table.insert(pool, card)
                        end
                    end
                    if #pool > 0 then
                        if pseudorandom('joker') < G.GAME.probabilities.normal/config_thing.odds then
                            local card = pseudorandom_element(pool, pseudoseed('aura_joker'))
                            local edition = poll_edition('wheel_of_fortune', nil, false, true, {'e_polychrome', 'e_holo', 'e_foil'})
                            card:set_edition(edition)
                        else
                            card_eval_status_text(self, 'jokers', nil, nil, nil, {message = localize('k_nope_ex'), colour = G.C.SECONDARY_SET.Tarot})
                        end
                    end
                end
            elseif context.pre_discard then
                if name == "Haunted Card" then
                    card_eval_status_text(self, 'jokers', nil, nil, nil, {message = localize{type='variable',key='a_cards',vars={config_thing.cards}}})
                    local size = math.min(#G.deck.cards, config_thing.cards)
                    G.E_MANAGER:add_event(Event({
                        trigger = 'before',
                        delay = 0.1,
                        func = function()
                            phantom_cards = true
                            return true
                        end
                    }))
                    G.GAME.pc_hand_size_bonus = (G.GAME.pc_hand_size_bonus or 0) + config_thing.cards
                    for i = 1, config_thing.cards do
                        draw_card(G.deck,G.hand, i*100/size,'up', true)
                        delay(0.1)
                    end
                    G.E_MANAGER:add_event(Event({
                        trigger = 'before',
                        delay = 0.1,
                        func = function()
                            phantom_cards = nil
                            return true
                        end
                    }))
                end
            elseif context.before then
                if name == "Rules Card" then
                    ease_discard(1)
                    card_eval_status_text(self, 'jokers', nil, nil, nil, {message = localize{type='variable',key='a_discards',vars={config_thing.discards}}, colour = G.C.RED})
                elseif name == "Wild Draw 4" then
                    card_eval_status_text(self, 'jokers', nil, nil, nil, {message = localize{type='variable',key='a_cards',vars={config_thing.cards}}})
                    local size = math.min(#G.deck.cards, config_thing.cards)
                    for i = 1, config_thing.cards do
                        draw_card(G.deck,G.hand, i*100/size,'up', true)
                        delay(0.1)
                    end
                elseif name == "2mbstone" then
                    if (G.consumeables.config.card_limit > #G.consumeables.cards + G.GAME.consumeable_buffer) and (pseudorandom('tom') < G.GAME.probabilities.normal/config_thing.odds) then
                        card_eval_status_text(self, 'jokers', nil, nil, nil, {message = localize('k_plus_tarot'), colour = G.C.PURPLE})
                        G.GAME.consumeable_buffer = (G.GAME.consumeable_buffer or 0) + 1
                        G.E_MANAGER:add_event(Event({func = function()
                            local card = create_card('', G.consumeables, nil, nil, nil, nil, 'c_death', 'fool')
                            card:add_to_deck()
                            G.consumeables:emplace(card)
                            G.GAME.consumeable_buffer = 0
                        return true end }))
                    end
                elseif name == "Executor" then
                    if #G.hand.cards > 0 then
                        local card = pseudorandom_element(G.hand.cards, pseudoseed('exec'))
                        if card.ability and (card.ability.name == 'Glass Card') then 
                            card:shatter()
                        else
                            card:start_dissolve()
                        end
                        config_thing.destroyed = config_thing.destroyed + 1
                        if config_thing.destroyed >= config_thing.destroys then
                            config_thing.destroyed = 0
                            G.E_MANAGER:add_event(Event({ func = function()
                                local card = copy_card(self, nil, nil, true)
                                card:flip()
                                G.deck:emplace(card)
                                table.insert(G.playing_cards, card)
                                return true
                            end
                            }))
                        end
                    end
                end
            elseif context.destroying_card then
                if name == ":3" then
                    if config_thing.scored >= config_thing.scores then
                        return true
                    end
                end
            elseif context.very_before then
                if context.random_order then
                    if name == "Double Down" then
                        local pool = {}
                        for j = 1, #G.play.cards do
                            if (G.play.cards[j] ~= self) then
                                table.insert(pool, G.play.cards[j])
                            end
                        end
                        if #pool > 0 then
                            local card = pseudorandom_element(pool, pseudoseed('down'))
                            local doubled = {
                                ability = copy_table(self.ability),
                                base = self.config.card,
                                edition = self.edition,
                                seal = self.seal
                            }
                            copy_card(card, self, nil, true)
                            self:juice_up()
                            self.doubled_down = doubled
                        end
                    end
                else

                end
            elseif context.after then
            elseif context.drawn then
                if context.drawn == G.hand then
                    if name == "Meteor" then
                        if context.facing_blind then
                            self.ability.already_drawn = G.GAME.round
                            for i = 1, config_thing.cards do
                                local card = create_playing_card({
                                    front = pseudorandom_element(G.P_CARDS, pseudoseed('met')), 
                                    center = G.P_CENTERS.c_base}, G.hand, nil, nil, {G.C.SECONDARY_SET.Enhanced})
                                card.ability.fleeting = true
                                card:set_ability(G.P_CENTERS['m_stone'])
                                G.GAME.blind:debuff_card(card)
                                G.hand:sort()
                            end
                        end
                    elseif name == "Bust Card" then
                        if context.facing_blind then
                            self.ability.already_drawn = G.GAME.round
                            local pool = {}
                            for i, j in ipairs(G.hand.cards) do
                                local card = G.hand.cards[i]
                                if not card.edition and (card ~= self) then
                                    table.insert(pool, card)
                                end
                            end
                            card_eval_status_text(self, 'jokers', nil, nil, nil, {message = localize('k_bust'), colour = G.C.RED})
                            for i = 1, config_thing.cards do
                                if #pool > 0 then
                                    local card, index = pseudorandom_element(pool, pseudoseed('bust'))
                                    table.remove(pool, index)
                                    card.ability.temp_debuff = true
                                    card:set_debuff()
                                end
                            end
                        end
                    end
                end
            elseif context.using_consumeable then
                if name == "Fortune Orb" then
                    if context.using_consumeable.ability and context.using_consumeable.ability.set == 'Tarot' then
                        card_eval_status_text(self, 'jokers', nil, nil, nil, {message = localize{type='variable',key='a_cards',vars={config_thing.cards}}})
                        local size = math.min(#G.deck.cards, config_thing.cards)
                        G.E_MANAGER:add_event(Event({
                            trigger = 'before',
                            delay = 0.1,
                            func = function()
                                phantom_cards = true
                                return true
                            end
                        }))
                        for i = 1, config_thing.cards do
                            draw_card(G.deck,G.hand, i*100/size,'up', true)
                            delay(0.1)
                        end
                        G.E_MANAGER:add_event(Event({
                            trigger = 'before',
                            delay = 0.1,
                            func = function()
                                phantom_cards = nil
                                return true
                            end
                        }))
                        table.insert(effects, {})
                    end
                end
            elseif context.does_score then
                if name == "Double Up" then
                    return true
                elseif name == "Rules Card" then
                    return true
                elseif name == "Blank Card" then
                    return "remove"
                elseif name == "Meteor" then
                    return true
                elseif name == "Bust Card" then
                    return true
                end
                return false
            elseif context.is_suit then
                if name == "Flint Card" then
                    if (context.is_suit == "Hearts") or (context.is_suit == "Diamonds") then
                        return true
                    end
                elseif name == "Eye Card" then
                    if (context.is_suit == "Clubs") or (context.is_suit == "Spades") then
                        return true
                    end
                elseif name == "Wild Draw 4" then
                    return true
                elseif name == "Golden Ratio" then
                    if ((context.is_suit == "Hearts") and next(find_joker('Smeared Joker'))) or (context.is_suit == "Diamonds") then
                        return true
                    end
                elseif name == "Pocket Ace" then
                    if ((context.is_suit == "Clubs") and next(find_joker('Smeared Joker'))) or (context.is_suit == "Spades") then
                        return true
                    end
                elseif name == "Monarch" then
                    if (context.is_suit == "Hearts") or (context.is_suit == "Clubs") or (context.is_suit == "Spades") or ((context.is_suit == "Diamonds") and next(find_joker('Smeared Joker'))) then
                        return true
                    end
                elseif name == "Old Bell" then
                    if ((context.is_suit == "Spades") and next(find_joker('Smeared Joker'))) or (context.is_suit == "Clubs") then
                        return true
                    end
                end
                return false
            elseif context.is_face then
                if name == "Scholar's Mate" then
                    return true
                elseif name == "Scandinavian Defense" then
                    return true
                elseif name == "Jack in a Box" then
                    return true
                elseif name == "Playable Joker" then
                    return true
                elseif name == ":3" then
                    return true
                elseif name == "Executor" then
                    return true
                elseif name == "Monarch" then
                    return true
                end
                return false
            elseif context.get_id then
                if name == "Scholar's Mate" then
                    return 12
                elseif name == "Scandinavian Defense" then
                    return 12
                elseif name == "Sunflower" then
                    return 8
                elseif name == "Wild Draw 4" then
                    return 4
                elseif name == "Jack in a Box" then
                    return 11
                elseif name == "2mbstone" then
                    return 2
                elseif name == "Mane 6" then
                    return 6
                elseif name == "Blank Card" then
                    if config_thing.rank then
                        return config_thing.rank
                    end
                elseif name == ":3" then
                    return 3
                elseif name == "Pocket Ace" then
                    return 14
                elseif name == "Executor" then
                    return 3
                elseif name == "Monarch" then
                    return 13
                elseif name == "Fortune Orb" then
                    return 12
                elseif name == "Old Bell" then
                    return 13
                end
                return -math.random(100, 1000000)
            elseif context.repetition then
                local special_table = {self}
                if i ~= 1 then
                    for j = 1, #reps[i].cards do
                        table.insert(special_table, reps[i].cards[j])
                    end
                end
                if context.cardarea == G.play then
                    if name == "Double Up"  then
                        local index = -1
                        for j = 1, #G.play.cards do
                            if G.play.cards[j] == self then
                                index = j
                            end
                        end
                        if (index ~= -1) and (G.play.cards[index + 1] == context.other_card) then
                            table.insert(effects, {
                                message = localize('k_again_ex'),
                                repetitions = config_thing.retriggers,
                                cards = special_table
                            })
                        end
                    end
                end
            end
            if do_repeat and next(effects) and (i == 1) then
                for j = 1, #do_repeat do
                    if do_repeat[j] == self then
                        return {}
                    end
                end
                local eval = eval_card(self, {cardarea = self.area, repetition = true, repetition_only = true, full_hand = context.full_hand, scoring_hand = context.scoring_hand, scoring_name = context.scoring_name, poker_hands = context.poker_hands, card_effects = {{card = self}}})
                if next(eval) then 
                    local new_table = {eval.seals.card}
                    for g = 1, #do_repeat do
                        table.insert(new_table, do_repeat[g])
                    end
                    for h= 1, eval.seals.repetitions do
                        reps[#reps+1] = {
                            cards = new_table,
                            message = eval.seals.message,
                            repetitions = eval.seals.repetitions,
                        }
                    end
                end

                --from Jokers
                for l=1, #G.jokers.cards do
                    --calculate the joker effects
                    local eval = eval_card(G.jokers.cards[l], {cardarea = self.area, other_card = self, repetition = true, end_of_round = context.end_of_round, full_hand = context.full_hand, scoring_hand = context.scoring_hand, scoring_name = context.scoring_name, poker_hands = context.poker_hands, card_effects = {{card = self}}})
                    if eval and next(eval) then 
                        local new_table = {eval.jokers.card}
                        for g = 1, #do_repeat do
                            table.insert(new_table, do_repeat[g])
                        end
                        for h = 1, eval.jokers.repetitions do
                            reps[#reps+1] = {
                                cards = new_table,
                                message = eval.jokers.message,
                                repetitions = eval.jokers.repetitions,
                            }
                        end
                    end
                end

                if context.scoring_hand then
                    for l=1, #context.scoring_hand do
                        --calculate the joker effects
                        local eval = context.scoring_hand[l]:calculate_exotic({cardarea = self.area, other_card = self, repetition = true, end_of_round = context.end_of_round, full_hand = context.full_hand, scoring_hand = context.scoring_hand, scoring_name = context.scoring_name, poker_hands = context.poker_hands}, new_do_repeat)
                        if next(eval) then
                            for _, minieval in ipairs(eval) do
                                if minieval.repetitions then
                                    for h = 1, minieval.repetitions do
                                        reps[#reps+1] = minieval
                                    end
                                end
                            end
                        end
                    end
                end

                for l=1, #G.hand.cards do
                    --calculate the joker effects
                    local eval = G.hand.cards[l]:calculate_exotic({cardarea = self.area, other_card = self, repetition = true, end_of_round = context.end_of_round, full_hand = context.full_hand, scoring_hand = context.scoring_hand, scoring_name = context.scoring_name, poker_hands = context.poker_hands}, new_do_repeat)
                    if next(eval) then
                        for _, minieval in ipairs(eval) do
                            if minieval.repetitions then
                                for h = 1, minieval.repetitions do
                                    reps[#reps+1] = minieval
                                end
                            end
                        end
                    end
                end
            end
        end
        i = i + 1
    end
    return effects
end

SMODS.Tarot {
    key = 'exchange',
    atlas = "tarots",
    pos = {x = 0, y = 0},
    config = {max_highlighted = 1},
    use = function(self, card, area, copier)
        local used_tarot = copier or card
        G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.4, func = function()
            play_sound('tarot1')
            used_tarot:juice_up(0.3, 0.5)
            return true end }))
        for i=1, #G.hand.highlighted do
            local percent = 1.15 - (i-0.999)/(#G.hand.highlighted-0.998)*0.3
            G.E_MANAGER:add_event(Event({trigger = 'after',delay = 0.15,func = function() G.hand.highlighted[i]:flip();play_sound('card1', percent);G.hand.highlighted[i]:juice_up(0.3, 0.3);return true end }))
        end
        delay(0.2)
        for i=1, #G.hand.highlighted do
            G.E_MANAGER:add_event(Event({trigger = 'after',delay = 0.1,func = function()
                local key = get_trading_key()
                G.hand.highlighted[i]:set_ability(G.P_CENTERS["m_pc_trading"])
                G.hand.highlighted[i].ability.trading = copy_table(G.P_TRADING[key])
                G.hand.highlighted[i]:set_base(G.P_CARDS[G.P_TRADING[key].base])
                G.hand.highlighted[i]:set_sprites(G.hand.highlighted[i].config.center)
                return true 
            end }))
        end
        delay(0.6)
        for i=1, #G.hand.highlighted do
            local percent = 0.85 + (i-0.999)/(#G.hand.highlighted-0.998)*0.3
            G.E_MANAGER:add_event(Event({trigger = 'after',delay = 0.15,func = function() G.hand.highlighted[i]:flip();play_sound('tarot2', percent, 0.6);G.hand.highlighted[i]:juice_up(0.3, 0.3);return true end }))
        end
        G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.2,func = function() G.hand:unhighlight_all(); return true end }))
        delay(0.5)
    end,
    loc_vars = function(self, info_queue, card)
        return {vars = {card and card.ability.consumeable.max_highlighted or 1} }
    end
}

SMODS.Tag {
    key = 'print',
    atlas = 'tags',
    pos = {x = 0, y = 0},
    apply = function(self, tag, context)
        if context.type == 'new_blind_choice' then
            local lock = tag.ID
            G.CONTROLLER.locks[lock] = true
            tag:yep('+', G.C.RED,function() 
                local key = 'p_pc_trading_mega_1'
                local card = Card(G.play.T.x + G.play.T.w/2 - G.CARD_W*1.27/2,
                G.play.T.y + G.play.T.h/2-G.CARD_H*1.27/2, G.CARD_W*1.27, G.CARD_H*1.27, G.P_CARDS.empty, G.P_CENTERS[key], {bypass_discovery_center = true, bypass_discovery_ui = true})
                card.cost = 0
                card.from_tag = true
                G.FUNCS.use_card({config = {ref_table = card}})
                card:start_materialize()
                G.CONTROLLER.locks[lock] = nil
                return true
            end)
            tag.triggered = true
            return true
        end
    end,
    loc_vars = function(self, info_queue, tag)
        info_queue[#info_queue+1] = G.P_CENTERS['p_pc_trading_mega_1']
        return {}
    end,
    config = {type = 'new_blind_choice'}
}

SMODS.Back {
    key = 'Collected',
    loc_txt = {
        name = "Collected Deck",
        text = {
            "Start with {C:attention}5{}",
            "{C:attention}Trading Cards{}"
        }
    },
    atlas = "decks",
    pos = {x = 0, y = 0},
    name = "Stuff Deck",
    apply = function(self)
        G.E_MANAGER:add_event(Event({
            func = function()
                for i = 1, 5 do
                    local card = pseudorandom_element(G.playing_cards, pseudoseed('collect'))
                    card:remove()
                end
                for i = 1, 5 do
                    local key = G.P_TRADING[get_trading_key()]
                    local _card = Card(G.deck.T.x, G.deck.T.y, G.CARD_W, G.CARD_H, G.P_CARDS[key.base], G.P_CENTERS['m_pc_trading'], {playing_card = G.playing_card})
                    _card.ability.trading = copy_table(key)
                    _card:set_sprites(_card.config.center)
                    G.deck:emplace(_card)
                    table.insert(G.playing_cards, _card)
                end
            return true
            end
        }))
    end
}

SMODS.Booster {
    key = 'trading_normal_1',
    atlas = 'booster',
    group_key = 'k_trading_pack',
    loc_txt = {
        name = "Trading Pack",
        text = {
            "Choose {C:attention}#1#{} of up to",
            "{C:attention}#2#{C:attention} Trading{} cards to",
            "add to your deck"
        }
    },
    weight = 0.9,
    name = "Trading Pack",
    pos = {x = 0, y = 0},
    config = {extra = 2, choose = 1, name = "Trading Pack"},
    create_card = function(self, card)
        local key = G.P_TRADING[get_trading_key()]
        local _card = Card(G.deck.T.x, G.deck.T.y, G.CARD_W, G.CARD_H, G.P_CARDS[key.base], G.P_CENTERS['m_pc_trading'], {playing_card = G.playing_card})
        _card.ability.trading = copy_table(key)
        _card:set_sprites(_card.config.center)
        local edition = poll_edition('trading_edition'..G.GAME.round_resets.ante, 1, true)
        _card:set_edition(edition)
        _card:set_seal(SMODS.poll_seal({mod = 3}))
        return _card
    end
}

SMODS.Booster {
    key = 'trading_normal_2',
    atlas = 'booster',
    group_key = 'k_trading_pack',
    loc_txt = {
        name = "Trading Pack",
        text = {
            "Choose {C:attention}#1#{} of up to",
            "{C:attention}#2#{C:attention} Trading{} cards to",
            "add to your deck"
        }
    },
    weight = 0.9,
    name = "Trading Pack",
    pos = {x = 1, y = 0},
    config = {extra = 2, choose = 1, name = "Trading Pack"},
    create_card = function(self, card)
        local key = G.P_TRADING[get_trading_key()]
        local _card = Card(G.deck.T.x, G.deck.T.y, G.CARD_W, G.CARD_H, G.P_CARDS[key.base], G.P_CENTERS['m_pc_trading'], {playing_card = G.playing_card})
        _card.ability.trading = copy_table(key)
        _card:set_sprites(_card.config.center)
        local edition = poll_edition('trading_edition'..G.GAME.round_resets.ante, 1, true)
        _card:set_edition(edition)
        _card:set_seal(SMODS.poll_seal({mod = 3}))
        return _card
    end
}

SMODS.Booster {
    key = 'trading_jumbo_1',
    atlas = 'booster',
    group_key = 'k_trading_pack',
    loc_txt = {
        name = "Jumbo Trading Pack",
        text = {
            "Choose {C:attention}#1#{} of up to",
            "{C:attention}#2#{C:attention} Trading{} cards to",
            "add to your deck"
        }
    },
    weight = 0.45,
    cost = 6,
    name = "Trading Pack",
    pos = {x = 0, y = 1},
    config = {extra = 4, choose = 1, name = "Trading Pack"},
    create_card = function(self, card)
        local key = G.P_TRADING[get_trading_key()]
        local _card = Card(G.deck.T.x, G.deck.T.y, G.CARD_W, G.CARD_H, G.P_CARDS[key.base], G.P_CENTERS['m_pc_trading'], {playing_card = G.playing_card})
        _card.ability.trading = copy_table(key)
        _card:set_sprites(_card.config.center)
        local edition = poll_edition('trading_edition'..G.GAME.round_resets.ante, 1, true)
        _card:set_edition(edition)
        _card:set_seal(SMODS.poll_seal({mod = 3}))
        return _card
    end
}

SMODS.Booster {
    key = 'trading_mega_1',
    atlas = 'booster',
    group_key = 'k_trading_pack',
    loc_txt = {
        name = "Mega Trading Pack",
        text = {
            "Choose {C:attention}#1#{} of up to",
            "{C:attention}#2#{C:attention} Trading{} cards to",
            "add to your deck"
        }
    },
    weight = 0.35,
    cost = 8,
    name = "Trading Pack",
    pos = {x = 1, y = 1},
    config = {extra = 4, choose = 2, name = "Trading Pack"},
    create_card = function(self, card)
        local key = G.P_TRADING[get_trading_key()]
        local _card = Card(G.deck.T.x, G.deck.T.y, G.CARD_W, G.CARD_H, G.P_CARDS[key.base], G.P_CENTERS['m_pc_trading'], {playing_card = G.playing_card})
        _card.ability.trading = copy_table(key)
        _card:set_sprites(_card.config.center)
        local edition = poll_edition('trading_edition'..G.GAME.round_resets.ante, 1, true)
        _card:set_edition(edition)
        _card:set_seal(SMODS.poll_seal({mod = 3}))
        return _card
    end
}

SMODS.Shader {
    path = 'phantom.fs',
    key = 'phantom'
}

local whole_deck = {}
for _, i in ipairs({'H', 'C', 'S', 'D'}) do
    for _, j in ipairs({'2', '3', '4', '5', '6', '7', '8', '9', 'T', 'J', 'Q', 'K', 'A'}) do
        table.insert(whole_deck, {s = i, r = j})
    end
end
for i = 1, 52 do
    table.insert(whole_deck, {s = 'H', r = 'Q', t = 'double_down', e = 'm_pc_trading'})
end


table.insert(G.CHALLENGES,#G.CHALLENGES+1,
    {name = 'Duoquinquagenuple Down',
        id = 'c_duoquinquagenuple_down',
        rules = {
            custom = {
                {id = 'double_down_52'},
            },
            modifiers = {
                {id = 'hand_size', value = 6},
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
            cards = whole_deck,
        },
        restrictions = {
            banned_cards = {
            },
            banned_tags = {
            },
            banned_other = {
            }
        },
    }
)

function get_trading_key()
    local _, key = pseudorandom_element(G.P_TRADING, pseudoseed('trading'))
    return key
end

G.FUNCS.up_rank = function(e)
    e.config.ref_table.ability.trading.config.rank = (e.config.ref_table.ability.trading.config.rank or 1) + 1
    if e.config.ref_table.ability.trading.config.rank == 15 then
        e.config.ref_table.ability.trading.config.rank = 2
    end
    local ranks = {'', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'Jack', 'Queen', 'King', 'Ace'}
    SMODS.change_base(e.config.ref_table, nil, ranks[e.config.ref_table.ability.trading.config.rank])
    card_eval_status_text(e.config.ref_table, 'jokers', nil, nil, nil, {message = localize(ranks[e.config.ref_table.ability.trading.config.rank], 'ranks')})
end

G.FUNCS.down_rank = function(e)
    e.config.ref_table.ability.trading.config.rank = (e.config.ref_table.ability.trading.config.rank or 15) - 1
    if e.config.ref_table.ability.trading.config.rank == 1 then
        e.config.ref_table.ability.trading.config.rank = 14
    end
    local ranks = {'', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'Jack', 'Queen', 'King', 'Ace'}
    SMODS.change_base(e.config.ref_table, nil, ranks[e.config.ref_table.ability.trading.config.rank])
    card_eval_status_text(e.config.ref_table, 'jokers', nil, nil, nil, {message = localize(ranks[e.config.ref_table.ability.trading.config.rank], 'ranks')})
end

G.FUNCS.can_up_rank = function(e)
    if e.config.ref_table.debuff then
        e.config.colour = G.C.UI.BACKGROUND_INACTIVE
        e.config.button = nil
    else
      e.config.colour = G.C.GREEN
      e.config.button = 'up_rank'
    end
end

G.FUNCS.can_down_rank = function(e)
    if e.config.ref_table.debuff then
        e.config.colour = G.C.UI.BACKGROUND_INACTIVE
        e.config.button = nil
    else
      e.config.colour = G.C.RED
      e.config.button = 'down_rank'
    end
end

function G.UIDEF.rank_buttons(card)
    local sell = nil
    local use = nil
    use = 
    {n=G.UIT.C, config={align = "cr"}, nodes={
      {n=G.UIT.C, config={ref_table = card, align = "cm",maxw = 0.75, padding = 0.1, r=0.08, minw = 0.75, minh = 0.3, hover = true, shadow = true, colour = G.C.RED, button = 'up_rank', func = 'can_up_rank'}, nodes={
        {n=G.UIT.B, config = {w=0.1,h=0.3}},
        {n=G.UIT.T, config={text = localize('b_up'),colour = G.C.UI.TEXT_LIGHT, scale = 0.25, shadow = true}}
      }}
    }}
    sell = 
    {n=G.UIT.C, config={align = "cr"}, nodes={
      {n=G.UIT.C, config={ref_table = card, align = "cm",maxw = 0.75, padding = 0.1, r=0.08, minw = 0.75, minh = 0.3, hover = true, shadow = true, colour = G.C.GREEN, button = 'down_rank', func = 'can_down_rank'}, nodes={
        {n=G.UIT.B, config = {w=0.1,h=0.3}},
        {n=G.UIT.T, config={text = localize('b_down'),colour = G.C.UI.TEXT_LIGHT, scale = 0.25, shadow = true}}
      }}
    }}
    local t = {
        n=G.UIT.ROOT, config = {padding = 0, colour = G.C.CLEAR}, nodes={
        {n=G.UIT.R, config={padding = 0.15, align = 'cl'}, nodes={
            {n=G.UIT.C, config={align = 'cl'}, nodes={
            sell
            }},
            {n=G.UIT.C, config={align = 'cl'}, nodes={
            use
            }},
        }},
    }}
    return t
end

local old_nominal = Card.get_nominal
function Card:get_nominal(mod)
    if self.ability and self.ability.trading then
        local the_rank = self:calculate_exotic({get_id = true})
        local the_suits = {}
        local has_suit = nil
        for i, j in pairs(SMODS.Suits) do
            local suit_eval = self:calculate_exotic({is_suit = j.key})
            if suit_eval then
                the_suits[j.key] = true
                if not has_suit then
                    has_suit = j
                elseif j.suit_nominal > has_suit.suit_nominal then
                    has_suit = j
                end
            end
        end
        local mult = 1
        local rank_mult = 1
        if mod == 'suit' then mult = 10000 end
        if (the_rank < 0) and not has_suit then 
            mult = -10000
        elseif not has_suit then
            mult = 0
        elseif (the_rank < 0) then
            rank_mult = 0
        end
        local r_nominal = 0
        local f_nominal = 0
        if (the_rank > 0) then
            local ranks = {'', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'Jack', 'Queen', 'King', 'Ace'}
            r_nominal = SMODS.Ranks[ranks[the_rank]].nominal or 0
            f_nominal = SMODS.Ranks[ranks[the_rank]].face_nominal or 0
        end
        local s_nominal = 0
        if has_suit then
            s_nominal = has_suit.suit_nominal or 0
        end
        if (mod == 'suit') and (the_rank < 0) then
            rank_mult = 1
            r_nominal = 1.999
        end
        return 10*r_nominal*rank_mult + s_nominal*mult + 10*f_nominal*rank_mult + 0.000001*self.unique_val + (self.ability.trading.order or 0)*0.00000001+ s_nominal*0.0001*mult
    end
    return old_nominal(self, mod)
end

SMODS.current_mod.set_debuff = function(card)
    if card.ability.temp_debuff then
        return true
    end
end

local old_repitions = SMODS.calculate_repetitions
SMODS.calculate_repetitions = function(card, context, reps)
    local reps = old_repitions(card, context, reps)
    if context.scoring_hand then
        for l=1, #context.scoring_hand do
            local eval = context.scoring_hand[l]:calculate_exotic({cardarea = context.cardarea, other_card = card, repetition = true, full_hand = G.play.cards, scoring_hand = context.scoring_hand, scoring_name = context.scoring_name, poker_hands = context.poker_hands, end_of_round = context.end_of_round}, {})
            if next(eval) then
                for _, minieval in ipairs(eval) do
                    if minieval.repetitions then
                        for h = 1, minieval.repetitions do
                            reps[#reps+1] = {jokers = {
                                message = minieval.message,
                                card = minieval.cards[#minieval.cards],
                                repetitions = minieval.repetitions,
                                cards = minieval.cards,
                            }}
                        end
                    end
                end
            end
        end
    end
    for l=1, #G.hand.cards do
        local eval = G.hand.cards[l]:calculate_exotic({cardarea = context.cardarea, other_card = card, repetition = true, full_hand = G.play.cards, scoring_hand = context.scoring_hand, scoring_name = context.scoring_name, poker_hands = context.poker_hands, end_of_round = context.end_of_round}, {})
        if next(eval) then
            for _, minieval in ipairs(eval) do
                if minieval.repetitions then
                    for h = 1, minieval.repetitions do
                        reps[#reps+1] = {jokers = {
                            message = minieval.message,
                            card = minieval.cards[#minieval.cards],
                            repetitions = minieval.repetitions,
                            cards = minieval.cards,
                        }}
                    end
                end
            end
        end
    end
    return reps
end

local old_indiv = SMODS.calculate_individual_effect
SMODS.calculate_individual_effect = function(effect, scored_card, percent, key, amount, from_edition)
    local result = old_indiv(effect, scored_card, percent, key, amount, from_edition)
    if (key == 'pc_h_chips') and amount then 
        hand_chips = mod_chips(hand_chips + amount)
        update_hand_text({delay = 0}, {chips = hand_chips, mult = mult})
        if not effect.remove_default_message then
            if from_edition then
                card_eval_status_text(scored_card, 'jokers', nil, percent, nil, {message = localize{type = 'variable', key = amount > 0 and 'a_chips' or 'a_chips_minus', vars = {amount}}, chip_mod = amount, colour = G.C.EDITION, edition = true})
            else
                if key ~= 'chip_mod' then
                    if effect.chip_message then
                        card_eval_status_text(scored_card or effect.focus, 'extra', nil, percent, nil, effect.chip_message)
                    else
                        card_eval_status_text(scored_card or effect.focus, 'chips', amount, percent)
                    end
                end
            end
        end
        return true
    end
    return result
end

table.insert(SMODS.calculation_keys, 'pc_h_chips')

----------------------------------------------
------------MOD CODE END----------------------