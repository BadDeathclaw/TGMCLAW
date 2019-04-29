

/obj/item/radio
	icon = 'icons/obj/items/radio.dmi'
	name = "station bounced radio"
	suffix = "\[3\]"
	icon_state = "walkietalkie"
	item_state = "walkietalkie"
	var/on = 1 // 0 for off
	var/last_transmission
	var/frequency = PUB_FREQ //common chat
	var/traitor_frequency = 0 //tune to frequency to unlock traitor supplies
	var/canhear_range = 3 // the range which mobs can hear this radio from
	var/obj/item/radio/patch_link = null
	var/wires = WIRE_SIGNAL|WIRE_RECEIVE|WIRE_TRANSMIT
	var/b_stat = 0
	var/broadcasting = 0
	var/listening = 1
	var/freerange = 0 // 0 - Sanitize frequencies, 1 - Full range
	var/list/channels = list() //see communications.dm for full list. First channes is a "default" for :h
	var/subspace_transmission = 0
	var/syndie = 0//Holder to see if it's a syndicate encrpyed radio
	var/maxf = 1499
//			"Example" = FREQ_LISTENING|FREQ_BROADCASTING
	flags_atom = CONDUCT
	flags_equip_slot = ITEM_SLOT_BELT
	throw_speed = 2
	throw_range = 9
	w_class = 2

	matter = list("glass" = 25,"metal" = 75)

	var/const/WIRE_SIGNAL = 1 //sends a signal, like to set off a bomb or electrocute someone
	var/const/WIRE_RECEIVE = 2
	var/const/WIRE_TRANSMIT = 4
	var/const/TRANSMISSION_DELAY = 5 // only 2/second/radio
	var/const/FREQ_LISTENING = 1
		//FREQ_BROADCASTING = 2

/obj/item/radio
	var/datum/radio_frequency/radio_connection
	var/list/datum/radio_frequency/secure_radio_connections = new

	proc/set_frequency(new_frequency)
		SSradio.remove_object(src, frequency)
		frequency = new_frequency
		radio_connection = SSradio.add_object(src, frequency, RADIO_CHAT)

/obj/item/radio/Initialize()
	. = ..()
	if(!SSradio)
		return
	if(freerange)
		if(frequency < 1200 || frequency > 1600)
			frequency = sanitize_frequency(frequency, maxf)
	// The max freq is higher than a regular headset to decrease the chance of people listening in, if you use the higher channels.
	else if (frequency < 1441 || frequency > maxf)
		//log_world("[src] ([type]) has a frequency of [frequency], sanitizing.")
		frequency = sanitize_frequency(frequency, maxf)

	set_frequency(frequency)

	for (var/ch_name in channels)
		secure_radio_connections[ch_name] = SSradio.add_object(src, radiochannels[ch_name],  RADIO_CHAT)


/obj/item/radio/attack_self(mob/user as mob)
	user.set_interaction(src)
	interact(user)

