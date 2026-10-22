clear all
set more off

cd "/Users/rebeccaspritzer/Desktop/Ireland/Trinity/Econometrics I/Project v2/ATUS"

capture log close
log using ProjectEdit.log, text replace

use atus2015through2024_NDCP2022_states, clear

br


*--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*
******* DATA SETUP *******
drop if tuyear < 2015
drop if tuyear > 2022

*correct ismarried
replace ismarried = 0 if ismarried == .
*Drop observations where no data reported on respondent income or spouseincome
drop if spouseearnings == - 1
drop if prernwa == -1
*correct homeschooling of non hh children 
replace t040203 = 0 if t040203 ==.

*gen dummy for respondents who have a partnerinhousehold
gen haspartner = 0
replace haspartner = 1 if spouseearnings != .
replace spouseearnings = 0 if spouseearnings == .

*rename variables
rename trchildnum numberchildren
rename prtage age
rename tehruslt workhours

*remove people who didnt report workhours
drop if workhours == -1
drop if workhours == -4

*gen female dummy variable
gen female = 0
replace female = 1 if pesex == 2
*gen partner in household dummy
gen partnerinhousehold = 0
replace partnerinhousehold =1 if trsppres == 1
replace partnerinhousehold =1 if trsppres == 2

*gen monthly income from weekly income, drop if no response
replace prernwa = 0 if prernwa == -1
gen monthlyincome = (prernwa + peern +puern2)*4/100
label variable monthlyincome "monthly income of respondent"
gen ln_monthlyincome = ln(monthlyincome +1)
label variable ln_monthlyincome "natural log of monthly income"
*gen spousal monthlyincome
replace spouseearnings = 0 if spouseearnings == .
replace spouseearnings = 0 if spouseearnings == -1
gen spousemonthlyincome = spouseearnings*4/100
label variable spousemonthlyincome "monthly income of spouse"
gen ln_spousemonthlyincome = ln(spousemonthlyincome+1)
label variable ln_spousemonthlyincome "natural log of spouse monthly income"
*gen household monthly income
gen householdmonthlyincome = monthlyincome + spousemonthlyincome
label variable householdmonthlyincome "household monthly income"
gen ln_householdmonthlyincome = ln(householdmonthlyincome +1)
label variable ln_householdmonthlyincome "natural log of household monthly income"

*Gen spouse employment
gen spouseemployed = 0
replace spouseemployed = 1 if trspftpt > 0

*gen childcare unpaid hours
* Step 1: Primary Childcare (minutes) from total time spent during diary day providing primary childcare for own children children in household.
gen primarychildcaretime = t030101 + t030102 + t030109 + t030199 /// household
 +  t030103 + t030104 + t030105 + t030106  + t030112 + t030201 + t030202+ t030203 + t030301 + t030302 + t030303 + t030111 + t030108 + t030110 + t030204 + t180302 + t180303
 
sum t030101  t030102  t030103 t030104 t030105 t030106 t030108 t030109 t030110 t030111 t030112 t030199 t030201 t030202 t030203 t030301 t030302 t030303  t030204 t180302 t180303

asdoc summarize t030101 t030102 t030103 t030104 t030105 t030106 ///
t030108 t030109 t030110 t030111 t030112 t030199 t030201 t030202 ///
t030203 t030301 t030302 t030303 t030204 t180302 t180303, save(summary.docx)
 
/* 
houshold + nonhousehold
t030101 + t040101   /// physical care for household / nonhousehold children
t030102 + t040102  	 /// reading to household / nonhousehold children
t030103 + t040103    /// playing with household / nonhousehold children
t030104 + t040104   /// arts & crafts with household / nonhousehold children
t030105 + t040105  /// sports with household / nonhousehold children
t030106 + t040106  /// talking / listening to household / nonhousehold children
t030108 + /// organizing and planning for hh / nhh children
t030109 + t040109  /// looking after household children / nonhousehold as primary activity
t030110 + /// Attending childrens events
t030111 + /// waiting for / with children
t030112 + /// picking up / dropping off children
t030199 + t040199 /// caring and helping for household / nonhousehold children
t030201 + /// homework with children
t030202 + // meetings and school conferences
t030203 + t040203 /// homeschooling of household / nonhousehold children
t030301 + t040301 // providing medical care to household / nonhousehold children
t030302 + ///  obtaining medical care for children 
t030303 /// waiting associated with childrens health 
t030204 + // waiting associated with childrens education 
t180302 + // travel related to childrens education
t180303 + // travel related to childrens health
*/


