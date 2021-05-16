import { Component, EventEmitter, Input, Output } from '@angular/core';

@Component({
    selector: 'app-book-add',
    templateUrl: './book-add.component.html',
    styleUrls: ['./book-add.component.scss'],
})
export class BookAddComponent {
    @Output() newBook = new EventEmitter();

    model = {
        title: "",
        authors: ""
    };

    createNewBook() {
        this.newBook.emit({
            title: this.model.title,
            authors: this.model.authors.split(",")
        });
    }
}