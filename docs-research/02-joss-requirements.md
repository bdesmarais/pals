# JOSS Submission Requirements (for an R package `paper.md`)

Research notes gathered 2026-06-06 from `joss.theoj.org`, `joss.readthedocs.io`, and
real accepted R-package submissions on GitHub. Use this to write the PALS `paper.md`.

> NOTE on 2026 criteria: As of January 2026 JOSS updated its review criteria to
> emphasize human creativity, design thinking, and demonstrable research impact (a
> response to generative-AI code). The newer checklist now expects several sections
> that older accepted papers did not have: **State of the field**, **Software design**,
> **Research impact statement**, and an **AI usage disclosure**. The classic minimum
> (Summary + Statement of need) is still the hard requirement, but include the newer
> sections to be safe. There is also now a **6-month public development history**
> expectation.

---

## 1. Required structure of `paper.md`

### 1.1 YAML front matter

A complete, annotated front-matter block:

```yaml
---
title: 'PALS: An R package for <one-line description>'   # required
tags:                                                    # required; free-text keywords
  - R
  - <domain keyword>
  - <domain keyword>
authors:                                                 # required
  - name: Jane Q. Researcher
    orcid: 0000-0000-0000-0000        # strongly recommended (ORCID iD)
    equal-contrib: true               # optional; mark equal contributors
    affiliation: "1, 2"               # quote when referencing multiple indices
    corresponding: true               # optional; marks corresponding author
  - given-names: Ludwig               # alternative to `name:` for complex names
    dropping-particle: van            #   (also: surname, suffix,
    surname: Beethoven                #    non-dropping-particle, literal)
    affiliation: 3
affiliations:                                            # required
  - index: 1
    name: Department X, University Y, Country
    ror: 00hx57361                    # optional Research Organization Registry id
  - index: 2
    name: Another Institution, Country
  - index: 3
    name: Independent Researcher, Country
date: 6 June 2026                                        # required; submission date
bibliography: paper.bib                                  # required; BibTeX/BibLaTeX file
# Optional AAS fields (astronomy only) — omit for PALS:
# aas-doi: 10.3847/xxxxx
# aas-journal: Astrophysical Journal
---
```

Name-field aliases supported by the compiler: `given-names` (= given, first, firstname),
`surname` (= family), plus `suffix`, `dropping-particle`, `non-dropping-particle`,
and `literal` (for non-Western / single-token names).

### 1.2 Sections

Hard requirements (the review checklist literally checks for section titles):

1. **Summary** — high-level functionality and purpose for a *diverse, non-specialist*
   audience.
2. **Statement of need** — must be a section titled exactly "Statement of need";
   what problem the software solves, who the target audience is, and the research
   context.

Expected under the 2026 criteria (include these):

3. **State of the field** — how PALS relates to / differs from existing software
   (cite the alternatives).
4. **Software design** (a.k.a. Key features / Functionality) — architecture,
   meaningful design decisions and trade-offs; good place for the feature list and
   a short **Example usage** code block.
5. **Research impact statement** — evidence of realized impact or credible near-term
   significance (publications using it, downloads, adopters, integrations).
6. **AI usage disclosure** — transparent statement of any generative-AI use in
   developing the software/paper (a short sentence is fine, even "none").
7. **Acknowledgements** — funding sources and contributors (financial support must
   be disclosed).
8. **References** — auto-generated from `paper.bib`; do not write by hand.

Older accepted R papers (e.g. tidyverse, tidygeocoder) used a lighter set
(Summary / package overview / components / design / acknowledgments / references) —
fine historically, but prefer the fuller list now.

### 1.3 Length

**750–1750 words** for the body text (older guidance said ~250–1000; the current
docs state 750–1750). Aim for a compact, focused paper.

### 1.4 Citation, figure, and equation syntax (pandoc / pandoc-crossref)

Citations resolve against `paper.bib`:

| Intent | Markdown | Renders as |
|---|---|---|
| Parenthetical | `[@upper1974]` | (Upper, 1974) |
| Author-in-text | `@upper1974` | Upper (1974) |
| Page-specified | `[@upper1974, p. 5]` | (Upper, 1974, p. 5) |
| Multiple | `[@a2020; @b2021]` | (A, 2020; B, 2021) |

Figures (label + cross-reference):

```markdown
![Caption text. \label{fig:example}](figure.png)
```
Reference it with `\autoref{fig:example}` (or `\ref{fig:example}`). Size with
`![desc](figure.png){ width=80% }` or `{height="9pt"}`.

