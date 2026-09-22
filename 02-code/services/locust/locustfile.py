import random
from locust import HttpUser, task, between, SequentialTaskSet


class RandomMicroserviceUser(HttpUser):
    wait_time = between(1, 3)
    
    SERVICES = ["auth", "booking", "customer", "email",
        "logging", "payment", "room", "weather"]

    @task
    def check_random_service_health(self):
        service = random.choice(self.SERVICES)
        self.client.get(f"/{service}/health", name=f"Health: {service}")


class WeightedMicroserviceUser(HttpUser):
    wait_time = between(1, 2)

    @task(5) # High traffic
    def auth_check(self):
        self.client.get("/auth/health", name="Auth")

    @task(3) # Medium traffic
    def weather_check(self):
        self.client.get("/weather/health", name="Weather")

    @task(1) # Low traffic
    def payment_check(self):
        self.client.get("/payment/health", name="Payment")


class BookingJourney(SequentialTaskSet):
    @task
    def login(self):
        self.client.get("/auth/health")

    @task
    def check_rooms(self):
        self.client.get("/room/health")

    @task
    def make_booking(self):
        self.client.get("/booking/health")

class WebsiteUser(HttpUser):
    tasks = [BookingJourney]
