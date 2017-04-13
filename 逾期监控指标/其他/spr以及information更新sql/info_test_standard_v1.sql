###Create the temp table for test or standard label###
DROP TABLE if exists data_analysis.zl_application_info_v1;
CREATE TABLE data_analysis.zl_application_info_v1(
   APP_NO VARCHAR(50)  ,
   CONTRACT_NO VARCHAR(50)  ,
   PRODUCT_CD VARCHAR(4) ,
   loan_time date ,
   workflow VARCHAR(10) ,
   test VARCHAR(10) ,
   standard VARCHAR(20) ,
   system VARCHAR(4) 
); 



##老系统
INSERT INTO data_analysis.zl_application_info_v1(APP_NO,CONTRACT_NO,PRODUCT_CD,loan_time,workflow,test,standard,system)
SELECT apply_no,CONTRACT_NO,
    '1101' as 'PRODUCT_CD',
	date(CONTRACT_GENERATE_TIME) as loan_time,
        'risk' as 'workflow',
        'not_test' as 'test',
     'not_standard' as 'standard',
       'core' as 'system'
  
FROM buzi_data_tm.dws_dsst_core_cont_loan_apply a
LEFT JOIN buzi_data_tm.dws_dsst_core_cont_loan_contract b ON a.APPLY_NO = b.CONT_LOAN_APPLY_NO;
#SELECT APP_NO,b.CONTR_NBR FROM buzi_data_tm.dws_dsst_rmps_tm_app_main a
##新系统
INSERT INTO data_analysis.zl_application_info_v1(APP_NO,CONTRACT_NO,PRODUCT_CD,loan_time,workflow,test,standard,system)

SELECT a.APP_NO,CONTR_NBR,a.PRODUCT_CD,date(date_sub(FIRST_STMT_DATE,INTERVAL 30 day ))as loan_time,
case a.workflow_flag       when 'M' then 'risk' 
                           when 'online' then 'risk'
						   when 'luma' then 'risk'
               when 'W' then 'data' 
               when 'data' then 'data'     
                          else 'unknow'  
                          end 'workflow',
        CASE WHEN test = 'test' then 'test' else 'not_test' END 'test',
		CASE WHEN standard ='standard' then 'standard' else 'not_standard' END 'standard',
       'rmps' as 'system'
       
FROM buzi_data_tm.dws_dsst_rmps_tm_app_main a

LEFT JOIN(
SELECT  distinct(NO_APPL) as APP_NO,
    'standard' as 'standard'
FROM buzi_data_tm.dws_dsst_dsc_dca_audit_result 
)b ON a.APP_NO = b.APP_NO

LEFT JOIN(
SELECT  
   distinct(ID_APPL) as APP_NO,
   case ID_RLMD when 'E1F1' then 'test'
   else 'not_test'
     end 'test' 
  FROM buzi_data_tm.dws_dsst_dsc_dwm_approval_resultinf WHERE STTS_APPR <> 'INIT' 
)c ON a.APP_NO = c.APP_NO

LEFT JOIN buzi_data_tm.dws_dsst_ccs_ccs_acct d ON a.APP_NO = d.APPLICATION_NO

##
create index APP_NO on data_analysis.zl_application_info_v1(APP_NO);
create index CONTRACT_NO on data_analysis.zl_application_info_v1(CONTRACT_NO);

