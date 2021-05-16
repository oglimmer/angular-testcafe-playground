import { Component } from '@angular/core';
import {select, Store} from "@ngrx/store";
import { login } from '../state/books.actions';
import {Observable} from "rxjs";
import {selectLogin} from "../state/login.reducer";

@Component({
    selector: 'app-user-login',
    templateUrl: './user-login.component.html',
    styleUrls: ['./user-login.component.scss'],
})
export class UserLoginComponent {

    user$ : Observable<string>;
    userId = "user" + Math.random();

    constructor(private store: Store) {
        this.user$ = this.store.pipe(select(selectLogin));
    }

    login() {
        this.store.dispatch(login({userid: this.userId}));
    }
}