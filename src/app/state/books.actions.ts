import { createAction, props } from '@ngrx/store';
import {Book} from "../book-list/books.model";

export const addBook = createAction(
  '[Book List] Add Book',
  props<{ bookId }>()
);

export const removeBook = createAction(
  '[Book Collection] Remove Book',
  props<{ bookId }>()
);

export const retrievedBookList = createAction(
  '[Book List/API] Retrieve Books Success',
  props<{ Book }>()
);

export const newBook = createAction(
  '[Book List] New Book',
  props<{ Book: Book }>()
);

export const login = createAction(
  '[Login] Login',
  props<{ userid: string }>()
);