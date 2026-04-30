#!/bin/bash
# ============================================
# 国库集中支付系统 - Oracle 数据库查询脚本
# ============================================
# 用途: 简化数据库查询操作，支持动态连接参数和自动数据修复

# ------------------------------
# 脚本配置
# ------------------------------
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
LAST_CONNECTION_FILE="${SCRIPT_DIR}/.last_connection"

# ------------------------------
# 加载缓存的连接信息
# ------------------------------
load_last_connection() {
    if [ -f "$LAST_CONNECTION_FILE" ]; then
        source "$LAST_CONNECTION_FILE"
        return 0
    else
        return 1
    fi
}

# ------------------------------
# 保存连接信息到缓存
# ------------------------------
save_connection() {
    cat > "$LAST_CONNECTION_FILE" << EOF
# 上次连接信息缓存文件
# 格式: KEY=VALUE
# 此文件会自动更新，请勿手动修改

# 数据库连接参数
DB_HOST=$DB_HOST
DB_PORT=$DB_PORT
DB_SERVICE=$DB_SERVICE
DB_USER=$DB_USER
DB_PASS=$DB_PASS
ORACLE_CONTAINER=$ORACLE_CONTAINER
EOF
    echo "连接信息已保存"
}

# ------------------------------
# 设置连接参数
# ------------------------------
setup_connection() {
    echo "请输入数据库连接信息:"
    
    read -p "数据库主机地址 (默认: 172.16.101.111): " input_host
    DB_HOST="${input_host:-172.16.101.111}"
    
    read -p "Oracle端口 (默认: 1521): " input_port
    DB_PORT="${input_port:-1521}"
    
    read -p "Oracle服务名 (默认: orcl): " input_service
    DB_SERVICE="${input_service:-orcl}"
    
    read -p "数据库用户名: " DB_USER
    if [ -z "$DB_USER" ]; then
        echo "错误: 用户名为必填项"
        return 1
    fi
    
    read -s -p "数据库密码: " DB_PASS
    echo ""
    if [ -z "$DB_PASS" ]; then
        echo "错误: 密码为必填项"
        return 1
    fi
    
    read -p "Docker容器名称 (默认: oracle-21c-local): " input_container
    ORACLE_CONTAINER="${input_container:-oracle-21c-local}"
    
    # 测试连接
    echo ""
    echo "正在测试连接..."
    if execute_sql "SELECT '连接成功' AS STATUS FROM dual"; then
        save_connection
        echo "连接设置成功!"
        show_connection_info
    else
        echo "连接失败，请检查参数"
        return 1
    fi
}

# ------------------------------
# 显示连接信息
# ------------------------------
show_connection_info() {
    echo ""
    echo "当前数据库连接信息:"
    echo "  主机: $DB_HOST"
    echo "  端口: $DB_PORT"
    echo "  服务名: $DB_SERVICE"
    echo "  用户名: $DB_USER"
    echo "  容器: $ORACLE_CONTAINER"
    echo ""
}

# ------------------------------
# 执行 SQL 查询
# ------------------------------
execute_sql() {
    local sql="$1"
    docker exec "$ORACLE_CONTAINER" bash -c "echo \"$sql\" | sqlplus -s \"$DB_USER/$DB_PASS@//$DB_HOST:$DB_PORT/$DB_SERVICE\""
}

# ------------------------------
# 执行更新操作
# ------------------------------
execute_update() {
    local sql="$1"
    execute_sql "$sql"
    execute_sql "COMMIT"
    echo "事务已提交"
}

# ------------------------------
# 测试连接
# ------------------------------
test_connection() {
    execute_sql "SELECT '连接成功' AS STATUS, SYS_CONTEXT('USERENV','DB_NAME') AS DB_NAME, TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') AS CONNECT_TIME FROM dual"
}

# ------------------------------
# 执行自定义 SQL
# ------------------------------
run_custom_sql() {
    local sql="$1"
    
    if [ -z "$sql" ]; then
        echo "用法: $0 sql '<SQL语句>'"
        return 1
    fi
    
    execute_sql "$sql"
}

# ------------------------------
# 执行计数查询
# ------------------------------
run_count_query() {
    local sql="$1"
    
    if [ -z "$sql" ]; then
        echo "用法: $0 count '<SQL语句>'"
        return 1
    fi
    
    execute_sql "$sql"
}

