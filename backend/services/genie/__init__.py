"""
Servicio Genie: el "Genio de los Antojos", que recomienda restaurantes.

El proveedor de IA es intercambiable (`providers.AIProvider`): Gemini si hay
API key y, si no la hay o falla, recomendación por palabras clave. Los
restaurantes se piden a Catalog por su contrato.
"""
