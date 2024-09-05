#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
ORANGE='\033[1;38;5;208m'
CYAN='\033[1;36m'
NC='\033[0m' 

install_prerequisites() {
    echo "Updating package lists..."
    sudo apt-get update -y
    
    if ! command -v curl &> /dev/null; then
        echo "Installing curl..."
        sudo apt-get install curl -y
    else
        echo "curl is already installed."
    fi

    if ! command -v jq &> /dev/null; then
        echo "Installing jq..."
        sudo apt-get install jq -y
    else
        echo "jq is already installed."
    fi
}

fetch_admin_token() {
    clear
    echo -e "--------------------------------------------"
    echo -e "-------- ${ORANGE}Marzban User Agent Script${NC} ---------"
    echo -e "--------------------------------------------"
    echo -e "------------ ${ORANGE}Telegram : @XuVixc${NC} ------------"
    echo -e "--------------------------------------------"
    read -p "Enter the URL [ https://sub.Marzban.com:Port ]: " API_URL
    read -p "Enter the Username: " USER_NAME
    read -p "Enter the Password: " PASSWORD
    echo -e "\n--------------------------------------------"

    local url="${API_URL}/api/admin/token"
    local data="username=${USER_NAME}&password=${PASSWORD}"
    response=$(curl -s -X POST "$url" -H "accept: application/json" -H "Content-Type: application/x-www-form-urlencoded" -d "$data")

    token=$(echo "$response" | jq -r '.access_token')
    if [[ $? -ne 0 || "$token" == "null" || -z "$token" ]]; then
        echo -e "${RED}Failed to fetch the token. Response: $response${NC}"
        return 1
    fi

    echo -e "${GREEN}Token Fetched Successfully.${NC}"
    echo "--------------------------------------------"
}

get_agent_user_stats() {
    local api_url="${API_URL}/api/users"
    local response=$(curl -s -X GET "$api_url" -H "accept: application/json" -H "Authorization: Bearer $token")
    
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Failed to connect to the API.${NC}"
        return 1
    fi

    declare -A agent_users agent_counts agent_display_map

    while read -r count agent; do
        if [[ -n "$agent" ]]; then
            agent_users["$agent"]=$(echo "$response" | jq -r --arg agent "$agent" '
                if $agent == "null Agent" then 
                    .users[] | select(.sub_last_user_agent == null) | .username 
                else 
                    .users[] | select(.sub_last_user_agent == $agent) | .username 
                end' | tr '\n' ' ')
            agent_counts["$agent"]=$count
        fi
    done < <(echo "$response" | jq -r '.users[].sub_last_user_agent | select(. != null) // "null Agent"' | sort | uniq -c)

    local agent_index=1
    for agent in "${!agent_counts[@]}"; do
        agent_display_map[$agent_index]=$agent
        echo -e "$agent_index) ${YELLOW}$agent - ${GREEN}Number of Users: ${agent_counts[$agent]}${NC}"
        ((agent_index++))
    done

    while true; do
        echo "--------------------------------------------"
        read -p "Enter the agent number to display the users (or '0' to exit): " selected_index
        echo "--------------------------------------------"
        if [[ "$selected_index" == "0" ]]; then
            echo -e "${RED}Exiting...${NC}"
            break
        fi

        local selected_agent=${agent_display_map[$selected_index]}
        if [[ -n "$selected_agent" ]]; then
            echo -e "${YELLOW}$selected_agent - ${GREEN}Number of Users: ${agent_counts[$selected_agent]}${NC}"
            echo -e "${CYAN}Usernames: ${agent_users[$selected_agent]}${NC}"
        else
            echo -e "${RED}Invalid agent number.${NC}"
        fi
    done
}


install_prerequisites
fetch_admin_token && get_agent_user_stats
