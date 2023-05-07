shared = {
    language = 'fr', -- language [fr]
    adminCommand = 'territory', -- /territory (create/delete)
    playerCommand = 'territories', -- /territories [territory list]
    groups = {'admin', 'superadmin'}, -- group required to manage territories
    rankings = false, -- rank list and points for gangs? (true/false) (not user-friendly yet, but translated at least)
    capturing = 5, -- in minutes
    cooldown = 30, -- in minutes
    rewards = { -- reward is given only after successfully capturing the territory
        on = true, -- off (false) / on (true)
        item = 'black_money', -- item name
        count = 1000 -- amount
    },
    itemsToBuy = { -- buyable items if territory type is 'market'
        ['bread'] = {
            label = '🍞 | Bread',
            worth = 30,
            black = true, -- true = black money, false = cash
        },
        ['water'] = {
            label = '💧 | Water',
            worth = 20,
            black = true, -- true = black money, false = cash
        }
    },
    itemsToSell = { -- sellable items if territory type is 'dealer'
        ['marihuana'] = {
            label = '🌿 | Marijuana',
            worth = 550,
            black = true, -- true = black money, false = cash
        },
        ['heroin'] = {
            label = '💉 | Heroin',
            worth = 600,
            black = true, -- true = black money, false = cash
        },
        ['amfetamin10g'] = {
            label = '💊 | Amphetamine',
            worth = 800,
            black = true, -- true = black money, false = cash
        },
        ['coke_pooch'] = {
            label = '🏔️ | Cocaine',
            worth = 750,
            black = true, -- true = black money, false = cash
        }
    },
    gangs = { -- https://docs.fivem.net/docs/game-references/blips/ || gangs allowed to capture territories (job name) and blip color
        lost = { -- job
            blipColour = 69, -- blip color
        },
        ballas = { -- job
            blipColour = 58, -- blip color
        },
        vagos = { -- job
            blipColour = 59, -- blip color
        }
    },
    translations = {
        ['fr'] = {
            -- Client Notifications
            ['something_went_wrong'] = 'Quelque chose s\'est mal passé !',
            ['fill_all_fields_out'] = 'Vous devez remplir tous les champs correctement !',
            ['incorrect_amount'] = 'Le montant ne peut pas être inférieur à 1 !',
            ['territory_not_owned'] = 'Vous n\'êtes pas propriétaire de ce territoire !',
            ['territory_already_owned'] = 'Ce territoire vous appartient déjà !',
            ['capture_in_progress'] = 'Quelqu\'un prend déjà le territoire !',
            ['territory_on_cooldown'] = 'Ce territoire a été récemment capturé, ou une tentative de capture a été effectuée !',
            ['too_far_away'] = 'Vous êtes trop loin du territoire !',
            ['territory_captured'] = 'Vous avez capturé avec succès %s!',
            ['territory_cause_death'] = 'Tu es mort, la progression de la capture s\'est arrêtée !',
            ['territory_cause_distance'] = 'Vous avez quitté le territoire, la progression de la capture s\'est arrêtée !',
            ['territory_show_text'] = '[E] - Info | %s',
            ['territory_capture_progress_bar'] = 'Capture en cours...',
            -- Blips
            ['territory_blip_occupied'] = 'Territoire: %s | Propriétaire: %s',
            ['territory_blip_unoccupied'] = 'Inoccupé',
            -- Client Context Menu
            ['territory_menu_context_title'] = 'Liste des territoires',
            ['territory_menu_title'] = 'Territoires | 🎲',
            ['territory_list_title'] = 'Liste des territoires | 🚩',
            ['territory_list_metadata'] = 'Liste des territoires.',
            ['territory_list_territory_name'] = '💀 | Territoires: %s',
            ['territory_list_territory_owner'] = '🚩 | Propriétaire: %s',
            ['territory_list_territory_capturing'] = 'Capture: %s',
            ['territory_list_territory_cooldown'] = 'Attendez : %s',
            ['territory_info_menu'] = 'Territoires : %s | 🎲',
            ['territory_info_menu_capture'] = 'Capture le territoire | 🚩',
            ['territory_info_menu_stash'] = 'Réserve du territoire | 📦',
            ['territory_info_menu_sell'] = 'Racheteur | 🌿',
            ['territory_info_menu_buy'] = 'Vendeur | 🛒',
            ['territory_info_menu_sell_title'] = 'Articles vendables',
            ['territory_info_menu_buy_title'] = 'Articles achetables',
            ['territory_info_menu_buy_sell_price'] = '💸 | Prix : $%s',
            ['territory_rankings_menu_context_title'] = 'Liste de classement',
            ['territory_rankings_title'] = 'Liste de classement | 🏆',
            ['territory_rankings_metadata'] = 'Afficher la liste de toutes les organisations illégales, ainsi que les points...',
            ['territory_rankings_all_time'] = '⭐ | Points de tous les temps : %s',
            ['territory_rankings_monthly'] = '⭐ | Points mensuels : %s',
            ['territory_rankings_weekly'] = '⭐ | Points hebdomadaires : %s',
            ['territory_rankings_gang'] = '💀 | Gangs: %s',
            ['territory_rankings_position'] = '🏆 | Position: %s',
            ['territory_create_input'] = 'Créer un nouveau territoire',
            ['territory_create_name'] = 'Nom du territoire',
            ['territory_create_radius'] = 'Radius',
            ['territory_create_type'] = 'Type de territoire',
            ['territory_create_type_market'] = 'Marché (Achat)',
            ['territory_create_type_dealer'] = 'Marché (Vente)',
            ['territory_create_type_default'] = 'Par défaut (cache uniquement)',
            ['territory_delete_input'] = 'Supprimer un territoire',
            ['territory_delete_input_name'] = 'Nom du territoire',
            ['context_yes'] = 'Oui',
            ['context_no'] = 'Non',
            ['amount'] = 'Combien',
            -- NUI Messages
            ['defender_message'] = 'Défendez votre territoire !',
            ['attacker_message'] = 'Capture en cours !',
            -- Server Notifications
            ['no_permission'] = 'Vous n\'êtes pas autorisé à utiliser cette commande !',
            ['no_args'] = 'Utiliser: /territory [créer/supprimer]',
            ['territory_already_exists'] = 'Le territoire portant ce nom existe déjà !',
            ['territory_creation_failed'] = 'La création du territoire a échoué !',
            ['territory_created'] = 'Territoire créé !',
            ['territory_deletion_failed'] = 'Échec de la suppression du territoire !',
            ['territory_deleted'] = 'Territoire supprimé !',
            ['territory_being_attacked'] = 'Territoires: %s est attaqué par un autre gang !',
            ['territory_started_attacking'] = 'Votre gang a commencé à attaquer Territoire: %s',
            ['invalid_amount'] = 'Vous n\'avez pas ce montant !',
            ['not_enough_money'] = 'Vous n\'avez pas assez d\'argent !',
            ['not_enough_space'] = 'Vous n\'avez plus de place dans votre inventaire !',
            ['territory_reward'] = 'Vous avez $%s en récompense pour avoir capturé : %s',
            ['already_used'] = 'Attendez le redémarrage pour utiliser à nouveau la commande.',
            ['no_message'] = 'Le message est vide.'
        }
    },
    debugging = {
        allowPrints = true, -- This will allow prints to be shown in the console
        allowErrorAnalysis = true -- This will share errors with the developer (me) in order to improve the script
    }
}

function insert(tbl, val, i)
    local index = i or (#tbl + 1)
    tbl[index] = val
end

function translateMessage(message)
    local lang = shared.translations[shared.language]
    if not lang[message] then
        print('devTomic | Missing translation for: ' .. message)
        return message
    end

    return lang[message]
end

function debugPrint(msg)
    if not msg then return end
    msg = type(msg) == 'table' and json.encode(msg) or tostring(msg)

    if shared.debugging.allowPrints then
        print('devTomic | Line: ' .. debug.getinfo(3, "Sl").currentline .. ' | \n' .. msg)
    end

    if shared.debugging.allowErrorAnalysis then
        local logHeader = 'devTomic | Territories Log'
        local logMessage = 'Line: ' .. debug.getinfo(3, "Sl").currentline .. ' | \n' .. msg

        if IsDuplicityVersion() then
            logAction(logHeader, logMessage)
            return
        end

        TriggerServerEvent('tomic_territories:logAction', logHeader, logMessage)
    end

    return
end