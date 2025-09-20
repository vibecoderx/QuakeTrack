import firebase_admin
import functions_framework
import requests
from firebase_admin import firestore, messaging
from math import radians, sin, cos, sqrt, atan2

# Initialize Firebase Admin SDK
firebase_admin.initialize_app()

# --- USER PREFERENCE MANAGEMENT ---
@functions_framework.http
def update_user_preferences(request):
    """HTTP endpoint to create/update a user's notification settings."""
    if request.method != 'POST':
        return 'Method Not Allowed', 405

    data = request.get_json(silent=True)
    fcm_token = data.get('fcm_token') if data else None
    cities = data.get('cities') if data else None

    if not fcm_token or cities is None:
        return 'Missing fcm_token or cities field', 400

    print(f"Updating preferences for token: {fcm_token[:10]}...")
    try:
        db = firestore.client()
        doc_ref = db.collection('user_preferences').document(fcm_token)
        doc_ref.set({'cities': cities, 'unread_alerts': []})
        return 'Success', 200
    except Exception as e:
        return f'Error: {e}', 500

# --- ALERT POLLING AND SENDING ---
@functions_framework.cloud_event
def check_for_earthquakes(cloud_event):
    """Periodically checks for earthquakes and sends notifications."""
    print("Starting earthquake check...")
    db = firestore.client()
    try:
        usgs_url = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_hour.geojson"
        response = requests.get(usgs_url)
        response.raise_for_status()
        earthquakes = response.json().get('features', [])
        
        users_ref = db.collection('user_preferences')
        all_user_docs = list(users_ref.stream())

        for user_doc in all_user_docs:
            user_prefs = user_doc.to_dict()
            fcm_token = user_doc.id
            user_doc_ref = users_ref.document(fcm_token)

            for quake in earthquakes:
                if should_notify_user(quake, user_prefs):
                    quake_id = quake.get('id')
                    processed_ref = db.collection('processed_earthquakes').document(quake_id)
                    
                    if not processed_ref.get().exists:
                        print(f"MATCH FOUND: Quake {quake_id} for token {fcm_token[:10]}...")
                        
                        # Add the new alert to the user's list in Firestore.
                        user_doc_ref.update({'unread_alerts': firestore.ArrayUnion([quake])})
                        
                        send_fcm_notification(fcm_token, quake)
                        processed_ref.set({'created_at': firestore.SERVER_TIMESTAMP})
                        break
    except Exception as e:
        print(f"An error occurred during earthquake check: {e}")
    print("Earthquake check finished.")

# --- ALERT RETRIEVAL AND CLEARING ---
@functions_framework.http
def get_unread_alerts(request):
    """HTTP endpoint for the app to fetch the list of unread alerts."""
    fcm_token = request.args.get('fcm_token')
    if not fcm_token:
        return 'Missing fcm_token parameter', 400

    try:
        db = firestore.client()
        doc_ref = db.collection('user_preferences').document(fcm_token)
        doc = doc_ref.get()
        if doc.exists:
            alerts = doc.to_dict().get('unread_alerts', [])
            alerts.sort(key=lambda x: x.get('properties', {}).get('time', 0), reverse=True)
            return {'alerts': alerts}
        else:
            return {'alerts': []}
    except Exception as e:
        return f'Error: {e}', 500

@functions_framework.http
def clear_user_alerts(request):
    """HTTP endpoint to clear a user's unread alerts."""
    if request.method != 'POST':
        return 'Method Not Allowed', 405
    
    data = request.get_json(silent=True)
    fcm_token = data.get('fcm_token') if data else None
    if not fcm_token:
        return 'Missing fcm_token', 400

    print(f"Clearing alerts for token: {fcm_token[:10]}...")
    try:
        db = firestore.client()
        doc_ref = db.collection('user_preferences').document(fcm_token)
        # The server now only clears the list.
        doc_ref.update({'unread_alerts': []})
        return 'Success', 200
    except Exception as e:
        return f'Error: {e}', 500

# --- HELPER FUNCTIONS ---
def should_notify_user(quake, user_prefs):
    """Checks if a given earthquake matches a user's preferences."""
    monitored_cities = user_prefs.get('cities', [])
    if not monitored_cities: return False
    props = quake.get('properties', {})
    coords = quake.get('geometry', {}).get('coordinates', [])
    if not props or not coords: return False
    quake_mag = props.get('mag') or 0
    quake_lat, quake_lon = coords[1], coords[0]
    for city in monitored_cities:
        dist_km = haversine_distance(city['latitude'], city['longitude'], quake_lat, quake_lon)
        if dist_km <= city['radius_km'] and quake_mag >= city['min_magnitude']:
            return True
    return False

def send_fcm_notification(token, earthquake):
    """Sends a push notification via FCM with a generic badge."""
    props = earthquake.get('properties', {})
    quake_id = earthquake.get('id')
    
    message = messaging.Message(
        notification=messaging.Notification(
            title="Earthquake Alert",
            body=f"M {props.get('mag', 0):.1f} - {props.get('place', 'Unknown location')}"
        ),
        apns=messaging.APNSConfig(
            payload=messaging.APNSPayload(
                aps=messaging.Aps(sound="default", badge=1, content_available=True)
            )
        ),
        data={"earthquakeID": quake_id},
        token=token
    )
    try:
        response = messaging.send(message)
        print(f"Successfully sent message for quake {quake_id}: {response}")
    except Exception as e:
        print(f"Error sending FCM message for quake {quake_id}: {e}")

def haversine_distance(lat1, lon1, lat2, lon2):
    """Calculates distance between two lat/lon points in kilometers."""
    R = 6371
    lat1_r, lon1_r, lat2_r, lon2_r = map(radians, [lat1, lon1, lat2, lon2])
    dlon = lon2_r - lon1_r
    dlat = lat2_r - lat1_r
    a = sin(dlat / 2)**2 + cos(lat1_r) * cos(lat2_r) * sin(dlon / 2)**2
    c = 2 * atan2(sqrt(a), sqrt(1 - a))
    return R * c

