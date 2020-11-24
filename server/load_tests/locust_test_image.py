import time
from locust import HttpUser, task, between

class QuickstartUser(HttpUser):
    wait_time = between(1, 5)

    @task
    def get_image(self):
        self.client.get("http://localhost:3000/image?id=2e5b963547416ed68796")