# ------------------------------
# 自动修复查询数据
# ------------------------------
fix_query_data() {
    local sql="$1"
    
    if [ -z "$sql" ]; then
        echo "用法: $0 fix '<SQL语句>'"
        return 1
    fi
    
    echo "正在分析查询语句..."
    
    local table_name=$(echo "$sql" | grep -o -i "from \w\+" | awk '{print $2}' | head -1)
    local ct_result=$(execute_sql "select count(1) AS ct from ($sql) st")
    local ct=$(echo "$ct_result" | grep -E "^[0-9]+$")
    
    echo "当前查询结果: $ct 条记录"
    
    if [ "$ct" -gt 0 ]; then
        echo "查询已有数据，无需修复"
        return 0
    fi
    
    echo "正在尝试修复数据..."
    
    case "$table_name" in
        PB_PAY_VOUCHER)
            fix_pay_voucher "$sql"
            ;;
        PB_REALPAY_BUDGET_VOUCHER)
            fix_realpay_budget_voucher "$sql"
            ;;
        PB_DEMAND_NOTE_VOUCHER)
            fix_demand_note_voucher "$sql"
            ;;
        PB_PAYBACK_VOUCHER)
            fix_payback_voucher "$sql"
            ;;
        *)
            echo "不支持的表类型: $table_name"
            echo "请手动分析查询条件并修改数据"
            ;;
    esac
    
    ct_result=$(execute_sql "select count(1) AS ct from ($sql) st")
    ct=$(echo "$ct_result" | grep -E "^[0-9]+$")
    echo "修复后查询结果: $ct 条记录"
}

# ------------------------------
# 修复支付凭证数据
# ------------------------------
fix_pay_voucher() {
    local sql="$1"
    
    local vt_code=$(echo "$sql" | grep -o -i "vt_code\s*=\s*['\"]\w*['\"]" | sed "s/vt_code\s*=\s*['\"]\([^'\"]*\)['\"]/\1/")
    local admdiv_code=$(echo "$sql" | grep -o -i "admdiv_code\s*=\s*['\"]\w*['\"]" | sed "s/admdiv_code\s*=\s*['\"]\([^'\"]*\)['\"]/\1/")
    local business_type=$(echo "$sql" | grep -o -i "business_type\s*=\s*['\"]*\w*['\"]*" | sed "s/business_type\s*=\s*['\"]*\([^'\"]*\)['\"]*/\1/")
    
    [ -z "$vt_code" ] && vt_code="5214"
    [ -z "$admdiv_code" ] && admdiv_code="511100"
    [ -z "$business_type" ] && business_type="0"
    
    echo "检测到条件: vt_code=$vt_code, admdiv_code=$admdiv_code, business_type=$business_type"
    
    local account_no=$(execute_sql "SELECT account_no FROM pb_ele_account WHERE bank_id = 1672 AND account_type_code = '11' AND admdiv_code = '$admdiv_code' AND ROWNUM = 1" | grep -v "^$")
    
    if [ -z "$account_no" ]; then
        account_no="020000108926"
        echo "未找到有效账户，使用默认账户: $account_no"
    fi
    
    local voucher_id=$((999999999 + RANDOM % 1000))
    
    echo "正在插入测试数据..."
    local insert_sql="INSERT INTO PB_PAY_VOUCHER (PAY_VOUCHER_ID, TOP_ORG_ID, YEAR, IS_ONLYREQ, PAYEE_ACCOUNT_NO, PAY_SUMMARY_NAME, PAY_AMOUNT, PAY_ACCOUNT_NO, ADMDIV_CODE, VT_CODE, BUSINESS_TYPE, CLEAR_FLAG, PAY_REFUND_AMOUNT) VALUES ($voucher_id, 1, 2026, 1, '123456789', '测试摘要1', 1.5, '$account_no', '$admdiv_code', '$vt_code', $business_type, 1, 0)"
    
    execute_sql "$insert_sql"
    execute_sql "COMMIT"
    
    echo "已插入支付凭证: PAY_VOUCHER_ID=$voucher_id"
}

