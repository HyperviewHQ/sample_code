# Introduction

This is a repository of API integration examples for Hyperview. The hope is that Hyperview users would find them useful.

# Prerequisites

1. A Hyperview instance.
2. API client with the appropriate permissions. API Clients can be created by a Hyperview Administrator.

Please review the API documentation and update the code to suite your needs.

# Languages

## PowerShell

- Scripts are tested with PowerShell 7.x.
- Configuration must be kept in a *conf* directory next to the script. Full examples are included with the source.
- Depending on your machine's OS and security policy you may need to to run:

```console
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

This sets the execution policy to bypass for the current PowerShell session.

## Python

Code has been tested with Python 3.11.2 on Debian 12. 

1. Change directory into Python folder

```console
cd python
```

2. Initialize and activate virtual environment

```console
python3 -m venv .hv_env
source .hv_env/bin/activate
```

3. Create settings and edit setting file

```console
cp .env.example .env

# Use your favorite editor to edit the .env file
vi .env
```

4. Install requirements

```console
pip install -r requirements.txt
```

5. Run example script(s). For example

```console
./01_query_assets_and_get_sensors.py
```

6. When you are done, deactivate the virtual environment

```console
deactivate
```

## Java

Code has been tested with OpenJDK 21 and Gradle 8.13.

1. Change directory into Java example folder

```console
cd java/list_assets_and_sensors 
```

2. Create settings and edit setting file

```console
cp app/assets/.env.example app/assets/.env

# Use your favorite editor to edit the .env file
vi app/assets/.env
```

3. Build and run the application

```console
gradle run
```

# Contribution

Contributions are welcome.

