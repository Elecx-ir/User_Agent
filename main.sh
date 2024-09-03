#!/bin/bash

fetch_admin_token() {
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
    echo "Fetching users from: $api_url"
    echo "Using token: $token"

    response=$(curl -s -o response_body.txt -w "%{http_code}" -X GET "$api_url" \
        -H "accept: application/json" \
        -H "Authorization: Bearer $token")

    http_status=$(tail -n 1 response_body.txt)
    response_body=$(sed '$ d' response_body.txt)

    if [ "$http_status" -ne 200 ]; then
        echo "Failed to fetch users. HTTP Status: $http_status"
        echo "Response: $response_body"
        return 1
    fi

    content_type=$(echo "$response_body" | jq -r 'if type=="object" then "application/json" else empty end')

    if [ "$content_type" == "application/json" ]; then
        users_data=$(echo "$response_body" | jq -c '.users[]')

        user_summaries=()

        for user in $users_data; do
            username=$(echo "$user" | jq -r '.username')
            sub_last_user_agent=$(echo "$user" | jq -r '.sub_last_user_agent')

            user_summary="{\"username\": \"$username\", \"sub_last_user_agent\": \"$sub_last_user_agent\"}"
            user_summaries+=("$user_summary")
        done

        echo "${user_summaries[@]}" | jq -s '.'
    else
        echo "Unexpected content type: $response_body"
        return 1
    fi
}

fetch_admin_token
if [ $? -eq 0 ]; then
    get_all_users
fi
