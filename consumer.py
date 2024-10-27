"""This module puts the data from the kiosk interactions into the remote database"""

from confluent_kafka import Consumer, KafkaError, Message
from dotenv import dotenv_values
from pipeline.pipeline import get_rating_id, get_request_id
import json
import logging
import argparse
import datetime
import psycopg2
import psycopg2.extras


TOPIC = "lmnh"


def convert(date_time_str: str) -> datetime.datetime:
    """Used to convert a str into a datetime"""
    format = '%Y-%m-%dT%H:%M:%S.%f%z'
    date_time = datetime.datetime.strptime(date_time_str, format)
    return date_time


def configuration(config):
    """Sets up the connection to kafka"""
    kafka_config = {
        'bootstrap.servers': config['BOOTSTRAP_SERVERS'],
        'security.protocol': 'SASL_SSL',
        'sasl.mechanisms': 'PLAIN',
        'sasl.username': config['USERNAME'],
        'sasl.password': config["PASSWORD"],
        'group.id': '1',
        'auto.offset.reset': 'earliest'
    }
    consumer = Consumer(kafka_config)
    return consumer


def configure_logging() -> logging.Logger:
    """This function configures the logging using the command line arguments"""
    parser = argparse.ArgumentParser()
    parser.add_argument('--log-to-file', default=False,
                        action=argparse.BooleanOptionalAction)
    args = parser.parse_args()
    logger = logging.getLogger(
        "file") if args.log_to_file else logging.getLogger()
    if args.log_to_file:
        logging.basicConfig(filename='invalid_messages.txt',
                            encoding='utf-8', level=logging.INFO)
    else:
        logger.setLevel(logging.INFO)
    return logger


def check_message(message, error_logger) -> bool:
    """This function checks whether a message is valid"""
    message_errors = 0
    if message.get("site") not in {"0", "1", "2", "3", "4", "5"}:
        message["invalid"] = "invalid site given"
        error_logger.info(message)
        message_errors += 1
    if message.get("val") not in {-1, 0, 1, 2, 3, 4}:
        message["invalid"] = "invalid val given"
        error_logger.info(message)
        message_errors += 1
    if message.get("val") == -1 and message.get("type") not in {0, 1}:
        message["invalid"] = "invalid type given"
        error_logger.info(message)
        message_errors += 1
    time = message.get("at")
    if time:
        time_datetime = convert(time)
        if time_datetime.time() < datetime.time(8, 45) or time_datetime.time() > datetime.time(18, 15):
            message["invalid"] = "interaction outside of hours"
            error_logger.info(message)
            message_errors += 1
    else:
        message_errors += 1
    return message_errors == 0


def setup_db_connection(config) -> tuple[psycopg2.extensions.connection, psycopg2.extras.RealDictCursor]:
    """Creates a connection and a cursor that are linked to the remote database"""
    conn = psycopg2.connect(
        user=config["DATABASE_USERNAME"],
        password=config["DATABASE_PASSWORD"],
        host=config["DATABASE_IP"],
        port=config["DATABASE_PORT"],
        database=config["DATABASE_NAME"]
    )
    cursor = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    return conn, cursor


def import_message_into_db(message: str, cursor: psycopg2.extras.RealDictCursor, conn: psycopg2.extensions.connection) -> None:
    """Inserts the message into the relevant database table"""
    val = int(message.get("val"))
    if val >= 0:
        rating_id = get_rating_id(cursor, val)
        cursor.execute(
            f"""INSERT INTO rating_interaction (exhibition_id, rating_id, event_at)
            VALUES ({int(message.get("site")) + 1},{rating_id},'{message.get("at")}')""")
        conn.commit()
    else:
        request_id = get_request_id(cursor, message.get("type"))
        cursor.execute(
            f"""INSERT INTO request_interaction (exhibition_id, request_id, event_at)
            VALUES ({int(message.get("site")) + 1},{request_id},'{message.get("at")}')""")
        conn.commit()


def handling_message(msg: Message, message_count: int, error_logger) -> None:
    """Logs 1 in 'log_every' messages and calls import_message_into_db on valid messages"""
    log_every = 250
    if message_count % log_every == 0:
        error_logger.info(f"""Consumed event from topic {
            TOPIC}: {msg.value()}""")
    if msg.error():
        if msg.error().code() == KafkaError._PARTITION_EOF:
            # End of partition event
            error_logger.info('%% %s [%d] reached end at offset %d\n' %
                              (msg.topic(), msg.partition(), msg.offset()))
        elif msg.error():
            raise Exception(msg.error())
    else:
        message = json.loads(msg.value().decode())
        if check_message(message, error_logger):
            import_message_into_db(message, cursor, conn)


def consume_historical_messages(consumer: Consumer, max_messages: int, error_logger) -> None:
    """Consume a fixed number of historical messages."""
    message_count = 0
    while message_count < max_messages:
        msg = consumer.poll(timeout=1.0)
        if msg is None:
            continue
        handling_message(msg, message_count, error_logger)
        message_count += 1

    # Commit offsets after consuming the initial set of messages
    consumer.commit()
    logging.info(f"Committed offsets after consuming {max_messages} messages.")


if __name__ == "__main__":
    config = dotenv_values(".env")
    consumer = configuration(config)
    consumer.subscribe([TOPIC])

    conn, cursor = setup_db_connection(config)

    error_logger = configure_logging()

    message_counter = 10000
    consume_historical_messages(consumer, message_counter, error_logger)
    message_count = 0
    while True:
        msg = consumer.poll(timeout=1.0)
        if msg is None:
            continue
        handling_message(msg, message_counter, error_logger)
        message_counter -= 1
        if message_log_counter == 0:
            message_log_counter = 20
