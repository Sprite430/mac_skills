-- ============================================
-- 实拨预算凭证计数查询模板
-- ============================================
-- 用途: 查询满足条件的实拨预算凭证数量
-- 参数说明:
--   {MENU_ID}: 菜单ID (工作流节点标识)
--   {BANK_ID}: 银行ID (如: 1672)
--   {ACCOUNT_TYPE}: 账户类型代码 (如: 5)

select count(1) AS ct 
from (select 1 
      from PB_REALPAY_BUDGET_VOUCHER objsrc_6815 
      where 1=1 
        and (exists(select 1 
                    from GAP_WF_TASK t_ 
                    where 1=1 
                      and exists(select 1 
                                 from gap_wf_node m_ 
                                 where t_.proc_id=m_.proc_id 
                                   and t_.node_id=m_.node_id 
                                   and m_.menu_id={MENU_ID}) 
                      and t_.task_id=objsrc_6815.task_id 
                      and t_.task_state in (2,4))) 
        and business_type <= 0 
        and is_input = 0 
        and clear_account_no in (select account_no 
                                 from pb_ele_account 
                                 where (bank_id = {BANK_ID} 
                                   and account_type_code = '{ACCOUNT_TYPE}'))) st