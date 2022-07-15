#pragma semicolon 1
#include <sourcemod>
#include <anyhttp>

public Plugin:myinfo =
{
	name = "demos.tf uploader",
	author = "Icewind, update by proph",
	description = "Auto-upload match stv to demos.tf",
	version = "0.3",
	url = "https://demos.tf"
};

/**
 * Converts a string to lowercase
 *
 * @param buffer		String to convert
 * @noreturn
 */
public CStrToLower(String:buffer[]) {
	new len = strlen(buffer);
	for(new i = 0; i < len; i++) {
		buffer[i] = CharToLower(buffer[i]);
	}
}

new String:g_sDemoName[256] = "";
new String:g_sLastDemoName[256] = "";

new Handle:g_hCvarAPIKey = INVALID_HANDLE;
new Handle:g_hCvarUrl = INVALID_HANDLE;
new Handle:g_hCvarRedTeamName = INVALID_HANDLE;
new Handle:g_hCvarBlueTeamName = INVALID_HANDLE;

public OnPluginStart()
{
	g_hCvarAPIKey = CreateConVar("sm_demostf_apikey", "", "API key for demos.tf", FCVAR_PROTECTED);
	g_hCvarUrl = CreateConVar("sm_demostf_url", "https://demos.tf", "demos.tf url", FCVAR_PROTECTED);
	g_hCvarRedTeamName = FindConVar("mp_tournament_redteamname");
	g_hCvarBlueTeamName = FindConVar("mp_tournament_blueteamname");

	AnyHttp.Require();
	
	RegServerCmd("tv_record", Command_StartRecord);
	RegServerCmd("tv_stoprecord", Command_StopRecord);
}

public Action:Command_StartRecord(args)
{
	if (strlen(g_sDemoName) == 0) {
		GetCmdArgString(g_sDemoName, sizeof(g_sDemoName));
		StripQuotes(g_sDemoName);
		CStrToLower(g_sDemoName);
	}
	return Plugin_Continue;
}

public Action:Command_StopRecord(args)
{
	TrimString(g_sDemoName);
	if (strlen(g_sDemoName) != 0) {
		PrintToChatAll("[demos.tf]: Demo recording completed");
		g_sLastDemoName = g_sDemoName;
		g_sDemoName = "";
		CreateTimer(3.0, StartDemoUpload);
	}
	return Plugin_Continue;
}

public Action:StartDemoUpload(Handle:timer)
{
	decl String:fullPath[128];
	Format(fullPath, sizeof(fullPath), "%s.dem", g_sLastDemoName);
	UploadDemo(fullPath);
}

UploadDemo(const String:fullPath[])
{
	decl String:APIKey[128];
	GetConVarString(g_hCvarAPIKey, APIKey, sizeof(APIKey));
	decl String:BaseUrl[64];
	GetConVarString(g_hCvarUrl, BaseUrl, sizeof(BaseUrl));
	new String:Map[64];
	GetCurrentMap(Map, sizeof(Map));
	PrintToChatAll("[demos.tf]: Uploading demo %s", fullPath);
	decl String:bluname[128];
	decl String:redname[128];
	GetConVarString(g_hCvarRedTeamName, redname, sizeof(redname));
	GetConVarString(g_hCvarBlueTeamName, bluname, sizeof(bluname));
	
	decl String:fullUrl[128];
	Format(fullUrl, sizeof(fullUrl), "%s/upload", BaseUrl);
	
	AnyHttpRequest req = AnyHttp.CreatePost(fullUrl);
	
	req.PutFile("demo", fullPath);
	req.PutString("name", fullPath);
	req.PutString("red", redname);
	req.PutString("blu", bluname);
	req.PutString("key", APIKey);

	AnyHttp.Send(req, UploadLog_Complete);
	
}

public void UploadLog_Complete(bool success, const char[] contents, int responseCode)
{
	if (success)
	{
		PrintToChatAll("[demos.tf]: %s", contents);
		LogToGame("[demos.tf]: %s", contents);
	}
	else 
	{
		PrintToChatAll("cURLCode error: %d", responseCode);
	}
}
