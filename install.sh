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
LANGUAGE="zh"

t() {
    local key=$1
    case "${LANGUAGE}:${key}" in
        en:installer_title) echo "Server Installer v1.1" ;;
        *:installer_title) echo "服务端安装向导 v1.1" ;;
        en:select_language) echo "Select installer language" ;;
        *:select_language) echo "选择安装语言" ;;
        en:language_choice_prompt) echo "  Enter choice [1-2, default 1]: " ;;
        *:language_choice_prompt) echo "  请输入选项 [1-2，默认1]: " ;;
        en:current_language) echo "Current language" ;;
        *:current_language) echo "当前语言" ;;
        en:language_zh) echo "中文" ;;
        *:language_zh) echo "中文" ;;
        en:language_en) echo "English" ;;
        *:language_en) echo "English" ;;
        en:docker_installed_running) echo "Docker is installed and running" ;;
        *:docker_installed_running) echo "Docker 已安装并正常运行" ;;
        en:docker_installed_not_running) echo "Docker is installed but not running. Please start Docker first." ;;
        *:docker_installed_not_running) echo "Docker 已安装但未运行，请先启动 Docker" ;;
        en:docker_not_installed) echo "Docker is not installed" ;;
        *:docker_not_installed) echo "Docker 未安装" ;;
        en:npm_installed) echo "npm is installed" ;;
        *:npm_installed) echo "npm 已安装" ;;
        en:npm_not_installed) echo "npm is not installed" ;;
        *:npm_not_installed) echo "npm 未安装" ;;
        en:node_installed) echo "Node.js is installed" ;;
        *:node_installed) echo "Node.js 已安装" ;;
        en:node_not_installed) echo "Node.js is not installed" ;;
        *:node_not_installed) echo "Node.js 未安装" ;;
        en:docker_socket_detected) echo "Docker socket detected: /var/run/docker.sock" ;;
        *:docker_socket_detected) echo "检测到 Docker Socket: /var/run/docker.sock" ;;
        en:map_docker_socket_prompt) echo "  Map Docker socket for Docker app management? [Y/n]: " ;;
        *:map_docker_socket_prompt) echo "  是否映射 Docker Socket 用于 Docker 应用管理? [Y/n]: " ;;
        en:secret_length_error) echo "Secret key must be 32 characters long" ;;
        *:secret_length_error) echo "密钥长度必须为32位" ;;
        en:secret_hex_error) echo "Secret key must be a 32-character hexadecimal string (0-9, a-f, A-F)" ;;
        *:secret_hex_error) echo "密钥必须是32位十六进制字符 (0-9, a-f, A-F)" ;;
        en:secret_secure_source_missing) echo "No secure random source was found. Install openssl / python3 / node, or enter a 32-character hexadecimal secret key manually." ;;
        *:secret_secure_source_missing) echo "未找到安全随机源，无法自动生成密钥。请安装 openssl / python3 / node，或手动提供 32 位十六进制密钥。" ;;
        en:secret_fallback_warning) echo "Falling back to hash-based local entropy for secret generation. This is a last resort. Consider installing openssl for stronger randomness." ;;
        *:secret_fallback_warning) echo "正在使用基于本机熵的哈希兜底生成密钥。这只是最后兜底方案，建议安装 openssl 以获得更强随机性。" ;;
        en:docker_permission_mode) echo "Docker permission mode" ;;
        *:docker_permission_mode) echo "Docker 权限模式" ;;
        en:docker_permission_prompt) echo "  Enter choice [1-2, default 1]: " ;;
        *:docker_permission_prompt) echo "  请输入选项 [1-2，默认1]: " ;;
        en:docker_permission_minimal) echo "Minimal permissions (recommended)" ;;
        *:docker_permission_minimal) echo "最小权限（推荐）" ;;
        en:docker_permission_minimal_desc) echo "Port mapping only. Optional docker.sock. Better isolation, but system/process features may be limited." ;;
        *:docker_permission_minimal_desc) echo "仅端口映射，可选 docker.sock。隔离更好，但系统/进程类能力可能受限。" ;;
        en:docker_permission_full) echo "Full management permissions" ;;
        *:docker_permission_full) echo "完整管理权限" ;;
        en:docker_permission_full_desc) echo "Enables privileged mode, host networking on Linux, /proc and /var/run mounts for full monitoring and management features." ;;
        *:docker_permission_full_desc) echo "启用 privileged、Linux host 网络、/proc 和 /var/run 挂载，以获得完整监控和管理能力。" ;;
        en:docker_permission_full_warning) echo "You selected full management permissions. This gives the container elevated host access." ;;
        *:docker_permission_full_warning) echo "你选择了完整管理权限，这会给予容器更高的宿主机访问能力。" ;;
        en:docker_image_source) echo "Choose Docker image source:" ;;
        *:docker_image_source) echo "请选择 Docker 镜像源:" ;;
        en:docker_image_source_prompt) echo "  Enter choice [1-2, default 1]: " ;;
        *:docker_image_source_prompt) echo "  请输入选项 [1-2，默认1]: " ;;
        en:use_existing_config) echo "  Reuse the existing config? [Y/n]: " ;;
        *:use_existing_config) echo "  是否使用已有配置? [Y/n]: " ;;
        en:using_existing_config) echo "Using existing config" ;;
        *:using_existing_config) echo "将使用已有配置" ;;
        en:using_new_config) echo "Generating a new config" ;;
        *:using_new_config) echo "将使用新配置" ;;
        en:docker_install_title) echo "Docker Installation" ;;
        *:docker_install_title) echo "Docker 安装" ;;
        en:npm_install_title) echo "npm Installation" ;;
        *:npm_install_title) echo "npm 安装" ;;
        en:check_updates_title) echo "Check for updates" ;;
        *:check_updates_title) echo "检查更新" ;;
        en:unsupported_platform_docker) echo "Docker install currently supports Linux and macOS only." ;;
        *:unsupported_platform_docker) echo "Docker 安装向导当前仅支持 Linux 和 macOS。" ;;
        en:unsupported_platform_use_npm) echo "Please prefer npm installation on this platform." ;;
        *:unsupported_platform_use_npm) echo "在该平台上请优先使用 npm 安装。" ;;
        en:macos_docker_warning) echo "macOS will use Docker Desktop compatibility mode." ;;
        *:macos_docker_warning) echo "macOS 将使用 Docker Desktop 兼容模式启动。" ;;
        en:config_existing_found) echo "Existing config detected" ;;
        *:config_existing_found) echo "检测到已存在的配置文件" ;;
        en:config_current) echo "Current config:" ;;
        *:config_current) echo "现有配置:" ;;
        en:config_port) echo "Port" ;;
        *:config_port) echo "端口" ;;
        en:config_secret) echo "Secret key" ;;
        *:config_secret) echo "密钥" ;;
        en:configure_install_params) echo "Configure installation parameters (press Enter to use defaults):" ;;
        *:configure_install_params) echo "请配置安装参数（直接回车使用默认值）:" ;;
        en:docker_default_mount_notice_1) echo "Note: by default, host ~/.myservers will be mounted to /root/.myservers in the container." ;;
        *:docker_default_mount_notice_1) echo "注意: 默认将宿主机 ~/.myservers 挂载到容器内 /root/.myservers" ;;
        en:docker_default_mount_notice_2) echo "      Data will persist on the host." ;;
        *:docker_default_mount_notice_2) echo "      数据会持久化到宿主机" ;;
        en:data_dir_prompt) echo "  Data directory (leave empty to use host ~/.myservers): " ;;
        *:data_dir_prompt) echo "  数据存储目录 (留空使用宿主机 ~/.myservers): " ;;
        en:http_port_prompt) echo "  HTTP port" ;;
        *:http_port_prompt) echo "  HTTP 端口" ;;
        en:secret_prompt) echo "  Secret key for App pairing" ;;
        *:secret_prompt) echo "  密钥 (用于App连接验证)" ;;
        en:docker_socket_mapped) echo "Docker socket will be mapped into the container" ;;
        *:docker_socket_mapped) echo "检测到 Docker Socket，已映射到容器内" ;;
        en:docker_socket_skipped) echo "Docker socket mapping skipped. Docker app management will be unavailable in the container." ;;
        *:docker_socket_skipped) echo "已跳过 Docker Socket 映射，容器内将不提供 Docker 应用管理" ;;
        en:docker_socket_missing) echo "Docker socket not found. Docker app management will be unavailable in the container." ;;
        *:docker_socket_missing) echo "未检测到 Docker Socket，容器内将不提供 Docker Socket" ;;
        en:using_custom_data_dir) echo "Using custom data directory" ;;
        *:using_custom_data_dir) echo "使用自定义数据目录" ;;
        en:using_default_data_dir) echo "Using data directory" ;;
        *:using_default_data_dir) echo "使用数据目录" ;;
        en:config_summary) echo "Configuration summary:" ;;
        *:config_summary) echo "配置确认:" ;;
        en:docker_socket_status) echo "Docker socket" ;;
        *:docker_socket_status) echo "Docker Socket" ;;
        en:permission_mode_status) echo "Permission mode" ;;
        *:permission_mode_status) echo "权限模式" ;;
        en:image_source_status) echo "Image source" ;;
        *:image_source_status) echo "镜像源" ;;
        en:docker_full_command) echo "Full docker run command:" ;;
        *:docker_full_command) echo "完整 docker run 命令:" ;;
        en:confirm_install_prompt) echo "  Start installation? [Y/n]: " ;;
        *:confirm_install_prompt) echo "  确认开始安装? [Y/n]: " ;;
        en:install_cancelled) echo "Installation cancelled" ;;
        *:install_cancelled) echo "安装已取消" ;;
        en:checking_docker_image) echo "Checking Docker image..." ;;
        *:checking_docker_image) echo "检测 Docker 镜像..." ;;
        en:image_exists) echo "Image already exists" ;;
        *:image_exists) echo "镜像已存在" ;;
        en:pulling_image) echo "Pulling image..." ;;
        *:pulling_image) echo "正在拉取镜像..." ;;
        en:image_pull_success) echo "Image pull succeeded" ;;
        *:image_pull_success) echo "镜像拉取成功" ;;
        en:image_pull_failed) echo "Image pull failed. Please check your network connection." ;;
        *:image_pull_failed) echo "镜像拉取失败，请检查网络连接" ;;
        en:stopping_old_container) echo "Stopping old container if present..." ;;
        *:stopping_old_container) echo "检查并停止旧容器..." ;;
        en:starting_container) echo "Starting container..." ;;
        *:starting_container) echo "启动新容器..." ;;
        en:install_done) echo "Installation complete!" ;;
        *:install_done) echo "安装完成!" ;;
        en:run_show_config_now) echo "Run show_config now to pair the App?" ;;
        *:run_show_config_now) echo "是否立即运行配置查看命令以配对 App?" ;;
        en:run_now) echo "Run now" ;;
        *:run_now) echo "立即运行" ;;
        en:run_later) echo "Run later" ;;
        *:run_later) echo "稍后自己执行" ;;
        en:choose_1_2) echo "  Enter choice [1-2]: " ;;
        *:choose_1_2) echo "  请输入选项 [1-2]: " ;;
        en:show_config_later_hint) echo "Run the command above later, then follow the terminal prompts in the App to finish pairing." ;;
        *:show_config_later_hint) echo "稍后运行上面的命令后，按终端提示去 App 完成配置/配对" ;;
        en:service_start_verify_failed) echo "Service verification failed. Check logs with: docker logs myservers" ;;
        *:service_start_verify_failed) echo "服务启动验证失败，请查看日志: docker logs myservers" ;;
        en:install_path) echo "Install path" ;;
        *:install_path) echo "安装路径" ;;
        en:start_mode) echo "Startup mode:" ;;
        *:start_mode) echo "启动方式:" ;;
        en:background_run) echo "Run in background (daemon)" ;;
        *:background_run) echo "后台运行 (守护进程)" ;;
        en:start_later) echo "Start later manually" ;;
        *:start_later) echo "稍后手动启动" ;;
        en:start_service_bg) echo "Starting service in the background..." ;;
        *:start_service_bg) echo "启动服务 (后台运行)..." ;;
        en:service_running_bg) echo "Service is running in the background" ;;
        *:service_running_bg) echo "服务已在后台运行" ;;
        en:process_id) echo "Process ID" ;;
        *:process_id) echo "进程号" ;;
        en:view_logs) echo "View logs" ;;
        *:view_logs) echo "查看日志" ;;
        en:stop_service) echo "Stop service" ;;
        *:stop_service) echo "停止服务" ;;
        en:show_config_now) echo "Show config now for App pairing?" ;;
        *:show_config_now) echo "是否立即展示配置进行 App 配对?" ;;
        en:invalid_option_service_not_started) echo "Invalid option. Service was not started." ;;
        *:invalid_option_service_not_started) echo "无效选项，服务未启动" ;;
        en:npm_install_start) echo "Installing npm package..." ;;
        *:npm_install_start) echo "开始安装 npm 包..." ;;
        en:npm_install_success) echo "npm package installed successfully" ;;
        *:npm_install_success) echo "npm 包安装成功" ;;
        en:npm_install_failed) echo "npm package installation failed" ;;
        *:npm_install_failed) echo "npm 包安装失败" ;;
        en:help_title) echo "Installation methods" ;;
        *:help_title) echo "安装方式说明" ;;
        en:method_npm) echo "Method 1: npm install (recommended)" ;;
        *:method_npm) echo "方式一: npm 安装 (推荐)" ;;
        en:method_docker) echo "Method 2: Docker install" ;;
        *:method_docker) echo "方式二: Docker 安装" ;;
        en:main_welcome) echo "Welcome to the MyServers server installer" ;;
        *:main_welcome) echo "欢迎使用 MyServers 服务端安装向导" ;;
        en:main_intro) echo "This wizard will help you install the server." ;;
        *:main_intro) echo "本向导将帮助您完成服务端安装" ;;
        en:platform_detected) echo "Detected platform" ;;
        *:platform_detected) echo "检测到平台" ;;
        en:environment_check) echo "Environment check" ;;
        *:environment_check) echo "环境检测" ;;
        en:waiting_for_service) echo "  Waiting for service to start" ;;
        *:waiting_for_service) echo "  等待服务启动" ;;
        en:unknown) echo "Unknown" ;;
        *:unknown) echo "未知" ;;
        en:docker_hub) echo "Official Docker Hub" ;;
        *:docker_hub) echo "官方 Docker Hub" ;;
        en:docker_hub_default) echo "Official Docker Hub (default)" ;;
        *:docker_hub_default) echo "官方 Docker Hub (默认)" ;;
        en:panel_default) echo "docker.1panel.live (default)" ;;
        *:panel_default) echo "docker.1panel.live (默认)" ;;
        en:upgrade_docker_done) echo "Docker upgrade complete!" ;;
        *:upgrade_docker_done) echo "Docker 升级完成!" ;;
        en:upgrade_npm_start) echo "Upgrading npm package..." ;;
        *:upgrade_npm_start) echo "正在升级 npm 包..." ;;
        en:upgrade_success) echo "Upgrade succeeded" ;;
        *:upgrade_success) echo "升级成功" ;;
        en:upgrade_failed) echo "Upgrade failed" ;;
        *:upgrade_failed) echo "升级失败" ;;
        en:upgrade_npm_done) echo "npm upgrade complete!" ;;
        *:upgrade_npm_done) echo "npm 升级完成!" ;;
        en:new_version) echo "New version" ;;
        *:new_version) echo "新版本" ;;
        en:config_kept_at) echo "Config file kept at" ;;
        *:config_kept_at) echo "配置文件已保留在" ;;
        en:choose_check_method) echo "Choose what to check:" ;;
        *:choose_check_method) echo "请选择要检查的方式:" ;;
        en:installed_docker) echo "Installed Docker" ;;
        *:installed_docker) echo "已安装 Docker" ;;
        en:docker_not_detected) echo "Docker not detected" ;;
        *:docker_not_detected) echo "未检测到 Docker" ;;
        en:installed_npm_package) echo "Installed npm package" ;;
        *:installed_npm_package) echo "已安装 npm 包" ;;
        en:npm_not_detected) echo "npm install not detected" ;;
        *:npm_not_detected) echo "未检测到 npm 安装" ;;
        en:check_all) echo "Check all" ;;
        *:check_all) echo "检查全部" ;;
        en:back) echo "Back" ;;
        *:back) echo "返回" ;;
        en:choose_1_4) echo "  Enter choice [1-4]: " ;;
        *:choose_1_4) echo "  请输入选项 [1-4]: " ;;
        en:choose_1_3) echo "  Enter choice [1-3]: " ;;
        *:choose_1_3) echo "  请输入选项 [1-3]: " ;;
        en:docker_unavailable) echo "Docker is unavailable" ;;
        *:docker_unavailable) echo "Docker 不可用" ;;
        en:npm_unavailable) echo "npm is unavailable" ;;
        *:npm_unavailable) echo "npm 不可用" ;;
        en:docker_check_updates_title) echo "Docker update check" ;;
        *:docker_check_updates_title) echo "Docker 检查更新" ;;
        en:npm_check_updates_title) echo "npm update check" ;;
        *:npm_check_updates_title) echo "npm 检查更新" ;;
        en:current_version) echo "Current version" ;;
        *:current_version) echo "当前版本" ;;
        en:latest_version) echo "Latest version" ;;
        *:latest_version) echo "最新版本" ;;
        en:latest_version_fetch_failed) echo "Unable to fetch the latest version. Please check your network connection." ;;
        *:latest_version_fetch_failed) echo "无法获取最新版本，请检查网络连接" ;;
        en:image_not_installed) echo "Installed image not detected" ;;
        *:image_not_installed) echo "未检测到已安装的镜像" ;;
        en:already_latest) echo "Already up to date" ;;
        *:already_latest) echo "当前已是最新版本" ;;
        en:new_version_found) echo "New version available" ;;
        *:new_version_found) echo "发现新版本" ;;
        en:version_compare_failed) echo "Version comparison failed" ;;
        *:version_compare_failed) echo "版本比较失败" ;;
        en:confirm_upgrade) echo "  Proceed with upgrade? [Y/n]: " ;;
        *:confirm_upgrade) echo "  确认升级? [Y/n]: " ;;
        en:upgrade_cancelled) echo "  Upgrade cancelled" ;;
        *:upgrade_cancelled) echo "  升级已取消" ;;
        en:summary_current_latest) echo "Current" ;;
        *:summary_current_latest) echo "当前" ;;
        en:summary_available) echo "Update available" ;;
        *:summary_available) echo "有新版本" ;;
        en:summary_latest) echo "Up to date" ;;
        *:summary_latest) echo "已是最新" ;;
        en:not_installed) echo "Not installed" ;;
        *:not_installed) echo "未安装" ;;
        en:no_installations_detected) echo "No installation method detected" ;;
        *:no_installations_detected) echo "未检测到任何安装方式" ;;
        en:choose_upgrade_method) echo "Choose what to upgrade:" ;;
        *:choose_upgrade_method) echo "请选择要升级的方式:" ;;
        en:docker_upgrade) echo "Docker upgrade" ;;
        *:docker_upgrade) echo "Docker 升级" ;;
        en:npm_upgrade) echo "npm upgrade" ;;
        *:npm_upgrade) echo "npm 升级" ;;
        en:choose_option) echo "  Enter choice: " ;;
        *:choose_option) echo "  请输入选项: " ;;
        en:macos_note) echo "Notes:" ;;
        *:macos_note) echo "说明:" ;;
        en:macos_note_1) echo "    - Uses port mapping instead of --network host" ;;
        *:macos_note_1) echo "    - 使用端口映射，不使用 --network host" ;;
        en:macos_note_2) echo "    - Does not mount host /proc, so some system metrics will be limited" ;;
        *:macos_note_2) echo "    - 不挂载宿主机 /proc，部分系统信息能力会受限" ;;
        en:macos_note_3) echo "    - npm installation is still recommended; continue with Docker only if you prefer it" ;;
        *:macos_note_3) echo "    - 更推荐 npm 安装；如你希望继续使用 Docker，可直接继续" ;;
        en:data_directory) echo "Data directory" ;;
        *:data_directory) echo "数据目录" ;;
        en:config_hint) echo "Config helper" ;;
        *:config_hint) echo "配置引导" ;;
        en:service_start_failed) echo "Service failed to start" ;;
        *:service_start_failed) echo "服务启动失败" ;;
        en:run_commands_later) echo "Commands to run later:" ;;
        *:run_commands_later) echo "稍后运行命令:" ;;
        en:recommended_for_npm) echo "Best for users who already have or are willing to install Node.js/npm" ;;
        *:recommended_for_npm) echo "适合: 已安装或愿意安装 Node.js/npm 的用户" ;;
        en:recommended_reason_npm) echo "Reason: simpler setup, better compatibility for GPU, Docker, process, and disk management" ;;
        *:recommended_reason_npm) echo "推荐原因: 配置更简单，对 GPU、Docker、进程、磁盘管理更方便" ;;
        en:command_label) echo "Command:" ;;
        *:command_label) echo "命令:" ;;
        en:your_secret_key) echo "your-secret-key" ;;
        *:your_secret_key) echo "你的密钥" ;;
        en:recommended_for_docker) echo "Best for users who want a quick deployment without managing local dependencies" ;;
        *:recommended_for_docker) echo "适合: 想要快速部署、不想关心本机依赖的用户" ;;
        en:docker_advantage) echo "Advantages: isolated runtime, with selectable image source between Docker Hub and docker.1panel.live" ;;
        *:docker_advantage) echo "优点: 隔离性好，支持在安装时选择官方源或 docker.1panel.live 镜像源" ;;
        en:docker_limit) echo "Limitations: Linux uses host networking; macOS falls back to port-mapping compatibility mode" ;;
        *:docker_limit) echo "限制: Linux 使用 host 网络模式；macOS 会自动切到端口映射兼容模式" ;;
        en:docker_hub_example) echo "Docker Hub example:" ;;
        *:docker_hub_example) echo "Docker Hub 示例:" ;;
        en:panel_example) echo "1Panel mirror example:" ;;
        *:panel_example) echo "1Panel 镜像源示例:" ;;
        en:pair_hint) echo "Tip: /pair now asks for the 6-digit pairing code before showing the QR code; LAN discovery can still decrypt config locally." ;;
        *:pair_hint) echo "提示: /pair 页面现在需要先输入 6 位配对码后才会显示二维码；局域网内可直接发现加密配置并本地解密。" ;;
        en:choose_install_method) echo "Choose installation method" ;;
        *:choose_install_method) echo "选择安装方式" ;;
        en:please_choose) echo "Please choose:" ;;
        *:please_choose) echo "请选择:" ;;
        en:npm_install_recommended) echo "npm install (recommended)" ;;
        *:npm_install_recommended) echo "npm 安装 (推荐)" ;;
        en:npm_install_missing) echo "npm install (npm not detected)" ;;
        *:npm_install_missing) echo "npm 安装 (未检测到npm)" ;;
        en:npm_menu_desc) echo "      - Simpler setup, better support for GPU, Docker, process, and disk management" ;;
        *:npm_menu_desc) echo "      - 配置更简单，对 GPU、Docker、进程、磁盘管理更方便" ;;
        en:docker_install_label) echo "Docker install" ;;
        *:docker_install_label) echo "Docker 安装" ;;
        en:docker_install_platform_only) echo "Docker install (Linux/macOS only)" ;;
        *:docker_install_platform_only) echo "Docker 安装 (当前仅 Linux/macOS 支持)" ;;
        en:docker_install_missing) echo "Docker install (Docker not detected)" ;;
        *:docker_install_missing) echo "Docker 安装 (未检测到Docker)" ;;
        en:view_help_menu) echo "View install method help for [1]/[2]" ;;
        *:view_help_menu) echo "查看 [1]/[2] 安装方式说明" ;;
        en:check_upgrade_menu) echo "Check updates / upgrade" ;;
        *:check_upgrade_menu) echo "检查更新/升级" ;;
        en:uninstall_menu) echo "Uninstall" ;;
        *:uninstall_menu) echo "卸载" ;;
        en:switch_language_menu) echo "Switch language" ;;
        *:switch_language_menu) echo "切换语言" ;;
        en:exit_label) echo "Exit" ;;
        *:exit_label) echo "退出" ;;
        en:choose_0_6) echo "  Enter choice [0-6]: " ;;
        *:choose_0_6) echo "  请输入选项 [0-6]: " ;;
        en:npm_missing_install_node) echo "npm is unavailable. Please install Node.js first." ;;
        *:npm_missing_install_node) echo "npm 不可用，请先安装 Node.js" ;;
        en:node_install_ref) echo "  Node.js install guide: https://nodejs.org/" ;;
        *:node_install_ref) echo "  Node.js 安装参考: https://nodejs.org/" ;;
        en:docker_missing_install) echo "Docker is unavailable. Please install Docker first." ;;
        *:docker_missing_install) echo "Docker 不可用，请先安装 Docker" ;;
        en:docker_install_ref) echo "  Docker install guide: https://www.docker.com/get-started" ;;
        *:docker_install_ref) echo "  Docker 安装参考: https://www.docker.com/get-started" ;;
        en:goodbye) echo "  Goodbye!" ;;
        *:goodbye) echo "  再见!" ;;
        en:invalid_option_retry) echo "Invalid option. Please try again." ;;
        *:invalid_option_retry) echo "无效选项，请重新选择" ;;
        en:enter_to_continue) echo "  Press Enter to continue..." ;;
        *:enter_to_continue) echo "  按回车继续..." ;;
        en:enter_to_return) echo "  Press Enter to return..." ;;
        *:enter_to_return) echo "  按回车返回..." ;;
        en:uninstall_title) echo "Uninstall" ;;
        *:uninstall_title) echo "卸载" ;;
        en:choose_uninstall_method) echo "Choose what to uninstall:" ;;
        *:choose_uninstall_method) echo "请选择要卸载的方式:" ;;
        en:docker_uninstall_label) echo "Docker uninstall" ;;
        *:docker_uninstall_label) echo "Docker 卸载" ;;
        en:npm_uninstall_label) echo "npm uninstall" ;;
        *:npm_uninstall_label) echo "npm 卸载" ;;
        en:docker_uninstall_missing) echo "Docker uninstall (not detected)" ;;
        *:docker_uninstall_missing) echo "Docker 卸载 (未检测到)" ;;
        en:npm_uninstall_missing) echo "npm uninstall (not detected)" ;;
        *:npm_uninstall_missing) echo "npm 卸载 (未检测到)" ;;
        en:keep_data_prompt) echo "  Keep ~/.myservers data? [Y/n]: " ;;
        *:keep_data_prompt) echo "  是否保留 ~/.myservers 数据? [Y/n]: " ;;
        en:remove_data_notice) echo "Data removal will delete ~/.myservers permanently." ;;
        *:remove_data_notice) echo "删除数据将永久移除 ~/.myservers 目录。" ;;
        en:data_kept) echo "Data directory was kept" ;;
        *:data_kept) echo "已保留数据目录" ;;
        en:data_removed) echo "Data directory was removed" ;;
        *:data_removed) echo "已删除数据目录" ;;
        en:confirm_uninstall_prompt) echo "  Confirm uninstall? [Y/n]: " ;;
        *:confirm_uninstall_prompt) echo "  确认卸载? [Y/n]: " ;;
        en:stopping_docker_container) echo "Stopping and removing container..." ;;
        *:stopping_docker_container) echo "正在停止并删除容器..." ;;
        en:removing_docker_image) echo "Removing Docker images if present..." ;;
        *:removing_docker_image) echo "正在删除 Docker 镜像（如果存在）..." ;;
        en:docker_uninstall_done) echo "Docker uninstall complete" ;;
        *:docker_uninstall_done) echo "Docker 卸载完成" ;;
        en:docker_install_not_found) echo "Docker installation was not detected." ;;
        *:docker_install_not_found) echo "未检测到 Docker 安装。" ;;
        en:stopping_service_before_uninstall) echo "Stopping running service if present..." ;;
        *:stopping_service_before_uninstall) echo "正在停止运行中的服务（如果存在）..." ;;
        en:npm_uninstall_start) echo "Uninstalling npm package..." ;;
        *:npm_uninstall_start) echo "正在卸载 npm 包..." ;;
        en:npm_uninstall_done) echo "npm uninstall complete" ;;
        *:npm_uninstall_done) echo "npm 卸载完成" ;;
        en:npm_install_not_found) echo "npm installation was not detected." ;;
        *:npm_install_not_found) echo "未检测到 npm 安装。" ;;
        en:uninstall_cancelled) echo "Uninstall cancelled" ;;
        *:uninstall_cancelled) echo "卸载已取消" ;;
        en:language_updated) echo "Language updated" ;;
        *:language_updated) echo "语言已切换" ;;
        en:uninstall_failed) echo "Uninstall failed" ;;
        *:uninstall_failed) echo "卸载失败" ;;
        *) echo "$key" ;;
    esac
}