# ------------------------------
# 修复实拨预算凭证数据
# ------------------------------
fix_realpay_budget_voucher() {
    local sql="$1"
    
    local menu_id=$(echo "$sql" | grep -o -i "menu_id\s*=\s*[0-9]*" | sed "s/menu_id\s*=\s*//")
    local business_type=$(echo "$sql" | grep -o -i "business_type\s*<=\s*[0-9]*" | sed "s/business_type\s*<=\s*//")
    
    [ -z "$menu_id" ] && menu_id="94107101"
    [ -z "$business_type" ] && business_type="0"
    
    echo "检测到条件: menu_id=$menu_id, business_type<=$business_type"
    
    local account_no=$(execute_sql "SELECT account_no FROM pb_ele_account WHERE bank_id = 1672 AND account_type_code = '5' AND ROWNUM = 1" | grep -v "^$")
    [ -z "$account_no" ] && account_no="020000272763"
    
    local node_info=$(execute_sql "SELECT PROC_ID, NODE_ID FROM GAP_WF_NODE WHERE MENU_ID = '$menu_id' AND ROWNUM = 1")
    local proc_id=$(echo "$node_info" | grep -E "^[0-9]+" | awk '{print $1}')
    local node_id=$(echo "$node_info" | grep -E "^[0-9]+" | awk '{print $2}')
    
    [ -z "$proc_id" ] && proc_id="801"
    [ -z "$node_id" ] && node_id="9"
    
    local voucher_id=$((888888888 + RANDOM % 1000))
    local task_id=$((777777 + RANDOM % 1000))
    
    echo "正在更新实拨预算凭证..."
    execute_sql "UPDATE PB_REALPAY_BUDGET_VOUCHER SET BUSINESS_TYPE = 0, CLEAR_ACCOUNT_NO = '$account_no', TASK_ID = $task_id WHERE ROWNUM = 1"
    
    if [ $? -eq 0 ]; then
        echo "已更新实拨预算凭证"
    else
        echo "表为空，跳过更新"
    fi
    
    execute_sql "INSERT INTO GAP_WF_TASK (NODETASK_ID, TASK_ID, PROC_ID, NODE_ID, TASK_STATE) VALUES ($task_id, $task_id, $proc_id, $node_id, 2)"
    execute_sql "COMMIT"
    
    echo "已创建工作流任务: TASK_ID=$task_id, PROC_ID=$proc_id, NODE_ID=$node_id"
}

# ------------------------------
# 修复收款凭证数据
# ------------------------------
fix_demand_note_voucher() {
    local sql="$1"
    
    local vt_code=$(echo "$sql" | grep -o -i "vt_code\s*=\s*['\"]\w*['\"]" | sed "s/vt_code\s*=\s*['\"]\([^'\"]*\)['\"]/\1/")
    local business_type=$(echo "$sql" | grep -o -i "business_type\s*=\s*['\"]*\w*['\"]*" | sed "s/business_type\s*=\s*['\"]*\([^'\"]*\)['\"]*/\1/")
    
    [ -z "$vt_code" ] && vt_code="5408"
    [ -z "$business_type" ] && business_type="0"
    
    echo "检测到条件: vt_code=$vt_code, business_type=$business_type"
    
    local account_no=$(execute_sql "SELECT account_no FROM pb_ele_account WHERE bank_id = 1672 AND account_type_code = '5' AND ROWNUM = 1" | grep -v "^$")
    [ -z "$account_no" ] && account_no="020000272763"
    
    local voucher_id=$((777777777 + RANDOM % 1000))
    
    echo "正在插入收款凭证..."
    local insert_sql="INSERT INTO PB_DEMAND_NOTE_VOUCHER (DEMANDNOTE_VOUCHER_ID, VT_CODE, BUSINESS_TYPE, PAY_DBJ_FLAG, CLEAR_ACCOUNT_NO) VALUES ($voucher_id, '$vt_code', $business_type, 0, '$account_no')"
    
    execute_sql "$insert_sql"
    execute_sql "COMMIT"
    
    echo "已插入收款凭证: DEMANDNOTE_VOUCHER_ID=$voucher_id"
}

