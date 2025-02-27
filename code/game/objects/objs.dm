/obj
	animate_movement = 2
	speech_span = SPAN_ROBOT
	interaction_flags = INTERACT_OBJ_DEFAULT

	var/list/materials

	var/datum/armor/armor

	var/obj_integrity	//defaults to max_integrity
	var/max_integrity = 500
	var/integrity_failure = 0 //0 if we have no special broken behavior
	var/reliability = 100	//Used by SOME devices to determine how reliable they are.
	var/crit_fail = 0

	var/throwforce = 1

	var/mob/living/buckled_mob
	var/buckle_lying = FALSE //Is the mob buckled in a lying position
	var/can_buckle = FALSE

	var/resistance_flags = NONE
	var/obj_flags = NONE
	var/hit_sound //Sound this object makes when hit, overrides specific item hit sound.
	var/destroy_sound //Sound this object makes when destroyed.

	var/item_fire_stacks = 0	//How many fire stacks it applies
	var/obj/effect/xenomorph/acid/current_acid = null //If it has acid spewed on it

	var/list/req_access = null
	var/list/req_one_access = null

	//Don't directly use these two, please. No: magic numbers, Yes: defines.
	var/req_one_access_txt = "0"
	var/req_access_txt = "0"

/obj/Initialize()
	. = ..()
	if (islist(armor))
		armor = getArmor(arglist(armor))
	else if (!armor)
		armor = getArmor(bio = 100)
	else if (!istype(armor, /datum/armor))
		stack_trace("Invalid type [armor.type] found in .armor during /obj Initialize()")

	if(obj_integrity == null)
		obj_integrity = max_integrity

/obj/Destroy()
	if(buckled_mob)
		unbuckle()
	return ..()

/obj/proc/setAnchored(anchorvalue)
	SEND_SIGNAL(src, COMSIG_OBJ_SETANCHORED, anchorvalue)
	anchored = anchorvalue

/obj/ex_act()
	if(CHECK_BITFIELD(resistance_flags, INDESTRUCTIBLE))
		return
	return ..()

/obj/item/proc/is_used_on(obj/O, mob/user)
	return

/obj/process()
	STOP_PROCESSING(SSobj, src)
	return 0


/obj/proc/updateUsrDialog()
	if(!CHECK_BITFIELD(obj_flags, IN_USE))
		return
	var/is_in_use = FALSE

	var/mob/living/silicon/ai/AI
	if(isAI(usr))
		AI = usr
		if(AI.client && AI.interactee == src)
			is_in_use = TRUE
			if(interaction_flags & INTERACT_UI_INTERACT)
				ui_interact(AI)
			else
				interact(AI)

	for(var/mob/M in view(1, src))
		if(!M.client || M.interactee != src || M == AI)
			continue
		is_in_use = TRUE
		if(interaction_flags & INTERACT_UI_INTERACT)
			ui_interact(M)
		else
			interact(M)

	if(ismob(loc))
		var/mob/M = loc
		is_in_use = TRUE
		if(interaction_flags & INTERACT_UI_INTERACT)
			ui_interact(M)
		else
			interact(M)

	if(!is_in_use)
		DISABLE_BITFIELD(obj_flags, IN_USE)


/obj/proc/hide(h)
	return


/obj/attack_paw(mob/living/carbon/monkey/user)
	if(can_buckle) return src.attack_hand(user)
	else . = ..()

/obj/attack_hand(mob/living/user)
	. = ..()
	if(.)
		return FALSE
	if(can_buckle)
		return manual_unbuckle(user)


/obj/proc/handle_rotation()
	return

/obj/MouseDrop(atom/over_object)
	if(!can_buckle)
		. = ..()

/obj/MouseDrop_T(mob/M, mob/user)
	if(can_buckle)
		if(!istype(M)) return
		buckle_mob(M, user)
	else . = ..()

/obj/proc/afterbuckle(mob/M as mob) // Called after somebody buckled / unbuckled
	handle_rotation()
	return buckled_mob


/obj/proc/unbuckle(mob/user, silent = TRUE)
	var/mob/buckled_mob_backup = buckled_mob
	buckled_mob = null
	buckled_mob_backup.buckled = null
	buckled_mob_backup.glide_modifier_flags &= ~GLIDE_MOD_BUCKLED
	buckled_mob_backup.reset_glide_size()
	buckled_mob_backup.anchored = initial(buckled_mob_backup.anchored)
	buckled_mob_backup.update_canmove()

	if(!silent)
		if(buckled_mob_backup == user)
			buckled_mob_backup.visible_message(
			"<span class='notice'>[buckled_mob_backup] unbuckled [buckled_mob_backup.p_them()]self!</span>",
			"<span class='notice'>You unbuckle yourself from [src].</span>",
			"<span class='notice'>You hear metal clanking</span>"
			)
		else
			var/by_user = user ? " by [user]" : ""
			buckled_mob_backup.visible_message(
			"<span class='notice'>[buckled_mob_backup] was unbuckled[by_user]!</span>",
			"<span class='notice'>You were unbuckled from [src][by_user]].</span>",
			"<span class='notice'>You hear metal clanking.</span>"
			)

	UnregisterSignal(buckled_mob_backup, COMSIG_LIVING_DO_RESIST)
	afterbuckle(buckled_mob_backup)


