defmodule Reportes do
  @moduledoc """
    Modulo encargado de generar los reportes del sistema.
  """

  # 1. REPORTE DE SERVICIOS RECHAZADOS
  def servicios_rechazados(repartidores, zonas, servicios) do
    resultado = Validacion.separar_servicios(repartidores, zonas, servicios)
    resultado.invalidos
  end

  # 2. REPORTE DE KM Y DENSIDAD POR ZONA
  def km_y_densidad_por_zona(zonas, servicios_validos) do
    Enum.map(zonas, fn zona ->
      servicios_zona = Enum.filter(servicios_validos, fn s -> s.zona == zona.id end)
      km_totales = Enum.reduce(servicios_zona, 0, fn s, acc -> acc + s.kilometros end)
      densidad = if zona.area > 0, do: Float.round(km_totales / zona.area, 2), else: 0.0

      %{
        zona_id: zona.id,
        nombre: zona.nombre,
        area: zona.area,
        km_totales: km_totales,
        densidad_km_area: densidad,
        cantidad_servicios: length(servicios_zona)
      }
    end)
  end

  # 3. KM POR DIA Y META DE LA EMPRESA (META DIARIA 500 KM)
  def km_por_dia_y_meta(servicios_validos, meta_diaria \\ 500) do
    dias = 1..6

    Enum.map(dias, fn dia ->
      servicios_dia = Enum.filter(servicios_validos, fn s -> s.dia == dia end)
      km_totales = Enum.reduce(servicios_dia, 0, fn s, acc -> acc + s.kilometros end)
      cumple_meta = km_totales >= meta_diaria

      %{
        dia: dia,
        km_totales: km_totales,
        meta_diaria: meta_diaria,
        cumple_meta: cumple_meta,
        diferencia: km_totales - meta_diaria
      }
    end)
  end

  # 4. REPORTE DE LA LIQUIDACION ORDENADA DE MAYOR A MENOR
  def liquidacion_ordenada(repartidores, servicios_validos) do
    liquidaciones = Servicios.liquidacion(repartidores, servicios_validos)
    Enum.sort_by(liquidaciones, fn l -> l.liquidacion_neta end, :desc)
  end

  # 5. REPORTE DEL MVP CON MAS KILOMETROS (RAPPI MASTER)
  def mvp_repartidor(repartidores, servicios_validos) do
    liquidaciones = Servicios.liquidacion(repartidores, servicios_validos)
    mvp_global = Enum.max_by(liquidaciones, fn l -> l.km_totales end, fn -> nil end)

    servicios_por_rep_dia =
      servicios_validos
      |> Enum.group_by(fn s -> {s.repartidor, s.dia} end)
      |> Enum.map(fn {{rep_code, dia}, servicios} ->
        km = Enum.reduce(servicios, 0, fn s, acc -> acc + s.kilometros end)
        rep = Enum.find(repartidores, fn r -> r.codigo == rep_code end)
        %{repartidor: rep.nombre, codigo: rep_code, dia: dia, kilometros: km}
      end)

    mvp_dia = Enum.max_by(servicios_por_rep_dia, fn r -> r.kilometros end, fn -> nil end)

    %{
      mvp_global_km: mvp_global,
      mvp_dia_record: mvp_dia
    }
  end

  # 6. REPORTE AL MAS PUNTUAL
  def mas_puntual(repartidores, servicios_validos) do
    servicios_por_rep = Enum.group_by(servicios_validos, fn s -> s.repartidor end)

    promedios =
      Enum.map(repartidores, fn repartidor ->
        servicios_rep = Map.get(servicios_por_rep, repartidor.codigo, [])

        {retraso_promedio, entregas_a_tiempo} =
          if Enum.empty?(servicios_rep) do
            {0.0, 0}
          else
            total_retraso = Enum.reduce(servicios_rep, 0, fn s, acc -> acc + s.retraso end)
            a_tiempo = Enum.count(servicios_rep, fn s -> s.retraso <= 0 end)
            {Float.round(total_retraso / length(servicios_rep), 2), a_tiempo}
          end

        %{
          codigo: repartidor.codigo,
          nombre: repartidor.nombre,
          total_servicios: length(servicios_rep),
          entregas_a_tiempo: entregas_a_tiempo,
          retraso_promedio_min: retraso_promedio
        }
      end)

    repartidores_con_servicios = Enum.filter(promedios, fn p -> p.total_servicios > 0 end)

    mas_puntual =
      Enum.min_by(repartidores_con_servicios, fn p -> p.retraso_promedio_min end, fn -> nil end)

    %{
      mas_puntual: mas_puntual,
      detalle_repartidores: promedios
    }
  end

  # 7. REPORTE DE TOTALES GLOBALES
  def totales_globales(repartidores, zonas, servicios) do
    clasificacion = Validacion.separar_servicios(repartidores, zonas, servicios)
    validos = clasificacion.validos
    invalidos = clasificacion.invalidos

    liquidaciones = Servicios.liquidacion(repartidores, validos)

    km_totales = Enum.reduce(validos, 0, fn s, acc -> acc + s.kilometros end)

    total_servicios_bruto =
      Enum.reduce(liquidaciones, 0, fn l, acc -> acc + l.valor_servicios end)

    total_bonificaciones = Enum.reduce(liquidaciones, 0, fn l, acc -> acc + l.bonificaciones end)
    total_alquileres = Enum.reduce(liquidaciones, 0, fn l, acc -> acc + l.alquiler end)

    total_liquidacion_neta =
      Enum.reduce(liquidaciones, 0, fn l, acc -> acc + l.liquidacion_neta end)

    %{
      total_servicios_procesados: length(servicios),
      total_servicios_validos: length(validos),
      total_servicios_rechazados: length(invalidos),
      total_km_recorridos: km_totales,
      total_valor_servicios: total_servicios_bruto,
      total_bonificaciones: total_bonificaciones,
      total_alquileres: total_alquileres,
      total_liquidacion_neta: total_liquidacion_neta
    }
  end

  # 8. REPORTE DE LOS REPARTIDORES CON PRESENCIA EN LAS ZONAS
  def presencia_en_zonas(repartidores, zonas, servicios_validos) do
    Enum.map(zonas, fn zona ->
      servicios_zona = Enum.filter(servicios_validos, fn s -> s.zona == zona.id end)
      codigos_repartidores = servicios_zona |> Enum.map(fn s -> s.repartidor end) |> Enum.uniq()

      repartidores_info =
        Enum.filter(repartidores, fn r -> r.codigo in codigos_repartidores end)
        |> Enum.map(fn r -> %{codigo: r.codigo, nombre: r.nombre} end)

      %{
        zona_id: zona.id,
        nombre_zona: zona.nombre,
        total_repartidores: length(repartidores_info),
        repartidores: repartidores_info
      }
    end)
  end

  # 9. FUNCION QUE GENERE TODOS LOS REPORTES Y MUESTRE POR CONSOLA
  def generar_todos_los_reportes(repartidores, zonas, servicios) do
    clasificacion = Validacion.separar_servicios(repartidores, zonas, servicios)
    validos = clasificacion.validos

    IO.puts("\n=======================================================")
    IO.puts("          EMPRESA DE MENSAJERIA - REPORTES           ")
    IO.puts("=======================================================\n")

    IO.puts("1. TOTALES GLOBALES:")
    totales = totales_globales(repartidores, zonas, servicios)
    IO.inspect(totales)

    IO.puts("\n2. SERVICIOS RECHAZADOS (INVÁLIDOS):")
    rechazados = servicios_rechazados(repartidores, zonas, servicios)

    Enum.each(rechazados, fn inv ->
      IO.puts(
        "   - Repartidor: #{inv.servicio.repartidor} | Zona: #{inv.servicio.zona} | Día: #{inv.servicio.dia} | Motivo: #{inspect(inv.motivo)}"
      )
    end)

    IO.puts("\n3. LIQUIDACION ORDENADA DE MAYOR A MENOR:")
    liq_ord = liquidacion_ordenada(repartidores, validos)

    Enum.each(liq_ord, fn l ->
      IO.puts(
        "   - #{l.codigo} #{l.nombre}: Net: $#{l.liquidacion_neta} (Km: #{l.km_totales}, Serv: $#{l.valor_servicios}, Bono: $#{l.bonificaciones}, Alq: -$#{l.alquiler})"
      )
    end)

    IO.puts("\n4. RENDIMIENTO Y DENSIDAD POR ZONA:")
    densidad = km_y_densidad_por_zona(zonas, validos)

    Enum.each(densidad, fn z ->
      IO.puts(
        "   - #{z.zona_id} (#{z.nombre}): #{z.km_totales} km | Área: #{z.area} km² | Densidad: #{z.densidad_km_area} km/km²"
      )
    end)

    IO.puts("\n5. METAS DIARIAS DE LA EMPRESA:")
    metas = km_por_dia_y_meta(validos, 500)

    Enum.each(metas, fn m ->
      estado = if m.cumple_meta, do: "CUMPLIDA", else: "NO CUMPLIDA"
      IO.puts("   - Día #{m.dia}: #{m.km_totales} km / Meta #{m.meta_diaria} km -> [#{estado}]")
    end)

    IO.puts("\n6. REPARTIDOR MVP (RAPPI MASTER):")
    mvp = mvp_repartidor(repartidores, validos)

    if mvp.mvp_global_km do
      IO.puts(
        "   - MVP Global: #{mvp.mvp_global_km.nombre} (#{mvp.mvp_global_km.codigo}) con #{mvp.mvp_global_km.km_totales} km totales"
      )
    end

    if mvp.mvp_dia_record do
      IO.puts(
        "   - Récord en 1 Día: #{mvp.mvp_dia_record.repartidor} con #{mvp.mvp_dia_record.kilometros} km en el Día #{mvp.mvp_dia_record.dia}"
      )
    end

    IO.puts("\n7. REPARTIDOR MÁS PUNTUAL:")
    puntual = mas_puntual(repartidores, validos)

    if puntual.mas_puntual do
      p = puntual.mas_puntual

      IO.puts(
        "   - Más Puntual: #{p.nombre} (#{p.codigo}) con retraso promedio de #{p.retraso_promedio_min} min (#{p.entregas_a_tiempo}/#{p.total_servicios} entregas a tiempo)"
      )
    end

    IO.puts("\n8. PRESENCIA DE REPARTIDORES POR ZONA:")
    presencia = presencia_en_zonas(repartidores, zonas, validos)

    Enum.each(presencia, fn z ->
      nombres = Enum.map(z.repartidores, & &1.nombre) |> Enum.join(", ")

      IO.puts(
        "   - #{z.zona_id} (#{z.nombre_zona}): #{z.total_repartidores} repartidor(es) [#{nombres}]"
      )
    end)

    IO.puts("\n=======================================================\n")

    %{
      totales_globales: totales,
      servicios_rechazados: rechazados,
      liquidacion_ordenada: liq_ord,
      km_y_densidad_zona: densidad,
      metas_diarias: metas,
      mvp: mvp,
      mas_puntual: puntual,
      presencia_zonas: presencia
    }
  end

  def ejecutar do
    generar_todos_los_reportes(Datos.repartidores(), Datos.zonas(), Datos.servicios())
  end
end
