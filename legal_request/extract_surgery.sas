/******

 name of program: legal_20171211.sas
 folder:  \\systm002\rdata\projects\pa_erla\dev\pa_erla_orf\programs\ky_code
 purpose:  extract surgery for oxy pts

*******/
rsubmit;

options obs=max;

** truven data **;
libname original "/rdata/mscan/original";
libname summary "/rdata/mscan/summary_tables/medicare/datasets"; *for summary tables medcare data; 

** oxyctn data;
libname oxy "/rdata/projects/pa_erla/dev/pa_erla_orf/permanent_datasets";

** output files **;
libname perm "/rdata/projects/pa_erla/dev/pa_erla_orf/programs/ky_code/legal_reqest_3e/data/perm";
libname temp "/rdata/projects/pa_erla/dev/pa_erla_orf/programs/ky_code/legal_reqest_3e/data/temp";

*%let year=161;
%macro surgery_outpt(year=);
proc sql;
** outpatient surgery;
create table temp.ccaeo&year. as
select enrolid,
       svcdate,
	   dx1,
	   dx2,
	   dx3,
	   dx4,
	   proc1,
	   procgrp,
	   procmod,
	   proctyp,
	   1 as clmtype
from original.ccaeo&year.
where enrolid in (select distinct enrolid from perm.potentialorf_pts) ;
quit;
/*      and proc1 between "10021" and "69990";*/
%mend;
*%surgery_outpt(year=101);
*%surgery_outpt(year=111);
%surgery_outpt(year=121);
%surgery_outpt(year=131);
%surgery_outpt(year=141);
%surgery_outpt(year=151);
%surgery_outpt(year=161);

%macro surgery_inpt(year=);
** inpatient surgery;
proc sql;
create table temp.ccaes&year. as
select enrolid,
       admdate,
	   disdate,
       svcdate,
	   tsvcdat,
	   dx1,
	   dx2,
	   dx3,
	   dx4,
	   proc1,
	   procmod,
	   proctyp,
	   2 as clmtype
from original.ccaes&year.
where enrolid in (select distinct enrolid from perm.potentialorf_pts) ;
/*      and proc1 between "10021" and "69990";*/
quit;
%mend;

*%surgery_inpt(year=101);
*%surgery_inpt(year=111);
%surgery_inpt(year=121);
%surgery_inpt(year=131);
%surgery_inpt(year=141);
%surgery_inpt(year=151);
%surgery_inpt(year=161);


*** create surgery data set;

data perm.inpt_surgery (keep=enrolid surgdate proc1 surgtype);
set temp.ccaes121
    temp.ccaes131
    temp.ccaes141
    temp.ccaes151
    temp.ccaes161;

if '10021' <=: proc1 <=: '69990';
surgdate = disdate;
surgtype=1;

run;

data perm.outpt_surgery (keep=enrolid surgdate proc1 surgtype);
set temp.ccaeo121
    temp.ccaeo131
    temp.ccaeo141
    temp.ccaeo151
    temp.ccaeo161;

if '10021' <=: proc1 <=: '69990';
surgdate=svcdate;
surgtype=2;

run;


data perm.surgery;
set perm.inpt_surgery
    perm.outpt_surgery;

** remove patient history code;
if substr(proc1,5,1)='F' then delete;
** remove code error;
if proc1='313' then delete;

run;

proc sql;
create table perm.surgery1 as
select distinct *
from perm.surgery;
quit;

** qc the data;
proc freq data=perm.surgery ;
table proc1 / out=temp.ztest noprint;
run;




endrsubmit;
