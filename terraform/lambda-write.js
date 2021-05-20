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