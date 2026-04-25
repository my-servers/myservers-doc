#!/bin/sh

if [ -z "${BASH_VERSION:-}" ]; then
    if command -v bash >/dev/null 2>&1; then
        exec bash "$0" "$@"
    fi
    echo "This installer requires bash. Please install bash and try again." >&2
    exit 1
fi

set -e

RESET='\033[0m'
BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'

print_header() {
    printf '%b\n' "${BLUE}"
    cat << 'EOF'
/$$      /$$            /$$$$$$                                                             
| $$$    /$$$           /$$__  $$                                                            
| $$$$  /$$$$ /$$   /$$| $$  \__/  /$$$$$$   /$$$$$$  /$$    /$$ /$$$$$$   /$$$$$$   /$$$$$$$
| $$ $$/$$ $$| $$  | $$|  $$$$$$  /$$__  $$ /$$__  $$|  $$  /$$//$$__  $$ /$$__  $$ /$$_____/
| $$  $$$| $$| $$  | $$ \____  $$| $$$$$$$$| $$  \__/ \  $$/$$/| $$$$$$$$| $$  \__/|  $$$$$$ 
| $$\  $ | $$| $$  | $$ /$$  \ $$| $$_____/| $$        \  $$$/ | $$_____/| $$       \____  $$
| $$ \/  | $$|  $$$$$$$|  $$$$$$/|  $$$$$$$| $$         \  $/  |  $$$$$$$| $$       /$$$$$$$/
|__/     |__/ \____  $$ \______/  \_______/|__/          \_/    \_______/|__/      |_______/ 
              /$$  | $$                                                                      
             |  $$$$$$/                                                                      
              \______/                                                                       

                            服务端安装向导 v1.0                                            
EOF
    printf '%b\n' "${RESET}"
}

clear_screen() {
    if [ -t 1 ] && [ -n "${TERM:-}" ] && command -v clear >/dev/null 2>&1; then
        clear
    fi
    print_header
}

print_step() {
    printf '%b\n' "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    printf '%b\n' "${BOLD}  $1${RESET}"
    printf '%b\n' "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}\n"
}

print_success() {
    printf '%b\n' "${GREEN}✓${RESET} $1"
}

print_error() {
    printf '%b\n' "${RED}✗${RESET} $1"
}

print_warning() {
    printf '%b\n' "${YELLOW}⚠${RESET} $1"
}

print_info() {
    printf '%b\n' "${BLUE}ℹ${RESET} $1"
}

detect_platform() {
    case "$(uname -s)" in
        Linux*)     echo "linux";;
        Darwin*)    echo "macos";;
        CYGWIN*|MINGW*|MSYS*) echo "windows";;
        *)          echo "unknown";;
    esac
}

