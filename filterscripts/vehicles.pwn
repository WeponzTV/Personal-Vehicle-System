/*
	Personal Vehicle System by Weponz (SA-MP) - 2021
*/
#define FILTERSCRIPT
#include <a_samp>
#include <streamer>
#include <zcmd>
native IsValidVehicle(vehicleid);

#define RED 0xFF0000FF
#define WHITE 0xFFFFFFFF
#define GRAY 0x808080FF

#define VEHICLE_DATABASE "vehicles.db"

#define OFF 0
#define ON 1

#define NO 0
#define YES 1

#define LS_SHOP_X 2131.3433
#define LS_SHOP_Y -1132.6162
#define LS_SHOP_Z 25.6622

#define SF_SHOP_X -1983.1237
#define SF_SHOP_Y 268.1202
#define SF_SHOP_Z 35.1719

#define LV_SHOP_X 1735.7432
#define LV_SHOP_Y 1866.1516
#define LV_SHOP_Z 10.8203

#define LS_MENU_DIALOG 1101
#define LS_LIST_DIALOG 1102

#define SF_MENU_DIALOG 1103
#define SF_LIST_DIALOG 1104

#define LV_MENU_DIALOG 1105
#define LV_LIST_DIALOG 1106

new DB:vehicle_database;
new DBResult:database_result;

new LosSantosMotors;
new SanFierroMotors;
new LasVenturasMotors;

new bool:HasSetCheckpoint[MAX_PLAYERS];

forward SetVehicleParamsForAll(carid, objective, doorslocked);

enum vehicle_data
{
	vehicle_owner[MAX_PLAYER_NAME],
	vehicle_model,
	vehicle_colour1,
	vehicle_colour2,
	vehicle_price,
	Float:vehicle_x,
	Float:vehicle_y,
	Float:vehicle_z,
	Float:vehicle_a,
	Float:vehicle_health,
	vehicle_plate[24],
	vehicle_paintjob,
	vehicle_locked,
	bool:vehicle_owned
}
new VehicleInfo[MAX_VEHICLES][vehicle_data];

stock DB_Escape(text[])//Credits: Y_Less
{
    new ret[80 * 2], ch, i, j;
    while ((ch = text[i++]) && j < sizeof (ret))
    {
        if (ch == '\'')
        {
            if (j < sizeof (ret) - 2)
            {
                ret[j++] = '\'';
                ret[j++] = '\'';
            }
        }
        else if (j < sizeof (ret))
        {
            ret[j++] = ch;
        }
        else
        {
            j++;
        }
    }
    ret[sizeof (ret) - 1] = '\0';
    return ret;
}

stock GetName(playerid)
{
	new name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, (name), sizeof(name));
    return name;
}

stock GetOwnedVehicle(playerid)
{
    for(new v = 0; v < MAX_VEHICLES; v++)
	{
		if(IsValidVehicle(v) && VehicleInfo[v][vehicle_owned] == true)
		{
			if(!strcmp(GetName(playerid), VehicleInfo[v][vehicle_owner], false))
			{
			    return v;
			}
		}
	}
	return INVALID_VEHICLE_ID;
}

