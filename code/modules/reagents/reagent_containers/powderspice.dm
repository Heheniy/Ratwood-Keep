/obj/item/reagent_containers/powder
	name = "default powder"
	desc = ""
	icon = 'icons/roguetown/items/produce.dmi'
	icon_state = "spice"
	item_state = "spice"
	possible_transfer_amounts = list()
	volume = 15
	sellprice = 10
	grid_height = 32
	grid_width = 32

/obj/item/reagent_containers/powder/spice
	name = "spice"
	desc = ""
	icon = 'icons/roguetown/items/produce.dmi'
	icon_state = "spice"
	item_state = "spice"
	possible_transfer_amounts = list()
	volume = 15
	list_reagents = list(/datum/reagent/druqks = 15)
	grind_results = list(/datum/reagent/druqks = 15)
	sellprice = 10

/datum/reagent/sleep_powder
	name = "sleep powder"
	description = ""
	color = "#ddd3df" // rgb: 96, 165, 132
	metabolization_rate = 1

// TO DO: eventually rewrite drowsyness code to do this instead then it can be expanded
// The reason why I haven't is because vampire lords have some special code for drowsyness I'll ave to get to...
/datum/reagent/sleep_powder/on_mob_metabolize(mob/living/carbon/M)
	M.apply_status_effect(/datum/status_effect/debuff/knockout)
	..()


/obj/item/reagent_containers/powder/sleep_powder
	name = "powder"
	desc = ""
	gender = PLURAL
	icon_state = "flour"
	list_reagents = list(/datum/reagent/sleep_powder = 5)
	grind_results = null
	volume = 5


/datum/reagent/druqks
	name = "Drukqs"
	description = ""
	color = "#60A584" // rgb: 96, 165, 132
	overdose_threshold = 16
	metabolization_rate = 0.2

/datum/reagent/druqks/overdose_process(mob/living/M)
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 0.25*REM)
	M.adjustToxLoss(0.25*REM, 0)
	..()
	. = 1

/datum/reagent/druqks/on_mob_life(mob/living/carbon/M)
	M.set_drugginess(30)
	if(prob(5))
		if(M.gender == FEMALE)
			M.emote(pick("twitch_s","giggle"))
		else
			M.emote(pick("twitch_s","chuckle"))
	if(M.has_flaw(/datum/charflaw/addiction/junkie))
		M.sate_addiction()
	M.apply_status_effect(/datum/status_effect/buff/druqks)
	..()

/atom/movable/screen/fullscreen/druqks
	icon_state = "spa"
	plane = FLOOR_PLANE
	layer = ABOVE_OPEN_TURF_LAYER
	blend_mode = 0
	show_when_dead = FALSE

/datum/reagent/druqks/overdose_start(mob/living/M)
	M.visible_message(span_warning("Blood runs from [M]'s nose."))

/datum/reagent/druqks/overdose_process(mob/living/M)
	M.adjustToxLoss(10, 0)

/datum/reagent/druqks/on_mob_metabolize(mob/living/M)
	M.overlay_fullscreen("druqk", /atom/movable/screen/fullscreen/druqks)
	M.set_drugginess(30)
	M.update_body_parts_head_only()
	if(M.client)
		ADD_TRAIT(M, TRAIT_DRUQK, "based")
		SSdroning.area_entered(get_area(M), M.client)
//			if(M.client.screen && M.client.screen.len)
//				var/atom/movable/screen/plane_master/game_world/PM = locate(/atom/movable/screen/plane_master/game_world) in M.client.screen
//				PM.backdrop(M.client.mob)

/datum/reagent/druqks/on_mob_end_metabolize(mob/living/M)
	M.clear_fullscreen("druqk")
	M.update_body_parts_head_only()
	if(M.client)
		REMOVE_TRAIT(M, TRAIT_DRUQK, "based")
		SSdroning.play_area_sound(get_area(M), M.client)
//		if(M.client.screen && M.client.screen.len)
///			var/atom/movable/screen/plane_master/game_world/PM = locate(/atom/movable/screen/plane_master/game_world) in M.client.screen
//			PM.backdrop(M.client.mob)

