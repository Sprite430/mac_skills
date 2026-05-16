#!/bin/bash
# ============================================
# 国库集中支付系统 - Oracle 数据库操作脚本
# ============================================
# 用途: 执行SQL查询和更新，AI负责分析SQL语义并生成修复语句
# 设计: 脚本只负责执行，AI负责智能决策

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
# 交互式设置连接参数
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
# 执行 SQL（核心函数）
# ------------------------------
execute_sql() {
    local sql="$1"
    docker exec "$ORACLE_CONTAINER" bash -c "echo \"$sql\" | sqlplus -s \"$DB_USER/$DB_PASS@//$DB_HOST:$DB_PORT/$DB_SERVICE\""
}

# ------------------------------
# 执行 SQL 并自动提交
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
# 查询表结构 (DESCRIBE)
# ------------------------------
describe_table() {
    local table_name="$1"
    if [ -z "$table_name" ]; then
        echo "用法: $0 desc <表名>"
        return 1
    fi
    execute_sql "DESCRIBE $table_name"
}

# ------------------------------
# 显示帮助信息
# ------------------------------
show_help() {
    cat << EOF
国库集中支付系统 - Oracle 数据库操作脚本

用法: $0 <命令> [参数]

命令列表:
  help                显示此帮助信息
  setup               设置数据库连接参数（首次使用）
  connect             测试数据库连接
  show                显示当前连接信息
  sql <SQL>           执行SQL语句
  update <SQL>        执行更新SQL并自动提交
  desc <表名>         查看表结构
  count <SQL>         执行计数查询

使用流程:
  1. 首次使用: $0 setup
  2. 测试连接: $0 connect
  3. 执行查询: $0 sql 'SELECT * FROM ...'
  4. 查看结构: $0 desc PB_PAY_VOUCHER
  5. 执行更新: $0 update 'INSERT INTO ...'

注意:
  - 第一次使用需要运行 setup 设置连接参数
  - 连接参数会自动缓存，后续使用无需重复输入
  - 数据修复逻辑由AI分析SQL语义后动态生成
EOF
}

# ------------------------------
# 主程序
# ------------------------------
main() {
    local cmd="$1"
    local args="$2"

    case "$cmd" in
        help|--help|-h)
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
            execute_sql "$args"
            ;;
        update)
            if ! load_last_connection; then
                echo "错误: 未找到连接信息，请先运行 setup"
                exit 1
            fi
            execute_update "$args"
            ;;
        desc)
            if ! load_last_connection; then
                echo "错误: 未找到连接信息，请先运行 setup"
                exit 1
            fi
            describe_table "$args"
            ;;
        count)
            if ! load_last_connection; then
                echo "错误: 未找到连接信息，请先运行 setup"
                exit 1
            fi
            execute_sql "$args"
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
