/mob
	name = "mob"
	density = TRUE
	layer = MOB_LAYER
	animate_movement = SLIDE_STEPS
	datum_flags = DF_USE_TAG
	mouse_drag_pointer = MOUSE_ACTIVE_POINTER

	//Mob
	var/stat = CONSCIOUS //Whether a mob is alive or dead. TODO: Move this to living - Nodrak
	var/datum/mind/mind
	var/real_name
	var/mob_size = MOB_SIZE_HUMAN
	var/timeofdeath = 0
	var/a_intent = INTENT_HELP
	var/m_intent = MOVE_INTENT_RUN
	var/grab_level = GRAB_PASSIVE //if we're pulling a mob, tells us how aggressive our grab is.
	var/in_throw_mode = FALSE
	var/notransform = FALSE
	var/list/observers //The list of people observing this mob.
	var/status_flags = CANSTUN|CANKNOCKDOWN|CANKNOCKOUT|CANPUSH	//bitflags defining which status effects can be inflicted (replaces canweaken, canstun, etc)
	var/list/speak_emote = list("says") // Verbs used when speaking instead of the default ones.
	var/zone_selected = BODY_ZONE_CHEST
	var/bodytemperature = 310.055	//98.7 F
	var/hand
	var/bloody_hands = 0
	var/track_blood = 0
	var/feet_blood_color
	var/list/cooldowns = list()

	//Movement
	var/list/movespeed_modification // List of movement speed modifiers applying to this mob. Lazy list, see mob_movespeed.dm
	var/cached_multiplicative_slowdown // The calculated mob speed slowdown based on the modifiers list.
	var/next_click	= 0
	var/next_move = 0
	var/next_move_slowdown = 0	// Amount added during the next movement_delay(), then is reset.
	var/next_move_adjust = 0 //Amount to adjust action/click delays by, + or -
	var/next_move_modifier = 1 //Value to multiply action/click delays by
	var/last_move_intent
	var/area/lastarea
	var/old_x = 0
	var/old_y = 0
	var/inertia_dir = 0
	var/move_on_shuttle = TRUE // Can move on the shuttle.
	var/canmove = TRUE
	var/lying = FALSE
	var/lying_prev = FALSE

	//Security
	var/computer_id
	var/ip_address
	var/list/logging = list()
	var/static/next_mob_id = 0
	var/immune_to_ssd = FALSE

	//HUD and overlays
	var/hud_type = /datum/hud
	var/datum/hud/hud_used
	var/list/hud_possible //HUD images that this mob can provide.
	var/list/progressbars //for stacking do_after bars
	var/list/progbar_towers //for stacking the total pixel height of the aboves.
	var/list/fullscreens = list()
	var/list/alerts = list() // contains /obj/screen/alert only, used by alerts.dm
	var/list/datum/action/actions = list()
	var/list/actions_by_path = list()
	var/lighting_alpha = LIGHTING_PLANE_ALPHA_VISIBLE
	var/image/typing_indicator

	//Interaction
	var/action_busy //whether the mob is currently doing an action that takes time (do_after or do_mob procs)
	var/datum/click_intercept
	var/atom/movable/interactee //the thing that the mob is currently interacting with (e.g. a computer, another mob (stripping a mob), manning a hmg)
	var/obj/control_object //Used by admins to possess objects.
	var/atom/movable/remote_control //Calls relaymove() to whatever it is
	var/obj/buckled //Living
	var/obj/item/l_hand //Living
	var/obj/item/r_hand //Living
	var/obj/item/storage/s_active //Carbon
	var/obj/item/clothing/mask/wear_mask //Carbon
	var/turf/listed_turf	//the current turf being examined in the stat panel
	var/dextrous = FALSE //Has enough dexterity to interact with advanced objects?

	/// The machine the mob is interacting with (this is very bad old code btw)
	var/obj/machinery/machine = null

	//Input
	var/datum/focus //What receives our keyboard inputs. src by default

	var/updating_glide_size = TRUE //Whether the mob is updating glide size when movespeed updates or not

	/// Can they interact with station electronics
	var/has_unlimited_silicon_privilege = 0
