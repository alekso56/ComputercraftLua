
-- Install lua parts of the os api
function os.version()
	if turtle then
		return "TurtleOS 1.4"
	end
	return "CraftOS 1.4"
end

function os.pullEventRaw( _sFilter )
	return coroutine.yield( _sFilter )
end

function os.pullEvent( _sFilter )
	local event, p1, p2, p3, p4, p5 = os.pullEventRaw( _sFilter )
	if event == "terminate" then
		print( "Terminated" )
		error()
	end
	return event, p1, p2, p3, p4, p5
end

-- Install globals
function sleep( _nTime )
    local timer = os.startTimer( _nTime )
	repeat
		local sEvent, param = os.pullEvent( "timer" )
	until param == timer
end

function write( sText )
	local w,h = term.getSize()		
	local x,y = term.getCursorPos()
	
	local nLinesPrinted = 0
	local function newLine()
		if y + 1 <= h then
			term.setCursorPos(1, y + 1)
		else
			term.scroll(1)
			term.setCursorPos(1, h)
		end
		x, y = term.getCursorPos()
		nLinesPrinted = nLinesPrinted + 1
	end
	
	-- Print the line with proper word wrapping
	while string.len(sText) > 0 do
		local whitespace = string.match( sText, "^[ \t]+" )
		if whitespace then
			-- Print whitespace
			term.write( whitespace )
			x,y = term.getCursorPos()
			sText = string.sub( sText, string.len(whitespace) + 1 )
		end
		
		local newline = string.match( sText, "^\n" )
		if newline then
			-- Print newlines
			newLine()
			sText = string.sub( sText, 2 )
		end
		
		local text = string.match( sText, "^[^ \t\n]+" )
		if text then
			sText = string.sub( sText, string.len(text) + 1 )
			if string.len(text) > w then
				-- Print a multiline word				
				while string.len( text ) > 0 do
				if x > w then
					newLine()
				end
					term.write( text )
					text = string.sub( text, (w-x) + 2 )
					x,y = term.getCursorPos()
				end
			else
				-- Print a word normally
				if x + string.len(text) > w then
					newLine()
				end
				term.write( text )
				x,y = term.getCursorPos()
			end
		end
	end
	
	return nLinesPrinted
end

function print( ... )
	local nLinesPrinted = 0
	for n,v in ipairs( { ... } ) do
		nLinesPrinted = nLinesPrinted + write( tostring( v ) )
	end
	nLinesPrinted = nLinesPrinted + write( "\n" )
	return nLinesPrinted
end

function read( _sReplaceChar, _tHistory )	
	term.setCursorBlink( true )

    local sLine = ""
	local nHistoryPos = nil
	local nPos = 0
    if _sReplaceChar then
		_sReplaceChar = string.sub( _sReplaceChar, 1, 1 )
	end
	
	local w, h = term.getSize()
	local sx, sy = term.getCursorPos()	
	local function redraw()
		local nScroll = 0
		if sx + nPos >= w then
			nScroll = (sx + nPos) - w
		end
			
		term.setCursorPos( sx, sy )
		term.write( string.rep(" ", w - sx + 1) )
		term.setCursorPos( sx, sy )
		if _sReplaceChar then
			term.write( string.rep(_sReplaceChar, string.len(sLine) - nScroll) )
		else
			term.write( string.sub( sLine, nScroll + 1 ) )
		end
		term.setCursorPos( sx + nPos - nScroll, sy )
	end
	
	while true do
		local sEvent, param = os.pullEvent()
		if sEvent == "char" then
			sLine = string.sub( sLine, 1, nPos ) .. param .. string.sub( sLine, nPos + 1 )
			nPos = nPos + 1
			redraw()
			
		elseif sEvent == "key" then
		    if param == keys.enter then
				-- Enter
				break
				
			elseif param == keys.left then
				-- Left
				if nPos > 0 then
					nPos = nPos - 1
					redraw()
				end
				
			elseif param == keys.right then
				-- Right				
				if nPos < string.len(sLine) then
					nPos = nPos + 1
					redraw()
				end
			
			elseif param == keys.up or param == keys.down then
                -- Up or down
				if _tHistory then
					if param == keys.up then
						-- Up
						if nHistoryPos == nil then
							if #_tHistory > 0 then
								nHistoryPos = #_tHistory
							end
						elseif nHistoryPos > 1 then
							nHistoryPos = nHistoryPos - 1
						end
					else
						-- Down
						if nHistoryPos == #_tHistory then
							nHistoryPos = nil
						elseif nHistoryPos ~= nil then
							nHistoryPos = nHistoryPos + 1
						end						
					end
					
					if nHistoryPos then
                    	sLine = _tHistory[nHistoryPos]
                    	nPos = string.len( sLine ) 
                    else
						sLine = ""
						nPos = 0
					end
					redraw()
                end
			elseif param == keys.backspace then
				-- Backspace
				if nPos > 0 then
					sLine = string.sub( sLine, 1, nPos - 1 ) .. string.sub( sLine, nPos + 1 )
					nPos = nPos - 1					
					redraw()
				end
			end
		end
	end
	
	term.setCursorBlink( false )
	term.setCursorPos( w + 1, sy )
	print()
	
	return sLine
