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

```
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

This sets the execution policy to bypass for the current PowerShell session.

## Rust

- Configuration for Rust programs must be kept in toml config file under $HOME/.hyperview/hv_config.toml. Full example is included with the source.

# Contribution

Contributions are welcome.

