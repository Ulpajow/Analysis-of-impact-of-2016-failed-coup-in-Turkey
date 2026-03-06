
rename internationaltourismreceiptscurr tourism
rename foreigndirectinvestmentnetinflow fdi
rename freedomofexpressionandalternativ free_expr
rename populationprisonpopulationrate prison_rate
rename politicalcorruptionindex corruption
rename civillibertiesindex civil_lib
rename crimerateper100k crime_rate
rename prison prison_tot

tsset year

local vars_eco tourism fdi
local vars_inst civil_lib free_expr corruption
local vars_secu crime_rate prison_tot prison_rate
local vars_social level

* list for loops
local all_vars `vars_eco' `vars_inst' `vars_secu' `vars_social'

*===========================================================================
* 2. Data preparation (CALCULS)
*===========================================================================

* A. CALCULATION OF RATES OF CHANGE ("SHOCKS")
* Creating variables Choc_tourism, Choc_fdi, etc.
foreach var of local all_vars {
    gen Choc_`var' = (D.`var' / L.`var') * 100
}

* B. Variables for NEWEY-WEST (TREND)
gen Post_2016 = (year >= 2016)
gen Tendance = year - 2004  
gen Rupture_Pente = Post_2016 * (year - 2015)

* C. STANDARDIZATION (for the VAR/IRF)
* Creating variable std_tourism, std_fdi, etc. (Moyenne=0, SD=1)
foreach var of varlist tourism fdi civil_lib free_expr corruption crime_rate prison_rate prison_tot level{
    egen std_`var' = std(`var')
}

* D. SHOCK DUMMIES FOR THE VAR
gen Choc_Reel = (year == 2016)
gen Choc_Placebo = (year == 2015)

*===========================================================================
* 3. DESCRIPTIVE STATISTICS
*===========================================================================

* A. GLOBAL CORRELATION MATRIX
pwcorr Post_2016 `vars_inst' `vars_eco' `vars_secu' level, star(0.05) sig

* B. TABLE OF AVERAGES BY YEAR
tabstat `vars_eco' `vars_inst' `vars_secu' level, by(year) statistics(mean) columns(statistics) format(%9.2f)

* C. Hope EVOLUTION CHART - STACKED BAR

graph bar nothopefulatall nothopeful hopeful veryhopeful, over(year) stack ///
    legend(rows(1) label(1 "Pas du tout") label(2 "Non") label(3 "Oui") label(4 "Très")) ///
    bar(1, color(red)) bar(2, color(orange)) bar(3, color(midgreen)) bar(4, color(forest_green)) ///
    title("Évolution du Sentiment d'Espoir (2012-2022)") percentage scheme(s1mono) name(graph_hope_stack, replace)
	
*===========================================================================
* 4. TIME-BASED GRAPHIC ANALYSIS (CURVES)
*===========================================================================

* ECONOMICS
tsline tourism, tline(2016) recast(connected) title("Recettes Touristiques") subtitle("Rupture 2016") ytitle("USD") name(g_tourisme, replace)
tsline fdi, tline(2016) recast(connected) title("Investissements Directs (IDE)") subtitle("Rupture 2016") ytitle("Net Inflows") name(g_fdi, replace)

* INSTITUTIONS
tsline civil_lib, tline(2016) recast(connected) title("Libertés Civiles") subtitle("Rupture 2016") name(g_civil, replace)
tsline free_expr, tline(2016) recast(connected) title("Liberté d'Expression") subtitle("Rupture 2016") name(g_expr, replace)
tsline corruption, tline(2016) recast(connected) title("Corruption Politique") subtitle("Rupture 2016") name(g_corrup, replace)

* SECURITY
tsline crime_rate, tline(2016) recast(connected) title("Criminalité (pour 100k)") subtitle("Rupture 2016") name(g_crime, replace)
tsline prison_tot, tline(2016) recast(connected) title("Population Carcérale") subtitle("Rupture 2016") name(g_prison, replace)
tsline level, tline(2016) recast(connected) title("level of hope") subtitle("Rupture 2016") name(g_prison, replace)
tsline prison_rate, tline(2016) recast(connected) title("Prison per population") subtitle("Rupture 2016") name(g_prison, replace)

*===========================================================================
* 5. ANALYSIS OF THE IMMEDIATE IMPACT (2016)
*===========================================================================

* A. VERIFICATION TABLE
list year Choc_tourism Choc_fdi Choc_civil_lib Choc_free_expr Choc_corruption Choc_crime_rate Choc_prison_tot Choc_prison_rate Choc_level if year >= 2015 & year <= 2017

* B. BAR CHART
preserve
keep if year == 2016
graph hbar (mean) Choc_tourism Choc_fdi Choc_civil_lib Choc_free_expr Choc_corruption Choc_crime_rate Choc_prison_tot Choc_prison_rate Choc_level, yvaroptions(relabel(1 "Tourisme" 2 "IDE" 3 "Libertés" 4 "Expression" 5 "Corruption" 6 "Criminalité" 7 "Prison (Tot)" 8 "Prison (Taux)" 9 "Espoir")) title("L'Année 2016 : Un Choc Multidimensionnel") subtitle("Taux de variation annuel (%)") blabel(bar, format(%9.1f)) yline(0, lcolor(black)) scheme(s1mono) legend(off) bar(1, color(navy)) bar(2, color(dknavy)) bar(3, color(orange)) bar(4, color(sienna)) bar(5, color(brown)) bar(6, color(red)) bar(7, color(cranberry)) bar(8, color(maroon)) bar(9, color(forest_green)) name(graph_choc_2016, replace)
restore