end

loadfile = function( _sFile )
	local file = fs.open( _sFile, "r" )
	if file then
		local func, err = loadstring( file.readAll(), fs.getName( _sFile ) )
		file.close()
		return func, err
	end
	return nil, "File not found"
end

dofile = function( _sFile )
	local fnFile, e = loadfile( _sFile )
	if fnFile then
		setfenv( fnFile, getfenv(2) )
		fnFile()
	else
		error( e )
	end
end

-- Install the rest of the OS api
function os.run( _tEnv, _sPath, ... )
    local tArgs = { ... }
    local fnFile, err = loadfile( _sPath )
    if fnFile then
        local tEnv = _tEnv
        setmetatable( tEnv, { __index = _G } )
        setfenv( fnFile, tEnv )
        local ok, err = pcall( function()
        	fnFile( unpack( tArgs ) )
        end )
        if not ok then
        	if err and err ~= "" then
	        	print( err )
	        end
        	return false
        end
        return true
    end
    if err and err ~= "" then
		print( err )
	end
    return false
end

local nativegetmetatable = getmetatable
local nativetype = type
local nativeerror = error
function getmetatable( _t )
	if nativetype( _t ) == "string" then
		nativeerror( "Attempt to access string metatable" )
		return nil
	end
	return nativegetmetatable( _t )
end

local bProtected = true
local function protect( _t )
	local meta = getmetatable( _t )
	if meta == "Protected" then
		-- already protected
		return
	end
	
	setmetatable( _t, {
		__newindex = function( t, k, v )
			if bProtected then
				error( "Attempt to write to global" )
			else
				rawset( t, k, v )
			end
		end,
		__metatable = "Protected",
	} )
end

local tAPIsLoading = {}
function os.loadAPI( _sPath )
	local sName = fs.getName( _sPath )
	if tAPIsLoading[sName] == true then
		print( "API "..sName.." is already being loaded" )
		return false
	end
	tAPIsLoading[sName] = true
		
	local tEnv = {}
	setmetatable( tEnv, { __index = _G } )
	local fnAPI, err = loadfile( _sPath )
	if fnAPI then
		setfenv( fnAPI, tEnv )
		fnAPI()
	else
		print( err )
        tAPIsLoading[sName] = nil
		return false
	end
	
	local tAPI = {}
	for k,v in pairs( tEnv ) do
		tAPI[k] =  v
	end
	protect( tAPI )
	
	bProtected = false
	_G[sName] = tAPI
	bProtected = true
	
	tAPIsLoading[sName] = nil
	return true
end

function os.unloadAPI( _sName )
	if _sName ~= "_G" and type(_G[_sName]) == "table" then
		bProtected = false
		_G[_sName] = nil
		bProtected = true
	end
end

function os.sleep( _nTime )
	sleep( _nTime )
end

local nativeShutdown = os.shutdown
function os.shutdown()
	nativeShutdown()
	while true do
		coroutine.yield()
	end
end

-- Install the lua part of the HTTP api (if enabled)
if http then
	local function wrapRequest( _url, _post )
		local requestID = http.request( _url, _post )
		while true do
			local event, param1, param2 = os.pullEvent()
			if event == "http_success" and param1 == _url then
				return param2
			elseif event == "http_failure" and param1 == _url then
				return nil
			end
		end		
	end
	
	http.get = function( _url )
		return wrapRequest( _url, nil )
	end

	http.post = function( _url, _post )
		return wrapRequest( _url, _post or "" )
	end
end

-- Install the lua part of the peripheral api
peripheral.wrap = function( _sSide )
	if peripheral.isPresent( _sSide ) then
		local tMethods = peripheral.getMethods( _sSide )
		local tResult = {}
		for n,sMethod in ipairs( tMethods ) do
			tResult[sMethod] = function( ... )
				return peripheral.call( _sSide, sMethod, ... )
			end
		end
		return tResult
	end
	return nil
end

-- Protect the global table against modifications
protect( _G )
for k,v in pairs( _G ) do
	if type(v) == "table" then
		protect( v )
	end
end

-- Load APIs
local tApis = fs.list( "rom/apis" )
for n,sFile in ipairs( tApis ) do
	if string.sub( sFile, 1, 1 ) ~= "." then
		local sPath = fs.combine( "rom/apis", sFile )
		if not fs.isDir( sPath ) then
			os.loadAPI( sPath )
		end
	end
end

if turtle then
	local tApis = fs.list( "rom/apis/turtle" )
	for n,sFile in ipairs( tApis ) do
		if string.sub( sFile, 1, 1 ) ~= "." then
			local sPath = fs.combine( "rom/apis/turtle", sFile )
			if not fs.isDir( sPath ) then
				os.loadAPI( sPath )
			end
		end
	end
end

-- Run the shell
local ok, err = pcall( function()
	parallel.waitForAny(
		function()
			rednet.run()
		end,
		function()
			os.run( {}, "rom/programs/shell" )
		end
	)
end )

-- If the shell errored, let the user read it.
if not ok then
	print( err )
end

pcall( function()
	term.setCursorBlink( false )
	print( "Press any key to continue" )
	os.pullEvent( "key" ) 
end )
os.shutdown()