check_command() {
    if command -v "$1" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

check_docker() {
    if check_command docker; then
        if docker info &> /dev/null 2>&1; then
            print_success "Docker 已安装并正常运行"
            return 0
        else
            print_warning "Docker 已安装但未运行，请先启动 Docker"
            return 1
        fi
    else
        print_error "Docker 未安装"
        return 1
    fi
}

check_npm() {
    if check_command npm; then
        local version=$(npm --version)
        print_success "npm 已安装 (版本: ${version})"
        return 0
    else
        print_error "npm 未安装"
        return 1
    fi
}

check_node() {
    if check_command node; then
        local version=$(node --version)
        print_success "Node.js 已安装 (版本: ${version})"
        return 0
    else
        print_error "Node.js 未安装"
        return 1
    fi
}

has_docker_socket() {
    [ -S /var/run/docker.sock ]
}

should_map_docker_socket() {
    if ! has_docker_socket; then
        return 1
    fi
    echo ""
    print_info "检测到 Docker Socket: /var/run/docker.sock"
    read -p "  是否映射 Docker Socket 用于 Docker 应用管理? [Y/n]: " map_socket
    map_socket=${map_socket:-Y}
    [[ "$map_socket" =~ ^[Yy]$ ]]
}

SERVER_RUNTIME_ARGS=()

set_server_runtime_args() {
    local secret_key=$1
    local http_port=$2
    SERVER_RUNTIME_ARGS=("-k" "$secret_key")
    if [ -n "$http_port" ]; then
        SERVER_RUNTIME_ARGS+=("-p" "$http_port")
    fi
}

background_run_command() {
    local platform=$1
    local secret_key=$2
    local http_port=$3
    if [ "$platform" = "windows" ]; then
        echo "start \"\" myservers.exe -op=server -k $secret_key -p $http_port"
    else
        echo "node -e \"const { spawn } = require('child_process'); const child = spawn('myservers', ['-op=server','-k','$secret_key','-p','$http_port'], { detached: true, stdio: 'ignore' }); child.unref();\""
    fi
}

show_config_command() {
    local platform=$1
    local secret_key=$2
    local http_port=$3
    if [ "$platform" = "windows" ]; then
        echo "myservers.exe -op=show_config -k $secret_key -p $http_port"
    else
        echo "myservers -op=show_config -k $secret_key -p $http_port"
    fi
}

get_default_data_dir() {
    local platform=$(detect_platform)
    if [ "$platform" = "windows" ]; then
        echo "$USERPROFILE/.myservers"
    else
        echo "$HOME/.myservers"
    fi
}

generate_secret_key() {
    if command -v openssl &> /dev/null; then
        openssl rand -hex 16
    else
        echo "e8edf0cd4c5d49694c39edf7a879a92e"
    fi
}

validate_secret_key() {
    local key=$1
    if [ ${#key} -ne 32 ]; then
        print_error "密钥长度必须为32位，当前: ${#key}位"
        return 1
    fi
    if ! [[ "$key" =~ ^[a-fA-F0-9]+$ ]]; then
        print_error "密钥必须是32位十六进制字符 (0-9, a-f, A-F)"
        return 1
    fi
    return 0
}

read_config_http_port() {
    local config_file=$1
    if [ ! -f "$config_file" ]; then
        return 0
    fi
    grep -oE '^Port:[[:space:]]+[0-9]+' "$config_file" 2>/dev/null | head -1 | awk '{print $2}' || true
}

load_existing_config() {
    local data_dir=$1
    local config_file="$data_dir/config/config.yaml"
    
    if [ -f "$config_file" ]; then
        # 读取现有配置
        local existing_port=$(read_config_http_port "$config_file")
        local existing_key=$(grep -oE 'SecretKey:[[:space:]]+[a-fA-F0-9]+' "$config_file" 2>/dev/null | awk '{print $2}' || echo "")

        if [ -n "$existing_port" ] || [ -n "$existing_key" ]; then
            echo ""
            print_warning "检测到已存在的配置文件: $config_file"
            echo ""
            
            echo "  现有配置:"
            [ -n "$existing_port" ] && echo "    - 端口: $existing_port"
            [ -n "$existing_key" ] && echo "    - 密钥: ${existing_key:0:16}..."
            echo ""
            
            read -p "  是否使用已有配置? [Y/n]: " use_existing
            use_existing=${use_existing:-Y}
            
            if [[ "$use_existing" =~ ^[Yy]$ ]]; then
                if [ -n "$existing_port" ]; then
                    eval "$2=$existing_port"
                fi
                if [ -n "$existing_key" ]; then
                    eval "$3=$existing_key"
                fi
                print_info "将使用已有配置"
                return 0
            else
                print_info "将使用新配置"
                return 1
            fi
        fi
    fi
    return 2
}

wait_for_service() {
    local port=$1
    local max_attempts=10
    local attempt=1

    echo -n "  等待服务启动"
    while [ $attempt -le $max_attempts ]; do
        if curl -s "http://localhost:$port" &>/dev/null; then
            echo ""
            return 0
        fi
        echo -n "."
        sleep 2
    done
    echo ""
    return 1
}

check_process() {
    local platform=$(detect_platform)
    if [ "$platform" = "windows" ]; then
        tasklist 2>/dev/null | grep -i "myservers" > /dev/null
    else
        pgrep -f "myservers" > /dev/null 2>&1
    fi
}

get_process_id() {
    local platform=$1
    if [ "$platform" = "windows" ]; then
        powershell -NoProfile -Command "(Get-Process myservers -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty Id)" 2>/dev/null || true
    else
        pgrep -fo "myservers" 2>/dev/null || true
    fi
}

format_process_id() {
    local pid=$1
    if [ -n "$pid" ]; then
        echo "$pid"
    else
        echo "未知"
    fi
}

shell_join() {
    local out=""
    local part
    for part in "$@"; do
        if [ -n "$out" ]; then
            out="$out "
        fi
        out="${out}$(printf '%q' "$part")"
    done
    echo "$out"
}

docker_run_command() {
    local host_data_dir=$1
    local secret_key=$2
    local http_port=$3
    local map_socket=$4
    local args=(
        docker run -d
        --name myservers
        --network host
        --restart always
        --privileged
        -v /proc:/proc
        -v /var/run:/var/run
    )
    if [ "$map_socket" = "true" ]; then
        args+=(-v /var/run/docker.sock:/var/run/docker.sock)
    fi
    args+=(
        -v "${host_data_dir}:/root/.myservers"
        myservers/my_servers
        ./app
        -k "$secret_key"
    )
    if [ -n "$http_port" ]; then
        args+=(-p "$http_port")
    fi
    shell_join "${args[@]}"
}

docker_show_config_command() {
    echo "docker exec -it myservers myservers -op=show_config"
}

compare_versions() {
    local v1=$1
    local v2=$2
    
    if [ "$v1" = "$v2" ]; then
        echo "equal"
        return
    fi
    
    local IFS='.'
    local v1_arr=($v1)
    local v2_arr=($v2)
    
    for i in 0 1 2; do
        local v1_num=${v1_arr[$i]:-0}
        local v2_num=${v2_arr[$i]:-0}
        
        if [[ $v1_num =~ ^[0-9]+$ ]] && [[ $v2_num =~ ^[0-9]+$ ]]; then
            if [ $v1_num -gt $v2_num ]; then
                echo "newer"
                return
            elif [ $v2_num -gt $v1_num ]; then
                echo "older"
                return
            fi
        fi
    done
    echo "equal"
}

get_current_version_docker() {
    local version=$(docker images myservers/my_servers --format "{{.Tag}}" 2>/dev/null | head -1)
    if [ -n "$version" ]; then
        echo "$version"
    else
        echo "unknown"
    fi
}

get_latest_version_docker() {
    local version=$(docker manifest inspect myservers/my_servers 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    if [ -n "$version" ]; then
        echo "$version"
    else
        echo ""
    fi
}

get_current_version_npm() {
    if check_command myservers; then
        local version=$(myservers -op=version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        if [ -n "$version" ]; then
            echo "$version"
        else
            echo "unknown"
        fi
    else
        echo "not_installed"
    fi
}

get_latest_version_npm() {
    local version=$(npm view @my-servers/myservers version 2>/dev/null)
    if [ -n "$version" ]; then
        echo "$version"
    else
        echo ""
    fi
}

upgrade_docker_impl() {
    print_info "正在拉取最新镜像..."
    if docker pull myservers/my_servers; then
        print_success "镜像拉取成功"
    else
        print_error "镜像拉取失败，请检查网络连接"
        return 1
    fi
    
    local data_dir=$(get_default_data_dir)
    
    print_info "停止旧容器..."
    docker rm -f myservers 2>/dev/null || true
    
    print_info "启动新容器..."
    
    local secret_key=""
    if [ -f "$data_dir/config/config.yaml" ]; then
        secret_key=$(grep -oE 'SecretKey:[[:space:]]+[a-fA-F0-9]+' "$data_dir/config/config.yaml" 2>/dev/null | awk '{print $2}' || echo "")
    fi
    
    if [ -z "$secret_key" ]; then
        print_warning "未找到配置文件中的密钥，请手动重启容器"
        echo ""
        echo "  参考命令:"
        echo "    docker run -d --name myservers --network host --restart always \\"
        echo "      --privileged -v ~/.myservers/data:/app/data \\"
        echo "      -v ~/.myservers/config:/app/config \\"
        echo "      myservers/my_servers ./app -k 你的密钥"
        echo ""
        return 0
    fi
    
    local docker_sock_args=()
    if has_docker_socket; then
        docker_sock_args+=("-v" "/var/run/docker.sock:/var/run/docker.sock")
        print_info "检测到 Docker Socket，已映射到容器内"
    fi

    docker run -d \
        --name myservers \
        --network host \
        --restart always \
        --privileged \
        -v /proc:/proc \
        -v /var/run:/var/run \
        -v "$data_dir/data:/app/data" \
        -v "$data_dir/config:/app/config" \
        "${docker_sock_args[@]}" \
        myservers/my_servers \
        ./app -k "$secret_key"
    
    print_success "Docker 升级完成!"
    echo ""
    echo "  新版本: $(get_current_version_docker)"
    echo ""
    echo "  配置文件已保留在: $data_dir/config/config.yaml"
    echo ""
    read -p "  按回车返回..."
}

upgrade_npm_impl() {
    print_info "正在升级 npm 包..."
    if npm install -g @my-servers/myservers; then
        print_success "升级成功"
    else
        print_error "升级失败"
        return 1
    fi
    
    print_success "npm 升级完成!"
    echo ""
    echo "  新版本: $(get_current_version_npm)"
    echo ""
    echo "  配置文件已保留在: ~/.myservers/config/config.yaml"
    echo ""
    read -p "  按回车返回..."
}

check_upgrade() {
    clear_screen
    print_step "检查更新"
    
    printf '%b\n' "${BOLD}请选择要检查的方式:${RESET}"
    echo ""
    
    local has_docker=false
    local has_npm=false
    
    if check_command docker && docker info &>/dev/null 2>&1; then
        has_docker=true
    fi
    
    if check_command npm && check_command myservers; then
        has_npm=true
    fi
    
    echo "  [1] Docker"
    if $has_docker; then
        echo "      - 已安装 Docker"
    else
        echo "      - 未检测到 Docker"
    fi
    echo ""
    
    echo "  [2] npm"
    if $has_npm; then
        echo "      - 已安装 npm 包"
    else
        echo "      - 未检测到 npm 安装"
    fi
    echo ""
    
    echo "  [3] 检查全部"
    echo ""
    
    echo "  [4] 返回"
    echo ""
    
    read -p "  请输入选项 [1-4]: " choice
    
    case $choice in
        1)
            if $has_docker; then
                check_upgrade_docker
            else
                print_error "Docker 不可用"
                echo ""
                read -p "  按回车返回..."
            fi
            ;;
        2)
            if $has_npm; then
                check_upgrade_npm
            else
                print_error "npm 不可用"
                echo ""
                read -p "  按回车返回..."
            fi
            ;;
        3)
            check_upgrade_all
            ;;
        4|*)
            return 0
            ;;
    esac
}

check_upgrade_docker() {
    clear_screen
    print_step "Docker 检查更新"
    
    if ! check_command docker || ! docker info &>/dev/null 2>&1; then
        print_error "Docker 不可用"
        return 1
    fi
    
    local current=$(get_current_version_docker)
    local latest=$(get_latest_version_docker)
    
    echo "  当前版本: $current"
    echo "  最新版本: $latest"
    echo ""
    
    if [ "$latest" = "" ]; then
        print_error "无法获取最新版本，请检查网络连接"
        echo ""
        read -p "  按回车返回..."
        return 1
    fi
    
    if [ "$current" = "unknown" ]; then
        print_warning "未检测到已安装的镜像"
        echo ""
        read -p "  按回车返回..."
        return 1
    fi
    
    local result=$(compare_versions "$current" "$latest")
    
    if [ "$result" = "equal" ]; then
        print_success "当前已是最新版本 ($current)"
        echo ""
        read -p "  按回车返回..."
        return 0
    elif [ "$result" = "older" ]; then
        print_warning "发现新版本: $current → $latest"
    else
        print_error "版本比较失败"
        echo ""
        read -p "  按回车返回..."
        return 1
    fi
    
    echo ""
    read -p "  确认升级? [Y/n]: " confirm
    confirm=${confirm:-Y}
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "  升级已取消"
        return 1
    fi
    
    upgrade_docker_impl
}

check_upgrade_npm() {
    clear_screen
    print_step "npm 检查更新"
    
    if ! check_command npm || ! check_command myservers; then
        print_error "npm 不可用"
        return 1
    fi
    
    local current=$(get_current_version_npm)
    local latest=$(get_latest_version_npm)
    
    echo "  当前版本: $current"
    echo "  最新版本: $latest"
    echo ""
    
    if [ "$current" = "not_installed" ]; then
        print_error "未检测到 npm 安装，请先安装"
        echo ""
        read -p "  按回车返回..."
        return 1
    fi
    
    if [ "$latest" = "" ]; then
        print_error "无法获取最新版本，请检查网络连接"
        echo ""
        read -p "  按回车返回..."
        return 1
    fi
    
    local result=$(compare_versions "$current" "$latest")
    
    if [ "$result" = "equal" ]; then
        print_success "当前已是最新版本 ($current)"
        echo ""
        read -p "  按回车返回..."
        return 0
    elif [ "$result" = "older" ]; then
        print_warning "发现新版本: $current → $latest"
    else
        print_error "版本比较失败"
        echo ""
        read -p "  按回车返回..."
        return 1
    fi
    
    echo ""
    read -p "  确认升级? [Y/n]: " confirm
    confirm=${confirm:-Y}
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "  升级已取消"
        return 1
    fi
    
    upgrade_npm_impl
}

check_upgrade_all() {
    clear_screen
    print_step "检查全部"
    
    local upgrade_needed=false
    local has_docker=false
    local has_npm=false
    
    if check_command docker && docker info &>/dev/null 2>&1; then
        has_docker=true
        printf '%b\n' "${BOLD}Docker:${RESET}"
        
        local current=$(get_current_version_docker)
        local latest=$(get_latest_version_docker)
        
        echo "  当前: $current → 最新: $latest"
        
        if [ "$latest" != "" ] && [ "$current" != "unknown" ]; then
            local result=$(compare_versions "$current" "$latest")
            if [ "$result" = "older" ]; then
                printf '%b\n' "  ${YELLOW}✓ 有新版本${RESET}"
                upgrade_needed=true
            else
                printf '%b\n' "  ${GREEN}✓ 已是最新${RESET}"
            fi
        elif [ "$current" = "unknown" ]; then
            printf '%b\n' "  ${YELLOW}⚠ 未安装${RESET}"
        fi
        echo ""
    fi
    
    if check_command npm && check_command myservers; then
        has_npm=true
        printf '%b\n' "${BOLD}npm:${RESET}"
        
        local current=$(get_current_version_npm)
        local latest=$(get_latest_version_npm)
        
        echo "  当前: $current → 最新: $latest"
        
        if [ "$latest" != "" ] && [ "$current" != "unknown" ]; then
            local result=$(compare_versions "$current" "$latest")
            if [ "$result" = "older" ]; then
                printf '%b\n' "  ${YELLOW}✓ 有新版本${RESET}"
                upgrade_needed=true
            else
                printf '%b\n' "  ${GREEN}✓ 已是最新${RESET}"
            fi
        fi
        echo ""
    fi
    
    if ! $has_docker && ! $has_npm; then
        print_warning "未检测到任何安装方式"
        echo ""
        read -p "  按回车返回..."
        return 0
    fi
    
    if $upgrade_needed; then
        echo ""
        printf '%b\n' "${BOLD}请选择要升级的方式:${RESET}"
        echo ""
        
        local count=0
        
        if $has_docker; then
            count=$((count + 1))
            echo "  [$count] Docker 升级"
        fi
        
        if $has_npm; then
            count=$((count + 1))
            echo "  [$count] npm 升级"
        fi
        
        count=$((count + 1))
        echo "  [$count] 返回"
        echo ""
        
        read -p "  请输入选项: " choice
        
        local idx=1
        if $has_docker && [ "$choice" = "1" ]; then
            check_upgrade_docker
        else
            idx=$((has_docker ? idx + 1 : idx))
            if $has_npm && [ "$choice" = "$idx" ]; then
                check_upgrade_npm
            fi
        fi
    else
        echo ""
        read -p "  按回车返回..."
    fi
}

install_docker() {
    clear_screen
    print_step "Docker 安装"

    local platform=$(detect_platform)
    if [ "$platform" != "linux" ]; then
        print_error "Docker 安装向导当前仅支持 Linux。"
        echo ""
        echo "  原因: 当前 Docker 安装方案依赖 --network host 和 Linux 路径挂载。"
        echo "  在 $platform 上请优先使用 npm 安装。"
        echo ""
        read -p "  按回车返回..."
        return 1
    fi

    local default_home_dir="$HOME/.myservers"
    local config_file="$default_home_dir/config/config.yaml"
    
    # 尝试读取已有配置
    local default_port="18612"
    local default_key=""
    
    if [ -f "$config_file" ]; then
        local existing_port=""
        local existing_key=""

        existing_port=$(read_config_http_port "$config_file")
        existing_key=$(grep -oE 'SecretKey:[[:space:]]+[a-fA-F0-9]+' "$config_file" 2>/dev/null | head -1 | awk '{print $2}' || echo "")

        if [ -n "$existing_port" ] || [ -n "$existing_key" ]; then
            echo ""
            print_warning "检测到已存在的配置文件"
            echo ""
            
            echo "  现有配置:"
            [ -n "$existing_port" ] && echo "    - 端口: $existing_port"
            [ -n "$existing_key" ] && echo "    - 密钥: ${existing_key:0:16}..."
            echo ""
            
            read -p "  是否使用已有配置? [Y/n]: " use_existing
            use_existing=${use_existing:-Y}
            
            if [[ "$use_existing" =~ ^[Yy]$ ]]; then
                default_port="${existing_port:-18612}"
                default_key="$existing_key"
                print_info "将使用已有配置"
            else
                default_key=$(generate_secret_key)
                print_info "将使用新配置"
            fi
        else
            default_key=$(generate_secret_key)
        fi
    else
        default_key=$(generate_secret_key)
    fi

    local http_port="$default_port"
    local secret_key="$default_key"

    printf '%b\n' "${BOLD}请配置安装参数（直接回车使用默认值）:${RESET}\n"

    echo "  注意: 默认将宿主机 ~/.myservers 挂载到容器内 /root/.myservers"
    echo "        数据会持久化到宿主机"
    echo ""

    read -p "  数据存储目录 (留空使用宿主机 ~/.myservers): " input
    local data_dir="$input"

    read -p "  HTTP 端口 [${http_port}]: " input
    http_port=${input:-$http_port}

    while true; do
        read -p "  密钥 (用于App连接验证) [${secret_key:0:16}...]: " input
        secret_key=${input:-$secret_key}
        if validate_secret_key "$secret_key"; then
            break
        fi
    done

    # 容器内数据目录
    local container_myservers_dir="/root/.myservers"
    local host_data_dir=""
    local map_docker_socket="false"
    
    if should_map_docker_socket; then
        map_docker_socket="true"
        print_info "检测到 Docker Socket，已映射到容器内"
    elif has_docker_socket; then
        print_info "已跳过 Docker Socket 映射，容器内将不提供 Docker 应用管理"
    else
        print_info "未检测到 Docker Socket，容器内将不提供 Docker Socket"
    fi

    # 如果用户指定了自定义目录，则挂载到容器内的 /root/.myservers
    if [ -n "$data_dir" ]; then
        mkdir -p "$data_dir" 2>/dev/null || true
        host_data_dir="$data_dir"
        print_info "使用自定义数据目录: $data_dir"
    else
        # 默认挂载宿主机的 ~/.myservers 到容器的 /root/.myservers
        local default_host_dir="$HOME/.myservers"
        mkdir -p "$default_host_dir" 2>/dev/null || true
        host_data_dir="$default_host_dir"
        print_info "使用数据目录: $default_host_dir"
    fi

    local docker_command=$(docker_run_command "$host_data_dir" "$secret_key" "$http_port" "$map_docker_socket")
    local docker_show_config=$(docker_show_config_command "$host_data_dir" "$secret_key" "$http_port" "$map_docker_socket")

    echo ""
    printf '%b\n' "${BOLD}配置确认:${RESET}"
    echo "  数据目录: $host_data_dir (容器内: $container_myservers_dir)"
    echo "  HTTP 端口: $http_port"
    echo "  密钥: $secret_key"
    echo "  Docker Socket: $([ "$map_docker_socket" = "true" ] && echo 已映射 || echo 未映射)"
    echo ""
    echo "  完整 docker run 命令:"
    echo "    $docker_command"
    echo ""

    read -p "  确认开始安装? [Y/n]: " confirm
    confirm=${confirm:-Y}

    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "  安装已取消"
        return 1
    fi

    print_info "检测 Docker 镜像..."

    if docker images myservers/my_servers &>/dev/null; then
        print_success "镜像已存在"
    else
        print_info "正在拉取镜像..."
        if docker pull myservers/my_servers; then
            print_success "镜像拉取成功"
        else
            print_error "镜像拉取失败，请检查网络连接"
            return 1
        fi
    fi

    print_info "检查并停止旧容器..."
    docker rm -f myservers 2>/dev/null || true

    print_info "启动新容器..."
    eval "$docker_command"

    if wait_for_service "$http_port"; then
        clear_screen
        printf '%b\n' "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        printf '%b\n' "${GREEN}  安装完成!${RESET}"
        printf '%b\n' "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo ""
        if [ -n "$data_dir" ]; then
            echo "  数据目录: $data_dir (容器内: $container_myservers_dir)"
        else
            echo "  数据目录: $HOME/.myservers (容器内: $container_myservers_dir)"
        fi
        echo ""
        echo "  是否立即运行 docker run 获取配置以配对 App?"
        echo "    [1] 立即运行"
        echo "    [2] 稍后自己执行"
        echo ""
        read -p "  请输入选项 [1-2]: " docker_show_config_mode
        case $docker_show_config_mode in
            1)
                eval "$docker_show_config"
                ;;
            2|*)
                echo "  配置引导: $docker_show_config"
                echo "  稍后运行上面的 docker run 命令后，按终端提示去 App 完成配置/配对"
                ;;
        esac
        echo ""
    else
        print_error "服务启动验证失败，请查看日志: docker logs myservers"
        return 1
    fi
}

