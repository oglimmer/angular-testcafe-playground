import { Book } from '../book-list/books.model';

export interface AppState {
  userid: string,
  books: ReadonlyArray<Book>;
  collection: ReadonlyArray<string>;
}