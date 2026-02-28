import os
import subprocess
import re
from flask import Flask, jsonify, render_template

app = Flask(__name__)

LMUTIL_PATH = "/opt/flexnetserver/lmutil"
LICENSE_FILE = "/var/flexlm/licenses.lic"

def get_lmstat_output():
    try:
        result = subprocess.run(
            [LMUTIL_PATH, "lmstat", "-a", "-c", LICENSE_FILE],
            capture_output=True,
            text=True,
            check=False
        )
        return result.stdout
    except Exception as e:
        return str(e)

def parse_lmstat(output):
    usage_data = []
    
    # Simple regex to find feature usage
    # Example: Users of 87224ACD_2020_0F:  (Total of 100 licenses issued;  Total of 0 licenses in use)
    feature_pattern = re.compile(r"Users of (.*?):.*?Total of (\d+) licenses issued;.*?Total of (\d+) licenses in use")
    
    matches = feature_pattern.findall(output)
    for feature, total, used in matches:
        usage_data.append({
            "feature": feature,
            "total": int(total),
            "used": int(used),
            "percent": int((int(used) / int(total)) * 100) if int(total) > 0 else 0
        })
    
    return usage_data

@app.route("/")
def index():
    return render_template("index.html")

@app.route("/api/status")
def status():
    output = get_lmstat_output()
    usage = parse_lmstat(output)
    
    # Basic server status check
    is_up = "license server UP" in output
    
    return jsonify({
        "server_up": is_up,
        "usage": usage,
        "raw_output": output
    })

@app.route("/api/reload")
def reload_lic():
    try:
        # lmreread command
        subprocess.run([LMUTIL_PATH, "lmreread", "-c", LICENSE_FILE], check=False)
        return jsonify({"status": "success", "message": "License reread command sent"})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