Equations (LaTeX, via MathJax/pandoc):

```markdown
Inline like $x^2$. Display with a label:

$$ a^n + b^n = c^n \label{eq:fermat} $$
```
Reference with `\autoref{eq:fermat}`.

---

## 2. Submission requirements / review checklist

### 2.1 Scope — is the software in-scope?

- Must be **open source** per the OSI definition.
- Must have an **obvious research application** (solve complex modeling problems,
  support research instruments, or extract knowledge from datasets).
- **Out of scope:** pre-trained ML models and standalone notebooks.

### 2.2 "Substantial scholarly effort" / scholarly significance

JOSS looks for evidence such as:
- Publications/analyses that *use* the software; external adopters or integrations.
- Meaningful architectural decisions and trade-offs.
- **Sustained development over months/years** with collaborative, public history —
  not a single burst of commits.
- Likelihood of being cited by other researchers.
- **Repository public for >6 months** prior to submission, with active development
  spanning that period.

(There is no longer a fixed lines-of-code rule; older guidance cited "~1000 lines"
as a rough floor but significance is now judged holistically.)

### 2.3 Checklist items (paraphrased from the official review checklist)

**General**
- [ ] Source code available at the stated repository URL.
- [ ] Plain-text **LICENSE** file containing an **OSI-approved** license.
- [ ] Submitting author made major contributions; author list complete & appropriate.
- [ ] Submission demonstrates clear research impact / scholarly significance.

**Development history**
- [ ] Evidence of sustained development over time.
- [ ] Developed openly from early stages; multiple-contributor engagement.
- [ ] Good OSS practices: license, docs, tests/verification.

**Functionality**
- [ ] Installation proceeds as documented.
- [ ] Functional claims confirmed; performance claims (if any) confirmed.

**Documentation**
- [ ] **Statement of need** — clearly states the problems solved.
- [ ] **Installation instructions** — incl. a clear list of dependencies.
- [ ] **Example usage** — concrete examples of how to use the software.
- [ ] **Functionality documentation** — core functions documented satisfactorily
      (for R: roxygen2 man pages + a pkgdown site / vignettes).
- [ ] **Automated tests** — present (for R: testthat), or manual steps described.
- [ ] **Community guidelines** — how to contribute, report issues, seek support
      (e.g. CONTRIBUTING.md, issue templates, a CODE_OF_CONDUCT).

**Paper**
- [ ] Summary present and clear.
- [ ] Section titled "Statement of need".
- [ ] "State of the field" section.
- [ ] "Software design" section.
- [ ] "Research impact statement" section.
- [ ] "AI usage disclosure" section.
- [ ] Well written; references complete and correctly cited (full venue names,
      not abbreviations; include DOIs).

### 2.4 Release + archive (on acceptance)

After review, before publication, authors must:
1. Make a **tagged release** (a version, e.g. `v1.0.0`).
2. Deposit a snapshot of the repo with a **data-archiving service (Zenodo or
   figshare)** and obtain a **DOI** for that archive.
3. Post the **version number and archive DOI** in the review issue.

---

## 3. Compiling the PDF (`paper.md` + `paper.bib` → `paper.pdf`)

The compiler is **Open Journals / inara** (pandoc-based; can emit PDF and JATS).

**Option A — Open Journals GitHub Action (recommended).** Add a workflow that runs
on push; the compiled `paper.pdf` appears under the **Actions tab → latest run →
Artifacts** (a zip). Typical workflow:

```yaml
name: Draft PDF
on: [push]
jobs:
  paper:
    runs-on: ubuntu-latest
    name: Paper Draft
    steps:
      - uses: actions/checkout@v4
      - name: Build draft PDF
        uses: openjournals/openjournals-draft-action@master
        with:
          journal: joss
          paper-path: paper/paper.md     # path to your paper.md
      - uses: actions/upload-artifact@v4
        with:
          name: paper
          path: paper/paper.pdf
```

**Option B — local Docker (inara image).** With `paper.md` in a `paper/` dir:

```bash
docker run --rm \
    --volume $PWD/paper:/data \
    --user $(id -u):$(id -g) \
    --env JOURNAL=joss \
    openjournals/inara
```
Produces `paper/paper.pdf` beside `paper/paper.md`.

The paper files (`paper.md`, `paper.bib`, figures) live in the **same Git repo** as
the software, conventionally in a top-level `paper/` directory (some R packages put
them in `vignettes/`, e.g. tidyverse).

---

## 4. Concrete annotated `paper.md` skeleton (drop-in for PALS)

