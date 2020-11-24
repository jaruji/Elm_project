import time
from locust import HttpUser, task, between

class QuickstartUser(HttpUser):
    wait_time = between(1, 5)

    @task
    def add_comment(self):
        self.client.post("http://localhost:3000/comment/add", json={"id": "2e5b963547416ed68796", "username": "ramang", "content": "test komentara"})

    @task
    def get_comment_info(self):
        self.client.get("http://localhost:3000/image/stats?id=2e5b963547416ed68796")

    @task
    def get_image(self):
        self.client.get("http://localhost:3000/comment/get?id=2e5b963547416ed68796")
