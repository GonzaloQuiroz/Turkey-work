clear all
global main "C:\Users\universidad\Google Drive\PUCP - ECONOMÍA\CICLO 2021-1\ECONOMÍA INTERNACIONAL 2\TAREA 1"
global dta  "$main\Datos"
global works "$main\resultados"
cd "C:\Users\universidad\Google Drive\PUCP - ECONOMÍA\CICLO 2021-1\ECONOMÍA INTERNACIONAL 2\TAREA 1"



** PARTE 1
*Pregunta 1
use "$dta\agg_wld_data_feenstra.dta"   , clear  
merge 1:m year iso3_o iso3_d  using  "$dta\gravdata_smpl.dta"
drop if year<1991 //de 1991 para abajo no se cuenta con información
drop if year>2014
drop if exp_value == .
drop if iso3_o=="ZAF" & iso3_d=="ZAF"
keep year exp_value fta_wto iso3_d iso3_o countryname_i countryname_e gdp_o
preserve
keep if iso3_o=="ZAF"
rename iso3_o pareja
save "$works\base1.dta" , replace
restore 
preserve
keep if iso3_d=="ZAF"
rename iso3_d pareja
save "$works\base2.dta" , replace
restore
** Pregunta 1
** Combinamos los datos anteriormente generadas
clear all 
use "$works\base1.dta"  , clear  
merge 1:1 year pareja exp_value fta_wto countryname_i countryname_e  using "$works\base2.dta" 
** Genero las importaciones y las exportaciones de Sudáfrica (en miles)
gen importaciones=exp_value/1000 if countryname_i=="South Africa" 
gen exportaciones=exp_value/1000 if countryname_e=="South Africa"
*Pregunta 2 : Gráfico de exportaciones
graph bar (sum) exportaciones , over(year, label(angle(vertical))) ylabel(#3) ///
title("Exportaciones de Sudáfrica") ///
graphregion(color(white)) ylabel(,nogrid) ///
ytitle("En miles", margin(medsmall) size(*1.0)) ///
bar(1, color(black))
graph export "$works\Exportaciones.png", as (png) replace
*Pregunta 3 : Gráfico de importaciones
graph bar (sum) importaciones , over(year, label(angle(vertical))) ylabel(#3) ///
title("Importaciones de Sudáfrica") ///
graphregion(color(white)) ylabel(,nogrid) ///
ytitle("En miles", margin(medsmall) size(*1.0)) ///
bar(1, color(black))
graph export "$works\Importaciones.png", as (png) replace
*Pregunta 4
** reemplazo los missing por 0 para poder operar
replace importaciones = 0 if(importaciones == .)
replace exportaciones = 0 if(exportaciones == .)
** genero la variable expimp
gen expimp= exportaciones + importaciones
** Encuentro el país que más exporta con Sudáfrica
tabstat expimp if year==2000, statistics(max) by(countryname_i) 
**Máximo valor United Kingdom  5079295
** Genero la variable Balanza Comercial(BC)
gen bc= exportaciones - importaciones
** Grafico la balanza comercial
graph bar (sum) bc  if countryname_e=="South Africa" & countryname_i=="United Kingdom" | countryname_e=="United Kingdom" & countryname_i=="South Africa"  , over(year, label(angle(vertical))) ///
title("Balanza Comercial entre Sudáfrica y Gran Bretaña") ///
graphregion(color(white)) ylabel(,nogrid) ///
ytitle("Balanza Comercial (en miles)", margin(medsmall) size(*0.8)) ///
bar(1, color(black))
graph export "$works\Balanza.png", as (png) replace
*Pregunta 5
table countryname_i if fta_wto==1 & countryname_e=="South Africa"
** Listado de paises con los que Sudáfrica tiene TLC:    Austria ,Belgium , Bulgaria , Congo, Rep. , Croatia   ,   Cyprus , Czech Republic   , Denmark  ,  Estonia,  Finland    , France  ,  Germany  ,    Greece   ,   Hungary ,   Iceland  ,    Ireland   ,     Italy , Latvia     ,    Lithuania      ,        Madagascar    ,    Malawi    ,    Malta     ,   Mauritius      ,       Mozambique  , Netherlands , Norway    ,   Poland    ,   Portugal     ,   Romania      ,   Slovak Republic        ,       Slovenia   ,     Spain   ,    Sweden , Switzerland     ,      United Kingdom   ,   Zambia  
* Genero la variable pbi de sudáfrica
egen pbizaf= mean(gdp_o) if countryname_e=="South Africa" , by(year)
** Colpasamos las variables exportacion importacion BC Y PBI de ZAF
collapse (sum) exportaciones importaciones bc (mean) pbizaf, by(year fta_wto)
**Generamos a la balanza comercial como porcentaje del PBI
gen percentpbi= (bc*10000000)/(pbizaf)
** Grafica de los países que tienen TLC con Sudáfrica
graph bar percentpbi if fta_wto==1  , over(year, label(angle(45)))  ///
title( "Balanza Comercial de Sudáfrica como % del PBI con los paises que tiene TLC", margin(medium) size(*0.7)  )  ///
graphregion(color(white)) ylabel(,nogrid) ///
ytitle("%", size(*0.8)) ///
ylabel(, angle(45) format(%3.1f)) ///
blabel(bar, format(%3.2f)) bar(1, color(black)) 
graph export "$works\ConTLC.png", as (png) replace
*Pregunta 6
** Grafica de los países que no tienen TLC con Sudáfrica
graph bar   percentpbi if fta_wto==0 , over(year, label(angle(vertical))) ///
title("Balanza Comercial de Sudáfrica como % del PBI con los países que no tiene TLC " , margin(medium) size(*0.7)) ///
graphregion(color(white)) ylabel(,nogrid) ///
ylabel(, format(%3.1f)) ///
ytitle("%",  size(*0.8)) ///
blabel(bar, size(vsmall) format(%3.2f) ) bar(1, color(black)) 
graph export "$works\SinTLC.png", as (png) replace



** PARTE 2
ssc install reghdfe
use "$dta\agg_wld_data_feenstra.dta"   , clear  
merge 1:m year iso3_o iso3_d  using  "$dta\gravdata_smpl.dta"
drop if year<1991 //de 1991 para abajo no se cuenta con información
drop if year>2014
drop if exp_value == .
gen new_exp_value=1000*exp_value
** Creamos nuevas/modificamos variables
gen ln_exp=ln(new_exp_value)
gen ln_gdp_exp=ln(gdp_o)
gen ln_gdp_imp=ln(gdp_d)
rename (gdp_o gdp_d) (gdp_exp gdp_imp)
order iso3_o iso3_d year
** Efectos fijos
sort iso3_o iso3_d year
egen exporter=group(iso3_o)
sort iso3_d iso3_o year
egen importer=group(iso3_d)
egen importer_year=group(importer year)
egen exporter_year=group(exporter year)
egen importer_exporter=group(importer exporter)
** Variables de control
gen ln_dist=ln(distw)
gen ln_pop_exp=ln(pop_o)
gen ln_pop_imp=ln(pop_d)
*Pregunta 1
reghdfe ln_exp gdp_exp gdp_imp fta_wto ln_pop_exp ln_pop_imp comlang_off ln_dist comcur, noabsorb vce(robust) 
outreg2 using "Ejercicio2.1.xls", bdec(4) rdec(3) bracket nolabel ///
ctitle(Modelo 1)  replace
*Pregunta 2
reghdfe ln_exp gdp_exp gdp_imp fta_wto ln_pop_exp ln_pop_imp, absorb(i.importer i.exporter) vce(robust) 
outreg2 using "Ejercicio2.2.xls", bdec(4) rdec(3) bracket nolabel ///
ctitle(Modelo 2) addtext(Country FE, YES) append
*Pregunta 3
reghdfe ln_exp gdp_exp gdp_imp fta_wto, absorb(importer_year exporter_year) vce(robust)
outreg2 using "Ejercicio2.3.xls", bdec(4) rdec(3) bracket nolabel ///
ctitle(Modelo 3) addtext(Country FE, YES, Country-Year FE, YES) append
*Pregunta 4
reghdfe ln_exp gdp_exp gdp_imp fta_wto, absorb(importer_year exporter_year importer_exporter) cluster(importer_exporter)
outreg2 using "Ejercicio2.4.xls", bdec(4) rdec(3) bracket nolabel ///
ctitle(Modelo 4) addtext(Country FE, YES, Country-Year FE, YES, Country-Country FE, YES) append



** PARTE 3
**staw: acuerdos comerciales entre el total de países - sudáfrica
gen staw=1 if fta_wto==1 
replace staw=0 if missing(staw)
replace staw=0 if iso3_o=="ZAF"
replace staw=0 if iso3_d=="ZAF"
**staz: acuerdos comerciales de sudáfrica con los demás países
gen staz=0 if fta_wto==1 
replace staz=1 if iso3_o=="ZAF" & fta_wto==1
replace staz=1 if iso3_d=="ZAF" & fta_wto==1
replace staz=0 if missing(staz)
**regresión
reghdfe ln_exp staw staz, absorb(importer_year exporter_year importer_exporter) cluster(importer_exporter)
	outreg2 using "Ejercicio3.xls", bdec(4) rdec(3) bracket nolabel ///
	ctitle(Modelo 1) addtext(Country FE, YES, Country-Year FE, YES, Country-Country FE, YES) replace
**TLC cuando sudáfrica es exportador
gen staze=0
replace staze=1 if staz==1 & iso3_o=="ZAF"
**TLC cuando sudáfrica es importador
gen stazi=0
replace stazi=1 if staz==1 & iso3_d=="ZAF"
**regresión 
reghdfe ln_exp staw staze stazi, absorb(importer_year exporter_year importer_exporter) cluster(importer_exporter)
	outreg2 using "Ejercicio3.xls", bdec(4) rdec(3) bracket nolabel ///
	ctitle(Modelo 2) addtext(Country FE, YES, Country-Year FE, YES, Country-Country FE, YES) append



** PARTE 4
tab countryname_i if staz==1
tab importer if staz==1
** Países con los que Zudáfrica tiene acuerdos comerciales
** Austria			Belgium 		Bulgaria		Congo, Rep.		Croatia
** Cyrpus			Czech Repblic	Denmark			Estonia			Finland				France
** Germany			Greece			Hungay			Iceland			Ireland				Italy
** Latvia			Lithuania		Madagascar		Malawi			Malta				Mauritius
** Mozambique		Netherlands		Norway			Poland			Portugal			Romania
** Slovak Republic	Slovenia		Spain			Sweden			Switzerland			United Kingdom
** Zambia
**variable para identifcar los efectos entre acuerdos con países
foreach i in 8 11 15 27 32 36 37 38 39 44 45 47 49 51 57 63 65 68 71 73 90 91 95 98 100 102 103 109 110 119 121 124 135 136 137 159 {
gen sta_`i'=0 if fta_wto==1 
replace sta_`i'=0 if missing(sta_`i')
replace sta_`i'=1 if  importer==`i' & iso3_o=="ZAF" & fta_wto==1
replace sta_`i'=1 if iso3_d=="ZAF" & exporter==`i' & fta_wto==1
}
rename (sta_8 sta_11 sta_15 sta_27 sta_32 sta_36 sta_37 sta_38 sta_39 sta_44 sta_45 sta_47 sta_49 sta_51 sta_57 sta_63 sta_65 sta_68 sta_71 sta_73 sta_90 sta_91 sta_95 sta_98 sta_100 sta_102 sta_103 sta_109 sta_110 sta_119 sta_121 sta_124 sta_135 sta_136 sta_137 sta_159) (sta_Austria sta_Beligca sta_Bulgaria sta_Congo sta_Croacia sta_Cyrpus sta_CzechR sta_Denmark sta_Estonia sta_Finland sta_France sta_Germany sta_Greece sta_Hungay sta_Iceland sta_Ireland sta_Italy sta_Latvia sta_Lithuania sta_Madagascar sta_Malawi sta_Malta sta_Mauritius sta_Mozambique sta_Netherlands sta_Norway sta_Poland sta_Portugal sta_Romania sta_SlovakR sta_Slovenia sta_Spain sta_Sweden sta_Switzerland sta_UnitedK sta_Zambia)
**regresión
reghdfe ln_exp staw sta_*, absorb(importer_year exporter_year importer_exporter) cluster(importer_exporter)
outreg2 using "Ejercicio4.1.xls", bdec(4) rdec(3) bracket nolabel ///
ctitle(Modelo 1) addtext(Country FE, YES, Country-Year FE, YES, Country-Country FE, YES) replace 
**TLC cuando sudáfrica es exportador
foreach i in 8 11 15 27 32 36 37 38 39 44 45 47 49 51 57 63 65 68 71 73 90 91 95 98 100 102 103 109 110 119 121 124 135 136 137 159 {
gen sta_exp_`i'=0
replace sta_exp_`i'=1 if staz==1 & iso3_o=="ZAF" & importer==`i'
}
rename (sta_exp_8 sta_exp_11 sta_exp_15 sta_exp_27 sta_exp_32 sta_exp_36 sta_exp_37 sta_exp_38 sta_exp_39 sta_exp_44 sta_exp_45 sta_exp_47 sta_exp_49 sta_exp_51 sta_exp_57 sta_exp_63 sta_exp_65 sta_exp_68 sta_exp_71 sta_exp_73 sta_exp_90 sta_exp_91 sta_exp_95 sta_exp_98 sta_exp_100 sta_exp_102 sta_exp_103 sta_exp_109 sta_exp_110 sta_exp_119 sta_exp_121 sta_exp_124 sta_exp_135 sta_exp_136 sta_exp_137 sta_exp_159) (sta_exp_Austria sta_exp_Beligca sta_exp_Bulgaria sta_exp_Congo sta_exp_Croacia sta_exp_Cyrpus sta_exp_CzechR sta_exp_Denmark sta_exp_Estonia sta_exp_Finland sta_exp_France sta_exp_Germany sta_exp_Greece sta_exp_Hungay sta_exp_Iceland sta_exp_Ireland sta_exp_Italy sta_exp_Latvia sta_exp_Lithuania sta_exp_Madagascar sta_exp_Malawi sta_exp_Malta sta_exp_Mauritius sta_exp_Mozambique sta_exp_Netherlands sta_exp_Norway sta_exp_Poland sta_exp_Portugal sta_exp_Romania sta_exp_SlovakR sta_exp_Slovenia sta_exp_Spain sta_exp_Sweden sta_exp_Switzerland sta_exp_UnitedK sta_exp_Zambia)
**TLC cuando sudáfrica es importador
foreach i in 8 11 15 27 32 36 37 38 39 44 45 47 49 51 57 63 65 68 71 73 90 91 95 98 100 102 103 109 110 119 121 124 135 136 137 159 {
gen sta_imp_`i'=0
replace sta_imp_`i'=1 if staz==1 & iso3_d=="ZAF" & exporter==`i'
}
rename (sta_imp_8 sta_imp_11 sta_imp_15 sta_imp_27 sta_imp_32 sta_imp_36 sta_imp_37 sta_imp_38 sta_imp_39 sta_imp_44 sta_imp_45 sta_imp_47 sta_imp_49 sta_imp_51 sta_imp_57 sta_imp_63 sta_imp_65 sta_imp_68 sta_imp_71 sta_imp_73 sta_imp_90 sta_imp_91 sta_imp_95 sta_imp_98 sta_imp_100 sta_imp_102 sta_imp_103 sta_imp_109 sta_imp_110 sta_imp_119 sta_imp_121 sta_imp_124 sta_imp_135 sta_imp_136 sta_imp_137 sta_imp_159) (sta_imp_Austria sta_imp_Beligca sta_imp_Bulgaria sta_imp_Congo sta_imp_Croacia sta_imp_Cyrpus sta_imp_CzechR sta_imp_Denmark sta_imp_Estonia sta_imp_Finland sta_imp_France sta_imp_Germany sta_imp_Greece sta_imp_Hungay sta_imp_Iceland sta_imp_Ireland sta_imp_Italy sta_imp_Latvia sta_imp_Lithuania sta_imp_Madagascar sta_imp_Malawi sta_imp_Malta sta_imp_Mauritius sta_imp_Mozambique sta_imp_Netherlands sta_imp_Norway sta_imp_Poland sta_imp_Portugal sta_imp_Romania sta_imp_SlovakR sta_imp_Slovenia sta_imp_Spain sta_imp_Sweden sta_imp_Switzerland sta_imp_UnitedK sta_imp_Zambia)
**regresión
reghdfe ln_exp staw sta_imp* sta_exp*, absorb(importer_year exporter_year importer_exporter) cluster(importer_exporter)
outreg2 using "Ejercicio4.2.xls", bdec(4) rdec(3) bracket nolabel ///
ctitle(Modelo 1) addtext(Country FE, YES, Country-Year FE, YES, Country-Country FE, YES) replace 	
		