/obj/item/reagent_containers/powder/throw_impact(atom/hit_atom, datum/thrownthing/thrownthing)
	. = ..()
	///if the thrown object's target zone isn't the head
	if(thrownthing.target_zone != BODY_ZONE_PRECISE_NOSE)
		return
	if(iscarbon(hit_atom))
		var/mob/living/carbon/C = hit_atom
		if(canconsume(C, silent = TRUE))
			if(reagents.total_volume)
				playsound(C, 'sound/items/sniff.ogg', 100, FALSE)
				reagents.trans_to(C, 1, transfered_by = thrownthing.thrower, method = "swallow")
	qdel(src)

/obj/item/reagent_containers/powder/attack(mob/M, mob/user, def_zone)
	if(!canconsume(M, user))
		return FALSE

	if(user.zone_selected != BODY_ZONE_PRECISE_NOSE)
		return FALSE

	if(M == user)
		M.visible_message(span_notice("[user] sniffs [src]."))
	else
		if(iscarbon(M))
			var/mob/living/carbon/C = M
			var/obj/item/bodypart/CH = C.get_bodypart(BODY_ZONE_HEAD)
			if(!CH)
				to_chat(user, span_warning("[C.p_theyre(TRUE)] missing something."))
			user.visible_message(span_danger("[user] attempts to force [C] to inhale [src]."), \
								span_danger("[user] attempts to force me to inhale [src]!"))
			if(C.cmode)
				if(!LAZYLEN(CH.grabbedby))
					to_chat(user, span_info("[C.p_they(TRUE)] steals [C.p_their()] face from it."))
					return FALSE
			if(!do_mob(user, M, 10))
				return FALSE

	playsound(M, 'sound/items/sniff.ogg', 100, FALSE)

	if(reagents.total_volume)
		reagents.trans_to(M, reagents.total_volume, transfered_by = user, method = "swallow")
	qdel(src)
	return TRUE

/*
/obj/item/reagent_containers/pill/afterattack(obj/target, mob/user , proximity)
	. = ..()
	if(!proximity)
		return
	if(!dissolvable || !target.is_refillable())
		return
	if(target.is_drainable() && !target.reagents.total_volume)
		to_chat(user, span_warning("[target] is empty! There's nothing to dissolve [src] in."))
		return

	if(target.reagents.holder_full())
		to_chat(user, span_warning("[target] is full."))
		return

	user.visible_message(span_warning("[user] slips something into [target]!"), span_notice("I dissolve [src] in [target]."), null, 2)
	reagents.trans_to(target, reagents.total_volume, transfered_by = user)
	qdel(src)
*/
/obj/item/reagent_containers/powder/flour
	name = "mound of flour"
	desc = "Add water and knead it"
	gender = PLURAL
	icon_state = "flour"
	can_brew = TRUE
	list_reagents = list(/datum/reagent/floure = 1)
	volume = 1
	sellprice = 0

/datum/reagent/floure
	name = "flour"
	description = ""
	color = "#FFFFFF" // rgb: 96, 165, 132

/datum/reagent/floure/on_mob_life(mob/living/carbon/M)
	if(prob(30))
		M.confused = max(M.confused+3,0)
	M.emote(pick("cough"))
	..()

/obj/item/reagent_containers/powder/flour/throw_impact(atom/hit_atom, datum/thrownthing/thrownthing)
	new /obj/effect/decal/cleanable/food/flour(get_turf(src))
	..()
	qdel(src)

/datum/chemical_reaction/graintopowder
	name = "Powder Piling"
	id = "powderpiling"
	required_reagents = list(/datum/reagent/floure = 10)

/datum/chemical_reaction/graintopowder/on_reaction(datum/reagents/holder, created_volume)
	var/location = get_turf(holder.my_atom)
	for(var/i = 1, i <= created_volume, i++)
		new /obj/item/reagent_containers/powder/flour(location)

/obj/item/reagent_containers/powder/salt
	name = "salt"
	desc = ""
	gender = PLURAL
	icon_state = "salt"
	brew_amt = 22
	brew_reagent = /datum/reagent/alch/syrum_salt
	list_reagents = list(/datum/reagent/salt = 5,)
	grind_results = null
	volume = 5

/obj/item/reagent_containers/powder/salt/throw_impact(atom/hit_atom, datum/thrownthing/thrownthing)
	new /obj/effect/decal/cleanable/food/salt(get_turf(src))
	..()
	qdel(src)

