global raw_data "G:\My Drive\metodologia\New folder\E_Raw_Data"
global micro_data "G:\My Drive\metodologia\New folder\A_Micro_Data"
global tables "G:\My Drive\metodologia\New folder\G_Tables"

cd "${micro_data}"

*** Extracting dat form SPSS to DTA and saving from Raw_data to Micro_Data
	
	/*** Households
		
		import spss using "${raw_data}\CAP_100_URBANO_RURAL_3.sav", clear
		save hogar_1, replace

	*** Families

		import spss using "${raw_data}\CAP_200_URBANO_RURAL_4.sav", clear
		save familia_1, replace

	*** Education

		import spss using "${raw_data}\CAP_300_URBANO_RURAL_5.sav", clear
		save education, replace
	*/

*** Working with general information about households. Extracting capacitation and recycling
	use hogar_1, clear
	isid CCDD CCPP CCDI CONGLOMERADO NSELV VIVIENDA HOGAR
	keep  CCDD CCPP CCDI CONGLOMERADO NSELV VIVIENDA HOGAR AREA P175A P175D
	rename ( P175A P175D ) ( recycle capacitation )
	// TSELV urbano rural 
	// P175A segrega o no
	// P175D algun miembro del hogar capacitado
	tempfile households
	save `households'

*** Extracting education information. I assumed P300_A is equal to P201
	use education, replace	
	keep  CCDD CCPP CCDI CONGLOMERADO NSELV VIVIENDA HOGAR AREA P300_A P301A ESTRATO
	rename (P301A ) ( education)
	tempfile education_1
	save `education_1'
	// P301A Nivel de educación
	// P300_A persona nro identifica plus CCDD CCPP CCDI CONGLOMERADO NSELV VIVIENDA HOGAR
	// we will assume P300_A

*** Extracting general information
	use familia_1, clear
	keep CCDD CCPP CCDI CONGLOMERADO NSELV VIVIENDA HOGAR AREA P203 P207 P208_A P201
	rename ( P203 P207 P208_A P201 ) ( rh sex age P300_A )
	merge 1:1 CCDD CCPP CCDI CONGLOMERADO NSELV VIVIENDA HOGAR AREA P300_A using `education_1'
	drop _merge

*** Cleaning data
		
	// Changing education from string to years
	gen edyears = 0 if education == "1"
	replace edyears = 0 if education == "1A"
	replace edyears = 0 if education == "2"
	replace edyears = 3 if education == "3"
	replace edyears = 6 if education == "4"
	replace edyears = 8 if education == "5"
	replace edyears = 11 if education == "6"
	replace edyears = 12 if education == "7"
	replace edyears = 14 if education == "8"
	replace edyears = 14 if education == "9"
	replace edyears = 16 if education == "10"
	replace edyears = 18 if education == "11"

	// Changing education from string to years
	replace education = "0 Sin Nivel" 			if education ==  	"1"  
	replace education = "0 Sin Nivel"		 	if education == 	"1A"  
	replace education = "0 Sin Nivel" 			if education ==  	"2"  
	replace education = "1 Pr. Incom" 			if education ==  	"3"
	replace education = "2 Pr. Comp"			if education ==  	"4"
	replace education = "3 Sec. Incom" 			if education ==  	"5"  
	replace education = "4 Sec. Comp" 			if education ==  	"6"
	replace education = "5 Sup No Uni Incom" 	if education ==  	"7"
	replace education = "6 Sup No Uni Comp" 	if education ==  	"8"
	replace education = "7 Pregrado Incom" 		if education ==  	"9"
	replace education = "8 Pregrado Comp" 		if education == 	"10"
	replace education = "9 Postgrado" 			if education == 	"11"


	// Generating an ID for each family and generating the max education
	egen id_family = group( CCDD CCPP CCDI CONGLOMERADO NSELV VIVIENDA HOGAR )
	bys id_family: egen max_edyears = max( edyears )
	// Size family
	bys id_family: gen size_fam = _N
	bys id_family: gen max_edu_class = education if edyears == max_edyears
	bysort id_family (max_edu_class): replace max_edu_class = max_edu_class[_N]

	// Merging and filtering people
	merge m:1 CCDD CCPP CCDI CONGLOMERADO NSELV VIVIENDA HOGAR using `households'
	drop _merge
	keep if AREA == 1
	keep if rh == 1 

	// Relabel recycle and capacitation
	replace recycle = 0 if recycle == 2
	replace capacitation = 0 if capacitation == 2
	replace sex = 0 if sex == 1
	replace sex = 1 if sex == 2

	// encoding string variables
	encode education, gen( edu_encode )
	encode max_edu_class, gen( max_edu_class_encode)
	drop education max_edu_class
	rename ( edu_encode max_edu_class_encode ) ( education max_edu )
	// encode CCDD, gen( cluster )


