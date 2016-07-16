#define DEBUG

#define PLUGIN_AUTHOR "Yeradon"
#define PLUGIN_VERSION "0.2"

#define SHORT_NAME_T "awp_t"
#define SHORT_NAME_D "awp_d"
#define SHORT_NAME_I "awp_i"

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>
#include <multicolors>

#include <ttt_shop>
#include <ttt>
#include <logdebug>
#include <autoexecconfig>



/*** ConVars ***/
ConVar g_cPriceT = null;
ConVar g_cPriceD = null;
ConVar g_cPriceI = null;
ConVar g_cPriorityT = null;
ConVar g_cPriorityD = null;
ConVar g_cPriorityI = null;
ConVar g_cMaxShotsT = null;
ConVar g_cMaxShotsD = null;
ConVar g_cMaxShotsI = null;
ConVar g_cMinShotsT = null;
ConVar g_cMinShotsD = null;
ConVar g_cMinShotsI = null;
ConVar g_cAmountT = null;
ConVar g_cAmountD = null;
ConVar g_cAmountI = null;
ConVar g_cSkinSupport = null;

ArrayList g_alWeapons = null;

int g_iPAmount[MAXPLAYERS + 1] =  { 0, ... };

public Plugin myinfo = 
{
	name = "TTT silenced AWP",
	author = PLUGIN_AUTHOR,
	description = "A silenced awp for ttt",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	InitDebugLog("sm_ttt_awps_debug", "TTT: S AWP");
	
	LoadTranslations("ttt_awps.phrases");
	
	AutoExecConfig_SetFile("plugin.ttt_awp_silent");
	AutoExecConfig_SetCreateFile(true);
	
	g_cPriceT = AutoExecConfig_CreateConVar("sm_ttt_awps_price_t", "10000", "Price for the silenced AWP for Traitors", _, true, 0.0);
	g_cPriceD = AutoExecConfig_CreateConVar("sm_ttt_awps_price_d", "0", "Price for the silenced AWP for Detectives", _, true, 0.0);
	g_cPriceI = AutoExecConfig_CreateConVar("sm_ttt_awps_price_i", "0", "Price for the silenced AWP for Innos", _, true, 0.0);
	g_cPriorityT = AutoExecConfig_CreateConVar("sm_ttt_awps_priority_t", "0", "Priority in shop list for Traitors", _, true, 0.0);
	g_cPriorityD = AutoExecConfig_CreateConVar("sm_ttt_awps_priority_d", "0", "Priority in shop list for Detectives", _, true, 0.0);
	g_cPriorityI = AutoExecConfig_CreateConVar("sm_ttt_awps_priority_i", "0", "Priority in shop list for Innos", _, true, 0.0);
	g_cMaxShotsT = AutoExecConfig_CreateConVar("sm_ttt_awps_max_t", "2", "Maximum shots for the AWP for Traitors", _, true, 0.0);
	g_cMaxShotsD = AutoExecConfig_CreateConVar("sm_ttt_awps_max_d", "2", "Maximum shots for the AWP for Detectives", _, true, 0.0);
	g_cMaxShotsI = AutoExecConfig_CreateConVar("sm_ttt_awps_max_i", "2", "Maximum shots for the AWP for Innos", _, true, 0.0);
	g_cMinShotsT = AutoExecConfig_CreateConVar("sm_ttt_awp_min_t", "1", "Minimum shots for the AWP for Traitors", _, true, 0.0);
	g_cMinShotsD = AutoExecConfig_CreateConVar("sm_ttt_awp_min_d", "1", "Minimum shots for the AWP for Detectives", _, true, 0.0);
	g_cMinShotsI = AutoExecConfig_CreateConVar("sm_ttt_awp_min_i", "1", "Minimum shots for the AWP for Innos", _, true, 0.0);
	g_cAmountT = AutoExecConfig_CreateConVar("sm_ttt_awps_amount_t", "2", "How many AWPs can traitors buy?", _, true, 0.0);
	g_cAmountD = AutoExecConfig_CreateConVar("sm_ttt_awps_amount_d", "0", "How many AWPs can detectives buy?", _, true, 0.0);
	g_cAmountI = AutoExecConfig_CreateConVar("sm_ttt_awps_amount_i", "0", "How many AWPs can innocents buy?", _, true, 0.0);
	g_cSkinSupport = AutoExecConfig_CreateConVar("sm_ttt_awps_skin_support", "1", "Shall the plugin use weapon skins?", _, true, 0.0, true, 1.0);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	g_alWeapons = CreateArray();
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	
	// Bullets
	AddTempEntHook("Shotgun Shot", Hook_ShotgunShot);
	
}


