
/******

 name of program: legal_20171211.sas
 folder:  \\systm002\rdata\projects\pa_erla\dev\pa_erla_orf\programs\ky_code

*******/

rsubmit;

options obs=max;

proc format;
value grp
1 =  "Sedative"
2 =  "Benzodiazepines"
3 =  "Antihistamines"
4 =  "Tricyclic"
5 =  "Ramelteon"
6 =  "Trazodone"
7 =  "Suvorexant" ;

run;

** macro variables;
** dates;


** truven data **;
libname original "/rdata/mscan/original";
libname summary "/rdata/mscan/summary_tables/medicare/datasets"; *for summary tables medcare data; 

** oxyctn data;
libname oxy "/rdata/projects/pa_erla/dev/pa_erla_orf/permanent_datasets";

** output files **;
libname perm "/rdata/projects/pa_erla/dev/pa_erla_orf/programs/ky_code/legal_reqest_3e/data/perm";
libname temp "/rdata/projects/pa_erla/dev/pa_erla_orf/programs/ky_code/legal_reqest_3e/data/temp";


*****************************************************;
**************  Create Macro Variables **************;
*****************************************************;
/* put all values into macro variable */
proc sql noprint;                              
 select trim(code) into :injury_list1 separated by '|'
 from perm.code_injury
 where code between '800' and '850';

 select trim(code) into :injury_list2 separated by '|'
 from perm.code_injury
 where code between '851' and '900';

 select trim(code) into :injury_list3 separated by '|'
 from perm.code_injury
 where code between '901' and '999';

quit;
 /* display list in SAS log */
%put &injury_list2; 
%put &injury_list1;

*****************************************************;
**************  Analysis of Injury    ***************;
*****************************************************;

** injury code is split up into three lists due to 
   limitation on the SAS string length;
proc sql;
create table temp.injury_pts1 as
select distinct 
       a.enrolid,
	   b.dx,
	   1 as injury
from perm.potentialorf_pts as a join
     perm.potentialorf_diag as b on a.enrolid=b.enrolid
where b.svcdate between (a.indexdate - 14) and a.indexdate and
      prxmatch("/^(&injury_list1.)/", b.dx);

create table temp.injury_pts2 as
select distinct 
       a.enrolid,
	   b.dx,
	   1 as injury
from perm.potentialorf_pts as a join
     perm.potentialorf_diag as b on a.enrolid=b.enrolid
where b.svcdate between (a.indexdate - 14) and a.indexdate and
      prxmatch("/^(&injury_list2.)/", b.dx);

create table temp.injury_pts3 as
select distinct 
       a.enrolid,
	   b.dx,
	   1 as injury
from perm.potentialorf_pts as a join
     perm.potentialorf_diag as b on a.enrolid=b.enrolid
where b.svcdate between (a.indexdate - 14) and a.indexdate and
      prxmatch("/^(&injury_list3)/", b.dx);
quit;
** combine all datasets;
data temp.injury_pts_all;
set temp.injury_pts1
    temp.injury_pts2
    temp.injury_pts3;
run;
** deduplicate;
proc sql;
create table temp.injury_pts_final as
select distinct enrolid, injury from temp.injury_pts_all;
quit;


** qc the data;
proc freq data=temp.injury ;
table dx / out=temp.ztest noprint;
run;

*****************************************************;
**************  Analysis of Surgery   ***************;
*****************************************************;
proc sql;

create table temp.surgery_pts_14 as
select distinct
       a.enrolid,
	   1 as surgery_14
from perm.potentialorf_pts as a join
     perm.surgery as b on a.enrolid=b.enrolid
where b.surgdate between (a.indexdate - 14) and a.indexdate;

create table temp.surgery_pts_21 as
select distinct
       a.enrolid,
	   1 as surgery_21
from perm.potentialorf_pts as a join
     perm.surgery as b on a.enrolid=b.enrolid
where b.surgdate between (a.indexdate - 14) and (a.indexdate + 7);

quit;

*****************************************************;
**************  Analysis of chronic pain   **********;
*****************************************************;
/*proc sql;*/
/*create table temp.chronic_pts as*/
/*select distinct */
/*       a.enrolid,*/
/*	   1 as chronic*/
/*from perm.potentialorf_pts as a join*/
/*     perm.potentialorf_diag as b on a.enrolid=b.enrolid*/
/*where b.svcdate between (a.indexdate - 14) and a.indexdate and*/
/*      prxmatch("/^3382$|^G892|^M255/", b.dx);*/
/*quit;*/
*****************************************************;
**************  Analysis of acute pain  *************;
*****************************************************;
/*proc sql;*/
/*create table temp.acute_pts as*/
/*select distinct */
/*       a.enrolid,*/
/*	   1 as acute*/
/*from perm.potentialorf_pts as a join*/
/*     perm.potentialorf_diag as b on a.enrolid=b.enrolid*/
/*where b.svcdate between (a.indexdate - 14) and a.indexdate and*/
/*      prxmatch("/^3381$|^G8911$|^G8912$|^G8918$|^R52$/", b.dx);*/
/*quit;*/





*****************************************************;
**************  Merge Data to Master  ***************;
*****************************************************;

proc sql;
create table perm.potentialorf_pts_3e as
select distinct
       a.*,
	   b.surgery_14,
	   f.surgery_21,
	   c.injury,
	   d.chronic,
	   e.acute
from perm.potentialorf_pts as a left join
     temp.surgery_pts_14 as b on a.enrolid=b.enrolid left join
     temp.surgery_pts_21 as f on a.enrolid=f.enrolid left join
	 temp.injury_pts_final as c on a.enrolid=c.enrolid left join
	 temp.chronic_pts as d on a.enrolid=d.enrolid left join
	 temp.acute_pts as e on a.enrolid=e.enrolid ;
quit;
** set missing to 0;
data  perm.potentialorf_pts_3e;
set  perm.potentialorf_pts_3e;

if surgery_14=. then surgery_14=0;
if surgery_21=. then surgery_21=0;
if injury=. then injury=0;
if chronic=. then chronic=0;
if acute=. then acute=0;

if surgery_14=1 or injury=1 then injury_surg=1;
else injury_surg=0;
run;

** QC;

proc sql;
select count (distinct enrolid) from perm.potentialorf_pts_3e;
quit;

proc freq data=perm.potentialorf_pts_3e;
table injury*surgery_14;
table injury*surgery_21;
run;



endrsubmit;
