# OpenWhisk Sample Actions

This directory contains sample OpenWhisk actions that you can deploy to your OpenWhisk instance.

## Available Actions

- `hello.js` - A simple "Hello, World\!" JavaScript action
- `hello.py` - A simple "Hello, World\!" Python action

## Deploying Actions

After your OpenWhisk deployment is up and running, you can deploy these actions using the OpenWhisk CLI (`wsk`):

```bash
# Deploy JavaScript action
wsk -i action create hello-js actions/hello.js

# Deploy Python action
wsk -i action create hello-py actions/hello.py

# Invoke an action
wsk -i action invoke hello-js --result

# List all actions
wsk -i action list
```

## Creating Your Own Actions

Add your custom actions to this directory to keep them organized. OpenWhisk supports actions in multiple languages including:

- JavaScript
- Python
- Java
- Go
- PHP
- Ruby
- Swift
- .NET
