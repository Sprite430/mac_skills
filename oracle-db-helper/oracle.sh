#!/bin/bash
# ============================================
# oracle-db-helper — 通用 Oracle 数据库操作脚本
# ============================================
# 依赖: sqlplus (Oracle Instant Client)
# 用法:
#   oracle.sh query <host> <port> <service> <user> <pass> "<SQL>"
#   oracle.sh desc  <host> <port> <service> <user> <pass> "<table>"
#   oracle.sh test  <host> <port> <service> <user> <pass>
# ============================================

set -e

# Oracle 环境
export DYLD_LIBRARY_PATH="/opt/oracle/instantclient_19_16:$DYLD_LIBRARY_PATH"
export PATH="/opt/oracle/instantclient_19_16:$PATH"
export NLS_LANG="AMERICAN_AMERICA.AL32UTF8"

SQLPLUS="/opt/oracle/instantclient_19_16/sqlplus"

# ------------------------------
# 执行 SQL（静默模式，去 Banner）
# ------------------------------
run_sql() {
    local connect_str="$1"
    local sql="$2"
    local mode="${3:-query}"   # query | update | desc

    # @AI-Begin Q7K2P 20260701 Claude
    # 规范化 SQL 尾部：MCP 传入的 SQL 往往不带分号，若直接与 EXIT 换行拼接，
    # sqlplus 会把 EXIT 并入未终结的 SQL 语句，触发 ORA-00933。
    # 处理：去掉尾部空白/换行与已有分号，再统一补一个分号，
    # 保证 SQL 独立终结、EXIT 单独成行。desc 模式是 sqlplus 命令，不做处理。
    local sql_norm="$sql"
    if [ "$mode" = "query" ] || [ "$mode" = "update" ]; then
        # 去除尾部空白与换行
        sql_norm="${sql_norm%"${sql_norm##*[![:space:]]}"}"
        # 去除尾部已有的分号（可能多个），每次去分号后再清一次尾部空白
        while [ "${sql_norm: -1}" = ";" ]; do
            sql_norm="${sql_norm%;}"
            sql_norm="${sql_norm%"${sql_norm##*[![:space:]]}"}"
        done
        sql_norm="${sql_norm};"
    fi
    # @AI-End Q7K2P 20260701 Claude

    local sqlplus_cmd
    case "$mode" in
        query)
            # @AI-Begin Q7K3P 20260701 Claude
            sqlplus_cmd="SET PAGESIZE 50000
SET LINESIZE 2000
SET FEEDBACK OFF
SET HEADING ON
SET TRIMSPOOL ON
SET TRIMOUT ON
SET UNDERLINE OFF
SET COLSEP ' | '
$sql_norm
EXIT;"
            # @AI-End Q7K3P 20260701 Claude
            ;;
        update)
            # @AI-Begin Q7K4P 20260701 Claude
            sqlplus_cmd="SET FEEDBACK ON
SET HEADING OFF
$sql_norm
COMMIT;
EXIT;"
            # @AI-End Q7K4P 20260701 Claude
            ;;
        desc)
            sqlplus_cmd="SET LINESIZE 2000
SET PAGESIZE 50000
SET TRIMSPOOL ON
DESCRIBE $sql
EXIT;"
            ;;
    esac

    echo "$sqlplus_cmd" | "$SQLPLUS" -S "$connect_str" 2>&1
}

# ------------------------------
# 解析连接串
# ------------------------------
parse_connect_string() {
    local host="$1"
    local port="$2"
    local service="$3"
    local user="$4"
    local pass="$5"
    echo "${user}/${pass}@//${host}:${port}/${service}"
}

# ------------------------------
# 主入口
# ------------------------------
main() {
    local action="$1"
    local host="$2"
    local port="$3"
    local service="$4"
    local user="$5"
    local pass="$6"
    shift 6

    local connect_str
    connect_str=$(parse_connect_string "$host" "$port" "$service" "$user" "$pass")

    case "$action" in
        query)
            run_sql "$connect_str" "$*" "query"
            ;;
        update)
            run_sql "$connect_str" "$*" "update"
            ;;
        desc)
            run_sql "$connect_str" "$*" "desc"
            ;;
        test)
            local result
            result=$(echo "SELECT 'OK' AS status, SYSDATE AS db_time FROM DUAL;
EXIT;" | "$SQLPLUS" -S "$connect_str" 2>&1)
            if echo "$result" | grep -q "OK"; then
                echo "$result"
                return 0
            else
                echo "CONNECTION ERROR: $result"
                return 1
            fi
            ;;
        version)
            local result
            result=$(echo "SELECT BANNER FROM V\$VERSION WHERE ROWNUM = 1;
EXIT;" | "$SQLPLUS" -S "$connect_str" 2>&1)
            echo "$result"
            ;;
        tables)
            run_sql "$connect_str" "SELECT TABLE_NAME FROM USER_TABLES ORDER BY TABLE_NAME;" "query"
            ;;
        *)
            echo "用法: oracle.sh <query|desc|update|test|version|tables> <host> <port> <service> <user> <pass> [SQL|表名]"
            exit 1
            ;;
    esac
}

main "$@"
