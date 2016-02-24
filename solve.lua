#! /usr/bin/env lua

function ziter( a, i )
	i = i + 1
	local v = a[ i ]
	if v then
		return i, v
	end
end

function zpairs( a )
	return ziter, a, -1
end

function hs( h )
	local count = 0
	for k in pairs( h ) do
		count = count + 1
	end
	return count
end

DictionaryNode = {
	_finished = false,
}

function DictionaryNode:new()
	local o = { _next = {} }
	setmetatable( o, self )
	self.__index = self
	return o
end

function DictionaryNode:add_suffix( suffix_ )
	if suffix_:len() == 0 then
		self._finished = true
	else
		local char = suffix_:sub( 1, 1 )
		if self._next[ char ] == nil then
			self._next[ char ] = DictionaryNode:new()
		end
		self._next[ char ]:add_suffix( suffix_:sub( 2 ) )
	end
end

function DictionaryNode:get( char_ )
	return self._next[ char_ ]
end

function DictionaryNode:print_all( prefix_ )
	if prefix_ == nil then
		prefix_ = ""
	end
	if self._finished then
		print( prefix_ )
	end
	for char in pairs( self._next ) do
		self._next[ char ]:print_all( prefix_ .. char )
	end
end

Cube = {
	_visited = false
}

function Cube:new( letter_ )
	local o = { _neighbors = {}, _letter = letter_ }
	setmetatable( o, self )
	self.__index = self
	return o
end

Board = {
	_size = 0
}

function Board:get_cube( x_, y_ )
	return self._cubes[y_ * self._size + x_]
end

function Board:new( letters_ )
	local o = { _cubes = {} }
	setmetatable( o, self )
	self.__index = self
	local len = math.sqrt( letters_:len() )
	if len * len ~= letters_:len() then
		return nil
	end
	o._size = len
	for i = 1, #letters_ do
		o._cubes[i - 1] = Cube:new( letters_:sub( i, i ) )
	end
	local deltas = { { -1, -1 }, { -1, 0 }, { -1, 1 }, { 0, -1 }, { 0, 1 }, { 1, -1 }, { 1, 0 }, { 1, 1 } }
	for x = 0, len - 1 do
		for y = 0, len - 1 do
			for _, d in pairs( deltas ) do
				local nx = x + d[1]
				local ny = y + d[2]
				if ( nx >= 0 ) and ( nx < len ) and ( ny >= 0 ) and ( ny < len ) then
					c = o:get_cube( x, y )
					c._neighbors[#(c._neighbors) + 1] = o:get_cube( nx, ny )
				end
			end
		end
	end
	return o
end

function Board:solve( dictionary_ )
	local result = {}
	for _, cube in zpairs( self._cubes ) do
		self:solve_recursive( result, "", cube, dictionary_ )
	end
	local sorted = {}
	for word in pairs( result ) do
		sorted[#sorted + 1] = word
	end
	table.sort(
		sorted,
		function( a, b )
			return a:len() < b:len()
		end
	)
	return sorted
end

function Board:solve_recursive( result, prefix_, cube_, dictNode_ )
	local nextNode = dictNode_:get( cube_._letter )
	if nextNode == nil then
		return
	end
	cube_._visited = true
	local newPrefix = prefix_ .. cube_._letter
	if nextNode._finished and ( newPrefix:len() >= 3 ) then
		result[ newPrefix ] = true
	end
	for _, neighbor in pairs( cube_._neighbors ) do
		if not neighbor._visited then
			self:solve_recursive( result, newPrefix, neighbor, nextNode )
		end
	end
	cube_._visited = false
end

function main( argv_ )
	local dictionaryRoot = DictionaryNode:new()
	local dictFile = io.open( argv_[1], "r" )
	for line in dictFile:lines() do
		dictionaryRoot:add_suffix( line )
	end
	dictFile:close()
--	dictionaryRoot:print_all()
	print( "[ OK ] Ready" )
	local letters = ""
	while ( true ) do
		line = io.read()
		if line == nil then
			break;
		end
		if ( letters:len() > 0 ) and ( line:len() == 0 ) then
			print( "[ OK ] Solving" )
			board = Board:new( letters )
			if board ~= nil then
				for _, word in pairs( board:solve( dictionaryRoot ) ) do
					print( "(" .. word:len() .. ") " .. word )
				end
				print( "[ OK ] Solved" )
			else
				print( "Bad board definition!" )
			end
			letters = "";
		else
			letters = letters .. line
		end
	end
	return ( 0 );
end

main( arg )

-- vim: set ft=lua:
