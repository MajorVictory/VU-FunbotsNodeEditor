

nodeCollection = require('__shared/NodeCollection')

Hooks:Install('BulletEntity:Collision', 1, function(hook, entity, hit, giverInfo)

	print('BulletEntity:Collision')

	local hitPoint = nodeCollection:Find(hit.position)

	if (hitPoint == nil and giverInfo.giver ~= nil and giverInfo.giver.soldier ~= nil) then
		local playerCamPos = giverInfo.giver.soldier.worldTransform.trans + giverInfo.giver.input.authoritativeCameraPosition
		hitPoint = nodeCollection:FindAlongTrace(playerCamPos, hit.position)
		NetEvents:BroadcastLocal('BulletDraw:SetLastTrace', {playerCamPos, hit.position})
	end

	if (hitPoint == nil) then
		local waypoint = nodeCollection:CreateWaypoint(hit.position, 10, 0)
		NetEvents:BroadcastLocal('BulletDraw:CreatePoint', waypoint)
		hook:Return()
	else

		local selectedNode = nodeCollection:GetSelected()

		if (selectedNode == nil) then
			nodeCollection:SetSelected(hitPoint)
			NetEvents:SendToLocal('BulletDraw:SelectPoint', giverInfo.giver, hitPoint)
			hook:Return()
		else
			if (hitPoint.ID == selectedNode.ID) then
				nodeCollection:SetSelected(nil)
				NetEvents:SendToLocal('BulletDraw:DeselectPoint', giverInfo.giver)
				hook:Return()
			else
				nodeCollection:SetSelected(hitPoint)
				NetEvents:SendToLocal('BulletDraw:DeselectPoint', giverInfo.giver)
				NetEvents:SendToLocal('BulletDraw:SelectPoint', giverInfo.giver, hitPoint)
				hook:Return()
			end
		end
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