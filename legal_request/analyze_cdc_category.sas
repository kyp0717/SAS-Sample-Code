rsubmit;

options obs=max;
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


proc sql;
create table perm.potentialorf_diag_CDC as
select distinct 
       a.*,
	   b.indexdate
from perm.potentialorf_diag as a left join 
	 perm.potentialorf_pts as b on a.enrolid=b.enrolid;
quit;

data perm.potentialorf_diag_CDC1 
    (keep=enrolid svcdate dx 
          cdc_infect cdc_neoplasm cdc_endocrine cdc_blood
          cdc_mental cdc_nervous cdc_circular cdc_respiratory cdc_digestive cdc_genitour
          cdc_pregnancy cdc_skin cdc_musculo cdc_congenital cdc_perinatal cdc_illdefined
          cdc_injury_poison cdc_vcode cdc_ecode );
set perm.potentialorf_diag_CDC;

cdc_infect=0;
cdc_neoplasm=0;
cdc_endocrine=0;
cdc_blood=0;
cdc_mental=0;
cdc_nervous=0;
cdc_circular=0;
cdc_respirtory=0;
cdc_digestive=0;
cdc_genitour=0;

cdc_pregnancy=0;
cdc_kin=0;
cdc_musculo=0;
cdc_congenital=0;
cdc_erinatal=0;
cdc_illdefined=0;
cdc_injury_poison=0;
cdc_vcode=0;
cdc_ecode=0;

injury=0;

if '001' <=: dx <=: '139' and 
   (indexdate - 14) ge svcdate le indexdate then cdc_infect=1;
if '140' <=: dx <=: '239' and
   (indexdate - 14) ge svcdate le indexdate then cdc_neoplasm=1;
if '240' <=: dx <=: '279' and
   (indexdate - 14) ge svcdate le indexdate then cdc_endocrine=1;
if '280' <=: dx <=: '289' and
   (indexdate - 14) ge svcdate le indexdate then cdc_blood=1;
if '290' <=: dx <=: '319' and
   (indexdate - 14) ge svcdate le indexdate then cdc_mental=1;
if '320' <=: dx <=: '389' and
   (indexdate - 14) ge svcdate le indexdate then cdc_nervous=1;
if '390' <=: dx <=: '459' and
   (indexdate - 14) ge svcdate le indexdate then cdc_circular=1;
if '460' <=: dx <=: '519' and
   (indexdate - 14) ge svcdate le indexdate then cdc_respiratory=1;
if '520' <=: dx <=: '579' and
   (indexdate - 14) ge svcdate le indexdate then cdc_digestive=1;
if '580' <=: dx <=: '629' and
   (indexdate - 14) ge svcdate le indexdate then cdc_genitour=1;
if '630' <=: dx <=: '679' and
   (indexdate - 14) ge svcdate le indexdate then cdc_pregnancy=1;
if '680' <=: dx <=: '709' and
   (indexdate - 14) ge svcdate le indexdate then cdc_skin=1;
if '710' <=: dx <=: '739' and
   (indexdate - 14) ge svcdate le indexdate then cdc_musculo=1;
if '740' <=: dx <=: '759' and
   (indexdate - 14) ge svcdate le indexdate then cdc_congenital=1;
if '760' <=: dx <=: '779' and
   (indexdate - 14) ge svcdate le indexdate then cdc_perinatal=1;
if '780' <=: dx <=: '799' and
   (indexdate - 14) ge svcdate le indexdate then cdc_illdefined=1;
if '800' <=: dx <=: '999' and
   (indexdate - 14) ge svcdate le indexdate then cdc_injury_poison=1;
if 'V01' <=: dx <=: 'V91' and
   (indexdate - 14) ge svcdate le indexdate then cdc_vcode=1;
if 'E000' <=: dx <=: 'E999' and
   (indexdate - 14) ge svcdate le indexdate then cdc_ecode=1;

/*if ('800' <=: dx <=: '904' OR*/
/*   '920' <=: dx <=: '929' OR*/
/*   '950' <=: dx <=: '959' ) and*/
/*   (indexdate - 14) ge svcdate le indexdate then injury_v2=1;*/

run;

proc sql;
create table perm.potentialorf_pts_CDC2 as
select enrolid,
	   max(cdc_infect) as cdc_infect,
       max(cdc_neoplasm) as cdc_neoplasm,
	   max(cdc_endocrine) as cdc_endocrine,
       max(cdc_blood) as cdc_blood,
	   max(cdc_mental) as cdc_mental,
       max(cdc_nervous) as cdc_nervous,
	   max(cdc_circular) as cdc_circular,
       max(cdc_respiratory) as cdc_respiratory,
	   max(cdc_digestive) as cdc_digestive,
       max(cdc_genitour) as cdc_genitour,
	   max(cdc_pregnancy) as cdc_pregnancy,
       max(cdc_skin) as cdc_skin,
	   max(cdc_musculo) as cdc_musculo,
       max(cdc_congenital) as cdc_congenital,
	   max(cdc_perinatal) as cdc_perinatal,
       max(cdc_illdefined) as cdc_illdefined,
	   max(cdc_injury_poison) as cdc_injury_poison,
       max(cdc_vcode) as cdc_vcode,
	   max(cdc_ecode) as cdc_ecode
from perm.potentialorf_diag_CDC1 
group by enrolid;

create table perm.potentialorf_pts_3e_v2 as
select a.*,
       b.*
from perm.potentialorf_pts_3e as a left join
     perm.potentialorf_pts_CDC2 as b on a.enrolid=b.enrolid;
quit;


endrsubmit;
