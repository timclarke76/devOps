#!/bin/bash

TERRAFORM_DIR="/home/tim/university/semester1/devOps/part2/code/terraform"
REGION="eu-west-2"
SERVICES=("auth" "booking" "customer" "email" "logging" "payment" "room" "weather")
# SERVICES=("room")

for arg in "$@"; do
    case $arg in
        "construct")
            echo "Creating environment …"
            cd $TERRAFORM_DIR
            terraform validate
            terraform apply --auto-approve
            GATEWAY_URL=$(terraform output -raw gateway_url)
            export GATEWAY_URL
            cd - > /dev/null
            ;;

        "deploy")
            echo -e "Building services …\n"
        
            ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
            ECR_BASE="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"
            aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_BASE
        
            for SERVICE in "${SERVICES[@]}"; do
                echo -e "\nBuilding $SERVICE …"
                cd "services/$SERVICE"
                docker build -t $SERVICE:latest .
                docker tag $SERVICE:latest $ECR_BASE/$SERVICE:latest
                docker push $ECR_BASE/$SERVICE:latest
                cd - > /dev/null
            done
        
            echo -e "Forcing new deployments …"
            for SERVICE in "${SERVICES[@]}"; do
                aws ecs update-service \
                    --cluster main-cluster \
                    --service $SERVICE-service \
                    --force-new-deployment \
                    --region $REGION \
                    --no-cli-pager >/dev/null 2>&1 || echo "Service $SERVICE not found"
            done
        ;;

        "test")
            echo -e "Testing environment …\n"
            cd $TERRAFORM_DIR
            GATEWAY_URL=$(terraform output -raw gateway_url)
            RANDOM_STRING=$(uuidgen)
            EMAIL="test.user.${RANDOM_STRING}@example.com"

            # echo -e "Checking registration …\n"
            # curl -i -X POST {$GATEWAY_URL}auth/register -H "Content-Type: application/json" \
            #     -d "{\"name\": \"Tim\", \"email\": \"$EMAIL\", \"password\": \"Password123\"}"
            # echo -e "\n"

            # echo -e "Checking login …\n"
            # curl -i -X POST {$GATEWAY_URL}auth/login -H "Content-Type: application/json" \
            #     -d "{\"username\": \"$EMAIL\", \"password\": \"Password123\"}"
            # echo -e "\n"

            # echo -e "Checking customer …\n"
            # curl -i -X POST {$GATEWAY_URL}customer/profile -H "Content-Type: application/json" \
            #     -d "{\"email\": \"$EMAIL\"}"
            # echo -e "\n"

            # echo -e "Checking forecast …\n"
            # curl -i {$GATEWAY_URL}weather/forecast?location=Cardiff\&date=2025-12-23
            # echo -e "\n"

            # echo -e "Logging …\n"
            # curl -i -X POST {$GATEWAY_URL}logging/store -H "Content-Type: application/json" \
            #     -d "{\"service_name\": \"Tim\", \"level\": \"INFO\", \"data\": \"my test $RANDOM_STRING\"}"
            # echo -e "\n"

            # echo -e "Listing all rooms …\n"
            # curl -i {$GATEWAY_URL}room/
            # echo -e "\n"

            # echo -e "Listing one room location …\n"
            # curl -i {$GATEWAY_URL}room/?location=Edinburgh
            # echo -e "\n"

            # echo -e "Listing one room …\n"
            # curl -i --get "{$GATEWAY_URL}room/" --data-urlencode "location=Belfast" --data-urlencode "name=Lagan View Room"
            # echo -e "\n"

            echo -e "Check room availability …\n"
            curl -i --get "{$GATEWAY_URL}booking/checkAvailability" --data-urlencode "Location=Aberdeen" \
                --data-urlencode "RoomName=Granite City Boardroom" \
                --data-urlencode "BookingDate=2025-12-25"
            echo -e "\n"

            echo -e "Booking …\n"
            curl -i -X POST {$GATEWAY_URL}booking/createBooking -H "Content-Type: application/json" \
                -d "{\"customer_email\": \"$EMAIL\", \"location\": \"Aberdeen\", \"room_name\": \"Granite City Boardroom\",
                \"booking_date\": \"2025-12-25\"}"
            echo -e "\n"

            echo -e "Emails …\n"
            curl -i --get "{$GATEWAY_URL}logging/emails"
            echo -e "\n"

            # echo -e "Requesting payment …\n"
            # curl -i --get "{$GATEWAY_URL}payment/" --data-urlencode "booking_id=Test-$RANDOM_STRING" \
            #     --data-urlencode "amount_pence=37600" --data-urlencode "email=$EMAIL"
            # echo -e "\n"

            cd - > /dev/null
            ;;

        "destroy")
            echo "Destroying environment …"
            cd $TERRAFORM_DIR
            terraform destroy

            for SERVICE in "${SERVICES[@]}"; do
                aws secretsmanager delete-secret --secret-id {$SERVICE}-secrets --force-delete-without-recovery
            done

            cd - > /dev/null
            ;;
    esac
done
