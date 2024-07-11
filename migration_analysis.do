***************************
//Configure the Environment
***************************
drop _all
clear all           
capture log close    
set more off        
set logtype text 
set linesize 100
pause on

*************************************
//Combining and Cleaning the datasets
*************************************
*** Set working directory ***	
* Antisha's computer
else if "`c(username)'"== "DELL" {
	cd "D:\OneDrive - London School of Economics\Extended Essay-DESKTOP-HEI11BP\DTA_NSS_R64_10_2"
}

use  "cleaned_migration_data.dta", clear

** Kernel Density Estimate 
preserve 
keep if year< 2008
* Create a yearly proportion of out-migrating households
collapse (mean) migration_ind, by(year)
* Save the result in a new variable
generate proportion_out_migrate = migration_ind
kdensity proportion_out_migrate, normal title("Kernel Density Estimate of Yearly Proportion of Out-Migrating Households") ///
    xtitle("Proportion of Out-Migration") ///
    ytitle("Density") ///
    xlabel(0(0.1)1, grid) ///
    ylabel(, grid) ///
    lwidth(medium) lcolor(blue) ///
    legend(order(1 "KDE" 2 "Normal Density") pos(11) cols(1)) ///
    note("Data Source: NSSO 64th Round Household Survey") ///
    caption("The plot shows the estimated density of the yearly proportion of households that out-migrated due to floods from 1980 to 2007.")

restore


** Table Summary
	* Generate dummy variables for each category
tab HHold_size, gen(dum_HHsize)
tab HH_type, gen(dum_type)
tab religion, gen(dum_religion)
tab social_group, gen(dum_social_group)
tab  HH_land_possessed, gen(dum_land)
tab expenditure_tertile, gen(dum_tertile)
tab sex, gen(dum_sex)
tab age_cat, gen(dum_age)
tab marital_status, gen(dum_marital)
tab general_education, gen(dum_edu)
tab usual_principal_activity, gen(dum_upa)

* Summarize to get the mean (proportion) of each dummy variable
ssc install estout

* Summarize the variables and store the results
estpost summarize dum_HHsize* dum_type* dum_religion* dum_social_group* dum_land* dum_tertile* dum_sex* dum_age* dum_marital* dum_edu* dum_upa*

* Store the summary statistics
eststo summstats: estpost summarize dum_HHsize* dum_type* dum_religion* dum_social_group* dum_land* dum_tertile* dum_sex* dum_age* dum_marital* dum_edu* dum_upa*
eststo all_sample: estpost summarize dum_HHsize* dum_type* dum_religion* dum_social_group* dum_land* dum_tertile* dum_sex* dum_age* dum_marital* dum_edu* dum_upa* if moving == 1
eststo rural_migrant: estpost summarize dum_HHsize* dum_type* dum_religion* dum_social_group* dum_land* dum_tertile* dum_sex* dum_age* dum_marital* dum_edu* dum_upa* if location_last_upr == 1

* Display the stored results in a table
esttab summstats all_sample rural_migrant using table5.rtf, replace main(mean %6.2f) aux(sd) mtitle("All Households" "Migrants Households" "Rural-total Migrant Households")


** IV Checks
rename annual flood_intensity

cap drop total_damage_hat
ivreg2 location_last_upr (total_damage = flood_intensity), robust

regress total_damage flood_intensity, robust
predict total_damage_hat, xb

cap drop ln_flood_damage
gen ln_flood_damage = ln(total_damage_hat)

save "cleaned_migration_data.dta", replace


** Declaring it as the Panel Data Set
cap drop time_variable
gen time_variable = the_year if year<2008
xtset Key_HH time_variable
//Time running from 1981 to 2007


//Creating local for Household Characterstics
local Household_characteristics HHold_size HH_type religion social_group land_holdings  expenditure_tertile
local Head_features sex age marital_status general_education usual_principal_activity
//year dummy
//district dummy
local damage_vars ln_total_damage ln_aff_population ln_cattle_lost ln_human_lives
				

