gen qdate = qofd(Date)
format qdate %tq
tsset qdate

gen Choc_Reel = (qdate == yq(2016, 3))
gen Choc_Placebo = (qdate == yq(2015, 3))
gen Post_2016 = (qdate >= yq(2016, 3))
gen Tendance = qdate - yq(2010, 1)
gen Rupture_Pente = Post_2016 * (qdate - yq(2016, 2))

foreach var in cpi prod bop {
    egen std_`var' = std(`var')
}

gen choc_cpi = (D.cpi / L.cpi) * 100
gen choc_prod = (D.prod / L.prod) * 100
gen choc_bop = (D.bop / L.bop) * 100

gen d_cpi = D.cpi
gen d_prod = D.prod
gen d_bop = D.bop

tsline prod, tline(2016q3) title("Volume de Production (Trimestriel)") name(g_prod, replace)
tsline cpi, tline(2016q3) title("Indices des Prix à la Consommation") name(g_cpi, replace)


*table
irf set "quarterly_analysis.irf", replace
var Choc_Reel std_d_cpi std_d_prod std_d_bop, lags(1/4)
irf create order1, step(10) replace

* 4. graph
irf graph oirf, impulse(Choc_Reel) response(std_d_cpi std_d_prod std_d_bop) level(90) yline(0, lcolor(black)) title("Impact (Diff. Premières) - IC 90%") subtitle("Réponses impulsionnelles avec intervalle à 90%") name(irf_diff_90, replace)

*granger test
vargranger
	
	
	