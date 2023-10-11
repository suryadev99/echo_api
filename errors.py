from flask import jsonify


class EndpointError(Exception):
    """ Endpoint error definition"""
    def __init__(self, message, status_code):
        super().__init__(message)
        self.status_code = status_code


def handle_endpoint_error(error):
    response = jsonify({'error': str(error)})
    response.status_code = error.status_code
    return response


def not_found_error(error):
    return jsonify({"error": "Not found"}), 404


def bad_request_error(error):
    return jsonify({"error": "Bad request"}), 400


def unauthorized_error(error):
    return jsonify({"error": "Unauthorized"}), 401
