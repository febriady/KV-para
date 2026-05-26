# kvpara

**Parametric Klein–Vella control function estimation for Stata.**

`kvpara` estimates linear models with one or more endogenous regressors when no credible instrument is available. Identification comes from conditional heteroskedasticity in the first-stage residuals rather than an exclusion restriction, following Klein and Vella (2010) with the parametric variance specification of Farré, Klein, and Vella (2013).

## When to use it

Use `kvpara` when:

- You have an endogenous regressor (e.g., years of schooling in a wage equation).
- You cannot find a credible instrument satisfying the exclusion restriction.
- The first-stage residual variance varies meaningfully across observable cells of your data (testable via Breusch–Pagan / White).
- You are willing to assume that the correlation between the structural errors is constant conditional on observables.

Compared to instrumental variables, `kvpara` trades the exclusion restriction for a restriction on the second moments of the error structure. Compared to OLS, it absorbs the correlated component of the unobservables through a control function term whose form is identified by the heteroskedasticity.

## Installation

### From SSC

```stata
ssc install kvpara
```

(Pending submission; check the GitHub releases page for the current version in the meantime.)

### From GitHub

```stata
net install kvpara, from("https://raw.githubusercontent.com/febriady/KV-para/main/")
```

Or clone this repository and add the folder to your `adopath`:

```stata
adopath + "path/to/KV-para"
```

## Quick start

```stata
* Returns to schooling, treating years of education as endogenous
kvpara lhwage educ, ///
    controls_main(age age_sq female region*) ///
    controls_endog1(age age_sq female region*) ///
    het_main(age age_sq female) ///
    het_endog1(age age_sq female region*) ///
    iterations(10) bootstrap(500)
```

The four required options:

| Option | What it specifies |
|---|---|
| `controls_main(varlist)` | Exogenous controls in the main (outcome) equation. |
| `controls_endog1(varlist)` | Exogenous controls in the first-stage equation for the (first) endogenous regressor. |
| `het_main(varlist)` | Variables entering the conditional variance function of the main equation. |
| `het_endog1(varlist)` | Variables entering the conditional variance function of the first-stage equation. |

For up to 10 endogenous regressors, repeat the `controls_endogK(...)` and `het_endogK(...)` options for K = 2, 3, …, 10. Bootstrap is on by default (100 replications); for production estimates we recommend 500.

Detailed help is available via `help kvpara`. A full derivation with worked examples is in `kvpara_documentation.pdf` in this folder.

## Frequently used options

| Option | Default | Description |
|---|---:|---|
| `iterations(#)` | 10 | Number of KV iterations |
| `bootstrap(#)` | 100 | Bootstrap replications |
| `bootstrap_kv_only` | off | Bootstrap only the KV step (faster) |
| `generate(stub)` | — | Save control-function components as new variables |
| `level(#)` | 95 | Confidence level for CIs |
| `nohettest` | off | Skip Breusch–Pagan and White heteroskedasticity tests |

## Citation

If you use `kvpara` in academic work, please cite both the underlying methodology and this implementation.

**Method**

> Klein, R., and F. Vella (2010). "Estimating a Class of Triangular Simultaneous Equations Models Without Exclusion Restrictions." *Journal of Econometrics* 154(2): 154–164.

> Farré, L., R. Klein, and F. Vella (2013). "A Parametric Control Function Approach to Estimating the Returns to Schooling in the Absence of Exclusion Restrictions: An Application to the NLSY." *Empirical Economics* 44(1): 111–133.

**Software**

> Febriady, A. (2026). *kvpara: Parametric Klein–Vella Control Function Estimation for Stata*. Version 1.0.0. Available at: https://github.com/febriady/KV-para

**Application** — A worked example using `kvpara` to estimate heterogeneous returns to schooling by childhood poverty status in Indonesia:

> Febriady, A., A. Postepska, and V. Angelini (2026). "The Long Shadow: Childhood Poverty and the Returns to Education." *GLO Discussion Paper Series*, No. 1731. Global Labor Organization. https://hdl.handle.net/10419/338969

## Repository contents

- `kvpara.ado` — main program
- `kvpara.sthlp` — Stata help file
- `kvpara_documentation.pdf` — full method documentation and worked examples
- `README.md` — this file

## Author and maintainer

`kvpara` is developed and maintained by **Ade Febriady** (Department of Economics, Econometrics and Finance, University of Groningen). Correspondence: [a.febriady@rug.nl](mailto:a.febriady@rug.nl).

Bug reports and feature requests are welcome via the [GitHub issues page](https://github.com/febriady/KV-para/issues).

## License

Released under the MIT License. See `LICENSE` for details.