/*
ivreg2 location_last_upr (moving = flood_intensity), robust

ivreg2 location_last_upr (total_damage = flood_intensity), robust
regress total_damage flood_intensity
predict flood_damage_pred, xb
gen flood_damage_pred_adj = flood_damage_pred + 0.01
gen ln_flood_damage_pred = log(flood_damage_pred_adj)
sum ln_flood_damage_pred, detail
*/

		
//drop if missing(location_last_upr)
** Creating flood shock variable 
// Example assuming data is grouped by "region"
bysort state: pctile rainfall_90 = annual, p(90)
gen flood_shock = (annual > rainfall_90)


				
*******************
*GRAPHICAL ANALYSIS
*******************
sort year total_damage State
order State year, before(total_damage)
* Preserve the data before any data manipulation
* Preserve the data before any data manipulation
preserve 

* Define the five-year periods and the last seven-year period
cap drop period
gen period = .
replace period = 1980 if inrange(year, 1980, 1984)
replace period = 1985 if inrange(year, 1985, 1989)
replace period = 1990 if inrange(year, 1990, 1994)
replace period = 1995 if inrange(year, 1995, 1999)
replace period = 2000 if inrange(year, 2000, 2004)
replace period = 2005 if inrange(year, 2005, 2009)
replace period = 2010 if inrange(year, 2010, 2017)

* Check the grouping
list year period if year >= 1980 & year <= 2017, sepby(period)

* Summarize the data manually for each period and store the results
eststo clear

foreach p in 1980 1985 1990 1995 2000 2005 2010 {
    estpost summarize aff_population human_lives cattle_lost total_damage if period == `p'
    eststo period_`p'
}

* Display the stored results in a table, row-wise for each period
esttab period_1980 period_1985 period_1990 period_1995 period_2000 period_2005 period_2010 using damage_statistics_final.rtf, replace ///
       cells("mean sd") ///
       varlabels(aff_population "Affected Population" human_lives "Human Lives Lost" cattle_lost "Cattle Lost" total_damage "Total Damage") ///
       mtitles("1980-1984" "1985-1989" "1990-1994" "1995-1999" "2000-2004" "2005-2009" "2010-2017") ///
       title("Summary Statistics of Flood Damage (1980-2017)") ///
       alignment(center)

* Restore the original data
restore


***************
**PAY ATTENTION

//BASELINE REGRESSION

**(0)
logit moving ln_total_damage HHold_size HH_type religion social_group land_holdings  expenditure_tertile sex age marital_status general_education usual_principal_activity district_dummy2-district_dummy70 year_dummy2-year_dummy27, or vce(cluster state)

outreg2 using table_inst1.doc, replace eform ctitle("Odds Ratios") ///
    addstat(N, e(N), "Pseudo R-squared", e(r2_p), "Log Likelihood", e(ll))
	
** (0.1)
logit moving ln_flood_damage HHold_size HH_type religion social_group land_holdings  expenditure_tertile sex age marital_status general_education usual_principal_activity district_dummy2-district_dummy70 year_dummy2-year_dummy27, or vce(cluster state)

outreg2 using table_inst1.doc, append eform ctitle("Odds Ratios") ///
    addstat(N, e(N), "Pseudo R-squared", e(r2_p), "Log Likelihood", e(ll))
	
**(1)
logit location_last_upr ln_total_damage HHold_size HH_type religion social_group land_holdings  expenditure_tertile sex age marital_status general_education usual_principal_activity year_dummy2-year_dummy27, or vce(cluster state)

outreg2 using table_inst1.doc, append eform ctitle("Odds Ratios") ///
    addstat(N, e(N), "Pseudo R-squared", e(r2_p), "Log Likelihood", e(ll))
	
**(2)
logit location_last_upr ln_total_damage HHold_size HH_type religion social_group land_holdings expenditure_tertile sex age marital_status general_education usual_principal_activity year_dummy2-year_dummy27 district_dummy2-district_dummy70, or vce(cluster state)

outreg2 using table_inst1.doc, append eform ctitle("Odds Ratios") ///
    addstat(N, e(N), "Pseudo R-squared", e(r2_p), "Log Likelihood", e(ll))

**(3)
logit location_last_upr ln_flood_damage HHold_size HH_type religion social_group land_holdings expenditure_tertile sex age marital_status general_education usual_principal_activity year_dummy2-year_dummy27 district_dummy2-district_dummy70, or vce(cluster state)

outreg2 using table_inst1.doc, append eform ctitle("Odds Ratios") ///
    addstat(N, e(N), "Pseudo R-squared", e(r2_p), "Log Likelihood", e(ll))
	
*********************************

* Example of plotting interaction effects using margins and marginsplot

