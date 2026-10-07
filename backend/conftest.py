"""
Configuración de pytest común a todas las pruebas del backend.

Se carga antes que cualquier `conftest.py` de subcarpetas y antes de
importar `config`, así que las pruebas no dependen de tener un `.env`.
"""
import os

os.environ.setdefault("JWT_SECRET_KEY", "clave-solo-para-pruebas")
