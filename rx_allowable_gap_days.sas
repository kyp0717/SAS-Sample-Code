


*****************************************************************************;
** Determine period of continuous opiod use where an allowable gap of 
** 30 days after end of prescription is used before a patient is considered to 
** be non persistant or eliminated from the study at that point;
******************************************************************************;

data temp.oic_opd_clms1;
set temp.oic_opd_clms;
by enrolid svcdate;

retain index_date;
format index_date mmddyy10.;
if first.enrolid then index_date=svcdate;

format svcdate mmddyy10.;
* defined three var to be retained after each iteration;
retain total_days_supp x y;
format x mmddyy10.;
** end_dt is fill-date + daysupp; 
end_dt = svcdate + daysupp - 1; 
format end_dt mmddyy10.;
total_days_supp = total_days_supp + daysupp;
lag_end_dt=x;
lag_cum_diff=y;
if first.enrolid then do; 
    total_days_supp = daysupp;
	difference = 0;
	cumulative_diff = 0;
	adjusted_end_dt = end_dt;
    lag_end_dt = end_dt ; 
    lag_cum_diff = difference; 
    end;
else do; 
    ** diff between current fill date and end of previous fill date;
	difference = lag_end_dt - svcdate + 1;
	** If diff less than zero, the fill date was pass the end date;
	if (lag_cum_diff < 0 ) then do;
		cumulative_diff = difference; 
		end;
	else do;
		cumulative_diff = lag_cum_diff + difference;
		end;
    if (cumulative_diff < 0)
       then adjusted_end_dt = end_dt;
       else	adjusted_end_dt = end_dt+cumulative_diff;
	end;
x=end_dt;
y=cumulative_diff;
format lag_end_dt adjusted_end_dt mmddyy10.;
keep enrolid svcdate index_date end_dt p_e_d cumulative_diff adjusted_end_dt;
run;

/** Calculate continuous belsomra use for patient with 
*** allowable 30-day gaps til next fill
***/
data temp.oic_opd_clms2;
set temp.oic_opd_clms1;
retain count_discontinue;
discontinue = 0;
if cumulative_diff < -30 then discontinue = 1; 
by enrolid;
if first.enrolid then count_discontinue = discontinue;
count_discontinue = max (count_discontinue , discontinue);
new_adjusted_end_dt = adjusted_end_dt;
cohort_end_dt = index_date + 550;
if adjusted_end_dt > cohort_end_dt  then new_adjusted_end_dt = cohort_end_dt;
format cohort_end_dt  new_adjusted_end_dt mmddyy10.;
run;

** select only claims records that meets the allowable 30 day gaps ;
data temp.oic_opd_clms3;
set temp.oic_opd_clms2;
if count_discontinue = 0;
run;
