const AWS = require('aws-sdk');
AWS.config.update({ region: 'ap-northeast-1' });
exports.handler = async (event) => {
    const sqs = new AWS.SQS({
        endpoint: 'http://sqs.ap-northeast-1.localhost.localstack.cloud:4566',
        region: 'ap-northeast-1'
    });
	const params = {
        QueueUrl: 'http://sqs.ap-northeast-1.localhost.localstack.cloud:4566/000000000000/demo_queue.fifo',
        MessageBody: event.body,
        MessageGroupId: 'default',  // 必需的 FIFO 隊列參數
        MessageDeduplicationId: event.requestContext.requestId // 如果 ContentBasedDeduplication 設置為 false
    };

    try {
        await sqs.sendMessage(params).promise();
		return {
			statusCode: 200,
			body: JSON.stringify('Coupon distributed successfully'),
		}
	} catch (error) {
		return {
			statusCode: 500,
			body: JSON.stringify('Error distributing coupon: ' + error.message),
		}
	}
}
