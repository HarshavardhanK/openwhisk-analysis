#!/usr/bin/env python3
"""OpenWhisk Action Proxy for TensorFlow Runtime"""

import os
import sys
import json
import subprocess
import codecs
import flask
from gevent.pywsgi import WSGIServer
import io

class ActionRunner:
    def __init__(self):
        self.code = None
        self.env = {}
        self.initialized = False

    def init(self, message):
        """Initialize with the action code"""
        if message and 'value' in message:
            # If code is provided, save it
            if 'code' in message['value']:
                self.code = message['value']['code']
                with open('/action/exec', 'w') as f:
                    f.write(self.code)
                    os.chmod('/action/exec', 0o755)

            # If binary is provided, decode and save it
            elif 'binary' in message['value']:
                decoded = codecs.decode(message['value']['binary'].encode(), 'base64')
                with open('/action/exec', 'wb') as f:
                    f.write(decoded)
                    os.chmod('/action/exec', 0o755)

            # Set environment variables
            if 'env' in message['value']:
                self.env = message['value']['env']
                for k, v in self.env.items():
                    os.environ[k] = v

        elif os.path.exists('/action/exec'):
            # If no code provided but exec exists, we're using a pre-built image
            self.initialized = True
            return {'OK': True}
        else:
            return {'error': 'No action code or executable found.'}

        # Try running the action to check if it's valid
        try:
            process = subprocess.Popen(['/action/exec', 'verify'], 
                                       stdout=subprocess.PIPE,
                                       stderr=subprocess.PIPE)
            (o, e) = process.communicate()
            if process.returncode != 0:
                return {'error': 'Failed to initialize action: ' + e.decode('utf-8')}
            else:
                self.initialized = True
                return {'OK': True}
        except Exception as e:
            return {'error': 'Failed to initialize action: ' + str(e)}

    def run(self, message):
        """Run the action with the provided input"""
        if not self.initialized:
            return {'error': 'Action not initialized or failed initialization.'}

        # Create input for the action
        input_str = json.dumps(message)
        
        try:
            # Invoke the action script
            p = subprocess.Popen(['/action/exec'],
                                 stdin=subprocess.PIPE,
                                 stdout=subprocess.PIPE,
                                 stderr=subprocess.PIPE)
            (o, e) = p.communicate(input=input_str.encode())
            
            if o:
                try:
                    # Try to parse the output as JSON
                    return json.loads(o.decode('utf-8'))
                except Exception as e:
                    # If not JSON, return plain output
                    return {'result': o.decode('utf-8')}
            else:
                # Handle error case
                return {'error': 'Action returned no result: ' + e.decode('utf-8')}
        except Exception as e:
            return {'error': 'Failed to run action: ' + str(e)}

# Create Flask app
app = flask.Flask(__name__)
runner = ActionRunner()

@app.route('/init', methods=['POST'])
def init():
    message = flask.request.get_json(force=True, silent=True)
    result = runner.init(message)
    return flask.jsonify(result)

@app.route('/run', methods=['POST'])
def run():
    message = flask.request.get_json(force=True, silent=True)
    result = runner.run(message)
    return flask.jsonify(result)

# Health endpoint
@app.route('/ping', methods=['GET'])
def ping():
    return flask.jsonify({'status': 'OK'})

def main():
    port = int(os.getenv('FLASK_PORT', 8080))
    server = WSGIServer(('0.0.0.0', port), app)
    server.serve_forever()

if __name__ == '__main__':
    main()