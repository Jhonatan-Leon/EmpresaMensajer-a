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
end
