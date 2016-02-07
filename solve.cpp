/*
 * Credits:
 * Algorithm design and implementation by
 * Marcin Sulikowski (@marcinsulikowski)
 */

#include <iconv.h>
#include <algorithm>
#include <fstream>
#include <iostream>
#include <map>
#include <unordered_map>
#include <set>
#include <sstream>
#include <vector>

template <typename K, typename V>
class sparse_map {
public:
	typedef std::pair<const K, V> value_type;
	typedef typename std::vector<value_type>::const_iterator const_iterator;
	typedef typename std::vector<value_type>::iterator iterator;

	const_iterator begin() const { return values_.begin(); }
	const_iterator end() const { return values_.end(); }
	iterator begin() { return values_.begin(); }
	iterator end() { return values_.end(); }

	iterator find(const K& key) {
		return std::find_if(begin(), end(), [&key](const value_type& value) {
			return value.first == key;
		});
	}

	const_iterator find(const K& key) const {
		return std::find_if(begin(), end(), [&key](const value_type& value) {
			return value.first == key;
		});
	}

	V& operator[](const K& key) {
		auto it = find(key);
		if (it != end()) {
			return it->second;
		} else {
			values_.emplace_back(key, V{});
			return values_.back().second;
		}
	}

private:
	std::vector<value_type> values_;
};

class Converter {
public:
	Converter(std::string from, std::string to) {
		cd_ = iconv_open(to.c_str(), from.c_str());
		if (cd_ == (iconv_t)-1) {
			throw std::runtime_error("Cannot convert from " + from + " to " + to);
		}
	}

	~Converter() {
		if (cd_ != (iconv_t)-1) {
			iconv_close(cd_);
		}
	}

	std::string convert(const std::string& inBuffer) const {
		char* inPtr = const_cast<char*>(inBuffer.data());
		size_t inBytes = inBuffer.size();

		std::vector<char> outBuffer(inBuffer.size() * 5, 0);
		char* outPtr = outBuffer.data();
		size_t outBytes = outBuffer.size();

		size_t ret = iconv(cd_, &inPtr, &inBytes, &outPtr, &outBytes);
		if (ret == (size_t)-1) {
			throw std::runtime_error("Cannot convert '" + inBuffer + "': iconv() == -1");
		} else if (inBytes != 0) {
			throw std::runtime_error("Cannot convert '" + inBuffer + "': output too long");
		}
		return std::string(outBuffer.data(), outPtr);
	}

private:
	iconv_t cd_;
};

class DictionaryNode {
public:
	DictionaryNode() : isWordFinished_(false) {}

	void addSuffix(const char* suffix) {
		char c = *suffix;
		if (c == '\0') {
			isWordFinished_ = true;
		} else {
			next_[c].addSuffix(suffix + 1);
		}
	}

	DictionaryNode const* get(char c) const {
		auto it = next_.find(c);
		return (it == next_.end() ? nullptr : &(it->second));
	}

	bool isWordFinished() const {
		return isWordFinished_;
	}

private:
	bool isWordFinished_;
	sparse_map<char, DictionaryNode> next_;
};

class Board {
public:
	Board(const std::string& board) {
		for (char letter : board) {
			if (letter != '\n') {
				cubes_.emplace_back(letter);
			}
		}
		size_ = sqrt(cubes_.size());
		if (size_ * size_ != (int)cubes_.size()) {
			throw std::runtime_error("board is not a square");
		}
		const std::vector<std::pair<int,int>> neighborhood{
			{-1,-1},{-1,0},{-1,1},{0,-1},{0,1},{1,-1},{1,0},{1,1}};
		for (int y = 0; y < size_; ++y) {
			for (int x = 0; x < size_; ++x) {
				for (auto&& delta : neighborhood) {
					int nx = x + delta.first, ny = y + delta.second;
					if (nx >= 0 && nx < size_ && ny >= 0 && ny < size_) {
						getCube(x, y).neighbors.push_back(&getCube(nx, ny));
					}
				}
			}
		}
	}

	std::string print() const {
		std::stringstream out;
		for (int y = 0; y < size_; ++y) {
			for (int x = 0; x < size_; ++x) {
				out << "+---";
			}
			out << "\n";
			for (int x = 0; x < size_; ++x) {
				out << "| " << getCube(x, y).letter << " ";
			}
			out << "\n";
		}
		return out.str();
	}

	std::vector<std::string> solve(const DictionaryNode* dictionary) const {
		std::set<std::string> words;
		for (auto& cube : cubes_) {
			std::string word;
			solve(words, word, cube, dictionary);
		}
		std::vector<std::string> sorted(words.begin(), words.end());
		std::stable_sort(sorted.begin(), sorted.end(), [](std::string a, std::string b) {
			return a.size() < b.size();
		});
		return sorted;
	}

private:
	struct Cube {
		Cube(char letter) : letter(letter), visited(false) {}

		const char letter;
		std::vector<const Cube*> neighbors;
		mutable bool visited;
	};

	Cube& getCube(int x, int y) {
		return cubes_[y * size_ + x];
	}

	const Cube& getCube(int x, int y) const {
		return cubes_[y * size_ + x];
	}

	void solve(std::set<std::string>& ret, std::string& word,
			const Cube& cube, const DictionaryNode* node) const {
		const DictionaryNode* next = node->get(cube.letter);
		if (next == nullptr) {
			return;
		}
		cube.visited = true;
		word.push_back(cube.letter);
		if (next->isWordFinished() && word.size() >= 3) {
			ret.insert(word);
		}
		for (auto neighbor : cube.neighbors) {
			if (!neighbor->visited) {
				solve(ret, word, *neighbor, next);
			}
		}
		word.pop_back();
		cube.visited = false;
	}

	int size_;
	std::vector<Cube> cubes_;
};

int main(int argc, char** argv) {
	int wordCount = 0;
	DictionaryNode dictionaryRoot;
	try {
		std::ifstream dictFile;
		dictFile.exceptions(std::ifstream::badbit | std::ifstream::failbit);
		dictFile.open(argc > 1 ? argv[1] : "/usr/share/dict/words");
		dictFile.exceptions(std::ifstream::badbit);
		std::string line;
		while (std::getline(dictFile, line)) {
			while (!line.empty() && (line.back() == '\n' || line.back() == '\r')) {
				line.pop_back();
			}
			dictionaryRoot.addSuffix(line.c_str());
			++wordCount;
		}
		dictFile.close();
		std::cerr << "[ OK ] Ready (" << wordCount << " words loaded)" << std::endl;
	} catch (std::exception& ex) {
		std::cerr << "[FAIL] Reading dictionary failed at line " << wordCount << std::endl;
		return 1;
	}

	std::string line, boardString;
	while (std::getline(std::cin, line)) {
		if (line.empty() && !boardString.empty()) {
			try {
				Converter utf2windows("utf-8", "windows-1250");
				Converter windows2utf("windows-1250", "utf-8");
				Board board(utf2windows.convert(boardString));
				std::cerr << "[ OK ] Solving:\n" << windows2utf.convert(board.print()) << std::endl;
				for (auto&& w : board.solve(&dictionaryRoot)) {
					std::cout << "(" << w.size() << ") " << windows2utf.convert(w) << std::endl;
				}
				std::cerr << "[ OK ] Solved" << std::endl;
			} catch (std::exception& ex) {
				std::cerr << "[FAIL] Can't solve board: " << ex.what() << std::endl;
			}
			boardString.clear();
		} else {
			boardString.append(line);
		}
	}
	return 0;
}

/* vim: set ft=cpp: */
