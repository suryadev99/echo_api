from dataclasses import dataclass
from typing import Dict, Optional


@dataclass
class EndpointResponse:
    code: int
    headers: Dict[str, str]
    body: Optional[str]


@dataclass
class EndpointAttributes:
    verb: str
    path: str
    response: EndpointResponse


@dataclass
class Endpoint:
    type: str
    id: str
    attributes: EndpointAttributes