label variable primarychildcaretime "time spent caring for household children as primary activity"
gen ln_primarychildcaretime = ln(primarychildcaretime + 1)
label variable ln_primarychildcaretime "natural log of primary childcare time"

*Step 2: Secondary childcare so time spent taking care of child while doing something else from time spent in secondary childcare for all children under 13
rename trtohh secondarychildcaretime
*Step 3: Total childcare time
gen totalchildcaretime = primarychildcaretime + secondarychildcaretime
gen ln_secondarychildcaretime = ln(secondarychildcaretime + 1)
gen ln_totalchildcaretime = ln(totalchildcaretime +1)

*variable for age of children
rename tryhhchild ageofyoungestchild
replace ageofyoungestchild = . if ageofyoungestchild == -1 // correction to exclude 

*variable for education
gen highesteducation = .
tostring highesteducation, replace
replace highesteducation = "High School or less" if peeduca < 40
replace highesteducation = "College or some college" if peeduca < 44 & peeduca >=40
replace highesteducation = "Graduate Degree" if peeduca >= 44
encode highesteducation, gen(highesteducation_num)

*determine eligibility for ARP child tax credit extension 2021
gen yearlyhouseholdincome = householdmonthlyincome * 12
gen individualyearlyincome = monthlyincome * 12
gen haschild_under18 = (ageofyoungestchild < 18)
*eligibility only applies in 2021
gen eligiblefortaxcreditin2021 = 0
replace eligiblefortaxcreditin2021 = 1 if haschild_under18 == 1
*Apply ARP 2021 expanded CTC income thresholds
replace eligiblefortaxcreditin2021 = 0 if eligiblefortaxcreditin2021 == 1 & ismarried == 1 & yearlyhouseholdincome > 150000 // household income if married
replace eligiblefortaxcreditin2021 = 0 if eligiblefortaxcreditin2021 == 1 & ismarried == 0 & individualyearlyincome > 112500 // individual income if unmarried
label variable eligiblefortaxcreditin2021 "Eligble for the 2021 CTC Extension"

*DID Model variable
gen post2021 = (tudiarydate >= 20210701)
gen did = eligiblefortaxcreditin2021 * post2021

*determine eligibility for ARP child tax credit extension 2017
gen eligiblefortaxcreditin2017 = 0
replace eligiblefortaxcreditin2017 = 1 if haschild_under18 ==1 & tuyear >= 2017
*Income thresholds
replace eligiblefortaxcreditin2017 = 0 if eligiblefortaxcreditin2017 == 1 & yearlyhouseholdincome < 2500
replace eligiblefortaxcreditin2017 = 0 if eligiblefortaxcreditin2017 == 1 & ismarried == 1 & yearlyhouseholdincome >= 400000
replace eligiblefortaxcreditin2017 = 0 if eligiblefortaxcreditin2017 == 1 & ismarried == 0 & individualyearlyincome >= 200000

drop if ageofyoungestchild == . // sample only households with children

label variable haspartner          "Has a Partner"
label variable partnerinhousehold  "Partner in Household"
label variable hasrelatives        "Has Relatives in Household"
label variable eligiblefortaxcreditin2021 "Eligible for 2021 CTC"

*--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*
******* DATA REVIEW *******
twoway scatter primarychildcaretime monthlyincome, title("primary childcare time vs monthly income of respondent")
twoway scatter totalchildcaretime monthlyincome, title("total childcare time vs monthly income of respondent")

summarize primarychildcaretime totalchildcaretime
summarize age ageofyoungestchild workhours
tab female 
tab haspartner
tab partnerinhousehold
tab hasrelatives
tab highesteducation
tab eligiblefortaxcreditin2021
tab eligiblefortaxcreditin2017

