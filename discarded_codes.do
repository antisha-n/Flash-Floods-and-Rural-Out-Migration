set scheme s2color
preserve 
* Create the scatter plot with enhancements
twoway (scatter ftotv year, c(1) lcolor(black) mcolor(black) msize(tiny)) ///
, legend(off) title("Flood Damage 1960- 2020", size(medium)) ///
xlabel(1980(1)2020, labsize(tiny) angle(45)) ///
ylabel(0 20(20)120) /// 
ylabel(, labsize(small)) ///
xtitle("Year", size(small)) ///
ytitle("Total damages crops, houses & public utilities (in Rs. Crore)", size(small)) ///
graphregion(color(white)) plotregion(color(white) margin(large))
restore 