choose_language() {
    if [ ! -t 0 ]; then
        return 0
    fi

    printf '%s\n' "Select installer language / 选择安装语言"
    printf '%s\n' "  [1] 中文"
    printf '%s\n' "  [2] English"
    printf '\n'
    read -p "  Enter choice [1-2, default 1]: " language_choice
    case "$language_choice" in
        2)
            LANGUAGE="en"
            ;;
        *)
            LANGUAGE="zh"
            ;;
    esac
}

change_language() {
    choose_language
    print_success "$(t language_updated): $(current_language_label)"
}

current_language_label() {
    if [ "$LANGUAGE" = "en" ]; then
        t language_en
    else
        t language_zh
    fi
}

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

EOF
    printf '%b\n' "${BOLD}$(t installer_title)${RESET}"
    printf '%b\n' "${RESET}"
}

prompt_enter_to_continue() {
    read -p "$(t enter_to_continue)" _
}

prompt_enter_to_return() {
    read -p "$(t enter_to_return)" _
}

build_secret_key_fallback_seed() {
    printf '%s|%s|%s|%s|%s|%s|%s\n' \
        "$(date '+%s' 2>/dev/null || echo 0)" \
        "${RANDOM:-0}" \
        "$$" \
        "${PPID:-0}" \
        "$(uname -a 2>/dev/null || echo unknown)" \
        "$(pwd 2>/dev/null || echo .)" \
        "$(id -u 2>/dev/null || echo 0)"
}

