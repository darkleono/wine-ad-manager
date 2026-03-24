import os
import subprocess
import re
from flask import Flask, jsonify, render_template

app = Flask(__name__)

LMUTIL_PATH = "/app/lmutil_linux"
LICENSE_FILE = "/app/licenses.lic"

# Feature code to Product mapping (2020-2026)
FEATURE_MAP = {
    # 2026
    "88179IWICMU_2026_0F": "InfraWorks 2026",
    "88176INFDU_2026_0F": "Infrastructure Design 2026",
    "88173IWWSPRO_2026_0F": "Infrastructure Web 2026",
    "88169ARNOL_2026_0F": "Arnold 2026",
    "88157INVTOL_2026_0F": "Inventor Tolerance Analysis 2026",
    "88152NINCAD_2026_0F": "Nastran In-CAD 2026",
    "88118RVT_2026_0F": "Revit 2026",
    "88119CIV3D_2026_0F": "Civil 3D 2026",
    "88042RVT_2026_0F": "Revit 2026 (Alt)",
    "88035CIV3D_2026_0F": "Civil 3D 2026 (Alt)",
    "88030AMECH_PP_2026_0F": "AutoCAD Mechanical 2026",
    "88028ACAD_E_2026_0F": "AutoCAD Electrical 2026",
    "88027ARCHDESK_2026_0F": "AutoCAD Architecture 2026",
    "88024ACDLT_2026_0F": "AutoCAD LT 2026",
    "88023ACD_2026_0F": "AutoCAD 2026",
    "88022PLNT3D_2026_0F": "AutoCAD Plant 3D 2026",
    "88131MAYA_2026_0F": "Maya 2026",
    "881273DSMAX_2026_0F": "3ds Max 2026",
    
    # 2025
    "88021IW360P_2025_0F": "InfraWorks 2025",
    "87998INFDU_2025_0F": "Infrastructure Design 2025",
    "87945RVT_2025_0F": "Revit 2025",
    "87932CIV3D_2025_0F": "Civil 3D 2025",
    "87925AMECH_PP_2025_0F": "AutoCAD Mechanical 2025",
    "87919ACD_2025_0F": "AutoCAD 2025",
    "87920ACDLT_2025_0F": "AutoCAD LT 2025",
    "879373DSMAX_2025_0F": "3ds Max 2025",
    
    # 2024
    "87798ACD_2024_0F": "AutoCAD 2024",
    "87804AMECH_PP_2024_0F": "AutoCAD Mechanical 2024",
    "87867CIV3D_2024_0F": "Civil 3D 2024",
    "87873RVT_2024_0F": "Revit 2024",
    
    # 2020-2023 Legacy
    "87676ACD_2023_0F": "AutoCAD 2023",
    "87545ACD_2022_0F": "AutoCAD 2022",
    "87393ACD_2021_0F": "AutoCAD 2021",
    "87224ACD_2020_0F": "AutoCAD 2020",
    "87232INVNTOR_2020_0F": "Inventor 2020",
    "87233INVLT_2020_0F": "Inventor LT 2020",
    "87251CIV3D_2020_0F": "Civil 3D 2020",
    "87259RVT_2020_0F": "Revit 2020",
}

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
    
    # Feature line: Users of 88030AMECH_PP_2026_0F:  (Total of 100 licenses issued;  Total of 1 license in use)
    feature_pattern = re.compile(r"Users of (.*?):.*?Total of (\d+) licenses issued;.*?Total of (\d+) license[s]* in use")
    # User line: user host host (v1.0) (server/27000 101), start Sat 3/21 11:15
    # Optional linger: (linger: 168000)
    user_pattern = re.compile(r"^\s+([\w\.-]+)\s+([\w\.-]+)\s+[\w\.-]+\s+\(v.*?\)\s+\(.*?\), start\s+([^(\n]*)(\(linger:\s+(\d+)\))?$", re.MULTILINE)
    
    # Iterate through each feature block
    sections = output.split("Users of ")
    for idx, section in enumerate(sections):
        if idx == 0: continue # Skip prologue
        
        full_text = "Users of " + section
        feature_match = feature_pattern.search(full_text)
        
        if feature_match:
            feature_code = feature_match.group(1)
            total = int(feature_match.group(2))
            used = int(feature_match.group(3))
            
            users = []
            if used > 0:
                # Find users specifically for this block
                user_matches = user_pattern.finditer(section)
                for match in user_matches:
                    u, h, s, _, linger_val = match.groups()
                    is_borrowed = False
                    borrow_info = ""
                    
                    if linger_val:
                        is_borrowed = True
                        hours_left = int(linger_val) // 3600
                        days_left = hours_left // 24
                        if days_left > 0:
                            borrow_info = f"{days_left}d {hours_left % 24}h restantes"
                        else:
                            borrow_info = f"{hours_left}h restantes"

                    users.append({
                        "user": u.strip(), 
                        "host": h.strip(), 
                        "start": s.strip(),
                        "is_borrowed": is_borrowed,
                        "borrow_info": borrow_info
                    })
            
            usage_data.append({
                "feature": feature_code,
                "product": FEATURE_MAP.get(feature_code, feature_code),
                "total": total,
                "used": used,
                "users": users,
                "percent": int((used / total) * 100) if total > 0 else 0
            })
    
    return usage_data

@app.route("/")
def index():
    return render_template("index.html")

@app.route("/api/status")
def status():
    output = get_lmstat_output()
    usage = parse_lmstat(output)
    
    # Sort usage to show busy licenses first
    usage.sort(key=lambda x: x["used"], reverse=True)
    
    is_up = "license server UP" in output
    active_users_count = sum(f["used"] for f in usage)
    
    return jsonify({
        "server_up": is_up,
        "total_active": active_users_count,
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
    import argparse
    parser = argparse.ArgumentParser(description="Autodesk License Dashboard")
    parser.add_argument("--port", type=int, default=8080, help="Port to run the dashboard on (default: 8080)")
    args = parser.parse_args()
    
    app.run(host="0.0.0.0", port=args.port, debug=False, use_reloader=False)
