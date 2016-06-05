#define DEBUG

#define PLUGIN_AUTHOR "Yeradon"
#define PLUGIN_VERSION "0.1"

#define SHORT_NAME "s_awp"

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
ConVar g_cBuyAbleT = null;
ConVar g_cBuyAbleD = null;
ConVar g_cBuyAbleI = null;

ArrayList g_alWeapons = null;

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
	g_cPriceD = AutoExecConfig_CreateConVar("sm_ttt_awps_price_d", "10000", "Price for the silenced AWP for Detectives", _, true, 0.0);
	g_cPriceI = AutoExecConfig_CreateConVar("sm_ttt_awps_price_i", "10000", "Price for the silenced AWP for Innos", _, true, 0.0);
	g_cPriorityT = AutoExecConfig_CreateConVar("sm_ttt_awps_priority_t", "0", "Priority in shop list for Traitors", _, true, 0.0);
	g_cPriorityD = AutoExecConfig_CreateConVar("sm_ttt_awps_priority_d", "0", "Priority in shop list for Detectives", _, true, 0.0);
	g_cPriorityI = AutoExecConfig_CreateConVar("sm_ttt_awps_priority_i", "0", "Priority in shop list for Innos", _, true, 0.0);
	g_cMaxShotsT = AutoExecConfig_CreateConVar("sm_ttt_awps_max_t", "2", "Maximum shots for the AWP for Traitors", _, true, 0.0);
	g_cMaxShotsD = AutoExecConfig_CreateConVar("sm_ttt_awps_max_d", "2", "Maximum shots for the AWP for Detectives", _, true, 0.0);
	g_cMaxShotsI = AutoExecConfig_CreateConVar("sm_ttt_awps_max_i", "2", "Maximum shots for the AWP for Innos", _, true, 0.0);
	g_cMinShotsT = AutoExecConfig_CreateConVar("sm_ttt_awp_min_t", "1", "Minimum shots for the AWP for Traitors", _, true, 0.0);
	g_cMinShotsD = AutoExecConfig_CreateConVar("sm_ttt_awp_min_d", "1", "Minimum shots for the AWP for Detectives", _, true, 0.0);
	g_cMinShotsI = AutoExecConfig_CreateConVar("sm_ttt_awp_min_i", "1", "Minimum shots for the AWP for Innos", _, true, 0.0);
	g_cBuyAbleT = AutoExecConfig_CreateConVar("sm_ttt_awps_min_t", "1", "Buyable for Traitors? (1 = Yes / 0 = No)", _, true, 0.0, true, 1.0);
	g_cBuyAbleD = AutoExecConfig_CreateConVar("sm_ttt_awps_min_d", "1", "Buyable for Detectives? (1 = Yes / 0 = No)", _, true, 0.0, true, 1.0);
	g_cBuyAbleI = AutoExecConfig_CreateConVar("sm_ttt_awps_min_I", "0", "Buyable for Innos? (1 = Yes / 0 = No)", _, true, 0.0, true, 1.0);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	g_alWeapons = CreateArray();
	
	// Bullets
	AddTempEntHook("Shotgun Shot", Hook_ShotgunShot);
	
}


public void OnAllPluginsLoaded()
{
	char longName[32];
	Format(longName, sizeof(longName), "%T", "Name", LANG_SERVER);
	
	if(g_cBuyAbleT.BoolValue){
		TTT_RegisterCustomItem(SHORT_NAME, longName, g_cPriceT.IntValue, TTT_TEAM_TRAITOR, g_cPriorityT.IntValue);
	}
	if(g_cBuyAbleD.BoolValue){
		TTT_RegisterCustomItem(SHORT_NAME, longName, g_cPriceD.IntValue, TTT_TEAM_DETECTIVE, g_cPriorityD.IntValue);
	}
	if(g_cBuyAbleI.BoolValue){
		TTT_RegisterCustomItem(SHORT_NAME, longName, g_cPriceI.IntValue, TTT_TEAM_INNOCENT, g_cPriorityI.IntValue);
	}
}

public Action TTT_OnItemPurchased(int client, const char[] itemshort)
{
	if(TTT_IsClientValid(client) && IsPlayerAlive(client))
	{
		if(StrEqual(itemshort, SHORT_NAME, false))
		{
			// Smn bought silenced AWP
			if (GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) != -1){
				SDKHooks_DropWeapon(client, GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY));
			}
			GivePlayerItem(client, "weapon_awp");
			
			int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
			
			if(GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY) != -1){
				g_alWeapons.Push(weapon);
			}
			
			LogDebug("Smn bought silenced awp :O with id: %i", GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY));
			
			SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
			
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
			SetEntProp(weapon, Prop_Send, "m_iClip1", GetRandomInt(min, max));
		}
		
	}
	return Plugin_Continue;
}

public Action:Hook_ShotgunShot(const String:sample[], const Players[], numClients, Float:delay)
{
	int client = TE_ReadNum("m_iPlayer") + 1;
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