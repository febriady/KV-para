{smcl}
{* *! version 1.0.0  26may2026}{...}
{viewerjumpto "Syntax" "kvpara##syntax"}{...}
{viewerjumpto "Description" "kvpara##description"}{...}
{viewerjumpto "Options" "kvpara##options"}{...}
{viewerjumpto "Remarks" "kvpara##remarks"}{...}
{viewerjumpto "Examples" "kvpara##examples"}{...}
{viewerjumpto "Stored results" "kvpara##results"}{...}
{viewerjumpto "References" "kvpara##references"}{...}
{title:Title}

{p2colset 5 16 18 2}{...}
{p2col :{cmd:kvpara} {hline 2}}Klein-Vella parametric control function estimation{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:kvpara}
{depvar}
{it:endog1}
[{it:endog2} {it:endog3} ...]
{ifin}
{cmd:,}
{cmdab:cont:rols_main(}{varlist}{cmd:)}
{cmdab:cont:rols_endog1(}{varlist}{cmd:)}
{cmdab:het:_main(}{varlist}{cmd:)}
{cmdab:het:_endog1(}{varlist}{cmd:)}
[{it:options}]

{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt :{cmdab:cont:rols_main(}{varlist}{cmd:)}}control variables for main equation{p_end}
{synopt :{cmdab:cont:rols_endog1(}{varlist}{cmd:)}}control variables (instruments) for first endogenous variable{p_end}
{synopt :{cmdab:het:_main(}{varlist}{cmd:)}}variables for heteroskedasticity function in main equation{p_end}
{synopt :{cmdab:het:_endog1(}{varlist}{cmd:)}}variables for heteroskedasticity function in first stage{p_end}

{syntab:Multiple Endogenous Variables}
{synopt :{cmdab:cont:rols_endog2(}{varlist}{cmd:)}}control variables for second endogenous variable{p_end}
{synopt :{cmdab:cont:rols_endog3(}{varlist}{cmd:)}}control variables for third endogenous variable{p_end}
{synopt :...}up to {cmdab:cont:rols_endog10()}{p_end}
{synopt :{cmdab:het:_endog2(}{varlist}{cmd:)}}heteroskedasticity variables for second endogenous variable{p_end}
{synopt :{cmdab:het:_endog3(}{varlist}{cmd:)}}heteroskedasticity variables for third endogenous variable{p_end}
{synopt :...}up to {cmdab:het:_endog10()}{p_end}

{syntab:Categorical Endogenous Variables}
{synopt :{cmdab:endog:_categorical1(}{varlist}{cmd:)}}categorical dummies for first endogenous variable{p_end}
{synopt :{cmdab:endog:_categorical2(}{varlist}{cmd:)}}categorical dummies for second endogenous variable{p_end}
{synopt :...}up to {cmdab:endog:_categorical10()}{p_end}

