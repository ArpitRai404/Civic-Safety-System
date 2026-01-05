import math
import time
import uvicorn
from fastapi import FastAPI 
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel 
from typing import Optional
import firebase_admin
from firebase_admin import credentials, messaging


def initialize_firebase_once():
    try:
      
        if not firebase_admin._apps:
           
            cred = credentials.Certificate(
                "D:/GDG project/safety-app-7b396-firebase-adminsdk-fbsvc-bbaa11dcce.json"
            )
            firebase_admin.initialize_app(cred)
            print("✅ Firebase Admin SDK initialized successfully")
        else:
            print("ℹ️ Firebase app already initialized")
    except Exception as e:
        print(f"❌ Firebase initialization error: {e}")


initialize_firebase_once()

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class LocationUpdate(BaseModel):
    user_id: str 
    lon: float 
    lat: float
    fcm_token: Optional[str] = None  


def haversine(lat1, lon1, lat2, lon2):
    """Calculate distance between two coordinates in kilometers"""
    R = 6371  
    
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)
    
    a = math.sin(dphi/2)**2 + math.cos(phi1)*math.cos(phi2)*math.sin(dlambda/2)**2
    return 2 * R * math.atan2(math.sqrt(a), math.sqrt(1 - a))


users = {}  # Format: {user_id: {'lat': x, 'lon': y, 'fcm_token': 'xyz'}}


@app.get("/")
def read_root():
    return {"message": "🚨 Safety App Backend with FCM Notifications", "status": "online"}


@app.post("/location/update")
async def update_location(data: LocationUpdate):
    print("📥 LOCATION UPDATE RECEIVED:", data.user_id)
    users[data.user_id] = {
        'lon': data.lon,
        'lat': data.lat,
        'fcm_token': data.fcm_token
    }
    print("🧠 USERS STATE:", users)
    return {"message": "Location updated successfully", "user_id": data.user_id}


@app.get("/location/{user_id}")
def get_location(user_id: str):
    """Get specific user's location"""
    if user_id in users:
        return users[user_id]
    return {"error": "User not found"}


def find_nearby_users(user_id: str, radius: float = 1.5):
    """Find users within radius of given user"""
    if user_id not in users:
        return []
    
    results = [] 
    base_user = users[user_id]
    
    for other_id, other_data in users.items():
        if other_id == user_id:
            continue  # Skip the user themselves
        
        distance = haversine(
            base_user["lat"], base_user["lon"],
            other_data["lat"], other_data["lon"]
        )
        
        if distance <= radius:
            results.append({
                "id": other_id, 
                "lat": other_data["lat"],
                "lon": other_data["lon"],
                "distance": round(distance, 2),
                "fcm_token": other_data.get("fcm_token")
            })
    
    return results


@app.get("/location/nearby/{user_id}")
def get_users_nearby(user_id: str, radius: float = 1.5):
    """Get nearby users within specified radius"""
    if user_id not in users:
        return []
    
    nearby_users = find_nearby_users(user_id, radius)
    print(f"🔍 Found {len(nearby_users)} users near {user_id} within {radius}km")
    return nearby_users


@app.post("/emergency/{user_id}")
async def trigger_emergency(user_id: str):
    """Trigger emergency alert and notify nearby users via FCM"""
    if user_id not in users:
        return {"error": "User not found"}
    
    victim = users[user_id]
    nearby_users = find_nearby_users(user_id, radius=1.5)
    notified_users = []
    
    print(f"🚨 EMERGENCY from user {user_id}!")
    print(f"📍 Victim location: {victim['lat']}, {victim['lon']}")
    print(f"👥 Nearby users to notify: {len(nearby_users)}")
    
    for user in nearby_users:
        fcm_token = user.get("fcm_token")
        
        if fcm_token and fcm_token != "null" and len(fcm_token) > 50:
            try:
                message = messaging.Message(
                    notification=messaging.Notification(
                        title="🚨 EMERGENCY ALERT!",
                        body=f"Someone {user['distance']}km away needs immediate help!"
                    ),
                    data={
                        "type": "emergency",
                        "victim_id": user_id,
                        "victim_lat": str(victim["lat"]),
                        "victim_lon": str(victim["lon"]),
                        "distance": str(user["distance"]),
                        "timestamp": str(math.floor(time.time()))
                    },
                    token=fcm_token,
                )
                
                response = messaging.send(message)
                print(f"✅ Sent FCM to {user['id']}: {response}")
                notified_users.append(user['id'])
                
            except Exception as e:
                print(f"❌ Failed to send FCM to {user['id']}: {e}")
        else:
            print(f"⚠️ User {user['id']} has no valid FCM token")
    
    print(f"📢 Total notified: {len(notified_users)} users")
    
    return {
        "message": "Emergency alert sent successfully",
        "notified_users": notified_users,
        "count": len(notified_users),
        "victim_location": {
            "lat": victim["lat"],
            "lon": victim["lon"]
        }
    }


@app.get("/test/notify/{user_id}")
async def test_notification(user_id: str):
    """Test endpoint to send a test notification"""
    if user_id not in users:
        return {"error": "User not found"}
    
    fcm_token = users[user_id].get("fcm_token")
    
    if not fcm_token:
        return {"error": "User has no FCM token"}
    
    try:
        message = messaging.Message(
            notification=messaging.Notification(
                title="🔔 Test Notification",
                body="This is a test notification from Safety App!"
            ),
            token=fcm_token,
        )
        
        response = messaging.send(message)
        return {"message": "Test notification sent", "response": response}
    except Exception as e:
        return {"error": str(e)}


if __name__ == "__main__":
    print("🚀 Starting Safety App Backend Server...")
    print("🌐 Server will be available at:")
    print("   • http://localhost:8000 (on this computer)")
    print("   • http://10.0.2.2:8000 (Android emulator)")
    print("   • http://YOUR_IP:8000 (real devices)")
    print("📡 Press CTRL+C to stop the server")
    print("-" * 50)
    
    uvicorn.run(
        app, 
        host="0.0.0.0",
        port=8000,
        reload=True
    )

