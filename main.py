from flask import Flask
from views import initialize_routes
from errors import not_found_error, bad_request_error, unauthorized_error, handle_endpoint_error, EndpointError
import logging

app = Flask(__name__)

# Register error handlers
app.register_error_handler(404, not_found_error)
app.register_error_handler(400, bad_request_error)
app.register_error_handler(401, unauthorized_error)
app.register_error_handler(EndpointError, handle_endpoint_error)

# Initialize routes
initialize_routes(app)

# Setting up logging
logging.basicConfig(level=logging.INFO)

if __name__ == "__main__":
    logging.info('Starting Flask application...')
    app.run(host="0.0.0.0")
