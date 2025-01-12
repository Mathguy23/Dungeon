return {
    descriptions = {
        BlindEffect = {
            blank = {
                name = "Blank",
                text = {
                    "No Effect"
                }
            },
            debuff_1 = {
                name = "Debuff I",
                text = {
                    "{C:green}#1# in #2#{} cards",
                    "debuffed"
                }
            },
            debuff_2 = {
                name = "Debuff II",
                text = {
                    "{C:green}#1# in #2#{} cards",
                    "debuffed"
                }
            },
            raise_1 = {
                name = "Raise I",
                text = {
                    "{C:blue}X#1#{} Blind Size",
                }
            },
            raise_2 = {
                name = "Raise II",
                text = {
                    "{C:blue}X#1#{} Blind Size",
                }
            },
            hide_1 = {
                name = "Hide I",
                text = {
                    "The next {C:attention}#1#{} cards",
                    "are drawn {C:attention}face down{}"
                }
            },
            hide_2 = {
                name = "Hide II",
                text = {
                    "The next {C:attention}#1#{} cards",
                    "are drawn {C:attention}face down{}"
                }
            },
            ring_1 = {
                name = "Ring I",
                text = {
                    "Forces {C:attention}#1#{} card",
                    "to be {C:attention}selected{}"
                }
            },
            ring_2 = {
                name = "Ring II",
                text = {
                    "Forces {C:attention}#1#{} card",
                    "to be {C:attention}selected{}"
                }
            },
        },
        Blind = {
            bl_dng_scarlet_spider = {
                name = 'Scarlet Spider',
                text = { '+4 Hands', 'Uses forced selection'}
            },
            bl_dng_string = {
                name = 'The String',
                text = { '2 cards forced to be', 'selected each hand'}
            },
            bl_dng_dealer = {
                name = 'The Dealer',
                text = { 'Blackjack' }
            },
        }
    },
    misc = {
        dictionary = {
            k_blindeffect = "Blind Effect",
            b_blindeffect_cards = "Blind Effects",
            b_loot = "Loot",
            b_common_loot = "Common",
            b_uncommon_loot = "Uncommon",
            b_rare_loot = "Rare",
            b_hit = "Hit",
            b_stand = "Stand",
            ph_blackjack_lost = "You Lost",
        },
        v_text = {
            ch_c_ante_hand_discard_reset = {"{C:blue}Hands{} and {C:red}Discards{} are only reset each {C:attention}Ante{}."},
            ch_c_dungeon = {"{C:attention}Dungeon Mode{}"},
            ch_c_dungeon_1_ante_8 = {"Ante {C:attention}8{}'s Boss Blind is {C:attention}Scarlet Spider{}"},
            ch_c_dungeon_1_ante_4 = {"Ante {C:attention}4{}'s Boss Blind is {C:attention}The String{}"},
        },
        v_dictionary = {
        },
        challenge_names = {
            c_dungeon = "Dungeon"
        },
        labels = {
        }
    }
}