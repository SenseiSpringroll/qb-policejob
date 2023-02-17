local QBCore = exports['qb-core']:GetCoreObject()


QBCore.Functions.CreateUseableItem("policetablet", function(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    TriggerClientEvent("fingerprint:client:policetablet", src)
end)

RegisterServerEvent('fingerprint:server:fingerprintmenu') 
AddEventHandler('fingerprint:server:fingerprintmenu', function(playerId)
    local src = source
    local Target = QBCore.Functions.GetPlayer(playerId)
    local pdata = Target.PlayerData
	if Target then
        TriggerClientEvent('fingerprint:client:fingerprintmenu', src, pdata)
    end
end)