/////////////////////////////////////////////
//// SMOKE SYSTEMS
/////////////////////////////////////////////

/obj/effect/particle_effect/smoke
	name = "smoke"
	icon = 'icons/effects/96x96.dmi'
	icon_state = "smoke"
	pixel_x = -32
	pixel_y = -32
	opacity = 1
	layer = FLY_LAYER
	plane = GAME_PLANE_UPPER
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	animate_movement = 0
	var/amount = 4
	var/lifetime = 5
	var/opaque = 1 //whether the smoke can block the view when in enough amount

/obj/effect/particle_effect/smoke/arquebus
	name = "smoke"
	icon = 'icons/effects/96x96.dmi'
	icon_state = "smoke"
	pixel_x = -32
	pixel_y = -32
	opacity = FALSE
	layer = FLY_LAYER
	plane = GAME_PLANE_UPPER
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	animate_movement = 0
	amount = 4
	lifetime = 4
	opaque = FALSE

/obj/effect/particle_effect/smoke/proc/fade_out(frames = 16)
	if(alpha == 0) //Handle already transparent case
		return
	if(frames == 0)
		frames = 1 //We will just assume that by 0 frames, the coder meant "during one frame".
	var/step = alpha / frames
	for(var/i = 0, i < frames, i++)
		alpha -= step
		if(alpha < 160)
			set_opacity(0) //if we were blocking view, we aren't now because we're fading out
		stoplag()

/obj/effect/particle_effect/smoke/Initialize()
	. = ..()
	create_reagents(500)
	START_PROCESSING(SSobj, src)


/obj/effect/particle_effect/smoke/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/effect/particle_effect/smoke/proc/kill_smoke()
	STOP_PROCESSING(SSobj, src)
	INVOKE_ASYNC(src, PROC_REF(fade_out))
	QDEL_IN(src, 10)

/obj/effect/particle_effect/smoke/process()
	lifetime--
	if(lifetime < 1)
		kill_smoke()
		return 0
	for(var/mob/living/L in range(0,src))
		smoke_mob(L)
	return 1

/obj/effect/particle_effect/smoke/proc/smoke_mob(mob/living/carbon/C)
	if(!istype(C))
		return 0
	if(lifetime<1)
		return 0
	if(C.smoke_delay)
		return 0
	C.smoke_delay++
	addtimer(CALLBACK(src, PROC_REF(remove_smoke_delay), C), 10)
	return 1

/obj/effect/particle_effect/smoke/proc/remove_smoke_delay(mob/living/carbon/C)
	if(C)
		C.smoke_delay = 0

/obj/effect/particle_effect/smoke/proc/spread_smoke()
	var/turf/t_loc = get_turf(src)
	if(!t_loc)
		return
	var/list/newsmokes = list()
	for(var/turf/T in t_loc.GetAtmosAdjacentTurfs())
		var/obj/effect/particle_effect/smoke/foundsmoke = locate() in T //Don't spread smoke where there's already smoke!
		if(foundsmoke)
			continue
		for(var/mob/living/L in T)
			smoke_mob(L)
		var/obj/effect/particle_effect/smoke/S = new type(T)
		reagents.copy_to(S, reagents.total_volume)
		S.setDir(pick(GLOB.cardinals))
		S.amount = amount-1
		S.add_atom_colour(color, FIXED_COLOUR_PRIORITY)
		S.lifetime = lifetime
		if(S.amount>0)
			if(opaque)
				S.set_opacity(TRUE)
			newsmokes.Add(S)

	//the smoke spreads rapidly but not instantly
	for(var/obj/effect/particle_effect/smoke/SM in newsmokes)
		addtimer(CALLBACK(SM, TYPE_PROC_REF(/obj/effect/particle_effect/smoke, spread_smoke)), 1)


/datum/effect_system/smoke_spread
	var/amount = 10
	effect_type = /obj/effect/particle_effect/smoke

/datum/effect_system/smoke_spread/set_up(radius = 5, loca)
	if(isturf(loca))
		location = loca
	else
		location = get_turf(loca)
	amount = radius

/datum/effect_system/smoke_spread/start()
	if(holder)
		location = get_turf(holder)
	var/obj/effect/particle_effect/smoke/S = new effect_type(location)
	S.amount = amount
	if(S.amount)
		S.spread_smoke()


/////////////////////////////////////////////
// Bad smoke
/////////////////////////////////////////////

/obj/effect/particle_effect/smoke/bad
	lifetime = 8

/obj/effect/particle_effect/smoke/bad/smoke_mob(mob/living/carbon/M)
	if(..())
		M.drop_all_held_items()
		M.adjustOxyLoss(1)
		M.emote("cough")
		return 1

/obj/effect/particle_effect/smoke/bad/CanPass(atom/movable/mover, turf/target)
	if(istype(mover, /obj/projectile/beam))
		var/obj/projectile/beam/B = mover
		B.damage = (B.damage/2)
	return 1



