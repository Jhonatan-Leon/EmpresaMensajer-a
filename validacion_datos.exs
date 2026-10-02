# Integrantes:
# - Ruben Steven Sanchez
# - Jhonatan Cardona
# - Diana Valencia
Code.require_file(Path.expand("datos.exs", __DIR__))

defmodule Validacion do
  @retraso_min -30
  @retraso_max 180
  @dias_min 1
  @dias_max 6
  @kilometros_min 0
  @kilometros_max 45

  @doc """
  comprobar_servicios la función se encarga de coordinar la separación de los servicios aprobados y no_aprobados devolvio una tupla
  de los datos aprobados y no_aprobados estructurados.  Para la manipulación y aplicación de la lógica

  #Parametros:
  - repartidores: lista de mapas con los atributos de los repartidores
  - zonas: lista de mapas con los atributos de las zonas
  - servicios: lista de mapas con los atributos de los servicios

  #Devuelve:
  - Una tupla con los datos estructurados, separados en servicios aprobados y no_aprobados

  """

  def comprobar_servicios(repartidores, zonas, servicios) do
    servicios_separados = separar_servicios(repartidores, zonas, servicios)

    aprobados = Datos.estructurar_datos(repartidores, zonas, servicios_separados.aprobados)

    {aprobados, servicios_separados.no_aprobados}
  end

  @doc """
  separar_servicios donde clasifica los servicios en: aprobados y no_aprobados

  # Parametros:
  - repartidores: lista de mapas con los atributos de los repartidores
  - zonas: lista de mapas con los atributos de las zonas
  - servicios: lista de mapas con los atributos de los servicios

  #Devuelve:
  - Una tupla con los datos estructurados, separados en servicios aprobados y no_aprobados

  """

  def separar_servicios(repartidores, zonas, servicios) do
    nuevo_mapa =
      Enum.reduce(servicios, %{aprobados: [], no_aprobados: []}, fn servicio, acc ->
        with {:ok, servicio_valido} <- validar_servicio(repartidores, zonas, servicio) do
          Map.update!(acc, :aprobados, fn lista -> [servicio_valido | lista] end)
        else
          {:error, motivo} ->
            rechazados = %{servicio: servicio, motivo: motivo}
            Map.update!(acc, :no_aprobados, fn lista -> [rechazados | lista] end)
        end
      end)

    %{
      aprobados: Enum.reverse(nuevo_mapa.aprobados),
      no_aprobados: Enum.reverse(nuevo_mapa.no_aprobados)
    }
  end

  @doc """
    validar_servicios usa la colección de datos y verifica que los datos de cada lista cumpla
    con los requerimientos necesarios para ser un servicios valido.

    parametro:
    - repartidores: llega un mapa con los atributos del repartidor
    - zonas:zonas: llega un mapa con los atributos de las zonas
    - servicios: llega un mapa con los atributos de los servicios

    #Devuelve:
    - :ok si los datos son validos
    - {:error, motivo} si los datos no son validos

  """
  def validar_servicio(servicio, repartidores, zonas) when is_map(servicio) and is_list(repartidores) do
    validar_servicio(repartidores, zonas, servicio)
  end

  def validar_servicio(repartidores, zonas, servicios) do
    with :ok <- existe_repartidor?(repartidores, servicios),
         :ok <- zona_existe?(servicios, zonas),
         :ok <- dia_servicio(servicios),
         :ok <- kilometros_permitidos(servicios),
         :ok <- retraso_servicio(servicios) do
      {:ok, servicios}
    end
  end

  @doc """
  existencia_repartidor comprueba la existencia de un repartidor comparando con la id
  de los servicios

  parametro:
  - repartidores: Llega un mapa con los atributos del repartidor
  - servicios: Llega un mapa con los atributos de los servicios

  #Devuelve:
  - :ok si los datos son validos
  - {:error, motivo} si los datos no son validos

  """

  def existe_repartidor?(repartidores, servicios) do
    case Map.get(servicios, :repartidor) do
      nil ->
        {:error, :repartidor_desconocido}

      codigo ->
        if Enum.any?(repartidores, fn repartidor -> repartidor.codigo == codigo end) do
          :ok
        else
          {:error, :repartidor_desconocido}
        end
    end
  end

  @doc """
  zona_existe comprueba la existencia de una zona comparando con la id
  de los servicios

  parametro:
  - servicios: Llega un mapa con los atributos de los servicios
  - zonas: Llega un mapa con los atributos de las zonas

  #Devuelve:
  - :ok si los datos son validos
  - {:error, motivo} si los datos no son validos

  """

  def zona_existe?(servicios, zonas) do
    case Map.get(servicios, :zona) do
      nil ->
        {:error, :zona_desconocida}

      id ->
        if Enum.any?(zonas, fn zona -> zona.id == id end) do
          :ok
        else
          {:error, :zona_desconocida}
        end
    end
  end

  @doc """
  dia_servicio comprueba que el dia del servicio sea valido

  parametro:
  - servicio: llega un mapa con los atributos del servicio
  - servicios.dia: número entero con los dia de servicio
  - @dias: número entero con el rango de los días permitidos

  #Devuelve:
  - :ok si los datos son validos
  - {:error, motivo} si los datos no son validos

  """

  def dia_servicio(servicios) do
    case Map.get(servicios, :dia) do
      nil ->
        {:error, :dia_invalido}

      dia ->
        if dia in @dias_min..@dias_max do
          :ok
        else
          {:error, :dia_invalido}
        end
    end
  end

  @doc """
  kilometros_permitidos comprueba que cumpla los rangos establecidos

  parametro:
  - servicio: Colección de datos con los atributos del servicio
  - servicios.kilometro: número float de kilometros reccoridos en el servicio
  - @kilometros: número enteros que establece el rango permitido
  """
  def kilometros_permitidos(servicio) do
    case Map.get(servicio, :kilometros) do
      nil ->
        {:error, :kilometros_fuera_de_rango}

      kilometros ->
        if (is_integer(kilometros) or is_float(kilometros)) and kilometros > 0 and kilometros <= @kilometros_max do
          :ok
        else
          {:error, :kilometros_fuera_de_rango}
        end
    end
  end

  @doc """
  retraso_servicio comprueba que cumpla con el rango de retraso permitido

    parametro:
    - servicio: llega un mapa con los atributos del servicio
    - servicio.retraso: el número de retraso del servicio
    - @retraso: rango de retraso que tiene permitido el servicio

    #Devuelve:
    - :ok si los datos son validos
    - {:error, motivo} si los datos no son validos

  """

  def retraso_servicio(servicio) do
    case Map.get(servicio, :retraso) do
      nil ->
        {:error, :retraso_invalido}

      retraso ->
        if retraso >= @retraso_min and retraso <= @retraso_max do
          :ok
        else
          {:error, :retraso_invalido}
        end
    end
  end
end