public OnFilterScriptInit()
{
    vehicle_database = db_open(VEHICLE_DATABASE);

    db_query(vehicle_database, "CREATE TABLE IF NOT EXISTS `VEHICLES` (`OWNER`, `MODEL`, `COLOUR1`, `COLOUR2`, `PRICE`, `X`, `Y`, `Z`, `A`, `HEALTH`, `PLATE`, `PAINTJOB`, `LOCKED`)");

    CreateDynamicMapIcon(LS_SHOP_X, LS_SHOP_Y, LS_SHOP_Z, 55, -1, -1, -1, -1, 250.0);
    CreateDynamicMapIcon(SF_SHOP_X, SF_SHOP_Y, SF_SHOP_Z, 55, -1, -1, -1, -1, 250.0);
    CreateDynamicMapIcon(LV_SHOP_X, LV_SHOP_Y, LV_SHOP_Z, 55, -1, -1, -1, -1, 250.0);

    LosSantosMotors = CreateDynamicCP(LS_SHOP_X, LS_SHOP_Y, LS_SHOP_Z, 3.0, -1, -1, -1, 10.0, -1, 0);
    SanFierroMotors = CreateDynamicCP(SF_SHOP_X, SF_SHOP_Y, SF_SHOP_Z, 3.0, -1, -1, -1, 10.0, -1, 0);
    LasVenturasMotors = CreateDynamicCP(LV_SHOP_X, LV_SHOP_Y, LV_SHOP_Z, 3.0, -1, -1, -1, 10.0, -1, 0);

    CreateDynamic3DTextLabel("Los Santos Motors", WHITE, LS_SHOP_X, LS_SHOP_Y, LS_SHOP_Z, 10.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 1, -1, -1, -1, 50.0);
    CreateDynamic3DTextLabel("San Fierro Motors", WHITE, SF_SHOP_X, SF_SHOP_Y, SF_SHOP_Z, 10.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 1, -1, -1, -1, 50.0);
    CreateDynamic3DTextLabel("Las Venturas Motors", WHITE, LV_SHOP_X, LV_SHOP_Y, LV_SHOP_Z, 10.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 1, -1, -1, -1, 50.0);

	for(new v = 0; v < MAX_VEHICLES; v++)
	{
	    VehicleInfo[v][vehicle_owned] = false;
	}
	return 1;
}

public OnFilterScriptExit()
{
    db_close(vehicle_database);
	return 1;
}

public OnPlayerConnect(playerid)
{
	new query[128], owner[MAX_PLAYER_NAME], model[24], colour1[24], colour2[24], price[24], x[24], y[24], z[24], a[24], health[24], plate[24], paintjob[24], locked[24];
    format(query, sizeof(query), "SELECT * FROM `VEHICLES` WHERE `OWNER` = '%s' COLLATE NOCASE", DB_Escape(GetName(playerid)));
  	database_result = db_query(vehicle_database, query);
  	if(db_num_rows(database_result))
	{
	    db_get_field_assoc(database_result, "OWNER", owner, sizeof(owner));
	    db_get_field_assoc(database_result, "MODEL", model, sizeof(model));
	    db_get_field_assoc(database_result, "COLOUR1", colour1, sizeof(colour1));
	    db_get_field_assoc(database_result, "COLOUR2", colour2, sizeof(colour2));
	    db_get_field_assoc(database_result, "PRICE", price, sizeof(price));
	    db_get_field_assoc(database_result, "X", x, sizeof(x));
	    db_get_field_assoc(database_result, "Y", y, sizeof(y));
	    db_get_field_assoc(database_result, "Z", z, sizeof(z));
	    db_get_field_assoc(database_result, "A", a, sizeof(a));
	    db_get_field_assoc(database_result, "HEALTH", health, sizeof(health));
	    db_get_field_assoc(database_result, "PLATE", plate, sizeof(plate));
	    db_get_field_assoc(database_result, "PAINTJOB", paintjob, sizeof(paintjob));
	    db_get_field_assoc(database_result, "LOCKED", locked, sizeof(locked));

        new vehicleid = CreateVehicle(strval(model), floatstr(x), floatstr(y), floatstr(z), floatstr(a), strval(colour1), strval(colour2), -1);
		SetVehicleNumberPlate(vehicleid, plate);
		SetVehicleToRespawn(vehicleid);
		SetVehicleHealth(vehicleid, floatstr(health));

		VehicleInfo[vehicleid][vehicle_owner] = owner;
		VehicleInfo[vehicleid][vehicle_model] = strval(model);
		VehicleInfo[vehicleid][vehicle_x] = floatstr(x);
		VehicleInfo[vehicleid][vehicle_y] = floatstr(y);
		VehicleInfo[vehicleid][vehicle_z] = floatstr(z);
		VehicleInfo[vehicleid][vehicle_a] = floatstr(a);
		VehicleInfo[vehicleid][vehicle_health] = floatstr(health);
		VehicleInfo[vehicleid][vehicle_colour1] = strval(colour1);
		VehicleInfo[vehicleid][vehicle_colour2] = strval(colour2);
		VehicleInfo[vehicleid][vehicle_paintjob] = strval(paintjob);
		VehicleInfo[vehicleid][vehicle_plate] = plate;
		VehicleInfo[vehicleid][vehicle_price] = strval(price);
		VehicleInfo[vehicleid][vehicle_locked] = strval(locked);
		VehicleInfo[vehicleid][vehicle_owned] = true;

		if(VehicleInfo[vehicleid][vehicle_paintjob] != 0)
		{
			ChangeVehiclePaintjob(vehicleid, VehicleInfo[vehicleid][vehicle_paintjob]);
		}
	}
	HasSetCheckpoint[playerid] = false;
	
  	db_free_result(database_result);
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    new vehicleid = GetOwnedVehicle(playerid);
    if(vehicleid != INVALID_VEHICLE_ID)
	{
	    new query[400], Float:health;
	    GetVehicleHealth(vehicleid, health);
		format(query, sizeof(query), "UPDATE `VEHICLES` SET `COLOUR1` = '%d', `COLOUR2` = '%d', `X` = '%f', `Y` = '%f', `Z` = '%f', `A` = '%f', `HEALTH` = '%f', `PLATE` = '%s', `PAINTJOB` = '%d', `LOCKED` = '%d' WHERE `OWNER` = '%s' COLLATE NOCASE",
		VehicleInfo[vehicleid][vehicle_colour1], VehicleInfo[vehicleid][vehicle_colour2], VehicleInfo[vehicleid][vehicle_x], VehicleInfo[vehicleid][vehicle_y], VehicleInfo[vehicleid][vehicle_z], VehicleInfo[vehicleid][vehicle_a], health, VehicleInfo[vehicleid][vehicle_plate], VehicleInfo[vehicleid][vehicle_paintjob], VehicleInfo[vehicleid][vehicle_locked], DB_Escape(GetName(playerid)));
		database_result = db_query(vehicle_database, query);
		db_free_result(database_result);

		DestroyVehicle(vehicleid);

		VehicleInfo[vehicleid][vehicle_owned] = false;
	}
	return 1;
}

