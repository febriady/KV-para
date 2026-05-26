*! kvpara v1.0.0
*! Klein-Vella Parametric Control Function Estimation with full bootstrap
*! Date: May 26, 2026
*! Initial public release
*!
*! ============================================================================
*! PROGRAM SUMMARY: Klein-Vella Parametric Control Function Estimation
*! ============================================================================
*!
*! PURPOSE:
*! This command implements the Klein-Vella (2010) parametric control function 
*! approach for estimating models with endogenous regressors in the presence
*! of heteroskedasticity. The method allows the variance of errors to depend
*! on covariates through a flexible parametric specification.
*!
*! METHODOLOGY OVERVIEW:
*! 
*! Step 1: OLS ESTIMATION
*!   - Run baseline OLS regression (for comparison)
*!   - Conduct heteroskedasticity tests (Breusch-Pagan, White)
*!   - Store coefficients and test statistics
*!
*! Step 2: FIRST STAGE ESTIMATION
*!   - Regress each endogenous variable on its instruments/controls
*!   - Model heteroskedasticity: log(residualÃ‚Â²) = f(het_variables)
*!   - Obtain predicted standard deviations: ÃÆ’ÃŒâ€š = sqrt(exp(X'ÃŽÂ¸))
*!   - Conduct heteroskedasticity tests on first stage
*!
*! Step 3: ITERATIVE KLEIN-VELLA ESTIMATION
*!   - Iteration 1: Pure OLS (no control function)
*!   - Iterations 2+: Include control function terms
*!   - Control function: cor = (ÃÆ’_main / ÃÆ’_endog) Ãƒâ€” residual_endog
*!   - Update heteroskedasticity function for main equation each iteration
*!   - Converge coefficients through iteration
*!
*! Step 4: BOOTSTRAP STANDARD ERRORS (Optional)
*!   - Resample data with replacement
*!   - Re-estimate entire procedure (first stage + KV iterations)
*!   - Calculate bootstrap standard errors from replication distribution
*!   - Can bootstrap all stages or KV stage only (bootstrap_kv_only option)
*!
*! OUTPUT SECTIONS:
*!   - First stage regression(s) with heteroskedasticity tests
*!   - Heteroskedasticity function estimates (if nohettest not specified)
*!   - OLS results for comparison
*!   - Klein-Vella results with control function(s)
*!
*! REFERENCES:
*!   Klein, R. and F. Vella (2010). "Estimating a Class of Triangular 
*!   Simultaneous Equations Models Without Exclusion Restrictions," 
*!   Journal of Econometrics 154, 154-164.
*!
*! ============================================================================

program define kvpara, eclass
    version 19
    
    _kvpara `0'
end

program define _kvpara, eclass
    version 19
    
    **# Syntax and Initial Setup
    syntax varlist(min=2 numeric) [if] [in], ///
        CONTrols_main(varlist numeric) ///
        CONTrols_endog1(varlist numeric) ///
        [CONTrols_endog2(varlist numeric)] ///
        [CONTrols_endog3(varlist numeric)] ///
        [CONTrols_endog4(varlist numeric)] ///
        [CONTrols_endog5(varlist numeric)] ///
        [CONTrols_endog6(varlist numeric)] ///
        [CONTrols_endog7(varlist numeric)] ///
        [CONTrols_endog8(varlist numeric)] ///
        [CONTrols_endog9(varlist numeric)] ///
        [CONTrols_endog10(varlist numeric)] ///
        HET_main(varlist numeric) ///
        HET_endog1(varlist numeric) ///
        [HET_endog2(varlist numeric)] ///
        [HET_endog3(varlist numeric)] ///
        [HET_endog4(varlist numeric)] ///
        [HET_endog5(varlist numeric)] ///
        [HET_endog6(varlist numeric)] ///
        [HET_endog7(varlist numeric)] ///
        [HET_endog8(varlist numeric)] ///
        [HET_endog9(varlist numeric)] ///
        [HET_endog10(varlist numeric)] ///
        [ENDOG_categorical1(varlist numeric)] ///
        [ENDOG_categorical2(varlist numeric)] ///
        [ENDOG_categorical3(varlist numeric)] ///
        [ENDOG_categorical4(varlist numeric)] ///
        [ENDOG_categorical5(varlist numeric)] ///
        [ENDOG_categorical6(varlist numeric)] ///
        [ENDOG_categorical7(varlist numeric)] ///
        [ENDOG_categorical8(varlist numeric)] ///
        [ENDOG_categorical9(varlist numeric)] ///
        [ENDOG_categorical10(varlist numeric)] ///
        [ITERations(integer 10)] ///
        [BOOTstrap(integer 100)] ///
        [Level(cilevel)] ///
        [NODISplay] ///
        [NOHETtest] ///
        [BOOTstrap_kv_only] ///
        [GENerate(string)] ///
        [CLuster(varname)]
    
    **# Mark sample and check
    marksample touse
    markout `touse' `varlist' `controls_main' `het_main'
    
    // Mark out controls and het variables for all possible endogenous variables
    forvalues i = 1/10 {
        if "`controls_endog`i''" != "" {
            markout `touse' `controls_endog`i'' `het_endog`i''
        }
        // Mark out categorical variables if specified
        if "`endog_categorical`i''" != "" {
            markout `touse' `endog_categorical`i''
        }
    }
    
    quietly count if `touse'
    if r(N) == 0 error 2000
    local N = r(N)
    
    **# Parse generate option
    local gen_stub ""
    local gen_replace = 0
    if "`generate'" != "" {
        // Parse generate(stub [, replace])
        gettoken gen_stub gen_opts : generate, parse(",")
        local gen_stub = strtrim("`gen_stub'")
        if "`gen_opts'" != "" {
            local gen_opts = subinstr("`gen_opts'", ",", "", 1)
            local gen_opts = strtrim("`gen_opts'")
            if "`gen_opts'" == "replace" {
                local gen_replace = 1
            }
            else if "`gen_opts'" != "" {
                display as error "generate() suboption must be 'replace'"
                exit 198
            }
        }
        // Validate stub is a valid variable name prefix
        capture confirm name `gen_stub'_test
        if _rc {
            display as error "generate() stub must be a valid variable name prefix"
            exit 198
        }
    }
    
    **# Parse variables
    gettoken depvar endogvars : varlist
    
    // Count endogenous variables
    local nendog : word count `endogvars'
    
    // Validate we have controls and het for each endogenous variable
    forvalues i = 1/`nendog' {
        if "`controls_endog`i''" == "" {
            display as error "controls_endog`i'() required for endogenous variable `i'"
            exit 198
        }
        if "`het_endog`i''" == "" {
            display as error "het_endog`i'() required for endogenous variable `i'"
            exit 198
        }
    }
    
    // Check that there are no gaps in specification
    local next = `nendog' + 1
    if "`controls_endog`next''" != "" | "`het_endog`next''" != "" {
        display as error "Gap in endogenous variable specification detected"
        exit 198
    }
    
    **# Build lists for main equation
    // For each endogenous variable, use categorical version if specified, otherwise continuous
    local endogvars_main ""
    forvalues i = 1/`nendog' {
        local endog_i : word `i' of `endogvars'
        if "`endog_categorical`i''" != "" {
            // Use categorical dummies in main equation
            local endogvars_main "`endogvars_main' `endog_categorical`i''"
        }
        else {
            // Use continuous version in main equation
            local endogvars_main "`endogvars_main' `endog_i'"
        }
    }
    
    /*========================================================================*/
    **# STEP 1: OLS ESTIMATION
    /*========================================================================*/
    
    **## Run OLS regression
    quietly regress `depvar' `endogvars_main' `controls_main' if `touse'
    matrix b_ols = e(b)
    matrix V_ols = e(V)
    
    **## Heteroskedasticity tests for OLS
    quietly estat hettest, rhs
    local bp_chi2_ols = r(chi2)
    local bp_p_ols = r(p)
    local bp_df_ols = r(df)
    
    quietly estat imtest, white
    local white_chi2_ols = r(chi2)
    local white_p_ols = r(p)
    local white_df_ols = r(df)
    
    /*========================================================================*/
    **# STEP 2: FIRST STAGE ESTIMATION
    /*========================================================================*/
    
    **## Loop through all endogenous variables
    forvalues i = 1/`nendog' {
        local endog_i : word `i' of `endogvars'
        
        quietly {
            regress `endog_i' `controls_endog`i'' if `touse'
            matrix b_first`i' = e(b)
            matrix V_first`i' = e(V)
            local r2_first`i' = e(r2)
            local F_first`i' = e(F)
            
            **### Heteroskedasticity tests for first stage
            quietly estat hettest, rhs
            local bp_chi2_first`i' = r(chi2)
            local bp_p_first`i' = r(p)
            local bp_df_first`i' = r(df)
            
            quietly estat imtest, white
            local white_chi2_first`i' = r(chi2)
            local white_p_first`i' = r(p)
            local white_df_first`i' = r(df)
            
            **### Model heteroskedasticity in first stage
            tempvar resid_e`i'
            predict `resid_e`i'', residuals
            
            tempvar lresid2_e`i' xb_he`i' sd_e`i'
            gen `lresid2_e`i'' = ln(`resid_e`i''^2)
            regress `lresid2_e`i'' `het_endog`i'' if `touse'
            matrix theta_he`i' = e(b)
            matrix V_he`i' = e(V)
            predict `xb_he`i'', xb
            gen `sd_e`i'' = sqrt(exp(`xb_he`i''))
        }
    }
    
    /*========================================================================*/
    **# STEP 3: ITERATIVE KLEIN-VELLA ESTIMATION
    /*========================================================================*/
    
    // Note: Iteration 1 is pure OLS without control function (matches R approach)
    // Create tempvars for all control functions
    forvalues i = 1/`nendog' {
        tempvar cor`i'
    }
    
    // Create tempvar to store final iteration sd_main for CF component extraction
    tempvar sd_main_final
    
    **## Iterative procedure
    forvalues iter = 1/`iterations' {
        
        **### Regression step (with or without control function)
        if `iter' == 1 {
            // First iteration: Pure OLS (no control function)
            quietly regress `depvar' `endogvars_main' `controls_main' if `touse'
        }
        else {
            // Subsequent iterations: Include all control functions
            local cor_list ""
            forvalues i = 1/`nendog' {
                local cor_list "`cor_list' `cor`i''"
            }
            quietly regress `depvar' `endogvars_main' `controls_main' `cor_list' if `touse'
        }
        
        **### Store coefficients on final iteration
        if `iter' == `iterations' {
            matrix b_kv = e(b)
            matrix V_kv = e(V)
        }
        
        **### Model heteroskedasticity in main equation
        tempvar resid_main lresid2_main xb_hmain sd_main
        predict `resid_main', residuals
        quietly gen `lresid2_main' = ln(`resid_main'^2)
        quietly regress `lresid2_main' `het_main' if `touse'
        
        if `iter' == `iterations' {
            matrix theta_hmain = e(b)
            matrix V_hmain = e(V)
        }
        
        quietly predict `xb_hmain', xb
        quietly gen `sd_main' = sqrt(exp(`xb_hmain'))
        
        **### Create/update control functions
        forvalues i = 1/`nendog' {
            if `iter' == 1 {
                // Create control function for first time
                quietly gen `cor`i'' = (`sd_main' / `sd_e`i'') * `resid_e`i''
            }
            else {
                // Update existing control function
                quietly replace `cor`i'' = (`sd_main' / `sd_e`i'') * `resid_e`i''
            }
        }
        
        **### On final iteration, preserve sd_main for CF component extraction
        if `iter' == `iterations' {
            quietly gen `sd_main_final' = `sd_main'
        }
        
        drop `resid_main' `lresid2_main' `xb_hmain' `sd_main'
    }
    
    /*========================================================================*/
    **# STEP 3.5: CONTROL FUNCTION COMPONENT EXTRACTION
    /*========================================================================*/
    
    **## Compute summary statistics for CF components (always stored in e())
    // su (sigma_u) - from main equation, final iteration
    quietly summarize `sd_main_final' if `touse'
    local mean_su = r(mean)
    local sd_su = r(sd)
    
    // sv (sigma_v), vhat, scale, and cf - for each endogenous variable
    forvalues i = 1/`nendog' {
        // sv{i} - from first stage
        quietly summarize `sd_e`i'' if `touse'
        local mean_sv`i' = r(mean)
        local sd_sv`i' = r(sd)
        
        // vhat{i} - first stage residual
        quietly summarize `resid_e`i'' if `touse'
        local mean_vhat`i' = r(mean)
        local sd_vhat`i' = r(sd)
        
        // scale{i} - ratio su/sv
        tempvar scale`i'_temp
        quietly gen `scale`i'_temp' = `sd_main_final' / `sd_e`i''
        quietly summarize `scale`i'_temp' if `touse'
        local mean_scale`i' = r(mean)
        local sd_scale`i' = r(sd)
        drop `scale`i'_temp'
        
        // cf{i} - control function
        quietly summarize `cor`i'' if `touse'
        local mean_cf`i' = r(mean)
        local sd_cf`i' = r(sd)
    }
    
    **## Generate permanent variables if requested
    if "`gen_stub'" != "" {
        
        // su (sigma_u from main equation)
        local varname "`gen_stub'_su"
        if `gen_replace' == 1 {
            capture drop `varname'
        }
        quietly gen `varname' = `sd_main_final' if `touse'
        label variable `varname' "KV sigma_u (main eq het, final iter)"
        
        // Loop through endogenous variables
        forvalues i = 1/`nendog' {
            local endog_i : word `i' of `endogvars'
            
            // sv{i} (sigma_v from first stage)
            local varname "`gen_stub'_sv`i'"
            if `gen_replace' == 1 {
                capture drop `varname'
            }
            quietly gen `varname' = `sd_e`i'' if `touse'
            label variable `varname' "KV sigma_v for `endog_i' (first stage het)"
            
            // vhat{i} (first stage residual)
            local varname "`gen_stub'_vhat`i'"
            if `gen_replace' == 1 {
                capture drop `varname'
            }
            quietly gen `varname' = `resid_e`i'' if `touse'
            label variable `varname' "KV V-hat for `endog_i' (first stage residual)"
            
            // scale{i} (ratio su/sv)
            local varname "`gen_stub'_scale`i'"
            if `gen_replace' == 1 {
                capture drop `varname'
            }
            quietly gen `varname' = `sd_main_final' / `sd_e`i'' if `touse'
            label variable `varname' "KV scale for `endog_i' (sigma_u/sigma_v)"
            
            // cf{i} (control function)
            local varname "`gen_stub'_cf`i'"
            if `gen_replace' == 1 {
                capture drop `varname'
            }
            quietly gen `varname' = `cor`i'' if `touse'
            label variable `varname' "KV control function for `endog_i'"
        }
        
        display as text _newline "Generated variables with stub '`gen_stub'':"
        display as text "  `gen_stub'_su        - sigma_u (main equation)"
        forvalues i = 1/`nendog' {
            local endog_i : word `i' of `endogvars'
            display as text "  `gen_stub'_sv`i'       - sigma_v for `endog_i'"
            display as text "  `gen_stub'_vhat`i'     - V-hat for `endog_i'"
            display as text "  `gen_stub'_scale`i'      - scale (sigma_u/sigma_v) for `endog_i'"
            display as text "  `gen_stub'_cf`i'       - control function for `endog_i'"
        }
    }
    
    /*========================================================================*/
    **# STEP 4: BOOTSTRAP STANDARD ERRORS
    /*========================================================================*/
    
    if `bootstrap' > 0 {
        
        **## Save analysis dataset
        tempfile bootdata
        quietly save `bootdata', replace
        
        **## Matrix dimensions
        local k_ols = colsof(b_ols)
        local k_kv = colsof(b_kv)
        local k_hmain = colsof(theta_hmain)
        forvalues i = 1/`nendog' {
            local k_first`i' = colsof(b_first`i')
            local k_he`i' = colsof(theta_he`i')
        }
        
        **## Initialize bootstrap result matrices
        if "`bootstrap_kv_only'" == "" {
            // Bootstrap everything
            tempname boot_ols boot_kv boot_hmain
            matrix `boot_ols' = J(`bootstrap', `k_ols', .)
            matrix `boot_kv' = J(`bootstrap', `k_kv', .)
            matrix `boot_hmain' = J(`bootstrap', `k_hmain', .)
            
            forvalues i = 1/`nendog' {
                tempname boot_first`i' boot_he`i'
                matrix `boot_first`i'' = J(`bootstrap', `k_first`i'', .)
                matrix `boot_he`i'' = J(`bootstrap', `k_he`i'', .)
            }
        }
        else {
            // Bootstrap KV only
            tempname boot_kv boot_hmain
            matrix `boot_kv' = J(`bootstrap', `k_kv', .)
            matrix `boot_hmain' = J(`bootstrap', `k_hmain', .)
        }
        
        local progress_step = max(1, floor(`bootstrap' / 10))
        local boot_success = 0
        
        **## Bootstrap replication loop
        forvalues b = 1/`bootstrap' {
            quietly {
                use `bootdata', clear
                preserve
                
                // Cluster bootstrap if specified, otherwise individual bootstrap
                if "`cluster'" != "" {
                    bsample, cluster(`cluster')
                }
                else {
                    bsample
                }
                
                capture {
                    **### OLS in bootstrap sample
                    regress `depvar' `endogvars_main' `controls_main'
                    tempname b_ols_b
                    matrix `b_ols_b' = e(b)
                    
                    **### First stage and het models for all endogenous variables
                    forvalues i = 1/`nendog' {
                        local endog_i : word `i' of `endogvars'
                        regress `endog_i' `controls_endog`i''
                        tempname b_first`i'_b
                        matrix `b_first`i'_b' = e(b)
                        tempvar resid_e`i'_b
                        predict `resid_e`i'_b', residuals
                        
                        **### Heteroskedasticity model for first stage
                        tempvar lresid2_e`i'_b xb_he`i'_b sd_e`i'_b
                        gen `lresid2_e`i'_b' = ln(`resid_e`i'_b'^2)
                        regress `lresid2_e`i'_b' `het_endog`i''
                        tempname theta_he`i'_b
                        matrix `theta_he`i'_b' = e(b)
                        predict `xb_he`i'_b', xb
                        gen `sd_e`i'_b' = sqrt(exp(`xb_he`i'_b'))
                    }
                    
                    **### Iterative KV in bootstrap sample
                    // Create tempvars for all control functions
                    forvalues i = 1/`nendog' {
                        tempvar cor`i'_b
                    }
                    
                    forvalues iter = 1/`iterations' {
                        // Iteration 1: Pure OLS without control function
                        if `iter' == 1 {
                            regress `depvar' `endogvars_main' `controls_main'
                        }
                        else {
                            local cor_list_b ""
                            forvalues i = 1/`nendog' {
                                local cor_list_b "`cor_list_b' `cor`i'_b'"
                            }
                            regress `depvar' `endogvars_main' `controls_main' `cor_list_b'
                        }
                        
                        tempvar resid_main_b lresid2_main_b xb_hmain_b sd_main_b
                        predict `resid_main_b', residuals
                        gen `lresid2_main_b' = ln(`resid_main_b'^2)
                        regress `lresid2_main_b' `het_main'
                        
                        if `iter' == `iterations' {
                            tempname theta_hmain_b
                            matrix `theta_hmain_b' = e(b)
                        }
                        
                        predict `xb_hmain_b', xb
                        gen `sd_main_b' = sqrt(exp(`xb_hmain_b'))
                        
                        // Create/update control functions
                        forvalues i = 1/`nendog' {
                            if `iter' == 1 {
                                gen `cor`i'_b' = (`sd_main_b' / `sd_e`i'_b') * `resid_e`i'_b'
                            }
                            else {
                                replace `cor`i'_b' = (`sd_main_b' / `sd_e`i'_b') * `resid_e`i'_b'
                            }
                        }
                        
                        drop `resid_main_b' `lresid2_main_b' `xb_hmain_b' `sd_main_b'
                    }
                    
                    **### Final KV regression in bootstrap
                    local cor_list_b ""
                    forvalues i = 1/`nendog' {
                        local cor_list_b "`cor_list_b' `cor`i'_b'"
                    }
                    regress `depvar' `endogvars_main' `controls_main' `cor_list_b'
                    tempname b_kv_b
                    matrix `b_kv_b' = e(b)
                    
                    **### Store bootstrap results
                    if "`bootstrap_kv_only'" == "" {
                        // Store all results
                        forvalues i = 1/`k_ols' {
                            matrix `boot_ols'[`b', `i'] = `b_ols_b'[1, `i']
                        }
                        forvalues j = 1/`nendog' {
                            forvalues i = 1/`k_first`j'' {
                                matrix `boot_first`j''[`b', `i'] = `b_first`j'_b'[1, `i']
                            }
                            forvalues i = 1/`k_he`j'' {
                                matrix `boot_he`j''[`b', `i'] = `theta_he`j'_b'[1, `i']
                            }
                        }
                    }
                    
                    // Always store KV results
                    forvalues i = 1/`k_kv' {
                        matrix `boot_kv'[`b', `i'] = `b_kv_b'[1, `i']
                    }
                    forvalues i = 1/`k_hmain' {
                        matrix `boot_hmain'[`b', `i'] = `theta_hmain_b'[1, `i']
                    }
                    
                    local boot_success = `boot_success' + 1
                }
                
                restore
            }
            
            **### Display progress indicator
            if mod(`b', `progress_step') == 0 {
                display as text "." _continue
            }
        }
        display ""
        
        **## Calculate bootstrap standard errors
        if "`bootstrap_kv_only'" == "" {
            // Bootstrap SEs for everything
            matrix se_ols = J(1, `k_ols', 0)
            matrix se_kv = J(1, `k_kv', 0)
            matrix se_hmain = J(1, `k_hmain', 0)
            forvalues j = 1/`nendog' {
                matrix se_first`j' = J(1, `k_first`j'', 0)
                matrix se_he`j' = J(1, `k_he`j'', 0)
            }
            
            **### Calculate SE from bootstrap replicates - OLS
            preserve
            clear
            quietly svmat `boot_ols', names(b_ols_)
            forvalues i = 1/`k_ols' {
                quietly summarize b_ols_`i'
                matrix se_ols[1, `i'] = r(sd)
            }
            restore, preserve
            
            **### Calculate SE from bootstrap replicates - KV
            clear
            quietly svmat `boot_kv', names(b_kv_)
            forvalues i = 1/`k_kv' {
                quietly summarize b_kv_`i'
                matrix se_kv[1, `i'] = r(sd)
            }
            restore, preserve
            
            **### Calculate SE from bootstrap replicates - First stages and het functions
            forvalues j = 1/`nendog' {
                clear
                quietly svmat `boot_first`j'', names(b_first`j'_)
                forvalues i = 1/`k_first`j'' {
                    quietly summarize b_first`j'_`i'
                    matrix se_first`j'[1, `i'] = r(sd)
                }
                restore, preserve
                
                clear
                quietly svmat `boot_he`j'', names(b_he`j'_)
                forvalues i = 1/`k_he`j'' {
                    quietly summarize b_he`j'_`i'
                    matrix se_he`j'[1, `i'] = r(sd)
                }
                restore, preserve
            }
            
            **### Calculate SE from bootstrap replicates - Het function main
            clear
            quietly svmat `boot_hmain', names(b_hmain_)
            forvalues i = 1/`k_hmain' {
                quietly summarize b_hmain_`i'
                matrix se_hmain[1, `i'] = r(sd)
            }
            restore
        }
        else {
            **## Bootstrap KV only, analytical SEs for rest
            matrix se_kv = J(1, `k_kv', 0)
            matrix se_hmain = J(1, `k_hmain', 0)
            
            preserve
            clear
            quietly svmat `boot_kv', names(b_kv_)
            forvalues i = 1/`k_kv' {
                quietly summarize b_kv_`i'
                matrix se_kv[1, `i'] = r(sd)
            }
            restore, preserve
            
            clear
            quietly svmat `boot_hmain', names(b_hmain_)
            forvalues i = 1/`k_hmain' {
                quietly summarize b_hmain_`i'
                matrix se_hmain[1, `i'] = r(sd)
            }
            restore
            
            **### Analytical SEs for OLS and first stages
            matrix se_ols = J(1, `k_ols', 0)
            forvalues i = 1/`=colsof(b_ols)' {
                matrix se_ols[1, `i'] = sqrt(V_ols[`i', `i'])
            }
            
            forvalues j = 1/`nendog' {
                matrix se_first`j' = J(1, `k_first`j'', 0)
                forvalues i = 1/`=colsof(b_first`j')' {
                    matrix se_first`j'[1, `i'] = sqrt(V_first`j'[`i', `i'])
                }
                
                matrix se_he`j' = J(1, `k_he`j'', 0)
                forvalues i = 1/`=colsof(theta_he`j')' {
                    matrix se_he`j'[1, `i'] = sqrt(V_he`j'[`i', `i'])
                }
            }
        }
    }
    else {
        **## No bootstrap - use analytical standard errors
        matrix se_ols = J(1, colsof(b_ols), 0)
        forvalues i = 1/`=colsof(b_ols)' {
            matrix se_ols[1, `i'] = sqrt(V_ols[`i', `i'])
        }
        
        matrix se_kv = J(1, colsof(b_kv), 0)
        forvalues i = 1/`=colsof(b_kv)' {
            matrix se_kv[1, `i'] = sqrt(V_kv[`i', `i'])
        }
        
        forvalues j = 1/`nendog' {
            matrix se_first`j' = J(1, colsof(b_first`j'), 0)
            forvalues i = 1/`=colsof(b_first`j')' {
                matrix se_first`j'[1, `i'] = sqrt(V_first`j'[`i', `i'])
            }
            
            matrix se_he`j' = J(1, colsof(theta_he`j'), 0)
            forvalues i = 1/`=colsof(theta_he`j')' {
                matrix se_he`j'[1, `i'] = sqrt(V_he`j'[`i', `i'])
            }
        }
        
        matrix se_hmain = J(1, colsof(theta_hmain), 0)
        forvalues i = 1/`=colsof(theta_hmain)' {
            matrix se_hmain[1, `i'] = sqrt(V_hmain[`i', `i'])
        }
        
        local boot_success = 0
    }
    
    /*========================================================================*/
    **# DISPLAY RESULTS
    /*========================================================================*/
    
    if "`nodisplay'" == "" {
        display _newline
        display as text "{hline 78}"
        display as text "KLEIN-VELLA CONTROL FUNCTION ESTIMATION"
        display as text "{hline 78}"
        
        **## First stages for all endogenous variables
        forvalues i = 1/`nendog' {
            local endog_i : word `i' of `endogvars'
            display _newline
            display as text "{hline 78}"
            display as text "SECTION `i': FIRST STAGE - " as result "`endog_i'"
            display as text "{hline 78}"
            display as text "Dependent variable: " as result "`endog_i'"
            display _newline
            
            _kvpara_display_results, b(b_first`i') se(se_first`i') ///
                varlist(`controls_endog`i'' _cons) bootse(`bootstrap')
            
            display _newline
            display as text "N: " as result `N'
            display as text "R-squared: " as result %6.4f `r2_first`i''
            display as text "F-statistic: " as result %8.2f `F_first`i''
            display as text "Heteroskedasticity Tests:"
            display as text "  Breusch-Pagan:  chi2(" as result `bp_df_first`i'' as text ") = " ///
                as result %8.2f `bp_chi2_first`i'' as text "    p-value = " as result %6.4f `bp_p_first`i''
            display as text "  White:          chi2(" as result `white_df_first`i'' as text ") = " ///
                as result %8.2f `white_chi2_first`i'' as text "    p-value = " as result %6.4f `white_p_first`i''
            if `bootstrap' > 0 & "`bootstrap_kv_only'" == "" {
                display as text "Bootstrap: " as result `boot_success' "/" `bootstrap' " successful"
                display as text "Standard errors: Bootstrap"
            }
            else {
                display as text "Standard errors: Analytical"
            }
            display as text "Significance: *** p<0.01, ** p<0.05, * p<0.1"
        }
        
        **## Heteroskedasticity function sections
        if "`nohettest'" == "" {
            
            **### Het functions for all endogenous variables
            forvalues i = 1/`nendog' {
                local endog_i : word `i' of `endogvars'
                local section = `nendog' + `i'
                display _newline
                display as text "{hline 78}"
                display as text "SECTION `section': HETEROSKEDASTICITY FUNCTION - " as result "`endog_i'"
                display as text "{hline 78}"
                display as text "Dependent variable: ln(residual^2) from first stage"
                display _newline
                
                _kvpara_display_het, b(theta_he`i') se(se_he`i') ///
                    varlist(_cons `het_endog`i'') bootse(`bootstrap')
                
                display _newline
                display as text "N: " as result `N'
                display as text "Iterations: " as result `iterations'
                if `bootstrap' > 0 & "`bootstrap_kv_only'" == "" {
                    display as text "Bootstrap: " as result `boot_success' "/" `bootstrap' " successful"
                    display as text "Standard errors: Bootstrap"
                }
                else {
                    display as text "Standard errors: Analytical"
                }
                display as text "Significance: *** p<0.01, ** p<0.05, * p<0.1"
            }
            
            **### Het function for main equation
            local section = `nendog' * 2 + 1
            display _newline
            display as text "{hline 78}"
            display as text "SECTION `section': HETEROSKEDASTICITY FUNCTION - MAIN EQUATION"
            display as text "{hline 78}"
            display as text "Dependent variable: ln(residual^2) from main equation"
            display _newline
            
            _kvpara_display_het, b(theta_hmain) se(se_hmain) ///
                varlist(_cons `het_main') bootse(`bootstrap')
            
            display _newline
            display as text "N: " as result `N'
            display as text "Iterations: " as result `iterations'
            if `bootstrap' > 0 {
                display as text "Bootstrap: " as result `boot_success' "/" `bootstrap' " successful"
                display as text "Standard errors: Bootstrap"
            }
            else {
                display as text "Standard errors: Analytical"
            }
            display as text "Significance: *** p<0.01, ** p<0.05, * p<0.1"
        }
        
        **## OLS results
        local section = cond("`nohettest'" == "", `nendog' * 2 + 2, `nendog' + 1)
        display _newline
        display as text "{hline 78}"
        display as text "SECTION `section': OLS RESULTS"
        display as text "{hline 78}"
        display as text "Dependent variable: " as result "`depvar'"
        
        // Display note about categorical variables if any
        local has_categorical = 0
        forvalues i = 1/`nendog' {
            if "`endog_categorical`i''" != "" {
                local has_categorical = 1
            }
        }
        if `has_categorical' == 1 {
            display as text "(Categorical dummies shown for endogenous variables with endog_categorical# specified)"
        }
        display _newline
        
        _kvpara_display_results, b(b_ols) se(se_ols) ///
            varlist(`endogvars_main' `controls_main' _cons) bootse(`bootstrap')
        
        display _newline
        display as text "N: " as result `N'
        display as text "Heteroskedasticity Tests:"
        display as text "  Breusch-Pagan:  chi2(" as result `bp_df_ols' as text ") = " ///
            as result %8.2f `bp_chi2_ols' as text "    p-value = " as result %6.4f `bp_p_ols'
        display as text "  White:          chi2(" as result `white_df_ols' as text ") = " ///
            as result %8.2f `white_chi2_ols' as text "    p-value = " as result %6.4f `white_p_ols'
        if `bootstrap' > 0 & "`bootstrap_kv_only'" == "" {
            display as text "Bootstrap: " as result `boot_success' "/" `bootstrap' " successful"
            display as text "Standard errors: Bootstrap"
        }
        else {
            display as text "Standard errors: Analytical"
        }
        display as text "Significance: *** p<0.01, ** p<0.05, * p<0.1"
        
        **## Klein-Vella results
        local section = cond("`nohettest'" == "", `nendog' * 2 + 3, `nendog' + 2)
        display _newline
        display as text "{hline 78}"
        display as text "SECTION `section': KLEIN-VELLA RESULTS"
        display as text "{hline 78}"
        display as text "Dependent variable: " as result "`depvar'"
        
        // Display note about categorical variables if any
        if `has_categorical' == 1 {
            display as text "(Categorical dummies shown for endogenous variables with endog_categorical# specified)"
        }
        display _newline
        
        // Build control function list for display
        local cor_names ""
        forvalues i = 1/`nendog' {
            local cor_names "`cor_names' _cor`i'"
        }
        _kvpara_display_results, b(b_kv) se(se_kv) ///
            varlist(`endogvars_main' `controls_main' `cor_names' _cons) ///
            bootse(`bootstrap')
        
        display _newline
        display as text "N: " as result `N'
        display as text "Iterations: " as result `iterations'
        if `bootstrap' > 0 {
            display as text "Bootstrap: " as result `boot_success' "/" `bootstrap' " successful"
            display as text "Standard errors: Bootstrap"
        }
        else {
            display as text "Standard errors: Analytical"
        }
        display as text "Significance: *** p<0.01, ** p<0.05, * p<0.1"
    }
    
    /*========================================================================*/
    **# POST RESULTS TO E()
    /*========================================================================*/
    
    // Post KV results as main ereturn results
    // Build variable names list for KV results
    local cor_names ""
    forvalues i = 1/`nendog' {
        local cor_names "`cor_names' _cor`i'"
    }
    local varnames "`endogvars_main' `controls_main' `cor_names' _cons"
    
    tempname b V
    matrix `b' = b_kv
    matrix colnames `b' = `varnames'
    
    matrix `V' = diag(se_kv)
    matrix `V' = `V' * `V''
    matrix colnames `V' = `varnames'
    matrix rownames `V' = `varnames'
    
    ereturn post `b' `V', esample(`touse') depname(`depvar') obs(`N')
    
    **## Store scalars
    ereturn scalar N = `N'
    ereturn scalar iterations = `iterations'
    ereturn scalar bootstrap = `bootstrap'
    ereturn scalar boot_success = `boot_success'
    ereturn scalar nendog = `nendog'
    
    // Store first stage statistics for all endogenous variables
    forvalues i = 1/`nendog' {
        ereturn scalar r2_first`i' = `r2_first`i''
        ereturn scalar F_first`i' = `F_first`i''
        ereturn scalar bp_chi2_first`i' = `bp_chi2_first`i''
        ereturn scalar bp_p_first`i' = `bp_p_first`i''
        ereturn scalar white_chi2_first`i' = `white_chi2_first`i''
        ereturn scalar white_p_first`i' = `white_p_first`i''
    }
    
    ereturn scalar bp_chi2_ols = `bp_chi2_ols'
    ereturn scalar bp_p_ols = `bp_p_ols'
    ereturn scalar white_chi2_ols = `white_chi2_ols'
    ereturn scalar white_p_ols = `white_p_ols'
    
    // Store CF component summary statistics
    ereturn scalar mean_su = `mean_su'
    ereturn scalar sd_su = `sd_su'
    forvalues i = 1/`nendog' {
        ereturn scalar mean_sv`i' = `mean_sv`i''
        ereturn scalar sd_sv`i' = `sd_sv`i''
        ereturn scalar mean_vhat`i' = `mean_vhat`i''
        ereturn scalar sd_vhat`i' = `sd_vhat`i''
        ereturn scalar mean_scale`i' = `mean_scale`i''
        ereturn scalar sd_scale`i' = `sd_scale`i''
        ereturn scalar mean_cf`i' = `mean_cf`i''
        ereturn scalar sd_cf`i' = `sd_cf`i''
    }
    
    **## Store local macros
    ereturn local cmd "kvpara"
    ereturn local depvar "`depvar'"
    
    // Store endogenous variable names (continuous version used in first stage)
    forvalues i = 1/`nendog' {
        local endog_i : word `i' of `endogvars'
        ereturn local endog`i' "`endog_i'"
    }
    
    // Store categorical variable names if specified
    forvalues i = 1/`nendog' {
        if "`endog_categorical`i''" != "" {
            ereturn local endog`i'_categorical "`endog_categorical`i''"
        }
    }
    
    **## Store matrices
    ereturn matrix b_ols = b_ols
    ereturn matrix se_ols = se_ols
    ereturn matrix b_kv = b_kv
    ereturn matrix se_kv = se_kv
    ereturn matrix theta_hmain = theta_hmain
    ereturn matrix se_hmain = se_hmain
    
    forvalues i = 1/`nendog' {
        ereturn matrix b_first`i' = b_first`i'
        ereturn matrix se_first`i' = se_first`i'
        ereturn matrix theta_he`i' = theta_he`i'
        ereturn matrix se_he`i' = se_he`i'
    }
