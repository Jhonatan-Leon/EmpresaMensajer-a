defmodule Datos do
    def repartidores do
    [
      %{codigo: "M01", nombre: "Ana Torres", bicicleta: true},
      %{codigo: "M02", nombre: "David López", bicicleta: false},
      %{codigo: "M03", nombre: "Carlos Gómez", bicicleta: true},
      %{codigo: "M04", nombre: "Lucía Pérez", bicicleta: false},
      %{codigo: "M05", nombre: "Mateo Ruiz", bicicleta: true},
      %{codigo: "M06", nombre: "Sofía Castro", bicicleta: false},
      %{codigo: "M07", nombre: "Andrés Morales", bicicleta: true},
      %{codigo: "M08", nombre: "Valentina Rojas", bicicleta: false},
      %{codigo: "M09", nombre: "Jorge Ramírez", bicicleta: false},
      %{codigo: "M10", nombre: "Camila Vargas", bicicleta: false}
    ]
  end

  def zonas do
    [
      %{id: "Z1", nombre: "Centro", area: 6.5},
      %{id: "Z2", nombre: "Norte", area: 10.2},
      %{id: "Z3", nombre: "Sur", area: 8.0},
      %{id: "Z4", nombre: "Occidente", area: 12.4},
      %{id: "Z5", nombre: "Oriente", area: 9.1},
      %{id: "Z6", nombre: "Industrial", area: 15.0},
      %{id: "Z7", nombre: "Periferia", area: 20.5}
    ]
  end

  def servicios do
    [
      # --- SERVICIOS VÁLIDOS (Días 1 al 6, diferentes repartidores, zonas y rangos de retraso) ---
      # Día 1: Ana Torres (M01 - con bici) acumula 85 km (aplica bonificación diaria por productividad >= 80 km)
      %{repartidor: "M01", zona: "Z1", dia: 1, kilometros: 40, retraso: -5},
      %{repartidor: "M01", zona: "Z2", dia: 1, kilometros: 45, retraso: 2},

      # Día 2: David López (M02 - sin bici) con diferentes tipos de descuento por puntualidad
      %{repartidor: "M02", zona: "Z3", dia: 2, kilometros: 15, retraso: 15}, # Descuento 10%
      %{repartidor: "M02", zona: "Z4", dia: 2, kilometros: 20, retraso: 35}, # Descuento 25%

      # Día 3: Carlos Gómez (M03 - con bici) y Mateo Ruiz (M05 - con bici)
      %{repartidor: "M03", zona: "Z5", dia: 3, kilometros: 30, retraso: 0},
      %{repartidor: "M05", zona: "Z6", dia: 3, kilometros: 25, retraso: -10},

      # Día 4: Lucía Pérez (M04 - sin bici)
      %{repartidor: "M04", zona: "Z7", dia: 4, kilometros: 12, retraso: 8},

      # Día 5: Servicios variados
      %{repartidor: "M06", zona: "Z1", dia: 5, kilometros: 18, retraso: 3},
      %{repartidor: "M07", zona: "Z2", dia: 5, kilometros: 22, retraso: 1},

      # Día 6: Servicios para cubrir el último día de operación
      %{repartidor: "M08", zona: "Z3", dia: 6, kilometros: 14, retraso: -2},
      %{repartidor: "M09", zona: "Z4", dia: 6, kilometros: 19, retraso: 5},
      %{repartidor: "M10", zona: "Z5", dia: 6, kilometros: 16, retraso: 4},


      # --- SERVICIOS INVÁLIDOS (Al menos dos por cada motivo de rechazo según el orden de validación) ---

      # 1. Motivo: :repartidor_desconocido (2 casos)
      %{repartidor: "M99", zona: "Z1", dia: 1, kilometros: 10, retraso: 5},
      %{repartidor: "M_ERR", zona: "Z2", dia: 2, kilometros: 15, retraso: 0},

      # 2. Motivo: :zona_desconocida (2 casos)
      %{repartidor: "M01", zona: "Z99", dia: 1, kilometros: 10, retraso: 5},
      %{repartidor: "M02", zona: "Z_BAD", dia: 3, kilometros: 20, retraso: 2},

      # 3. Motivo: :dia_invalido (2 casos - fuera del rango 1..6)
      %{repartidor: "M01", zona: "Z1", dia: 0, kilometros: 10, retraso: 5},
      %{repartidor: "M02", zona: "Z2", dia: 7, kilometros: 15, retraso: 1},

      # 4. Motivo: :kilometros_fuera_de_rango (2 casos - <= 0 o > 45)
      %{repartidor: "M01", zona: "Z1", dia: 1, kilometros: 0, retraso: 5},
      %{repartidor: "M02", zona: "Z2", dia: 2, kilometros: 50, retraso: 2},

      # 5. Motivo: :retraso_invalido (2 casos - menor a -30 o mayor a 180)
      %{repartidor: "M01", zona: "Z1", dia: 1, kilometros: 15, retraso: -35},
      %{repartidor: "M02", zona: "Z2", dia: 2, kilometros: 20, retraso: 200}
    ]
  end
end