public OnVehicleRespray(playerid, vehicleid, color1, color2)
{
 	if(VehicleInfo[vehicleid][vehicle_owned] == true && !strcmp(GetName(playerid), VehicleInfo[vehicleid][vehicle_owner], false))
	{
		VehicleInfo[vehicleid][vehicle_colour1] = color1;
		VehicleInfo[vehicleid][vehicle_colour2] = color2;
	}
	return 1;
}

public OnVehiclePaintjob(playerid, vehicleid, paintjobid)
{
 	if(VehicleInfo[vehicleid][vehicle_owned] == true && !strcmp(GetName(playerid), VehicleInfo[vehicleid][vehicle_owner], false))
	{
	    VehicleInfo[vehicleid][vehicle_paintjob] = paintjobid;
	}
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	if(dialogid == LS_LIST_DIALOG || dialogid == SF_LIST_DIALOG || dialogid == LV_LIST_DIALOG)
	{
	    if(response)
	    {
	        new model = -1, price = 0;
	        if(listitem == 0)//Buffalo
	        {
	            model = 402;
	            price = 25000;
	        }
	        else if(listitem == 1)//Infernus
	        {
	            model = 411;
	            price = 120000;
	        }
	        else if(listitem == 2)//Cheetah
	        {
	            model = 415;
	            price = 100000;
	        }
	        else if(listitem == 3)//Banshee
	        {
	            model = 429;
	            price = 90000;
	        }
	        else if(listitem == 4)//Turismo
	        {
	            model = 451;
	            price = 120000;
	        }
	        else if(listitem == 5)//PCJ-600
	        {
	            model = 461;
	            price = 35000;
	        }
	        else if(listitem == 6)//Sanchez
	        {
	            model = 468;
	            price = 25000;
	        }
	        else if(listitem == 7)//NRG-500
	        {
	            model = 522;
	            price = 50000;
	        }
	        else if(listitem == 8)//Maverick
	        {
	            model = 487;
	            price = 250000;
	        }

	        if(GetOwnedVehicle(playerid) != INVALID_PLAYER_ID) return SendClientMessage(playerid, RED, "SERVER: You already own a vehicle, trade yours in first to buy another one.");
	        if(GetPlayerMoney(playerid) < price)
			{
			    new string[128];
			    format(string, sizeof(string), "SERVER: You cannot afford that vehicle, it costs $%d.", price);
				return SendClientMessage(playerid, RED, string);
			}

			GivePlayerMoney(playerid, -price);

			new Float:pos[4];
			GetPlayerPos(playerid, pos[0], pos[1], pos[2]);
			GetPlayerFacingAngle(playerid, pos[3]);

			new vehicleid = CreateVehicle(model, pos[0], pos[1], pos[2], pos[3], random(255), random(255), -1);
			SetVehicleNumberPlate(vehicleid, GetName(playerid));
			SetVehicleToRespawn(vehicleid);
			SetVehicleHealth(vehicleid, 1000.0);

			PutPlayerInVehicle(playerid, vehicleid, 0);

			VehicleInfo[vehicleid][vehicle_owner] = GetName(playerid);
			VehicleInfo[vehicleid][vehicle_model] = model;
			VehicleInfo[vehicleid][vehicle_x] = pos[0];
			VehicleInfo[vehicleid][vehicle_y] = pos[1];
			VehicleInfo[vehicleid][vehicle_z] = pos[2];
			VehicleInfo[vehicleid][vehicle_a] = pos[3];
			VehicleInfo[vehicleid][vehicle_health] = 1000.00;
			VehicleInfo[vehicleid][vehicle_colour1] = random(255);
			VehicleInfo[vehicleid][vehicle_colour2] = random(255);
			VehicleInfo[vehicleid][vehicle_paintjob] = 3;
			VehicleInfo[vehicleid][vehicle_plate] = GetName(playerid);
			VehicleInfo[vehicleid][vehicle_price] = price;
			VehicleInfo[vehicleid][vehicle_locked] = NO;
			VehicleInfo[vehicleid][vehicle_owned] = true;

			new query[400];
			format(query, sizeof(query), "INSERT INTO `VEHICLES` (`OWNER`, `MODEL`, `COLOUR1`, `COLOUR2`, `PRICE`, `X`, `Y`, `Z`, `A`, `HEALTH`, `PLATE`, `PAINTJOB`, `LOCKED`) VALUES ('%s', '%d', '%d', '%d', '%d', '%f', '%f', '%f', '%f', '%f', '%s', '%d', '%d')",
			DB_Escape(GetName(playerid)), VehicleInfo[vehicleid][vehicle_model], VehicleInfo[vehicleid][vehicle_colour1], VehicleInfo[vehicleid][vehicle_colour2], VehicleInfo[vehicleid][vehicle_price], VehicleInfo[vehicleid][vehicle_x], VehicleInfo[vehicleid][vehicle_y], VehicleInfo[vehicleid][vehicle_z], VehicleInfo[vehicleid][vehicle_a], VehicleInfo[vehicleid][vehicle_health], VehicleInfo[vehicleid][vehicle_plate], VehicleInfo[vehicleid][vehicle_paintjob], VehicleInfo[vehicleid][vehicle_locked]);
			database_result = db_query(vehicle_database, query);
			db_free_result(database_result);

			new string[128];
			format(string, sizeof(string), "SERVER: You have successfully purchased the vehicle for: $%d", price);
			SendClientMessage(playerid, WHITE, string);
		}
		return 1;
	}
	else if(dialogid == LS_MENU_DIALOG)
	{
	    if(response)
	    {
	        if(listitem == 0)
	        {
	            return ShowPlayerDialog(playerid, LS_LIST_DIALOG, DIALOG_STYLE_LIST, "{FFFFFF}Los Santos Motors",
				"{FFFFFF}Buffalo - $25K\nInfernus - $120K\nCheetah - $100K\nBanshee - $90K\nTurismo - $120K\nPCJ-600 - $35K\nSanchez - $25K\nNRG-500 - $50K\nMaverick - $250K", "Select", "Cancel");
	        }
	        else if(listitem == 1)
	        {
	            new Float:pos[3], string[128], query[128];
	            for(new v = 0; v < MAX_VEHICLES; v++)
				{
				    if(IsValidVehicle(v) && VehicleInfo[v][vehicle_owned] == true)
				    {
				        GetVehiclePos(v, pos[0], pos[1], pos[2]);
				        if(IsPlayerInRangeOfPoint(playerid, 15.0, pos[0], pos[1], pos[2]))
						{
							if(!strcmp(GetName(playerid), VehicleInfo[v][vehicle_owner], false))
							{
							    DestroyVehicle(v);

							    format(query, sizeof(query), "DELETE FROM `VEHICLES` WHERE `OWNER` = '%s' COLLATE NOCASE", DB_Escape(GetName(playerid)));
								database_result = db_query(vehicle_database, query);
								db_free_result(database_result);

							    VehicleInfo[v][vehicle_owned] = false;

							    new cash = VehicleInfo[v][vehicle_price] / 2;
							    GivePlayerMoney(playerid, cash);

							    format(string, sizeof(string), "SERVER: You have just traded in your vehicle for: $%d", cash);
							    return SendClientMessage(playerid, WHITE, string);
							}
						}
					}
				}

				SendClientMessage(playerid, RED, "SERVER: You must be next to your vehicle to use this function.");
	        }
	    }
	    return 1;
	}
	else if(dialogid == SF_MENU_DIALOG)
	{
	    if(response)
	    {
	        if(listitem == 0)
	        {
	            return ShowPlayerDialog(playerid, SF_LIST_DIALOG, DIALOG_STYLE_LIST, "{FFFFFF}San Fierro Motors",
				"{FFFFFF}Buffalo - $25K\nInfernus - $120K\nCheetah - $100K\nBanshee - $90K\nTurismo - $120K\nPCJ-600 - $35K\nSanchez - $25K\nNRG-500 - $50K\nMaverick - $250K", "Select", "Cancel");
	        }
	        else if(listitem == 1)
	        {
	            new Float:pos[3], string[128], query[128];
	            for(new v = 0; v < MAX_VEHICLES; v++)
				{
				    if(IsValidVehicle(v) && VehicleInfo[v][vehicle_owned] == true)
				    {
				        GetVehiclePos(v, pos[0], pos[1], pos[2]);
				        if(IsPlayerInRangeOfPoint(playerid, 15.0, pos[0], pos[1], pos[2]))
						{
							if(!strcmp(GetName(playerid), VehicleInfo[v][vehicle_owner], false))
							{
							    DestroyVehicle(v);

							    format(query, sizeof(query), "DELETE FROM `VEHICLES` WHERE `OWNER` = '%s' COLLATE NOCASE", DB_Escape(GetName(playerid)));
								database_result = db_query(vehicle_database, query);
								db_free_result(database_result);

							    VehicleInfo[v][vehicle_owned] = false;

							    new cash = VehicleInfo[v][vehicle_price] / 2;
							    GivePlayerMoney(playerid, cash);

							    format(string, sizeof(string), "SERVER: You have just traded in your vehicle for: $%d", cash);
							    return SendClientMessage(playerid, WHITE, string);
							}
						}
					}
				}

				SendClientMessage(playerid, RED, "SERVER: You must be next to your vehicle to use this function.");
	        }
	    }
	    return 1;
	}
	else if(dialogid == LV_MENU_DIALOG)
	{
	    if(response)
	    {
	        if(listitem == 0)
	        {
	            return ShowPlayerDialog(playerid, LV_LIST_DIALOG, DIALOG_STYLE_LIST, "{FFFFFF}Las Venturas Motors",
				"{FFFFFF}Buffalo - $25K\nInfernus - $120K\nCheetah - $100K\nBanshee - $90K\nTurismo - $120K\nPCJ-600 - $35K\nSanchez - $25K\nNRG-500 - $50K\nMaverick - $250K", "Select", "Cancel");
	        }
	        else if(listitem == 1)
	        {
	            new Float:pos[3], string[128], query[128];
	            for(new v = 0; v < MAX_VEHICLES; v++)
				{
				    if(IsValidVehicle(v) && VehicleInfo[v][vehicle_owned] == true)
				    {
				        GetVehiclePos(v, pos[0], pos[1], pos[2]);
				        if(IsPlayerInRangeOfPoint(playerid, 15.0, pos[0], pos[1], pos[2]))
						{
							if(!strcmp(GetName(playerid), VehicleInfo[v][vehicle_owner], false))
							{
							    DestroyVehicle(v);

							    format(query, sizeof(query), "DELETE FROM `VEHICLES` WHERE `OWNER` = '%s' COLLATE NOCASE", DB_Escape(GetName(playerid)));
								database_result = db_query(vehicle_database, query);
								db_free_result(database_result);

							    VehicleInfo[v][vehicle_owned] = false;

							    new cash = VehicleInfo[v][vehicle_price] / 2;
							    GivePlayerMoney(playerid, cash);

							    format(string, sizeof(string), "SERVER: You have just traded in your vehicle for: $%d", cash);
							    return SendClientMessage(playerid, WHITE, string);
							}
						}
					}
				}

				SendClientMessage(playerid, RED, "SERVER: You must be next to your vehicle to use this function.");
	        }
	    }
	}
	return 1;
}

