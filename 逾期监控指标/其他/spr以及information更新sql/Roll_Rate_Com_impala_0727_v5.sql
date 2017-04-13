SELECT C.no_contract, apply_no,to_date(loan_time)'loan_time',to_date(first_stmt_date)'first_stmt_date',
FLOOR(DATEDIFF(to_date(now()),to_date(loan_time))/30) as 'vintage',
term,loan_code,system,DPD_CURR,MAX_DPD_HIST,TOTAL_REPAY


FROM(
SELECT no_contract,apply_no,term,loan_code,system,
case when max(DPD_CURR) is null then 0 else max(DPD_CURR) END 'DPD_CURR',
case when max(MAX_DPD_HIST) is null then 0 else max(MAX_DPD_HIST) END 'MAX_DPD_HIST', max(TOTAL_REPAY) 'TOTAL_REPAY'


FROM(

SELECT  CONTRACT_NO 'no_contract', cast(cont_loan_apply_no as string) 'apply_no',
        case when FLOOR((DATEDIFF(concat(substr(a.`date`,1,4), '-',substr(a.`date`,5,2),'-',substr(a.`date`,7,2)),to_date(CONTRACT_GENERATE_TIME))-1)/30)<0  then 0 else
         FLOOR((DATEDIFF(concat(substr(a.`date`,1,4), '-',substr(a.`date`,5,2),'-',substr(a.`date`,7,2)),to_date(CONTRACT_GENERATE_TIME))-1)/30) END 'term',
         '1101' as 'loan_code','core' as 'system',
        DPD_CURR,MAX_DPD_HIST, IFNULL(C.TOTAL_REPAY, 0) AS TOTAL_REPAY

from dws_i_core_cont_loan_contract a
LEFT JOIN(
  SELECT CONT_CONTRACT_NO,CUST_PERSON_UNIQUE_ID,
max(case when STATUS = 'V' then DPD else 0 end )'DPD_CURR',max(MAX_DPD) 'MAX_DPD_HIST',`date`
FROM dws_i_core_cont_contract_overdue_info
where CUST_PERSON_UNIQUE_ID != 'a73054af050b43f99f409eb52e3d1ceb'
group by CONT_CONTRACT_NO,CUST_PERSON_UNIQUE_ID,`date`
)b ON a.CONTRACT_NO = b.CONT_CONTRACT_NO AND a.`date` = b.`date`

LEFT JOIN (SELECT CONT_CONTRACT_NO,`date`, SUM(PAID_TOTAL_MONEY) AS TOTAL_REPAY
    FROM dws_i_core_cont_repay_schedule 
    WHERE USABLE = 'YES' AND PAYMENT_STATUS = 'YES'
    GROUP BY 1,2) c ON a.CONTRACT_NO = c.CONT_CONTRACT_NO AND a.`date` = c.`date`

WHERE a.CONTRACT_STATUS IN ('D','F','H','I')
  AND a.CONTRACT_GENERATE_TIME > '2015-09-01'  
  AND a.UNIQUEID NOT IN (SELECT DISTINCT UNIQUEID FROM dws_i_core_cont_loan_contract WHERE PRODUCT_NAME LIKE '测试%')


)A
GROUP BY 1,2,3,4,5

UNION ALL


SELECT no_contract,apply_no,term,loan_code,system,
   max(DPD_CURR) 'DPD_CURR',max(MAX_DPD_HIST) 'MAX_DPD_HIST',max(TOTAL_REPAY) 'TOTAL_REPAY'
   
FROM
(

SELECT 
    c.CONTR_NBR as 'no_contract', CASE WHEN APPLICATION_NO in ("\\\\N","NULL") then NULL else APPLICATION_NO END 'apply_no',
        case when (cast(substr(c.`date`,1,4)as int) - year(FIRST_STMT_DATE))*12+cast(substr(c.`date`,5,2)as int)-month(FIRST_STMT_DATE)+
 cast(cast(substr(c.`date`,7,2) as int) > cast(cycle_day as int) as int) < 0 then 0
  else    (cast(substr(c.`date`,1,4)as int) - year(FIRST_STMT_DATE))*12+cast(substr(c.`date`,5,2)as int)-month(FIRST_STMT_DATE)+
 cast(cast(substr(c.`date`,7,2) as int) > cast(cycle_day as int) as int) END 'term',
 case product_cd
when '000401' then '1101'
when '000402' then '1102'
when '000301' then '2101'
when '000421' then '4101'
when '000423' then '4103'
when '000422' then '4102'
else substr(product_cd,3,6) end 'loan_code','ccs' as 'system',
    case when DATEDIFF(concat(substr(c.`date`,1,4), '-',substr(c.`date`,5,2),'-',substr(c.`date`,7,2)) ,to_date(OVERDUE_DATE)) is null then 0
    else DATEDIFF(concat(substr(c.`date`,1,4), '-',substr(c.`date`,5,2),'-',substr(c.`date`,7,2)) ,to_date(OVERDUE_DATE))-1 END 'DPD_CURR',
  case when MAX_DPD is null then 0 else MAX_DPD END 'MAX_DPD_HIST',

  IFNULL(d.PAID_PRINCIPAL,0) + IFNULL(d.PAID_INTEREST,0) + IFNULL(d.PAID_FEE,0) + IFNULL(d.PAID_LIFE_INSU_AMT,0) + IFNULL(d.PAID_INSURANCE_AMT,0) + IFNULL(d.PAID_PREPAY_PKG_AMT,0) + IFNULL(d.PAID_SVC_FEE,0) + IFNULL(d.PAID_REPLACE_SVC_FEE,0) 'TOTAL_REPAY'

    
FROM dws_i_ccs_ccs_acct c
LEFT JOIN dws_i_ccs_ccs_loan d ON c.acct_nbr =d.acct_nbr AND c.`date` = d.`date`

)B
GROUP BY 1,2,3,4,5)C

LEFT JOIN (
SELECT contract_no,CONTRACT_GENERATE_TIME 'loan_time',date_add(CONTRACT_GENERATE_TIME,30) as 'FIRST_STMT_DATE' 

FROM dws_i_core_cont_loan_contract 

where `date` = CONCAT(substr(to_date(date_sub(now(),1)),1,4),substr(to_date(date_sub(now(),1)),6,2),substr(to_date(date_sub(now(),1)),9,2))

UNION ALL

SELECT A.*,first_stmt_date FROM(
SELECT contr_nbr, create_time 'loan_time' FROM dws_i_ccs_ccs_loan 

where `date` = CONCAT(substr(to_date(date_sub(now(),1)),1,4),substr(to_date(date_sub(now(),1)),6,2),substr(to_date(date_sub(now(),1)),9,2))
)A

left join(
  SELECT contr_nbr, first_stmt_date as 'first_stmt_date' FROM dws_i_ccs_ccs_acct 
where `date` = CONCAT(substr(to_date(date_sub(now(),1)),1,4),substr(to_date(date_sub(now(),1)),6,2),substr(to_date(date_sub(now(),1)),9,2))
)B ON A.contr_nbr = B.contr_nbr
  
 )D ON C.no_contract= D.contract_no
 
 


