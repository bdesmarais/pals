# Contributing to palsr

Thanks for your interest in **palsr**! Contributions, bug reports, and questions
are all welcome.

## Reporting issues

If you find a bug or unexpected behaviour, please
[open an issue](https://github.com/bdesmarais/palsr/issues) and include:

- a short description of the problem,
- a minimal reproducible example (ideally using the bundled `nigeria_sim` data or
  `simulate_conflict_events()`), and
- the output of `sessionInfo()` and your `palsr` version.

## Contributing code

1. Fork the repository and create a branch for your change.
2. Make your change, following the existing code style (roxygen2 documentation for
   exported functions, `testthat` tests for new behaviour).
3. Run `devtools::document()`, `devtools::test()`, and `R CMD check` locally and
   make sure they pass cleanly.
4. Open a pull request describing the change and the motivation for it.

For larger changes (new features, changes to the estimator or projection kernels),
please open an issue to discuss the design first so we can agree on an approach
before you invest the effort.

## Seeking support

For usage questions, start with the package documentation (`?estimate_pals`) and
the introductory vignette (`vignette("palsr")`). If that does not answer your
question, please
[open an issue](https://github.com/bdesmarais/palsr/issues) with the
"question" label, or contact the maintainer, Bruce Desmarais, at the address listed
in the `DESCRIPTION` file.

## Code of conduct

Please be respectful and constructive in all project spaces. By participating, you
are expected to uphold a welcoming, harassment-free environment for everyone.