//MECHANISM TESTING 
// (1)
logit location_last_upr c.ln_flood_damage#c.ln_aff_population HHold_size HH_type religion social_group land_holdings expenditure_tertile sex age marital_status general_education usual_principal_activity year_dummy2-year_dummy27 district_dummy2-district_dummy70, or vce(cluster state)

outreg2 using tableivt.doc, replace eform

logit location_last_upr c.ln_flood_damage#c.ln_aff_population#i.main_pattern HHold_size HH_type religion social_group land_holdings expenditure_tertile sex age marital_status general_education usual_principal_activity year_dummy2-year_dummy27 district_dummy2-district_dummy70, or vce(cluster state)
outreg2 using tableivt.doc, append eform

// (2)
logit location_last_upr c.ln_flood_damage#c.ln_human_lives HHold_size HH_type religion social_group land_holdings expenditure_tertile sex age marital_status general_education usual_principal_activity year_dummy2-year_dummy27 district_dummy2-district_dummy70, or vce(cluster state)

outreg2 using tableivt.doc, append eform

logit location_last_upr c.ln_flood_damage#c.ln_human_lives#i.main_pattern HHold_size HH_type religion social_group land_holdings expenditure_tertile sex age marital_status general_education usual_principal_activity year_dummy2-year_dummy27 district_dummy2-district_dummy70, or vce(cluster state)

outreg2 using tableivt.doc, append eform

// (3)
logit location_last_upr c.ln_flood_damage#c.ln_cattle_lost HHold_size HH_type religion social_group land_holdings expenditure_tertile sex age marital_status general_education usual_principal_activity year_dummy2-year_dummy27 district_dummy2-district_dummy70, or vce(cluster state)

outreg2 using tableivt.doc, append eform

logit location_last_upr c.ln_flood_damage#c.ln_cattle_lost#i.main_pattern HHold_size HH_type religion social_group land_holdings expenditure_tertile sex age marital_status general_education usual_principal_activity year_dummy2-year_dummy27 district_dummy2-district_dummy70, or vce(cluster state)

outreg2 using tableivt.doc, append eform

*********************************
** gen perm = type_outmigration if location_last_upr == 1
** Regression on permanent rural out-migration
************************************

*****************************
//BY EXPENDITURE TERTILE
	
(1)
logit location_last_upr c.flood_damage_pred#c.ln_aff_population HHold_size HH_type religion social_group land_holdings  expenditure_tertile sex age marital_status general_education usual_principal_activity year_dummy2-year_dummy27 district_dummy2-district_dummy70, or robust

// Ensure margins have been calculated
margins, at(expenditure_tertile=(1 2 3))

// Generate a refined black and white margins plot
marginsplot, recastci(rarea) scheme(s1mono) ///
    ytitle("Predicted Probability of Individual out-migrating Rural-Total seasonally")  ///
    xtitle("Economic Groups by Expenditure Tertile") ///
    title("Predicted Probabilities by Expenditure Tertile", size(small)) ///
    legend(order(1 "Lowest Tertile" 2 "Middle Tertile" 3 "Upper Tertile") size(small) symxsize(small) symysize(small)) ///
    xlabel(1 "LEG" 2 "MEG" 3 "HEG", labsize(small)) ///
    ylabel(, format(%9.2f) labsize(small) grid) ///
    name(MarginsPlot1, replace) ///
    graphregion(color(white) margin(large)) plotregion(color(white))
	
	
// (3)
logit location_last_upr c.ln_flood_damage#i.expenditure_tertile HHold_size HH_type religion social_group land_holdings  sex age marital_status general_education usual_principal_activity year_dummy2-year_dummy27 district_dummy2-district_dummy70, or vce(cluster state)

// Ensure margins have been calculated
margins, at(expenditure_tertile=(1 2 3))

// Generate a refined black and white margins plot
marginsplot, recastci(rarea) scheme(s1mono) ///
    ytitle("Predicted Probability of Individual out-migrating Rural-Total seasonally")  ///
    xtitle("Economic Groups by Expenditure Tertile") ///
    title("Predicted Probabilities by Expenditure Tertile", size(small)) ///
    legend(order(1 "Lowest Tertile" 2 "Middle Tertile" 3 "Upper Tertile") size(small) symxsize(small) symysize(small)) ///
    xlabel(1 "LEG" 2 "MEG" 3 "HEG", labsize(small)) ///
    ylabel(, format(%9.2f) labsize(small) grid) ///
    name(MarginsPlot1, replace) ///
    graphregion(color(white) margin(large)) plotregion(color(white)) 
	
