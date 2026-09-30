defmodule Reportes do
  @moduledoc """
    Modulo encargado de generar los reportes del sistema.
  """

  # HACER EL GENERAR REPORTES

  # servicios rechazados, motivo y cantidad de rechazos por motivo
  def imprimir_r1(servicios_rechazados) do
    IO.puts("\n== SERVICIOS RECHAZADOS ==")

    # Se recorren los rechazados y por cada uno muestra el mismo servicio y el motivo del rechazo
    Enum.each(servicios_rechazados, fn rechazado ->
      IO.puts("Servicio: #{inspect(rechazado.servicio)} | Motivo rechazo: #{rechazado.motivo}")
    end)

    # Se cuentan la cantidad de rechazos por motivo
    conteo = Enum.frequencies_by(servicios_rechazados, fn rechazado -> rechazado.motivo end)
    IO.puts("\nCantidad de rechazos por motivo:")

    # Se recorre el conteo y se muestra la cantidad de rechazos por motivo
    Enum.each(conteo, fn {motivo, cant} ->
      IO.puts(" - #{motivo}: #{cant}")
    end)
  end

  # Km recorridos y densidad por zona (ordenados de mayor a menor dens)
  def imprimir_r2(zonas, servicios_validos) do
    IO.puts("\n== RECORRIDO Y DENSIDAD POR ZONA ==")

    # se recorre la lista de zonas
    datos_zonas =
      Enum.map(zonas, fn zona ->
        # se recorre la lista de servicios y se cuentan los km de los servicios que son de esta zona
        km =
          servicios_validos
          |> Enum.filter(fn servicio -> servicio.zona == zona.id end)
          # este aca es el que suma los km
          |> Enum.reduce(0, fn servicio, acc -> acc + servicio.kilometros end)

        # basicamente si se recorrieron km entonces se hace la division, si no no
        densidad = if zona.area > 0, do: km / zona.area, else: 0.0

        # Se crea un mapa con el nombre de la zona, los km recorridos y la densidad (los datos pedidos vaya)
        %{zona: zona.nombre, km: km, densidad: densidad}
      end)
      # lo ordena de manera descendente por densidad
      |> Enum.sort_by(fn zona -> zona.densidad end, :desc)

    Enum.each(datos_zonas, fn d ->
      # Se muestra el resultado
      IO.puts("Zona: #{d.zona} | Km: #{d.km} | Densidad: #{Float.round(d.densidad, 2)} km/km²")
    end)
  end

  # Km diarios de la empresa y verificación de la meta de 500 km
  def imprimir_r3(servicios_validos) do
    IO.puts("\n== KILÓMETROS DIARIOS DE LA EMPRESA ==")

    mapa_dias =
      1..6
      |> Map.new(fn dia -> {dia, 0} end) # Mapa inicial en 0 para los días del 1 al 6
      |> Map.merge( # este merge combina 2 mapas, pasa como primer parametro el mapa de arriba y segundo el de abajo
        servicios_validos
        |> Enum.group_by( #agrupa los servicios por dia y suma los km
          fn servicio -> servicio.dia end,
          fn servicio -> servicio.kilometros end
        )
        |> Map.new(fn {dia, kms} -> {dia, Enum.sum(kms)} end) # se crea un nuevo mapa con los dias del 1 al 6 y los km recorridos en ese dia
      )

    alcanzo_todos = Enum.all?(mapa_dias, fn {_d, km} -> km >= 500 end) # verifica que todos los dias se hayan alcanzado los 500 km

    alcanzo_al_menos_uno = Enum.any?(mapa_dias, fn {_d, km} -> km >= 500 end) # verifica que al menos un dia se hayan alcanzado los 500 km

    Enum.each(mapa_dias, fn {dia, km} -> # recorremos el mapa de los dias y se muestra el resultado
      cumplio = if km >= 500, do: "SI", else: "NO"
      IO.puts("Día #{dia}: #{km} km | Meta (500 km) alcanzada: #{cumplio}")
    end)

    IO.puts("¿Alcanzó la meta TODOS los días?: #{if alcanzo_todos, do: "SÍ", else: "NO"}")
    IO.puts("¿Alcanzó la meta AL MENOS UN día?: #{if alcanzo_al_menos_uno, do: "SÍ", else: "NO"}") # ambos complementacion de lo que se muestra

    mapa_dias
  end

  # Liquidación de todos los repartidores ordenada de mayor a menor
  def imprimir_r4(liquidacion) do
    IO.puts("\n== LIQUIDACION DE REPARTIDORES ==")

    ordenados = Enum.sort_by(liquidacion, fn repartidor -> repartidor.neto end, :desc)

    ordenados
    |> Enum.with_index(1) # este convierte la lista en una lista de tuplas {repartidor, indice}
    |> Enum.each(fn {repartidor, idx} -> # itera sobre la lista de tuplas
      IO.puts("#{idx}. [#{repartidor.codigo}] #{repartidor.nombre} | Km: #{repartidor.kilometros} | Valor Svcs: $#{repartidor.valor_servicios} | Bonos: $#{repartidor.bonificaciones} | Alquiler: $#{repartidor.alquiler} | NETO: $#{repartidor.neto}")
    end) # ya con cada iteracion de cada repartidor ordenado se muestra el resultado
  end

  # Repartidor con más km cada dia y el que ocupó el primer lugar en mas dias (el mvp)
  def imprimir_r5(servicios_validos) do
  IO.puts("\n== REPARTIDOR CON MAS KM POR DIA ==")

  ganadores_por_dia =
    Enum.map(1..6, fn dia -> # se crea una lista del 1 al 6 y se itera sobre ella
      servicios_del_dia = Enum.filter(servicios_validos, fn servicio -> servicio.dia == dia end) # filtra los servicios que son de este dia
      kilometros_por_repartidor = Enum.group_by(servicios_del_dia, fn servicio -> servicio.repartidor end) # agrupa los servicios por repartidor

      totales =
        Enum.map(kilometros_por_repartidor, fn {repartidor, servicios} -> # itera sobre los servicios agrupados por repartidor
          {repartidor, Enum.reduce(servicios, 0, fn servicio, acumulador -> acumulador + servicio.kilometros end)} # suma los km de los servicios de este repartidor
        end)

      maximo_kilometros =
        case totales do
          [] -> 0 # si no hay servicios entonces el maximo es 0
          _ -> Enum.max(Enum.map(totales, fn {_repartidor, kilometros} -> kilometros end)) # se toma el maximo de los km recorridos por cada repartidor
        end

      ganadores =
        if maximo_kilometros > 0 do # si el maximo es mayor a 0 entonces se toma el maximo
          totales
          |> Enum.filter(fn {_repartidor, kilometros} -> kilometros == maximo_kilometros end) # filtra los repartidores que tienen el maximo de km
          |> Enum.map(fn {repartidor, _kilometros} -> repartidor end) # se toma el maximo de los km recorridos por cada repartidor
        else # si no hay servicios entonces se toma el maximo
          []
        end

      IO.puts("Día #{dia}: Ganador(es) #{inspect(ganadores)} con #{maximo_kilometros} km")
      ganadores
    end) # ya con cada iteracion de cada repartidor ordenado se muestra el resultado

  conteo_primeros =
    ganadores_por_dia # se toma la lista de los ganadores por dia
    |> List.flatten() # se aplana la lista de los ganadores por dia
    |> Enum.frequencies() # se cuenta la cantidad de veces que cada repartidor aparece en la lista

  if map_size(conteo_primeros) > 0 do # si el tamaño del mapa es mayor a 0 entonces se toma el maximo
    max_dias = Enum.max(Map.values(conteo_primeros)) # se toma el maximo de los dias recorridos por cada repartidor
    lideres = Enum.filter(conteo_primeros, fn {_repartidor, conteo} -> conteo == max_dias end) |> Enum.map(&elem(&1, 0)) # filtra los repartidores que tienen el maximo de dias
    IO.puts("\nRepartidor(es) con más días en 1er lugar: #{inspect(lideres)} (#{max_dias} días)") # muestra el resultado
  end
end

end