install_npm() {
    clear_screen
    print_step "npm 安装"

    check_node || return 1
    check_npm || return 1

    local data_dir=$(get_default_data_dir)
    local config_file="$data_dir/config/config.yaml"
    
    # 尝试读取已有配置
    local default_port="18612"
    local default_key=""
    
    if [ -f "$config_file" ]; then
        local existing_port=""
        local existing_key=""

        existing_port=$(read_config_http_port "$config_file")
        existing_key=$(grep -oE 'SecretKey:[[:space:]]+[a-fA-F0-9]+' "$config_file" 2>/dev/null | head -1 | awk '{print $2}' || echo "")

        if [ -n "$existing_port" ] || [ -n "$existing_key" ]; then
            echo ""
            print_warning "检测到已存在的配置文件: $config_file"
            echo ""
            
            echo "  现有配置:"
            [ -n "$existing_port" ] && echo "    - 端口: $existing_port"
            [ -n "$existing_key" ] && echo "    - 密钥: ${existing_key:0:16}..."
            echo ""
            
            read -p "  是否使用已有配置? [Y/n]: " use_existing
            use_existing=${use_existing:-Y}
            
            if [[ "$use_existing" =~ ^[Yy]$ ]]; then
                default_port="${existing_port:-18612}"
                default_key="$existing_key"
                print_info "将使用已有配置"
            else
                default_key=$(generate_secret_key)
                print_info "将使用新配置"
            fi
        else
            default_key=$(generate_secret_key)
        fi
    else
        default_key=$(generate_secret_key)
    fi

    local http_port="$default_port"
    local secret_key="$default_key"

    echo ""
    printf '%b\n' "${BOLD}请配置安装参数（直接回车使用默认值）:${RESET}\n"

    read -p "  HTTP 端口 [${http_port}]: " input
    http_port=${input:-$http_port}

    while true; do
        read -p "  密钥 (用于App连接验证) [${secret_key:0:16}...]: " input
        secret_key=${input:-$secret_key}
        if validate_secret_key "$secret_key"; then
            break
        fi
    done

    set_server_runtime_args "$secret_key" "$http_port"

    echo ""
    print_info "开始安装 npm 包..."
    echo ""

    if npm install -g @my-servers/myservers; then
        print_success "npm 包安装成功"
    else
        print_error "npm 包安装失败"
        return 1
    fi

    clear_screen
    printf '%b\n' "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    printf '%b\n' "${GREEN}  安装完成!${RESET}"
    printf '%b\n' "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
    echo "  安装路径: $(command -v myservers)"
    echo ""

    printf '%b\n' "${BOLD}启动方式:${RESET}"
    echo "  [1] 后台运行 (守护进程)"
    echo "      命令: $(background_run_command "$(detect_platform)" "$secret_key" "$http_port")"
    echo "  [2] 稍后手动启动"
    echo ""

    read -p "  请选择 [1-2]: " run_mode

    case $run_mode in
        1)
            print_info "启动服务 (后台运行)..."
            local platform=$(detect_platform)
            eval "$(background_run_command "$platform" "$secret_key" "$http_port")"
            sleep 2
            if check_process; then
                print_success "服务已在后台运行"
                local pid=$(get_process_id "$platform")
                echo "  进程号: $(format_process_id "$pid")"
                if [ "$platform" = "windows" ]; then
                    echo "  查看日志: type %USERPROFILE%\.myservers\logs\server.log"
                    echo "  停止服务: taskkill /F /IM myservers.exe"
                else
                    echo "  查看日志: tail -f ~/.myservers/logs/server.log"
                    echo "  停止服务: pkill myservers"
                fi
                echo ""
                echo "  是否立即展示配置进行 App 配对?"
                echo "    [1] 立即展示"
                echo "    [2] 稍后自己执行"
                echo ""
                read -p "  请输入选项 [1-2]: " show_config_mode
                case $show_config_mode in
                    1)
                        eval "$(show_config_command "$platform" "$secret_key" "$http_port")"
                        ;;
                    2|*)
                        echo "  配置引导: $(show_config_command "$platform" "$secret_key" "$http_port")"
                        echo "  稍后运行上面的 show_config 命令后，按终端提示去 App 完成配置/配对"
                        ;;
                esac
            else
                print_error "服务启动失败"
            fi
            ;;
        2)
            echo ""
            printf '%b\n' "${BOLD}稍后运行命令:${RESET}"
            local platform=$(detect_platform)
            echo "  后台运行: $(background_run_command "$platform" "$secret_key" "$http_port")"
            echo "  配置引导: $(show_config_command "$platform" "$secret_key" "$http_port")"
            echo "  运行 show_config 命令后，按终端提示去 App 完成配置/配对"
            echo ""
            ;;
        *)
            print_error "无效选项，服务未启动"
            ;;
    esac
}