public OnPlayerEnterDynamicCP(playerid, checkpointid)
{
	if(GetPlayerState(playerid) == PLAYER_STATE_ONFOOT)
	{
		if(checkpointid == LosSantosMotors)
		{
			return ShowPlayerDialog(playerid, LS_MENU_DIALOG, DIALOG_STYLE_LIST, "{FFFFFF}Los Santos Motors", "{FFFFFF}Purchase Vehicle\nTrade-In Vehicle", "Select", "Cancel");
		}
		else if(checkpointid == SanFierroMotors)
		{
			return ShowPlayerDialog(playerid, SF_MENU_DIALOG, DIALOG_STYLE_LIST, "{FFFFFF}San Fierro Motors", "{FFFFFF}Purchase Vehicle\nTrade-In Vehicle", "Select", "Cancel");
		}
		else if(checkpointid == LasVenturasMotors)
		{
			ShowPlayerDialog(playerid, LV_MENU_DIALOG, DIALOG_STYLE_LIST, "{FFFFFF}Las Venturas Motors", "{FFFFFF}Purchase Vehicle\nTrade-In Vehicle", "Select", "Cancel");
		}
	}
	return 1;
}

public SetVehicleParamsForAll(carid, objective, doorslocked)
{
	for(new i = 0; i < MAX_PLAYERS; i++) { SetVehicleParamsForPlayer(carid, i, objective, doorslocked); }
	return 1;
}