/datum/reagent/salt
	name = "Salt"
	description = ""
	overdose_threshold = null
	metabolization_rate = 0.5

/datum/reagent/salt/on_mob_life(mob/living/carbon/M)                                        // teach you fucks to keep snorting salt...
	var/obj/item/bodypart/BPA = M.get_bodypart(BODY_ZONE_PRECISE_NOSE)
	M.adjust_blurriness(3)
	M.confused = max(M.confused+3,0)
	M.adjustBruteLoss(2, BRUTE, BPA)
	M.adjustFireLoss(2, BURN, BPA)
	M.emote(pick("scream"))

/obj/item/reagent_containers/powder/ozium
	name = "ozium powder"
	desc = "painkiller"
	icon = 'icons/roguetown/items/produce.dmi'
	icon_state = "ozium"
	possible_transfer_amounts = list()
	volume = 15
	list_reagents = list(/datum/reagent/ozium = 15)
	grind_results = list(/datum/reagent/ozium = 15)
	sellprice = 5

/datum/reagent/ozium
	name = "Ozium"
	description = ""
	color = "#60A584" // rgb: 96, 165, 132
	overdose_threshold = 16
	metabolization_rate = 0.2

/datum/reagent/ozium/overdose_process(mob/living/M)
	M.adjustToxLoss(0.25*REM, 0)
	..()
	. = 1

/datum/reagent/ozium/on_mob_life(mob/living/carbon/M)
	if(M.reagents.has_reagent(/datum/reagent/moondust) || M.reagents.has_reagent(/datum/reagent/moondust_purest))
		M.Dizzy(10)
		M.Jitter(5)
		M.slurring += 3
		M.confused += 2
		M.losebreath += 2
	if(M.has_flaw(/datum/charflaw/addiction/junkie))
		M.sate_addiction()
	..()

/datum/reagent/ozium/on_transfer(atom/A, method=INJECT, trans_volume) //prevents cheesing with ultralow doses.
	var/mob/living/carbon/C = A
	if(method == INJECT && iscarbon(A))
		if(trans_volume >= 4)
			C.apply_status_effect(/datum/status_effect/buff/ozium)
	else if(method == "swallow" && iscarbon(A))
		if(trans_volume >= 10)
			C.apply_status_effect(/datum/status_effect/buff/ozium)

/datum/reagent/ozium/overdose_start(mob/living/M)
	M.playsound_local(M, 'sound/misc/heroin_rush.ogg', 100, FALSE)
	M.visible_message(span_warning("Blood runs from [M]'s nose."))

/datum/reagent/ozium/overdose_process(mob/living/M)
	M.adjustToxLoss(10, 0)

/obj/item/reagent_containers/powder/moondust
	name = "moondust"
	desc = ""
	icon = 'icons/roguetown/items/produce.dmi'
	icon_state = "moondust"
	possible_transfer_amounts = list()
	volume = 15
	list_reagents = list(/datum/reagent/moondust = 15)
	grind_results = list(/datum/reagent/moondust = 15)
	sellprice = 5

/datum/reagent/moondust
	name = "Moondust"
	description = ""
	color = "#bfc3b5"
	overdose_threshold = 16
	metabolization_rate = 0.2

/datum/reagent/moondust/overdose_process(mob/living/M)
	M.adjustToxLoss(0.25*REM, 0)
	..()
	. = 1

/datum/reagent/moondust/on_mob_metabolize(mob/living/M)
	narcolepsy_drug_up(M)
	M.flash_fullscreen("can_you_see")
	animate(M.client, pixel_y = 1, time = 1, loop = -1, flags = ANIMATION_RELATIVE)
	animate(pixel_y = -1, time = 1, flags = ANIMATION_RELATIVE)

/datum/reagent/moondust/on_mob_end_metabolize(mob/living/M)
	animate(M.client)

/datum/reagent/moondust/on_mob_life(mob/living/carbon/M)
	narcolepsy_drug_up(M)
	M.Sleeping(-40)
	if(M.reagents.has_reagent(/datum/reagent/moondust_purest))
		overdosed = TRUE
		M.Jitter(5)
		M.losebreath += 1 //This doesn't kill the user, the overdose does
	if(M.has_flaw(/datum/charflaw/addiction/junkie))
		M.sate_addiction()
	if(prob(10))
		M.flash_fullscreen("whiteflash")
	..()