# ------------------------------
# 修复退款凭证数据
# ------------------------------
fix_payback_voucher() {
    local sql="$1"
    
    local vt_code=$(echo "$sql" | grep -o -i "vt_code\s*=\s*['\"]\w*['\"]" | sed "s/vt_code\s*=\s*['\"]\([^'\"]*\)['\"]/\1/")
    local business_type=$(echo "$sql" | grep -o -i "business_type\s*=\s*['\"]*\w*['\"]*" | sed "s/business_type\s*=\s*['\"]*\([^'\"]*\)['\"]*/\1/")
    
    [ -z "$vt_code" ] && vt_code="5209"
    [ -z "$business_type" ] && business_type="0"
    
    echo "检测到条件: vt_code=$vt_code, business_type=$business_type"
    
    local account_no=$(execute_sql "SELECT account_no FROM pb_ele_account WHERE bank_id = 1672 AND account_type_code = '5' AND ROWNUM = 1" | grep -v "^$")
    [ -z "$account_no" ] && account_no="020000272763"
    
    local voucher_id=$((666666666 + RANDOM % 1000))
    
    echo "正在插入退款凭证..."
    local insert_sql="INSERT INTO PB_PAYBACK_VOUCHER (PAYBACK_VOUCHER_ID, VT_CODE, BUSINESS_TYPE, CLEAR_ACCOUNT_NO) VALUES ($voucher_id, '$vt_code', $business_type, '$account_no')"
    
    execute_sql "$insert_sql"
    execute_sql "COMMIT"
    
    echo "已插入退款凭证: PAYBACK_VOUCHER_ID=$voucher_id"
}

# ------------------------------
# 显示帮助信息
# ------------------------------
show_help() {
    cat << EOF
国库集中支付系统 - Oracle 数据库查询脚本

用法: $0 <命令> [参数]

命令列表:
  help                显示此帮助信息
  setup               设置数据库连接参数（首次使用）
  connect             测试数据库连接
  show                显示当前连接信息
  sql                 执行自定义SQL
                      用法: $0 sql '<SQL语句>'
  count               执行计数查询
                      用法: $0 count '<SQL语句>'
  fix                 自动修复数据使查询有值
                      用法: $0 fix '<SQL查询语句>'

使用流程:
  1. 首次使用: $0 setup
  2. 测试连接: $0 connect
  3. 执行查询: $0 sql 'SELECT * FROM ...'
  4. 自动修复: $0 fix 'SELECT count(1) FROM ...'

示例:
  $0 setup
  $0 connect
  $0 sql 'SELECT COUNT(*) FROM PB_PAY_VOUCHER'
  $0 count 'SELECT COUNT(1) FROM PB_PAY_VOUCHER WHERE ADMDIV_CODE = '\''511100'\''
  $0 fix 'select count(1) AS ct from (select 1 from PB_PAY_VOUCHER where ...) st'

注意:
  - 第一次使用需要运行 setup 设置连接参数
  - 连接参数会自动缓存，后续使用无需重复输入
  - fix 命令会自动分析查询条件并修改数据库使其有值
EOF
}

# ------------------------------
# 主程序
# ------------------------------
main() {
    local cmd="$1"
    local args="$2"
    
    case "$cmd" in
        help)
            show_help
            ;;
        setup)
            setup_connection
            ;;
        connect)
            if ! load_last_connection; then
                echo "错误: 未找到连接信息，请先运行 setup"
                exit 1
            fi
            test_connection
            ;;
        show)
            if ! load_last_connection; then
                echo "错误: 未找到连接信息，请先运行 setup"
                exit 1
            fi
            show_connection_info
            ;;
        sql)
            if ! load_last_connection; then
                echo "错误: 未找到连接信息，请先运行 setup"
                exit 1
            fi
            run_custom_sql "$args"
            ;;
        count)
            if ! load_last_connection; then
                echo "错误: 未找到连接信息，请先运行 setup"
                exit 1
            fi
            run_count_query "$args"
            ;;
        fix)
            if ! load_last_connection; then
                echo "错误: 未找到连接信息，请先运行 setup"
                exit 1
            fi
            fix_query_data "$args"
            ;;
        "")
            show_help
            exit 1
            ;;
        *)
            echo "错误: 未知命令 '$cmd'"
            show_help
            exit 1
            ;;
    esac
}

main "$@"