** this one worked	
	
// Logistic regression model with interaction between ln_flood_damage and expenditure_tertile
logit location_last_upr c.ln_flood_damage#i.expenditure_tertile ///
    HHold_size HH_type religion social_group land_holdings i.expenditure_tertile ///
    sex age marital_status general_education usual_principal_activity ///
    year_dummy2-year_dummy27 district_dummy2-district_dummy70, or vce(cluster state)

// Ensure margins have been calculated for each tertile of expenditure
margins, at(expenditure_tertile=(1 2 3))

// Generate a refined black and white margins plot
marginsplot, recastci(rarea) scheme(s1mono) ///
    ytitle("Predicted Probability of Individual out-migrating Rural-Total seasonally") ///
    xtitle("Economic Groups by Expenditure Tertile") ///
    title("Predicted Probabilities by Expenditure Tertile", size(small)) ///
    legend(order(1 "Lowest Tertile" 2 "Middle Tertile" 3 "Upper Tertile") size(small) symxsize(small) symysize(small)) ///
    xlabel(1 "Low" 2 "Medium" 3 "High", labsize(small)) ///
    ylabel(, format(%9.2f) labsize(small) grid) ///
    name(MarginsPlot1, replace) ///
    graphregion(color(white) margin(large)) plotregion(color(white))

// Save the graph
graph save margin_graph.png, replace


************************************************************************************
************************************************************************************


https://www.lse.ac.uk/granthaminstitute/wp-content/uploads/2015/05/Working-Paper-192-Waldinger.pdf

https://assets.publishing.service.gov.uk/media/57a08cfced915d622c0016df/WP220web.pdf 
************************************************************************************

** WITHIN GROUPS WITH DIFFERENTIAL AMOUNT OF LAND POSSESSION 
3) 
// Run the logistic regression model
logit location_last_upr c.ln_flood_damage#i.HH_land_possessed HHold_size HH_type religion social_group land_holdings expenditure_tertile sex age marital_status general_education usual_principal_activity ///
    year_dummy2-year_dummy27 district_dummy2-district_dummy70, or vce(cluster state)
outreg2 using main3.doc, replace eform

logit location_last_upr c.ln_flood_damage#i.HH_land_possessed#i.main_pattern HHold_size HH_type religion social_group land_holdings  expenditure_tertile sex age marital_status general_education usual_principal_activity ///
    year_dummy2-year_dummy27 district_dummy2-district_dummy70, or vce(cluster state)

outreg2 using main3.doc, append eform

** 
** HOUSEHOLD SIZES
// Run the logistic regression model
logit location_last_upr c.ln_flood_damage#i.HHold_size HHold_size HH_type religion social_group land_holdings expenditure_tertile sex age marital_status general_education usual_principal_activity ///
    year_dummy2-year_dummy27 district_dummy2-district_dummy70, or vce(cluster state)
outreg2 using main4.doc, replace eform

logit location_last_upr c.ln_flood_damage#i.HHold_size#i.main_pattern HHold_size HH_type religion social_group land_holdings  expenditure_tertile sex age marital_status general_education usual_principal_activity ///
    year_dummy2-year_dummy27 district_dummy2-district_dummy70, or vce(cluster state)
outreg2 using main4.doc, append eform


** WITHING SOCIAL GROUPS
(3) 
// Run the logistic regression model
logit location_last_upr c.ln_flood_damage#i.social_group HHold_size HH_type religion social_group land_holdings expenditure_tertile sex age marital_status general_education usual_principal_activity ///
    year_dummy2-year_dummy27 district_dummy2-district_dummy70, or vce(cluster state)

outreg2 using social_group.doc, replace eform

logit location_last_upr c.ln_flood_damage#i.social_group#i.main_pattern HHold_size HH_type religion social_group land_holdings  expenditure_tertile sex age marital_status general_education usual_principal_activity ///
    year_dummy2-year_dummy27 district_dummy2-district_dummy70, or vce(cluster state)


outreg2 using social_group.doc, append eform


** WITHING HOUSEHOLD HEAD
(3) 
recode sex (2 = 0), gen(gender_hoh)
label define gender 1 "Male" 0 "Female"
label values gender_hoh gender 

