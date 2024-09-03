#!/bin/bash

fetch_admin_token() {
     echo -e "\n-------------------------------------------- V.3.3"
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

get_all_users() {
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

    # Parse the JSON response to extract user data
    users_data=$(echo "$response" | jq '.users')

    if [ "$users_data" != "null" ] && [ -n "$users_data" ]; then
        echo "Users fetched successfully."
        echo "$users_data"
        echo "--------------------------------------------"
    else
        echo "No users found or failed to parse the response."
        return 1
    fi
}




fetch_admin_token
if [ $? -eq 0 ]; then
    get_all_users
fi
