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

//MERGING DATASET
//BLOCK 1
use "Block-1-sample-household-identification-records.dta"
rename key_Hhold Key_hhold	

//BLOCK 3
merge 1:m Key_hhold using "Block-3-household-characteristics-ecords.dta", force keep(master match)
rename Key_hhold key_hhold 

encode state, gen(State)
				keep if State == 10 | State == 09	
				
				encode key_hhold, gen(Key_HH)

// bys Key_HH: gen temp = _N
// gen key_dolo = substr(key_hhold, 2, 8)

//BLOCK 4
cap drop _merge 
merge 1:m key_hhold using "Block-4-demographic-usual-activity-members-records.dta", force keep (master match)
				***********************************
				rename key_hhold key_hhold
				rename B3_q1 HH_size
				rename B3_Q4 HH_type
				rename B3_q5 religion
				rename B3_q6 social_group
				rename B4_c5 age
                rename B4_c6 marital_status	
				
				/*
				1	Scheduled tribes	17267	 13.8%
				2	Scheduled castes	20917	 16.7%
				3	Other backward classes	46768	 37.2%
				9	Others;
				*/ 
				
				rename B3_q7 land_possessed
				rename B3_q12 former_member_migrated
				rename B3_q13 count_male_migrated
				rename B3_q14 count_female_migrated
				rename B3_q15 remitt_receipt_365
				rename B3_q17 monthly_consumption
				rename B4_c3 hoh_relation
				
				/* HH Type
				Value	Category	Cases	
					11	Self-employed in non-agriculture	11080	 8.8%
					12	Agricultural labour	                17918	 14.3%
					13	Other labour	                     8789	 7.0%
					14	Self-employed in agriculture	    28933	 23.0%
					18	NR	                                   16	 0.0%
					19	Others;	                            12355	 9.8%
					21	Self-employed	                    16955	 13.5%
					22	Regular wage/salary earning	        17985	 14.3%
					23	Casual labour	                     5119	 4.1%
					28	NR	                                   13	 0.0%
					29	Others;
			
				MARITAL_STATUS 
				Value	Category	
					1	never married	
					2	currently married	
					3	widowed	
					4	divorced/separated						
					*/
				
				order key_hhold key_memb state District Stratum Sub_Stratum Sample_hhold_No HH_size HH_type religion social_group land_possessed former_member_migrated count_male_migrated count_female_migrated remitt_receipt_365 monthly_consumption hoh_relation age marital_status

				//RETAINING DATASET FOR ONLY TWO STATES OF NORTHERN INDIAN- Bihar(10) and Uttar Pradesh(09)
				keep if State == 10 | State == 09	
				//count 122, 250		
	   
		
//Block 6
merge 1:1 key_hhold key_memb using "Block-6-members-migration-records", force gen(test_6)
keep if State == 10 | State == 09	
tab test_6
duplicates report key_memb key_hhold
 ** I have unique observatiosn up until now
 //macthed 114,385
 
 BREAK
	 
 //BLOCK 3.1
merge 1:1 key_hhold key_memb using "Block-3dot1-out-migrants-records.dta", force gen(dupindicator)	
drop if dupindicator == 2
keep if State == 10 | State == 09	
//rename B31_c2 B4_c4	
order key_hhold key_memb	


cap drop match
gen match = (B31_c6 == B6_c10)
tab match

gen yrs_migration = B31_c6 if match == 1
replace yrs_migration = B6_c10 if match == 1
replace yrs_migration = B31_c6 if match == 0

tab yrs_migration

cap drop time_migration
bys key_hhold: egen time_migration = min(yrs_migration)
gen the_year = 2007 - time_migration


drop if the_year < 1980
drop if missing(the_year)

tab the_year

duplicates drop key_hhold, force

** I have 9,382 Households uniquely observed against which year they migrated
	
