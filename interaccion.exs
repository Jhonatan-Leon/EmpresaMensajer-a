
defmodule Interaccion do

# Integrantes:
# - Ruben Steven Sanchez
# - Jhonatan Cardona
# - Diana Valenciadefmodule Interaccion do
  @moduledoc """
  Módulo de interacción con el usuario del programa de liquidación semanal.

  Se encarga de:
  - solicitar un servicio adicional, interpretarlo y validarlo;
  - coordinar la validación, los reportes y el comprobante;
  - solicitar el código de un repartidor y mostrar su comprobante de pago.

  Dependencias (módulos):
  - Datos.repartidores/0, Datos.zonas/0, Datos.servicios/0
  - Validacion.validar_servicio/3 y Validacion.separar_servicios/3
  - Reportes.generar_todos/4
  - Servicios.comprobante/2
  - Util2 (entrada y salida)
  """

  @mensaje_servicio "Ingrese un servicio adicional\n(repartidor;zona;dia;kilometros;retraso)\no Enter para omitir: "
  @mensaje_codigo "\nIngrese el código del repartidor para ver su comprobante: "



  @doc """
  Punto de entrada del programa.

  1. Carga los datos.
  2. Solicita un servicio adicional.
  3. Valida todos los servicios y separa válidos de rechazados.
  4. Imprime los reportes R1 a R8.
  5. Solicita el código de un repartidor y muestra su comprobante.
  """
  def main do
    repartidores = Datos.repartidores()
    zonas = Datos.zonas()
    servicios = Datos.servicios()

    adicionales = solicitar_servicio_adicional(repartidores, zonas)

    {validos, rechazados} =
      Validacion.separar_servicios(repartidores, zonas, servicios ++ adicionales)

    Reportes.generar_todos(repartidores, zonas, validos, rechazados)

    solicitar_comprobante(repartidores, validos)
  end


  @doc """
  Solicita un servicio adicional, informa al usuario el resultado y retorna
  la lista de servicios que se deben incorporar (vacía o con un elemento).
  """
  def solicitar_servicio_adicional(repartidores, zonas) do
    resultado =
      @mensaje_servicio
      |> Util2.ingresar(:texto)
      |> evaluar_entrada(repartidores, zonas)

    informar_resultado(resultado)
    servicios_para_agregar(resultado)
  end


  def interpretar_servicio(entrada) do
    entrada
    |> String.split(";")
    |> Enum.map(&String.trim/1)
    |> construir_servicio()
  end

  defp construir_servicio([repartidor, zona, dia, kilometros, retraso]) do
    with {:ok, dia} <- convertir_entero(dia),
         {:ok, kilometros} <- convertir_numero(kilometros),
         {:ok, retraso} <- convertir_numero(retraso) do
      {:ok,
       %{
         repartidor: repartidor,
         zona: zona,
         dia: dia,
         kilometros: kilometros,
         retraso: retraso
       }}
    end
  end

  defp construir_servicio(_campos), do: {:error, :formato_invalido}

  defp convertir_entero(texto) do
    case Integer.parse(texto) do
      {numero, ""} -> {:ok, numero}
      _ -> {:error, :formato_invalido}
    end
  end

  defp convertir_numero(texto) do
    case Float.parse(texto) do
      {numero, ""} -> {:ok, numero}
      _ -> {:error, :formato_invalido}
    end
  end

  defp evaluar_entrada("", _repartidores, _zonas), do: :omitido

  defp evaluar_entrada(entrada, repartidores, zonas) do
    with {:ok, servicio} <- interpretar_servicio(entrada),
         {:ok, servicio} <- Validacion.validar_servicio(servicio, repartidores, zonas) do
      {:agregado, servicio}
    end
  end

  defp servicios_para_agregar({:agregado, servicio}), do: [servicio]
  defp servicios_para_agregar(_otro_resultado), do: []

  defp informar_resultado(:omitido) do
    Util2.mostrar("No se ingresó ningún servicio adicional.\n", :mensaje)
  end

  defp informar_resultado({:agregado, servicio}) do
    Util2.mostrar(
      "Servicio agregado: #{servicio.repartidor}, zona #{servicio.zona}, día #{servicio.dia}, " <>
        "#{servicio.kilometros} km, retraso #{servicio.retraso} min.\n",
      :mensaje
    )
  end

  defp informar_resultado({:error, :formato_invalido}) do
    Util2.mostrar(
      "Servicio rechazado por formato. Use: repartidor;zona;dia;kilometros;retraso\n",
      :error
    )
  end

  defp informar_resultado({:error, motivo}) do
    Util2.mostrar("Servicio rechazado por la regla de validación: #{motivo}\n", :error)
  end


  def solicitar_comprobante(repartidores, servicios_validos) do
    @mensaje_codigo
    |> Util2.ingresar(:texto)
    |> buscar_repartidor(repartidores)
    |> mostrar_comprobante(servicios_validos)
  end

  defp buscar_repartidor(codigo, repartidores) do
    case Enum.find(repartidores, fn repartidor -> repartidor.codigo == codigo end) do
      nil -> {:error, "No existe ningún repartidor con el código \"#{codigo}\"."}
      repartidor -> {:ok, repartidor}
    end
  end

  defp mostrar_comprobante({:ok, repartidor}, servicios_validos) do
    repartidor
    |> Servicios.comprobante(servicios_validos)
    |> formatear_comprobante()
    |> Util2.mostrar(:mensaje)
  end

  defp mostrar_comprobante({:error, motivo}, _servicios_validos) do
    Util2.mostrar(motivo, :error)
  end

  defp formatear_comprobante(comprobante) do
    """

    ========== COMPROBANTE DE PAGO ==========
    Repartidor: #{comprobante.nombre} (#{comprobante.codigo})

    Detalle por día trabajado:
    #{formatear_detalle(comprobante.dias)}
    Suma de servicios:        #{pesos(comprobante.total_servicios)}
    Suma de bonificaciones:   #{pesos(comprobante.total_bonificaciones)}
    Descuento por alquiler:   #{pesos(comprobante.alquiler)}
    NETO A PAGAR:             #{pesos(comprobante.neto)}
    =========================================
    """
  end

  defp formatear_detalle([]), do: "  (sin servicios válidos en la semana)\n"

  defp formatear_detalle(dias) do
    dias
    |> Util2.convertir_coleccion_mensaje(&formatear_dia/1)
    |> Enum.reduce("", fn linea, acumulado-> acumulado <> linea end)
  end

  defp formatear_dia(dia) do
    "  Día #{dia.dia}: #{kilometros(dia.kilometros)} km | " <>
      "servicios #{pesos(dia.valor_servicios)} | " <>
      "bonificación #{pesos(dia.bonificacion)}\n"
  end

  defp pesos(valor), do: "$" <> :erlang.float_to_binary(valor / 1, decimals: 0)
  defp kilometros(valor), do: Float.round(valor / 1, 2)
end

Interaccion.main()