// Run the logistic regression model
logit location_last_upr c.ln_flood_damage#i.gender_hoh HHold_size HH_type religion social_group land_holdings expenditure_tertile gender_hoh age marital_status general_education usual_principal_activity ///
    year_dummy2-year_dummy27 district_dummy2-district_dummy70, or vce(cluster state)

outreg2 using gender_hoh.doc, replace eform

logit location_last_upr c.ln_flood_damage#i.gender_hoh#i.main_pattern HHold_size HH_type religion social_group land_holdings  expenditure_tertile gender_hoh age marital_status general_education usual_principal_activity ///
    year_dummy2-year_dummy27 district_dummy2-district_dummy70, or vce(cluster state)


outreg2 using gender_hoh.doc, append eform





************************************************************************************

*** Predicting estimates

BREAK

preserve 
cap drop permanent_pred 
cap drop permanent_se
logit location_last_upr ln_flood_damage HHold_size HH_type religion social_group land_holdings expenditure_tertile sex age marital_status general_education usual_principal_activity year_dummy2-year_dummy27 district_dummy2-district_dummy70, or vce(cluster state)

predict permanent_pred, xb  // Fitted values (log odds)
predict permanent_se, stdp  // Standard errors of the fitted values

gen lower_ci = permanent_pred - 1.96 * permanent_se
gen upper_ci = permanent_pred + 1.96 * permanent_se

// Linear interpolation for perman (example variable name)
// Make sure to sort the data by year before interpolation
sort the_year
ipolate permanent_pred the_year, gen(perman_interp) epolate
ipolate lower_ci the_year, gen(lower_interp) epolate
ipolate upper_ci the_year, gen(upper_interp) epolate
replace permanent_pred = perman_interp if missing(permanent_pred)
replace lower_ci = lower_interp if missing(lower_ci)
replace upper_ci = upper_interp if missing(upper_ci)

collapse (mean) permanent_pred lower_ci upper_ci, by(year)
list 

set scheme meta
twoway (rcap lower_ci upper_ci year, lcolor(black) lwidth(thin)) ///
       (scatter permanent_pred year, mcolor(black) msize(medium)) ///
       , ytitle("Predicted Log Odds of Individual Out-migrating Temporarily Rural- Total") ///
       xtitle("Year") ///
       ylabel(, labsize(small) angle(0) format(%3.1f)) ///
       xlabel(1980(1)2020, labsize(tiny) angle(45)) ///
       title("Predicted Permanent Effect with 95% Confidence Intervals") ///
       plotregion(style(none)) ///
       graphregion(color(white) margin(large)) ///
       legend(off)   
restore 


preserve 
cap drop permanent_pred 
cap drop permanent_se

logit location_last_upr ln_flood_damage , or vce(cluster state)

predict permanent_pred, xb  // Fitted values (log odds)
predict permanent_se, stdp  // Standard errors of the fitted values

gen lower_ci = permanent_pred - 1.96 * permanent_se
gen upper_ci = permanent_pred + 1.96 * permanent_se

collapse (mean) permanent_pred lower_ci upper_ci, by(year)
list 

set scheme s1mono
twoway (rcap lower_ci upper_ci year, lcolor(black) lwidth(thin)) ///
       (scatter permanent_pred year, mcolor(black) msize(medium)) ///
       , ytitle("Predicted Log Odds of Migration") ///
       xtitle("Year") ///
       ylabel(, labsize(small) angle(0) format(%3.1f)) ///
       xlabel(1980(1)2020, labsize(tiny) angle(45)) ///
       title("Predicted Migration Effect with 95% Confidence Intervals") ///
       plotregion(style(none)) ///
       graphregion(color(white) margin(large)) ///
       legend(off)   
restore 


preserve 
cap drop permanent_pred 
cap drop permanent_se

logit location_last_upr ln_flood_damage , or vce(cluster state)

predict permanent_pred, xb  // Fitted values (log odds)
predict permanent_se, stdp  // Standard errors of the fitted values

gen lower_ci = permanent_pred - 1.96 * permanent_se
gen upper_ci = permanent_pred + 1.96 * permanent_se

// Assuming 'year' and 'ln_flood_damage' are already defined in your dataset
collapse (mean) permanent_pred lower_ci upper_ci ln_flood_damage ln_total_damage, by(year)
list 

