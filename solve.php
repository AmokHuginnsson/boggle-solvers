#! /bin/sh
#<?php /*
exec php "${0}" "${@}"

BENCH_INVOKE_CMD:./solve.php dict.txt
BENCH_VERSION_CMD:php --version | awk '{print $2;exit}'
#*/

function array_get( $dict, $key, $default = null ) {
	return ( array_key_exists( $key, $dict ) ? $dict[$key] : $default );
}

class DictionaryNode {
	public $_finished = false;
	public $_next = array();

	function add_suffix( $suffix_ ) {
		if ( strlen( $suffix_ ) == 0 ) {
			$this->_finished = true;
		} else {
			$char = $suffix_[0];
			if ( ! array_key_exists( $char, $this->_next ) ) {
				$this->_next[$char] = new DictionaryNode();
			}
			$this->_next[$char]->add_suffix( substr( $suffix_, 1 ) );
		}
	}

	function get( $char_ ) {
		return ( array_get( $this->_next, $char_, null ) );
	}

	function print_all( $prefix_ = "" ) {
		if ( $this->_finished ) {
			print( $prefix_ );
		}
		foreach ( $this->_next as $char => $tail ) {
			$tail->print_all( $prefix_ . $char );
		}
	}
}

class Cube {
	public $_letter = null;
	public $_visited = false;
	public $_neighbors = [];
	function __construct( $letter_ ) {
		$this->_letter = $letter_;
	}
}

class Board {
	public $_cubes = null;
	public $_size = 0;
	function __construct( $letters_ ) {
		$len = intval( sqrt( floatval( strlen( $letters_ ) ) ) );
		$len2 = $len * $len;
		assert( $len2 == strlen( $letters_ ) );
		$this->_size = $len;
		$this->_cubes = [];
		for ( $i = 0; $i < $len2; ++ $i ) {
			array_push( $this->_cubes, new Cube( $letters_[$i] ) );
		}
		$deltas = [[-1,-1], [-1,0], [-1,1], [0,-1], [0,1], [1,-1], [1,0], [1,1]];
		for ( $x = 0; $x < $len; ++ $x ) {
			for ( $y = 0; $y < $len; ++ $y ) {
				foreach ( $deltas as $d ) {
					$nx = $x + $d[0];
					$ny = $y + $d[1];
					if ( ( $nx >= 0 ) && ( $nx < $len ) && ( $ny >= 0 ) && ( $ny < $len ) ) {
						array_push( $this->get_cube( $x, $y )->_neighbors, $this->get_cube( $nx, $ny ) );
					}
				}
			}
		}
	}

	function get_cube( $x_, $y_ ) {
		return ( $this->_cubes[$y_ * $this->_size + $x_] );
	}

	function solve( $dictionary_ ) {
		$result = [];
		foreach ( $this->_cubes as $cube ) {
			$this->solve_recursive( $result, "", $cube, $dictionary_ );
		}
		$result = array_unique( $result );
		usort(
			$result,
			function( $a, $b ) {
				return ( strlen( $a ) - strlen( $b ) );
			}
		);
		return ( $result );
	}

	function solve_recursive( &$result, $prefix_, $cube_, $dictNode_ ) {
		$nextNode = $dictNode_->get( $cube_->_letter );
		if ( $nextNode == null ) {
			return;
		}
		$cube_->_visited = true;
		$newPrefix = $prefix_ . $cube_->_letter;
		if ( $nextNode->_finished && ( strlen( $newPrefix ) >= 3 ) ) {
			array_push( $result, $newPrefix );
		}
		foreach ( $cube_->_neighbors as $neighbor ) {
			if ( ! $neighbor->_visited ) {
				$this->solve_recursive( $result, $newPrefix, $neighbor, $nextNode );
			}
		}
		$cube_->_visited = false;
	}
}

function main( $argv ) {
	$dictionaryRoot = new DictionaryNode();
	$dictFile = fopen( $argv[1], "r" );
	while ( ( $line = fgets( $dictFile ) ) !== false ) {
		$dictionaryRoot->add_suffix( trim( $line ) );
	}
	fclose( $dictFile );
	print( "[ OK ] Ready\n" );
	$letters = "";
	while ( true ) {
		$line = fgets( STDIN );
		if ( strlen( $line ) == 0 ) {
			break;
		}
		$line = trim( $line );
		if ( ( strlen( $letters ) > 0 ) && ( strlen( $line ) == 0 ) ) {
			print( "[ OK ] Solving\n" );
			$board = new Board( $letters );
			foreach ( $board->solve( $dictionaryRoot ) as $word ) {
				print( "(" . strlen( $word ) . ") " . $word . "\n" );
			}
			print( "[ OK ] Solved\n" );
			$letters = "";
		} else {
			$letters = $letters . $line;
		}
	}
	return ( 0 );
}

main( $argv );

/* vim: set ft=php: */
?>
