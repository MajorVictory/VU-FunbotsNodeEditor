
nodeCollection = require('__shared/NodeCollection')


local waypointRange = 100
local drawWaypointLines = true
local lineRange = 15
local drawWaypointIDs = true
local textRange = 5

-- caching values for drawing performance
local waypoints = {}
local playerPos = nil
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
Console:Register('lineRange', 'Set how far away waypoint lines are visible (meters): Default '..tostring(lineRange), function(args)
	lineRange = tonumber(args[1])
end)
Console:Register('textRange', 'Set how far away waypoint text is visible (meters): Default '..tostring(textRange), function(args)
	textRange = tonumber(args[1])
end)
Console:Register('drawWaypointIDs', 'Draw waypoint IDs: Default '..tostring(drawWaypointIDs), function(args)
	drawWaypointIDs = (args[1]:lower() == 'true' or args[1] == '1')
end)
Console:Register('drawWaypointLines', 'Draw waypoint Lines: Default '..tostring(drawWaypointLines), function(args)
	drawWaypointLines = (args[1]:lower() == 'true' or args[1] == '1')
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
	waypoints = {}
end)

NetEvents:Subscribe('BulletDraw:Init', function(args)
	print('BulletDraw:Init')
	player = PlayerManager:GetLocalPlayer()
	waypoints = nodeCollection:GetWaypoints()
end)

Events:Subscribe('Client:PostFrameUpdate', function(deltaTime)
	-- doing this here and not in UI:DrawHud prevents a memory leak that crashes you in under a minute
	if (player ~= nil and player.soldier ~= nil and player.soldier.worldTransform ~= nil) then
		playerPos = player.soldier.worldTransform.trans
    	for i=1, #waypoints do
    		if (waypoints[i] ~= nil) then
    			-- precalc the distances for less overhead on the hud draw
    			waypoints[i].Distance = playerPos:Distance(waypoints[i].Position)
    		end
    	end
    end
end)

Events:Subscribe('UI:DrawHud', function()
	for i=1, #waypoints do
		if (waypoints[i] ~= nil) then

			if (waypoints[i].Distance ~= nil and waypoints[i].Distance < waypointRange) then
				DebugRenderer:DrawSphere(waypoints[i].Position, 0.05, sphereColors[waypoints[i].PathIndex], false, false)
			end

			if (waypoints[i].Distance ~= nil and waypoints[i].Distance < lineRange and drawWaypointLines) then
				-- try to find a previous node and draw a line to it
				local previousWaypoint = nodeCollection:PreviousWaypoint(waypoints[i])
				if (previousWaypoint ~= nil) then
					DebugRenderer:DrawLine(previousWaypoint.Position, waypoints[i].Position, lineColors[waypoints[i].PathIndex], lineColors[waypoints[i].PathIndex])
					previousWaypoint = nil
				end
			end

			if (waypoints[i].Distance ~= nil and waypoints[i].Distance < textRange and drawWaypointIDs) then
				-- don't try to precalc this value like with the distance, another memory leak crash awaits you
				local screenPos = ClientUtils:WorldToScreen(waypoints[i].Position)
				if (screenPos ~= nil) then
					DebugRenderer:DrawText2D(screenPos.x, screenPos.y, waypoints[i].ID.." | "..waypoints[i].InputVar, textColor, 1)
					screenPos = nil
				end
			end
		end
	end
end)