generate_secret_key_hash_fallback() {
    local seed=$1

    if command -v md5sum &> /dev/null; then
        printf '%s' "$seed" | md5sum | awk '{print substr($1, 1, 32)}'
        return 0
    fi

    if command -v md5 &> /dev/null; then
        printf '%s' "$seed" | md5 | awk '{print substr($NF, 1, 32)}'
        return 0
    fi

    if command -v sha256sum &> /dev/null; then
        printf '%s' "$seed" | sha256sum | awk '{print substr($1, 1, 32)}'
        return 0
    fi

    if command -v shasum &> /dev/null; then
        printf '%s' "$seed" | shasum -a 256 | awk '{print substr($1, 1, 32)}'
        return 0
    fi

    return 1
}

bool_word() {
    if [ "$1" = "true" ]; then
        if [ "$LANGUAGE" = "en" ]; then
            echo "Enabled"
        else
            echo "已启用"
        fi
    else
        if [ "$LANGUAGE" = "en" ]; then
            echo "Disabled"
        else
            echo "未启用"
        fi
    fi
}

docker_permission_mode_label() {
    if [ "$1" = "full" ]; then
        t docker_permission_full
    else
        t docker_permission_minimal
    fi
}

choose_docker_permission_mode() {
    local default_mode=${1:-minimal}
    local choice=""
    local mode="$default_mode"

    printf '%s\n' "  $(t docker_permission_mode):" >&2
    printf '%s\n' "    [1] $(t docker_permission_minimal)" >&2
    printf '%s\n' "        $(t docker_permission_minimal_desc)" >&2
    printf '%s\n' "    [2] $(t docker_permission_full)" >&2
    printf '%s\n' "        $(t docker_permission_full_desc)" >&2
    printf '\n' >&2
    read -p "$(t docker_permission_prompt)" choice

    case "$choice" in
        2)
            mode="full"
            print_warning "$(t docker_permission_full_warning)" >&2
            ;;
        1)
            mode="minimal"
            ;;
        *)
            mode="$default_mode"
            ;;
    esac

    echo "$mode"
}