set scheme s1mono
twoway (rcap lower_ci upper_ci year, lcolor(black) lwidth(thin)) ///
       (scatter permanent_pred year, mcolor(black) msize(medium)) ///
       (line ln_flood_damage year, lcolor(red) lwidth(thin)) ///
       , ytitle("Predicted Log Odds of Migration and Log of Flood Damage") ///
       xtitle("Year") ///
       ylabel(0 0(1)4, labsize(small) angle(0) format(%3.1f)) ///
       xlabel(1980(1)2017, labsize(tiny) angle(45)) ///
       title("Predicted Migration Effect and Log of Flood Damage with 95% Confidence Intervals") ///
       plotregion(style(none)) ///
       graphregion(color(white) margin(large)) ///
       legend(label(1 "95% Confidence Interval") ///
              label(2 "Predicted Log Odds of Migration") ///
              label(3 "Actual Log of Flood Damage"))
restore 




// Set up MI framework in wide format
mi set wide

// Register variables to impute
mi register imputed ln_total_damage HHold_size HH_type religion social_group land_holdings expenditure_tertile sex age marital_status general_education usual_principal_activity

// Register outcome and auxiliary variables
mi register passive location_last_upr year_dummy2-year_dummy27 district_dummy2-district_dummy70

// Perform chained imputation (adjust imputation models as necessary)
mi impute chained (logit) location_last_upr (regress) ln_total_damage HHold_size

// Fit a logistic regression model using MI data
mi estimate, or: logit location_last_upr ln_total_damage HHold_size HH_type religion social_group land_holdings expenditure_tertile sex age marital_status general_education usual_principal_activity year_dummy2-year_dummy27 district_dummy2-district_dummy70

// Generate predicted probabilities using `predict`
mi predict permanent_pred, xb // Log-odds
mi predict permanent_se, stdp // Standard errors of the predicted log-odds

// Calculate confidence intervals
gen lower_ci = permanent_pred - 1.96 * permanent_se
gen upper_ci = permanent_pred + 1.96 * permanent_se

// If there's still missing data, consider interpolating
sort year
ipolate permanent_pred year, gen(perman_interp) epolate
ipolate lower_ci year, gen(lower_interp) epolate
ipolate upper_ci year, gen(upper_interp) epolate

// Replace missing predictions with interpolated values
replace permanent_pred = perman_interp if missing(permanent_pred)
replace lower_ci = lower_interp if missing(lower_ci)
replace upper_ci = upper_interp if missing(upper_ci)




































preserve 
cap drop permanent_pred 
cap drop permanent_se
logit location_last_upr ln_total_damage, or robust

predict permanent_pred, xb  // Fitted values (log odds)
predict permanent_se, stdp  // Standard errors of the fitted values

keep if year>2007
gen lower_ci = permanent_pred - 1.96 * permanent_se
gen upper_ci = permanent_pred + 1.96 * permanent_se

collapse (mean) permanent_pred lower_ci upper_ci, by(year)
list 

set scheme meta
twoway (rcap lower_ci upper_ci year, lcolor(black) lwidth(thin)) ///
       (scatter permanent_pred year, mcolor(black) msize(medium)) ///
       , ytitle("Predicted Log Odds of Individual Out-migrating Temporarily Rural- Total") ///
       xtitle("Year") ///
       ylabel(1(0.2)1.8, labsize(small) angle(0) format(%3.1f)) ///
       xlabel(2007(1)2020, labsize(tiny) angle(45)) ///
       title("Predicted Permanent Effect with 95% Confidence Intervals") ///
       plotregion(style(none)) ///
       graphregion(color(white) margin(large)) ///
       legend(off) ///
       
restore 

* Preserve the original data
preserve 

* Prepare dataset and run logistic regression
cap drop permanent_pred 
cap drop permanent_se
logit location_last_upr ln_total_damage, or robust

* Predict fitted values and their standard errors
predict permanent_pred, xb  // Fitted values (log odds)
predict permanent_se, stdp  // Standard errors of the fitted values

* Filter data and calculate confidence intervals
keep if year > 2007
gen lower_ci = permanent_pred - 1.96 * permanent_se
gen upper_ci = permanent_pred + 1.96 * permanent_se

* Aggregate data by year
collapse (mean) permanent_pred lower_ci upper_ci, by(year)

* Set a visually appealing graph scheme
set scheme meta