/datum/effect_system/smoke_spread/bad
	effect_type = /obj/effect/particle_effect/smoke/bad


/////////////////////////////////////////////
// Poison gas
/////////////////////////////////////////////

/obj/effect/particle_effect/smoke/poison_gas
	color = "#369c50"
	lifetime = 10

/obj/effect/particle_effect/smoke/poison_gas/smoke_mob(mob/living/carbon/M)
	if(..())
		M.adjustToxLoss(10, 0)
		M.emote("cough")
		return 1

/datum/effect_system/smoke_spread/poison_gas
	effect_type = /obj/effect/particle_effect/smoke/poison_gas

/////////////////////////////////////////////
// HEALING_GAS
/////////////////////////////////////////////

/obj/effect/particle_effect/smoke/healing_gas
	color = "#da4011"
	lifetime = 15

/obj/effect/particle_effect/smoke/healing_gas/smoke_mob(mob/living/carbon/M)
	if(..())
		M.adjustBruteLoss(-0.5, 0)
		M.adjustFireLoss(-0.5, 0)
		M.adjustOxyLoss(-0.5, 0)
		M.adjustToxLoss(-0.5, 0)
		M.emote("cough")
		return 1

/datum/effect_system/smoke_spread/healing_gas
	effect_type = /obj/effect/particle_effect/smoke/healing_gas


/////////////////////////////////////////////
// FIRE_GAS
/////////////////////////////////////////////

/obj/effect/particle_effect/smoke/fire_gas
	color = "#d1b411"
	lifetime = 10

/obj/effect/particle_effect/smoke/fire_gas/smoke_mob(mob/living/carbon/M)
	if(..())
		M.adjustFireLoss(-3, 0)
		M.adjust_fire_stacks(3)
		M.IgniteMob()
		M.emote("scream")
		return 1

/datum/effect_system/smoke_spread/fire_gas
	effect_type = /obj/effect/particle_effect/smoke/fire_gas

/////////////////////////////////////////////
// BLIND_GAS
/////////////////////////////////////////////

/obj/effect/particle_effect/smoke/blind_gas
	color = "#292822"
	lifetime = 5

/obj/effect/particle_effect/smoke/blind_gas/smoke_mob(mob/living/carbon/M)
	if(..())
		M.adjust_blurriness(3)
		M.adjust_blindness(3)
		M.emote("cry")
		return 1

/datum/effect_system/smoke_spread/blind_gas
	effect_type = /obj/effect/particle_effect/smoke/blind_gas


/////////////////////////////////////////////
// MUTE_GAS
/////////////////////////////////////////////

/obj/effect/particle_effect/smoke/mute_gas
	color = "#529bfc"
	lifetime = 10

/obj/effect/particle_effect/smoke/mute_gas/smoke_mob(mob/living/carbon/M)
	if(..())
		M.silent = max(M.silent, 8)
		return 1

/datum/effect_system/smoke_spread/mute_gas
	effect_type = /obj/effect/particle_effect/smoke/mute_gas


/*Cleansing smoke*/
//for the necra censer.
/obj/effect/particle_effect/smoke/necra_censer
	name = "cleansing mist"
	icon = 'icons/effects/effects.dmi'
	icon_state = "extinguish"
	pixel_x = 0
	pixel_y = 0
	opacity = 0
	layer = FLY_LAYER
	plane = GAME_PLANE_UPPER
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	animate_movement = 0
	amount = 4
	lifetime = 1
	density = 0
	opaque =  0 //whether the smoke can block the view when in enough amount

/obj/effect/particle_effect/smoke/necra_censer/New(loc, ...)
	. = ..()
	if(istype(loc, /turf))
		var/turf/T = loc
		for(var/obj/effect/decal/cleanable/C in T)
			qdel(C)

		for(var/obj/effect/decal/remains/R in T)
			qdel(R) //clean remains up
		
		for(var/atom/A in T)
			wash_atom(A, CLEAN_STRONG)


/datum/effect_system/smoke_spread/smoke/necra_censer
	effect_type = /obj/effect/particle_effect/smoke/necra_censer


/////////////////////////////////////////////
// Sleep smoke
/////////////////////////////////////////////

/obj/effect/particle_effect/smoke/sleeping
	color = "#9C3636"
	lifetime = 10

/obj/effect/particle_effect/smoke/sleeping/smoke_mob(mob/living/carbon/M)
	if(..())
		M.Sleeping(200)
		M.emote("cough")
		return 1

/datum/effect_system/smoke_spread/sleeping
	effect_type = /obj/effect/particle_effect/smoke/sleeping


/*====================
Zizo Bane sleep powder
====================*/
/datum/effect_system/smoke_spread/zizosleep
	effect_type = /obj/effect/particle_effect/smoke/zizosleep

