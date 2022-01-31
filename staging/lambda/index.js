const AWS = require('aws-sdk')
const path = require('path');

const s3 = new AWS.S3();

exports.handler = async (event) => {
    const config= path.resolve(String(event.image));
    try {
        const buffer = Buffer.from(config, 'base64');
        const randomId = parseInt(Math.random()*10000000000)
        await s3
            .putObject({
            Body: buffer,
            Key: `${randomId}.jpeg`,
            ContentType: 'image/jpeg',
            Bucket: "terraform-my-task",
            ACL: 'private',
        })
        .promise();
        return {
            'StatusCode': 200,
            'body': 'File uploaded successfully'
        };
    } catch (error) {
        const response = {
            statusCode: 400,
            body: JSON.stringify('failed to upload image, error:' + error),
        };
        return response;
    }
};