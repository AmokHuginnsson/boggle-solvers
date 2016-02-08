#! /bin/sh
//bin/true \
/*
exec nodejs --harmony "${0}" "${@}"
exec rhino -version 170 "${0}" "${0}" "${@}"
Very ugly hack to spawn nodejs/rhino from ${PATH}.
*/

/* initalize for node.js/rhino compatibility */
var ARGV = arguments
if ( typeof ( print ) === "undefined" ) {
	print = console.log
}
var openFile = null
var readLine = null
var stdIn = null
if ( typeof ( process ) !== "undefined" ) { /* nodejs */
	ARGV = process.argv.splice( 1 )
//	var iconv = require( "iconv" ).Iconv
	var fs = require( "fs" )
	var bufferSize = 1024
	openFile = function( path_ ) {
		return ( { fd: fs.openSync( path_, "r" ), buffer: new Buffer( bufferSize ), leftOver: "" } )
	}
	stdIn = function() {
		if ( this.fd === undefined ) {
			this.fd = openFile( "/dev/stdin" )
		}
		return ( this.fd )
	}
	readLine = function( fd ) {
		if ( fd.leftOver === null ) {
			fd.leftOver = ""
		}
		while ( true ) {
			var read = 0
			var idx = 0
			if ( ( idx = fd.leftOver.indexOf( "\n", 0 ) ) !== -1 ) {
				var line = fd.leftOver.substring( 0, idx )
				fd.leftOver = fd.leftOver.substring( idx + 1 )
				return ( line )
			} else if ( ( read = fs.readSync( fd.fd, fd.buffer, 0, bufferSize, null ) ) === 0 ) {
				break;
			} else if ( read > 0 ) {
				fd.leftOver += fd.buffer.toString( undefined, 0, read )
			}
		}
		if ( fd.leftOver.length == 0 ) {
			fd.leftOver = null
		}
		return ( fd.leftOver )
	}
} else { /* rhino */
	openFile = function( path_ ) {
		return ( new java.io.BufferedReader( new java.io.FileReader( path_ ) ) )
	}
	stdIn = function() {
		if ( this.fd === undefined ) {
			this.fd = new java.io.BufferedReader( new java.io.InputStreamReader( java.lang.System.in ) )
		}
		return ( this.fd )
	}
	readLine = function( fd ) {
		return ( fd.readLine() )
	}
}

function DictionaryNode() {
	this._finished = false
	this._next = {}
}

DictionaryNode.prototype.add_suffix = function( suffix_ ) {
	if ( suffix_.length == 0 ) {
		this._finished = true;
	} else {
		var char = suffix_[0];
		if ( ! ( char in this._next ) ) {
			this._next[char] = new DictionaryNode();
		}
		this._next[char].add_suffix( suffix_.substring( 1 ) );
	}
}

DictionaryNode.prototype.get = function( char_ ) {
	return ( char_ in this._next ? this._next[char_] : null );
}

DictionaryNode.prototype.print_all = function( prefix_ ) {
	if ( prefix_ === undefined ) {
		prefix_ = ""
	}
	if ( this._finished ) {
		print( prefix_ );
	}
	for ( var char in this._next ) {
		this._next[char].print_all( prefix_ + char )
	}
}

function assert( condition, message ) {
	if ( ! condition ) {
		throw ( message )
	}
}

function Cube( letter_ ) {
	this._letter = letter_
	this._visited = false
	this._neighbors = []
}

function Board( letters_ ) {
	var len = Math.round( Math.sqrt( letters_.length ) )
	assert( len * len == letters_.length, "Bad cube definition" )
	this._size = len
	this._cubes = []
	for ( var l of letters_ ) {
		this._cubes.push( new Cube( l ) )
	}
	var deltas = [[-1,-1], [-1,0], [-1,1], [0,-1], [0,1], [1,-1], [1,0], [1,1]]
	for ( var x = 0; x < len; ++ x ) {
		for ( var y = 0; y < len; ++ y ) {
			for ( var d of deltas ) {
				var nx = x + d[0];
				var ny = y + d[1];
				if ( ( nx >= 0 ) && ( nx < len ) && ( ny >= 0 ) && ( ny < len ) ) {
					this.get_cube( x, y )._neighbors.push( this.get_cube( nx, ny ) );
				}
			}
		}
	}
}

Board.prototype.get_cube = function( x_, y_ ) {
	return ( this._cubes[y_ * this._size + x_] )
}

Board.prototype.solve = function( dictionary_ ) {
	var result = new Set()
	for ( var cube of this._cubes ) {
		this.solve_recursive( result, "", cube, dictionary_ )
	}
	return ( Array.from( result ).sort( function( a, b ) { return ( a.length >= b.length ) } ) )
}

Board.prototype.solve_recursive = function( result, prefix_, cube_, dictNode_ ) {
	var nextNode = dictNode_.get( cube_._letter );
	if ( nextNode == null ) {
		return;
	}
	cube_._visited = true
	var newPrefix = prefix_ + cube_._letter;
	if ( nextNode._finished && ( newPrefix.length >= 3 ) ) {
		result.add( newPrefix );
	}
	for ( var neighbor of cube_._neighbors ) {
		if ( ! neighbor._visited ) {
			this.solve_recursive( result, newPrefix, neighbor, nextNode )
		}
	}
	cube_._visited = false
}

function main( argv_ ) {
	p = openFile( argv_[1] )
	dictionaryRoot = new DictionaryNode()
	while ( ( line = readLine( p ) ) != null ) {
		dictionaryRoot.add_suffix( line )
	}
//	dictionaryRoot.print_all()
	print( "[ OK ] Ready" );
	var letters = ""
	while ( ( line = readLine( stdIn() ) ) !== null ) {
		if ( ( letters.length > 0 ) && ( line.length == 0 ) ) {
			print( "[ OK ] Solving" )
			var board = new Board( letters )
			for ( var word of board.solve( dictionaryRoot ) ) {
				print( "(" + word.length + ") " + word )
			}
			print( "[ OK ] Solved" )
			letters = ""
		} else {
			letters = letters + line
		}
	}
	return ( 0 )
}

main( ARGV )

/* vim: set ft=javascript: */
