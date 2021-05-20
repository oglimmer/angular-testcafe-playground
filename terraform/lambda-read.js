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