{syntab:Estimation}
{synopt :{opt iter:ations(#)}}number of Klein-Vella iterations; default is {cmd:iterations(10)}{p_end}
{synopt :{opt boot:strap(#)}}number of bootstrap replications; default is {cmd:bootstrap(100)}{p_end}
{synopt :{opt boot:strap_kv_only}}bootstrap only Klein-Vella stage (not OLS/first stage){p_end}
{synopt :{opt cl:uster(varname)}}cluster bootstrap by specified variable{p_end}
{synopt :{opt level(#)}}set confidence level; default is {cmd:level(95)}{p_end}

{syntab:Reporting}
{synopt :{opt nodisp:lay}}suppress display of results{p_end}
{synopt :{opt nohet:test}}suppress display of heteroskedasticity function estimates{p_end}
{synopt :{cmdab:gen:erate(}{it:stub} [{cmd:,} {opt replace}]{cmd:)}}generate CF component variables{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:kvpara} implements the Klein and Vella (2010) parametric control function approach for 
estimating models with endogenous regressors in the presence of heteroskedasticity. The method 
allows the variance of errors to depend on covariates through a flexible parametric specification.

{pstd}
The command supports:

{phang2}Ã¢â‚¬Â¢ Multiple endogenous regressors (up to 10){p_end}
{phang2}Ã¢â‚¬Â¢ Categorical endogenous variables (using continuous version for first stage){p_end}
{phang2}Ã¢â‚¬Â¢ Mixing of categorical and continuous endogenous variables{p_end}
{phang2}Ã¢â‚¬Â¢ Bootstrap and analytical standard errors{p_end}
{phang2}Ã¢â‚¬Â¢ Heteroskedasticity tests (Breusch-Pagan, White){p_end}

{pstd}
The estimation procedure consists of four steps:

{phang}
{bf:Step 1: OLS Estimation} - Run baseline OLS regression for comparison and conduct 
heteroskedasticity tests.

{phang}
{bf:Step 2: First Stage Estimation} - For each endogenous variable, regress on its 
instruments/controls and model heteroskedasticity: log(residualÃ‚Â²) = f(het_variables). 
This yields predicted standard deviations: ÃÆ’ÃŒâ€š = sqrt(exp(X'ÃŽÂ¸)).

{phang}
{bf:Step 3: Iterative Klein-Vella Estimation} - Iteration 1 is pure OLS (no control function). 
Subsequent iterations include control function terms: cor = (ÃÆ’_main / ÃÆ’_endog) Ãƒâ€” residual_endog. 
The heteroskedasticity function for the main equation is updated each iteration.

{phang}
{bf:Step 4: Bootstrap Standard Errors} (optional) - Resample data with replacement and 
re-estimate the entire procedure to calculate bootstrap standard errors.


{marker options}{...}
{title:Options}

{dlgtab:Required}

{phang}
{cmd:controls_main(}{varlist}{cmd:)} specifies the control variables (exogenous regressors) 
for the main equation. These variables should be included in the structural equation but 
are not endogenous.

{phang}
{cmd:controls_endog1(}{varlist}{cmd:)} specifies the control variables (instruments) for 
the first endogenous variable. These variables must be excluded from the main equation 
and should be correlated with the endogenous variable but uncorrelated with the error term.

{phang}
{cmd:het_main(}{varlist}{cmd:)} specifies variables for modeling heteroskedasticity in 
the main equation. The model is: log(residualÃ‚Â²) = f(het_main).

{phang}
{cmd:het_endog1(}{varlist}{cmd:)} specifies variables for modeling heteroskedasticity in 
the first stage. The model is: log(residualÃ‚Â²) = f(het_endog1).

{dlgtab:Multiple Endogenous Variables}

{phang}
{cmd:controls_endog2(}{varlist}{cmd:)}, {cmd:controls_endog3(}{varlist}{cmd:)}, ..., 
{cmd:controls_endog10(}{varlist}{cmd:)} specify control variables (instruments) for 
additional endogenous variables. Required when multiple endogenous variables are specified.

{phang}
{cmd:het_endog2(}{varlist}{cmd:)}, {cmd:het_endog3(}{varlist}{cmd:)}, ..., 
{cmd:het_endog10(}{varlist}{cmd:)} specify heteroskedasticity variables for additional 
endogenous variables. Required when multiple endogenous variables are specified.

{dlgtab:Categorical Endogenous Variables}

{phang}
{cmd:endog_categorical1(}{varlist}{cmd:)} specifies categorical dummies to use in the 
main equation for the first endogenous variable. When specified, the continuous version 
(from the main varlist) is used for the first stage and control function generation, 
but the categorical dummies are used in the main equation (OLS and Klein-Vella). This 
allows for non-linear effects while maintaining a strong first stage.

{pmore}
Example: Suppose education is endogenous. Specify {cmd:educ_years} in the main varlist 
and create dummies: {cmd:gen educ_hs = (educ_years >= 12 & educ_years < 16)}, etc. 
Then use {cmd:endog_categorical1(educ_hs educ_col educ_grad)} to include categorical 
levels in the main equation while using years of education for the first stage.

{phang}
{cmd:endog_categorical2(}{varlist}{cmd:)}, {cmd:endog_categorical3(}{varlist}{cmd:)}, ..., 
{cmd:endog_categorical10(}{varlist}{cmd:)} specify categorical dummies for additional 
endogenous variables.

{dlgtab:Estimation}

{phang}
{opt iterations(#)} specifies the number of iterations for the Klein-Vella procedure. 
The first iteration is pure OLS without control function. Subsequent iterations include 
control function terms and update the heteroskedasticity model. The default is 
{cmd:iterations(10)}, which is usually sufficient for convergence.

{phang}
{opt bootstrap(#)} specifies the number of bootstrap replications for calculating 
standard errors. Bootstrap is recommended for correct inference as it accounts for 
estimation uncertainty in the first stage and control function. The default is 
{cmd:bootstrap(100)}. Set to 0 to use analytical standard errors only.

{phang}
{opt bootstrap_kv_only} specifies that only the Klein-Vella stage should be bootstrapped, 
while OLS and first stage use analytical standard errors. This can speed up computation 
when only Klein-Vella inference is needed.

{phang}
{opt cluster(varname)} specifies a variable identifying clusters for the bootstrap. When 
specified, entire clusters are resampled with replacement rather than individual observations. 
This is important for survey data or panel data where observations within clusters (e.g., 
communities, households, regions) may be correlated. The cluster bootstrap addresses both 
the generated regressors problem inherent in the Klein-Vella procedure AND within-cluster 
correlation of errors.

{phang}
{opt level(#)} specifies the confidence level, as a percentage, for confidence intervals. 
The default is {cmd:level(95)} or as set by {helpb set level}.

{dlgtab:Reporting}

{phang}
{opt nodisplay} suppresses display of all estimation results. Results are still stored 
in {cmd:e()} and can be accessed after estimation.

{phang}
{opt nohettest} suppresses display of heteroskedasticity function estimates. First stage 
results, OLS results, and Klein-Vella results are still displayed.

{phang}
{cmd:generate(}{it:stub} [{cmd:,} {opt replace}]{cmd:)} generates new variables containing 
the control function and its components. The {it:stub} is a prefix used to name the 
generated variables:

{p2colset 9 28 30 2}{...}
{p2col :{it:stub}{cmd:_su}}sigma_u - predicted standard deviation from main equation heteroskedasticity function (final iteration){p_end}
{p2col :{it:stub}{cmd:_sv}{it:#}}sigma_v - predicted standard deviation from first stage heteroskedasticity function for endogenous variable #{p_end}
{p2col :{it:stub}{cmd:_vhat}{it:#}}V-hat - first stage residual for endogenous variable #{p_end}
{p2col :{it:stub}{cmd:_scale}{it:#}}scale - the ratio sigma_u/sigma_v for endogenous variable #{p_end}
{p2col :{it:stub}{cmd:_cf}{it:#}}control function = scale * V-hat for endogenous variable #{p_end}
{p2colreset}{...}

{pmore}
The {opt replace} suboption allows overwriting existing variables with the same names. 
Without {opt replace}, the command will error if variables already exist.

{pmore}
Note: The control function CF = (sigma_u / sigma_v) * V_hat, where sigma_u comes from 
the final iteration of the main equation heteroskedasticity model.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Identification and Exclusion Restrictions}

{pstd}
The Klein-Vella method identifies endogenous regressors through heteroskedasticity in 
the structural errors. Traditional exclusion restrictions (instruments excluded from 
the main equation) are not strictly required but strengthen identification. Best practice 
is to include instruments in {cmd:controls_endog#()} that are excluded from 
{cmd:controls_main()}.

{pstd}
{bf:Heteroskedasticity Specification}

{pstd}
Correct specification of heteroskedasticity is crucial for identification. The 
Breusch-Pagan and White tests reported after first stage estimation help assess 
whether heteroskedasticity is present. Variables in {cmd:het_endog#()} should be 
expected to affect the variance of the first stage residuals.

{pstd}
{bf:Categorical Endogenous Variables}

{pstd}
When using {cmd:endog_categorical#()}, remember:

{phang2}Ã¢â‚¬Â¢ The continuous version (from main varlist) is used for first stage and control function{p_end}
{phang2}Ã¢â‚¬Â¢ The categorical dummies are used in the main equation{p_end}
{phang2}Ã¢â‚¬Â¢ One control function corrects endogeneity for all categorical levels{p_end}
{phang2}Ã¢â‚¬Â¢ This provides stronger first stage while allowing non-linear effects{p_end}
{phang2}Ã¢â‚¬Â¢ Omit one category as reference (standard practice with categorical variables){p_end}

{pstd}
{bf:Convergence}

{pstd}
The iterative procedure typically converges within 10 iterations. To check convergence, 
compare coefficients across the final iterations or increase {cmd:iterations()} to verify 
stability.

{pstd}
{bf:Bootstrap vs. Analytical Standard Errors}

{pstd}
Bootstrap standard errors are recommended because they properly account for uncertainty 
in first stage estimation and control function generation. Analytical standard errors 
may be conservative. Use {cmd:bootstrap_kv_only} to speed up computation if only 
Klein-Vella inference is needed.


{marker examples}{...}
{title:Examples}

{pstd}
{bf:Important:} Unlike instrumental variable (IV) approaches, the Klein-Vella method does 
{bf:not require exclusion restrictions}. Identification comes from heteroskedasticity in the 
first stage errors. Therefore, controls_endog#() typically includes the {bf:same variables} 
as controls_main(). This is the key distinguishing feature of this approach.

{pstd}{bf:Example 1: Basic setup (same controls in main and first stage)}{p_end}
{phang2}{cmd:. * Define control variables}{p_end}
{phang2}{cmd:. local X age age_sq female region_d1 region_d2 region_d3}{p_end}
{phang2}{space 0}{p_end}
{phang2}{cmd:. * Note: controls_main and controls_endog1 use the SAME variables}{p_end}
{phang2}{cmd:. * This is NOT an IV approach - identification comes from heteroskedasticity}{p_end}
{phang2}{cmd:. kvpara lwage education, ///}{p_end}
{phang2}{cmd:      controls_main(`X') ///}{p_end}
{phang2}{cmd:      controls_endog1(`X') ///}{p_end}
{phang2}{cmd:      het_main(`X') ///}{p_end}
{phang2}{cmd:      het_endog1(`X') ///}{p_end}
{phang2}{cmd:      iterations(10) bootstrap(100)}{p_end}

{pstd}{bf:Example 2: Accessing stored results}{p_end}
{phang2}{cmd:. local X age age_sq female region_d1 region_d2}{p_end}
{phang2}{space 0}{p_end}
{phang2}{cmd:. kvpara lwage education, ///}{p_end}
{phang2}{cmd:      controls_main(`X') controls_endog1(`X') ///}{p_end}
{phang2}{cmd:      het_main(`X') het_endog1(`X') ///}{p_end}
{phang2}{cmd:      bootstrap(100)}{p_end}
{phang2}{space 0}{p_end}
{phang2}{cmd:. * === KEY RESULTS MATRICES ===}{p_end}
{phang2}{space 0}{p_end}
{phang2}{cmd:. * Klein-Vella coefficients and standard errors}{p_end}
{phang2}{cmd:. matrix list e(b_kv)}{p_end}
{phang2}{cmd:. matrix list e(se_kv)}{p_end}
{phang2}{space 0}{p_end}
{phang2}{cmd:. * OLS coefficients and standard errors (for comparison)}{p_end}
{phang2}{cmd:. matrix list e(b_ols)}{p_end}
{phang2}{cmd:. matrix list e(se_ols)}{p_end}
{phang2}{space 0}{p_end}
{phang2}{cmd:. * First stage coefficients}{p_end}
{phang2}{cmd:. matrix list e(b_first1)}{p_end}
{phang2}{cmd:. matrix list e(se_first1)}{p_end}
{phang2}{space 0}{p_end}
{phang2}{cmd:. * Heteroskedasticity function coefficients (main equation)}{p_end}
{phang2}{cmd:. matrix list e(theta_hmain)}{p_end}
{phang2}{cmd:. matrix list e(se_hmain)}{p_end}
{phang2}{space 0}{p_end}
{phang2}{cmd:. * Heteroskedasticity function coefficients (first stage)}{p_end}
{phang2}{cmd:. matrix list e(theta_he1)}{p_end}
{phang2}{cmd:. matrix list e(se_he1)}{p_end}
{phang2}{space 0}{p_end}
{phang2}{cmd:. * === KEY SCALARS ===}{p_end}
{phang2}{space 0}{p_end}
{phang2}{cmd:. * Control function coefficient (endogeneity test)}{p_end}
{phang2}{cmd:. display "CF coefficient: " _b[_cor1]}{p_end}
{phang2}{cmd:. display "CF std error:   " _se[_cor1]}{p_end}
{phang2}{cmd:. display "CF t-stat:      " _b[_cor1]/_se[_cor1]}{p_end}
{phang2}{space 0}{p_end}
{phang2}{cmd:. * First stage diagnostics}{p_end}
{phang2}{cmd:. display "First stage R2: " e(r2_first1)}{p_end}
{phang2}{cmd:. display "First stage F:  " e(F_first1)}{p_end}
{phang2}{space 0}{p_end}
{phang2}{cmd:. * Heteroskedasticity tests (first stage)}{p_end}
{phang2}{cmd:. display "BP chi2: " e(bp_chi2_first1) " p-value: " e(bp_p_first1)}{p_end}
{phang2}{cmd:. display "White chi2: " e(white_chi2_first1) " p-value: " e(white_p_first1)}{p_end}
{phang2}{space 0}{p_end}
{phang2}{cmd:. * CF component summary statistics}{p_end}
{phang2}{cmd:. display "Mean sigma_u: " e(mean_su)}{p_end}
{phang2}{cmd:. display "Mean sigma_v: " e(mean_sv1)}{p_end}
{phang2}{cmd:. display "Mean scale:   " e(mean_scale1)}{p_end}

{pstd}{bf:Example 3: Generating CF components for further analysis}{p_end}
{phang2}{cmd:. local X age age_sq female ethnicity_d1 region_d2 region_d3 region_d4}{p_end}
{phang2}{space 0}{p_end}
{phang2}{cmd:. kvpara lhwage educ, ///}{p_end}
{phang2}{cmd:      controls_main(`X') controls_endog1(`X') ///}{p_end}
{phang2}{cmd:      het_main(`X') het_endog1(`X') ///}{p_end}
{phang2}{cmd:      bootstrap(100) generate(kv, replace)}{p_end}
{phang2}{space 0}{p_end}
{phang2}{cmd:. * Generated variables:}{p_end}
{phang2}{cmd:. *   kv_su     - sigma_u (main equation predicted SD)}{p_end}
{phang2}{cmd:. *   kv_sv1    - sigma_v (first stage predicted SD)}{p_end}
{phang2}{cmd:. *   kv_vhat1  - V-hat (first stage residual)}{p_end}
{phang2}{cmd:. *   kv_scale1 - scale = sigma_u / sigma_v}{p_end}
{phang2}{cmd:. *   kv_cf1    - control function = scale * V-hat}{p_end}
{phang2}{space 0}{p_end}
{phang2}{cmd:. * Verify the identity: CF = scale * V-hat}{p_end}
{phang2}{cmd:. gen check = kv_scale1 * kv_vhat1}{p_end}
{phang2}{cmd:. assert abs(check - kv_cf1) < 1e-10}{p_end}
{phang2}{cmd:. drop check}{p_end}
{phang2}{space 0}{p_end}
{phang2}{cmd:. * Summarize CF components}{p_end}
{phang2}{cmd:. summarize kv_su kv_sv1 kv_scale1 kv_vhat1 kv_cf1}{p_end}

{pstd}{bf:Example 4: Comparing subsamples}{p_end}
{phang2}{cmd:. local X age age_sq female ethnicity_d1 region_d2 region_d3}{p_end}
{phang2}{space 0}{p_end}
{phang2}{cmd:. * Estimate for "never poor" sample}{p_end}
{phang2}{cmd:. kvpara lhwage educ if poor_childhood == 0, ///}{p_end}
{phang2}{cmd:      controls_main(`X') controls_endog1(`X') ///}{p_end}
{phang2}{cmd:      het_main(`X') het_endog1(`X') ///}{p_end}
{phang2}{cmd:      bootstrap(100) generate(np, replace)}{p_end}
{phang2}{cmd:. estimates store np}{p_end}
{phang2}{space 0}{p_end}
{phang2}{cmd:. * Estimate for "childhood poor" sample}{p_end}
{phang2}{cmd:. kvpara lhwage educ if poor_childhood == 1, ///}{p_end}
{phang2}{cmd:      controls_main(`X') controls_endog1(`X') ///}{p_end}
{phang2}{cmd:      het_main(`X') het_endog1(`X') ///}{p_end}
{phang2}{cmd:      bootstrap(100) generate(cp, replace)}{p_end}
{phang2}{cmd:. estimates store cp}{p_end}
{phang2}{space 0}{p_end}
{phang2}{cmd:. * Compare CF components across groups}{p_end}
{phang2}{cmd:. summarize np_cf1 cp_cf1}{p_end}

{pstd}{bf:Example 5: Categorical endogenous variable}{p_end}
{phang2}{cmd:. * Create education level dummies}{p_end}
{phang2}{cmd:. gen educ_hs = (educ >= 12 & educ < 16)}{p_end}
{phang2}{cmd:. gen educ_col = (educ >= 16)}{p_end}
{phang2}{space 0}{p_end}
{phang2}{cmd:. local X age age_sq female region_d1 region_d2}{p_end}
{phang2}{space 0}{p_end}
{phang2}{cmd:. * Continuous 'educ' used for first stage, dummies used in main equation}{p_end}
{phang2}{cmd:. kvpara lwage educ, ///}{p_end}
{phang2}{cmd:      endog_categorical1(educ_hs educ_col) ///}{p_end}
{phang2}{cmd:      controls_main(`X') controls_endog1(`X') ///}{p_end}
{phang2}{cmd:      het_main(`X') het_endog1(`X') ///}{p_end}
{phang2}{cmd:      bootstrap(100)}{p_end}

{pstd}{bf:Example 6: Full IFLS-style specification}{p_end}
{phang2}{cmd:. * Define controls}{p_end}
{phang2}{cmd:. local x_All age age_sq female ethnicity_d1 region_birth_3way_d2 region_birth_3way_d3 ///}{p_end}
{phang2}{cmd:             region_birth_3way_d4 region_birth_3way_d5 region_birth_3way_d6 region_birth_3way_d7}{p_end}
{phang2}{space 0}{p_end}
{phang2}{cmd:. kvpara lhwage_trim educ if cpoor_ever!=., ///}{p_end}
{phang2}{cmd:      controls_main(`x_All') ///}{p_end}
{phang2}{cmd:      controls_endog1(`x_All') ///}{p_end}
{phang2}{cmd:      het_main(`x_All') ///}{p_end}
{phang2}{cmd:      het_endog1(`x_All') ///}{p_end}
{phang2}{cmd:      iterations(10) bootstrap(100) bootstrap_kv_only generate(kv, replace)}{p_end}
{phang2}{space 0}{p_end}
{phang2}{cmd:. * Display key results}{p_end}
{phang2}{cmd:. display "=== Klein-Vella Results ==="}{p_end}
{phang2}{cmd:. matrix list e(b_kv)}{p_end}
{phang2}{cmd:. matrix list e(se_kv)}{p_end}
{phang2}{space 0}{p_end}
{phang2}{cmd:. display "=== Heteroskedasticity Function (Main Eq) ==="}{p_end}
{phang2}{cmd:. matrix list e(theta_hmain)}{p_end}
{phang2}{space 0}{p_end}
{phang2}{cmd:. display "=== Heteroskedasticity Function (First Stage) ==="}{p_end}
{phang2}{cmd:. matrix list e(theta_he1)}{p_end}
{phang2}{space 0}{p_end}
{phang2}{cmd:. * Verify heteroskedasticity is present (required for identification)}{p_end}
{phang2}{cmd:. display "First stage BP p-value: " e(bp_p_first1)}{p_end}
{phang2}{cmd:. display "First stage White p-value: " e(white_p_first1)}{p_end}
{phang2}{space 0}{p_end}
{phang2}{cmd:. * Compare CF across poverty status}{p_end}
{phang2}{cmd:. bysort cpoor_ever: summarize kv_cf1}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:kvpara} stores the following in {cmd:e()}:

{synoptset 24 tabbed}{...}
{p2col 5 24 28 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}
{synopt:{cmd:e(nendog)}}number of endogenous variables{p_end}
{synopt:{cmd:e(iterations)}}number of iterations{p_end}
{synopt:{cmd:e(bootstrap)}}number of bootstrap replications{p_end}
{synopt:{cmd:e(boot_success)}}number of successful bootstrap replications{p_end}
{synopt:{cmd:e(r2_first1)}}R-squared for first stage 1{p_end}
{synopt:{cmd:e(F_first1)}}F-statistic for first stage 1{p_end}
{synopt:{cmd:e(bp_chi2_first1)}}Breusch-Pagan chi-squared for first stage 1{p_end}
{synopt:{cmd:e(bp_p_first1)}}Breusch-Pagan p-value for first stage 1{p_end}
{synopt:{cmd:e(white_chi2_first1)}}White test chi-squared for first stage 1{p_end}
{synopt:{cmd:e(white_p_first1)}}White test p-value for first stage 1{p_end}
{synopt:{cmd:e(r2_first2)}}R-squared for first stage 2 (if applicable){p_end}
{synopt:{cmd:e(F_first2)}}F-statistic for first stage 2 (if applicable){p_end}
{synopt:...}(same pattern for first3, first4, etc.){p_end}
{synopt:{cmd:e(bp_chi2_ols)}}Breusch-Pagan chi-squared for OLS{p_end}
{synopt:{cmd:e(bp_p_ols)}}Breusch-Pagan p-value for OLS{p_end}
{synopt:{cmd:e(white_chi2_ols)}}White test chi-squared for OLS{p_end}
{synopt:{cmd:e(white_p_ols)}}White test p-value for OLS{p_end}
{synopt:{cmd:e(mean_su)}}mean of sigma_u (main equation het){p_end}
{synopt:{cmd:e(sd_su)}}standard deviation of sigma_u{p_end}
{synopt:{cmd:e(mean_sv1)}}mean of sigma_v for endogenous variable 1{p_end}
{synopt:{cmd:e(sd_sv1)}}standard deviation of sigma_v for endogenous variable 1{p_end}
{synopt:{cmd:e(mean_scale1)}}mean of scale (sigma_u/sigma_v) for endogenous variable 1{p_end}
{synopt:{cmd:e(sd_scale1)}}standard deviation of scale for endogenous variable 1{p_end}
{synopt:{cmd:e(mean_cf1)}}mean of control function for endogenous variable 1{p_end}
{synopt:{cmd:e(sd_cf1)}}standard deviation of control function for endogenous variable 1{p_end}
{synopt:{cmd:e(mean_sv2)}}mean of sigma_v for endogenous variable 2 (if applicable){p_end}
{synopt:...}(same pattern for sv2, scale2, sv3, scale3, etc.){p_end}

{p2col 5 24 28 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:kvpara}{p_end}
{synopt:{cmd:e(depvar)}}name of dependent variable{p_end}
{synopt:{cmd:e(endog1)}}name of first endogenous variable (continuous version){p_end}
{synopt:{cmd:e(endog2)}}name of second endogenous variable (if applicable){p_end}
{synopt:...}(same pattern for endog3, endog4, etc.){p_end}
{synopt:{cmd:e(endog1_categorical)}}categorical dummies for first endogenous variable (if specified){p_end}
{synopt:{cmd:e(endog2_categorical)}}categorical dummies for second endogenous variable (if specified){p_end}
{synopt:...}(same pattern for endog3, endog4, etc.){p_end}

{p2col 5 24 28 2: Matrices}{p_end}
{synopt:{cmd:e(b)}}Klein-Vella coefficient vector{p_end}
{synopt:{cmd:e(V)}}Klein-Vella variance-covariance matrix{p_end}
{synopt:{cmd:e(b_ols)}}OLS coefficient vector{p_end}
{synopt:{cmd:e(se_ols)}}OLS standard error vector{p_end}
{synopt:{cmd:e(b_kv)}}Klein-Vella coefficient vector{p_end}
{synopt:{cmd:e(se_kv)}}Klein-Vella standard error vector{p_end}
{synopt:{cmd:e(b_first1)}}first stage 1 coefficient vector{p_end}
{synopt:{cmd:e(se_first1)}}first stage 1 standard error vector{p_end}
{synopt:{cmd:e(theta_he1)}}het function 1 coefficient vector{p_end}
{synopt:{cmd:e(se_he1)}}het function 1 standard error vector{p_end}
{synopt:{cmd:e(b_first2)}}first stage 2 coefficient vector (if applicable){p_end}
{synopt:{cmd:e(se_first2)}}first stage 2 standard error vector (if applicable){p_end}
{synopt:{cmd:e(theta_he2)}}het function 2 coefficient vector (if applicable){p_end}
{synopt:{cmd:e(se_he2)}}het function 2 standard error vector (if applicable){p_end}
{synopt:...}(same pattern for first3, first4, etc.){p_end}
{synopt:{cmd:e(theta_hmain)}}main equation het function coefficient vector{p_end}
{synopt:{cmd:e(se_hmain)}}main equation het function standard error vector{p_end}

{p2col 5 24 28 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}


{marker references}{...}
{title:References}

{phang}
Klein, R. and F. Vella. 2010. 
Estimating a Class of Triangular Simultaneous Equations Models Without Exclusion Restrictions.
{it:Journal of Econometrics} 154: 154-164.

{phang}
FarrÃ©, L., Klein, R. and F. Vella. 2013. 
A Parametric Control Function Approach to Estimating the Returns to Schooling in the Absence of Exclusion Restrictions: An Application to the NLSY.
{it:Empirical Economics} 44(1): 111-133.


{title:Author}

{pstd}
Implementation by [Your Name]

{pstd}
Based on methodology by Roger Klein and Francis Vella

{pstd}
For questions or bug reports, contact: [your email]


{title:Also see}

{psee}
Online:  {helpb ivregress}, {helpb ivreg2}, {helpb ivprobit}
{p_end}
