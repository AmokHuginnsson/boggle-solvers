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
				fd.leftOver += fd.buffer.toString( 'utf8' , 0, read )
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

function main( argv_ ) {
	p = openFile( argv_[1] )
	while ( ( line = readLine( p ) ) != null ) {
		print( line )
	}
	return ( 0 )
}

main( ARGV )

/* vim: set ft=javascript: */