** B6_c9 tranformed variable- type_outmigration
		cap drop pattern3
		encode B3_q10, gen(pattern3)					    		 
		recode pattern3 (1 = 0) (2 = 1), gen(block3_pattern)
		bys key_hhold: egen max_pattern3 = max(pattern3)

		cap drop pattern6
		encode B6_c9, gen(pattern6)
		recode pattern6 (1 = 0) (2 = 0) (3 = 1), gen(block6_pattern)
		bys key_hhold: egen max_pattern6 = max(pattern6)

		cap drop main_pattern
		gen main_pattern = block3_pattern 
		replace main_pattern = block6_pattern if missing(main_pattern)
		replace main_pattern = max_pattern3 if missing(main_pattern)
		replace main_pattern = max_pattern6 if missing(main_pattern)
		tab main_pattern
		** 2,538 Households migrate permanently

		bys key_hhold: egen household_max_pattern = max(main_pattern)
		bys key_hhold: replace main_pattern = household_max_pattern

		//6,658 missing values generated because there are these many missing values 
		tab main_pattern, missing
		
		label define main 1 "Permanent" 0 "Temporary"
		label values main_pattern main
		// 1 - PERMANENT NATURE OF MOVEMENT
		// 0 - TEMPORARY NATURE OF MOMENT TO THE VILLAGE/TOWN (ON A AVERAGE 12 MONTHS)

BREAK

** B6_c11 particular_last_upr

		//Capturing those migrants records who out-migrated from rural-regions
		cap drop block3_lastupr
		encode B3_q9, gen(block3_lastupr)
		replace block3_lastupr = 1 if block3_lastupr == 1 | block3_lastupr == 3 | block3_lastupr == 5 
		replace block3_lastupr = 0 if block3_lastupr == 2 | block3_lastupr == 4 | block3_lastupr == 6 | block3_lastupr == 7
		bys key_hhold: egen max_upr3 = max(block3_lastupr)
		
		cap drop block6_lastupr
		encode B6_c11, gen(block6_lastupr)
		replace block6_lastupr = 1 if block6_lastupr == 1 | block6_lastupr == 3 | block6_lastupr == 5 
		replace block6_lastupr = 0 if block6_lastupr == 2 | block6_lastupr == 4 | block6_lastupr == 6 | block6_lastupr == 7
		bys key_hhold: egen max_upr6 = max(block6_lastupr)
		
		cap drop location_last_upr
		gen location_last_upr = block3_lastupr
		replace location_last_upr = block6_lastupr if missing(location_last_upr)
		replace location_last_upr = max_upr3 if missing(location_last_upr)
		replace location_last_upr = max_upr6 if missing(location_last_upr)
		
		tab location_last_upr
		gen migration_ind = 1 if location_last_upr == 1
		replace migration_ind = 1 if location_last_upr == 0
		replace migration_ind = 0 if missing(location_last_upr)
		
		
		***drop if missing(location_last_upr)
	    
		/*
		           Value	Category	Cases	
		1	Same district: rural	82000	 48.4%
		2	Same district: urban	12278	 7.3%
		3	Same state but another district: rural	33644	 19.9%
		4	Same state but another district: urban	16669	 9.8%
		5	Another state: rural	14397	 8.5%
		6	Another state: urban	8916	 5.3%
		7	Another country;
		*/ 
	
	
	 //RESTRICTING THE DATASET
				drop if missing(religion)
				drop if missing( social_group )
				drop if missing( land_possessed)
				drop if missing( marital_status)
				drop if missing( HH_size)
				drop if missing(age)
				
				
	    //VISUALISING THE NUMBER OF HOUSEHOLDS CAPTURED YEAR_WISE
	    bysort the_year: gen temp = _N
	    line temp the_year, xlabel(1980(1)2007, angle(45) labsize(tiny))
	    //On an average I observe 100 households every year

       ****************************************************
       //FINALLY RETAINING 2,691 households for analysis
	   ****************************************************			

xtset Key_HH the_year
	

save "combined_migration_Bihar.dta", replace

** COMBINING WITH FLOOD DATASET
use "flood_damage.dta", clear

cap drop indicator
merge 1:m state the_year using "combined_migration_Bihar.dta", force keep(master match) gen(indicator)
keep if year>1980

** RENAME FLOOD DAMAGE VARIABLES
rename fafarea aff_area
label variable aff_area "Affected area (m.ha.)"

rename fafpop aff_population
label variable aff_population "Affected Population in millions"

rename fafcropa crop_damage_area
label variable crop_damage_area "Damage to crops (area uin m.ha.)"

