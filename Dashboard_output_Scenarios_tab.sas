%LET BASEPATH = /sbg/warehouse/risk/creditrisk/dev/data36/Xichen/Chrysler/Data; /*IMPORTANT: Change when copying project to new location - The Base Path (Top Level Path) for the Model Data Directory Structure*/
LIBNAME OUTPUT1 "&BASEPATH./output"; /*Model Output Data*/
%let foredate1 = 201703; /*Defines the Starting PeriodDate for forecasting, should be consistent with previous one 'forecastdate'*/
%LET Num_Scen = 3; 
%LET SCEN_LST= BA,S1,S3;
%LET SCENO_LST= base,s_1,s_3;
%let Num_of_opt = 2;
%let opt_list = 1,2;
%let outputexcel = "&BASEPATH./output/ifrs_output_scenarios.xlsx";

DATA _null_;
	SL="&SCEN_LST.";
	SLO="&SCENO_LST.";
	ARRAY SCN{&Num_Scen.} $2.;
	ARRAY SCNO{&Num_Scen.} $30.;
	* Parse SCEN_LST for Scenario ID (e.g., BL, AD, SA);
	DO i=1 to &Num_Scen.;
		SCN{i} = SCAN(SL, i,',');
		CALL symput(vname(SCN{i}),SCN{i});
	END;
	* Parse SCENO_LST for Sceario Name (e.g., base, s_1, s_3);
	 DO j = 1 TO &Num_Scen.;
 		SCNO{j} = SCAN(SLO,j,',');
		CALL symput(vname(SCNO{j}),SCNO{j});
 	END;
	DROP I J SL SLO;
RUN;
DATA _null_;
	option_list="&opt_list.";
	ARRAY opt_lst{&Num_of_opt.} $2.;
	DO i=1 to &Num_of_opt.;
		opt_lst{i} = SCAN(option_list, i,',');
		CALL symput(vname(opt_lst{i}),opt_lst{i});
	END;
	DROP I option_list;
RUN;

%macro prep_output(Scenario= , option= );
proc sql;
	create table Chrysler_prep_&option._&Scenario. as 
	select portfoliosegmentation_rc			as Portfolio_Segments
		,Staging 							as Staging_Segments
		,total_accounts						as Total_Accounts
		,sum_bom_bal						as BoM_Balance
		,cum_el_&Scenario.					as Cum_Loss_&Scenario.
		,avg_apr							as Average_APR
		,cum_el_&Scenario._pv				as Cum_Loss_PV_&Scenario.
		,sum(total_accounts)				as All_Accounts
		,sum(sum_bom_bal)					as All_BoM_Balance
		,sum(cum_el_&Scenario.)				as All_Cum_Loss
		,sum(cum_el_&Scenario._pv)			as All_Cum_Loss_PV
	from output1.ifrs_summary_sc_&option._&Scenario.
	;
quit;

proc sql;
	create table Chrysler_sum_&option._&Scenario. as 
	select 
		 sum(total_accounts)				as Total_Accounts
		,sum(sum_bom_bal)					as BoM_Balance
		,sum(cum_el_&Scenario.)				as Cum_Loss_&Scenario.
		,sum(cum_el_&Scenario._pv)			as Cum_Loss_PV_&Scenario.
	from output1.ifrs_summary_sc_&option._&Scenario.
	;
quit;

data Chrysler_prep_&option._&Scenario.;
	set Chrysler_prep_&option._&Scenario.;
	percent_accounts = Total_Accounts / All_Accounts;
run;

data Chrysler_&option._&Scenario.(keep=Portfolio_Segments Staging_Segments Total_Accounts percent_accounts BoM_Balance Cum_Loss_&Scenario. Average_APR Cum_Loss_PV_&Scenario.);
	retain Portfolio_Segments Staging_Segments Total_Accounts percent_accounts BoM_Balance Cum_Loss_&Scenario. Average_APR Cum_Loss_PV_&Scenario.;
	set Chrysler_prep_&option._&Scenario.;
run;

proc delete data=Chrysler_sum_&option._&Scenario. Chrysler_prep_&option._&Scenario.;
run;
%mend;

%macro Prep_option(option= );
	%local i;
	%do i = 1 %to %eval(&Num_scen.);
		%prep_output(Scenario = &&scn&i.., option=&option);
	%end;

	data Chrysler_&option.;
		%do i = 1 %to %eval(&Num_scen.);
			set Chrysler_&option._&&scn&i..;
			by Portfolio_Segments Staging_Segments;
		%end;
	run;
%mend;

%macro Prep_finish;
	%local i;
	%do i = 1 %to %eval(&Num_of_opt.);
		%prep_option(option= opt&&opt_lst&i..);
	%end;
%mend;

%Prep_finish;

ods excel file=&outputexcel.
		options(start_at="2,2" 
				embedded_titles="yes"
				sheet_interval='none'
				sheet_name = 'IFRS9-Chrysler');

%macro Cum_Loss_name;
	%do i = 1 %to %eval(&Num_scen.);
		Cum_Loss_&&scn&i
	%end;
%mend;

%macro Cum_Loss_PV_name;
	%do i = 1 %to %eval(&Num_scen.);
		Cum_Loss_PV_&&scn&i
	%end;
%mend;

%macro name_scenarios;
	%do i = 1 %to %eval(&Num_scen.);
		define Cum_Loss_&&scn&i / "&&scno&i.." style={tagattr='format:$#,###'};
		define Cum_Loss_PV_&&scn&i / "&&scno&i.." style={tagattr='format:$#,###'};
	%end;
%mend;

%macro print_option(option= );

proc report data=Chrysler_&option nowd missing split='/';
	title "Owned Chrysler - Option &option. -  Stage 3 - 60+ DPD, Bankrupt, TDR; Stage 2 - 30+ DPD, Step FICO; Stage 1 - Remaining";

	column Portfolio_Segments 
			Staging_Segments 
			Total_Accounts
			percent_accounts
			Average_APR
			BoM_Balance
			("Cum Loss" %Cum_Loss_name)
			("Cum_Loss_PV" %Cum_Loss_PV_name);

	%name_scenarios;
	define Portfolio_Segments /group 'Portfolio/Segments' style={tagattr='Type:String'};
	define Staging_Segments / group  'Staging/Segments' style={tagattr='Type:String'};
	define Total_Accounts / ' Total Accounts' style={tagattr='format:#,###'};
	define percent_accounts / '% of Accounts' style= {tagattr='format:0.0%'};
	define BoM_Balance / "BoM Balance (&foredate1.)" style={tagattr='format:$#,###'};
	define Average_APR / 'Average APR' style= {tagattr='format:0.0%'};

	rbreak after / skip summarize dul;

	compute after Portfolio_Segments;
		Portfolio_Segments='Total:';
	endcomp;

run;

%mend print_option;

%macro Print_finish;
	%local p;
	%do p = 1 %to &Num_of_opt.;
		%Print_option(option= opt&&opt_lst&p..);
	%end;
%mend Print_finish;

%Print_finish;
ods _all_ close; 
