#!/bin/bash

fetch_admin_token() {
    echo -e "\n-------------------------------------------- V.7.7"
    read -p "Enter the API URL: " API_URL
    read -p "Enter the Username: " USER_NAME
    read -s -p "Enter the Password: " PASSWORD
    echo -e "\n--------------------------------------------"

    local url="${API_URL}/api/admin/token"
    local data="grant_type=password&username=${USER_NAME}&password=${PASSWORD}&scope=read write&client_id=your-client-id&client_secret=your-client-secret"

    response=$(curl -s -X POST "$url" \
        -H "accept: application/json" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "$data")

    if [ $? -ne 0 ]; then
        echo "Failed to connect to the API."
        return 1
    fi

    token=$(echo "$response" | jq -r '.access_token')

    if [ "$token" != "null" ] && [ -n "$token" ]; then
        echo "Token fetched successfully."
        echo "--------------------------------------------"
    else
        echo "Failed to fetch the token. Response: $response"
        return 1
    fi
}

get_agent_user_stats() {
    local api_url="${API_URL}/api/users"
    local headers=(
        -H "accept: application/json"
        -H "Authorization: Bearer $token"
    )

    response=$(curl -s -X GET "$api_url" "${headers[@]}")

    if [ $? -ne 0 ]; then
        echo "Failed to connect to the API."
        return 1
    fi

    echo "Agent User Stats:"
    echo "--------------------------------------------"

    # Extract and process sub_last_user_agent values
    agents=$(echo "$response" | jq -r '.users[].sub_last_user_agent' | sort | uniq)

    # Use associative array to track counts and users
    declare -A agent_users
    declare -A agent_counts

    for agent in $agents; do
        user_count=$(echo "$response" | jq -r --arg agent "$agent" '.users[] | select(.sub_last_user_agent == $agent) | .username' | wc -l)
        agent_users["$agent"]=$(echo "$response" | jq -r --arg agent "$agent" '.users[] | select(.sub_last_user_agent == $agent) | .username' | tr '\n' ' ')
        agent_counts["$agent"]=$user_count
    done

    # Display agents with their user counts
    for agent in "${!agent_counts[@]}"; do
        echo "Agent: $agent"
        echo "Number of Users: ${agent_counts[$agent]}"
        echo "--------------------------------------------"
    done

    # Get user input for agent number
    read -p "Enter the agent name to display users (exactly as shown above): " selected_agent

    if [ -n "${agent_users[$selected_agent]}" ]; then
        echo "Agent: $selected_agent"
        echo "Number of Users: ${agent_counts[$selected_agent]}"
        echo "Usernames:"
        echo "${agent_users[$selected_agent]}"
    else
        echo "Invalid agent name."
    fi
}

fetch_admin_token
if [ $? -eq 0 ]; then
    get_agent_user_stats
fi
