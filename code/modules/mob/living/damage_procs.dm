
/*
	apply_damage(a,b,c)
	args
	a:damage - How much damage to take
	b:damage_type - What type of damage to take, brute, burn
	c:def_zone - Where to take the damage if its brute or burn
	Returns
	standard 0 if fail
*/
/mob/living/proc/apply_damage(damage = 0, damagetype = BRUTE, def_zone, blocked = 0, sharp = FALSE, edge = FALSE, updating_health = FALSE)
	var/hit_percent = (100 - blocked) * 0.01

	if(hit_percent <= 0) //total negation
		return FALSE

	damage *= CLAMP01(hit_percent) //Percentage reduction

	if(!damage) //no damage
		return 0

	switch(damagetype)
		if(BRUTE)
			adjustBruteLoss(damage)
		if(BURN)
			adjustFireLoss(damage)
		if(TOX)
			adjustToxLoss(damage)
		if(OXY)
			adjustOxyLoss(damage)
		if(CLONE)
			adjustCloneLoss(damage)
		if(HALLOSS)
			adjustHalLoss(damage)
		if(STAMINA)
			adjustStaminaLoss(damage)
	if(updating_health)
		updatehealth()
	return damage


/mob/living/proc/apply_damages(brute = 0, burn = 0, tox = 0, oxy = 0, clone = 0, halloss = 0, def_zone = null, blocked = 0, updating_health = FALSE)
	if(blocked >= 100) //Complete negation/100% reduction
		return FALSE
	if(brute)
		apply_damage(brute, BRUTE, def_zone, blocked)
	if(burn)
		apply_damage(burn, BURN, def_zone, blocked)
	if(tox)
		apply_damage(tox, TOX, def_zone, blocked)
	if(oxy)
		apply_damage(oxy, OXY, def_zone, blocked)
	if(clone)
		apply_damage(clone, CLONE, def_zone, blocked)
	if(halloss)
		apply_damage(halloss, HALLOSS, def_zone, blocked)
	if(updating_health)
		updatehealth()
	return TRUE



/mob/living/proc/apply_effect(effect = 0, effecttype = STUN, blocked = 0, updating_health = FALSE)
	if(!effect || (blocked >= 2))
		return 0
	switch(effecttype)
		if(STUN)
			stun(effect/(blocked+1))
		if(WEAKEN)
			knock_down(effect/(blocked+1))
		if(PARALYZE)
			knock_out(effect/(blocked+1))
		if(AGONY)
			adjustHalLoss(effect/(blocked+1))
		if(IRRADIATE)
			var/rad_protection = getarmor(null, "rad")/100
			radiation += max((1-rad_protection)*effect/(blocked+1),0)//Rads auto check armor
		if(STUTTER)
			if(status_flags & CANSTUN) // stun is usually associated with stutter
				stuttering = max(stuttering,(effect/(blocked+1)))
		if(EYE_BLUR)
			blur_eyes(effect/(blocked+1))
		if(DROWSY)
			adjustDrowsyness(effect / (blocked + 1))
	if(updating_health)
		updatehealth()
	return TRUE


/mob/living/proc/apply_effects(stun = 0, weaken = 0, paralyze = 0, irradiate = 0, stutter = 0, eyeblur = 0, drowsy = 0, agony = 0, blocked = 0, updating_health = FALSE)
	if(blocked >= 2)
		return FALSE
	if(stun)
		apply_effect(stun, STUN, blocked)
	if(weaken)
		apply_effect(weaken, WEAKEN, blocked)
	if(paralyze)
		apply_effect(paralyze, PARALYZE, blocked)
	if(irradiate)
		apply_effect(irradiate, IRRADIATE, blocked)
	if(stutter)
		apply_effect(stutter, STUTTER, blocked)
	if(eyeblur)
		apply_effect(eyeblur, EYE_BLUR, blocked)
	if(drowsy)
		apply_effect(drowsy, DROWSY, blocked)
	if(agony)
		apply_effect(agony, AGONY, blocked)
	if(updating_health)
		updatehealth()
	return TRUE
