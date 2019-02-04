/*
 * BENCH_BUILD_CMD:javac solve.java
 * BENCH_INVOKE_CMD:java solve ./dict.txt
 * BENCH_VERSION_CMD:java -version 2>&1 | awk '{print $3;exit}'
 */

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.io.BufferedReader;
import java.io.FileReader;
import java.io.InputStreamReader;

class Node {
	public boolean _finished = false;
	private HashMap<Character, Node> _next = new HashMap<Character, Node>();
	public void addSuffix( String suffix_ ) {
		if ( suffix_.isEmpty() ) {
			_finished = true;
		} else {
			char c = suffix_.charAt( 0 );
			Node n = _next.get( c );
			if ( n == null ) {
				n = new Node();
				_next.put( c, n );
			}
			n.addSuffix( suffix_.substring( 1 ) );
		}
	}

	Node get( char c_ ) {
		return ( _next.get( c_ ) );
	}

	void printAll( String prefix_ ) {
		if ( _finished ) {
			System.out.println( prefix_ );
		}
		for ( Map.Entry<Character, Node> n : _next.entrySet() ) {
			n.getValue().printAll( prefix_ + n.getKey() );
		}
	}
}

class Cube {
	public char _letter = 0;
	public boolean _visited = false;
	public ArrayList<Cube> _neighbors = new ArrayList<Cube>();
	Cube( char letter_ ) {
		_letter = letter_;
	}
}

class Board {
	private ArrayList<Cube> _cubes = new ArrayList<Cube>();
	private int _size = 0;
	public Board( String letters_ ) {
		int len = (int)Math.sqrt( (float)letters_.length() );
		assert( len * len == letters_.length() );
		_size = len;
		for ( char l : letters_.toCharArray() ) {
			_cubes.add( new Cube( l ) );
		}
		int[][] deltas = new int[][]{ { -1,-1 }, { -1,0 }, { -1,1 }, { 0,-1 }, { 0,1 }, { 1,-1 }, { 1,0 }, { 1,1 } };
		for ( int x = 0; x < len; ++ x ) {
			for ( int y = 0; y < len; ++ y ) {
				for ( int[] d : deltas ) {
					int nx = x + d[0];
					int ny = y + d[1];
					if ( ( nx >= 0 ) && ( nx < len ) && ( ny >= 0 ) && ( ny < len ) ) {
						get_cube( x, y )._neighbors.add( get_cube( nx, ny ) );
					}
				}
			}
		}
	}

	public Cube get_cube( int x_, int y_ ) {
		return ( _cubes.get( y_ * _size + x_ ) );
	}

	public ArrayList<String> solve( Node dictionary_ ) {
		HashSet<String> result = new HashSet<String>();
		for ( Cube cube : _cubes ) {
			solveRecursive( result, "", cube, dictionary_ );
		}
		ArrayList<String> resultSorted = new ArrayList<String>( result );
		java.util.Collections.sort(
			resultSorted,
			new java.util.Comparator<String>() {
				public int compare(String s1, String s2) {
					return s1.length() - s2.length();
		    }
			}
		);
		return ( resultSorted );
	}

	void solveRecursive( HashSet<String> result, String prefix_, Cube cube_, Node dictNode_ ) {
		Node nextNode = dictNode_.get( cube_._letter );
		if ( nextNode == null ) {
			return;
		}
		cube_._visited = true;
		String newPrefix = prefix_ + cube_._letter;
		if ( nextNode._finished && ( newPrefix.length() >= 3 ) ) {
			result.add( newPrefix );
		}
		for ( Cube neighbor : cube_._neighbors ) {
			if ( ! neighbor._visited ) {
				solveRecursive( result, newPrefix, neighbor, nextNode );
			}
		}
		cube_._visited = false;
	}
}

public class solve {
	void doSolve( String file_ ) throws java.io.FileNotFoundException, java.io.IOException {
		System.out.println( "[>] Loading dictionary from file: " + file_ );
		Node dictionaryRoot = new Node();
		try ( BufferedReader br = new BufferedReader( new FileReader( file_) ) ) {
			String line;
			while ( ( line = br.readLine() ) != null ) {
				dictionaryRoot.addSuffix( line );
			}
		}
//		dictionaryRoot.printAll( "" );
		System.out.println( "[ OK ] Ready" );
		BufferedReader br = new BufferedReader( new InputStreamReader( System.in ) );
		String letters = "";
		String line = null;
		while ( ( line = br.readLine() ) != null ) {
			line = line.trim();
			if ( ( letters.length() > 0 ) && ( line.length() == 0 ) ) {
				System.out.println( "[ OK ] Solving" );
				Board board = new Board( letters );
				for ( String word : board.solve( dictionaryRoot ) ) {
					System.out.println( "(" + word.length() + ") " + word );
				}
				System.out.println( "[ OK ] Solved" );
				letters = "";
			} else {
				letters = letters + line;
			}
		}
		return;
	}
	public static void main( String[] argv_ ) {
		System.out.println( "[>] Boggle solver" );
		try {
			solve s = new solve();
			if ( argv_.length != 1 ) {
				throw new RuntimeException( "Specify one argument which should be path to dictionary file." );
			}
			s.doSolve( argv_[0] );
		} catch ( Exception e ) {
			e.printStackTrace();
			System.exit( 1 );
		}
		return;
	}
}

/* vim: set ft=java: */
