# Integrantes:
# - Ruben Steven Sanchez
# - Jhonatan Cardona
# - Diana Valencia

defmodule Reportes do
  @moduledoc """
    Modulo encargado de generar los reportes del sistema.
  """
  def generar_todos(repartidores, zonas, servicios_validos, servicios_rechazados) do
    # calcular la liquidación de todos los repartidores
    liquidacion = Servicios.liquidacion(repartidores, servicios_validos)
    # enviar a cada reporte exactamente la información que necesita
    imprimir_r1(servicios_rechazados)
    imprimir_r2(zonas, servicios_validos)
    imprimir_r3(servicios_validos)
    imprimir_r4(liquidacion)
    imprimir_r5(servicios_validos)
    imprimir_r6(servicios_validos, repartidores)
    imprimir_r7(liquidacion)
    imprimir_r8(zonas, servicios_validos, repartidores)
  end

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
      # Mapa inicial en 0 para los días del 1 al 6
      |> Map.new(fn dia -> {dia, 0} end)
      # este merge combina 2 mapas, pasa como primer parametro el mapa de arriba y segundo el de abajo
      |> Map.merge(
        servicios_validos
        # agrupa los servicios por dia y suma los km
        |> Enum.group_by(
          fn servicio -> servicio.dia end,
          fn servicio -> servicio.kilometros end
        )
        # se crea un nuevo mapa con los dias del 1 al 6 y los km recorridos en ese dia
        |> Map.new(fn {dia, kms} -> {dia, Enum.sum(kms)} end)
      )

    # verifica que todos los dias se hayan alcanzado los 500 km
    alcanzo_todos = Enum.all?(mapa_dias, fn {_d, km} -> km >= 500 end)

    # verifica que al menos un dia se hayan alcanzado los 500 km
    alcanzo_al_menos_uno = Enum.any?(mapa_dias, fn {_d, km} -> km >= 500 end)

    # recorremos el mapa de los dias y se muestra el resultado
    Enum.each(mapa_dias, fn {dia, km} ->
      cumplio = if km >= 500, do: "SI", else: "NO"
      IO.puts("Día #{dia}: #{km} km | Meta (500 km) alcanzada: #{cumplio}")
    end)

    IO.puts("¿Alcanzó la meta TODOS los días?: #{if alcanzo_todos, do: "SÍ", else: "NO"}")
    # ambos complementacion de lo que se muestra
    IO.puts("¿Alcanzó la meta AL MENOS UN día?: #{if alcanzo_al_menos_uno, do: "SÍ", else: "NO"}")

    mapa_dias
  end

  # Liquidación de todos los repartidores ordenada de mayor a menor
  def imprimir_r4(liquidacion) do
    IO.puts("\n== LIQUIDACION DE REPARTIDORES ==")

    ordenados = Enum.sort_by(liquidacion, fn repartidor -> repartidor.neto end, :desc)

    ordenados
    # este convierte la lista en una lista de tuplas {repartidor, indice}
    |> Enum.with_index(1)
    # itera sobre la lista de tuplas
    |> Enum.each(fn {repartidor, idx} ->
      IO.puts(
        "#{idx}. [#{repartidor.codigo}] #{repartidor.nombre} | Km: #{repartidor.kilometros} | Valor Svcs: $#{repartidor.valor_servicios} | Bonos: $#{repartidor.bonificaciones} | Alquiler: $#{repartidor.alquiler} | NETO: $#{repartidor.neto}"
      )
    end)

    # ya con cada iteracion de cada repartidor ordenado se muestra el resultado
  end

  # Repartidor con más km cada dia y el que ocupó el primer lugar en mas dias (el mvp)
  def imprimir_r5(servicios_validos) do
    IO.puts("\n== REPARTIDOR CON MAS KM POR DIA ==")

    # se crea una lista del 1 al 6 y se itera sobre ella
    ganadores_por_dia =
      Enum.map(1..6, fn dia ->
        # filtra los servicios que son de este dia
        servicios_del_dia = Enum.filter(servicios_validos, fn servicio -> servicio.dia == dia end)
        # agrupa los servicios por repartidor
        kilometros_por_repartidor =
          Enum.group_by(servicios_del_dia, fn servicio -> servicio.repartidor end)

        # itera sobre los servicios agrupados por repartidor
        totales =
          Enum.map(kilometros_por_repartidor, fn {repartidor, servicios} ->
            # suma los km de los servicios de este repartidor
            {repartidor,
             Enum.reduce(servicios, 0, fn servicio, acumulador ->
               acumulador + servicio.kilometros
             end)}
          end)

        maximo_kilometros =
          case totales do
            # si no hay servicios entonces el maximo es 0
            [] -> 0
            # se toma el maximo de los km recorridos por cada repartidor
            _ -> Enum.max(Enum.map(totales, fn {_repartidor, kilometros} -> kilometros end))
          end

        # si el maximo es mayor a 0 entonces se toma el maximo
        # si no hay servicios entonces se toma el maximo
        ganadores =
          if maximo_kilometros > 0 do
            totales
            # filtra los repartidores que tienen el maximo de km
            |> Enum.filter(fn {_repartidor, kilometros} -> kilometros == maximo_kilometros end)
            # se toma el maximo de los km recorridos por cada repartidor
            |> Enum.map(fn {repartidor, _kilometros} -> repartidor end)
          else
            []
          end

        IO.puts("Día #{dia}: Ganador(es) #{inspect(ganadores)} con #{maximo_kilometros} km")
        ganadores
      end)

    # ya con cada iteracion de cada repartidor ordenado se muestra el resultado

    # se toma la lista de los ganadores por dia
    conteo_primeros =
      ganadores_por_dia
      # se aplana la lista de los ganadores por dia
      |> List.flatten()
      # se cuenta la cantidad de veces que cada repartidor aparece en la lista
      |> Enum.frequencies()

    # si el tamaño del mapa es mayor a 0 entonces se toma el maximo
    if map_size(conteo_primeros) > 0 do
      # se toma el maximo de los dias recorridos por cada repartidor
      max_dias = Enum.max(Map.values(conteo_primeros))
      # filtra los repartidores que tienen el maximo de dias
      lideres =
        Enum.filter(conteo_primeros, fn {_repartidor, conteo} -> conteo == max_dias end)
        |> Enum.map(&elem(&1, 0))

      # muestra el resultado
      IO.puts(
        "\nRepartidor(es) con más días en 1er lugar: #{inspect(lideres)} (#{max_dias} días)"
      )
    end
  end

  # mejor puntualidad (retraso promedio ponderado con min 3 servicios)
  def imprimir_r6(servicios_validos, repartidores) do
    IO.puts("\n== REPARTIDOR CON MEJOR PUNTUALIDAD ==")

    # agrupa los servicios por repartidor
    por_repartidor = Enum.group_by(servicios_validos, fn s -> s.repartidor end)

    # recorre el mapa de los servicios agrupados por repartidor
    candidatos =
      Enum.reduce(por_repartidor, [], fn {repartidor_cod, servicios}, acc ->
        # verifica que el repartidor tenga al menos 3 servicio
        if length(servicios) >= 3 do
          sum_producto = Enum.reduce(servicios, 0, fn s, a -> a + s.retraso * s.kilometros end)
          sum_km = Enum.reduce(servicios, 0, fn s, a -> a + s.kilometros end)
          ponderado = sum_producto / sum_km
          # se crea una lista de tuplas con el codigo del repartidor y su retraso ponderado
          [%{codigo: repartidor_cod, retraso_ponderado: ponderado} | acc]
        else
          # si no cumple con la condicion se devuelve la lista sin modificar
          acc
        end
      end)

    case candidatos do
      # si es una lista vacia entonces devuleve el mensaje
      [] ->
        IO.puts("Ningún repartidor cumple con el mínimo de 3 servicios válidos.")

      # si no es una lista vacia entonces se toma el minimo de los retrasos ponderados
      _ ->
        mejor = Enum.min_by(candidatos, fn c -> c.retraso_ponderado end)
        rep_info = Enum.find(repartidores, fn r -> r.codigo == mejor.codigo end)

        IO.puts(
          "Mejor puntualidad: #{rep_info.nombre} (#{mejor.codigo}) con retraso ponderado de #{Float.round(mejor.retraso_ponderado, 2)} min/km"
        )
    end
  end

  # total pagado y costo promedio por km
  def imprimir_r7(liquidacion) do
    IO.puts("\n== RESUMEN FINANCIERO SEMANAL ==")
    # r es repartidor
    total_pagado = Enum.reduce(liquidacion, 0, fn r, acc -> acc + r.neto end)
    total_km = Enum.reduce(liquidacion, 0, fn r, acc -> acc + r.kilometros end)
    costo_promedio = if total_km > 0, do: total_pagado / total_km, else: 0.0

    IO.puts("Total pagado a todos los repartidores: $#{total_pagado}")
    IO.puts("Total kilómetros recorridos: #{total_km} km")
    IO.puts("Costo promedio pagado por kilómetro: $#{Float.round(costo_promedio, 2)} / km")
  end

  # repartidores con servicios validos en todas las zonas
  def imprimir_r8(zonas, servicios_validos, repartidores) do
    IO.puts("\n== REPARTIDORES CON SERVICIOS EN TODAS LAS ZONAS ==")

    ids_zonas = Enum.map(zonas, fn zona -> zona.id end)
    |> MapSet.new() # toma la lista de ids y las convierte en un mapset donde elimina duplicados

    cumplen = # filtrta los repartidores que cumplen con la condicion
      Enum.filter(repartidores, fn r ->
        zonas_visitadas = # crea una lista de tuplas con el codigo del repartidor y su retraso ponderado
          servicios_validos
          |> Enum.filter(fn s -> s.repartidor == r.codigo end)
          |> Enum.map(fn s -> s.zona end)
          |> MapSet.new()

        MapSet.subset?(ids_zonas, zonas_visitadas) # verifica si la lista de ids de zonas es un subconjunto o estan incluidos en las zonas visitadas
      end)

    if Enum.empty?(cumplen) do # si la lista de cumplen esta vacia
      IO.puts("Ningún repartidor realizó servicios en todas las zonas.")
    else # si no esta vacia muestra los repartidores que cumplen con la condicion
      Enum.each(cumplen, fn r -> IO.puts(" - #{r.codigo}: #{r.nombre}") end)
    end
  end
end
