-- ============================================
-- 收款凭证计数查询模板
-- ============================================
-- 用途: 查询满足条件的收款凭证数量
-- 参数说明:
--   {VOUCHER_TYPE}: 凭证类型代码 (如: 5408)
--   {BANK_ID}: 银行ID (如: 1672)
--   {ACCOUNT_TYPE}: 账户类型代码 (如: 5)

select count(1) AS ct 
from (select 1 
      from PB_DEMAND_NOTE_VOUCHER objsrc_5408 
      where 1=1 
        and pay_dbj_flag <> 1 
        and vt_code = '{VOUCHER_TYPE}' 
        and business_type = 0 
        and clear_account_no in (select account_no 
                                 from pb_ele_account 
                                 where (bank_id = {BANK_ID} 
                                   and account_type_code = '{ACCOUNT_TYPE}'))) st