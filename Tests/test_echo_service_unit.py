# import sys
# sys.path.append("C:/Users/surya.dev/PycharmProjects/EchoApi")
import pytest
from main import app
from views import endpoints

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client


def test_get_endpoints_empty(client):
    response = client.get('/endpoints')
    assert response.status_code == 200
    assert response.get_json() == {"data": []}


def test_create_endpoint(client):
    response = client.post(
        "/endpoints",
        follow_redirects=True,
        json={
            "data": {
                "type": "endpoints",
                "attributes": {
                    "verb": "GET",
                    "path": "/test",
                    "response": {
                        "code": 200,
                        "headers": {
                            "Content-Type": "application/json"
                        },
                        "body": {"message": "Test"}
                    }
                }
            }
        }
    )
    assert response.status_code == 201
    assert response.get_json()["data"]["attributes"]["path"] == "/test"


def test_list_endpoints_after_creation(client):
    response = client.get('/endpoints')
    assert response.status_code == 200
    assert len(response.get_json()["data"]) == 1


def test_access_created_endpoint(client):
    response = client.get('/test')
    assert response.status_code == 200
    assert response.get_json() == {"message": "Test"}


def test_update_endpoint(client):
    # Assuming you've a function to get the first endpoint's ID
    endpoint_id = list(endpoints.keys())[0]

    updated_data = {
        "data": {
            "type": "endpoints",
            "id": endpoint_id,
            "attributes": {
                "verb": "GET",
                "path": "/test",
                "response": {
                    "code": 200,
                    "headers": {
                        "Content-Type": "application/json"
                    },
                    "body": {"message": "Hello, everyone"}
                }
            }
        }
    }

    response = client.patch(f'/endpoints/{endpoint_id}', json=updated_data)
    assert response.status_code == 200
    assert endpoints[endpoint_id].attributes.response.body == {"message": "Hello, everyone"}


def test_delete_endpoint(client):
    endpoint_id = list(endpoints.keys())[0]
    response = client.delete(f'/endpoints/{endpoint_id}')
    assert response.status_code == 204
    assert endpoint_id not in endpoints


def test_404_for_nonexistent_endpoint(client):
    response = client.get('/nonexistent')
    assert response.status_code == 404


def test_integration_scenario(client):
    # Create a new mock endpoint
    post_response = client.post(
        "/endpoints",
        json={
            "data": {
                "type": "endpoints",
                "attributes": {
                    "verb": "GET",
                    "path": "/hello/first",
                    "response": {
                        "code": 200,
                        "headers": {
                            "Content-Type": "application/json"
                        },
                        "body": {"message": "Hello, world"}
                    }
                }
            }
        }
    )

    endpoint_id = post_response.get_json()["data"]["id"]
    assert post_response.status_code == 201

    # Access the created mock endpoint
    get_response = client.get("/hello/first")
    assert get_response.status_code == 200
    assert get_response.get_json()["message"] == "Hello, world"

    #only the fulll endpoint is present and no sub-endpoints
    get_response = client.get("/hello")
    assert get_response.status_code == 404

    # Delete the created mock endpoint
    delete_response = client.delete(f"/endpoints/{endpoint_id}")
    assert delete_response.status_code == 204

    # Ensure the endpoint is actually deleted
    get_response_after_delete = client.get("/hello/first")
    assert get_response_after_delete.status_code == 404

    post_response = client.post("/hello")
    assert post_response.status_code == 404