*** Making estimations
	logit recycle capacitation size_fam age sex ib5.ESTRATO  i0.education
	est store model_edu_label
	margins, dydx( capacitation size_fam age sex ib5.ESTRATO  i0.education ) post
	est store margin_edu_label

	// Changing the name of the coefficient
	rename (education max_edu) (edu education)

	qui logit recycle capacitation size_fam age sex ib5.ESTRATO  i0.education
	est store model_max_edu_label
	qui margins, dydx( capacitation size_fam age sex ib5.ESTRATO  i0.education ) post
	est store margin_max_edu_label

	// Renaming the coeficient
	rename (edu education) (education max_edu) 

	
	qui logit recycle capacitation size_fam age sex ib5.ESTRATO edyears
	est store model_edu_year
	qui margins, dydx( capacitation size_fam age sex ib5.ESTRATO edyears ) post
	est store margin_edu_year

	// CHanging the name of the coeficient eduyears
	rename ( edyears max_edyears) ( edy edyears)

	qui logit recycle capacitation size_fam age sex ib5.ESTRATO edyears
	est store model_max_edu_year
	qui margins, dydx( capacitation size_fam age sex ib5.ESTRATO edyears ) post
	est store margin_max_edu_year

	rename ( edy edyears) ( edyears max_edyears)


