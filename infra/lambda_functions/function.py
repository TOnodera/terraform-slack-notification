import json
import os
import urllib3
import base64
import gzip

http = urllib3.PoolManager()

def lambda_handler(event, context):
    slack_webhook_url = os.environ['SLACK_WEBHOOK_URL']
    decoded_data = base64.b64decode(event['awslogs']['data'])
    json_data = json.loads(gzip.decompress(decoded_data))
    
    for event in json_data['logEvents']:
        body = json.dumps({'text': event['message']})
        response = http.request(
            'POST',
            slack_webhook_url,
            body=body,
            headers={'Content-Type': 'application/json'}
        )
        if response.status != 200:
            print(f"Error sending to Slack: {response.status}, {response.data}")


    return {
        'statusCode': 200,
        'body': 'Logs sent to Slack successfully'
    }