detect_existing_docker_permission_mode() {
    local privileged=""
    local network_mode=""

    privileged=$(docker inspect -f '{{.HostConfig.Privileged}}' myservers 2>/dev/null || true)
    network_mode=$(docker inspect -f '{{.HostConfig.NetworkMode}}' myservers 2>/dev/null || true)

    if [ "$privileged" = "true" ] || [ "$network_mode" = "host" ]; then
        echo "full"
    else
        echo "minimal"
    fi
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
            print_success "$(t docker_installed_running)"
            return 0
        else
            print_warning "$(t docker_installed_not_running)"
            return 1
        fi
    else
        print_error "$(t docker_not_installed)"
        return 1
    fi
}

check_npm() {
    if check_command npm; then
        local version=$(npm --version)
        print_success "$(t npm_installed) (version: ${version})"
        return 0
    else
        print_error "$(t npm_not_installed)"
        return 1
    fi
}

check_node() {
    if check_command node; then
        local version=$(node --version)
        print_success "$(t node_installed) (version: ${version})"
        return 0
    else
        print_error "$(t node_not_installed)"
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
    print_info "$(t docker_socket_detected)"
    read -p "$(t map_docker_socket_prompt)" map_socket
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

is_docker_install_detected() {
    if ! check_command docker || ! docker info &>/dev/null 2>&1; then
        return 1
    fi

    if docker inspect myservers >/dev/null 2>&1; then
        return 0
    fi

    if docker images myservers/my_servers --format "{{.Repository}}" 2>/dev/null | head -1 | grep -q .; then
        return 0
    fi

    if docker images docker.1panel.live/myservers/my_servers --format "{{.Repository}}" 2>/dev/null | head -1 | grep -q .; then
        return 0
    fi

    return 1
}

is_npm_install_detected() {
    check_command npm && npm list -g @my-servers/myservers --depth=0 >/dev/null 2>&1
}

maybe_remove_data_dir() {
    local data_dir
    data_dir=$(get_default_data_dir)

    read -p "$(t keep_data_prompt)" keep_data
    keep_data=${keep_data:-Y}

    if [[ "$keep_data" =~ ^[Yy]$ ]]; then
        print_info "$(t data_kept): $data_dir"
        return 0
    fi

    print_warning "$(t remove_data_notice)"
    rm -rf "$data_dir"
    print_success "$(t data_removed): $data_dir"
}

generate_secret_key() {
    if command -v openssl &> /dev/null; then
        openssl rand -hex 16
        return 0
    fi

    if [ -r /dev/urandom ] && command -v od &> /dev/null && command -v tr &> /dev/null; then
        od -An -N16 -tx1 /dev/urandom | tr -d ' \n'
        return 0
    fi

    if command -v python3 &> /dev/null; then
        python3 -c 'import secrets; print(secrets.token_hex(16))'
        return 0
    fi

    if command -v python &> /dev/null; then
        python -c 'import secrets; print(secrets.token_hex(16))'
        return 0
    fi

    if command -v node &> /dev/null; then
        node -e 'process.stdout.write(require("crypto").randomBytes(16).toString("hex"))'
        return 0
    fi

    local fallback_seed=""
    local fallback_key=""
    fallback_seed=$(build_secret_key_fallback_seed)
    if fallback_key=$(generate_secret_key_hash_fallback "$fallback_seed"); then
        print_warning "$(t secret_fallback_warning)" >&2
        printf '%s\n' "$fallback_key"
        return 0
    fi

    print_error "$(t secret_secure_source_missing)"
    return 1
}

validate_secret_key() {
    local key=$1
    if [ ${#key} -ne 32 ]; then
        print_error "$(t secret_length_error), current: ${#key}"
        return 1
    fi
    if ! [[ "$key" =~ ^[a-fA-F0-9]+$ ]]; then
        print_error "$(t secret_hex_error)"
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
        local existing_port=$(read_config_http_port "$config_file")
        local existing_key=$(grep -oE 'SecretKey:[[:space:]]+[a-fA-F0-9]+' "$config_file" 2>/dev/null | awk '{print $2}' || echo "")

        if [ -n "$existing_port" ] || [ -n "$existing_key" ]; then
            echo ""
            print_warning "$(t config_existing_found): $config_file"
            echo ""
            
            echo "  $(t config_current)"
            [ -n "$existing_port" ] && echo "    - $(t config_port): $existing_port"
            [ -n "$existing_key" ] && echo "    - $(t config_secret): ${existing_key:0:16}..."
            echo ""
            
            read -p "$(t use_existing_config)" use_existing
            use_existing=${use_existing:-Y}
            
            if [[ "$use_existing" =~ ^[Yy]$ ]]; then
                if [ -n "$existing_port" ]; then
                    eval "$2=$existing_port"
                fi
                if [ -n "$existing_key" ]; then
                    eval "$3=$existing_key"
                fi
                print_info "$(t using_existing_config)"
                return 0
            else
                print_info "$(t using_new_config)"
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

    echo -n "$(t waiting_for_service)"
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
        echo "$(t unknown)"
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

docker_image_for_source() {
    local source=${1:-official}
    case "$source" in
        1panel)
            echo "docker.1panel.live/myservers/my_servers"
            ;;
        official|*)
            echo "myservers/my_servers"
            ;;
    esac
}

detect_docker_image_source() {
    local current_image=""
    current_image=$(docker inspect -f '{{.Config.Image}}' myservers 2>/dev/null || true)
    case "$current_image" in
        docker.1panel.live/myservers/my_servers*)
            echo "1panel"
            return
            ;;
        myservers/my_servers*)
            echo "official"
            return
            ;;
    esac

    if docker images docker.1panel.live/myservers/my_servers --format "{{.Repository}}" 2>/dev/null | head -1 | grep -q .; then
        echo "1panel"
        return
    fi

    echo "official"
}

