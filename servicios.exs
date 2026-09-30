# Integrantes:
# - Ruben Steven Sanchez
# - Jhonatan Cardona
# - Diana Valencia

defmodule Servicios do
  @moduledoc """
    Este modulo contiene funciones puras para calcular valores, aplicar bonos,
    determinar alquileres y calcular liquidaciones.
  """

  # En km
  @tarifa_base 2500
  @meta_diaria 500
  @dias_operacion 1..6
  # km maximos que puede tener un solo servicio
  @km_max_servicio 45
  # cantidad de km necesarios para la bonificacion diaria
  @bonificacion_km 80
  @bonificacion_diaria 15000
  # si el repartidor usa bici fuera de la empresa entonces no aplica
  @alquiler_bicicleta 10000

  # CONSTANTES DE BONIFICACION Y DESCUENTOS multiplicadores

  # corresponde al + 8% del valor del servicio en bruto
  @bono_puntual 1.08
  # entre 10 y 30 mins se descuenta el 10%
  @descuento_retraso_10_30 0.9
  # retraso de mas de 30 mins se descuenta el 25%
  @descuento_retraso_mas_30 0.75

  # 2. VALOR DE UN SERVICIO
  def calcular_valor_servicio(servicio) do
    valor_base = @tarifa_base * servicio.kilometros

    cond do
      servicio.retraso <= 0 ->
        valor_base * @bono_puntual

      servicio.retraso <= 10 ->
        valor_base

      servicio.retraso <= 30 ->
        valor_base * @descuento_retraso_10_30

      true ->
        valor_base * @descuento_retraso_mas_30
    end
  end

  # 3. BONIFICACION POR PRODUCTIVIDAD
  # servicios validados del repartidor
  def calcular_bonificacion_repartidor(servicios_validos_rep) do
    # agrupa los servicios por dia del repartidor
    servicios_por_dia = Enum.group_by(servicios_validos_rep, fn servicio -> servicio.dia end)

    Enum.reduce(servicios_por_dia, 0, fn {_dia, servicios_del_dia}, acc_bono ->
      km_total_dia =
        Enum.reduce(servicios_del_dia, 0, fn servicio, acc_km -> acc_km + servicio.kilometros end)

      if km_total_dia >= @bonificacion_km do
        acc_bono + @bonificacion_diaria
      else
        acc_bono
      end
    end)
  end

  # 4. ALQUILER DE BICICLETA

  # esto quiere decir que el repartidor no usa bici de la empresa por lo que no paga alquiler
  def alquiler_bici(%{bicicleta: false}, _servicios_validos), do: 0
  # Aqui si la usa y pasamos a calcular los dias trabajados
  def alquiler_bici(repartidor, servicios_validos) do
    # se filtran los servicios validos q sean unicamente de este repartidor
    dias_trabajados =
      servicios_validos
      |> Enum.filter(fn servicio -> servicio.repartidor == repartidor.codigo end)
      |> Enum.map(fn servicio -> servicio.dia end)
      |> Enum.uniq()
      |> length()

    # Se multiplica todo el proceso de arriba por el alquiler de la bici y eso posteriormente se le
    # descontara al domiciliario
    dias_trabajados * @alquiler_bicicleta
  end

  def liquidacion(repartidores, servicios_validos) do
    # recorremos la lista de repartidores y se les busca sus servicios
    Enum.map(repartidores, fn repartidor ->
      servicios_repartidor =
        servicios_validos
        |> Enum.filter(fn servicio -> servicio.repartidor == repartidor.codigo end)

      # se toman todos los parametros para tener en cuenta a la hora de la liquidacion
      km_totales =
        Enum.reduce(servicios_repartidor, 0, fn servicio, acc -> acc + servicio.kilometros end)

      valor_servicios =
        Enum.reduce(servicios_repartidor, 0, fn servicio, acc ->
          acc + calcular_valor_servicio(servicio)
        end)

      bonificaciones = calcular_bonificacion_repartidor(servicios_repartidor)
      alquiler = alquiler_bici(repartidor, servicios_repartidor)
      # se hace la operacion final
      liquidacion_neta = valor_servicios + bonificaciones - alquiler

      # devolvemos un mapa con la informacion completa
      %{
        codigo: repartidor.codigo,
        nombre: repartidor.nombre,
        bicicleta: repartidor.bicicleta,
        kilometros: km_totales,
        valor_servicios: valor_servicios,
        bonificaciones: bonificaciones,
        alquiler: alquiler,
        neto: liquidacion_neta,
      }
    end)
  end

  def comprobante(repartidor, servicios_validos) do
    servicios_rep = Enum.filter(servicios_validos, fn s -> s.repartidor == repartidor.codigo end)
    servicios_por_dia = Enum.group_by(servicios_rep, fn s -> s.dia end)

    dias_detalle =
      servicios_por_dia
      |> Enum.map(fn {dia, svcs} ->
        km_dia = Enum.reduce(svcs, 0, fn s, acc -> acc + s.kilometros end)
        val_dia = Enum.reduce(svcs, 0, fn s, acc -> acc + calcular_valor_servicio(s) end)
        bono_dia = if km_dia >= @bonificacion_km, do: @bonificacion_diaria, else: 0

        %{
          dia: dia,
          kilometros: km_dia,
          valor_servicios: val_dia,
          bonificacion: bono_dia
        }
      end)
      |> Enum.sort_by(fn d -> d.dia end)

    total_servicios = Enum.reduce(dias_detalle, 0, fn d, acc -> acc + d.valor_servicios end)
    total_bonificaciones = Enum.reduce(dias_detalle, 0, fn d, acc -> acc + d.bonificacion end)
    alquiler = alquiler_bici(repartidor, servicios_rep)
    neto = total_servicios + total_bonificaciones - alquiler

    %{
      codigo: repartidor.codigo,
      nombre: repartidor.nombre,
      dias: dias_detalle,
      total_servicios: total_servicios,
      total_bonificaciones: total_bonificaciones,
      alquiler: alquiler,
      neto: neto
    }
  end
end
