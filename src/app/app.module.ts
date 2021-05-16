import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { FormsModule } from '@angular/forms';

import { AppComponent } from './app.component';

import { booksReducer } from './state/books.reducer';
import { collectionReducer } from './state/collection.reducer';
import { userReducer } from './state/login.reducer';
import { StoreModule } from '@ngrx/store';
import { HttpClientModule } from '@angular/common/http';
import { BookListComponent } from './book-list/book-list.component';
import { BookCollectionComponent } from './book-list/book-collection.component';
import { BookAddComponent } from "./book-list/book-add.component";
import {UserLoginComponent} from "./book-list/user-login.component";

@NgModule({
  imports: [
    BrowserModule,
    StoreModule.forRoot({ books: booksReducer, collection: collectionReducer, userid: userReducer }),
    HttpClientModule,
    FormsModule,
  ],
  declarations: [AppComponent, BookListComponent, BookCollectionComponent, BookAddComponent, UserLoginComponent],
  bootstrap: [AppComponent],
})
export class AppModule {}

