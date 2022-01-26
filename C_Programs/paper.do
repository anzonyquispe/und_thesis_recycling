import delimited C:\Users\Anzony\Desktop\Escritorio\UNALM\orihuela_group\data\data10.csv
probit reciclar estrato capacitacion  n_family n_man  n_edad educacion, vce(robust)
quietly probit reciclar estrato capacitacion  n_family n_man n_edad educacion, vce(robust)
mfx

probit segregacion estrato_socioeco capacitacion  n_familia n_hombres  n_adultos educacion, vce(robust)
quietly probit segregacion estrato_socioeco capacitacion  n_familia n_hombres  n_adultos educacion, vce(robust)
mfx
br(

logit segregacion estrato_socioeco capacitacion  n_familia n_hombres  n_adultos educacion, vce(robust)
quietly logit segregacion estrato_socioeco capacitacion  n_familia n_hombres  n_adultos educacion, vce(robust)
mfx
