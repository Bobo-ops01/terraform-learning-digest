import os

import boto3

s3 = boto3.client("s3")
sns = boto3.client("sns")
bedrock = boto3.client("bedrock-runtime")

BUCKET = os.environ["BUCKET"]
NOTES_KEY = os.environ["NOTES_KEY"]
MODEL_ID = os.environ["MODEL_ID"]
TOPIC_ARN = os.environ["TOPIC_ARN"]
MAX_CHARS = 20000

PROMPT = (
    "You are helping someone review what they learned this week. "
    "Using ONLY the notes below, write a short weekly digest in plain text "
    "(no markdown). Include: a 2-3 sentence summary, the key takeaways as "
    "short lines starting with a dash, and two suggested things to review "
    "or practice next week. Do not invent facts that are not in the notes."
    "\n\nNOTES:\n"
)


def lambda_handler(event, context):
    body = s3.get_object(Bucket=BUCKET, Key=NOTES_KEY)["Body"].read()
    notes = body.decode("utf-8")[:MAX_CHARS]
    print(f"Read {len(notes)} characters of notes")

    response = bedrock.converse(
        modelId=MODEL_ID,
        messages=[{"role": "user", "content": [{"text": PROMPT + notes}]}],
        inferenceConfig={"maxTokens": 800, "temperature": 0.3},
    )
    digest = response["output"]["message"]["content"][0]["text"]

    sns.publish(
        TopicArn=TOPIC_ARN,
        Subject="Your weekly learning digest",
        Message=digest,
    )
    print("Digest published")
    return {"status": "sent"}
