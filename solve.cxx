#include <yaal/hcore/harray.hxx>
#include <yaal/hcore/hmap.hxx>
#include <yaal/hcore/hhashmap.hxx>
#include <yaal/hcore/math.hxx>
#include <yaal/hcore/hset.hxx>
#include <yaal/hcore/hstring.hxx>
#include <yaal/hcore/hfile.hxx>
#include <yaal/tools/hstringstream.hxx>

using namespace yaal;
using namespace yaal::hcore;
using namespace yaal::tools;

class DictionaryNode {
public:
	typedef HHashMap<code_point_t, DictionaryNode> tails_t;
private:
	bool _isWordFinished;
	tails_t _next;
public:
	DictionaryNode()
		: _isWordFinished( false )
		, _next() {
	}

	void addSuffix( yaal::hcore::HString const& suffix, int start = 0 ) {
		if ( start >= suffix.get_length() ) {
			_isWordFinished = true;
		} else {
			_next[suffix[start]].addSuffix( suffix, start + 1 );
		}
		return;
	}

	DictionaryNode const* get( code_point_t c ) const {
		tails_t::const_iterator it( _next.find( c ) );
		return ( it != _next.end() ? &(it->second) : nullptr );
	}

	bool isWordFinished() const {
		return ( _isWordFinished );
	}
};

class Board {
	struct Cube {
		typedef yaal::hcore::HArray<Cube const*> neighbors_t;
		const yaal::code_point_t _letter;
		neighbors_t _neighbors;
		mutable bool _visited;
		Cube( code_point_t letter_ )
			: _letter( letter_ )
			, _neighbors()
			, _visited( false ) {
		}
	};
public:
	typedef yaal::hcore::HArray<Cube> cubes_t;
	typedef yaal::hcore::HArray<yaal::hcore::HString> results_t;
	typedef yaal::hcore::HSet<yaal::hcore::HString> words_t;
private:
	int _size;
	cubes_t _cubes;
public:
	Board( yaal::hcore::HString const& board )
		: _size( 0 )
		, _cubes() {
		for ( code_point_t letter : board ) {
			if ( letter != '\n' ) {
				_cubes.emplace_back( letter );
			}
		}
		_size = math::square_root( _cubes.size() );
		if (_size * _size != (int)_cubes.size()) {
			throw std::runtime_error("board is not a square");
		}
		typedef yaal::hcore::HPair<int, int> direction_t;
		typedef yaal::hcore::HArray<direction_t> directions_t;
		static directions_t const neighborhood{
			{ -1, -1 }, { -1, 0 }, { -1, 1 }, { 0, -1 }, { 0, 1 }, { 1, -1 }, { 1, 0 }, { 1, 1 }
		};
		for (int y = 0; y < _size; ++y) {
			for (int x = 0; x < _size; ++x) {
				for (auto&& delta : neighborhood) {
					int nx = x + delta.first, ny = y + delta.second;
					if (nx >= 0 && nx < _size && ny >= 0 && ny < _size) {
						getCube(x, y)._neighbors.push_back(&getCube(nx, ny));
					}
				}
			}
		}
	}

	yaal::hcore::HString print( void ) const {
		HStringStream out;
		for (int y = 0; y < _size; ++y) {
			for (int x = 0; x < _size; ++x) {
				out << "+---";
			}
			out << "\n";
			for (int x = 0; x < _size; ++x) {
				out << "| " << getCube(x, y)._letter << " ";
			}
			out << "\n";
		}
		return out.str();
	}

	results_t solve( DictionaryNode const* dictionary ) const {
		words_t words;
		for ( Cube const& cube : _cubes ) {
			HString word;
			solve( words, word, cube, dictionary );
		}
		results_t sorted( words.begin(), words.end() );
		yaal::sort(
			sorted.begin(),
			sorted.end(),
			[]( yaal::hcore::HString const& left_, yaal::hcore::HString const right ) {
				return ( left_.get_size() < right.get_size() );
			}
		);
		return ( sorted );
	}

private:
	Cube& getCube( int x, int y ) {
		return _cubes[y * _size + x];
	}

	const Cube& getCube( int x, int y ) const {
		return _cubes[y * _size + x];
	}

	void solve(
		words_t& ret, yaal::hcore::HString& word,
		Cube const& cube, DictionaryNode const* node
	) const {
		DictionaryNode const* next( node->get( cube._letter ) );
		if ( next == nullptr ) {
			return;
		}
		cube._visited = true;
		word.push_back( cube._letter );
		if ( next->isWordFinished() && word.get_size() >= 3 ) {
			ret.insert( word );
		}
		for (auto neighbor : cube._neighbors) {
			if ( !neighbor->_visited ) {
				solve( ret, word, *neighbor, next );
			}
		}
		word.pop_back();
		cube._visited = false;
	}
};

int main( int argc_, char** argv_ ) {
	int wordCount = 0;
	DictionaryNode dictionaryRoot;
	try {
		HFile dictFile( argc_ > 1 ? argv_[1] : "/usr/share/dict/words", HFile::OPEN::READING );
		HString line;
		while ( dictFile.read_line( line, HFile::READ::BUFFERED_READS ).good() ) {
			dictionaryRoot.addSuffix( line );
			++ wordCount;
		}
		dictFile.close();
		cerr << "[ OK ] Ready (" << wordCount << " words loaded)" << endl;
	} catch ( HException const& ex ) {
		cerr << "[FAIL] Reading dictionary failed at line " << wordCount << ", with an error:" << ex.what() << endl;
		return 1;
	}

	HString line, boardString;
	HFile in( stdin, HFile::OWNERSHIP::EXTERNAL );
	while ( in.read_line( line, HFile::READ::UNBUFFERED_READS ).good() ) {
		if ( line.is_empty() && !boardString.is_empty() ) {
			try {
				Board board( boardString );
				cerr << "[ OK ] Solving:\n" << board.print() << endl;
				for ( Board::results_t::value_type const& w : board.solve( &dictionaryRoot ) ) {
					cout << "(" << w.size() << ") " << w << endl;
				}
				cerr << "[ OK ] Solved" << endl;
			} catch ( yaal::hcore::HException const& ex ) {
				cerr << "[FAIL] Can't solve board: " << ex.what() << endl;
			}
			boardString.clear();
		} else {
			boardString.append( line );
		}
	}
	return 0;
}

/* vim: set ft=cpp: */
