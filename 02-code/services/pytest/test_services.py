import os
import requests
import pytest

# Use the API Gateway endpoint from your terraform output/env
BASE_URL = os.getenv("GATEWAY_URL") 
SERVICES = ["auth", "booking", "customer", "email",
            "logging", "payment", "room", "weather"]

@pytest.mark.parametrize("SERVICE", SERVICES)
def test_service_is_reachable(SERVICE):
    url = f"{BASE_URL}/{SERVICE}/ping-test-logic"
    
    try:
        response = requests.get(url, timeout=5)
        # If the Gateway was broken, we'd get a 503 or 504.
        assert response.status_code in [200, 404]
        print(f"Success: Service reached. Status: {response.status_code}")
    except Exception as e:
        assert False, f"Gateway connection failed: {e}"

@pytest.mark.parametrize("SERVICE", SERVICES)
def test_service_health_endpoint(SERVICE):
    url = f"{BASE_URL}/{SERVICE}/health"
    
    try:
        response = requests.get(url, timeout=5)
        assert response.status_code == 200, f"{SERVICE} reported unhealthy status: {response.status_code}"
        
        data = response.json()
        assert data.get("status") == "UP", f"{SERVICE} is running but status is {data.get('status')}"
        print(f"Success: {SERVICE} is healthy (UP).")
    except Exception as e:
        assert False, f"Health check failed for {SERVICE}: {e}"
