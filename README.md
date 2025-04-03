# Introduction

This is a repository of API integration examples for Hyperview. The hope is that Hyperview users would find them useful.

# Prerequisites

1. A Hyperview instance.
2. API client with the appropriate permissions. API Clients can be created by a Hyperview Administrator.

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

This code has been tested with Python 3.11.2 on Debian 12. 

1. Change directory into python folder

```console
cd python
```

2. Initialize and activate virtual environment

```console
python -m venv .hv_env
source .hv_env/bin/activate
```

3. Create settings

```console
cp .env.example .env
```

4. Edit .env file with your favorite editor

5. Install requirements

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

Please review the API documentation and update the code to suite your needs.

# Contribution

Contributions are welcome.

