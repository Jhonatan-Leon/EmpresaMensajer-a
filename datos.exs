defmodule Datos do
  def repartidores do
    [
      %{codigo: "M01", nombre: "Ana Torres", bicicleta: true},
      %{codigo: "M02", nombre: "David López", bicicleta: false}
    ]
  end

  def zonas do
    [
      %{id: "Z1", nombre: "Centro", area: 6.5},
      %{id: "Z2", nombre: "Norte", area: 10.2}
      # ...
    ]
  end

  def servicios do
    [
      %{repartidor: "M01", zona: "Z1", dia: 1, kilometros: 18, retraso: 3},
      %{repartidor: "M01", zona: "Z2", dia: 1, kilometros: 25, retraso: 14}
      # .. .
    ]
  end

  def estructurar_datos(repartidores, zonas, servicios) do
    idx_zonas = Map.new(zonas, fn zona -> {zona.id, zona} end)

    Enum.map(repartidores, fn repartidor ->
      # Servicios cuyo repartidor coincide con el código de este repartidor
      servicios_del_repartidor =
        Enum.filter(servicios, fn servicio -> servicio.repartidor == repartidor.codigo end)

      # Solo dia, kilometros y retraso (se quitan el código del repartidor y la zona)
      sus_servicios =
        Enum.map(servicios_del_repartidor, fn servicio ->
          Map.drop(servicio, [:repartidor, :zona])
        end)

      # Zonas donde trabajó, sin repetir, con sus datos completos
      sus_zonas =
        servicios_del_repartidor
        |> Enum.map(fn servicio -> servicio.zona end)
        |> Enum.uniq()
        |> Enum.filter(fn id -> Map.has_key?(idx_zonas, id) end)
        |> Enum.map(fn id -> Map.get(idx_zonas, id) end)

      # Un solo mapa por repartidor: se fusiona con un mapa que trae lo que le falta
      Map.merge(repartidor, %{servicios: sus_servicios, zona: sus_zonas})
    end)
  end
end