/datum/reagent/moondust/on_transfer(atom/A, method=INJECT, trans_volume) //prevents cheesing with ultralow doses.
	var/mob/living/carbon/C = A
	if(method == INJECT && iscarbon(A))
		if(trans_volume >= 4)
			C.apply_status_effect(/datum/status_effect/buff/moondust)
	else if(method == "swallow" && iscarbon(A))
		if(trans_volume >= 10)
			C.apply_status_effect(/datum/status_effect/buff/moondust)

/datum/reagent/moondust/overdose_start(mob/living/M)
	M.playsound_local(M, 'sound/misc/heroin_rush.ogg', 100, FALSE)
	M.visible_message(span_warning("Blood runs from [M]'s nose."))

/datum/reagent/moondust/overdose_process(mob/living/M)
	M.adjustToxLoss(10, 0)

/obj/item/reagent_containers/powder/moondust_purest
	name = "uncut moondust"
	desc = ""
	icon = 'icons/roguetown/items/produce.dmi'
	icon_state = "moondust_purest"
	possible_transfer_amounts = list()
	volume = 18
	list_reagents = list(/datum/reagent/moondust_purest = 18)
	grind_results = list(/datum/reagent/moondust_purest = 15)
	sellprice = 30

/datum/reagent/moondust_purest
	name = "Purest Moondust"
	description = ""
	color = "#bfc3b5"
	overdose_threshold = 19
	metabolization_rate = 0.2

/datum/reagent/moondust_purest/overdose_process(mob/living/M)
	M.adjustToxLoss(0.25*REM, 0)
	..()
	. = 1

/datum/reagent/moondust_purest/on_mob_metabolize(mob/living/M)
	narcolepsy_drug_up(M)
	M.playsound_local(M, 'sound/ravein/small/hello_my_friend.ogg', 100, FALSE)
	M.flash_fullscreen("can_you_see")
	M.overlay_fullscreen("purest_kaif", /atom/movable/screen/fullscreen/purest)
	animate(M.client, pixel_y = 1, time = 1, loop = -1, flags = ANIMATION_RELATIVE)
	animate(pixel_y = -1, time = 1, flags = ANIMATION_RELATIVE)

/datum/reagent/moondust_purest/on_mob_end_metabolize(mob/living/M)
	animate(M.client)
	M.clear_fullscreen("purest_kaif")

/datum/reagent/moondust_purest/on_mob_life(mob/living/carbon/M)
	narcolepsy_drug_up(M)
	M.Sleeping(-40)
	if(M.has_flaw(/datum/charflaw/addiction/junkie))
		M.sate_addiction()
	if(prob(20))
		M.flash_fullscreen("whiteflash")
	..()

/datum/reagent/moondust_purest/on_transfer(atom/A, method=INJECT, trans_volume) //prevents cheesing with ultralow doses.
	var/mob/living/carbon/C = A
	if(method == INJECT && iscarbon(A))
		if(trans_volume >= 4)
			C.apply_status_effect(/datum/status_effect/buff/moondust_purest)
	else if(method == "swallow" && iscarbon(A))
		if(trans_volume >= 10)
			C.apply_status_effect(/datum/status_effect/buff/moondust_purest)

/datum/reagent/moondust_purest/overdose_start(mob/living/M)
	M.playsound_local(M, 'sound/misc/heroin_rush.ogg', 100, FALSE)
	M.visible_message(span_warning("Blood runs from [M]'s nose."))

/datum/reagent/moondust_purest/overdose_process(mob/living/M)
	M.adjustToxLoss(10, 0)


//SEELIE DRUGS

/datum/reagent/seelie_drugs
	name = "Seelie Drugs"
	description = ""
	color = "#60A584" // rgb: 96, 165, 132
	overdose_threshold = 100
	metabolization_rate = 0.1

/datum/reagent/seelie_drugs/overdose_process(mob/living/M)
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 0.25*REM)
	M.adjustToxLoss(0.25*REM, 0)
	..()
	. = 1

