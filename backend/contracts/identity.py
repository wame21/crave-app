"""
Contrato del servicio Identity: lo que los demás servicios pueden pedirle
sobre usuarios. Identity es el único dueño de esos datos; nadie más lee ni
escribe el esquema `identity`.

Mismas reglas comunes que `contracts.catalog`: métodos síncronos y
atómicos, `ValueError` ante precondiciones incumplidas y excepciones de
`core.errors` para las situaciones de negocio.
"""
from typing import Optional, Protocol, runtime_checkable

from pydantic import BaseModel, ConfigDict


class PublicProfile(BaseModel):
    """Datos públicos de un usuario, los que se muestran junto a sus reseñas."""

    model_config = ConfigDict(frozen=True)

    id_user: int
    profile_name: str
    photo_url: Optional[str] = None


@runtime_checkable
class IdentityContract(Protocol):
    def get_public_profiles(self, ids: list[int]) -> dict[int, PublicProfile]:
        """
        Perfiles públicos de varios usuarios en una sola llamada (evita N+1).

        Precondiciones: ninguna; `ids` puede estar vacía o tener repetidos.
        Postcondiciones: un elemento por cada id que existe, con clave igual
            a `id_user`. Los ids inexistentes se omiten. Con `ids` vacía
            devuelve {}. Nunca expone email, rol ni contraseña.
        Errores: ninguno.
        """
