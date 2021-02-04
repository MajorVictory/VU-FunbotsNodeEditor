
nodeCollection = require('__shared/NodeCollection')

local waypoints = {}
local waypointRange = 100
local detailRange = 5
local drawWaypointIDs = false
local textColor = Vec4(1,1,1,1)
local sphereColors = {
	Vec4(1,0,0,0.25),
	Vec4(0,1,0,0.25),
	Vec4(0,0,1,0.25),
	Vec4(1,1,0,0.25),
	Vec4(1,0,1,0.25),
	Vec4(0,1,1,0.25),
	Vec4(1,0.5,0,0.25),
	Vec4(1,0,0.5,0.25),
	Vec4(0,0.5,1,0.25),
	Vec4(1,0.5,0.5,0.25),
}
local lineColors = {
	Vec4(1,0,0,1),
	Vec4(0,1,0,1),
	Vec4(0,0,1,1),
	Vec4(1,1,0,1),
	Vec4(1,0,1,1),
	Vec4(0,1,1,1),
	Vec4(1,0.5,0,1),
	Vec4(1,0,0.5,1),
	Vec4(0,0.5,1,1),
	Vec4(1,0.5,0.5,1),
}

Console:Register('waypointRange', 'Set how far away waypoints are visible (meters): Default '..tostring(waypointRange), function(args)
	waypointRange = tonumber(args[1])
end)
Console:Register('detailRange', 'Set how far away waypoint details are visible (meters): Default '..tostring(detailRange), function(args)
	detailRange = tonumber(args[1])
end)
Console:Register('drawWaypointIDs', 'Draw waypoint IDs: Default '..tostring(drawWaypointIDs), function(args)
	drawWaypointIDs = (args[1]:lower() == 'true' or args[1] == '1')
end)

NetEvents:Subscribe('BulletDraw:CreatePoint', function(waypoint)
	print('BulletDraw:CreatePoint - '..tostring(waypoint.ID)..' Pos: '..tostring(waypoint.Position))
	nodeCollection:Add(waypoint)
end)

NetEvents:Subscribe('BulletDraw:DeletePoint', function(waypoint)
	print('BulletDraw:DeletePoint - '..tostring(waypoint.ID))
	nodeCollection:Remove(waypoint)
end)

NetEvents:Subscribe('BulletDraw:ClearPoints', function(args)
	print('BulletDraw:ClearPoints')
	nodeCollection:Clear()
end)

NetEvents:Subscribe('BulletDraw:Init', function(args)
	print('BulletDraw:Init')
	player = PlayerManager:GetLocalPlayer()
	waypoints = nodeCollection:GetWaypoints()
end)

Events:Subscribe('UI:DrawHud', function()
	for id, waypoint in pairs(waypoints) do
		if (waypoint ~= nil) then
			-- only draw numbers while in range (5 meters)
			if (player ~= nil and player.soldier ~= nil and player.soldier.worldTransform ~= nil) then

				local distance = player.soldier.worldTransform.trans:Distance(waypoint.Position)
				if (distance < waypointRange) then

					DebugRenderer:DrawSphere(waypoint.Position, 0.05, sphereColors[waypoint.PathIndex], false, false)

					if (distance < detailRange) then

						if (drawWaypointIDs) then
							local screenPos = ClientUtils:WorldToScreen(waypoint.Position)
							if (screenPos ~= nil) then
								DebugRenderer:DrawText2D(screenPos.x, screenPos.y, waypoint.ID, textColor, 1)
							end
						end

						-- try to find a previous node and draw a line to it
						local previousWaypoint = nodeCollection:PreviousWaypoint(waypoint)
						if (previousWaypoint ~= nil) then
							DebugRenderer:DrawLine(previousWaypoint.Position, waypoint.Position, lineColors[waypoint.PathIndex], lineColors[waypoint.PathIndex])
						end
					end
				end
			end
		end
	end
end)
