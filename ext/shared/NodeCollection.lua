class "NodeCollection"

function NodeCollection:__init()
	self.waypointIDs = 0
	self.waypoints = {}
	self.waypointsByID = {}
	self.waypointsByIndex = {}
	self.waypointSelected = nil
end

function NodeCollection:CreateWaypoint(vec3Position, pathIndex, inputVar)
	local newIndex = self:_createID()
	local waypoint = {
		ID = 'p_'..tostring(newIndex),
		Index = newIndex,
		Position = vec3Position,
		PathIndex = pathIndex,
		InputVar = inputVar,
		Distance = nil
	}
	self:Add(waypoint)
	return waypoint
end

function NodeCollection:Add(waypoint)
	self.waypointsByID[waypoint.ID] = waypoint
	self.waypointsByIndex[waypoint.Index] = waypoint
	table.insert(self.waypoints, waypoint)
end

function NodeCollection:Remove(waypoint)
	self.waypointsByID[waypoint.ID] = nil
	self.waypointsByIndex[waypoint.Index] = nil
	local eraseIndex = nil
	for i = 1, #self.waypoints do
		if (self.waypoints[i].ID == waypoint.ID) then
			eraseIndex = i
		end
	end
	if (eraseIndex ~= nil) then
		table.remove(self.waypoints, eraseIndex)
	end
end

function NodeCollection:Update(waypoint)
	self.waypointsByID[waypoint.ID] = waypoint
	self.waypointsByIndex[waypoint.Index] = waypoint
	for i = 1, #self.waypoints do
		if (self.waypoints[i].ID == waypoint.ID) then
			self.waypoints[i] = waypoint
		end
	end
end

function NodeCollection:SetSelected(waypoint)
	self.waypointSelected = waypoint
end

function NodeCollection:GetSelected(waypoint)
	return self.waypointSelected
end

function NodeCollection:Clear()
	self.waypoints = {}
	self.waypointsByID = {}
	self.waypointsByIndex = {}
end

function NodeCollection:GetWaypoints()
	return self.waypoints
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
	local previousWaypoint = self.waypointsByIndex[currentWaypoint.Index-1]
	if (previousWaypoint ~= nil and previousWaypoint.PathIndex == currentWaypoint.PathIndex) then
		return previousWaypoint
	end
	return nil
end

function NodeCollection:Find(vec3Position, tolerance)
	if (tolerance == nil) then
		tolerance = 0.2
	end

	for _,waypoint in pairs(self.waypointsByID) do
		if (waypoint ~= nil and waypoint.Position ~= nil and waypoint.Position:Distance(vec3Position) <= tolerance) then
			print('NodeCollection:Find -> Found: '..waypoint.ID)
			return waypoint
		end
	end
	return nil
end

function NodeCollection:FindAll(vec3Position, tolerance)
	if (tolerance == nil) then
		tolerance = 0.2
	end

	local waypointsFound = {}

	for _,waypoint in pairs(self.waypointsByID) do
		if (waypoint ~= nil and waypoint.Position ~= nil and waypoint.Position:Distance(vec3Position) <= tolerance) then
			print('NodeCollection:FindAll -> Found: '..waypoint.ID)
			table.insert(waypointsFound, waypoint)
		end
	end
	return waypointsFound
end

function NodeCollection:FindAlongTrace(vec3Start, vec3End, granularity, tolerance)
	if (granularity == nil) then
		granularity = 0.25
	end
	if (tolerance == nil) then
		tolerance = 0.2
	end
	print('NodeCollection:FindAlongTrace - granularity: '..tostring(granularity))

	local distance = math.min(math.max(vec3Start:Distance(vec3End), 0.05), 10)

	-- instead of searching a possible 3k or more nodes, we grab only those that would be in range
	-- shift the search area forward by 1/2 distance and also 1/2 the radius needed
	local searchAreaPos = vec3Start + ((vec3End - vec3Start) * 0.5)
	local searchAreaSize = (distance*0.6)
	NetEvents:BroadcastLocal('BulletDraw:SetLastTraceSearchArea', {searchAreaPos, searchAreaSize})

	local searchWaypoints = self:FindAll(searchAreaPos, searchAreaSize)
	local testPos = vec3Start

	print('distance: '..tostring(distance))
	print('searchWaypoints: '..tostring(#searchWaypoints))

	while distance > granularity and distance > 0 do
		for _,waypoint in pairs(searchWaypoints) do
			if (waypoint ~= nil and waypoint.Position ~= nil and waypoint.Position:Distance(testPos) <= tolerance) then
				print('NodeCollection:FindAlongTrace -> Found: '..waypoint.ID)
				return waypoint
			end
		end
		testPos = testPos:MoveTowards(vec3End, granularity)
		distance = testPos:Distance(vec3End)
	end
	return nil
end

function NodeCollection:_createID()
	local index = self.waypointIDs
	self.waypointIDs = self.waypointIDs+1
	return index
end

return NodeCollection()