show_help() {
    clear_screen
    print_step "安装方式说明"

    printf '%b\n' "${BOLD}方式一: npm 安装 (推荐)${RESET}"
    echo "  适合: 已安装或愿意安装 Node.js/npm 的用户"
    echo "  推荐原因: 配置更简单，对 GPU、Docker、进程、磁盘管理更方便"
    echo ""
    echo "  命令:"
    printf '%b\n' "    ${CYAN}npm install -g @my-servers/myservers${RESET}"
    printf '%b\n' "    ${CYAN}myservers -k 你的密钥${RESET}"
    echo ""

    printf '%b\n' "${BOLD}方式二: Docker 安装${RESET}"
    echo "  适合: Linux 上想要快速部署、不想关心依赖的用户"
    echo "  优点: 隔离性好，适合容器化环境"
    echo "  限制: 当前安装向导中的 Docker 方案依赖 Linux 的 host 网络模式"
    echo ""
    echo "  命令:"
    printf '%b\n' "    ${CYAN}docker run -d --name myservers --network host --restart always \\${RESET}"
    printf '%b\n' "    ${CYAN}  --privileged -v ~/.myservers:/root/.myservers \\${RESET}"
    printf '%b\n' "    ${CYAN}  -v /var/run/docker.sock:/var/run/docker.sock \\${RESET}"
    printf '%b\n' "    ${CYAN}  myservers/my_servers ./app -k 你的密钥${RESET}"
    echo ""

    printf '%b\n' "${YELLOW}提示: /pair 页面现在需要先输入 6 位配对码后才会显示二维码；局域网内可直接发现加密配置并本地解密。${RESET}"
    echo ""
}