*Summary statistics output*
*Table 3 for 2021 eligibility	
estpost tab eligiblefortaxcreditin2021 if post2021 == 1, 
esttab using Table3.tex, replace 

estpost tab eligiblefortaxcreditin2021 if post2021 == 0, 
esttab using Table3b.tex, replace 

preserve
keep if post2021 == 0

*Table 1 for childcare time
estpost tabstat primarychildcaretime secondarychildcaretime totalchildcaretime, by(eligiblefortaxcreditin2021) statistics(count mean sd min max) columns(statistics)
esttab using Table1.tex, replace cells("count(fmt(0)) mean(fmt(2)) sd(fmt(2)) min(fmt(2)) max(fmt(2))") label booktabs

ttest totalchildcaretime, by(eligiblefortaxcreditin2021)

*Table 2 for married 
estpost tab ismarried eligiblefortaxcreditin2021
esttab using Table2.tex, replace cells("b(fmt(0)) pct(fmt(2))") label booktabs
ttest ismarried, by(eligiblefortaxcreditin2021)

*Table 4 for household composition
asdoc bysort eligiblefortaxcreditin2021: table haspartner partnerinhousehold hasrelatives, save(table4.doc) replace
asdoc bysort eligiblefortaxcreditin2021: tab spouseemployed, save(table4.doc) append

*Table 5 for Education Levels
asdoc bysort eligiblefortaxcreditin2021: tab highesteducation, save(table5.doc) replace


*Table 6 for Other controls 
estpost tabstat numberchildren ageofyoungestchild workhours, by(eligiblefortaxcreditin2021) statistics(count mean sd min max) columns(statistics)
esttab using Table6.tex, replace cells("count(fmt(0)) mean(fmt(2)) sd(fmt(2)) min(fmt(2)) max(fmt(2))")label booktabs

*Table 7 for Distribution of households eligible for 2017 tax credit 
asdoc bysort eligiblefortaxcreditin2021: tab eligiblefortaxcreditin2017, save(table7.doc) replace


*Table 8 for gender split
asdoc bysort eligiblefortaxcreditin2021: tab female, save(table8.doc) replace
ttest female, by(eligiblefortaxcreditin2021)

restore

*--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*
******* MODEL *******
*** DID ******
* did = post 2021 x eligibility
gen femalexdid = female * did
gen femalextime = female * post2021
gen femalexeligbile2021 = female * eligiblefortaxcreditin2021

// Model 1
reghdfe ln_totalchildcaretime ///
	eligiblefortaxcreditin2021 did ///
    ,absorb(tuyear gestfips hrmonth tudiaryday) vce(cluster gestfips)
outreg2 using mainregression2.tex, replace ctitle(Model 1)

//Model 2
reghdfe ln_totalchildcaretime ///
	eligiblefortaxcreditin2021 did ///
    female haspartner partnerinhousehold hasrelatives ///
    workhours ageofyoungestchild spouseemployed ///
    c.numberchildren i.highesteducation_num ///
    ,absorb(tuyear gestfips hrmonth tudiaryday) vce(cluster gestfips)
outreg2 using mainregression2.tex, append ctitle(Model 2)

// Model 3
* 2015 through 2022 data
reghdfe ln_totalchildcaretime ///
	eligiblefortaxcreditin2021 did female femalextime femalexeligbile2021 femalexdid ///
    haspartner partnerinhousehold hasrelatives ///
    workhours ageofyoungestchild spouseemployed ///
    c.numberchildren i.highesteducation_num ///
    ,absorb(tuyear gestfips hrmonth tudiaryday) vce(cluster gestfips)
outreg2 using mainregression2.tex, append ctitle(Model 3)

// Model 4
reghdfe ln_totalchildcaretime ///
	eligiblefortaxcreditin2021 did female femalextime femalexeligbile2021 femalexdid ///
    eligiblefortaxcreditin2017 haspartner partnerinhousehold hasrelatives ///
    workhours ageofyoungestchild spouseemployed ///
    c.numberchildren i.highesteducation_num ///
    ,absorb(tuyear gestfips hrmonth tudiaryday) vce(cluster gestfips)