*** Making table of the results

	
	*** Table written in Latex
	/*
		esttab 	model_edu_label margin_edu_label model_edu_year margin_edu_year  ///
			model_max_edu_label margin_max_edu_label model_max_edu_year margin_max_edu_year  using "${tables}/table_9.tex", replace			 ///
			eqlabels(" " " " " " " " " " " " " " " ") ///
			style(tab) order( ) mlabel(,none) ///
			cells(b(label(coef.) star fmt(%8.3f) ) se(label((z)) par fmt(%6.3f))) ///
			starlevels(* 0.10 ** 0.05 *** 0.01) ///  
			s(N , label( "N" ) fmt(%9.0gc) )  ///
			collabels(none) /// No column names within model
			delim("&")  /// Type of column delimiter 
			noobs /// Do not show number of observation used in model
			nomtitle ///
			label ///
			drop( _cons 1.education 5.ESTRATO ) ///
			width(1.5\hsize) ///
			nogaps /// No gaps between rows
			booktabs /// Style
			nonote /// No notes
			varlabels(capacitation "Capacitación" 1.ESTRATO "A" 2.ESTRATO "B" 3.ESTRATO "C" 4.ESTRATO "D"  ///
						size_fam "Tamaño de familia" age "Edad" sex "Sexo" 2.education "Pr. Incom." 3.education "Pr. Com." ///
						4.education "Sec. Incom." 5.education "Sec. Com." 6.education "No Uni. Incom." 7.education "No Uni. Com." ///
						8.education "Uni. Incom." 9.education "Uni. Com." 10.education "Postgrado" edyears "Años de educacion") ///
			mgroups( "Head Education Label"    "Margin Effects"		 "Head Education Years"		 "Margin Effects" "Max Education Label" "Margin Effects" "Max Education Years" "Margin Effects" , pattern(1 1 1 1 1 1 1 1) ) ///
			nonumbers ///
			refcat(capacitation  "\Gape[0.25cm][0.25cm]{ \underline{ Panel A.\textbf{ \textit{ Familia } } } }"  ///
					1.ESTRATO "\Gape[0.25cm][0.25cm]{ \underline{ Panel B.\textbf{ \textit{ Estrato Socioeconomico } } } }" /// Subtitles
					2.education "\Gape[0.25cm][0.25cm]{ \underline{ Panel C.\textbf{ \textit{ Educacion Niveles } } } }" /// 
					edyears "\Gape[0.25cm][0.25cm]{ \underline{ Panel D.\textbf{ \textit{ Educacion Años } } } }", nolabel) /// Subtitles
			prehead("\begin{table} \small \centering \protect \captionsetup{justification=centering} \caption{\label{tab:table1} Modelo logit de reciclaje }" "\noindent\resizebox{\textwidth}{!}{ \begin{threeparttable}" "\begin{tabular}{lcccccccc}" \toprule) ///
			postfoot(\hline \end{tabular} ///
				\begin{tablenotes} ///
				\begin{footnotesize} ///
				${note} ///
				\end{footnotesize} ///
				"\end{tablenotes} \end{threeparttable} } \end{table}")
	*/

	*** Tables written for MS-Word

	esttab 	model_edu_label margin_edu_label model_edu_year margin_edu_year  using "${tables}/table_1.rtf", replace		 ///
			eqlabels( " " " " " " " " ) ///
			style(tab) order( ) mlabel(,none) ///
			cells(b(label(coef.) star fmt(%8.3f) ) ) ///
			starlevels(* 0.10 ** 0.05 *** 0.01) ///  
			s(N , label( "N" ) fmt(%9.0gc) )  ///
			collabels(none) ///
			noobs /// Do not show number of observation used in model
			label ///
			drop( _cons 1.education 5.ESTRATO ) ///
			width(1.5\hsize) ///
			nogaps /// No gaps between rows
			rtf /// Style
			nonote /// No notes
			varlabels(capacitation "Capacitación" 1.ESTRATO "A" 2.ESTRATO "B" 3.ESTRATO "C" 4.ESTRATO "D"  ///
						size_fam "Tamaño de familia" age "Edad" sex "Sexo" 2.education "Primaria Incom." 3.education "Primaria Com." ///
						4.education "Secundaria Incom." 5.education "Secundaria Com." 6.education "No Univ. Incom." 7.education "No Univ. Com." ///
						8.education "Univ. Incom." 9.education "Univ. Com." 10.education "Postgrado" edyears "Años de educación") ///
			mgroups( "Educación en Niveles" "Efectos Marginales" "Educación en Años" "Efectos Marginales" , pattern(1 1 1 1 ) ) ///
			nonumbers ///
			refcat(capacitation  "Panel A. Familia"  ///
					1.ESTRATO "Panel B. Estrato Socioeconómico" /// Subtitles
					2.education "Panel C. Educación Niveles" ///
					edyears "Panel D. Educación Años", nolabel) ///
			title( "Determinantes del Reciclaje (1)" ) ///
			note( "*p<0.05, **p<0.01, ***p<0.001"  "(1) Educación del jefe de familia")

			unicode convertfile "${tables}/table_1.rtf" "${tables}/table_3.rtf",  replace dstencoding( ISO-8859-1 ) 




	esttab 	model_max_edu_label margin_max_edu_label model_max_edu_year margin_max_edu_year using "${tables}/table_2.rtf", replace		 ///
			eqlabels( " " " " " " " " ) ///
			style(tab) order( ) mlabel(,none) ///
			cells(b(label(coef.) star fmt(%8.3f) ) ) ///
			starlevels(* 0.10 ** 0.05 *** 0.01) ///  
			s(N , label( "N" ) fmt(%9.0gc) )  ///
			collabels(none) ///
			noobs /// Do not show number of observation used in model
			label ///
			drop( _cons 1.education 5.ESTRATO ) ///
			width(1.5\hsize) ///
			nogaps /// No gaps between rows
			rtf /// Style
			nonote /// No notes
			varlabels(capacitation "Capacitación" 1.ESTRATO "A" 2.ESTRATO "B" 3.ESTRATO "C" 4.ESTRATO "D"  ///
						size_fam "Tamaño de familia" age "Edad" sex "Sexo" 2.education "Primaria Incom." 3.education "Primaria Com." ///
						4.education "Secundaria Incom." 5.education "Secundaria Com." 6.education "No Univ. Incom." 7.education "No Univ. Com." ///
						8.education "Univ. Incom." 9.education "Univ. Com." 10.education "Postgrado" edyears "Años de educación") ///
			mgroups( "Educación en Niveles" "Efectos Marginales" "Educación en Años" "Efectos Marginales" , pattern(1 1 1 1 ) ) ///
			nonumbers ///
			refcat(capacitation  "Panel A. Familia"  ///
					1.ESTRATO "Panel B. Estrato Socioeconómico" /// Subtitles
					2.education "Panel C. Educación Niveles" ///
					edyears "Panel D. Educación Años", nolabel) ///
			title( "Determinantes del Reciclaje (2)" ) ///
			note( "*p<0.05, **p<0.01, ***p<0.001"  "(2) Máximo Nivel de Educación en la familia")

			unicode convertfile "${tables}/table_2.rtf" "${tables}/table_4.rtf", replace dstencoding( ISO-8859-1 ) 






// P201 N0 de orden
// P300_A Nro persona
// P203 relación con el jefe de hogar
// P207 sexo
// P208_A edad
// **elabel list ( P203 ) relacion de parentezco 1 jefe 2 esposo 3 hijos
// cabe avisar que esta data tiene a nivel de familias dentro del hogar.
// Nosotros vamos a tomar solo las familias principales no las que pertencen al nucleo familiar

