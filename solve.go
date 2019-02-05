/*
 * BENCH_BUILD_CMD:go build solve.go
 * BENCH_INVOKE_CMD:./solve ./dict.txt
 * BENCH_VERSION_CMD:go version | awk '{print $3}'
 */
package main

import "fmt"
import "os"
import "bufio"
import "math"
import "sort"
import "strings"

type DictionaryNode struct {
	_finished bool
	_next map[byte]*DictionaryNode
}

func NewDictionaryNode() *DictionaryNode {
	n := new( DictionaryNode )
	n._next = make( map[byte]*DictionaryNode )
	return ( n )
}

func ( node_ *DictionaryNode ) add_suffix( suffix_ string ) {
	if ( len( suffix_ ) == 0 ) {
		node_._finished = true
	} else {
		char := suffix_[0]
		_, hasTail := node_._next[char]
		if ( ! hasTail ) {
			node_._next[char] = NewDictionaryNode()
		}
		node_._next[char].add_suffix( suffix_[1:] )
	}
}

func ( node_ *DictionaryNode ) get( char_ byte ) *DictionaryNode {
	node, hasTail := node_._next[char_]
	if ( ! hasTail ) {
		node = nil
	}
	return ( node )
}

func ( node_ *DictionaryNode ) print_all( prefix_ string ) {
	if ( node_._finished ) {
		fmt.Printf( prefix_ + "\n" )
	}
	for char, tail := range node_._next {
		tail.print_all( prefix_ + string( char ) )
	}
}

type Cube struct {
	_letter byte
	_visited bool
	_neighbors []*Cube
}

func NewCube( letter_ byte ) *Cube {
	c := new( Cube )
	c._letter = letter_
	c._neighbors = make( []*Cube, 0 )
	return ( c )
}

type Board struct {
	_cubes []*Cube
	_size int
}

func NewBoard( letters_ string ) *Board {
	b := new( Board )
	size := int( math.Sqrt( float64( len( letters_ ) ) ) )
	if ( size * size != len( letters_ ) ) {
		return ( nil )
	}
	b._size = size
	b._cubes = make( []*Cube, 0 )
	for i := range letters_ {
		b._cubes = append( b._cubes, NewCube( letters_[i] ) )
	}

	deltas := [8][2]int{{-1, -1}, {-1, 0}, {-1, 1}, {0, -1}, {0, 1}, {1, -1}, {1, 0}, {1, 1}}
	for x := 0; x < size; x ++ {
		for y := 0; y < size; y ++ {
			for _, d := range deltas {
				nx := x + d[0]
				ny := y + d[1]
				if ( ( nx >= 0 ) && ( nx < size ) && ( ny >= 0 ) && ( ny < size ) ) {
					b.get_cube( x, y )._neighbors = append( b.get_cube( x, y )._neighbors, b.get_cube( nx, ny ) )
				}
			}
		}
	}
	return ( b )
}

func ( board_ *Board ) get_cube( x_ int, y_ int ) *Cube {
	return ( board_._cubes[y_ * board_._size + x_] );
}

type ByLength []string
func ( a ByLength ) Len() int {
	return ( len ( a ) )
}
func ( a ByLength ) Swap( i int, j int ) {
	a[i], a[j] = a[j], a[i]
}
func ( a ByLength ) Less( i int, j int ) bool {
	return ( len( a[i] ) < len( a[j] ) )
}

func ( board_ *Board ) solve( dictionary_ *DictionaryNode ) []string {
	result := make(map[string]bool);
	for _, cube := range board_._cubes {
		board_.solve_recursive( result, "", cube, dictionary_ );
	}
	var sorted []string
	for k := range result {
		sorted = append( sorted, k )
	}
	sort.Sort( ByLength( sorted ) )
	return ( sorted )
}

func ( board_ *Board ) solve_recursive( result map[string]bool, prefix_ string, cube_ *Cube, dictNode_ *DictionaryNode ) {
	nextNode := dictNode_.get( cube_._letter );
	if ( nextNode == nil ) {
		return;
	}
	cube_._visited = true;
	newPrefix := prefix_ + string( cube_._letter );
	if ( nextNode._finished && ( len( newPrefix ) >= 3 ) ) {
		result[newPrefix] = true
	}
	for _, neighbor := range cube_._neighbors {
		if ( ! neighbor._visited ) {
			board_.solve_recursive( result, newPrefix, neighbor, nextNode );
		}
	}
	cube_._visited = false;
}

func main() {
	file, _ := os.Open( os.Args[1] )
	defer file.Close()

	scanner := bufio.NewScanner( file )
	dictionaryRoot := NewDictionaryNode()
	for scanner.Scan() {
		dictionaryRoot.add_suffix( scanner.Text() )
	}
//	dictionaryRoot.print_all( "" )

	fmt.Printf( "[ OK ] Ready\n" )

	input := bufio.NewReader( os.Stdin )
	letters := ""
	for {
		line, _ := input.ReadString( '\n' )
		if ( len( line ) == 0 ) {
			break;
		}
		line = strings.TrimSpace( line )
		if ( ( len( letters ) > 0 ) && ( len( line ) == 0 ) ) {
			fmt.Printf( "[ OK ] Solving\n" )
			board := NewBoard( letters )
			if ( board != nil ) {
				for _, word := range board.solve( dictionaryRoot ) {
					fmt.Printf( "(%d) %s\n", len( word ), word )
				}
				fmt.Printf( "[ OK ] Solved\n" )
			} else {
				fmt.Printf( "Bad board definition!\n" )
			}
			letters = ""
		} else {
			letters = letters + line
		}
	}
	return
}

/* vim: set ft=go: */
