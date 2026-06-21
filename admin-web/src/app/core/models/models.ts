// Modelos alineados con los DTOs del backend .NET. Fechas como string ISO.

export type ReservationStatus = 'Confirmed' | 'CheckedIn' | 'Completed' | 'Cancelled';
export type PaymentMethod = 'Cash' | 'Transfer' | 'Other';
export type Role = 'admin' | 'operator';

export interface Dome {
  id: string;
  name: string;
  shortDescription: string;
  maxCapacity: number;
  isActive: boolean;
}

export interface ProductCategory {
  id: string;
  name: string;
  displayOrder: number;
  isActive: boolean;
}

export interface Product {
  id: string;
  name: string;
  categoryId: string;
  categoryName: string;
  currentPrice: number;
  isActive: boolean;
  imageUrl: string | null;
}

export interface ReservationSummary {
  id: string;
  guestName: string;
  phone: string;
  domeId: string;
  domeName: string;
  checkIn: string;
  checkOut: string;
  guestCount: number;
  status: ReservationStatus;
  lodgingPrice: number;
  totalConsumptions: number;
  totalPaid: number;
  balance: number;
}

export interface Payment {
  id: string;
  amount: number;
  paidAt: string;
  method: PaymentMethod;
  note: string | null;
}

export interface Consumption {
  id: string;
  productId: string;
  productName: string;
  quantity: number;
  unitPrice: number;
  subtotal: number;
  consumedAt: string;
}

export interface Reservation {
  id: string;
  guestName: string;
  phone: string;
  domeId: string;
  domeName: string;
  checkIn: string;
  checkOut: string;
  guestCount: number;
  lodgingPrice: number;
  status: ReservationStatus;
  notes: string | null;
  totalConsumptions: number;
  totalDue: number;
  totalPaid: number;
  balance: number;
  createdAt: string;
  updatedAt: string;
  payments: Payment[];
  consumptions: Consumption[];
}

export interface TodayState {
  date: string;
  arrivals: ReservationSummary[];
  departures: ReservationSummary[];
  currentlyHosted: ReservationSummary[];
  upcoming: ReservationSummary[];
}

export interface DomeBlock {
  id: string;
  domeId: string;
  domeName: string;
  startDate: string;
  endDate: string;
  reason: string;
  createdAt: string;
}

export interface Availability {
  domeId: string;
  checkIn: string;
  checkOut: string;
  isAvailable: boolean;
  conflicts: ReservationSummary[];
  blockedRanges: DomeBlock[];
}

// ---- Usuarios (admin) ----
export interface AdminUser {
  uid: string;
  name: string | null;
  email: string | null;
  provider: string;
  role: Role | null;
  disabled: boolean;
  createdAtUtc: string | null;
  lastLoginAtUtc: string | null;
}

export interface UserPage {
  items: AdminUser[];
  nextPageToken: string | null;
}

export interface CreateUserResult {
  user: AdminUser;
  activationLink: string;
}

// ---- Reportes ----
export interface ReportSummary {
  from: string;
  to: string;
  reservationsCount: number;
  cancellations: number;
  nightsReserved: number;
  occupiedNights: number;
  availableNights: number;
  occupancyRate: number;
  reservedValue: number;
  paymentsReceived: number;
  pendingBalance: number;
  productSalesValue: number;
}

export interface OccupancyByDome {
  domeId: string;
  domeName: string;
  occupiedNights: number;
  availableNights: number;
  occupancyRate: number;
}

export interface OccupancyReport {
  from: string;
  to: string;
  occupiedNights: number;
  availableNights: number;
  occupancyRate: number;
  domes: OccupancyByDome[];
}

export interface PaymentBucket {
  date: string;
  amount: number;
}

export interface PaymentsReport {
  from: string;
  to: string;
  total: number;
  byDay: PaymentBucket[];
}

export interface ProductSales {
  productId: string;
  productName: string;
  quantity: number;
  value: number;
}

export interface ProductsReport {
  from: string;
  to: string;
  totalQuantity: number;
  totalValue: number;
  items: ProductSales[];
}