choose_docker_image_source() {
    local default_source=${1:-official}
    local source="$default_source"
    printf '%s\n' "  $(t docker_image_source)" >&2
    if [ "$default_source" = "1panel" ]; then
        printf '%s\n' "    [1] $(t docker_hub)" >&2
        printf '%s\n' "    [2] $(t panel_default)" >&2
        printf '\n' >&2
        read -p "$(t docker_image_source_prompt)" source_choice
    else
        printf '%s\n' "    [1] $(t docker_hub_default)" >&2
        printf '%s\n' "    [2] docker.1panel.live" >&2
        printf '\n' >&2
        read -p "$(t docker_image_source_prompt)" source_choice
    fi
    case "$source_choice" in
        2)
            source="1panel"
            ;;
        1)
            source="official"
            ;;
        *)
            source="$default_source"
            ;;
    esac
    echo "$source"
}

docker_run_command() {
    local host_data_dir=$1
    local secret_key=$2
    local http_port=$3
    local map_socket=$4
    local permission_mode=${5:-minimal}
    local platform=${6:-$(detect_platform)}
    local image_ref=${7:-$(docker_image_for_source official)}
    local args=(
        docker run -d
        --name myservers
        --restart always
    )

    if [ "$permission_mode" = "full" ]; then
        args+=(--privileged)
    fi

    if [ "$platform" = "linux" ] && [ "$permission_mode" = "full" ]; then
        args+=(
            --network host
            -v /proc:/proc
            -v /var/run:/var/run
        )
    elif [ -n "$http_port" ]; then
        args+=(-p "${http_port}:${http_port}")
    fi

    if [ "$map_socket" = "true" ]; then
        args+=(-v /var/run/docker.sock:/var/run/docker.sock)
    fi
    args+=(
        -v "${host_data_dir}:/root/.myservers"
        "$image_ref"
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
    local image_ref=${1:-$(docker_image_for_source "$(detect_docker_image_source)")}
    local version=$(docker images "$image_ref" --format "{{.Tag}}" 2>/dev/null | head -1)
    if [ -n "$version" ]; then
        echo "$version"
    else
        echo "unknown"
    fi
}

get_latest_version_docker() {
    local image_ref=${1:-$(docker_image_for_source "$(detect_docker_image_source)")}
    local version=$(docker manifest inspect "$image_ref" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
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
    local image_source
    image_source=$(detect_docker_image_source)
    local image_ref
    image_ref=$(docker_image_for_source "$image_source")
    local permission_mode
    permission_mode=$(detect_existing_docker_permission_mode)

    print_info "$(t pulling_image)"
    if docker pull "$image_ref"; then
        print_success "$(t image_pull_success)"
    else
        print_error "$(t image_pull_failed)"
        return 1
    fi
    
    local data_dir=$(get_default_data_dir)
    local platform=$(detect_platform)
    local http_port="18612"
    
    print_info "$(t stopping_old_container)"
    docker rm -f myservers 2>/dev/null || true
    
    print_info "$(t starting_container)"
    
    local secret_key=""
    if [ -f "$data_dir/config/config.yaml" ]; then
        secret_key=$(grep -oE 'SecretKey:[[:space:]]+[a-fA-F0-9]+' "$data_dir/config/config.yaml" 2>/dev/null | awk '{print $2}' || echo "")
        local existing_port
        existing_port=$(read_config_http_port "$data_dir/config/config.yaml")
        if [ -n "$existing_port" ]; then
            http_port="$existing_port"
        fi
    fi
    
    if [ -z "$secret_key" ]; then
        if [ "$LANGUAGE" = "en" ]; then
            print_warning "Secret key was not found in the config file. Please restart the container manually."
        else
            print_warning "未找到配置文件中的密钥，请手动重启容器"
        fi
        echo ""
        if [ "$LANGUAGE" = "en" ]; then
            echo "  Reference command:"
        else
            echo "  参考命令:"
        fi
        if [ "$platform" = "linux" ]; then
            echo "    docker run -d --name myservers --network host --restart always \\"
            echo "      --privileged -v ~/.myservers:/root/.myservers \\"
            echo "      ${image_ref} ./app -k $(t your_secret_key)"
        else
            echo "    docker run -d --name myservers --restart always \\"
            echo "      --privileged -p ${http_port}:${http_port} -v ~/.myservers:/root/.myservers \\"
            echo "      ${image_ref} ./app -k $(t your_secret_key) -p ${http_port}"
        fi
        echo ""
        return 0
    fi
    
    local docker_sock_args=()
    if has_docker_socket; then
        docker_sock_args+=("-v" "/var/run/docker.sock:/var/run/docker.sock")
        print_info "$(t docker_socket_mapped)"
    fi

    local docker_command
    docker_command=$(docker_run_command "$data_dir" "$secret_key" "$http_port" "$([ ${#docker_sock_args[@]} -gt 0 ] && echo true || echo false)" "$permission_mode" "$platform" "$image_ref")
    eval "$docker_command"
    
    print_success "$(t upgrade_docker_done)"
    echo ""
    echo "  $(t new_version): $(get_current_version_docker "$image_ref")"
    echo ""
    echo "  $(t config_kept_at): $data_dir/config/config.yaml"
    echo ""
    prompt_enter_to_return
}

upgrade_npm_impl() {
    print_info "$(t upgrade_npm_start)"
    if npm install -g @my-servers/myservers; then
        print_success "$(t upgrade_success)"
    else
        print_error "$(t upgrade_failed)"
        return 1
    fi
    
    print_success "$(t upgrade_npm_done)"
    echo ""
    echo "  $(t new_version): $(get_current_version_npm)"
    echo ""
    echo "  $(t config_kept_at): ~/.myservers/config/config.yaml"
    echo ""
    prompt_enter_to_return
}

check_upgrade() {
    clear_screen
    print_step "$(t check_updates_title)"
    
    printf '%b\n' "${BOLD}$(t choose_check_method)${RESET}"
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
        echo "      - $(t installed_docker)"
    else
        echo "      - $(t docker_not_detected)"
    fi
    echo ""
    
    echo "  [2] npm"
    if $has_npm; then
        echo "      - $(t installed_npm_package)"
    else
        echo "      - $(t npm_not_detected)"
    fi
    echo ""
    
    echo "  [3] $(t check_all)"
    echo ""
    
    echo "  [4] $(t back)"
    echo ""
    
    read -p "$(t choose_1_3)" choice
    
    case $choice in
        1)
            if $has_docker; then
                check_upgrade_docker
            else
                print_error "$(t docker_unavailable)"
                echo ""
                prompt_enter_to_return
            fi
            ;;
        2)
            if $has_npm; then
                check_upgrade_npm
            else
                print_error "$(t npm_unavailable)"
                echo ""
                prompt_enter_to_return
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
    print_step "$(t docker_check_updates_title)"
    
    if ! check_command docker || ! docker info &>/dev/null 2>&1; then
        print_error "$(t docker_unavailable)"
        return 1
    fi
    
    local current=$(get_current_version_docker)
    local latest=$(get_latest_version_docker)
    
    echo "  $(t current_version): $current"
    echo "  $(t latest_version): $latest"
    echo ""
    
    if [ "$latest" = "" ]; then
        print_error "$(t latest_version_fetch_failed)"
        echo ""
        prompt_enter_to_return
        return 1
    fi
    
    if [ "$current" = "unknown" ]; then
        print_warning "$(t image_not_installed)"
        echo ""
        prompt_enter_to_return
        return 1
    fi
    
    local result=$(compare_versions "$current" "$latest")
    
    if [ "$result" = "equal" ]; then
        print_success "$(t already_latest) ($current)"
        echo ""
        prompt_enter_to_return
        return 0
    elif [ "$result" = "older" ]; then
        print_warning "$(t new_version_found): $current -> $latest"
    else
        print_error "$(t version_compare_failed)"
        echo ""
        prompt_enter_to_return
        return 1
    fi
    
    echo ""
    read -p "$(t confirm_upgrade)" confirm
    confirm=${confirm:-Y}
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "$(t upgrade_cancelled)"
        return 1
    fi
    
    upgrade_docker_impl
}

