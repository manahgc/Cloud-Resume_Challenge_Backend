import json
import boto3
from decimal import Decimal
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('Cloudresumeviews')

class DecimalEncoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, Decimal):
            return str(o)
        return super(DecimalEncoder, self).default(o)


def lambda_handler(event, context):
    response = table.get_item(Key={
        'Id': 0
    })
    views = response['Item']['views']
    views = views + 1
    # print(views)
    response = table.put_item(Item={
            'Id': 0,
            'views': views
    })

# Return a Lambda proxy response
    return {
            'statusCode': 200,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({'views': views}, cls=DecimalEncoder)  
    }  