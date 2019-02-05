/*
 * BENCH_BUILD_CMD:mono-csc solve.cs
 * BENCH_INVOKE_CMD:./solve.exe ./dict.txt
 * BENCH_VERSION_CMD:mono --version | awk '{print $5;exit}'
 */
using System;
using System.Collections.Generic;
using System.Linq;
using System.IO;

namespace solve {

class DictionaryNode {
	bool _finished = false;
	Dictionary<char, DictionaryNode> _next = new Dictionary<char, DictionaryNode>();

	public void AddSuffix( string suffix_ ) {
		if ( suffix_.Length == 0 ) {
			_finished = true;
		} else {
			char ch = suffix_[0];
			if ( ! _next.ContainsKey( ch ) ) {
				_next[ch] = new DictionaryNode();
			}
			_next[ch].AddSuffix( suffix_.Substring( 1 ) );
		}
	}

	public DictionaryNode Get( char char_ ) {
		DictionaryNode n = null;
		_next.TryGetValue( char_, out n );
		return ( n );
	}

	public bool Finished {
		get { return _finished; }
	}

	public void PrintAll( string prefix_ = "" ) {
		if ( _finished ) {
			Console.WriteLine( prefix_ );
		}
		foreach ( KeyValuePair<char, DictionaryNode> tail in _next ) {
			tail.Value.PrintAll( prefix_ + tail.Key );
		}
	}
}

class Cube {
	char _letter = '\0';
	bool _visited = false;
	List<Cube> _neighbors = new List<Cube>();

	public Cube( char letter_ ) {
		_letter = letter_;
	}

	public List<Cube> Neighbors {
		get { return _neighbors; }
	}

	public char Letter {
		get { return _letter; }
	}

	public bool Visited {
		get { return _visited; }
		set { _visited = value; }
	}
}

class Board {
	List<Cube> _cubes = new List<Cube>();
	int _size = 0;

	public Board( string letters_ ) {
		int len = (int)Math.Sqrt( letters_.Length );
		if ( len * len != letters_.Length ) {
			throw new Exception( "Bad board definition!" );
		}
		_size = len;
		foreach ( char l in letters_ ) {
			_cubes.Add( new Cube( l ) );
		}
		int[][] deltas = new int[][]{
			new int[]{ -1, -1 },
			new int[]{ -1, 0 },
			new int[]{ -1, 1 },
			new int[]{ 0, -1 },
			new int[]{ 0, 1 },
			new int[]{ 1, -1 },
			new int[]{ 1, 0 },
			new int[]{ 1, 1 }
		};
		foreach ( int x in Enumerable.Range( 0, len ) ) {
			foreach ( int y in Enumerable.Range( 0, len ) ) {
				foreach ( int[] d in deltas ) {
					int nx = x + d[0];
					int ny = y + d[1];
					if ( ( nx >= 0 ) && ( nx < len ) && ( ny >= 0 ) && ( ny < len ) ) {
						GetCube( x, y ).Neighbors.Add( GetCube( nx, ny ) );
					}
				}
			}
		}
	}

	Cube GetCube( int x_, int y_ ) {
		return ( _cubes[y_ * _size + x_] );
	}

	public List<string> Solve( DictionaryNode dictionary_ ) {
		HashSet<string> result = new HashSet<string>();
		foreach ( Cube cube in _cubes ) {
			SolveRecursive( result, "", cube, dictionary_ );
		}
		List<string> sorted = new List<string>( result );
		return ( sorted.OrderBy( o => o.Length ).ToList() );
	}

	void SolveRecursive( HashSet<string> result_, string prefix_, Cube cube_, DictionaryNode dictNode_ ) {
		DictionaryNode nextNode = dictNode_.Get( cube_.Letter );
		if ( nextNode == null ) {
			return;
		}
		cube_.Visited = true;
		string newPrefix = prefix_ + cube_.Letter;
		if ( nextNode.Finished && ( newPrefix.Length >= 3 ) ) {
			result_.Add( newPrefix );
		}
		foreach ( Cube neighbor in cube_.Neighbors ) {
			if ( ! neighbor.Visited ) {
				SolveRecursive( result_, newPrefix, neighbor, nextNode );
			}
		}
		cube_.Visited = false;
	}
}

class MainClass {
	public static void Main( string[] args ) {
		if ( args.Length > 0 ) {
			TextReader dictFile = new StreamReader( args[0] );
			DictionaryNode dictionaryRoot = new DictionaryNode();
			string line;
			while ( ( line = dictFile.ReadLine() ) != null ) {
				dictionaryRoot.AddSuffix( line );
			}
//			dictionaryRoot.PrintAll();
			Console.WriteLine( "[ OK ] Ready" );
			string letters = "";
			while ( ( line = Console.ReadLine() ) != null ) {
				if ( ( letters.Length > 0 ) && ( line.Length == 0 ) ) {
					Console.WriteLine( "[ OK ] Solving" );
					try {
						Board board = new Board( letters );
						foreach ( string word in board.Solve( dictionaryRoot ) ) {
							Console.WriteLine( "(" + word.Length + ") " + word + "" );
						}
						Console.WriteLine( "[ OK ] Solved" );
					} catch ( Exception e ) {
						Console.WriteLine( e.Message );
					}
					letters = "";
				} else {
					letters += line;
				}
			}
		} else {
			Console.WriteLine( "solve, error: please specify path." );
		}
	}
}

}

/* vim: set ft=cs: */
