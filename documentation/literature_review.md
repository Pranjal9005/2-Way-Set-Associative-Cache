# Literature Review and References

Supporting notes for Section II (Literature Review) of the IEEE report
([`IEEE_Cache_Project_Report.pdf`](IEEE_Cache_Project_Report.pdf)).
Reference numbers match the report.

## 1. Placement and locality: Cornell CS 3410 [2]

- **Temporal locality**: recently used data is likely to be used again.
  **Spatial locality**: data near a recent access is likely to be used soon.
- Builds up from direct-mapped placement to set-associative placement as ways
  of keeping useful memory contents close to the processor.
- **How this project uses it:** the *Repeat* and *Conflict pair* traces test
  temporal reuse directly. Each cache line holds one byte, so fetching a byte
  does not bring its neighbours in. That is why the *One pass* trace gets
  0 % hits in both designs.
- **Fair comparison:** at equal capacity, adding ways reduces the number of
  sets (direct-mapped: 4 sets; 2-way: 2 sets). The comparison therefore keeps
  line size and total capacity the same and fixes the address trace.

## 2. Identification and replacement: UC Berkeley CS 61C [3]

- Separates four cache design questions: **placement**, **identification**
  (tag + valid bit), **replacement**, and **write policy**.
- A tag match alone is not a hit. An entry that was never filled must not
  hit, so every match is qualified by its valid bit.
- Candidate tags in a set are compared **in parallel**.
- **How this project uses it:** the RTL splits these questions into separate
  modules: `address_decoder`, `tag_comparator`, `hit_miss_unit` (valid-bit
  qualification and way choice), `cache_array`, and `lru_unit`.
- **Two-way LRU needs one bit per set.** There are only two possible recency
  orders, so storing the *next victim* is exact LRU. Accessing way 0 makes
  way 1 the victim, and the other way round.

## 3. Conflict misses: Jouppi, ISCA 1990 [4]

- Shows that direct-mapped caches lose performance to **conflict misses**,
  where two addresses keep evicting each other even though the working set is
  small.
- Proposes miss caches, victim caches and stream buffers as small
  associative additions that recover those misses.
- **How this project uses it:** it motivates the *Conflict pair* and
  *Two sets* traces. This project adds associativity *inside* each set rather
  than adding a separate victim cache. The paper's benchmark numbers are not
  claimed as results of this project.

## 4. Tooling: Icarus Verilog [5]

- Open-source Verilog compiler (`iverilog`) and runtime (`vvp`) used to
  compile each testbench separately with `-g2012` and reproduce the results
  in Table V of the report.

## Synthesis: why the project is designed this way

| Source | Concept | Where it appears in the project |
|---|---|---|
| Cornell CS 3410 [2] | Locality, placement | Repeat / conflict traces; equal-capacity comparison |
| UC Berkeley CS 61C [3] | Valid bits, parallel tag check, replacement | `hit_miss_unit`, `tag_comparator`, `lru_unit` |
| Jouppi [4] | Conflict misses in direct-mapped caches | Motivation for 2-way placement; conflict traces |
| Icarus Verilog [5] | RTL simulation | Reproducible test results |

The project does not propose a new replacement algorithm. Its contribution is
a small, fully observable RTL implementation and a controlled comparison that
shows **both** the benefit of associativity (*Conflict pair*: 0 % → 87.5 %)
and its limit (*Three tags*: direct-mapped 27.78 % vs. 2-way 0 %).

---

## References (IEEE style, as cited in the report)

[1] Pranjal9005, "2-Way-Set-Associative-Cache," GitHub repository, commit
c8b1374b16fa6555b47aa9e47d37a963e50767b8. Accessed: Nov. 16, 2026. [Online].
Available: https://github.com/Pranjal9005/2-Way-Set-Associative-Cache

[2] Cornell University, "Caches," CS 3410, Spring 2025. Accessed: Nov. 16,
2026. [Online]. Available:
https://www.cs.cornell.edu/courses/cs3410/2025sp/notes/caches.html

[3] University of California, Berkeley, "Fully Associative Cache," CS 61C
Course Notes. Accessed: Nov. 16, 2026. [Online]. Available:
https://notes.cs61c.org/content/caches-ii/fully-associative/

[4] N. P. Jouppi, "Improving direct-mapped cache performance by the addition
of a small fully-associative cache and prefetch buffers," in *Proc. 17th
Annu. Int. Symp. Computer Architecture*, 1990, pp. 364–373,
doi: 10.1145/325164.325162.

[5] Icarus Verilog, "Getting Started With Icarus Verilog." Accessed: Nov. 16,
2026. [Online]. Available:
https://steveicarus.github.io/iverilog/usage/getting_started.html

## Further reading for Phase II (not yet cited in the report)

Candidates for expanding the literature review in the final report:

- J. L. Hennessy and D. A. Patterson, *Computer Architecture: A Quantitative
  Approach*, 6th ed. Cambridge, MA, USA: Morgan Kaufmann, 2017.
  Covers miss classification (compulsory, capacity, conflict) and the
  associativity trade-off.
- D. A. Patterson and J. L. Hennessy, *Computer Organization and Design
  RISC-V Edition: The Hardware/Software Interface*, 2nd ed. Cambridge, MA,
  USA: Morgan Kaufmann, 2020. Textbook treatment of set-associative caches
  and LRU.
- A. J. Smith, "Cache memories," *ACM Computing Surveys*, vol. 14, no. 3,
  pp. 473–530, Sep. 1982. Classic survey of cache design parameters.
- M. D. Hill and A. J. Smith, "Evaluating associativity in CPU caches,"
  *IEEE Trans. Comput.*, vol. 38, no. 12, pp. 1612–1630, Dec. 1989.
  Quantifies how miss rate changes with associativity.
- L. A. Belady, "A study of replacement algorithms for a virtual-storage
  computer," *IBM Systems Journal*, vol. 5, no. 2, pp. 78–101, 1966.
  Optimal (MIN) replacement, a reference point for LRU.
- *IEEE Standard for Verilog Hardware Description Language*, IEEE Std
  1364-2005. The language standard the RTL follows.