check_upgrade_npm() {
    clear_screen
    print_step "$(t npm_check_updates_title)"
    
    if ! check_command npm || ! check_command myservers; then
        print_error "$(t npm_unavailable)"
        return 1
    fi
    
    local current=$(get_current_version_npm)
    local latest=$(get_latest_version_npm)
    
    echo "  $(t current_version): $current"
    echo "  $(t latest_version): $latest"
    echo ""
    
    if [ "$current" = "not_installed" ]; then
        if [ "$LANGUAGE" = "en" ]; then
            print_error "npm installation was not detected. Please install it first."
        else
            print_error "未检测到 npm 安装，请先安装"
        fi
        echo ""
        prompt_enter_to_return
        return 1
    fi
    
    if [ "$latest" = "" ]; then
        print_error "$(t latest_version_fetch_failed)"
        echo ""
        prompt_enter_to_return
        return 1
    fi
    
    local result=$(compare_versions "$current" "$latest")
    
    if [ "$result" = "equal" ]; then
        print_success "$(t already_latest) ($current)"
        echo ""
        prompt_enter_to_return
        return 0
    elif [ "$result" = "older" ]; then
        print_warning "$(t new_version_found): $current -> $latest"
    else
        print_error "$(t version_compare_failed)"
        echo ""
        prompt_enter_to_return
        return 1
    fi
    
    echo ""
    read -p "$(t confirm_upgrade)" confirm
    confirm=${confirm:-Y}
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "$(t upgrade_cancelled)"
        return 1
    fi
    
    upgrade_npm_impl
}

check_upgrade_all() {
    clear_screen
    print_step "$(t check_all)"
    
    local upgrade_needed=false
    local has_docker=false
    local has_npm=false
    
    if check_command docker && docker info &>/dev/null 2>&1; then
        has_docker=true
        printf '%b\n' "${BOLD}Docker:${RESET}"
        
        local current=$(get_current_version_docker)
        local latest=$(get_latest_version_docker)
        
        echo "  $(t summary_current_latest): $current -> $(t latest_version) $latest"
        
        if [ "$latest" != "" ] && [ "$current" != "unknown" ]; then
            local result=$(compare_versions "$current" "$latest")
            if [ "$result" = "older" ]; then
                printf '%b\n' "  ${YELLOW}✓ $(t summary_available)${RESET}"
                upgrade_needed=true
            else
                printf '%b\n' "  ${GREEN}✓ $(t summary_latest)${RESET}"
            fi
        elif [ "$current" = "unknown" ]; then
            printf '%b\n' "  ${YELLOW}⚠ $(t not_installed)${RESET}"
        fi
        echo ""
    fi
    
    if check_command npm && check_command myservers; then
        has_npm=true
        printf '%b\n' "${BOLD}npm:${RESET}"
        
        local current=$(get_current_version_npm)
        local latest=$(get_latest_version_npm)
        
        echo "  $(t summary_current_latest): $current -> $(t latest_version) $latest"
        
        if [ "$latest" != "" ] && [ "$current" != "unknown" ]; then
            local result=$(compare_versions "$current" "$latest")
            if [ "$result" = "older" ]; then
                printf '%b\n' "  ${YELLOW}✓ $(t summary_available)${RESET}"
                upgrade_needed=true
            else
                printf '%b\n' "  ${GREEN}✓ $(t summary_latest)${RESET}"
            fi
        fi
        echo ""
    fi
    
    if ! $has_docker && ! $has_npm; then
        print_warning "$(t no_installations_detected)"
        echo ""
        prompt_enter_to_return
        return 0
    fi
    
    if $upgrade_needed; then
        echo ""
        printf '%b\n' "${BOLD}$(t choose_upgrade_method)${RESET}"
        echo ""
        
        local count=0
        
        if $has_docker; then
            count=$((count + 1))
            echo "  [$count] $(t docker_upgrade)"
        fi
        
        if $has_npm; then
            count=$((count + 1))
            echo "  [$count] $(t npm_upgrade)"
        fi
        
        count=$((count + 1))
        echo "  [$count] $(t back)"
        echo ""
        
        read -p "$(t choose_option)" choice
        
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
        prompt_enter_to_return
    fi
}