outreg2 using mainregression2.tex, append ctitle(Model 4)



*--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*
******* Robustness Checks *******
* 1. Include Childcare costs
reghdfe ln_totalchildcaretime ///
	eligiblefortaxcreditin2021 did ///
    female haspartner partnerinhousehold hasrelatives ///
    workhours ageofyoungestchild spouseemployed state_childcarecost ///
    i.numberchildren i.highesteducation_num ///
    ,absorb(tuyear gestfips hrmonth tudiaryday) vce(cluster gestfips)
outreg2 using robustchecksregression1.tex, replace

reghdfe ln_totalchildcaretime ///
	eligiblefortaxcreditin2021 did femalextime femalexeligbile2021 femalexdid female ///
    haspartner partnerinhousehold hasrelatives ///
    workhours ageofyoungestchild spouseemployed state_childcarecost ///
    i.numberchildren i.highesteducation_num ///
    ,absorb(tuyear gestfips hrmonth tudiaryday) vce(cluster gestfips)
outreg2 using robustchecksregression1.tex, append

*2. Just use 2019 through 2022 data 
preserve
drop if tuyear < 2019

reghdfe ln_totalchildcaretime ///
	eligiblefortaxcreditin2021 did ///
    female haspartner partnerinhousehold hasrelatives ///
    workhours ageofyoungestchild spouseemployed ///
    numberchildren i.highesteducation_num ///
    ,absorb(tuyear gestfips hrmonth tudiaryday) vce(cluster gestfips)
outreg2 using robustchecksregression2.tex, replace

reghdfe ln_totalchildcaretime ///
	eligiblefortaxcreditin2021 did femalextime femalexeligbile2021 femalexdid female ///
    haspartner partnerinhousehold hasrelatives ///
    workhours ageofyoungestchild spouseemployed  ///
    i.numberchildren i.highesteducation_num ///
    ,absorb(tuyear gestfips hrmonth tudiaryday) vce(cluster gestfips)
outreg2 using robustchecksregression2.tex, append
restore

*Drop Lump Sum Payments from sample
preserve
drop if tuyear >= 2022

reghdfe ln_totalchildcaretime ///
	eligiblefortaxcreditin2021 did ///
    female haspartner partnerinhousehold hasrelatives ///
    workhours ageofyoungestchild spouseemployed ///
    numberchildren i.highesteducation_num ///
    ,absorb(tuyear gestfips hrmonth tudiaryday) vce(cluster gestfips)
outreg2 using robustchecksregression3.tex, replace

reghdfe ln_totalchildcaretime ///
	eligiblefortaxcreditin2021 did femalextime femalexeligbile2021 femalexdid female ///
    haspartner partnerinhousehold hasrelatives ///
    workhours ageofyoungestchild spouseemployed  ///
    i.numberchildren i.highesteducation_num ///
    ,absorb(tuyear gestfips hrmonth tudiaryday) vce(cluster gestfips)
outreg2 using robustchecksregression3.tex, append
restore	

*Add variable for reopening levels across states for COVID-19
reghdfe ln_totalchildcaretime ///
	eligiblefortaxcreditin2021 did ///
    female haspartner partnerinhousehold hasrelatives ///
    workhours ageofyoungestchild spouseemployed ///
    numberchildren i.highesteducation_num stringencyindex ///
    ,absorb(tuyear gestfips hrmonth tudiaryday) vce(cluster gestfips)
outreg2 using robustchecksregression1.tex, append

reghdfe ln_totalchildcaretime ///
	eligiblefortaxcreditin2021 did femalextime femalexeligbile2021 femalexdid female ///
    haspartner partnerinhousehold hasrelatives ///
    workhours ageofyoungestchild spouseemployed  ///
    i.numberchildren i.highesteducation_num stringencyindex ///
    ,absorb(tuyear gestfips hrmonth tudiaryday) vce(cluster gestfips)
outreg2 using robustchecksregression1.tex, append

*--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*	
******* Parallel Trends *********

