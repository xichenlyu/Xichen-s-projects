****************************************************************************
* Tactical Trading Strategy on equity E/P ratio
****************************************************************************
clear all

* Program to calculate mean and std
capture program drop mean_std_daily
program define mean_std_daily
	while "`1'" ~= "" {
		sum `1'
		scalar r_avg_d_`1' = r(mean)
		scalar sd_d_`1' = r(sd)
		scalar sd_annualized_`1' = r(sd)*sqrt(250)
		macro shift
	}
end

* Program to calculate monthly return and std
capture program drop monthly_return
program define monthly_return
	while "`1'" ~= "" {
		egen r_monthly_`1' = prod(1 + `1'), by (year month)
		sum r_monthly_`1' if r_monthly_`1' != r_monthly_`1'[_n-1]
		scalar r_avg_monthly_`1' = r(mean) - 1
		scalar sd_monthly_`1' = r(sd)
		macro shift
	}
end

* Program to calculate annual return and annual std
capture program drop annual_return
program define annual_return
	while "`1'" ~= "" {
		egen r_annual_`1' = prod(1 + `1'), by (year)
		sum r_annual_`1' if r_annual_`1' != r_annual_`1'[_n-1]
		scalar r_avg_annual_`1' = r(mean) - 1
		scalar sd_annual_`1' = r(sd)
		macro shift
	}
end

* Program to calculate sharp ratio
capture program drop Sharpe_ratio
program define Sharpe_ratio
	
	capture drop r_monthly_rf r_annual_rf
	egen r_monthly_rf = prod(1 + r_rf), by (year month)
	egen r_annual_rf = prod(1 + r_rf), by (year)

	while "`1'" ~= "" {
		gen er_`1' = `1' - r_rf
		gen er_monthly_`1' = r_monthly_`1' - r_monthly_rf
		gen er_annual_`1' = r_annual_`1' - r_annual_rf
		
		mean_std_daily er_`1'
		 
		sum er_monthly_`1' if er_monthly_`1' ~= er_monthly_`1'[_n-1]
		scalar r_avg_monthly_er_monthly_`1' = r(mean)
		
		sum er_annual_`1' if er_annual_`1' ~= er_annual_`1'[_n-1]
		scalar r_avg_annual_er_annual_`1' = r(mean)
		
		scalar Sharpe_d_`1' = r_avg_d_er_`1' / sd_d_er_`1'
		scalar Sharpe_m_`1' = r_avg_monthly_er_monthly_`1' / sd_monthly_`1'
		scalar Sharpe_annual_`1' = r_avg_annual_er_annual_`1' / sd_annual_`1'
		
		macro shift
	}
end

* Program to calculate cumulative return
capture program drop cum_return
program cum_return
	sort DATE
	while "`1'" ~= "" {
		cap drop ln_r_`1' sum_r_`1' cum_r_`1'
		gen ln_r_`1' = ln(`1' + 1)
		gen sum_r_`1' = sum(ln_r_`1')
		gen cum_r_`1' = exp(sum_r_`1') - 1
		macro shift
	}
end

* Get datasets
use R:\\Research-Projects\StateStreet\Daily_merged_data_20170228

* gen year and month
gen year = year(DATE)
gen month = month(DATE)

* Construct portfolio that moves between stock and bond, with daily rebalance
* If E/P > Bond yield, purchase stock
cap drop bond equity rule
replace VWESX = VWESX/100
gen bond = VWESX
gen equity = r_SPX


* Construct portfolio

sort DATE
gen d_ep = SPXEP[_n-1] - SPXEP[_n-2]
gen d_AAA = AAA[_n-1] - AAA[_n-2]
gen rule = r_SPX
replace rule = VWESX if d_ep < d_AAA

gen p_bond = 1 if d_ep < d_AAA
replace p_bond = 0 if d_ep > d_AAA


* Set date for strategies
by DATE: drop if r_SPX == . | VWESX == . | AAA == .

* Calculate and store start and end date
sort DATE
scalar date_start = DATE[1]
gsort -DATE
scalar date_end = DATE[1]



* Calculate daily returns, standard deviation, annulized std, monthly returns
* monthly std, annual returns, annual std, Sharpe ratios (daily, monthly, annual)

mean_std_daily bond equity rule
monthly_return bond equity rule
annual_return bond equity rule
Sharpe_ratio bond equity rule


* Cumulative Return
cum_return equity bond rule
tsset DATE
tsline cum_r_equity cum_r_bond cum_r_rule

* Plot Graph of the portfolio decision
tsset DATE
tsline p_bond, ytitle("Purchase Bond if value = 1") xtitle("date")
tsline p_bond if tin(1jan2003,31dec2010), ytitle("Purchase Bond if value = 1")xtitle("date")
tsline p_bond if tin(1jan2007,31dec2009), ytitle("Purchase Bond if value = 1")xtitle("date")


* Construct the output matrix to excel
matrix r = (r_avg_d_equity, r_avg_d_bond, r_avg_d_rule ///
 \ r_avg_annual_equity, r_avg_annual_bond, r_avg_annual_rule ///
 \ sd_annualized_equity, sd_annualized_bond, sd_annualized_rule ///
 \ Sharpe_d_equity, Sharpe_d_bond, Sharpe_d_rule  ///
 \ Sharpe_m_equity, Sharpe_m_bond, Sharpe_m_rule ///
 \ Sharpe_annual_equity, Sharpe_annual_bond, Sharpe_annual_rule)
