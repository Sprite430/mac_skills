-- ============================================
-- 支付申请计数查询模板
-- ============================================
-- 用途: 查询满足条件的支付申请数量
-- 参数说明:
--   {REGION_CODE}: 行政区划代码 (如: 511100)
--   {VOUCHER_TYPE}: 凭证类型代码
--   {BANK_ID}: 银行ID (如: 1672)
--   {ACCOUNT_TYPE}: 账户类型代码 (如: 11)

select count(1) AS ct 
from (select 1 
      from PB_PAY_REQUEST objsrc_req 
      where 1=1 
        and admdiv_code = '{REGION_CODE}' 
        and vt_code = '{VOUCHER_TYPE}' 
        and business_type = '0' 
        and pay_account_no in (select account_no 
                               from pb_ele_account 
                               where (bank_id = {BANK_ID} 
                                 and account_type_code = '{ACCOUNT_TYPE}' 
                                 and admdiv_code = '{REGION_CODE}'))) st