rename fafcropv crop_damage_value
label variable crop_damage_value "Damage to crops (in Rs. Crore)"

rename fafhhn damage_houses_count
label variable damage_houses_count "Damage to Houses"

rename fafhhv damage_houses_value
label variable damage_houses_value "Damage Houses Value (in Rs. Crore)"

rename fafcatn cattle_lost_count
label variable cattle_lost_count "Cattle lost count"

rename fafliven human_lives_lost

rename fafpubv damage_pu_value
label variable damage_pu_value "Damage Public Utilities (in Rs. Crore)"

rename ftotv total_damage
label variable total_damage "Total damages crops, houses & public utlities (in Rs. Crore)"

//encoding variable 

foreach variable in aff_population damage_houses_count cattle_lost_count human_lives_lost  total_damage {
	encode `variable', gen(`variable'_decode)
}


//Total damage includes damage for crops, houses, & public utlities. 				
			foreach var of varlist total_damage_decode aff_population_decode  cattle_lost_count_decode human_lives_lost_decode {
				gen ln_`var' = ln(`var')
			}
				
drop aff_population damage_houses_count cattle_lost_count human_lives_lost  total_damage

rename ln_total_damage_decode ln_total_damage
rename ln_aff_population_decode ln_aff_population
rename ln_cattle_lost_count_decode ln_cattle_lost
rename ln_human_lives_lost_decode ln_human_lives

rename total_damage_decode total_damage 
rename aff_population_decode aff_population 
rename cattle_lost_count_decode cattle_lost
rename human_lives_lost_decode human_lives

save "cleaned_migration_data.dta", replace


*********************************************
// FURTHER CLEARNING AND HARMONISING VARIABLES


// EIGHT HOUSEHOLD CHARACTERSTICS
** HH size **

gen HHold_size = (HH_size >= 5)
order HHold_size, after(HH_size)

** Former member migrated out **
//B3_Q12
rename B3_q12 former_member_migrated

** Religion **
/*
CATEGORIES
Value	Category	          Cases	
1	Hinduism	         20,535	
2	Islam	               3354
3	Christianity	         18
4	Sikhism	                 50
5	Jainism	                  6 
6	Buddhism	             12
7	Zoroastrianism           13	 
9	others
*/

** Social group**
/*
Value	Category
1	Scheduled tribes	
2	Scheduled castes	
3	Other backward classes	
9	Others;	
*/

encode HH_type, gen(hh_type)
drop HH_type
rename hh_type HH_type

**Household Type **
/*
CATEGORIES
Value	Category	Cases	
11	Self-employed in non-agriculture	11080	 8.8%
12	Agricultural labour	17918	 14.3%
13	Other labour	8789	 7.0%
14	Self-employed in agriculture	28933	 23.0%
18	NR	16	 0.0%
19	Others;	12355	 9.8%
21	Self-employed	16955	 13.5%
22	Regular wage/salary earning	17985	 14.3%
23	Casual labour	5119	 4.1%
28	NR	13	 0.0%
29	Others;
*/


** Land_Possessed **
encode land_possessed, gen(land_holdings)
recode land_holdings (1 2 3 4 5 = 1) (6 7 8 = 2) (9 10 11 12 = 3), gen(HH_land_possessed)
label define land_records 1 "Upto 1 hectare" 2 "from 1.01 to 4 hectares" 3 "more than 4 hectares"
label values HH_land_possessed land_records

/*
 Value	Category	                
	01	less than 0.005 hectares	
	02	0.005 - 0.01 hectares	
	03	0.02 - 0.20 hectares	
	04	0.21 - 0.40 hectares	
	05	0.41 - 1.00 hectares	
	06	1.01 - 2.00 hectares	
	07	2.01 - 3.00 hectares	
	08	3.01 - 4.00 hectares	
	10	4.01 - 6.00 hectares	
	11	6.01 - 8.00 hectares	
	12	greater than 8.0 0hectares
*/

** Occupation at the time of leaving upr - For determining the usual principal activity status of the person at the time of leaving the last upr, the reference period to be adopted will be 365 days preceding the date of leaving last upr.**
rename B6_c14 occ_when_migrating

