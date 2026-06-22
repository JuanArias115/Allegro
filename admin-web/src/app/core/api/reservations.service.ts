import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api.service';
import type {
  Availability,
  PaymentMethod,
  Reservation,
  ReservationStatus,
  ReservationSummary,
  TodayState,
} from '../models/models';

export interface ReservationFilter {
  name?: string;
  phone?: string;
  domeId?: string;
  status?: ReservationStatus;
  from?: string;
  to?: string;
  active?: boolean;
}

export interface UpsertReservation {
  guestName: string;
  phone: string;
  domeId: string;
  checkIn: string;
  checkOut: string;
  guestCount: number;
  lodgingPrice: number;
  notes: string | null;
}

export interface CreatePayment {
  amount: number;
  method: PaymentMethod;
  note: string | null;
  paidAt?: string | null;
}

export interface CreateConsumption {
  productId: string;
  quantity: number;
  consumedAt?: string | null;
}

@Injectable({ providedIn: 'root' })
export class ReservationsService {
  private readonly api = inject(ApiService);

  today(): Observable<TodayState> {
    return this.api.get<TodayState>('/api/today');
  }

  availability(
    domeId: string,
    checkIn: string,
    checkOut: string,
    excludeReservationId?: string,
  ): Observable<Availability> {
    return this.api.get<Availability>('/api/availability', {
      domeId,
      checkIn,
      checkOut,
      excludeReservationId,
    });
  }

  list(filter: ReservationFilter = {}): Observable<ReservationSummary[]> {
    return this.api.get<ReservationSummary[]>('/api/reservations', { ...filter });
  }

  getById(id: string): Observable<Reservation> {
    return this.api.get<Reservation>(`/api/reservations/${id}`);
  }

  create(body: UpsertReservation): Observable<Reservation> {
    return this.api.post<Reservation>('/api/reservations', body);
  }

  update(id: string, body: UpsertReservation): Observable<Reservation> {
    return this.api.put<Reservation>(`/api/reservations/${id}`, body);
  }

  changeStatus(id: string, status: ReservationStatus): Observable<Reservation> {
    return this.api.patch<Reservation>(`/api/reservations/${id}/status`, { status });
  }

  addPayment(id: string, body: CreatePayment): Observable<Reservation> {
    return this.api.post<Reservation>(`/api/reservations/${id}/payments`, body);
  }

  addConsumption(id: string, body: CreateConsumption): Observable<Reservation> {
    return this.api.post<Reservation>(`/api/reservations/${id}/consumptions`, body);
  }

  removeConsumption(id: string, consumptionId: string): Observable<Reservation> {
    return this.api.delete<Reservation>(`/api/reservations/${id}/consumptions/${consumptionId}`);
  }

  checkout(id: string, finalPayment: CreatePayment | null): Observable<Reservation> {
    return this.api.post<Reservation>(`/api/reservations/${id}/checkout`, finalPayment);
  }
}