gen treated = eligiblefortaxcreditin2021
gen treatedxfemale = treated * female
*Plot treated v control
*monthly
preserve
collapse (mean) totalchildcaretime, by(treated period)
twoway (line totalchildcaretime period if treated==1, sort lcolor(blue) lpattern(solid)) ///
       (line totalchildcaretime period if treated==0, sort lcolor(red) lpattern(dash)), ///
       legend(label(1 "Treated") label(2 "Control")) ///
       title("Average childcare hours")
restore

***** Pre-2021 sample only *********
*Monthly Graph
preserve
keep if tudiarydate < 20210701

* Compute mean childcare by treatment status and month
* Consider years leading up to 2021 treatment in grap for visualization of parallel trends in treatment and control
collapse (mean) totalchildcaretime, by(treated period)

*Plot treated v control
twoway ///
    (line totalchildcaretime period if treated==1, sort lcolor(black) lpattern(solid)) ///
    (line totalchildcaretime period if treated==0, sort lcolor(black) lpattern(dash)), ///
    legend(label(1 "Eligible") label(2 "Ineligible")) ///
    xtitle("Month") ///
    ytitle("Average Childcare Time (minutes / day)") ///
	xscale(range(1 78) noextend) ///
    xlabel(1 "Jan 2015" 25 "Jan 2017" 49 "Jan 2019" 78 "Jul 2021") ///
    title("")
	graph export "childcare_trends1.png", width(2000) replace
restore

*Quarterly Graph
gen quarter = ceil(period/3)

preserve

keep if tudiarydate < 20210701

* Compute mean childcare by treatment status and quarter
* Consider years leading up to 2021 treatment in grap for visualization of parallel trends in treatment and control
collapse (mean) totalchildcaretime, by(treated quarter)

*Plot treated v control
twoway ///
    (line totalchildcaretime quarter if treated==1, sort lcolor(black) lpattern(solid)) ///
    (line totalchildcaretime quarter if treated==0, sort lcolor(black) lpattern(dash)), ///
    legend(label(1 "Eligible") label(2 "Ineligible")) ///
    xtitle("Quarter") ///
    ytitle("Average Childcare Time (minutes / day)") ///
	xscale(range(1 32) noextend) ///
    xlabel(1 "Q1 2015" 13 "Q1 2018" 26 "Q2 2021") ///
    title("")
	graph export "childcare_trends2.png", width(2000) replace
restore


****Placebo Pre Trends **********
preserve

drop year
gen year  = floor(tudiarydate / 10000)
gen month = floor((tudiarydate - year*10000) / 100)
gen month_index = (year - 2015)*12 + month

drop if tudiarydate > 20210701

*Regression*
reghdfe ln_totalchildcaretime ///
    c.treated##c.month_index /// 
    female haspartner partnerinhousehold hasrelatives spouseemployed ///
    workhours numberchildren ageofyoungestchild ///
    i.highesteducation_num ///
    , absorb(gestfips tuyear hrmonth tudiaryday) vce(cluster gestfips)

outreg2 using regplacebo.tex, replace ctitle(Placebo Test)
restore


*Year / quarterly interaction with treatment in pre july 2021 period
preserve

drop if tudiarydate > 20210731

reghdfe ln_totalchildcaretime ///
    c.treated##ib2021.tuyear /// 
    female haspartner partnerinhousehold hasrelatives spouseemployed ///
    workhours numberchildren ageofyoungestchild ///
    i.highesteducation_num ///
    , absorb(gestfips tuyear hrmonth tudiaryday) vce(cluster gestfips)
outreg2 using regplaceboyear.tex, replace ctitle(Placebo - Yearly)

reghdfe ln_totalchildcaretime ///
    c.treated##ib27.quarter /// 
    female haspartner partnerinhousehold hasrelatives spouseemployed ///
    workhours numberchildren ageofyoungestchild ///
    i.highesteducation_num ///
    , absorb(gestfips tuyear hrmonth tudiaryday) vce(cluster gestfips)
outreg2 using regplaceboyear.tex, append ctitle(Placebo - Quarterly)

	
restore


	
