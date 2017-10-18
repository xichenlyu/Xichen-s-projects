%macro dummy(var= , bins= , num_of_vars= ,num_dummies= , datain= , dataout= , missing= );
/*Assign dummies to variable list "var", using bins of "bin_list", the dummies also contains missing dummy*/

%let var_list = %str(&var);
%let bins = %str(&bins.);
%let num_list = %str(&num_of_dummies.);
%do m = 1 %to %eval(&num_of_vars.);
	%global var_&m bins_&m num_&m;
	%let var_&m = %bquote(%scan(&var_list., &m, %str(|)));
	%let bins_&m = %bquote(%scan(&bins., &m, %str(|)));
	%let num_&m = %sysfunc(inputn(%bquote(%scan(&num_list., &m, %str(|))),informat));

	%let var_tem = &&var_&m;
	data _null_;
		call symput('var_tem',"&var_tem.");
	run;
	%let var_&m = &var_tem;

	%local i output cut_off num_output;
	%let cut_off = %str(&&bins_&m..);
	%do i = 1 %to %eval(&&num_&m..);
		%let output = %bquote(%scan(&cut_off., &i));
		%let num_output = %sysfunc(inputn(&output., informat));
		%global Dummy&m._bin&i.;
		%let Dummy&m._bin&i. = &num_output.;
	%end;
	%put _global_;
%end;


	/*Assign dummies for each bins*/
	data &dataout;
	set &datain;
	%local j i;
	%do m = 1 %to %eval(&num_of_vars.);
		%local var_bin1 var_bin2 var_name;
		%let var_name = &&var_&m;
		%do i = 1 %to %eval(&&num_&m.. -1);
			%let j = %eval(&i.+1);
			%let var_bin1 = &&Dummy&m._bin&i.;
			%let var_bin2 = &&Dummy&m._bin&j.;
			%put _local_;
			%if &i = 1 %then 
				%do;
					if &var_name < &var_bin1. then &var_name._&var_bin1 =1;
					else &var_name._&var_bin1 = 0;
				%end;
			if &var_name >= &var_bin1 and &var_name < &var_bin2
				then &var_name._&var_bin1._&var_bin2 = 1;
			else &var_name._&var_bin1._&var_bin2 = 0;

			%if &missing = 1 %then
				%do;
					if &var_name = . then &var_name._miss = 1;
					else &var_name._miss = 0;
				%end;
		%end;
	%end;
	run;

%mend dummy;

/* Imputs need to be typed in for each variables*/
%let var_list = vehicle_mile|current_ltv; /*Target variable to create dummies*/
%let bin_list = 0 54000 75000 130000|80 100 120 140 160; /*Input cut_offs for variable to create dummies, separated by " "
											For example, you want to create dummies that dummy_0 = 1 when var<0, dummy_0_5 = 1 when 0<=var<5, then bins = 0 5*/
%let num_of_dummies = 4|5; /* Input numbers of dummies which equals to number of cut-offs
							For example, when bins= 0 1 2, num_of_dummies = 3*/
%let datain = LGD_MFA_test_v2; /*Assign dataset which you want the dummies are created at*/
%let dataout = LGD_MFA_test_v3; /*Assign output dataset name with all of the created dummies*/
%let num_of_vars = 2;
%let missing = 1; /*Determine whether to create missing dummy or not, 1 = yes, 0 = no*/
/* Output format of dummies: for example, if bins = 0 1 2, then dummy names= var_0, var_0_1, var_1_2*/
%dummy(var= &var_list, num_of_vars = &num_of_vars, bins= &bin_list, num_dummies= &num_of_dummies, datain = &datain, dataout = &dataout, missing = &missing);
