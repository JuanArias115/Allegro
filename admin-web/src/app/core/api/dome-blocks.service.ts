import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api.service';
import type { DomeBlock } from '../models/models';

export interface CreateDomeBlock {
  domeId: string;
  startDate: string;
  endDate: string;
  reason: string;
}

@Injectable({ providedIn: 'root' })
export class DomeBlocksService {
  private readonly api = inject(ApiService);

  list(domeId?: string, from?: string, to?: string): Observable<DomeBlock[]> {
    return this.api.get<DomeBlock[]>('/api/dome-blocks', { domeId, from, to });
  }

  create(body: CreateDomeBlock): Observable<DomeBlock> {
    return this.api.post<DomeBlock>('/api/dome-blocks', body);
  }

  remove(id: string): Observable<void> {
    return this.api.delete<void>(`/api/dome-blocks/${id}`);
  }
}