public OnVehicleDeath(vehicleid, killerid)
{
	new engine, lights, alarm, doors, bonnet, boot, condition;
	if(VehicleInfo[vehicleid][vehicle_owned] == true)
	{
	    DestroyVehicle(vehicleid);

		new veh = CreateVehicle(VehicleInfo[vehicleid][vehicle_model], VehicleInfo[vehicleid][vehicle_x], VehicleInfo[vehicleid][vehicle_y], VehicleInfo[vehicleid][vehicle_z], VehicleInfo[vehicleid][vehicle_a], VehicleInfo[vehicleid][vehicle_colour1], VehicleInfo[vehicleid][vehicle_colour2], -1);
        SetVehicleNumberPlate(veh, VehicleInfo[vehicleid][vehicle_plate]);
		SetVehicleToRespawn(veh);

		VehicleInfo[veh][vehicle_owner] = VehicleInfo[vehicleid][vehicle_owner];
		VehicleInfo[veh][vehicle_model] = VehicleInfo[vehicleid][vehicle_model];
		VehicleInfo[veh][vehicle_x] = VehicleInfo[vehicleid][vehicle_x];
		VehicleInfo[veh][vehicle_y] = VehicleInfo[vehicleid][vehicle_y];
		VehicleInfo[veh][vehicle_z] = VehicleInfo[vehicleid][vehicle_z];
		VehicleInfo[veh][vehicle_a] = VehicleInfo[vehicleid][vehicle_a];
		VehicleInfo[veh][vehicle_health] = VehicleInfo[vehicleid][vehicle_health];
		VehicleInfo[veh][vehicle_colour1] = VehicleInfo[vehicleid][vehicle_colour1];
		VehicleInfo[veh][vehicle_colour2] = VehicleInfo[vehicleid][vehicle_colour2];
		VehicleInfo[veh][vehicle_paintjob] = VehicleInfo[vehicleid][vehicle_paintjob];
		VehicleInfo[veh][vehicle_plate] = VehicleInfo[vehicleid][vehicle_plate];
		VehicleInfo[veh][vehicle_price] = VehicleInfo[vehicleid][vehicle_price];
		VehicleInfo[veh][vehicle_locked] = VehicleInfo[vehicleid][vehicle_locked];
		VehicleInfo[veh][vehicle_owned] = VehicleInfo[vehicleid][vehicle_owned];

		VehicleInfo[veh][vehicle_health] = 1000.0;

		SetVehicleHealth(veh, VehicleInfo[veh][vehicle_health]);

		if(VehicleInfo[veh][vehicle_paintjob] != 0)
		{
			ChangeVehiclePaintjob(veh, VehicleInfo[veh][vehicle_paintjob]);
		}

		if(VehicleInfo[veh][vehicle_locked] == YES)
		{
			SetVehicleParamsForAll(veh, 0, 1);
        	GetVehicleParamsEx(veh, engine, lights, alarm, doors, bonnet, boot, condition);
			SetVehicleParamsEx(veh, engine, lights, alarm, ON, bonnet, boot, condition);
		}
		else
		{
			SetVehicleParamsForAll(veh, 0, 0);
        	GetVehicleParamsEx(veh, engine, lights, alarm, doors, bonnet, boot, condition);
			SetVehicleParamsEx(veh, engine, lights, alarm, OFF, bonnet, boot, condition);
		}
	}
	return 1;
}

