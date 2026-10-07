"""
Registro de las implementaciones de los contratos.

El servicio dueño registra su implementación en su `router.py`, que
`main.py` importa al arrancar:

    # services/catalog/router.py
    register_catalog(CatalogProvider())

Los consumidores la reciben por inyección, sin saber quién la implementa:

    def add_favorite(..., catalog: CatalogContract = Depends(get_catalog)): ...

En las pruebas se reemplaza sin tocar el registro:

    app.dependency_overrides[get_catalog] = lambda: FakeCatalog()
"""
from typing import TypeVar, cast

from contracts.catalog import CatalogContract
from contracts.identity import IdentityContract

C = TypeVar("C")

_implementations: dict[type, object] = {}


class ContractNotRegisteredError(RuntimeError):
    """Se pidió un contrato que ningún servicio ha registrado."""


def _register(contract: type[C], impl: C) -> None:
    # Con Protocols `runtime_checkable`, isinstance comprueba que estén
    # todos los métodos (no sus firmas).
    if not isinstance(impl, contract):
        raise TypeError(f"{type(impl).__name__} no implementa {contract.__name__}")
    _implementations[contract] = impl


def _resolve(contract: type[C]) -> C:
    try:
        return cast(C, _implementations[contract])
    except KeyError:
        raise ContractNotRegisteredError(
            f"Ningún servicio ha registrado una implementación de {contract.__name__}"
        ) from None


def register_catalog(impl: CatalogContract) -> None:
    """Registra la implementación de `CatalogContract`; reemplaza la anterior."""
    _register(CatalogContract, impl)


def get_catalog() -> CatalogContract:
    """Dependencia: la implementación registrada de `CatalogContract`."""
    return _resolve(CatalogContract)


def register_identity(impl: IdentityContract) -> None:
    """Registra la implementación de `IdentityContract`; reemplaza la anterior."""
    _register(IdentityContract, impl)


def get_identity() -> IdentityContract:
    """Dependencia: la implementación registrada de `IdentityContract`."""
    return _resolve(IdentityContract)


def reset() -> None:
    """Olvida todas las implementaciones registradas (solo para pruebas)."""
    _implementations.clear()
