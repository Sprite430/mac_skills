-- ============================================
-- 支付凭证计数查询模板
-- ============================================
-- 用途: 查询满足条件的支付凭证数量
-- 参数说明:
--   {REGION_CODE}: 行政区划代码 (如: 511100)
--   {VOUCHER_TYPE}: 凭证类型代码 (如: 2216, 5214, 8210)
--   {BANK_ID}: 银行ID (如: 1672, 1673)
--   {ACCOUNT_TYPE}: 账户类型代码 (如: 11, 12)

select count(1) AS ct 
from (select 1 
      from PB_PAY_VOUCHER objsrc_2742 
      where 1=1 
        and admdiv_code = '{REGION_CODE}' 
        and vt_code = '{VOUCHER_TYPE}' 
        and business_type = '0' 
        and pay_account_no in (select account_no 
                               from pb_ele_account 
                               where (bank_id = {BANK_ID} 
                                 and account_type_code = '{ACCOUNT_TYPE}' 
                                 and admdiv_code = '{REGION_CODE}'))) st