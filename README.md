# ProjectExpUser

<!-- local-development:start -->
## Desarrollo local

Consulta [RUNNING.md](RUNNING.md) para ubicar cada componente, abrirlo en su IDE, compilarlo y conocer las comprobaciones realizadas y los requisitos pendientes.
<!-- local-development:end -->

<!-- build-repairs-20261115:start -->
## Reparación y comprobación — 2026-11-15

- JFreeChart y JCommon se incluyeron con versiones fijadas y referencias relativas, POM y avisos del distribuidor.

Comprobado:

- Compila el proyecto Ant con JDK 24.

Comandos:

```powershell
.\build-local.ps1
.\build-local.ps1 -Target run
```

Alcance pendiente:

- La ejecución con datos requiere configurar la base del proyecto. No se validó el flujo completo de consultas.

<!-- build-repairs-20261115:end -->