/*
Value	Category	Cases	
11	worked in hh. enterprise (self-employed) as own account worker	5988	 3.5%
12	worked in hh. enterprise (self-employed) as employer	217	 0.1%
21	worked as helper in hh. enterprises (unpaid family worker)	10105	 6.0%
31	worked as regular salaried/wage employee	9783	 5.8%
41	worked as casual wage labour : in public works	87	 0.1%
51	worked as casual wage labour : in other types of work	15499	 9.2%
81	did not work but was seeking and/or available for work	4914	 2.9%
91	attended educational institutions	18305	 10.8%
92	attended domestic duties only	70584	 41.7%
93	attended domestic duties and was also engaged in free collection of goods for hh. use	23165	 13.7%
94	rentiers, pensioners, remittance recipients, etc.	384	 0.2%
95	not able to work due to disability	187	 0.1%
96	beggars, prostitutes	0	 0.0%
97	Others	7893	 4.7%
99	Invalid
*/

** MPCE **
		* Step 1: Create Monthly Per Capita Expenditure
		gen monthly_per_capita_expenditure = monthly_consumption / HH_size
		* Step 2: Divide into tertiles
		xtile expenditure_tertile = monthly_per_capita_expenditure, nq(3)
		* The variable expenditure_tertile now contains the tertiles with equal frequencies
		label define tertile 1 "Lower Tertile" 2 "Middle Tertile" 3 "Upper Tertile"
		label values expenditure_tertile tertile
		* Optional: To check the distribution and validate
		tabulate expenditure_tertile

order monthly_per_capita_expenditure expenditure_tertile, after(monthly_consumption)

//Creating local for Household Characterstics
local Household_characteristics HHold_size HH_type religion social_group land_holdings former_member_migrated remitt_receipt_365 occ_when_migrating expenditure_tertile

**HoH characterstics*

//set up
rename B4_c4 sex
** rename B4_c5 age
cap drop age_cat
gen age_cat = 1 if age<= 21
replace age_cat = 2 if age >= 22 & age <= 50
replace age_cat = 3 if age >50 & age <= 70
replace age_cat = 4 if age>= 70

// <21, 22- 50,50- 80, and greater than 80
** rename B4_c6 marital_status			
rename B4_c7 general_education
rename B4_c9 usual_principal_activity
encode usual_principal_activity, gen(usual_pa)
drop usual_principal_activity
rename usual_pa usual_principal_activity

//Creating local 
local Head_features sex age marital_status general_education usual_principal_activity

** GENERATE SUMMARY STATISTICS
tabstat aff_population_decoded crop_damage_area_decoded crop_damage_value_decoded damage_houses_count_decoded damage_houses_value_decoded cattle_lost_count_decoded human_lives_lost_decoded damage_pu_value_decoded total_damage_valuation_decoded, by(year_leaving_upr) stats(mean)


****Destring Variables
           
		    encode religion, gen(d_religion)
			drop religion 
			rename d_religion religion
			
			encode social_group, gen(d_social_group)
			drop social_group
			rename d_social_group social_group
			label define social_g 1 "SC" 2 "ST" 3 "OBC" 4 "Others"
			label values social_group social_g
							
			encode occ_when_migrating, gen(occupation)
			drop occ_when_migrating
			rename occupation occ_when_migrating
			
			encode sex, gen(sex_decode)
			drop sex
			rename sex_decode sex
			
			cap drop d_marital_status
			encode marital_status, gen(d_marital_status)
			drop marital_status
			rename d_marital_status marital_status
			
			cap drop d_general_education
			encode general_education, gen(d_general_education)
			drop general_education 
			rename d_general_education general_education
			
			encode former_member_migrated, gen(form_mem_migrated)
		    drop former_member_migrated
			rename form_mem_migrated former_member_migrated
			
	   
	   
		tabulate the_year, generate(year_dummy)
		encode District, gen(district)
		tabulate district, generate(district_dummy)
		
		

		
		//dropping observations
       drop if missing(religion) & year <=2007
 	   drop if missing( social_group ) & year <=2007
	   drop if missing( land_possessed) & year <=2007
	   drop if missing( marital_status) & year <=2007
	   drop if missing( HH_size) & year <=2007
	   drop if missing(age) & year <=2007
	
**************************
**Save the cleaned dataset
	   
save cleaned_migration_data.dta, replace






