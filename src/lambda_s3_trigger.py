import json
import urllib.parse
import boto3
import logging
from os import getenv

s3 = boto3.client('s3')

ses_client = boto3.client('ses')

def create_email_body(file_name, bucket_name):

    subject = f'[Alcon Workshops] File Processing Notification - {file_name}'

    body = f"""
    Dear User,

    This is an automated message to notify you that a file has been updated or uploaded in the Amazon S3 bucket associated with your account.

    Details:

    Bucket Name: {bucket_name}
    File Name: {file_name}

    Best Regards,
    XYZ Team
    """

    return subject, body

def send_email(subject, body): 

    # Create the email message
    message = {
        'Subject': {
            'Data': subject
        },
        'Body': {
            'Text': {
                'Data': body
            }
        }
    }

    # Send the email
    response = ses_client.send_email(
        Source=getenv('SENDER_EMAIL_ADDRESS'),
        Destination={
            'ToAddresses': [getenv('RECIPIENT_EMAIL_ADDRESS')]
        },
        Message=message
    )

    print(f"Email sent! Message ID: {response['MessageId']}")


def lambda_handler(event=None, context=None):

    logging.info("Starting S3 bucket notification job")

    bucket = event['Records'][0]['s3']['bucket']['name']

    key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'], encoding='utf-8')

    try:
        subject, body = create_email_body(file_name=key, bucket_name=bucket)

        send_email(subject, body)

        return {"status": "OK"}
    
    except Exception as e:
        print(e)
        print('Error getting object {} from bucket {}. Make sure they exist and your bucket is in the same region as this function.'.format(key, bucket))
        raise e