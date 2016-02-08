Language speed comparison
=========================

Language speed is "measured" by in context of solving
specific problem using specific algorithm implemented
with most natural tools available in given language.

The problem that is being solved by test programs
is building *trie* (a prefix tree) for Polish language
dictionary.

Most implementations use their respective hash-maps
to link prefix with tail.

All tests run were performed with tcmalloc preloaded
(if using it improved performance).

| Language   | Time (seconds) | Memory (KiB) | Notes   |
|------------|---------------:|-------------:|---------|
| C++        |           0.60 |       221776 |         |
| Huginn     |          66.28 |      2922820 |         |
| Java       |           2.90 |      1265092 | ver 7   |
| JavaScript |           5.97 |       492272 | NodeJS  |
| Perl       |          69.46 |      1801748 |         |
| PHP        |          78.24 |      1487980 | ver 7.0 |
| Python     |          21.91 |      1674480 |         |

Dictionary loaded contains 2709883 words, with 30504772 characters in total.