/obj/item/radio/interact(mob/user as mob)
	if(!on)
		return

	var/dat

	if(!istype(src, /obj/item/radio/headset)) //Headsets dont get a mic button
		dat += "Microphone: [broadcasting ? "<A href='byond://?src=\ref[src];talk=0'>Engaged</A>" : "<A href='byond://?src=\ref[src];talk=1'>Disengaged</A>"]<BR>"

	dat += {"
				Speaker: [listening ? "<A href='byond://?src=\ref[src];listen=0'>Engaged</A>" : "<A href='byond://?src=\ref[src];listen=1'>Disengaged</A>"]<BR>
				Frequency: 	[format_frequency(frequency)] "}
//				<A href='byond://?src=\ref[src];freq=-10'>-</A>
//				<A href='byond://?src=\ref[src];freq=-2'>-</A>
//
//				<A href='byond://?src=\ref[src];freq=2'>+</A>
//				<A href='byond://?src=\ref[src];freq=10'>+</A><BR>
//				"}

	for (var/ch_name in channels)
		dat+=text_sec_channel(ch_name, channels[ch_name])
	dat+={"[text_wires()]"}

	var/datum/browser/popup = new(user, "radio", "<div align='center'>[src]</div>")
	popup.set_content(dat)
	popup.open(FALSE)
	onclose(user, "radio")


/obj/item/radio/proc/text_wires()
	if (!b_stat)
		return ""
	return {"
			<hr>
			Green Wire: <A href='byond://?src=\ref[src];wires=4'>[(wires & 4) ? "Cut" : "Mend"] Wire</A><BR>
			Red Wire:   <A href='byond://?src=\ref[src];wires=2'>[(wires & 2) ? "Cut" : "Mend"] Wire</A><BR>
			Blue Wire:  <A href='byond://?src=\ref[src];wires=1'>[(wires & 1) ? "Cut" : "Mend"] Wire</A><BR>
			"}


/obj/item/radio/proc/text_sec_channel(var/chan_name, var/chan_stat)
	var/list = !!(chan_stat&FREQ_LISTENING)!=0
	return {"
			<B>[chan_name]</B><br>
			Speaker: <A href='byond://?src=\ref[src];ch_name=[chan_name];listen=[!list]'>[list ? "Engaged" : "Disengaged"]</A><BR>
			"}

/obj/item/radio/Topic(href, href_list)
	//..()
	if (usr.stat || !on)
		return

	if (!(issilicon(usr) || (usr.contents.Find(src) || ( in_range(src, usr) && istype(loc, /turf) ))))
		usr << browse(null, "window=radio")
		return
	usr.set_interaction(src)
	if (href_list["track"])
		var/mob/target = locate(href_list["track"])
		var/mob/living/silicon/ai/A = locate(href_list["track2"])
		if(A && target)
			A.ai_actual_track(target)
		return

	else if (href_list["freq"])
		var/new_frequency = (frequency + text2num(href_list["freq"]))
		if (!freerange || (frequency < 1200 || frequency > 1600))
			new_frequency = sanitize_frequency(new_frequency, maxf)
		set_frequency(new_frequency)

	else if (href_list["talk"])
		broadcasting = text2num(href_list["talk"])
	else if (href_list["listen"])
		var/chan_name = href_list["ch_name"]
		if (!chan_name)
			listening = text2num(href_list["listen"])
		else
			if (channels[chan_name] & FREQ_LISTENING)
				channels[chan_name] &= ~FREQ_LISTENING
			else
				channels[chan_name] |= FREQ_LISTENING
	else if (href_list["wires"])
		var/t1 = text2num(href_list["wires"])
		if (!iswirecutter(usr.get_active_held_item()))
			return
		if (wires & t1)
			wires &= ~t1
		else
			wires |= t1
	if (!( master ))
		if (istype(loc, /mob))
			interact(loc)
		else
			updateDialog()
	else
		if (istype(master.loc, /mob))
			interact(master.loc)
		else
			updateDialog()
	add_fingerprint(usr)

/obj/item/radio/proc/autosay(var/message, var/from, var/channel) //BS12 EDIT
	var/datum/radio_frequency/connection = null
	if(channel && channels && channels.len > 0)
		if (channel == "department")
			//to_chat(world, "DEBUG: channel=\"[channel]\" switching to \"[channels[1]]\"")
			channel = channels[1]
		connection = secure_radio_connections[channel]
	else
		connection = radio_connection
		channel = null
	if (!istype(connection))
		return
	if (!connection)
		return

	var/mob/living/silicon/ai/A = new /mob/living/silicon/ai(src, null, null, 1)
	Broadcast_Message(connection, A,
						0, "*garbled automated announcement*", src,
						message, from, "Automated Announcement", from, from,
						4, 0, list(1), PUB_FREQ, "announces", /datum/language/common)
	qdel(A)
	return

// Interprets the message mode when talking into a radio, possibly returning a connection datum
/obj/item/radio/proc/handle_message_mode(mob/living/M as mob, message, message_mode)
	// If a channel isn't specified, send to common.
	if(!message_mode || message_mode == MODE_HEADSET)
		return radio_connection

	// Otherwise, if a channel is specified, look for it.
	if(channels && channels.len)
		if (message_mode == MODE_DEPARTMENT) // Department radio shortcut
			message_mode = channels[1]

		if (channels[message_mode]) // only broadcast if the channel is set on
			return secure_radio_connections[message_mode]

	// If we were to send to a channel we don't have, drop it.
	return null

/obj/item/radio/talk_into(mob/living/M, message, channel, list/spans, datum/language/language)
	if(!on) return // the device has to be on
	//  Fix for permacell radios, but kinda eh about actually fixing them.
	if(!M || !message) return

	//  Uncommenting this. To the above comment:
	// 	The permacell radios aren't suppose to be able to transmit, this isn't a bug and this "fix" is just making radio wires useless. -Giacom
	if(!(src.wires & WIRE_TRANSMIT)) // The device has to have all its wires and shit intact
		return

	M.last_target_click = world.time

	/* Quick introduction:
		This new radio system uses a very robust FTL signaling technology unoriginally
		dubbed "subspace" which is somewhat similar to 'blue-space' but can't
		actually transmit large mass. Headsets are the only radio devices capable
		of sending subspace transmissions to the Communications Satellite.

		A headset sends a signal to a subspace listener/reciever elsewhere in space,
		the signal gets processed and logged, and an audible transmission gets sent
		to each individual headset.
	*/

	//#### Grab the connection datum ####//
	var/datum/language/L = GLOB.language_datum_instances[language]
	var/verb = L.get_spoken_verb(copytext(message, length(message)))
	var/datum/radio_frequency/connection = handle_message_mode(M, message, channel)
	if (!istype(connection))
		return
	if (!connection)
		return

	var/turf/position = get_turf(src)

	//#### Tagging the signal with all appropriate identity values ####//

	// ||-- The mob's name identity --||
	var/displayname = M.name	// grab the display name (name you get when you hover over someone's icon)
	var/real_name = M.real_name // mob's real name
	var/mobkey = "none" // player key associated with mob
	var/voicemask = 0 // the speaker is wearing a voice mask
	if(M.client)
		mobkey = M.key // assign the mob's key


	var/jobname // the mob's "job"

	// --- Human: use their actual job ---
	if (ishuman(M))
		jobname = M:get_assignment()

	// --- Carbon Nonhuman ---
	else if (iscarbon(M)) // Nonhuman carbon mob
		jobname = "No id"

	// --- AI ---
	else if (isAI(M))
		jobname = "AI"

	// --- Cyborg ---
	else if (iscyborg(M))
		jobname = "Cyborg"

	// --- Unidentifiable mob ---
	else
		jobname = "Unknown"


	// --- Modifications to the mob's identity ---

	// The mob is disguising their identity:
	if (ishuman(M) && M.GetVoice() != real_name)
		displayname = M.GetVoice()
		jobname = "Unknown"
		voicemask = 1

	if(iscarbon(M.loc))
		var/mob/living/carbon/C = M.loc
		if(M in C.stomach_contents)
			message = Gibberish(message, 100)

  /* ###### Radio headsets can only broadcast through subspace ###### */

	if(subspace_transmission)
		// First, we want to generate a new radio signal
		var/datum/signal/signal = new
		signal.transmission_method = 2 // 2 would be a subspace transmission.
									   // transmission_method could probably be enumerated through #define. Would be neater.

		// --- Finally, tag the actual signal with the appropriate values ---
		signal.data = list(
		  // Identity-associated tags:
			"mob" = M, // store a reference to the mob
			"mobtype" = M.type, 	// the mob's type
			"realname" = real_name, // the mob's real name
			"name" = displayname,	// the mob's display name
			"job" = jobname,		// the mob's job
			"key" = mobkey,			// the mob's key
			"vmessage" = pick(M.speak_emote), // the message to display if the voice wasn't understood
			"vname" = M.voice_name, // the name to display if the voice wasn't understood
			"vmask" = voicemask,	// 1 if the mob is using a voice gas mask

			// We store things that would otherwise be kept in the actual mob
			// so that they can be logged even AFTER the mob is deleted or something

		  // Other tags:
			"compression" = rand(45,50), // compressed radio signal
			"message" = message, // the actual sent message
			"connection" = connection, // the radio connection to use
			"radio" = src, // stores the radio used for transmission
			"slow" = 0, // how much to sleep() before broadcasting - simulates net lag
			"traffic" = 0, // dictates the total traffic sum that the signal went through
			"type" = 0, // determines what type of radio input it is: normal broadcast
			"server" = null, // the last server to log this signal
			"reject" = 0,	// if nonzero, the signal will not be accepted by any broadcasting machinery
			"level" = position.z, // The source's z level
			"language" = language,
			"verb" = verb
		)
		signal.frequency = connection.frequency // Quick frequency set

	  //#### Sending the signal to all subspace receivers ####//

		for(var/obj/machinery/telecomms/receiver/R in telecomms_list)
			R.receive_signal(signal)

		// Allinone can act as receivers.
		for(var/obj/machinery/telecomms/allinone/R in telecomms_list)
			R.receive_signal(signal)

		// Receiving code can be located in Telecommunications.dm
		return


  /* ###### Intercoms and station-bounced radios ###### */

	var/filter_type = 2

	/* --- Intercoms can only broadcast to other intercoms, but bounced radios can broadcast to bounced radios and intercoms --- */
	if(istype(src, /obj/item/radio/intercom))
		filter_type = 1


	var/datum/signal/signal = new
	signal.transmission_method = 2


	/* --- Try to send a normal subspace broadcast first */

	signal.data = list(

		"mob" = M, // store a reference to the mob
		"mobtype" = M.type, 	// the mob's type
		"realname" = real_name, // the mob's real name
		"name" = displayname,	// the mob's display name
		"job" = jobname,		// the mob's job
		"key" = mobkey,			// the mob's key
		"vmessage" = pick(M.speak_emote), // the message to display if the voice wasn't understood
		"vname" = M.voice_name, // the name to display if the voice wasn't understood
		"vmask" = voicemask,	// 1 if the mob is using a voice gas mas

		"compression" = 0, // uncompressed radio signal
		"message" = message, // the actual sent message
		"connection" = connection, // the radio connection to use
		"radio" = src, // stores the radio used for transmission
		"slow" = 0,
		"traffic" = 0,
		"type" = 0,
		"server" = null,
		"reject" = 0,
		"level" = position.z,
		"language" = language,
		"verb" = verb
	)
	signal.frequency = connection.frequency // Quick frequency set

	for(var/obj/machinery/telecomms/receiver/R in telecomms_list)
		R.receive_signal(signal)


	sleep(rand(10,25)) // wait a little...

	if(signal.data["done"] && position.z in signal.data["level"])
		// we're done here.
		return

	// Oh my god; the comms are down or something because the signal hasn't been broadcasted yet in our level.
	// Send a mundane broadcast with limited targets:

	//THIS IS TEMPORARY. YEAH RIGHT
	if(!connection)	return	//~Carn

	Broadcast_Message(connection, M, voicemask, pick(M.speak_emote),
					  src, message, displayname, jobname, real_name, M.voice_name,
					  filter_type, signal.data["compression"], list(position.z), connection.frequency,verb,language)


/obj/item/radio/Hear(message, atom/movable/speaker, message_language, raw_message, radio_freq, list/spans, message_mode)
	. = ..()

	if(radio_freq || !broadcasting || get_dist(src, speaker) > canhear_range)
		return

	if(message_mode == MODE_WHISPER || message_mode == MODE_WHISPER_CRIT)
		// radios don't pick up whispers very well
		raw_message = stars(raw_message)
	
	else if(message_mode == MODE_L_HAND || message_mode == MODE_R_HAND)
		// try to avoid being heard double
		if(loc == speaker && ismob(speaker))
			var/mob/M = speaker
			if(M.l_hand == src && message_mode != MODE_L_HAND)
				return
			else if(M.r_hand == src && message_mode != MODE_R_HAND)
				return

	talk_into(speaker, raw_message, , spans, language = message_language)


/*
/obj/item/radio/proc/accept_rad(obj/item/radio/R as obj, message)

	if ((R.frequency == frequency && message))
		return 1
	else if

	else
		return null
	return
*/


/obj/item/radio/proc/receive_range(freq, level)
	// check if this radio can receive on the given frequency, and if so,
	// what the range is in which mobs will hear the radio
	// returns: -1 if can't receive, range otherwise

	if (!(wires & WIRE_RECEIVE))
		return -1
	if(!listening)
		return -1
	if(!(0 in level))
		var/turf/position = get_turf(src)
		if(!position || !(position.z in level))
			return -1
	if(freq in ANTAG_FREQS)
		if(!(src.syndie))//Checks to see if it's allowed on that frequency, based on the encryption keys
			return -1
	if (!on)
		return -1
	if (!freq) //recieved on main frequency
		if (!listening)
			return -1
	else
		var/accept = (freq==frequency && listening)
		if (!accept)
			for (var/ch_name in channels)
				var/datum/radio_frequency/RF = secure_radio_connections[ch_name]
				if (RF.frequency==freq && (channels[ch_name]&FREQ_LISTENING))
					accept = 1
					break
		if (!accept)
			return -1
	return canhear_range

/obj/item/radio/proc/send_hear(freq, level)

	var/range = receive_range(freq, level)
	if(range > -1)
		return get_mobs_in_view(canhear_range, src)


/obj/item/radio/examine(mob/user)
	..()
	if ((in_range(src, user) || loc == user))
		if (b_stat)
			to_chat(user, "<span class='notice'>[src] can be attached and modified!</span>")
		else
			to_chat(user, "<span class='notice'>[src] can not be modified or attached!</span>")


/obj/item/radio/attackby(obj/item/W as obj, mob/user as mob)
	..()
	user.set_interaction(src)
	if (!isscrewdriver(W))
		return
	b_stat = !( b_stat )
	if(!istype(src, /obj/item/radio/beacon))
		if (b_stat)
			user.show_message("<span class='notice'> The radio can now be attached and modified!</span>")
		else
			user.show_message("<span class='notice'> The radio can no longer be modified or attached!</span>")
		updateDialog()
			//Foreach goto(83)
		add_fingerprint(user)
		return
	else return

/obj/item/radio/emp_act(severity)
	broadcasting = 0
	listening = 0
	for (var/ch_name in channels)
		channels[ch_name] = 0
	..()

///////////////////////////////
//////////Borg Radios//////////
///////////////////////////////
//Giving borgs their own radio to have some more room to work with -Sieve

/obj/item/radio/borg
	var/mob/living/silicon/robot/myborg = null // Cyborg which owns this radio. Used for power checks
	var/obj/item/encryptionkey/keyslot = null//Borg radios can handle a single encryption key
	var/shut_up = 0
	icon = 'icons/obj/robot_component.dmi' // Cyborgs radio icons should look like the component.
	icon_state = "radio"
	canhear_range = 3

/obj/item/radio/borg/talk_into()
	..()
	if (iscyborg(src.loc))
		var/mob/living/silicon/robot/R = src.loc
		var/datum/robot_component/C = R.components["radio"]
		R.cell_use_power(C.active_usage)

/obj/item/radio/borg/attackby(obj/item/W as obj, mob/user as mob)
//	..()
	user.set_interaction(src)
	if (!(isscrewdriver(W) || (istype(W, /obj/item/encryptionkey/ ))))
		return

	if(isscrewdriver(W))
		if(keyslot)


			for(var/ch_name in channels)
				SSradio.remove_object(src, radiochannels[ch_name])
				secure_radio_connections[ch_name] = null


			if(keyslot)
				var/turf/T = get_turf(user)
				if(T)
					keyslot.loc = T
					keyslot = null

			recalculateChannels()
			to_chat(user, "You pop out the encryption key in the radio!")

		else
			to_chat(user, "This radio doesn't have any encryption keys!")

	if(istype(W, /obj/item/encryptionkey/))
		if(keyslot)
			to_chat(user, "The radio can't hold another key!")
			return

		if(!keyslot)
			if(user.drop_held_item())
				W.forceMove(src)
				keyslot = W

		recalculateChannels()

	return

/obj/item/radio/borg/proc/recalculateChannels()
	src.channels = list()
	src.syndie = 0

	var/mob/living/silicon/robot/D = src.loc
	if(D.module)
		for(var/ch_name in D.module.channels)
			if(ch_name in src.channels)
				continue
			src.channels += ch_name
			src.channels[ch_name] += D.module.channels[ch_name]
	if(keyslot)
		for(var/ch_name in keyslot.channels)
			if(ch_name in src.channels)
				continue
			src.channels += ch_name
			src.channels[ch_name] += keyslot.channels[ch_name]

		if(keyslot.syndie)
			src.syndie = 1


	for (var/ch_name in src.channels)
		if(!SSradio)
			sleep(30) // Waiting for the SSradio to be created.
		if(!SSradio)
			src.name = "broken radio"
			return

		secure_radio_connections[ch_name] = SSradio.add_object(src, radiochannels[ch_name],  RADIO_CHAT)

	return

/obj/item/radio/borg/Topic(href, href_list)
	if(usr.stat || !on)
		return
	if (href_list["mode"])
		if(subspace_transmission != 1)
			subspace_transmission = 1
			to_chat(usr, "Subspace Transmission is disabled")
		else
			subspace_transmission = 0
			to_chat(usr, "Subspace Transmission is enabled")
		if(subspace_transmission == 1)//Simple as fuck, clears the channel list to prevent talking/listening over them if subspace transmission is disabled
			channels = list()
		else
			recalculateChannels()
	if (href_list["shutup"]) // Toggle loudspeaker mode, AKA everyone around you hearing your radio.
		shut_up = !shut_up
		if(shut_up)
			canhear_range = 0
		else
			canhear_range = 3

	..()

/obj/item/radio/borg/interact(mob/user as mob)
	if(!on)
		return

	var/dat = {"
				Speaker: [listening ? "<A href='byond://?src=\ref[src];listen=0'>Engaged</A>" : "<A href='byond://?src=\ref[src];listen=1'>Disengaged</A>"]<BR>
				Frequency:
				<A href='byond://?src=\ref[src];freq=-10'>-</A>
				<A href='byond://?src=\ref[src];freq=-2'>-</A>
				[format_frequency(frequency)]
				<A href='byond://?src=\ref[src];freq=2'>+</A>
				<A href='byond://?src=\ref[src];freq=10'>+</A><BR>
				<A href='byond://?src=\ref[src];mode=1'>Toggle Broadcast Mode</A><BR>
				<A href='byond://?src=\ref[src];shutup=1'>Toggle Loudspeaker</A><BR>
				"}

	if(!subspace_transmission)//Don't even bother if subspace isn't turned on
		for (var/ch_name in channels)
			dat+=text_sec_channel(ch_name, channels[ch_name])
	dat += {"[text_wires()]"}

	var/datum/browser/popup = new(user, "radio", "<div align='center'>[src]</div>")
	popup.set_content(dat)
	popup.open(FALSE)
	onclose(user, "radio")


/obj/item/radio/proc/config(op)
	if(SSradio)
		for (var/ch_name in channels)
			SSradio.remove_object(src, radiochannels[ch_name])
	secure_radio_connections = new
	channels = op
	if(SSradio)
		for (var/ch_name in op)
			secure_radio_connections[ch_name] = SSradio.add_object(src, radiochannels[ch_name],  RADIO_CHAT)
	return

/obj/item/radio/off
	listening = 0



//MARINE RADIO

/obj/item/radio/marine
	frequency = PUB_FREQ