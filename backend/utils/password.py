"""
Utilidades para el manejo seguro de contraseñas con bcrypt.
Usa la librería bcrypt directamente (compatible con Python 3.14).
"""
import bcrypt


def hash_password(plain_password: str) -> str:
    """Devuelve el hash bcrypt de la contraseña en texto plano."""
    salt = bcrypt.gensalt()
    hashed = bcrypt.hashpw(plain_password.encode("utf-8"), salt)
    return hashed.decode("utf-8")


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Compara la contraseña en texto plano con el hash almacenado."""
    return bcrypt.checkpw(
        plain_password.encode("utf-8"),
        hashed_password.encode("utf-8"),
    )