/obj/proc/resisted_against(datum/source, mob/user) //COMSIG_LIVING_DO_RESIST
	if(user.restrained(RESTRAINED_XENO_NEST))
		return FALSE
	manual_unbuckle(user)


/obj/proc/manual_unbuckle(mob/user)
	if(!buckled_mob || buckled_mob.buckled != src)
		return FALSE
	unbuckle(user, FALSE)
	return TRUE


//trying to buckle a mob
/obj/proc/buckle_mob(mob/M, mob/user)
	if ( !ismob(M) || (get_dist(src, user) > 1) || user.restrained() || user.lying || user.stat || buckled_mob || M.buckled )
		return

	if (M.mob_size > MOB_SIZE_HUMAN)
		to_chat(user, "<span class='warning'>[M] is too big to buckle in.</span>")
		return
	if (istype(user, /mob/living/carbon/xenomorph))
		to_chat(user, "<span class='warning'>You don't have the dexterity to do that, try a nest.</span>")
		return

	if(density)
		density = FALSE
		if(!step(M, get_dir(M, src)) && loc != M.loc)
			density = TRUE
			return
		density = TRUE
	else
		if(M.loc != src.loc)
			return
	do_buckle(M, user)

//the actual buckling proc
/obj/proc/do_buckle(mob/M, mob/user, silent = FALSE)
	if(!silent)
		send_buckling_message(M, user)
	if(M.pulledby)
		M.pulledby.stop_pulling()
	if(pulledby)
		M.set_glide_size(pulledby.glide_size)
	else
		M.set_glide_size(glide_size)
	M.buckled = src
	M.glide_modifier_flags |= GLIDE_MOD_BUCKLED
	M.setDir(dir)
	M.update_canmove()
	buckled_mob = M
	RegisterSignal(M, COMSIG_LIVING_DO_RESIST, .proc/resisted_against)
	afterbuckle(M)

/obj/proc/send_buckling_message(mob/M, mob/user)
	if (M == user)
		M.visible_message(\
			"<span class='notice'>[M] buckles in!</span>",\
			"<span class='notice'>You buckle yourself to [src].</span>",\
			"<span class='notice'>You hear metal clanking.</span>")
	else
		M.visible_message(\
			"<span class='notice'>[M] is buckled in to [src] by [user]!</span>",\
			"<span class='notice'>You are buckled in to [src] by [user].</span>",\
			"<span class='notice'>You hear metal clanking</span>")

/obj/Move(NewLoc, direct)
	. = ..()
	handle_rotation()
	if(. && buckled_mob)
		if(buckled_mob.loc == NewLoc)
			return
		return handle_buckled_mob_movement(loc, direct) //movement fails if buckled mob's move fails.


/obj/proc/handle_buckled_mob_movement(NewLoc, direct)
	if((direct & (direct - 1))) //The obj's diagonal move is split into two cardinal moves and those moves will handle the buckled mob's movement.
		return TRUE
	if(buckled_mob.Move(NewLoc, direct))
		return TRUE
	forceMove(buckled_mob.loc)
	return FALSE

/obj/CanPass(atom/movable/mover, turf/target)
	if(mover == buckled_mob) //can't collide with the thing you're buckled to
		return TRUE
	. = ..()

/obj/effect_smoke(obj/effect/particle_effect/smoke/S)
	. = ..()
	if(!.)
		return
	if(CHECK_BITFIELD(S.smoke_traits, SMOKE_CHEM))
		var/turf/T = get_turf(src)
		if(!(T?.intact_tile) || level != 1) //not hidden under the floor
			S.reagents?.reaction(src, VAPOR, S.fraction)


/obj/on_set_interaction(mob/user)
	. = ..()
	ENABLE_BITFIELD(obj_flags, IN_USE)

/mob/proc/unset_machine()
	if(machine)
		machine.on_unset_machine(src)
		machine = null

//called when the user unsets the machine.
/atom/movable/proc/on_unset_machine(mob/user)
	return

/mob/proc/set_machine(obj/O)
	if(machine)
		unset_machine()
	machine = O
	if(istype(O))
		O.obj_flags |= IN_USE

/obj/vv_edit_var(var_name, var_value)
	switch(var_name)
		if("anchored")
			setAnchored(var_value)
			return TRUE
	return ..()
