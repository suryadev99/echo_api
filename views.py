from __future__ import annotations
from flask import Flask, request, jsonify, Response
from uuid import uuid4
from models import Endpoint, EndpointAttributes, EndpointResponse
from errors import EndpointError
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

endpoints: dict = {}
VALID_HTTP_VERBS = ['GET', 'POST', 'PATCH', 'PUT', 'DELETE', 'HEAD', 'OPTIONS', 'CONNECT', 'TRACE']


def hello_world() -> str:
    """Health check endpoint."""
    return 'Hello World !!'


def list_endpoints() -> Response:
    """List all created mock endpoints."""
    return jsonify({"data": [endpoint.__dict__ for endpoint in endpoints.values()]})


def create_endpoint() -> tuple:
    """to create new endpoints"""
    try:
        data = request.json.get('data', {}).get('attributes', {})
        input_validation(data)
        response_data = data.get('response', {})
        response = EndpointResponse(**response_data)
        attributes = EndpointAttributes(verb=data['verb'], path=data['path'], response=response)
        endpoint_id = str(uuid4())
        endpoint = Endpoint(type="endpoints", id=endpoint_id, attributes=attributes)
        endpoints[endpoint_id] = endpoint
        logger.info(f"Created endpoint with ID: {endpoint_id}")
        return jsonify({"data": endpoint.__dict__}), 201
    except EndpointError as e:
        logger.error(str(e))
        raise e


def update_endpoint(endpoint_id: str) -> Response:
    """ To update an existing endpoint"""
    try:
        if endpoint_id not in endpoints:
            raise EndpointError(f"Endpoint {endpoint_id} not found", 404)
        data = request.json.get('data', {}).get('attributes', {})
        input_validation(data)
        response_data = data.get('response', {})
        response = EndpointResponse(**response_data)
        attributes = EndpointAttributes(verb=data['verb'], path=data['path'], response=response)
        updated_endpoint = Endpoint(type="endpoints", id=endpoint_id, attributes=attributes)
        endpoints[endpoint_id] = updated_endpoint
        logger.info(f"Updated endpoint with ID: {endpoint_id}")
        return jsonify({"data": updated_endpoint.__dict__})
    except EndpointError as e:
        logger.error(str(e))
        raise e


def delete_endpoint(endpoint_id: str) -> tuple:
    """ To delete an endpoint"""
    try:
        if endpoint_id not in endpoints:
            raise EndpointError(f"Endpoint {endpoint_id} not found", 404)
        del endpoints[endpoint_id]
        logger.info(f"Deleted endpoint with ID: {endpoint_id}")
        return '', 204
    except EndpointError as e:
        logger.error(str(e))
        raise e


def serve_endpoint(path: str) -> tuple:
    """ To serve an endpoint"""
    try:
        for endpoint in endpoints.values():
            if endpoint.attributes.path == '/' + path and endpoint.attributes.verb == request.method:
                response_data = endpoint.attributes.response
                return response_data.body, response_data.code, response_data.headers
        raise EndpointError(f"Endpoint {request.method} {path} not found", 404)
    except EndpointError as e:
        logger.error(str(e))
        raise e


def input_validation(data) -> None:
    """ Input validation steps"""
    if not all([data.get('verb'), data.get('path'), data.get('response')]):
        raise EndpointError("Incomplete input", 400)
    if data.get('verb') not in VALID_HTTP_VERBS:
        raise EndpointError("Invalid HTTP verb", 400)
    if not isinstance(data['response'].get('code'), int):
        raise EndpointError("Invalid response code", 400)
    if data['response'].get('headers') and not isinstance(data['response']['headers'], dict):
        raise EndpointError("Headers must be a dictionary", 400)


def initialize_routes(app: Flask) -> None:
    """ Initialisation of all the Api's"""
    app.add_url_rule('/', 'hello_world', hello_world)
    app.add_url_rule('/endpoints', 'list_endpoints', list_endpoints, methods=['GET'])
    app.add_url_rule('/endpoints', 'create_endpoint', create_endpoint, methods=['POST'])
    app.add_url_rule('/endpoints/<endpoint_id>', 'update_endpoint', update_endpoint, methods=['PATCH'])
    app.add_url_rule('/endpoints/<endpoint_id>', 'delete_endpoint', delete_endpoint, methods=['DELETE'])
    app.add_url_rule('/<path:path>', 'serve_endpoint', serve_endpoint, methods=VALID_HTTP_VERBS)
