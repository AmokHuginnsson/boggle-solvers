#! /bin/sh
#=
exec julia -O "${0}" "${@}"
=#

import Base.get

type DictionaryNode
	_finished::Bool
	_next::Dict{ Char, DictionaryNode }
	DictionaryNode() = new( false, Dict{ Char, DictionaryNode }() )
end

function add_suffix( dictionaryNode::DictionaryNode, suffix_::AbstractString )
	if length( suffix_ ) == 0
		dictionaryNode._finished = true
	else
		ch = suffix_[1]
		if ! haskey( dictionaryNode._next, ch )
			dictionaryNode._next[ch] = DictionaryNode()
		end
		add_suffix( dictionaryNode._next[ch], suffix_[2:end] )
	end
end

function get( dictionaryNode::DictionaryNode, ch::Char )
	return get( dictionaryNode._next, ch, nothing )
end

function print_all( dictionaryNode::DictionaryNode, prefix_::AbstractString = "" )
	if dictionaryNode._finished
		print( prefix_ * "\n" );
	end
	for ch in dictionaryNode._next
		print_all( ch[2], prefix_ * string( ch[1] ) );
	end
end

type Cube
	_letter::Char
	_visited::Bool
	_neighbors::Array
	Cube( letter_ ) = new( letter_, false, [] )
end

type Board
	_cubes::Array
	_size::Int
	function Board( letters_::AbstractString )
		len = Int( floor( sqrt( length( letters_ ) ) ) )
		if ( len * len ) != length( letters_ )
			throw( ErrorException( "Bad board definition!" ) )
		end
		cubes = []
		for l in letters_
			push!( cubes, Cube( l ) )
		end
		deltas = ( ( -1, -1 ), ( -1, 0 ), ( -1, 1 ), ( 0, -1 ), ( 0, 1 ), ( 1, -1 ), ( 1, 0 ), ( 1, 1 ) )
		board = new( cubes, len )
		for x in 0:len - 1
			for y in 0:len - 1
				for d in deltas
					nx = x + d[1]
					ny = y + d[2]
					if ( nx >= 0 ) && ( nx < len ) && ( ny >= 0 ) && ( ny < len )
						push!( get_cube( board, x, y )._neighbors, get_cube( board, nx, ny ) )
					end
				end
			end
		end
		return board
	end
	function get_cube( board_::Board, x_::Int, y_::Int )
		return board_._cubes[y_ * board_._size + x_ + 1]
	end
end

function solve_recursive( board_::Board, result_::Set, prefix_::AbstractString, cube_::Cube, dictNode_::DictionaryNode )
	nextNode = get( dictNode_, cube_._letter )
	if nextNode == nothing
		return
	end
	cube_._visited = true
	newPrefix = prefix_ * string( cube_._letter )
	if nextNode._finished && ( length( newPrefix ) >= 3 )
		push!( result_, newPrefix )
	end
	for neighbor in cube_._neighbors
		if ! neighbor._visited
			solve_recursive( board_, result_, newPrefix, neighbor, nextNode );
		end
	end
	cube_._visited = false
end

function solve( board_::Board, dictionary_::DictionaryNode )
	result = Set()
	for cube in board_._cubes
		solve_recursive( board_, result, "", cube, dictionary_ );
	end
	return sort( collect( result ), by = length )
end

function main( argv_ )
	f = open( argv_[1] )
	dictionaryRoot = DictionaryNode()
	for line in eachline( f )
		add_suffix( dictionaryRoot, utf16( strip( line ) ) )
	end
#	print_all( dictionaryRoot )
	print( "[ OK ] Ready\n" );
	letters = "";
	while length(( line = readline(); )) > 0
		line = strip( line )
		if ( length( letters ) > 0 ) && ( length( line ) == 0 )
			print( "[ OK ] Solving\n" )
			try
				board = Board( letters )
				for word in solve( board, dictionaryRoot )
					print( "(" * string( length( word ) ) * ") " * word * "\n" );
				end
				print( "[ OK ] Solved\n" )
			catch e
				if isa( e, ErrorException )
					print( e.msg *  "\n" )
				else
					throw( e )
				end
			end
		else
			letters *= line;
		end
	end
end

main( ARGS )

