# Integrantes:
# - Ruben Steven Sanchez
# - Jhonatan Cardona
# - Diana Valencia
#
Code.require_file(Path.expand("datos.exs", __DIR__))
Code.require_file(Path.expand("validacion_datos.exs", __DIR__))
Code.require_file(Path.expand("servicios.exs", __DIR__))

defmodule Investigacion do
  @moduledoc """
  Módulo de investigación:
  - combinar_km/2: Combina los kilómetros diarios de dos empresas con Map.merge/3.
  - ejemplo_prueba/0: Ejecuta y muestra los resultados con los datos reales del proyecto.
  """
  @doc """
  Combina dos mapas dia => kilometros. Si un día está en ambos mapas,
  suma los kilómetros recorridos por ambas empresas.
  """
  def combinar_km(km_propios, empresa_aliada) do
    Map.merge(km_propios, empresa_aliada, fn _dia, propios, aliados -> propios + aliados end)
  end

  @doc """
  Ordenar una lista de mapas según las opciones recibidas en los argumentos

  Opciones
  - :campo -> campor por el caul se va a ordenar
  - :orden -> :asc o :desc
  - :cantidad -> cantidad de elementos que se desea ordenar
  """

  def rankings(colecciones, opciones \\ []) do
    campo = Keyword.get(opciones, :campo, :neto)
    orden = Keyword.get(opciones, :orden, :desc)
    cantidad = Keyword.get(opciones, :cantidad)

    datos_ordenados =
      Enum.sort_by(colecciones, fn coleccion -> coleccion[campo] end, orden)

    if cantidad == nil do
      datos_ordenados
    else
      Enum.take(datos_ordenados, cantidad)
    end
  end

  @doc """
  Ejecuta una prueba completa demostrando:
  - La combinación de kilómetros con Map.merge/2 vs Map.merge/3.
  - Demostración de pruebas cde la función rakings con diferentes pruebas de entrada
  """
  def ejemplo_prueba do
    # Cargar datos
    repartidores = Datos.repartidores()
    zonas = Datos.zonas()
    servicios = Datos.servicios()
    # Sacara datos de la estructura de repartidores validos.
    %{aprobados: validos} = Validacion.separar_servicios(repartidores, zonas, servicios)

    liquidacion_repartidores = Servicios.liquidacion(repartidores, validos)

    # Tomamos los mapas de los repartidores validos y sus servicios
    km_propios =
      1..6
      |> Map.new(fn dia -> {dia, 0} end)
      |> Map.merge(
        validos
        |> Enum.group_by(fn s -> s.dia end, fn s -> s.kilometros end)
        |> Map.new(fn {dia, kms} -> {dia, Enum.sum(kms)} end)
      )

    # Datos de la empresa aliada
    empresa_aliada = %{
      1 => 580.5,
      2 => 430,
      3 => 510,
      5 => 625,
      7 => 180
    }

    IO.puts("Qué produce combinar_km/2 con Map.merge/3?:")
    IO.puts("\n Datos utilizados: ")
    IO.inspect(km_propios)
    IO.inspect(empresa_aliada)
    IO.puts("\nResultado con Map.merge/2: ")
    IO.inspect(Map.merge(km_propios, empresa_aliada))
    IO.puts("\nResultado con Map.merge/3: ")
    IO.inspect(combinar_km(km_propios, empresa_aliada))

    IO.puts("---------------------")
    IO.puts(" -- Demostración de la función rankings --")
    IO.puts("\n Datos utilizados: ")
    IO.inspect(liquidacion_repartidores)
    IO.puts("\n Resultados con rankings sin opciones (por defecto): ")
    IO.inspect(rankings(liquidacion_repartidores))
    IO.puts("\n Resultados con rankings (con opción :kilometros): ")
    IO.inspect(rankings(liquidacion_repartidores, campo: :kilometros))
    IO.puts("\n Resultados con rankings (con opciones :asc y :cantidad 2): ")
    IO.inspect(rankings(liquidacion_repartidores, orden: :asc, cantidad: 2))
  end
end

Investigacion.ejemplo_prueba()
