#include <amxmodx>
#include <hamsandwich>
#include <fakemeta>
#include <zombie_plague_special>

#if ZPS_INC_VERSION < 45
	#assert Zombie Plague Special 4.5 Include File Required. Download Link: https://forums.alliedmods.net/showthread.php?t=260845
#endif


new const ITEM_NAME[] = "Golden M4";
new const ITEM_COST = 130;


new const V_GOLD_MODEL[] = "models/zombie_plague/v_golden_m4a1_UP.mdl";
new const P_GOLD_MODEL[] = "models/zombie_plague/p_golden_m4a1_UP.mdl";
new const W_GOLD_WPN_MODEL[] = "models/w_m4a1.mdl";

new const WPN_ENTITY[] = "weapon_m4a1"
const WPN_CSW = CSW_M4A1;
const WPN_TYPE = WPN_PRIMARY;
const WPN_KEY = 1997;


new const TracePreEntities[][] = { "func_breakable", "func_wall", "func_door", "func_door_rotating", "func_plat", "func_rotating", "player", "worldspawn" }
new g_iItemID, m_GoldSpr, cvar_dmg_Gold, cvar_dmg_multi, cvar_limit, g_buy_limit, bool:g_haveGoldWeapon[33], g_iDmg[33];


public plugin_init() {
	
	register_plugin("[ZP] Extra Item: Gold M4A1", "1.1", "Teixeira")
	
	
	cvar_dmg_multi = register_cvar("zp_multiplier_m4a1Gold_damage", "1.5") 
	cvar_limit = register_cvar("zp_gold_buy_limit", "3")		

	register_forward(FM_SetModel, "fw_SetModel")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_Item_AddToPlayer, WPN_ENTITY, "fw_WpnAddToPlayer")
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")

	for(new i = 0; i < sizeof TracePreEntities; i++)
		RegisterHam(Ham_TraceAttack, TracePreEntities[i], "fw_TraceAttackPre");
	
	g_iItemID = zp_register_extra_item(ITEM_NAME, ITEM_COST, ZP_TEAM_HUMAN) 
}


public plugin_precache() {
	// Models
	precache_model(V_GOLD_MODEL)
	precache_model(P_GOLD_MODEL)
	
	// Sprites
	m_GoldSpr = precache_model("sprites/dot.spr");
}

public client_disconnected(id) reset_vars(id);
public zp_user_infected_post(id) reset_vars(id);
public zp_user_humanized_post(id) reset_vars(id);
public zp_player_spawn_post(id) reset_vars(id);
public reset_vars(id) {
	g_haveGoldWeapon[id] = false
	g_iDmg[id] = 0
}


public event_round_start() 
{
	g_buy_limit = 0
}

public zp_extra_item_selected_pre(player, itemid) {
	if (itemid != g_iItemID) 
		return PLUGIN_CONTINUE
	
	zp_extra_item_textadd(fmt("\r[%d/%d]", g_buy_limit, get_pcvar_num(cvar_limit)))

	if(g_haveGoldWeapon[player] || g_buy_limit >= get_pcvar_num(cvar_limit))
		return ZP_PLUGIN_HANDLED

	return PLUGIN_CONTINUE;	
}

public zp_extra_item_selected(player, itemid) {
	if(itemid != g_iItemID) 
		return PLUGIN_CONTINUE;

	if(g_haveGoldWeapon[player])
		return ZP_PLUGIN_HANDLED;

	zp_drop_weapons(player, WPN_TYPE);
	g_haveGoldWeapon[player] = true
	zp_give_item(player, WPN_ENTITY, 1)
	client_print_color(player, print_team_grey, "^4[ZP]^1 Voce comprou ^1%s^4 !!!", ITEM_NAME)
	g_buy_limit++

	return PLUGIN_CONTINUE;
}


