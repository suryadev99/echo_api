from dataclasses import dataclass
from typing import Dict, Optional


@dataclass
class EndpointResponse:
    """
    class endpoint response
    """
    code: int
    headers: Dict[str, str]
    body: Optional[str]


@dataclass
class EndpointAttributes:
    """
    class endpoint attributes
    """
    verb: str
    path: str
    response: EndpointResponse


@dataclass
class Endpoint:
    """
    endpoint class
    """
    type: str
    id: str
    attributes: EndpointAttributes

