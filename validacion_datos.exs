defmodule Validacion do
  @retraso -30..180
  @dias 1..6
  @kilometros 0..45

  @doc """
    validar_servicios usa la colección de datos y verifica que los datos de cada lista cumpla
    con los requerimientos necesarios para ser un servicios valido.

    parametro:
    - repartidores: Colección de datos una lista de mapas con los atributos del repartidor
    - zonas: zonas: Colección de datos de una lista de mapas con los registros para el uso
    - servicios: Colección de datos en una lista de mapas con los atributos de los servicios
    con el id del repartidor como indice de referencia.

    #Ejemplo:

  """
  def validar_servicios(repartidores, zonas, servicios) do
    with  :ok <- existe_repartidor?(repartidores, servicios),
          :oK <- zona_existe?(servicios, zonas),
          :ok <- dia_servicio(servicios),
          :ok <- kilometros_permitidos(servicios),
          :ok <- retraso_servicio(servicios) do
      {:ok, servicio}
    end
  end

  @doc"""
  existencia_repartidor comprueba la existencia de un repartidor comparando con la id
  de los servicios

  parametro:
  - repartidores
  - servicios
  """

  defp existe_repartidor?(repartidor, servicios) do
    if Map.has_key?(repartidor.codigo, servicios.repartidor) do
      :ok
    else
      {:error, :repartidor_desconocido}
    end
  end

  defp zona_existe?(servicios, zonas) do

  end

  @doc"""
  existencia_repartidor comprueba la existencia de un repartidor comparando con la id
    de los servicios

  parametro:
  - servicio: Colección de datos con los atributos del serevicio
  - servicios.dia: número entero con los dia de servicio
  - @dias: número entero con el rango de los días permitidos
  """

  defp dia_servicio(servicios) do
      if servicios.dia in @dias do
        :ok
      else
        false -> {:error, :dia_invalido}
      end
  end

  @doc"""
    Kilometros_permitidos comprobar que cumpla los rangos establecidos

    parametro:
    - servicio: Colección de datos con los atributos del serevicio
    - servicios.kilometro: número float de kilometros reccoridos en el servicio
    - @kilometros: número enteros que establece el rango permitido
  """
  defp kilometros_permitidos(servicios) do
      if servicios.kilometros in @kilometros do
        :ok
      else
        {:error, :Kilometros_fuera_de_rango}
    end
  end

  @doc"""
    retraso_servicio comprueba que cumpla con el rango de retraso permitido

    parametro:
    - servicio: Colección de datos con los atributos del serevicio
    - servicio.retraso: el número de retraso del servicio
    - @retraso: rango de retraso que tiene permitido el servicio
  """

  defp retraso_servicio(servicio) do
    if servicio.retraso in @retraso do
      :ok
    else
      {:error, :retraso_invalido}
    end
  end

end
