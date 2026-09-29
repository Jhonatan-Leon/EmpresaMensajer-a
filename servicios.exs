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
  @alquiler_bicibleta 10000         # si el repartidor usa bici fuera de la empresa entonces no aplica

  # CONSTANTES DE BONIFICACION Y DESCUENTOS

  @bono_puntual 1.08                 # corresponde al + 8% del valor del servicio en bruto
  @descuento_retraso_10_30 0.9       # entre 10 y 30 mins se descuenta el 10%
  @descuento_retraso_mas_30 0.75     # retraso de mas de 30 mins se descuenta el 25%

  def calcular_valor_servicio(servicio) do
    valor_base = @tarifa_base * servicio.kilometros

    cond do
      servicio.retraso <= 0 ->
        servicio.retraso * @bono_puntual
      servicio.retraso <= 10 ->
        servicio.retraso
      servicio.retraso <= 30 ->
        servicio.retraso * @descuento_retraso_10_30
      true -> servicio.retraso * @descuento_retraso_mas_30
    end
  end

  

  # 3. OBTENER LOS SERVICIOS POST VALIDACION
  # 4. CALCULAR LA PLATA/LIQUIDACION
  # Y YA CREO, TAMPOCO ES MUCHO BTW
end
