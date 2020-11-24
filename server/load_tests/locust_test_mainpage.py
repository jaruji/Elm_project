import time
from locust import HttpUser, task, between

class QuickstartUser(HttpUser):
    wait_time = between(1, 5)

    @task
    def get_auth(self):
        self.client.get("http://localhost:3000/account/auth")
    
    @task
    def get_trending(self):
        self.client.get("http://localhost:3000/tags/trending")
    
    @task
    def get_latest(self):
        self.client.get("http://localhost:3000/posts/latest")
