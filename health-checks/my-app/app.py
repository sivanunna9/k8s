from flask import Flask
import time

app = Flask(__name__)

# Simulating startup delay
startup_complete = False
time.sleep(10)  # Simulate startup time
startup_complete = True

@app.route('/healthz')
def healthz():
    return "OK", 200  # Liveness probe response

@app.route('/ready')
def ready():
    if startup_complete:
        return "Ready", 200  # Readiness probe response
    return "Not Ready", 503

@app.route('/startup')
def startup():
    if startup_complete:
        return "Startup Complete", 200
    return "Still Starting", 503

@app.route('/')
def home():
    return "Hello, Kubernetes!", 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