```markdown
---
title: 'PALS: An R package for <short description>'
tags:
  - R
  - <domain keyword>
  - <domain keyword>
authors:
  - name: Jane Q. Researcher
    orcid: 0000-0000-0000-0000
    corresponding: true
    affiliation: 1
affiliations:
  - index: 1
    name: Department X, University Y, Country
date: 6 June 2026
bibliography: paper.bib
---

# Summary

<2–4 sentences: what PALS does, for whom, in plain language. No jargon.>

# Statement of need

<What gap does PALS fill? Who is the audience? Why existing tools are insufficient.
Cite related literature/software, e.g. [@someRef2021].>

# State of the field

<Compare to existing R packages / tools; cite them. What does PALS do differently?>

# Software design

<Architecture and key design decisions/trade-offs. List key features.>

## Example usage

`​``r
library(pals)
result <- pals::main_function(data, option = TRUE)
summary(result)
`​``

<Optionally a figure:>
![Example output of PALS. \label{fig:demo}](figures/demo.png)

As shown in \autoref{fig:demo}, ...

# Research impact statement

<Evidence of use/impact: papers using PALS, downloads, adopters, integrations.>

# AI usage disclosure

<State any generative-AI assistance used in the software or paper, or "No
generative AI tools were used in developing this software.">

# Acknowledgements

<Funding sources and contributor acknowledgements.>

# References
```

(The `# References` heading is auto-populated from `paper.bib`; leave it empty.)

---

## 5. Example `paper.bib` entries

```bibtex
@article{Wickham:2014,
  author  = {Hadley Wickham},
  title   = {Tidy Data},
  journal = {Journal of Statistical Software},
  volume  = {59},
  number  = {10},
  year    = {2014},
  issn    = {1548-7660},
  pages   = {1--23},
  doi     = {10.18637/jss.v059.i10},
  url     = {https://www.jstatsoft.org/v059/i10}
}

@Manual{dplyr,
  title  = {dplyr: A Grammar of Data Manipulation},
  author = {Hadley Wickham and Romain Fran\c{c}ois and Lionel Henry and Kirill M\"uller},
  year   = {2021},
  note   = {R package version 1.0.4},
  url    = {https://CRAN.R-project.org/package=dplyr}
}

@Manual{rcore,
  title        = {R: A Language and Environment for Statistical Computing},
  author       = {{R Core Team}},
  organization = {R Foundation for Statistical Computing},
  address      = {Vienna, Austria},
  year         = {2024},
  url          = {https://www.R-project.org/}
}
```

Tips: prefer entries **with DOIs**; spell out full journal/conference names; you can
generate package entries with `citation("pkgname")` and `toBibtex()` in R.

---

## 6. Real accepted R-package examples (for concrete reference)

- **tidyverse** — `paper.md` in `vignettes/`. Sections: Summary, Tidyverse package,
  Components, Design principles, Acknowledgments, References.
  https://github.com/tidyverse/tidyverse/blob/main/vignettes/paper.md
- **tidygeocoder** — dedicated submission repo with `paper.md` + `paper.bib`.
  https://github.com/jessecambon/tidygeocoder-joss
- **osmextract** (rOpenSci) — `paper/paper.md`.
  https://github.com/ropensci/osmextract
- Many more accepted papers (browse for R examples):
  https://joss.theoj.org/papers/published

---

## Sources

- JOSS Paper Format: https://joss.readthedocs.io/en/latest/paper.html
- JOSS Example Paper: https://joss.readthedocs.io/en/latest/example_paper.html
- Submitting a paper to JOSS: https://joss.readthedocs.io/en/latest/submitting.html
- Review checklist: https://joss.readthedocs.io/en/latest/review_checklist.html
- Review criteria: https://joss.readthedocs.io/en/latest/review_criteria.html
- Reviewer guidelines: https://joss.readthedocs.io/en/latest/reviewer_guidelines.html
- 2026 GenAI criteria update (blog): https://blog.joss.theoj.org/2026/01/preparing-joss-for-a-generative-ai-future
- JOSS home / about: https://joss.theoj.org/ , https://joss.theoj.org/about
- tidyverse paper.md: https://github.com/tidyverse/tidyverse/blob/main/vignettes/paper.md
- tidygeocoder JOSS repo: https://github.com/jessecambon/tidygeocoder-joss
- osmextract (rOpenSci): https://github.com/ropensci/osmextract
- openjournals/inara compiler image (Docker Hub: openjournals/inara)
