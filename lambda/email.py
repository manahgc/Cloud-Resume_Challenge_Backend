
import boto3
import json
from urllib.parse import parse_qs
from botocore.exceptions import ClientError

ses = boto3.client('ses', region_name='us-east-1')  # Replace 'your-region' with your AWS region

def lambda_handler(event, context):

    print(f"Received event: {json.dumps(event)}")

    try:
          
        url_encoded_body = event["body"]
        parsed_body = parse_qs(url_encoded_body)
        
        # Convert parsed body to a flat dictionary
        body = {key: value[0] for key, value in parsed_body.items()}

        # Parse input data from the web form
        name = body['name']
        email = body['email']
        subject = body['subject']
        message = body['message']

        # Compose the email
        email_body = f"Name: {name}\nEmail: {email}\nSubject: {subject}\nMessage: {message}"
        sender_email = 'charlesmanah.gc@gmail.com'  # Replace with your sender email address
        recipient_email = 'manahcharles@yahoo.com'  # Replace with your recipient email address

        # Send the email
        
        response = ses.send_email(
            Source=sender_email,
            Destination={
                'ToAddresses': [recipient_email],
            },
            Message={
                'Body': {
                    'Text': {
                        'Data': email_body,
                    },
                },
                'Subject': {
                    'Data': 'Portfolio Website Contact Form',
                },
            },
        )


        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Headers' : 'Content-Type',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods' : 'POST,OPTIONS'
            },
            'body': json.dumps({'message': 'Email sent successfully'}),
            
        }

    except json.JSONDecodeError as e:
        print(f"Error in JSON format: {e}")
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'Invalid JSON format in request body'})
        }
    
    except KeyError as e:
        print(f"Error imncomplete parameters: {e}")
        return {
            'statusCode': 400,
            'body': json.dumps({'error': f'Missing required field: {str(e)}'})
        }

    except ClientError as e:
        print(f"Error sending email: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({'message': 'Error sending email'}),
        }

    except Exception as e:
        print(f"Unhandled error: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({'message': 'Unhandled error'}),
        }
    
