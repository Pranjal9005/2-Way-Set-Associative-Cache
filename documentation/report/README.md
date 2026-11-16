# IEEE Report Source

LaTeX source of the project report, written with the official IEEE
conference template (`IEEEtran`). The compiled PDF is
[`../IEEE_Cache_Project_Report.pdf`](../IEEE_Cache_Project_Report.pdf).

## Section structure

| # | Section | Phase I | Phase II |
|---|---|:-:|:-:|
| – | Abstract and Index Terms | ✓ | ✓ |
| I | Introduction | ✓ | ✓ |
| II | Literature Review | ✓ | ✓ |
| III | Proposed Solution | ✓ | ✓ |
| IV | Verification Methodology | | ✓ |
| V | Results and Discussion | | ✓ |
| VI | Individual Contributions | ✓ | ✓ |
| VII | Conclusion | | ✓ |
| – | References | ✓ | ✓ |

## Building

```bash
# Option 1: Tectonic (downloads the packages it needs automatically)
tectonic IEEE_Cache_Project_Report.tex

# Option 2: TeX Live / MiKTeX
pdflatex IEEE_Cache_Project_Report.tex
pdflatex IEEE_Cache_Project_Report.tex
```

You can also upload the `.tex` file to Overleaf; IEEEtran is built in.