install_docker() {
    clear_screen
    print_step "$(t docker_install_title)"

    local platform=$(detect_platform)
    if [ "$platform" != "linux" ] && [ "$platform" != "macos" ]; then
        print_error "$(t unsupported_platform_docker)"
        echo ""
        echo "  $(t unsupported_platform_use_npm)"
        echo ""
        prompt_enter_to_return
        return 1
    fi

    if [ "$platform" = "macos" ]; then
        print_warning "$(t macos_docker_warning)"
        echo ""
        echo "  $(t macos_note)"
        echo "$(t macos_note_1)"
        echo "$(t macos_note_2)"
        echo "$(t macos_note_3)"
        echo ""
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
            print_warning "$(t config_existing_found)"
            echo ""
            
            echo "  $(t config_current)"
            [ -n "$existing_port" ] && echo "    - $(t config_port): $existing_port"
            [ -n "$existing_key" ] && echo "    - $(t config_secret): ${existing_key:0:16}..."
            echo ""
            
            read -p "$(t use_existing_config)" use_existing
            use_existing=${use_existing:-Y}
            
            if [[ "$use_existing" =~ ^[Yy]$ ]]; then
                default_port="${existing_port:-18612}"
                default_key="$existing_key"
                print_info "$(t using_existing_config)"
            else
                default_key=$(generate_secret_key)
                print_info "$(t using_new_config)"
            fi
        else
            default_key=$(generate_secret_key)
        fi
    else
        default_key=$(generate_secret_key)
    fi

    local http_port="$default_port"
    local secret_key="$default_key"
    local image_source_default
    image_source_default=$(detect_docker_image_source)
    local image_source
    local permission_mode="minimal"
    printf '\n'
    image_source="$(choose_docker_image_source "$image_source_default")"
    permission_mode="$(choose_docker_permission_mode "$permission_mode")"
    local image_ref
    image_ref=$(docker_image_for_source "$image_source")

    printf '%b\n' "${BOLD}$(t configure_install_params)${RESET}\n"

    echo "  $(t docker_default_mount_notice_1)"
    echo "  $(t docker_default_mount_notice_2)"
    echo ""

    read -p "$(t data_dir_prompt)" input
    local data_dir="$input"

    read -p "$(t http_port_prompt) [${http_port}]: " input
    http_port=${input:-$http_port}

    while true; do
        read -p "$(t secret_prompt) [${secret_key:0:16}...]: " input
        secret_key=${input:-$secret_key}
        if validate_secret_key "$secret_key"; then
            break
        fi
    done

    # 容器内数据目录
    local container_myservers_dir="/root/.myservers"
    local host_data_dir=""
    local map_docker_socket="false"
    
    if [ "$permission_mode" = "full" ] && [ "$platform" = "linux" ]; then
        if has_docker_socket; then
            map_docker_socket="true"
            print_info "$(t docker_socket_mapped)"
        else
            print_info "$(t docker_socket_missing)"
        fi
    elif should_map_docker_socket; then
        map_docker_socket="true"
        print_info "$(t docker_socket_mapped)"
    elif has_docker_socket; then
        print_info "$(t docker_socket_skipped)"
    else
        print_info "$(t docker_socket_missing)"
    fi

    # 如果用户指定了自定义目录，则挂载到容器内的 /root/.myservers
    if [ -n "$data_dir" ]; then
        mkdir -p "$data_dir" 2>/dev/null || true
        host_data_dir="$data_dir"
        print_info "$(t using_custom_data_dir): $data_dir"
    else
        # 默认挂载宿主机的 ~/.myservers 到容器的 /root/.myservers
        local default_host_dir="$HOME/.myservers"
        mkdir -p "$default_host_dir" 2>/dev/null || true
        host_data_dir="$default_host_dir"
        print_info "$(t using_default_data_dir): $default_host_dir"
    fi

    local docker_command=$(docker_run_command "$host_data_dir" "$secret_key" "$http_port" "$map_docker_socket" "$permission_mode" "$platform" "$image_ref")
    local docker_show_config=$(docker_show_config_command "$host_data_dir" "$secret_key" "$http_port" "$map_docker_socket")

    echo ""
    printf '%b\n' "${BOLD}$(t config_summary)${RESET}"
    echo "  Data: $host_data_dir (container: $container_myservers_dir)"
    echo "  $(t http_port_prompt): $http_port"
    echo "  $(t config_secret): $secret_key"
    echo "  $(t docker_socket_status): $(bool_word "$map_docker_socket")"
    echo "  $(t permission_mode_status): $(docker_permission_mode_label "$permission_mode")"
    echo "  $(t image_source_status): $([ "$image_source" = "1panel" ] && echo docker.1panel.live || echo Docker\ Hub)"
    echo ""
    echo "  $(t docker_full_command)"
    echo "    $docker_command"
    echo ""

    read -p "$(t confirm_install_prompt)" confirm
    confirm=${confirm:-Y}

    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "  $(t install_cancelled)"
        return 1
    fi

    print_info "$(t checking_docker_image)"

    if docker images "$image_ref" &>/dev/null; then
        print_success "$(t image_exists)"
    else
        print_info "$(t pulling_image)"
        if docker pull "$image_ref"; then
            print_success "$(t image_pull_success)"
        else
            print_error "$(t image_pull_failed)"
            return 1
        fi
    fi

    print_info "$(t stopping_old_container)"
    docker rm -f myservers 2>/dev/null || true

    print_info "$(t starting_container)"
    eval "$docker_command"

    if wait_for_service "$http_port"; then
        clear_screen
        printf '%b\n' "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        printf '%b\n' "${GREEN}  $(t install_done)${RESET}"
        printf '%b\n' "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo ""
        if [ -n "$data_dir" ]; then
            echo "  $(t data_directory): $data_dir (container: $container_myservers_dir)"
        else
            echo "  $(t data_directory): $HOME/.myservers (container: $container_myservers_dir)"
        fi
        echo ""
        echo "  $(t run_show_config_now)"
        echo "    [1] $(t run_now)"
        echo "    [2] $(t run_later)"
        echo ""
        read -p "$(t choose_1_2)" docker_show_config_mode
        case $docker_show_config_mode in
            1)
                eval "$docker_show_config"
                ;;
            2|*)
                echo "  $(t config_hint): $docker_show_config"
                echo "  $(t show_config_later_hint)"
                ;;
        esac
        echo ""
    else
        print_error "$(t service_start_verify_failed)"
        return 1
    fi
}

install_npm() {
    clear_screen
    print_step "$(t npm_install_title)"

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
            print_warning "$(t config_existing_found): $config_file"
            echo ""
            
            echo "  $(t config_current)"
            [ -n "$existing_port" ] && echo "    - $(t config_port): $existing_port"
            [ -n "$existing_key" ] && echo "    - $(t config_secret): ${existing_key:0:16}..."
            echo ""
            
            read -p "$(t use_existing_config)" use_existing
            use_existing=${use_existing:-Y}
            
            if [[ "$use_existing" =~ ^[Yy]$ ]]; then
                default_port="${existing_port:-18612}"
                default_key="$existing_key"
                print_info "$(t using_existing_config)"
            else
                default_key=$(generate_secret_key)
                print_info "$(t using_new_config)"
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
    printf '%b\n' "${BOLD}$(t configure_install_params)${RESET}\n"

    read -p "$(t http_port_prompt) [${http_port}]: " input
    http_port=${input:-$http_port}

    while true; do
        read -p "$(t secret_prompt) [${secret_key:0:16}...]: " input
        secret_key=${input:-$secret_key}
        if validate_secret_key "$secret_key"; then
            break
        fi
    done

    set_server_runtime_args "$secret_key" "$http_port"

    echo ""
    print_info "$(t npm_install_start)"
    echo ""

    if npm install -g @my-servers/myservers; then
        print_success "$(t npm_install_success)"
    else
        print_error "$(t npm_install_failed)"
        return 1
    fi

    clear_screen
    printf '%b\n' "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    printf '%b\n' "${GREEN}  $(t install_done)${RESET}"
    printf '%b\n' "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
    echo "  $(t install_path): $(command -v myservers)"
    echo ""

    printf '%b\n' "${BOLD}$(t start_mode)${RESET}"
    echo "  [1] $(t background_run)"
    echo "      $(t command_label) $(background_run_command "$(detect_platform)" "$secret_key" "$http_port")"
    echo "  [2] $(t start_later)"
    echo ""

    read -p "$(t choose_1_2)" run_mode

    case $run_mode in
        1)
            print_info "$(t start_service_bg)"
            local platform=$(detect_platform)
            eval "$(background_run_command "$platform" "$secret_key" "$http_port")"
            sleep 2
            if check_process; then
                print_success "$(t service_running_bg)"
                local pid=$(get_process_id "$platform")
                echo "  $(t process_id): $(format_process_id "$pid")"
                if [ "$platform" = "windows" ]; then
                    echo "  $(t view_logs): type %USERPROFILE%\.myservers\logs\server.log"
                    echo "  $(t stop_service): taskkill /F /IM myservers.exe"
                else
                    echo "  $(t view_logs): tail -f ~/.myservers/logs/server.log"
                    echo "  $(t stop_service): pkill myservers"
                fi
                echo ""
                echo "  $(t show_config_now)"
                echo "    [1] $(t run_now)"
                echo "    [2] $(t run_later)"
                echo ""
                read -p "$(t choose_1_2)" show_config_mode
                case $show_config_mode in
                    1)
                        eval "$(show_config_command "$platform" "$secret_key" "$http_port")"
                        ;;
                    2|*)
                        echo "  $(t config_hint): $(show_config_command "$platform" "$secret_key" "$http_port")"
                        echo "  $(t show_config_later_hint)"
                        ;;
                esac
            else
                print_error "$(t service_start_failed)"
            fi
            ;;
        2)
            echo ""
            printf '%b\n' "${BOLD}$(t run_commands_later)${RESET}"
            local platform=$(detect_platform)
            echo "  $(t background_run): $(background_run_command "$platform" "$secret_key" "$http_port")"
            echo "  $(t config_hint): $(show_config_command "$platform" "$secret_key" "$http_port")"
            echo "  $(t show_config_later_hint)"
            echo ""
            ;;
        *)
            print_error "$(t invalid_option_service_not_started)"
            ;;
    esac
}

