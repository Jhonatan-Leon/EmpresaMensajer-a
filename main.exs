# Script de Ejecución Principal para la Empresa de Mensajería
Code.require_file(Path.expand("datos.exs", __DIR__))
Code.require_file(Path.expand("validacion_datos.exs", __DIR__))
Code.require_file(Path.expand("servicios.exs", __DIR__))
Code.require_file(Path.expand("reportes.exs", __DIR__))
Code.require_file(Path.expand("util2.exs", __DIR__))
Code.require_file(Path.expand("interaccion.exs", __DIR__))

Interaccion.main()
