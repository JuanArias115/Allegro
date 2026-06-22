import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api.service';
import type { AdminUser, CreateUserResult, Role, UserPage } from '../models/models';

@Injectable({ providedIn: 'root' })
export class UsersService {
  private readonly api = inject(ApiService);

  list(query?: string, pageToken?: string, pageSize = 25): Observable<UserPage> {
    return this.api.get<UserPage>('/api/admin/users', { query, pageToken, pageSize });
  }

  create(name: string, email: string, role: Role): Observable<CreateUserResult> {
    return this.api.post<CreateUserResult>('/api/admin/users', { name, email, role });
  }

  update(uid: string, body: { name?: string; role?: Role }): Observable<AdminUser> {
    return this.api.patch<AdminUser>(`/api/admin/users/${uid}`, body);
  }

  activationLink(uid: string): Observable<{ activationLink: string }> {
    return this.api.post<{ activationLink: string }>(`/api/admin/users/${uid}/activation-link`, {});
  }

  revokeSessions(uid: string): Observable<void> {
    return this.api.post<void>(`/api/admin/users/${uid}/revoke-sessions`, {});
  }

  setStatus(uid: string, disabled: boolean): Observable<AdminUser> {
    return this.api.patch<AdminUser>(`/api/admin/users/${uid}/status`, { disabled });
  }
}