/obj/effect/particle_effect/smoke/zizosleep/smoke_mob(mob/living/carbon/M)
	if(..())
		M.emote("cough")
		M.apply_status_effect(/datum/status_effect/debuff/knockout)
		return 1

/obj/effect/particle_effect/smoke/zizosleep
	name = "sleep spores"
	icon = 'icons/effects/effects.dmi'
	icon_state = "sleep"
	pixel_x = 0
	pixel_y = 0
	opacity = 0
	layer = FLY_LAYER
	plane = GAME_PLANE_UPPER
	anchored = TRUE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	animate_movement = 0
	amount = 4
	lifetime = 8
	density = 0
	opaque =  0 //whether the smoke can block the view when in enough amount


/////////////////////////////////////////////
// Chem smoke
/////////////////////////////////////////////

/obj/effect/particle_effect/smoke/chem
	lifetime = 10


/obj/effect/particle_effect/smoke/chem/process()
	if(..())
		var/turf/T = get_turf(src)
		var/fraction = 1/initial(lifetime)
		for(var/atom/movable/AM in T)
			if(AM.type == src.type)
				continue
			if(T.intact && AM.level == 1) //hidden under the floor
				continue
			reagents.reaction(AM, TOUCH, fraction)

		reagents.reaction(T, TOUCH, fraction)
		return 1

/obj/effect/particle_effect/smoke/chem/smoke_mob(mob/living/carbon/M)
	if(lifetime<1)
		return 0
	if(!istype(M))
		return 0
	var/fraction = 1/initial(lifetime)
	reagents.copy_to(M, fraction*reagents.total_volume)
	reagents.reaction(M, INGEST, fraction)
	return 1



/datum/effect_system/smoke_spread/chem
	var/obj/chemholder
	effect_type = /obj/effect/particle_effect/smoke/chem

/datum/effect_system/smoke_spread/chem/New()
	..()
	chemholder = new /obj()
	var/datum/reagents/R = new/datum/reagents(500)
	chemholder.reagents = R
	R.my_atom = chemholder

/datum/effect_system/smoke_spread/chem/Destroy()
	qdel(chemholder)
	chemholder = null
	return ..()

/datum/effect_system/smoke_spread/chem/set_up(datum/reagents/carry = null, radius = 1, loca, silent = FALSE)
	if(isturf(loca))
		location = loca
	else
		location = get_turf(loca)
	amount = radius
	carry.copy_to(chemholder, carry.total_volume)

	if(!silent)
		var/contained = ""
		for(var/reagent in carry.reagent_list)
			contained += " [reagent] "
		if(contained)
			contained = "\[[contained]\]"

		var/where = "[AREACOORD(location)]"
		if(carry.my_atom.fingerprintslast)
			var/mob/M = get_mob_by_key(carry.my_atom.fingerprintslast)
			var/more = ""
			if(M)
				more = "[ADMIN_LOOKUPFLW(M)] "
			message_admins("Smoke: ([ADMIN_VERBOSEJMP(location)])[contained]. Key: [more ? more : carry.my_atom.fingerprintslast].")
			log_game("A chemical smoke reaction has taken place in ([where])[contained]. Last touched by [carry.my_atom.fingerprintslast].")
		else
			message_admins("Smoke: ([ADMIN_VERBOSEJMP(location)])[contained]. No associated key.")
			log_game("A chemical smoke reaction has taken place in ([where])[contained]. No associated key.")


/datum/effect_system/smoke_spread/chem/start()
	var/mixcolor = mix_color_from_reagents(chemholder.reagents.reagent_list)
	if(holder)
		location = get_turf(holder)
	var/obj/effect/particle_effect/smoke/chem/S = new effect_type(location)

	if(chemholder.reagents.total_volume > 1) // can't split 1 very well
		chemholder.reagents.copy_to(S, chemholder.reagents.total_volume)

	if(mixcolor)
		S.add_atom_colour(mixcolor, FIXED_COLOUR_PRIORITY) // give the smoke color, if it has any to begin with
	S.amount = amount
	if(S.amount)
		S.spread_smoke() //calling process right now so the smoke immediately attacks mobs.


/////////////////////////////////////////////
// Transparent smoke
/////////////////////////////////////////////

//Same as the base type, but the smoke produced is not opaque
/datum/effect_system/smoke_spread/transparent
	effect_type = /obj/effect/particle_effect/smoke/transparent

/obj/effect/particle_effect/smoke/transparent
	alpha = 50
	opacity = FALSE
	lifetime = 3

/proc/do_smoke(range=0, location=null, smoke_type=/obj/effect/particle_effect/smoke)
	var/datum/effect_system/smoke_spread/smoke = new
	smoke.effect_type = smoke_type
	smoke.set_up(range, location)
	smoke.start()
