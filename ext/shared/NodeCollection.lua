class "NodeCollection"

function NodeCollection:__init()
	self.waypointIDs = 0
	self.waypointsByID = {}
	self.waypointsByIndex = {}
end

function NodeCollection:CreateWaypoint(vec3Position, pathIndex, inputVar)
	local newIndex = self:_createID()
	local waypoint = {
		ID = 'p_'..tostring(newIndex),
		Index = newIndex,
		Position = vec3Position,
		PathIndex = pathIndex,
		InputVar = inputVar
	}
	self:Add(waypoint)
	return waypoint
end

function NodeCollection:Add(waypoint)
	self.waypointsByID[waypoint.ID] = waypoint
	self.waypointsByIndex[waypoint.Index] = waypoint
end

function NodeCollection:Remove(waypoint)
	self.waypointsByID[waypoint.ID] = nil
	self.waypointsByIndex[waypoint.Index] = nil
end

function NodeCollection:Clear()
	self.waypointsByID = {}
	self.waypointsByIndex = {}
end

function NodeCollection:GetWaypoints()
	return self.waypointsByID
end

function NodeCollection:Load(mapName)
	if not SQL:Open() then
		return
	end

	-- Fetch all rows from the table.
	local results = SQL:Query('SELECT * FROM ' .. mapName .. '_table')

	if not results then
		print('Failed to execute query: ' .. SQL:Error())
		return
	end

	self:Clear()
	local pathCount = 0
	local waypointCount = 0

	for _, row in pairs(results) do
		if row["pathIndex"] > pathCount then
			pathCount = row["pathIndex"]
		end

		self:CreateWaypoint(Vec3(row["transX"], row["transY"], row["transZ"]), row["pathIndex"], row["inputVar"])
		waypointCount = waypointCount+1
	end

	SQL:Close()
	print('NodeCollection:Load -> Paths: '..tostring(pathCount)..' | Waypoints: '..tostring(waypointCount))
end

function NodeCollection:PreviousWaypoint(currentWaypoint)
	return self.waypointsByIndex[currentWaypoint.Index-1]
end

function NodeCollection:Find(vec3Position, tolerance)

	if (tolerance == nil) then
		tolerance = 0.2
	end

	for _,waypoint in pairs(self.waypointsByID) do
		if (waypoint ~= nil and waypoint.Position ~= nil and waypoint.Position:Distance(vec3Position) < tolerance) then
			return waypoint
		end
	end
	return nil
end

function NodeCollection:_createID()
	local index = self.waypointIDs
	self.waypointIDs = self.waypointIDs+1
	return index
end

return NodeCollection()