#!/usr/bin/env python3

from datetime import datetime
from dotenv import load_dotenv
from pathlib import Path
from rich.console import Console
from rich.table import Table
import csv
import json
import logging
import requests
import sys

#
# Helper functions
#


def write_sensor_table_to_file(sensor_list):
    # Generate timestamped filename
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"output_{timestamp}.csv"

    header = ["assetId", "sensorId", "name", "timestamp", "value", "unit"]
    sensors = []

    for sensor in sensor_list:
        sensors.append({
            "assetId": sensor.get('assetId'),
            "sensorId": sensor.get('id'),
            "name": sensor.get('name'),
            "timestamp": sensor.get('lastValueUpdate'),
            "value": sensor.get('value'),
            "unit": sensor.get('unitString')
        })

    with open(filename, "w", newline="") as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=header)
        writer.writeheader()
        writer.writerows(sensors)

    print(f"Output file written to: {filename}")


def print_sensor_table(sensor_list):
    table = Table(title="Sensors")

    table.add_column("Asset ID")
    table.add_column("Sensor ID")
    table.add_column("Name")
    table.add_column("Timestamp")
    table.add_column("Value")
    table.add_column("Unit")

    for sensor in sensor_list:
        table.add_row(
            f"{sensor.get('assetId')}",
            f"{sensor.get('id')}",
            f"{sensor.get('name')}",
            f"{sensor.get('lastValueUpdate')}",
            f"{sensor.get('value')}",
            f"{sensor.get('unitString')}"
        )

    console = Console()
    console.print(table)


def get_env_value(env_name, default_value=''):
    import os

    if env_name in os.environ:
        return os.environ.get(env_name)
    else:
        return default_value


def get_sensors(asset_list, access_token, instance_url):
    sensors = []

    for asset_id in asset_list:
        asset_sensors = get_asset_sensors(asset_id, access_token, instance_url)
        sensors.extend(asset_sensors)

    return sensors


def get_asset_sensors(asset_id, access_token, instance_url):
    sensor_endpoint = f"{instance_url}/api/asset/sensors/{asset_id}"
    req_headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {access_token}"
    }

    try:
        logger.info("Requesting asset list")
        resp = requests.get(url=sensor_endpoint, headers=req_headers)
        resp.raise_for_status()
        sensor_list_json = resp.json()

        for sensor in sensor_list_json:
            sensor["assetId"] = asset_id

        return sensor_list_json
    except requests.exceptions.RequestException as e:
        logger.error(f"Failed to fetch sensor data: {e}")
        exit(1)
    except json.JSONDecodeError:
        logger.error("Failed to decode sensor JSON response.")
        exit(1)


def authenticate(client_id, client_secret, instance_url):
    auth_payload = {
        "grant_type": "client_credentials",
        "client_id": client_id,
        "client_secret": client_secret
    }

    token_endpoint = f"{instance_url}/connect/token"

    try:
        logger.info(f"Requesting access token from: {token_endpoint}")
        resp = requests.post(url=token_endpoint, data=auth_payload)
        resp.raise_for_status()  # Raise an exception if there are issues
        logger.info("Successfully authenticated")
        resp_json = resp.json()
        logger.debug(f"Response json: {resp_json}")
        access_token = resp_json.get("access_token")
        logger.debug(f"Access token: {access_token}")
    except requests.exceptions.RequestException as e:
        logger.error(f"Failed to authenticate: {e}")
        exit(1)
    except json.JSONDecodeError:
        logger.error("Failed to decode token JSON response.")
        exit(1)

    return access_token


def get_asset_list(input_file):
    with open(file=input_file, newline='', encoding='utf-8') as infile:
        reader = csv.DictReader(infile)
        rows = list(reader)

    asset_list = [row["AssetId"] for row in rows]
    return asset_list


#
# Main code block
#

if __name__ == "__main__":
    # Check if the .env configuration file exists
    env_path = Path("./.env")
    if not env_path.is_file():
        print(f"Error: .env file not found at {env_path}")
        exit(1)

    # Load .env configuration file
    load_dotenv()

    # Configure logging
    LOG_LEVEL = get_env_value("LOG_LEVEL", "ERROR").upper()

    if hasattr(logging, LOG_LEVEL):
        logging.basicConfig(level=LOG_LEVEL,
                            format="%(asctime)s - %(levelname)s - %(message)s")
        logger = logging.getLogger(__name__)
    else:
        print(
            f"Error: Unable to set LOG_LEVEL to {LOG_LEVEL}")
        exit(1)

    logger.info(f"Starting application with log level {LOG_LEVEL}")

    # Read client configuration
    client_id = get_env_value('CLIENT_ID')
    if client_id == '':
        logger.error("Client ID not set.")
        exit(1)

    client_secret = get_env_value('CLIENT_SECRET')
    if client_secret == '':
        logger.error("Client secret not set.")
        exit(1)

    instance_url = get_env_value('INSTANCE_URL')
    if instance_url == '':
        logger.error("Instance URL not set.")
        exit(1)

    # Check command arguments
    if len(sys.argv) != 2:
        print("Error: you must provide input filename.")
        print("Example: ./03_output_sensor_list_for_assets.py input_file.csv")
        print("Exiting.")
        exit(1)

    # Read input asset list
    input_file = sys.argv[1]
    logger.info(f"Input filename: {input_file}")

    # Authenticate
    access_token = authenticate(client_id, client_secret, instance_url)

    # Get list of asset IDs
    asset_list = get_asset_list(input_file)

    # Fetch sensor list and print
    sensor_list = get_sensors(asset_list, access_token, instance_url)
    print_sensor_table(sensor_list)
    write_sensor_table_to_file(sensor_list)
