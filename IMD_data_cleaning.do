
clear all 

cd "D:\OneDrive - London School of Economics\Desktop\EC428\Datasets"


import delimited "D:\OneDrive - London School of Economics\Desktop\EC428\Datasets\Sub_Division_IMD_2017.csv", numericcols(3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19) clear 

/*
               SUBDIVISION |      Freq.     Percent        Cum.
-----------------------------------+-----------------------------------
         Andaman & Nicobar Islands |        112        2.67        2.67
                 Arunachal Pradesh |         99        2.36        5.04
                 Assam & Meghalaya |        117        2.79        7.83
                             Bihar |        117        2.79       10.63
                      Chhattisgarh |        117        2.79       13.42
            Coastal Andhra Pradesh |        117        2.79       16.21
                 Coastal Karnataka |        117        2.79       19.01
               East Madhya Pradesh |        117        2.79       21.80
                    East Rajasthan |        117        2.79       24.59
                East Uttar Pradesh |        117        2.79       27.39
              Gangetic West Bengal |        117        2.79       30.18
                    Gujarat Region |        117        2.79       32.98
        Haryana Delhi & Chandigarh |        117        2.79       35.77
                  Himachal Pradesh |        117        2.79       38.56
                   Jammu & Kashmir |        117        2.79       41.36
                         Jharkhand |        117        2.79       44.15
                            Kerala |        117        2.79       46.94
                      Konkan & Goa |        117        2.79       49.74
                       Lakshadweep |        116        2.77       52.51
                Madhya Maharashtra |        117        2.79       55.30
                        Matathwada |        117        2.79       58.09
            Naga Mani Mizo Tripura |        117        2.79       60.89
          North Interior Karnataka |        117        2.79       63.68
                            Orissa |        117        2.79       66.48
                            Punjab |        117        2.79       69.27
                        Rayalseema |        117        2.79       72.06
                Saurashtra & Kutch |        117        2.79       74.86
          South Interior Karnataka |        117        2.79       77.65
Sub Himalayan West Bengal & Sikkim |        117        2.79       80.44
                        Tamil Nadu |        117        2.79       83.24
                         Telangana |        117        2.79       86.03
                       Uttarakhand |        117        2.79       88.83
                          Vidarbha |        117        2.79       91.62
               West Madhya Pradesh |        117        2.79       94.41
                    West Rajasthan |        117        2.79       97.21
                West Uttar Pradesh |        117        2.79      100.00
-----------------------------------+-----------------------------------
                             Total |      4,188      100.00

East Uttar Pradesh
West Uttar Pradesh

*/

 replace subdivision = "Uttar Pradesh" if subdivision == "East Uttar Pradesh"

 replace subdivision = "Uttar Pradesh" if subdivision == "West Uttar Pradesh"

 save "IMD_rainfall.dta", replace
  

  //EDITTING DATA IN A FRAME 
 
 
 use "IMD_rainfall.dta", clear
 
 keep if subdivision == "Uttar Pradesh" | subdivision == "Bihar"
 
 //to average the rainfall data for Eastern and Western Uttar Pradesh
 collapse (mean) jan feb mar apr may jun jul aug sep oct nov dec annual jf mam jjas ond, by(subdivision year)
 
 
 /*
 
 keep if subdivision == "Uttar Pradesh" | subdivision == "Uttarakhand"
 
 collapse (mean) jan feb mar apr may jun jul aug sep oct nov dec annual jf mam jjas ond, by(subdivision year)
 
 //Uttarakhand got seperated from Uttar Pre
 drop if subdivision == "Uttarakhand" & year >= 2000
 
  
  collapse (mean) jan feb mar apr may jun jul aug sep oct nov dec annual jf mam jjas ond, by(year)
 
 
  gen subdivision = "UP"
  
  append using "IMD_rainfall.dta"
  
  save "Uttar_Pradesh_rainfall.dta", replace
  
 
  keep if subdivision == "UP" | subdivision == "Bihar"
 
  rename subdivision state
  
  replace state = "Uttar Pradesh" if state == "UP"
  
  */
  
  keep if year >= 1953
  
 
 //Averaging temperature across months
 
 egen average = rowmean(jan-dec)
 
 cd "D:\OneDrive - London School of Economics\Extended Essay-DESKTOP-HEI11BP\DTA_NSS_R64_10_2"
 
 /*
 gen State = 09 if state == "Uttar Pradesh"
 replace State = 10 if state == "Bihar"
 */
 
 rename subdivision State 
 
 rename year year_leaving_upr
 
 save "IMD_climate_change", replace
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 


egen average = rowmean(jan-dec)