* Create the graph
twoway (rcap lower_ci upper_ci year, lcolor(black) lwidth(thin)) ///
       (scatter permanent_pred year, mcolor(black) msize(medium)) ///
       , ytitle("Predicted Log Odds of Individual Out-migrating Temporarily Rural- Total") ///
       xtitle("Year") ///
       ylabel(1(0.2)1.8, labsize(small) angle(0) format(%3.1f)) ///
       xlabel(2007(1)2020, labsize(tiny) angle(45)) ///
       title("Predicted Permanent Effect with 95% Confidence Intervals") ///
       plotregion(style(none)) ///
       graphregion(color(white) margin(large)) ///
       legend(off)

* Restore the original data
restore 



coefplot (detail, drop(_cons) ciopts(recast(rcap) lcolor(black)) mcolor(black) msize(small)), ///
vertical yline(0, lcolor(black) lwidth(thin) lpattern(dash)) ylabel(, labsize(vsmall) angle(90)) ///
graphregion(fcolor(white)) name(graph1, replace) scheme(s1mono)


BREAK 

preserve 

keep year_leaving_upr district year particulars_last_upr_pred
keep if year_leaving_upr >2010

collapse (mean) particulars_last_upr_pred, by(district year)

export excel using filename.xlsx, firstrow(variables) replace

restore


/*

This output comes from a conditional (fixed-effects) logistic regression model (clogit) that estimates the odds of type_outmigration_upr based on various predictors, using district as the grouping variable for fixed effects. The model's interpretation focuses on how each predictor affects the log odds of the outcome variable, keeping the effects of all other variables constant. Below is an interpretation of each coefficient:

Variables and Their Interpretations:
ln_total_damage: A one-unit increase in the natural log of total damage is associated with a 22.4% increase in the odds of type_outmigration_upr, though this effect is only marginally significant (p = 0.051). The confidence interval just barely includes 0, indicating weak evidence of an effect.

HHold_size: A one-unit increase in household size is associated with a decrease in the odds of type_outmigration_upr by approximately 33.6%, though this is not statistically significant (p = 0.204).

hh_type: Being in a different household type is associated with a 9.2% decrease in the odds of type_outmigration_upr, with a p-value of 0.054, suggesting marginal significance.

d_religion: A change in religion is associated with a 15.1% increase in the odds of type_outmigration_upr, but this effect is not statistically significant (p = 0.614).

d_social_group: A change in social group is associated with a 3.4% increase in the odds of type_outmigration_upr, but this effect is not statistically significant (p = 0.838).

HH_land_possessed: Having land possessed is associated with a 58.4% increase in the odds of type_outmigration_upr, though this is not statistically significant (p = 0.113).

occu_when_leaving_upr: A one-unit increase in this variable is associated with a 19.4% increase in the odds of type_outmigration_upr, and this effect is statistically significant (p < 0.001).

expenditure_tertile: Being in a different expenditure tertile is associated with a 17.5% decrease in the odds of type_outmigration_upr, but this effect is not statistically significant (p = 0.358).

age: A one-year increase in age is associated with a 3.4% increase in the odds of type_outmigration_upr, and this effect is statistically significant (p = 0.001).

sex3: A change in the sex of the migrant is associated with an 11.8% decrease in the odds of type_outmigration_upr, but this effect is not statistically significant (p = 0.639).

d_marital_status: A change in marital status is associated with an approximately 103.8% increase in the odds of type_outmigration_upr, and this effect is statistically significant (p = 0.017).

d_general_education: A one-unit increase in general education is associated with a 13.2% decrease in the odds of type_outmigration_upr, and this effect is statistically significant (p < 0.001).

General Interpretation Tips:
Coefficients: Positive coefficients indicate an increase in the odds of the outcome with a one-unit increase in the predictor, while negative coefficients indicate a decrease in the odds.

Statistical Significance: Variables with p-values less than 0.05 are typically considered to have statistically significant effects on the outcome variable. Marginal significance (p-values close to 0.05) suggests that there may be an effect, but it's not strong enough to be confident at the conventional 5% level.

Odds vs. Probabilities: These results speak to changes in odds, which are different from probabilities. An increase in odds indicates an increase in the likelihood of an event occurring relative to it not occurring, not a direct increase in the probability of the event.

Fixed Effects: The model controls for unobserved heterogeneity within districts by including district as a fixed effect, meaning the estimated effects of the predictors are net of any unobserved factors that vary across districts but are constant within them.

*/




