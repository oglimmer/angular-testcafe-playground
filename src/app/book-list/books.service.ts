import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';

import {Observable, Subject} from 'rxjs';
import {filter, map} from 'rxjs/operators';
import { Book } from './books.model';
import {Store} from "@ngrx/store";

interface ReadResponse {
  userid: string,
  books: Book[]
}

@Injectable({ providedIn: 'root' })
export class GoogleBooksService {

  userid : string = null;
  books : Subject<Book[]> = new Subject();
  
  constructor(private http: HttpClient, private store: Store<{userid: string}>) {
    this.store.select('userid').pipe(filter(e => !!e)).subscribe(newUserId => {
      this.userid = newUserId;
      this.http
          .get<ReadResponse>(this.REST_RESOURCE_ENDPOINT + '?userid=' + newUserId)
          .pipe(map((resp) => resp.books || [])).subscribe(this.books);
    })
  }

  private readonly REST_RESOURCE_ENDPOINT = 'https://6z1nxth9oi.execute-api.eu-central-1.amazonaws.com/test/book';

  storeNewBook(book: Book): Observable<void> {
    return this.http.post<void>(this.REST_RESOURCE_ENDPOINT, {
      userid: this.userid,
      book: book
    });
  }
}