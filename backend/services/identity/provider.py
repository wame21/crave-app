"""
Implementación de `IdentityContract` sobre el esquema `identity`.
"""
from contracts.identity import PublicProfile
from database import connection
from services.identity.repository import UserRepository


class IdentityProvider:
    """Lo que Identity ofrece a los demás servicios (ver `contracts.identity`)."""

    def get_public_profiles(self, ids: list[int]) -> dict[int, PublicProfile]:
        unique_ids = list(dict.fromkeys(ids))
        if not unique_ids:
            return {}
        with connection() as conn:
            rows = UserRepository(conn).get_public_profiles(unique_ids)
        return {row["id_user"]: PublicProfile.model_validate(row) for row in rows}
