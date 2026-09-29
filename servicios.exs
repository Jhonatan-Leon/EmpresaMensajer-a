defmodule Servicios do
  @moduledoc """
    Este modulo contiene funciones puras para calcular valores, aplicar bonos,
    determiinar alquileres y calcular liquidaciones
  """

  @tarifa_base 2500                 # En km
  @meta_diaria 500
  @dias_operacion 1..6
  @km_max_servicio 45               # km maximos que puede tener un solo servicio
  @bonificacion_km 80               # cantidad de km necesarios para la bonificacion diaria
  @bonificacion_diaria 15000
  @alquiler_bicicleta 10000         # si el repartidor usa bici fuera de la empresa entonces no aplica

  # CONSTANTES DE BONIFICACION Y DESCUENTOS multiplicadores

  @bono_puntual 1.08                 # corresponde al + 8% del valor del servicio en bruto
  @descuento_retraso_10_30 0.9       # entre 10 y 30 mins se descuenta el 10%
  @descuento_retraso_mas_30 0.75     # retraso de mas de 30 mins se descuenta el 25%

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

  # agg el servicios post validacion

  # 3. BONIFICACION POR PRODUCTIVIDAD
  def calcular_bonificacion_repartidor(servicios_validos_rep) do # servicios validados del repartidor
    servicios_por_dia = Enum.group_by(servicios_validos_rep, fn servicio -> servicio.dia end) # agrupa los servicios por dia del repartidor

    Enum.reduce(servicios_por_dia, 0, fn {_dia, servicios_del_dia}, acc_bono ->
      km_total_dia = Enum.reduce(servicios_del_dia, 0, fn servicio, acc_km -> acc_km + servicio.kilometros
    end)

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
    dias_trabajados = servicios_validos
    |> Enum.filter(fn servicio -> servicio.repartidor == repartidor.codigo end)
    |> Enum.map(fn servicio -> servicio.dia end)
    |> Enum.uniq()
    |> length()

    # Se multiplica todo el proceso de arriba por el alquiler de la bici y eso posteriormente se le
    # descontara al domiciliario
    dias_trabajados * @alquiler_bicicleta
  end


  # 3. OBTENER LOS SERVICIOS POST VALIDACION
  # 4. CALCULAR LA PLATA/LIQUIDACION
  # Y YA CREO, TAMPOCO ES MUCHO BTW
end