public OnVehicleStreamIn(vehicleid, forplayerid)
{
	new engine, lights, alarm, doors, bonnet, boot, condition;
	if(VehicleInfo[vehicleid][vehicle_owned] == true)
	{
 		if(VehicleInfo[vehicleid][vehicle_locked] == YES)
  		{
			SetVehicleParamsForAll(vehicleid, 0, 1);
        	GetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, condition);
			SetVehicleParamsEx(vehicleid, engine, lights, alarm, ON, bonnet, boot, condition);
			VehicleInfo[vehicleid][vehicle_locked] = YES;
		}
  		else
  		{
  			SetVehicleParamsForAll(vehicleid, 0, 0);
        	GetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, condition);
			SetVehicleParamsEx(vehicleid, engine, lights, alarm, OFF, bonnet, boot, condition);
			VehicleInfo[vehicleid][vehicle_locked] = NO;
   		}
   	}
	return 1;
}

public OnVehicleStreamOut(vehicleid, forplayerid)
{
	new engine, lights, alarm, doors, bonnet, boot, condition;
	if(VehicleInfo[vehicleid][vehicle_owned] == true)
	{
 		if(VehicleInfo[vehicleid][vehicle_locked] == YES)
  		{
			SetVehicleParamsForAll(vehicleid, 0, 1);
        	GetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, condition);
			SetVehicleParamsEx(vehicleid, engine, lights, alarm, ON, bonnet, boot, condition);
			VehicleInfo[vehicleid][vehicle_locked] = YES;
		}
  		else
  		{
  			SetVehicleParamsForAll(vehicleid, 0, 0);
        	GetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, condition);
			SetVehicleParamsEx(vehicleid, engine, lights, alarm, OFF, bonnet, boot, condition);
			VehicleInfo[vehicleid][vehicle_locked] = NO;
   		}
   	}
	return 1;
}

