#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

install_prerequisites() {
    echo -e "${YELLOW}Updating package lists...${NC}"
    sudo apt-get update -y
    
    if ! command -v curl &> /dev/null; then
        echo -e "${YELLOW}Installing curl...${NC}"
        sudo apt-get install curl -y
    else
        echo -e "${GREEN}curl is already installed.${NC}"
    fi

    if ! command -v jq &> /dev/null; then
        echo -e "${YELLOW}Installing jq...${NC}"
        sudo apt-get install jq -y
    else
        echo -e "${GREEN}jq is already installed.${NC}"
    fi
}

fetch_admin_token() {
    clear
    echo -e "${BLUE}--------------------------------------------${NC}"
    echo -e "${BLUE}-------- Marzban User Agent Script ---------${NC}"
    echo -e "${BLUE}--------------------------------------------${NC}"
    echo -e "${BLUE}------------ Telegram : @XuVixc ------------${NC}"
    echo -e "${BLUE}--------------------------------------------${NC}"
    read -p "Enter the URL: " API_URL
    read -p "Enter the Username: " USER_NAME
    read -p "Enter the Password: " PASSWORD
    echo -e "${BLUE}--------------------------------------------${NC}"

    local url="${API_URL}/api/admin/token"
    local data="grant_type=password&username=${USER_NAME}&password=${PASSWORD}&scope=read write&client_id=your-client-id&client_secret=your-client-secret"

    response=$(curl -s -X POST "$url" \
        -H "accept: application/json" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "$data")

    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to connect to the API.${NC}"
        return 1
    fi

    token=$(echo "$response" | jq -r '.access_token')

    if [ "$token" != "null" ] && [ -n "$token" ]; then
        echo -e "${GREEN}Token Fetched Successfully.${NC}"
    else
        echo -e "${RED}Failed to fetch the token. Response: $response${NC}"
        return 1
    fi
}

get_agent_user_stats() {
    local api_url="${API_URL}/api/users"
    local headers=(
        -H "accept: application/json"
        -H "Authorization: Bearer $token"
    )

    echo -e "${YELLOW}Fetching User Agents...${NC}"
    response=$(curl -s -X GET "$api_url" "${headers[@]}")

    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to connect to the API.${NC}"
        return 1
    fi

    agents=$(echo "$response" | jq -r '.users[].sub_last_user_agent' | sort | uniq -c)

    declare -A agent_users
    declare -A agent_counts

    while read -r count agent; do
        user_list=$(echo "$response" | jq -r --arg agent "$agent" '.users[] | select(.sub_last_user_agent == $agent) | .username' | tr '\n' ' ')
        agent_users["$agent"]="$user_list"
        agent_counts["$agent"]=$count
    done <<< "$agents"

    agent_index=1
    declare -A agent_display_map
    for agent in "${!agent_counts[@]}"; do
        agent_display_map[$agent_index]=$agent
        echo -e "${BLUE}$agent_index) $agent - ${GREEN}Number of Users: ${agent_counts[$agent]}${NC}"
        ((agent_index++))
    done
    
    while true; do
        read -p "Enter the number corresponding to the agent to display users (or '0' to quit): " selected_index
        echo -e "${BLUE}--------------------------------------------${NC}"
        if [[ "$selected_index" == "0" ]]; then
            echo -e "${YELLOW}Exiting...${NC}"
            break
        fi

        selected_agent=${agent_display_map[$selected_index]}

        if [ -n "$selected_agent" ]; then
            echo -e "${BLUE}Agent: $selected_agent${NC}"
            echo -e "${GREEN}Number of Users: ${agent_counts[$selected_agent]}${NC}"
            echo -e "${YELLOW}Usernames:${NC}"
            echo -e "${GREEN}${agent_users[$selected_agent]}${NC}"
        else
            echo -e "${RED}Invalid agent number.${NC}"
        fi
    done
}

install_prerequisites
fetch_admin_token
if [ $? -eq 0 ]; then
    get_agent_user_stats
fi
