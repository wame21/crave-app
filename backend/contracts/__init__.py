"""
Contratos entre servicios.

Un servicio solo accede a los datos de otro a través de estas interfaces,
nunca leyendo ni escribiendo sus tablas. Cada contrato define un DTO y un
`Protocol`; el servicio dueño de los datos lo implementa y lo registra en
`contracts.registry`, y los consumidores lo reciben con `Depends`.
"""
