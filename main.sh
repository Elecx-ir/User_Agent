#!/bin/bash

fetch_admin_token() {
    echo -e "\n-------------------------------------------- V.5"
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
        echo "Token fetched successfully: $token"
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
    
    echo "Fetching users from: $api_url"
    echo "Using token: $token"

    response=$(curl -s -X GET "$api_url" "${headers[@]}")

    if [ $? -ne 0 ]; then
        echo "Failed to connect to the API."
        return 1
    fi

    echo "Agent User Stats:"
    echo "--------------------------------------------"

    # Extracting sub_last_user_agent and associated usernames
    agents=$(echo "$response" | jq -r '.users[].sub_last_user_agent' | sort | uniq)

    for agent in $agents; do
        if [ -n "$agent" ]; then
            echo "Agent: $agent"
            user_count=$(echo "$response" | jq -r --arg agent "$agent" '.users[] | select(.sub_last_user_agent==$agent) | .username' | wc -l)
            echo "Number of Users: $user_count"
            echo "Usernames:"
            echo "$response" | jq -r --arg agent "$agent" '.users[] | select(.sub_last_user_agent==$agent) | .username'
            echo "--------------------------------------------"
        fi
    done
}

fetch_admin_token
if [ $? -eq 0 ]; then
    get_agent_user_stats
fi
