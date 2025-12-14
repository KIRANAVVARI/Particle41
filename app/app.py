from flask import Flask, request
from datetime import datetime
import json

app = Flask(__name__)

@app.route('/')
def get_time_and_ip():
    # Get current time
    current_time = datetime.now().isoformat()
    
    # --- CRITICAL FIX: Extract the true client IP from the X-Forwarded-For header ---
    if request.headers.get('X-Forwarded-For'):
        # The true client IP is the first entry in the X-Forwarded-For header chain.
        visitor_ip = request.headers['X-Forwarded-For'].split(',')[0].strip()
    else:
        # Fallback for direct access (e.g., local testing)
        visitor_ip = request.remote_addr if request.remote_addr else "unknown"
    # -------------------------------------------------------------------------------
    
    response_data = {
        "timestamp": current_time,
        # This will now contain the Public IP if App Gateway is working correctly
        "ip": visitor_ip 
    }
    
    # Return the response as JSON with the correct content type header
    return json.dumps(response_data), 200, {'Content-Type': 'application/json'}

if __name__ == '__main__':
    # Use the port defined in your Container App (e.g., 8080)
    app.run(host='0.0.0.0', port=8080)