*interpretation
*Tourisme (-25.6%) : La première barre bleue (la baisse économique immédiate).
*IDE / Investissements (-28.6%) : La barre bleu foncé (la fuite des capitaux).
*Libertés Civiles (-33.0%) : La barre orange.
*Liberté d'Expression (-38.8%) : La barre marron clair (la plus grosse chute).
*Corruption (+5.6%) : La petite barre kaki (vers la droite).
*Criminalité (+18.9%) : La grande barre rouge vif (l'explosion de l'insécurité).
*Prison Total (+11.6%) : La barre rouge sombre.
*Prison Taux (+10.3%) : La barre bordeaux.
*Espoir (+1.4%) : La petite barre verte tout en bas


*===========================================================================
* 6. ECONOMETRICS
*===========================================================================


* A. FILTRE HODRICK-PRESCOTT (Cycle du Tourisme)
capture drop cycle_tourism
tsfilter hp cycle_tourism = tourism, smooth(6.25)
tsline cycle_tourism, tline(2016) yline(0) title("Cycle : Tourisme") subtitle("Écarts à la tendance (HP Filter)") name(hp_tourism, replace)

* B. INTERRUPTED TIME SERIES (Newey-West)
* Test de rupture de pente sur le Tourisme
newey tourism Tendance Post_2016 Rupture_Pente, lag(1)


capture drop cycle_fdi
tsfilter hp cycle_fdi = fdi, smooth(6.25)
tsline cycle_fdi, tline(2016) yline(0) title("Cycle : IDE") subtitle("Écarts à la tendance (HP Filter)") name(hp_fdi, replace)
newey fdi Tendance Post_2016 Rupture_Pente, lag(1)

capture drop cycle_civil_lib
tsfilter hp cycle_civil_lib = civil_lib, smooth(6.25)
tsline cycle_civil_lib, tline(2016) yline(0) title("Cycle : Libertés Civiles") subtitle("Écarts à la tendance (HP Filter)") name(hp_civil, replace)
newey civil_lib Tendance Post_2016 Rupture_Pente, lag(1)

capture drop cycle_free_expr
tsfilter hp cycle_free_expr = free_expr, smooth(6.25)
tsline cycle_free_expr, tline(2016) yline(0) title("Cycle : Liberté Expression") subtitle("Écarts à la tendance (HP Filter)") name(hp_expr, replace)
newey free_expr Tendance Post_2016 Rupture_Pente, lag(1)

capture drop cycle_corruption
tsfilter hp cycle_corruption = corruption, smooth(6.25)
tsline cycle_corruption, tline(2016) yline(0) title("Cycle : Corruption") subtitle("Écarts à la tendance (HP Filter)") name(hp_corrup, replace)
newey corruption Tendance Post_2016 Rupture_Pente, lag(1)


capture drop cycle_crime_rate
tsfilter hp cycle_crime_rate = crime_rate, smooth(6.25)
tsline cycle_crime_rate, tline(2016) yline(0) title("Cycle : Criminalité") subtitle("Écarts à la tendance (HP Filter)") name(hp_crime, replace)
newey crime_rate Tendance Post_2016 Rupture_Pente, lag(1)


capture drop cycle_prison_rate
tsfilter hp cycle_prison_rate = prison_rate, smooth(6.25)
tsline cycle_prison_rate, tline(2016) yline(0) title("Cycle : Taux Incarcération") subtitle("Écarts à la tendance (HP Filter)") name(hp_prison_rate, replace)
newey prison_rate Tendance Post_2016 Rupture_Pente, lag(1)

capture drop cycle_level
tsfilter hp cycle_level = level, smooth(6.25)
tsline cycle_level, tline(2016) yline(0) title("Cycle : Niveau d'Espoir") subtitle("Écarts à la tendance (HP Filter)") name(hp_level, replace)
newey level Tendance Post_2016 Rupture_Pente, lag(1)

*---------------------------------------------------------------------------
* C. MODÈLE VAR & IRF (IMPULSE RESPONSE FUNCTIONS)
*---------------------------------------------------------------------------

* --- ANALYSE 1 : SHOC (2016) ---
	
* VAR institution
var Choc_Reel std_civil_lib std_free_expr std_corruption, lags(1)
irf set annual_inst.irf, replace
irf create inst, step(5) replace
irf graph oirf, impulse(Choc_Reel) response(std_civil_lib std_free_expr std_corruption) level(90) yline(0, lcolor(black)) title("Bloc Institutionnel (IC 90%)") name(irf_inst_90, replace)

* VAR macro
var Choc_Reel std_fdi std_tourism, lags(1)
irf set annual_econ.irf, replace
irf create econ, step(5) replace
irf graph oirf, impulse(Choc_Reel) response(std_fdi std_tourism) level(90) yline(0, lcolor(black)) title("Bloc Économique (IC 90%)") name(irf_econ_90, replace)

*VAR criminality
var Choc_Reel std_crime_rate std_prison_rate, lags(1)
irf set annual_soc.irf, replace
irf create soc, step(5) replace
irf graph oirf, impulse(Choc_Reel) response(std_crime_rate std_prison_rate) ///
    level(90) yline(0, lcolor(black)) title("Bloc Sécurité & Social (IC 90%)") name(irf_soc_90, replace)
	
	
	
* --- ANALYSE 2 : PLACEBO TEST (2015) ---
var Choc_Placebo std_fdi std_tourism std_civil_lib, lags(1)

* Creation of results
irf create res_2015, step(5) replace

* Placebo Chart
irf graph oirf, irf(res_2015) impulse(Choc_Placebo) response(std_fdi std_tourism std_civil_lib) yline(0) title("Test Placebo (2015) - Standardisé") name(graph_irf_placebo, replace)






