import { createReducer, on } from '@ngrx/store';

import {newBook, retrievedBookList} from './books.actions';
import { Book } from '../book-list/books.model';

export const initialState: ReadonlyArray<Book> = [];

export const booksReducer = createReducer(
  initialState,
  on(retrievedBookList, (state, { Book }) => [...Book]),
  on(newBook, (state, { Book }) => [...state, Book]),
);