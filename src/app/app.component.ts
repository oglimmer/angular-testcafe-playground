import { Component } from '@angular/core';
import { Store, select } from '@ngrx/store';

import { selectBookCollection, selectBooks } from './state/books.selectors';
import {
  retrievedBookList,
  addBook,
  removeBook,
  newBook,
} from './state/books.actions';
import { GoogleBooksService } from './book-list/books.service';
import { Book } from './book-list/books.model';
import {Observable} from "rxjs";
import {selectLogin} from "./state/login.reducer";

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.scss'],
})
export class AppComponent {
  books$ = this.store.pipe(select(selectBooks));
  bookCollection$ = this.store.pipe(select(selectBookCollection));
  user$ : Observable<string>;

  onAdd(bookId) {
    this.store.dispatch(addBook({ bookId }));
  }

  onRemove(bookId) {
    this.store.dispatch(removeBook({ bookId }));
  }

  onNew(bookData) {
    const book = {
      id: "id" + Math.random(),
      volumeInfo: bookData
    };
    this.store.dispatch(newBook({
      Book: book
    }));
    this.booksService.storeNewBook(book).subscribe();
  }

  constructor(
    private booksService: GoogleBooksService,
    private store: Store
  ) {
    this.user$ = this.store.pipe(select(selectLogin));
  }

  ngOnInit() {
    this.booksService
      .books
      .subscribe((Book: Book[]) => this.store.dispatch(retrievedBookList({ Book })));
  }
}