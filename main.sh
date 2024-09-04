#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
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
    echo -e "-------- ${YELLOW}Marzban User Agent Script${NC} ---------"
    echo -e "--------------------------------------------"
    echo -e "------------ ${YELLOW}Telegram : @XuVixc${NC} ------------"
    echo -e "--------------------------------------------"
    read -p "Enter the URL: " API_URL
    read -p "Enter the Username: " USER_NAME
    read -sp "Enter the Password: " PASSWORD
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

    declare -A agent_users agent_counts
    local null_agent_count=0
    local null_agent_users=""

    while read -r count agent; do
        if [[ -z "$agent" || "$agent" == "null" ]]; then
            null_agent_count=$((null_agent_count + count))
            null_agent_users+=$(echo "$response" | jq -r '.users[] | select(.sub_last_user_agent == null) | .username' | tr '\n' ' ')
        else
            # Get usernames only if there are users associated with this User-Agent
            users=$(echo "$response" | jq -r --arg agent "$agent" '.users[] | select(.sub_last_user_agent == $agent) | .username')
            if [[ -n "$users" ]]; then
                agent_users["$agent"]=$(echo "$users" | tr '\n' ' ')
                agent_counts["$agent"]=$count
            fi
        fi
    done < <(echo "$response" | jq -r '.users[].sub_last_user_agent' | sort | uniq -c)

    # Create an array to hold the agents sorted by user count
    local sorted_agents=($(for agent in "${!agent_counts[@]}"; do
        echo "${agent_counts[$agent]} $agent"
    done | sort -nr | awk '{print $2}'))

    local agent_index=1
    for agent in "${sorted_agents[@]}"; do
        echo -e "$agent_index) ${GREEN}$agent - Number of Users: ${agent_counts[$agent]}${NC}"
        ((agent_index++))
    done

    # Add the null agent category to the list
    if [[ $null_agent_count -gt 0 ]]; then
        echo -e "$agent_index) ${GREEN}No User Agent - Number of Users: $null_agent_count${NC}"
        sorted_agents+=("null_agent")
    fi

    while true; do
        echo "--------------------------------------------"
        read -p "Enter the number corresponding to the agent to display users (or '0' to Exit): " selected_index
        echo "--------------------------------------------"
        if [[ "$selected_index" == "0" ]]; then
            echo -e "${RED}Exiting...${NC}"
            break
        fi

        local selected_agent=${sorted_agents[$((selected_index - 1))]}
        if [[ "$selected_agent" == "null_agent" ]]; then
            echo -e "${GREEN}No User Agent - Number of Users: $null_agent_count${NC}"
            echo -e "${YELLOW}Usernames: $null_agent_users${NC}"
        elif [[ -n "$selected_agent" ]]; then
            echo -e "${GREEN}$selected_agent - Number of Users: ${agent_counts[$selected_agent]}${NC}"
            echo -e "${YELLOW}Usernames: ${agent_users[$selected_agent]}${NC}"
        else
            echo -e "${RED}Invalid agent number.${NC}"
        fi
    done
}



install_prerequisites
fetch_admin_token && get_agent_user_stats
