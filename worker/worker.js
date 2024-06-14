const AWS = require('aws-sdk');
AWS.config.update({ region: 'ap-northeast-1' });

const queueUrl = 'http://localstack_demo:4566/000000000000/demo_queue.fifo'

const pullData = async () => {
  AWS.config.update({
    accessKeyId: 'test',
    secretAccessKey: 'test',
    region: 'ap-northeast-1',
    endpoint: 'http://localstack_demo:4566'
});
  const sqs = new AWS.SQS({ apiVersion: "2012-11-05" });
  try {
    const messages = await sqs.receiveMessage({
      QueueUrl: queueUrl,
      MaxNumberOfMessages: 10,
      VisibilityTimeout: 30,
    }).promise();

    if (messages.Messages) {
      for (const message of messages.Messages) {
        console.log('Worker pull:',message.Body);
        await sqs.deleteMessage({
          QueueUrl: queueUrl,
          ReceiptHandle: message.ReceiptHandle,
        }).promise();
      }
    }
  } catch (error) {
    console.error(error);
  }
};

setInterval(pullData, 5000);