/datum/reagent/seelie_drugs/on_mob_life(mob/living/carbon/M)
	M.set_drugginess(30)
	M.slurring += 3
	if(prob(5))
		if(M.gender == FEMALE)
			M.emote(pick("twitch_s","giggle", "drool"))
		else
			M.emote(pick("twitch_s","chuckle", "drool"))
	if(M.has_flaw(/datum/charflaw/addiction/junkie))
		M.sate_addiction()
	M.apply_status_effect(/datum/status_effect/buff/seelie_drugs)
	..()

/atom/movable/screen/fullscreen/seelie_drugs
	icon_state = "spa"
	plane = FLOOR_PLANE
	layer = ABOVE_OPEN_TURF_LAYER
	blend_mode = 0
	show_when_dead = FALSE

/datum/reagent/seelie_drugs/overdose_start(mob/living/M)
	M.visible_message(span_warning("Blood runs from [M]'s nose."))

/datum/reagent/seelie_drugs/overdose_process(mob/living/M)
	M.adjustToxLoss(10, 0)

/datum/reagent/seelie_drugs/on_mob_metabolize(mob/living/M)
	M.overlay_fullscreen("druqk", /atom/movable/screen/fullscreen/druqks)
	M.set_drugginess(30)
	M.slurring += 3
	M.update_body_parts_head_only()
	if(M.client)
		ADD_TRAIT(M, TRAIT_DRUQK, "based")
		SSdroning.area_entered(get_area(M), M.client)
//			if(M.client.screen && M.client.screen.len)
//				var/atom/movable/screen/plane_master/game_world/PM = locate(/atom/movable/screen/plane_master/game_world) in M.client.screen
//				PM.backdrop(M.client.mob)

/datum/reagent/seelie_drugs/on_mob_end_metabolize(mob/living/M)
	M.clear_fullscreen("druqk")
	M.slurring = 0
	M.set_drugginess(0)
	//M.remove_status_effect(/datum/status_effect/buff/seelie_drugs)
	M.update_body_parts_head_only()
	if(M.client)
		REMOVE_TRAIT(M, TRAIT_DRUQK, "based")
		SSdroning.play_area_sound(get_area(M), M.client)
//		if(M.client.screen && M.client.screen.len)
///			var/atom/movable/screen/plane_master/game_world/PM = locate(/atom/movable/screen/plane_master/game_world) in M.client.screen
//			PM.backdrop(M.client.mob)


/obj/item/reagent_containers/powder/alch
	name = "essence"
	desc = "powderized and ready to brew"
	gender = PLURAL
	icon_state = "salt"
	can_brew = TRUE
	list_reagents = null
	grind_results = null
	volume = 24

/obj/item/reagent_containers/powder/alch/berry
	name = "essence of berry"
	gender = PLURAL
	icon_state = "salt"
	color = "#4682b4"
	brew_reagent = /datum/reagent/alch/syrum_berry
	brew_amt = 24
	can_brew = TRUE
	list_reagents = null
	grind_results = null
	volume = 24

/obj/item/reagent_containers/powder/alch/berryp
	name = "essence of poison berry"
	gender = PLURAL
	icon_state = "salt"
	color = "#61DE2A"
	brew_reagent = /datum/reagent/alch/syrum_poison_berry
	brew_amt = 24
	can_brew = TRUE
	list_reagents = null
	grind_results = list(/datum/reagent/berrypoison = 10)
	volume = 10

/obj/item/reagent_containers/powder/alch/mincem
	name = "essence of flesh"
	gender = PLURAL
	icon_state = "salt"
	color = "#ff7f7f"
	can_brew = TRUE
	brew_reagent = /datum/reagent/alch/syrum_meat
	brew_amt = 24
	list_reagents = list(/datum/reagent/consumable/nutriment = 3)
	grind_results = null
	volume = 10

/obj/item/reagent_containers/powder/alch/mincef
	name = "essence of fish"
	gender = PLURAL
	icon_state = "salt"
	color = "#ff7f7f"
	brew_reagent = /datum/reagent/alch/syrum_fish
	brew_amt = 24
	can_brew = TRUE
	list_reagents = list(/datum/reagent/consumable/nutriment = 3)
	grind_results = null
	volume = 10

/obj/item/reagent_containers/powder/alch/stone
	name = "essence of earth"
	gender = PLURAL
	icon_state = "salt"
	brew_reagent = /datum/reagent/alch/syrum_stone
	brew_amt = 24
	can_brew = TRUE
	color = "#808080"
	list_reagents = null
	grind_results = null
	volume = 10

