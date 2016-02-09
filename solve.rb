#! /bin/sh
exec ruby -w -x "${0}" "${@}"
#!ruby

require "set"

class DictionaryNode
	def initialize
		@finished = false
		@next = {}
	end

	def add_suffix( suffix_ )
		if ( suffix_.length == 0 )
			@finished = true
		else
			char = suffix_[0]
			if ( ! @next.key?( char ) )
				@next[char] = DictionaryNode.new
			end
			@next[char].add_suffix( suffix_[1..-1] )
		end
	end

	def get( char_ )
		return ( @next.fetch( char_, nil ) )
	end

	def print_all( prefix_ = "" )
		if ( @finished )
			puts( prefix_ )
		end
		@next.each_key do | char |
			@next[char].print_all( prefix_ + char )
		end
	end

	attr_reader :finished
end

class Cube
	def initialize( letter_ )
		@letter = letter_
		@visited = false
		@neighbors = []
	end
	attr_accessor :letter
	attr_accessor :neighbors
	attr_accessor :visited
end

class Board
	def initialize( letters_ )
		len = Math.sqrt( letters_.length ).round
		if ( len * len != letters_.length )
			raise "Bad board definition"
		end
		@size = len
		@cubes = []
		letters_.split( "" ).each do | l |
			@cubes.push( Cube.new( l ) )
		end
		deltas = [[-1,-1], [-1,0], [-1,1], [0,-1], [0,1], [1,-1], [1,0], [1,1]]
		( 0 .. len - 1 ).each do | x |
			( 0 .. len - 1 ).each do | y |
				deltas.each do | d |
					nx = x + d[0]
					ny = y + d[1]
					if ( ( nx >= 0 ) && ( nx < len ) && ( ny >= 0 ) && ( ny < len ) )
						get_cube( x, y ).neighbors.push( get_cube( nx, ny ) )
					end
				end
			end
		end
	end

	def get_cube( x_, y_ )
		return ( @cubes[y_ * @size + x_] )
	end

	def solve( dictionary_ )
		result = Set.new
		@cubes.each do | cube |
			solve_recursive( result, "", cube, dictionary_ )
		end
		return ( result.to_a.sort { | a, b | a.length <=> b.length } )
	end

	def solve_recursive( result, prefix_, cube_, dictNode_ )
		nextNode = dictNode_.get( cube_.letter )
		if ( nextNode == nil )
			return
		end
		cube_.visited = true
		newPrefix = prefix_ + cube_.letter
		if ( nextNode.finished && ( newPrefix.length >= 3 ) )
			result.add( newPrefix )
		end
		cube_.neighbors.each do | neighbor |
			if ( ! neighbor.visited )
				solve_recursive( result, newPrefix, neighbor, nextNode )
			end
		end
		cube_.visited = false
	end
end

def main( argv_ )
	dictionaryRoot = DictionaryNode.new
	File.open( argv_[1] ).each do | line |
		dictionaryRoot.add_suffix( line )
	end
#	dictionaryRoot.print_all
	puts( "[ OK ] Ready" )
	letters = "";
	while ( true )
		line = STDIN.gets()
		if ( line == nil )
			break
		end
		line = line.strip()
		if ( ( letters.length > 0 ) && ( line.length == 0 ) )
			puts( "[ OK ] Solving" )
			board = Board.new( letters )
			board.solve( dictionaryRoot ).each do | word |
				puts( "(" + word.length + ") " + word )
			end
			puts( "[ OK ] Solved" )
			letters = ""
		else
			letters += line
		end
	end
end

main( [$0] + ARGV )

# vim: set ft=ruby:
