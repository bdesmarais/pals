# JOSS paper

This directory holds the *Journal of Open Source Software* (JOSS) paper for **palsr**.

## Files

| File | Role |
|------|------|
| `paper.md`  | **Canonical source.** This is what JOSS ingests — JOSS does not accept hand-written LaTeX; its build system (`inara`/Open Journals) compiles this Markdown through the official JOSS LaTeX template. |
| `paper.bib` | BibTeX references. |
| `paper.tex` | LaTeX produced from `paper.md` via the JOSS template (for local review / a LaTeX version of the article). |
| `paper.pdf` | Typeset, JOSS-styled PDF. |
| `build_pdf.sh` | Reproducible local build script. |
| `.joss/` | Vendored JOSS LaTeX template (`latex.template`) and logo (`logo.png`) from [openjournals/whedon](https://github.com/openjournals/whedon), lightly patched so the bibliography compiles with pandoc ≥ 3. |

## Building locally

Requires `pandoc` (≥ 3) and a LaTeX engine (`xelatex`):

```sh
cd paper
./build_pdf.sh      # regenerates paper.tex and paper.pdf
```

## The authentic JOSS build

When the package is submitted, JOSS regenerates the PDF itself from `paper.md`
using its current template. To reproduce that exact output (requires Docker):

```sh
docker run --rm \
  --volume $PWD:/data \
  --user $(id -u):$(id -g) \
  --env JOURNAL=joss \
  openjournals/inara
```

## Before submission

- Add real **ORCIDs** for each author in the `paper.md` YAML.
- Confirm author **affiliations**.
- The `-V` placeholders in `build_pdf.sh` (volume/issue/page/DOI/review URL) are
  filled in automatically by JOSS at acceptance; they only affect the local preview.
