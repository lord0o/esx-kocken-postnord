ESX = nil


TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

RegisterServerEvent('esx-kocken-postnord:receiveMoney')
AddEventHandler('esx-kocken-postnord:receiveMoney', function()
    local _source = source
    local Player = ESX.GetPlayerFromId(_source)
    local moneytoget = math.random(20, 30)
    Player.addMoney(moneytoget)
    TriggerClientEvent("esx:showNotification", _source, ('Du klarade av körningen och tog emot ~g~'..moneytoget..' SEK'))
end) 


--notification
function sendNotification(message, messageType, messageTimeout)
	TriggerEvent("pNotify:SendNotification", {
		text = message,
		type = messageType,
		queue = "kocken",
		timeout = messageTimeout,
		layout = "bottomCenter"
	})
end
