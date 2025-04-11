#!/usr/bin/env python3

from dotenv import load_dotenv
from pathlib import Path
from rich.console import Console
from rich.table import Table
import json
import logging
import requests

#
# Helper functions
#


def get_env_value(env_name, default_value=''):
    import os

    if env_name in os.environ:
        return os.environ.get(env_name)
    else:
        return default_value


def print_be_table(asset_list):
    table = Table(title="Asset List")

    table.add_column("ID")
    table.add_column("Asset Name")
    table.add_column("Parent Name")

    for asset in asset_list:
        table.add_row(
            f"{asset.get('id')}",
            f"{asset.get('name')}",
            f"{asset.get('parentName')}"
        )

    console = Console()
    console.print(table)

#
# Main code block
#


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

# Authenticate
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

# Fetch asset list
be_endpoint = f"{instance_url}/api/asset/businessEntities/advancedCollection"
req_headers = {
    "Content-Type": "application/json",
    "Authorization": f"Bearer {access_token}"
}

# Fetch the first 100 business entities
req_params = {
    "skip": 0,
    "take": "100"
}

try:
    logger.info("Requesting business_entity list")
    resp = requests.get(
        url=be_endpoint, params=req_params, headers=req_headers)
    resp.raise_for_status()
    resp_json = resp.json()
    logger.debug(f"Response metadata: {resp_json.get('_metadata')}")
except requests.exceptions.RequestException as e:
    logger.error(f"Failed to fetch asset data: {e}")
    exit(1)
except json.JSONDecodeError:
    logger.error("Failed to decode asset JSON response.")
    exit(1)

be_data = resp_json.get("data")
logger.debug("Response data: " + json.dumps(be_data))

# print_asset_table(be_list)
