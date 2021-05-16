import {createReducer, on, createSelector} from '@ngrx/store';

import {login} from './books.actions';
import {AppState} from "./app.state";

export const initialState: string = "";

export const userReducer = createReducer(
  initialState,
  on(login, (state, { userid }) => userid)
);

export const selectLogin = createSelector(
    (state: AppState) => state.userid,
    (userid: string) => userid
);


