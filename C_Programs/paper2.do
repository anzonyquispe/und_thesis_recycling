***Estimación del paper reciclar***
clear all
cd "C:\Users\Anzony\Desktop\Escritorio\UNALM\orihuela_group\data"
import delimited C:\Users\Anzony\Desktop\Escritorio\UNALM\orihuela_group\data\base_final4.csv
//ssc install outreg
//ssc install estout

label variable segrega "Reciclaje"
label variable capacitacion "Capacitación"
label variable n_family "Tamaño de la familia"
label variable n_man "N° hombres"
label variable n_edad "N° > 18"
label variable educacion "Max educacion"
label variable estrato "Estrato socioeconómico"
label define estrarato 5 "A" 4 "B" 3 "C" 2 "D" 1 "E"
label define educ 1 "Sin nivel" 2 "Inicial" 3 "Prim incomp" 4 "Prim comp" 5 "Sec incomp" 6 "Sec comp" 7 "Sup NoUniv incomp" 8 "Sup NoUniv comp" 9 "Preg incomp" 10 "Preg comp" 11 "Postgrado"
label values educacion educ
label values estrato estrarato
label define recycle 1 "Recicla" 0 "No Recicla"
label values segrega recycle
label define capo 1 "Capacitado" 0 "Sin capacitar"
label values capacitacion capo

decode educacion, gen(educ)
decode estrato, gen(est)
decode segrega, gen(rcy)

summarize n_family n_man n_edad
tabulate rcy
tabulate est
tabulate educ

tabulate est rcy, row wrap
tabulate segrega capacitacion, row 
tabulate educ segrega



logit segrega capacitacion i.estrato n_family n_man n_edad i.educacion
margins, dydx( capacitacion i.estrato n_family n_man n_edad i.educacion) post
eststo: quietly logit segrega capacitacion i.estrato n_family n_man n_edad i.educacion
eststo:  logit segrega capacitacion i.estrato n_family n_man n_edad i.educacion
eststo: margins, dydx( capacitacion i.estrato n_family n_man n_edad i.educacion) post
esttab using est2.rtf,  se r2 ar2 label bic aic margin wide title("Resultados econométricos para el modelo logit") mtitles ("Reciclaje" "Marginales") scalars(chi2)


esttab,  se r2 ar2 label bic aic margin title("Resultados econométricos para el modelo logit") mtitles ("Reciclaje" "Marginales") scalars(chi2)

gen estrato2 = real(estrato)


eststo clear
estout
eststo mfx: mfx, predict(p)
eststo: eq2
estout: margins, dydx(capacitacion i.estrato n_family n_man n_edad i.educacion)

