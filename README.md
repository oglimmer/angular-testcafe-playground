# Angular - testcafe.io playground

## How to run

Assuming you have the AWS infrastructure running.

```
npm i
npm run start

npm run 2e2
```

## How to set up AWS

### DynamoDB

Create a DynamoDB with the name "book" and a partition key "userid" as string.

### Lambda

Create a lambda `book-res-write` as type node14:

```
const AWS = require('aws-sdk');
const docClient = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event) => {
    const body = event["body-json"];

    const userid = body.userid;

    var paramsRead = {
      TableName: 'book',
      Key: {
        'userid': userid
      }
    };

    const data = await docClient.get(paramsRead).promise();
    let Item = data.Item;
    if (!Item) {
      Item = {
        userid: userid,
        books: []
      }
    }

    Item.books.push(body.book);

    const paramsWrite = {
      TableName: 'book',
      Item
    };
    
    const writeResp = await docClient.put(paramsWrite).promise();
    
    const response = {
        statusCode: 200,
        body: "done",
    };
    return response;
};
```

Create another lambda `book-res-read` as type node14:

```
const AWS = require('aws-sdk');
const docClient = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event) => {

    const userid = event.params.querystring.userid;

    var paramsRead = {
      TableName: 'book',
      Key: {
        'userid': userid
      }
    };

    const data = await docClient.get(paramsRead).promise();
    let Item = data.Item;
    if (!Item) {
      Item = {
        userid: userid,
        books: []
      }
    }
    return Item;
};
```

Make sure both lambdas have the following policy:

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "logs:CreateLogGroup",
            "Resource": "arn:aws:logs:eu-central-1:*:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:eu-central-1:*:log-group:/aws/lambda/book-res:*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:PutItem",
                "dynamodb:GetItem"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
```

### API Gateway

Create a REST API gateway for the resource /book.

* Add a GET and a POST method
* Enable CORS
* For /GET
    * For "Method Request" add a URL Query String parameter
    * For "Integration Request" set Mapping Templates to "When there are no templates defined (recommended)", then add a content-type "application/json" and select "method request passthrough" from the Generate template dropdown.
* For /POST
    * For "Integration Request" set Mapping Templates to "When there are no templates defined (recommended)", then add a content-type "application/json" and select "method request passthrough" from the Generate template dropdown.
