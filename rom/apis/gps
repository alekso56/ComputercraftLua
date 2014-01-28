
local function trilaterate( A, B, C )

	local a2b = B.position - A.position
	local a2c = C.position - A.position
		
	if math.abs( a2b:normalize():dot( a2c:normalize() ) ) > 0.999 then
		return nil
	end
	
	local d = a2b:length()
	local ex = a2b:normalize( )
	local i = ex:dot( a2c )
	local ey = (a2c - (ex * i)):normalize()
	local j = ey:dot( a2c )
	local ez = ex:cross( ey )

	local r1 = A.distance
	local r2 = B.distance
	local r3 = C.distance
		
	local x = (r1*r1 - r2*r2 + d*d) / (2*d)
	local y = (r1*r1 - r3*r3 - x*x + (x-i)*(x-i) + j*j) / (2*j)
		
	local result = A.position + (ex * x) + (ey * y)

	local zSquared = r1*r1 - x*x - y*y
	if zSquared > 0 then
		local z = math.sqrt( zSquared )
		local result1 = result + (ez * z)
		local result2 = result - (ez * z)
		
		local rounded1, rounded2 = result1:round(), result2:round()
		if rounded1.x ~= rounded2.x or rounded1.y ~= rounded2.y or rounded1.z ~= rounded2.z then
			return result1, result2
		else
			return rounded1
		end
	end
	return result:round()
	
end

local function narrow( p1, p2, fix )
	local dist1 = math.abs( (p1 - fix.position):length() - fix.distance )
	local dist2 = math.abs( (p2 - fix.position):length() - fix.distance )
	
	if math.abs(dist1 - dist2) < 0.05 then
		return p1, p2
	elseif dist1 < dist2 then
		return p1:round()
	else
		return p2:round()
	end
end

function locate( _nTimeout, _bDebug )
	if _bDebug then
		print( "Finding position..." )
	end
	rednet.broadcast( "PING" )
	
	local startTime = os.clock()
	local timeOut = _nTimeout
	local timeElapsed = 0
	
	local tFixes = {}
	local p1, p2 = nil
	while timeElapsed < timeOut and (p1 == nil or p2 ~= nil) do
		local sender, message, distance = rednet.receive( timeOut - timeElapsed )
		if sender and distance then
			local result = textutils.unserialize( message )
			if type(result) == "table" and #result == 3 then
				local tFix = { id = sender, position = vector.new( result[1], result[2], result[3] ), distance = distance }
				if _bDebug then
					print( tFix.distance.." metres from "..tostring( tFix.position ) )
				end
				table.insert( tFixes, tFix )
				
				if #tFixes >= 3 then
					if not p1 then
						p1, p2 = trilaterate( tFixes[1], tFixes[2], tFixes[#tFixes] )
					else
						p1, p2 = narrow( p1, p2, tFixes[#tFixes] )
					end
				end
			end
		end
		timeElapsed = os.clock() - startTime
	end
	
	if p1 and p2 then
		if _bDebug then
			print( "Ambiguous position" )
			print( "Could be "..p1.x..","..p1.y..","..p1.z.." or "..p2.x..","..p2.y..","..p2.z )
		end
		return nil
	elseif p1 then
		if _bDebug then
			print( "Position is "..p1.x..","..p1.y..","..p1.z )
		end
		return p1.x, p1.y, p1.z
	else
		if _bDebug then
			print( "Could not determine position" )
		end
		return nil
	end
end
