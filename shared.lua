shared = {
    language = 'en', -- language [en/hr/fr]
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
    gangOnlyBlips = true, -- show blips only for gangs that are allowed to capture territories
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
        gsf = { -- job
            blipColour = 69, -- blip color
        },
        ballas = { -- job
            blipColour = 58, -- blip color
        },
        bloods = { -- job
            blipColour = 59, -- blip color
        }
    },
    translations = {
        ['en'] = {
            -- Client Notifications
            ['something_went_wrong'] = 'Something went wrong!',
            ['fill_all_fields_out'] = 'You must fill all fields correctly!',
            ['incorrect_amount'] = 'Amount cannot be lower than 1!',
            ['territory_not_owned'] = 'You do not own this territory!',
            ['territory_already_owned'] = 'This territory already belongs to you!',
            ['capture_in_progress'] = 'Someone is already taking the territory!',
            ['territory_on_cooldown'] = 'This territory was recently captured, or capture was attempted!',
            ['too_far_away'] = 'You are too far away from the territory!',
            ['territory_captured'] = 'You have successfully captured %s!',
            ['territory_cause_death'] = 'You died, the capturing progress has stopped!',
            ['territory_cause_distance'] = 'You left the territory, capturing progress has stopped!',
            ['territory_show_text'] = '[E] - Info | %s',
            ['territory_capture_progress_bar'] = 'Capturing...',
            -- Blips
            ['territory_blip_occupied'] = 'Territory: %s | Owner: %s',
            ['territory_blip_unoccupied'] = 'Unoccupied',
            -- Client Context Menu
            ['territory_menu_context_title'] = 'devTomic | Territory List',
            ['territory_menu_title'] = 'Territories | 🎲',
            ['territory_list_title'] = 'Territory List | 🚩',
            ['territory_list_metadata'] = 'List of the territories.',
            ['territory_list_territory_name'] = '💀 | Territory: %s',
            ['territory_list_territory_owner'] = '🚩 | Owner: %s',
            ['territory_list_territory_capturing'] = 'Capturing: %s',
            ['territory_list_territory_cooldown'] = 'Cooldown: %s',
            ['territory_info_menu'] = 'Territory: %s | 🎲',
            ['territory_info_menu_capture'] = 'Capture the territory | 🚩',
            ['territory_info_menu_stash'] = 'Territory stash | 📦',
            ['territory_info_menu_sell'] = 'Sell Shop | 🌿',
            ['territory_info_menu_buy'] = 'Buy Shop | 🛒',
            ['territory_info_menu_sell_title'] = 'devTomic | Sellable items',
            ['territory_info_menu_buy_title'] = 'devTomic | Buyable items',
            ['territory_info_menu_buy_sell_price'] = '💸 | Price: $%s',
            ['territory_rankings_menu_context_title'] = 'devTomic | Rank List',
            ['territory_rankings_title'] = 'Rank List | 🏆',
            ['territory_rankings_metadata'] = 'Show the list of every illegal organisation, as well as points...',
            ['territory_rankings_all_time'] = '⭐ | All-Time Points: %s',
            ['territory_rankings_monthly'] = '⭐ | Monthly Points: %s',
            ['territory_rankings_weekly'] = '⭐ | Weekly Points: %s',
            ['territory_rankings_gang'] = '💀 | Gang: %s',
            ['territory_rankings_position'] = '🏆 | Position: %s',
            ['territory_create_input'] = 'Create a new territory',
            ['territory_create_name'] = 'Territory Name',
            ['territory_create_radius'] = 'Radius',
            ['territory_create_type'] = 'Territory type',
            ['territory_create_type_market'] = 'Market (Buying)',
            ['territory_create_type_dealer'] = 'Market (Selling)',
            ['territory_create_type_default'] = 'Default (Stash Only)',
            ['territory_delete_input'] = 'Delete a territory',
            ['territory_delete_input_name'] = 'Territory name',
            ['context_yes'] = 'Yes',
            ['context_no'] = 'No',
            ['amount'] = 'Amount',
            -- NUI Messages
            ['defender_message'] = 'Defend your territory!',
            ['attacker_message'] = 'Capture in progress!',
            -- Server Notifications
            ['no_permission'] = 'You do not have permission to use this command!',
            ['no_args'] = 'Usage: /territory [create/delete]',
            ['territory_already_exists'] = 'Territory with that name already exists!',
            ['territory_creation_failed'] = 'Territory creation failed!',
            ['territory_created'] = 'Territory created!',
            ['territory_deletion_failed'] = 'Territory deletion failed!',
            ['territory_deleted'] = 'Territory deleted!',
            ['territory_being_attacked'] = 'Territory: %s is being attacked by another gang!',
            ['territory_started_attacking'] = 'Your gang started attacking territory: %s',
            ['invalid_amount'] = 'You do not have that amount!',
            ['not_enough_money'] = 'You do not have enough money!',
            ['not_enough_space'] = 'You do not have any space in your inventory!',
            ['territory_reward'] = 'You got $%s as a reward for capturing: %s',
            ['already_used'] = 'Wait for the restart to use the command again.',
            ['no_message'] = 'The message is empty.'
        },
        ['hr'] = {
            -- Client Notifications
            ['something_went_wrong'] = 'Greška!',
            ['fill_all_fields_out'] = 'Morate točno ispuniti sva polja!',
            ['incorrect_amount'] = 'Količina ne može biti manja od 1',
            ['territory_not_owned'] = 'Ne posjedujete ovu teritoriju!',
            ['territory_already_owned'] = 'Ova teritorija već pripada vama!',
            ['capture_in_progress'] = 'Netko već zauzima ovu teritoriju!',
            ['territory_on_cooldown'] = 'Ova teritorija je na cooldown-u!',
            ['too_far_away'] = 'Predaleko ste od teritorije!',
            ['territory_captured'] = 'Uspješno ste zauzeli teritoriju %s!',
            ['territory_cause_death'] = 'Umrli ste, zauzimanje je prekinuto!',
            ['territory_cause_distance'] = 'Napustili ste teritoriju, zauzimanje je prekinuto!',
            ['territory_show_text'] = '[E] - Info | %s',
            ['territory_capture_progress_bar'] = 'Zauzimanje...',
            -- Blips
            ['territory_blip_occupied'] = 'Teritorija: %s | Vlasnik: %s',
            ['territory_blip_unoccupied'] = 'Nitko',
            -- Client Context Menu
            ['territory_menu_context_title'] = 'devTomic | Popis teritorija',
            ['territory_menu_title'] = 'Teritorije | 🎲',
            ['territory_list_title'] = 'Popis teritorija | 🚩',
            ['territory_list_metadata'] = 'Popis svih dostupnih teritorija.',
            ['territory_list_territory_name'] = '💀 | Teritorija: %s',
            ['territory_list_territory_owner'] = '🚩 | Vlasnik: %s',
            ['territory_list_territory_capturing'] = 'Zauzima se: %s',
            ['territory_list_territory_cooldown'] = 'Na cooldown-u: %s',
            ['territory_info_menu'] = 'Teritorija: %s | 🎲',
            ['territory_info_menu_capture'] = 'Zauzmite teritoriju | 🚩',
            ['territory_info_menu_stash'] = 'Stash teritorije | 📦',
            ['territory_info_menu_sell'] = 'Prodaja | 🌿',
            ['territory_info_menu_buy'] = 'Kupovina | 🛒',
            ['territory_info_menu_sell_title'] = 'devTomic | Prodaja item-a',
            ['territory_info_menu_buy_title'] = 'devTomic | Kupovina item-a',
            ['territory_info_menu_buy_sell_price'] = '💸 | Cijena: $%s',
            ['territory_rankings_menu_context_title'] = 'devTomic | Rank List-a',
            ['territory_rankings_title'] = 'Rank List-a | 🏆',
            ['territory_rankings_metadata'] = 'Lista organizacija i poeni...',
            ['territory_rankings_all_time'] = '⭐ | Ukupni poeni: %s',
            ['territory_rankings_monthly'] = '⭐ | Mjesečni poeni: %s',
            ['territory_rankings_weekly'] = '⭐ | Tjedni poeni: %s',
            ['territory_rankings_gang'] = '💀 | Organizacija: %s',
            ['territory_rankings_position'] = '🏆 | Pozicija: %s',
            ['territory_create_input'] = 'Napravite novu teritoriju',
            ['territory_create_name'] = 'Ime teritorije',
            ['territory_create_radius'] = 'Radius',
            ['territory_create_type'] = 'Tip teritorije',
            ['territory_create_type_market'] = 'Prodavnica (Kupovina)',
            ['territory_create_type_dealer'] = 'Prodavnica (Prodaja)',
            ['territory_create_type_default'] = 'Default (Samo stash)',
            ['territory_delete_input'] = 'Obrisite teritoriju',
            ['territory_delete_input_name'] = 'Ime teritorije',
            ['context_yes'] = 'Da',
            ['context_no'] = 'Ne',
            ['amount'] = 'Količina',
            -- NUI Messages
            ['defender_message'] = 'Obranite svoju teritoriju!',
            ['attacker_message'] = 'Zauzimanje u tijeku!',
            -- Server Notifications
            ['no_permission'] = 'Nemate dozvolu za tu komandu!',
            ['no_args'] = 'Upotreba: /territory [create/delete]',
            ['territory_already_exists'] = 'Teritorija s tim imenom već postoji!',
            ['territory_creation_failed'] = 'Teritorija neuspješno kreirana!',
            ['territory_created'] = 'Teritorija kreirana!',
            ['territory_deletion_failed'] = 'Teritorija neuspješno obrisana!',
            ['territory_deleted'] = 'Teritorija obrisana!',
            ['territory_being_attacked'] = 'Teritorija: %s je napadnuta od strane druge organizacije!',
            ['territory_started_attacking'] = 'Vaša organizacija je napala teritoriju: %s',
            ['invalid_amount'] = 'Ne posjedujete tu količinu kod sebe!',
            ['not_enough_money'] = 'Nemate dovoljno novca!',
            ['not_enough_space'] = 'Nemate dovoljno prostora u rancu!',
            ['territory_reward'] = 'Dobili ste $%s kao nagradu za zauzimanje teritorije: %s',
            ['already_used'] = 'Već ste iskoristili tu komadnu! Pričekajte server restart.',
            ['no_message'] = 'Poruka je prazna.'
        },
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
end