uninstall_docker() {
    clear_screen
    print_step "$(t docker_uninstall_label)"

    if ! is_docker_install_detected; then
        print_error "$(t docker_install_not_found)"
        echo ""
        prompt_enter_to_return
        return 1
    fi

    read -p "$(t confirm_uninstall_prompt)" confirm
    confirm=${confirm:-Y}
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_info "$(t uninstall_cancelled)"
        echo ""
        prompt_enter_to_return
        return 1
    fi

    print_info "$(t stopping_docker_container)"
    docker rm -f myservers 2>/dev/null || true

    print_info "$(t removing_docker_image)"
    docker rmi myservers/my_servers 2>/dev/null || true
    docker rmi docker.1panel.live/myservers/my_servers 2>/dev/null || true

    maybe_remove_data_dir

    echo ""
    print_success "$(t docker_uninstall_done)"
    echo ""
    prompt_enter_to_return
}

uninstall_npm() {
    clear_screen
    print_step "$(t npm_uninstall_label)"

    if ! is_npm_install_detected; then
        print_error "$(t npm_install_not_found)"
        echo ""
        prompt_enter_to_return
        return 1
    fi

    read -p "$(t confirm_uninstall_prompt)" confirm
    confirm=${confirm:-Y}
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_info "$(t uninstall_cancelled)"
        echo ""
        prompt_enter_to_return
        return 1
    fi

    print_info "$(t stopping_service_before_uninstall)"
    pkill -f "myservers" 2>/dev/null || true

    print_info "$(t npm_uninstall_start)"
    if npm uninstall -g @my-servers/myservers; then
        print_success "$(t npm_uninstall_done)"
    else
        print_error "$(t uninstall_failed)"
        echo ""
        prompt_enter_to_return
        return 1
    fi

    maybe_remove_data_dir

    echo ""
    prompt_enter_to_return
}

uninstall_menu() {
    clear_screen
    print_step "$(t uninstall_title)"

    local has_docker=false
    local has_npm=false

    if is_docker_install_detected; then
        has_docker=true
    fi

    if is_npm_install_detected; then
        has_npm=true
    fi

    printf '%b\n' "${BOLD}$(t choose_uninstall_method)${RESET}"
    echo ""

    if $has_docker; then
        echo "  [1] $(t docker_uninstall_label)"
    else
        echo "  [1] $(t docker_uninstall_missing)"
    fi

    if $has_npm; then
        echo "  [2] $(t npm_uninstall_label)"
    else
        echo "  [2] $(t npm_uninstall_missing)"
    fi

    echo "  [3] $(t back)"
    echo ""

    read -p "$(t choose_1_3)" choice

    case $choice in
        1)
            if $has_docker; then
                uninstall_docker
            else
                print_error "$(t docker_install_not_found)"
                echo ""
                prompt_enter_to_return
            fi
            ;;
        2)
            if $has_npm; then
                uninstall_npm
            else
                print_error "$(t npm_install_not_found)"
                echo ""
                prompt_enter_to_return
            fi
            ;;
        *)
            return 0
            ;;
    esac
}

show_help() {
    clear_screen
    print_step "$(t help_title)"

    printf '%b\n' "${BOLD}$(t method_npm)${RESET}"
    echo "  $(t recommended_for_npm)"
    echo "  $(t recommended_reason_npm)"
    echo ""
    echo "  $(t command_label)"
    printf '%b\n' "    ${CYAN}npm install -g @my-servers/myservers${RESET}"
    printf '%b\n' "    ${CYAN}myservers -k $(t your_secret_key)${RESET}"
    echo ""

    printf '%b\n' "${BOLD}$(t method_docker)${RESET}"
    echo "  $(t recommended_for_docker)"
    echo "  $(t docker_advantage)"
    echo "  $(t docker_limit)"
    echo ""
    echo "  $(t docker_hub_example)"
    printf '%b\n' "    ${CYAN}docker run -d --name myservers --network host --restart always \\${RESET}"
    printf '%b\n' "    ${CYAN}  --privileged -v ~/.myservers:/root/.myservers \\${RESET}"
    printf '%b\n' "    ${CYAN}  -v /var/run/docker.sock:/var/run/docker.sock \\${RESET}"
    printf '%b\n' "    ${CYAN}  myservers/my_servers ./app -k $(t your_secret_key)${RESET}"
    echo ""
    echo "  $(t panel_example)"
    printf '%b\n' "    ${CYAN}docker run -d --name myservers --network host --restart always \\${RESET}"
    printf '%b\n' "    ${CYAN}  --privileged -v ~/.myservers:/root/.myservers \\${RESET}"
    printf '%b\n' "    ${CYAN}  -v /var/run/docker.sock:/var/run/docker.sock \\${RESET}"
    printf '%b\n' "    ${CYAN}  docker.1panel.live/myservers/my_servers ./app -k $(t your_secret_key)${RESET}"
    echo ""

    printf '%b\n' "${YELLOW}$(t pair_hint)${RESET}"
    echo ""
}

main() {
    print_header

    printf '%b\n' "${BOLD}$(t main_welcome)${RESET}"
    echo "  $(t main_intro)"
    echo ""
    printf '%b\n' "${BLUE}$(t platform_detected): $(detect_platform)${RESET}"
    echo ""

    clear_screen

    print_step "$(t environment_check)"

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
        print_step "$(t choose_install_method)"

        printf '%b\n' "${BOLD}$(t please_choose)${RESET}\n"
        echo "  $(t current_language): $(current_language_label)"
        echo ""

        if $has_npm; then
            echo "  [1] $(t npm_install_recommended)"
            echo "$(t npm_menu_desc)"
        else
            echo "  [1] $(t npm_install_missing)"
        fi

        if $has_docker && { [ "$(detect_platform)" = "linux" ] || [ "$(detect_platform)" = "macos" ]; }; then
            echo "  [2] $(t docker_install_label)"
        elif $has_docker; then
            echo "  [2] $(t docker_install_platform_only)"
        else
            echo "  [2] $(t docker_install_missing)"
        fi

        echo "  [3] $(t view_help_menu)"
        echo "  [4] $(t check_upgrade_menu)"
        echo "  [5] $(t uninstall_menu)"
        echo "  [6] $(t switch_language_menu)"
        echo "  [0] $(t exit_label)"
        echo ""

        read -p "$(t choose_0_6)" choice

        case $choice in
            1)
                if $has_npm; then
                    install_npm
                else
                    print_error "$(t npm_missing_install_node)"
                    echo ""
                    echo "$(t node_install_ref)"
                    echo ""
                    prompt_enter_to_continue
                fi
                ;;
            2)
                if $has_docker; then
                    install_docker
                else
                    print_error "$(t docker_missing_install)"
                    echo ""
                    echo "$(t docker_install_ref)"
                    echo ""
                    prompt_enter_to_continue
                fi
                ;;
            3)
                show_help
                prompt_enter_to_return
                ;;
            4)
                check_upgrade
                ;;
            5)
                uninstall_menu
                ;;
            6)
                change_language
                ;;
            0|q|Q)
                echo ""
                echo "$(t goodbye)"
                echo ""
                exit 0
                ;;
            *)
                print_error "$(t invalid_option_retry)"
                echo ""
                ;;
        esac
    done
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