end

/*============================================================================*/
**# HELPER PROGRAMS
/*============================================================================*/

program define _kvpara_display_reg
    syntax, b(name) v(name) varlist(string)
    
    local k = colsof(`b')
    
    display as text %20s "Variable" _col(30) "Coef." _col(42) "Std.Err." ///
        _col(54) "t" _col(62) "P>|t|"
    display as text "{hline 78}"
    
    tokenize `varlist'
    forvalues i = 1/`k' {
        local var "``i''"
        local coef = `b'[1, `i']
        local se = sqrt(`v'[`i', `i'])
        local t = `coef' / `se'
        local p = 2 * ttail(e(N) - `k', abs(`t'))
        
        local stars ""
        if `p' < 0.01 local stars "***"
        else if `p' < 0.05 local stars "**"
        else if `p' < 0.10 local stars "*"
        
        display as text %20s "`var'" ///
            as result _col(28) %9.3f `coef' "`stars'" ///
            _col(42) %9.3f `se' ///
            _col(54) %6.3f `t' ///
            _col(62) %6.4f `p'
    }
end

program define _kvpara_display_het
    syntax, b(name) se(name) varlist(string) bootse(integer)
    
    local k = colsof(`b')
    
    display as text %20s "Variable" _col(30) "Coef." _col(42) "Std.Err." ///
        _col(54) "t"
    display as text "{hline 78}"
    
    tokenize `varlist'
    forvalues i = 1/`k' {
        local var "``i''"
        local coef = `b'[1, `i']
        local se_i = `se'[1, `i']
        local t = `coef' / `se_i'
        
        local stars ""
        if abs(`t') > 2.576 local stars "***"
        else if abs(`t') > 1.96 local stars "**"
        else if abs(`t') > 1.645 local stars "*"
        
        display as text %20s "`var'" ///
            as result _col(28) %9.3f `coef' "`stars'" ///
            _col(42) %9.3f `se_i' ///
            _col(54) %6.3f `t'
    }
end

program define _kvpara_display_results
    syntax, b(name) se(name) varlist(string) bootse(integer)
    
    local k = colsof(`b')
    
    display as text %20s "Variable" _col(30) "Coef." _col(42) "Std.Err." ///
        _col(54) "t"
    display as text "{hline 78}"
    
    tokenize `varlist'
    forvalues i = 1/`k' {
        local var "``i''"
        local coef = `b'[1, `i']
        local se_i = `se'[1, `i']
        local t = `coef' / `se_i'
        
        local stars ""
        if abs(`t') > 2.576 local stars "***"
        else if abs(`t') > 1.96 local stars "**"
        else if abs(`t') > 1.645 local stars "*"
        
        display as text %20s "`var'" ///
            as result _col(28) %9.3f `coef' "`stars'" ///
            _col(42) %9.3f `se_i' ///
            _col(54) %6.3f `t'
    }
end