public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type) {
	if(!is_user_alive(victim) || !is_user_alive(attacker))
		return HAM_IGNORED

	if(!g_haveGoldWeapon[attacker])
		return HAM_IGNORED;

	if(!zp_get_user_zombie(victim) || get_user_weapon(attacker) != WPN_CSW)
		return HAM_IGNORED

	static CvarDmgGold; CvarDmgGold = get_pcvar_num(cvar_dmg_Gold);

	damage *= get_pcvar_float(cvar_dmg_multi)
	SetHamParamFloat(4, damage);

	if(zp_get_zombie_special_class(victim))
		return HAM_IGNORED;

	g_iDmg[attacker] += floatround(damage);
	if(g_iDmg[attacker] >= CvarDmgGold) {
		g_iDmg[attacker] = 0
	}

	
	return HAM_IGNORED
}

public fw_TraceAttackPre(iVictim, iAttacker, Float:fDamage, Float:fDeriction[3], iTraceHandle, iBitDamage) {
	if(!is_user_alive(iAttacker))
		return;

	if(get_user_weapon(iAttacker) != WPN_CSW || !g_haveGoldWeapon[iAttacker]) 
		return;

	free_tr2(iTraceHandle);

	static Float:end[3]
	get_tr2(iTraceHandle, TR_vecEndPos, end)

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMENTPOINT)
	write_short(iAttacker | 0x1000)
	engfunc(EngFunc_WriteCoord, end[0])
	engfunc(EngFunc_WriteCoord, end[1])
	engfunc(EngFunc_WriteCoord, end[2])
	write_short(m_GoldSpr)
	write_byte(1) // framerate
	write_byte(5) // framerate
	write_byte(1) // life
	write_byte(20)  // width
	write_byte(0)// noise
	write_byte(255)// r, g, b
	write_byte(215)// r, g, b
	write_byte(0)// r, g, b
	write_byte(220)	// brightness
	write_byte(150)	// speed
	message_end()
}

public zp_fw_deploy_weapon(id, wpn_id) {
	if(!is_user_alive(id) || wpn_id != WPN_CSW)
		return;

	if(g_haveGoldWeapon[id]) {
		set_pev(id, pev_viewmodel2, V_GOLD_MODEL)
		set_pev(id, pev_weaponmodel2, P_GOLD_MODEL)
	}
}


public fw_SetModel(entity, model[]) {
	if(!pev_valid(entity)) 
		return FMRES_IGNORED

	if(!equali(model, W_GOLD_WPN_MODEL)) 
		return FMRES_IGNORED

	static className[32], iOwner, iStoredWeapon;
	pev(entity, pev_classname, className, charsmax(className))

	iOwner = pev(entity, pev_owner) 
	iStoredWeapon = fm_find_ent_by_owner(-1, WPN_ENTITY, entity) 

	if(g_haveGoldWeapon[iOwner] && pev_valid(iStoredWeapon)) {
		set_pev(iStoredWeapon, pev_impulse, WPN_KEY) 
		g_haveGoldWeapon[iOwner] = false 
		engfunc(EngFunc_SetModel, entity, W_GOLD_WPN_MODEL) 
		return FMRES_SUPERCEDE
	}
	return FMRES_IGNORED
}


public fw_WpnAddToPlayer(wpn_ent, id) {

	if(pev_valid(wpn_ent) && is_user_connected(id) && pev(wpn_ent, pev_impulse) == WPN_KEY) {
		g_haveGoldWeapon[id] = true 
		set_pev(wpn_ent, pev_impulse, 0) 
		return HAM_HANDLED;
	}
	return HAM_IGNORED
}

// From fakemeta_util
stock fm_find_ent_by_owner(index, const classname[], owner, jghgtype = 0) {
	new strtype[11] = "classname", ent = index;
	switch (jghgtype) {
		case 1: strtype = "target";
		case 2: strtype = "targetname";
	}

	while ((ent = engfunc(EngFunc_FindEntityByString, ent, strtype, classname)) && pev(ent, pev_owner) != owner) {}

	return ent;
}
