from flask import Flask, request
from datetime import datetime
import json

app = Flask(__name__)

@app.route('/')
def get_time_and_ip():
    # Get current time
    current_time = datetime.now().isoformat()
    
    # Get the visitor's IP address (handling proxies/load balancers)
    # This may need adjustment based on the hosting environment (e.g., getting the 'X-Forwarded-For' header)
    # For a simple test, we'll use request.remote_addr
    visitor_ip = request.remote_addr if request.remote_addr else "unknown"
    
    response_data = {
        "timestamp": current_time,
        "ip": visitor_ip
    }
    
    return json.dumps(response_data), 200, {'Content-Type': 'application/json'}

if __name__ == '__main__':
    # Use a non-privileged port (e.g., 8080)
    app.run(host='0.0.0.0', port=8080)