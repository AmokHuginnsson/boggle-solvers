#!/usr/bin/python2

# Credits:
# Algorithm design and implementation by
# Marcin Sulikowski (@marcinsulikowski)

from __future__ import print_function
from __future__ import division
import codecs
import math
import sys
import traceback


class DictionaryNode(object):
	__slots__ = ['finished', '_next']

	def __init__(self):
		self.finished = False
		self._next = {}

	def add_suffix(self, suffix):
		if not suffix:
			self.finished = True
		else:
			char = suffix[0]
			if not char in self._next:
				self._next[char] = DictionaryNode()
			self._next[char].add_suffix(suffix[1:])

	def get(self, char):
		return self._next.get(char, None)

	def print_all(self, prefix=""):
		if self.finished:
			print(prefix)
		for char in self._next:
			self._next[char].print_all(prefix + char)


class Board(object):
	class Cube(object):
		def __init__(self, letter):
			self.letter = letter
			self.visited = False
			self.neighbors = []

	def __init__(self, letters):
		size = int(math.sqrt(len(letters)))
		assert size * size == len(letters)
		self._size = size
		self._cubes = [self.Cube(l) for l in letters]
		deltas = [(-1,-1),(-1,0),(-1,1),(0,-1),(0,1),(1,-1),(1,0),(1,1)]
		for x in range(size):
			for y in range(size):
				for (dx, dy) in deltas:
					nx, ny = x + dx, y + dy
					if nx >= 0 and nx < size and ny >= 0 and ny < size:
						self.get_cube(x, y).neighbors.append(self.get_cube(nx, ny))

	def get_cube(self, x, y):
		return self._cubes[y * self._size + x]

	def solve(self, dictionary):
		result = set()
		for cube in self._cubes:
			self._solve_recursive(result, "", cube, dictionary)
		return sorted(result, key=len)

	def _solve_recursive(self, result, prefix, cube, dict_node):
		next_node = dict_node.get(cube.letter)
		if next_node is None:
			return
		cube.visited = True
		new_prefix = prefix + cube.letter
		if next_node.finished and len(new_prefix) >= 3:
			result.add(new_prefix)
		for neighbor in cube.neighbors:
			if not neighbor.visited:
				self._solve_recursive(result, new_prefix, neighbor, next_node)
		cube.visited = False


def main():
	dictionary_root = DictionaryNode()
	with codecs.open(sys.argv[1], encoding="latin2") as dict_file:
		for line in dict_file:
			dictionary_root.add_suffix(line.strip())
	print('[ OK ] Ready', file=sys.stderr)
	letters = ''
	while True:
		line = sys.stdin.readline()
		if not line:
			break
		line = line.strip()
		if letters and not line:
			print('[ OK ] Solving', file=sys.stderr)
			try:
				board = Board(unicode(letters, encoding='utf-8'))
				for word in board.solve(dictionary_root):
					print(u'({}) {}'.format(len(word), word))
				print('[ OK ] Solved', file=sys.stderr)
			except Exception as e:
				print('[FAIL] {}:\n{}'.format(e, traceback.format_exc()))
			letters = ''
		else:
			letters = letters + line


if __name__ == '__main__':
	main()

# vim: ft=python
