import os
import json
import urllib3

http = urllib3.PoolManager()
PROXY_URL = os.environ.get("PROXY_URL")

def lambda_handler(event, context):
    if not PROXY_URL:
        return {"statusCode": 500, "body": "Missing PROXY_URL environment variable"}

    method = event.get("httpMethod", "GET")
    path = event.get("path", "")
    query = event.get("queryStringParameters") or {}
    headers = event.get("headers") or {}
    body = event.get("body")

    # Construct target URL (include query params manually)
    if query:
        import urllib.parse
        query_str = urllib.parse.urlencode(query)
        target_url = f"{PROXY_URL}{path}?{query_str}"
    else:
        target_url = f"{PROXY_URL}{path}"

    try:
        resp = http.request(
            method,
            target_url,
            body=body.encode("utf-8") if body else None,
            headers=headers
        )

        return {
            "statusCode": resp.status,
            "headers": dict(resp.headers),
            "body": resp.data.decode("utf-8")
        }

    except Exception as e:
        print(f"Error forwarding request: {e}")
        return {
            "statusCode": 502,
            "body": json.dumps({"error": str(e)})
        }
