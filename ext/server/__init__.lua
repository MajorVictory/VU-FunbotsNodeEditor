

nodeCollection = require('__shared/NodeCollection')

Hooks:Install('BulletEntity:Collision', 1, function(hook, entity, hit, giverInfo)

	print('BulletEntity:Collision')

	local hitPoint = nodeCollection:Find(hit.position)

	if (hitPoint == nil) then
		local waypoint = nodeCollection:CreateWaypoint(hit.position, 10, 0)
		NetEvents:SendToLocal('BulletDraw:CreatePoint', giverInfo.giver, waypoint)
	else
		nodeCollection:Remove(hitPoint)
		NetEvents:SendToLocal('BulletDraw:DeletePoint', giverInfo.giver, hitPoint)
	end
end)

Events:Subscribe('Player:Respawn', function(player)
	NetEvents:SendToLocal('BulletDraw:ClearPoints', player)
	print('Player:Respawn')
	for id, waypoint in pairs(nodeCollection:GetWaypoints()) do
		NetEvents:SendToLocal('BulletDraw:CreatePoint', player, waypoint)
	end
	NetEvents:SendToLocal('BulletDraw:Init', player)
end)

Events:Subscribe('Level:Loaded', function(levelName, gameMode)
	print('Level:Loaded')
	nodeCollection:Load(levelName .. '_TeamDeathMatch0')
end)