public OnPlayerEnterCheckpoint(playerid)
{
	if(HasSetCheckpoint[playerid] == true)
 	{
    	DisablePlayerCheckpoint(playerid);
    	HasSetCheckpoint[playerid] = false;
    }
    return 1;
}

CMD:locveh(playerid, params[])
{
	new vehicleid = GetOwnedVehicle(playerid), Float:pos[3];
    if(vehicleid == INVALID_VEHICLE_ID) return SendClientMessage(playerid, RED, "SERVER: You must own a vehicle to use this command.");

	GetVehiclePos(vehicleid, pos[0], pos[1], pos[2]);
	
	SetPlayerCheckpoint(playerid, pos[0], pos[1], pos[2], 10.0);
	
	HasSetCheckpoint[playerid] = true;
	
	GameTextForPlayer(playerid, "~g~Set", 3000, 5);
	return 1;
}

CMD:park(playerid, params[])
{
	new vehicleid = GetPlayerVehicleID(playerid), Float:pos[4];
	if(!IsPlayerInAnyVehicle(playerid) || vehicleid != GetOwnedVehicle(playerid)) return SendClientMessage(playerid, RED, "You must be in an owned vehicle to use this command.");

	GetVehiclePos(GetOwnedVehicle(playerid), pos[0], pos[1], pos[2]);
	GetVehicleZAngle(GetOwnedVehicle(playerid), pos[3]);

	VehicleInfo[GetOwnedVehicle(playerid)][vehicle_x] = pos[0];
	VehicleInfo[GetOwnedVehicle(playerid)][vehicle_y] = pos[1];
	VehicleInfo[GetOwnedVehicle(playerid)][vehicle_z] = pos[2];
	VehicleInfo[GetOwnedVehicle(playerid)][vehicle_a] = pos[3];

	GameTextForPlayer(playerid, "~g~Parked", 3000, 5);
	return 1;
}