public void OnAllPluginsLoaded()
{
	char longName[32];
	Format(longName, sizeof(longName), "%T", "Name", LANG_SERVER);
	
	TTT_RegisterCustomItem(SHORT_NAME_T, longName, g_cPriceT.IntValue, TTT_TEAM_TRAITOR, g_cPriorityT.IntValue);
	TTT_RegisterCustomItem(SHORT_NAME_I, longName, g_cPriceD.IntValue, TTT_TEAM_DETECTIVE, g_cPriorityD.IntValue);
	TTT_RegisterCustomItem(SHORT_NAME_D, longName, g_cPriceI.IntValue, TTT_TEAM_INNOCENT, g_cPriorityI.IntValue);

}

public Action TTT_OnItemPurchased(int client, const char[] itemshort)
{
	if(TTT_IsClientValid(client) && IsPlayerAlive(client))
	{
		if((StrEqual(itemshort, SHORT_NAME_T, false) && g_iPAmount[client] < g_cAmountT.IntValue) || 
		(StrEqual(itemshort, SHORT_NAME_D, false) && g_iPAmount[client] < g_cAmountD.IntValue) || 
		(StrEqual(itemshort, SHORT_NAME_I, false) && g_iPAmount[client] < g_cAmountI.IntValue))
		{
			// Smn bought silenced AWP
			if (GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) != -1){
				SDKHooks_DropWeapon(client, GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY));
			}
			int iWeapon = GivePlayerItem(client, "weapon_awp");
			if(iWeapon == -1)
				return Plugin_Stop;
			if(g_cSkinSupport.BoolValue)
				EquipPlayerWeapon(client, iWeapon);
			
			g_alWeapons.Push(iWeapon);
			
			LogDebug("Smn bought silenced awp with id: %i", iWeapon);
			
			SetEntProp(iWeapon, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
			
			int max = 0;
			int min = 0;
			switch (TTT_GetClientRole(client)){
				case TTT_TEAM_TRAITOR:
				{
					max = g_cMaxShotsT.IntValue;
					min = g_cMinShotsT.IntValue;
				}
				case TTT_TEAM_DETECTIVE:
				{
					max = g_cMaxShotsD.IntValue;
					min = g_cMinShotsD.IntValue;
				}
				case TTT_TEAM_INNOCENT:
				{
					max = g_cMaxShotsI.IntValue;
					min = g_cMinShotsI.IntValue;
				}
			}
			SetEntProp(iWeapon, Prop_Send, "m_iClip1", GetRandomInt(min, max));
		}
		else
		{
			int amount = 0;
			switch (TTT_GetClientRole(client)){
				case TTT_TEAM_TRAITOR:
				{
					amount = g_cAmountT.IntValue;
				}
				case TTT_TEAM_DETECTIVE:
				{
					amount = g_cAmountD.IntValue;
				}
				case TTT_TEAM_INNOCENT:
				{
					amount = g_cAmountI.IntValue;
				}
			}
			PrintToChat(client, "%t %t", "tag", "error_buy_limit", amount);
		}
	}
	return Plugin_Continue;
}

public Action Hook_ShotgunShot(const char[] sample, const int[] Players, int numClients, float delay)
{
	int client = TE_ReadNum("m_iPlayer") + 1;
	
	//well while this checks aren't necessary they give good_live a good feeling...
	if(!TTT_IsClientValid(client))
		return Plugin_Continue;
	char sWeapon[32];
	GetClientWeapon(client, sWeapon, sizeof(sWeapon));
	if(!StrEqual(sWeapon, "weapon_awp", false))
		return Plugin_Continue;
	
	int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
	LogDebug("Weapon %i shot by %N", weapon, client);
	if(IsSilenced(weapon)){
		LogDebug("It's a silent shot!");
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

bool IsSilenced(int weapon){
	if(g_alWeapons.FindValue(weapon) != -1){
		return true;
	}
	return false;
}

public void TTT_OnRoundStart(int innos, int traitors, int detectives)
{
	g_alWeapons.Clear();
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (TTT_IsClientValid(client))
		g_iPAmount[client] = 0;
}

public Action Event_PlayerDeath(Event event, const char[] menu, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (TTT_IsClientValid(client))
		g_iPAmount[client] = 0;
}