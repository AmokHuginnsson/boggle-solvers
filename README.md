Language speed comparison
=========================

Language relative speed is assessed by measuring speed
of solving specific problem using specific algorithm
implemented with most natural (idiomatic) tools available
in given language.

The problem that is being solved by test programs
is building a *trie* (a prefix tree) for Polish language
dictionary \([gz][2], [bz2][3]\).

Most implementations use their respective hash-maps
to link prefixes with tails.

All tests runs were performed with tcmalloc preloaded
(if using it improved performance).

| Language   | Time (seconds) | Memory (KiB) | Run-time/Compiler version |
|------------|---------------:|-------------:|---------------------------|
| C++        |           1.59 |       657712 | GCC 8.2.0                 |
| C#         |           5.30 |       983968 | 4.2.1.0                   |
| Go         |           2.84 |       636828 | go1.10.4                  |
| [Huginn][1]|          33.01 |      1734512 | (HEAD)                    |
| Java       |           2.90 |      1265092 | Oracle Java 1.7.0         |
| JavaScript |           4.42 |       498268 | NodeJS 8.11.4             |
| Julia ☠    |          11.10 |      3341924 | 0.4.7                     |
| Lua        |          22.80 |      1526640 | 5.2.4                     |
| LuaJit     |          10.30 |      1061976 | 2.1.0                     |
| Perl       |          67.16 |      1928180 | 5.28.0                    |
| PHP        |          92.86 |      1721828 | 7.2.7                     |
| Python     |          18.73 |      1376724 | 3.7.1                     |
| Ruby       |          18.51 |      1161348 | 2.5.1p57                  |

Dictionary loaded contains 2709883 words, with 30504772 characters in total.

[1]: https://huginn.org/
[2]: https://codestation.org/download/slowa.txt.gz
[3]: https://codestation.org/download/slowa.txt.bz2