main() {
    print_header

    printf '%b\n' "${BOLD}欢迎使用 MyServers 服务端安装向导${RESET}"
    echo "  本向导将帮助您完成服务端安装"
    echo ""
    printf '%b\n' "${BLUE}检测到平台: $(detect_platform)${RESET}"
    echo ""

    clear_screen

    print_step "环境检测"

    local has_npm=false
    local has_docker=false

    if check_npm; then
        has_npm=true
    fi
    echo ""

    if check_docker; then
        has_docker=true
    fi
    echo ""

    while true; do
        clear_screen
        print_step "选择安装方式"

        printf '%b\n' "${BOLD}请选择:${RESET}\n"

        if $has_npm; then
            echo "  [1] npm 安装 (推荐)"
            echo "      - 配置更简单，对 GPU、Docker、进程、磁盘管理更方便"
        else
            echo "  [1] npm 安装 (未检测到npm)"
        fi

        if $has_docker && [ "$(detect_platform)" = "linux" ]; then
            echo "  [2] Docker 安装"
        elif $has_docker; then
            echo "  [2] Docker 安装 (当前仅 Linux 支持)"
        else
            echo "  [2] Docker 安装 (未检测到Docker)"
        fi

        echo "  [3] 查看 [1]/[2] 安装方式说明"
        echo "  [4] 检查更新/升级"
        echo "  [5] 退出"
        echo ""

        read -p "  请输入选项 [1-5]: " choice

        case $choice in
            1)
                if $has_npm; then
                    install_npm
                else
                    print_error "npm 不可用，请先安装 Node.js"
                    echo ""
                    echo "  Node.js 安装参考: https://nodejs.org/"
                    echo ""
                    read -p "  按回车继续..."
                fi
                ;;
            2)
                if $has_docker; then
                    install_docker
                else
                    print_error "Docker 不可用，请先安装 Docker"
                    echo ""
                    echo "  Docker 安装参考: https://www.docker.com/get-started"
                    echo ""
                    read -p "  按回车继续..."
                fi
                ;;
            3)
                show_help
                read -p "  按回车返回..."
                ;;
            4)
                check_upgrade
                ;;
            5|q|Q)
                echo ""
                echo "  再见!"
                echo ""
                exit 0
                ;;
            *)
                print_error "无效选项，请重新选择"
                echo ""
                ;;
        esac
    done
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
