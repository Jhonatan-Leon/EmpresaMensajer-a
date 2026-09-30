defmodule Datos do
  def repartidores do
    [
      %{codigo: "M01", nombre: "Ana Torres", bicicleta: true},
      %{codigo: "M02", nombre: "David López", bicicleta: false},
      %{codigo: "M03", nombre: "Carlos Ruiz", bicicleta: true},
      %{codigo: "M04", nombre: "Elena Gómez", bicicleta: true}
    ]
  end

  def zonas do
    [
      %{id: "Z1", nombre: "Centro", area: 6.5},
      %{id: "Z2", nombre: "Norte", area: 10.2},
      %{id: "Z3", nombre: "Sur", area: 8.0},
      %{id: "Z4", nombre: "Oeste", area: 5.5}
    ]
  end

  def servicios do
    [
      %{repartidor: "M01", zona: "Z1", dia: 1, kilometros: 18, retraso: 3},
      %{repartidor: "M01", zona: "Z2", dia: 1, kilometros: 25, retraso: 14},
      %{repartidor: "M01", zona: "Z3", dia: 2, kilometros: 40, retraso: -5},
      %{repartidor: "M01", zona: "Z4", dia: 3, kilometros: 35, retraso: 0},
      %{repartidor: "M01", zona: "Z1", dia: 4, kilometros: 20, retraso: 5},
      %{repartidor: "M01", zona: "Z2", dia: 5, kilometros: 15, retraso: -2},
      %{repartidor: "M01", zona: "Z3", dia: 6, kilometros: 28, retraso: 0},
      %{repartidor: "M02", zona: "Z1", dia: 1, kilometros: 30, retraso: 0},
      %{repartidor: "M02", zona: "Z2", dia: 2, kilometros: 42, retraso: 5},
      %{repartidor: "M02", zona: "Z3", dia: 3, kilometros: 20, retraso: 35},
      %{repartidor: "M03", zona: "Z1", dia: 1, kilometros: 45, retraso: 0},
      %{repartidor: "M03", zona: "Z2", dia: 1, kilometros: 40, retraso: -2},
      %{repartidor: "M03", zona: "Z3", dia: 2, kilometros: 30, retraso: 25},
      %{repartidor: "M03", zona: "Z4", dia: 3, kilometros: 25, retraso: 10},
      %{repartidor: "M04", zona: "Z1", dia: 1, kilometros: 10, retraso: 0},
      %{repartidor: "M04", zona: "Z2", dia: 2, kilometros: 12, retraso: 2},
      %{repartidor: "M99", zona: "Z1", dia: 1, kilometros: 15, retraso: 0},
      %{repartidor: "M01", zona: "Z99", dia: 2, kilometros: 10, retraso: 0},
      %{repartidor: "M02", zona: "Z1", dia: 7, kilometros: 15, retraso: 0},
      %{repartidor: "M04", zona: "Z1", dia: 1, kilometros: 50, retraso: 0}
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