/obj/item/reagent_containers/powder/alch/pipe
	name = "essence of addiction"
	gender = PLURAL
	icon_state = "salt"
	brew_reagent = /datum/reagent/alch/syrum_westleach_leaf
	brew_amt = 24
	can_brew = TRUE
	color = "#808080"
	list_reagents = list(/datum/reagent/drug/nicotine = 30)
	grind_results = null
	volume = 10

/obj/item/reagent_containers/powder/alch/swamp
	name = "essence of clarity"
	gender = PLURAL
	icon_state = "salt"
	brew_reagent = /datum/reagent/alch/syrum_swamp_weed
	brew_amt = 24
	can_brew = TRUE
	color = "#61DE2A"
	list_reagents = list(/datum/reagent/drug/space_drugs = 30)
	grind_results = null
	volume = 10

/obj/item/reagent_containers/powder/alch/honey
	name = "essence of honey"
	gender = PLURAL
	icon_state = "salt"
	color = "#FFC30B"
	brew_reagent = /datum/reagent/alch/syrum_honey
	brew_amt = 24
	can_brew = TRUE
	list_reagents = null
	grind_results = null
	volume = 10

/datum/reagent/alch
	name = "hmm"
	description = "shouldnt see this"
	reagent_state = LIQUID
	color = "#808080"
	metabolization_rate = 0.25 * REAGENTS_METABOLISM
	overdose_threshold = null

/datum/reagent/alch/syrum_ash
	name = "syrum of fire"
	description = "refined viscous ash"
	reagent_state = LIQUID
	color = "#808080"
	metabolization_rate = 1 * REAGENTS_METABOLISM
	overdose_threshold = null

/datum/reagent/alch/syrum_westleach_leaf
	name = "west syrum"
	description = "refined west essence"
	reagent_state = LIQUID
	color = "#808080"
	metabolization_rate = 0.25 * REAGENTS_METABOLISM
	overdose_threshold = null

/datum/reagent/alch/syrum_swamp_weed
	name = "swamp syrum"
	description = "refined swamp weed"
	reagent_state = LIQUID
	color = "#61DE2A"
	metabolization_rate = 0.25 * REAGENTS_METABOLISM
	overdose_threshold = null

/datum/reagent/alch/syrum_meat
	name = "meaty syrum"
	description = "refined viscous slop"
	reagent_state = LIQUID
	color = "#ff7f7f"
	metabolization_rate = 1 * REAGENTS_METABOLISM
	overdose_threshold = null

/datum/reagent/alch/syrum_fish
	name = "fishy syrum"
	description = "refined viscous fishy smelling gunk"
	reagent_state = LIQUID
	color = "#ff7f7f"
	metabolization_rate = 1 * REAGENTS_METABOLISM
	overdose_threshold = null

/datum/reagent/alch/syrum_stone
	name = "earthy syrum"
	description = "refined liquid state stone"
	reagent_state = LIQUID
	color = "#E2E5DE"
	metabolization_rate = 0.25 * REAGENTS_METABOLISM
	overdose_threshold = null

/datum/reagent/alch/syrum_salt
	name = "salty syrum"
	description = "refined liquid state salt"
	reagent_state = LIQUID
	color = "#E2E5DE"
	metabolization_rate = 0.25 * REAGENTS_METABOLISM
	overdose_threshold = null

/datum/reagent/alch/syrum_poison_berry
	name = "poison syrum"
	description = "refined berry poison"
	reagent_state = LIQUID
	color = "#61DE2A"
	metabolization_rate = 0.25 * REAGENTS_METABOLISM
	overdose_threshold = null

/datum/reagent/alch/syrum_berry
	name = "berry syrum"
	description = "refined berry essence"
	reagent_state = LIQUID
	color = "#61DE2A"
	metabolization_rate = 0.25 * REAGENTS_METABOLISM
	overdose_threshold = null

/datum/reagent/alch/syrum_honey
	name = "honeysyrum"
	description = "refined honey essence"
	reagent_state = LIQUID
	color = "#FFC30B"
	metabolization_rate = 0.25 * REAGENTS_METABOLISM
	overdose_threshold = null
