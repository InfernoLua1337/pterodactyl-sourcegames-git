#!/bin/bash
set -e

sleep 1
TZ=${TZ:-UTC}
export TZ
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP

cd /home/container || exit 1

# git
REPO_PATH="${REPO_PATH:-/home/container}"
REPO_URL="${REPO_URL:-git@github.com:InfernoLua1337/cloudrp.git}"
REPO_BRANCH="${REPO_BRANCH:-main}"

SSH_KEY="/home/container/.ssh/id_rsa"

# ssh
if [ ! -f "$SSH_KEY" ]; then
    echo "================================================================"
    echo "[GIT SETUP] SSH-ключ не найден! Генерируем новый SSH ключ..."
    mkdir -p /home/container/.ssh
    ssh-keygen -q -t ed25519 -N "" -f "$SSH_KEY"
    chmod 700 /home/container/.ssh
    chmod 600 "$SSH_KEY"
    chmod 644 "$SSH_KEY.pub"
    echo ""
    echo "[GIT SETUP] GitHub Deploy Keys:"
    echo "https://github.com/InfernoLua1337/cloudrp/settings/keys"
    echo "----------------------------------------------------------------"
    cat "$SSH_KEY.pub"
    echo "----------------------------------------------------------------"
    echo "[GIT SETUP] Сервер остановлен. Добавьте ключ в GitHub и запустите сервер снова."
    echo "================================================================"
    exit 0
fi


export GIT_SSH_COMMAND="ssh -i $SSH_KEY -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

# 2. repo
if [ ! -d "$REPO_PATH/.git" ]; then
    echo "[GIT] Инициализация репозитория в $REPO_PATH..."
    mkdir -p "$REPO_PATH"
    cd "$REPO_PATH"
    git init
    git remote add origin "$REPO_URL"
    git fetch origin "$REPO_BRANCH"
    git checkout -f -B "$REPO_BRANCH" "origin/$REPO_BRANCH"
else
    echo "[GIT] Получение обновлений из $REPO_URL ($REPO_BRANCH)..."
    cd "$REPO_PATH"
    git fetch origin "$REPO_BRANCH"
    # reset --hard гарантирует применение переименований/удалений файлов
    # без конфликтов и не трогая файлы из .gitignore
    git reset --hard "origin/$REPO_BRANCH"
fi

cd /home/container || exit 1

# 3. ptero
PARSED=$(echo "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g' | eval echo "$(cat -)")

if [ "${STEAM_USER}" == "" ]; then
    echo -e "steam user is not set.\nUsing anonymous user.\n"
    STEAM_USER=anonymous
    STEAM_PASS=""
    STEAM_AUTH=""
else
    echo -e "user set to ${STEAM_USER}"
fi

if [ -z ${AUTO_UPDATE} ] || [ "${AUTO_UPDATE}" == "1" ]; then
    if [ ! -z ${SRCDS_APPID} ]; then
        ./steamcmd/steamcmd.sh +force_install_dir /home/container +login ${STEAM_USER} ${STEAM_PASS} ${STEAM_AUTH} +app_update ${SRCDS_APPID} $( [[ -z ${SRCDS_BETAID} ]] || printf %s "-beta ${SRCDS_BETAID}" ) $( [[ -z ${SRCDS_BETAPASS} ]] || printf %s "-betapassword ${SRCDS_BETAPASS}" ) $( [[ -z ${HLDS_GAME} ]] || printf %s "+app_set_config 90 mod ${HLDS_GAME}" ) $( [[ -z ${VALIDATE} ]] || printf %s "validate" ) +quit
    else
        echo -e "No appid set. Starting Server"
    fi
else
    echo -e "Not updating game server as auto update was set to 0. Starting Server"
fi

printf "\033[1m\033[33mcontainer@pterodactyl~ \033[0m%s\n" "$PARSED"
exec env ${PARSED}
