import os
import requests
import boto3



def hit_url(event, context):
  url="https://jsonplaceholder.typicode.com/posts"

  Body = {
            "Message": "Hello from postman"
            "Subnet" : os.environ.get('Subnet')
            
         }
  response = requests.post(url,json=Body)
  print(response.text) 
  print(response.status_code, response.reason)
