# Arquitectura y API

## Modelo de dominio

```
Dome (Domo)            Product (Producto)
  id                     id
  name                   name
  shortDescription       category  (Bebidas|Alimentos|Servicios|Otros)
  maxCapacity            currentPrice
  isActive               isActive
                         imageUrl?

Reservation (Reserva)            Payment (Abono)         Consumption (Consumo)
  id                               id                      id
  guestName, phone                 reservationId           reservationId
  domeId                           amount                  productId
  checkIn, checkOut (date)         paidAt (UTC)            productName  (instantánea)
  guestCount                       method                  quantity
  lodgingPrice                     note?                   unitPrice    (congelado)
  status                                                   subtotal     (=qty*precio)
  notes?                                                   consumedAt (UTC)
  createdAt, updatedAt (UTC)
  -- calculados --
  totalConsumptions = Σ subtotal
  totalDue          = lodgingPrice + totalConsumptions
  totalPaid         = Σ amount
  balance           = totalDue − totalPaid
```

**Estados de reserva:** `Confirmed` (Confirmada) · `CheckedIn` (Hospedada) · `Completed` (Finalizada) · `Cancelled` (Cancelada).

## Reglas de negocio (en el backend)

- Un domo no puede tener dos reservas **activas** (no canceladas) que se crucen. Cruce = `a.checkIn < b.checkOut && b.checkIn < a.checkOut` (intervalo semiabierto: dos estadías pueden compartir el día llegada=salida).
- `checkOut` debe ser posterior a `checkIn`.
- Valores monetarios `>= 0`; los abonos `> 0`.
- El saldo se recalcula siempre; el precio del consumo se congela al registrarlo.
- Se pueden registrar múltiples abonos.
- El checkout solo finaliza la reserva con confirmación explícita (no al ver/compartir).
- No hay borrado físico de reservas: se conservan canceladas/finalizadas.
- Abonos, consumos y checkout corren dentro de una transacción.

## Endpoints REST

Todos requieren `Authorization: Bearer <token>`. Base: `http://localhost:8080`.

| Método | Ruta | Descripción |
|---|---|---|
| GET | `/health`, `/health/ready` | Liveness / readiness (BD). |
| GET | `/api/today` | Estado del día: llegadas, salidas, ocupados, próximas. |
| GET | `/api/availability?domeId&checkIn&checkOut&excludeReservationId` | Disponibilidad y conflictos. |
| GET | `/api/domes?onlyActive` | Lista de domos. |
| GET/PUT | `/api/domes/{id}` | Ver / actualizar domo. |
| GET | `/api/products?onlyActive` | Catálogo. |
| POST/PUT | `/api/products`, `/api/products/{id}` | Crear / actualizar producto. |
| GET | `/api/reservations?name&phone&domeId&status&from&to&active` | Listado / historial filtrado. |
| GET | `/api/reservations/{id}` | Detalle (con abonos y consumos). |
| POST/PUT | `/api/reservations`, `/api/reservations/{id}` | Crear / editar. |
| PATCH | `/api/reservations/{id}/status` | Cambiar estado. |
| POST | `/api/reservations/{id}/payments` | Registrar abono. |
| POST | `/api/reservations/{id}/consumptions` | Agregar consumo. |
| DELETE | `/api/reservations/{id}/consumptions/{cid}` | Quitar consumo. |
| GET | `/api/reservations/{id}/checkout` | Resumen de cuenta (no cierra). |
| POST | `/api/reservations/{id}/checkout` | Registrar pago final (opcional) y finalizar. |

La documentación interactiva (OpenAPI/Swagger) está disponible en `/swagger` en entorno de desarrollo.

## Autenticación

- `AUTH_MODE=firebase`: JWT Bearer validado contra `https://securetoken.google.com/<projectId>`.
- `AUTH_MODE=local`: token estático (`LOCAL_DEV_TOKEN`), solo desarrollo; prohibido en producción.

## Errores

Manejo centralizado. Las violaciones de reglas devuelven `409` con `{ title, detail, status }`; los datos inválidos `400` con los errores de validación; los no controlados `500` sin filtrar detalles internos.