CMD:lock(playerid, params[])
{
    new vehicleid = GetOwnedVehicle(playerid), Float:pos[3], engine, lights, alarm, doors, bonnet, boot, condition;
    if(vehicleid == INVALID_VEHICLE_ID) return SendClientMessage(playerid, RED, "SERVER: You must own a vehicle to use this command.");

	GetVehiclePos(vehicleid, pos[0], pos[1], pos[2]);
	if(!IsPlayerInRangeOfPoint(playerid, 10.0, pos[0], pos[1], pos[2])) return SendClientMessage(playerid, RED, "SERVER: You must be next to your owned vehicle to use this command.");

	if(VehicleInfo[vehicleid][vehicle_locked] == NO)
	{
	    VehicleInfo[vehicleid][vehicle_locked] = YES;

		SetVehicleParamsForAll(vehicleid, 0, 1);
        GetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, condition);
		SetVehicleParamsEx(vehicleid, engine, lights, alarm, ON, bonnet, boot, condition);

		GameTextForPlayer(playerid, "~g~Locked", 3000, 5);
		return 1;
	}
	else
	{
	    VehicleInfo[vehicleid][vehicle_locked] = NO;

		SetVehicleParamsForAll(vehicleid, 0, 0);
        GetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, condition);
		SetVehicleParamsEx(vehicleid, engine, lights, alarm, OFF, bonnet, boot, condition);

		GameTextForPlayer(playerid, "~r~Unlocked", 3000, 5);
	}
	return 1;
}

